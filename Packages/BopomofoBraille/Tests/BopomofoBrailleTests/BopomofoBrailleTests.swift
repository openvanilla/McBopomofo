import Testing

@testable import BopomofoBraille

@Suite("Test the BopomofoBrailleConverter")
final class BopomofoBrailleTests {

    @Test(
        "Test conversion",
        .serialized,
        arguments: [
            ("ㄎㄜˇ、IBM", "ㄎㄜˇ、 IBM"),
            ("24", ""),
            ("1", ""),
            ("2000", ""),
            ("1.5", ""),
            ("1.555555", ""),
            ("2%", ""),
            ("222222%", ""),
            ("222222%", ""),
            ("2°C", ""),
            ("This is just a test", ""),
            ("This is just a test ABCD 1234", ""),
            ("ㄨㄛˇㄗㄨㄟˋㄒㄧˇㄏㄨㄢㄋㄧˇㄌㄜ˙ ABCD 1234", ""),
            ("ABCD ㄨㄛˇㄗㄨㄟˋㄒㄧˇㄏㄨㄢㄋㄧˇㄌㄜ˙ 1234", ""),
            ("ㄨㄛˇㄗㄨㄟˋㄒㄧˇㄏㄨㄢㄋㄧˇㄌㄜ˙", ""),
            ("ㄈㄤˊㄑㄩㄓㄨㄤˋㄎㄨㄤˋㄙㄢㄕㄥㄒㄧㄠˋ", ""),
            ("ㄊㄠㄎㄨㄥㄍㄨㄥㄙ", ""),
            ("ㄧㄥˊㄏㄨㄛˇㄔㄨㄥˊㄚㄇㄢˋㄇㄢˋㄈㄟㄨㄟˊㄈㄥㄑㄧㄥㄑㄧㄥㄔㄨㄟ", ""),
            ("ㄩㄝˋㄌㄧㄤˋㄐㄧㄝˇㄐㄧㄝˇㄎㄨㄞˋㄔㄨㄌㄞˊㄇㄟˋㄇㄟˋㄅㄨˊㄧㄠˋㄕㄨㄟˋ", ""),
            ("ㄨㄛˇㄏㄨㄚㄌㄜ˙ㄉㄧㄢˇㄕˊㄐㄧㄢㄗˋㄐㄧˇㄒㄧㄝˇㄌㄜ˙ㄧㄍㄜ˙ㄐㄧㄤㄓㄨˋㄧㄣㄓㄨㄢˇㄏㄨㄢˋㄔㄥˊㄉㄧㄢˇㄗˋㄉㄜ˙ㄇㄛˊㄗㄨˇ", ""),
            ("ㄗˋㄐㄧˇ", ""),
            ("ㄐㄧˇ", ""),
            ("「ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ」", ""),
            ("『『ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ』』", ""),
            ("ㄧㄡˇㄉㄧㄢˇㄑㄧˊㄍㄨㄞˋㄓㄜˋㄧㄤˋㄎㄜˇㄧˇㄇㄚ", ""),
            ("ㄧㄡˇㄉㄧㄢˇㄑㄧˊㄍㄨㄞˋㄓㄜˋㄧㄤˋㄎㄜˇㄧˇㄇㄚ？", ""),
            ("「ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ」", ""),
            ("「「", "『"),
            ("「", "「"),
            ("？", "o"),
            ("，，，，，", "⠆⠆⠆⠆⠆"),
        ])
    func testConverter(input: String, expected: String) {
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        if expected == "" {
            #expect(r2 == input, "\(r2)")
        } else {
            #expect(r2 == expected, "\(r2)")
        }
    }

    @Test(
        "Test BopomofoSyllable from raw value",
        arguments: [
            ("ㄉㄧˋ", "⠙⠡⠐"),
            ("ㄧ", "⠡⠄"),
            ("ㄊㄧㄠˊ", "⠋⠪⠂"),
            ("ㄌㄜ˙", "⠉⠮⠁"),
        ])
    func test第(input: String, expected: String) {
        do {
            let b = try BopomofoSyllable(rawValue: input)
            let output = b.braille
            #expect(output == expected)
        } catch {
            Issue.record(error)
        }
    }

    @Test(
        "Test BopomofoSyllable from Braille",
        arguments: [
            ("⠙⠡⠐", "ㄉㄧˋ"),
            ("⠡⠄", "ㄧ"),
            ("⠋⠪⠂", "ㄊㄧㄠˊ"),
            ("⠉⠮⠁", "ㄌㄜ˙"),
        ])
    func test第Reversed(input: String, expected: String) {
        do {
            let b = try BopomofoSyllable(braille: input)
            let output = b.rawValue
            #expect(output == expected)
        } catch {
            Issue.record(error)
        }
    }

    @Test(
        "Test ASCII Braille conversion",
        arguments: [
            ("k*\"", "ㄐㄧˋ"),
            ("c!a", "ㄌㄜ˙"),
            ("/`", "ㄨˇ"),
        ])
    func testAsciiBrailleReversed(input: String, expected: String) {
        let output = BopomofoBrailleConverter.convert(braille: input, type: .ascii)
        #expect(output == expected)
    }

    @Test("Test ASCII Braille digit sign")
    func testAsciiDigitSign() {
        let braille = BopomofoBrailleConverter.convert(bopomofo: "123", type: .ascii)
        #expect(braille == "#123")

        let output = BopomofoBrailleConverter.convert(braille: "#123", type: .ascii)
        #expect(output == "123")
    }

    @Test("Test ASCII Braille uppercase sign")
    func testAsciiUppercaseSign() {
        let braille = BopomofoBrailleConverter.convert(bopomofo: "ABcd", type: .ascii)
        #expect(braille == ",a,bcd")

        let output = BopomofoBrailleConverter.convert(braille: ",a,bcd", type: .ascii)
        #expect(output == "ABcd")
    }

    @Test(
        "Test ASCII Braille yv combinations",
        arguments: [
            ("ㄩㄝˋ", "8\""),
            ("ㄩㄢˋ", "~\""),
            ("ㄩㄣˋ", "4\""),
            ("ㄩㄥˋ", "6\""),
        ])
    func testAsciiYvCombinations(input: String, expected: String) {
        let braille = BopomofoBrailleConverter.convert(bopomofo: input, type: .ascii)
        #expect(braille == expected)

        let output = BopomofoBrailleConverter.convert(braille: expected, type: .ascii)
        #expect(output == input)
    }

}
