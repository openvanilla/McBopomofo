import XCTest
@testable import BopomofoBraille

final class BopomofoBrailleTests: XCTestCase {

    func testConvertDigits1() {
        let input = "1"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertDigits20000() {
        let input = "20000"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertDigit_1_5() {
        let input = "1.5"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }


    func testConvertDigit_1_555555() {
        let input = "1.555555"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertDigitAndPercent1() {
        let input = "2%"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertDigitAndPercent2() {
        let input = "222222%"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertDigitAndDegree() {
        let input = "2°C"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertLetters() {
        let input = "This is just a test"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertLettersAndDigits() {
        let input = "This is just a test ABCD 1234"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBumpLettersAndDigits() {
        let input = "ㄨㄛˇㄗㄨㄟˋㄒㄧˇㄏㄨㄢㄋㄧˇㄌㄜ˙ ABCD 1234"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertLettersBpmfAndDigits() {
        let input = "ABCD ㄨㄛˇㄗㄨㄟˋㄒㄧˇㄏㄨㄢㄋㄧˇㄌㄜ˙ 1234"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf1() {
        let input = "ㄨㄛˇㄗㄨㄟˋㄒㄧˇㄏㄨㄢㄋㄧˇㄌㄜ˙"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        XCTAssert(r1 == "⠒⠈⠓⠫⠐⠑⠡⠈⠗⠻⠄⠝⠡⠈⠉⠮⠁")
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf2() {
        let input = "ㄈㄤˊㄑㄩㄓㄨㄤˋㄎㄨㄤˋㄙㄢㄕㄥㄒㄧㄠˋ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        XCTAssert(r1 == "⠟⠭⠂⠚⠳⠄⠁⠸⠐⠇⠸⠐⠑⠧⠄⠊⠵⠄⠑⠪⠐")
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf3() {
        let input = "ㄊㄠㄎㄨㄥㄍㄨㄥㄙ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        XCTAssert(r1 == "⠋⠩⠄⠇⠯⠄⠅⠯⠄⠑⠱⠄")
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf4() {
        let input = "ㄧㄥˊㄏㄨㄛˇㄔㄨㄥˊㄚㄇㄢˋㄇㄢˋㄈㄟㄨㄟˊㄈㄥㄑㄧㄥㄑㄧㄥㄔㄨㄟ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf5() {
        let input = "ㄩㄝˋㄌㄧㄤˋㄐㄧㄝˇㄐㄧㄝˇㄎㄨㄞˋㄔㄨㄌㄞˊㄇㄟˋㄇㄟˋㄅㄨˊㄧㄠˋㄕㄨㄟˋ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf6() {
        let input = "ㄨㄛˇㄏㄨㄚㄌㄜ˙ㄉㄧㄢˇㄕˊㄐㄧㄢㄗˋㄐㄧˇㄒㄧㄝˇㄌㄜ˙ㄧㄍㄜ˙ㄐㄧㄤㄓㄨˋㄧㄣㄓㄨㄢˇㄏㄨㄢˋㄔㄥˊㄉㄧㄢˇㄗˋㄉㄜ˙ㄇㄛˊㄗㄨˇ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf7() {
        let input = "ㄗˋㄐㄧˇ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBmpf8() {
        let input = "ㄐㄧˇ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertPunctuation() {
        let input = "，，，，，"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == "⠆⠆⠆⠆⠆", r2)
    }

    func testConvertBpmfAndPunctuation1() {
        let input = "「ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ」"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBpmfAndPunctuation2() {
        let input = "『『ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ』』"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBpmf8() {
        let input = "ㄧㄡˇㄉㄧㄢˇㄑㄧˊㄍㄨㄞˋㄓㄜˋㄧㄤˋㄎㄜˇㄧˇㄇㄚ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBpmfAndPunctuation3() {
        let input = "ㄧㄡˇㄉㄧㄢˇㄑㄧˊㄍㄨㄞˋㄓㄜˋㄧㄤˋㄎㄜˇㄧˇㄇㄚ？"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testConvertBpmfAndPunctuation4() {
        let input = "ㄧㄡˇㄉㄧㄢˇㄑㄧˊㄍㄨㄞˋ，ㄓㄜˋㄧㄤˋㄎㄜˇㄧˇㄇㄚ？"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testPunctuation2() {
        let input = "？"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == "o", r2)
    }

    func testConvertBpmfAndPunctuation5() {
        let input = "「ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ」"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(brailleToTokens: r1)
        let substring = r2[0] as! String
        XCTAssert(substring == "「", substring)
    }

    func testPunctuation3() {
        let input = "「「"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(brailleToTokens: r1)
        let substring = r2[0] as! String
        XCTAssert(substring == "『", substring)
    }

    func testPunctuation4() {
        let input = "「"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(brailleToTokens: r1)
        let substring = r2[0] as! String
        XCTAssert(substring == "「", substring)
    }

    func test第() {
        do {
            let b = try BopomofoSyllable(rawValue: "ㄉㄧˋ")
            let output = b.braille
            XCTAssertTrue(output == "⠙⠡⠐")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test第Reversed() {
        do {
            let b = try BopomofoSyllable(braille: "⠙⠡⠐")
            let output = b.rawValue
            XCTAssertTrue(output == "ㄉㄧˋ")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }


    func testㄧ() {
        do {
            let b = try BopomofoSyllable(rawValue: "ㄧ")
            let output = b.braille
            XCTAssertTrue(output == "⠡⠄")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testㄧReversed() {
        do {
            let b = try BopomofoSyllable(braille: "⠡⠄")
            let output = b.rawValue
            XCTAssertTrue(output == "ㄧ")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test條() {
        do {
            let b = try BopomofoSyllable(rawValue: "ㄊㄧㄠˊ")
            let output = b.braille
            XCTAssertTrue(output == "⠋⠪⠂")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test條Reversed() {
        do {
            let b = try BopomofoSyllable(braille: "⠋⠪⠂")
            let output = b.rawValue
            XCTAssertTrue(output == "ㄊㄧㄠˊ")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test了() {
        do {
            let b = try BopomofoSyllable(rawValue: "ㄌㄜ˙")
            let output = b.braille
            XCTAssertTrue(output == "⠉⠮⠁")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test了Reversed() {
        do {
            let b = try BopomofoSyllable(braille: "⠉⠮⠁")
            let output = b.rawValue
            XCTAssertTrue(output == "ㄌㄜ˙")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
