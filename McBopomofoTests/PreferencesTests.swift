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

import XCTest
@testable import McBopomofo

class PreferencesTests: XCTestCase {

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

    func restore(from snapshot:[String: Any]) {
        Preferences.allKeys.forEach {
            UserDefaults.standard.set(snapshot[$0], forKey: $0)
        }
    }

    var snapshot: [String: Any]?

    override func setUpWithError() throws {
        snapshot = makeSnapshot()
        reset()
    }

    override func tearDownWithError() throws {
        if let snapshot = snapshot {
            restore(from: snapshot)
        }
    }

    func testKeyboardLayout() {
        XCTAssert(Preferences.keyboardLayout == 0)
        Preferences.keyboardLayout = 1
        XCTAssert(Preferences.keyboardLayout == 1)
    }

    func testKeyboardLayoutName() {
        XCTAssert(Preferences.keyboardLayoutName == "Standard")
        Preferences.keyboardLayout = 1
        XCTAssert(Preferences.keyboardLayoutName == "ETen")
    }

    func testBasisKeyboardLayoutPreferenceKey() {
        XCTAssert(Preferences.basisKeyboardLayout == "com.apple.keylayout.US")
        Preferences.basisKeyboardLayout = "com.apple.keylayout.ABC"
        XCTAssert(Preferences.basisKeyboardLayout == "com.apple.keylayout.ABC")
    }

    func testFunctionKeyboardLayout() {
        XCTAssert(Preferences.functionKeyboardLayout == "com.apple.keylayout.US")
        Preferences.functionKeyboardLayout = "com.apple.keylayout.ABC"
        XCTAssert(Preferences.functionKeyboardLayout == "com.apple.keylayout.ABC")
    }

    func testFunctionKeyKeyboardLayoutOverrideIncludeShiftKey() {
        XCTAssert(Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey == false)
        Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey = true
        XCTAssert(Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey == true)
    }

    func testCandidateTextSize() {
        XCTAssert(Preferences.candidateListTextSize == 16)

        Preferences.candidateListTextSize = 18
        XCTAssert(Preferences.candidateListTextSize == 18)

        Preferences.candidateListTextSize = 11
        XCTAssert(Preferences.candidateListTextSize == 12)
        Preferences.candidateListTextSize = 197
        XCTAssert(Preferences.candidateListTextSize == 196)

        Preferences.candidateListTextSize = 12
        XCTAssert(Preferences.candidateListTextSize == 12)
        Preferences.candidateListTextSize = 196
        XCTAssert(Preferences.candidateListTextSize == 196)

        Preferences.candidateListTextSize = 13
        XCTAssert(Preferences.candidateListTextSize == 13)
        Preferences.candidateListTextSize = 195
        XCTAssert(Preferences.candidateListTextSize == 195)
    }

    func testSelectPhraseAfterCursorAsCandidate() {
        XCTAssert(Preferences.selectPhraseAfterCursorAsCandidate == false)
        Preferences.selectPhraseAfterCursorAsCandidate = true
        XCTAssert(Preferences.selectPhraseAfterCursorAsCandidate == true)
    }

    func testUseHorizontalCandidateList() {
        XCTAssert(Preferences.useHorizontalCandidateList == false)
        Preferences.useHorizontalCandidateList = true
        XCTAssert(Preferences.useHorizontalCandidateList == true)
    }

    func testComposingBufferSize() {
        XCTAssert(Preferences.composingBufferSize == 10)
        Preferences.composingBufferSize = 4
        XCTAssert(Preferences.composingBufferSize == 4)
        Preferences.composingBufferSize = 20
        XCTAssert(Preferences.composingBufferSize == 20)
        Preferences.composingBufferSize = 3
        XCTAssert(Preferences.composingBufferSize == 4)
        Preferences.composingBufferSize = 101
        XCTAssert(Preferences.composingBufferSize == 100)
        Preferences.composingBufferSize = 5
        XCTAssert(Preferences.composingBufferSize == 5)
        Preferences.composingBufferSize = 19
        XCTAssert(Preferences.composingBufferSize == 19)
    }

    func testChooseCandidateUsingSpace() {
        XCTAssert(Preferences.chooseCandidateUsingSpace == true)
        Preferences.chooseCandidateUsingSpace = false
        XCTAssert(Preferences.chooseCandidateUsingSpace == false)
    }

    func testChineseConversionEnabled() {
        XCTAssert(Preferences.chineseConversionEnabled == false)
        Preferences.chineseConversionEnabled = true
        XCTAssert(Preferences.chineseConversionEnabled == true)
        _ = Preferences.toggleChineseConversionEnabled()
        XCTAssert(Preferences.chineseConversionEnabled == false)
    }

    func testHalfWidthPunctuationEnabled() {
        XCTAssert(Preferences.halfWidthPunctuationEnabled == false)
        Preferences.halfWidthPunctuationEnabled = true
        XCTAssert(Preferences.halfWidthPunctuationEnabled == true)
        _ = Preferences.toggleHalfWidthPunctuationEnabled()
        XCTAssert(Preferences.halfWidthPunctuationEnabled == false)
    }

    func testEscToCleanInputBuffer() {
        XCTAssert(Preferences.escToCleanInputBuffer == false)
        Preferences.escToCleanInputBuffer = true
        XCTAssert(Preferences.escToCleanInputBuffer == true)
    }

    func testCandidateTextFontName() {
        XCTAssert(Preferences.candidateTextFontName == nil)
        Preferences.candidateTextFontName = "Helvetica"
        XCTAssert(Preferences.candidateTextFontName == "Helvetica")
    }

    func testCandidateKeyLabelFontName() {
        XCTAssert(Preferences.candidateKeyLabelFontName == nil)
        Preferences.candidateKeyLabelFontName = "Helvetica"
        XCTAssert(Preferences.candidateKeyLabelFontName == "Helvetica")
    }

    func testCandidateKeys() {
        XCTAssert(Preferences.candidateKeys == Preferences.defaultCandidateKeys)
        Preferences.candidateKeys = "abcd"
        XCTAssert(Preferences.candidateKeys == "abcd")
    }

    func testPhraseReplacementEnabledKey() {
        XCTAssert(Preferences.phraseReplacementEnabled == false)
        Preferences.phraseReplacementEnabled = true
        XCTAssert(Preferences.phraseReplacementEnabled == true)
    }

    func testChineseConversionEngine() {
        XCTAssert(Preferences.chineseConversionEngine == 0)
        Preferences.chineseConversionEngine = 1
        XCTAssert(Preferences.chineseConversionEngine == 1)
    }

    func testChineseConversionStyle() {
        XCTAssert(Preferences.chineseConversionStyle == 0)
        Preferences.chineseConversionStyle = 1
        XCTAssert(Preferences.chineseConversionStyle == 1)
    }

}

class CandidateKeyValidationTests: XCTestCase {
    func testEmpty() {
        do {
            try Preferences.validate(candidateKeys: "")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.empty)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testSpaces() {
        do {
            try Preferences.validate(candidateKeys: "    ")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.empty)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testInvalidKeys() {
        do {
            try Preferences.validate(candidateKeys: "中文字元")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.invalidCharacters)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testInvalidLatinLetters() {
        do {
            try Preferences.validate(candidateKeys: "üåçøöacpo")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.invalidCharacters)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testSpaceInBetween() {
        do {
            try Preferences.validate(candidateKeys: "1 2 3 4")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.containSpace)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testDuplicatedKeys() {
        do {
            try Preferences.validate(candidateKeys: "aabbccdd")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.duplicatedCharacters)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testTooShort1() {
        do {
            try Preferences.validate(candidateKeys: "abc")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.tooShort)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testTooShort2() {
        do {
            try Preferences.validate(candidateKeys: "abcd")
        } catch {
            XCTFail("Should be safe")
        }
    }

    func testTooLong1() {
        do {
            try Preferences.validate(candidateKeys: "qwertyuiopasdfgh")
            XCTFail("exception not thrown")
        } catch(Preferences.CandidateKeyError.tooLong)  {
        } catch {
            XCTFail("exception not thrown")
        }
    }

    func testTooLong2() {
        do {
            try Preferences.validate(candidateKeys: "qwertyuiopasdfg")
        }
        catch {
            XCTFail("Should be safe")
        }
    }
}
