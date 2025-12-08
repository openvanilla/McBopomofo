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

import CandidateUI
import XCTest

@testable import McBopomofo

func charCode(_ string: String) -> UInt16 {
    let scalars = string.unicodeScalars
    return UInt16(scalars[scalars.startIndex].value)
}

class KeyHandlerBopomofoTests: XCTestCase {
    var handler = KeyHandler()
    var chineseConversionEnabled: Bool  = false

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

    func testSyncWithPreferences() {
        let savedKeyboardLayout = Preferences.keyboardLayout
        Preferences.keyboardLayout = .standard
        handler.syncWithPreferences()

        Preferences.keyboardLayout = .eten
        handler.syncWithPreferences()

        Preferences.keyboardLayout = .hsu
        handler.syncWithPreferences()

        Preferences.keyboardLayout = .eten26
        handler.syncWithPreferences()

        Preferences.keyboardLayout = .hanyuPinyin
        handler.syncWithPreferences()

        Preferences.keyboardLayout = .IBM
        handler.syncWithPreferences()

        Preferences.keyboardLayout = savedKeyboardLayout
        handler.syncWithPreferences()
    }

    func testIgnoreEmpty() {
        let input = KeyHandlerInput(
            inputText: "", keyCode: 0, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreEnter() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.enter.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreUp() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.up.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result, "\(state)")
    }

    func testIgnoreDown() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result, "\(state)")
    }

    func testIgnoreLeft() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreRight() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnorePageUp() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.pageUp.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnorePageDown() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.pageDown.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreHome() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreEnd() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.end.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreDelete() {
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.delete.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreCommand() {
        let input = KeyHandlerInput(
            inputText: "A", keyCode: 0, charCode: 0, flags: .command, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreOption() {
        let input = KeyHandlerInput(
            inputText: "A", keyCode: 0, charCode: 0, flags: .option, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreNumericPad() {
        let input = KeyHandlerInput(
            inputText: "A", keyCode: 0, charCode: 0, flags: .numericPad, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreCapslock() {
        let input = KeyHandlerInput(
            inputText: "A", keyCode: 0, charCode: 0, flags: .capsLock, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testCapslock() {
        var input = KeyHandlerInput(
            inputText: "b", keyCode: 0, charCode: charCode("b"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        var count = 0

        input = KeyHandlerInput(
            inputText: "a", keyCode: 0, charCode: charCode("a"), flags: .capsLock,
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            if count == 1 {
                state = newState
            }
            count += 1
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Committing, "\(state)")
        if let state = state as? InputState.Committing {
            XCTAssertEqual(state.poppedText, "a")
        }
    }

    func testCapslockShift() {
        var input = KeyHandlerInput(
            inputText: "b", keyCode: 0, charCode: charCode("b"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        input = KeyHandlerInput(
            inputText: "a", keyCode: 0, charCode: charCode("a"), flags: [.capsLock, .shift],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Empty, "\(state)")
    }

    func testisNumericPad() {
        let current = Preferences.selectCandidateWithNumericKeypad
        Preferences.selectCandidateWithNumericKeypad = false
        defer {
            Preferences.selectCandidateWithNumericKeypad = current
        }

        var input = KeyHandlerInput(
            inputText: "b", keyCode: 0, charCode: charCode("b"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        input = KeyHandlerInput(
            inputText: "1", keyCode: 0, charCode: charCode("1"), flags: .numericPad,
            isVerticalMode: false)
        var count = 0
        var empty: InputState = InputState.Empty()
        var target: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            switch count {
            case 0:
                state = newState
            case 1:
                target = newState
            case 2:
                empty = newState
            default:
                break
            }
            count += 1

        } errorCallback: {
        }

        XCTAssertEqual(count, 3)
        XCTAssertTrue(state is InputState.Empty, "\(state)")
        XCTAssertTrue(empty is InputState.Empty, "\(empty)")
        XCTAssertTrue(target is InputState.Committing, "\(target)")
        if let state = target as? InputState.Committing {
            XCTAssertEqual(state.poppedText, "1")
        }
    }

    // Regression test for #292.
    func testUppercaseLetterWhenEmpty1() {
        let current = Preferences.letterBehavior
        Preferences.letterBehavior = 0
        defer {
            Preferences.letterBehavior = current
        }
        let input = KeyHandlerInput(
            inputText: "A", keyCode: KeyCode.enter.rawValue, charCode: charCode("A"), flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertFalse(result)
    }

    func testUppercaseLetterWhenEmpty2() {
        let current = Preferences.letterBehavior
        Preferences.letterBehavior = 1
        defer {
            Preferences.letterBehavior = current
        }

        let input = KeyHandlerInput(
            inputText: "A", keyCode: KeyCode.enter.rawValue, charCode: charCode("A"), flags: [],
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "a")
        }
    }

    // Regression test for #292.
    func testUppercaseLetterWhenNotEmpty1() {
        let current = Preferences.letterBehavior
        Preferences.letterBehavior = 0
        defer {
            Preferences.letterBehavior = current
        }

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

        let letterInput = KeyHandlerInput(
            inputText: "A", keyCode: 0, charCode: charCode("A"), flags: .shift,
            isVerticalMode: false)
        let result = handler.handle(input: letterInput, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertFalse(result)
    }

    // Regression test for #292.
    func testUppercaseLetterWhenNotEmpty2() {
        let current = Preferences.letterBehavior
        Preferences.letterBehavior = 1
        defer {
            Preferences.letterBehavior = current
        }

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

        let letterInput = KeyHandlerInput(
            inputText: "A", keyCode: 0, charCode: charCode("A"), flags: .shift,
            isVerticalMode: false)
        handler.handle(input: letterInput, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "一a")
        }
    }

    func testPunctuationTable() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false
        defer {
            Preferences.halfWidthPunctuationEnabled = enabled
        }

        let input = KeyHandlerInput(
            inputText: "`", keyCode: 0, charCode: charCode("`"), flags: .shift,
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertTrue(state.candidates.map { $0.value }.contains("，"))
        }
    }

    func testIgnorePunctuationTable() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false

        defer {
            Preferences.halfWidthPunctuationEnabled = enabled
        }

        var state: InputState = InputState.Empty()
        var input = KeyHandlerInput(
            inputText: "1", keyCode: 0, charCode: charCode("1"), flags: .shift,
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        input = KeyHandlerInput(
            inputText: "`", keyCode: 0, charCode: charCode("`"), flags: .shift,
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "ㄅ")
        }
    }

    func testHalfPunctuationComma() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = true
        defer {
            Preferences.halfWidthPunctuationEnabled = enabled
        }

        let input = KeyHandlerInput(
            inputText: "<", keyCode: 0, charCode: charCode("<"), flags: .shift,
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, ",")
        }
    }

    func testPunctuationComma() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false
        defer {
            Preferences.halfWidthPunctuationEnabled = enabled
        }
        let input = KeyHandlerInput(
            inputText: "<", keyCode: 0, charCode: charCode("<"), flags: .shift,
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "，")
        }
    }

    func testHalfPunctuationPeriod() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = true
        defer {
            Preferences.halfWidthPunctuationEnabled = enabled
        }
        let input = KeyHandlerInput(
            inputText: ">", keyCode: 0, charCode: charCode(">"), flags: .shift,
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, ".")
        }
    }

    func testPunctuationPeriod() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false
        defer {
            Preferences.halfWidthPunctuationEnabled = enabled
        }

        let input = KeyHandlerInput(
            inputText: ">", keyCode: 0, charCode: charCode(">"), flags: .shift,
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "。")
        }
    }

    func testCtrlPunctuationPeriod() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false
        defer {
            Preferences.halfWidthPunctuationEnabled = enabled
        }

        let input = KeyHandlerInput(
            inputText: ".", keyCode: 0, charCode: charCode("."), flags: .control,
            isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "。")
        }
    }

    func testInvalidBpmf() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        let keepReadingUponCompositionError = Preferences.keepReadingUponCompositionError
        Preferences.associatedPhrasesEnabled = false
        Preferences.keepReadingUponCompositionError = false
        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
            Preferences.keepReadingUponCompositionError = keepReadingUponCompositionError
        }

        var state: InputState = InputState.Empty()
        let keys = Array("ni4").map {
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
        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testInputting() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false

        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("vul3a945j4up gj bj4z83").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "小麥注音輸入法")
        }
    }

    func testInputtingNihao() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false
        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
        }
    }

    func testInputtingTianKong() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false
        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("wu0 dj/ ").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "天空")
        }
    }

    func testCommittingNihao() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false
        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
        }

        let enter = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [], isVerticalMode: false)
        var committing: InputState?
        var empty: InputState?
        var count = 0

        handler.handle(input: enter, state: state) { newState in
            switch count {
            case 0:
                committing = newState
            case 1:
                empty = newState
            default:
                break
            }
            count += 1
        } errorCallback: {
        }

        XCTAssertTrue(committing is InputState.Committing, "\(state)")
        if let committing = committing as? InputState.Committing {
            XCTAssertEqual(committing.poppedText, "你好")
        }
        XCTAssertTrue(empty is InputState.Empty, "\(state)")
    }

    func testDelete() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false
        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        let left = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        let delete = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.delete.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var errorCalled = false

        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(input: delete, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(input: delete, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCalled = true
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }
        XCTAssertTrue(errorCalled)

        errorCalled = false

        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 0)
        }

        handler.handle(input: delete, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testBackspaceToDeleteReading() {
        var state: InputState = InputState.Empty()
        let keys = Array("su").map {
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

        let backspace = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)

        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "ㄋ")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testBackspaceAtBegin() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false
        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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

        let left = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }

        let backspace = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)
        var errorCall = false
        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCall = true
        }
        XCTAssertTrue(errorCall)
    }

    func testBackspaceToDeleteReadingWithText() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl").map {
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

        let backspace = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)

        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你ㄏ")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }
    }

    func testBackspace() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false
        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        let backspace = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)

        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")

    }

    func testCursorWithReading() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl").map {
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
        let left = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        let right = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var leftErrorCalled = false
        var rightErrorCalled = false

        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
            leftErrorCalled = true
        }

        handler.handle(input: right, state: state) { newState in
            state = newState
        } errorCallback: {
            rightErrorCalled = true
        }

        XCTAssertTrue(leftErrorCalled)
        XCTAssertTrue(rightErrorCalled)
    }

    func testCursor() {

        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        let left = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        let right = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        var errorCalled = false

        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }

        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCalled = true
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }
        XCTAssertTrue(errorCalled)

        handler.handle(input: right, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(input: right, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        errorCalled = false
        handler.handle(input: right, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCalled = true
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }
        XCTAssertTrue(errorCalled)
        Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
    }

    func testCandidateWithDown() {
        var state: InputState = InputState.Empty()
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        let selectPhraseAfterCursorAsCandidate = Preferences.selectPhraseAfterCursorAsCandidate
        let moveCursorAfterSelectingCandidate = Preferences.moveCursorAfterSelectingCandidate
        Preferences.associatedPhrasesEnabled = false
        Preferences.selectPhraseAfterCursorAsCandidate = false
        Preferences.moveCursorAfterSelectingCandidate = false

        defer {
            Preferences.selectPhraseAfterCursorAsCandidate = selectPhraseAfterCursorAsCandidate
            Preferences.moveCursorAfterSelectingCandidate = moveCursorAfterSelectingCandidate
        }

        let keys = Array("su3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        let down = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        handler.handle(input: down, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
            let candidates = state.candidates
            XCTAssertTrue(candidates.map { $0.value }.contains("你"))
        }

        Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
    }

    func testCandidateWithSpace() {
        let enabled = Preferences.chooseCandidateUsingSpace
        let selectPhraseAfterCursorAsCandidate = Preferences.selectPhraseAfterCursorAsCandidate
        let moveCursorAfterSelectingCandidate = Preferences.moveCursorAfterSelectingCandidate
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.chooseCandidateUsingSpace = true
        Preferences.selectPhraseAfterCursorAsCandidate = false
        Preferences.moveCursorAfterSelectingCandidate = false
        Preferences.associatedPhrasesEnabled = false
        defer {
            Preferences.chooseCandidateUsingSpace = enabled
            Preferences.selectPhraseAfterCursorAsCandidate = selectPhraseAfterCursorAsCandidate
            Preferences.moveCursorAfterSelectingCandidate = moveCursorAfterSelectingCandidate
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        let space = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 32, flags: [], isVerticalMode: false)
        handler.handle(input: space, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
            let candidates = state.candidates
            XCTAssertTrue(candidates.map { $0.value }.contains("你"))
        }

    }

    func testInputSpace() {
        let enabled = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = false
        defer {
            Preferences.chooseCandidateUsingSpace = enabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
        }

        var count = 0
        var target: InputState = InputState.Empty()
        var empty: InputState = InputState.Empty()

        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 32, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            switch count {
            case 0:
                state = newState
            case 1:
                target = newState
            case 2:
                empty = newState
            default:
                break
            }
            count += 1
        } errorCallback: {
        }

        XCTAssertEqual(count, 3)
        XCTAssertTrue(state is InputState.Committing, "\(state)")
        if let state = state as? InputState.Committing {
            XCTAssertEqual(state.poppedText, "你")
        }
        XCTAssertTrue(target is InputState.Committing, "\(target)")
        if let target = target as? InputState.Committing {
            XCTAssertEqual(target.poppedText, " ")
        }
        XCTAssertTrue(empty is InputState.Empty, "\(empty)")
    }

    func testInputSpaceInBetween() {
        let enabled = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = false
        defer {
            Preferences.chooseCandidateUsingSpace = enabled
        }
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
        }

        var input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 32, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你 好")
        }
    }

    func testHomeAndEnd() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        let home = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        let end = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.end.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        handler.handle(input: home, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }

        var homeErrorCalled = false
        handler.handle(input: home, state: state) { newState in
            state = newState
        } errorCallback: {
            homeErrorCalled = true
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }
        XCTAssertTrue(homeErrorCalled)

        handler.handle(input: end, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        var endErrorCalled = false
        handler.handle(input: end, state: state) { newState in
            state = newState
        } errorCallback: {
            endErrorCalled = true
        }

        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }
        XCTAssertTrue(endErrorCalled)
    }

    func testHomeAndEndWithReading() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你ㄏㄠ")
            XCTAssertEqual(state.cursorIndex, 3)
        }

        let home = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        let end = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.end.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        var homeErrorCalled = false
        var endErrorCalled = false

        handler.handle(input: home, state: state) { newState in
            state = newState
        } errorCallback: {
            homeErrorCalled = true
        }

        XCTAssertTrue(homeErrorCalled)
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你ㄏㄠ")
            XCTAssertEqual(state.cursorIndex, 3)
        }

        handler.handle(input: end, state: state) { newState in
            state = newState
        } errorCallback: {
            endErrorCalled = true
        }

        XCTAssertTrue(endErrorCalled)
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你ㄏㄠ")
            XCTAssertEqual(state.cursorIndex, 3)
        }
    }

    func testMarkingLeftAtBegin() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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

        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        var errorCalled = false

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCalled = true
        }
        XCTAssertTrue(errorCalled)
    }

    func testMarkingRightAtEnd() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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

        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        var errorCalled = false
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCalled = true
        }
        XCTAssertTrue(errorCalled)
    }

    func testMarkingLeft() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        var input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Marking, "\(state)")
        if let state = state as? InputState.Marking {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
            XCTAssertEqual(state.markerIndex, 1)
            XCTAssertEqual(state.markedRange, NSRange(location: 1, length: 1))
        }

        input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Marking, "\(state)")
        if let state = state as? InputState.Marking {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
            XCTAssertEqual(state.markerIndex, 0)
            XCTAssertEqual(state.markedRange, NSRange(location: 0, length: 2))
        }

        var stateForGoingRight: InputState = state

        let right = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        handler.handle(input: right, state: stateForGoingRight) { newState in
            stateForGoingRight = newState
        } errorCallback: {
        }
        handler.handle(input: right, state: stateForGoingRight) { newState in
            stateForGoingRight = newState
        } errorCallback: {
        }

        XCTAssertTrue(stateForGoingRight is InputState.Inputting, "\(stateForGoingRight)")
    }

    func testMarkingRight() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        let left = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        let errorInput = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        var errorCalled = false
        handler.handle(input: errorInput, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCalled = true
        }
        XCTAssertTrue(errorCalled)

        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Marking, "\(state)")
        if let state = state as? InputState.Marking {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
            XCTAssertEqual(state.markerIndex, 1)
            XCTAssertEqual(state.markedRange, NSRange(location: 0, length: 1))
        }

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Marking, "\(state)")
        if let state = state as? InputState.Marking {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
            XCTAssertEqual(state.markerIndex, 2)
            XCTAssertEqual(state.markedRange, NSRange(location: 0, length: 2))
        }

        var stateForGoingLeft: InputState = state

        handler.handle(input: left, state: stateForGoingLeft) { newState in
            stateForGoingLeft = newState
        } errorCallback: {
        }
        handler.handle(input: left, state: stateForGoingLeft) { newState in
            stateForGoingLeft = newState
        } errorCallback: {
        }

        XCTAssertTrue(stateForGoingLeft is InputState.Inputting, "\(stateForGoingLeft)")
    }

    func testCancelMarking() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        var input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift,
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Marking, "\(state)")
        if let state = state as? InputState.Marking {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
            XCTAssertEqual(state.markerIndex, 1)
            XCTAssertEqual(state.markedRange, NSRange(location: 1, length: 1))
        }

        input = KeyHandlerInput(
            inputText: "1", keyCode: 0, charCode: charCode("1"), flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好ㄅ")
        }
    }

    func testEscToClearReadingAndGoToEmpty() {
        let enabled = Preferences.escToCleanInputBuffer
        Preferences.escToCleanInputBuffer = false
        defer {
            Preferences.escToCleanInputBuffer = enabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "ㄋㄧ")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testEscToClearReadingAndGoToInputting() {
        let enabled = Preferences.escToCleanInputBuffer
        Preferences.escToCleanInputBuffer = false
        defer {
            Preferences.escToCleanInputBuffer = enabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你ㄏㄠ")
            XCTAssertEqual(state.cursorIndex, 3)
        }

        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }
    }

    func testEscToClearAll() {
        let enabled = Preferences.escToCleanInputBuffer
        Preferences.escToCleanInputBuffer = true
        defer {
            Preferences.escToCleanInputBuffer = enabled
        }

        var state: InputState = InputState.Empty()
        let keys = Array("su3cl").map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你ㄏㄠ")
            XCTAssertEqual(state.cursorIndex, 3)
        }

        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testEscKey() {
        var state: InputState = InputState.Empty()
        let keys = Array("w8").map {
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [],
            isVerticalMode: false)

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState)
    }

    func testEscKeyWithCandidate() {
        var state: InputState = InputState.Empty()
        let keys = Array("w8 ").map {
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
        let down = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        handler.handle(input: down, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.ChoosingCandidate)

        let esc = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [],
            isVerticalMode: false)

        handler.handle(input: esc, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting)
    }

    func testHomeKey() {
        var state: InputState = InputState.Empty()
        let keys = Array("w8 ").map {
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting)
        if let state = state as? InputState.Inputting {
            XCTAssertTrue(state.cursorIndex == 0)
        }
    }

    func testHomeAndEndKey() {
        var state: InputState = InputState.Empty()
        let keys = Array("w8 ").map {
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
        let home = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        handler.handle(input: home, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        let end = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.end.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        handler.handle(input: end, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting)
        if let state = state as? InputState.Inputting {
            XCTAssertTrue(state.cursorIndex == 1)
        }
    }

    func testTabKey() {
        var state: InputState = InputState.Empty()
        let keys = Array("w8 ").map {
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.tab.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting)
    }

    func testMacroAndTabKey() {
        var state: InputState = InputState.Empty()
        // 今天
        let keys = Array("rup wu0 ").map {
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.tab.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting)
    }

    func testLookUpCandidateInDictionaryAndCancelWithTabKey() {
        var state: InputState = InputState.Empty()
        let keys = Array("wu0 dj/ ").map {
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
        var input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        input = KeyHandlerInput(
            inputText: "?", keyCode: 0, charCode: 0, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssert(state is InputState.SelectingDictionary)

        input = KeyHandlerInput(
            inputText: "?", keyCode: 0, charCode: 0, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssert(state is InputState.ChoosingCandidate)
    }

    func testLookUpCandidateInDictionaryAndCancelWithEscKey() {
        var state: InputState = InputState.Empty()
        let keys = Array("wu0 dj/ ").map {
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
        var input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        input = KeyHandlerInput(
            inputText: "?", keyCode: 0, charCode: 0, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssert(state is InputState.SelectingDictionary)

        input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssert(state is InputState.ChoosingCandidate)
    }

}

extension KeyHandlerBopomofoTests {
    func testSelectingFeature() {
        var state: InputState = InputState.Empty()
        let input = KeyHandlerInput(
            inputText: "\\", keyCode: 42, charCode: charCode("\\"), flags: [.control],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.SelectingFeature)
    }
}

extension KeyHandlerBopomofoTests {
    func testEnterBig5() {
        let big5InputEnabled = Preferences.big5InputEnabled
        Preferences.big5InputEnabled = true
        var state: InputState = InputState.Big5(code: "")

        let input = KeyHandlerInput(
            inputText: "`", keyCode: 0, charCode: charCode("`"), flags: [.control],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.Big5)
        Preferences.big5InputEnabled = big5InputEnabled
    }

    func testBig5Input() {
        var state: InputState = InputState.Big5(code: "")
        var commitState: InputState?
        XCTAssert(state is InputState.Big5)
        let keys = Array("a143").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(
                inputText: key, keyCode: 0, charCode: charCode(key), flags: [],
                isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
                if newState is InputState.Committing {
                    commitState = newState
                }
            } errorCallback: {
            }
        }
        XCTAssert(state is InputState.Empty)
        XCTAssert(commitState is InputState.Committing)
        if let commitState = commitState as? InputState.Committing {
            XCTAssertTrue(commitState.poppedText == "。")
        }
    }

    func testBig5Cancel() {
        var state: InputState = InputState.Big5(code: "")
        XCTAssert(state is InputState.Big5)
        let keys = Array("a14").map {
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.Empty)
    }

    func testBig5Delete() {
        var state: InputState = InputState.Big5(code: "")
        XCTAssert(state is InputState.Big5)
        let keys = Array("a14").map {
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: KeyCode.delete.rawValue, charCode: 0, flags: [],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.Big5)
        if let state = state as? InputState.Big5 {
            XCTAssertTrue(state.code == "A1")
        }
    }

}

extension KeyHandlerBopomofoTests {
    func testCtrlEnter1() {
        let controlEnterOutput = Preferences.controlEnterOutput
        Preferences.controlEnterOutput = .bpmfReading
        var state: InputState = InputState.Empty()
        var commitState: InputState?
        let keys = Array("su3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(
                inputText: key, keyCode: 0, charCode: charCode(key), flags: [],
                isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
                if newState is InputState.Committing {
                    commitState = newState
                }
            } errorCallback: {
            }
        }
        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [.control],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
            if newState is InputState.Committing {
                commitState = newState
            }
        } errorCallback: {
        }

        XCTAssert(state is InputState.Empty)
        XCTAssert(commitState is InputState.Committing)
        if let commitState = commitState as? InputState.Committing {
            XCTAssertTrue(commitState.poppedText == "ㄋㄧˇ")
        }
        Preferences.controlEnterOutput = controlEnterOutput
    }

    func testCtrlEnter2() {
        let controlEnterOutput = Preferences.controlEnterOutput
        Preferences.controlEnterOutput = .htmlRuby
        var state: InputState = InputState.Empty()
        var commitState: InputState?
        let keys = Array("su3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(
                inputText: key, keyCode: 0, charCode: charCode(key), flags: [],
                isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
                if newState is InputState.Committing {
                    commitState = newState
                }
            } errorCallback: {
            }
        }
        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [.control],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
            if newState is InputState.Committing {
                commitState = newState
            }
        } errorCallback: {
        }

        XCTAssert(state is InputState.Empty)
        XCTAssert(commitState is InputState.Committing)
        if let commitState = commitState as? InputState.Committing {
            XCTAssertTrue(
                commitState.poppedText == "<ruby>你<rp>(</rp><rt>ㄋㄧˇ</rt><rp>)</rp></ruby>")
        }
        Preferences.controlEnterOutput = controlEnterOutput
    }

    func testCtrlEnter3() {
        let controlEnterOutput = Preferences.controlEnterOutput
        Preferences.controlEnterOutput = .braille
        var state: InputState = InputState.Empty()
        var commitState: InputState?
        let keys = Array("su3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(
                inputText: key, keyCode: 0, charCode: charCode(key), flags: [],
                isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
                if newState is InputState.Committing {
                    commitState = newState
                }
            } errorCallback: {
            }
        }
        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [.control],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
            if newState is InputState.Committing {
                commitState = newState
            }
        } errorCallback: {
        }

        XCTAssert(state is InputState.Empty)
        XCTAssert(commitState is InputState.Committing)
        if let commitState = commitState as? InputState.Committing {
            XCTAssertTrue(commitState.poppedText == "⠝⠡⠈")
        }
        Preferences.controlEnterOutput = controlEnterOutput
    }
}


extension KeyHandlerBopomofoTests {
    func testEnterAssocatedPhrases() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = true
        var state: InputState = InputState.Empty()
        let keys = Array("5j/ cj86").map {
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [.shift],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.AssociatedPhrases)
        if let state = state as? InputState.AssociatedPhrases {
            XCTAssert(state.composingBuffer == "中華")
            XCTAssert(state.prefixReading == "ㄓㄨㄥ-ㄏㄨㄚˊ")
            XCTAssert(state.candidate(at: 0) == "民國")
        }

        Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
    }

    func testEnterAssocatedPunctuaton() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = true
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
        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [.shift],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.AssociatedPhrases)
        if let state = state as? InputState.AssociatedPhrases {
            XCTAssert(state.composingBuffer == "『")
            XCTAssert(state.prefixReading == "_punctuation_{")
            XCTAssert(state.candidate(at: 0) == "』")
        }

        Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
    }

    func testCancelAssocatedPhrases() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = true
        var state: InputState = InputState.Empty()
        let keys = Array("5j/ cj86").map {
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
        let shiftEnter = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [.shift],
            isVerticalMode: false)
        handler.handle(input: shiftEnter, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        let input = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssert(state is InputState.Inputting)
        if let state = state as? InputState.Inputting {
            XCTAssert(state.composingBuffer == "中華")
        }
        Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
    }

    func testSelectAssocatedPhrases() {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = false
        var state: InputState = InputState.Empty()
        let keys = Array("5j/ cj86").map {
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
        let shitEnter = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [.shift],
            isVerticalMode: false)
        handler.handle(input: shitEnter, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.AssociatedPhrases)
        let input = KeyHandlerInput(
            inputText: "1", keyCode: 0, charCode: charCode("1"), flags: [.shift],
            isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssert(state is InputState.AssociatedPhrases)
        guard let associatedPhrasesState = state as? InputState.AssociatedPhrases else {
            XCTFail()
            return
        }
        handler.fixNodeForAssociatedPhraseWithPrefix(
            at: Int(associatedPhrasesState.cursorIndex),
            prefixReading: associatedPhrasesState.prefixReading,
            prefixValue: associatedPhrasesState.prefixValue,
            associatedPhraseReading: associatedPhrasesState.candidates[0].reading,
            associatedPhraseValue: associatedPhrasesState.candidates[0].value)
        let finalState = handler.buildInputtingState()
        XCTAssert(finalState is InputState.Inputting)
        if let finalState = finalState as? InputState.Inputting {
            XCTAssertTrue(finalState.composingBuffer == "中華民國")
        }
        Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
    }
}

extension KeyHandlerBopomofoTests {
    func testForceCommit() {
        var state: InputState = InputState.Empty()
        let keys = Array("5j/ cj86").map {
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
        handler.handleForceCommit { newState in
            state = newState
        }
        XCTAssertTrue(state is InputState.Committing)
        if let state = state as? InputState.Committing {
            XCTAssertTrue(state.poppedText == "中華")
        }
    }
}

extension KeyHandlerBopomofoTests {
    func testNumberTypingAndCommitWithEnter() {
        var state: InputState = InputState.Number(number: "", candidates: [])
        for ch in Array("12345") {
            let s = String(ch)
            let input = KeyHandlerInput(
                inputText: s, keyCode: 0, charCode: charCode(s), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {}
        }
        XCTAssertTrue(state is InputState.Number, "\(state)")
        if let numberState = state as? InputState.Number {
            XCTAssertEqual(numberState.number, "12345")
            XCTAssertTrue(numberState.composingBuffer.hasSuffix("12345"))
        }

        var committing: InputState?
        var empty: InputState?
        var count = 0
        let enter = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 13, flags: [], isVerticalMode: false)
        handler.handle(input: enter, state: state) { newState in
            switch count {
            case 0: committing = newState
            case 1: empty = newState
            default: break
            }
            count += 1
        } errorCallback: {}

        XCTAssertEqual(count, 2)
        XCTAssertTrue(committing is InputState.Committing, "\(String(describing: committing))")
        if let committing = committing as? InputState.Committing {
            XCTAssertEqual(committing.poppedText, "一萬二千三百四十五")
        }
        XCTAssertTrue(empty is InputState.Empty, "\(String(describing: empty))")
    }

    func testNumberBackspaceAndEsc() {
        var state: InputState = InputState.Number(number: "123", candidates: [])
        let backspace = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)
        handler.handle(input: backspace, state: state) { newState in
            state = newState
        } errorCallback: {}
        XCTAssertTrue(state is InputState.Number, "\(state)")
        if let numberState = state as? InputState.Number {
            XCTAssertEqual(numberState.number, "12")
        }

        let esc = KeyHandlerInput(
            inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: esc, state: state) { newState in
            state = newState
        } errorCallback: {}
        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState || state is InputState.Empty, "\(state)")
    }

    func testNumberIgnoresNonDigit() {
        var state: InputState = InputState.Number(number: "9", candidates: [])
        let letter = KeyHandlerInput(
            inputText: "a", keyCode: 0, charCode: charCode("a"), flags: [], isVerticalMode: false)
        let _ = handler.handle(input: letter, state: state) { newState in
            state = newState
        } errorCallback: {}
        // Expect still Number with unchanged buffer
        XCTAssertTrue(state is InputState.Number, "\(state)")
        if let numberState = state as? InputState.Number {
            XCTAssertEqual(numberState.number, "9")
        }
    }

    func testNumberChineseCandidates() {
        var state: InputState = InputState.Number(number: "", candidates: [])
        let keys = Array("123").map { String($0) }
        for ch in keys {
            let input = KeyHandlerInput(
                inputText: ch, keyCode: 0, charCode: charCode(ch), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {}
        }
        XCTAssertTrue(state is InputState.Number, "\(state)")
        if let numberState = state as? InputState.Number {
            XCTAssertEqual(numberState.number, "123")
            XCTAssertTrue(numberState.candidates.contains("一百二十三"))
            XCTAssertTrue(numberState.candidates.contains("壹佰貳拾參"))
            XCTAssertTrue(numberState.candidates.contains("CXXIII")) // Roman numeral for 123
        }
    }

    func testNumberDecimalPointAndChineseCandidates() {
        var state: InputState = InputState.Number(number: "", candidates: [])
        let keys = Array("12.34").map { String($0) }
        for ch in keys {
            let input = KeyHandlerInput(
                inputText: ch, keyCode: 0, charCode: charCode(ch), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {}
        }
        XCTAssertTrue(state is InputState.Number, "\(state)")
        if let numberState = state as? InputState.Number {
            XCTAssertEqual(numberState.number, "12.34")
            XCTAssertTrue(numberState.candidates.contains("一十二點三四"))
            XCTAssertTrue(numberState.candidates.contains("壹拾貳點參肆"))
            XCTAssertFalse(numberState.candidates.contains("XII.XXXIV")) // Roman numerals should not be present for decimals
        }
    }

    func testNumberRomanCandidatesOutOfRange() {
        var state: InputState = InputState.Number(number: "", candidates: [])
        let keys = Array("4000").map { String($0) } // Max Roman is 3999
        for ch in keys {
            let input = KeyHandlerInput(
                inputText: ch, keyCode: 0, charCode: charCode(ch), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {}
        }
        XCTAssertTrue(state is InputState.Number, "\(state)")
        if let numberState = state as? InputState.Number {
            XCTAssertEqual(numberState.number, "4000")
            XCTAssertTrue(numberState.candidates.contains("四千"))
            XCTAssertTrue(numberState.candidates.contains("肆仟"))
            XCTAssertFalse(numberState.candidates.contains("MMMM")) // Should not contain Roman numeral
        }
    }
}

extension KeyHandlerBopomofoTests {

    func checkChangingReadingUsingToneKey(input: String, expected: String) {
        let associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        let allowChangingPriorTone = Preferences.allowChangingPriorTone
        Preferences.associatedPhrasesEnabled = false
        Preferences.allowChangingPriorTone = true

        defer {
            Preferences.associatedPhrasesEnabled = associatedPhrasesEnabled
            Preferences.allowChangingPriorTone = allowChangingPriorTone
        }

        var state: InputState = InputState.Empty()
        let keys = Array(input).map {
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
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, expected)
        }
    }

    // Input 小麥 then change to tone 3
    func testChangingReadingUsingToneKey1() {
        checkChangingReadingUsingToneKey(input: "vul3a943", expected: "小買")
    }

    // Input 小麥 then change to tone 4
    func testChangingReadingUsingToneKey2() {
        checkChangingReadingUsingToneKey(input: "vul3a946", expected: "小埋")
    }

    // Input 小麥 then change to tone 5
    func testChangingReadingUsingToneKey3() {
        checkChangingReadingUsingToneKey(input: "vul3a947", expected: "小麥˙")
    }
}
