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
        handler.inputMode = kBopomofoModeIdentifier
    }

    override func tearDownWithError() throws {
    }

    func testPunctuationComma() {
        let input = KeyHandlerInput(inputText: "<", keyCode: 0, charCode: charCode("<"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "，")
        }
    }

    func testPunctuationPeriod() {
        let input = KeyHandlerInput(inputText: ">", keyCode: 0, charCode: charCode(">"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "。")
        }
    }

    func testInputting() {
        var state: InputState = InputState.Empty()
        let keys = Array("vul3a945j4up gj bj4z83").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
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
        let keys = Array("su3cl3").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
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
        let keys = Array("wu0 dj/ ").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
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
        let keys = Array("su3cl3").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
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

        handler.handle(enter, state: state) { newState in
            switch count {
            case 0:
                committing = newState
            case 1:
                empty = newState
            default:
                break
            }
            count += 1
        } candidateSelectionCallback: {
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
        let keys = Array("su3cl3").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
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

        handler.handle(left, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(delete, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(delete, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
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

        handler.handle(left, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 0)
        }

        handler.handle(delete, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testBackspace() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
            } errorCallback: {
            }
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        let backspace = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 8, flags: [], isVerticalMode: false)

        handler.handle(backspace, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(backspace, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testCursor() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
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

        handler.handle(left, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(left, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }

        handler.handle(left, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
            errorCalled = true
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }
        XCTAssertTrue(errorCalled)

        handler.handle(right, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        handler.handle(right, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }

        errorCalled = false
        handler.handle(right, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
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
        let keys = Array("su3").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
            } errorCallback: {
            }
        }
        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
        }

        let space = KeyHandlerInput(inputText: " ", keyCode: KeyCode.down.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        handler.handle(space, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertEqual(state.composingBuffer, "你")
            XCTAssertEqual(state.cursorIndex, 1)
            let candidates = state.candidates
            XCTAssertTrue(candidates.contains("你"))
        }
    }

    func testHomeAndEnd() {
        var state: InputState = InputState.Empty()
        let keys = Array("su3cl3").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
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

        handler.handle(home, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 0)
        }

        handler.handle(end, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "你好")
            XCTAssertEqual(state.cursorIndex, 2)
        }
    }

}
