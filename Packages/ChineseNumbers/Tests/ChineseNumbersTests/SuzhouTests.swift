// Copyright (c) 2022 and onwards The McBopomofo Authors.
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
