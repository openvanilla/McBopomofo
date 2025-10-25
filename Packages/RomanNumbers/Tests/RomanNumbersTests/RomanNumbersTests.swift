import Testing
@testable import RomanNumbers

@Suite("RomanNumbersTests")
struct RomanNumbersTests {

    @Test("Test alphabets",  arguments: [
        ("0", ""),
        ("1", "I"),
        ("3999", "MMMCMXCIX"),
        ("2000", "MM"),
        ("2025", "MMXXV")
    ]) func test(input: String, expected: String ) async throws {
        let output = try RomanNumbers.convert(string: input)
        #expect(output == expected)
    }

    @Test("Test Upper cased",  arguments: [
        ("0", ""),
        ("1", "Ⅰ"),
        ("3999", "ⅯⅯⅯⅭⅯⅩⅭⅨ"),
        ("2000", "ⅯⅯ"),
        ("2025", "ⅯⅯⅩⅩⅤ")
    ]) func testUpperCase(input: String, expected: String ) async throws {
        let output = try RomanNumbers.convert(string: input, style: .fullWidthUpper)
        #expect(output == expected)
    }

    @Test("Test Lower cased",  arguments: [
        ("0", ""),
        ("1", "ⅰ"),
        ("3999", "ⅿⅿⅿⅽⅿⅹⅽⅸ"),
        ("2000", "ⅿⅿ"),
        ("2025", "ⅿⅿⅹⅹⅴ")
    ]) func testLowerCase(input: String, expected: String ) async throws {
        let output = try RomanNumbers.convert(string: input, style: .fullWidthLower)
        #expect(output == expected)
    }

}
