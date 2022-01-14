import XCTest
@testable import VXHanConvert

final class VXHanConvertTests: XCTestCase {
    func testSC2TC() {
        let text = "简体中文转繁体中文"
        let converted = VXHanConvert.convertToTraditional(from: text)
        XCTAssert(converted == "簡體中文轉繁體中文")
    }

    func testTC2SC() {
        let text = "繁體中文轉簡體中文"
        let converted = VXHanConvert.convertToSimplified(from: text)
        XCTAssert(converted == "繁体中文转简体中文")
    }
}
