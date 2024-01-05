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

#import <Foundation/Foundation.h>

@class KeyHandlerInput;
@class InputState;

NS_ASSUME_NONNULL_BEGIN

typedef NSString *const InputMode NS_TYPED_ENUM;
extern InputMode InputModeBopomofo;
extern InputMode InputModePlainBopomofo;

@class KeyHandler;

@protocol KeyHandlerDelegate <NSObject>
- (id)candidateControllerForKeyHandler:(KeyHandler *)keyHandler;
- (void)keyHandler:(KeyHandler *)keyHandler didSelectCandidateAtIndex:(NSInteger)index candidateController:(id)controller;
- (BOOL)keyHandler:(KeyHandler *)keyHandler didRequestWriteUserPhraseWithState:(InputState *)state;
@end

@interface AssociatedPhraseArrayItem : NSObject

+ (NSArray <AssociatedPhraseArrayItem *>*)createItemWithModelSearchableText:(NSString *)modelText readingSearchableText:(NSString *)readingText;

- (instancetype)initWithValue:(NSString *)character reading:(NSString *)reading;
@property (strong, nonatomic) NSString *value;
@property (strong, nonatomic) NSString *reading;
@end

@interface KeyHandler : NSObject

- (BOOL)handleInput:(KeyHandlerInput *)input
              state:(InputState *)state
      stateCallback:(void (^)(InputState *))stateCallback
      errorCallback:(void (^)(void))errorCallback NS_SWIFT_NAME(handle(input:state:stateCallback:errorCallback:));

- (void)syncWithPreferences;
- (void)fixNodeWithReading:(NSString *)reading value:(NSString *)value useMoveCursorAfterSelectionSetting:(BOOL)flag NS_SWIFT_NAME(fixNode(reading:value:useMoveCursorAfterSelectionSetting:));
- (void)fixNodeAtIndex:(NSInteger)index Reading:(NSString *)reading value:(NSString *)value associatedPhrase:(NSArray <AssociatedPhraseArrayItem *> *)associatedPhrase NS_SWIFT_NAME(fixNode(index:reading:value:associatedPhrase:));

- (void)clear;

- (void)handleForceCommitWithStateCallback:(void (^)(InputState *))stateCallback
    NS_SWIFT_NAME(handleForceCommit(stateCallback:));

- (InputState *)buildInputtingState;
- (nullable InputState *)buildAssociatePhrasePlainStateWithKey:(NSString *)key useVerticalMode:(BOOL)useVerticalMode;
- (nullable InputState *)buildAssociatePhraseStateWithPreviousState:(id)state selectedIndex:(NSInteger)index selectedPhrase:(NSString *)key selectedReading:(NSString *)selectedReading useVerticalMode:(BOOL)useVerticalMode;

@property (strong, nonatomic) InputMode inputMode;
@property (weak, nonatomic) id<KeyHandlerDelegate> delegate;
@property (assign, nonatomic, readonly) NSInteger actualCandidateCursorIndex;
@property (assign, nonatomic, readonly) NSInteger cursorIndex;
@end

NS_ASSUME_NONNULL_END
