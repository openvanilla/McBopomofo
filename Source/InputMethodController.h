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

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "Mandarin.h"
#import "Gramambular.h"
#import "McBopomofoLM.h"
#import "UserOverrideModel.h"
#import "McBopomofo-Swift.h"

@interface McBopomofoInputMethodController : IMKInputController {
@private
    // the reading buffer that takes user input
    Formosa::Mandarin::BopomofoReadingBuffer *_bpmfReadingBuffer;

    // language model
    McBopomofo::McBopomofoLM *_languageModel;

    // user override model
    McBopomofo::UserOverrideModel *_userOverrideModel;

    // the grid (lattice) builder for the unigrams (and bigrams)
    Formosa::Gramambular::BlockReadingBuilder *_builder;

    // latest walked path (trellis) using the Viterbi algorithm
    std::vector<Formosa::Gramambular::NodeAnchor> _walkedNodes;
}

- (BOOL)handleInput:(KeyHandlerInput *)input
              state:(InputState *)state
      stateCallback:(void (^)(InputState *))stateCallback
candidateSelectionCallback:(void (^)(void))candidateSelectionCallback
        errorCallback:(void (^)(void))errorCallback;

- (void)handleState:(InputState *)newState client:(id)client;

@end
