import XCTest

@testable import ChineseNumbers

final class SuzhouTests: XCTestCase {

    func testSuzhou1() {
        let intInput = "1000"
        let decInput = "0000"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput)
        XCTAssertEqual(output, "〡千")
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

    func testSuzhou7() {
        let intInput = "1010"
        let decInput = "0000"
        let output = SuzhouNumbers.generate(intPart: intInput, decPart: decInput, preferInitialVertical: true)
        let expected = "〡〇〡\n千"
        XCTAssertEqual(output, expected)

    }
}
