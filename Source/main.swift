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
import InputSourceHelper

private func install() -> Int32 {
    guard let bundleID = Bundle.main.bundleIdentifier else {
        return -1
    }
    let bundleUrl = Bundle.main.bundleURL
    var inputSource = InputSourceHelper.inputSource(for: bundleID)

    if inputSource == nil {
        NSLog("Registering input source \(bundleID) at \(bundleUrl.absoluteString)");
        // then register
        let status = InputSourceHelper.registerTnputSource(at: bundleUrl)

        if !status {
            NSLog("Fatal error: Cannot register input source \(bundleID) at \(bundleUrl.absoluteString).")
            return -1
        }

        inputSource = InputSourceHelper.inputSource(for: bundleID)
    }

    guard let inputSource = inputSource else {
        NSLog("Fatal error: Cannot find input source \(bundleID) after registration.")
        return -1
    }

    if !InputSourceHelper.inputSourceEnabled(for: inputSource) {
        NSLog("Enabling input source \(bundleID) at \(bundleUrl.absoluteString).")
        let status = InputSourceHelper.enable(inputSource: inputSource)
        if !status {
            NSLog("Fatal error: Cannot enable input source \(bundleID).")
            return -1
        }
        if !InputSourceHelper.inputSourceEnabled(for: inputSource) {
            NSLog("Fatal error: Cannot enable input source \(bundleID).")
            return -1
        }
    }

    if CommandLine.arguments.count > 2 && CommandLine.arguments[2] == "--all" {
        let enabled = InputSourceHelper.enableAllInputMode(for: bundleID)
        NSLog(enabled ? "All input sources enabled for \(bundleID)" : "Cannot enable all input sources for \(bundleID), but this is ignored")
    }
    return 0
}

let kConnectionName = "McBopomofo_1_Connection"

if CommandLine.arguments.count > 1 {
    if CommandLine.arguments[1] == "install" {
        let exitCode = install()
        exit(exitCode)
    }
}

guard let mainNibName = Bundle.main.infoDictionary?["NSMainNibFile"] as? String else {
    NSLog("Fatal error: NSMainNibFile key not defined in Info.plist.");
    exit(-1)
}

let loaded = Bundle.main.loadNibNamed(mainNibName, owner: NSApp, topLevelObjects: nil)
if !loaded {
    NSLog("Fatal error: Cannot load \(mainNibName).")
    exit(-1)
}

guard let bundleID = Bundle.main.bundleIdentifier, let server = IMKServer(name: kConnectionName, bundleIdentifier: bundleID) else {
    NSLog("Fatal error: Cannot initialize input method server with connection \(kConnectionName).")
    exit(-1)
}

NSApp.run()
