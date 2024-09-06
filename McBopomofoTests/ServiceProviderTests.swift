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
        XCTAssert(output == "ㄒㄧㄠ-ㄅㄛ-ㄎㄨㄞˋ")
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

    func testAddReading() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let input = "美好的朝陽"
        let expected = "美(ㄇㄟˇ)好(ㄏㄠˇ)的(ㄉㄜ˙)朝(ㄓㄠ)陽(ㄧㄤˊ)"
        let output = provider.addReading(string: input)
        XCTAssert(output == expected, output)
    }

    func testTokenize1() {
        let provider = ServiceProvider()
        let output = provider.tokenize(string: "『『』『』『")
        let expected = ["『", "『", "』", "『", "』", "『"]
        XCTAssert(output.map { $0.0 } == expected, "\(output)")
    }

    func testTokenize2() {
        let provider = ServiceProvider()
        let output = provider.tokenize(string: "『這樣可以嗎？』")
        let expected = ["『", "這樣", "可以", "嗎", "？", "』"]
        XCTAssert(output.map { $0.0 } == expected, "\(output)")
    }

    func testAddReading2() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let input = "『這樣可以嗎？』我相當好奇的問了他，但是還是不知道他的意思"
        let expected =
            "『這(ㄓㄜˋ)樣(ㄧㄤˋ)可(ㄎㄜˇ)以(ㄧˇ)嗎(ㄇㄚ)？』我(ㄨㄛˇ)相(ㄒㄧㄤ)當(ㄉㄤ)好(ㄏㄠˋ)奇(ㄑㄧˊ)的(ㄉㄜ˙)問(ㄨㄣˋ)了(ㄌㄜ˙)他(ㄊㄚ)，但(ㄉㄢˋ)是(ㄕˋ)還(ㄏㄞˊ)是(ㄕˋ)不(ㄅㄨˊ)知(ㄓ)道(ㄉㄠˋ)他(ㄊㄚ)的(ㄉㄜ˙)意(ㄧˋ)思(ㄙ)"
        let output = provider.addReading(string: input)
        XCTAssert(output == expected, output)
    }

    func testConvertBrailleToChinese1() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "⠰⠤⠋⠺⠂⠻⠄⠛⠥⠂⠓⠫⠐⠑⠳⠄⠪⠐⠙⠮⠁⠅⠎⠐⠊⠱⠐⠑⠪⠄⠏⠣⠄⠇⠶⠐⠤⠆"
        let expected = "「台灣人最需要的就是消波塊」"
        let output = provider.convertBrailleToChineseText(string: input)
        XCTAssert(output == expected, output)
    }

    func testConvertBrailleToChinese2() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "⠰⠤⠋⠺⠂⠻⠄⠛⠥⠂⠓⠫⠐⠑⠳⠄⠪⠐⠙⠮⠁⠅⠎⠐⠊⠱⠐⠑⠪⠄⠏⠣⠄⠇⠶⠐⠤⠆"
        let expected = "「台灣人最需要的就是消波塊」"
        let output = provider.convertBrailleToChineseText(string: input)
        XCTAssert(output == expected, output)
    }

    func testConvertBrailleThenBack1() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "由「小麥」的作者"
        let r1 = provider.convertToBraille(string: input)
        print(r1)
        let r2 = provider.convertBrailleToChineseText(string: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBrailleThenBack2() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "This is a test"
        let r1 = provider.convertToBraille(string: input)
        let r2 = provider.convertBrailleToChineseText(string: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBrailleThenBack3() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "第1名"
        let r1 = provider.convertToBraille(string: input)
        XCTAssert(r1 == "⠙⠡⠐ ⠼⠂ ⠍⠽⠂", r1)
        let r2 = provider.convertBrailleToChineseText(string: r1)
        XCTAssert(r2 == "地 1 明", r2)
    }

    func testConvertBrailleThenBack4() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "第A名"
        let r1 = provider.convertToBraille(string: input)
        let r2 = provider.convertBrailleToChineseText(string: r1)
        XCTAssert(r2 == "地 A 明", r2)
    }

    func testConvertBrailleThenBack5() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "第AB名"
        let r1 = provider.convertToBraille(string: input)
        let r2 = provider.convertBrailleToChineseText(string: r1)
        XCTAssert(r2 == "地 AB 明", r2)
    }

    func testConvertBrailleThenBack6() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let input = "第A1名"
        let r1 = provider.convertToBraille(string: input)
        let r2 = provider.convertBrailleToChineseText(string: r1)
        XCTAssert(r2 == "地 A1 明", r2)
    }

    func testLetters1() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let result = provider.convertToBraille(string: "This is a test")
        XCTAssert(result == "⠠⠞⠓⠊⠎ ⠊⠎ ⠁ ⠞⠑⠎⠞")
    }

    func testLetters2() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let result = provider.convertToBraille(string: "This is a test 台灣人最需要的就是消波塊")
        XCTAssert(result == "⠠⠞⠓⠊⠎ ⠊⠎ ⠁ ⠞⠑⠎⠞ ⠋⠺⠂⠻⠄⠛⠥⠂⠓⠫⠐⠑⠳⠄⠪⠐⠙⠮⠁⠅⠎⠐⠊⠱⠐⠑⠪⠄⠏⠣⠄⠇⠶⠐", result)
    }

    func testDigit() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let result = provider.convertToBraille(string: "24")
        XCTAssert(result == "⠼⠆⠲", result)
    }


}
