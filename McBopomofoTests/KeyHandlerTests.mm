#import <XCTest/XCTest.h>
#import "KeyHandler.h"
#import "LanguageModelManager.h"
#import "McBopomofoTests-Swift.h"

@interface KeyHandlerTests : XCTestCase

@end

@implementation KeyHandlerTests

- (void)setUp
{
    [LanguageModelManager loadDataModels];
}

- (void)tearDown
{
}

- (void)testInputtingNihaoUsingMcBopomofo
{
    KeyHandler *handler = [[KeyHandler alloc] init];
    handler.inputMode = kBopomofoModeIdentifier;

    KeyHandlerInput *input;
    __block InputState *state;
    state = [[InputStateEmpty alloc] init];

    input = [[KeyHandlerInput alloc] initWithInputText:@"s" keyCode:0 charCode:'s' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"u" keyCode:0 charCode:'u' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"3" keyCode:0 charCode:'3' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"c" keyCode:0 charCode:'c' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"l" keyCode:0 charCode:'l' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"3" keyCode:0 charCode:'3' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    XCTAssertTrue([state isKindOfClass:NSClassFromString(@"McBopomofo.InputStateInputting")], @"It should be an inputting state %@.", NSStringFromClass([state class]));
    NSString *composingBuffer = [(InputStateInputting *)state composingBuffer];
    XCTAssertTrue([composingBuffer isEqualToString:@"你好"], @"It should be 你好 but %@", composingBuffer);
}

- (void)testComittingNihaoUsingMcBopomofo
{
    KeyHandler *handler = [[KeyHandler alloc] init];
    handler.inputMode = kBopomofoModeIdentifier;

    KeyHandlerInput *input;
    __block InputState *state;
    state = [[InputStateEmpty alloc] init];

    input = [[KeyHandlerInput alloc] initWithInputText:@"s" keyCode:0 charCode:'s' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"u" keyCode:0 charCode:'u' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"3" keyCode:0 charCode:'3' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"c" keyCode:0 charCode:'c' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"l" keyCode:0 charCode:'l' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"3" keyCode:0 charCode:'3' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    __block NSInteger count = 0;

    __block InputState *empty;

    input = [[KeyHandlerInput alloc] initWithInputText:@" " keyCode:0 charCode:13 flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        if (!count) {
            state = inState;
        }
        empty = inState;
        count++;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    XCTAssertTrue([state isKindOfClass:NSClassFromString(@"McBopomofo.InputStateCommitting")], @"It should be a committing state %@.", NSStringFromClass([state class]));
    NSString *poppedText = [(InputStateCommitting *)state poppedText];
    XCTAssertTrue([poppedText isEqualToString:@"你好"], @"It should be 你好 but %@", poppedText);

    XCTAssertTrue([empty isKindOfClass:NSClassFromString(@"McBopomofo.InputStateEmpty")], @"It should be an empty state %@.", NSStringFromClass([state class]));
}


- (void)testBackspaceUsingMcBopomofo
{
    KeyHandler *handler = [[KeyHandler alloc] init];
    handler.inputMode = kBopomofoModeIdentifier;

    KeyHandlerInput *input;
    __block InputState *state;
    state = [[InputStateEmpty alloc] init];

    input = [[KeyHandlerInput alloc] initWithInputText:@"s" keyCode:0 charCode:'s' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"u" keyCode:0 charCode:'u' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"3" keyCode:0 charCode:'3' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"c" keyCode:0 charCode:'c' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"l" keyCode:0 charCode:'l' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    input = [[KeyHandlerInput alloc] initWithInputText:@"3" keyCode:0 charCode:'3' flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    XCTAssertTrue([state isKindOfClass:NSClassFromString(@"McBopomofo.InputStateInputting")], @"It should be an inputting state %@.", NSStringFromClass([state class]));
    NSString *composingBuffer = [(InputStateInputting *)state composingBuffer];
    XCTAssertTrue([composingBuffer isEqualToString:@"你好"], @"It should be 你好 but %@", composingBuffer);

    input = [[KeyHandlerInput alloc] initWithInputText:@" " keyCode:0 charCode:8 flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        state = (InputStateInputting *)inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    XCTAssertTrue([state isKindOfClass:NSClassFromString(@"McBopomofo.InputStateInputting")], @"It should be a inputting state %@.", NSStringFromClass([state class]));
    composingBuffer = [(InputStateInputting *)state composingBuffer];
    XCTAssertTrue([composingBuffer isEqualToString:@"你"], @"It should be 你 but %@", composingBuffer);

    __block InputStateEmpty *empty;

    input = [[KeyHandlerInput alloc] initWithInputText:@" " keyCode:0 charCode:8 flags:0 isVerticalMode:0];
    [handler handleInput:input state:state stateCallback:^(InputState * inState) {
        empty = (InputStateEmpty *)inState;
    } candidateSelectionCallback:^{
    } errorCallback:^{
    }];

    XCTAssertTrue([empty isKindOfClass:NSClassFromString(@"McBopomofo.InputStateEmptyIgnoringPreviousState")], @"It should be a inputting state %@.", NSStringFromClass([state class]));
}

@end

