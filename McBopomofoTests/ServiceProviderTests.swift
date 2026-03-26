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

import AppKit
import Testing

@testable import McBopomofo

@Suite("Test the service provider", .serialized)
final class ServiceProviderTests {
    private func makePasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
    }

    private func write(_ string: String, to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(string, forType: .string)
    }

    private func read(from pasteboard: NSPasteboard) -> String? {
        pasteboard.string(forType: .string)
    }

    @Test(
        "Test extrct reading",
        arguments: [
            ("", ""),
            ("電腦", "ㄉㄧㄢˋ-ㄋㄠˇ"),
            ("🔥🔥🔥", "ㄏㄨㄛˇ-ㄏㄨㄛˇ-ㄏㄨㄛˇ"),
            ("🔥", "ㄏㄨㄛˇ"),
            (" ", "？"),
            ("！", "_ctrl_punctuation_!"),

        ])
    func testExtractReading(input: String, expected: String) {
        let provider = ServiceProvider()
        let output = provider.extractReading(from: input)
        #expect(output == expected)
    }

    @Test(
        "Test add pinyin",
        arguments: [
            ("小麥輸入法", "小(xiao)麥(mai)輸(shu)入(ru)法(fa)"),
            ("美好的朝陽", "美(mei)好(hao)的(de)朝(zhao)陽(yang)"),
        ])
    func testAddPinyin(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        if let helper = helper as? ServiceProviderDelegate {
            provider.delegate = helper
        }
        let output = provider.addHanyuPinyin(string: input)
        #expect(output == expected)
    }

    @Test(
        "Test add readings",
        arguments: [
            ("美好的朝陽", "美(ㄇㄟˇ)好(ㄏㄠˇ)的(ㄉㄜ˙)朝(ㄓㄠ)陽(ㄧㄤˊ)"),
            (
                "『這樣可以嗎？』我相當好奇的問了他，但是還是不知道他的意思",
                "『這(ㄓㄜˋ)樣(ㄧㄤˋ)可(ㄎㄜˇ)以(ㄧˇ)嗎(ㄇㄚ)？』我(ㄨㄛˇ)相(ㄒㄧㄤ)當(ㄉㄤ)好(ㄏㄠˋ)奇(ㄑㄧˊ)的(ㄉㄜ˙)問(ㄨㄣˋ)了(ㄌㄜ˙)他(ㄊㄚ)，但(ㄉㄢˋ)是(ㄕˋ)還(ㄏㄞˊ)是(ㄕˋ)不(ㄅㄨˊ)知(ㄓ)道(ㄉㄠˋ)他(ㄊㄚ)的(ㄉㄜ˙)意(ㄧˋ)思(ㄙ)"
            ),
        ])
    func testAddReading(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let output = provider.addReading(string: input)
        #expect(output == expected)
    }

    @Test(
        "Test convert to pinyin",
        arguments: [
            ("美好的朝陽", "meihaodezhaoyang")
        ]
    )
    func testConvertToPinyin(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        if let helper = helper as? ServiceProviderDelegate {
            provider.delegate = helper
        }
        let output = provider.convertToHanyuPinyin(string: input)
        #expect(output == expected)
    }

    @Test(
        "Test convert to readings",
        arguments: [
            ("美好的朝陽", "ㄇㄟˇㄏㄠˇㄉㄜ˙ㄓㄠㄧㄤˊ")
        ]
    )
    func testConvertToReadings(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let output = provider.convertToReadings(string: input)
        #expect(output == expected)
    }

    @Test(
        "Test tokenize",
        arguments: [
            ("『『』『』『", ["『", "『", "』", "『", "』", "『"]),
            ("『這樣可以嗎？』", ["『", "這樣", "可以", "嗎", "？", "』"]),
        ])
    func testTokenize1(input: String, expected: [String]) {
        let provider = ServiceProvider()
        let output = provider.tokenize(string: input)
        #expect(output.map { $0.0 } == expected, "\(output)")
    }

    @Test(
        "Test converting Unicode Taiwanese Braille to Chinese",
        arguments: [
            ("⠰⠤⠋⠺⠂⠻⠄⠛⠥⠂⠓⠫⠐⠑⠳⠄⠪⠐⠙⠮⠁⠅⠎⠐⠊⠱⠐⠑⠪⠄⠏⠣⠄⠇⠶⠐⠤⠆", "「台灣人最需要的就是消波塊」")
        ])
    func testConvertUnicodeBrailleToChinese(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let output = provider.convertUnicodeBrailleToChineseText(string: input)
        #expect(output == expected, "\(output)")
    }

    @Test(
        "Test coverting Chinese to Unicode Taiwanese Braille, then coverting it back",
        arguments: [
            ("由「小麥」的作者", ""),
            ("This is a test", ""),
            ("第1名", "地 1 明"),
            ("第A名", "地 A 明"),
            ("第AB名", "地 AB 明"),
            ("第A1名", "地 A1 明"),
        ])
    func testConvertBrailleThenBack(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let r1 = provider.convertToUnicodeBraille(string: input)
        let r2 = provider.convertUnicodeBrailleToChineseText(string: r1)
        if expected == "" {
            #expect(r2 == input, "\(r2)")
        } else {
            #expect(r2 == expected, "\(r2)")
        }
    }

    @Test(
        "Test coverting letters to Unicode Taiwanese Braille",
        arguments: [
            ("This is a test", "⠠⠞⠓⠊⠎ ⠊⠎ ⠁ ⠞⠑⠎⠞"),
            ("This is a test 台灣人最需要的就是消波塊", "⠠⠞⠓⠊⠎ ⠊⠎ ⠁ ⠞⠑⠎⠞ ⠋⠺⠂⠻⠄⠛⠥⠂⠓⠫⠐⠑⠳⠄⠪⠐⠙⠮⠁⠅⠎⠐⠊⠱⠐⠑⠪⠄⠏⠣⠄⠇⠶⠐"),
        ])
    func testUnicodeBrailleLetters(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let result = provider.convertToUnicodeBraille(string: input)
        #expect(result == expected)
    }

    @Test(
        "Test coverting digits to Unicode Taiwanese Braille",
        arguments: [
            ("24", "⠼⠆⠲")
        ])
    func testUnicodeBrailleDigit(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let result = provider.convertToUnicodeBraille(string: input)
        #expect(result == expected)
    }

    @Test(
        "Test coverting letters to ASCII Taiwanese Braille",
        arguments: [
            ("This is a test", ",this is a test")
        ])
    func testASCIIBrailleLetters(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let result = provider.convertToASCIIBraille(string: input)
        #expect(result == expected)
    }

    @Test(
        "Test coverting Chinese to ASCII Taiwanese Braille, then coverting it back",
        arguments: [
            ("由「小麥」的作者", ""),
            ("This is a test", ""),
            ("第1名", "地 1 明"),
            ("第A名", "地 A 明"),
            ("第AB名", "地 AB 明"),
            ("第A1名", "地 A1 明"),
        ])
    func testConvertASCIIBrailleThenBack(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let r1 = provider.convertToASCIIBraille(string: input)
        let r2 = provider.convertASCIIBrailleToChineseText(string: r1)
        if expected == "" {
            #expect(r2 == input, "\(r2)")
        } else {
            #expect(r2 == expected, "\(r2)")
        }
    }

    @Test(
        "Test coverting digits to ASCII Taiwanese Braille",
        arguments: [
            ("24", "#24")
        ])
    func testASCIIBrailleDigit(input: String, expected: String) {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let result = provider.convertToASCIIBraille(string: input)
        #expect(result == expected)
    }

    @Test("Test add reading service with pasteboard")
    func testAddReadingServiceWithPasteboard() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let pasteboard = makePasteboard()
        let input = "美好的朝陽"
        write(input, to: pasteboard)

        provider.addReading(pasteboard, userData: nil, error: nil)

        #expect(read(from: pasteboard) == provider.addReading(string: input))
    }

    @Test("Test convert to readings service rejects overlong input")
    func testConvertToReadingsServiceRejectsOverlongInput() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let pasteboard = makePasteboard()
        let input = String(repeating: "美", count: 3000)
        write(input, to: pasteboard)

        provider.convertToReadings(pasteboard, userData: nil, error: nil)

        #expect(read(from: pasteboard) == input)
    }

    @Test("Test convert Unicode braille to Chinese service with pasteboard")
    func testConvertUnicodeBrailleToChineseServiceWithPasteboard() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let pasteboard = makePasteboard()
        let input = "⠰⠤⠋⠺⠂⠻⠄⠛⠥⠂⠓⠫⠐⠑⠳⠄⠪⠐⠙⠮⠁⠅⠎⠐⠊⠱⠐⠑⠪⠄⠏⠣⠄⠇⠶⠐⠤⠆"
        write(input, to: pasteboard)

        provider.convertUnicodeBrailleToChineseText(pasteboard, userData: nil, error: nil)

        #expect(read(from: pasteboard) == provider.convertUnicodeBrailleToChineseText(string: input))
    }

    @Test("Test convert ASCII braille to Chinese service with pasteboard")
    func testConvertASCIIBrailleToChineseServiceWithPasteboard() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let helper = ServiceProviderInputHelper()
        provider.delegate = helper as? any ServiceProviderDelegate
        let pasteboard = makePasteboard()
        let input = provider.convertToASCIIBraille(string: "「台灣人最需要的就是消波塊」")
        write(input, to: pasteboard)

        provider.convertASCIIBrailleToChineseText(pasteboard, userData: nil, error: nil)

        #expect(read(from: pasteboard) == provider.convertASCIIBrailleToChineseText(string: input))
    }

    @Test("Test convert to annotated text service with pasteboard")
    func testConvertToBpmfAnnotatedTextServiceWithPasteboard() {
        LanguageModelManager.loadDataModels()
        let provider = ServiceProvider()
        let pasteboard = makePasteboard()
        let input = "你好"
        write(input, to: pasteboard)

        provider.convertToBpmfAnnotatedText(pasteboard, userData: nil, error: nil)

        #expect(read(from: pasteboard) == provider.convertToBpmfAnnotatedText(string: input))
    }
}
