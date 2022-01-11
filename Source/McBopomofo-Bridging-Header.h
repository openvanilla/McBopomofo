//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

//extern void LTLoadLanguageModel(void);
//extern void LTLoadUserLanguageModelFile(void);

@import Foundation;

@interface LanguageModelManager : NSObject
+ (void)loadDataModels;
+ (void)loadUserPhrasesModel;
+ (BOOL)checkIfUserLanguageModelFilesExist;
@end
