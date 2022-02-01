import XCTest
@testable import McBopomofo

class KeyHandlerPlainBopomofoTests: XCTestCase {
    var handler = KeyHandler()

    override func setUpWithError() throws {
        LanguageModelManager.loadDataModels()
        handler = KeyHandler()
        handler.inputMode = .plainBopomofo
    }

    override func tearDownWithError() throws {
    }

    func testPunctuationTable() {
        let input = KeyHandlerInput(inputText: "`", keyCode: 0, charCode: charCode("`"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertTrue(state.candidates.contains("，"))
        }
    }

    func testPunctuationComma() {
        let input = KeyHandlerInput(inputText: "<", keyCode: 0, charCode: charCode("<"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
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

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertEqual(state.composingBuffer, "。")
        }
    }

    func testInputNe() {
        let input = KeyHandlerInput(inputText: "s", keyCode: 0, charCode: charCode("s"), flags: .shift, isVerticalMode: false)
        var state: InputState = InputState.Empty()
        handler.handle(input, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.Inputting, "\(state)")
        if let state = state as? InputState.Inputting {
            XCTAssertEqual(state.composingBuffer, "ㄋ")
        }
    }

    func testInputNi() {
        var state: InputState = InputState.Empty()
        let keys = Array("su").map { String($0) }
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
            XCTAssertEqual(state.composingBuffer, "ㄋㄧ")
        }
    }

    func testInputNi3() {
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

        XCTAssertTrue(state is InputState.ChoosingCandidate, "\(state)")
        if let state = state as? InputState.ChoosingCandidate {
            XCTAssertTrue(state.candidates.contains("你"))
        }
    }

    func testCancelCandidateUsingDelete() {
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

        let input = KeyHandlerInput(inputText: " ", keyCode: KeyCode.delete.rawValue, charCode: 0, flags: [], isVerticalMode: false)
        handler.handle(input, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testCancelCandidateUsingEsc() {
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

        let input = KeyHandlerInput(inputText: " ", keyCode: 0, charCode: 27, flags: [], isVerticalMode: false)
        handler.handle(input, state: state) { newState in
            state = newState
        } candidateSelectionCallback: {
        } errorCallback: {
        }

        XCTAssertTrue(state is InputState.EmptyIgnoringPreviousState, "\(state)")
    }

    func testAssociatedPhrases() {
        let enabled = Preferences.associatedPhrasesEnabled
        Preferences.associatedPhrasesEnabled = true
        var state: InputState = InputState.Empty()
        let keys = Array("aul ").map { String($0) }
        for key in keys {
            let input = KeyHandlerInput(inputText: key, keyCode: 0, charCode: charCode(key), flags: [], isVerticalMode: false)
            handler.handle(input, state: state) { newState in
                state = newState
            } candidateSelectionCallback: {
            } errorCallback: {
            }
        }

        XCTAssertTrue(state is InputState.AssociatedPhrases, "\(state)")
        if let state = state as? InputState.AssociatedPhrases {
            XCTAssertTrue(state.candidates.contains("嗚"))
        }
        Preferences.associatedPhrasesEnabled = enabled
    }


}
