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

import Cocoa
import Testing

@testable import NSStringUtils

@Suite("Test NSStringUtils")
final class NSStringUtilsTests {

    @Test("Test nextUtf16Position", arguments: [
        ("中文", 0, 1),
        ("中文", 1, 2),
        ("🌳🌳", 0, 2),
        ("🌳🌳", 1, 2),
        ("🌳🌳", 2, 4),
        ("🌳🌳", 3, 4),
        ("🌳🌳", 4, 4),
        ("🌳🌳🌳", 4, 6),
    ])
    func testNextUtf16Position(text: String, from: Int, expected: Int) {
        let s = NSString(string: text)
        #expect(s.nextUtf16Position(for: from) == expected)
    }

    @Test("Test previousUtf16Position", arguments: [
        ("中文", 1, 0),
        ("中文", 2, 1),
        ("🌳🌳", 0, 0),
        ("🌳🌳", 1, 0),
        ("🌳🌳", 2, 0),
        ("🌳🌳", 3, 0),
        ("🌳🌳", 4, 2),
    ])
    func testPrevNormal_0(text: String, from: Int, expected: Int) {
        let s = NSString(string: text)
        #expect(s.previousUtf16Position(for: from) == expected)
    }
}
