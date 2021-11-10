//
// AppDelegate.m
//
// Copyright (c) 2011-2012 The McBopomofo Project.
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
#import <sys/mount.h>

static NSString *const kTargetBin = @"McBopomofo";
static NSString *const kTargetType = @"app";
static NSString *const kTargetBundle = @"McBopomofo.app";
static NSString *const kDestinationPartial = @"~/Library/Input Methods/"; 
static NSString *const kTargetPartialPath = @"~/Library/Input Methods/McBopomofo.app";
static NSString *const kTargetFullBinPartialPath = @"~/Library/Input Methods/McBopomofo.app/Contents/MacOS/McBopomofo";

static const NSTimeInterval kTranslocationRemovalTickInterval = 0.5;
static const NSTimeInterval kTranslocationRemovalDeadline = 60.0;

/// A simple replacement for the deprecated NSRunAlertPanel.
void RunAlertPanel(NSString *title, NSString *message, NSString *buttonTitle) {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:buttonTitle];
    [alert runModal];
}

@implementation AppDelegate
@synthesize installButton = _installButton;
@synthesize cancelButton = _cancelButton;
@synthesize textView = _textView;
@synthesize progressSheet = _progressSheet;
@synthesize progressIndicator = _progressIndicator;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _installingVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];

    _archiveUtil = [[ArchiveUtil alloc] initWithAppName:kTargetBin targetAppBundleName:kTargetBundle];
    [_archiveUtil validateIfNotarizedArchiveExists];

    [self.cancelButton setNextKeyView:self.installButton];
    [self.installButton setNextKeyView:self.cancelButton];
    [[self window] setDefaultButtonCell:[self.installButton cell]];

    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithRTF:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"]] documentAttributes:NULL];

    NSMutableAttributedString *mutableAttrStr = [attrStr mutableCopy];
    [mutableAttrStr addAttribute:NSForegroundColorAttributeName value:[NSColor controlTextColor] range:NSMakeRange(0, [mutableAttrStr length])];
    [[self.textView textStorage] setAttributedString:mutableAttrStr];
    [self.textView setSelectedRange:NSMakeRange(0, 0)];
  
    [[self window] setTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ (for version %@, r%@)", nil), [[self window] title], versionString, _installingVersion]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[kTargetPartialPath stringByExpandingTildeInPath]]) {
        NSBundle *currentBundle = [NSBundle bundleWithPath:[kTargetPartialPath stringByExpandingTildeInPath]];

        NSString *shortVersion = [[currentBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *currentVersion = [[currentBundle infoDictionary] objectForKey:(id)kCFBundleVersionKey];

        _currentVersionNumber = [currentVersion integerValue];
        if (shortVersion && currentVersion && [currentVersion compare:_installingVersion options:NSNumericSearch] == NSOrderedAscending) {
            _upgrading = YES;
        }
    }

    if (_upgrading) {
        [_installButton setTitle:NSLocalizedString(@"Agree and Upgrade", nil)];
    }

    [[self window] center];
    [[self window] orderFront:self];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)agreeAndInstallAction:(id)sender
{
    [_cancelButton setEnabled:NO];
    [_installButton setEnabled:NO];
    [self removeThenInstallInputMethod];
}

- (void)removeThenInstallInputMethod
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[kTargetPartialPath stringByExpandingTildeInPath]]) {

        BOOL shouldWaitForTranslocationRemoval =
            [self appBundleTranslocatedToARandomizedPath:kTargetPartialPath] &&
            [self.window respondsToSelector:@selector(beginSheet:completionHandler:)];

        // http://www.cocoadev.com/index.pl?MoveToTrash
        NSString *sourceDir = [kDestinationPartial stringByExpandingTildeInPath];
        NSString *trashDir = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
        NSInteger tag;
        
        [[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:sourceDir destination:trashDir files:[NSArray arrayWithObject:kTargetBundle] tag:&tag]; 
        (void)tag;

        NSTask *killTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObjects: @"-9", kTargetBin, nil]];
        [killTask waitUntilExit];

        if (shouldWaitForTranslocationRemoval) {
            [self.progressIndicator startAnimation:self];
            [self.window beginSheet:self.progressSheet completionHandler:^(NSModalResponse returnCode) {
                // Schedule the install action in runloop so that the sheet gets a change to dismiss itself.
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (returnCode == NSModalResponseContinue) {
                        [self installInputMethodWithWarning:NO];
                    } else {
                        [self installInputMethodWithWarning:YES];
                    }
                });
            }];

            _translocationRemovalStartTime = [NSDate date];
            [NSTimer scheduledTimerWithTimeInterval:kTranslocationRemovalTickInterval target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
            return;
        }
    }
    
    [self installInputMethodWithWarning:NO];
}

- (void)timerTick:(NSTimer *)timer
{
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:_translocationRemovalStartTime];
    [self.progressIndicator setDoubleValue:MIN(elapsed / kTranslocationRemovalDeadline, 1.0)];

    if (elapsed >= kTranslocationRemovalDeadline) {
        [timer invalidate];
        [self.window endSheet:self.progressSheet returnCode:NSModalResponseCancel];
    } else if (![self appBundleTranslocatedToARandomizedPath:kTargetPartialPath]) {
        [self.progressIndicator setDoubleValue:1.0];
        [timer invalidate];
        [self.window endSheet:self.progressSheet returnCode:NSModalResponseContinue];
    }
}


- (void)installInputMethodWithWarning:(BOOL)warning
{
    // If the unzipped archive does not exist, this must be a dev-mode installer.
    NSString *targetBundle = [_archiveUtil unzipNotarizedArchive];
    if (!targetBundle) {
        targetBundle = [[NSBundle mainBundle] pathForResource:kTargetBin ofType:kTargetType];
    }
    
    NSTask *cpTask = [NSTask launchedTaskWithLaunchPath:@"/bin/cp" arguments:[NSArray arrayWithObjects:@"-R", targetBundle, [kDestinationPartial stringByExpandingTildeInPath], nil]];
    [cpTask waitUntilExit];
    if ([cpTask terminationStatus] != 0) {
        RunAlertPanel(NSLocalizedString(@"Install Failed", nil), NSLocalizedString(@"Cannot copy the file to the destination.", nil),  NSLocalizedString(@"Cancel", nil));
        [NSApp terminate:self];
    }

    NSArray *installArgs = [NSArray arrayWithObjects:@"install", nil];
    NSTask *installTask = [NSTask launchedTaskWithLaunchPath:[kTargetFullBinPartialPath stringByExpandingTildeInPath] arguments:installArgs];
    [installTask waitUntilExit];
    if ([installTask terminationStatus] != 0) {
        RunAlertPanel(NSLocalizedString(@"Install Failed", nil), NSLocalizedString(@"Cannot activate the input method.", nil),  NSLocalizedString(@"Cancel", nil));
        [NSApp terminate:self];        
    }

    if (warning) {
        RunAlertPanel(NSLocalizedString(@"Attention", nil), NSLocalizedString(@"McBopomofo is upgraded, but please log out or reboot for the new version to be fully functional.", nil),  NSLocalizedString(@"OK", nil));
    } else {
        RunAlertPanel(NSLocalizedString(@"Installation Successful", nil), NSLocalizedString(@"McBopomofo is ready to use.", nil),  NSLocalizedString(@"OK", nil));
    }

    [[NSApplication sharedApplication] performSelector:@selector(terminate:) withObject:self afterDelay:0.1];
}
                                   

- (IBAction)cancelAction:(id)sender
{
    [NSApp terminate:self];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApp terminate:self];    
}

// Determines if an app is translocated by Gatekeeper to a randomized path
// See https://weblog.rogueamoeba.com/2016/06/29/sierra-and-gatekeeper-path-randomization/
- (BOOL)appBundleTranslocatedToARandomizedPath:(NSString *)bundle
{
    const char *bundleAbsPath = [[bundle stringByExpandingTildeInPath] UTF8String];
    int entryCount = getfsstat(NULL, 0, 0);
    int entrySize = sizeof(struct statfs);
    struct statfs *bufs = (struct statfs *)calloc(entryCount, entrySize);
    entryCount = getfsstat(bufs, entryCount * entrySize, MNT_NOWAIT);
    for (int i = 0; i < entryCount; i++) {
        if (!strcmp(bundleAbsPath, bufs[i].f_mntfromname)) {
            free(bufs);

            // getfsstat() may return us a cached result, and so we need to get the stat of the mounted fs.
            // If statfs() returns an error, the mounted fs is already gone.
            struct statfs stat;
            int checkResult = statfs(bundleAbsPath, &stat);
            if (checkResult != 0) {
                // Meaning the app's bundle is not mounted, that is it's not translocated.
                // It also means that the app is not loaded.
                return NO;
            }

            return YES;
        }
    }
    free(bufs);
    return NO;

}
@end
