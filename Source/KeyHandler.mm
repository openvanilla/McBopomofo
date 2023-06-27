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

#import "KeyHandler.h"
#import "LanguageModelManager+Privates.h"
#import "Mandarin.h"
#import "McBopomofo-Swift.h"
#import "McBopomofoLM.h"
#import "UTF8Helper.h"
#import "UserOverrideModel.h"
#import "reading_grid.h"

#import <string>
#import <unordered_map>
#import <utility>

@import CandidateUI;
@import NSStringUtils;

InputMode InputModeBopomofo = @"org.openvanilla.inputmethod.McBopomofo.Bopomofo";
InputMode InputModePlainBopomofo = @"org.openvanilla.inputmethod.McBopomofo.PlainBopomofo";

@implementation KeyHandler {
    std::shared_ptr<Formosa::Gramambular2::LanguageModel> _emptySharedPtr;

    // the reading buffer that takes user input
    Formosa::Mandarin::BopomofoReadingBuffer *_bpmfReadingBuffer;

    // language model
    McBopomofo::McBopomofoLM *_languageModel;

    // user override model
    McBopomofo::UserOverrideModel *_userOverrideModel;

    Formosa::Gramambular2::ReadingGrid *_grid;
    Formosa::Gramambular2::ReadingGrid::WalkResult _latestWalk;

    NSString *_inputMode;
}

//@synthesize inputMode = _inputMode;
@synthesize delegate = _delegate;

- (NSString *)inputMode
{
    return _inputMode;
}

- (void)setInputMode:(NSString *)value
{
    NSString *newInputMode;
    McBopomofo::McBopomofoLM *newLanguageModel;

    if ([value isKindOfClass:[NSString class]] && [value isEqual:InputModePlainBopomofo]) {
        newInputMode = InputModePlainBopomofo;
        newLanguageModel = [LanguageModelManager languageModelPlainBopomofo];
        newLanguageModel->setPhraseReplacementEnabled(false);
    } else {
        newInputMode = InputModeBopomofo;
        newLanguageModel = [LanguageModelManager languageModelMcBopomofo];
        newLanguageModel->setPhraseReplacementEnabled(Preferences.phraseReplacementEnabled);
    }
    newLanguageModel->setExternalConverterEnabled(Preferences.chineseConversionStyle == 1);

    // Only apply the changes if the value is changed
    if (![_inputMode isEqualToString:newInputMode]) {
        _inputMode = newInputMode;
        _languageModel = newLanguageModel;

        if (_grid == nullptr) {
            NSLog(@"used after release????");
        }

        if (_grid != nullptr) {
            delete _grid;
            // This returns a shared_ptr that in turn points to an unmanaged object.
            std::shared_ptr<Formosa::Gramambular2::LanguageModel> lm(_emptySharedPtr, _languageModel);
            _grid = new Formosa::Gramambular2::ReadingGrid(lm);
            _grid->setReadingSeparator("-");
        }

        if (!_bpmfReadingBuffer->isEmpty()) {
            _bpmfReadingBuffer->clear();
        }
    }
}

- (void)dealloc
{
    delete _bpmfReadingBuffer;
    delete _grid;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bpmfReadingBuffer = new Formosa::Mandarin::BopomofoReadingBuffer(Formosa::Mandarin::BopomofoKeyboardLayout::StandardLayout());

        // create the lattice builder
        _languageModel = [LanguageModelManager languageModelMcBopomofo];
        _languageModel->setPhraseReplacementEnabled(Preferences.phraseReplacementEnabled);
        _userOverrideModel = [LanguageModelManager userOverrideModel];

        // This returns a shared_ptr that in turn points to an unmanaged object.
        std::shared_ptr<Formosa::Gramambular2::LanguageModel> lm(_emptySharedPtr, _languageModel);
        _grid = new Formosa::Gramambular2::ReadingGrid(lm);
        _grid->setReadingSeparator("-");

        _inputMode = InputModeBopomofo;
    }
    return self;
}

- (void)syncWithPreferences
{
    NSInteger layout = Preferences.keyboardLayout;
    switch (layout) {
    case KeyboardLayoutStandard:
        _bpmfReadingBuffer->setKeyboardLayout(Formosa::Mandarin::BopomofoKeyboardLayout::StandardLayout());
        break;
    case KeyboardLayoutEten:
        _bpmfReadingBuffer->setKeyboardLayout(Formosa::Mandarin::BopomofoKeyboardLayout::ETenLayout());
        break;
    case KeyboardLayoutHsu:
        _bpmfReadingBuffer->setKeyboardLayout(Formosa::Mandarin::BopomofoKeyboardLayout::HsuLayout());
        break;
    case KeyboardLayoutEten26:
        _bpmfReadingBuffer->setKeyboardLayout(Formosa::Mandarin::BopomofoKeyboardLayout::ETen26Layout());
        break;
    case KeyboardLayoutHanyuPinyin:
        _bpmfReadingBuffer->setKeyboardLayout(Formosa::Mandarin::BopomofoKeyboardLayout::HanyuPinyinLayout());
        break;
    case KeyboardLayoutIBM:
        _bpmfReadingBuffer->setKeyboardLayout(Formosa::Mandarin::BopomofoKeyboardLayout::IBMLayout());
        break;
    default:
        _bpmfReadingBuffer->setKeyboardLayout(Formosa::Mandarin::BopomofoKeyboardLayout::StandardLayout());
        Preferences.keyboardLayout = KeyboardLayoutStandard;
    }
    _languageModel->setExternalConverterEnabled(Preferences.chineseConversionStyle == 1);
}

- (void)fixNodeWithReading:(NSString *)reading value:(NSString *)value useMoveCursorAfterSelectionSetting:(BOOL)flag
{
    size_t actualCursor = [self _actualCandidateCursorIndex];
    Formosa::Gramambular2::ReadingGrid::Candidate candidate(reading.UTF8String, value.UTF8String);
    if (!_grid->overrideCandidate(actualCursor, candidate)) {
        return;
    }

    Formosa::Gramambular2::ReadingGrid::WalkResult prevWalk = _latestWalk;
    [self _walk];

    // Update the user override model if warranted.
    size_t accumulatedCursor = 0;
    auto nodeIter = _latestWalk.findNodeAt([self _actualCandidateCursorIndex], &accumulatedCursor);
    if (nodeIter == _latestWalk.nodes.cend()) {
        return;
    }
    Formosa::Gramambular2::ReadingGrid::NodePtr currentNode = *nodeIter;
    if (currentNode != nullptr && currentNode->currentUnigram().score() > -8) {
        _userOverrideModel->observe(prevWalk, _latestWalk, [self _actualCandidateCursorIndex], [[NSDate date] timeIntervalSince1970]);
    }

    if (currentNode != nullptr && flag && Preferences.moveCursorAfterSelectingCandidate) {
        _grid->setCursor(accumulatedCursor);
    }
}

- (void)clear
{
    _bpmfReadingBuffer->clear();
    _grid->clear();
    _latestWalk = Formosa::Gramambular2::ReadingGrid::WalkResult {};
}

- (void)handleForceCommitWithStateCallback:(void (^)(InputState *))stateCallback
{
    if (_bpmfReadingBuffer->isEmpty() && _grid->length() == 0) {
        // No-op if both are empty.
        return;
    }

    // Upon force-commit, clear the BPMF reading, then "steal" the composing buffer text from the built inputting state.
    _bpmfReadingBuffer->clear();
    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
    [self clear];

    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:inputting.composingBuffer];
    stateCallback(committing);
}

- (std::string)_currentLayout
{
    NSString *keyboardLayoutName = Preferences.keyboardLayoutName;
    std::string layout = std::string(keyboardLayoutName.UTF8String) + "_";
    return layout;
}

- (BOOL)handleInput:(KeyHandlerInput *)input state:(InputState *)inState stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    InputState *state = inState;
    UniChar charCode = input.charCode;
    McBopomofoEmacsKey emacsKey = input.emacsKey;

    // MARK: Handle Big5 Input
    if ([state isKindOfClass:[InputStateBig5 class]]) {
        return [self _handleBig5State:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // if the inputText is empty, it's a function key combination, we ignore it
    if (!input.inputText.length) {
        return NO;
    }

    // if the composing buffer is empty and there's no reading, and there is some function key combination, we ignore it
    BOOL isFunctionKey = ([input isCommandHold] || [input isOptionHold] || [input isNumericPad]) || [input isControlHotKey];
    if (![state isKindOfClass:[InputStateNotEmpty class]] && ![state isKindOfClass:[InputStateAssociatedPhrases class]] && isFunctionKey) {
        return NO;
    }

    // Caps Lock processing : if Caps Lock is on, temporarily disable bopomofo.
    if (charCode == 8 || charCode == 13 || [input isAbsorbedArrowKey] || [input isExtraChooseCandidateKey] || [input isCursorForward] || [input isCursorBackward]) {
        // do nothing if backspace is pressed -- we ignore the key
    } else if ([input isCapsLockOn]) {
        // process all possible combination, we hope.
        [self clear];
        InputStateEmpty *emptyState = [[InputStateEmpty alloc] init];
        stateCallback(emptyState);

        // first commit everything in the buffer.
        if ([input isShiftHold]) {
            return NO;
        }

        // if ASCII but not printable, don't use insertText:replacementRange: as many apps don't handle non-ASCII char insertions.
        if (charCode < 0x80 && !isprint(charCode)) {
            return NO;
        }

        // when shift is pressed, don't do further processing, since it outputs capital letter anyway.
        InputStateCommitting *committingState = [[InputStateCommitting alloc] initWithPoppedText:[input.inputText lowercaseString]];
        stateCallback(committingState);
        stateCallback(emptyState);
        return YES;
    }

    if ([input isNumericPad]) {
        if (![input isLeft] && ![input isRight] && ![input isDown] && ![input isUp] && charCode != 32 && isprint(charCode)) {
            [self clear];
            InputStateEmpty *emptyState = [[InputStateEmpty alloc] init];
            stateCallback(emptyState);
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:[input.inputText lowercaseString]];
            stateCallback(committing);
            stateCallback(emptyState);
            return YES;
        }
    }

    // MARK: Handle Candidates
    if ([state isKindOfClass:[InputStateChoosingCandidate class]]) {
        return [self _handleCandidateState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Handle Associated Phrases
    if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        BOOL result = [self _handleCandidateState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
        if (result) {
            return YES;
        }
        state = [[InputStateEmpty alloc] init];
        stateCallback(state);
    }

    // MARK: Handle Marking
    if ([state isKindOfClass:[InputStateMarking class]]) {
        InputStateMarking *marking = (InputStateMarking *)state;
        if ([self _handleMarkingState:(InputStateMarking *)state input:input stateCallback:stateCallback errorCallback:errorCallback]) {
            return YES;
        }
        state = [marking convertToInputting];
        stateCallback(state);
    }

    BOOL keyConsumedByReading = NO;
    BOOL skipBpmfHandling = [input isReservedKey] || [input isControlHold];

    // MARK: Handle BPMF Keys

    // see if it's valid BPMF reading
    if (!skipBpmfHandling && _bpmfReadingBuffer->isValidKey((char)charCode)) {
        _bpmfReadingBuffer->combineKey((char)charCode);
        keyConsumedByReading = YES;

        // if we have a tone marker, we have to insert the reading to the
        // builder in other words, if we don't have a tone marker, we just
        // update the composing buffer
        if (!_bpmfReadingBuffer->hasToneMarker()) {
            stateCallback([self buildInputtingState]);
            return YES;
        }
    }

    BOOL composeReading = _bpmfReadingBuffer->isValidKey((char)charCode) && _bpmfReadingBuffer->hasToneMarker() && !_bpmfReadingBuffer->hasToneMarkerOnly();

    // see if we have composition if Enter/Space is hit and buffer is not empty
    // this is bit-OR'ed so that the tone marker key is also taken into account
    composeReading |= (!_bpmfReadingBuffer->isEmpty() && (charCode == 32 || charCode == 13));
    if (composeReading) {
        // combine the reading
        std::string reading = _bpmfReadingBuffer->syllable().composedString();

        // see if we have a unigram for this
        if (!_languageModel->hasUnigrams(reading)) {
            errorCallback();

            if (Preferences.keepReadingUponCompositionError) {
                stateCallback([self buildInputtingState]);
                return YES;
            }

            _bpmfReadingBuffer->clear();
            if (!_grid->length()) {
                stateCallback([[InputStateEmptyIgnoringPreviousState alloc] init]);
            } else {
                stateCallback([self buildInputtingState]);
            }
            return YES;
        }

        _grid->insertReading(reading);
        [self _walk];

        // get user override model suggestion
        if (_inputMode != InputModePlainBopomofo) {
            McBopomofo::UserOverrideModel::Suggestion suggestion = _userOverrideModel->suggest(_latestWalk, [self _actualCandidateCursorIndex], [[NSDate date] timeIntervalSince1970]);
            if (!suggestion.empty()) {
                Formosa::Gramambular2::ReadingGrid::Node::OverrideType type = suggestion.forceHighScoreOverride ? Formosa::Gramambular2::ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore : Formosa::Gramambular2::ReadingGrid::Node::OverrideType::kOverrideValueWithScoreFromTopUnigram;
                _grid->overrideCandidate([self _actualCandidateCursorIndex], suggestion.candidate, type);
                [self _walk];
            }
        }

        // then update the text
        _bpmfReadingBuffer->clear();

        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        stateCallback(inputting);

        if (_inputMode == InputModePlainBopomofo) {
            InputStateChoosingCandidate *choosingCandidates = [self _buildCandidateState:inputting useVerticalMode:input.useVerticalMode];
            if (choosingCandidates.candidates.count == 1) {
                [self clear];
                NSString *text = choosingCandidates.candidates.firstObject.value;
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:text];
                stateCallback(committing);

                if (!Preferences.associatedPhrasesEnabled) {
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    stateCallback(empty);
                } else {
                    InputStateAssociatedPhrases *associatedPhrases = (InputStateAssociatedPhrases *)[self buildAssociatePhraseStateWithKey:text useVerticalMode:input.useVerticalMode];
                    if (associatedPhrases) {
                        stateCallback(associatedPhrases);
                    } else {
                        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                        stateCallback(empty);
                    }
                }
            } else {
                stateCallback(choosingCandidates);
            }
        }

        // and tells the client that the key is consumed
        return YES;
    }

    // Indicates that the Bopomofo reading is not-empty but also not composed.
    // The only possibility for this to be true is that when the reading only
    // contains tone markers.
    if (keyConsumedByReading) {
        stateCallback([self buildInputtingState]);
        return true;
    }

    // MARK: Space and Down
    // keyCode 125 = Down, charCode 32 = Space
    if (_bpmfReadingBuffer->isEmpty() &&
        [state isKindOfClass:[InputStateNotEmpty class]] && ([input isExtraChooseCandidateKey] || charCode == 32 || (input.useVerticalMode && ([input isVerticalModeOnlyChooseCandidateKey])))) {
        if (charCode == 32) {
            // if the spacebar is NOT set to be a selection key
            if ([input isShiftHold] || !Preferences.chooseCandidateUsingSpace) {
                if (_grid->cursor() >= _grid->length()) {
                    NSString *composingBuffer = [(InputStateNotEmpty *)state composingBuffer];
                    if (composingBuffer.length) {
                        InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
                        stateCallback(committing);
                    }
                    [self clear];
                    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:@" "];
                    stateCallback(committing);
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    stateCallback(empty);
                } else if (_languageModel->hasUnigrams(" ")) {
                    _grid->insertReading(" ");
                    [self _walk];
                    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
                    stateCallback(inputting);
                }
                return YES;
            }
        }
        InputStateChoosingCandidate *choosingCandidates = [self _buildCandidateState:(InputStateNotEmpty *)state useVerticalMode:input.useVerticalMode];
        stateCallback(choosingCandidates);
        return YES;
    }

    // MARK: Esc
    if (charCode == 27) {
        return [self _handleEscWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Tab
    if ([input isTab]) {
        return [self _handleTabState:state shiftIsHold:[input isShiftHold] stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Cursor backward
    if ([input isCursorBackward] || emacsKey == McBopomofoEmacsKeyBackward) {
        return [self _handleBackwardWithState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK:  Cursor forward
    if ([input isCursorForward] || emacsKey == McBopomofoEmacsKeyForward) {
        return [self _handleForwardWithState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Home
    if ([input isHome] || emacsKey == McBopomofoEmacsKeyHome) {
        return [self _handleHomeWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: End
    if ([input isEnd] || emacsKey == McBopomofoEmacsKeyEnd) {
        return [self _handleEndWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: AbsorbedArrowKey
    if ([input isAbsorbedArrowKey] || [input isExtraChooseCandidateKey]) {
        return [self _handleAbsorbedArrowKeyWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Backspace
    if (charCode == 8) {
        return [self _handleBackspaceWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Delete
    if ([input isDelete] || emacsKey == McBopomofoEmacsKeyDelete) {
        return [self _handleDeleteWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Enter
    if (charCode == 13) {
        if ([input isControlHold] && Preferences.controlEnterOutput != 0) {
            return [self _handleCtrlEnterWithState:state stateCallback:stateCallback errorCallback:errorCallback];
        }
        return [self _handleEnterWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Enter Big5 code mode
    if ([input isControlHold] && (charCode == '`')) {
        [self clear];
        if ([state isKindOfClass:[InputStateInputting class]]) {
            InputStateInputting *current = (InputStateInputting *)state;
            NSString *composingBuffer = current.composingBuffer;
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
            stateCallback(committing);
        }
        InputStateBig5 *big5 = [[InputStateBig5 alloc] initWithCode:@""];
        stateCallback(big5);
        return YES;
    }

    // MARK: Punctuation list
    if ((char)charCode == '`') {
        if (_languageModel->hasUnigrams("_punctuation_list")) {
            if (_bpmfReadingBuffer->isEmpty()) {
                _grid->insertReading("_punctuation_list");
                [self _walk];
                InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
                stateCallback(inputting);
                InputStateChoosingCandidate *choosingCandidate = [self _buildCandidateState:inputting useVerticalMode:input.useVerticalMode];
                stateCallback(choosingCandidate);
            } else { // If there is still unfinished bpmf reading, ignore the punctuation
                errorCallback();
            }
            return YES;
        }
    }

    // MARK: Punctuation
    // if nothing is matched, see if it's a punctuation key for current layout.

    std::string punctuationNamePrefix;
    if ([input isControlHold]) {
        punctuationNamePrefix = "_ctrl_punctuation_";
    } else if (Preferences.halfWidthPunctuationEnabled) {
        punctuationNamePrefix = "_half_punctuation_";
    } else {
        punctuationNamePrefix = "_punctuation_";
    }
    std::string layout = [self _currentLayout];
    std::string customPunctuation = punctuationNamePrefix + layout + std::string(1, (char)charCode);
    if ([self _handlePunctuation:customPunctuation state:state usingVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback]) {
        return YES;
    }

    // if nothing is matched, see if it's a punctuation key.
    std::string punctuation = punctuationNamePrefix + std::string(1, (char)charCode);
    if ([self _handlePunctuation:punctuation state:state usingVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback]) {
        return YES;
    }

    if ((char)charCode >= 'A' && (char)charCode <= 'Z') {
        if (Preferences.letterBehavior == 1) {
            std::string letter = std::string("_letter_") + std::string(1, (char)charCode);
            if ([self _handlePunctuation:letter state:state usingVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback]) {
                return YES;
            }
        } else {
            if ([state isKindOfClass:[InputStateNotEmpty class]]) {
                [self clear];
                InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                stateCallback(empty);
                state = empty;
            }
        }
    }

    // still nothing, then we update the composing buffer (some app has
    // strange behavior if we don't do this, "thinking" the key is not
    // actually consumed)
    if ([state isKindOfClass:[InputStateNotEmpty class]] || !_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    return NO;
}

- (BOOL)_handleTabState:(InputState *)state shiftIsHold:(BOOL)shiftIsHold stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (!_grid->length()) {
        return NO;
    }

    if (![state isKindOfClass:[InputStateInputting class]]) {
        errorCallback();
        return YES;
    }

    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        return YES;
    }

    NSArray *candidates = [[self _buildCandidateState:(InputStateInputting *)state useVerticalMode:NO] candidates];
    if (candidates.count == 0) {
        errorCallback();
        return YES;
    }

    auto nodeIter = _latestWalk.findNodeAt([self _actualCandidateCursorIndex]);
    if (nodeIter == _latestWalk.nodes.cend()) {
        // Shouldn't happen.
        errorCallback();
        return true;
    }
    Formosa::Gramambular2::ReadingGrid::NodePtr currentNode = *nodeIter;

    size_t currentIndex = 0;
    if (!currentNode->isOverridden()) {
        // If the user never selects a candidate for the node, we start from the
        // first candidate, so the user has a chance to use the unigram with two or
        // more characters when type the tab key for the first time.
        //
        // In other words, if a user type two BPMF readings, but the score of seeing
        // them as two unigrams is higher than a phrase with two characters, the
        // user can just use the longer phrase by typing the tab key.
        InputStateCandidate *candidate = candidates[0];
        if (currentNode->reading() == candidate.reading.UTF8String && currentNode->value() == candidate.value.UTF8String) {
            // If the first candidate is the value of the current node, we use next
            // one.
            if (shiftIsHold) {
                currentIndex = [candidates count] - 1;
            } else {
                currentIndex = 1;
            }
        }
    } else {
        for (InputStateCandidate *candidate : candidates) {
            if (currentNode->reading() == candidate.reading.UTF8String && currentNode->value() == candidate.value.UTF8String) {
                if (shiftIsHold) {
                    currentIndex == 0 ? currentIndex = candidates.count - 1 : currentIndex--;
                } else {
                    currentIndex++;
                }
                break;
            }
            currentIndex++;
        }
    }

    if (currentIndex >= candidates.count) {
        currentIndex = 0;
    }

    InputStateCandidate *candidate = candidates[currentIndex];
    [self fixNodeWithReading:candidate.reading value:candidate.value useMoveCursorAfterSelectionSetting:NO];
    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
    stateCallback(inputting);
    return YES;
}

- (BOOL)_handleEscWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    BOOL escToClearInputBufferEnabled = Preferences.escToCleanInputBuffer;

    if (escToClearInputBufferEnabled) {
        // if the option is enabled, we clear everything including the composing
        // buffer, walked nodes and the reading.
        [self clear];
        InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
        stateCallback(empty);
    } else {
        // if reading is not empty, we cancel the reading; Apple's built-in
        // Zhuyin (and the erstwhile Hanin) has a default option that Esc
        // "cancels" the current composed character and revert it to
        // Bopomofo reading, in odds with the expectation of users from
        // other platforms

        if (!_bpmfReadingBuffer->isEmpty()) {
            _bpmfReadingBuffer->clear();
            if (!_grid->length()) {
                InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
                stateCallback(empty);
            } else {
                InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
                stateCallback(inputting);
            }
        }
    }
    return YES;
}

- (BOOL)_handleBackwardWithState:(InputState *)state input:(KeyHandlerInput *)input stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    InputStateInputting *currentState = (InputStateInputting *)state;

    if ([input isShiftHold]) {
        // Shift + left
        if (currentState.cursorIndex > 0) {
            NSInteger previousPosition = [currentState.composingBuffer previousUtf16PositionFor:currentState.cursorIndex];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex markerIndex:previousPosition readings:[self _currentReadings]];
            marking.tooltipForInputting = currentState.tooltip;
            stateCallback(marking);
        } else {
            errorCallback();
            stateCallback(state);
        }
    } else {
        if (_grid->cursor() > 0) {
            _grid->setCursor(_grid->cursor() - 1);
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
        } else {
            errorCallback();
            stateCallback(state);
        }
    }
    return YES;
}

- (BOOL)_handleForwardWithState:(InputState *)state input:(KeyHandlerInput *)input stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    InputStateInputting *currentState = (InputStateInputting *)state;

    if ([input isShiftHold]) {
        // Shift + Right
        if (currentState.cursorIndex < currentState.composingBuffer.length) {
            NSInteger nextPosition = [currentState.composingBuffer nextUtf16PositionFor:currentState.cursorIndex];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex markerIndex:nextPosition readings:[self _currentReadings]];
            marking.tooltipForInputting = currentState.tooltip;
            stateCallback(marking);
        } else {
            errorCallback();
            stateCallback(state);
        }
    } else {
        if (_grid->cursor() < _grid->length()) {
            _grid->setCursor(_grid->cursor() + 1);
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
        } else {
            errorCallback();
            stateCallback(state);
        }
    }

    return YES;
}

- (BOOL)_handleHomeWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    if (_grid->cursor()) {
        _grid->setCursor(0);
        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        stateCallback(inputting);
    } else {
        errorCallback();
        stateCallback(state);
    }

    return YES;
}

- (BOOL)_handleEndWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    if (_grid->cursor() != _grid->length()) {
        _grid->setCursor(_grid->length());
        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        stateCallback(inputting);
    } else {
        errorCallback();
        stateCallback(state);
    }

    return YES;
}

- (BOOL)_handleAbsorbedArrowKeyWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
    }
    stateCallback(state);
    return YES;
}

- (BOOL)_handleBackspaceWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (_bpmfReadingBuffer->hasToneMarkerOnly()) {
        _bpmfReadingBuffer->clear();
    } else if (_bpmfReadingBuffer->isEmpty()) {
        if (_grid->cursor()) {
            _grid->deleteReadingBeforeCursor();
            [self _walk];
        } else {
            errorCallback();
            stateCallback(state);
            return YES;
        }
    } else {
        _bpmfReadingBuffer->backspace();
    }

    if (_bpmfReadingBuffer->isEmpty() && !_grid->length()) {
        InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
        stateCallback(empty);
    } else {
        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        stateCallback(inputting);
    }
    return YES;
}

- (BOOL)_handleDeleteWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (_bpmfReadingBuffer->isEmpty()) {
        if (_grid->cursor() != _grid->length()) {
            _grid->deleteReadingAfterCursor();
            [self _walk];
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            if (!inputting.composingBuffer.length) {
                InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
                stateCallback(empty);
            } else {
                stateCallback(inputting);
            }
        } else {
            errorCallback();
            stateCallback(state);
        }
    } else {
        errorCallback();
        stateCallback(state);
    }

    return YES;
}

- (BOOL)_handleCtrlEnterWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    NSArray *readings = [self _currentReadings];
    NSString *composingBuffer = [readings componentsJoinedByString:@"-"];

    [self clear];

    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
    stateCallback(committing);
    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
    stateCallback(empty);
    return YES;
}

- (BOOL)_handleEnterWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    [self clear];

    InputStateInputting *current = (InputStateInputting *)state;
    NSString *composingBuffer = current.composingBuffer;
    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
    stateCallback(committing);
    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
    stateCallback(empty);
    return YES;
}

- (BOOL)_handlePunctuation:(std::string)customPunctuation state:(InputState *)state usingVerticalMode:(BOOL)useVerticalMode stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (!_languageModel->hasUnigrams(customPunctuation)) {
        return NO;
    }

    if (_bpmfReadingBuffer->isEmpty()) {
        _grid->insertReading(customPunctuation);
        [self _walk];
    } else { // If there is still unfinished bpmf reading, ignore the punctuation
        errorCallback();
        stateCallback(state);
        return YES;
    }

    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
    stateCallback(inputting);

    if (_inputMode == InputModePlainBopomofo && _bpmfReadingBuffer->isEmpty()) {
        InputStateChoosingCandidate *candidateState = [self _buildCandidateState:inputting useVerticalMode:useVerticalMode];

        if ([candidateState.candidates count] == 1) {
            [self clear];
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:candidateState.candidates.firstObject.value];
            stateCallback(committing);
            InputStateEmpty *empty = [[InputStateEmpty alloc] init];
            stateCallback(empty);
        } else {
            stateCallback(candidateState);
        }
    }
    return YES;
}

- (BOOL)_handleMarkingState:(InputStateMarking *)state
                      input:(KeyHandlerInput *)input
              stateCallback:(void (^)(InputState *))stateCallback
              errorCallback:(void (^)(void))errorCallback
{
    UniChar charCode = input.charCode;

    if (charCode == 27) {
        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        stateCallback(inputting);
        return YES;
    }

    // Enter
    if (charCode == 13) {
        if (![self.delegate keyHandler:self didRequestWriteUserPhraseWithState:state]) {
            errorCallback();
            return YES;
        }
        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        stateCallback(inputting);
        return YES;
    }

    // Shift + left
    if (([input isCursorBackward] || input.emacsKey == McBopomofoEmacsKeyBackward)
        && ([input isShiftHold])) {
        NSUInteger index = state.markerIndex;
        if (index > 0) {
            index = [state.composingBuffer previousUtf16PositionFor:index];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:state.composingBuffer cursorIndex:state.cursorIndex markerIndex:index readings:state.readings];
            marking.tooltipForInputting = state.tooltipForInputting;

            if (marking.markedRange.length == 0) {
                InputState *inputting = [marking convertToInputting];
                stateCallback(inputting);
            } else {
                stateCallback(marking);
            }
        } else {
            errorCallback();
            stateCallback(state);
        }
        return YES;
    }

    // Shift + Right
    if (([input isCursorForward] || input.emacsKey == McBopomofoEmacsKeyForward)
        && ([input isShiftHold])) {
        NSUInteger index = state.markerIndex;
        if (index < state.composingBuffer.length) {
            index = [state.composingBuffer nextUtf16PositionFor:index];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:state.composingBuffer cursorIndex:state.cursorIndex markerIndex:index readings:state.readings];
            marking.tooltipForInputting = state.tooltipForInputting;
            if (marking.markedRange.length == 0) {
                InputState *inputting = [marking convertToInputting];
                stateCallback(inputting);
            } else {
                stateCallback(marking);
            }
        } else {
            errorCallback();
            stateCallback(state);
        }
        return YES;
    }
    return NO;
}

- (BOOL)_handleCandidateState:(InputState *)state
                        input:(KeyHandlerInput *)input
                stateCallback:(void (^)(InputState *))stateCallback
                errorCallback:(void (^)(void))errorCallback;
{
    NSString *inputText = input.inputText;
    UniChar charCode = input.charCode;
    VTCandidateController *gCurrentCandidateController = [self.delegate candidateControllerForKeyHandler:self];

    BOOL cancelCandidateKey = (charCode == 27) || (charCode == 8) || [input isDelete];

    if (cancelCandidateKey) {
        if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
        } else if (_inputMode == InputModePlainBopomofo) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
        } else {
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
        }
        return YES;
    }

    if (charCode == 13 || [input isEnter]) {
        if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
            return YES;
        }
        [self.delegate keyHandler:self didSelectCandidateAtIndex:gCurrentCandidateController.selectedCandidateIndex candidateController:gCurrentCandidateController];
        return YES;
    }

    if (charCode == 32 || [input isPageDown] || input.emacsKey == McBopomofoEmacsKeyNextPage) {
        BOOL updated = [gCurrentCandidateController showNextPage];
        if (!updated) {
            errorCallback();
        }
        return YES;
    }

    if ([input isPageUp]) {
        BOOL updated = [gCurrentCandidateController showPreviousPage];
        if (!updated) {
            errorCallback();
        }
        return YES;
    }

    if ([input isLeft]) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
            if (!updated) {
                errorCallback();
            }
        } else {
            BOOL updated = [gCurrentCandidateController showPreviousPage];
            if (!updated) {
                errorCallback();
            }
        }
        return YES;
    }

    if (input.emacsKey == McBopomofoEmacsKeyBackward) {
        BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
        if (!updated) {
            errorCallback();
        }
        return YES;
    }

    if ([input isRight]) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController highlightNextCandidate];
            if (!updated) {
                errorCallback();
            }
        } else {
            BOOL updated = [gCurrentCandidateController showNextPage];
            if (!updated) {
                errorCallback();
            }
        }
        return YES;
    }

    if (input.emacsKey == McBopomofoEmacsKeyForward) {
        BOOL updated = [gCurrentCandidateController highlightNextCandidate];
        if (!updated) {
            errorCallback();
        }
        return YES;
    }

    if ([input isUp]) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController showPreviousPage];
            if (!updated) {
                errorCallback();
            }
        } else {
            BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
            if (!updated) {
                errorCallback();
            }
        }
        return YES;
    }

    if ([input isDown]) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController showNextPage];
            if (!updated) {
                errorCallback();
            }
        } else {
            BOOL updated = [gCurrentCandidateController highlightNextCandidate];
            if (!updated) {
                errorCallback();
            }
        }
        return YES;
    }

    if ([input isHome] || input.emacsKey == McBopomofoEmacsKeyHome) {
        if (gCurrentCandidateController.selectedCandidateIndex == 0) {
            errorCallback();
        } else {
            gCurrentCandidateController.selectedCandidateIndex = 0;
        }

        return YES;
    }

    NSArray *candidates;

    if ([state isKindOfClass:[InputStateChoosingCandidate class]]) {
        candidates = [(InputStateChoosingCandidate *)state candidates];
    } else if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        candidates = [(InputStateAssociatedPhrases *)state candidates];
    }

    if (!candidates) {
        return NO;
    }

    if (([input isEnd] || input.emacsKey == McBopomofoEmacsKeyEnd) && candidates.count > 0) {
        if (gCurrentCandidateController.selectedCandidateIndex == candidates.count - 1) {
            errorCallback();
        } else {
            gCurrentCandidateController.selectedCandidateIndex = candidates.count - 1;
        }
        return YES;
    }

    if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        if (![input isShiftHold]) {
            return NO;
        }
    }

    NSInteger index = NSNotFound;
    NSString *match;
    if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        match = input.inputTextIgnoringModifiers;
    } else {
        match = inputText;
    }

    for (NSUInteger j = 0, c = [gCurrentCandidateController.keyLabels count]; j < c; j++) {
        VTCandidateKeyLabel *label = gCurrentCandidateController.keyLabels[j];
        if ([match compare:label.key options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            index = j;
            break;
        }
    }

    if (index != NSNotFound) {
        NSUInteger candidateIndex = [gCurrentCandidateController candidateIndexAtKeyLabelIndex:index];
        if (candidateIndex != NSUIntegerMax) {
            [self.delegate keyHandler:self didSelectCandidateAtIndex:candidateIndex candidateController:gCurrentCandidateController];
            return YES;
        }
    }

    if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        return NO;
    }

    if (_inputMode == InputModePlainBopomofo) {
        std::string layout = [self _currentLayout];
        std::string punctuationNamePrefix;
        if ([input isControlHold]) {
            punctuationNamePrefix = "_ctrl_punctuation_";
        } else if (Preferences.halfWidthPunctuationEnabled) {
            punctuationNamePrefix = "_half_punctuation_";
        } else {
            punctuationNamePrefix = "_punctuation_";
        }
        std::string customPunctuation = punctuationNamePrefix + layout + std::string(1, (char)charCode);
        std::string punctuation = punctuationNamePrefix + std::string(1, (char)charCode);

        BOOL shouldAutoSelectCandidate = _bpmfReadingBuffer->isValidKey((char)charCode) || _languageModel->hasUnigrams(customPunctuation) || _languageModel->hasUnigrams(punctuation);

        if (!shouldAutoSelectCandidate && (char)charCode >= 'A' && (char)charCode <= 'Z') {
            std::string letter = std::string("_letter_") + std::string(1, (char)charCode);
            if (_languageModel->hasUnigrams(letter)) {
                shouldAutoSelectCandidate = YES;
            }
        }

        if (shouldAutoSelectCandidate) {
            NSUInteger candidateIndex = [gCurrentCandidateController candidateIndexAtKeyLabelIndex:0];
            if (candidateIndex != NSUIntegerMax) {
                [self.delegate keyHandler:self didSelectCandidateAtIndex:candidateIndex candidateController:gCurrentCandidateController];
                [self clear];
                InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
                stateCallback(empty);
                [self handleInput:input state:empty stateCallback:stateCallback errorCallback:errorCallback];
            }
            return YES;
        }
    }

    errorCallback();
    return YES;
}

- (BOOL)_handleBig5State:(InputState *)state
                        input:(KeyHandlerInput *)input
                stateCallback:(void (^)(InputState *))stateCallback
                errorCallback:(void (^)(void))errorCallback;
{
    InputStateBig5 *bigs = (InputStateBig5 *)state;
    UniChar charCode = input.charCode;
    BOOL cancelKey = (charCode == 27);
    if (cancelKey) {
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
        stateCallback(empty);
        return YES;
    }

    if ((charCode == 8) || [input isDelete]) {
        NSString *code = bigs.code;
        if (code.length > 0) {
            code = [code substringToIndex:code.length - 1];
        }
        InputStateBig5 *newState = [[InputStateBig5 alloc] initWithCode:code];
        stateCallback(newState);
        return YES;
    }

    if ((charCode >= '0' && charCode <= '9') ||
        (charCode >= 'a' && charCode <= 'f')) {
        NSString *appneded = [NSString stringWithFormat:@"%@%c", bigs.code, toupper(charCode)];
        if (appneded.length == 4) {
            long big5Code = (long)strtol(appneded.UTF8String, NULL, 16);
            char bytes[3] = {0};
            bytes[0] = (big5Code >> CHAR_BIT) & 0xff;
            bytes[1] = big5Code & 0xff;
            CFStringRef string = CFStringCreateWithCString(NULL, bytes, kCFStringEncodingBig5);
            if (string == NULL) {
                errorCallback();
                InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                stateCallback(empty);
                return YES;
            }

            InputStateCommitting *commiting = [[InputStateCommitting alloc] initWithPoppedText:(__bridge NSString *)string];
            stateCallback(commiting);
            InputStateEmpty *empty = [[InputStateEmpty alloc] init];
            stateCallback(empty);
        } else {
            InputStateBig5 *newState = [[InputStateBig5 alloc] initWithCode:appneded];
            stateCallback(newState);
        }
        return YES;
    }

    errorCallback();
    return YES;
}

#pragma mark - States Building

- (InputStateInputting *)buildInputtingState
{
    // To construct an Inputting state, we need to first retrieve the entire
    // composing buffer from the current grid, then split the composed string
    // into head and tail, so that we can insert the current reading (if
    // not-empty) between them.
    //
    // We'll also need to compute the UTF-8 cursor index. The idea here is we
    // use a "running" index that will eventually catch the cursor index in the
    // builder. The tricky part is that if the spanning length of the node that
    // the cursor is at does not agree with the actual codepoint count of the
    // node's value, we'll need to move the cursor at the end of the node to
    // avoid confusions.
    size_t runningCursor = 0; // spanning-length-based, like the builder cursor

    std::string composed;
    size_t builderCursor = _grid->cursor();
    size_t composedCursor = 0; // UTF-8 (so "byte") cursor per fcitx5 requirement.
    NSString *tooltip = @"";

    for (const auto& node : _latestWalk.nodes) {
        std::string value = node->value();
        composed += value;

        // No work if runningCursor has already caught up with builderCursor.
        if (runningCursor == builderCursor) {
            continue;
        }
        size_t readingLength = node->spanningLength();

        // Simple case: if the running cursor is behind, add the spanning length.
        if (runningCursor + readingLength <= builderCursor) {
            composedCursor += value.length();
            runningCursor += readingLength;
            continue;
        }

        // The builder cursor is in the middle of the node.
        size_t distance = builderCursor - runningCursor;
        size_t valueCodePointCount = McBopomofo::CodePointCount(value);

        // The actual partial value's code point length is the shorter of the
        // distance and the value's code point count.
        size_t cpLen = std::min(distance, valueCodePointCount);
        std::string actualValue = McBopomofo::SubstringToCodePoints(value, cpLen);
        composedCursor += actualValue.length();
        runningCursor += distance;

        // Create a tooltip to warn the user that their cursor is between two
        // readings (syllables) even if the cursor is not in the middle of a
        // composed string due to its being shorter than the number of readings.
        if (valueCodePointCount < readingLength) {
            // builderCursor is guaranteed to be > 0. If it was 0, we wouldn't even
            // reach here due to runningCursor having already "caught up" with
            // builderCursor. It is also guaranteed to be less than the size of the
            // builder's readings for the same reason: runningCursor would have
            // already caught up.
            const std::string& prevReading = _grid->readings()[builderCursor - 1];
            const std::string& nextReading = _grid->readings()[builderCursor];

            tooltip = [NSString stringWithFormat:NSLocalizedString(@"Cursor is between \"%@\" and \"%@\".", @""),
                                [NSString stringWithUTF8String:prevReading.c_str()],
                                [NSString stringWithUTF8String:nextReading.c_str()]];
        }
    }

    std::string headStr = composed.substr(0, composedCursor);
    std::string tailStr = composed.substr(composedCursor, composed.length() - composedCursor);

    NSString *head = [NSString stringWithUTF8String:headStr.c_str()];
    NSString *reading = [NSString stringWithUTF8String:_bpmfReadingBuffer->composedString().c_str()];
    NSString *tail = [NSString stringWithUTF8String:tailStr.c_str()];
    NSString *composedText = [head stringByAppendingString:[reading stringByAppendingString:tail]];
    NSInteger cursorIndex = head.length + reading.length;
    InputStateInputting *newState = [[InputStateInputting alloc] initWithComposingBuffer:composedText cursorIndex:cursorIndex];
    newState.tooltip = tooltip;
    return newState;
}

- (void)_walk
{
    _latestWalk = _grid->walk();
}

- (InputStateChoosingCandidate *)_buildCandidateState:(InputStateNotEmpty *)currentState useVerticalMode:(BOOL)useVerticalMode
{
    auto candidates = _grid->candidatesAt([self _actualCandidateCursorIndex]);

    std::unordered_map<std::string, size_t> valueCountMap;
    for (const auto& c : candidates) {
        ++valueCountMap[c.value];
    }

    NSMutableArray *candidatesArray = [[NSMutableArray alloc] init];
    for (const auto& c : candidates) {
        std::string displayText = c.value;
        if (valueCountMap[displayText] > 1) {
            displayText += " (";
            std::string reading = c.reading;
            std::replace(reading.begin(), reading.end(), '-', ' ');
            displayText += reading;
            displayText += ")";
        }

        NSString *r = [NSString stringWithUTF8String:c.reading.c_str()];
        NSString *v = [NSString stringWithUTF8String:c.value.c_str()];
        NSString *dt = [NSString stringWithUTF8String:displayText.c_str()];
        InputStateCandidate *candidate = [[InputStateCandidate alloc] initWithReading:r value:v displayText:dt];
        [candidatesArray addObject:candidate];
    }

    InputStateChoosingCandidate *state = [[InputStateChoosingCandidate alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex candidates:candidatesArray useVerticalMode:useVerticalMode];
    return state;
}

- (size_t)_actualCandidateCursorIndex
{
    size_t cursor = _grid->cursor();

    // If the cursor is at the end, always return cursor - 1. Even though
    // ReadingGrid already handles this edge case, we want to use this value
    // consistently. UserOverrideModel also requires the cursor to be this
    // correct value.
    if (cursor == _grid->length() && cursor > 0) {
        return cursor - 1;
    }

    // ReadingGrid already makes the assumption that the cursor is always *at*
    // the reading location, and when selectPhraseAfterCursorAsCandidate is true
    // we don't need to do anything. Rather, it's when the flag is false (the
    // default value), that we want to decrement the cursor by one.
    if (!Preferences.selectPhraseAfterCursorAsCandidate && cursor > 0) {
        return cursor - 1;
    }

    return cursor;
}

- (NSArray *)_currentReadings
{
    NSMutableArray *readingsArray = [[NSMutableArray alloc] init];
    std::vector<std::string> v = _grid->readings();
    for (const auto& reading : _grid->readings()) {
        [readingsArray addObject:[NSString stringWithUTF8String:reading.c_str()]];
    }
    return readingsArray;
}

- (nullable InputState *)buildAssociatePhraseStateWithKey:(NSString *)key useVerticalMode:(BOOL)useVerticalMode
{
    std::string cppKey(key.UTF8String);
    if (_languageModel->hasAssociatedPhrasesForKey(cppKey)) {
        std::vector<std::string> phrases = _languageModel->associatedPhrasesForKey(cppKey);
        NSMutableArray<NSString *> *array = [NSMutableArray array];
        for (auto phrase : phrases) {
            NSString *item = [[NSString alloc] initWithUTF8String:phrase.c_str()];
            [array addObject:item];
        }
        InputStateAssociatedPhrases *associatedPhrases = [[InputStateAssociatedPhrases alloc] initWithCandidates:array useVerticalMode:useVerticalMode];
        return associatedPhrases;
    }
    return nil;
}

@end
