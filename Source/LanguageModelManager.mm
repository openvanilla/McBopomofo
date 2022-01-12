#import "LanguageModelManager.h"
#import <fstream>
#import <iostream>
#import <set>
#import "OVStringHelper.h"
#import "OVUTF8Helper.h"

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

+ (void)loadUserPhrasesModel
{
    gLanguageModelMcBopomofo.loadUserPhrases([[self userPhrasesDataPathMcBopomofo] UTF8String], [[self excludedPhrasesDataPathMcBopomofo] UTF8String]);
    gLanguageModelPlainBopomofo.loadUserPhrases("", [[self excludedPhrasesDataPathPlainBopomofo] UTF8String]);
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
    return YES;
}

+ (BOOL)writeUserPhrase:(NSString *)userPhrase
{
    if (![self checkIfUserLanguageModelFilesExist]) {
        return NO;
    }

    NSString *currentMarkedPhrase = [userPhrase stringByAppendingString:@"\n"];

    NSString *path = [self userPhrasesDataPathMcBopomofo];
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:path];
    if (!file) {
        return NO;
    }
    [file seekToEndOfFile];
    NSData *data = [currentMarkedPhrase dataUsingEncoding:NSUTF8StringEncoding];
    [file writeData:data];
    [file closeFile];

    [self loadUserPhrasesModel];
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
