#import "ServiceProviderInputHelper.h"
#import "McBopomofo-Swift.h"
#import "McBopomofoLM.h"
#import "LanguageModelManager+Privates.h"

@interface ServiceProviderInputHelper()
{
    std::shared_ptr<Formosa::Gramambular2::LanguageModel> _emptySharedPtr;
    Formosa::Gramambular2::ReadingGrid *_grid;
    Formosa::Gramambular2::ReadingGrid::WalkResult _latestWalk;
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
        _latestWalk = Formosa::Gramambular2::ReadingGrid::WalkResult {};
    }
    return self;
}

@end

@implementation ServiceProviderInputHelper(ServiceProviderDelegate)


- (void)serviceProvider:(ServiceProvider * _Nonnull)provider didRequestInsertReading:(NSString * _Nonnull)didRequestInsertReading 
{
    _grid->insertReading(didRequestInsertReading.UTF8String);
    _latestWalk = _grid->walk();
}

- (NSString * _Nonnull)serviceProviderDidRequestCommitting:(ServiceProvider * _Nonnull)provider 
{
    std::string output;
    for (const auto& node : _latestWalk.nodes) {
        output += node->value();
    }
    _grid->clear();
    _latestWalk = Formosa::Gramambular2::ReadingGrid::WalkResult {};
    return [NSString stringWithUTF8String:output.c_str()];
}

@end
