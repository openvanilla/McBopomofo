import XCTest
@testable import ChineseNumbers

final class ChineseNumbersTests: XCTestCase {
    func testTrimmingZerosAtStart1() {
        let input = "00001111"
        let output = input.trimmingZerosAtStart()
        XCTAssertEqual(output, "1111")
    }

    func testTrimmingZerosAtStart2() {
        let input = "00001111000"
        let output = input.trimmingZerosAtStart()
        XCTAssertEqual(output, "1111000")
    }

    func testTrimmingZerosAtEnd1() {
        let input = "1111000"
        let output = input.trimmingZerosAtEnd()
        XCTAssertEqual(output, "1111")
    }

    func testTrimmingZerosAtEnd2() {
        let input = "00001111000"
        let output = input.trimmingZerosAtEnd()
        XCTAssertEqual(output, "00001111")
    }

    func testNum1() {
        let intInput = "11000"
        let decInput = "0000"
        let output = ChineseNumbers.generate(intPart: intInput, decPart: decInput, digitCase: .lowercase)
        XCTAssertEqual(output, "一萬一千")
    }

    func testNum2() {
        let intInput = "11111"
        let decInput = "0000"
        let output = ChineseNumbers.generate(intPart: intInput, decPart: decInput, digitCase: .lowercase)
        XCTAssertEqual(output, "一萬一千一百一十一")
    }

    func testNum3() {
        let intInput = "100000001"
        let decInput = "0000"
        let output = ChineseNumbers.generate(intPart: intInput, decPart: decInput, digitCase: .lowercase)
        XCTAssertEqual(output, "一億〇一")
    }

    func testNum4() {
        let intInput = "1"
        let decInput = "99999"
        let output = ChineseNumbers.generate(intPart: intInput, decPart: decInput, digitCase: .lowercase)
        XCTAssertEqual(output, "一點九九九九九")
    }

    func testNum5() {
        let intInput = "1"
        let decInput = "99999"
        let output = ChineseNumbers.generate(intPart: intInput, decPart: decInput, digitCase: .uppercase)
        XCTAssertEqual(output, "壹點玖玖玖玖玖")
    }

}
