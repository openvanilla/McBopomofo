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

import Testing

@testable import McBopomofo

@Suite("Associated Phrases Testing")
final class AssociatedPhrasesTests {

    var handler = KeyHandler()
    var chineseConversionEnabled: Bool = false

    init() async throws {
        chineseConversionEnabled = Preferences.chineseConversionEnabled
        Preferences.chineseConversionEnabled = false
        LanguageModelManager.loadDataModels()
        handler = KeyHandler()
        handler.inputMode = .bopomofo
    }

    deinit {
        Preferences.chineseConversionEnabled = chineseConversionEnabled
    }

    @Test(
        "Test building an associated phrase from characters",
        arguments: [
            ("u6", "ㄧ", "一")
        ])
    func testBuildingAssociatedPhrasesState(keySequence: String, reading: String, value: String) {
        var state: InputState = InputState.Empty()
        let keys = Array(keySequence).map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(
                inputText: key, keyCode: 0, charCode: charCode(key), flags: [],
                isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }
        guard
            let associatedPhrases = handler.buildAssociatedPhraseState(
                withPreviousState: state, prefixCursorAt: 1, reading: reading, value: value,
                selectedCandidateIndex: 0, useVerticalMode: false, useShiftKey: false)
                as? InputState.AssociatedPhrases
        else {
            Issue.record("There should be an associated phrase state")
            return
        }
        #expect(associatedPhrases.candidates.count > 0)
    }

    @Test(
        "Test building an associated phrase from punctuations",
        arguments: [
            ("『", "『』"),
            ("《", "《》"),
        ])
    func testAssociatedPhrasesStatePunctuation1(input: String, result: String) {
        var state: InputState = InputState.Empty()
        let keys = Array("{").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(
                inputText: key, keyCode: 0, charCode: charCode(key), flags: [],
                isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }
        guard
            let associatedPhrases = handler.buildAssociatedPhraseState(
                withPreviousState: state, prefixCursorAt: 1, reading: "_punctuation_{",
                value: input,
                selectedCandidateIndex: 0, useVerticalMode: false, useShiftKey: false)
                as? InputState.AssociatedPhrases
        else {
            Issue.record("There should be an associated phrase state")
            return
        }
        #expect(associatedPhrases.candidates.count > 0)
        let candidate = associatedPhrases.candidates[0]

        handler.fixNodeForAssociatedPhraseWithPrefix(
            at: associatedPhrases.prefixCursorIndex, prefixReading: associatedPhrases.prefixReading,
            prefixValue: associatedPhrases.prefixValue, associatedPhraseReading: candidate.reading,
            associatedPhraseValue: candidate.value)
        guard let inputting = handler.buildInputtingState() as? InputState.Inputting else {
            Issue.record("There should be an inputting state")
            return
        }
        #expect(inputting.composingBuffer == result)
    }

}
