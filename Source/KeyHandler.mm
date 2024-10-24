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

#import <algorithm>
#import <optional>
#import <sstream>
#import <string>
#import <unordered_map>
#import <utility>
#import <vector>

@import CandidateUI;
@import NSStringUtils;
@import OpenCCBridge;
@import ChineseNumbers;
@import BopomofoBraille;

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
    newLanguageModel->setExternalConverterEnabled(Preferences.chineseConversionStyle == ChineseConversionStyleModel);

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
    KeyboardLayout layout = Preferences.keyboardLayout;
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
    _languageModel->setExternalConverterEnabled(Preferences.chineseConversionStyle == ChineseConversionStyleModel);
}

- (void)fixNodeWithReading:(NSString *)reading value:(NSString *)value originalCursorIndex:(size_t)originalCursorIndex useMoveCursorAfterSelectionSetting:(BOOL)flag
{
    size_t actualCursor = self.actualCandidateCursorIndex;
    Formosa::Gramambular2::ReadingGrid::Candidate candidate(reading.UTF8String, value.UTF8String);
    if (!_grid->overrideCandidate(actualCursor, candidate)) {
        return;
    }

    Formosa::Gramambular2::ReadingGrid::WalkResult prevWalk = _latestWalk;
    [self _walk];

    // Update the user override model if warranted.
    size_t accumulatedCursor = 0;
    auto nodeIter = _latestWalk.findNodeAt(actualCursor, &accumulatedCursor);
    if (nodeIter == _latestWalk.nodes.cend()) {
        return;
    }
    Formosa::Gramambular2::ReadingGrid::NodePtr currentNode = *nodeIter;
    if (currentNode != nullptr && currentNode->currentUnigram().score() > -8) {
        _userOverrideModel->observe(prevWalk, _latestWalk, self.actualCandidateCursorIndex, [NSDate date].timeIntervalSince1970);
    }

    if (currentNode != nullptr && flag && Preferences.moveCursorAfterSelectingCandidate) {
        _grid->setCursor(accumulatedCursor);
    } else {
        _grid->setCursor(originalCursorIndex);
    }
}

- (void)fixNodeForAssociatedPhraseWithPrefixAt:(size_t)prefixCursorIndex prefixReading:(NSString *)pfxReading prefixValue:(NSString *)pfxValue associatedPhraseReading:(NSString *)phraseReading associatedPhraseValue:(NSString *)phraseValue
{

    if (_grid->length() == 0) {
      return;
    }

    // Unlike actualCandidateCursorIndex() which takes the Hanyin/MS IME cursor
    // modes into consideration, prefixCursorIndex is *already* the actual node
    // position in the grid. The only boundary condition is when prefixCursorIndex
    // is at the end. That's when we should decrement by one.
    size_t actualPrefixCursorIndex = (prefixCursorIndex == _grid->length())
                                         ? prefixCursorIndex - 1
                                         : prefixCursorIndex;
    // First of all, let's find the target node where the prefix is found. The
    // node may not be exactly the same as the prefix.
    size_t accumulatedCursor = 0;
    auto nodeIter =
        _latestWalk.findNodeAt(actualPrefixCursorIndex, &accumulatedCursor);

    // Should not happen. The end location must be >= the node's spanning length.
    if (accumulatedCursor < (*nodeIter)->spanningLength()) {
      return;
    }

    // Let's do a split override. If a node is now ABCD, let's make four overrides
    // A-B-C-D, essentially splitting the node. Why? Because we're inserting an
    // associated phrase. Say the phrase is BCEF with the prefix BC. If we don't
    // do the override, the nodes that represent A and D may not carry the same
    // values after the next walk, since the underlying reading is now a-bcef-d
    // and that does not necessary guarantee that A and D will be there.
    std::vector<std::string> originalNodeValues = McBopomofo::Split((*nodeIter)->value());
    if (originalNodeValues.size() == (*nodeIter)->spanningLength()) {
      // Only performs this if the condition is satisfied.
      size_t overrideIndex = accumulatedCursor - (*nodeIter)->spanningLength();
      for (const auto& value : originalNodeValues) {
        _grid->overrideCandidate(overrideIndex, value);
        ++overrideIndex;
      }
    }

    std::string prefixReading(pfxReading.UTF8String);
    std::string prefixValue(pfxValue.UTF8String);

    // Now, we override the prefix candidate again. This provides us with
    // information for how many more we need to fill in to complete the
    // associated phrase.
    Formosa::Gramambular2::ReadingGrid::Candidate prefixCandidate{prefixReading,
                                                                  prefixValue};
    if (!_grid->overrideCandidate(actualPrefixCursorIndex, prefixCandidate)) {
      return;
    }
    [self _walk];

    // Now we've set ourselves up. Because associated phrases require the strict
    // one-reading-for-one-value rule, we can comfortably count how many readings
    // we'll need to insert. First, let's move to the end of the newly overridden
    // phrase.
    nodeIter =
        _latestWalk.findNodeAt(actualPrefixCursorIndex, &accumulatedCursor);
    _grid->setCursor(accumulatedCursor);

    std::string associatedPhraseReading(phraseReading.UTF8String);
    std::string associatedPhraseValue(phraseValue.UTF8String);

    // Compute how many more reading do we have to insert.
    size_t nodeSpanningLength = (*nodeIter)->spanningLength();
    std::vector<std::string> splitReadings =
        McBopomofo::AssociatedPhrasesV2::SplitReadings(associatedPhraseReading);
    size_t splitReadingsSize = splitReadings.size();
    if (nodeSpanningLength >= splitReadingsSize) {
      // Shouldn't happen
      return;
    }

    for (size_t i = nodeSpanningLength; i < splitReadingsSize; i++) {
      _grid->insertReading(splitReadings[i]);
      ++accumulatedCursor;
      _grid->setCursor(accumulatedCursor);
    }

    // Finally, let's override with the full associated phrase's value.
    if (!_grid->overrideCandidate(actualPrefixCursorIndex,
                                 associatedPhraseValue)) {
      // Shouldn't happen
    }

    [self _walk];
    // Cursor is already at accumulatedCursor, so no more work here.
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

    // MARK: Handle Selecting Feature
    if ([state isKindOfClass:[InputStateSelectingFeature class]] ||
        [state isKindOfClass:[InputStateSelectingDateMacro class]]) {
        return [self _handleCandidateState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Handle Big5 Input
    if ([state isKindOfClass:[InputStateBig5 class]]) {
        return [self _handleBig5State:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Handle Chinese Number Input
    if ([state isKindOfClass:[InputStateChineseNumber class]]) {
        return [self _handleNumberState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    if ([state isKindOfClass:[InputStateEnclosedNumber class]]) {
        return [self _handleEnclosedNumberState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }


    // if the inputText is empty, it's a function key combination, we ignore it
    if (!input.inputText.length) {
        return NO;
    }

    // if the composing buffer is empty and there's no reading, and there is some function key combination, we ignore it
    BOOL isFunctionKey = (input.isCommandHold || input.isOptionHold || input.isNumericPad) || input.isControlHotKey;
    if (![state isKindOfClass:[InputStateNotEmpty class]] &&
        ![state isKindOfClass:[InputStateAssociatedPhrasesPlain class]] &&
        !([state isKindOfClass:[InputStateAssociatedPhrases class]] && [(InputStateAssociatedPhrases*)state useShiftKey]) &&
        isFunctionKey) {
        return NO;
    }

    // Caps Lock processing : if Caps Lock is on, temporarily disable bopomofo.
    if (charCode == 8 || charCode == 13 || input.isAbsorbedArrowKey || input.isExtraChooseCandidateKey || input.isCursorForward || input.isCursorBackward) {
        // do nothing if backspace is pressed -- we ignore the key
    } else if (input.isCapsLockOn) {
        // process all possible combination, we hope.
        [self clear];
        InputStateEmpty *emptyState = [[InputStateEmpty alloc] init];
        stateCallback(emptyState);

        // first commit everything in the buffer.
        if (input.isShiftHold) {
            return NO;
        }

        // if ASCII but not printable, don't use insertText:replacementRange: as many apps don't handle non-ASCII char insertions.
        if (charCode < 0x80 && !isprint(charCode)) {
            return NO;
        }

        // when shift is pressed, don't do further processing, since it outputs capital letter anyway.
        InputStateCommitting *committingState = [[InputStateCommitting alloc] initWithPoppedText:input.inputText.lowercaseString];
        stateCallback(committingState);
        stateCallback(emptyState);
        return YES;
    }

    if (input.isNumericPad && !Preferences.selectCandidateWithNumericKeypad) {
        if (!input.isLeft && !input.isRight && !input.isDown && !input.isUp && charCode != 32 && isprint(charCode)) {
            [self clear];
            InputStateEmpty *emptyState = [[InputStateEmpty alloc] init];
            stateCallback(emptyState);
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:input.inputText.lowercaseString];
            stateCallback(committing);
            stateCallback(emptyState);
            return YES;
        }
    }

    // MARK: Handle Associated Phrases
    if ([state isKindOfClass:[InputStateAssociatedPhrasesPlain class]]) {
        BOOL result = [self _handleCandidateState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
        if (result) {
            return YES;
        }
        state = [[InputStateEmpty alloc] init];
        stateCallback(state);
    }

    if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        BOOL result = [self _handleCandidateState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
        if (result) {
            return YES;
        }
        if ([(InputStateAssociatedPhrases *)state useShiftKey]) {
            state = [self buildInputtingState];
            stateCallback(state);
        } else {
            return YES;
        }
    }

    // MARK: Handle Candidates
    if ([state isKindOfClass:[InputStateChoosingCandidate class]]) {
        return [self _handleCandidateState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Handle Other States with Menu
    if ([state isKindOfClass:[InputStateSelectingDictionary class]] ||
        [state isKindOfClass:[InputStateShowingCharInfo class]]) {
        return [self _handleCandidateState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
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
    BOOL skipBpmfHandling = input.isReservedKey || input.isControlHold;

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
            McBopomofo::UserOverrideModel::Suggestion suggestion = _userOverrideModel->suggest(_latestWalk, self.actualCandidateCursorIndex, [NSDate date].timeIntervalSince1970);
            if (!suggestion.empty()) {
                Formosa::Gramambular2::ReadingGrid::Node::OverrideType type = suggestion.forceHighScoreOverride ? Formosa::Gramambular2::ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore : Formosa::Gramambular2::ReadingGrid::Node::OverrideType::kOverrideValueWithScoreFromTopUnigram;
                _grid->overrideCandidate(self.actualCandidateCursorIndex, suggestion.candidate, type);
                [self _walk];
            }
        }

        // then update the text
        _bpmfReadingBuffer->clear();

        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        stateCallback(inputting);

        if (_inputMode == InputModeBopomofo && Preferences.associatedPhrasesEnabled) {
            [self handleAssociatedPhraseWithState:(InputStateInputting *)inputting useVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback useShiftKey:YES];
        }
        else if (_inputMode == InputModePlainBopomofo) {
            InputStateChoosingCandidate *choosingCandidates = [self _buildCandidateStateFromInputtingState:inputting useVerticalMode:input.useVerticalMode];

            if (choosingCandidates.candidates.count == 1) {
                [self clear];
                NSString *text = choosingCandidates.candidates.firstObject.value;
                NSString *candidateReading = choosingCandidates.candidates.firstObject.reading;
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:text];
                stateCallback(committing);

                if (!Preferences.associatedPhrasesEnabled) {
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    stateCallback(empty);
                } else {
                    InputStateAssociatedPhrasesPlain *associatedPhrases = (InputStateAssociatedPhrasesPlain *)[self buildAssociatedPhrasePlainStateWithReading:candidateReading value:text useVerticalMode:input.useVerticalMode];
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
        [state isKindOfClass:[InputStateNotEmpty class]] && (input.isExtraChooseCandidateKey || charCode == 32 || (input.useVerticalMode && (input.isVerticalModeOnlyChooseCandidateKey)))) {
        if (charCode == 32) {
            // if the spacebar is NOT set to be a selection key
            if (input.isShiftHold || !Preferences.chooseCandidateUsingSpace) {
                if (_grid->cursor() >= _grid->length()) {
                    NSString *composingBuffer = ((InputStateNotEmpty *)state).composingBuffer;
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

        size_t originalCursorIndex = _grid->cursor();

        // Note: When the cursor is at the end of the composing buffer and the
        // preference that make McBopomofo be like MS Bopomofo are on, the
        // cursor should be moved to the begin of the last character.
        if (originalCursorIndex == _grid->length() &&
            Preferences.selectPhraseAfterCursorAsCandidate &&
            Preferences.moveCursorAfterSelectingCandidate) {
            _grid->setCursor(originalCursorIndex - 1);
        }
        InputStateChoosingCandidate *choosingCandidates = [self _buildCandidateStateFromInputtingState:(InputStateInputting *)[self buildInputtingState] useVerticalMode:input.useVerticalMode];
        choosingCandidates.originalCursorIndex = originalCursorIndex;
        stateCallback(choosingCandidates);
        return YES;
    }

    // MARK: Esc
    if (charCode == 27) {
        return [self _handleEscWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Tab
    if (input.isTab) {
        return [self _handleTabState:state shiftIsHold:input.isShiftHold stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Cursor backward
    if (input.isCursorBackward || emacsKey == McBopomofoEmacsKeyBackward) {
        return [self _handleBackwardWithState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK:  Cursor forward
    if (input.isCursorForward || emacsKey == McBopomofoEmacsKeyForward) {
        return [self _handleForwardWithState:state input:input stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Home
    if (input.isHome || emacsKey == McBopomofoEmacsKeyHome) {
        return [self _handleHomeWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: End
    if (input.isEnd || emacsKey == McBopomofoEmacsKeyEnd) {
        return [self _handleEndWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: AbsorbedArrowKey
    if (input.isAbsorbedArrowKey || input.isExtraChooseCandidateKey) {
        return [self _handleAbsorbedArrowKeyWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Backspace
    if (charCode == 8) {
        return [self _handleBackspaceWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Delete
    if (input.isDelete || emacsKey == McBopomofoEmacsKeyDelete) {
        return [self _handleDeleteWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Enter
    if (charCode == 13) {
        if (_inputMode == InputModeBopomofo && input.isControlHold) {
            NSString *string = @"";
            if (Preferences.controlEnterOutput == ControlEnterOutputOff) {
                errorCallback();
                return YES;
            }
            switch (Preferences.controlEnterOutput) {
                case ControlEnterOutputBpmfReading:
                    string = [self _currentBpmfReading];
                    break;
                case ControlEnterOutputHtmlRuby:
                    string = [self _currentHtmlRuby];
                    break;
                case ControlEnterOutputBraille:
                    string = [self _currentBraille];
                    break;
                default:
                    break;
            }
            [self clear];

            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:string];
            stateCallback(committing);
            InputStateEmpty *empty = [[InputStateEmpty alloc] init];
            stateCallback(empty);
            return YES;
        }
        if (_inputMode == InputModeBopomofo &&
            input.isShiftHold &&
            [state isKindOfClass:[InputStateInputting class]]) {
            return [self handleAssociatedPhraseWithState:(InputStateInputting *)state useVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback useShiftKey:NO];
        }
        return [self _handleEnterWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Enter Big5 code mode
    if (input.isControlHold && (charCode == '`')) {
        if (Preferences.big5InputEnabled) {
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
    }

    if (input.isControlHold && (input.keyCode == 42)) {
        [self clear];
        if ([state isKindOfClass:[InputStateInputting class]]) {
            InputStateInputting *current = (InputStateInputting *)state;
            NSString *composingBuffer = current.composingBuffer;
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
            stateCallback(committing);
        }
        InputStateSelectingFeature *selecting = [[InputStateSelectingFeature alloc] init];
        stateCallback(selecting);
        return YES;
    }


    // MARK: Punctuation list
    if ((char)charCode == '`' &&
        !(input.isControlHold || input.isCommandHold || input.isOptionHold)
        ) {
        if (_languageModel->hasUnigrams("_punctuation_list")) {
            if (_bpmfReadingBuffer->isEmpty()) {
                _grid->insertReading("_punctuation_list");
                [self _walk];
                size_t originalCursorIndex = _grid->cursor();
                if (Preferences.selectPhraseAfterCursorAsCandidate) {
                    _grid->setCursor(originalCursorIndex - 1);
                }
                InputStateChoosingCandidate *choosingCandidate = [self _buildCandidateStateFromInputtingState:(InputStateInputting *)[self buildInputtingState] useVerticalMode:input.useVerticalMode];
                choosingCandidate.originalCursorIndex = originalCursorIndex;
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
    if (input.isControlHold) {
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

    InputStateChoosingCandidate *candidateState = [self _buildCandidateStateFromInputtingState:(InputStateInputting *)[self buildInputtingState] useVerticalMode:NO];
    NSArray *candidates = candidateState.candidates;
    if (candidates.count == 0) {
        errorCallback();
        return YES;
    }

    auto nodeIter = _latestWalk.findNodeAt(self.actualCandidateCursorIndex);
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
                currentIndex = candidates.count - 1;
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
    size_t originalCursorIndex = _grid->cursor();
    [self fixNodeWithReading:candidate.reading value:candidate.value originalCursorIndex:originalCursorIndex useMoveCursorAfterSelectionSetting:NO];
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

    if (input.isShiftHold) {
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

    if (input.isShiftHold) {
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

- (NSString *)_currentBpmfReading
{
    NSArray *readings = [self _currentReadings];
    NSString *composingBuffer = [readings componentsJoinedByString:@"-"];
    return composingBuffer;
}

- (NSString *)_currentHtmlRuby
{
    std::string composed;
    for (const auto& node : _latestWalk.nodes) {
        std::string key = node->reading();
        std::replace(key.begin(), key.end(), '-', ' ');
        std::string value = node->value();

        // If a key starts with underscore, it is usually for a punctuation or a
        // symbol but not a Bopomofo reading, so we just ignore such case.
        if (key.rfind(std::string("_"), 0) == 0) {
            composed += value;
        } else {
            composed += "<ruby>";
            composed += value;
            composed += "<rp>(</rp><rt>" + key + "</rt><rp>)</rp>";
            composed += "</ruby>";
        }
    }
    return [NSString stringWithUTF8String:composed.c_str()];
}


- (NSString *)_currentBraille
{
    NSMutableString *composingBuffer = [[NSMutableString alloc] init];
    for (const auto& node : _latestWalk.nodes) {
        std::string value = node->currentUnigram().value();
        std::string reading = node->reading();
        if (reading[0] == '_') {
            NSString *punctuation = [[NSString alloc] initWithUTF8String:value.c_str()];
            NSString *converted = [BopomofoBrailleConverter convertFromBopomofo:punctuation];
            [composingBuffer appendString:converted];
        } else {
            std::string delimiter = "-";
            size_t pos = 0;
            std::string token;
            while ((pos = reading.find(delimiter)) != std::string::npos) {
                token = reading.substr(0, pos);
                NSString *tokenString = [[NSString alloc] initWithUTF8String:token.c_str()];
                NSString *converted = [BopomofoBrailleConverter convertFromBopomofo:tokenString];
                [composingBuffer appendString:converted];
                reading.erase(0, pos + delimiter.length());
            }
            NSString *tokenString = [[NSString alloc] initWithUTF8String:reading.c_str()];
            NSString *converted = [BopomofoBrailleConverter convertFromBopomofo:tokenString];
            [composingBuffer appendString:converted];
        }
    }
    return composingBuffer;
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

        InputStateChoosingCandidate *candidateState = [self _buildCandidateStateFromInputtingState:(InputStateInputting *)[self buildInputtingState] useVerticalMode:useVerticalMode];

        if (candidateState.candidates.count == 1) {
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

    // Dictionary look up
    if ([input.inputText isEqualToString:@"?"]) {
        if (state.markedRange.length > 0) {
            InputStateSelectingDictionary *newState = [[InputStateSelectingDictionary alloc] initWithPreviousState:state selectedString:state.selectedText selectedIndex:0];
            stateCallback(newState);
            return YES;
        }
    }

    // Shift + left
    if ((input.isCursorBackward || input.emacsKey == McBopomofoEmacsKeyBackward)
        && (input.isShiftHold)) {
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
    if ((input.isCursorForward || input.emacsKey == McBopomofoEmacsKeyForward)
        && (input.isShiftHold)) {
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

    BOOL cancelCandidateKey = (charCode == 27) || (charCode == 8) || input.isDelete;

    BOOL isCursorMovingKey =
        (Preferences.allowMovingCursorWhenChoosingCandidates && ([input.inputText isEqualToString:@"j"] || [input.inputText isEqualToString:@"k"])) ||
        (input.isShiftHold && (input.isLeft || input.isRight));

    if ([state isKindOfClass:[InputStateChoosingCandidate class]] && isCursorMovingKey) {
        if ([input.inputText isEqualToString:@"j"] || (input.isLeft && input.isShiftHold)
            ) {
            size_t cursor = _grid->cursor();
            if (cursor > 0) {
                cursor--;
                _grid->setCursor(cursor);
            } else {
                errorCallback();
                return YES;
            }
        } else if ([input.inputText isEqualToString:@"k"]  || (input.isRight && input.isShiftHold)) {
            size_t cursor = _grid->cursor();
            if (cursor < _grid->length()) {
                cursor++;
                _grid->setCursor(cursor);
            } else {
                errorCallback();
                return YES;
            }
        }
        InputState *newState = [self _buildCandidateStateFromInputtingState:(InputStateInputting *)[self buildInputtingState] useVerticalMode:[(InputStateChoosingCandidate *)state useVerticalMode]];
        stateCallback(newState);
        return YES;
    }

    if (_inputMode == InputModeBopomofo && [input.inputText isEqualToString:@"?"]) {
        if ([state isKindOfClass:[InputStateShowingCharInfo class]] ||
            [state isKindOfClass:[InputStateSelectingDictionary class]]) {
            cancelCandidateKey = YES;
        } else if ([state isKindOfClass:[InputStateChoosingCandidate class]]) {
            InputStateChoosingCandidate *currentState = (InputStateChoosingCandidate *)state;
            NSInteger index = gCurrentCandidateController.selectedCandidateIndex;
            NSString *selectedPhrase = currentState.candidates[index].displayText;
            InputStateSelectingDictionary *newState = [[InputStateSelectingDictionary alloc] initWithPreviousState:currentState selectedString:selectedPhrase selectedIndex:index];
            stateCallback(newState);
            return YES;
        }
        else if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
           if ([(InputStateAssociatedPhrases *)state useShiftKey]) {
               return NO;
           }
       }
    }

    if (cancelCandidateKey) {
        if ([state isKindOfClass:[InputStateShowingCharInfo class]]) {
            InputStateShowingCharInfo *current = (InputStateShowingCharInfo *)state;
            NSInteger selectedIndex = current.previousState.selectedIndex;
            InputStateNotEmpty *newState = current.previousState.previousState;
            stateCallback(newState);
            gCurrentCandidateController = [self.delegate candidateControllerForKeyHandler:self];
            gCurrentCandidateController.selectedCandidateIndex = selectedIndex;
        } else if ([state isKindOfClass:[InputStateSelectingDictionary class]]) {
            InputStateSelectingDictionary *current = (InputStateSelectingDictionary *)state;
            NSInteger selectedIndex = current.selectedIndex;
            InputStateNotEmpty *newState = current.previousState;
            stateCallback(newState);
            gCurrentCandidateController = [self.delegate candidateControllerForKeyHandler:self];
            gCurrentCandidateController.selectedCandidateIndex = selectedIndex;
        } else if ([state isKindOfClass:[InputStateSelectingFeature class]]) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
        } else if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
            if ([(InputStateAssociatedPhrases *)state useShiftKey]) {
                return NO;
            }

            InputStateAssociatedPhrases *current = (InputStateAssociatedPhrases *)state;
            NSInteger selectedIndex = current.selectedIndex;
            InputStateNotEmpty *newState = current.previousState;
            stateCallback(newState);
            gCurrentCandidateController = [self.delegate candidateControllerForKeyHandler:self];
            gCurrentCandidateController.selectedCandidateIndex = selectedIndex;
        } else if ([state isKindOfClass:[InputStateAssociatedPhrasesPlain class]]) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
        } else if (_inputMode == InputModePlainBopomofo) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
        } else if ([state isKindOfClass:[InputStateChoosingCandidate class]]) {
            size_t originalCursorIndex = ((InputStateChoosingCandidate *)state).originalCursorIndex;
            _grid->setCursor(originalCursorIndex);
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
        } else {
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
        }
        return YES;
    }

    if (charCode == 13 || input.isEnter) {
        // Find associated phrases from the chosen candidate.

        if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
            if ([(InputStateAssociatedPhrases *)state useShiftKey]) {
                if (input.isShiftHold) {
                    return YES;
                }
                return NO;
            }
        }

        if (_inputMode == InputModeBopomofo &&
            input.isShiftHold) {
            if ([state isKindOfClass:[InputStateChoosingCandidate class]]) {
                InputStateChoosingCandidate *current = (InputStateChoosingCandidate *)state;
                NSInteger selectedCandidateIndex = gCurrentCandidateController.selectedCandidateIndex;
                InputStateCandidate *candidate = current.candidates[selectedCandidateIndex];
                NSString *prefixReading = candidate.reading;
                NSString *prefixValue = candidate.value;
                InputState* newState = [self buildAssociatedPhraseStateWithPreviousState:current candidateStateOriginalCursorAt:current.originalCursorIndex prefixReading:prefixReading value:prefixValue selectedCandidateIndex:selectedCandidateIndex useVerticalMode:current.useVerticalMode useShiftKey:NO];
                if (newState) {
                    stateCallback(newState);
                } else {
                    errorCallback();
                }
                return YES;
            }
        }

        if ([state isKindOfClass:[InputStateAssociatedPhrasesPlain class]]) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
            return YES;
        }

        [self.delegate keyHandler:self didSelectCandidateAtIndex:gCurrentCandidateController.selectedCandidateIndex candidateController:gCurrentCandidateController];
        return YES;
    }

    if (charCode == 32 || input.isPageDown || input.emacsKey == McBopomofoEmacsKeyNextPage) {
        BOOL updated = [gCurrentCandidateController showNextPage];
        if (!updated) {
            errorCallback();
        }
        return YES;
    }

    if (input.isPageUp) {
        BOOL updated = [gCurrentCandidateController showPreviousPage];
        if (!updated) {
            errorCallback();
        }
        return YES;
    }

    if (input.isLeft) {
        if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
            if ([(InputStateAssociatedPhrases *)state useShiftKey] && input.isShiftHold) {
                return NO;
            }
        }

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

    if (input.isRight) {
        if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
            if ([(InputStateAssociatedPhrases *)state useShiftKey] && input.isShiftHold) {
                return NO;
            }
        }

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

    if (input.isUp) {
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

    if (input.isDown) {
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

    if (input.isHome || input.emacsKey == McBopomofoEmacsKeyHome) {
        if (gCurrentCandidateController.selectedCandidateIndex == 0) {
            errorCallback();
        } else {
            gCurrentCandidateController.selectedCandidateIndex = 0;
        }

        return YES;
    }

    NSInteger candidateCount = 0;
    if ([state conformsToProtocol:@protocol(CandidateProvider)]) {
        candidateCount = ((id<CandidateProvider>)state).candidateCount;
    }

    if (!candidateCount) {
        return NO;
    }

    if ((input.isEnd || input.emacsKey == McBopomofoEmacsKeyEnd) && candidateCount > 0) {
        if (gCurrentCandidateController.selectedCandidateIndex == candidateCount - 1) {
            errorCallback();
        } else {
            gCurrentCandidateController.selectedCandidateIndex = candidateCount - 1;
        }
        return YES;
    }

    BOOL useInputTextIgnoringModifiers = NO;
    if ([state isKindOfClass:[InputStateAssociatedPhrasesPlain class]]) {
        useInputTextIgnoringModifiers = YES;
    } else if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        useInputTextIgnoringModifiers = [(InputStateAssociatedPhrases *)state useShiftKey];
    }

    if (useInputTextIgnoringModifiers) {
        if (!input.isShiftHold) {
            return NO;
        }
    }

    NSInteger index = NSNotFound;
    NSString *match;

    if (useInputTextIgnoringModifiers) {
        match = input.inputTextIgnoringModifiers;
    } else {
        match = inputText;
    }

    for (NSUInteger j = 0, c = gCurrentCandidateController.keyLabels.count; j < c; j++) {
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

    if (useInputTextIgnoringModifiers) {
        return NO;
    }

    if (_inputMode == InputModePlainBopomofo) {
        std::string layout = [self _currentLayout];
        std::string punctuationNamePrefix;
        if (input.isControlHold) {
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

- (BOOL)_handleNumberState:(InputState *)state
                   input:(KeyHandlerInput *)input
           stateCallback:(void (^)(InputState *))stateCallback
           errorCallback:(void (^)(void))errorCallback;
{
    InputStateChineseNumber *numberState = (InputStateChineseNumber *)state;
    UniChar charCode = input.charCode;
    BOOL cancelKey = (charCode == 27);
    if (cancelKey) {
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
        stateCallback(empty);
        return YES;
    }
    if ((charCode == 8) || input.isDelete) {
        NSString *number = numberState.number;
        if (number.length > 0) {
            number = [number substringToIndex:number.length - 1];
        } else {
            errorCallback();
            return YES;
        }
        InputStateChineseNumber *newState = [[InputStateChineseNumber alloc] initWithStyle:numberState.style number:number];
        stateCallback(newState);
        return YES;
    }

    if (charCode == 13) {
        if (!numberState.number.count) {
            InputStateEmpty *empty = [[InputStateEmpty alloc] init];
            stateCallback(empty);
            return YES;
        }
        NSString *intPart = @"";
        NSString *decPart = @"";
        NSArray *components = [numberState.number componentsSeparatedByString:@"."];
        if (components.count == 2) {
            intPart = components[0];
            decPart = components[1];
        } else {
            intPart = numberState.number;
        }

        switch (numberState.style) {
            case InputStateChineseNumberStyleLower:
            {
                NSString *string = [ChineseNumbers generateWithIntPart:intPart decPart:decPart digitCase:ChineseNumbersCaseLowercase];
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:string];
                stateCallback(committing);
            }
                break;
            case InputStateChineseNumberStyleUpper:
            {
                NSString *string = [ChineseNumbers generateWithIntPart:intPart decPart:decPart digitCase:ChineseNumbersCaseUppercase];
                if (Preferences.chineseConversionEnabled) {
                    string = [[OpenCCBridge sharedInstance] convertToSimplified:string];
                }
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:string];
                stateCallback(committing);
            }
                break;

            case InputStateChineseNumberStyleSuzhou:
            {
                NSString *string = [SuzhouNumbers generateWithIntPart:intPart decPart:decPart unit:@"[單位]" preferInitialVertical:YES];
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:string];
                stateCallback(committing);
            }
                break;
            default:
                break;
        }
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
        stateCallback(empty);
        return YES;
    }

    if (charCode >= '0' && charCode <= '9') {
        if (numberState.number.length > 20) {
            errorCallback();
            return YES;
        }

        NSString *appended = [NSString stringWithFormat:@"%@%c", numberState.number, toupper(charCode)];
        InputStateChineseNumber *newState = [[InputStateChineseNumber alloc] initWithStyle:numberState.style number:appended];
        stateCallback(newState);
    } else if (charCode == '.') {
        if ([numberState.number containsString:@"."]) {
            errorCallback();
            return YES;
        }
        if (numberState.number.length == 0 ||
            numberState.number.length > 20) {
            errorCallback();
            return YES;
        }

        NSString *appended = [NSString stringWithFormat:@"%@%c", numberState.number, toupper(charCode)];
        InputStateChineseNumber *newState = [[InputStateChineseNumber alloc] initWithStyle:numberState.style number:appended];
        stateCallback(newState);
    } else {
        errorCallback();
    }
    return YES;
}

- (BOOL)_handleEnclosedNumberState:(InputState *)state
                   input:(KeyHandlerInput *)input
           stateCallback:(void (^)(InputState *))stateCallback
           errorCallback:(void (^)(void))errorCallback;
{
    InputStateEnclosedNumber *enclosedNumber = (InputStateEnclosedNumber *)state;
    UniChar charCode = input.charCode;
    BOOL cancelKey = (charCode == 27);
    if (cancelKey) {
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
        stateCallback(empty);
        return YES;
    }
    if ((charCode == 8) || input.isDelete) {
        NSString *number = enclosedNumber.number;
        if (number.length > 0) {
            number = [number substringToIndex:number.length - 1];
        }
        InputStateEnclosedNumber *newState = [[InputStateEnclosedNumber alloc] initWithNumber:number];
        stateCallback(newState);
        return YES;
    }

    if (charCode == 13 || charCode == 32) {
        NSString *number = enclosedNumber.number;
        std::string key = std::string("_number_") + std::string([number UTF8String]);

        if (_languageModel->hasUnigrams(key)) {
            if (_bpmfReadingBuffer->isEmpty()) {

                auto unigrams = _languageModel->getUnigrams(key);
                if (unigrams.size() == 1) {
                    auto unigram = unigrams[0];
                    NSString *string = [[NSString alloc] initWithUTF8String:unigram.value().c_str()];
                    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:string];
                    stateCallback(committing);
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    stateCallback(empty);
                    return YES;
                }

                _grid->insertReading(key);
                [self _walk];
                size_t originalCursorIndex = _grid->cursor();
                if (Preferences.selectPhraseAfterCursorAsCandidate) {
                    _grid->setCursor(originalCursorIndex - 1);
                }
                InputStateChoosingCandidate *choosingCandidate = [self _buildCandidateStateFromInputtingState:(InputStateInputting *)[self buildInputtingState] useVerticalMode:input.useVerticalMode];
                choosingCandidate.originalCursorIndex = originalCursorIndex;
                stateCallback(choosingCandidate);
            } else { // If there is still unfinished bpmf reading, ignore the punctuation
                errorCallback();
            }
        } else {
            errorCallback();
        }
        return YES;
    }

    if (charCode >= '0' && charCode <= '9') {
        if (enclosedNumber.number.length > 2) {
            errorCallback();
            return YES;
        }

        NSString *appended = [NSString stringWithFormat:@"%@%c", enclosedNumber.number, charCode];
        InputStateEnclosedNumber *newState = [[InputStateEnclosedNumber alloc] initWithNumber:appended];
        stateCallback(newState);
    } else {
        errorCallback();
    }

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

    if ((charCode == 8) || input.isDelete) {
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
        NSString *appended = [NSString stringWithFormat:@"%@%c", bigs.code, toupper(charCode)];
        if (appended.length == 4) {
            long big5Code = (long)strtol(appended.UTF8String, NULL, 16);
            char bytes[3] = {0};
            bytes[0] = (big5Code >> CHAR_BIT) & 0xff;
            bytes[1] = big5Code & 0xff;
            CFStringRef string = CFStringCreateWithCString(NULL, bytes, kCFStringEncodingBig5_HKSCS_1999);
            if (string == NULL) {
                errorCallback();
                InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                stateCallback(empty);
                return YES;
            }

            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:(__bridge NSString *)string];
            CFRelease(string);
            stateCallback(committing);
            InputStateEmpty *empty = [[InputStateEmpty alloc] init];
            stateCallback(empty);
        } else {
            InputStateBig5 *newState = [[InputStateBig5 alloc] initWithCode:appended];
            stateCallback(newState);
        }
        return YES;
    }

    errorCallback();
    return YES;
}



- (BOOL)handleAssociatedPhraseWithState:(InputStateInputting *)state
                useVerticalMode:(BOOL)useVerticalMode
                stateCallback:(void (^)(InputState *))stateCallback
                errorCallback:(void (^)(void))errorCallback
                useShiftKey:(BOOL)useShiftKey
{
    size_t cursor = _grid->cursor();

    // We need to find the node *before* the cursor, so cursor must be >= 1.
    if (cursor < 1) {
        errorCallback();
        return YES;
    }

    // Find the selected node *before* the cursor.
    size_t prefixCursorIndex = cursor - 1;

    size_t endCursorIndex = 0;
    auto nodePtrIt = _latestWalk.findNodeAt(prefixCursorIndex, &endCursorIndex);
    if (nodePtrIt == _latestWalk.nodes.cend() || endCursorIndex == 0) {
        // Shouldn't happen.
        errorCallback();
        return YES;
    }

    // Validate that the value's codepoint count is the same as the number
    // of readings. This is a strict requirement for the associated phrases.
    std::vector<std::string> codepoints = McBopomofo::Split((*nodePtrIt)->value());
    std::vector<std::string> readings = McBopomofo::AssociatedPhrasesV2::SplitReadings((*nodePtrIt)->reading());
    if (codepoints.size() != readings.size()) {
        errorCallback();
        return YES;
    }

    if (endCursorIndex < readings.size()) {
        // Shouldn't happen.
        errorCallback();
        return YES;
    }

    // Try to find the longest associated phrase prefix. Suppose we have
    // a walk A-B-CD-EFGH and the cursor is between EFG and H. Our job is
    // to try the prefixes EFG, EF, and G to see which one yields a list
    // of possible associated phrases.
    //
    //             grid_->cursor()
    //                 |
    //                 v
    //     A-B-C-D-|EFG|H|
    //             ^     ^
    //             |     |
    //             |    endCursorIndex
    //           startCursorIndex
    //
    // In this case, the max prefix length is 3. This works because our
    // association phrases mechanism require that the node's codepoint
    // length and reading length (i.e. the spanning length) must be equal.
    //
    // And say if the prefix "FG" has associated phrases FGPQ, FGRST, and
    // the user later chooses FGRST, we will first override the FG node
    // again, essentially breaking that from E and H (the vertical bar
    // represents the cursor):
    //
    //     A-B-C-D-E'-FG|-H'
    //
    // And then we add the readings for the RST to the grid, and override
    // the grid at the cursor position with the value FGRST (and its
    // corresponding reading) again, so that the process is complete:
    //
    //     A-B-C-D-E'-FGRST|-H'
    //
    // Notice that after breaking FG from EFGH, the values E and H may
    // change due to a new walk, hence the notation E' and H'. We address
    // issue in pinNodeWithAssociatedPhrase() by making sure that the nodes
    // will be overridden with the values E and H.
    size_t startCursorIndex = endCursorIndex - readings.size();
    size_t prefixLength = cursor - startCursorIndex;
    size_t maxPrefixLength = prefixLength;
    for (; prefixLength > 0; --prefixLength) {
        size_t startIndex = maxPrefixLength - prefixLength;
        auto cpBegin = codepoints.cbegin();
        auto cpEnd = codepoints.cbegin();
        std::advance(cpBegin, startIndex);
        std::advance(cpEnd, maxPrefixLength);
        auto cpSlice = std::vector<std::string>(cpBegin, cpEnd);

        auto rdBegin = readings.cbegin();
        auto rdEnd = readings.cbegin();
        std::advance(rdBegin, startIndex);
        std::advance(rdEnd, maxPrefixLength);
        auto rdSlice = std::vector<std::string>(rdBegin, rdEnd);

        std::stringstream value;
        for (const std::string& cp : cpSlice) {
            value << cp;
        }

        NSString *combinedReading = @(McBopomofo::AssociatedPhrasesV2::CombineReadings(rdSlice).c_str());
        NSString *actualValue = @(value.str().c_str());
        InputState *newState = [self buildAssociatedPhraseStateWithPreviousState:state prefixCursorAt:prefixCursorIndex reading:combinedReading value:actualValue selectedCandidateIndex:0 useVerticalMode:useVerticalMode useShiftKey:useShiftKey];
        if (newState) {
            stateCallback(newState);
            return YES;
        }
    }
    if (!useShiftKey) {
        errorCallback();
    }
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
        if (valueCodePointCount != readingLength) {
            // builderCursor is guaranteed to be > 0. If it was 0, we wouldn't even
            // reach here due to runningCursor having already "caught up" with
            // builderCursor. It is also guaranteed to be less than the size of the
            // builder's readings for the same reason: runningCursor would have
            // already caught up.
            const std::string& prevReading = _grid->readings()[builderCursor - 1];
            const std::string& nextReading = _grid->readings()[builderCursor];

            tooltip = [NSString stringWithFormat:NSLocalizedString(@"Cursor is between \"%@\" and \"%@\".", @""),
                                @(prevReading.c_str()),
                                @(nextReading.c_str())];
        }
    }

    std::string headStr = composed.substr(0, composedCursor);
    std::string tailStr = composed.substr(composedCursor, composed.length() - composedCursor);

    NSString *head = @(headStr.c_str());
    NSString *reading = @(_bpmfReadingBuffer->composedString().c_str());
    NSString *tail = @(tailStr.c_str());
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

- (InputStateChoosingCandidate *)_buildCandidateStateFromInputtingState:(InputStateInputting *)inputting useVerticalMode:(BOOL)useVerticalMode
{
    auto candidates = _grid->candidatesAt(self.actualCandidateCursorIndex);

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

        NSString *r = @(c.reading.c_str());
        NSString *v = @(c.value.c_str());
        NSString *dt = @(displayText.c_str());
        InputStateCandidate *candidate = [[InputStateCandidate alloc] initWithReading:r value:v displayText:dt];
        [candidatesArray addObject:candidate];
    }

    InputStateChoosingCandidate *state = [[InputStateChoosingCandidate alloc] initWithComposingBuffer:inputting.composingBuffer cursorIndex:inputting.cursorIndex candidates:candidatesArray useVerticalMode:useVerticalMode];
    return state;
}

- (size_t)computeActualCursorIndex:(size_t)cursor
{
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

- (NSInteger)actualCandidateCursorIndex
{
    return [self computeActualCursorIndex:_grid->cursor()];
}

- (NSInteger)cursorIndex
{
    size_t cursor = _grid->cursor();
    return cursor;
}

- (NSArray *)_currentReadings
{
    NSMutableArray *readingsArray = [[NSMutableArray alloc] init];
    std::vector<std::string> v = _grid->readings();
    for (const auto& reading : _grid->readings()) {
        [readingsArray addObject:@(reading.c_str())];
    }
    return readingsArray;
}

- (nullable InputState *)buildAssociatedPhrasePlainStateWithReading:(NSString *)reading value:(NSString *)value useVerticalMode:(BOOL)useVerticalMode;
{
    // Check if we need to convert the value back to TC.
    NSString *actualValue = value;
    BOOL scToTc = Preferences.chineseConversionEnabled &&
            Preferences.chineseConversionStyle == ChineseConversionStyleModel;
    if (scToTc) {
        actualValue = [[OpenCCBridge sharedInstance] convertToTraditional:value];
    }

    std::string cppValue(actualValue.UTF8String);
    std::vector<std::string> readings = McBopomofo::AssociatedPhrasesV2::SplitReadings(std::string(reading.UTF8String));

    std::vector<McBopomofo::AssociatedPhrasesV2::Phrase> phrases = _languageModel->findAssociatedPhrasesV2(cppValue, readings);
    if (!phrases.empty()) {
        NSMutableArray<InputStateCandidate *> *array = [NSMutableArray array];
        for (const auto& phrase : phrases) {
            // AssociatedPhrasesV2::Phrase's value *contains* the prefix, hence this.
            std::string valueWithoutPrefix = phrase.value.substr(cppValue.length());

            // Ditto for reading; so we need to skip the prefix's readings.
            auto readingIter = phrase.readings.cbegin();
            for (auto ri = readings.cbegin(), re = readings.cend(); ri != re && readingIter != phrase.readings.cend(); ++ri) {
                ++readingIter;
                if (readingIter == phrase.readings.cend()) {
                    // Shouldn't happen; mark this as an invalid phrase.
                    continue;
                }
            }
            std::vector<std::string> readingsWithoutPrefix{readingIter, phrase.readings.cend()};
            std::string combinedReading = McBopomofo::AssociatedPhrasesV2::CombineReadings(readingsWithoutPrefix);

            NSString *candidateReading = @(combinedReading.c_str());
            NSString *candidateValue = @(valueWithoutPrefix.c_str());
            InputStateCandidate *candidate = [[InputStateCandidate alloc] initWithReading:candidateReading value:candidateValue displayText:candidateValue];
            [array addObject:candidate];
        }
        InputStateAssociatedPhrasesPlain *associatedPhrases = [[InputStateAssociatedPhrasesPlain alloc] initWithCandidates:array useVerticalMode:useVerticalMode];
        return associatedPhrases;
    }
    return nil;
}

- (nullable InputState *)buildAssociatedPhraseStateWithPreviousState:(id)state prefixCursorAt:(size_t)prefixCursorIndex reading:(NSString *)reading value:(NSString *)value selectedCandidateIndex:(NSInteger)candidateIndex useVerticalMode:(BOOL)useVerticalMode useShiftKey:(BOOL)useShiftKey
{
    BOOL scToTc = Preferences.chineseConversionEnabled &&
            Preferences.chineseConversionStyle == ChineseConversionStyleModel;

    std::vector<std::string> splitReadings = McBopomofo::AssociatedPhrasesV2::SplitReadings(std::string(reading.UTF8String));
    NSString *actualValue = value;
    if (scToTc) {
        // The data is in Traditional Chinese, and so if ChineseConversionStyleModel is enabled, we need to convert the prefix back.
        actualValue = [[OpenCCBridge sharedInstance] convertToTraditional:actualValue];
    }
    std::string prefixValue(actualValue.UTF8String);
    std::vector<McBopomofo::AssociatedPhrasesV2::Phrase> phrases = _languageModel->findAssociatedPhrasesV2(prefixValue, splitReadings);

    if (phrases.empty()) {
        return nil;
    }

    NSMutableArray<InputStateCandidate *> *array = [NSMutableArray array];
    for (const auto& phrase : phrases) {
        std::string combinedReading = McBopomofo::AssociatedPhrasesV2::CombineReadings(phrase.readings);
        NSString *candidateReading = @(combinedReading.c_str());
        NSString *candidateValue = @(phrase.value.c_str());

        // Display text chops the prefix.
        std::string valueWithoutPrefix = phrase.value.substr(prefixValue.length());
        NSString *displayText = @(valueWithoutPrefix.c_str());

        // Follow the logic of ChineseConversionStyleModel, if enabled.
        if (scToTc) {
            candidateValue = [[OpenCCBridge sharedInstance] convertToSimplified:candidateValue];
            displayText = [[OpenCCBridge sharedInstance] convertToSimplified:displayText];
        }

        InputStateCandidate *candidate = [[InputStateCandidate alloc] initWithReading:candidateReading value:candidateValue displayText:displayText];
        [array addObject:candidate];
    }
    InputStateAssociatedPhrases *associatedPhrases = [[InputStateAssociatedPhrases alloc] initWithPreviousState:state prefixCursorIndex:prefixCursorIndex prefixReading:reading prefixValue:value selectedIndex:candidateIndex candidates:array useVerticalMode:useVerticalMode useShiftKey:useShiftKey];
    return associatedPhrases;
}

- (nullable InputState *)buildAssociatedPhraseStateWithPreviousState:(id)state candidateStateOriginalCursorAt:(size_t)candidtaeStateOriginalCursorIndex prefixReading:(NSString *)prefixReading value:(NSString *)prefixValue selectedCandidateIndex:(NSInteger)candidateIndex useVerticalMode:(BOOL)useVerticalMode useShiftKey:(BOOL)useShiftKey
{
    return [self buildAssociatedPhraseStateWithPreviousState:state prefixCursorAt:[self computeActualCursorIndex:candidtaeStateOriginalCursorIndex] reading:prefixReading value:prefixValue selectedCandidateIndex:candidateIndex useVerticalMode:useVerticalMode useShiftKey:useShiftKey];
}


@end
