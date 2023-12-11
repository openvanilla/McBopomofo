// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

#import "LanguageModelManager.h"
#import "LanguageModelManager+Privates.h"
#import "McBopomofo-Swift.h"

@import VXHanConvert;
@import OpenCCBridge;

static const int kUserOverrideModelCapacity = 500;
static const double kObservedOverrideHalflife = 5400.0; // 1.5 hr.

static McBopomofo::McBopomofoLM gLanguageModelMcBopomofo;
static McBopomofo::McBopomofoLM gLanguageModelPlainBopomofo;
static McBopomofo::UserOverrideModel gUserOverrideModel(kUserOverrideModelCapacity, kObservedOverrideHalflife);

static NSString *const kUserDataTemplateName = @"template-data";
static NSString *const kExcludedPhrasesMcBopomofoTemplateName = @"template-exclude-phrases";
static NSString *const kExcludedPhrasesPlainBopomofoTemplateName = @"template-exclude-phrases-plain-bpmf";
static NSString *const kPhraseReplacementTemplateName = @"template-phrases-replacement";
static NSString *const kTemplateExtension = @".txt";

@implementation LanguageModelManager

static void LTLoadLanguageModelFile(NSString *filenameWithoutExtension, McBopomofo::McBopomofoLM& lm)
{
    Class cls = NSClassFromString(@"McBopomofoInputMethodController");
    NSString *dataPath = [[NSBundle bundleForClass:cls] pathForResource:filenameWithoutExtension ofType:@"txt"];
    lm.loadLanguageModel([dataPath UTF8String]);
}

static void LTLoadAssociatedPhrases(McBopomofo::McBopomofoLM& lm)
{
    Class cls = NSClassFromString(@"McBopomofoInputMethodController");
    NSString *dataPath = [[NSBundle bundleForClass:cls] pathForResource:@"associated-phrases" ofType:@"txt"];
    lm.loadAssociatedPhrases([dataPath UTF8String]);
}

+ (void)loadDataModels
{
    if (!gLanguageModelMcBopomofo.isDataModelLoaded()) {
        LTLoadLanguageModelFile(@"data", gLanguageModelMcBopomofo);
    }
    if (!gLanguageModelPlainBopomofo.isDataModelLoaded()) {
        LTLoadLanguageModelFile(@"data-plain-bpmf", gLanguageModelPlainBopomofo);
    }
    if (!gLanguageModelPlainBopomofo.isAssociatedPhrasesLoaded()) {
        LTLoadAssociatedPhrases(gLanguageModelPlainBopomofo);
    }
}

+ (void)loadDataModel:(InputMode)mode
{
    if ([mode isEqualToString:InputModeBopomofo]) {
        if (!gLanguageModelMcBopomofo.isDataModelLoaded()) {
            LTLoadLanguageModelFile(@"data", gLanguageModelMcBopomofo);
        }
    }

    if ([mode isEqualToString:InputModePlainBopomofo]) {
        if (!gLanguageModelPlainBopomofo.isDataModelLoaded()) {
            LTLoadLanguageModelFile(@"data-plain-bpmf", gLanguageModelPlainBopomofo);
        }
        if (!gLanguageModelPlainBopomofo.isAssociatedPhrasesLoaded()) {
            LTLoadAssociatedPhrases(gLanguageModelPlainBopomofo);
        }
    }
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
    auto macroConverter = [](std::string input) {
        NSString *inputText = [NSString stringWithUTF8String:input.c_str()];
        NSString *handled = [[InputMacroController shared] handle:inputText];
        return std::string(handled.UTF8String);
    };

    auto converter = [](std::string input) {
        if (!Preferences.chineseConversionEnabled) {
            return input;
        }

        if (Preferences.chineseConversionStyle == 0) {
            return input;
        }

        NSString *text = [NSString stringWithUTF8String:input.c_str()];
        if (Preferences.chineseConversionEngine == 1) {
            text = [VXHanConvert convertToSimplifiedFrom:text];
        } else {
            text = [[OpenCCBridge sharedInstance] convertToSimplified:text];
        }
        return std::string(text.UTF8String);
    };

    gLanguageModelMcBopomofo.setMacroConverter(macroConverter);
    gLanguageModelMcBopomofo.setExternalConverter(converter);
    gLanguageModelPlainBopomofo.setExternalConverter(converter);
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

+ (BOOL)ensureFileExists:(NSString *)filePath populateWithTemplate:(NSString *)templateBasename extension:(NSString *)ext
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {

        NSURL *templateURL = [[NSBundle mainBundle] URLForResource:templateBasename withExtension:ext];
        NSData *templateData;
        if (templateURL) {
            templateData = [NSData dataWithContentsOfURL:templateURL];
        } else {
            templateData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
        }

        BOOL result = [templateData writeToFile:filePath atomically:YES];
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
    if (![self ensureFileExists:[self userPhrasesDataPathMcBopomofo] populateWithTemplate:kUserDataTemplateName extension:kTemplateExtension]) {
        return NO;
    }
    if (![self ensureFileExists:[self excludedPhrasesDataPathMcBopomofo] populateWithTemplate:kExcludedPhrasesMcBopomofoTemplateName extension:kTemplateExtension]) {
        return NO;
    }
    if (![self ensureFileExists:[self excludedPhrasesDataPathPlainBopomofo] populateWithTemplate:kExcludedPhrasesPlainBopomofoTemplateName extension:kTemplateExtension]) {
        return NO;
    }
    if (![self ensureFileExists:[self phraseReplacementDataPathMcBopomofo] populateWithTemplate:kPhraseReplacementTemplateName extension:kTemplateExtension]) {
        return NO;
    }
    return YES;
}

+ (BOOL)checkIfUserPhraseExist:(NSString *)userPhrase key:(NSString *)key NS_SWIFT_NAME(checkIfExist(userPhrase:key:))
{
    std::string unigramKey(key.UTF8String);
    auto unigrams = gLanguageModelMcBopomofo.getUnigrams(unigramKey);
    std::string userPhraseString(userPhrase.UTF8String);
    for (const auto& unigram : unigrams) {
        if (unigram.value() == userPhraseString) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)writeUserPhrase:(NSString *)userPhrase
{
    if (![self checkIfUserLanguageModelFilesExist]) {
        return NO;
    }

    BOOL addLineBreakAtFront = NO;
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
                    addLineBreakAtFront = YES;
                }
                [readFile closeFile];
            }
        }
    }

    NSMutableString *currentMarkedPhrase = [NSMutableString string];
    if (addLineBreakAtFront) {
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

    //  We use FSEventStream to monitor the change of the user phrase folder,
    //  so we don't have to load data here.
    //  [self loadUserPhrases];
    return YES;
}

+ (NSString *)dataFolderPath
{
    BOOL useCustomLocation = Preferences.useCustomUserPhraseLocation;
    if (!useCustomLocation) {
        return [UserPhraseLocationHelper defaultUserPhraseLocation];
    }
    return Preferences.customUserPhraseLocation;
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

+ (McBopomofo::McBopomofoLM *)languageModelMcBopomofo
{
    return &gLanguageModelMcBopomofo;
}

+ (McBopomofo::McBopomofoLM *)languageModelPlainBopomofo
{
    return &gLanguageModelPlainBopomofo;
}

+ (McBopomofo::UserOverrideModel *)userOverrideModel
{
    return &gUserOverrideModel;
}

+ (BOOL)phraseReplacementEnabled
{
    return gLanguageModelMcBopomofo.phraseReplacementEnabled();
}

+ (void)setPhraseReplacementEnabled:(BOOL)phraseReplacementEnabled
{
    gLanguageModelMcBopomofo.setPhraseReplacementEnabled(phraseReplacementEnabled);
}

+ (nullable NSString *)readingFor:(NSString *)phrase {
    if (!gLanguageModelMcBopomofo.isDataModelLoaded()) {
        [self loadDataModel:InputModeBopomofo];
    }
    
    std::string reading = gLanguageModelMcBopomofo.getReading(phrase.UTF8String);
    return !reading.empty() ? [NSString stringWithUTF8String:reading.c_str()] : nil;
}

@end
