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

import XCTest
@testable import McBopomofo

class InputMacroTests: XCTestCase {

    func testNotMacro() {
        let macro = "MACRO@NONE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(macro == output)
    }

    func testThisYearPlain() {
        let macro = "MACRO@THIS_YEAR_PLAIN"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testThisYear() {
        let macro = "MACRO@THIS_YEAR_PLAIN_WITH_ERA"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output.starts(with: "西元"))
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testThisYearRoc() {
        let macro = "MACRO@THIS_YEAR_ROC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output.starts(with: "民國"))
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testThisYearJapanese() {
        let macro = "MACRO@THIS_YEAR_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testLastYearPlain() {
        let macro = "MACRO@LAST_YEAR_PLAIN"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }


    func testLastYear() {
        let macro = "MACRO@LAST_YEAR_PLAIN_WITH_ERA"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output.starts(with: "西元"))
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testLastYearRoc() {
        let macro = "MACRO@LAST_YEAR_ROC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output.starts(with: "民國"))
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testLastYearJapanese() {
        let macro = "MACRO@LAST_YEAR_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testNextYearPlain() {
        let macro = "MACRO@NEXT_YEAR_PLAIN"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testNextYear() {
        let macro = "MACRO@NEXT_YEAR_PLAIN_WITH_ERA"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output.starts(with: "西元"))
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testNextYearRoc() {
        let macro = "MACRO@NEXT_YEAR_ROC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output.starts(with: "民國"))
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testNextYearJapanese() {
        let macro = "MACRO@NEXT_YEAR_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testTodayShort() {
        let macro = "MACRO@DATE_TODAY_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let components = output.split(separator: "/").map { substring in
            String(substring)
        }
        let year = components[0]
        let month = components[1]
        let day = components[2]
        XCTAssertTrue(Int(year) ?? 0 >= 2023)
        XCTAssertTrue(Int(month) ?? 0 >= 1 && Int(month) ?? 0 <= 12)
        XCTAssertTrue(Int(day) ?? 0 >= 1 && Int(month) ?? 0 <= 31)
    }

    func testYesterdayShort() {
        let macro = "MACRO@DATE_YESTERDAY_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let components = output.split(separator: "/").map { substring in
            String(substring)
        }
        let year = components[0]
        let month = components[1]
        let day = components[2]
        XCTAssertTrue(Int(year) ?? 0 >= 2023)
        XCTAssertTrue(Int(month) ?? 0 >= 1 && Int(month) ?? 0 <= 12)
        XCTAssertTrue(Int(day) ?? 0 >= 1 && Int(month) ?? 0 <= 31)
    }

    func testTomorrowShort() {
        let macro = "MACRO@DATE_TOMORROW_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let components = output.split(separator: "/").map { substring in
            String(substring)
        }
        let year = components[0]
        let month = components[1]
        let day = components[2]
        XCTAssertTrue(Int(year) ?? 0 >= 2023)
        XCTAssertTrue(Int(month) ?? 0 >= 1 && Int(month) ?? 0 <= 12)
        XCTAssertTrue(Int(day) ?? 0 >= 1 && Int(month) ?? 0 <= 31)
    }

    func testTodayMedium() {
        let macro = "MACRO@DATE_TODAY_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testYesterdayMedium() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testTomorrowMedium() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testTodayMediumRoc() {
        let macro = "MACRO@DATE_TODAY_MEDIUM_ROC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("民國"))
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testYesterdayMediumRoc() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM_ROC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("民國"))
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testYesterdayTomorrowRoc() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM_ROC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("民國"))
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testTodayMediumChinese() {
        let macro = "MACRO@DATE_TODAY_MEDIUM_CHINESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
    }

    func testYesterdayMediumChinese() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM_CHINESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
    }

    func testTomorrowMediumChinese() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM_CHINESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
    }

    func testTodayLongJapanese() {
        let macro = "MACRO@DATE_TODAY_MEDIUM_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testYesterdayLongJapanese() {
        let macro = "MACRO@DATE_YESTERDAY_MEDIUM_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testTomorrowLongJapanese() {
        let macro = "MACRO@DATE_TOMORROW_MEDIUM_JAPANESE"
        let output = InputMacroController.shared.handle(macro)
        XCTAssert(output.contains("年"))
        XCTAssert(output.contains("月"))
        XCTAssert(output.contains("日"))
    }

    func testTimeNowShort() {
        let macro = "MACRO@TIME_NOW_SHORT"
        let output = InputMacroController.shared.handle(macro)
        let numberPath = output[output.index(output.startIndex, offsetBy: 2)...]
        let numberComponents = String(numberPath).split(separator: ":")
        let hour = numberComponents[0]
        let min = numberComponents[1]
        XCTAssert(Int(hour) ?? -1 >= 0 && Int(hour) ?? -1 <= 12)
        XCTAssert(Int(min) ?? -1 >= 0 && Int(min) ?? -1 <= 59)
    }

    func testTimeNowMedium() {
        let macro = "MACRO@TIME_NOW_MEDIUM"
        let output = InputMacroController.shared.handle(macro)
        let numberPath = output[output.index(output.startIndex, offsetBy: 2)...]
        let numberComponents = String(numberPath).split(separator: ":")
        let hour = numberComponents[0]
        let min = numberComponents[1]
        let sec = numberComponents[2]
        XCTAssert(Int(hour) ?? -1 >= 0 && Int(hour) ?? -1 <= 12)
        XCTAssert(Int(min) ?? -1 >= 0 && Int(min) ?? -1 <= 59)
        XCTAssert(Int(sec) ?? -1 >= 0 && Int(sec) ?? -1 <= 59)
    }

    func testThisYearGanzhi() {
        let macro = "MACRO@THIS_YEAR_GANZHI"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testLastYearGanzhi() {
        let macro = "MACRO@LAST_YEAR_GANZHI"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testNextYearGanzhi() {
        let macro = "MACRO@NEXT_YEAR_GANZHI"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testThisYearChineseZodiac() {
        let macro = "MACRO@THIS_YEAR_CHINESE_ZODIAC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testLastYearChineseZodiac() {
        let macro = "MACRO@LAST_YEAR_CHINESE_ZODIAC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

    func testNextYearChineseZodiac() {
        let macro = "MACRO@NEXT_YEAR_CHINESE_ZODIAC"
        let output = InputMacroController.shared.handle(macro)
        XCTAssertTrue(output[output.index(output.endIndex, offsetBy: -1)] == "年")
    }

}

