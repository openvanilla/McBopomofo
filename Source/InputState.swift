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
    @objc (InputStateDeactivated)
    class Deactivated: InputState {
        override var description: String {
            "<InputState.Deactivated>"
        }
    }

    // MARK: -

    /// Represents that the composing buffer is empty.
    @objc (InputStateEmpty)
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
    @objc (InputStateEmptyIgnoringPreviousState)
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
    @objc (InputStateCommitting)
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

    /// Represents that the composing buffer is not empty.
    @objc (InputStateNotEmpty)
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
    @objc (InputStateInputting)
    class Inputting: NotEmpty {
        @objc var poppedText: String = ""
        @objc var tooltip: String = ""

        @objc override init(composingBuffer: String, cursorIndex: UInt) {
            super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
        }

        @objc var attributedString: NSAttributedString {
            let attributedSting = NSAttributedString(string: composingBuffer, attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .markedClauseSegment: 0
            ])
            return attributedSting
        }

        override var description: String {
            "<InputState.Inputting, composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex)>, poppedText:\(poppedText)>"
        }
    }

    // MARK: -

    private let kMinMarkRangeLength = 2
    private let kMaxMarkRangeLength = 6

    /// Represents that the user is marking a range in the composing buffer.
    @objc (InputStateMarking)
    class Marking: NotEmpty {

        @objc private(set) var markerIndex: UInt
        @objc private(set) var markedRange: NSRange
        @objc var tooltip: String {

            if composingBuffer.count != readings.count {
                return NSLocalizedString("There are special phrases in your text. We don't support adding new phrases in this case.", comment: "")
            }

            if Preferences.phraseReplacementEnabled {
                return NSLocalizedString("Phrase replacement mode is on. Not suggested to add phrase in the mode.", comment: "")
            }
            if Preferences.chineseConversionStyle == 1 && Preferences.chineseConversionEnabled {
                return NSLocalizedString("Model based Chinese conversion is on. Not suggested to add phrase in the mode.", comment: "")
            }
            if markedRange.length == 0 {
                return ""
            }

            let text = (composingBuffer as NSString).substring(with: markedRange)
            if markedRange.length < kMinMarkRangeLength {
                return String(format: NSLocalizedString("You are now selecting \"%@\". You can add a phrase with two or more characters.", comment: ""), text)
            } else if (markedRange.length > kMaxMarkRangeLength) {
                return String(format: NSLocalizedString("You are now selecting \"%@\". A phrase cannot be longer than %d characters.", comment: ""), text, kMaxMarkRangeLength)
            }
            return String(format: NSLocalizedString("You are now selecting \"%@\". Press enter to add a new phrase.", comment: ""), text)
        }

        @objc var tooltipForInputting: String = ""
        @objc private(set) var readings: [String]

        @objc init(composingBuffer: String, cursorIndex: UInt, markerIndex: UInt, readings: [String]) {
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

            attributedSting.setAttributes([
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .markedClauseSegment: 0
            ], range: NSRange(location: 0, length: markedRange.location))
            attributedSting.setAttributes([
                .underlineStyle: NSUnderlineStyle.thick.rawValue,
                .markedClauseSegment: 1
            ], range: markedRange)
            attributedSting.setAttributes([
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .markedClauseSegment: 2
            ], range: NSRange(location: end,
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
            /// McBopomofo allows users to input a string whose length differs
            /// from the amount of Bopomofo readings. In this case, the range
            /// in the composing buffer and the readings could not match, so
            /// we disable the function to write user phrases in this case.
            if composingBuffer.count != readings.count {
                return false
            }

            return markedRange.length >= kMinMarkRangeLength &&
                markedRange.length <= kMaxMarkRangeLength
        }

        @objc var userPhrase: String {
            let text = (composingBuffer as NSString).substring(with: markedRange)
            let exactBegin = StringUtils.convertToCharIndex(from: markedRange.location, in: composingBuffer)
            let exactEnd = StringUtils.convertToCharIndex(from: markedRange.location + markedRange.length, in: composingBuffer)
            let readings = readings[exactBegin..<exactEnd]
            let joined = readings.joined(separator: "-")
            return "\(text) \(joined)"
        }
    }

    // MARK: -

    /// Represents that the user is choosing in a candidates list.
    @objc (InputStateChoosingCandidate)
    class ChoosingCandidate: NotEmpty {
        @objc private(set) var candidates: [String]
        @objc private(set) var useVerticalMode: Bool

        @objc init(composingBuffer: String, cursorIndex: UInt, candidates: [String], useVerticalMode: Bool) {
            self.candidates = candidates
            self.useVerticalMode = useVerticalMode
            super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
        }

        @objc var attributedString: NSAttributedString {
            let attributedSting = NSAttributedString(string: composingBuffer, attributes: [
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .markedClauseSegment: 0
            ])
            return attributedSting
        }

        override var description: String {
            "<InputState.ChoosingCandidate, candidates:\(candidates), useVerticalMode:\(useVerticalMode),  composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex)>"
        }
    }

    // MARK: -

    /// Represents that the user is choosing in a candidates list
    /// in the associated phrases mode.
    @objc (InputStateAssociatedPhrases)
    class AssociatedPhrases: InputState {
        @objc private(set) var candidates: [String] = []
        @objc private(set) var useVerticalMode: Bool = false
        @objc init(candidates: [String], useVerticalMode: Bool) {
            self.candidates = candidates
            self.useVerticalMode = useVerticalMode
            super.init()
        }

        override var description: String {
            "<InputState.AssociatedPhrases, candidates:\(candidates), useVerticalMode:\(useVerticalMode)>"
        }
    }
}
