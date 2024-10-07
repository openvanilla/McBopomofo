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
    var brailleCode: String { get }
}

private protocol Combination {
    var bopomofo: String { get }
    var braille: String { get }
    var brailleCode: String { get }
}

// MARK: - Syllables

private enum Consonant: String, CaseIterable, Syllable {

    static let bpmfBrailleMap: [Consonant: (String, String)] = [
        .ㄅ: ("⠕", "135"),
        .ㄆ: ("⠏", "1234"),
        .ㄇ: ("⠍", "134"),
        .ㄈ: ("⠟", "12345"),
        .ㄉ: ("⠙", "145"),
        .ㄊ: ("⠋", "124"),
        .ㄋ: ("⠝", "1345"),
        .ㄌ: ("⠉", "14"),
        .ㄍ: ("⠅", "13"),
        .ㄎ: ("⠇", "123"),
        .ㄏ: ("⠗", "1235"),
        .ㄐ: ("⠅", "13"),
        .ㄑ: ("⠚", "245"),
        .ㄒ: ("⠑", "15"),
        .ㄓ: ("⠁", "1"),
        .ㄔ: ("⠃", "12"),
        .ㄕ: ("⠊", "24"),
        .ㄖ: ("⠛", "1245"),
        .ㄗ: ("⠓", "125"),
        .ㄘ: ("⠚", "245"),
        .ㄙ: ("⠑", "15"),
    ]

    fileprivate var bopomofo: String {
        self.rawValue
    }

    fileprivate var braille: String {
        Consonant.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleCode: String {
        Consonant.bpmfBrailleMap[self]!.1
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
    static let bpmfBrailleMap: [MiddleVowel: (String, String)] = [
        .ㄧ: ("⠡", "16"),
        .ㄨ: ("⠌", "34"),
        .ㄩ: ("⠳", "1256"),
    ]
    fileprivate var bopomofo: String {
        self.rawValue
    }

    fileprivate var braille: String {
        MiddleVowel.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleCode: String {
        MiddleVowel.bpmfBrailleMap[self]!.1
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
    static let bpmfBrailleMap: [Vowel: (String, String)] = [
        .ㄚ: ("⠜", "345"),
        .ㄛ: ("⠣", "126"),
        .ㄜ: ("⠮", "2346"),
        .ㄝ: ("⠢", "26"),
        .ㄞ: ("⠺", "2456"),
        .ㄟ: ("⠴", "356"),
        .ㄠ: ("⠩", "146"),
        .ㄡ: ("⠷", "12356"),
        .ㄢ: ("⠧", "1236"),
        .ㄣ: ("⠥", "136"),
        .ㄤ: ("⠭", "1346"),
        .ㄥ: ("⠵", "1356"),
        .ㄦ: ("⠱", "156"),
    ]

    fileprivate var bopomofo: String {
        self.rawValue
    }

    fileprivate var braille: String {
        Vowel.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleCode: String {
        Vowel.bpmfBrailleMap[self]!.1
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
    static let bpmfBrailleMap: [ㄧ_Combination: (String, String)] = [
        .ㄧㄚ: ("⠾", "23456"),
        .ㄧㄛ: ("⠴", "356"),
        .ㄧㄝ: ("⠬", "346"),
        .ㄧㄞ: ("⠢", "26"),
        .ㄧㄠ: ("⠪", "246"),
        .ㄧㄡ: ("⠎", "234"),
        .ㄧㄢ: ("⠞", "2345"),
        .ㄧㄣ: ("⠹", "1456"),
        .ㄧㄤ: ("⠨", "46"),
        .ㄧㄥ: ("⠽", "13456"),
    ]

    fileprivate var bopomofo: String {
        "ㄧ" + self.rawValue
    }

    fileprivate var braille: String {
        ㄧ_Combination.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleCode: String {
        ㄧ_Combination.bpmfBrailleMap[self]!.1
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
    static let bpmfBrailleMap: [ㄨ_Combination: (String, String)] = [
        .ㄨㄚ: ("⠔", "35"),
        .ㄨㄛ: ("⠒", "25"),
        .ㄨㄞ: ("⠶", "2356"),
        .ㄨㄟ: ("⠫", "1246"),
        .ㄨㄢ: ("⠻", "12456"),
        .ㄨㄣ: ("⠿", "123456"),
        .ㄨㄤ: ("⠸", "456"),
        .ㄨㄥ: ("⠯", "12346"),
    ]

    fileprivate var bopomofo: String {
        "ㄨ" + self.rawValue
    }

    fileprivate var braille: String {
        ㄨ_Combination.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleCode: String {
        ㄨ_Combination.bpmfBrailleMap[self]!.1
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
    static let bpmfBrailleMap: [ㄩ_Combination: (String, String)] = [
        .ㄩㄝ: ("⠦", "236"),
        .ㄩㄢ: ("⠘", "45"),
        .ㄩㄣ: ("⠲", "256"),
        .ㄩㄥ: ("⠖", "235"),
    ]

    fileprivate var bopomofo: String {
        "ㄩ" + self.rawValue
    }

    fileprivate var braille: String {
        ㄩ_Combination.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleCode: String {
        ㄩ_Combination.bpmfBrailleMap[self]!.1
    }

    case ㄩㄝ = "ㄝ"
    case ㄩㄢ = "ㄢ"
    case ㄩㄣ = "ㄣ"
    case ㄩㄥ = "ㄥ"

}

// MARK: - Tone

private enum Tone: String, CaseIterable {
    static let bpmfBrailleMap: [Tone: (String, String)] = [
        .tone1: ("⠄", "3"),
        .tone2: ("⠂", "2"),
        .tone3: ("⠈", "4"),
        .tone4: ("⠐", "5"),
        .tone5: ("⠁", "1"),
    ]

    fileprivate var bopomofo: String {
        return self.rawValue
    }

    fileprivate var braille: String {
        Tone.bpmfBrailleMap[self]!.0
    }

    fileprivate var brailleCode: String {
        Tone.bpmfBrailleMap[self]!.1
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

    private static let consonantBraille = Set(Consonant.allCases.map { $0.braille })
    private static let middleVowelBraille = Set(MiddleVowel.allCases.map { $0.braille })
    private static let vowelBraille = Set(Vowel.allCases.map { $0.braille })
    private static let toneBraille = Set(Tone.allCases.map { $0.braille })
    private static let ㄧBraille = Set(ㄧ_Combination.allCases.map { $0.braille })
    private static let ㄨBraille = Set(ㄨ_Combination.allCases.map { $0.braille })
    private static let ㄩBraille = Set(ㄩ_Combination.allCases.map { $0.braille })

    public var rawValue: String
    public var braille: String

    public init(rawValue: String) throws {
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
        self.braille = BopomofoSyllable.makeBraille(consonant, middleVowel, vowel, tone)
    }

    public init(braille: String) throws {

        if braille.count < kMinimalBrailleLength {
            throw BopomofoSyllableError.invalidLength
        }

        func shouldConnectWithYiOrYv(_ next: String) -> Bool {
            return next == MiddleVowel.ㄧ.braille || next == MiddleVowel.ㄩ.braille
                || BopomofoSyllable.ㄧBraille.contains(next)
                || BopomofoSyllable.ㄩBraille.contains(next)
        }

        var consonant: Consonant?
        var middleVowel: MiddleVowel?
        var vowel: Vowel?
        var tone: Tone?

        let string = braille.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        for (index, c) in string.enumerated() {
            let s = String(c)
            switch s {
            case "⠱":
                if index == 0 {
                    vowel = .ㄦ
                }
                if let consonant, consonant.isSingle == false {
                    throw BopomofoSyllableError.other
                }
            case "⠁":  // ㄓ or tone5
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
            case "⠑":  // ㄙ and ㄒ
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
            case "⠚":  // ㄑ and ㄘ
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
            case "⠅":  // ㄍ and ㄐ
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
            case _ where BopomofoSyllable.consonantBraille.contains(s):
                if consonant != nil {
                    throw BopomofoSyllableError.duplicatedConsonant
                }
                if middleVowel != nil || vowel != nil {
                    throw BopomofoSyllableError.consonantShouldBeAtFront
                }
                consonant = Consonant.allCases.first { aCase in
                    aCase.braille == s
                }
            case _ where BopomofoSyllable.middleVowelBraille.contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                middleVowel = MiddleVowel.allCases.first { aCase in
                    aCase.braille == s
                }
            case _ where BopomofoSyllable.vowelBraille.contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                vowel = Vowel.allCases.first { aCase in
                    aCase.braille == s
                }
            case _ where BopomofoSyllable.ㄧBraille.contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                let combination = ㄧ_Combination.allCases.first { aCase in
                    aCase.braille == s
                }
                guard let combination = combination else {
                    throw BopomofoSyllableError.other
                }
                middleVowel = MiddleVowel.ㄧ
                vowel = Vowel(rawValue: combination.rawValue)
            case _ where BopomofoSyllable.ㄨBraille.contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                let combination = ㄨ_Combination.allCases.first { aCase in
                    aCase.braille == s
                }
                guard let combination = combination else {
                    throw BopomofoSyllableError.other
                }
                middleVowel = MiddleVowel.ㄨ
                vowel = Vowel(rawValue: combination.rawValue)
            case _ where BopomofoSyllable.ㄩBraille.contains(s):
                if middleVowel != nil {
                    throw BopomofoSyllableError.middleVowelAlreadySet
                }
                if vowel != nil {
                    throw BopomofoSyllableError.vowelAlreadySet
                }
                let combination = ㄩ_Combination.allCases.first { aCase in
                    aCase.braille == s
                }
                guard let combination = combination else {
                    throw BopomofoSyllableError.other
                }
                middleVowel = MiddleVowel.ㄩ
                vowel = Vowel(rawValue: combination.rawValue)

            case _ where BopomofoSyllable.toneBraille.contains(s):
                if tone != nil {
                    throw BopomofoSyllableError.toneAlreadySet
                }
                tone = Tone.allCases.first { aCase in
                    aCase.braille == s
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
        _ tone: Tone
    ) -> String {
        var output = ""
        if let consonant {
            output += consonant.braille
        }
        if let vowel {
            if let middleVowel {
                let c = try? middleVowel.buildCombination(rawValue: vowel.rawValue)
                output += c?.braille ?? ""
            } else {
                output += vowel.braille
            }
        } else if let middleVowel {
            output += middleVowel.braille
        } else if let consonant, consonant.isSingle {
            // ㄭ
            output += "⠱"
        }

        output += tone.braille
        return output
    }
}
