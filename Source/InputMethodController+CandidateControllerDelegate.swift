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
import Cocoa
import InputMethodKit
import NotifierUI
import SystemCharacterInfo

extension McBopomofoInputMethodController: CandidateControllerDelegate {

    func candidateCountForController(_ controller: CandidateController) -> UInt {
        if let state = state as? CandidateProvider {
            UInt(state.candidateCount)
        } else {
            0
        }
    }

    func candidateController(_ controller: CandidateController, candidateAtIndex index: UInt)
        -> String
    {
        if let state = state as? CandidateProvider {
            state.candidate(at: Int(index))
        } else {
            ""
        }
    }

    func candidateController(
        _ controller: CandidateController, didSelectCandidateAtIndex index: UInt
    ) {
        let client = currentClient

        switch state {
        case let state as InputState.ChoosingCandidate:
            let selectedCandidate = state.candidates[Int(index)]
            keyHandler.fixNode(
                reading: selectedCandidate.reading, value: selectedCandidate.value,
                originalCursorIndex: Int(state.originalCursorIndex),
                useMoveCursorAfterSelectionSetting: true)

            guard let inputting = keyHandler.buildInputtingState() as? InputState.Inputting else {
                return
            }

            switch keyHandler.inputMode {
            case .plainBopomofo:
                keyHandler.clear()
                let composingBuffer = inputting.composingBuffer
                handle(state: .Committing(poppedText: composingBuffer), client: client)
                if Preferences.associatedPhrasesEnabled,
                    let associatePhrases = keyHandler.buildAssociatedPhrasePlainState(
                        withReading: selectedCandidate.reading, value: selectedCandidate.value,
                        useVerticalMode: state.useVerticalMode)
                        as? InputState.AssociatedPhrasesPlain
                {
                    self.handle(state: associatePhrases, client: client)
                } else {
                    handle(state: .Empty(), client: client)
                }
            case .bopomofo:
                handle(state: inputting, client: client)
                if Preferences.associatedPhrasesEnabled {
                    var textFrame = NSRect.zero
                    let attributes: [AnyHashable: Any]? = (client as? IMKTextInput)?.attributes(
                        forCharacterIndex: 0, lineHeightRectangle: &textFrame)
                    let useVerticalMode =
                        (attributes?["IMKTextOrientation"] as? NSNumber)?.intValue == 0 || false

                    let state = keyHandler.buildInputtingState()
                    keyHandler.handleAssociatedPhrase(
                        with: state, useVerticalMode: useVerticalMode,
                        stateCallback: { newState in
                            self.handle(state: newState, client: client)
                        },
                        errorCallback: {
                            if Preferences.beepUponInputError {
                                NSSound.beep()
                            }
                        }, useShiftKey: true)
                }
            default:
                break
            }
        case let state as InputState.AssociatedPhrases:
            let candidate = state.candidates[Int(index)]
            keyHandler.fixNodeForAssociatedPhraseWithPrefix(
                at: state.prefixCursorIndex, prefixReading: state.prefixReading,
                prefixValue: state.prefixValue, associatedPhraseReading: candidate.reading,
                associatedPhraseValue: candidate.value)
            guard let inputting = keyHandler.buildInputtingState() as? InputState.Inputting else {
                return
            }
            handle(state: inputting, client: client)
            break
        case let state as InputState.AssociatedPhrasesPlain:
            let selectedCandidate = state.candidates[Int(index)]
            handle(state: .Committing(poppedText: selectedCandidate.value), client: currentClient)
            if Preferences.associatedPhrasesEnabled,
                let associatePhrases = keyHandler.buildAssociatedPhrasePlainState(
                    withReading: selectedCandidate.reading, value: selectedCandidate.value,
                    useVerticalMode: state.useVerticalMode) as? InputState.AssociatedPhrasesPlain
            {
                handle(state: associatePhrases, client: client)
            } else {
                handle(state: .Empty(), client: client)
            }
        case let state as InputState.SelectingFeature:
            if let nextState = state.nextState(by: Int(index)) {
                handle(state: nextState, client: client)
            }
        case let state as InputState.SelectingDateMacro:
            let candidate = state.candidate(at: Int(index))
            if !candidate.isEmpty {
                let committing = InputState.Committing(poppedText: candidate)
                handle(state: committing, client: client)
            }
        case let state as InputState.SelectingDictionary:
            let handled = state.lookUp(usingServiceAtIndex: Int(index), state: state) { state in
                handle(state: state, client: client)
            }
            if handled {
                let previous = state.previousState
                let candidateIndex = state.selectedIndex
                handle(state: previous, client: client)
                if candidateIndex > 0 {
                    gCurrentCandidateController?.selectedCandidateIndex = UInt(candidateIndex)
                }
            }
        case let state as InputState.ShowingCharInfo:
            let text = state.menuTitleValueMapping[Int(index)].1
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(text, forType: .string)
            NotifierController.notify(
                message: String(format: NSLocalizedString("%@ has been copied.", comment: ""), text)
            )

            let previous = state.previousState.previousState
            let candidateIndex = state.previousState.selectedIndex
            handle(state: previous, client: client)
            if candidateIndex > 0 {
                gCurrentCandidateController?.selectedCandidateIndex = UInt(candidateIndex)
            }
        case let state as InputState.CustomMenu:
            let entry = state.entries[Int(index)]
            entry.callback()
        case let state as InputState.Number:
            let candidate = state.candidate(at: Int(index))
            let committing = InputState.Committing(poppedText: candidate)
            handle(state: committing, client: client)
        default:
            break
        }
    }

    func candidateController(_ controller: CandidateController, readingAtIndex index: UInt) -> String? {
        if let state = state as? CandidateProvider {
            state.reading(at: Int(index))
        } else {
            nil
        }
    }

    func candidateController(_ controller: CandidateController, requestExplanationFor candidate: String, reading: String) -> String? {
        // The method helps to provide character information for Voice Over.
        // For example, when a user turns VoiceOver on and then select a candidate
        // like "中", Voice Over will say "「中國地方」的「中」".

        if reading == "" {
            return nil
        }
        if reading.hasPrefix("_") {
            return nil
        }

        func getMcbopomofoExplanation(for candidate: String, reading: String) -> String? {
            let state = keyHandler
                .buildAssociatedPhrasePlainState(
                    withReading: reading,
                    value: candidate,
                    useVerticalMode: false
                )
            if let state = state as? InputState.AssociatedPhrasesPlain {
                let phrase = state.candidate(at: 0)
                return "「\(candidate)\(phrase)」的「\(candidate)」"
            }
            return nil
        }

        func checkIfSystemCharacterInfoReady() -> Bool {
            charInfo != nil
        }

        func getSystemExplanation(for chr: String) -> String? {
            guard let charInfo = charInfo,
                  let result = try? charInfo.read(string: chr) else {
                return nil
            }
            if let example = result.traditionalExample ?? result.simplifiedExample {
                return "「\(example)」的「\(chr)」"
            }
            if let components = result.components {
                return "「\(components)」組成的「\(chr)」"
            }
            return nil
        }

        if let singleExplan = getMcbopomofoExplanation(for: candidate, reading: reading) {
            return singleExplan
        }
        if !checkIfSystemCharacterInfoReady() {
            return nil
        }
        var components: [String] = []
        for chr in candidate {
            let result = getSystemExplanation(for: String(chr)) ?? String(chr)
            components.append(result)
        }
        switch components.count {
        case 0:
            return nil
        case 1:
            return components[0]
        default:
            return "\(candidate) - \(components.joined(separator: ", "))"
        }
    }
}
