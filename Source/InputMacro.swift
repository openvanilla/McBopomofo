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

// MARK: Private Methods

fileprivate func formatDateWithStyle(calendarName:Calendar.Identifier, yearOffset: Int, dayOffset: Int, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
    let calendar = Calendar(identifier: calendarName)
    let now = Date()
    guard let dateAppendingYear = calendar.date(byAdding: .year, value: yearOffset, to: now),
          let dateAppendingDay = calendar.date(byAdding: .day, value: dayOffset, to: dateAppendingYear)
    else {
        return ""
    }
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    formatter.locale = Locale(identifier: calendarName == .japanese ? "ja_JP" : "zh_Hant_TW")
    return formatter.string(from: dateAppendingDay)
}

fileprivate func formatWithPattern(calendarName:Calendar.Identifier, yearOffset: Int, dayOffset: Int, pattern: String) -> String {
    let calendar = Calendar(identifier: calendarName)
    let now = Date()
    guard let dateAppendingYear = calendar.date(byAdding: .year, value: yearOffset, to: now),
          let dateAppendingDay = calendar.date(byAdding: .day, value: dayOffset, to: dateAppendingYear)
    else {
        return ""
    }
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.dateFormat = pattern
    formatter.locale = Locale(identifier: calendarName == .japanese ? "ja_JP" : "zh_Hant_TW")
    return formatter.string(from: dateAppendingDay)
}

fileprivate func formatDate(calendarName:Calendar.Identifier, dayOffset: Int, style: DateFormatter.Style) -> String {
    return formatDateWithStyle(calendarName: calendarName, yearOffset: 0, dayOffset: dayOffset, dateStyle: style, timeStyle: .none)
}

fileprivate func formatTime(style: DateFormatter.Style) -> String {
    return formatDateWithStyle(calendarName: .gregorian, yearOffset: 0, dayOffset: 0, dateStyle: .none, timeStyle: style)
}

fileprivate func formatTimeZone(style: TimeZone.NameStyle) -> String {
    let timezone = TimeZone.current
    let locale = Locale(identifier: "zh_Hant_TW")
    return timezone.localizedName(for: style, locale: locale) ?? ""
}

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


// MARK: - Protocols

protocol InputMacro {
    var name: String { get }
    var replacement: String { get }
}

fileprivate protocol InputMacroDate: InputMacro {
    var calendarName: Calendar.Identifier { get }
    var dayOffset: Int { get }
    var style: DateFormatter.Style { get }
}

extension InputMacroDate {
    var replacement: String {
        formatDate(calendarName: calendarName, dayOffset: dayOffset, style: style)
    }
}

fileprivate protocol InputMacroYear: InputMacro {
    var calendarName: Calendar.Identifier { get }
    var yearOffset: Int { get }
    var pattern: String { get }
}

extension InputMacroYear {
    var replacement: String {
        formatWithPattern(calendarName: calendarName, yearOffset: yearOffset, dayOffset: 0, pattern: pattern) + "年"
    }
}

fileprivate protocol InputMacroDayOfTheWeek: InputMacro {
    var calendarName: Calendar.Identifier { get }
    var dayOffset: Int { get }
    var pattern: String { get }
}

extension InputMacroDayOfTheWeek {
    var replacement: String {
        formatWithPattern(calendarName: calendarName, yearOffset: 0, dayOffset: dayOffset, pattern: pattern)
    }
}

fileprivate protocol InputMacroDateTime: InputMacro {
    var style: DateFormatter.Style { get }
}

extension InputMacroDateTime {
    var replacement: String { formatTime(style: style) }
}

fileprivate protocol InputMacroTimeZone: InputMacro {
    var style: TimeZone.NameStyle { get }
}

extension InputMacroTimeZone {
    var replacement: String { formatTimeZone(style: style) }
}

fileprivate protocol InputMacroTransform: InputMacro {
    var yearOffset: Int { get }
    var transform: (Int) -> (String) { get }
}

extension InputMacroTransform {
    var replacement: String {
        transform(getCurrentYear() + yearOffset)
    }
}

fileprivate protocol InputMacroGanZhi: InputMacroTransform {}

extension InputMacroGanZhi {
    var transform: (Int) -> (String) { ganzhi(year:) }
}

fileprivate protocol InputMacroZodiac: InputMacroTransform {}

extension InputMacroZodiac {
    var transform: (Int) -> (String) { chineseZodiac(year:) }
}



// MARK: - Date

struct InputMacroDateTodayShort: InputMacroDate {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 0 }
    var style: DateFormatter.Style { .short }
    var name: String { "MACRO@DATE_TODAY_SHORT" }
}

struct InputMacroDateTodayMedium: InputMacroDate {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 0 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_TODAY_MEDIUM" }
}

struct InputMacroDateTodayMediumRoc: InputMacroDate {
    var calendarName: Calendar.Identifier { .republicOfChina }
    var dayOffset: Int { 0 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_TODAY_MEDIUM_ROC" }
}

struct InputMacroDateTodayMediumChinese: InputMacroDate {
    var calendarName: Calendar.Identifier { .chinese }
    var dayOffset: Int { 0 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_TODAY_MEDIUM_CHINESE" }
}

struct InputMacroDateTodayMediumJapanese: InputMacroDate {
    var calendarName: Calendar.Identifier { .japanese }
    var dayOffset: Int { 0 }
    var style: DateFormatter.Style { .long }
    var name: String { "MACRO@DATE_TODAY_MEDIUM_JAPANESE" }
}

struct InputMacroDateYesterdayShort: InputMacroDate {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { -1 }
    var style: DateFormatter.Style { .short }
    var name: String { "MACRO@DATE_YESTERDAY_SHORT" }
}

struct InputMacroDateYesterdayMedium: InputMacroDate {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { -1 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_YESTERDAY_MEDIUM" }
}

struct InputMacroDateYesterdayMediumRoc: InputMacroDate {
    var calendarName: Calendar.Identifier { .republicOfChina }
    var dayOffset: Int { -1 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_YESTERDAY_MEDIUM_ROC" }
}

struct InputMacroDateYesterdayMediumChinese: InputMacroDate {
    var calendarName: Calendar.Identifier { .chinese }
    var dayOffset: Int { -1 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_YESTERDAY_MEDIUM_CHINESE" }
}

struct InputMacroDateYesterdayMediumJapanese: InputMacroDate {
    var calendarName: Calendar.Identifier { .japanese }
    var dayOffset: Int { -1 }
    var style: DateFormatter.Style { .long }
    var name: String { "MACRO@DATE_YESTERDAY_MEDIUM_JAPANESE" }
}

struct InputMacroDateTomorrowShort: InputMacroDate {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 1 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_TOMORROW_SHORT" }
}

struct InputMacroDateTomorrowMedium: InputMacroDate {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 1 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_TOMORROW_MEDIUM" }
}

struct InputMacroDateTomorrowMediumRoc: InputMacroDate {
    var calendarName: Calendar.Identifier { .republicOfChina }
    var dayOffset: Int { 1 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_TOMORROW_MEDIUM_ROC" }
}

struct InputMacroDateTomorrowMediumChinese: InputMacroDate {
    var calendarName: Calendar.Identifier { .chinese }
    var dayOffset: Int { 1 }
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@DATE_TOMORROW_MEDIUM_CHINESE" }
}

struct InputMacroDateTomorrowMediumJapanese: InputMacroDate {
    var calendarName: Calendar.Identifier { .japanese }
    var dayOffset: Int { 1 }
    var style: DateFormatter.Style { .long }
    var name: String { "MACRO@DATE_TOMORROW_MEDIUM_JAPANESE" }
}

// MARK: - Year

struct InputMacroThisYearPlain: InputMacroYear {
    var calendarName: Calendar.Identifier { .gregorian }
    var yearOffset: Int { 0 }
    var pattern: String { "y" }
    var name: String { "MACRO@THIS_YEAR_PLAIN" }
}

struct InputMacroThisYearPlainWithEra: InputMacroYear {
    var calendarName: Calendar.Identifier { .gregorian }
    var yearOffset: Int { 0 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@THIS_YEAR_PLAIN_WITH_ERA" }
}

struct InputMacroThisYearRoc: InputMacroYear {
    var calendarName: Calendar.Identifier { .republicOfChina }
    var yearOffset: Int { 0 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@THIS_YEAR_ROC" }
}

struct InputMacroThisYearJapanese: InputMacroYear {
    var calendarName: Calendar.Identifier { .japanese }
    var yearOffset: Int { 0 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@THIS_YEAR_JAPANESE" }
}

struct InputMacroLastYearPlain: InputMacroYear {
    var calendarName: Calendar.Identifier { .gregorian }
    var yearOffset: Int { -1 }
    var pattern: String { "y" }
    var name: String { "MACRO@LAST_YEAR_PLAIN" }
}

struct InputMacroLastYearPlainWithEra: InputMacroYear {
    var calendarName: Calendar.Identifier { .gregorian }
    var yearOffset: Int { -1 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@LAST_YEAR_PLAIN_WITH_ERA" }
}

struct InputMacroLastYearRoc: InputMacroYear {
    var calendarName: Calendar.Identifier { .republicOfChina }
    var yearOffset: Int { -1 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@LAST_YEAR_ROC" }
}

struct InputMacroLastYearJapanese: InputMacroYear {
    var calendarName: Calendar.Identifier { .japanese }
    var yearOffset: Int { -1 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@LAST_YEAR_JAPANESE" }
}

struct InputMacroNextYearPlain: InputMacroYear {
    var calendarName: Calendar.Identifier { .gregorian }
    var yearOffset: Int { 1 }
    var pattern: String { "y" }
    var name: String { "MACRO@NEXT_YEAR_PLAIN" }
}

struct InputMacroNextYearPlainWithEra: InputMacroYear {
    var calendarName: Calendar.Identifier { .gregorian }
    var yearOffset: Int { 1 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@NEXT_YEAR_PLAIN_WITH_ERA" }
}

struct InputMacroNextYearRoc: InputMacroYear {
    var calendarName: Calendar.Identifier { .republicOfChina }
    var yearOffset: Int { 1 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@NEXT_YEAR_PLAIN_WITH_ERA" }
}

struct InputMacroNextYearJapanese: InputMacroYear {
    var calendarName: Calendar.Identifier { .japanese }
    var yearOffset: Int { 1 }
    var pattern: String { "Gy" }
    var name: String { "MACRO@NEXT_YEAR_JAPANESE" }
}

// MARK: - Day of the Week

struct InputMacroWeekdayTodayShort: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 0 }
    var pattern: String { "E" }
    var name: String { "MACRO@DATE_TODAY_WEEKDAY_SHORT" }
}

struct InputMacroWeekdayToday: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 0 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_TODAY_WEEKDAY" }
}

struct InputMacroWeekdayToday2: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 0 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_TODAY2_WEEKDAY" }

    var replacement: String {
        let original = formatWithPattern(calendarName: calendarName, yearOffset: 0, dayOffset: dayOffset, pattern: pattern)
        return original.replacingOccurrences(of: "星期", with: "禮拜")
    }
}

struct InputMacroWeekdayTodayJapanese: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .japanese }
    var dayOffset: Int { 0 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_TODAY_WEEKDAY_JAPANESE" }
}

struct InputMacroWeekdayYesterdayShort: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { -1 }
    var pattern: String { "E" }
    var name: String { "MACRO@DATE_YESTERDAY_WEEKDAY_SHORT" }
}

struct InputMacroWeekdayYesterday: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { -1 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_YESTERDAY_WEEKDAY" }
}

struct InputMacroWeekdayYesterday2: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { -1 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_YESTERDAY2_WEEKDAY" }

    var replacement: String {
        let original = formatWithPattern(calendarName: calendarName, yearOffset: 0, dayOffset: dayOffset, pattern: pattern)
        return original.replacingOccurrences(of: "星期", with: "禮拜")
    }
}

struct InputMacroWeekdayYesterdayJapanese: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .japanese }
    var dayOffset: Int { -1 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_YESTERDAY_WEEKDAY_JAPANESE" }
}

struct InputMacroWeekdayTomorrowShort: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 1 }
    var pattern: String { "E" }
    var name: String { "MACRO@DATE_TOMORROW_WEEKDAY_SHORT" }
}

struct InputMacroWeekdayTomorrow: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 1 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_TOMORROW_WEEKDAY" }
}

struct InputMacroWeekdayTomorrow2: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .gregorian }
    var dayOffset: Int { 1 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_TOMORROW2_WEEKDAY" }
}

struct InputMacroWeekdayTomorrowJapanese: InputMacroDayOfTheWeek {
    var calendarName: Calendar.Identifier { .japanese }
    var dayOffset: Int { 1 }
    var pattern: String { "EEEE" }
    var name: String { "MACRO@DATE_TOMORROW_WEEKDAY_JAPANESE" }
}

// MARK: - Datetime

struct InputMacroDateTimeNowShort: InputMacroDateTime {
    var style: DateFormatter.Style { .short }
    var name: String { "MACRO@TIME_NOW_SHORT" }
}

struct InputMacroDateTimeNowMedium: InputMacroDateTime {
    var style: DateFormatter.Style { .medium }
    var name: String { "MACRO@TIME_NOW_MEDIUM" }
}

// MARK: - Time Zone

struct InputMacroTimeZoneStandard: InputMacroTimeZone {
    var style: TimeZone.NameStyle { .standard }
    var name: String { "MACRO@TIMEZONE_STANDARD" }
}

struct InputMacroTimeZoneShortGeneric: InputMacroTimeZone {
    var style: TimeZone.NameStyle { .shortGeneric }
    var name: String { "MACRO@TIMEZONE_GENERIC_SHORT" }
}

// MARK: - Ganzhi

struct InputMacroThisYearGanZhi: InputMacroGanZhi {
    var yearOffset: Int { 0 }
    var name: String { "MACRO@THIS_YEAR_GANZHI" }
}

struct InputMacroLastYearGanZhi: InputMacroGanZhi {
    var yearOffset: Int { -1 }
    var name: String { "MACRO@LAST_YEAR_GANZHI" }
}

struct InputMacroNextYearGanZhi: InputMacroGanZhi {
    var yearOffset: Int { 1 }
    var name: String { "MACRO@NEXT_YEAR_GANZHI" }
}

// MARK: - Chinese Zodiac

struct InputMacroThisYearChineseZodiac: InputMacroZodiac {
    var yearOffset: Int { 0 }
    var name: String { "MACRO@THIS_YEAR_CHINESE_ZODIAC" }
}

struct InputMacroLastYearChineseZodiac: InputMacroZodiac {
    var yearOffset: Int { 0 }
    var name: String { "MACRO@LAST_YEAR_CHINESE_ZODIAC" }
}

struct InputMacroNextYearChineseZodiac: InputMacroZodiac {
    var yearOffset: Int { 0 }
    var name: String { "MACRO@NEXT_YEAR_CHINESE_ZODIAC" }
}



// MARK: - InputMacroController

class InputMacroController: NSObject {
    @objc
    static let shared = InputMacroController()

    private var macros: [String: InputMacro] = {
        let macros: [InputMacro] = [
           InputMacroDateTodayShort(),
           InputMacroDateTodayMedium(),
           InputMacroDateTodayMediumRoc(),
           InputMacroDateTodayMediumChinese(),
           InputMacroDateTodayMediumJapanese(),
           InputMacroThisYearPlain(),
           InputMacroThisYearPlainWithEra(),
           InputMacroThisYearRoc(),
           InputMacroThisYearJapanese(),
           InputMacroLastYearPlain(),
           InputMacroLastYearPlainWithEra(),
           InputMacroLastYearRoc(),
           InputMacroLastYearJapanese(),
           InputMacroNextYearPlain(),
           InputMacroNextYearPlainWithEra(),
           InputMacroNextYearRoc(),
           InputMacroNextYearJapanese(),
           InputMacroWeekdayTodayShort(),
           InputMacroWeekdayToday(),
           InputMacroWeekdayToday2(),
           InputMacroWeekdayTodayJapanese(),
           InputMacroWeekdayYesterdayShort(),
           InputMacroWeekdayYesterday(),
           InputMacroWeekdayYesterday2(),
           InputMacroWeekdayYesterdayJapanese(),
           InputMacroWeekdayTomorrowShort(),
           InputMacroWeekdayTomorrow(),
           InputMacroWeekdayTomorrow2(),
           InputMacroWeekdayTomorrowJapanese(),
           InputMacroDateYesterdayShort(),
           InputMacroDateYesterdayMedium(),
           InputMacroDateYesterdayMediumRoc(),
           InputMacroDateYesterdayMediumChinese(),
           InputMacroDateYesterdayMediumJapanese(),
           InputMacroDateTomorrowShort(),
           InputMacroDateTomorrowMedium(),
           InputMacroDateTomorrowMediumRoc(),
           InputMacroDateTomorrowMediumChinese(),
           InputMacroDateTomorrowMediumJapanese(),
           InputMacroDateTimeNowShort(),
           InputMacroDateTimeNowMedium(),
           InputMacroTimeZoneStandard(),
           InputMacroTimeZoneShortGeneric(),
           InputMacroThisYearGanZhi(),
           InputMacroLastYearGanZhi(),
           InputMacroNextYearGanZhi(),
           InputMacroThisYearChineseZodiac(),
           InputMacroLastYearChineseZodiac(),
           InputMacroNextYearChineseZodiac(),
        ]
        var map: [String: InputMacro] = [:]
        macros.forEach { macro in
            map[macro.name] = macro
        }
        return map
    }()


    @objc
    func handle(_ input: String) -> String {
        if let macro = macros[input] {
            return macro.replacement
        }
        return input
    }

}

