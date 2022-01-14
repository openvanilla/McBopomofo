#import "VXHanConvert.h"

const size_t vxSC2TCTableSize = 8189;
extern unsigned short vxSC2TCTable[];

const size_t vxTC2SCTableSize = 3059;
extern unsigned short vxTC2SCTable[];

struct VXHCData
{
    unsigned short key, value;
};

int VXHCCompare(const void *a, const void *b)
{
    unsigned short x=((const struct VXHCData*)a)->key, y=((const struct VXHCData*)b)->key;
    if (x==y) return 0;
    if (x<y) return -1;
    return 1;
}

unsigned short VXHCFind(unsigned key, unsigned short *table, size_t size)
{
    struct VXHCData k;
    k.key=key;
    struct VXHCData *d=(struct VXHCData*)bsearch(&k, table, size, sizeof(struct VXHCData), VXHCCompare);
    if (!d) return 0;
    return d->value;
}

unsigned short VXUCS2TradToSimpChinese(unsigned short c)
{
    return VXHCFind(c, vxTC2SCTable, vxTC2SCTableSize);
}

unsigned short VXUCS2SimpToTradChinese(unsigned short c)
{
    return VXHCFind(c, vxSC2TCTable, vxSC2TCTableSize);
}

@implementation VXHanConvert

+ (NSString *)convertToSimplifiedFrom:(NSString *)string NS_SWIFT_NAME(convertToSimplified(from:))
{
    NSData *utf16Data = [string dataUsingEncoding:NSUTF16StringEncoding];
    unsigned short * bytes = (unsigned short *)utf16Data.bytes;
    for(NSInteger i = 0; i < utf16Data.length; i++) {
        unsigned short c = bytes[i];
        unsigned short value = VXUCS2TradToSimpChinese(c);
        bytes[i] = value ? value : c;
    }

    return [[NSString alloc] initWithData:utf16Data encoding:NSUTF16StringEncoding];
}

+ (NSString *)convertToTraditionalFrom:(NSString *)string NS_SWIFT_NAME(convertToTraditional(from:))
{
    NSData *utf16Data = [string dataUsingEncoding:NSUTF16StringEncoding];
    unsigned short * bytes = (unsigned short *)utf16Data.bytes;
    for(NSInteger i = 0; i < utf16Data.length; i++) {
        unsigned short c = bytes[i];
        unsigned short value = VXUCS2SimpToTradChinese(c);
        bytes[i] = value ? value : c;
    }

    return [[NSString alloc] initWithData:utf16Data encoding:NSUTF16StringEncoding];
}

@end
