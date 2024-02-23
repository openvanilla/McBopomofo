#import "ServiceProviderInputHelper.h"
#import "McBopomofo-Swift.h"
#import "McBopomofoLM.h"
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


@end
