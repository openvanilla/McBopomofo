import XCTest
@testable import NSStringUtils

final class NSStringUtilsTests: XCTestCase {
    func testNextWith🌳_0() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.nextUtf16Position(for: 0), 2)
    }

    func testNextWith🌳_1() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.nextUtf16Position(for: 1), 2)
    }

    func testNextWith🌳_2() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.nextUtf16Position(for: 2), 4)
    }

    func testNextWith🌳_3() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.nextUtf16Position(for: 3), 4)
    }

    func testNextWith🌳_4() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.nextUtf16Position(for: 4), 4)
    }

    func testNextWith🌳_5() {
        let s = NSString("🌳🌳🌳")
        XCTAssertEqual(s.nextUtf16Position(for: 4), 6)
    }

    func testPrevWith🌳_0() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 0), 0)
    }

    func testPrevWith🌳_1() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 1), 0)
    }

    func testINextWith🌳_2() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 2), 0)
    }

    func testINextWith🌳_3() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 3), 0)
    }

    func testINextWith🌳_4() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 4), 2)
    }

}
