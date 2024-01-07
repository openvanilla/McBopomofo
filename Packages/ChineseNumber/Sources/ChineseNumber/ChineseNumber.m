#import "ChineseNumber.h"

const char *chinese_number(const char *int_part, const char *dec_part, bool use_formal);
extern const char *suzhou_number(const char *int_part, const char *dec_part, bool vertical_digit_at_start, const char *unit);

@implementation ChineseNumber

+ (NSString *)lowerNumberWithIntPart:(NSString *)intPart decPart:(NSString *)decPart
{
    const char *result = chinese_number (intPart.UTF8String, decPart.UTF8String, false);
    NSString *string = [[NSString alloc] initWithUTF8String:result];
    free ((void *) result);
    return string;
}

+ (NSString *)upperNumberWithIntPart:(NSString *)intPart decPart:(NSString *)decPart
{
    const char *result = chinese_number (intPart.UTF8String, decPart.UTF8String, true);
    NSString *string = [[NSString alloc] initWithUTF8String:result];
    free ((void *) result);
    return string;
}

+ (NSString *)suzhouNumberWithIntPart:(NSString *)intPart decPart:(NSString *)decPart
{
    const char *result = suzhou_number (intPart.UTF8String, decPart.UTF8String, true, (const char *) "[單位]");
    NSString *string = [[NSString alloc] initWithUTF8String:result];
    free ((void *) result);
    return string;
}

@end
