import XCTest
@testable import McBopomofo

final class ServiceProviderTests: XCTestCase {
    func testExtractReading0() {
        let provider = ServiceProvider()
        let output = provider.extractReading(from: "")
        XCTAssert(output == "", output)
    }

    func testExtractReading1() {
        let provider = ServiceProvider()
        let output = provider.extractReading(from: "消波塊")
        XCTAssert(output == "ㄒㄧㄠ-ㄆㄛ-ㄎㄨㄞˋ")
    }

    func testExtractReading2() {
        let provider = ServiceProvider()
        let output = provider.extractReading(from: "🔥🔥🔥")
        XCTAssert(output == "ㄏㄨㄛˇ-ㄏㄨㄛˇ-ㄏㄨㄛˇ")
    }

    func testExtractReading3() {
        let provider = ServiceProvider()
        let output = provider.extractReading(from: "🔥")
        XCTAssert(output == "ㄏㄨㄛˇ")
    }

    func testExtractReading4() {
        let provider = ServiceProvider()
        let output = provider.extractReading(from: " ")
        XCTAssert(output == "？", output)
    }

    func testExtractReading5() {
        let provider = ServiceProvider()
        let output = provider.extractReading(from: "！")
        XCTAssert(output == "_ctrl_punctuation_!", output)
    }
}
