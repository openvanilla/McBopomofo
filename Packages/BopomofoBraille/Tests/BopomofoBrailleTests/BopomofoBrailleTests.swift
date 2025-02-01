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

}
