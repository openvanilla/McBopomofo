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

struct SystemLanguageSettingsCollectorPlugin: InfoCollectorPlugin {
    var name: String { "System language settings collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        // Gather preferred languages and current locale information
        let preferred = Locale.preferredLanguages
        let current = Locale.current

        var lines: [String] = []
        if preferred.isEmpty == false {
            // Show top 5 preferred languages to keep output concise
            let list = preferred.prefix(5).joined(separator: ", ")
            lines.append("- Preferred Languages: \(list)")
        } else {
            lines.append("- Preferred Languages: (none)")
        }

        // Locale identifier and some common components
        lines.append("- Current Locale: \(current.identifier)")

        // Language code
        if #available(iOS 16, macOS 13, *) {
            if let languageCode = current.language.languageCode?.identifier {
                lines.append("- Language Code: \(languageCode)")
            }
        } else {
            if let languageCode = current.languageCode {
                lines.append("- Language Code: \(languageCode)")
            }
        }

        // Region code
        if #available(iOS 16, macOS 13, *) {
            if let regionCode = current.region?.identifier {
                lines.append("- Region Code: \(regionCode)")
            }
        } else {
            if let regionCode = current.regionCode {
                lines.append("- Region Code: \(regionCode)")
            }
        }

        // Currency
        if #available(iOS 16, macOS 13, *) {
            if let currency = current.currency?.identifier {
                lines.append("- Currency: \(currency)")
            }
        } else {
            if let currency = current.currencyCode {
                lines.append("- Currency: \(currency)")
            }
        }

        callback(.success(lines.joined(separator: "\n")))
    }
}
