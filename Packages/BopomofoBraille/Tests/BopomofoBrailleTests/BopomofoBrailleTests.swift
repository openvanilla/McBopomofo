import XCTest
@testable import BopomofoBraille

final class BopomofoBrailleTests: XCTestCase {
    func testC1() {
        let input = "ㄨㄛˇㄗㄨㄟˋㄒㄧˇㄏㄨㄢㄋㄧˇㄌㄜ˙"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        XCTAssert(r1 == "⠒⠈⠓⠫⠐⠑⠡⠈⠗⠻⠄⠝⠡⠈⠉⠮⠁")
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC2() {
        let input = "ㄈㄤˊㄑㄩㄓㄨㄤˋㄎㄨㄤˋㄙㄢㄕㄥㄒㄧㄠˋ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        XCTAssert(r1 == "⠟⠭⠂⠚⠳⠄⠁⠸⠐⠇⠸⠐⠑⠧⠄⠊⠵⠄⠑⠪⠐")
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC3() {
        let input = "ㄊㄠㄎㄨㄥㄍㄨㄥㄙ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        XCTAssert(r1 == "⠋⠩⠄⠇⠯⠄⠅⠯⠄⠑⠱⠄")
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC4() {
        let input = "ㄧㄥˊㄏㄨㄛˇㄔㄨㄥˊㄚㄇㄢˋㄇㄢˋㄈㄟㄨㄟˊㄈㄥㄑㄧㄥㄑㄧㄥㄔㄨㄟ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC5() {
        let input = "ㄩㄝˋㄌㄧㄤˋㄐㄧㄝˇㄐㄧㄝˇㄎㄨㄞˋㄔㄨㄌㄞˊㄇㄟˋㄇㄟˋㄅㄨˊㄧㄠˋㄕㄨㄟˋ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC6() {
        let input = "ㄨㄛˇㄏㄨㄚㄌㄜ˙ㄉㄧㄢˇㄕˊㄐㄧㄢㄗˋㄐㄧˇㄒㄧㄝˇㄌㄜ˙ㄧㄍㄜ˙ㄐㄧㄤㄓㄨˋㄧㄣㄓㄨㄢˇㄏㄨㄢˋㄔㄥˊㄉㄧㄢˇㄗˋㄉㄜ˙ㄇㄛˊㄗㄨˇ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        print(r1)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC7() {
        let input = "ㄗˋㄐㄧˇ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        print(r1)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC8() {
        let input = "ㄐㄧˇ"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        print(r1)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC9() {
        let input = "，，，，，"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        print(r1)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC10() {
        let input = "「ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ」"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        print(r1)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testC11() {
        let input = "『『ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ』』"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        print(r1)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }


    func testC12() {
        let input = "ㄧㄡˇㄉㄧㄢˇㄑㄧˊㄍㄨㄞˋ，ㄓㄜˋㄧㄤˋㄎㄜˇㄧˇㄇㄚ？"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        print(r1)
        let r2 = BopomofoBrailleConverter.convert(braille: r1)
        XCTAssert(r2 == input, r2)
    }

    func testBrailleToTokens1() {
        let input = "「ㄊㄞˊㄨㄢㄖㄣˊㄒㄩㄧㄠˋㄏㄣˇㄉㄨㄛㄉㄜ˙ㄒㄧㄠㄆㄛㄎㄨㄞˋ」"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(brailleToTokens: r1)
        let substring = r2[0] as! String
        XCTAssert(substring == "「", substring)
    }

    func testBrailleToTokens2() {
        let input = "「「"
        let r1 = BopomofoBrailleConverter.convert(bopomofo: input)
        let r2 = BopomofoBrailleConverter.convert(brailleToTokens: r1)
        let substring = r2[0] as! String
        XCTAssert(substring == "『", substring)
    }

    func testBrailleToTokens3() {
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
