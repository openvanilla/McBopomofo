#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The legacy chinese conversion library from OpenVanilla.
@interface VXHanConvert : NSObject

/// Converts to Simplified Chinese from Traditional Chinese.
/// @param string The traditional Chinese text.
+ (NSString *)convertToSimplifiedFrom:(NSString *)string NS_SWIFT_NAME(convertToSimplified(from:));

/// Convert to Traditional Chinese from Simplified CHinese.
/// @param string The Simplified Chinese text.
+ (NSString *)convertToTraditionalFrom:(NSString *)string NS_SWIFT_NAME(convertToTraditional(from:));

@end

NS_ASSUME_NONNULL_END
