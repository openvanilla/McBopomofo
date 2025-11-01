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

import AppKit
import Carbon.HIToolbox
import Foundation

struct ActiveInputSourceListCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Active input sources collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        func getStringValue(_ source: TISInputSource, _ property: CFString) -> String? {
            if let valuePts = TISGetInputSourceProperty(source, property) {
                let value = Unmanaged<CFString>.fromOpaque(valuePts).takeUnretainedValue()
                return String(value)
            }
            return nil
        }

        // Use HIToolbox TIS APIs to get current and enabled input sources
        // Build a query for enabled input sources
        let keys: [CFString: Any] = [
            kTISPropertyInputSourceIsEnabled: kCFBooleanTrue as CFBoolean,
            kTISPropertyInputSourceIsSelectCapable: kCFBooleanTrue as CFBoolean,
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource as CFString,
        ]
        let dict = keys as CFDictionary
        var lines: [String] = []
        // Enabled input sources
        if let list = TISCreateInputSourceList(dict, false)?.takeRetainedValue()
            as? [TISInputSource]
        {
            lines.append("- Enabled Input Sources:")
            for src in list {
                let name = getStringValue(src, kTISPropertyLocalizedName) ?? "<unknown>"
                let sid = getStringValue(src, kTISPropertyInputSourceID) ?? ""
                let category =
                    getStringValue(
                        src,
                        kTISPropertyInputSourceCategory
                    ) ?? ""
                lines.append("  - \(name) (\(sid)) [\(category)]")
            }
        }

        if lines.isEmpty {
            lines.append("No input sources found")
        }
        callback(.success(lines.joined(separator: "\n")))
    }
}
