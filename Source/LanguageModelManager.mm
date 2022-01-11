#import "LanguageModelManager.h"
#import <fstream>
#import <iostream>
#import <set>
#import "OVStringHelper.h"
#import "OVUTF8Helper.h"

using namespace std;
using namespace Formosa::Gramambular;
using namespace OpenVanilla;

static const int kUserOverrideModelCapacity = 500;
static const double kObservedOverrideHalflife = 5400.0;  // 1.5 hr.

FastLM globalLanguageModel;
FastLM globalLanguageModelPlainBopomofo;
FastLM globalUserPhraseLanguageModel;
McBopomofo::UserOverrideModel globalUserOverrideModel(kUserOverrideModelCapacity, kObservedOverrideHalflife);

@implementation LanguageModelManager

static bool LTLoadLanguageModelFile(NSString *filenameWithoutExtension, FastLM &lm)
{
    Class cls = NSClassFromString(@"McBopomofoInputMethodController");
    NSString *dataPath = [[NSBundle bundleForClass:cls] pathForResource:filenameWithoutExtension ofType:@"txt"];
    bool result = lm.open([dataPath UTF8String]);
    return (BOOL)result;
}

+ (void)loadDataModels
{
    bool dataOpenResult = LTLoadLanguageModelFile(@"data", globalLanguageModel);
    if (!dataOpenResult) {
        NSLog(@"Failed to open language model.");
    }
    bool plainBpmfOpenResult = LTLoadLanguageModelFile(@"data-plain-bpmf", globalLanguageModelPlainBopomofo);
    if (!plainBpmfOpenResult) {
        NSLog(@"Failed to open language model for plain bpmf.");
    }
}

+ (void)loadUserPhrasesModel
{
    globalUserPhraseLanguageModel.close();
    bool result = globalUserPhraseLanguageModel.open([[self userPhrasesDataPath] UTF8String]);
    if (!result) {
        NSLog(@"Failed to open user phrases.");
    }
}

+ (BOOL)checkIfUserLanguageModelFileExists
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

    NSString *filePath = [self userPhrasesDataPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL result = [[@"" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:filePath atomically:YES];
        if (!result) {
            NSLog(@"Failed to write file");
            return NO;
        }
    }
    return YES;
}

+ (BOOL)writeUserPhrase:(NSString *)userPhrase
{
    if (![self checkIfUserLanguageModelFileExists]) {
        return NO;
    }

    NSString *currentMarkedPhrase = [userPhrase stringByAppendingString:@"\n"];

    NSString *path = [self userPhrasesDataPath];
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

+ (NSString *)userPhrasesDataPath
{
    return [[self dataFolderPath] stringByAppendingPathComponent:@"data.txt"];
}

 + (Formosa::Gramambular::FastLM *)languageModelMcBopomofo
{
    return &globalLanguageModel;
}

+ (Formosa::Gramambular::FastLM *)languageModelPlainBopomofo
{
    return &globalLanguageModelPlainBopomofo;
}

+ (Formosa::Gramambular::FastLM *)userPhraseLanguageModel
{
    return &globalUserPhraseLanguageModel;
}

+ (McBopomofo::UserOverrideModel *)userOverrideModel
{
    return &globalUserOverrideModel;
}

@end
