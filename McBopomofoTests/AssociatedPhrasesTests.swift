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

import XCTest

@testable import McBopomofo

class AssociatedPhrasesTests: XCTestCase {

    var handler = KeyHandler()
    var chineseConversionEnabled: Bool = false

    override func setUpWithError() throws {
        chineseConversionEnabled = Preferences.chineseConversionEnabled
        Preferences.chineseConversionEnabled = false
        LanguageModelManager.loadDataModels()
        handler = KeyHandler()
        handler.inputMode = .bopomofo
    }

    override func tearDownWithError() throws {
        Preferences.chineseConversionEnabled = chineseConversionEnabled
    }

    func testBuildingAssociatedPhrasesState() {
        var state: InputState = InputState.Empty()
        let keys = Array("u6").map {
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
                withPreviousState: state, prefixCursorAt: 1, reading: "ㄧ", value: "一",
                selectedCandidateIndex: 0, useVerticalMode: false, useShiftKey: false)
                as? InputState.AssociatedPhrases
        else {
            XCTFail("There should be an associated phrase state")
            return
        }
        XCTAssert(associatedPhrases.candidates.count > 0)
    }

    func testAssociatedPhrasesStatePunctuation1() {
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
                withPreviousState: state, prefixCursorAt: 1, reading: "_punctuation_{", value: "『",
                selectedCandidateIndex: 0, useVerticalMode: false, useShiftKey: false)
                as? InputState.AssociatedPhrases
        else {
            XCTFail("There should be an associated phrase state")
            return
        }
        XCTAssert(associatedPhrases.candidates.count > 0)
        let candidate = associatedPhrases.candidates[0]

        handler.fixNodeForAssociatedPhraseWithPrefix(
            at: associatedPhrases.prefixCursorIndex, prefixReading: associatedPhrases.prefixReading,
            prefixValue: associatedPhrases.prefixValue, associatedPhraseReading: candidate.reading,
            associatedPhraseValue: candidate.value)
        guard let inputting = handler.buildInputtingState() as? InputState.Inputting else {
            XCTFail("There should be an inputting state")
            return
        }
        XCTAssertTrue(inputting.composingBuffer == "『』")
    }

    func testAssociatedPhrasesStatePunctuation2() {
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
                withPreviousState: state, prefixCursorAt: 1, reading: "_punctuation_{", value: "《",
                selectedCandidateIndex: 0, useVerticalMode: false, useShiftKey: false)
                as? InputState.AssociatedPhrases
        else {
            XCTFail("There should be an associated phrase state")
            return
        }
        XCTAssert(associatedPhrases.candidates.count > 0)
        let candidate = associatedPhrases.candidates[0]

        handler.fixNodeForAssociatedPhraseWithPrefix(
            at: associatedPhrases.prefixCursorIndex, prefixReading: associatedPhrases.prefixReading,
            prefixValue: associatedPhrases.prefixValue, associatedPhraseReading: candidate.reading,
            associatedPhraseValue: candidate.value)
        guard let inputting = handler.buildInputtingState() as? InputState.Inputting else {
            XCTFail("There should be an inputting state")
            return
        }
        XCTAssertTrue(inputting.composingBuffer == "《》")
    }

}
