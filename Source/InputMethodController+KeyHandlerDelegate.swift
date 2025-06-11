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
import InputMethodKit
import CandidateUI

extension McBopomofoInputMethodController: KeyHandlerDelegate {
    func candidateController(for keyHandler: KeyHandler) -> Any {
        gCurrentCandidateController ?? .vertical
    }

    func keyHandler(_ keyHandler: KeyHandler, didSelectCandidateAt index: Int, candidateController controller: Any) {
        if index < 0 {
            return
        }
        if let controller = controller as? CandidateController {
            self.candidateController(controller, didSelectCandidateAtIndex: UInt(index))
        }
    }

    private func runUserPhraseHookIfEnabled(text: String) {
        if !Preferences.addPhraseHookEnabled {
            return
        }

        func run(_ script: String, arguments: [String]) {
            let process = Process()
            process.launchPath = script
            process.arguments = arguments
            // Some user may sign the git commits with gpg, and gpg is often
            // installed by homebrew, so we add the path of homebrew here.
            process.environment = ["PATH": "/opt/homebrew/bin:/usr/bin:/usr/local/bin:/bin"]

            let path = LanguageModelManager.dataFolderPath
            if #available(macOS 10.13, *) {
                process.currentDirectoryURL = URL(fileURLWithPath: path)
            } else {
                FileManager.default.changeCurrentDirectoryPath(path)
            }

            #if DEBUG
            let pipe = Pipe()
            process.standardError = pipe
            #endif
            process.launch()
            process.waitUntilExit()
            #if DEBUG
            let read = pipe.fileHandleForReading
            let data = read.readDataToEndOfFile()
            let s = String(data: data, encoding: .utf8)
            NSLog("result \(String(describing: s))")
            #endif
        }

        let script = Preferences.addPhraseHookPath

        DispatchQueue.global().async {
            run("/bin/sh", arguments: [script, text])
        }
    }

    func keyHandler(_ keyHandler: KeyHandler, didRequestWriteUserPhraseWith state: InputState) -> Bool {
        guard let state = state as? InputState.Marking else {
            return false
        }
        if !state.validToWrite {
            return false
        }
        LanguageModelManager.writeUserPhrase(state.userPhrase)
        runUserPhraseHookIfEnabled(text: state.selectedText)
        return true
    }

    func keyHandler(_ keyHandler: KeyHandler, didRequestBoostScoreForPhrase phrase: String, reading: String) -> Bool {
        let phraseToWrite = "\(phrase) \(reading)"
        let result = LanguageModelManager.writeUserPhrase(phraseToWrite)
        if result {
            runUserPhraseHookIfEnabled(text: phrase)
        }
        return result
    }

    func keyHandler(_ keyHandler: KeyHandler, didRequestExcludePhrase phrase: String, reading: String) -> Bool {
        let phraseToWrite = "\(phrase) \(reading)"
        let result = LanguageModelManager.removeUserPhrase(phraseToWrite)
        if result {
            runUserPhraseHookIfEnabled(text: phrase)
        }
        return result
    }

    func keyHandlerDidRequestReloadLanguageModel(_ keyHandler: KeyHandler) -> Bool {
        LanguageModelManager.loadUserPhrases(enableForPlainBopomofo: false)
        return true
    }

}
