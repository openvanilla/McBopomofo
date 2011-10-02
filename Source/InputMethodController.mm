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
#import "SimpleLM.h"
#import "OVStringHelper.h"
#import "OVUTF8Helper.h"
#import "AppDelegate.h"

// C++ namespace usages
using namespace std;
using namespace Formosa::Mandarin;
using namespace Formosa::Gramambular;
using namespace OpenVanilla;

// default, min and max candidate list text size
static const NSInteger kDefaultCandidateListTextSize = 14;
static const NSInteger kMinCandidateListTextSize = 12;
static const NSInteger kMaxCandidateListTextSize = 128;

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
static NSString *const kCandidateListTextSizeKey = @"CandidateListTextSize";
static NSString *const kSelectPhraseAfterCursorAsCandidatePreferenceKey = @"SelectPhraseAfterCursorAsCandidate";
static NSString *const kUseHorizontalCandidateListPreferenceKey = @"UseHorizontalCandidateList";
static NSString *const kComposingBufferSizePreferenceKey = @"ComposingBufferSize";
static NSString *const kDisableUserCandidateSelectionLearning = @"DisableUserCandidateSelectionLearning";
static NSString *const kChooseCandidateUsingSpaceKey = @"ChooseCandidateUsingSpaceKey";

// a global object for saving the "learned" user candidate selections
NSMutableDictionary *TLCandidateLearningDictionary = nil;
NSString *TLUserCandidatesDictionaryPath = nil;

// if DEBUG is defined, a DOT file (GraphViz format) will be written to the
// specified path everytime the grid is walked
#if DEBUG
static NSString *const kGraphVizOutputfile = @"/tmp/lettuce-visualization.dot";
#endif

// IMK candidate panel object, created in main()
extern IMKCandidates *LTSharedCandidates;

// shared language model object that stores our phrase-term probability database
SimpleLM LTLanguageModel;

// private methods
@interface LettuceInputMethodController ()
- (size_t)actualCandidateCursorIndex;
- (NSString *)neighborTrigramString;

- (void)_performDeferredSaveUserCandidatesDictionary;
- (void)saveUserCandidatesDictionary;
@end

// sort helper
class NodeAnchorDescendingSorter
{
public:
    bool operator()(const NodeAnchor& a, const NodeAnchor &b) const {
        return a.node->key().length() > b.node->key().length();
    }
};

@implementation LettuceInputMethodController
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
	    // create the reading buffer
        _bpmfReadingBuffer = new BopomofoReadingBuffer(BopomofoKeyboardLayout::StandardLayout());
        
        // create the lattice builder
        _builder = new BlockReadingBuilder(&LTLanguageModel);
        
        // each Mandarin syllable is separated by a hyphen
        _builder->setJoinSeparator("-");
        
        // create the composing buffer
        _composingBuffer = [[NSMutableString alloc] init];
        
        // populate the settings, by default, DISABLE user candidate learning
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kDisableUserCandidateSelectionLearning]) {
            [[NSUserDefaults standardUserDefaults] setObject:(id)kCFBooleanTrue forKey:kDisableUserCandidateSelectionLearning];
        }
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
    
    #if DEBUG
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
            NSString *clearMenuItemTitle = [NSString stringWithFormat:NSLocalizedString(@"Clear Learning Dictionary (%ju Items)", @""), (uintmax_t)[TLCandidateLearningDictionary count]];
            NSMenuItem *clearMenuItem = [[[NSMenuItem alloc] initWithTitle:clearMenuItemTitle action:@selector(clearLearningDictionary:) keyEquivalent:@""] autorelease];
            [menu addItem:clearMenuItem];

            
            NSMenuItem *dumpMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Dump Learning Data to Console", @"") action:@selector(dumpLearningDictionary:) keyEquivalent:@""] autorelease];
            [menu addItem:dumpMenuItem];
        }
    }
    #endif //DEBUG
	
	NSMenuItem *aboutMenuItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"About McBopomofo…", @"") action:@selector(showAbout:) keyEquivalent:@""] autorelease];
	[menu addItem:aboutMenuItem];
    
    return menu;
}

#pragma mark IMKStateSetting protocol methods

- (void)showPreferences:(id)sender
{
    // show the preferences panel, and also make the IME app itself the focus
    [super showPreferences:sender];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)activateServer:(id)client
{
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
    // commit any residue in the composing buffer
    [self commitComposition:client];
    _currentDeferredClient = nil;    
    _currentCandidateClient = nil;
}

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
}

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

- (BOOL)inputText:(NSString*)inputText key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)client
{
	NSRect textFrame = NSZeroRect;
	NSDictionary *attributes = [client attributesForCharacterIndex:0 lineHeightRectangle:&textFrame];
	BOOL userVerticalMode = [attributes objectForKey:@"IMKTextOrientation"] && [[attributes objectForKey:@"IMKTextOrientation"] integerValue] == 0;
	NSInteger leftKey = userVerticalMode ? 125 : 124;
	NSInteger rightKey = userVerticalMode ? 126 : 123;
	NSInteger downKey = userVerticalMode ? 123 : 126;
//	NSInteger upKey = userVerticalMode ? 124 : 125;	
	
    // get the unicode character code
	UniChar charCode = [inputText length] ? [inputText characterAtIndex:0] : 0;    
    
    if ([[client bundleIdentifier] isEqualToString:@"com.apple.Terminal"] && [NSStringFromClass([client class]) isEqualToString:@"IPMDServerClientWrapper"])
    {
        // special handling for com.apple.Terminal
        _currentDeferredClient = client;
    }
    
    // if the inputText is empty, it's a function key combination, we ignore it
	if (![inputText length]) {
		return NO;
	}

    // if the composing buffer is empty and there's no reading, and there is some function key combination, we ignore it
    if (![_composingBuffer length] && _bpmfReadingBuffer->isEmpty() && ((flags & NSCommandKeyMask) || (flags & NSControlKeyMask) || (flags & NSAlternateKeyMask))) {
        return NO;
    }        
    
    bool composeReading = false;
    
    // caps lock processing : if caps locked, temporarily disabled bopomofo.
	if ([NSEvent modifierFlags] & NSAlphaShiftKeyMask){
		if ([_composingBuffer length]) [self commitComposition:client];
		if ([NSEvent modifierFlags] & NSShiftKeyMask) return NO;
		NSString *popedText = [inputText lowercaseString];
		[client insertText:popedText replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
		return YES;
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
        string reading = _bpmfReadingBuffer->composedString();
        
        // see if we have a unigram for this
        if (!LTLanguageModel.hasUnigramsForKey(reading)) {
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
            
            NSString *overrideCandidateString = [TLCandidateLearningDictionary objectForKey:trigram];
            if (overrideCandidateString) {
                [self candidateSelected:(NSAttributedString *)overrideCandidateString];
            }
        }
        
        // then update the text
        _bpmfReadingBuffer->clear();
        [self updateClientComposingBuffer:client];
        
        // and tells the client that the key is consumed
        return YES;        
    }

    // keyCode 125 = Down, charCode 32 = Space
    if (_bpmfReadingBuffer->isEmpty() && [_composingBuffer length] > 0 && (keyCode == downKey || charCode == 32)) {
		if (charCode == 32) {
			if (![[NSUserDefaults standardUserDefaults] boolForKey:kChooseCandidateUsingSpaceKey]) {
				if (_builder->cursorIndex() >= _builder->length()) {
					[_composingBuffer appendString:@" "];
					[self commitComposition:client];
					_bpmfReadingBuffer->clear();					
				}
				else if (LTLanguageModel.hasUnigramsForKey(" ")) {
					_builder->insertReadingAtCursor(" ");
					[self popOverflowComposingTextAndWalk:client];
					[self updateClientComposingBuffer:client];
				}
				return YES;
					
			}
		}
		
		// candidate
        [LTSharedCandidates setDismissesAutomatically:YES];
        
        // wrap NSNumber; we only allow number keys 1-9 as selection keys in this project
        #define LTUIntObj(x)    ([NSNumber numberWithInteger:x])        
        [LTSharedCandidates setSelectionKeys:[NSArray arrayWithObjects:LTUIntObj(18), LTUIntObj(19), LTUIntObj(20), LTUIntObj(21), LTUIntObj(23), LTUIntObj(22), LTUIntObj(26), LTUIntObj(28), LTUIntObj(25), nil]];
        #undef LTUIntObj

        // set the candidate panel style
        BOOL useHorizontalCandidateList = [[NSUserDefaults standardUserDefaults] boolForKey:kUseHorizontalCandidateListPreferenceKey];

        if (userVerticalMode) {
            [LTSharedCandidates setPanelType:kIMKSingleColumnScrollingCandidatePanel];
		}
		else if (useHorizontalCandidateList) {
            [LTSharedCandidates setPanelType:kIMKSingleRowSteppingCandidatePanel];
        }
        else {
            [LTSharedCandidates setPanelType:kIMKSingleColumnScrollingCandidatePanel];
        }
        
        // set the attributes for the candidate panel (which uses NSAttributedString)
        NSInteger textSize = [[NSUserDefaults standardUserDefaults] integerForKey:kCandidateListTextSizeKey];        
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:textSize], NSFontAttributeName, nil];		
		[LTSharedCandidates setAttributes:attributes];

        [LTSharedCandidates updateCandidates];
        [LTSharedCandidates show:kIMKLocateCandidatesBelowHint];
        
        // update the composing text, set the client
        [self updateClientComposingBuffer:client];
        _currentCandidateClient = client;
        return YES;
    }
    
    // Esc
    if (charCode == 27) {        
        if (_bpmfReadingBuffer->isEmpty()) {
            if (![_composingBuffer length]) {
                return NO;
            }
            
            //[self beep];
            //如果要按 ESC 的時候都已經知道要取消些啥，不必beep
        }
        else {
            _bpmfReadingBuffer->clear();
        }

        [self updateClientComposingBuffer:client];
        return YES;
    }
    
    // The Right key, note we use keyCode here
    if (keyCode == rightKey) {
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
    
    // The Left key, note we use keyCode here
    if (keyCode == leftKey) {
        if (!_bpmfReadingBuffer->isEmpty()) {            
            [self beep];
        }
        else {
            if (![_composingBuffer length]) {
                return NO;
            }
            
            if (_builder->cursorIndex() < [_composingBuffer length]) {
                _builder->setCursorIndex(_builder->cursorIndex() + 1);
            }
            else {
                [self beep];
            }
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
    
    // Enter
    if (charCode == 13) {
        if (![_composingBuffer length]) {
            return NO;
        }
        
        [self commitComposition:client];
        return YES;
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
        default:
			break;
    }
	
	string customPunctuation = string("_punctuation_") + layout + string(1, (char)charCode);
	if (LTLanguageModel.hasUnigramsForKey(customPunctuation)) {
        if (_bpmfReadingBuffer->isEmpty()) {
            _builder->insertReadingAtCursor(customPunctuation);
            [self popOverflowComposingTextAndWalk:client];
        }
        else { // If there is still unfinished bpmf reading, ignore the punctuation
            [self beep];
        }
        [self updateClientComposingBuffer:client];
        return YES;
    }
	
    // if nothing is matched, see if it's a punctuation key
    string punctuation = string("_punctuation_") + string(1, (char)charCode);
    if (LTLanguageModel.hasUnigramsForKey(punctuation)) {
        if (_bpmfReadingBuffer->isEmpty()) {
            _builder->insertReadingAtCursor(punctuation);
            [self popOverflowComposingTextAndWalk:client];
        }
        else { // If there is still unfinished bpmf reading, ignore the punctuation
            [self beep];
        }
        [self updateClientComposingBuffer:client];
        return YES;
    }

    // still nothing, then we update the composing buffer (some app has
    // strange behavior if we don't do this, "thinking" the key is not
    // actually consumed)
    if ([_composingBuffer length]) {
        [self beep];
        [self updateClientComposingBuffer:client];
        return YES;
    }

    return NO;
}

- (NSArray*)candidates:(id)client
{
    // returns the candidate
    
    NSMutableArray *results = [NSMutableArray array];
    size_t cursorIndex = [self actualCandidateCursorIndex];
    vector<NodeAnchor> nodes = _builder->grid().nodesCrossingOrEndingAt(cursorIndex);
    
    // sort the nodes, so that longer nodes (representing longer phrases) are placed at the top of the candidate list
    sort(nodes.begin(), nodes.end(), NodeAnchorDescendingSorter());

    // then use the C++ trick to retrieve the candidates for each node at/crossing the cursor
    for (vector<NodeAnchor>::iterator ni = nodes.begin(), ne = nodes.end(); ni != ne; ++ni) {
        const vector<KeyValuePair>& candidates = (*ni).node->candidates();
        for (vector<KeyValuePair>::const_iterator ci = candidates.begin(), ce = candidates.end(); ci != ce; ++ci) {
            [results addObject:[NSString stringWithUTF8String:(*ci).value.c_str()]];
        }
    }
        
    return results;
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
             
- (void)candidateSelected:(NSAttributedString *)candidateString
{
    // candidate selected, override the node with selection
    
    string selectedValue;
    
    if ([candidateString isKindOfClass:[NSString class]]) {
        selectedValue = [(NSString *)candidateString UTF8String];
    }
    else {
        selectedValue = [[candidateString string] UTF8String];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kDisableUserCandidateSelectionLearning]) {
        NSString *trigram = [self neighborTrigramString];
        NSString *selectedNSString = [NSString stringWithUTF8String:selectedValue.c_str()];
        [TLCandidateLearningDictionary setObject:selectedNSString forKey:trigram];
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
        
    [self walk];
    [self updateClientComposingBuffer:_currentCandidateClient];
    _currentCandidateClient = nil;
}

#pragma mark Private methods

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

- (void)_performDeferredSaveUserCandidatesDictionary
{
    BOOL __unused success = [TLCandidateLearningDictionary writeToFile:TLUserCandidatesDictionaryPath atomically:YES];
}

- (void)saveUserCandidatesDictionary
{
    if (!TLUserCandidatesDictionaryPath) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_performDeferredSaveUserCandidatesDictionary) object:nil];
    
    // TODO: Const-ize the delay
    [self performSelector:@selector(_performDeferredSaveUserCandidatesDictionary) withObject:nil afterDelay:5.0];
}

#pragma Misc menu items

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
    [TLCandidateLearningDictionary removeAllObjects];
    [self _performDeferredSaveUserCandidatesDictionary];
}

- (void)dumpLearningDictionary:(id)sender
{
    NSLog(@"%@", TLCandidateLearningDictionary);
}
@end


void LTLoadLanguageModel()
{
    // load the language model; the performance of this function can be greatly improved
    // with better loading/parsing methods
    
    NSDate *__unused startTime = [NSDate date];

    NSString *dataPath = [[NSBundle bundleForClass:[LettuceInputMethodController class]] pathForResource:@"data" ofType:@"txt"];
    
    ifstream ifs;
    ifs.open([dataPath UTF8String]);
    while (ifs.good()) {
        string line;
        getline(ifs, line);
        
        if (!line.size() || (line.size() && line[0] == '#')) {
            continue;
        }
        
        vector<string> p = OVStringHelper::SplitBySpacesOrTabs(line);
        
        if (p.size() == 3) {
            LTLanguageModel.add(p[1], p[0], atof(p[2].c_str()));
        }
    }
    ifs.close();
	LTLanguageModel.add(" ", " ", 0.0);
    
    // initialize the singleton learning dictionary
    // putting singleton in @synchronized is the standard way in Objective-C
    // to avoid race condition
    TLCandidateLearningDictionary = [[NSMutableDictionary alloc] init];
        
    // the first instance is also responsible for loading the dictionary
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDirectory, YES);
    if (![paths count]) {
        NSLog(@"Fatal error: cannot find Applicaiton Support directory.");
        return;
    }
    
    NSString *appSupportPath = [paths objectAtIndex:0];
    
    // TODO: Change this
    NSString *userDictPath = [appSupportPath stringByAppendingPathComponent:@"Lettuce"];

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
    TLUserCandidatesDictionaryPath = [userDictFile retain];

    exists = [[NSFileManager defaultManager] fileExistsAtPath:userDictFile isDirectory:&isDir];
    if (exists && !isDir) {
        NSData *data = [NSData dataWithContentsOfFile:userDictFile];
        if (!data) {
            return;
        }
        
        NSString *errorStr = nil;
        NSPropertyListFormat format = 0;
        id plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&errorStr];
        if (plist && [plist isKindOfClass:[NSDictionary class]]) {
            [TLCandidateLearningDictionary setDictionary:(NSDictionary *)plist];
            NSLog(@"User dictionary read, item count: %ju", (uintmax_t)[TLCandidateLearningDictionary count]);
        }        
    }
    
}
