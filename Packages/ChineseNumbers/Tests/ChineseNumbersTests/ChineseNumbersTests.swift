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

    func testSuzhou1() {
        let intInput = "1000"
        let decInput = "0000"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput)
        XCTAssertEqual(output, "〡\n千")
    }

    func testSuzhou2() {
        let intInput = "1234"
        let decInput = "0000"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput)
        XCTAssertEqual(output, "〡二〣〤\n千")
    }

    func testSuzhou3() {
        let intInput = "2222"
        let decInput = "0000"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput)
        XCTAssertEqual(output, "〢二〢二\n千")
    }

    func testSuzhou4() {
        let intInput = "0022"
        let decInput = "2200"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput)
        XCTAssertEqual(output, "〢二〢二\n十")
    }

    func testSuzhou5() {
        let intInput = "0022"
        let decInput = "2200"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput, preferInitialVertical: false)
        XCTAssertEqual(output, "二〢二〢\n十")
    }

    func testSuzhou6() {
        let intInput = "0010"
        let decInput = "0000"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput, preferInitialVertical: false)
        XCTAssertEqual(output, "〸")
    }


}
