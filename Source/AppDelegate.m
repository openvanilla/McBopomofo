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
#import "OVNonModalAlertWindowController.h"
#import "PreferencesWindowController.h"

extern void LTLoadLanguageModel(void);

static NSString *kCheckUpdateAutomatically = @"CheckUpdateAutomatically";
static NSString *kNextUpdateCheckDateKey = @"NextUpdateCheckDate";
static NSString *kUpdateInfoEndpointKey = @"UpdateInfoEndpoint";
static NSString *kUpdateInfoSiteKey = @"UpdateInfoSite";
static const NSTimeInterval kNextCheckInterval = 86400.0;
static const NSTimeInterval kTimeoutInterval = 60.0;

@interface AppDelegate () <NSURLConnectionDataDelegate, OVNonModalAlertWindowControllerDelegate>
@end

@implementation AppDelegate
@synthesize window = _window;

- (void)dealloc
{
    _preferencesWindowController = nil;
    _updateCheckConnection = nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)inNotification
{
    LTLoadLanguageModel();

    if (![[NSUserDefaults standardUserDefaults] objectForKey:kCheckUpdateAutomatically]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kCheckUpdateAutomatically];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

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

    _currentUpdateCheckIsForced = forced;

    // time for update?
    if (!forced) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kCheckUpdateAutomatically]) {
            return;
        }

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
    BOOL isForcedCheck = _currentUpdateCheckIsForced;

    _receivingData = nil;
    _updateCheckConnection = nil;
    _currentUpdateCheckIsForced = NO;

    if (isForcedCheck) {
        [[OVNonModalAlertWindowController sharedInstance] showWithTitle:NSLocalizedString(@"Update Check Failed", nil) content:[NSString stringWithFormat:NSLocalizedString(@"There may be no internet connection or the server failed to respond.\n\nError message: %@", nil), [error localizedDescription]] confirmButtonTitle:NSLocalizedString(@"Dismiss", nil) cancelButtonTitle:nil cancelAsDefault:NO delegate:nil];
    }
}

- (void)showNoUpdateAvailableAlert
{
    [[OVNonModalAlertWindowController sharedInstance] showWithTitle:NSLocalizedString(@"Check for Update Completed", nil) content:NSLocalizedString(@"You are already using the latest version of McBopomofo.", nil) confirmButtonTitle:NSLocalizedString(@"OK", nil) cancelButtonTitle:nil cancelAsDefault:NO delegate:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id plist = [NSPropertyListSerialization propertyListWithData:_receivingData options:NSPropertyListImmutable format:NULL error:NULL];
#if DEBUG
    NSLog(@"plist %@",plist);
#endif

    BOOL isForcedCheck = _currentUpdateCheckIsForced;

    _receivingData = nil;
    _updateCheckConnection = nil;
    _currentUpdateCheckIsForced = NO;

    if (!plist) {
        if (isForcedCheck) {
            [self showNoUpdateAvailableAlert];
        }
        return;
    }

    NSString *remoteVersion = [plist objectForKey:(id)kCFBundleVersionKey];
#if DEBUG
    NSLog(@"the remoteversion is %@",remoteVersion);
#endif
    if (!remoteVersion) {
        if (isForcedCheck) {
            [self showNoUpdateAvailableAlert];
        }
        return;
    }

    // TODO: Validate info (e.g. bundle identifier)
    // TODO: Use HTML to display change log, need a new key like UpdateInfoChangeLogURL for this

    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = [infoDict objectForKey:(id)kCFBundleVersionKey];
    NSComparisonResult result  = [currentVersion compare:remoteVersion options:NSNumericSearch];

    if (result != NSOrderedAscending) {
        if (isForcedCheck) {
            [self showNoUpdateAvailableAlert];
        }
        return;
    }


    NSString *siteInfoURLString = [plist objectForKey:kUpdateInfoSiteKey];
    if (!siteInfoURLString) {
        if (isForcedCheck) {
            [self showNoUpdateAvailableAlert];
        }
        return;
    }

    NSURL *siteInfoURL = [NSURL URLWithString:siteInfoURLString];
    if (!siteInfoURL) {
        if (isForcedCheck) {
            [self showNoUpdateAvailableAlert];
        }
        return;
    }
    _updateNextStepURL = siteInfoURL;

    NSDictionary *versionDescriptions = [plist objectForKey:@"Description"];
    NSString *versionDescription = @"";
    if ([versionDescriptions isKindOfClass:[NSDictionary class]]) {
        NSString *locale = @"en";
        NSArray *supportedLocales = [NSArray arrayWithObjects:@"en", @"zh-Hant", @"zh-Hans", nil];
        NSArray *preferredTags = [NSBundle preferredLocalizationsFromArray:supportedLocales];
        if ([preferredTags count]) {
            locale = [preferredTags objectAtIndex:0];
        }
        versionDescription = [versionDescriptions objectForKey:locale];
        if (!versionDescription) {
            versionDescription = [versionDescriptions objectForKey:@"en"];
        }

        if (!versionDescription) {
            versionDescription = @"";
        }
        else {
            versionDescription = [@"\n\n" stringByAppendingString:versionDescription];
        }
    }

    NSString *content = [NSString stringWithFormat:NSLocalizedString(@"You're currently using McBopomofo %@ (%@), a new version %@ (%@) is now available. Do you want to visit McBopomofo's website to download the version?%@", nil), [infoDict objectForKey:@"CFBundleShortVersionString"], currentVersion, [plist objectForKey:@"CFBundleShortVersionString"], remoteVersion, versionDescription];

    [[OVNonModalAlertWindowController sharedInstance] showWithTitle:NSLocalizedString(@"New Version Available", nil) content:content confirmButtonTitle:NSLocalizedString(@"Visit Website", nil) cancelButtonTitle:NSLocalizedString(@"Not Now", nil) cancelAsDefault:NO delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivingData appendData:data];
}

- (void)nonModalAlertWindowControllerDidConfirm:(OVNonModalAlertWindowController *)controller
{
    if (_updateNextStepURL) {
        [[NSWorkspace sharedWorkspace] openURL:_updateNextStepURL];
    }

    _updateNextStepURL = nil;
}

- (void)nonModalAlertWindowControllerDidCancel:(OVNonModalAlertWindowController *)controller
{
    _updateNextStepURL = nil;
}

@end
