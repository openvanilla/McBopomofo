import XCTest
@testable import McBopomofo

class PreferencesTests: XCTestCase {

    override func setUpWithError() throws {
        Preferences.reset()
    }

    override func tearDownWithError() throws {
        Preferences.reset()
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
        Preferences.composingBufferSize = 21
        XCTAssert(Preferences.composingBufferSize == 20)
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

    func testChineneConversionEngine() {
        XCTAssert(Preferences.chineneConversionEngine == 0)
        Preferences.chineneConversionEngine = 1
        XCTAssert(Preferences.chineneConversionEngine == 1)
    }

    func testChineseConversionStyle() {
        XCTAssert(Preferences.chineseConversionStyle == 0)
        Preferences.chineseConversionStyle = 1
        XCTAssert(Preferences.chineseConversionStyle == 1)
    }

}
