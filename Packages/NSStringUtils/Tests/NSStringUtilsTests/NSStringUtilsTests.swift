import XCTest
@testable import NSStringUtils

final class NSStringUtilsTests: XCTestCase {

    func testNextNormal_0() {
        let s = NSString("中文")
        XCTAssertEqual(s.nextUtf16Position(for: 0), 1)
    }

    func testNextNormal_1() {
        let s = NSString("中文")
        XCTAssertEqual(s.nextUtf16Position(for: 1), 2)
    }

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

    func testPrevNormal_0() {
        let s = NSString("中文")
        XCTAssertEqual(s.previousUtf16Position(for: 1), 0)
    }

    func testPrevNormal_1() {
        let s = NSString("中文")
        XCTAssertEqual(s.previousUtf16Position(for: 2), 1)
    }

    func testPrevWith🌳_0() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 0), 0)
    }

    func testPrevWith🌳_1() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 1), 0)
    }

    func testPrevWith🌳_2() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 2), 0)
    }

    func testPrevWith🌳_3() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 3), 0)
    }

    func testPrevWith🌳_4() {
        let s = NSString("🌳🌳")
        XCTAssertEqual(s.previousUtf16Position(for: 4), 2)
    }

}
