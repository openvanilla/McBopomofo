// Copyright (c) 2011 and onwards The McBopomofo Authors.
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
#import <string>
@import CandidateUI;

@class KeyHandlerInput;
@class InputState;
@class InputStateInputting;
@class InputStateMarking;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kBopomofoModeIdentifier;
extern NSString *const kPlainBopomofoModeIdentifier;

@class KeyHandler;

@protocol KeyHandlerDelegate <NSObject>
- (VTCandidateController *)candidateControllerForKeyHandler:(KeyHandler *)keyHandler;
- (void)keyHandler:(KeyHandler *)keyHandler didSelectCandidateAtIndex:(NSInteger)index candidateController:(VTCandidateController *)controller;
- (BOOL)keyHandler:(KeyHandler *)keyHandler didRequestWriteUserPhraseWithState:(InputStateMarking *)state;
@end

@interface KeyHandler : NSObject

- (BOOL)handleInput:(KeyHandlerInput *)input
              state:(InputState *)state
      stateCallback:(void (^)(InputState *))stateCallback
candidateSelectionCallback:(void (^)(void))candidateSelectionCallback
      errorCallback:(void (^)(void))errorCallback;

- (void)syncWithPreferences;
- (void)fixNodeWithValue:(std::string)value;
- (void)clear;

- (InputStateInputting *)_buildInputtingState;

@property (strong, nonatomic) NSString *inputMode;
@property (weak, nonatomic) id <KeyHandlerDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
