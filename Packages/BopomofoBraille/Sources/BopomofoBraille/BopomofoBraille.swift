import Foundation

fileprivate protocol Syllable {
    var bopomofo: String { get }
    var braille: String { get }
}

fileprivate protocol Combination {
    var bopomofo: String { get }
    var braille: String { get }
}

// MARK: - Syllables

fileprivate enum Consonant: String, CaseIterable, Syllable {
    fileprivate var bopomofo: String {
        return self.rawValue
    }

    fileprivate var braille: String {
        switch self {
        case .ㄅ:
            "⠕"
        case .ㄆ:
            "⠏"
        case .ㄇ:
            "⠍"
        case .ㄈ:
            "⠟"
        case .ㄉ:
            "⠙"
        case .ㄊ:
            "⠋"
        case .ㄋ:
            "⠝"
        case .ㄌ:
            "⠉"
        case .ㄍ:
            "⠅"
        case .ㄎ:
            "⠇"
        case .ㄏ:
            "⠗"
        case .ㄐ:
            "⠅"
        case .ㄑ:
            "⠚"
        case .ㄒ:
            "⠑"
        case .ㄓ:
            "⠁"
        case .ㄔ:
            "⠃"
        case .ㄕ:
            "⠊"
        case .ㄖ:
            "⠛"
        case .ㄗ:
            "⠓"
        case .ㄘ:
            "⠚"
        case .ㄙ:
            "⠑"
        }
    }

    fileprivate var isSingle: Bool {
        switch self {
        case.ㄓ, .ㄔ, .ㄕ, .ㄖ, .ㄗ, .ㄘ, .ㄙ:
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


fileprivate enum MiddleVowel: String, CaseIterable, Syllable {
    fileprivate var bopomofo: String {
        return self.rawValue
    }

    fileprivate var braille: String {
        switch self {
        case .ㄧ:
            "⠡"
        case .ㄨ:
            "⠌"
        case .ㄩ:
            "⠳"
        }
    }

    fileprivate func buildCombination(rawValue: String) throws -> Combination {
        guard let result: Combination = switch self {
        case .ㄧ:
            ㄧ_Combination(rawValue: rawValue)
        case .ㄨ:
            ㄨ_Combination(rawValue: rawValue)
        case .ㄩ:
            ㄩ_Combination(rawValue: rawValue)
        } else {
            throw BopomofoSyllableError.invalidCharacter
        }
        return result
    }

    case ㄧ = "ㄧ"
    case ㄨ = "ㄨ"
    case ㄩ = "ㄩ"
}


fileprivate enum Vowel: String, CaseIterable, Syllable {
    fileprivate var bopomofo: String {
        return self.rawValue
    }
    
    fileprivate var braille: String {
        switch self {
        case .ㄚ:
            "⠜"
        case .ㄛ:
            "⠣"
        case .ㄜ:
            "⠮"
        case .ㄝ:
            "⠢"
        case .ㄞ:
            "⠺"
        case .ㄟ:
            "⠴"
        case .ㄠ:
            "⠩"
        case .ㄡ:
            "⠷"
        case .ㄢ:
            "⠧"
        case .ㄣ:
            "⠥"
        case .ㄤ:
            "⠭"
        case .ㄥ:
            "⠵"
        case .ㄦ:
            "⠱"
        }
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

fileprivate enum ㄧ_Combination: String, CaseIterable, Combination {
    fileprivate var bopomofo: String {
        "ㄧ" + self.rawValue
    }

    fileprivate var braille: String {
        switch self {
        case .ㄧㄚ:
            "⠾"
        case .ㄧㄛ:
            "⠴"
        case .ㄧㄝ:
            "⠬"
        case .ㄧㄞ:
            "⠢"
        case .ㄧㄠ:
            "⠪"
        case .ㄧㄡ:
            "⠎"
        case .ㄧㄢ:
            "⠞"
        case .ㄧㄣ:
            "⠹"
        case .ㄧㄤ:
            "⠨"
        case .ㄧㄥ:
            "⠽"
        }
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

fileprivate enum ㄨ_Combination: String, CaseIterable, Combination {
    fileprivate var bopomofo: String {
        "ㄨ" + self.rawValue
    }

    fileprivate var braille: String {
        switch self {
        case .ㄨㄚ:
            "⠔"
        case .ㄨㄛ:
            "⠒"
        case .ㄨㄞ:
            "⠶"
        case .ㄨㄟ:
            "⠫"
        case .ㄨㄢ:
            "⠻"
        case .ㄨㄣ:
            "⠿"
        case .ㄨㄤ:
            "⠸"
        case .ㄨㄥ:
            "⠯"
        }
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

fileprivate enum ㄩ_Combination: String, CaseIterable, Combination {
    fileprivate var bopomofo: String {
        "ㄩ" + self.rawValue
    }

    fileprivate var braille: String {
        switch self {
        case .ㄩㄝ:
            "⠦"
        case .ㄩㄢ:
            "⠘"
        case .ㄩㄣ:
            "⠲"
        case .ㄩㄥ:
            "⠖"
        }
    }

    case ㄩㄝ = "ㄝ"
    case ㄩㄢ = "ㄢ"
    case ㄩㄣ = "ㄣ"
    case ㄩㄥ = "ㄥ"

}

// MARK: - Tone

fileprivate enum Tone: String, CaseIterable {
    fileprivate var bopomofo: String {
        return self.rawValue
    }

    fileprivate var braille: String {
        switch self {
        case .tone1:
            "⠄"
        case .tone2:
            "⠂"
        case .tone3:
            "⠈"
        case .tone4:
            "⠐"
        case .tone5:
            "⠁"
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
    private static let middleVowelValues = Set(MiddleVowel.allCases.map{ $0.rawValue })
    private static let vowelValues = Set(Vowel.allCases.map { $0.rawValue })
    private static let toneValues = Set(Tone.allCases.map { $0.rawValue })

    private static let consonantBraille = Set(Consonant.allCases.map { $0.braille })
    private static let middleVowelBraille = Set(MiddleVowel.allCases.map{ $0.braille })
    private static let vowelBraille = Set(Vowel.allCases.map { $0.braille })
    private static let toneBraille = Set(Tone.allCases.map { $0.braille })
    private static let ㄧBraille = Set(ㄧ_Combination.allCases.map { $0.braille })
    private static let ㄨBraille = Set(ㄨ_Combination.allCases.map { $0.braille })
    private static let ㄩBraille = Set(ㄩ_Combination.allCases.map { $0.braille })

    public var rawValue: String
    public var braille: String

    public init(rawValue: String) throws {
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
                    _ = try middleVowel.buildCombination(rawValue:s)
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
        func shouldConnectWithYiOrYv(_ next: String) -> Bool {
            return next == MiddleVowel.ㄧ.braille ||
                next ==  MiddleVowel.ㄩ.braille ||
                BopomofoSyllable.ㄧBraille.contains(next) ||
                BopomofoSyllable.ㄩBraille.contains(next)
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
            case "⠁": // ㄓ or tone5
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
            case "⠑": // ㄙ and ㄒ
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
            case "⠚": // ㄑ and ㄘ
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
            case "⠅": // ㄍ and ㄐ
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
        return (consonant?.rawValue ?? "") +
        (middleVowel?.rawValue ?? "") +
        (vowel?.rawValue ?? "") +
        tone.rawValue
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
