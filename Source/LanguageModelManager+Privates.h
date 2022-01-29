#import "LanguageModelManager.h"
#import "UserOverrideModel.h"
#import "McBopomofoLM.h"

NS_ASSUME_NONNULL_BEGIN

@interface LanguageModelManager ()
@property (class, readonly, nonatomic) McBopomofo::McBopomofoLM *languageModelMcBopomofo;
@property (class, readonly, nonatomic) McBopomofo::McBopomofoLM *languageModelPlainBopomofo;
@property (class, readonly, nonatomic) McBopomofo::UserOverrideModel *userOverrideModel;
@end

NS_ASSUME_NONNULL_END
