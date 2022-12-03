//
// InputMethodController.m
//
// Copyright (c) 2011 The McBopomofo Project.
//
// Contributors:
//     Mengjuei Hsieh (@mjhsieh)
//     Weizhong Yang (@zonble)
//
// Based on the Syrup Project and the Formosana Library
// by Lukhnos Liu (@lukhnos).
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
//

#import "InputMethodController.h"
#import <fstream>
#import <iostream>
#import <set>
#import "OVStringHelper.h"
#import "OVUTF8Helper.h"
#import "AppDelegate.h"
#import "VTHorizontalCandidateController.h"
#import "VTVerticalCandidateController.h"

// C++ namespace usages
using namespace std;
using namespace Formosa::Mandarin;
using namespace Formosa::Gramambular;
using namespace OpenVanilla;

// default, min and max candidate list text size
static const NSInteger kDefaultCandidateListTextSize = 16;
static const NSInteger kMinKeyLabelSize = 10;
static const NSInteger kMinCandidateListTextSize = 12;
static const NSInteger kMaxCandidateListTextSize = 196;

// default, min and max composing buffer size (in codepoints)
// modern Macs can usually work up to 16 codepoints when the builder still
// walks the grid with good performance; slower Macs (like old PowerBooks)
// will start to sputter beyond 12; such is the algorithmatic complexity
// of the Viterbi algorithm used in the builder library (at O(N^2))
static const NSInteger kDefaultComposingBufferSize = 10;
static const NSInteger kMinComposingBufferSize = 4;
static const NSInteger kMaxComposingBufferSize = 20;

// user defaults (app perferences) key names; in this project we use
// NSUserDefaults throughout and do not wrap them in another config object
static NSString *const kKeyboardLayoutPreferenceKey = @"KeyboardLayout";
static NSString *const kBasisKeyboardLayoutPreferenceKey = @"BasisKeyboardLayout";  // alphanumeric ("ASCII") input basis
static NSString *const kFunctionKeyKeyboardLayoutPreferenceKey = @"FunctionKeyKeyboardLayout";  // alphanumeric ("ASCII") input basis
static NSString *const kFunctionKeyKeyboardLayoutOverrideIncludeShiftKey = @"FunctionKeyKeyboardLayoutOverrideIncludeShift"; // whether include shift
static NSString *const kCandidateListTextSizeKey = @"CandidateListTextSize";
static NSString *const kSelectPhraseAfterCursorAsCandidatePreferenceKey = @"SelectPhraseAfterCursorAsCandidate";
static NSString *const kUseHorizontalCandidateListPreferenceKey = @"UseHorizontalCandidateList";
static NSString *const kComposingBufferSizePreferenceKey = @"ComposingBufferSize";
static NSString *const kDisableUserCandidateSelectionLearning = @"DisableUserCandidateSelectionLearning";
static NSString *const kChooseCandidateUsingSpaceKey = @"ChooseCandidateUsingSpaceKey";

// advanced (usually optional) settings
static NSString *const kCandidateTextFontName = @"CandidateTextFontName";
static NSString *const kCandidateKeyLabelFontName = @"CandidateKeyLabelFontName";
static NSString *const kCandidateKeys = @"CandidateKeys";

// input modes
static NSString *const kBopomofoModeIdentifier = @"org.openvanilla.inputmethod.McBopomofo.Bopomofo";
static NSString *const kPlainBopomofoModeIdentifier = @"org.openvanilla.inputmethod.McBopomofo.PlainBopomofo";

// key code enums
enum {
    kEnterKeyCode = 76,
    kUpKeyCode = 126,
    kDownKeyCode = 125,
    kLeftKeyCode = 123,
    kRightKeyCode = 124,
    kPageUpKeyCode = 116,
    kPageDownKeyCode = 121,
    kHomeKeyCode = 115,
    kEndKeyCode = 119,
    kDeleteKeyCode = 117
};

// a global object for saving the "learned" user candidate selections
NSMutableDictionary *gCandidateLearningDictionary = nil;
NSString *gUserCandidatesDictionaryPath = nil;
VTCandidateController *gCurrentCandidateController = nil;

// if DEBUG is defined, a DOT file (GraphViz format) will be written to the
// specified path everytime the grid is walked
#if DEBUG
static NSString *const kGraphVizOutputfile = @"/tmp/McBopomofo-visualization.dot";
#endif

// shared language model object that stores our phrase-term probability database
FastLM gLanguageModel;
FastLM gLanguageModelPlainBopomofo;

// private methods
@interface McBopomofoInputMethodController () <VTCandidateControllerDelegate>
+ (VTHorizontalCandidateController *)horizontalCandidateController;
+ (VTVerticalCandidateController *)verticalCandidateController;

- (void)collectCandidates;

- (size_t)actualCandidateCursorIndex;
- (NSString *)neighborTrigramString;

- (void)_performDeferredSaveUserCandidatesDictionary;
- (void)saveUserCandidatesDictionary;
- (void)_showCandidateWindowUsingVerticalMode:(BOOL)useVerticalMode client:(id)client;

- (void)beep;
- (BOOL)handleInputText:(NSString*)inputText key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)client;
- (BOOL)handleCandidateEventWithInputText:(NSString *)inputText charCode:(UniChar)charCode keyCode:(NSUInteger)keyCode;

- (void)showAbout:(id)sender;
- (void)updateClientComposingBuffer:(id)client;
@end

// sort helper
class NodeAnchorDescendingSorter
{
public:
    bool operator()(const NodeAnchor& a, const NodeAnchor &b) const {
        return a.node->key().length() > b.node->key().length();
    }
};

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

    [_composingBuffer release];

    [_candidates release];

    // the two client pointers are weak pointers (i.e. we don't retain them)
    // therefore we don't do anything about it

    [super dealloc];
}

- (id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)client
{
    // an instance is initialized whenever a text input client (a Mac app) requires
    // text input from an IME

    self = [super initWithServer:server delegate:delegate client:client];
    if (self) {
        _candidates = [[NSMutableArray alloc] init];

        // create the reading buffer
        _bpmfReadingBuffer = new BopomofoReadingBuffer(BopomofoKeyboardLayout::StandardLayout());

        // create the lattice builder
        _languageModel = &gLanguageModel;
        _builder = new BlockReadingBuilder(_languageModel);

        // each Mandarin syllable is separated by a hyphen
        _builder->setJoinSeparator("-");

        // create the composing buffer
        _composingBuffer = [[NSMutableString alloc] init];

        // populate the settings, by default, DISABLE user candidate learning
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kDisableUserCandidateSelectionLearning]) {
            [[NSUserDefaults standardUserDefaults] setObject:(id)kCFBooleanTrue forKey:kDisableUserCandidateSelectionLearning];
        }

        _inputMode = kBopomofoModeIdentifier;
    }

    return self;
}

- (NSMenu *)menu
{
    // a menu instance (autoreleased) is requested every time the user click on the input menu
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Input Method Menu"] autorelease];
    NSMenuItem *preferenceMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"McBopomofo Preferences", @"") action:@selector(showPreferences:) keyEquivalent:@""] autorelease];
    [menu addItem:preferenceMenuItem];

    // If Option key is pressed, show the learning-related menu

    #if 0
    //I think the following line is 10.6+ specific
    if ([[NSEvent class] respondsToSelector:@selector(modifierFlags)] && ([NSEvent modifierFlags] & NSAlternateKeyMask)) {

        BOOL learningEnabled = ![[NSUserDefaults standardUserDefaults] boolForKey:kDisableUserCandidateSelectionLearning];

        NSMenuItem *learnMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Enable Selection Learning", @"") action:@selector(toggleLearning:) keyEquivalent:@""] autorelease];
        if (learningEnabled) {
            [learnMenuItem setState:NSOnState];
        }
        else {
            [learnMenuItem setState:NSOffState];
        }

        [menu addItem:learnMenuItem];

        if (learningEnabled) {
            NSString *clearMenuItemTitle = [NSString stringWithFormat:NSLocalizedString(@"Clear Learning Dictionary (%ju Items)", @""), (uintmax_t)[gCandidateLearningDictionary count]];
            NSMenuItem *clearMenuItem = [[[NSMenuItem alloc] initWithTitle:clearMenuItemTitle action:@selector(clearLearningDictionary:) keyEquivalent:@""] autorelease];
            [menu addItem:clearMenuItem];


            NSMenuItem *dumpMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Dump Learning Data to Console", @"") action:@selector(dumpLearningDictionary:) keyEquivalent:@""] autorelease];
            [menu addItem:dumpMenuItem];
        }
    }
    #endif //DEBUG

    #if DEBUG
    NSMenuItem *updateCheckItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Check for Updates…", @"") action:@selector(checkForUpdate:) keyEquivalent:@""] autorelease];
    [menu addItem:updateCheckItem];
    #endif

    NSMenuItem *aboutMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"About McBopomofo…", @"") action:@selector(showAbout:) keyEquivalent:@""] autorelease];
    [menu addItem:aboutMenuItem];

    return menu;
}

#pragma mark - IMKStateSetting protocol methods

- (void)activateServer:(id)client
{
    [[NSUserDefaults standardUserDefaults] synchronize];

    // Override the keyboard layout. Use US if not set.
    NSString *basisKeyboardLayoutID = [[NSUserDefaults standardUserDefaults] stringForKey:kBasisKeyboardLayoutPreferenceKey];
    if (!basisKeyboardLayoutID) {
        basisKeyboardLayoutID = @"com.apple.keylayout.US";
    }
    [client overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];

    // reset the state
    _currentDeferredClient = nil;
    _currentCandidateClient = nil;
    _builder->clear();
    _walkedNodes.clear();
    [_composingBuffer setString:@""];

    // checks and populates the default settings
    NSInteger keyboardLayout = [[NSUserDefaults standardUserDefaults] integerForKey:kKeyboardLayoutPreferenceKey];
    switch (keyboardLayout) {
        case 0:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::StandardLayout());
            break;
        case 1:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::ETenLayout());
            break;
        case 2:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::HsuLayout());
            break;
        case 3:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::ETen26Layout());
            break;
        case 4:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::HanyuPinyinLayout());
            break;
        case 5:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::IBMLayout());
            break;
        default:
            _bpmfReadingBuffer->setKeyboardLayout(BopomofoKeyboardLayout::StandardLayout());
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kKeyboardLayoutPreferenceKey];
    }

    // set the size
    NSInteger textSize = [[NSUserDefaults standardUserDefaults] integerForKey:kCandidateListTextSizeKey];
    NSInteger previousTextSize = textSize;
    if (textSize == 0) {
        textSize = kDefaultCandidateListTextSize;
    }
    else if (textSize < kMinCandidateListTextSize) {
        textSize = kMinCandidateListTextSize;
    }
    else if (textSize > kMaxCandidateListTextSize) {
        textSize = kMaxCandidateListTextSize;
    }

    if (textSize != previousTextSize) {
        [[NSUserDefaults standardUserDefaults] setInteger:textSize forKey:kCandidateListTextSizeKey];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kChooseCandidateUsingSpaceKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kChooseCandidateUsingSpaceKey];
    }

    [(AppDelegate *)[NSApp delegate] checkForUpdate];
}

- (void)deactivateServer:(id)client
{
    // clean up reading buffer residues
    if (!_bpmfReadingBuffer->isEmpty()) {
        _bpmfReadingBuffer->clear();
        [client setMarkedText:@"" selectionRange:NSMakeRange(0, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    }

    // commit any residue in the composing buffer
    [self commitComposition:client];

    _currentDeferredClient = nil;
    _currentCandidateClient = nil;

    gCurrentCandidateController.delegate = nil;
    gCurrentCandidateController.visible = NO;
    [_candidates removeAllObjects];
}

- (void)setValue:(id)value forTag:(long)tag client:(id)sender
{
    NSString *newInputMode;
    Formosa::Gramambular::FastLM *newLanguageModel;

    if ([value isKindOfClass:[NSString class]] && [value isEqual:kPlainBopomofoModeIdentifier]) {
        newInputMode = kPlainBopomofoModeIdentifier;
        newLanguageModel = &gLanguageModelPlainBopomofo;
    }
    else {
        newInputMode = kBopomofoModeIdentifier;
        newLanguageModel = &gLanguageModel;
    }

    // Only apply the changes if the value is changed
    if (![_inputMode isEqualToString:newInputMode]) {
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Remember to override the keyboard layout again -- treat this as an activate eventy
        NSString *basisKeyboardLayoutID = [[NSUserDefaults standardUserDefaults] stringForKey:kBasisKeyboardLayoutPreferenceKey];
        if (!basisKeyboardLayoutID) {
            basisKeyboardLayoutID = @"com.apple.keylayout.US";
        }
        [sender overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];

        _inputMode = newInputMode;
        _languageModel = newLanguageModel;

        if (!_bpmfReadingBuffer->isEmpty()) {
            _bpmfReadingBuffer->clear();
            [self updateClientComposingBuffer:sender];
        }

        if ([_composingBuffer length] > 0) {
            [self commitComposition:sender];
        }

        if (_builder) {
            delete _builder;
            _builder = new BlockReadingBuilder(_languageModel);
            _builder->setJoinSeparator("-");
        }
    }
}

#pragma mark - IMKServerInput protocol methods

- (void)commitComposition:(id)client
{
    // if it's Terminal, we don't commit at the first call (the client of which will not be IPMDServerClientWrapper)
    // then we defer the update in the next runloop round -- so that the composing buffer is not
    // meaninglessly flushed, an annoying bug in Terminal.app since Mac OS X 10.5
    if ([[client bundleIdentifier] isEqualToString:@"com.apple.Terminal"] && ![NSStringFromClass([client class]) isEqualToString:@"IPMDServerClientWrapper"])
    {
        if (_currentDeferredClient) {
            [self performSelector:@selector(updateClientComposingBuffer:) withObject:_currentDeferredClient afterDelay:0.0];
        }
        return;
    }

    // commit the text, clear the state
    [client insertText:_composingBuffer replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    _builder->clear();
    _walkedNodes.clear();
    [_composingBuffer setString:@""];
    gCurrentCandidateController.visible = NO;
    [_candidates removeAllObjects];
}

// TODO: bug #28 is more likely to live in this method.
- (void)updateClientComposingBuffer:(id)client
{
    // "updating the composing buffer" means to request the client to "refresh" the text input buffer
    // with our "composing text"

    [_composingBuffer setString:@""];
    NSInteger composedStringCursorIndex = 0;

    size_t readingCursorIndex = 0;
    size_t builderCursorIndex = _builder->cursorIndex();

    // we must do some Unicode codepoint counting to find the actual cursor location for the client
    // i.e. we need to take UTF-16 into consideration, for which a surrogate pair takes 2 UniChars
    // locations
    for (vector<NodeAnchor>::iterator wi = _walkedNodes.begin(), we = _walkedNodes.end() ; wi != we ; ++wi) {
        if ((*wi).node) {
            string nodeStr = (*wi).node->currentKeyValue().value;
            vector<string> codepoints = OVUTF8Helper::SplitStringByCodePoint(nodeStr);
            size_t codepointCount = codepoints.size();

            NSString *valueString = [NSString stringWithUTF8String:nodeStr.c_str()];
            [_composingBuffer appendString:valueString];

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
            }
            else {
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
    NSString *head = [_composingBuffer substringToIndex:composedStringCursorIndex];
    NSString *reading = [NSString stringWithUTF8String:_bpmfReadingBuffer->composedString().c_str()];
    NSString *tail = [_composingBuffer substringFromIndex:composedStringCursorIndex];
    NSString *composedText = [head stringByAppendingString:[reading stringByAppendingString:tail]];
    NSInteger cursorIndex = composedStringCursorIndex + [reading length];

    // we must use NSAttributedString so that the cursor is visible --
    // can't just use NSString
    NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
                              [NSNumber numberWithInt:0], NSMarkedClauseSegmentAttributeName, nil];
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:composedText attributes:attrDict] autorelease];

    // the selection range is where the cursor is, with the length being 0 and replacement range NSNotFound,
    // i.e. the client app needs to take care of where to put ths composing buffer
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursorIndex, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    _latestReadingCursor = cursorIndex;
}

- (void)walk
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

- (void)popOverflowComposingTextAndWalk:(id)client
{
    // in an ideal world, we can as well let the user type forever,
    // but because the Viterbi algorithm has a complexity of O(N^2),
    // the walk will become slower as the number of nodes increase,
    // therefore we need to "pop out" overflown text -- they usually
    // lose their influence over the whole MLE anyway -- so tht when
    // the user type along, the already composed text at front will
    // be popped out

    NSInteger _composingBufferSize = [[NSUserDefaults standardUserDefaults] integerForKey:kComposingBufferSizePreferenceKey];
    NSInteger previousComposingBufferSize = _composingBufferSize;

    if (_composingBufferSize == 0) {
        _composingBufferSize = kDefaultComposingBufferSize;
    }
    else if (_composingBufferSize < kMinComposingBufferSize) {
        _composingBufferSize = kMinComposingBufferSize;
    }
    else if (_composingBufferSize > kMaxComposingBufferSize) {
        _composingBufferSize = kMaxComposingBufferSize;
    }

    if (_composingBufferSize != previousComposingBufferSize) {
        [[NSUserDefaults standardUserDefaults] setInteger:_composingBufferSize forKey:kComposingBufferSizePreferenceKey];
    }

    if (_builder->grid().width() > (size_t)_composingBufferSize) {
        if (_walkedNodes.size() > 0) {
            NodeAnchor &anchor = _walkedNodes[0];
            NSString *popedText = [NSString stringWithUTF8String:anchor.node->currentKeyValue().value.c_str()];
            [client insertText:popedText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
            _builder->removeHeadReadings(anchor.spanningLength);
        }
    }

    [self walk];
}

- (void)beep
{
    // use the system's default sound (configurable in System Preferences) to give a warning
    NSBeep();
}

- (BOOL)handleInputText:(NSString*)inputText key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)client
{
    NSRect textFrame = NSZeroRect;
    NSDictionary *attributes = nil;

    bool composeReading = false;
    BOOL useVerticalMode = NO;

    @try {
        attributes = [client attributesForCharacterIndex:0 lineHeightRectangle:&textFrame];
        useVerticalMode = [attributes objectForKey:@"IMKTextOrientation"] && [[attributes objectForKey:@"IMKTextOrientation"] integerValue] == 0;
    }
    @catch (NSException *e) {
        // exception may raise while using Twitter.app's search filed.
    }

    NSInteger cursorForwardKey = useVerticalMode ? kDownKeyCode : kRightKeyCode;
    NSInteger cursorBackwardKey = useVerticalMode ? kUpKeyCode : kLeftKeyCode;
    NSInteger extraChooseCandidateKey = useVerticalMode ? kLeftKeyCode : kDownKeyCode;
    NSInteger absorbedArrowKey = useVerticalMode ? kRightKeyCode : kUpKeyCode;
    NSInteger verticalModeOnlyChooseCandidateKey = useVerticalMode ? absorbedArrowKey : 0;

    // get the unicode character code
    UniChar charCode = [inputText length] ? [inputText characterAtIndex:0] : 0;

    if ([[client bundleIdentifier] isEqualToString:@"com.apple.Terminal"] && [NSStringFromClass([client class]) isEqualToString:@"IPMDServerClientWrapper"]) {
        // special handling for com.apple.Terminal
        _currentDeferredClient = client;
    }

    // if the inputText is empty, it's a function key combination, we ignore it
    if (![inputText length]) {
        return NO;
    }

    // if the composing buffer is empty and there's no reading, and there is some function key combination, we ignore it
    if (![_composingBuffer length] && _bpmfReadingBuffer->isEmpty() && ((flags & NSCommandKeyMask) || (flags & NSControlKeyMask) || (flags & NSAlternateKeyMask) || (flags & NSNumericPadKeyMask))) {
        return NO;
    }


    // Caps Lock processing : if Caps Lock is on, temporarily disable bopomofo.
    if (charCode == 8 || charCode == 13 || keyCode == absorbedArrowKey || keyCode == extraChooseCandidateKey || keyCode == cursorForwardKey || keyCode == cursorBackwardKey) {
        // do nothing if backspace is pressed -- we ignore the key
    }
    else if (flags & NSAlphaShiftKeyMask) {
        // process all possible combination, we hope.
        if ([_composingBuffer length]) {
            [self commitComposition:client];
        }

        // first commit everything in the buffer.
        if (flags & NSShiftKeyMask) {
            return NO;
        }

        // when shift is pressed, don't do further processing, since it outputs capital letter anyway.
        NSString *popedText = [inputText lowercaseString];
        [client insertText:popedText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        return YES;
    }

    if (flags & NSNumericPadKeyMask) {
        if (keyCode != kLeftKeyCode && keyCode != kRightKeyCode && keyCode != kDownKeyCode && keyCode != kUpKeyCode && charCode != 32 && isprint(charCode)) {
            if ([_composingBuffer length]) {
                [self commitComposition:client];
            }

            NSString *popedText = [inputText lowercaseString];
            [client insertText:popedText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
            return YES;
        }
    }

    // if we have candidate, it means we need to pass the event to the candidate handler
    if ([_candidates count]) {
        return [self handleCandidateEventWithInputText:inputText charCode:charCode keyCode:keyCode];
    }

    // see if it's valid BPMF reading
    if (_bpmfReadingBuffer->isValidKey((char)charCode)) {
        _bpmfReadingBuffer->combineKey((char)charCode);

        // if we have a tone marker, we have to insert the reading to the builder
        // in other words, if we don't have a tone marker, we just update the composing buffer
        composeReading = _bpmfReadingBuffer->hasToneMarker();
        if (!composeReading) {
            [self updateClientComposingBuffer:client];
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
            [self beep];
            [self updateClientComposingBuffer:client];
            return YES;
        }

        // and insert it into the lattice
        _builder->insertReadingAtCursor(reading);

        // then walk the lattice
        [self popOverflowComposingTextAndWalk:client];

        // see if we need to override the selection if a learned one exists
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kDisableUserCandidateSelectionLearning]) {
            NSString *trigram = [self neighborTrigramString];

            // Lookup from the user dict to see if the trigram fit or not
            NSString *overrideCandidateString = [gCandidateLearningDictionary objectForKey:trigram];
            if (overrideCandidateString) {
                [self candidateSelected:(NSAttributedString *)overrideCandidateString];
            }
        }

        // then update the text
        _bpmfReadingBuffer->clear();
        [self updateClientComposingBuffer:client];

        if (_inputMode == kPlainBopomofoModeIdentifier) {
            [self _showCandidateWindowUsingVerticalMode:useVerticalMode client:client];
        }

        // and tells the client that the key is consumed
        return YES;
    }

    // keyCode 125 = Down, charCode 32 = Space
    if (_bpmfReadingBuffer->isEmpty() && [_composingBuffer length] > 0 && (keyCode == extraChooseCandidateKey || charCode == 32 || (useVerticalMode && (keyCode == verticalModeOnlyChooseCandidateKey)))) {
        if (charCode == 32) {
            // if the spacebar is NOT set to be a selection key
            if (![[NSUserDefaults standardUserDefaults] boolForKey:kChooseCandidateUsingSpaceKey]) {
                if (_builder->cursorIndex() >= _builder->length()) {
                    [_composingBuffer appendString:@" "];
                    [self commitComposition:client];
                    _bpmfReadingBuffer->clear();
                }
                else if (_languageModel->hasUnigramsForKey(" ")) {
                    _builder->insertReadingAtCursor(" ");
                    [self popOverflowComposingTextAndWalk:client];
                    [self updateClientComposingBuffer:client];
                }
                return YES;

            }
        }
        [self _showCandidateWindowUsingVerticalMode:useVerticalMode client:client];
        return YES;
    }

    // Esc
    if (charCode == 27) {
        // if reading is not empty, we cancel the reading; Apple's built-in Zhuyin (and the erstwhile Hanin) has a default option that Esc "cancels" the current composed character and revert it to Bopomofo reading, in odds with the expectation of users from other platforms

        if (_bpmfReadingBuffer->isEmpty()) {
            // no nee to beep since the event is deliberately triggered by user

            if (![_composingBuffer length]) {
                return NO;
            }
        }
        else {
            _bpmfReadingBuffer->clear();
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }

    // handle cursor backward
    if (keyCode == cursorBackwardKey) {
        if (!_bpmfReadingBuffer->isEmpty()) {
            [self beep];
        }
        else {
            if (![_composingBuffer length]) {
                return NO;
            }

            if (_builder->cursorIndex() > 0) {
                _builder->setCursorIndex(_builder->cursorIndex() - 1);
            }
            else {
                [self beep];
            }
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }

    // handle cursor forward
    if (keyCode == cursorForwardKey) {
        if (!_bpmfReadingBuffer->isEmpty()) {
            [self beep];
        }
        else {
            if (![_composingBuffer length]) {
                return NO;
            }

            if (_builder->cursorIndex() < _builder->length()) {
                _builder->setCursorIndex(_builder->cursorIndex() + 1);
            }
            else {
                [self beep];
            }
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }

    if (keyCode == kHomeKeyCode) {
        if (!_bpmfReadingBuffer->isEmpty()) {
            [self beep];
        }
        else {
            if (![_composingBuffer length]) {
                return NO;
            }

            if (_builder->cursorIndex()) {
                _builder->setCursorIndex(0);
            }
            else {
                [self beep];
            }
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }

    if (keyCode == kEndKeyCode) {
        if (!_bpmfReadingBuffer->isEmpty()) {
            [self beep];
        }
        else {
            if (![_composingBuffer length]) {
                return NO;
            }

            if (_builder->cursorIndex() != _builder->length()) {
                _builder->setCursorIndex(_builder->length());
            }
            else {
                [self beep];
            }
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }

    if (keyCode == absorbedArrowKey || keyCode == extraChooseCandidateKey) {
        if (!_bpmfReadingBuffer->isEmpty()) {
            [self beep];
        }
        [self updateClientComposingBuffer:client];
        return YES;
    }

    // Backspace
    if (charCode == 8) {
        if (_bpmfReadingBuffer->isEmpty()) {
            if (![_composingBuffer length]) {
                return NO;
            }

            if (_builder->cursorIndex()) {
                _builder->deleteReadingBeforeCursor();
                [self walk];
            }
            else {
                [self beep];
            }
        }
        else {
            _bpmfReadingBuffer->backspace();
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }

    // Delete
    if (keyCode == kDeleteKeyCode) {
        if (_bpmfReadingBuffer->isEmpty()) {
            if (![_composingBuffer length]) {
                return NO;
            }

            if (_builder->cursorIndex() != _builder->length()) {
                _builder->deleteReadingAfterCursor();
                [self walk];
            }
            else {
                [self beep];
            }
        }
        else {
            [self beep];
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }


    // Enter
    if (charCode == 13) {
        if (![_composingBuffer length]) {
            return NO;
        }

        [self commitComposition:client];
        return YES;
    }

    // punctuation list
    if ((char)charCode == '`') {
        if (_languageModel->hasUnigramsForKey(string("_punctuation_list"))) {
            if (_bpmfReadingBuffer->isEmpty()) {
                _builder->insertReadingAtCursor(string("_punctuation_list"));
                [self popOverflowComposingTextAndWalk:client];
                [self _showCandidateWindowUsingVerticalMode:useVerticalMode client:client];
            }
            else { // If there is still unfinished bpmf reading, ignore the punctuation
                [self beep];
            }
            [self updateClientComposingBuffer:client];
            return YES;
        }
    }

    string layout = string("Standard_");;
    NSInteger keyboardLayout = [[NSUserDefaults standardUserDefaults] integerForKey:kKeyboardLayoutPreferenceKey];
    switch (keyboardLayout) {
        case 0:
            layout = string("Standard_");
            break;
        case 1:
            layout = string("ETen_");
            break;
        case 2:
            layout = string("ETen26_");
            break;
        case 3:
            layout = string("Hsu_");
            break;
        case 4:
            layout = string("HanyuPinyin_");
            break;
        case 5:
            layout = string("IBM_");
            break;
        default:
            break;
    }

    string customPunctuation = string("_punctuation_") + layout + string(1, (char)charCode);
    if (_languageModel->hasUnigramsForKey(customPunctuation)) {
        if (_bpmfReadingBuffer->isEmpty()) {
            _builder->insertReadingAtCursor(customPunctuation);
            [self popOverflowComposingTextAndWalk:client];
        }
        else { // If there is still unfinished bpmf reading, ignore the punctuation
            [self beep];
        }
        [self updateClientComposingBuffer:client];

        if (_inputMode == kPlainBopomofoModeIdentifier && _bpmfReadingBuffer->isEmpty()) {
            [self collectCandidates];
            if ([_candidates count] == 1) {
                [self commitComposition:client];
            }
            else {
                [self _showCandidateWindowUsingVerticalMode:useVerticalMode client:client];
            }
        }

        return YES;
    }

    // if nothing is matched, see if it's a punctuation key
    string punctuation = string("_punctuation_") + string(1, (char)charCode);
    if (_languageModel->hasUnigramsForKey(punctuation)) {
        if (_bpmfReadingBuffer->isEmpty()) {
            _builder->insertReadingAtCursor(punctuation);
            [self popOverflowComposingTextAndWalk:client];
        }
        else { // If there is still unfinished bpmf reading, ignore the punctuation
            [self beep];
        }
        [self updateClientComposingBuffer:client];

        if (_inputMode == kPlainBopomofoModeIdentifier && _bpmfReadingBuffer->isEmpty()) {
            [self collectCandidates];
            if ([_candidates count] == 1) {
                [self commitComposition:client];
            }
            else {
                [self _showCandidateWindowUsingVerticalMode:useVerticalMode client:client];
            }
        }

        return YES;
    }

    // still nothing, then we update the composing buffer (some app has
    // strange behavior if we don't do this, "thinking" the key is not
    // actually consumed)
    if ([_composingBuffer length] || !_bpmfReadingBuffer->isEmpty()) {
        [self beep];
        [self updateClientComposingBuffer:client];
        return YES;
    }

    return NO;
}

- (BOOL)handleCandidateEventWithInputText:(NSString *)inputText charCode:(UniChar)charCode keyCode:(NSUInteger)keyCode
{
    if (_inputMode == kPlainBopomofoModeIdentifier) {
        if (charCode == '<') {
            keyCode = kPageUpKeyCode;
        }
        else if (charCode == '>') {
            keyCode = kPageDownKeyCode;
        }
    }

    if (charCode == 27) {
        gCurrentCandidateController.visible = NO;
        [_candidates removeAllObjects];

        if (_inputMode == kPlainBopomofoModeIdentifier) {
            _builder->clear();
            _walkedNodes.clear();
            [_composingBuffer setString:@""];
        }
        [self updateClientComposingBuffer:_currentCandidateClient];
        return YES;
    }
    else if (charCode == 13 || keyCode == kEnterKeyCode) {
        [self candidateController:gCurrentCandidateController didSelectCandidateAtIndex:gCurrentCandidateController.selectedCandidateIndex];
        return YES;
    }
    else if (charCode == 32 || keyCode == kPageDownKeyCode) {
        BOOL updated = [gCurrentCandidateController showNextPage];
        if (!updated) {
            [self beep];
        }
        return YES;
    }
    else if (keyCode == kPageUpKeyCode) {
        BOOL updated = [gCurrentCandidateController showPreviousPage];
        if (!updated) {
            [self beep];
        }
        return YES;
    }
    else if (keyCode == kLeftKeyCode) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
            if (!updated) {
                [self beep];
            }
            return YES;
        }
        else {
            [self beep];
            return YES;
        }
    }
    else if (keyCode == kRightKeyCode) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController highlightNextCandidate];
            if (!updated) {
                [self beep];
            }
            return YES;
        }
        else {
            [self beep];
            return YES;
        }
    }
    else if (keyCode == kUpKeyCode) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController showPreviousPage];
            if (!updated) {
                [self beep];
            }
            return YES;
        }
        else {
            BOOL updated = [gCurrentCandidateController highlightPreviousCandidate];
            if (!updated) {
                [self beep];
            }
            return YES;
        }
    }
    else if (keyCode == kDownKeyCode) {
        if ([gCurrentCandidateController isKindOfClass:[VTHorizontalCandidateController class]]) {
            BOOL updated = [gCurrentCandidateController showNextPage];
            if (!updated) {
                [self beep];
            }
            return YES;
        }
        else {
            BOOL updated = [gCurrentCandidateController highlightNextCandidate];
            if (!updated) {
                [self beep];
            }
            return YES;
        }
    }
    else if (keyCode == kHomeKeyCode) {
        if (gCurrentCandidateController.selectedCandidateIndex == 0) {
            [self beep];

        }
        else {
            gCurrentCandidateController.selectedCandidateIndex = 0;
        }

        return YES;
    }
    else if (keyCode == kEndKeyCode && [_candidates count] > 0) {
        if (gCurrentCandidateController.selectedCandidateIndex == [_candidates count] - 1) {
            [self beep];
        }
        else {
            gCurrentCandidateController.selectedCandidateIndex = [_candidates count] - 1;
        }

        return YES;
    }
    else {
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
            if (_bpmfReadingBuffer->isValidKey((char)charCode)) {
                NSUInteger candidateIndex = [gCurrentCandidateController candidateIndexAtKeyLabelIndex:0];
                if (candidateIndex != NSUIntegerMax) {
                    [self candidateController:gCurrentCandidateController didSelectCandidateAtIndex:candidateIndex];
                    return [self handleInputText:inputText key:keyCode modifiers:0 client:_currentCandidateClient];
                }
            }
        }

        [self beep];
        return YES;
    }
}

- (NSUInteger)recognizedEvents:(id)sender
{
    return NSKeyDownMask | NSFlagsChangedMask;
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)client
{
    if ([event type] == NSFlagsChanged) {
        NSString *functionKeyKeyboardLayoutID = [[NSUserDefaults standardUserDefaults] stringForKey:kFunctionKeyKeyboardLayoutPreferenceKey];
        if (!functionKeyKeyboardLayoutID) {
            functionKeyKeyboardLayoutID = @"com.apple.keylayout.US";
        }

        NSString *basisKeyboardLayoutID = [[NSUserDefaults standardUserDefaults] stringForKey:kBasisKeyboardLayoutPreferenceKey];
        if (!basisKeyboardLayoutID) {
            basisKeyboardLayoutID = @"com.apple.keylayout.US";
        }

        // If no override is needed, just return NO.
        if ([functionKeyKeyboardLayoutID isEqualToString:basisKeyboardLayoutID]) {
            return NO;
        }

        // Function key pressed.
        BOOL includeShift = [[NSUserDefaults standardUserDefaults] boolForKey:kFunctionKeyKeyboardLayoutOverrideIncludeShiftKey];
        if (([event modifierFlags] & ~NSShiftKeyMask) || (([event modifierFlags] & NSShiftKeyMask) && includeShift)) {
            // Override the keyboard layout and let the OS do its thing
            [client overrideKeyboardWithKeyboardNamed:functionKeyKeyboardLayoutID];
            return NO;
        }

        // Revert back to the basis layout when the function key is released
        [client overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];
        return NO;
    }

    NSString *inputText = [event characters];
    NSInteger keyCode = [event keyCode];
    NSUInteger flags = [event modifierFlags];
    return [self handleInputText:inputText key:keyCode modifiers:flags client:client];
}

#pragma mark - Private methods

+ (VTHorizontalCandidateController *)horizontalCandidateController
{
    static VTHorizontalCandidateController *instance = nil;
    @synchronized(self) {
        if (!instance) {
            instance = [[VTHorizontalCandidateController alloc] init];
        }
    }

    return instance;
}

+ (VTVerticalCandidateController *)verticalCandidateController
{
    static VTVerticalCandidateController *instance = nil;
    @synchronized(self) {
        if (!instance) {
            instance = [[VTVerticalCandidateController alloc] init];
        }
    }

    return instance;
}

- (void)collectCandidates
{
    // returns the candidate
    [_candidates removeAllObjects];

    size_t cursorIndex = [self actualCandidateCursorIndex];
    vector<NodeAnchor> nodes = _builder->grid().nodesCrossingOrEndingAt(cursorIndex);

    // sort the nodes, so that longer nodes (representing longer phrases) are placed at the top of the candidate list
    stable_sort(nodes.begin(), nodes.end(), NodeAnchorDescendingSorter());

    // then use the C++ trick to retrieve the candidates for each node at/crossing the cursor
    for (vector<NodeAnchor>::iterator ni = nodes.begin(), ne = nodes.end(); ni != ne; ++ni) {
        const vector<KeyValuePair>& candidates = (*ni).node->candidates();
        for (vector<KeyValuePair>::const_iterator ci = candidates.begin(), ce = candidates.end(); ci != ce; ++ci) {
            [_candidates addObject:[NSString stringWithUTF8String:(*ci).value.c_str()]];
        }
    }
}

- (size_t)actualCandidateCursorIndex
{
    size_t cursorIndex = _builder->cursorIndex();

    BOOL candidatePhraseLocatedAfterCursor = [[NSUserDefaults standardUserDefaults] boolForKey:kSelectPhraseAfterCursorAsCandidatePreferenceKey];

    if (candidatePhraseLocatedAfterCursor) {
        // MS Phonetics IME style, phrase is *after* the cursor, i.e. cursor is always *before* the phrase
        if (cursorIndex < _builder->length()) {
            ++cursorIndex;
        }
    }
    else {
        if (!cursorIndex) {
            ++cursorIndex;
        }
    }

    return cursorIndex;
}

- (NSString *)neighborTrigramString
{
    // gather the "trigram" for user candidate selection learning

    NSMutableArray *termArray = [NSMutableArray array];

    size_t cursorIndex = [self actualCandidateCursorIndex];
    vector<NodeAnchor> nodes = _builder->grid().nodesCrossingOrEndingAt(cursorIndex);

    const Node* prev = 0;
    const Node* current = 0;
    const Node* next = 0;

    size_t wni = 0;
    size_t wnc = _walkedNodes.size();
    size_t accuSpanningLength = 0;
    for (wni = 0; wni < wnc; wni++) {
        NodeAnchor& anchor = _walkedNodes[wni];
        if (!anchor.node) {
            continue;
        }

        accuSpanningLength += anchor.spanningLength;
        if (accuSpanningLength >= cursorIndex) {
            prev = current;
            current = anchor.node;
            break;
        }

        current = anchor.node;
    }

    if (wni + 1 < wnc) {
        next = _walkedNodes[wni + 1].node;
    }

    string term;
    if (prev) {
        term = prev->currentKeyValue().key;
        [termArray addObject:[NSString stringWithUTF8String:term.c_str()]];
    }

    if (current) {
        term = current->currentKeyValue().key;
        [termArray addObject:[NSString stringWithUTF8String:term.c_str()]];
    }

    if (next) {
        term = next->currentKeyValue().key;
        [termArray addObject:[NSString stringWithUTF8String:term.c_str()]];
    }

    return [termArray componentsJoinedByString:@"-"];
}

- (void)_performDeferredSaveUserCandidatesDictionary
{
    BOOL __unused success = [gCandidateLearningDictionary writeToFile:gUserCandidatesDictionaryPath atomically:YES];
}

- (void)saveUserCandidatesDictionary
{
    if (!gUserCandidatesDictionaryPath) {
        return;
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_performDeferredSaveUserCandidatesDictionary) object:nil];

    // TODO: Const-ize the delay
    [self performSelector:@selector(_performDeferredSaveUserCandidatesDictionary) withObject:nil afterDelay:5.0];
}

- (void)_showCandidateWindowUsingVerticalMode:(BOOL)useVerticalMode client:(id)client
{
    // set the candidate panel style
    BOOL useHorizontalCandidateList = [[NSUserDefaults standardUserDefaults] boolForKey:kUseHorizontalCandidateListPreferenceKey];

    if (useVerticalMode) {
        gCurrentCandidateController = [McBopomofoInputMethodController verticalCandidateController];
    }
    else if (useHorizontalCandidateList) {
        gCurrentCandidateController = [McBopomofoInputMethodController horizontalCandidateController];
    }
    else {
        gCurrentCandidateController = [McBopomofoInputMethodController verticalCandidateController];
    }

    // set the attributes for the candidate panel (which uses NSAttributedString)
    NSInteger textSize = [[NSUserDefaults standardUserDefaults] integerForKey:kCandidateListTextSizeKey];

    NSInteger keyLabelSize = textSize / 2;
    if (keyLabelSize < kMinKeyLabelSize) {
        keyLabelSize = kMinKeyLabelSize;
    }

    NSString *ctFontName = [[NSUserDefaults standardUserDefaults] stringForKey:kCandidateTextFontName];
    NSString *klFontName = [[NSUserDefaults standardUserDefaults] stringForKey:kCandidateKeyLabelFontName];
    NSString *ckeys = [[NSUserDefaults standardUserDefaults] stringForKey:kCandidateKeys];

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
    [self collectCandidates];

    if (_inputMode == kPlainBopomofoModeIdentifier && [_candidates count] == 1) {
        [self commitComposition:client];
        return;
    }

    gCurrentCandidateController.delegate = self;
    [gCurrentCandidateController reloadData];

    // update the composing text, set the client
    [self updateClientComposingBuffer:client];
    _currentCandidateClient = client;

    NSRect lineHeightRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);

    NSInteger cursor = _latestReadingCursor;
    if (cursor == [_composingBuffer length] && cursor != 0) {
        cursor--;
    }

    // some apps (e.g. Twitter for Mac's search bar) handle this call incorrectly, hence the try-catch
    @try {
        [client attributesForCharacterIndex:cursor lineHeightRectangle:&lineHeightRect];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }

    if (useVerticalMode) {
        [gCurrentCandidateController setWindowTopLeftPoint:NSMakePoint(lineHeightRect.origin.x + lineHeightRect.size.width + 4.0, lineHeightRect.origin.y - 4.0) bottomOutOfScreenAdjustmentHeight:lineHeightRect.size.height + 4.0];
    }
    else {
        [gCurrentCandidateController setWindowTopLeftPoint:NSMakePoint(lineHeightRect.origin.x, lineHeightRect.origin.y - 4.0) bottomOutOfScreenAdjustmentHeight:lineHeightRect.size.height + 4.0];
    }

    gCurrentCandidateController.visible = YES;
}

#pragma mark - Misc menu items

- (void)showPreferences:(id)sender
{
    // show the preferences panel, and also make the IME app itself the focus
    if ([IMKInputController instancesRespondToSelector:@selector(showPreferences:)]) {
        [super showPreferences:sender];
    } else {
        [(AppDelegate *)[NSApp delegate] showPreferences];
    }
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)checkForUpdate:(id)sender
{
    [(AppDelegate *)[[NSApplication sharedApplication] delegate] checkForUpdateForced:YES];
}

- (void)showAbout:(id)sender
{
    [[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)toggleLearning:(id)sender
{
    BOOL toggle = ![[NSUserDefaults standardUserDefaults] boolForKey:kDisableUserCandidateSelectionLearning];

    [[NSUserDefaults standardUserDefaults] setBool:toggle forKey:kDisableUserCandidateSelectionLearning];
}

- (void)clearLearningDictionary:(id)sender
{
    [gCandidateLearningDictionary removeAllObjects];
    [self _performDeferredSaveUserCandidatesDictionary];
}

- (void)dumpLearningDictionary:(id)sender
{
    NSLog(@"%@", gCandidateLearningDictionary);
}

- (NSUInteger)candidateCountForController:(VTCandidateController *)controller
{
    return [_candidates count];
}

- (NSString *)candidateController:(VTCandidateController *)controller candidateAtIndex:(NSUInteger)index
{
    return [_candidates objectAtIndex:index];
}

- (void)candidateController:(VTCandidateController *)controller didSelectCandidateAtIndex:(NSUInteger)index
{
    gCurrentCandidateController.visible = NO;

    // candidate selected, override the node with selection
    string selectedValue = [[_candidates objectAtIndex:index] UTF8String];

    if (![[NSUserDefaults standardUserDefaults] boolForKey:kDisableUserCandidateSelectionLearning]) {
        NSString *trigram = [self neighborTrigramString];
        NSString *selectedNSString = [NSString stringWithUTF8String:selectedValue.c_str()];
        [gCandidateLearningDictionary setObject:selectedNSString forKey:trigram];
        [self saveUserCandidatesDictionary];
    }

    size_t cursorIndex = [self actualCandidateCursorIndex];
    vector<NodeAnchor> nodes = _builder->grid().nodesCrossingOrEndingAt(cursorIndex);

    for (vector<NodeAnchor>::iterator ni = nodes.begin(), ne = nodes.end(); ni != ne; ++ni) {
        const vector<KeyValuePair>& candidates = (*ni).node->candidates();

        for (size_t i = 0, c = candidates.size(); i < c; ++i) {
            if (candidates[i].value == selectedValue) {
                // found our node
                const_cast<Node*>((*ni).node)->selectCandidateAtIndex(i);
                break;
            }
        }
    }

    [_candidates removeAllObjects];

    [self walk];
    [self updateClientComposingBuffer:_currentCandidateClient];

    if (_inputMode == kPlainBopomofoModeIdentifier) {
        [self commitComposition:_currentCandidateClient];
        return;
    }
}

@end

static void LTLoadLanguageModelFile(NSString *filenameWithoutExtension, FastLM &lm)
{
    NSString *dataPath = [[NSBundle bundleForClass:[McBopomofoInputMethodController class]] pathForResource:filenameWithoutExtension ofType:@"txt"];
    bool result = lm.open([dataPath UTF8String]);
    if (!result) {
        NSLog(@"Failed opening language model: %@", dataPath);
    }
}


void LTLoadLanguageModel()
{
    LTLoadLanguageModelFile(@"data", gLanguageModel);
    LTLoadLanguageModelFile(@"data-plain-bpmf", gLanguageModelPlainBopomofo);


    // initialize the singleton learning dictionary
    // putting singleton in @synchronized is the standard way in Objective-C
    // to avoid race condition
    gCandidateLearningDictionary = [[NSMutableDictionary alloc] init];

    // the first instance is also responsible for loading the dictionary
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDirectory, YES);
    if (![paths count]) {
        NSLog(@"Fatal error: cannot find Applicaiton Support directory.");
        return;
    }

    NSString *appSupportPath = [paths objectAtIndex:0];
    NSString *userDictPath = [appSupportPath stringByAppendingPathComponent:@"McBopomofo"];

    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:userDictPath isDirectory:&isDir];

    if (exists) {
        if (!isDir) {
            NSLog(@"Fatal error: Path '%@' is not a directory", userDictPath);
            return;
        }
    }
    else {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:userDictPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLog(@"Failed to create directory '%@', error: %@", userDictPath, error);
            return;
        }
    }

    // TODO: Change this
    NSString *userDictFile = [userDictPath stringByAppendingPathComponent:@"UserCandidatesCache.plist"];
    gUserCandidatesDictionaryPath = [userDictFile retain];

    exists = [[NSFileManager defaultManager] fileExistsAtPath:userDictFile isDirectory:&isDir];
    if (exists && !isDir) {
        NSData *data = [NSData dataWithContentsOfFile:userDictFile];
        if (!data) {
            return;
        }

        NSString *errorStr = nil;
        NSPropertyListFormat format;
        id plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorStr];
        if (plist && [plist isKindOfClass:[NSDictionary class]]) {
            [gCandidateLearningDictionary setDictionary:(NSDictionary *)plist];
            NSLog(@"User dictionary read, item count: %ju", (uintmax_t)[gCandidateLearningDictionary count]);
        }
    }

}
