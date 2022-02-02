// Copyright (c) 2011 and onwards The McBopomofo Authors.
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
