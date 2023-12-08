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

fileprivate struct InputMacroThisYearGanZhi: InputMacro {
    var name: String {
        "MACRO@THIS_YEAR_GANZHI"
    }

    var replacement: String {
        func ganshi(year: Int) -> String {
            let gan = ["癸", "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬"]
            let zhi = ["亥", "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌"]

            if year < 4 {
                let year = year * -1
                let base = 60 - (year + 2) % 60
                let ganBase = base % 10
                let zhiBase = base % 12
                return gan[ganBase] + zhi[zhiBase] + "年"
            }
            let base = (year - 3) % 60
            let ganBase = base % 10
            let zhiBase = base % 12
            return gan[ganBase] + zhi[zhiBase] + "年"
        }
        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        return ganshi(year: year)
    }
}

fileprivate struct InputMacroThisYearWoodRat: InputMacro {
    var name: String {
        "MACRO@THIS_YEAR_WOOD_RAT"
    }

    var replacement: String {
        func woodRat(year: Int) -> String {
            let gan = ["水", "木", "木", "火", "火", "土", "土", "金", "金", "水"]
            let zhi = ["豬", "鼠", "牛", "虎", "兔", "龍", "蛇", "馬", "羊", "猴", "雞", "狗"]

            if year < 4 {
                let year = year * -1
                let base = 60 - (year + 2) % 60
                let ganBase = base % 10
                let zhiBase = base % 12
                return gan[ganBase] + zhi[zhiBase] + "年"
            }
            let base = (year - 3) % 60
            let ganBase = base % 10
            let zhiBase = base % 12
            return gan[ganBase] + zhi[zhiBase] + "年"
        }

        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        return woodRat(year: year)
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
            InputMacroThisYearGanZhi(),
            InputMacroThisYearWoodRat(),
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

