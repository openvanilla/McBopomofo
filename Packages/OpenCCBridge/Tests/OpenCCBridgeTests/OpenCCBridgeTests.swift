import XCTest
@testable import OpenCCBridge

final class OpenCCBridgeTests: XCTestCase {
    func testTC2SC() throws {
        let text = "繁體中文轉簡體中文"
        let converted = OpenCCBridge.convertToSimplified(text)
        XCTAssert(converted == "繁体中文转简体中文")
    }
}
