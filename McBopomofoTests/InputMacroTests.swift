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

import Testing

@testable import McBopomofo

@Suite("Test macros")
final class InputMacroTests {

    @Test func testNotMacro() {
        let macro = "MACRO@NONE"
        let output = InputMacroController.shared.handle(macro)
        #expect(macro == output)
    }

    @Test func testThisYearPlain() {
        let macro = "MACRO@THIS_YEAR_PLAIN"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testThisYear() {
        let macro = "MACRO@THIS_YEAR_PLAIN_WITH_ERA"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.starts(with: "西元"))
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testThisYearRoc() {
        let macro = "MACRO@THIS_YEAR_ROC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.starts(with: "民國"))
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testThisYearJapanese() {
        let macro = "MACRO@THIS_YEAR_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testLastYearPlain() {
        let macro = "MACRO@LAST_YEAR_PLAIN"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testLastYear() {
        let macro = "MACRO@LAST_YEAR_PLAIN_WITH_ERA"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.starts(with: "西元"))
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testLastYearRoc() {
        let macro = "MACRO@LAST_YEAR_ROC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.starts(with: "民國"))
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testLastYearJapanese() {
        let macro = "MACRO@LAST_YEAR_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testNextYearPlain() {
        let macro = "MACRO@NEXT_YEAR_PLAIN"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testNextYear() {
        let macro = "MACRO@NEXT_YEAR_PLAIN_WITH_ERA"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.starts(with: "西元"))
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testNextYearRoc() {
        let macro = "MACRO@NEXT_YEAR_ROC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.starts(with: "民國"))
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testNextYearJapanese() {
        let macro = "MACRO@NEXT_YEAR_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testTodayShort() {
        let macro = "MACRO@DATE_TODAY_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let components = output.split(separator: "/").map { substring in
            String(substring)
        }
        let year = components[0]
        let month = components[1]
        let day = components[2]
        #expect(Int(year) ?? 0 >= 2023)
        #expect(Int(month) ?? 0 >= 1 && Int(month) ?? 0 <= 12)
        #expect(Int(day) ?? 0 >= 1 && Int(month) ?? 0 <= 31)
    }

    @Test func testYesterdayShort() {
        let macro = "MACRO@DATE_YESTERDAY_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let components = output.split(separator: "/").map { substring in
            String(substring)
        }
        let year = components[0]
        let month = components[1]
        let day = components[2]
        #expect(Int(year) ?? 0 >= 2023)
        #expect(Int(month) ?? 0 >= 1 && Int(month) ?? 0 <= 12)
        #expect(Int(day) ?? 0 >= 1 && Int(month) ?? 0 <= 31)
    }

    @Test func testTomorrowShort() {
        let macro = "MACRO@DATE_TOMORROW_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let components = output.split(separator: "/").map { substring in
            String(substring)
        }
        let year = components[0]
        let month = components[1]
        let day = components[2]
        #expect(Int(year) ?? 0 >= 2023)
        #expect(Int(month) ?? 0 >= 1 && Int(month) ?? 0 <= 12)
        #expect(Int(day) ?? 0 >= 1 && Int(month) ?? 0 <= 31)
    }

    @Test func testTodayMedium() {
        let macro = "MACRO@DATE_TODAY_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testYesterdayMedium() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testTomorrowMedium() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testTodayMediumRoc() {
        let macro = "MACRO@DATE_TODAY_MEDIUM_ROC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("民國"))
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testYesterdayMediumRoc() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM_ROC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("民國"))
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testYesterdayTomorrowRoc() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM_ROC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("民國"))
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testTodayMediumChinese() {
        let macro = "MACRO@DATE_TODAY_MEDIUM_CHINESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
    }

    @Test func testYesterdayMediumChinese() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM_CHINESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
    }

    @Test func testTomorrowMediumChinese() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM_CHINESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
    }

    @Test func testTodayLongJapanese() {
        let macro = "MACRO@DATE_TODAY_MEDIUM_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testYesterdayLongJapanese() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testTomorrowLongJapanese() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        #expect(output.contains("年"))
        #expect(output.contains("月"))
        #expect(output.contains("日"))
    }

    @Test func testTimeNowShort() {
        let macro = "MACRO@TIME_NOW_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let numberPath = output[output.index(output.startIndex, offsetBy: 2)...]
        let numberComponents = String(numberPath).split(separator: ":")
        let hour = numberComponents[0]
        let min = numberComponents[1]
        #expect(Int(hour) ?? -1 >= 0 && Int(hour) ?? -1 <= 12)
        #expect(Int(min) ?? -1 >= 0 && Int(min) ?? -1 <= 59)
    }

    @Test func testTimeNowMedium() {
        let macro = "MACRO@TIME_NOW_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        let numberPath = output[output.index(output.startIndex, offsetBy: 2)...]
        let numberComponents = String(numberPath).split(separator: ":")
        let hour = numberComponents[0]
        let min = numberComponents[1]
        let sec = numberComponents[2]
        #expect(Int(hour) ?? -1 >= 0 && Int(hour) ?? -1 <= 12)
        #expect(Int(min) ?? -1 >= 0 && Int(min) ?? -1 <= 59)
        #expect(Int(sec) ?? -1 >= 0 && Int(sec) ?? -1 <= 59)
    }

    @Test func testThisYearGanzhi() {
        let macro = "MACRO@THIS_YEAR_GANZHI"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testLastYearGanzhi() {
        let macro = "MACRO@LAST_YEAR_GANZHI"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testNextYearGanzhi() {
        let macro = "MACRO@NEXT_YEAR_GANZHI"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testThisYearChineseZodiac() {
        let macro = "MACRO@THIS_YEAR_CHINESE_ZODIAC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testLastYearChineseZodiac() {
        let macro = "MACRO@LAST_YEAR_CHINESE_ZODIAC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    @Test func testNextYearChineseZodiac() {
        let macro = "MACRO@NEXT_YEAR_CHINESE_ZODIAC"
        let output = InputMacroController.shared.handle(macro)
        #expect(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

}
