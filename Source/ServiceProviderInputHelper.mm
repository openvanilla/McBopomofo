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

#import "ServiceProviderInputHelper.h"
#import "McBopomofo-Swift.h"
#import "McBopomofoLM.h"
#import "Mandarin.h"
#import "LanguageModelManager+Privates.h"

@interface ServiceProviderInputHelper()
{
    std::shared_ptr<Formosa::Gramambular2::LanguageModel> _emptySharedPtr;
    Formosa::Gramambular2::ReadingGrid *_grid;
}
@end

@interface ServiceProviderInputHelper(ServiceProviderDelegate) <ServiceProviderDelegate>
@end

@implementation ServiceProviderInputHelper

- (void)dealloc
{
    delete _grid;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        std::shared_ptr<Formosa::Gramambular2::LanguageModel> lm(_emptySharedPtr, [LanguageModelManager languageModelMcBopomofo]);
        _grid = new Formosa::Gramambular2::ReadingGrid(lm);
    }
    return self;
}

@end

@implementation ServiceProviderInputHelper(ServiceProviderDelegate)

- (void)reset
{
    _grid->clear();
}


- (void)serviceProvider:(ServiceProvider * _Nonnull)provider didRequestInsertReading:(NSString * _Nonnull)didRequestInsertReading 
{
    _grid->insertReading(didRequestInsertReading.UTF8String);
}

- (NSString * _Nonnull)serviceProviderDidRequestCommitting:(ServiceProvider * _Nonnull)provider 
{
    Formosa::Gramambular2::ReadingGrid::WalkResult _latestWalk = _grid->walk();
    std::string output;
    for (const auto& node : _latestWalk.nodes) {
        output += node->value();
    }
    [self reset];
    return [NSString stringWithUTF8String:output.c_str()];
}

- (void)serviceProviderDidRequestReset:(ServiceProvider * _Nonnull)provider
{
    [self reset];
}

- (NSString * _Nonnull)service:(ServiceProvider * _Nonnull)provider didRequestConvertReadintToHanyuPinyin:(NSString * _Nonnull)input
{
    std::string reading = std::string([input UTF8String]);
    Formosa::Mandarin::BopomofoSyllable syllable = Formosa::Mandarin::BopomofoSyllable::FromComposedString(reading);
    std::string hanyuPinyin = syllable.HanyuPinyinString(false, false);
    return [[NSString alloc] initWithUTF8String:hanyuPinyin.c_str()];
}

@end
