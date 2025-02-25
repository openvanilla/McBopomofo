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

import Testing

@testable import McBopomofo

@Suite("Preference Tests", .serialized)
final class PreferencesTests {

    func reset() {
        Preferences.allKeys.forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }

    func makeSnapshot() -> [String: Any] {
        var dict = [String: Any]()
        Preferences.allKeys.forEach {
            dict[$0] = UserDefaults.standard.object(forKey: $0)
        }
        return dict
    }

    func restore(from snapshot: [String: Any]) {
        Preferences.allKeys.forEach {
            UserDefaults.standard.set(snapshot[$0], forKey: $0)
        }
    }

    var snapshot: [String: Any]?

    init() async throws {
        snapshot = makeSnapshot()
        reset()
    }

    deinit {
        if let snapshot = snapshot {
            restore(from: snapshot)
        }
    }

    @Test("Test keyboard layout setting")
    func testKeyboardLayout() {
        #expect(Preferences.keyboardLayout == .standard)
        Preferences.keyboardLayout = .eten
        #expect(Preferences.keyboardLayout == .eten)
    }

    @Test("Test keyboard layout name conversion")
    func testKeyboardLayoutName() {
        #expect(Preferences.keyboardLayoutName == "Standard")
        Preferences.keyboardLayout = .eten
        #expect(Preferences.keyboardLayoutName == "ETen")
    }

    @Test("Test basis keyboard layout preference key")
    func testBasisKeyboardLayoutPreferenceKey() {
        #expect(Preferences.basisKeyboardLayout == "com.apple.keylayout.US")
        Preferences.basisKeyboardLayout = "com.apple.keylayout.ABC"
        #expect(Preferences.basisKeyboardLayout == "com.apple.keylayout.ABC")
    }

    @Test("Test function keyboard layout setting")
    func testFunctionKeyboardLayout() {
        #expect(Preferences.functionKeyboardLayout == "com.apple.keylayout.US")
        Preferences.functionKeyboardLayout = "com.apple.keylayout.ABC"
        #expect(Preferences.functionKeyboardLayout == "com.apple.keylayout.ABC")
    }

    @Test("Test shift key override for function keyboard layout")
    func testFunctionKeyKeyboardLayoutOverrideIncludeShiftKey() {
        #expect(Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey == false)
        Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey = true
        #expect(Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey == true)
    }

    @Test("Test candidate text size constraints and changes")
    func testCandidateTextSize() {
        #expect(Preferences.candidateListTextSize == 16)

        Preferences.candidateListTextSize = 18
        #expect(Preferences.candidateListTextSize == 18)

        Preferences.candidateListTextSize = 11
        #expect(Preferences.candidateListTextSize == 12)
        Preferences.candidateListTextSize = 197
        #expect(Preferences.candidateListTextSize == 196)

        Preferences.candidateListTextSize = 12
        #expect(Preferences.candidateListTextSize == 12)
        Preferences.candidateListTextSize = 196
        #expect(Preferences.candidateListTextSize == 196)

        Preferences.candidateListTextSize = 13
        #expect(Preferences.candidateListTextSize == 13)
        Preferences.candidateListTextSize = 195
        #expect(Preferences.candidateListTextSize == 195)
    }

    @Test("Test phrase selection after cursor as candidate")
    func testSelectPhraseAfterCursorAsCandidate() {
        #expect(Preferences.selectPhraseAfterCursorAsCandidate == false)
        Preferences.selectPhraseAfterCursorAsCandidate = true
        #expect(Preferences.selectPhraseAfterCursorAsCandidate == true)
    }

    @Test("Test horizontal candidate list preference")
    func testUseHorizontalCandidateList() {
        #expect(Preferences.useHorizontalCandidateList == false)
        Preferences.useHorizontalCandidateList = true
        #expect(Preferences.useHorizontalCandidateList == true)
    }

    @Test("Test space key candidate selection")
    func testChooseCandidateUsingSpace() {
        #expect(Preferences.chooseCandidateUsingSpace == true)
        Preferences.chooseCandidateUsingSpace = false
        #expect(Preferences.chooseCandidateUsingSpace == false)
    }

    @Test("Test Chinese conversion toggle")
    func testChineseConversionEnabled() {
        #expect(Preferences.chineseConversionEnabled == false)
        Preferences.chineseConversionEnabled = true
        #expect(Preferences.chineseConversionEnabled == true)
        _ = Preferences.toggleChineseConversionEnabled()
        #expect(Preferences.chineseConversionEnabled == false)
    }

    @Test("Test half-width punctuation toggle")
    func testHalfWidthPunctuationEnabled() {
        #expect(Preferences.halfWidthPunctuationEnabled == false)
        Preferences.halfWidthPunctuationEnabled = true
        #expect(Preferences.halfWidthPunctuationEnabled == true)
        _ = Preferences.toggleHalfWidthPunctuationEnabled()
        #expect(Preferences.halfWidthPunctuationEnabled == false)
    }

    @Test("Test ESC key clearing input buffer")
    func testEscToCleanInputBuffer() {
        #expect(Preferences.escToCleanInputBuffer == false)
        Preferences.escToCleanInputBuffer = true
        #expect(Preferences.escToCleanInputBuffer == true)
    }

    @Test("Test candidate text font name setting")
    func testCandidateTextFontName() {
        #expect(Preferences.candidateTextFontName == nil)
        Preferences.candidateTextFontName = "Helvetica"
        #expect(Preferences.candidateTextFontName == "Helvetica")
    }

    @Test("Test candidate key label font name setting")
    func testCandidateKeyLabelFontName() {
        #expect(Preferences.candidateKeyLabelFontName == nil)
        Preferences.candidateKeyLabelFontName = "Helvetica"
        #expect(Preferences.candidateKeyLabelFontName == "Helvetica")
    }

    @Test("Test candidate keys configuration")
    func testCandidateKeys() {
        #expect(Preferences.candidateKeys == Preferences.defaultCandidateKeys)
        Preferences.candidateKeys = "abcd"
        #expect(Preferences.candidateKeys == "abcd")
    }

    @Test("Test phrase replacement toggle")
    func testPhraseReplacementEnabledKey() {
        #expect(Preferences.phraseReplacementEnabled == false)
        Preferences.phraseReplacementEnabled = true
        #expect(Preferences.phraseReplacementEnabled == true)
    }

    @Test("Test Chinese conversion style setting")
    func testChineseConversionStyle() {
        #expect(Preferences.chineseConversionStyle == .output)
        Preferences.chineseConversionStyle = .model
        #expect(Preferences.chineseConversionStyle == .model)
    }

}

final class CandidateKeyValidationTests {
    @Test("Test empty candidate keys validation")
    func testEmpty() {
        do {
            try Preferences.validate(candidateKeys: "")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.empty) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test spaces in candidate keys validation")
    func testSpaces() {
        do {
            try Preferences.validate(candidateKeys: "    ")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.empty) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test invalid characters in candidate keys")
    func testInvalidKeys() {
        do {
            try Preferences.validate(candidateKeys: "中文字元")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.invalidCharacters) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test invalid Latin letters in candidate keys")
    func testInvalidLatinLetters() {
        do {
            try Preferences.validate(candidateKeys: "üåçøöacpo")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.invalidCharacters) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test spaces between candidate keys")
    func testSpaceInBetween() {
        do {
            try Preferences.validate(candidateKeys: "1 2 3 4")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.containSpace) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test duplicated candidate keys")
    func testDuplicatedKeys() {
        do {
            try Preferences.validate(candidateKeys: "aabbccdd")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.duplicatedCharacters) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test too short candidate keys string")
    func testTooShort1() {
        do {
            try Preferences.validate(candidateKeys: "abc")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.tooShort) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test minimum length candidate keys string")
    func testTooShort2() {
        do {
            try Preferences.validate(candidateKeys: "abcd")
        } catch {
            Issue.record("Should be safe")
        }
    }

    @Test("Test too long candidate keys string")
    func testTooLong1() {
        do {
            try Preferences.validate(candidateKeys: "qwertyuiopasdfgh")
            Issue.record("exception not thrown")
        } catch (Preferences.CandidateKeyError.tooLong) {
        } catch {
            Issue.record("exception not thrown")
        }
    }

    @Test("Test maximum length candidate keys string")
    func testTooLong2() {
        do {
            try Preferences.validate(candidateKeys: "qwertyuiopasdfg")
        } catch {
            Issue.record("Should be safe")
        }
    }
}
