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

import Foundation

protocol InputMacro {
    var name: String { get }
    var replacement: String { get }
}

fileprivate struct InputMacroDateTodayShort: InputMacro {
    var name: String {
        "MACRO@DATE_TODAY_SHORT"
    }

    var replacement: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        return dateFormatter.string(from: date)
    }
}

fileprivate struct InputMacroDateTodayMedium: InputMacro {
    var name: String {
        "MACRO@DATE_TODAY_MEDIUEM"
    }

    var replacement: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        return dateFormatter.string(from: date)
    }
}

fileprivate struct InputMacroDateTodayMediumROC: InputMacro {
    var name: String {
        "MACRO@DATE_TODAY_MEDIUEM_ROC"
    }

    var replacement: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        dateFormatter.calendar = Calendar(identifier: .republicOfChina)
        return dateFormatter.string(from: date)
    }
}

fileprivate struct InputMacroDateTodayMediumChinese: InputMacro {
    var name: String {
        "MACRO@DATE_TODAY_MEDIUEM_CHINESE"
    }

    var replacement: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        dateFormatter.calendar = Calendar(identifier: .chinese)
        return dateFormatter.string(from: date)
    }
}

fileprivate struct InputMacroTimeNowShort: InputMacro {
    var name: String {
        "MACRO@TIME_NOW_SHORT"
    }

    var replacement: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        return dateFormatter.string(from: date)
    }
}

fileprivate struct InputMacroTimeNowMedium: InputMacro {
    var name: String {
        "MACRO@TIME_NOW_MEDIUM"
    }

    var replacement: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        return dateFormatter.string(from: date)
    }
}

fileprivate struct InputMacroTimeZoneStandard: InputMacro {
    var name: String {
        "MACRO@TIMEZONE_STANDARD"
    }

    var replacement: String {
        let timezone = TimeZone.current
        let locale = Locale(identifier: "zh_Hant_TW")
        return timezone.localizedName(for: .standard, locale: locale) ?? ""
    }
}

fileprivate struct InputMacroTimeZoneShortGeneric: InputMacro {
    var name: String {
        "MACRO@TIMEZONE_GENERIC_SHORT"
    }

    var replacement: String {
        let timezone = TimeZone.current
        let locale = Locale(identifier: "zh_Hant_TW")
        return timezone.localizedName(for: .shortGeneric, locale: locale) ?? ""
    }
}

class InputMacroController: NSObject {
    @objc
    static let shared = InputMacroController()

    private var macros: [InputMacro] =
        [
            InputMacroDateTodayShort(),
            InputMacroDateTodayMedium(),
            InputMacroDateTodayMediumROC(),
            InputMacroDateTodayMediumChinese(),
            InputMacroTimeNowShort(),
            InputMacroTimeNowMedium(),
            InputMacroTimeZoneStandard(),
            InputMacroTimeZoneShortGeneric(),
        ]

    @objc
    func handle(_ input: String) -> String {
        for inputMacro in macros {
            if inputMacro.name == input {
                return inputMacro.replacement
            }
        }
        return input
    }

}

