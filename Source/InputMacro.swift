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

// MARK: - Date

fileprivate func formatDate(date: Date, style: DateFormatter.Style, calendar: Calendar = Calendar(identifier: .gregorian)) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = style
    dateFormatter.timeStyle = .none
    dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
    dateFormatter.calendar = calendar
    return dateFormatter.string(from: date)
}

fileprivate struct InputMacroDateTodayShort: InputMacro {
    var name: String { "MACRO@DATE_TODAY_SHORT" }

    var replacement: String {
        let date = Date()
        return formatDate(date: date, style: .short)
    }
}

fileprivate struct InputMacroDateYesterdayShort: InputMacro {
    var name: String { "MACRO@DATE_YESTERDAY_SHORT" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * -24)
        return formatDate(date: date, style: .short)
    }
}

fileprivate struct InputMacroDateTomorrowShort: InputMacro {
    var name: String { "MACRO@DATE_TOMORROW_SHORT" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * 24)
        return formatDate(date: date, style: .short)
    }
}

fileprivate struct InputMacroDateTodayMedium: InputMacro {
    var name: String { "MACRO@DATE_TODAY_MEDIUM" }

    var replacement: String {
        let date = Date()
        return formatDate(date: date, style: .medium)
    }
}

fileprivate struct InputMacroDateYesterdayMedium: InputMacro {
    var name: String { "MACRO@DATE_YESTERDAY_MEDIUM" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * -24)
        return formatDate(date: date, style: .medium)
    }
}

fileprivate struct InputMacroDateTomorrowMedium: InputMacro {
    var name: String { "MACRO@DATE_TOMORROW_MEDIUM" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * 24)
        return formatDate(date: date, style: .medium)
    }
}

fileprivate struct InputMacroDateTodayMediumROC: InputMacro {
    var name: String { "MACRO@DATE_TODAY_MEDIUM_ROC" }

    var replacement: String {
        let date = Date()
        return formatDate(date: date, style: .medium, calendar: Calendar(identifier: .republicOfChina))
    }
}

fileprivate struct InputMacroDateYesterdayMediumROC: InputMacro {
    var name: String { "MACRO@DATE_YESTERDAY_MEDIUM_ROC" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * -24)
        return formatDate(date: date, style: .medium, calendar: Calendar(identifier: .republicOfChina))
    }
}

fileprivate struct InputMacroDateTomorrowMediumROC: InputMacro {
    var name: String { "MACRO@DATE_TOMORROW_MEDIUM_ROC" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * 24)
        return formatDate(date: date, style: .medium, calendar: Calendar(identifier: .republicOfChina))
    }
}


fileprivate struct InputMacroDateTodayMediumChinese: InputMacro {
    var name: String { "MACRO@DATE_TODAY_MEDIUM_CHINESE" }

    var replacement: String {
        let date = Date()
        return formatDate(date: date, style: .medium, calendar: Calendar(identifier: .chinese))
    }
}

fileprivate struct InputMacroDateYesterdayMediumChinese: InputMacro {
    var name: String { "MACRO@DATE_YESTERDAY_MEDIUM_CHINESE" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * -24)
        return formatDate(date: date, style: .medium, calendar: Calendar(identifier: .chinese))
    }
}

fileprivate struct InputMacroDateTomorrowMediumChinese: InputMacro {
    var name: String { "MACRO@DATE_TOMORROW_MEDIUM_CHINESE" }

    var replacement: String {
        let date = Date().addingTimeInterval(60 * 60 * 24)
        return formatDate(date: date, style: .medium, calendar: Calendar(identifier: .chinese))
    }
}

// MARK: - Time

fileprivate struct InputMacroTimeNowShort: InputMacro {
    var name: String { "MACRO@TIME_NOW_SHORT" }

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
    var name: String { "MACRO@TIME_NOW_MEDIUM" }

    var replacement: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = Locale(identifier: "zh_Hant_TW")
        return dateFormatter.string(from: date)
    }
}

// MARK: - Time Zone

fileprivate struct InputMacroTimeZoneStandard: InputMacro {
    var name: String { "MACRO@TIMEZONE_STANDARD" }

    var replacement: String {
        let timezone = TimeZone.current
        let locale = Locale(identifier: "zh_Hant_TW")
        return timezone.localizedName(for: .standard, locale: locale) ?? ""
    }
}

fileprivate struct InputMacroTimeZoneShortGeneric: InputMacro {
    var name: String { "MACRO@TIMEZONE_GENERIC_SHORT" }

    var replacement: String {
        let timezone = TimeZone.current
        let locale = Locale(identifier: "zh_Hant_TW")
        return timezone.localizedName(for: .shortGeneric, locale: locale) ?? ""
    }
}

// MARK: - Ganzhi

fileprivate func getCurrentYear() -> Int {
    let date = Date()
    let calendar = Calendar(identifier: .gregorian)
    let year = calendar.component(.year, from: date)
    return year
}

fileprivate func getYearBase(year: Int) -> (Int, Int) {
    let base: Int = year < 4 ? 60 - ((year * -1) + 2) % 60 : (year - 3) % 60
    return (base % 10, base % 12)
}

fileprivate func ganzhi(year: Int) -> String {
    let gan = ["癸", "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬"]
    let zhi = ["亥", "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌"]
    let (ganBase, zhiBase) = getYearBase(year: year)
    return gan[ganBase] + zhi[zhiBase] + "年"
}

fileprivate func chineseZodiac(year: Int) -> String {
    let gan = ["水", "木", "木", "火", "火", "土", "土", "金", "金", "水"]
    let zhi = ["豬", "鼠", "牛", "虎", "兔", "龍", "蛇", "馬", "羊", "猴", "雞", "狗"]
    let (ganBase, zhiBase) = getYearBase(year: year)
    return gan[ganBase] + zhi[zhiBase] + "年"
}

fileprivate struct InputMacroThisYearGanZhi: InputMacro {
    var name: String { "MACRO@THIS_YEAR_GANZHI" }

    var replacement: String {
        let year = getCurrentYear()
        return ganzhi(year: year)
    }
}

fileprivate struct InputMacroLastYearGanZhi: InputMacro {
    var name: String { "MACRO@LAST_YEAR_GANZHI" }

    var replacement: String {
        let year = getCurrentYear()
        return ganzhi(year: year - 1)
    }
}

fileprivate struct InputMacroNextYearGanZhi: InputMacro {
    var name: String { "MACRO@NEXT_YEAR_GANZHI" }

    var replacement: String {
        let year = getCurrentYear()
        return ganzhi(year: year + 1)
    }
}

fileprivate struct InputMacroThisYearChineseZodiac: InputMacro {
    var name: String { "MACRO@THIS_YEAR_CHINESE_ZODIAC" }

    var replacement: String {
        let year = getCurrentYear()
        return chineseZodiac(year: year)
    }
}

fileprivate struct InputMacroLastYearChineseZodiac: InputMacro {
    var name: String { "MACRO@LAST_YEAR_CHINESE_ZODIAC" }

    var replacement: String {
        let year = getCurrentYear()
        return chineseZodiac(year: year - 1)
    }
}

fileprivate struct InputMacroNextYearChineseZodiac: InputMacro {
    var name: String { "MACRO@NEXT_YEAR_CHINESE_ZODIAC" }

    var replacement: String {
        let year = getCurrentYear()
        return chineseZodiac(year: year + 1)
    }
}

// MARK: - InputMacroController

class InputMacroController: NSObject {
    @objc
    static let shared = InputMacroController()

    private var macros: [String:InputMacro] = {
        let macros: [InputMacro] = [
            InputMacroDateTodayShort(),
            InputMacroDateYesterdayShort(),
            InputMacroDateTomorrowShort(),
            InputMacroDateTodayMedium(),
            InputMacroDateYesterdayMedium(),
            InputMacroDateTomorrowMedium(),
            InputMacroDateTodayMediumROC(),
            InputMacroDateYesterdayMediumROC(),
            InputMacroDateTomorrowMediumROC(),
            InputMacroDateTodayMediumChinese(),
            InputMacroDateYesterdayMediumChinese(),
            InputMacroDateTomorrowMediumChinese(),
            InputMacroTimeNowShort(),
            InputMacroTimeNowMedium(),
            InputMacroTimeZoneStandard(),
            InputMacroTimeZoneShortGeneric(),
            InputMacroThisYearGanZhi(),
            InputMacroLastYearGanZhi(),
            InputMacroNextYearGanZhi(),
            InputMacroThisYearChineseZodiac(),
            InputMacroLastYearChineseZodiac(),
            InputMacroNextYearChineseZodiac(),
        ]
        var map:[String:InputMacro] = [:]
        macros.forEach { macro in
            map[macro.name] = macro
        }
        return map
    } ()


    @objc
    func handle(_ input: String) -> String {
        if let macro = macros[input] {
            return macro.replacement
        }
        return input
    }

}

