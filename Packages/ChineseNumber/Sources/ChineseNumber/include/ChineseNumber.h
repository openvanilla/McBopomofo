#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChineseNumber : NSObject

+ (NSString *)lowerNumberWithIntPart:(NSString *)intPart decPart:(NSString *)decPart;
+ (NSString *)upperNumberWithIntPart:(NSString *)intPart decPart:(NSString *)decPart;
+ (NSString *)suzhouNumberWithIntPart:(NSString *)intPart decPart:(NSString *)decPart;

@end

NS_ASSUME_NONNULL_END
