// Copyright (c) 2011 and onwards The McBopomofo Authors.
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

#import "Mandarin.h"
#import "Gramambular.h"
#import "McBopomofoLM.h"
#import "UserOverrideModel.h"
#import "LanguageModelManager+Privates.h"
#import "OVUTF8Helper.h"
#import "KeyHandler.h"
#import "McBopomofo-Swift.h"
#import <string>

@import CandidateUI;

// C++ namespace usages
using namespace std;
using namespace Formosa::Mandarin;
using namespace Formosa::Gramambular;
using namespace McBopomofo;
using namespace OpenVanilla;

InputMode InputModeBopomofo = @"org.openvanilla.inputmethod.McBopomofo.Bopomofo";
InputMode InputModePlainBopomofo = @"org.openvanilla.inputmethod.McBopomofo.PlainBopomofo";

static const double kEpsilon = 0.000001;

static double FindHighestScore(const vector<NodeAnchor> &nodes, double epsilon) {
    double highestScore = 0.0;
    for (auto ni = nodes.begin(), ne = nodes.end(); ni != ne; ++ni) {
        double score = ni->node->highestUnigramScore();
        if (score > highestScore) {
            highestScore = score;
        }
    }
    return highestScore + epsilon;
}

// sort helper
class NodeAnchorDescendingSorter
{
public:
    bool operator()(const NodeAnchor &a, const NodeAnchor &b) const {
        return a.node->key().length() > b.node->key().length();
    }
};

// if DEBUG is defined, a DOT file (GraphViz format) will be written to the
// specified path every time the grid is walked
#if DEBUG
static NSString *const kGraphVizOutputfile = @"/tmp/McBopomofo-visualization.dot";
#endif


@implementation KeyHandler
{
    // the reading buffer that takes user input
    Formosa::Mandarin::BopomofoReadingBuffer *_bpmfReadingBuffer;

    // language model
    McBopomofo::McBopomofoLM *_languageModel;

    // user override model
    McBopomofo::UserOverrideModel *_userOverrideModel;

    // the grid (lattice) builder for the unigrams (and bigrams)
    Formosa::Gramambular::BlockReadingBuilder *_builder;

    // latest walked path (trellis) using the Viterbi algorithm
    std::vector<Formosa::Gramambular::NodeAnchor> _walkedNodes;

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
    McBopomofoLM *newLanguageModel;

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

        if (_builder) {
            delete _builder;
            _builder = new BlockReadingBuilder(_languageModel);
            _builder->setJoinSeparator("-");
        }

        if (!_bpmfReadingBuffer->isEmpty()) {
            _bpmfReadingBuffer->clear();
        }
    }
}

- (void)dealloc
{
    // clean up everything
    if (_bpmfReadingBuffer) {
        delete _bpmfReadingBuffer;
    }

    if (_builder) {
        delete _builder;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _bpmfReadingBuffer = new BopomofoReadingBuffer(BopomofoKeyboardLayout::StandardLayout());

        // create the lattice builder
        _languageModel = [LanguageModelManager languageModelMcBopomofo];
        _languageModel->setPhraseReplacementEnabled(Preferences.phraseReplacementEnabled);
        _userOverrideModel = [LanguageModelManager userOverrideModel];

        _builder = new BlockReadingBuilder(_languageModel);

        // each Mandarin syllable is separated by a hyphen
        _builder->setJoinSeparator("-");
        _inputMode = InputModeBopomofo;
    }
    return self;
}

- (void)syncWithPreferences
{
    NSInteger layout = Preferences.keyboardLayout;
    switch (layout) {
        case KeyboardLayoutStandard:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::StandardLayout());
            break;
        case KeyboardLayoutEten:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::ETenLayout());
            break;
        case KeyboardLayoutHsu:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::HsuLayout());
            break;
        case KeyboardLayoutEten26:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::ETen26Layout());
            break;
        case KeyboardLayoutHanyuPinyin:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::HanyuPinyinLayout());
            break;
        case KeyboardLayoutIBM:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::IBMLayout());
            break;
        default:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::StandardLayout());
            Preferences.keyboardLayout = KeyboardLayoutStandard;
    }
    _languageModel->setExternalConverterEnabled(Preferences.chineseConversionStyle == 1);
}

- (void)fixNodeWithValue:(NSString *)value
{
    size_t cursorIndex = [self _actualCandidateCursorIndex];
    string stringValue = [value UTF8String];
    _builder->grid().fixNodeSelectedCandidate(cursorIndex, stringValue);
    if (_inputMode != InputModePlainBopomofo) {
        _userOverrideModel->observe(_walkedNodes, cursorIndex, stringValue, [[NSDate date] timeIntervalSince1970]);
    }
    [self _walk];
}

- (void)clear
{
    _bpmfReadingBuffer->clear();
    _builder->clear();
    _walkedNodes.clear();
}

- (string)_currentLayout
{
    NSString *keyboardLayoutName = Preferences.keyboardLayoutName;
    string layout = string(keyboardLayoutName.UTF8String) + string("_");
    return layout;
}

- (BOOL)handleInput:(KeyHandlerInput *)input state:(InputState *)inState stateCallback:(void (^)(InputState *))stateCallback candidateSelectionCallback:(void (^)(void))candidateSelectionCallback errorCallback:(void (^)(void))errorCallback
{
    InputState *state = inState;
    UniChar charCode = input.charCode;
    McBopomofoEmacsKey emacsKey = input.emacsKey;

    // if the inputText is empty, it's a function key combination, we ignore it
    if (![input.inputText length]) {
        return NO;
    }

    // if the composing buffer is empty and there's no reading, and there is some function key combination, we ignore it
    BOOL isFunctionKey = ([input isCommandHold] || [input isOptionHold] || [input isNumericPad]) || [input isControlHotKey];
    if (![state isKindOfClass:[InputStateNotEmpty class]] &&
        ![state isKindOfClass:[InputStateAssociatedPhrases class]] &&
        isFunctionKey) {
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
        return [self _handleCandidateState:state input:input stateCallback:stateCallback candidateSelectionCallback:candidateSelectionCallback errorCallback:errorCallback];
    }

    // MARK: Handle Associated Phrases
    if ([state isKindOfClass:[InputStateAssociatedPhrases class]]) {
        BOOL result = [self _handleCandidateState:state input:input stateCallback:stateCallback candidateSelectionCallback:candidateSelectionCallback errorCallback:errorCallback];
        if (result) {
            return YES;
        }
        state = [[InputStateEmpty alloc] init];
        stateCallback(state);
    }

    // MARK: Handle Marking
    if ([state isKindOfClass:[InputStateMarking class]]) {
        InputStateMarking *marking = (InputStateMarking *) state;
        if ([self _handleMarkingState:(InputStateMarking *) state input:input stateCallback:stateCallback candidateSelectionCallback:candidateSelectionCallback errorCallback:errorCallback]) {
            return YES;
        }
        state = [marking convertToInputting];
        stateCallback(state);
    }

    bool composeReading = false;

    // MARK: Handle BPMF Keys
    // see if it's valid BPMF reading
    if (![input isControlHold] && _bpmfReadingBuffer->isValidKey((char) charCode)) {
        _bpmfReadingBuffer->combineKey((char) charCode);

        // if we have a tone marker, we have to insert the reading to the
        // builder in other words, if we don't have a tone marker, we just
        // update the composing buffer
        composeReading = _bpmfReadingBuffer->hasToneMarker();
        if (!composeReading) {
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
            return YES;
        }
    }

    // see if we have composition if Enter/Space is hit and buffer is not empty
    // this is bit-OR'ed so that the tone marker key is also taken into account
    composeReading |= (!_bpmfReadingBuffer->isEmpty() && (charCode == 32 || charCode == 13));
    if (composeReading) {
        // combine the reading
        string reading = _bpmfReadingBuffer->syllable().composedString();

        // see if we have a unigram for this
        if (!_languageModel->hasUnigramsForKey(reading)) {
            errorCallback();
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
            return YES;
        }

        // and insert it into the lattice
        _builder->insertReadingAtCursor(reading);

        // then walk the lattice
        NSString *poppedText = [self _popOverflowComposingTextAndWalk];

        // get user override model suggestion
        string overrideValue = (_inputMode == InputModePlainBopomofo) ? "" :
                _userOverrideModel->suggest(_walkedNodes, _builder->cursorIndex(), [[NSDate date] timeIntervalSince1970]);

        if (!overrideValue.empty()) {
            size_t cursorIndex = [self _actualCandidateCursorIndex];
            vector<NodeAnchor> nodes = _builder->grid().nodesCrossingOrEndingAt(cursorIndex);
            double highestScore = FindHighestScore(nodes, kEpsilon);
            _builder->grid().overrideNodeScoreForSelectedCandidate(cursorIndex, overrideValue, highestScore);
        }

        // then update the text
        _bpmfReadingBuffer->clear();

        InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
        inputting.poppedText = poppedText;
        stateCallback(inputting);

        if (_inputMode == InputModePlainBopomofo) {
            InputStateChoosingCandidate *choosingCandidates = [self _buildCandidateState:inputting useVerticalMode:input.useVerticalMode];
            if (choosingCandidates.candidates.count == 1) {
                [self clear];
                NSString *text = choosingCandidates.candidates.firstObject;
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:text];
                stateCallback(committing);

                if (!Preferences.associatedPhrasesEnabled) {
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    stateCallback(empty);
                }
                else {
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

    // MARK: Space and Down
    // keyCode 125 = Down, charCode 32 = Space
    if (_bpmfReadingBuffer->isEmpty() &&
            [state isKindOfClass:[InputStateNotEmpty class]] &&
            ([input isExtraChooseCandidateKey] || charCode == 32 || (input.useVerticalMode && ([input isVerticalModeOnlyChooseCandidateKey])))) {
        if (charCode == 32) {
            // if the spacebar is NOT set to be a selection key
            if ([input isShiftHold] || !Preferences.chooseCandidateUsingSpace) {
                if (_builder->cursorIndex() >= _builder->length()) {
                    if ([state isKindOfClass:[InputStateNotEmpty class]]) {
                        NSString *composingBuffer = [(InputStateNotEmpty *)state composingBuffer];
                        if ([composingBuffer length]) {
                            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
                            stateCallback(committing);
                        }
                    }
                    [self clear];
                    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:@" "];
                    stateCallback(committing);
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    stateCallback(empty);
                } else if (_languageModel->hasUnigramsForKey(" ")) {
                    _builder->insertReadingAtCursor(" ");
                    NSString *poppedText = [self _popOverflowComposingTextAndWalk];
                    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
                    inputting.poppedText = poppedText;
                    stateCallback(inputting);
                }
                return YES;

            }
        }
        InputStateChoosingCandidate *choosingCandidates = [self _buildCandidateState:(InputStateNotEmpty *) state useVerticalMode:input.useVerticalMode];
        stateCallback(choosingCandidates);
        return YES;
    }

    // MARK: Esc
    if (charCode == 27) {
        return [self _handleEscWithState:state stateCallback:stateCallback errorCallback:errorCallback];
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
        return [self _handleEnterWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Punctuation list
    if ((char) charCode == '`') {
        if (_languageModel->hasUnigramsForKey(string("_punctuation_list"))) {
            if (_bpmfReadingBuffer->isEmpty()) {
                _builder->insertReadingAtCursor(string("_punctuation_list"));
                NSString *poppedText = [self _popOverflowComposingTextAndWalk];
                InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
                inputting.poppedText = poppedText;
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

    string punctuationNamePrefix;
    if ([input isControlHold]) {
        punctuationNamePrefix = string("_ctrl_punctuation_");
    } else if (Preferences.halfWidthPunctuationEnabled) {
        punctuationNamePrefix = string("_half_punctuation_");
    } else {
        punctuationNamePrefix = string("_punctuation_");
    }
    string layout = [self _currentLayout];
    string customPunctuation = punctuationNamePrefix + layout + string(1, (char) charCode);
    if ([self _handlePunctuation:customPunctuation state:state usingVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback]) {
        return YES;
    }

    // if nothing is matched, see if it's a punctuation key.
    string punctuation = punctuationNamePrefix + string(1, (char) charCode);
    if ([self _handlePunctuation:punctuation state:state usingVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback]) {
        return YES;
    }

    if ((char) charCode >= 'A' && (char) charCode <= 'Z') {
        string letter = string("_letter_") + string(1, (char) charCode);
        if ([self _handlePunctuation:letter state:state usingVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback]) {
            return YES;
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

- (BOOL)_handleEscWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
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

        if (_bpmfReadingBuffer->isEmpty()) {
            // no nee to beep since the event is deliberately triggered by user
            if (![state isKindOfClass:[InputStateInputting class]]) {
                return NO;
            }
        } else {
            _bpmfReadingBuffer->clear();
            InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
            stateCallback(inputting);
        }
    }
    return YES;
}

- (BOOL)_handleBackwardWithState:(InputState *)state input:(KeyHandlerInput *)input stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    InputStateInputting *currentState = (InputStateInputting *) state;

    if ([input isShiftHold]) {
        // Shift + left
        if (currentState.cursorIndex > 0) {
            NSInteger previousPosition = [StringUtils previousUtf16PositionForIndex:currentState.cursorIndex in:currentState.composingBuffer];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex markerIndex:previousPosition readings:[self _currentReadings]];
            stateCallback(marking);
        } else {
            errorCallback();
            stateCallback(state);
        }
    } else {
        if (_builder->cursorIndex() > 0) {
            _builder->setCursorIndex(_builder->cursorIndex() - 1);
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
    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    InputStateInputting *currentState = (InputStateInputting *) state;

    if ([input isShiftHold]) {
        // Shift + Right
        if (currentState.cursorIndex < currentState.composingBuffer.length) {
            NSInteger nextPosition = [StringUtils nextUtf16PositionForIndex:currentState.cursorIndex in:currentState.composingBuffer];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex markerIndex:nextPosition readings:[self _currentReadings]];
            stateCallback(marking);
        } else {
            errorCallback();
            stateCallback(state);
        }
    } else {
        if (_builder->cursorIndex() < _builder->length()) {
            _builder->setCursorIndex(_builder->cursorIndex() + 1);
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
    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (_builder->cursorIndex()) {
        _builder->setCursorIndex(0);
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
    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
        stateCallback(state);
        return YES;
    }

    if (![state isKindOfClass:[InputStateInputting class]]) {
        return NO;
    }

    if (_builder->cursorIndex() != _builder->length()) {
        _builder->setCursorIndex(_builder->length());
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
    if (!_bpmfReadingBuffer->isEmpty()) {
        errorCallback();
    }
    stateCallback(state);
    return YES;
}

- (BOOL)_handleBackspaceWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (_bpmfReadingBuffer->isEmpty()) {
        if (![state isKindOfClass:[InputStateInputting class]]) {
            return NO;
        }

        if (_builder->cursorIndex()) {
            _builder->deleteReadingBeforeCursor();
            [self _walk];
        } else {
            errorCallback();
            stateCallback(state);
            return YES;
        }
    } else {
        _bpmfReadingBuffer->backspace();
    }

    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
    if (!inputting.composingBuffer.length) {
        InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
        stateCallback(empty);
    } else {
        stateCallback(inputting);
    }
    return YES;
}

- (BOOL)_handleDeleteWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (_bpmfReadingBuffer->isEmpty()) {
        if (![state isKindOfClass:[InputStateInputting class]]) {
            return NO;
        }

        if (_builder->cursorIndex() != _builder->length()) {
            _builder->deleteReadingAfterCursor();
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

- (BOOL)_handleEnterWithState:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if ([state isKindOfClass:[InputStateInputting class]]) {
        if (_inputMode == InputModePlainBopomofo) {
            if (!_bpmfReadingBuffer->isEmpty()) {
                errorCallback();
            }
            return YES;
        }

        [self clear];

        InputStateInputting *current = (InputStateInputting *) state;
        NSString *composingBuffer = current.composingBuffer;
        InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
        stateCallback(committing);
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
        stateCallback(empty);
        return YES;
    }

    return NO;
}

- (BOOL)_handlePunctuation:(string)customPunctuation state:(InputState *)state usingVerticalMode:(BOOL)useVerticalMode stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
{
    if (!_languageModel->hasUnigramsForKey(customPunctuation)) {
        return NO;
    }

    NSString *poppedText;
    if (_bpmfReadingBuffer->isEmpty()) {
        _builder->insertReadingAtCursor(customPunctuation);
        poppedText = [self _popOverflowComposingTextAndWalk];
    } else { // If there is still unfinished bpmf reading, ignore the punctuation
        errorCallback();
        stateCallback(state);
        return YES;
    }

    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
    inputting.poppedText = poppedText;
    stateCallback(inputting);

    if (_inputMode == InputModePlainBopomofo && _bpmfReadingBuffer->isEmpty()) {
        InputStateChoosingCandidate *candidateState = [self _buildCandidateState:inputting useVerticalMode:useVerticalMode];

        if ([candidateState.candidates count] == 1) {
            [self clear];
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:candidateState.candidates.firstObject];
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
 candidateSelectionCallback:(void (^)(void))candidateSelectionCallback
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
            index = [StringUtils previousUtf16PositionForIndex:index in:state.composingBuffer];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:state.composingBuffer cursorIndex:state.cursorIndex markerIndex:index readings:state.readings];
            stateCallback(marking);
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
            index = [StringUtils nextUtf16PositionForIndex:index in:state.composingBuffer];
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:state.composingBuffer cursorIndex:state.cursorIndex markerIndex:index readings:state.readings];
            stateCallback(marking);
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
   candidateSelectionCallback:(void (^)(void))candidateSelectionCallback
                errorCallback:(void (^)(void))errorCallback;
{
    NSString *inputText = input.inputText;
    UniChar charCode = input.charCode;
    VTCandidateController *gCurrentCandidateController = [self.delegate candidateControllerForKeyHandler:self];

    BOOL cancelCandidateKey = (charCode == 27) || (charCode == 8) || [input isDelete];

    if (cancelCandidateKey) {
        if ([state isKindOfClass: [InputStateAssociatedPhrases class]]) {
            [self clear];
            InputStateEmptyIgnoringPreviousState *empty = [[InputStateEmptyIgnoringPreviousState alloc] init];
            stateCallback(empty);
        }
        else if (_inputMode == InputModePlainBopomofo) {
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
        if ([state isKindOfClass: [InputStateAssociatedPhrases class]]) {
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
        candidateSelectionCallback();
        return YES;
    }

    if ([input isPageUp]) {
        BOOL updated = [gCurrentCandidateController showPreviousPage];
        if (!updated) {
            errorCallback();
        }
        candidateSelectionCallback();
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
        candidateSelectionCallback();
        return YES;
    }

    if (input.emacsKey == McBopomofoEmacsKeyBackward) {
        BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
        if (!updated) {
            errorCallback();
        }
        candidateSelectionCallback();
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
        candidateSelectionCallback();
        return YES;
    }

    if (input.emacsKey == McBopomofoEmacsKeyForward) {
        BOOL updated = [gCurrentCandidateController highlightNextCandidate];
        if (!updated) {
            errorCallback();
        }
        candidateSelectionCallback();
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
        candidateSelectionCallback();
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
        candidateSelectionCallback();
        return YES;
    }

    if ([input isHome] || input.emacsKey == McBopomofoEmacsKeyHome) {
        if (gCurrentCandidateController.selectedCandidateIndex == 0) {
            errorCallback();
        } else {
            gCurrentCandidateController.selectedCandidateIndex = 0;
        }

        candidateSelectionCallback();
        return YES;
    }

    NSArray *candidates;

    if ([state isKindOfClass: [InputStateChoosingCandidate class]]) {
        candidates = [(InputStateChoosingCandidate *)state candidates];
    } else if ([state isKindOfClass: [InputStateAssociatedPhrases class]]) {
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

        candidateSelectionCallback();
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
        string layout = [self _currentLayout];
        string punctuationNamePrefix;
        if ([input isControlHold]) {
            punctuationNamePrefix = string("_ctrl_punctuation_");
        } else if (Preferences.halfWidthPunctuationEnabled) {
            punctuationNamePrefix = string("_half_punctuation_");
        } else {
            punctuationNamePrefix = string("_punctuation_");
        }
        string customPunctuation = punctuationNamePrefix + layout + string(1, (char) charCode);
        string punctuation = punctuationNamePrefix + string(1, (char) charCode);

        BOOL shouldAutoSelectCandidate = _bpmfReadingBuffer->isValidKey((char) charCode) || _languageModel->hasUnigramsForKey(customPunctuation) ||
                _languageModel->hasUnigramsForKey(punctuation);

        if (!shouldAutoSelectCandidate && (char) charCode >= 'A' && (char) charCode <= 'Z') {
            string letter = string("_letter_") + string(1, (char) charCode);
            if (_languageModel->hasUnigramsForKey(letter)) {
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
                [self handleInput:input state:empty stateCallback:stateCallback candidateSelectionCallback:candidateSelectionCallback errorCallback:errorCallback];
            }
            return YES;
        }
    }

    errorCallback();
    candidateSelectionCallback();
    return YES;
}

#pragma mark - States Building

- (InputStateInputting *)buildInputtingState
{
    // "updating the composing buffer" means to request the client to "refresh" the text input buffer
    // with our "composing text"
    NSMutableString *composingBuffer = [[NSMutableString alloc] init];
    NSInteger composedStringCursorIndex = 0;

    size_t readingCursorIndex = 0;
    size_t builderCursorIndex = _builder->cursorIndex();

    NSMutableArray <InputPhrase *> *phrases = [[NSMutableArray alloc] init];

    // we must do some Unicode codepoint counting to find the actual cursor location for the client
    // i.e. we need to take UTF-16 into consideration, for which a surrogate pair takes 2 UniChars
    // locations
    for (vector<NodeAnchor>::iterator wi = _walkedNodes.begin(), we = _walkedNodes.end(); wi != we; ++wi) {
        if ((*wi).node) {
            string nodeStr = (*wi).node->currentKeyValue().value;
            vector<string> codepoints = OVUTF8Helper::SplitStringByCodePoint(nodeStr);
            size_t codepointCount = codepoints.size();

            NSString *valueString = [NSString stringWithUTF8String:nodeStr.c_str()];
            [composingBuffer appendString:valueString];

            NSString *readingString = [NSString stringWithUTF8String:(*wi).node->currentKeyValue().key.c_str()];
            InputPhrase *phrase = [[InputPhrase alloc] initWithText:valueString reading:readingString];
            [phrases addObject:phrase];

            // this re-aligns the cursor index in the composed string
            // (the actual cursor on the screen) with the builder's logical
            // cursor (reading) cursor; each built node has a "spanning length"
            // (e.g. two reading blocks has a spanning length of 2), and we
            // accumulate those lengths to calculate the displayed cursor
            // index
            size_t spanningLength = (*wi).spanningLength;
            if (readingCursorIndex + spanningLength <= builderCursorIndex) {
                composedStringCursorIndex += [valueString length];
                readingCursorIndex += spanningLength;
            } else {
                for (size_t i = 0; i < codepointCount && readingCursorIndex < builderCursorIndex; i++) {
                    composedStringCursorIndex += [[NSString stringWithUTF8String:codepoints[i].c_str()] length];
                    readingCursorIndex++;
                }
            }
        }
    }

    // now we gather all the info, we separate the composing buffer to two parts, head and tail,
    // and insert the reading text (the Mandarin syllable) in between them;
    // the reading text is what the user is typing
    NSString *head = [composingBuffer substringToIndex:composedStringCursorIndex];
    NSString *reading = [NSString stringWithUTF8String:_bpmfReadingBuffer->composedString().c_str()];
    NSString *tail = [composingBuffer substringFromIndex:composedStringCursorIndex];
    NSString *composedText = [head stringByAppendingString:[reading stringByAppendingString:tail]];
    NSInteger cursorIndex = composedStringCursorIndex + [reading length];

    InputStateInputting *newState = [[InputStateInputting alloc] initWithComposingBuffer:composedText cursorIndex:cursorIndex];
    return newState;
}

- (void)_walk
{
    // retrieve the most likely trellis, i.e. a Maximum Likelihood Estimation
    // of the best possible Mandarain characters given the input syllables,
    // using the Viterbi algorithm implemented in the Gramambular library
    Walker walker(&_builder->grid());

    // the reverse walk traces the trellis from the end
    _walkedNodes = walker.reverseWalk(_builder->grid().width());

    // then we reverse the nodes so that we get the forward-walked nodes
    reverse(_walkedNodes.begin(), _walkedNodes.end());

    // if DEBUG is defined, a GraphViz file is written to kGraphVizOutputfile
#if DEBUG
    string dotDump = _builder->grid().dumpDOT();
    NSString *dotStr = [NSString stringWithUTF8String:dotDump.c_str()];
    NSError *error = nil;

    BOOL __unused success = [dotStr writeToFile:kGraphVizOutputfile atomically:YES encoding:NSUTF8StringEncoding error:&error];
#endif
}

- (NSString *)_popOverflowComposingTextAndWalk
{
    // in an ideal world, we can as well let the user type forever,
    // but because the Viterbi algorithm has a complexity of O(N^2),
    // the walk will become slower as the number of nodes increase,
    // therefore we need to "pop out" overflown text -- they usually
    // lose their influence over the whole MLE anyway -- so that when
    // the user type along, the already composed text at front will
    // be popped out

    NSString *poppedText = @"";
    NSInteger composingBufferSize = Preferences.composingBufferSize;

    if (_builder->grid().width() > (size_t) composingBufferSize) {
        if (_walkedNodes.size() > 0) {
            NodeAnchor &anchor = _walkedNodes[0];
            poppedText = [NSString stringWithUTF8String:anchor.node->currentKeyValue().value.c_str()];
            _builder->removeHeadReadings(anchor.spanningLength);
        }
    }

    [self _walk];
    return poppedText;
}

- (InputStateChoosingCandidate *)_buildCandidateState:(InputStateNotEmpty *)currentState useVerticalMode:(BOOL)useVerticalMode
{
    NSMutableArray *candidatesArray = [[NSMutableArray alloc] init];

    size_t cursorIndex = [self _actualCandidateCursorIndex];
    vector<NodeAnchor> nodes = _builder->grid().nodesCrossingOrEndingAt(cursorIndex);

    // sort the nodes, so that longer nodes (representing longer phrases) are placed at the top of the candidate list
    stable_sort(nodes.begin(), nodes.end(), NodeAnchorDescendingSorter());

    // then use the C++ trick to retrieve the candidates for each node at/crossing the cursor
    for (vector<NodeAnchor>::iterator ni = nodes.begin(), ne = nodes.end(); ni != ne; ++ni) {
        const vector<KeyValuePair> &candidates = (*ni).node->candidates();
        for (vector<KeyValuePair>::const_iterator ci = candidates.begin(), ce = candidates.end(); ci != ce; ++ci) {
            [candidatesArray addObject:[NSString stringWithUTF8String:(*ci).value.c_str()]];
        }
    }

    InputStateChoosingCandidate *state = [[InputStateChoosingCandidate alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex candidates:candidatesArray useVerticalMode:useVerticalMode];
    return state;
}

- (size_t)_actualCandidateCursorIndex
{
    size_t cursorIndex = _builder->cursorIndex();
    if (Preferences.selectPhraseAfterCursorAsCandidate) {
        // MS Phonetics IME style, phrase is *after* the cursor, i.e. cursor is always *before* the phrase
        if (cursorIndex < _builder->length()) {
            ++cursorIndex;
        }
    } else {
        if (!cursorIndex) {
            ++cursorIndex;
        }
    }

    return cursorIndex;
}

- (NSArray *)_currentReadings
{
    NSMutableArray *readingsArray = [[NSMutableArray alloc] init];
    vector<std::string> v = _builder->readings();
    for (vector<std::string>::iterator it_i = v.begin(); it_i != v.end(); ++it_i) {
        [readingsArray addObject:[NSString stringWithUTF8String:it_i->c_str()]];
    }
    return readingsArray;
}

- (nullable InputState *)buildAssociatePhraseStateWithKey:(NSString *)key useVerticalMode:(BOOL)useVerticalMode
{
    string cppKey = string(key.UTF8String);
    if (_languageModel->hasAssociatedPhrasesForKey(cppKey)) {
        vector<string> phrases = _languageModel->associatedPhrasesForKey(cppKey);
        NSMutableArray <NSString *> *array = [NSMutableArray array];
        for (auto phrase: phrases) {
            NSString *item = [[NSString alloc] initWithUTF8String:phrase.c_str()];
            [array addObject:item];
        }
        InputStateAssociatedPhrases *associatedPhrases = [[InputStateAssociatedPhrases alloc] initWithCandidates:array useVerticalMode:useVerticalMode];
        return associatedPhrases;
    }
    return nil;
}

@end
