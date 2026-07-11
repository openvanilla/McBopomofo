// Copyright (c) 2026 and onwards The McBopomofo Authors.
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

import Testing
@testable import SystemCharacterInfo

@Test
func testUnihanDictionary1() async throws {
    let dict = try UnihanDictionary()
    let result = try dict.read(string: "上")
    #expect(result.canjie == "卜一")
    #expect(result.canjieKeys == "YM")
}

@Test
func testUnihanDictionary2() async throws {
    let dict = try UnihanDictionary()
    let result = try dict.read(string: "台")
    #expect(result.canjie == "戈口")
    #expect(result.canjieKeys == "IR")
}

@Test
func testUnihanDictionary3() async throws {
    let dict = try UnihanDictionary()
    let result = try dict.read(string: "爽")
    #expect(result.canjie == "大大大大")
    #expect(result.canjieKeys == "KKKK")
}
