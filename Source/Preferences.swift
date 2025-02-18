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
private let kFunctionKeyKeyboardLayoutOverrideIncludeShiftKey =
    "FunctionKeyKeyboardLayoutOverrideIncludeShift"
private let kCandidateListTextSizeKey = "CandidateListTextSize"
private let kSelectPhraseAfterCursorAsCandidateKey = "SelectPhraseAfterCursorAsCandidate"
private let kMoveCursorAfterSelectingCandidateKey = "MoveCursorAfterSelectingCandidate"
private let kUseHorizontalCandidateListPreferenceKey = "UseHorizontalCandidateList"
private let kChooseCandidateUsingSpaceKey = "ChooseCandidateUsingSpaceKey"
private let kChineseConversionEnabledKey = "ChineseConversionEnabled"
private let kHalfWidthPunctuationEnabledKey = "HalfWidthPunctuationEnable"
private let kEscToCleanInputBufferKey = "EscToCleanInputBuffer"
private let kKeepReadingUponCompositionError = "KeepReadingUponCompositionError"

private let kCandidateTextFontName = "CandidateTextFontName"
private let kCandidateKeyLabelFontName = "CandidateKeyLabelFontName"
private let kCandidateKeys = "CandidateKeys"
private let kAllowMovingCursorWhenChoosingCandidates = "AllowMovingCursorWhenChoosingCandidates"

private let kPhraseReplacementEnabledKey = "PhraseReplacementEnabled"
private let kChineseConversionStyleKey = "ChineseConversionStyle"
private let kAssociatedPhrasesEnabledKey = "AssociatedPhrasesEnabled"
private let kLetterBehaviorKey = "LetterBehavior"
private let kControlEnterOutputKey = "ControlEnterOutput"
private let kShiftEnterEnabledKey = "ShiftEnterEnabled"
private let kUseCustomUserPhraseLocation = "UseCustomUserPhraseLocation"
private let kCustomUserPhraseLocation = "CustomUserPhraseLocation"

private let kDefaultCandidateListTextSize: CGFloat = 16
private let kMinCandidateListTextSize: CGFloat = 12
private let kMaxCandidateListTextSize: CGFloat = 196

private let kDefaultKeys = "123456789"
private let kDefaultAssociatedPhrasesKeys = "!@#$%^&*("

private let kAddPhraseHookEnabledKey = "AddPhraseHookEnabled"
private let kAddPhraseHookPath = "AddPhraseHookPath"

private let kSelectCandidateWithNumericKeypad = "SelectCandidateWithNumericKeypad"
private let kBig5InputEnabledKey = "Big5InputEnabled"

// Need to be populated to true by default upon first start, so the key is not private.
let kBeepUponInputErrorKey = "BeepUponInputError"

private let kEnableUserPhrasesInPlainBopomofo = "EnableUserPhrasesInPlainBopomofo"

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
struct UserDefaultWithFunction<Value> {
    let key: String
    let defaultValueFunction: () -> Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            container.object(forKey: key) as? Value ?? defaultValueFunction()
        }
        set {
            container.set(newValue, forKey: key)
        }
    }
}

@propertyWrapper
struct EnumUserDefault<T: RawRepresentable> {
    let key: String
    let defaultValue: T
    var container: UserDefaults = .standard

    var wrappedValue: T {
        get {
            if let value = container.object(forKey: key) as? T.RawValue {
                return T(rawValue: value) ?? defaultValue
            }
            return defaultValue
        }
        set {
            container.set(newValue.rawValue, forKey: key)
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

// MARK: -

@objc enum KeyboardLayout: Int {
    case standard = 0
    case eten = 1
    case hsu = 2
    case eten26 = 3
    case hanyuPinyin = 4
    case IBM = 5

    var name: String {
        return switch self {
        case .standard:
            "Standard"
        case .eten:
            "ETen"
        case .hsu:
            "Hsu"
        case .eten26:
            "ETen26"
        case .hanyuPinyin:
            "HanyuPinyin"
        case .IBM:
            "IBM"
        }
    }
}

@objc enum ChineseConversionStyle: Int {
    case output
    case model

    var name: String {
        return switch self {
        case .output:
            "output"
        case .model:
            "model"
        }
    }
}

// MARK: -

class Preferences: NSObject {
    static var allKeys: [String] {
        [
            kKeyboardLayoutPreferenceKey,
            kBasisKeyboardLayoutPreferenceKey,
            kFunctionKeyKeyboardLayoutPreferenceKey,
            kFunctionKeyKeyboardLayoutOverrideIncludeShiftKey,
            kCandidateListTextSizeKey,
            kSelectPhraseAfterCursorAsCandidateKey,
            kUseHorizontalCandidateListPreferenceKey,
            kChooseCandidateUsingSpaceKey,
            kChineseConversionEnabledKey,
            kHalfWidthPunctuationEnabledKey,
            kEscToCleanInputBufferKey,
            kKeepReadingUponCompositionError,
            kCandidateTextFontName,
            kCandidateKeyLabelFontName,
            kCandidateKeys,
            kPhraseReplacementEnabledKey,
            kChineseConversionStyleKey,
            kAssociatedPhrasesEnabledKey,
            kControlEnterOutputKey,
            kShiftEnterEnabledKey,
            kUseCustomUserPhraseLocation,
            kCustomUserPhraseLocation,
        ]
    }

    @objc static func populateDefaults() {
        Preferences.keyboardLayout = Preferences.keyboardLayout
        Preferences.basisKeyboardLayout = Preferences.basisKeyboardLayout
        Preferences.functionKeyboardLayout = Preferences.functionKeyboardLayout
        Preferences.candidateKeys = Preferences.candidateKeys
        Preferences.selectPhraseAfterCursorAsCandidate = Preferences.selectPhraseAfterCursorAsCandidate
        Preferences.moveCursorAfterSelectingCandidate = Preferences.moveCursorAfterSelectingCandidate
        Preferences.useHorizontalCandidateList = Preferences.useHorizontalCandidateList
        Preferences.chineseConversionEnabled = Preferences.chineseConversionEnabled
        Preferences.halfWidthPunctuationEnabled = Preferences.halfWidthPunctuationEnabled
        Preferences.selectCandidateWithNumericKeypad = Preferences.selectCandidateWithNumericKeypad
        Preferences.big5InputEnabled = Preferences.big5InputEnabled
        Preferences.chineseConversionStyle = Preferences.chineseConversionStyle
        Preferences.phraseReplacementEnabled = Preferences.phraseReplacementEnabled
        Preferences.associatedPhrasesEnabled = Preferences.associatedPhrasesEnabled
        Preferences.letterBehavior = Preferences.letterBehavior
        Preferences.controlEnterOutput = Preferences.controlEnterOutput
        Preferences.shiftEnterEnabled = Preferences.shiftEnterEnabled
        Preferences.addPhraseHookEnabled = Preferences.addPhraseHookEnabled
        Preferences.addPhraseHookPath = Preferences.addPhraseHookPath
        Preferences.beepUponInputError = Preferences.beepUponInputError
        Preferences.enableUserPhrasesInPlainBopomofo = Preferences.enableUserPhrasesInPlainBopomofo
    }

    @EnumUserDefault(key: kKeyboardLayoutPreferenceKey, defaultValue: KeyboardLayout.standard)
    @objc static var keyboardLayout: KeyboardLayout

    @objc static var keyboardLayoutName: String {
        keyboardLayout.name
    }

    @UserDefault(key: kBasisKeyboardLayoutPreferenceKey, defaultValue: "com.apple.keylayout.US")
    @objc static var basisKeyboardLayout: String

    @UserDefault(
        key: kFunctionKeyKeyboardLayoutPreferenceKey, defaultValue: "com.apple.keylayout.US")
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

    @UserDefault(key: kChooseCandidateUsingSpaceKey, defaultValue: true)
    @objc static var chooseCandidateUsingSpace: Bool

    @UserDefault(key: kChineseConversionEnabledKey, defaultValue: false)
    @objc static var chineseConversionEnabled: Bool

    @objc static func toggleChineseConversionEnabled() -> Bool {
        chineseConversionEnabled = !chineseConversionEnabled
        return chineseConversionEnabled
    }

    @UserDefault(key: kHalfWidthPunctuationEnabledKey, defaultValue: false)
    @objc static var halfWidthPunctuationEnabled: Bool

    @objc static func toggleHalfWidthPunctuationEnabled() -> Bool {
        halfWidthPunctuationEnabled = !halfWidthPunctuationEnabled
        return halfWidthPunctuationEnabled
    }

    @UserDefault(key: kEscToCleanInputBufferKey, defaultValue: false)
    @objc static var escToCleanInputBuffer: Bool

    @UserDefault(key: kKeepReadingUponCompositionError, defaultValue: false)
    @objc static var keepReadingUponCompositionError: Bool

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
                return NSLocalizedString(
                    "Candidate keys can only contain Latin characters and numbers.", comment: "")
            case .containSpace:
                return NSLocalizedString("Candidate keys cannot contain space.", comment: "")
            case .duplicatedCharacters:
                return NSLocalizedString("There should not be duplicated keys.", comment: "")
            case .tooShort:
                return NSLocalizedString(
                    "Candidate keys cannot be shorter than 4 characters.", comment: "")
            case .tooLong:
                return NSLocalizedString(
                    "Candidate keys cannot be longer than 15 characters.", comment: "")
            }
        }
    }

    /// Whether allows moving the cursor by J/K keys, when the candidate
    /// window is presented.
    @UserDefault(key: kAllowMovingCursorWhenChoosingCandidates, defaultValue: false)
    @objc static var allowMovingCursorWhenChoosingCandidates: Bool
}

extension Preferences {
    /// The conversion style.
    ///
    /// - 0: convert the output
    /// - 1: convert the phrase models.
    @EnumUserDefault(key: kChineseConversionStyleKey, defaultValue: ChineseConversionStyle.output)
    @objc static var chineseConversionStyle: ChineseConversionStyle

    @objc static var chineseConversionStyleName: String {
        chineseConversionStyle.name
    }
}

extension Preferences {

    @UserDefault(key: kPhraseReplacementEnabledKey, defaultValue: false)
    @objc static var phraseReplacementEnabled: Bool

    @objc static func togglePhraseReplacementEnabled() -> Bool {
        phraseReplacementEnabled = !phraseReplacementEnabled
        return phraseReplacementEnabled
    }

    @UserDefault(key: kAssociatedPhrasesEnabledKey, defaultValue: false)
    @objc static var associatedPhrasesEnabled: Bool

    @objc static func toggleAssociatedPhrasesEnabled() -> Bool {
        associatedPhrasesEnabled = !associatedPhrasesEnabled
        return associatedPhrasesEnabled
    }

    @UserDefault(key: kShiftEnterEnabledKey, defaultValue: true)
    @objc static var shiftEnterEnabled: Bool
}

@objc enum ControlEnterOutput: Int {
    case off = 0
    case bpmfReading = 1
    case htmlRuby = 2
    case braille = 3
    case hanyuPinyin = 4
}

extension Preferences {
    /// The behavior of pressing letter keys.
    ///
    /// - 0: Output upper-cased letters directly.
    /// - 1: Output lower-cased letters in the composing buffer.
    @UserDefault(key: kLetterBehaviorKey, defaultValue: 0)
    @objc static var letterBehavior: Int

    /// The behavior of pressing Ctrl + Enter.
    ///
    /// - 0: Disabled.
    /// - 1: Output BPMF readings.
    @EnumUserDefault(key: kControlEnterOutputKey, defaultValue: .off)
    @objc static var controlEnterOutput: ControlEnterOutput
}

@objc class UserPhraseLocationHelper: NSObject {
    @objc static var defaultUserPhraseLocation: String {
        let paths = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true)
        let appSupportPath = paths.first!
        return (appSupportPath as NSString).appendingPathComponent("McBopomofo")
    }
}

extension NSNotification.Name {
    static var userPhraseLocationDidChange = NSNotification.Name(
        rawValue: "UserPhraseLocationDidChangeNotification")
}

extension Preferences {

    static func postUserPhraseLocationNotification() {
        let location: String = {
            if !useCustomUserPhraseLocation {
                return UserPhraseLocationHelper.defaultUserPhraseLocation
            }
            if customUserPhraseLocation.isEmpty {
                return UserPhraseLocationHelper.defaultUserPhraseLocation
            }
            return customUserPhraseLocation
        }()
        let notification = Notification(
            name: .userPhraseLocationDidChange, object: self,
            userInfo: [
                "location": location
            ])
        NotificationQueue.default.dequeueNotifications(matching: notification, coalesceMask: 0)
        NotificationQueue.default.enqueue(notification, postingStyle: .now)
    }

    @UserDefault(key: kUseCustomUserPhraseLocation, defaultValue: false)
    @objc static var useCustomUserPhraseLocation: Bool {
        didSet {
            postUserPhraseLocationNotification()
        }
    }

    @UserDefault(key: kCustomUserPhraseLocation, defaultValue: "")
    @objc static var customUserPhraseLocation: String {
        didSet {
            postUserPhraseLocationNotification()
        }
    }
}

extension Preferences {
    static func defaultAddPhraseHookPath() -> String {
        let bundle = Bundle.main
        let hookPath = bundle.path(forResource: "add-phrase-hook", ofType: "sh")
        return hookPath!
    }

    @UserDefault(key: kAddPhraseHookEnabledKey, defaultValue: false)
    @objc static var addPhraseHookEnabled: Bool

    @UserDefaultWithFunction(
        key: kAddPhraseHookPath, defaultValueFunction: defaultAddPhraseHookPath)
    @objc static var addPhraseHookPath: String
}

extension Preferences {
    @UserDefault(key: kSelectCandidateWithNumericKeypad, defaultValue: false)
    @objc static var selectCandidateWithNumericKeypad: Bool
}

extension Preferences {
    @UserDefault(key: kBig5InputEnabledKey, defaultValue: true)
    @objc static var big5InputEnabled: Bool
}

extension Preferences {
    @UserDefault(key: kBeepUponInputErrorKey, defaultValue: true)
    @objc static var beepUponInputError: Bool
}

extension Preferences {
    @UserDefault(key: kEnableUserPhrasesInPlainBopomofo, defaultValue: false)
    @objc static var enableUserPhrasesInPlainBopomofo: Bool
}
