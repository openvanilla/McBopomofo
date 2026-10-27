// Copyright (c) 2026 and onwards The McBopomofo Authors.
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

import CandidateKit
import XCTest

@testable import McBopomofo

@MainActor
final class KeyHandlerCandidatePreferenceTests: XCTestCase {
    func testCandidateControllerRuntimeClassAndArrowDirections() throws {
        XCTAssertTrue(
            NSClassFromString("CKCandidateController") === CandidateKit.CandidateController.self)
        for vertical in [false, true] {
            let fixture = try CandidateKeyFixture(vertical: vertical, expandable: false)
            let controller = fixture.controller
            defer { controller.visible = false }
            XCTAssertEqual(controller.isHorizontal, !vertical)
            XCTAssertEqual(controller.keyLabels.map(\.key), Array("asdf").map(String.init))
            fixture.send(
                vertical ? "\u{F701}" : "\u{F703}",
                keyCode: vertical ? KeyCode.down.rawValue : KeyCode.right.rawValue)
            XCTAssertEqual(controller.selectedCandidateIndex, 1)
            fixture.send("\u{F72B}", keyCode: KeyCode.end.rawValue)
            XCTAssertEqual(controller.selectedCandidateIndex, 23)
            fixture.send("\u{F729}", keyCode: KeyCode.home.rawValue)
            XCTAssertEqual(controller.selectedCandidateIndex, 0)
        }
    }

    func testExpandableSpaceSelectsHighlightedCandidateOrPagesInEveryLayout() throws {
        let saved = Preferences.chooseCandidateUsingSpace
        defer { Preferences.chooseCandidateUsingSpace = saved }

        for vertical in [false, true] {
            let fixture = try CandidateKeyFixture(vertical: vertical, expandable: true)
            defer { fixture.controller.visible = false }
            fixture.controller.selectedCandidateIndex = 2

            Preferences.chooseCandidateUsingSpace = false
            fixture.send(" ")
            XCTAssertEqual(fixture.controller.selectedCandidateIndex, 2)
            fixture.send(" ")
            XCTAssertGreaterThan(fixture.controller.selectedCandidateIndex, 2)
        }
    }

    func testNonexpandingNavigationPreservesSelectionAndKeyLabels() throws {
        let savedSpace = Preferences.chooseCandidateUsingSpace
        let savedCursor = Preferences.allowMovingCursorWhenChoosingCandidates
        Preferences.allowMovingCursorWhenChoosingCandidates = .disabled
        defer {
            Preferences.chooseCandidateUsingSpace = savedSpace
            Preferences.allowMovingCursorWhenChoosingCandidates = savedCursor
        }
        for mode in [InputMode.bopomofo, .plainBopomofo] {
            for vertical in [false, true] {
                for spaceSelects in [false, true] {
                    Preferences.chooseCandidateUsingSpace = spaceSelects
                    let fixture = try CandidateKeyFixture(
                        vertical: vertical, expandable: false, count: 10)
                    fixture.handler.inputMode = mode
                    defer { fixture.controller.visible = false }
                    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.02))
                    fixture.controller.selectedCandidateIndex = 2
                    let inputs: [(String, UInt16)] = [
                        (" ", 49), ("s", 0),
                        ("\u{F72D}", KeyCode.pageDown.rawValue),
                        ("\u{F72C}", KeyCode.pageUp.rawValue),
                        (
                            vertical ? "\u{F701}" : "\u{F703}",
                            vertical ? KeyCode.down.rawValue : KeyCode.right.rawValue
                        ),
                        (
                            vertical ? "\u{F700}" : "\u{F702}",
                            vertical ? KeyCode.up.rawValue : KeyCode.left.rawValue
                        ),
                        ("\u{F729}", KeyCode.home.rawValue),
                        ("\u{F72B}", KeyCode.end.rawValue),
                        ("\u{F72C}", KeyCode.pageUp.rawValue),
                        ("d", 0), ("\r", 36),
                    ]
                    let expectedIndices: [UInt] =
                        vertical
                        ? [6, 6, 9, 5, 6, 5, 0, 9, 5, 5, 5]
                        : [4, 4, 8, 4, 5, 4, 0, 9, 4, 4, 4]
                    let expectedFirstLabels: [UInt] =
                        vertical
                        ? [4, 4, 6, 4, 4, 4, 0, 6, 4, 4, 4]
                        : [4, 4, 8, 4, 4, 4, 0, 8, 4, 4, 4]
                    let expectedSelections = [
                        [], [5], [5], [5], [5], [5], [5], [5], [5], [5, 6],
                        [5, 6, vertical ? 5 : 4],
                    ]
                    for (step, input) in inputs.enumerated() {
                        let (text, keyCode) = input
                        fixture.send(text, keyCode: keyCode)
                        XCTAssertEqual(
                            fixture.controller.selectedCandidateIndex, expectedIndices[step],
                            "vertical=\(vertical), key=\(keyCode)")
                        XCTAssertEqual(fixture.selections, expectedSelections[step])
                        for slot in 0..<4 {
                            let index = expectedFirstLabels[step] + UInt(slot)
                            XCTAssertEqual(
                                fixture.controller.candidateIndexAtKeyLabelIndex(UInt(slot)),
                                index < 10 ? index : UInt.max,
                                "vertical=\(vertical), key=\(keyCode), slot=\(slot)")
                        }
                    }
                }
            }
        }
    }

    func testLetterSelectionKeysFollowCurrentPageInBothInputModes() throws {
        let saved = Preferences.allowMovingCursorWhenChoosingCandidates
        Preferences.allowMovingCursorWhenChoosingCandidates = .disabled
        defer { Preferences.allowMovingCursorWhenChoosingCandidates = saved }

        for mode in [InputMode.bopomofo, .plainBopomofo] {
            for vertical in [false, true] {
                for expandable in [false, true] {
                    let fixture = try CandidateKeyFixture(
                        vertical: vertical, expandable: expandable)
                    defer { fixture.controller.visible = false }
                    fixture.handler.inputMode = mode
                    XCTAssertEqual(
                        fixture.controller.keyLabels.map(\.displayedText),
                        Array("asdf").map(String.init))
                    fixture.send("d")
                    XCTAssertEqual(fixture.selections, [2])

                    XCTAssertTrue(fixture.controller.showNextPage())
                    let expected = fixture.controller.candidateIndexAtKeyLabelIndex(1)
                    XCTAssertNotEqual(expected, UInt.max)
                    fixture.send("S", flags: .shift)
                    XCTAssertEqual(fixture.selections, [2, Int(expected)])
                }
            }
        }
    }

    func testNonexpandingBoundaryKeysReportUnchangedSelection() throws {
        let savedSpace = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = true
        defer { Preferences.chooseCandidateUsingSpace = savedSpace }
        for vertical in [false, true] {
            for count in [3, 4, 10] {
                let fixture = try CandidateKeyFixture(
                    vertical: vertical, expandable: false,
                    count: count)
                defer { fixture.controller.visible = false }
                fixture.send("\u{F729}", keyCode: KeyCode.home.rawValue, expectsError: true)
                fixture.send("\u{F72C}", keyCode: KeyCode.pageUp.rawValue, expectsError: true)
                XCTAssertEqual(fixture.controller.selectedCandidateIndex, 0)
                if count <= 4 {
                    fixture.send(" ", expectsError: true)
                    XCTAssertEqual(fixture.controller.selectedCandidateIndex, 0)
                }
                fixture.controller.selectedCandidateIndex = UInt(count - 1)
                fixture.send("\u{F72B}", keyCode: KeyCode.end.rawValue, expectsError: true)
                fixture.send(" ", expectsError: true)
                fixture.send("\u{F72D}", keyCode: KeyCode.pageDown.rawValue, expectsError: true)
                XCTAssertEqual(fixture.controller.selectedCandidateIndex, UInt(count - 1))
                XCTAssertTrue(fixture.selections.isEmpty)
            }
        }
    }

    func testShiftSpaceAndPageDownStillPageWhenSpaceSelects() throws {
        let saved = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = true
        defer { Preferences.chooseCandidateUsingSpace = saved }
        let fixture = try CandidateKeyFixture(vertical: true, expandable: false)
        defer { fixture.controller.visible = false }

        fixture.send(" ", flags: .shift)
        XCTAssertEqual(fixture.controller.selectedCandidateIndex, 4)
        fixture.send("\u{F72D}", keyCode: KeyCode.pageDown.rawValue)
        XCTAssertEqual(fixture.controller.selectedCandidateIndex, 8)
        XCTAssertTrue(fixture.selections.isEmpty)
    }

    func testPlainAssociatedPhrasesKeepShiftSelectionKeys() throws {
        let saved = Preferences.chooseCandidateUsingSpace
        Preferences.chooseCandidateUsingSpace = true
        defer { Preferences.chooseCandidateUsingSpace = saved }
        let fixture = try CandidateKeyFixture(vertical: true, expandable: false)
        defer { fixture.controller.visible = false }
        let choosing = try XCTUnwrap(fixture.state as? InputState.ChoosingCandidate)
        fixture.state = InputState.AssociatedPhrasesPlain(
            candidates: choosing.candidates, useVerticalMode: false)
        var configuration = fixture.controller.configuration
        configuration.showsKeyLabelsAsDetails = true
        try fixture.controller.apply(configuration: configuration)
        fixture.controller.keyLabels = Array("asdf").map {
            CandidateKit.CandidateKeyLabel(key: String($0), displayedText: "⇧ " + String($0))
        }

        fixture.send(" ")
        XCTAssertTrue(fixture.selections.isEmpty)
        let expected = fixture.controller.candidateIndexAtKeyLabelIndex(1)
        fixture.send("S", flags: .shift, ignoringModifiers: "s")
        XCTAssertEqual(fixture.selections, [Int(expected)])
    }

    func testExpandedPageKeysMoveOneRowOrColumnAndClampAtTheEnd() throws {
        for vertical in [false, true] {
            let fixture = try CandidateKeyFixture(vertical: vertical, expandable: true)
            defer { fixture.controller.visible = false }
            fixture.controller.selectedCandidateIndex = 2
            XCTAssertTrue(fixture.controller.showNextPage())
            XCTAssertEqual(fixture.controller.selectedCandidateIndex, 2)

            fixture.send("\u{F72D}", keyCode: KeyCode.pageDown.rawValue)
            XCTAssertEqual(fixture.controller.selectedCandidateIndex, 6)
            fixture.send("\u{F72C}", keyCode: KeyCode.pageUp.rawValue)
            XCTAssertEqual(fixture.controller.selectedCandidateIndex, 2)

            fixture.controller.selectedCandidateIndex = 22
            XCTAssertFalse(fixture.controller.showNextPage())
            XCTAssertEqual(fixture.controller.selectedCandidateIndex, 22)
            XCTAssertTrue(fixture.selections.isEmpty)
        }
    }

    func testPreviewAndInputMethodNavigationStayInSync() throws {
        for vertical in [false, true] {
            for expandable in [false, true] {
                let fixture = try CandidateKeyFixture(vertical: vertical, expandable: expandable)
                let preview = CandidateKit.CandidateController(
                    configuration: fixture.controller.configuration)
                preview.replaceCandidates(
                    fixture.controller.inputCandidates, initialSelectedIndex: 2)
                preview.visible = true
                fixture.controller.selectedCandidateIndex = 2
                defer {
                    fixture.controller.visible = false
                    preview.visible = false
                }

                let inputs: [(String, UInt16, NSEvent.ModifierFlags)] = [
                    ("\u{F72D}", KeyCode.pageDown.rawValue, []),
                    ("\u{F72D}", KeyCode.pageDown.rawValue, []),
                    (
                        vertical ? "\u{F701}" : "\u{F703}",
                        vertical ? KeyCode.down.rawValue : KeyCode.right.rawValue, []
                    ),
                    (
                        vertical ? "\u{F700}" : "\u{F702}",
                        vertical ? KeyCode.up.rawValue : KeyCode.left.rawValue, []
                    ),
                    ("\u{F72C}", KeyCode.pageUp.rawValue, []),
                    ("\u{F72B}", KeyCode.end.rawValue, []),
                    ("\u{F729}", KeyCode.home.rawValue, []),
                    ("\t", KeyCode.tab.rawValue, .shift),
                    ("\t", KeyCode.tab.rawValue, []),
                ]
                for (text, keyCode, flags) in inputs {
                    fixture.send(text, flags: flags, keyCode: keyCode)
                    let event = try XCTUnwrap(
                        NSEvent.keyEvent(
                            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                            windowNumber: 0, context: nil, characters: text,
                            charactersIgnoringModifiers: text, isARepeat: false, keyCode: keyCode))
                    XCTAssertTrue(preview.handleKeyEvent(event))
                    XCTAssertEqual(
                        preview.selectedCandidateIndex, fixture.controller.selectedCandidateIndex)
                    XCTAssertEqual(
                        preview.window?.frame.size, fixture.controller.window?.frame.size)
                    for slot in 0..<4 {
                        XCTAssertEqual(
                            preview.candidateIndexAtKeyLabelIndex(UInt(slot)),
                            fixture.controller.candidateIndexAtKeyLabelIndex(UInt(slot)))
                    }
                }
            }
        }
    }

    func testRowBoundariesAndTabWrappingInBothInputModes() throws {
        for mode in [InputMode.bopomofo, .plainBopomofo] {
            for vertical in [false, true] {
                for expandable in [false, true] {
                    let fixture = try CandidateKeyFixture(
                        vertical: vertical, expandable: expandable, count: 10)
                    fixture.handler.inputMode = mode
                    defer { fixture.controller.visible = false }

                    fixture.controller.selectedCandidateIndex = 9
                    fixture.send("\u{F729}", keyCode: KeyCode.home.rawValue)
                    XCTAssertEqual(fixture.controller.selectedCandidateIndex, expandable ? 8 : 0)
                    fixture.send("\u{F72B}", keyCode: KeyCode.end.rawValue)
                    XCTAssertEqual(fixture.controller.selectedCandidateIndex, 9)
                    fixture.send("\t", keyCode: KeyCode.tab.rawValue)
                    XCTAssertEqual(fixture.controller.selectedCandidateIndex, 0)
                    fixture.send("\t", flags: .shift, keyCode: KeyCode.tab.rawValue)
                    XCTAssertEqual(fixture.controller.selectedCandidateIndex, 9)
                    XCTAssertTrue(fixture.selections.isEmpty)
                }
            }
        }
    }

    func testAutomaticAssociatedPhraseConfirmsWithShiftReturnWithoutIndexLabels() throws {
        let fixture = try CandidateKeyFixture(vertical: false, expandable: true)
        defer { fixture.controller.visible = false }
        let choosing = try XCTUnwrap(fixture.state as? InputState.ChoosingCandidate)
        fixture.state = InputState.AssociatedPhrases(
            previousState: choosing, prefixCursorIndex: 1, prefixReading: "ㄧ", prefixValue: "字",
            selectedIndex: 0, candidates: choosing.candidates, useVerticalMode: false,
            autoTriggered: true)
        var configuration = fixture.controller.configuration
        configuration.indexLabels = ""
        try fixture.controller.apply(configuration: configuration)
        fixture.controller.replaceCandidates(
            [CandidateKit.Candidate(displayString: "詞", detail: "⇧ ⏎")], initialSelectedIndex: 0)

        XCTAssertTrue(fixture.controller.keyLabels.isEmpty)
        fixture.send("\r", flags: .shift, keyCode: 36)
        XCTAssertEqual(fixture.selections, [0])
    }
}

@MainActor
private final class CandidateKeyFixture: NSObject, @MainActor KeyHandlerDelegate {
    let handler = KeyHandler()
    let controller: CandidateKit.CandidateController
    var state: InputState
    var selections: [Int] = []

    init(vertical: Bool, expandable: Bool, count: Int = 24) throws {
        controller =
            vertical
            ? CandidateKit.VerticalCandidateController(expandable: expandable)
            : CandidateKit.HorizontalCandidateController(expandable: expandable)
        let candidates = (0..<count).map {
            InputState.Candidate(
                reading: "ㄧ", value: "字\($0)", displayText: "字\($0)", rawValue: "字\($0)")
        }
        state = InputState.ChoosingCandidate(
            composingBuffer: "字", cursorIndex: 1, candidates: candidates, useVerticalMode: false)
        super.init()
        handler.delegate = self
        handler.inputMode = .bopomofo
        var configuration = controller.configuration
        configuration.indexLabels = "asdf"
        configuration.pageSize = 4
        configuration.animationDuration = 0
        try controller.apply(configuration: configuration)
        controller.replaceCandidates(
            candidates.map { CandidateKit.Candidate(displayString: $0.value) },
            initialSelectedIndex: 0)
        controller.visible = true
    }

    func send(
        _ text: String, flags: NSEvent.ModifierFlags = [], keyCode: UInt16 = 0,
        ignoringModifiers: String? = nil, expectsError: Bool = false
    ) {
        let input = KeyHandlerInput(
            inputText: text, keyCode: keyCode, charCode: charCode(text), flags: flags,
            isVerticalMode: false, inputTextIgnoringModifiers: ignoringModifiers)
        var reportedError = false
        XCTAssertTrue(
            handler.handle(input: input, state: state) { _ in
                XCTFail("CandidateKit.Candidate navigation should not replace the input state.")
            } errorCallback: {
                reportedError = true
            })
        XCTAssertEqual(reportedError, expectsError)
    }

    func candidateController(for keyHandler: KeyHandler) -> Any { controller }
    func keyHandler(
        _ keyHandler: KeyHandler, didSelectCandidateAt index: Int, candidateController: Any
    ) {
        selections.append(index)
    }
    func keyHandler(
        _ keyHandler: KeyHandler, didRequestWriteUserPhraseWith state: InputState
    ) -> Bool { false }
    func keyHandler(
        _ keyHandler: KeyHandler, didRequestBoostScoreForPhrase phrase: String, reading: String
    ) -> Bool { false }
    func keyHandler(
        _ keyHandler: KeyHandler, didRequestExcludePhrase phrase: String, reading: String
    ) -> Bool { false }
    func keyHandlerDidRequestReloadLanguageModel(_ keyHandler: KeyHandler) -> Bool { false }
}
