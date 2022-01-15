#import "LanguageModelManager.h"
#import <fstream>
#import <iostream>
#import <set>
#import "OVStringHelper.h"
#import "OVUTF8Helper.h"
#import "McBopomofo-Swift.h"

@import VXHanConvert;
@import OpenCCBridge;

using namespace std;
using namespace Formosa::Gramambular;
using namespace McBopomofo;
using namespace OpenVanilla;

static const int kUserOverrideModelCapacity = 500;
static const double kObservedOverrideHalflife = 5400.0;  // 1.5 hr.

McBopomofoLM gLanguageModelMcBopomofo;
McBopomofoLM gLanguageModelPlainBopomofo;
UserOverrideModel gUserOverrideModel(kUserOverrideModelCapacity, kObservedOverrideHalflife);

@implementation LanguageModelManager

static void LTLoadLanguageModelFile(NSString *filenameWithoutExtension, McBopomofoLM &lm)
{
    Class cls = NSClassFromString(@"McBopomofoInputMethodController");
    NSString *dataPath = [[NSBundle bundleForClass:cls] pathForResource:filenameWithoutExtension ofType:@"txt"];
    lm.loadLanguageModel([dataPath UTF8String]);
}

+ (void)loadDataModels
{
    LTLoadLanguageModelFile(@"data", gLanguageModelMcBopomofo);
    LTLoadLanguageModelFile(@"data-plain-bpmf", gLanguageModelPlainBopomofo);
}

+ (void)loadUserPhrases
{
    gLanguageModelMcBopomofo.loadUserPhrases([[self userPhrasesDataPathMcBopomofo] UTF8String], [[self excludedPhrasesDataPathMcBopomofo] UTF8String]);
    gLanguageModelPlainBopomofo.loadUserPhrases(NULL, [[self excludedPhrasesDataPathPlainBopomofo] UTF8String]);
}

+ (void)loadUserPhraseReplacement
{
    gLanguageModelMcBopomofo.loadPhraseReplacementMap([[self phraseReplacementDataPathMcBopomofo] UTF8String]);
}

+ (void)setupDataModelValueConverter
{
    auto converter = [] (string input) {
        if (!Preferences.chineseConversionEnabled) {
            return input;
        }

        if (Preferences.chineseConversionStyle == 0) {
            return input;
        }

        NSString *text = [NSString stringWithUTF8String:input.c_str()];
        if (Preferences.chineneConversionEngine == 1) {
            text = [VXHanConvert convertToSimplifiedFrom:text];
        }
        else {
            text = [OpenCCBridge convertToSimplified:text];
        }
        return string(text.UTF8String);
    };

    gLanguageModelMcBopomofo.setExternalConvrter(converter);
    gLanguageModelPlainBopomofo.setExternalConvrter(converter);
}

+ (BOOL)checkIfUserDataFolderExists
{
    NSString *folderPath = [self dataFolderPath];
    BOOL isFolder = NO;
    BOOL folderExist = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isFolder];
    if (folderExist && !isFolder) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:folderPath error:&error];
        if (error) {
            NSLog(@"Failed to remove folder %@", error);
            return NO;
        }
        folderExist = NO;
    }
    if (!folderExist) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Failed to create folder %@", error);
            return NO;
        }
    }
    return YES;
}

+ (BOOL)checkIfFileExist:(NSString *)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL result = [[@"" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:YES];
        if (!result) {
            NSLog(@"Failed to write file");
            return NO;
        }
    }
    return YES;
}

+ (BOOL)checkIfUserLanguageModelFilesExist
{
    if (![self checkIfUserDataFolderExists]) {
        return NO;
    }
    if (![self checkIfFileExist:[self userPhrasesDataPathMcBopomofo]]) {
        return NO;
    }
    if (![self checkIfFileExist:[self excludedPhrasesDataPathMcBopomofo]]) {
        return NO;
    }
    if (![self checkIfFileExist:[self excludedPhrasesDataPathPlainBopomofo]]) {
        return NO;
    }
    if (![self checkIfFileExist:[self phraseReplacementDataPathMcBopomofo]]) {
        return NO;
    }
    return YES;
}

+ (BOOL)writeUserPhrase:(NSString *)userPhrase
{
    if (![self checkIfUserLanguageModelFilesExist]) {
        return NO;
    }

    BOOL shuoldAddLineBreakAtFront = NO;
    NSString *path = [self userPhrasesDataPathMcBopomofo];

    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        unsigned long long fileSize = [attr fileSize];
        if (!error && fileSize) {
            NSFileHandle *readFile = [NSFileHandle fileHandleForReadingAtPath:path];
            if (readFile) {
                [readFile seekToFileOffset:fileSize - 1];
                NSData *data = [readFile readDataToEndOfFile];
                const void *bytes = [data bytes];
                if (*(char *)bytes != '\n') {
                    shuoldAddLineBreakAtFront = YES;
                }
                [readFile closeFile];
            }
        }
    }

    NSMutableString *currentMarkedPhrase = [NSMutableString string];
    if (shuoldAddLineBreakAtFront) {
        [currentMarkedPhrase appendString:@"\n"];
    }
    [currentMarkedPhrase appendString:userPhrase];
    [currentMarkedPhrase appendString:@"\n"];

    NSFileHandle *writeFile = [NSFileHandle fileHandleForUpdatingAtPath:path];
    if (!writeFile) {
        return NO;
    }
    [writeFile seekToEndOfFile];
    NSData *data = [currentMarkedPhrase dataUsingEncoding:NSUTF8StringEncoding];
    [writeFile writeData:data];
    [writeFile closeFile];

    [self loadUserPhrases];
    return YES;
}

+ (NSString *)dataFolderPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDirectory, YES);
    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *userDictPath = [appSupportPath stringByAppendingPathComponent:@"McBopomofo"];
    return userDictPath;
}

+ (NSString *)userPhrasesDataPathMcBopomofo
{
    return [[self dataFolderPath] stringByAppendingPathComponent:@"data.txt"];
}

+ (NSString *)excludedPhrasesDataPathMcBopomofo
{
    return [[self dataFolderPath] stringByAppendingPathComponent:@"exclude-phrases.txt"];
}

+ (NSString *)excludedPhrasesDataPathPlainBopomofo
{
    return [[self dataFolderPath] stringByAppendingPathComponent:@"exclude-phrases-plain-bpmf.txt"];
}

+ (NSString *)phraseReplacementDataPathMcBopomofo
{
    return [[self dataFolderPath] stringByAppendingPathComponent:@"phrases-replacement.txt"];
}

 + (McBopomofoLM *)languageModelMcBopomofo
{
    return &gLanguageModelMcBopomofo;
}

+ (McBopomofoLM *)languageModelPlainBopomofo
{
    return &gLanguageModelPlainBopomofo;
}

+ (McBopomofo::UserOverrideModel *)userOverrideModel
{
    return &gUserOverrideModel;
}

@end
