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

#import "VXHanConvert.h"

const size_t vxSC2TCTableSize = 8189;
extern unsigned short vxSC2TCTable[];

const size_t vxTC2SCTableSize = 3059;
extern unsigned short vxTC2SCTable[];

struct VXHCData {
    unsigned short key, value;
};

int VXHCCompare(const void *a, const void *b)
{
    unsigned short x = ((const struct VXHCData *)a)->key, y = ((const struct VXHCData *)b)->key;
    if (x == y)
        return 0;
    if (x < y)
        return -1;
    return 1;
}

unsigned short VXHCFind(unsigned key, unsigned short *table, size_t size)
{
    struct VXHCData k;
    k.key = key;
    struct VXHCData *d = (struct VXHCData *)bsearch(&k, table, size, sizeof(struct VXHCData), VXHCCompare);
    if (!d)
        return 0;
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

static NSString *GetConvertedString(NSString *input, uint16_t (*filterFunction)(uint16_t))
{
    NSUInteger length = [input length];
    if (!length) {
        return input;
    }

    unichar *chars = (unichar *) calloc(length, sizeof(unichar));
    if (!chars) {
        return input;
    }

    for (NSUInteger i = 0; i < length; i++) {
        // -getCharacters:range: calls characterAtIndex: "correctly, though inefficiently"
        // according to the API doc; since we only care about the raw data (see below),
        // we just use characterAtIndex:.
        unichar ch = [input characterAtIndex:i];

        // Since the convert tables only deal with code points < U+FFFF,
        // even if this straddles a surrogate pair, this is still ok.
        unichar converted = filterFunction(ch);
        if (converted) {
            chars[i] = converted;
        } else {
            chars[i] = ch;
        }
    }

    NSString *output = [[NSString alloc] initWithCharacters:chars length:length];
    free(chars);
    return output;
}

@implementation VXHanConvert

+ (NSString *)convertToSimplifiedFrom:(NSString *)string NS_SWIFT_NAME(convertToSimplified(from:))
{
    return GetConvertedString(string, VXUCS2TradToSimpChinese);
}

+ (NSString *)convertToTraditionalFrom:(NSString *)string NS_SWIFT_NAME(convertToTraditional(from:))
{
    return GetConvertedString(string, VXUCS2SimpToTradChinese);
}

@end
