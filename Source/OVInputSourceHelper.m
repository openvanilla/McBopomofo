//
// OVInputSourceHelper.m
//
// Copyright (c) 2010-2011 Lukhnos D. Liu (lukhnos at lukhnos dot org)
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

#import "OVInputSourceHelper.h"

@implementation OVInputSourceHelper
+ (NSArray *)allInstalledInputSources
{
    CFArrayRef list = TISCreateInputSourceList(NULL, true);
    return (__bridge NSArray *)list;
//    return [NSMakeCollectable(list) autorelease];
}

+ (TISInputSourceRef)inputSourceForProperty:(CFStringRef)inPropertyKey stringValue:(NSString *)inValue
{
    CFTypeID stringID = CFStringGetTypeID();

    for (id source in [self allInstalledInputSources]) {
        CFTypeRef property = TISGetInputSourceProperty((__bridge TISInputSourceRef)source, inPropertyKey);
        if (!property || CFGetTypeID(property) != stringID) {
            continue;
        }

        if (inValue && [inValue compare:(__bridge NSString *)property] == NSOrderedSame) {
            return (__bridge TISInputSourceRef)source;
        }
    }
    return NULL;
}

+ (TISInputSourceRef)inputSourceForInputSourceID:(NSString *)inID
{
    return [self inputSourceForProperty:kTISPropertyInputSourceID stringValue:inID];
}

+ (BOOL)inputSourceEnabled:(TISInputSourceRef)inInputSource
{
    CFBooleanRef value = TISGetInputSourceProperty(inInputSource, kTISPropertyInputSourceIsEnabled);
    return value ? (BOOL)CFBooleanGetValue(value) : NO;
}

+ (BOOL)enableInputSource:(TISInputSourceRef)inInputSource
{
    OSStatus status = TISEnableInputSource(inInputSource);
    return status == noErr;
}

+ (BOOL)enableAllInputModesForInputSourceBundleID:(NSString *)inID
{
    BOOL enabled = NO;

    for (id source in [self allInstalledInputSources]) {
        TISInputSourceRef inputSource = (__bridge TISInputSourceRef)source;
        NSString *bundleID = (__bridge NSString *)TISGetInputSourceProperty(inputSource, kTISPropertyBundleID);
        NSString *mode = (NSString *)CFBridgingRelease(TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID));
        if (mode && [bundleID isEqualToString:inID]) {
            BOOL modeEnabled = [self enableInputSource:inputSource];
            if (!modeEnabled) {
                return NO;
            }

            enabled = YES;
        }
    }

    return enabled;
}

+ (BOOL)enableInputMode:(NSString *)modeID forInputSourceBundleID:(NSString *)bundleID
{
    for (id source in [self allInstalledInputSources]) {
        TISInputSourceRef inputSource = (__bridge TISInputSourceRef)source;
        NSString *inputSoureBundleID = (__bridge NSString *)TISGetInputSourceProperty(inputSource, kTISPropertyBundleID);
        NSString *inputSourceModeID = (NSString *)CFBridgingRelease(TISGetInputSourceProperty(inputSource, kTISPropertyInputModeID));

        if ([modeID isEqual:inputSourceModeID] && [bundleID isEqual:inputSoureBundleID]) {
            BOOL enabled = [self enableInputSource:inputSource];
            NSLog(@"Attempt to enable input source of mode: %@, bundle ID: %@, result: %d", modeID, bundleID, enabled);
            return enabled;
        }
    }

    NSLog(@"Failed to find any matching input source of mode: %@, bundle ID: %@", modeID, bundleID);
    return NO;
}

+ (BOOL)disableInputSource:(TISInputSourceRef)inInputSource
{
    OSStatus status = TISDisableInputSource(inInputSource);
    return status == noErr;
}

+ (BOOL)registerInputSource:(NSURL *)inBundleURL
{
    OSStatus status = TISRegisterInputSource((__bridge CFURLRef)inBundleURL);
    return status == noErr;
}
@end
