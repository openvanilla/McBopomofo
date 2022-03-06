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

import Cocoa

private let kKeyboardLayoutPreferenceKey = "KeyboardLayout"
/// alphanumeric ("ASCII") input basic keyboard layout.
private let kBasisKeyboardLayoutPreferenceKey = "BasisKeyboardLayout"
/// alphanumeric ("ASCII") input basic keyboard layout.
private let kFunctionKeyKeyboardLayoutPreferenceKey = "FunctionKeyKeyboardLayout"
/// whether include shift.
private let kFunctionKeyKeyboardLayoutOverrideIncludeShiftKey = "FunctionKeyKeyboardLayoutOverrideIncludeShift"
private let kCandidateListTextSizeKey = "CandidateListTextSize"
private let kSelectPhraseAfterCursorAsCandidateKey = "SelectPhraseAfterCursorAsCandidate"
private let kMoveCursorAfterSelectingCandidateKey = "MoveCursorAfterSelectingCandidate"
private let kUseHorizontalCandidateListPreferenceKey = "UseHorizontalCandidateList"
private let kComposingBufferSizePreferenceKey = "ComposingBufferSize"
private let kChooseCandidateUsingSpaceKey = "ChooseCandidateUsingSpaceKey"
private let kChineseConversionEnabledKey = "ChineseConversionEnabled"
private let kHalfWidthPunctuationEnabledKey = "HalfWidthPunctuationEnable"
private let kEscToCleanInputBufferKey = "EscToCleanInputBuffer"

private let kCandidateTextFontName = "CandidateTextFontName"
private let kCandidateKeyLabelFontName = "CandidateKeyLabelFontName"
private let kCandidateKeys = "CandidateKeys"
private let kPhraseReplacementEnabledKey = "PhraseReplacementEnabled"
private let kChineseConversionEngineKey = "ChineseConversionEngine"
private let kChineseConversionStyleKey = "ChineseConversionStyle"
private let kEmojiInputEnabledKey = "EmojiInputEnabled"
private let kAssociatedPhrasesEnabledKey = "AssociatedPhrasesEnabled"
private let kControlEnterOutputKey = "ControlEnterOutput"

private let kDefaultCandidateListTextSize: CGFloat = 16
private let kMinCandidateListTextSize: CGFloat = 12
private let kMaxCandidateListTextSize: CGFloat = 196

// default, min and max composing buffer size (in codepoints)
// modern Macs can usually work up to 16 codepoints when the builder still
// walks the grid with good performance; slower Macs (like old PowerBooks)
// will start to sputter beyond 12; such is the algorithmatic complexity
// of the Viterbi algorithm used in the builder library (at O(N^2))
private let kDefaultComposingBufferSize = 10
private let kMinComposingBufferSize = 4
private let kMaxComposingBufferSize = 20

private let kDefaultKeys = "123456789"
private let kDefaultAssociatedPhrasesKeys = "!@#$%^&*("

// MARK: Property wrappers

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            container.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct CandidateListTextSize {
    let key: String
    let defaultValue: CGFloat = kDefaultCandidateListTextSize
    lazy var container: UserDefault = {
        UserDefault(key: key, defaultValue: defaultValue)
    }()

    var wrappedValue: CGFloat {
        mutating get {
            var value = container.wrappedValue
            if value < kMinCandidateListTextSize {
                value = kMinCandidateListTextSize
            } else if value > kMaxCandidateListTextSize {
                value = kMaxCandidateListTextSize
            }
            return value
        }
        set {
            var value = newValue
            if value < kMinCandidateListTextSize {
                value = kMinCandidateListTextSize
            } else if value > kMaxCandidateListTextSize {
                value = kMaxCandidateListTextSize
            }
            container.wrappedValue = value
        }
    }
}

@propertyWrapper
struct ComposingBufferSize {
    let key: String
    let defaultValue: Int = kDefaultComposingBufferSize
    lazy var container: UserDefault = {
        UserDefault(key: key, defaultValue: defaultValue)
    }()

    var wrappedValue: Int {
        mutating get {
            let currentValue = container.wrappedValue
            if currentValue < kMinComposingBufferSize {
                return kMinComposingBufferSize
            } else if currentValue > kMaxComposingBufferSize {
                return kMaxComposingBufferSize
            }
            return currentValue
        }
        set {
            var value = newValue
            if value < kMinComposingBufferSize {
                value = kMinComposingBufferSize
            } else if value > kMaxComposingBufferSize {
                value = kMaxComposingBufferSize
            }
            container.wrappedValue = value
        }
    }
}

// MARK: -

@objc enum KeyboardLayout: Int {
    case standard = 0
    case eten = 1
    case hsu = 2
    case eten26 = 3
    case hanyuPinyin = 4
    case IBM = 5

    var name: String {
        switch (self) {
        case .standard:
            return "Standard"
        case .eten:
            return "ETen"
        case .hsu:
            return "Hsu"
        case .eten26:
            return "ETen26"
        case .hanyuPinyin:
            return "HanyuPinyin"
        case .IBM:
            return "IBM"
        }
    }
}

@objc enum ChineseConversionEngine: Int {
    case openCC
    case vxHanConvert

    var name: String {
        switch (self) {
        case .openCC:
            return "OpenCC"
        case .vxHanConvert:
            return "VXHanConvert"
        }
    }
}

@objc enum ChineseConversionStyle: Int {
    case output
    case model

    var name: String {
        switch (self) {
        case .output:
            return "output"
        case .model:
            return "model"
        }
    }
}

// MARK: -

class Preferences: NSObject {
    static var allKeys:[String] {
        [kKeyboardLayoutPreferenceKey,
         kBasisKeyboardLayoutPreferenceKey,
         kFunctionKeyKeyboardLayoutPreferenceKey,
         kFunctionKeyKeyboardLayoutOverrideIncludeShiftKey,
         kCandidateListTextSizeKey,
         kSelectPhraseAfterCursorAsCandidateKey,
         kUseHorizontalCandidateListPreferenceKey,
         kComposingBufferSizePreferenceKey,
         kChooseCandidateUsingSpaceKey,
         kChineseConversionEnabledKey,
         kEmojiInputEnabledKey,
         kHalfWidthPunctuationEnabledKey,
         kEscToCleanInputBufferKey,
         kCandidateTextFontName,
         kCandidateKeyLabelFontName,
         kCandidateKeys,
         kPhraseReplacementEnabledKey,
         kChineseConversionEngineKey,
         kChineseConversionStyleKey,
         kAssociatedPhrasesEnabledKey]
    }


    @UserDefault(key: kKeyboardLayoutPreferenceKey, defaultValue: 0)
    @objc static var keyboardLayout: Int

    @objc static var keyboardLayoutName: String {
        (KeyboardLayout(rawValue: keyboardLayout) ?? KeyboardLayout.standard).name
    }

    @UserDefault(key: kBasisKeyboardLayoutPreferenceKey, defaultValue: "com.apple.keylayout.US")
    @objc static var basisKeyboardLayout: String

    @UserDefault(key: kFunctionKeyKeyboardLayoutPreferenceKey, defaultValue: "com.apple.keylayout.US")
    @objc static var functionKeyboardLayout: String

    @UserDefault(key: kFunctionKeyKeyboardLayoutOverrideIncludeShiftKey, defaultValue: false)
    @objc static var functionKeyKeyboardLayoutOverrideIncludeShiftKey: Bool

    @CandidateListTextSize(key: kCandidateListTextSizeKey)
    @objc static var candidateListTextSize: CGFloat

    @UserDefault(key: kSelectPhraseAfterCursorAsCandidateKey, defaultValue: false)
    @objc static var selectPhraseAfterCursorAsCandidate: Bool

    @UserDefault(key: kMoveCursorAfterSelectingCandidateKey, defaultValue: false)
    @objc static var moveCursorAfterSelectingCandidate: Bool

    @UserDefault(key: kUseHorizontalCandidateListPreferenceKey, defaultValue: false)
    @objc static var useHorizontalCandidateList: Bool

    @ComposingBufferSize(key: kComposingBufferSizePreferenceKey)
    @objc static var composingBufferSize: Int

    @UserDefault(key: kChooseCandidateUsingSpaceKey, defaultValue: true)
    @objc static var chooseCandidateUsingSpace: Bool

    @UserDefault(key: kChineseConversionEnabledKey, defaultValue: false)
    @objc static var chineseConversionEnabled: Bool

    @objc static func toggleChineseConversionEnabled() -> Bool {
        chineseConversionEnabled = !chineseConversionEnabled
        return chineseConversionEnabled
    }

    @UserDefault(key: kEmojiInputEnabledKey, defaultValue: false)
    @objc static var emojiInputEnabled: Bool

    @objc static func toggleEmojiInputEnabled() -> Bool {
        emojiInputEnabled = !emojiInputEnabled
        return emojiInputEnabled
    }

    @UserDefault(key: kHalfWidthPunctuationEnabledKey, defaultValue: false)
    @objc static var halfWidthPunctuationEnabled: Bool

    @objc static func toggleHalfWidthPunctuationEnabled() -> Bool {
        halfWidthPunctuationEnabled = !halfWidthPunctuationEnabled
        return halfWidthPunctuationEnabled
    }

    @UserDefault(key: kEscToCleanInputBufferKey, defaultValue: false)
    @objc static var escToCleanInputBuffer: Bool

    // MARK: Optional settings

    @UserDefault(key: kCandidateTextFontName, defaultValue: nil)
    @objc static var candidateTextFontName: String?

    @UserDefault(key: kCandidateKeyLabelFontName, defaultValue: nil)
    @objc static var candidateKeyLabelFontName: String?

    @UserDefault(key: kCandidateKeys, defaultValue: kDefaultKeys)
    @objc static var candidateKeys: String

    @objc static var defaultCandidateKeys: String {
        kDefaultKeys
    }
    @objc static var suggestedCandidateKeys: [String] {
        [kDefaultKeys, "asdfghjkl", "asdfzxcvb"]
    }

    static func validate(candidateKeys: String) throws {
        let trimmed = candidateKeys.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw CandidateKeyError.empty
        }
        if !trimmed.canBeConverted(to: .ascii) {
            throw CandidateKeyError.invalidCharacters
        }
        if trimmed.contains(" ") {
            throw CandidateKeyError.containSpace
        }
        if trimmed.count < 4 {
            throw CandidateKeyError.tooShort
        }
        if trimmed.count > 15 {
            throw CandidateKeyError.tooLong
        }
        let set = Set(Array(trimmed))
        if set.count != trimmed.count {
            throw CandidateKeyError.duplicatedCharacters
        }
    }

    enum CandidateKeyError: Error, LocalizedError {
        case empty
        case invalidCharacters
        case containSpace
        case duplicatedCharacters
        case tooShort
        case tooLong

        var errorDescription: String? {
            switch self {
            case .empty:
                return NSLocalizedString("Candidates keys cannot be empty.", comment: "")
            case .invalidCharacters:
                return NSLocalizedString("Candidate keys can only contain Latin characters and numbers.", comment: "")
            case .containSpace:
                return NSLocalizedString("Candidate keys cannot contain space.", comment: "")
            case .duplicatedCharacters:
                return NSLocalizedString("There should not be duplicated keys.", comment: "")
            case .tooShort:
                return NSLocalizedString("Candidate keys cannot be shorter than 4 characters.", comment: "")
            case .tooLong:
                return NSLocalizedString("Candidate keys cannot be longer than 15 characters.", comment: "")
            }
        }

    }

    @UserDefault(key: kPhraseReplacementEnabledKey, defaultValue: false)
    @objc static var phraseReplacementEnabled: Bool

    @objc static func togglePhraseReplacementEnabled() -> Bool {
        phraseReplacementEnabled = !phraseReplacementEnabled
        return phraseReplacementEnabled
    }

    /// The conversion engine.
    ///
    /// - 0: OpenCC
    /// - 1: VXHanConvert
    @UserDefault(key: kChineseConversionEngineKey, defaultValue: 0)
    @objc static var chineseConversionEngine: Int

    @objc static var chineseConversionEngineName: String? {
        ChineseConversionEngine(rawValue: chineseConversionEngine)?.name
    }

    /// The conversion style.
    ///
    /// - 0: convert the output
    /// - 1: convert the phrase models.
    @UserDefault(key: kChineseConversionStyleKey, defaultValue: 0)
    @objc static var chineseConversionStyle: Int

    @objc static var chineseConversionStyleName: String? {
        ChineseConversionStyle(rawValue: chineseConversionStyle)?.name
    }

    @UserDefault(key: kAssociatedPhrasesEnabledKey, defaultValue: false)
    @objc static var associatedPhrasesEnabled: Bool

    @objc static func toggleAssociatedPhrasesEnabled() -> Bool {
        associatedPhrasesEnabled = !associatedPhrasesEnabled
        return associatedPhrasesEnabled
    }

    @UserDefault(key: kControlEnterOutputKey, defaultValue: 0)
    @objc static var controlEnterOutput: Int
}
