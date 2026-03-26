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

import Foundation

private let kMinimalBopomofoLength = 1
private let kMinimalBrailleLength = 2

private protocol Syllable {
    var bopomofo: String { get }
    var braille: String { get }
    var brailleAscii: String { get }
    var brailleCode: String { get }
    func getBraille(by type: BrailleType) -> String
}

extension Syllable {
    func getBraille(by type: BrailleType) -> String {
        switch type {
        case .unicode:
            braille
        case .ascii:
            brailleAscii
        }
    }
}

private protocol Combination {
    var bopomofo: String { get }
    var braille: String { get }
    var brailleAscii: String { get }
    var brailleCode: String { get }
    func getBraille(by type: BrailleType) -> String
}

extension Combination {
    func getBraille(by type: BrailleType) -> String {
        switch type {
        case .unicode:
            braille
        case .ascii:
            brailleAscii
        }
    }
}

// MARK: - Syllables

private enum Consonant: String, CaseIterable, Syllable {

    static let bpmfBrailleMap: [Consonant: (String, String, String)] = [
        .ㄅ: ("⠕", "o", "135"),
        .ㄆ: ("⠏", "p", "1234"),
        .ㄇ: ("⠍", "m", "134"),
        .ㄈ: ("⠟", "q", "12345"),
        .ㄉ: ("⠙", "d", "145"),
        .ㄊ: ("⠋", "f", "124"),
        .ㄋ: ("⠝", "n", "1345"),
        .ㄌ: ("⠉", "c", "14"),
        .ㄍ: ("⠅", "k", "13"),
        .ㄎ: ("⠇", "l", "123"),
        .ㄏ: ("⠗", "r", "1235"),
        .ㄐ: ("⠅", "k", "13"),
        .ㄑ: ("⠚", "j", "245"),
        .ㄒ: ("⠑", "e", "15"),
        .ㄓ: ("⠁", "a", "1"),
        .ㄔ: ("⠃", "b", "12"),
        .ㄕ: ("⠊", "i", "24"),
        .ㄖ: ("⠛", "g", "1245"),
        .ㄗ: ("⠓", "h", "125"),
        .ㄘ: ("⠚", "j", "245"),
        .ㄙ: ("⠑", "e", "15"),
    ]

    fileprivate var bopomofo: String {
        self.rawValue
    }

    fileprivate var braille: String {
        Consonant.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleAscii: String {
        Consonant.bpmfBrailleMap[self]!.1
    }

    fileprivate var brailleCode: String {
        Consonant.bpmfBrailleMap[self]!.2
    }

    fileprivate var isSingle: Bool {
        switch self {
        case .ㄓ, .ㄔ, .ㄕ, .ㄖ, .ㄗ, .ㄘ, .ㄙ:
            true
        default:
            false
        }
    }

    case ㄅ = "ㄅ"
    case ㄆ = "ㄆ"
    case ㄇ = "ㄇ"
    case ㄈ = "ㄈ"
    case ㄉ = "ㄉ"
    case ㄊ = "ㄊ"
    case ㄋ = "ㄋ"
    case ㄌ = "ㄌ"
    case ㄍ = "ㄍ"
    case ㄎ = "ㄎ"
    case ㄏ = "ㄏ"
    case ㄐ = "ㄐ"
    case ㄑ = "ㄑ"
    case ㄒ = "ㄒ"
    case ㄓ = "ㄓ"
    case ㄔ = "ㄔ"
    case ㄕ = "ㄕ"
    case ㄖ = "ㄖ"
    case ㄗ = "ㄗ"
    case ㄘ = "ㄘ"
    case ㄙ = "ㄙ"
}

private enum MiddleVowel: String, CaseIterable, Syllable {
    static let bpmfBrailleMap: [MiddleVowel: (String, String, String)] = [
        .ㄧ: ("⠡", "*", "16"),
        .ㄨ: ("⠌", "/", "34"),
        .ㄩ: ("⠳", "|", "1256"),
    ]
    fileprivate var bopomofo: String {
        self.rawValue
    }

    fileprivate var braille: String {
        MiddleVowel.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleAscii: String {
        MiddleVowel.bpmfBrailleMap[self]!.1
    }

    fileprivate var brailleCode: String {
        MiddleVowel.bpmfBrailleMap[self]!.2
    }

    fileprivate func buildCombination(rawValue: String) throws -> Combination {
        guard
            let result: Combination =
                switch self {
                case .ㄧ:
                    ㄧ_Combination(rawValue: rawValue)
                case .ㄨ:
                    ㄨ_Combination(rawValue: rawValue)
                case .ㄩ:
                    ㄩ_Combination(rawValue: rawValue)
                }
        else {
            throw BopomofoSyllableError.invalidCharacter
        }
        return result
    }

    case ㄧ = "ㄧ"
    case ㄨ = "ㄨ"
    case ㄩ = "ㄩ"
}

private enum Vowel: String, CaseIterable, Syllable {
    static let bpmfBrailleMap: [Vowel: (String, String, String)] = [
        .ㄚ: ("⠜", ">", "345"),
        .ㄛ: ("⠣", "<", "126"),
        .ㄜ: ("⠮", "!", "2346"),
        .ㄝ: ("⠢", "5", "26"),
        .ㄞ: ("⠺", "w", "2456"),
        .ㄟ: ("⠴", "0", "356"),
        .ㄠ: ("⠩", "%", "146"),
        .ㄡ: ("⠷", "(", "12356"),
        .ㄢ: ("⠧", "v", "1236"),
        .ㄣ: ("⠥", "u", "136"),
        .ㄤ: ("⠭", "x", "1346"),
        .ㄥ: ("⠵", "z", "1356"),
        .ㄦ: ("⠱", ":", "156"),
    ]

    fileprivate var bopomofo: String {
        self.rawValue
    }

    fileprivate var braille: String {
        Vowel.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleAscii: String {
        Vowel.bpmfBrailleMap[self]!.1
    }

    fileprivate var brailleCode: String {
        Vowel.bpmfBrailleMap[self]!.2
    }

    case ㄚ = "ㄚ"
    case ㄛ = "ㄛ"
    case ㄜ = "ㄜ"
    case ㄝ = "ㄝ"
    case ㄞ = "ㄞ"
    case ㄟ = "ㄟ"
    case ㄠ = "ㄠ"
    case ㄡ = "ㄡ"
    case ㄢ = "ㄢ"
    case ㄣ = "ㄣ"
    case ㄤ = "ㄤ"
    case ㄥ = "ㄥ"
    case ㄦ = "ㄦ"
}

// MARK: - Combination

private enum ㄧ_Combination: String, CaseIterable, Combination {
    static let bpmfBrailleMap: [ㄧ_Combination: (String, String, String)] = [
        .ㄧㄚ: ("⠾", ")", "23456"),
        .ㄧㄛ: ("⠴", "0", "356"),
        .ㄧㄝ: ("⠬", "+", "346"),
        .ㄧㄞ: ("⠢", "5", "26"),
        .ㄧㄠ: ("⠪", "{", "246"),
        .ㄧㄡ: ("⠎", "s", "234"),
        .ㄧㄢ: ("⠞", "t", "2345"),
        .ㄧㄣ: ("⠹", "?", "1456"),
        .ㄧㄤ: ("⠨", ".", "46"),
        .ㄧㄥ: ("⠽", "y", "13456"),
    ]

    fileprivate var bopomofo: String {
        "ㄧ" + self.rawValue
    }

    fileprivate var braille: String {
        ㄧ_Combination.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleAscii: String {
        ㄧ_Combination.bpmfBrailleMap[self]!.1
    }

    fileprivate var brailleCode: String {
        ㄧ_Combination.bpmfBrailleMap[self]!.2
    }

    case ㄧㄚ = "ㄚ"
    case ㄧㄛ = "ㄛ"
    case ㄧㄝ = "ㄝ"
    case ㄧㄞ = "ㄞ"
    case ㄧㄠ = "ㄠ"
    case ㄧㄡ = "ㄡ"
    case ㄧㄢ = "ㄢ"
    case ㄧㄣ = "ㄣ"
    case ㄧㄤ = "ㄤ"
    case ㄧㄥ = "ㄥ"
}

private enum ㄨ_Combination: String, CaseIterable, Combination {
    static let bpmfBrailleMap: [ㄨ_Combination: (String, String, String)] = [
        .ㄨㄚ: ("⠔", "9", "35"),
        .ㄨㄛ: ("⠒", "3", "25"),
        .ㄨㄞ: ("⠶", "7", "2356"),
        .ㄨㄟ: ("⠫", "$", "1246"),
        .ㄨㄢ: ("⠻", "}", "12456"),
        .ㄨㄣ: ("⠿", "=", "123456"),
        .ㄨㄤ: ("⠸", "_", "456"),
        .ㄨㄥ: ("⠯", "&", "12346"),
    ]

    fileprivate var bopomofo: String {
        "ㄨ" + self.rawValue
    }

    fileprivate var braille: String {
        ㄨ_Combination.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleAscii: String {
        ㄨ_Combination.bpmfBrailleMap[self]!.1
    }

    fileprivate var brailleCode: String {
        ㄨ_Combination.bpmfBrailleMap[self]!.2
    }

    case ㄨㄚ = "ㄚ"
    case ㄨㄛ = "ㄛ"
    case ㄨㄞ = "ㄞ"
    case ㄨㄟ = "ㄟ"
    case ㄨㄢ = "ㄢ"
    case ㄨㄣ = "ㄣ"
    case ㄨㄤ = "ㄤ"
    case ㄨㄥ = "ㄥ"
}

private enum ㄩ_Combination: String, CaseIterable, Combination {
    static let bpmfBrailleMap: [ㄩ_Combination: (String, String, String)] = [
        .ㄩㄝ: ("⠦", "8", "236"),
        .ㄩㄢ: ("⠘", "~", "45"),
        .ㄩㄣ: ("⠲", "4", "256"),
        .ㄩㄥ: ("⠖", "6", "235"),
    ]

    fileprivate var bopomofo: String {
        "ㄩ" + self.rawValue
    }

    fileprivate var braille: String {
        ㄩ_Combination.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleAscii: String {
        ㄩ_Combination.bpmfBrailleMap[self]!.1
    }

    fileprivate var brailleCode: String {
        ㄩ_Combination.bpmfBrailleMap[self]!.2
    }

    case ㄩㄝ = "ㄝ"
    case ㄩㄢ = "ㄢ"
    case ㄩㄣ = "ㄣ"
    case ㄩㄥ = "ㄥ"

}

// MARK: - Tone

private enum Tone: String, CaseIterable {
    static let bpmfBrailleMap: [Tone: (String, String, String)] = [
        .tone1: ("⠄", "'", "3"),
        .tone2: ("⠂", "1", "2"),
        .tone3: ("⠈", "`", "4"),
        .tone4: ("⠐", "\"", "5"),
        .tone5: ("⠁", "a", "1"),
    ]

    fileprivate var bopomofo: String {
        return self.rawValue
    }

    fileprivate var braille: String {
        Tone.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleAscii: String {
        Tone.bpmfBrailleMap[self]!.1
    }

    fileprivate var brailleCode: String {
        Tone.bpmfBrailleMap[self]!.1
    }

    func getBraille(by type: BrailleType) -> String {
        switch type {
        case .unicode:
            braille
        case .ascii:
            brailleAscii
        }

    }

    case tone1 = ""
    case tone2 = "ˊ"
    case tone3 = "ˇ"
    case tone4 = "ˋ"
    case tone5 = "˙"
}

// MARK: -

/// Errors for `BopomofoSyllable`.
public enum BopomofoSyllableError: Error, LocalizedError {
    case invalidLength
    case invalidCharacter
    case duplicatedConsonant
    case consonantShouldBeAtFront
    case middleVowelAlreadySet
    case middleVowelShouldBeBeforeVowel
    case vowelAlreadySet
    case invalidVowelCombination
    case toneShouldBeAtEnd
    case toneAlreadySet
    case noTone
    case other

    public var errorDescription: String? {
        switch self {
        case .invalidLength:
            "Invalid length"
        case .invalidCharacter:
            "Invalid character"
        case .duplicatedConsonant:
            "Consonant duplicated"
        case .consonantShouldBeAtFront:
            "Consonant should be at front"
        case .middleVowelAlreadySet:
            "Middle vowel already set"
        case .middleVowelShouldBeBeforeVowel:
            "Middle vowel should be before vowel"
        case .vowelAlreadySet:
            "Vowel already set"
        case .invalidVowelCombination:
            "invalid vowel combination"
        case .toneShouldBeAtEnd:
            "Tone should be at end"
        case .toneAlreadySet:
            "Tone already set"
        case .noTone:
            "No tone"
        case .other:
            "Other error"
        }
    }
}

/// Represents the Bopomofo syllables.
public struct BopomofoSyllable {
    private static let consonantValues = Set(Consonant.allCases.map { $0.rawValue })
    private static let middleVowelValues = Set(MiddleVowel.allCases.map { $0.rawValue })
    private static let vowelValues = Set(Vowel.allCases.map { $0.rawValue })
    private static let toneValues = Set(Tone.allCases.map { $0.rawValue })

    private static let consonantBraille = [
        Set(Consonant.allCases.map { $0.braille }),
        Set(Consonant.allCases.map { $0.brailleAscii }),
    ]
    private static let middleVowelBraille = [
        Set(MiddleVowel.allCases.map { $0.braille }),
        Set(MiddleVowel.allCases.map { $0.brailleAscii }),
    ]
    private static let vowelBraille = [
        Set(Vowel.allCases.map { $0.braille }),
        Set(Vowel.allCases.map { $0.brailleAscii }),
    ]
    private static let toneBraille = [
        Set(Tone.allCases.map { $0.braille }),
        Set(Tone.allCases.map { $0.brailleAscii }),
    ]
    private static let ㄧBraille = [
        Set(ㄧ_Combination.allCases.map { $0.braille }),
        Set(ㄧ_Combination.allCases.map { $0.brailleAscii }),
    ]
    private static let ㄨBraille = [
        Set(ㄨ_Combination.allCases.map { $0.braille }),
        Set(ㄨ_Combination.allCases.map { $0.brailleAscii }),
    ]
    private static let ㄩBraille = [
        Set(ㄩ_Combination.allCases.map { $0.braille }),
        Set(ㄩ_Combination.allCases.map { $0.brailleAscii }),
    ]

    private static func braille<S: Syllable>(for value: S, type: BrailleType) -> String {
        value.getBraille(by: type)
    }

    private static func braille<C: Combination>(for value: C, type: BrailleType) -> String {
        value.getBraille(by: type)
    }

    public var rawValue: String
    public var braille: String
    public var type: BrailleType

    public init(rawValue: String, type: BrailleType = .unicode) throws {
        if rawValue.count < kMinimalBopomofoLength {
            throw BopomofoSyllableError.invalidLength
        }

        var consonant: Consonant?
        var middleVowel: MiddleVowel?
        var vowel: Vowel?
        var tone: Tone = .tone1

        for c in rawValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            let s = String(c)
            switch s {
            case _ where BopomofoSyllable.consonantValues.contains(s):
                if consonant != nil {
                    throw BopomofoSyllableError.duplicatedConsonant
                }
                if middleVowel != nil || vowel != nil {
                    throw BopomofoSyllableError.consonantShouldBeAtFront
                }
                consonant = Consonant(rawValue: s)
            case _ where BopomofoSyllable.middleVowelValues.contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.middleVowelShouldBeBeforeVowel
                }
                middleVowel = MiddleVowel(rawValue: s)
            case _ where BopomofoSyllable.vowelValues.contains(s):
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                if let middleVowel {
                    _ = try middleVowel.buildCombination(rawValue: s)
                }

                vowel = Vowel(rawValue: s)
            case _ where BopomofoSyllable.toneValues.contains(s):
                if consonant == nil && middleVowel == nil && vowel == nil {
                    throw BopomofoSyllableError.toneShouldBeAtEnd
                }
                if tone != Tone.tone1 {
                    throw BopomofoSyllableError.toneAlreadySet
                }
                tone = Tone(rawValue: s)!
            default:
                throw BopomofoSyllableError.invalidCharacter
            }
        }

        self.rawValue = rawValue
        self.braille = BopomofoSyllable.makeBraille(consonant, middleVowel, vowel, tone, type)
        self.type = type
    }

    public init(braille: String, type: BrailleType = .unicode) throws {

        if braille.count < kMinimalBrailleLength {
            throw BopomofoSyllableError.invalidLength
        }

        func shouldConnectWithYiOrYv(_ next: String) -> Bool {
            return next == MiddleVowel.ㄧ.getBraille(by: type)
                || next == MiddleVowel.ㄩ.getBraille(by: type)
                || BopomofoSyllable.ㄧBraille[type.rawValue].contains(next)
                || BopomofoSyllable.ㄩBraille[type.rawValue].contains(next)
        }

        var consonant: Consonant?
        var middleVowel: MiddleVowel?
        var vowel: Vowel?
        var tone: Tone?

        let string = braille.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        for (index, c) in string.enumerated() {
            let s = String(c)
            switch s {
            case Vowel.ㄦ.getBraille(by: type):
                if index == 0 {
                    vowel = .ㄦ
                }
                if let consonant, consonant.isSingle == false {
                    throw BopomofoSyllableError.other
                }
            case Consonant.ㄓ.getBraille(by: type):  // ㄓ or tone5
                if index == 0 {
                    consonant = Consonant.ㄓ
                } else {
                    if consonant == nil && middleVowel == nil && vowel == nil {
                        throw BopomofoSyllableError.toneShouldBeAtEnd
                    }
                    if tone != nil {
                        throw BopomofoSyllableError.toneAlreadySet
                    }
                    tone = .tone5
                }
            case Consonant.ㄒ.getBraille(by: type):  // ㄙ and ㄒ
                if consonant != nil {
                    throw BopomofoSyllableError.duplicatedConsonant
                }
                if index + 1 >= string.count {
                    throw BopomofoSyllableError.other
                }

                let nextStart = string.index(string.startIndex, offsetBy: index + 1)
                let next = String(string[nextStart...nextStart])
                if shouldConnectWithYiOrYv(next) {
                    consonant = .ㄒ
                } else {
                    consonant = .ㄙ
                }
            case Consonant.ㄑ.getBraille(by: type):  // ㄑ and ㄘ
                if consonant != nil {
                    throw BopomofoSyllableError.duplicatedConsonant
                }
                if index + 1 >= string.count {
                    throw BopomofoSyllableError.other
                }

                let nextStart = string.index(string.startIndex, offsetBy: index + 1)
                let next = String(string[nextStart...nextStart])
                if shouldConnectWithYiOrYv(next) {
                    consonant = .ㄑ
                } else {
                    consonant = .ㄘ
                }
            case Consonant.ㄐ.getBraille(by: type):  // ㄍ and ㄐ
                if consonant != nil {
                    throw BopomofoSyllableError.duplicatedConsonant
                }
                if index + 1 >= string.count {
                    throw BopomofoSyllableError.other
                }
                let nextStart = string.index(string.startIndex, offsetBy: index + 1)
                let next = String(string[nextStart...nextStart])
                if shouldConnectWithYiOrYv(next) {
                    consonant = .ㄐ
                } else {
                    consonant = .ㄍ
                }
            case _
            where
                BopomofoSyllable
                .consonantBraille[type.rawValue]
                .contains(s):
                if consonant != nil {
                    throw BopomofoSyllableError.duplicatedConsonant
                }
                if middleVowel != nil || vowel != nil {
                    throw BopomofoSyllableError.consonantShouldBeAtFront
                }
                consonant = Consonant.allCases.first { aCase in
                    BopomofoSyllable.braille(for: aCase, type: type) == s
                }
            case _
            where
                BopomofoSyllable
                .middleVowelBraille[type.rawValue]
                .contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                middleVowel = MiddleVowel.allCases.first { aCase in
                    BopomofoSyllable.braille(for: aCase, type: type) == s
                }
            case _
            where
                BopomofoSyllable
                .vowelBraille[type.rawValue]
                .contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                vowel = Vowel.allCases.first { aCase in
                    BopomofoSyllable.braille(for: aCase, type: type) == s
                }
            case _ where BopomofoSyllable.ㄧBraille[type.rawValue].contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                let combination = ㄧ_Combination.allCases.first { aCase in
                    BopomofoSyllable.braille(for: aCase, type: type) == s
                }
                guard let combination = combination else {
                    throw BopomofoSyllableError.other
                }
                middleVowel = MiddleVowel.ㄧ
                vowel = Vowel(rawValue: combination.rawValue)
            case _ where BopomofoSyllable.ㄨBraille[type.rawValue].contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                let combination = ㄨ_Combination.allCases.first { aCase in
                    BopomofoSyllable.braille(for: aCase, type: type) == s
                }
                guard let combination = combination else {
                    throw BopomofoSyllableError.other
                }
                middleVowel = MiddleVowel.ㄨ
                vowel = Vowel(rawValue: combination.rawValue)
            case _ where BopomofoSyllable.ㄩBraille[type.rawValue].contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                let combination = ㄩ_Combination.allCases.first { aCase in
                    BopomofoSyllable.braille(for: aCase, type: type) == s
                }
                guard let combination = combination else {
                    throw BopomofoSyllableError.other
                }
                middleVowel = MiddleVowel.ㄩ
                vowel = Vowel(rawValue: combination.rawValue)

            case _
            where
                BopomofoSyllable
                .toneBraille[type.rawValue]
                .contains(s):
                if tone != nil {
                    throw BopomofoSyllableError.toneAlreadySet
                }
                tone = Tone.allCases.first { aCase in
                    aCase.getBraille(by: type) == s
                }
            default:
                throw BopomofoSyllableError.invalidCharacter
            }
        }

        guard let tone = tone else {
            throw BopomofoSyllableError.noTone
        }

        self.braille = braille
        self.rawValue = BopomofoSyllable.makeRawValue(consonant, middleVowel, vowel, tone)
        self.type = type
    }

    static private func makeRawValue(
        _ consonant: Consonant?,
        _ middleVowel: MiddleVowel?,
        _ vowel: Vowel?,
        _ tone: Tone
    ) -> String {
        return (consonant?.rawValue ?? "") + (middleVowel?.rawValue ?? "") + (vowel?.rawValue ?? "")
            + tone.rawValue
    }

    static private func makeBraille(
        _ consonant: Consonant?,
        _ middleVowel: MiddleVowel?,
        _ vowel: Vowel?,
        _ tone: Tone,
        _ type: BrailleType = .unicode
    ) -> String {
        var output = ""
        if let consonant {
            output += consonant.getBraille(by: type)
        }
        if let vowel {
            if let middleVowel {
                let c = try? middleVowel.buildCombination(rawValue: vowel.rawValue)
                output += c?.getBraille(by: type) ?? ""
            } else {
                output += vowel.getBraille(by: type)
            }
        } else if let middleVowel {
            output += middleVowel.getBraille(by: type)
        } else if let consonant, consonant.isSingle {
            // ㄭ, which is duplicated with ㄦ, is represented as ㄭ in Braille.
            let suffix = Vowel.ㄦ.getBraille(by: type)
            output += suffix
        }

        output += tone.getBraille(by: type)
        return output
    }
}
