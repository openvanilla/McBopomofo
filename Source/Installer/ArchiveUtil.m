// Copyright (c) 2012 and onwards The McBopomofo Authors.
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

#import "ArchiveUtil.h"

@implementation ArchiveUtil
- (instancetype)initWithAppName:(NSString *)name
            targetAppBundleName:(NSString *)targetAppBundleName {
    self = [super init];
    if (self) {
        _appName = name;
        _targetAppBundleName = targetAppBundleName;
    }
    return self;
}

- (void)delloc {
    _appName = nil;
    _targetAppBundleName = nil;
}

- (BOOL)validateIfNotarizedArchiveExists {
    NSString *resourePath = [[NSBundle mainBundle] resourcePath];
    NSString *devModeAppBundlePath =
        [resourePath stringByAppendingPathComponent:_targetAppBundleName];

    NSArray<NSString *> *notarizedArchivesContent =
        [[NSFileManager defaultManager] subpathsAtPath:[self notarizedArchivesPath]];
    NSInteger count = [notarizedArchivesContent count];
    BOOL notarizedArchiveExists =
        [[NSFileManager defaultManager] fileExistsAtPath:[self notarizedArchive]];
    BOOL devModeAppBundleExists =
        [[NSFileManager defaultManager] fileExistsAtPath:devModeAppBundlePath];

    if (count > 0) {
        // Not a valid distribution package.
        if (count != 1 || !notarizedArchiveExists || devModeAppBundleExists) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setAlertStyle:NSAlertStyleInformational];
            [alert setMessageText:@"Internal Error"];
            [alert
                setInformativeText:
                    [NSString stringWithFormat:@"devMode installer, expected archive name: %@, "
                                               @"archive exists: %d, devMode app bundle exists: %d",
                                               [self notarizedArchive], notarizedArchiveExists,
                                               devModeAppBundleExists]];
            [alert addButtonWithTitle:@"Terminate"];
            [alert runModal];

            [[NSApplication sharedApplication] terminate:nil];
        } else {
            return YES;
        }
    }

    if (!devModeAppBundleExists) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert setMessageText:@"Internal Error"];
        [alert
            setInformativeText:[NSString stringWithFormat:@"Dev target bundle does not exist: %@",
                                                          devModeAppBundlePath]];
        [alert addButtonWithTitle:@"Terminate"];
        [alert runModal];
        [[NSApplication sharedApplication] terminate:nil];
    }

    // Notarized archive does not exist, but it's ok.
    return NO;
}

- (NSString *)unzipNotarizedArchive {
    if (![self validateIfNotarizedArchiveExists]) {
        return nil;
    }

    NSString *tempFilePath =
        [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    NSArray *arguments = @[ [self notarizedArchive], @"-d", tempFilePath ];

    NSTask *unzipTask = [[NSTask alloc] init];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    [unzipTask setArguments:arguments];
    [unzipTask launch];
    [unzipTask waitUntilExit];

    NSAssert(unzipTask.terminationStatus == 0, @"Must successfully unzipped");

    NSString *result = [tempFilePath stringByAppendingPathComponent:_targetAppBundleName];
    NSAssert([[NSFileManager defaultManager] fileExistsAtPath:result],
             @"App bundle must be unzipped at %@", result);
    return result;
}

- (NSString *)notarizedArchivesPath {
    NSString *resourePath = [[NSBundle mainBundle] resourcePath];
    NSString *notarizedArchivesPath =
        [resourePath stringByAppendingPathComponent:@"NotarizedArchives"];
    return notarizedArchivesPath;
}

- (NSString *)notarizedArchive {
    NSString *bundleVersion =
        [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
    NSString *notarizedArchiveBasename =
        [NSString stringWithFormat:@"%@-r%@.zip", _appName, bundleVersion];
    NSString *notarizedArchive =
        [[self notarizedArchivesPath] stringByAppendingPathComponent:notarizedArchiveBasename];
    return notarizedArchive;
}
@end
