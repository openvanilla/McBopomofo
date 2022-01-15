#import <Foundation/Foundation.h>
#import "UserOverrideModel.h"
#import "McBopomofoLM.h"

NS_ASSUME_NONNULL_BEGIN

@interface LanguageModelManager : NSObject

+ (void)loadDataModels;
+ (void)loadUserPhrases;
+ (void)loadUserPhraseReplacement;
+ (void)setupDataModelValueConverter;
+ (BOOL)checkIfUserLanguageModelFilesExist;
+ (BOOL)writeUserPhrase:(NSString *)userPhrase;

@property (class, readonly, nonatomic) NSString *dataFolderPath;
@property (class, readonly, nonatomic) NSString *userPhrasesDataPathMcBopomofo;
@property (class, readonly, nonatomic) NSString *excludedPhrasesDataPathMcBopomofo;
@property (class, readonly, nonatomic) NSString *excludedPhrasesDataPathPlainBopomofo;
@property (class, readonly, nonatomic) NSString *phraseReplacementDataPathMcBopomofo;
@property (class, readonly, nonatomic) McBopomofo::McBopomofoLM *languageModelMcBopomofo;
@property (class, readonly, nonatomic) McBopomofo::McBopomofoLM *languageModelPlainBopomofo;
@property (class, readonly, nonatomic) McBopomofo::UserOverrideModel *userOverrideModel;
@end

NS_ASSUME_NONNULL_END
