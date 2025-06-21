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

import Cocoa
import NSStringUtils

@objc protocol CandidateProvider: NSObjectProtocol {
    @objc var candidateCount: Int { get }
    @objc func candidate(at index: Int) -> String
}

/// Represents the states for the input method controller.
///
/// An input method is actually a finite state machine. It receives the inputs
/// from hardware like keyboard and mouse, changes its state, updates user
/// interface by the state, and finally produces the text output and then them
/// to the client apps. It should be a one-way data flow, and the user interface
/// and text output should follow unconditionally one single data source.
///
/// The InputState class is for representing what the input controller is doing,
/// and the place to store the variables that could be used. For example, the
/// array for the candidate list is useful only when the user is choosing a
/// candidate, and the array should not exist when the input controller is in
/// another state.
///
/// They are immutable objects. When the state changes, the controller should
/// create a new state object to replace the current state instead of modifying
/// the existing one.
///
/// McBopomofo's input controller has following possible states:
///
/// - Deactivated: The user is not using McBopomofo yet.
/// - Empty: The user has switched to McBopomofo but did not input anything yet,
///   or, he or she has committed text into the client apps and starts a new
///   input phase.
/// - Committing: The input controller is sending text to the client apps.
/// - Inputting: The user has inputted something and the input buffer is
///   visible.
/// - Marking: The user is creating a area in the input buffer and about to
///   create a new user phrase.
/// - Choosing Candidate: The candidate window is open to let the user to choose
///   one among the candidates.
class InputState: NSObject {

    /// Represents that the input controller is deactivated.
    @objc(InputStateDeactivated)
    class Deactivated: InputState {
        override var description: String {
            "<InputState.Deactivated>"
        }
    }

    // MARK: -

    /// Represents that the composing buffer is empty.
    @objc(InputStateEmpty)
    class Empty: InputState {
        @objc var composingBuffer: String {
            ""
        }

        override var description: String {
            "<InputState.Empty>"
        }
    }

    // MARK: -

    /// Represents that the composing buffer is empty.
    @objc(InputStateEmptyIgnoringPreviousState)
    class EmptyIgnoringPreviousState: InputState {
        @objc var composingBuffer: String {
            ""
        }
        override var description: String {
            "<InputState.EmptyIgnoringPreviousState>"
        }
    }

    // MARK: -

    /// Represents that the input controller is committing text into client app.
    @objc(InputStateCommitting)
    class Committing: InputState {
        @objc private(set) var poppedText: String = ""

        @objc convenience init(poppedText: String) {
            self.init()
            self.poppedText = poppedText
        }

        override var description: String {
            "<InputState.Committing poppedText:\(poppedText)>"
        }
    }

    // MARK: -

    @objc(InputStateSelectingFeature)
    class SelectingFeature: InputState, CandidateProvider {
        var featureList: [(String, () -> InputState)] = [
            (NSLocalizedString("Big5 Code", comment: ""), { .Big5(code: "") }),
            (NSLocalizedString("Date and Time", comment: ""), { .SelectingDateMacro() }),
            (NSLocalizedString("Enclosed Numbers", comment: ""), { .EnclosedNumber(number: "") }),
            (
                NSLocalizedString("Lowercase Chinese Numbers", comment: ""),
                { .ChineseNumber(style: .lower, number: "") }
            ),
            (
                NSLocalizedString("Uppercase Chinese Numbers", comment: ""),
                { .ChineseNumber(style: .upper, number: "") }
            ),
            (
                NSLocalizedString("Suzhou Numbers", comment: ""),
                { .ChineseNumber(style: .suzhou, number: "") }
            ),
        ]

        override var description: String {
            "<InputState.SelectingFeature>"
        }

        @objc var menu: [String] {
            featureList.map { $0.0 }
        }

        func nextState(by index: Int) -> InputState? {
            featureList[index].1()
        }

        var candidateCount: Int {
            featureList.count
        }

        func candidate(at index: Int) -> String {
            featureList[index].0
        }
    }

    @objc(InputStateSelectingDateMacro)
    class SelectingDateMacro: InputState, CandidateProvider {
        private var macros: [String] = [
            "MACRO@DATE_TODAY_SHORT",
            "MACRO@DATE_TODAY_MEDIUM",
            "MACRO@DATE_TODAY_MEDIUM_ROC",
            "MACRO@DATE_TODAY_MEDIUM_CHINESE",
            "MACRO@DATE_TODAY_MEDIUM_JAPANESE",
            "MACRO@THIS_YEAR_PLAIN",
            "MACRO@THIS_YEAR_PLAIN_WITH_ERA",
            "MACRO@THIS_YEAR_ROC",
            "MACRO@THIS_YEAR_JAPANESE",
            "MACRO@DATE_TODAY_WEEKDAY_SHORT",
            "MACRO@DATE_TODAY_WEEKDAY",
            "MACRO@DATE_TODAY2_WEEKDAY",
            "MACRO@DATE_TODAY_WEEKDAY_JAPANESE",
            "MACRO@TIME_NOW_SHORT",
            "MACRO@TIME_NOW_MEDIUM",
            "MACRO@THIS_YEAR_GANZHI",
            "MACRO@THIS_YEAR_CHINESE_ZODIAC",
        ]

        private(set) var menu: [String]

        override init() {
            self.menu = self.macros.map { macro in
                InputMacroController.shared.handle(macro)
            }.filter { string in
                !string.isEmpty
            }
        }

        override var description: String {
            "<InputState.SelectingDateMacro>"
        }

        var candidateCount: Int {
            menu.count
        }

        func candidate(at index: Int) -> String {
            menu[index]
        }
    }

    @objc(InputStateChineseNumber)
    class ChineseNumber: InputState {

        @objc(InputStateChineseNumberStyle)
        enum Style: Int {
            case lower = 0
            case upper = 1
            case suzhou = 2

            var label: String {
                switch self {
                case .lower:
                    "中文數字"
                case .upper:
                    "大寫數字"
                case .suzhou:
                    "蘇州碼"
                }
            }
        }

        @objc private(set) var number: String
        @objc private(set) var style: Style

        @objc init(style: Style, number: String) {
            self.style = style
            self.number = number
        }

        override var description: String {
            "<InputState.ChineseNumber, style:\(style), number:\(number)>"
        }

        @objc public var composingBuffer: String {
            return "[\(style.label)] \(number)"
        }
    }

    @objc(InputStateBig5)
    class Big5: InputState {
        @objc private(set) var code: String

        @objc init(code: String) {
            self.code = code
        }

        override var description: String {
            "<InputState.Big5, code:\(code)>"
        }

        @objc public var composingBuffer: String {
            return "[內碼] \(code)"
        }
    }

    @objc(InputStateEnclosedNumber)
    class EnclosedNumber: InputState {
        @objc private(set) var number: String

        @objc init(number: String) {
            self.number = number
        }

        override var description: String {
            "<InputState.EnclosedNumber, code:\(number)>"
        }

        @objc public var composingBuffer: String {
            return "[標題數字] \(number)"
        }
    }

    // MARK: -

    /// Represents that the composing buffer is not empty.
    @objc(InputStateNotEmpty)
    class NotEmpty: InputState {
        @objc private(set) var composingBuffer: String
        @objc private(set) var cursorIndex: UInt

        @objc init(composingBuffer: String, cursorIndex: UInt) {
            self.composingBuffer = composingBuffer
            self.cursorIndex = cursorIndex
        }

        override var description: String {
            "<InputState.NotEmpty, composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex)>"
        }
    }

    // MARK: -

    /// Represents that the user is inputting text.
    @objc(InputStateInputting)
    class Inputting: NotEmpty {
        @objc var tooltip: String = ""

        @objc override init(composingBuffer: String, cursorIndex: UInt) {
            super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
        }

        @objc var attributedString: NSAttributedString {
            let attributedSting = NSAttributedString(
                string: composingBuffer,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .markedClauseSegment: 0,
                ])
            return attributedSting
        }

        override var description: String {
            "<InputState.Inputting, composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex)>"
        }
    }

    // MARK: -

    private let kMinMarkRangeLength = 2
    private let kMaxMarkRangeLength = 8

    /// Represents that the user is marking a range in the composing buffer.
    @objc(InputStateMarking)
    class Marking: NotEmpty {
        private func validate(tooltip: inout String) -> Bool {
            /// McBopomofo allows users to input a string whose length differs
            /// from the amount of Bopomofo readings. In this case, the range
            /// in the composing buffer and the readings could not match, so
            /// we disable the function to write user phrases in this case.
            if composingBuffer.count != readings.count {
                tooltip = NSLocalizedString(
                    "Certain Unicode symbols or characters not supported as user phrases.",
                    comment: "")
                return false
            }
            if Preferences.phraseReplacementEnabled {
                tooltip = NSLocalizedString(
                    "Phrase replacement mode is on. Not recommended to add user phrases.",
                    comment: "")
                return false

            }
            if Preferences.chineseConversionStyle == ChineseConversionStyle.model
                && Preferences.chineseConversionEnabled
            {
                tooltip = NSLocalizedString(
                    "Model-based Chinese conversion is on. Not recommended to add user phrases.",
                    comment: "")
                return false
            }

            if markedRange.length == 0 {
                tooltip = ""
                return false
            }

            let text = (composingBuffer as NSString).substring(with: markedRange)
            if markedRange.length < kMinMarkRangeLength {
                tooltip = String(
                    format: NSLocalizedString(
                        "Marking \"%@\": add a custom phrase by selecting two or more characters.",
                        comment: ""), text)
                return false
            } else if markedRange.length > kMaxMarkRangeLength {
                tooltip = String(
                    format: NSLocalizedString(
                        "The phrase being marked \"%@\" is longer than the allowed %d characters.",
                        comment: ""), text, kMaxMarkRangeLength)
                return false
            }

            let (exactBegin, _) = (composingBuffer as NSString).characterIndex(
                from: markedRange.location)
            let (exactEnd, _) = (composingBuffer as NSString).characterIndex(
                from: markedRange.location + markedRange.length)
            let selectedReadings = readings[exactBegin..<exactEnd]

            let joined = selectedReadings.joined(separator: "-")
            let exist = LanguageModelManager.checkIfExist(userPhrase: text, key: joined)
            if exist {
                tooltip = String(
                    format: NSLocalizedString(
                        "The phrase being marked \"%@\" already exists.", comment: ""), text)
                return false
            }

            tooltip = String(
                format: NSLocalizedString(
                    "Marking \"%@\". Press Enter to add it as a new phrase.", comment: ""), text)
            return true
        }

        @objc private(set) var markerIndex: UInt
        @objc private(set) var markedRange: NSRange
        @objc var tooltip: String {
            var tooltip = ""
            _ = validate(tooltip: &tooltip)
            return tooltip
        }

        @objc var tooltipForInputting: String = ""
        @objc private(set) var readings: [String]

        @objc init(
            composingBuffer: String, cursorIndex: UInt, markerIndex: UInt, readings: [String]
        ) {
            self.markerIndex = markerIndex
            let begin = min(cursorIndex, markerIndex)
            let end = max(cursorIndex, markerIndex)
            markedRange = NSMakeRange(Int(begin), Int(end - begin))
            self.readings = readings
            super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
        }

        @objc var attributedString: NSAttributedString {
            let attributedSting = NSMutableAttributedString(string: composingBuffer)
            let end = markedRange.location + markedRange.length

            attributedSting.setAttributes(
                [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .markedClauseSegment: 0,
                ], range: NSRange(location: 0, length: markedRange.location))
            attributedSting.setAttributes(
                [
                    .underlineStyle: NSUnderlineStyle.thick.rawValue,
                    .markedClauseSegment: 1,
                ], range: markedRange)
            attributedSting.setAttributes(
                [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .markedClauseSegment: 2,
                ],
                range: NSRange(
                    location: end,
                    length: (composingBuffer as NSString).length - end))
            return attributedSting
        }

        override var description: String {
            "<InputState.Marking, composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex), markedRange:\(markedRange)>"
        }

        @objc func convertToInputting() -> Inputting {
            let state = Inputting(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
            state.tooltip = tooltipForInputting
            return state
        }

        @objc var validToWrite: Bool {
            var tooltip = ""
            return validate(tooltip: &tooltip)
        }

        @objc var selectedText: String {
            (composingBuffer as NSString).substring(with: markedRange)
        }

        @objc var userPhrase: String {
            let text = (composingBuffer as NSString).substring(with: markedRange)
            let (exactBegin, _) = (composingBuffer as NSString).characterIndex(
                from: markedRange.location)
            let (exactEnd, _) = (composingBuffer as NSString).characterIndex(
                from: markedRange.location + markedRange.length)
            let selectedReadings = readings[exactBegin..<exactEnd]
            let joined = selectedReadings.joined(separator: "-")
            return "\(text) \(joined)"
        }
    }

    // MARK: -

    @objc(InputStateCandidate)
    class Candidate: NSObject {
        @objc private(set) var reading: String
        @objc private(set) var value: String
        @objc private(set) var displayText: String
        /// The original value of a candidate.
        ///
        /// The value of a candidate may differ from its original value. For example,
        /// if a user turns on Chinese conversion, or a candidate is a macro, the
        /// original value would be converted to another value.
        @objc private(set) var originalValue: String

        @objc init(reading: String, value: String, displayText: String, originalValue: String) {
            self.reading = reading
            self.value = value
            self.displayText = displayText
            self.originalValue = originalValue
        }
    }

    /// Represents that the user is choosing in a candidates list.
    @objc(InputStateChoosingCandidate)
    class ChoosingCandidate: NotEmpty, CandidateProvider {
        @objc private(set) var candidates: [Candidate]
        @objc private(set) var useVerticalMode: Bool
        @objc var originalCursorIndex: UInt

        @objc init(
            composingBuffer: String, cursorIndex: UInt, candidates: [Candidate],
            useVerticalMode: Bool
        ) {
            self.candidates = candidates
            self.useVerticalMode = useVerticalMode
            self.originalCursorIndex = cursorIndex
            super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
        }

        @objc var attributedString: NSAttributedString {
            let attributedSting = NSAttributedString(
                string: composingBuffer,
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .markedClauseSegment: 0,
                ])
            return attributedSting
        }

        override var description: String {
            "<InputState.ChoosingCandidate, candidates:\(candidates), useVerticalMode:\(useVerticalMode),  composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex)>"
        }

        @objc var candidateCount: Int {
            candidates.count
        }

        @objc func candidate(at index: Int) -> String {
            candidates[index].displayText
        }
    }

    // MARK: -

    /// Represents that the user is choosing in a candidates list
    /// in the associated phrases mode.
    ///
    /// This is for Bopomofo input mode.
    @objc(InputStateAssociatedPhrases)
    class AssociatedPhrases: NotEmpty, CandidateProvider {
        @objc private(set) var previousState: NotEmpty
        @objc private(set) var prefixCursorIndex: Int = 0
        @objc private(set) var prefixReading: String = ""
        @objc private(set) var prefixValue: String = ""
        @objc private(set) var selectedIndex: Int = 0
        @objc private(set) var candidates: [Candidate] = []
        @objc private(set) var useVerticalMode: Bool = false
        @objc private(set) var useShiftKey: Bool = false

        @objc init(
            previousState: NotEmpty, prefixCursorIndex: Int, prefixReading: String,
            prefixValue: String,
            selectedIndex: Int, candidates: [Candidate], useVerticalMode: Bool, useShiftKey: Bool
        ) {
            self.previousState = previousState
            self.prefixCursorIndex = prefixCursorIndex
            self.prefixReading = prefixReading
            self.prefixValue = prefixValue
            self.selectedIndex = selectedIndex
            self.candidates = candidates
            self.useVerticalMode = useVerticalMode
            self.useShiftKey = useShiftKey
            super.init(
                composingBuffer: previousState.composingBuffer,
                cursorIndex: previousState.cursorIndex)
        }

        override var description: String {
            "<InputState.AssociatedPhrases, previousState:\(previousState), prefixCursorIndex:\(prefixCursorIndex), prefixReading:\(prefixReading), prefixValue:\(prefixValue), selectedIndex:\(selectedIndex), candidates:\(candidates), useVerticalMode:\(useVerticalMode)>"
        }

        var candidateCount: Int {
            candidates.count
        }

        func candidate(at index: Int) -> String {
            candidates[index].displayText
        }
    }

    /// Represents that the user is choosing in a candidates list
    /// in the associated phrases mode.
    ///
    /// This is for Plain Bopomofo input mode.
    @objc(InputStateAssociatedPhrasesPlain)
    class AssociatedPhrasesPlain: InputState, CandidateProvider {
        @objc private(set) var candidates: [Candidate] = []
        @objc private(set) var useVerticalMode: Bool = false

        @objc init(candidates: [Candidate], useVerticalMode: Bool) {
            self.candidates = candidates
            self.useVerticalMode = useVerticalMode
            super.init()
        }

        override var description: String {
            "<InputState.AssociatedPhrasesPlain, candidates:\(candidates), useVerticalMode:\(useVerticalMode)>"
        }

        @objc var candidateCount: Int {
            candidates.count
        }

        func candidate(at index: Int) -> String {
            candidates[index].displayText
        }
    }

    // MARK: -

    /// Represents that the user is choosing a dictionary service.
    @objc(InputStateSelectingDictionary)
    class SelectingDictionary: NotEmpty, CandidateProvider {
        @objc private(set) var previousState: NotEmpty
        @objc private(set) var selectedPhrase: String = ""
        @objc private(set) var selectedIndex: Int = 0
        @objc private(set) var menu: [String]

        @objc
        init(previousState: NotEmpty, selectedString: String, selectedIndex: Int) {
            self.previousState = previousState
            self.selectedPhrase = selectedString
            self.selectedIndex = selectedIndex
            self.menu = DictionaryServices.shared.services.map { service in
                service.textForMenu(selectedString: selectedString)
            }
            super.init(
                composingBuffer: previousState.composingBuffer,
                cursorIndex: previousState.cursorIndex)
        }

        func lookUp(
            usingServiceAtIndex index: Int, state: InputState, stateCallback: (InputState) -> Void
        ) -> Bool {
            DictionaryServices.shared.lookUp(
                phrase: selectedPhrase, withServiceAtIndex: index, state: state,
                stateCallback: stateCallback)
        }

        override var description: String {
            "<InputState.SelectingDictionaryService>"
        }

        @objc var candidateCount: Int {
            menu.count
        }

        @objc func candidate(at index: Int) -> String {
            menu[index]
        }

    }

    /// Represents that the user is choosing information about selected
    /// characters.
    @objc(InputStateShowingCharInfo)
    class ShowingCharInfo: NotEmpty, CandidateProvider {
        @objc private(set) var previousState: SelectingDictionary
        @objc private(set) var selectedPhrase: String = ""
        @objc private(set) var selectedIndex: Int = 0
        @objc private(set) var menu: [String]
        private(set) var menuTitleValueMapping: [(String, String)]

        @objc
        init(previousState: SelectingDictionary, selectedString: String, selectedIndex: Int) {
            self.previousState = previousState
            self.selectedPhrase = selectedString
            self.selectedIndex = selectedIndex

            func buildItem(prefix: String, selectedString: String, builder: (String) -> String) -> (
                String, String
            ) {
                let result = builder(selectedString)
                return ("\(prefix): \(result)", result)
            }

            func getCharCode(string: String, encoding: UInt32) -> String {
                return string.map { c in
                    let swiftString = "\(c)"
                    let cfString: CFString = swiftString as CFString
                    var cStringBuffer = [CChar](repeating: 0, count: 4)
                    CFStringGetCString(cfString, &cStringBuffer, 4, encoding)
                    let data = Data(bytes: cStringBuffer, count: strlen(cStringBuffer))
                    if data.count >= 2 {
                        return "0x" + String(format: "%02x%02x", data[0], data[1]).uppercased()
                    }
                    return "N/A"
                }.joined(separator: " ")
            }

            self.menuTitleValueMapping = [
                buildItem(
                    prefix: "UTF-8 HEX", selectedString: selectedPhrase,
                    builder: { string in
                        string.map { c in
                            "0x" + c.utf8.map { String(format: "%02x", $0).uppercased() }.joined()
                        }.joined(separator: " ")
                    }),
                buildItem(
                    prefix: "UTF-16 HEX", selectedString: selectedPhrase,
                    builder: { string in
                        string.map { c in
                            "0x" + c.utf16.map { String(format: "%02x", $0).uppercased() }.joined()
                        }.joined(separator: " ")
                    }),
                buildItem(
                    prefix: "URL Escape", selectedString: selectedPhrase,
                    builder: { string in
                        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    }),
                buildItem(
                    prefix: "Big5", selectedString: selectedPhrase,
                    builder: { string in
                        getCharCode(string: string, encoding: 0x0A06)
                    }),
                buildItem(
                    prefix: "GB2312", selectedString: selectedPhrase,
                    builder: { string in
                        getCharCode(string: string, encoding: 0x0631)
                    }),
                buildItem(
                    prefix: "Shift JIS", selectedString: selectedPhrase,
                    builder: { string in
                        getCharCode(string: string, encoding: 0x0A01)
                    }),
            ]
            self.menu = menuTitleValueMapping.map { $0.0 }
            super.init(
                composingBuffer: previousState.composingBuffer,
                cursorIndex: previousState.cursorIndex)
        }

        override var description: String {
            "<InputState.eShowingCharInfo>"
        }

        var candidateCount: Int {
            menu.count
        }

        func candidate(at index: Int) -> String {
            menu[index]
        }

    }

    @objc(InputStateCustomMenuEntry)
    class CustomMenuEntry: NSObject {
        @objc var title: String
        @objc var callback: () -> (Void)

        @objc init(title: String, callback: @escaping () -> (Void)) {
            self.title = title
            self.callback = callback
        }
    }

    /// Represents that the user is choosing information about selected
    /// characters.
    @objc(InputStateCustomMenu)
    class CustomMenu: NotEmpty, CandidateProvider {
        @objc private(set) var previousState: NotEmpty
        @objc private(set) var title: String
        @objc private(set) var entries: [CustomMenuEntry]
        @objc private(set) var selectedIndex: Int = 0

        @objc init(
            composingBuffer: String,
            cursorIndex: UInt,
            title: String,
            entries: [CustomMenuEntry],
            previousState: NotEmpty,
            selectedIndex: Int
        ) {
            self.title = title
            self.entries = entries
            self.previousState = previousState
            self.selectedIndex = selectedIndex
            super.init(
                composingBuffer: composingBuffer,
                cursorIndex: cursorIndex
            )
        }

        var candidateCount: Int {
            entries.count
        }

        func candidate(at index: Int) -> String {
            entries[index].title
        }

    }
}
