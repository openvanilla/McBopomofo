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

#import "McBopomofoLM.h"
#import "InputMethodController.h"
#import "KeyHandler.h"
#import "LanguageModelManager.h"

// Swift Packages
@import CandidateUI;
@import NotifierUI;
@import TooltipUI;
@import OpenCCBridge;
@import VXHanConvert;

//// C++ namespace usages
using namespace std;
using namespace McBopomofo;

static const NSInteger kMinKeyLabelSize = 10;

VTCandidateController *gCurrentCandidateController = nil;

// https://clang-analyzer.llvm.org/faq.html
__attribute__((annotate("returns_localized_nsstring")))
static inline NSString *LocalizationNotNeeded(NSString *s) {
    return s;
}

@interface McBopomofoInputMethodController ()
{
    // the current text input client; we need to keep this when candidate panel is on
    id _currentCandidateClient;

    // a special deferred client for Terminal.app fix
    id _currentDeferredClient;

    KeyHandler *_keyHandler;
    InputState *_state;
}
@end

@interface McBopomofoInputMethodController (VTCandidateController) <VTCandidateControllerDelegate>
@end

@interface McBopomofoInputMethodController (KeyHandlerDelegate) <KeyHandlerDelegate>
@end

@interface McBopomofoInputMethodController (UI)
+ (VTHorizontalCandidateController *)horizontalCandidateController;
+ (VTVerticalCandidateController *)verticalCandidateController;
+ (TooltipController *)tooltipController;
- (void)_showTooltip:(NSString *)tooltip composingBuffer:(NSString *)composingBuffer cursorIndex:(NSInteger)cursorIndex client:(id)client;
- (void)_hideTooltip;
@end

@implementation McBopomofoInputMethodController

- (id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)client
{
    // an instance is initialized whenever a text input client (a Mac app) requires
    // text input from an IME

    self = [super initWithServer:server delegate:delegate client:client];
    if (self) {
        _keyHandler = [[KeyHandler alloc] init];
        _keyHandler.delegate = self;
        _state = [[InputStateEmpty alloc] init];
    }

    return self;
}

- (NSMenu *)menu
{
    // a menu instance (autoreleased) is requested every time the user click on the input menu
    NSMenu *menu = [[NSMenu alloc] initWithTitle:LocalizationNotNeeded(@"Input Method Menu")];
    NSString *inputMode = _keyHandler.inputMode;

    [menu addItemWithTitle:NSLocalizedString(@"McBopomofo Preferences", @"") action:@selector(showPreferences:) keyEquivalent:@""];

    NSMenuItem *chineseConversionMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Chinese Conversion", @"") action:@selector(toggleChineseConverter:) keyEquivalent:@"g"];
    chineseConversionMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagControl;
    chineseConversionMenuItem.state = Preferences.chineseConversionEnabled ? NSControlStateValueOn : NSControlStateValueOff;

    NSMenuItem *halfWidthPunctuationMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Use Half-Width Punctuations", @"") action:@selector(toggleHalfWidthPunctuation:) keyEquivalent:@""];
    halfWidthPunctuationMenuItem.state = Preferences.halfWidthPunctuationEnabled ? NSControlStateValueOn : NSControlStateValueOff;

    BOOL optionKeyPressed = [[NSEvent class] respondsToSelector:@selector(modifierFlags)] && ([NSEvent modifierFlags] & NSEventModifierFlagOption);

    if (inputMode == kBopomofoModeIdentifier && optionKeyPressed) {
        NSMenuItem *phaseReplacementMenuItem = [menu addItemWithTitle:NSLocalizedString(@"Use Phrase Replacement", @"") action:@selector(togglePhraseReplacementEnabled:) keyEquivalent:@""];
        phaseReplacementMenuItem.state = Preferences.phraseReplacementEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    }

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:NSLocalizedString(@"User Phrases", @"") action:NULL keyEquivalent:@""];
    if (inputMode == kPlainBopomofoModeIdentifier) {
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

    [_keyHandler clear];
    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
    [self handleState:empty client:client];

    // checks and populates the default settings
    [_keyHandler syncWithPreferences];
    [(AppDelegate *) NSApp.delegate checkForUpdate];
}

- (void)deactivateServer:(id)client
{
    [_keyHandler clear];

    InputStateEmpty *empty = [[InputStateEmpty alloc] init];
    [self handleState:empty client:client];

    InputStateDeactivated *inactive = [[InputStateDeactivated alloc] init];
    [self handleState:inactive client:client];
}

- (void)setValue:(id)value forTag:(long)tag client:(id)sender
{
    NSString *newInputMode;

    if ([value isKindOfClass:[NSString class]] && [value isEqual:kPlainBopomofoModeIdentifier]) {
        newInputMode = kPlainBopomofoModeIdentifier;
    } else {
        newInputMode = kBopomofoModeIdentifier;
    }

    // Only apply the changes if the value is changed
    if (![_keyHandler.inputMode isEqualToString:newInputMode]) {
        [[NSUserDefaults standardUserDefaults] synchronize];

        // Remember to override the keyboard layout again -- treat this as an activate event.
        NSString *basisKeyboardLayoutID = Preferences.basisKeyboardLayout;
        [sender overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];
        [_keyHandler clear];
        _keyHandler.inputMode = newInputMode;
        InputState *empty = [[InputState alloc] init];
        [self handleState:empty client:sender];
    }
}

#pragma  mark - IMKServerInput protocol methods

- (NSUInteger)recognizedEvents:(id)sender
{
    return NSEventMaskKeyDown | NSEventMaskFlagsChanged;
}

- (BOOL)handleEvent:(NSEvent *)event client:(id)client
{
    if ([event type] == NSEventMaskFlagsChanged) {
        NSString *functionKeyKeyboardLayoutID = Preferences.functionKeyboardLayout;
        NSString *basisKeyboardLayoutID = Preferences.basisKeyboardLayout;

        // If no override is needed, just return NO.
        if ([functionKeyKeyboardLayoutID isEqualToString:basisKeyboardLayoutID]) {
            return NO;
        }

        // Function key pressed.
        BOOL includeShift = Preferences.functionKeyKeyboardLayoutOverrideIncludeShiftKey;
        if ((event.modifierFlags & ~NSEventModifierFlagShift) || ((event.modifierFlags & NSEventModifierFlagShift) && includeShift)) {
            // Override the keyboard layout and let the OS do its thing
            [client overrideKeyboardWithKeyboardNamed:functionKeyKeyboardLayoutID];
            return NO;
        }

        // Revert to the basis layout when the function key is released
        [client overrideKeyboardWithKeyboardNamed:basisKeyboardLayoutID];
        return NO;
    }

    NSRect textFrame = NSZeroRect;
    NSDictionary *attributes = nil;
    BOOL useVerticalMode = NO;

    @try {
        attributes = [client attributesForCharacterIndex:0 lineHeightRectangle:&textFrame];
        useVerticalMode = attributes[@"IMKTextOrientation"] && [attributes[@"IMKTextOrientation"] integerValue] == 0;
    }
    @catch (NSException *e) {
        // exception may raise while using Twitter.app's search filed.
    }

    if ([[client bundleIdentifier] isEqualToString:@"com.apple.Terminal"] && [NSStringFromClass([client class]) isEqualToString:@"IPMDServerClientWrapper"]) {
        // special handling for com.apple.Terminal
        _currentDeferredClient = client;
    }

    KeyHandlerInput *input = [[KeyHandlerInput alloc] initWithEvent:event isVerticalMode:useVerticalMode];
    BOOL result = [_keyHandler handleInput:input state:_state stateCallback:^(InputState *state) {
        [self handleState:state client:client];
    }           candidateSelectionCallback:^{
        NSLog(@"candidate window updated.");
    }                        errorCallback:^{
        NSBeep();
    }];

    return result;
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [currentDeferredClient insertText:buffer replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
            });
        }
        return;
    }
    [client insertText:buffer replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

- (void)handleState:(InputState *)newState client:(id)client
{
//    NSLog(@"current state: %@ new state: %@", _state, newState );

    // We need to set the state to the member variable since the candidate
    // window need to read the candidates from it.
    InputState *previous = _state;
    _state = newState;

    if ([newState isKindOfClass:[InputStateDeactivated class]]) {
        [self _handleDeactivated:(InputStateDeactivated *) newState previous:previous client:client];
    } else if ([newState isKindOfClass:[InputStateEmpty class]]) {
        [self _handleEmpty:(InputStateEmpty *) newState previous:previous client:client];
    } else if ([newState isKindOfClass:[InputStateEmptyIgnoringPreviousState class]]) {
        [self _handleEmptyIgnoringPrevious:(InputStateEmptyIgnoringPreviousState *) newState previous:previous client:client];
    } else if ([newState isKindOfClass:[InputStateCommitting class]]) {
        [self _handleCommitting:(InputStateCommitting *) newState previous:previous client:client];
    } else if ([newState isKindOfClass:[InputStateInputting class]]) {
        [self _handleInputting:(InputStateInputting *) newState previous:previous client:client];
    } else if ([newState isKindOfClass:[InputStateMarking class]]) {
        [self _handleMarking:(InputStateMarking *) newState previous:previous client:client];
    } else if ([newState isKindOfClass:[InputStateChoosingCandidate class]]) {
        [self _handleChoosingCandidate:(InputStateChoosingCandidate *) newState previous:previous client:client];
    }
}

- (void)_handleDeactivated:(InputStateDeactivated *)state previous:(InputState *)previous client:(id)client
{
    // commit any residue in the composing buffer
    if ([previous isKindOfClass:[InputStateInputting class]]) {
        NSString *buffer = ((InputStateInputting *) previous).composingBuffer;
        [self _commitText:buffer client:client];
    }
    [client setMarkedText:@"" selectionRange:NSMakeRange(0, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    _currentDeferredClient = nil;
    _currentCandidateClient = nil;

    gCurrentCandidateController.delegate = nil;
    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleEmpty:(InputStateEmpty *)state previous:(InputState *)previous client:(id)client
{
    // commit any residue in the composing buffer
    if ([previous isKindOfClass:[InputStateInputting class]]) {
        NSString *buffer = ((InputStateInputting *) previous).composingBuffer;
        [self _commitText:buffer client:client];
    }

    [client setMarkedText:@"" selectionRange:NSMakeRange(0, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleEmptyIgnoringPrevious:(InputStateEmptyIgnoringPreviousState *)state previous:(InputState *)previous client:(id)client
{
    [client setMarkedText:@"" selectionRange:NSMakeRange(0, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleCommitting:(InputStateCommitting *)state previous:(InputState *)previous client:(id)client
{
    NSString *poppedText = state.poppedText;
    [self _commitText:poppedText client:client];
    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleInputting:(InputStateInputting *)state previous:(InputState *)previous client:(id)client
{
    NSString *poppedText = state.poppedText;
    if (poppedText.length) {
        [self _commitText:poppedText client:client];
    }

    NSUInteger cursorIndex = state.cursorIndex;
    NSAttributedString *attrString = state.attributedString;

    // the selection range is where the cursor is, with the length being 0 and replacement range NSNotFound,
    // i.e. the client app needs to take care of where to put ths composing buffer
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursorIndex, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    gCurrentCandidateController.visible = NO;
    [self _hideTooltip];
}

- (void)_handleMarking:(InputStateMarking *)state previous:(InputState *)previous client:(id)client
{
    NSUInteger cursorIndex = state.cursorIndex;
    NSAttributedString *attrString = state.attributedString;

    // the selection range is where the cursor is, with the length being 0 and replacement range NSNotFound,
    // i.e. the client app needs to take care of where to put ths composing buffer
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursorIndex, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    gCurrentCandidateController.visible = NO;
    if (state.tooltip.length) {
        [self _showTooltip:state.tooltip composingBuffer:state.composingBuffer cursorIndex:state.markerIndex client:client];
    } else {
        [self _hideTooltip];
    }
}

- (void)_handleChoosingCandidate:(InputStateChoosingCandidate *)state previous:(InputState *)previous client:(id)client
{
    NSUInteger cursorIndex = state.cursorIndex;
    NSAttributedString *attrString = state.attributedString;

    // the selection range is where the cursor is, with the length being 0 and replacement range NSNotFound,
    // i.e. the client app needs to take care of where to put ths composing buffer
    [client setMarkedText:attrString selectionRange:NSMakeRange(cursorIndex, 0) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];

    if (_keyHandler.inputMode == kPlainBopomofoModeIdentifier && state.candidates.count == 1) {
        NSString *buffer = [self _convertToSimplifiedChineseIfRequired:state.candidates.firstObject];
        [client insertText:buffer replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        InputStateEmpty *empty = [[InputStateEmpty alloc] init];
        [self handleState:empty client:client];
    } else {
        if (![previous isKindOfClass:[InputStateChoosingCandidate class]]) {
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
    NSString *candidateKeys = Preferences.candidateKeys;

    gCurrentCandidateController.keyLabelFont = klFontName ? [NSFont fontWithName:klFontName size:keyLabelSize] : [NSFont systemFontOfSize:keyLabelSize];
    gCurrentCandidateController.candidateFont = ctFontName ? [NSFont fontWithName:ctFontName size:textSize] : [NSFont systemFontOfSize:textSize];

    NSMutableArray *keyLabels = [@[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"] mutableCopy];

    if (candidateKeys.length > 1) {
        [keyLabels removeAllObjects];
        for (NSUInteger i = 0, c = candidateKeys.length; i < c; i++) {
            [keyLabels addObject:[candidateKeys substringWithRange:NSMakeRange(i, 1)]];
        }
    }

    gCurrentCandidateController.keyLabels = keyLabels;
    gCurrentCandidateController.delegate = self;
    [gCurrentCandidateController reloadData];
    _currentCandidateClient = client;

    NSRect lineHeightRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);
    NSInteger cursor = state.cursorIndex;
    if (cursor == state.composingBuffer.length && cursor != 0) {
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

#pragma mark - Misc menu items

- (void)showPreferences:(id)sender
{
    // show the preferences panel, and also make the IME app itself the focus
    if ([IMKInputController instancesRespondToSelector:@selector(showPreferences:)]) {
        [super showPreferences:sender];
    } else {
        [(AppDelegate *) NSApp.delegate showPreferences];
    }
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)toggleChineseConverter:(id)sender
{
    BOOL chineseConversionEnabled = [Preferences toggleChineseConversionEnabled];
    [NotifierController notifyWithMessage:chineseConversionEnabled ? NSLocalizedString(@"Chinese conversion on", @"") : NSLocalizedString(@"Chinese conversion off", @"") stay:NO];
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
    [(AppDelegate *) NSApp.delegate checkForUpdateForced:YES];
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
        string selectedValue = [state.candidates[index] UTF8String];
        [_keyHandler fixNodeWithValue:selectedValue];
        InputStateInputting *inputting = [_keyHandler _buildInputtingState];

        if (_keyHandler.inputMode == kPlainBopomofoModeIdentifier) {
            [_keyHandler clear];
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

@implementation McBopomofoInputMethodController (KeyHandlerDelegate)

- (nonnull VTCandidateController *)candidateControllerForKeyHandler:(nonnull KeyHandler *)keyHandler
{
    return gCurrentCandidateController;
}

- (BOOL)keyHandler:(nonnull KeyHandler *)keyHandler didRequestWriteUserPhraseWithState:(nonnull InputStateMarking *)state
{
    if (!state.validToWrite) {
        return NO;
    }
    NSString *userPhrase = state.userPhrase;
    [LanguageModelManager writeUserPhrase:userPhrase];
    return YES;
}

- (void)keyHandler:(nonnull KeyHandler *)keyHandler didSelectCandidateAtIndex:(NSInteger)index candidateController:(nonnull VTCandidateController *)controller
{
    [self candidateController:gCurrentCandidateController didSelectCandidateAtIndex:index];
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

- (void)_showTooltip:(NSString *)tooltip composingBuffer:(NSString *)composingBuffer cursorIndex:(NSInteger)cursorIndex client:(id)client
{
    NSRect lineHeightRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);

    NSUInteger cursor = (NSUInteger) cursorIndex;
    if (cursor == composingBuffer.length && cursor != 0) {
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
