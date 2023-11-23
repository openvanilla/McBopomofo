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

func charCode(_ string: String) -> UInt16 {
    let scalars = string.unicodeScalars
    return UInt16(scalars[scalars.startIndex].value)
}

class KeyHandlerBopomofoTests: XCTestCase {
    var handler = KeyHandler()

    override func setUpWithError() throws {
        LanguageModelManager.loadDataModels()
        handler = KeyHandler()
        handler.inputMode = .bopomofo
    }

    override func tearDownWithError() throws {
    }

    func testIgnoreEmpty() {
        let input = KeyHandlerInput(inputText: "", keyCode: 0, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreEnter() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.enter.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreUp() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.up.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result, "\(state)")
    }

    func testIgnoreDown() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result, "\(state)")
    }

    func testIgnoreLeft() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreRight() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnorePageUp() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.pageUp.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnorePageDown() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.pageDown.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreHome() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreEnd() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.end.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreDelete() {
        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.delete.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreCommand() {
        let input = KeyHandlerInput(inputText: "A", keyCode: 0, charCode: 0, flags: .command, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreOption() {
        let input = KeyHandlerInput(inputText: "A", keyCode: 0, charCode: 0, flags: .option, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreNumericPad() {
        let input = KeyHandlerInput(inputText: "A", keyCode: 0, charCode: 0, flags: .numericPad, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testIgnoreCapslock() {
        let input = KeyHandlerInput(inputText: "A", keyCode: 0, charCode: 0, flags: .capsLock, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertFalse(result)
    }

    func testCapslock() {
        var input = KeyHandlerInput(inputText: "b", keyCode: 0, charCode: charCode("b"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        var count = 0

        input = KeyHandlerInput(inputText: "a", keyCode: 0, charCode: charCode("a"), flags: .capsLock, isVerticalMode: false)
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
        var input = KeyHandlerInput(inputText: "b", keyCode: 0, charCode: charCode("b"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        input = KeyHandlerInput(inputText: "a", keyCode: 0, charCode: charCode("a"), flags: [.capsLock, .shift], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Empty, "\(state)")
    }

    func testisNumericPad() {
        let current = Preferences.selectCandidateWithNumericKeypad
        Preferences.selectCandidateWithNumericKeypad = false

        var input = KeyHandlerInput(inputText: "b", keyCode: 0, charCode: charCode("b"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        input = KeyHandlerInput(inputText: "1", keyCode: 0, charCode: charCode("1"), flags: .numericPad, isVerticalMode: false)
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

        Preferences.selectCandidateWithNumericKeypad = current

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
        let input = KeyHandlerInput(inputText: "A", keyCode: KeyCode.enter.rawValue, charCode: charCode("A"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        let result = handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        Preferences.letterBehavior = current
        XCTAssertFalse(result)
    }

    func testUppercaseLetterWhenEmpty2() {
        let current = Preferences.letterBehavior
        Preferences.letterBehavior = 1
        let input = KeyHandlerInput(inputText: "A", keyCode: KeyCode.enter.rawValue, charCode: charCode("A"), flags: [], isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        Preferences.letterBehavior = current

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "a")
        }
    }

    // Regression test for #292.
    func testUppercaseLetterWhenNotEmpty1() {
        let current = Preferences.letterBehavior
        Preferences.letterBehavior = 0
        var state: InputState = InputState.Empty()
        let keys = Array("u6").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }

        let letterInput = KeyHandlerInput(inputText: "A", keyCode: 0, charCode: charCode("A"), flags: .shift, isVerticalMode: false)
        let result = handler.handle(input: letterInput, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        Preferences.letterBehavior = current
        XCTAssertFalse(result)
    }

    // Regression test for #292.
    func testUppercaseLetterWhenNotEmpty2() {
        let current = Preferences.letterBehavior
        Preferences.letterBehavior = 1
        var state: InputState = InputState.Empty()
        let keys = Array("u6").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }

        let letterInput = KeyHandlerInput(inputText: "A", keyCode: 0, charCode: charCode("A"), flags: .shift, isVerticalMode: false)
        handler.handle(input: letterInput, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        Preferences.letterBehavior = current

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "一a")
        }
    }

    func testPunctuationTable() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false
        let input = KeyHandlerInput(inputText: "`", keyCode: 0, charCode: charCode("`"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertTrue(state.candidates.map { $0.value }.contains("，"))
        }
        Preferences.halfWidthPunctuationEnabled = enabled
    }

    func testIgnorePunctuationTable() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false
        var state: InputState = InputState.Empty()
        var input = KeyHandlerInput(inputText: "1", keyCode: 0, charCode: charCode("1"), flags: .shift, isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        input = KeyHandlerInput(inputText: "`", keyCode: 0, charCode: charCode("`"), flags: .shift, isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }


        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "ㄅ")
        }
        Preferences.halfWidthPunctuationEnabled = enabled
    }


    func testHalfPunctuationComma() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = true
        let input = KeyHandlerInput(inputText: "<", keyCode: 0, charCode: charCode("<"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, ",")
        }
        Preferences.halfWidthPunctuationEnabled = enabled
    }


    func testPunctuationComma() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false
        let input = KeyHandlerInput(inputText: "<", keyCode: 0, charCode: charCode("<"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "，")
        }
        Preferences.halfWidthPunctuationEnabled = enabled
    }

    func testHalfPunctuationPeriod() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = true
        let input = KeyHandlerInput(inputText: ">", keyCode: 0, charCode: charCode(">"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, ".")
        }
        Preferences.halfWidthPunctuationEnabled = enabled
    }

    func testPunctuationPeriod() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false

        let input = KeyHandlerInput(inputText: ">", keyCode: 0, charCode: charCode(">"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "。")
        }
        Preferences.halfWidthPunctuationEnabled = enabled
    }

    func testCtrlPunctuationPeriod() {
        let enabled = Preferences.halfWidthPunctuationEnabled
        Preferences.halfWidthPunctuationEnabled = false

        let input = KeyHandlerInput(inputText: ".", keyCode: 0, charCode: charCode("."), flags: .control, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "。")
        }
        Preferences.halfWidthPunctuationEnabled = enabled
    }

    func testInvalidBpmf() {
        var state: InputState = InputState.Empty()
        let keys = Array("ni4").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }
        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testInputting() {
        var state: InputState = InputState.Empty()
        let keys = Array("vul3a945j4up gj bj4z83").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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
        var state: InputState = InputState.Empty()
        let keys = Array("wu0 dj/ ").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
        }

        let enter = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 13, flags: [], isVerticalMode: false)
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
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let left = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        let delete = KeyHandlerInput(inputText: " ", keyCode: KeyCode.delete.rawValue, charCode: 0, flags: [], isVerticalMode: false)
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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }

        let backspace = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)

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
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }

        let left = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [], isVerticalMode: false)
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

        let backspace = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)
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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }

        let backspace = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)

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
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let backspace = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)

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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }
        let left = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        let right = KeyHandlerInput(inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: [], isVerticalMode: false)
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
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let left = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        let right = KeyHandlerInput(inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: [], isVerticalMode: false)

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
    }

    func testCandidateWithDown() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let down = KeyHandlerInput(inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [], isVerticalMode: false)
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
    }

    func testCandidateWithSpace() {
        let enabled = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = true
        var state: InputState = InputState.Empty()
        let keys = Array("su3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let space = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 32, flags: [], isVerticalMode: false)
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
        Preferences.chooseCandidateUsingSpace = enabled
    }

    func testInputSpace() {
        let enabled = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = false
        var state: InputState = InputState.Empty()
        let keys = Array("su3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let input = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 32, flags: [], isVerticalMode: false)
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
        Preferences.chooseCandidateUsingSpace = enabled
    }

    func testInputSpaceInBetween() {
        let enabled = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = false
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
        }

        var input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        input = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 32, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你 好")
        }
        Preferences.chooseCandidateUsingSpace = enabled
    }

    func testHomeAndEnd() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let home = KeyHandlerInput(inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        let end = KeyHandlerInput(inputText: " ", keyCode: KeyCode.end.rawValue, charCode: 0, flags: [], isVerticalMode: false)

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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let home = KeyHandlerInput(inputText: " ", keyCode: KeyCode.home.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        let end = KeyHandlerInput(inputText: " ", keyCode: KeyCode.end.rawValue, charCode: 0, flags: [], isVerticalMode: false)
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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }

        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input: input, state: state) { newState in
                state = newState
            } errorCallback: {
            }
        }

        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        var input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
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

        input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
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

        let right = KeyHandlerInput(inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let left = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }
        handler.handle(input: left, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        let errorInput = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
        var errorCalled = false
        handler.handle(input: errorInput, state: state) { newState in
            state = newState
        } errorCallback: {
            errorCalled = true
        }
        XCTAssertTrue(errorCalled)


        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.right.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
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
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        var input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.left.rawValue, charCode: 0, flags: .shift, isVerticalMode: false)
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

        input = KeyHandlerInput(inputText: "1", keyCode: 0, charCode: charCode("1"), flags: [], isVerticalMode: false)
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
        var state: InputState = InputState.Empty()
        let keys = Array("su").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let input = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
        Preferences.escToCleanInputBuffer = enabled
    }

    func testEscToClearReadingAndGoToInputting() {
        let enabled = Preferences.escToCleanInputBuffer
        Preferences.escToCleanInputBuffer = false
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let input = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }
        Preferences.escToCleanInputBuffer = enabled
    }


    func testEscToClearAll() {
        let enabled = Preferences.escToCleanInputBuffer
        Preferences.escToCleanInputBuffer = true
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl").map {
            String($0)
        }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
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

        let input = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input: input, state: state) { newState in
            state = newState
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
        Preferences.escToCleanInputBuffer = enabled
    }

}
