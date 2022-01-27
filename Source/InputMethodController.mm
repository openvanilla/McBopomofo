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

#import "InputMethodController.h"
#import <fstream>
#import <iostream>
#import <set>
#import "OVStringHelper.h"
#import "OVUTF8Helper.h"
#import "LanguageModelManager.h"

// Swift Packages
@import CandidateUI;
@import NotifierUI;
@import TooltipUI;
@import OpenCCBridge;
@import VXHanConvert;

// C++ namespace usages
using namespace std;
using namespace Formosa::Mandarin;
using namespace Formosa::Gramambular;
using namespace McBopomofo;
using namespace OpenVanilla;

static const NSInteger kMinKeyLabelSize = 10;

// input modes
static NSString *const kBopomofoModeIdentifier = @"org.openvanilla.inputmethod.McBopomofo.Bopomofo";
static NSString *const kPlainBopomofoModeIdentifier = @"org.openvanilla.inputmethod.McBopomofo.PlainBopomofo";

VTCandidateController *gCurrentCandidateController = nil;

// if DEBUG is defined, a DOT file (GraphViz format) will be written to the
// specified path everytime the grid is walked
#if DEBUG
static NSString *const kGraphVizOutputfile = @"/tmp/McBopomofo-visualization.dot";
#endif

// https://clang-analyzer.llvm.org/faq.html
__attribute__((annotate("returns_localized_nsstring")))
static inline NSString *LocalizationNotNeeded(NSString *s) {
    return s;
}

@interface McBopomofoInputMethodController ()
{
    NSInteger _latestReadingCursor;

    // the current text input client; we need to keep this when candidate panel is on
    id _currentCandidateClient;

    // a special deferred client for Terminal.app fix
    id _currentDeferredClient;

    // current input mode
    NSString *_inputMode;

    InputState *_state;
}
@end

@interface McBopomofoInputMethodController (VTCandidateController) <VTCandidateControllerDelegate>
@end

@interface McBopomofoInputMethodController (UI)
+ (VTHorizontalCandidateController *)horizontalCandidateController;
+ (VTVerticalCandidateController *)verticalCandidateController;
+ (TooltipController *)tooltipController;
- (void)_showTooltip:(NSString *)tooltip composingBuffer:(NSString *)composingBuffer client:(id)client;
- (void)_hideTooltip;
@end

// sort helper
class NodeAnchorDescendingSorter
{
public:
    bool operator()(const NodeAnchor &a, const NodeAnchor &b) const {
        return a.node->key().length() > b.node->key().length();
    }
};

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

@implementation McBopomofoInputMethodController

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

- (id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)client
{
    // an instance is initialized whenever a text input client (a Mac app) requires
    // text input from an IME

    self = [super initWithServer:server delegate:delegate client:client];
    if (self) {
        // create the reading buffer
        _bpmfReadingBuffer = new BopomofoReadingBuffer(BopomofoKeyboardLayout::StandardLayout());

        // create the lattice builder
        _languageModel = [LanguageModelManager languageModelMcBopomofo];
        _languageModel->setPhraseReplacementEnabled(Preferences.phraseReplacementEnabled);
        _userOverrideModel = [LanguageModelManager userOverrideModel];

        _builder = new BlockReadingBuilder(_languageModel);

        // each Mandarin syllable is separated by a hyphen
        _builder->setJoinSeparator("-");


        _inputMode = kBopomofoModeIdentifier;
        _state = [[InputStateEmpty alloc] init];
    }

    return self;
}

- (NSMenu *)menu
{
    // a menu instance (autoreleased) is requested every time the user click on the input menu
    NSMenu *menu = [[NSMenu alloc] initWithTitle:LocalizationNotNeeded(@"Input Method Menu")];

    [menu addItemWithTitle:NSLocalizedString(@"McBopomofo Preferences", @"") action:@selector(showPreferences:) keyEquivalent:@""];

    NSMenuItem *chineseConversionMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Chinese Conversion", @"") action:@selector(toggleChineseConverter:) keyEquivalent:@"g"];
    chineseConversionMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagControl;
    chineseConversionMenuItem.state = Preferences.chineseConversionEnabled ? NSControlStateValueOn : NSControlStateValueOff;

    NSMenuItem *halfWidthPunctuationMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Use Half-Width Punctuations", @"") action:@selector(toggleHalfWidthPunctuation:) keyEquivalent:@""];
    halfWidthPunctuationMenuItem.state = Preferences.halfWidthPunctuationEnabled ? NSControlStateValueOn : NSControlStateValueOff;

    BOOL optionKeyPressed = [[NSEvent class] respondsToSelector:@selector(modifierFlags)] && ([NSEvent modifierFlags] & NSEventModifierFlagOption);

    if (_inputMode == kBopomofoModeIdentifier && optionKeyPressed) {
        NSMenuItem *phaseReplacementMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Use Phrase Replacement", @"") action:@selector(togglePhraseReplacementEnabled:) keyEquivalent:@""];
        phaseReplacementMenuItem.state = Preferences.phraseReplacementEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    }

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:NSLocalizedString(@"User Phrases", @"") action:NULL keyEquivalent:@""];
    if (_inputMode == kPlainBopomofoModeIdentifier) {
        NSMenuItem *editExcludedPhrasesItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Edit Excluded Phrases", @"") action:@selector(openExcludedPhrasesPlainBopomofo:) keyEquivalent:@""];
        [menu addItem:editExcludedPhrasesItem];
    } else {
        [menu addItemWithTitle:NSLocalizedString(@"Edit User Phrases", @"") action:@selector(openUserPhrases:) keyEquivalent:@""];
        [menu addItemWithTitle:NSLocalizedString(@"Edit Excluded Phrases", @"") action:@selector(openExcludedPhrasesMcBopomofo:) keyEquivalent:@""];
        if (optionKeyPressed) {
            [menu addItemWithTitle:NSLocalizedString(@"Edit Phrase Replacement Table", @"") action:@selector(openPhraseReplacementMcBopomofo:) keyEquivalent:@""];
        }
    }
    [menu addItemWithTitle:NSLocalizedString(@"Reload User Phrases", @"") action:@selector(reloadUserPhrases:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];

    [menu addItemWithTitle:NSLocalizedString(@"Check for Updates…", @"") action:@selector(checkForUpdate:) keyEquivalent:@""];
    [menu addItemWithTitle:NSLocalizedString(@"About McBopomofo…", @"") action:@selector(showAbout:) keyEquivalent:@""];
    return menu;
}

#pragma mark - IMKStateSetting protocol methods

- (void)activateServer:(id)client
{
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Override the keyboard layout. Use US if not set.
    NSString *basisKeyboardLayoutID = Preferences.basisKeyboardLayout;
    [client overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];

    // reset the state
    _currentDeferredClient = nil;
    _currentCandidateClient = nil;
    InputStateEmpty *newState = [[InputStateEmpty alloc] init];
    [self handleState:newState client:client];

    // checks and populates the default settings
    switch (Preferences.keyboardLayout) {
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

    [(AppDelegate * )[
    NSApp
    delegate] checkForUpdate];
}

- (void)deactivateServer:(id)client
{
    InputStateDeactive *newState = [[InputStateDeactive alloc] init];
    [self handleState:newState client:client];
}

- (void)setValue:(id)value forTag:(long)tag client:(id)sender
{
    NSString *newInputMode;
    McBopomofoLM *newLanguageModel;

    if ([value isKindOfClass:[NSString class]] && [value isEqual:kPlainBopomofoModeIdentifier]) {
        newInputMode = kPlainBopomofoModeIdentifier;
        newLanguageModel = [LanguageModelManager languageModelPlainBopomofo];
        newLanguageModel->setPhraseReplacementEnabled(false);
    } else {
        newInputMode = kBopomofoModeIdentifier;
        newLanguageModel = [LanguageModelManager languageModelMcBopomofo];
        newLanguageModel->setPhraseReplacementEnabled(Preferences.phraseReplacementEnabled);
    }
    newLanguageModel->setExternalConverterEnabled(Preferences.chineseConversionStyle == 1);

    // Only apply the changes if the value is changed
    if (![_inputMode isEqualToString:newInputMode]) {
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Remember to override the keyboard layout again -- treat this as an activate eventy
        NSString *basisKeyboardLayoutID = Preferences.basisKeyboardLayout;
        [sender overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];

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

        InputState *empty = [[InputState alloc] init];
        [self handleState:empty client:sender];

    }
}

#pragma  mark - IMKServerInput protocol methods

- (NSUInteger)recognizedEvents:(id)sender
{
    return NSKeyDownMask | NSFlagsChangedMask;
}

- (string)_currentLayout
{
    NSString *keyboardLayoutName = Preferences.keyboardLayoutName;
    string layout = string(keyboardLayoutName.UTF8String) + string("_");
    return layout;
}

- (BOOL)handleInput:(KeyHandlerInput *)input state:(InputState *)state stateCallback:(void (^)(InputState *))stateCallback candidateSelectionCallback:(void (^)(void))candidateSelectionCallback errorCallback:(void (^)(void))errorCallback
{
    // get the unicode character code
    UniChar charCode = input.charCode;
    uint16 keyCode = input.keyCode;

    NSEventModifierFlags flags = input.flags;
    McBopomofoEmacsKey emacsKey = input.emacsKey;

    // if the inputText is empty, it's a function key combination, we ignore it
    if (![input.inputText length]) {
        return NO;
    }

    // if the composing buffer is empty and there's no reading, and there is some function key combination, we ignore it
    BOOL isFunctionKey = ((flags & NSEventModifierFlagCommand) || (flags & NSEventModifierFlagControl) || (flags & NSEventModifierFlagOption) || (flags & NSEventModifierFlagNumericPad));
    if (![state isKindOfClass:[InputStateInputting class]] && isFunctionKey) {
        return NO;
    }

    // Caps Lock processing : if Caps Lock is on, temporarily disable bopomofo.
    if (charCode == 8 || charCode == 13 || keyCode == input.absorbedArrowKey || keyCode == input.extraChooseCandidateKey || keyCode == input.cursorForwardKey || keyCode == input.cursorBackwardKey) {
        // do nothing if backspace is pressed -- we ignore the key
    } else if (flags & NSAlphaShiftKeyMask) {
        // process all possible combination, we hope.
        InputStateEmpty *emptyState = [[InputStateEmpty alloc] init];
        stateCallback(emptyState);

        // first commit everything in the buffer.
        if (flags & NSEventModifierFlagShift) {
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

    if (flags & NSEventModifierFlagNumericPad) {
        if (keyCode != KeyCodeLeft && keyCode != KeyCodeRight && keyCode != KeyCodeDown && keyCode != KeyCodeUp && charCode != 32 && isprint(charCode)) {
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
        return [self _handleCandidateState:(InputStateChoosingCandidate *) state input:input stateCallback:stateCallback candidateSelectionCallback:candidateSelectionCallback errorCallback:errorCallback];
    }

    // MARK: Handle Marking
    if ([state isKindOfClass:[InputStateMarking class]]) {
        if ([self _handleMarkingState:(InputStateMarking *)state input:input stateCallback:stateCallback candidateSelectionCallback:candidateSelectionCallback errorCallback:errorCallback]) {
            return YES;
        }
    }

    bool composeReading = false;

    // MARK: Handle BPMF Keys
    // see if it's valid BPMF reading
    if (_bpmfReadingBuffer->isValidKey((char) charCode)) {
        _bpmfReadingBuffer->combineKey((char) charCode);

        // if we have a tone marker, we have to insert the reading to the
        // builder in other words, if we don't have a tone marker, we just
        // update the composing buffer
        composeReading = _bpmfReadingBuffer->hasToneMarker();
        if (!composeReading) {
            InputStateInputting *inputting = [self _buildInputtingState];
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
            InputStateInputting *inputting = [self _buildInputtingState];
            stateCallback(inputting);
            return YES;
        }

        // and insert it into the lattice
        _builder->insertReadingAtCursor(reading);

        // then walk the lattice
        NSString *poppedText = [self _popOverflowComposingTextAndWalk];

        // get user override model suggestion
        string overrideValue = (_inputMode == kPlainBopomofoModeIdentifier) ? "" :
                _userOverrideModel->suggest(_walkedNodes, _builder->cursorIndex(), [[NSDate date] timeIntervalSince1970]);

        if (!overrideValue.empty()) {
            size_t cursorIndex = [self _actualCandidateCursorIndex];
            vector<NodeAnchor> nodes = _builder->grid().nodesCrossingOrEndingAt(cursorIndex);
            double highestScore = FindHighestScore(nodes, kEpsilon);
            _builder->grid().overrideNodeScoreForSelectedCandidate(cursorIndex, overrideValue, highestScore);
        }

        // then update the text
        _bpmfReadingBuffer->clear();

        InputStateInputting *inputting = [self _buildInputtingState];
        inputting.poppedText = poppedText;
        stateCallback(inputting);

        if (_inputMode == kPlainBopomofoModeIdentifier) {
            InputStateChoosingCandidate *choosingCandidates = [self _buildCandidateState:inputting useVerticalMode:input.useVerticalMode];
            stateCallback(choosingCandidates);
        }

        // and tells the client that the key is consumed
        return YES;
    }

    // MARK: Space and Down
    // keyCode 125 = Down, charCode 32 = Space
    if (_bpmfReadingBuffer->isEmpty() &&
            [state isKindOfClass:[InputStateNotEmpty class]] &&
            (keyCode == input.extraChooseCandidateKey || charCode == 32 || (input.useVerticalMode && (keyCode == input.verticalModeOnlyChooseCandidateKey)))) {
        if (charCode == 32) {
            // if the spacebar is NOT set to be a selection key
            if ((flags & NSEventModifierFlagShift) != 0 || !Preferences.chooseCandidateUsingSpace) {
                if (_builder->cursorIndex() >= _builder->length()) {
                    _bpmfReadingBuffer->clear();
                    InputStateCommitting *commiting = [[InputStateCommitting alloc] initWithPoppedText:@" "];
                    stateCallback(commiting);
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    stateCallback(empty);
                } else if (_languageModel->hasUnigramsForKey(" ")) {
                    _builder->insertReadingAtCursor(" ");
                    NSString *poppedText = [self _popOverflowComposingTextAndWalk];
                    InputStateInputting *inputting = [self _buildInputtingState];
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
    if (keyCode == input.cursorBackwardKey || emacsKey == McBopomofoEmacsKeyBackward) {
        return [self _handleBackwardWithState:state flags:flags stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK:  Cursor forward
    if (keyCode == input.cursorForwardKey || emacsKey == McBopomofoEmacsKeyForward) {
        return [self _handleForwardWithState:state flags:flags stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Home
    if (keyCode == KeyCodeHome || emacsKey == McBopomofoEmacsKeyHome) {
        return [self _handleHomeWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: End
    if (keyCode == KeyCodeEnd || emacsKey == McBopomofoEmacsKeyEnd) {
        return [self _handleEndWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: AbsorbedArrowKey
    if (keyCode == input.absorbedArrowKey || keyCode == input.extraChooseCandidateKey) {
        return [self _handleAbsorbedArrowKeyWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Backspace
    if (charCode == 8) {
        return [self _handleBackspaceWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Delete
    if (keyCode == KeyCodeDelete || emacsKey == McBopomofoEmacsKeyDelete) {
        return [self _handleDeleteWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Enter
    if (charCode == 13) {
        return [self _handleEnterWithState:state stateCallback:stateCallback errorCallback:errorCallback];
    }

    // MARK: Punctuation list
    if ((char) charCode == '`') {
        if ([self _handlePunctuation:string("_punctuation_list") state:state usingVerticalMode:input.useVerticalMode stateCallback:stateCallback errorCallback:errorCallback]) {
            return YES;
        }
    }

    // MARK: Punctuation
    // if nothing is matched, see if it's a punctuation key for current layout.
    string layout = [self _currentLayout];
    string punctuationNamePrefix = Preferences.halfWidthPunctuationEnabled ? string("_half_punctuation_") : string("_punctuation_");
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
        // if the optioon is enabled, we clear everythiong including the composing
        // buffer, walked nodes and the reading.
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
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
            InputStateInputting *inputting = [self _buildInputtingState];
            stateCallback(inputting);
        }
    }
    return YES;
}

- (BOOL)_handleBackwardWithState:(InputState *)state flags:(NSEventModifierFlags)flags stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
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

    if (flags & NSEventModifierFlagShift) {
        // Shift + left
        if (_builder->cursorIndex() > 0) {
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex markerIndex:currentState.cursorIndex - 1];
            marking.readings = [self _currentReadings];
            stateCallback(marking);
        } else {
            errorCallback();
            stateCallback(state);
        }
    } else {
        if (_builder->cursorIndex() > 0) {
            _builder->setCursorIndex(_builder->cursorIndex() - 1);
            InputStateInputting *inputting = [self _buildInputtingState];
            stateCallback(inputting);
        } else {
            errorCallback();
            stateCallback(state);
        }
    }
    return YES;
}

- (BOOL)_handleForwardWithState:(InputState *)state flags:(NSEventModifierFlags)flags stateCallback:(void (^)(InputState *))stateCallback errorCallback:(void (^)(void))errorCallback
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
    if (flags & NSEventModifierFlagShift) {
        // Shift + Right
        if (_builder->cursorIndex() < _builder->length()) {
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:currentState.composingBuffer cursorIndex:currentState.cursorIndex markerIndex:currentState.cursorIndex + 1];
            marking.readings = [self _currentReadings];
            stateCallback(marking);
        } else {
            errorCallback();
            stateCallback(state);
        }
    } else {
        if (_builder->cursorIndex() < _builder->length()) {
            _builder->setCursorIndex(_builder->cursorIndex() + 1);
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
        InputStateInputting *inputting = [self _buildInputtingState];
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
        InputStateInputting *inputting = [self _buildInputtingState];
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

    InputStateInputting *inputting = [self _buildInputtingState];
    stateCallback(inputting);
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
            InputStateInputting *inputting = [self _buildInputtingState];
            stateCallback(inputting);
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
        InputStateInputting *current = (InputStateInputting *) state;
        NSString *composingBuffer = current.composingBuffer;
        InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
        stateCallback(committing);
        InputState *empty = [[InputState alloc] init];
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

    NSString *poppedText = @"";
    if (_bpmfReadingBuffer->isEmpty()) {
        _builder->insertReadingAtCursor(customPunctuation);
        poppedText = [self _popOverflowComposingTextAndWalk];
    } else { // If there is still unfinished bpmf reading, ignore the punctuation
        errorCallback();
        stateCallback(state);
        return YES;
    }
    InputStateInputting *inputting = [self _buildInputtingState];
    inputting.poppedText = poppedText;
    stateCallback(inputting);

    if (_inputMode == kPlainBopomofoModeIdentifier && _bpmfReadingBuffer->isEmpty()) {
        InputStateChoosingCandidate *candidateState = [self _buildCandidateState:inputting useVerticalMode:useVerticalMode];

        if ([candidateState.candidates count] == 1) {
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
    if (input.charCode == 27) {
        InputStateInputting *inputting = [self _buildInputtingState];
        stateCallback(inputting);
        return YES;
    }
    // Enter
    if (input.charCode == 13) {
        if (![self _writeUserPhrase]) {
            errorCallback();
            return YES;
        }
        InputStateInputting *inputting = [self _buildInputtingState];
        stateCallback(inputting);
        return YES;
    }
    // Shift + left
    if ((input.keyCode == input.cursorBackwardKey || input.emacsKey == McBopomofoEmacsKeyBackward)
        && (input.flags & NSEventModifierFlagShift)) {
        NSUInteger index = state.markerIndex;
        if (index > 0) {
            index -= 1;
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:state.composingBuffer cursorIndex:state.cursorIndex markerIndex:index];
            marking.readings = state.readings;
            stateCallback(marking);
        } else {
            stateCallback(state);
            errorCallback();
        }
        return YES;
    }
    // Shift + Right
    if ((input.keyCode == input.cursorForwardKey || input.emacsKey == McBopomofoEmacsKeyForward)
        && (input.flags & NSEventModifierFlagShift)) {
        NSUInteger index = state.markerIndex;
        if (index < state.composingBuffer.length) {
            index += 1;
            InputStateMarking *marking = [[InputStateMarking alloc] initWithComposingBuffer:state.composingBuffer cursorIndex:state.cursorIndex markerIndex:index];
            marking.readings = state.readings;
            stateCallback(marking);
        } else {
            stateCallback(state);
            errorCallback();
        }
        return YES;
    }
    return NO;
}


- (BOOL)_handleCandidateState:(InputStateChoosingCandidate *)state
                        input:(KeyHandlerInput *)input
                stateCallback:(void (^)(InputState *))stateCallback
   candidateSelectionCallback:(void (^)(void))candidateSelectionCallback
                errorCallback:(void (^)(void))errorCallback;
{
    NSString *inputText = input.inputText;
    UniChar charCode = input.charCode;
    uint16 keyCode = input.keyCode;
    McBopomofoEmacsKey emacsKey = input.emacsKey;

    BOOL cancelCandidateKey =
            (charCode == 27) ||
                    ((_inputMode == kPlainBopomofoModeIdentifier) &&
                            (charCode == 8 || keyCode == KeyCodeDelete));

    if (cancelCandidateKey) {
        if (_inputMode == kPlainBopomofoModeIdentifier) {
            _builder->clear();
            _walkedNodes.clear();
        }
        InputState *inputting = [self _buildInputtingState];
        stateCallback(inputting);
        return YES;
    } else if (charCode == 13 || keyCode == KeyCodeEnter) {
        [self candidateController:gCurrentCandidateController didSelectCandidateAtIndex:gCurrentCandidateController.selectedCandidateIndex];
        return YES;
    } else if (charCode == 32 || keyCode == KeyCodePageDown || emacsKey == McBopomofoEmacsKeyNextPage) {
        BOOL updated = [gCurrentCandidateController showNextPage];
        if (!updated) {
            errorCallback();
        }
        candidateSelectionCallback();
        return YES;
    } else if (keyCode == KeyCodePageUp) {
        BOOL updated = [gCurrentCandidateController showPreviousPage];
        if (!updated) {
            errorCallback();
        }
        candidateSelectionCallback();
        return YES;
    } else if (keyCode == KeyCodeLeft) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        } else {
            BOOL updated = [gCurrentCandidateController showPreviousPage];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        }
    } else if (emacsKey == McBopomofoEmacsKeyBackward) {
        BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
        if (!updated) {
            errorCallback();
        }
        candidateSelectionCallback();
        return YES;
    } else if (keyCode == KeyCodeRight) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController highlightNextCandidate];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        } else {
            BOOL updated = [gCurrentCandidateController showNextPage];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        }
    } else if (emacsKey == McBopomofoEmacsKeyForward) {
        BOOL updated = [gCurrentCandidateController highlightNextCandidate];
        if (!updated) {
            errorCallback();
        }
        candidateSelectionCallback();
        return YES;
    } else if (keyCode == KeyCodeUp) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController showPreviousPage];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        } else {
            BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        }
    } else if (keyCode == KeyCodeDown) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController showNextPage];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        } else {
            BOOL updated = [gCurrentCandidateController highlightNextCandidate];
            if (!updated) {
                errorCallback();
            }
            candidateSelectionCallback();
            return YES;
        }
    } else if (keyCode == KeyCodeHome || emacsKey == McBopomofoEmacsKeyHome) {
        if (gCurrentCandidateController.selectedCandidateIndex == 0) {
            errorCallback();
        } else {
            gCurrentCandidateController.selectedCandidateIndex = 0;
        }

        candidateSelectionCallback();
        return YES;
    } else if ((keyCode == KeyCodeEnd || emacsKey == McBopomofoEmacsKeyEnd) && [state.candidates count] > 0) {
        if (gCurrentCandidateController.selectedCandidateIndex == [state.candidates count] - 1) {
            errorCallback();
        } else {
            gCurrentCandidateController.selectedCandidateIndex = [state.candidates count] - 1;
        }

        candidateSelectionCallback();
        return YES;
    } else {
        NSInteger index = NSNotFound;
        for (NSUInteger j = 0, c = [gCurrentCandidateController.keyLabels count]; j < c; j++) {
            if ([inputText compare:[gCurrentCandidateController.keyLabels objectAtIndex:j] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                index = j;
                break;
            }
        }

        [gCurrentCandidateController.keyLabels indexOfObject:inputText];
        if (index != NSNotFound) {
            NSUInteger candidateIndex = [gCurrentCandidateController candidateIndexAtKeyLabelIndex:index];
            if (candidateIndex != NSUIntegerMax) {
                [self candidateController:gCurrentCandidateController didSelectCandidateAtIndex:candidateIndex];
                return YES;
            }
        }

        if (_inputMode == kPlainBopomofoModeIdentifier) {
            string layout = [self _currentLayout];
            string customPunctuation = string("_punctuation_") + layout + string(1, (char) charCode);
            string punctuation = string("_punctuation_") + string(1, (char) charCode);

            BOOL shouldAutoSelectCandidate = _bpmfReadingBuffer->isValidKey((char) charCode) || _languageModel->hasUnigramsForKey(customPunctuation) ||
                    _languageModel->hasUnigramsForKey(punctuation);

            if (shouldAutoSelectCandidate) {
                NSUInteger candidateIndex = [gCurrentCandidateController candidateIndexAtKeyLabelIndex:0];
                if (candidateIndex != NSUIntegerMax) {
                    [self candidateController:gCurrentCandidateController didSelectCandidateAtIndex:candidateIndex];
                    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
                    [self handleInput:input state:empty stateCallback:stateCallback candidateSelectionCallback:candidateSelectionCallback errorCallback:errorCallback];
                }
                return YES;
            }
        }

        errorCallback();
        candidateSelectionCallback();
        return YES;
    }
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)client
{
    if ([event type] == NSFlagsChanged) {
        NSString *functionKeyKeyboardLayoutID = Preferences.functionKeyboardLayout;
        NSString *basisKeyboardLayoutID = Preferences.basisKeyboardLayout;

        // If no override is needed, just return NO.
        if ([functionKeyKeyboardLayoutID isEqualToString:basisKeyboardLayoutID]) {
            return NO;
        }

        // Function key pressed.
        BOOL includeShift = Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey;
        if (([event modifierFlags] & ~NSEventModifierFlagShift) || (([event modifierFlags] & NSEventModifierFlagShift) && includeShift)) {
            // Override the keyboard layout and let the OS do its thing
            [client overrideKeyboardWithKeyboardNamed:functionKeyKeyboardLayoutID];
            return NO;
        }

        // Revert back to the basis layout when the function key is released
        [client overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];
        return NO;
    }

    NSRect textFrame = NSZeroRect;
    NSDictionary *attributes = nil;
    BOOL useVerticalMode = NO;

    @try {
        attributes = [client attributesForCharacterIndex:0 lineHeightRectangle:&textFrame];
        useVerticalMode = [attributes objectForKey:@"IMKTextOrientation"] && [[attributes objectForKey:@"IMKTextOrientation"] integerValue] == 0;
    }
    @catch (NSException *e) {
        // exception may raise while using Twitter.app's search filed.
    }

    if ([[client bundleIdentifier] isEqualToString:@"com.apple.Terminal"] && [NSStringFromClass([client class]) isEqualToString:@"IPMDServerClientWrapper"]) {
        // special handling for com.apple.Terminal
        _currentDeferredClient = client;
    }

    KeyHandlerInput *input = [[KeyHandlerInput alloc] initWithEvent:event isVerticalMode:useVerticalMode];
    BOOL result = [self handleInput:input state:_state stateCallback:^(InputState *state) {
        [self handleState:state client:client];
    } candidateSelectionCallback:^{
        [self handleState:self->_state client:(self->_currentCandidateClient ? self->_currentCandidateClient : client)];
    } errorCallback:^{
        NSBeep();
    }];

    return result;
}

#pragma mark - States Building

- (InputStateInputting *)_buildInputtingState
{
    // "updating the composing buffer" means to request the client to "refresh" the text input buffer
    // with our "composing text"
    NSMutableString *composingBuffer = [[NSMutableString alloc] init];
    NSInteger composedStringCursorIndex = 0;

    size_t readingCursorIndex = 0;
    size_t builderCursorIndex = _builder->cursorIndex();

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

            // this re-aligns the cursor index in the composed string
            // (the actual cursor on the screen) with the builder's logical
            // cursor (reading) cursor; each built node has a "spanning length"
            // (e.g. two reading blocks has a spanning length of 2), and we
            // accumulate those lengthes to calculate the displayed cursor
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
    // lose their influence over the whole MLE anyway -- so tht when
    // the user type along, the already composed text at front will
    // be popped out

    NSString *poppedText = @"";
    NSInteger composingBufferSize = Preferences.composingBufferSize;

    if (_builder->grid().width() > (size_t) composingBufferSize) {
        if (_walkedNodes.size() > 0) {
            NodeAnchor &anchor = _walkedNodes[0];
            poppedText = [NSString stringWithUTF8String:anchor.node->currentKeyValue().value.c_str()];
            // Chinese conversion.
            poppedText = [self _convertToSimplifiedChineseIfRequired:poppedText];
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
    for(vector<std::string>::iterator it_i=v.begin(); it_i!=v.end(); ++it_i) {
        [readingsArray addObject:[NSString stringWithUTF8String:it_i->c_str()]];
    }
    return readingsArray;
}

#pragma mark - States Handling

- (NSString *)_convertToSimplifiedChineseIfRequired:(NSString *)text
{
    if (!Preferences.chineseConversionEnabled) {
        return text;
    }

    if (Preferences.chineseConversionStyle == 1) {
        return text;
    }

    if (Preferences.chineseConversionEngine == 1) {
        return [VXHanConvert convertToSimplifiedFrom:text];
    }

    return [OpenCCBridge convertToSimplified:text];
}

- (void)_commitText:(NSString *)text client:(id)client
{
    NSString *buffer = [self _convertToSimplifiedChineseIfRequired:text];
    if (!buffer.length) {
        return;;
    }

    // if it's Terminal, we don't commit at the first call (the client of which will not be IPMDServerClientWrapper)
    // then we defer the update in the next runloop round -- so that the composing buffer is not
    // meaninglessly flushed, an annoying bug in Terminal.app since Mac OS X 10.5
    if ([[client bundleIdentifier] isEqualToString:@"com.apple.Terminal"] && ![NSStringFromClass([client class]) isEqualToString:@"IPMDServerClientWrapper"]) {
        if (_currentDeferredClient) {
            id currentDeferredClient = _currentDeferredClient;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [currentDeferredClient insertText:buffer replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
            });
        }
        return;
    }
    [client insertText:buffer replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

- (void)handleState:(InputState *)newState client:(id)client
{
    NSLog(@"current state: %@ new state: %@", _state, newState );
    
    if ([newState isKindOfClass:[InputStateDeactive class]]) {
        [self _handleInputStateDeactive:(InputStateDeactive *) newState previous:_state client:client];
    }

    if ([newState isKindOfClass:[InputStateEmpty class]]) {
        [self _handleInputStateEmpty:(InputStateEmpty *) newState previous:_state client:client];
    }

    if ([newState isKindOfClass:[InputStateCommitting class]]) {
        [self _handleInputStateCommitting:(InputStateCommitting *) newState previous:_state client:client];
    }

    if ([newState isKindOfClass:[InputStateInputting class]]) {
        [self _handleInputStateInputting:(InputStateInputting *) newState previous:_state client:client];
    }

    if ([newState isKindOfClass:[InputStateMarking class]]) {
        [self _handleInputStateMarking:(InputStateMarking *) newState previous:_state client:client];
    }

    if ([newState isKindOfClass:[InputStateChoosingCandidate class]]) {
        [self _handleInputStateChoosingCandidate:(InputStateChoosingCandidate *)newState previous:_state client:client];
    }

    _state = newState;
}

- (void)_handleInputStateDeactive:(InputStateDeactive *)state previous:(InputState *)previous client:(id)client
{
    // clean up reading buffer residues
    if (!_bpmfReadingBuffer->isEmpty()) {
        _bpmfReadingBuffer->clear();
        [client setMarkedText:@"" selectionRange:NSMakeRange(0, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    }

    // commit any residue in the composing buffer
    if ([previous isKindOfClass:[InputStateInputting class]]) {
        NSString *buffer = [(InputStateInputting *) _state composingBuffer];
        [self _commitText:buffer client:client];
    }

    _currentDeferredClient = nil;
    _currentCandidateClient = nil;

    gCurrentCandidateController.delegate = nil;
    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleInputStateEmpty:(InputStateEmpty *)state previous:(InputState *)previous client:(id)client
{
    // commit any residue in the composing buffer
    if ([previous isKindOfClass:[InputStateInputting class]]) {
        NSString *buffer = [(InputStateInputting *) _state composingBuffer];
        [self _commitText:buffer client:client];
    }

    _builder->clear();
    _walkedNodes.clear();
    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleInputStateCommitting:(InputStateCommitting *)state previous:(InputState *)previous client:(id)client
{
    NSString *poppedText = [state poppedText];
    [self _commitText:poppedText client:client];

    _builder->clear();
    _walkedNodes.clear();
    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleInputStateInputting:(InputStateInputting *)state previous:(InputState *)previous client:(id)client
{
    NSString *poppedText = state.poppedText;
    if (poppedText.length) {
        [self _commitText:poppedText client:client];
    }

    NSUInteger cursorIndex = [state cursorIndex];
    NSAttributedString *attrString = [state attributedString];

    // the selection range is where the cursor is, with the length being 0 and replacement range NSNotFound,
    // i.e. the client app needs to take care of where to put ths composing buffer
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursorIndex, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleInputStateMarking:(InputStateMarking *)state previous:(InputState *)previous client:(id)client
{
    NSUInteger cursorIndex = [state cursorIndex];
    NSAttributedString *attrString = [state attributedString];

    // the selection range is where the cursor is, with the length being 0 and replacement range NSNotFound,
    // i.e. the client app needs to take care of where to put ths composing buffer
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursorIndex, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    gCurrentCandidateController.visible = NO;
    [self _showTooltip:state.tooltip composingBuffer:state.composingBuffer client:client];
}

- (void)_handleInputStateChoosingCandidate:(InputStateChoosingCandidate *)state previous:(InputState *)previous client:(id)client
{
    NSUInteger cursorIndex = [state cursorIndex];
    NSAttributedString *attrString = [state attributedString];

    // the selection range is where the cursor is, with the length being 0 and replacement range NSNotFound,
    // i.e. the client app needs to take care of where to put ths composing buffer
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursorIndex, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    if (_inputMode == kPlainBopomofoModeIdentifier && [state.candidates count] == 1) {
        NSString *buffer = [self _convertToSimplifiedChineseIfRequired:state.candidates.firstObject];
        [client insertText:buffer replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
        [self handleState:empty client:client];
        return;
    } else {
        if (![_state isKindOfClass:[InputStateChoosingCandidate class]]) {
            [self _showCandidateWindowWithState:state client:client];
        }
    }
}

- (void)_showCandidateWindowWithState:(InputStateChoosingCandidate *)state client:(id)client
{
    // set the candidate panel style
    BOOL useVerticalMode = state.useVerticalMode;

    if (useVerticalMode) {
        gCurrentCandidateController = [McBopomofoInputMethodController verticalCandidateController];
    } else if (Preferences.useHorizontalCandidateList) {
        gCurrentCandidateController = [McBopomofoInputMethodController horizontalCandidateController];
    } else {
        gCurrentCandidateController = [McBopomofoInputMethodController verticalCandidateController];
    }

    // set the attributes for the candidate panel (which uses NSAttributedString)
    NSInteger textSize = Preferences.candidateListTextSize;

    NSInteger keyLabelSize = textSize / 2;
    if (keyLabelSize < kMinKeyLabelSize) {
        keyLabelSize = kMinKeyLabelSize;
    }

    NSString *ctFontName = Preferences.candidateTextFontName;
    NSString *klFontName = Preferences.candidateKeyLabelFontName;
    NSString *ckeys = Preferences.candidateKeys;

    gCurrentCandidateController.keyLabelFont = klFontName ? [NSFont fontWithName:klFontName size:keyLabelSize] : [NSFont systemFontOfSize:keyLabelSize];
    gCurrentCandidateController.candidateFont = ctFontName ? [NSFont fontWithName:ctFontName size:textSize] : [NSFont systemFontOfSize:textSize];

    NSMutableArray *keyLabels = [NSMutableArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil];

    if ([ckeys length] > 1) {
        [keyLabels removeAllObjects];
        for (NSUInteger i = 0, c = [ckeys length]; i < c; i++) {
            [keyLabels addObject:[ckeys substringWithRange:NSMakeRange(i, 1)]];
        }
    }

    gCurrentCandidateController.keyLabels = keyLabels;

    gCurrentCandidateController.delegate = self;
    [gCurrentCandidateController reloadData];

    // update the composing text, set the client
    NSInteger cursor = 0;

    //    NSInteger cursor = _latestReadingCursor;
    if ([state respondsToSelector:@selector(cursorIndex)]) {
        cursor = [[state performSelector:@selector(cursorIndex)] integerValue];
    }

    NSAttributedString *attrString = [state attributedString];
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursor, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    _currentCandidateClient = client;

    NSRect lineHeightRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);

    if (cursor == [state.composingBuffer length] && cursor != 0) {
        cursor--;
    }

    // some apps (e.g. Twitter for Mac's search bar) handle this call incorrectly, hence the try-catch
    @try {
        [client attributesForCharacterIndex:cursor lineHeightRectangle:&lineHeightRect];
    }
    @catch (NSException *exception) {
        NSLog(@"lineHeightRectangle %@", exception);
    }

    if (useVerticalMode) {
        [gCurrentCandidateController setWindowTopLeftPoint:NSMakePoint(lineHeightRect.origin.x + lineHeightRect.size.width + 4.0, lineHeightRect.origin.y - 4.0) bottomOutOfScreenAdjustmentHeight:lineHeightRect.size.height + 4.0];
    } else {
        [gCurrentCandidateController setWindowTopLeftPoint:NSMakePoint(lineHeightRect.origin.x, lineHeightRect.origin.y - 4.0) bottomOutOfScreenAdjustmentHeight:lineHeightRect.size.height + 4.0];
    }

    gCurrentCandidateController.visible = YES;

}

#pragma mark - User phrases


- (BOOL)_writeUserPhrase
{
    return NO;
//    NSString *currentMarkedPhrase = [self _currentMarkedTextAndReadings];
//    if (![currentMarkedPhrase length]) {
//        [self beep];
//        return NO;
//    }

//    return [LanguageModelManager writeUserPhrase:currentMarkedPhrase];
}



#pragma mark - Misc menu items

- (void)showPreferences:(id)sender
{
    // show the preferences panel, and also make the IME app itself the focus
    if ([IMKInputController instancesRespondToSelector:@selector(showPreferences:)]) {
        [super showPreferences:sender];
    } else {
        [(AppDelegate * )[
        NSApp
        delegate] showPreferences];
    }
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)toggleChineseConverter:(id)sender
{
    BOOL chineseConversionEnabled = [Preferences toggleChineseConversionEnabled];
    [NotifierController                                  notifyWithMessage:
            chineseConversionEnabled ?
                    NSLocalizedString(@"Chinese conversion on", @"") :
                    NSLocalizedString(@"Chinese conversion off", @"") stay:NO];
}

- (void)toggleHalfWidthPunctuation:(id)sender
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
    [Preferences toggleHalfWidthPunctuationEnabled];
#pragma GCC diagnostic pop
}

- (void)togglePhraseReplacementEnabled:(id)sender
{
    BOOL enabled = [Preferences togglePhraseReplacementEnabled];
    McBopomofoLM *lm = [LanguageModelManager languageModelMcBopomofo];
    lm->setPhraseReplacementEnabled(enabled);
}

- (void)checkForUpdate:(id)sender
{
    [(AppDelegate * )[[NSApplication sharedApplication] delegate] checkForUpdateForced:YES];
}

- (BOOL)_checkUserFiles
{
    if (![LanguageModelManager checkIfUserLanguageModelFilesExist]) {
        NSString *content = [NSString stringWithFormat:NSLocalizedString(@"Please check the permission of at \"%@\".", @""), [LanguageModelManager dataFolderPath]];
        [[NonModalAlertWindowController sharedInstance] showWithTitle:NSLocalizedString(@"Unable to create the user phrase file.", @"") content:content confirmButtonTitle:NSLocalizedString(@"OK", @"") cancelButtonTitle:nil cancelAsDefault:NO delegate:nil];
        return NO;
    }

    return YES;
}

- (void)_openUserFile:(NSString *)path
{
    if (![self _checkUserFiles]) {
        return;
    }
    NSURL *url = [NSURL fileURLWithPath:path];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)openUserPhrases:(id)sender
{
    [self _openUserFile:[LanguageModelManager userPhrasesDataPathMcBopomofo]];
}

- (void)openExcludedPhrasesPlainBopomofo:(id)sender
{
    [self _openUserFile:[LanguageModelManager excludedPhrasesDataPathPlainBopomofo]];
}

- (void)openExcludedPhrasesMcBopomofo:(id)sender
{
    [self _openUserFile:[LanguageModelManager excludedPhrasesDataPathMcBopomofo]];
}

- (void)openPhraseReplacementMcBopomofo:(id)sender
{
    [self _openUserFile:[LanguageModelManager phraseReplacementDataPathMcBopomofo]];
}

- (void)reloadUserPhrases:(id)sender
{
    [LanguageModelManager loadUserPhrases];
    [LanguageModelManager loadUserPhraseReplacement];
}

- (void)showAbout:(id)sender
{
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}


@end

#pragma mark -

@implementation McBopomofoInputMethodController (VTCandidateController)

- (NSUInteger)candidateCountForController:(VTCandidateController *)controller
{
    if ([_state isKindOfClass:[InputStateChoosingCandidate class]]) {
        InputStateChoosingCandidate *state = (InputStateChoosingCandidate *) _state;
        return state.candidates.count;
    }
    return 0;
}

- (NSString *)candidateController:(VTCandidateController *)controller candidateAtIndex:(NSUInteger)index
{
    if ([_state isKindOfClass:[InputStateChoosingCandidate class]]) {
        InputStateChoosingCandidate *state = (InputStateChoosingCandidate *) _state;
        return state.candidates[index];
    }
    return @"";
}

- (void)candidateController:(VTCandidateController *)controller didSelectCandidateAtIndex:(NSUInteger)index
{
    gCurrentCandidateController.visible = NO;

    if ([_state isKindOfClass:[InputStateChoosingCandidate class]]) {
        InputStateChoosingCandidate *state = (InputStateChoosingCandidate *) _state;

        // candidate selected, override the node with selection
        string selectedValue = [[state.candidates objectAtIndex:index] UTF8String];

        size_t cursorIndex = [self _actualCandidateCursorIndex];
        _builder->grid().fixNodeSelectedCandidate(cursorIndex, selectedValue);
        if (_inputMode != kPlainBopomofoModeIdentifier) {
            _userOverrideModel->observe(_walkedNodes, cursorIndex, selectedValue, [[NSDate date] timeIntervalSince1970]);
        }

        [self _walk];

        InputStateInputting *inputting = [self _buildInputtingState];

        if (_inputMode == kPlainBopomofoModeIdentifier) {
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:inputting.composingBuffer];
            [self handleState:committing client:_currentCandidateClient];
            InputStateEmpty *empty = [[InputStateEmpty alloc] init];
            [self handleState:empty client:_currentCandidateClient];
        } else {
            [self handleState:inputting client:_currentCandidateClient];
        }
    }
}

@end

@implementation McBopomofoInputMethodController (UI)

+ (VTHorizontalCandidateController *)horizontalCandidateController
{
    static VTHorizontalCandidateController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VTHorizontalCandidateController alloc] init];
    });
    return instance;
}

+ (VTVerticalCandidateController *)verticalCandidateController
{
    static VTVerticalCandidateController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[VTVerticalCandidateController alloc] init];
    });
    return instance;
}

+ (TooltipController *)tooltipController
{
    static TooltipController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TooltipController alloc] init];
    });
    return instance;
}

- (void)_showTooltip:(NSString *)tooltip composingBuffer:(NSString *)composingBuffer client:(id)client
{
    NSRect lineHeightRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);

    NSInteger cursor = 0;
    if ([_state respondsToSelector:@selector(cursorIndex)]) {
        cursor = [[_state performSelector:@selector(cursorIndex)] integerValue];
    }

    if (cursor == [composingBuffer length] && cursor != 0) {
        cursor--;
    }

    // some apps (e.g. Twitter for Mac's search bar) handle this call incorrectly, hence the try-catch
    @try {
        [client attributesForCharacterIndex:cursor lineHeightRectangle:&lineHeightRect];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }

    [[McBopomofoInputMethodController tooltipController] showTooltip:tooltip atPoint:lineHeightRect.origin];
}

- (void)_hideTooltip
{
    if ([McBopomofoInputMethodController tooltipController].window.isVisible) {
        [[McBopomofoInputMethodController tooltipController] hide];
    }
}

@end

