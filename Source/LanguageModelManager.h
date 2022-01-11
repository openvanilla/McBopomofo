#import <Foundation/Foundation.h>
#import "FastLM.h"
#import "UserOverrideModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LanguageModelManager : NSObject

+ (void)loadDataModels;
+ (void)loadUserPhrasesModel;
+ (BOOL)checkIfUserLanguageModelFilesExist;
+ (BOOL)writeUserPhrase:(NSString *)userPhrase;

@property (class, readonly, nonatomic) NSString *dataFolderPath;
@property (class, readonly, nonatomic) NSString *userPhrasesDataPathMcBopomofo;
@property (class, readonly, nonatomic) NSString *excludedPhrasesDataPathMcBopomofo;
@property (class, readonly, nonatomic) NSString *excludedPhrasesDataPathPlainBopomofo;
@property (class, readonly, nonatomic) Formosa::Gramambular::FastLM *languageModelMcBopomofo;
@property (class, readonly, nonatomic) Formosa::Gramambular::FastLM *languageModelPlainBopomofo;
@property (class, readonly, nonatomic) Formosa::Gramambular::FastLM *userPhraseLanguageModel;
@property (class, readonly, nonatomic) Formosa::Gramambular::FastLM *excludedPhrasesLanguageModelMcBopomofo;
@property (class, readonly, nonatomic) Formosa::Gramambular::FastLM *excludedPhrasesLanguageModelPlainBopomofo;
@property (class, readonly, nonatomic) McBopomofo::UserOverrideModel *userOverrideModel;
@end

NS_ASSUME_NONNULL_END
