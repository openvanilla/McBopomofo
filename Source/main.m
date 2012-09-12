//
// main.m
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

#import <Cocoa/Cocoa.h>
#import "OVInputSourceHelper.h"

static NSString *const kConnectionName = @"McBopomofo_1_Connection";

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // register and enable the input source (along with all its input modes)
    if (argc > 1 && !strcmp(argv[1], "install")) {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSURL *bundleURL = nil;
        if ([[NSBundle mainBundle] respondsToSelector:@selector(bundleURL)]) {
            // For Mac OS X 10.6+
            bundleURL = [[NSBundle mainBundle] bundleURL];
        }
        else {
            // For Mac OS X 10.5
            bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        }

        TISInputSourceRef inputSource = [OVInputSourceHelper inputSourceForInputSourceID:bundleID];

        // if this IME name is not found in the list of available IMEs
        if (!inputSource) {
            NSLog(@"Registering input source %@ at %@.", bundleID, [bundleURL absoluteString]);
            // then register
            BOOL status = [OVInputSourceHelper registerInputSource:bundleURL];

            if (!status) {
                NSLog(@"Fatal error: Cannot register input source %@ at %@.", bundleID, [bundleURL absoluteString]);
                [pool drain];
                return -1;
            }

            inputSource = [OVInputSourceHelper inputSourceForInputSourceID:bundleID];
            // if it still doesn't register successfully, bail.
            if (!inputSource) {
                NSLog(@"Fatal error: Cannot find input source %@ after registration.", bundleID);
                [pool drain];
                return -1;
            }
        }

        // if it's not enabled, just enabled it
        if (inputSource && ![OVInputSourceHelper inputSourceEnabled:inputSource]) {
            NSLog(@"Enabling input source %@ at %@.", bundleID, [bundleURL absoluteString]);
            BOOL status = [OVInputSourceHelper enableInputSource:inputSource];

            if (!status != noErr) {
                NSLog(@"Fatal error: Cannot enable input source %@.", bundleID);
                [pool drain];
                return -1;
            }
            if (![OVInputSourceHelper inputSourceEnabled:inputSource]){
                NSLog(@"Fatal error: Cannot enable input source %@.", bundleID);
                [pool drain];
                return -1;
            }
        }

        if (argc > 2 && !strcmp(argv[2], "--all")) {
            BOOL enabled = [OVInputSourceHelper enableAllInputModesForInputSourceBundleID:bundleID];
            if (enabled) {
                NSLog(@"All input sources enabled for %@", bundleID);
            }
            else {
                NSLog(@"Cannot enable all input sources for %@, but this is ignored", bundleID);
            }
        }

        return 0;
    }

    NSString *mainNibName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSMainNibFile"];
    if (!mainNibName) {
        NSLog(@"Fatal error: NSMainNibFile key not defined in Info.plist.");
        [pool drain];
        return -1;
    }

    BOOL loadResult = [NSBundle loadNibNamed:mainNibName owner:[NSApplication sharedApplication]];
    if (!loadResult) {
        NSLog(@"Fatal error: Cannot load %@.", mainNibName);
        [pool drain];
        return -1;
    }

    IMKServer *server = [[IMKServer alloc] initWithName:kConnectionName bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    if (!server) {
        NSLog(@"Fatal error: Cannot initialize input method server with connection %@.", kConnectionName);
        [pool drain];
        return -1;
    }

    [[NSApplication sharedApplication] run];
    [server release];
    [pool drain];
    return 0;
}
