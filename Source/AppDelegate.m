//
// AppDelegate.m
//
// Copyright (c) 2011 The McBopomofo Project.
//
// Contributors:
//     Mengjuei Hsieh (@mjhsieh)
//     Weizhong Yang (@zonble)
//
// Based on the Syrup Project and the Formosana Library
// by Lukhnos Liu (@lukhnos).
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "AppDelegate.h"
#import "UpdateNotificationController.h"
#import "PreferencesWindowController.h"

void LTLoadLanguageModel();

static NSString *kNextUpdateCheckDateKey = @"NextUpdateCheckDate";
static NSString *kUpdateInfoEndpointKey = @"UpdateInfoEndpoint";
static NSString *kUpdateInfoSiteKey = @"UpdateInfoSite";
static const NSTimeInterval kNextCheckInterval = 86400.0;
static const NSTimeInterval kTimeoutInterval = 60.0;

@interface AppDelegate () <NSURLConnectionDataDelegate>
@end

@implementation AppDelegate
@synthesize window = _window;

- (void)dealloc
{
    [_preferencesWindowController release];
    [_updateCheckConnection release];
    [_updateNotificationController release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)inNotification
{
    LTLoadLanguageModel();

    [self checkForUpdate];
}

- (void)checkForUpdate
{
    [self checkForUpdateForced:NO];
}

- (void)checkForUpdateForced:(BOOL)forced
{
    if (_updateCheckConnection) {
        // busy
        return;
    }

    // time for update?
    if (!forced) {
        NSDate *now = [NSDate date];
        NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:kNextUpdateCheckDateKey];
        if (![date isKindOfClass:[NSDate class]]) {
            date = now;
        }

        if ([now compare:date] == NSOrderedAscending) {
            return;
        }
    }

    NSDate *nextUpdateDate = [NSDate dateWithTimeInterval:kNextCheckInterval sinceDate:[NSDate date]];
    [[NSUserDefaults standardUserDefaults] setObject:nextUpdateDate forKey:kNextUpdateCheckDateKey];

    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *updateInfoURLString = [infoDict objectForKey:kUpdateInfoEndpointKey];
    if (![updateInfoURLString length]) {
        return;
    }

    NSURL *updateInfoURL = [NSURL URLWithString:updateInfoURLString];
    if (!updateInfoURL) {
        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:updateInfoURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:kTimeoutInterval];
    if (!request) {
        return;
    }
#if DEBUG
    NSLog(@"about to request update url %@ ",updateInfoURL);
#endif

    if (_receivingData) {
        [_receivingData release];
        _receivingData = nil;
    }

    // create a new data buffer and connection
    _receivingData = [[NSMutableData alloc] init];
    _updateCheckConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [_updateCheckConnection start];
}

- (void)showPreferences
{
    if (!_preferencesWindowController) {
        _preferencesWindowController = [[PreferencesWindowController alloc] initWithWindowNibName:@"preferences"];
    }
    [[_preferencesWindowController window] center];
    [[_preferencesWindowController window] orderFront:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_receivingData release];
    _receivingData = nil;
    [_updateCheckConnection release];
    _updateCheckConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id plist = [NSPropertyListSerialization propertyListFromData:_receivingData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
#if DEBUG
    NSLog(@"plist %@",plist);
#endif

    [_receivingData release];
    _receivingData = nil;
    [_updateCheckConnection release];
    _updateCheckConnection = nil;

    if (!plist) {
        return;
    }

    NSString *remoteVersion = [plist objectForKey:(id)kCFBundleVersionKey];
#if DEBUG
    NSLog(@"the remoteversion is %@",remoteVersion);
#endif
    if (!remoteVersion) {
        return;
    }

    // TODO: Validate info (e.g. bundle identifier)
    // TODO: Use HTML to display change log, need a new key like UpdateInfoChangeLogURL for this

    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = [infoDict objectForKey:(id)kCFBundleVersionKey];
    NSComparisonResult result  = [currentVersion compare:remoteVersion options:NSNumericSearch];

    if (result != NSOrderedAscending) {
        return;
    }


    NSString *siteInfoURLString = [plist objectForKey:kUpdateInfoSiteKey];
    if (!siteInfoURLString) {
        return;
    }

    NSURL *siteInfoURL = [NSURL URLWithString:siteInfoURLString];
    if (!siteInfoURL) {
        return;
    }


    if (_updateNotificationController) {
        [_updateNotificationController release], _updateNotificationController = nil;
    }

    _updateNotificationController = [[UpdateNotificationController alloc] initWithWindowNibName:@"UpdateNotificationController"];

    _updateNotificationController.siteURL = siteInfoURL;
    _updateNotificationController.infoText = [NSString stringWithFormat:NSLocalizedString(@"You are running version %@ (%@), and the new version %@ (%@) is now available.\n\nVisit the website to download it?", @""),
                                              [infoDict objectForKey:@"CFBundleShortVersionString"],
                                              [infoDict objectForKey:(id)kCFBundleVersionKey],
                                              [plist objectForKey:@"CFBundleShortVersionString"],
                                              [plist objectForKey:(id)kCFBundleVersionKey],
                                              nil];

    [_updateNotificationController showWindow:self];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivingData appendData:data];
}
@end
