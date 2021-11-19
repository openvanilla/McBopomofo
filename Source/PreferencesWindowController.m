//
// PreferencesWindowController.m
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
#import "PreferencesWindowController.h"
#import <Carbon/Carbon.h>

static NSString *const kBasisKeyboardLayoutPreferenceKey = @"BasisKeyboardLayout";  // alphanumeric ("ASCII") input basis
static NSString *const kCandidateKeys = @"CandidateKeys";
static NSString *const kDefaultKeys = @"123456789";

@implementation PreferencesWindowController
@synthesize fontSizePopUpButton = _fontSizePopUpButton;
@synthesize basisKeyboardLayoutButton = _basisKeyboardLayoutButton;
@synthesize selectionKeyComboBox = _selectionKeyComboBox;

- (void)awakeFromNib
{
    CFArrayRef list = TISCreateInputSourceList(NULL, true);
    NSMenuItem *usKeyboardLayoutItem = nil;
    NSMenuItem *chosenItem = nil;

    [self.basisKeyboardLayoutButton.menu removeAllItems];

    NSString *basisKeyboardLayoutID = [[NSUserDefaults standardUserDefaults] stringForKey:kBasisKeyboardLayoutPreferenceKey];

    for (int i = 0; i < CFArrayGetCount(list); i++) {
        TISInputSourceRef source = (TISInputSourceRef)CFArrayGetValueAtIndex(list, i);

        CFStringRef category = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory);
        if (CFStringCompare(category, kTISCategoryKeyboardInputSource, 0) != kCFCompareEqualTo) {
            continue;
        }

        CFBooleanRef asciiCapable = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsASCIICapable);
        if (!CFBooleanGetValue(asciiCapable)) {
            continue;
        }

        CFStringRef sourceType = TISGetInputSourceProperty(source, kTISPropertyInputSourceType);
        if (CFStringCompare(sourceType, kTISTypeKeyboardLayout, 0) != kCFCompareEqualTo) {
            continue;
        }

        NSString *sourceID = (__bridge NSString *)TISGetInputSourceProperty(source, kTISPropertyInputSourceID);
        NSString *localizedName = (__bridge NSString *)TISGetInputSourceProperty(source, kTISPropertyLocalizedName);

        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = localizedName;
        item.representedObject = sourceID;

        if ([sourceID isEqualToString:@"com.apple.keylayout.US"]) {
            usKeyboardLayoutItem = item;
        }

        // false if nil
        if ([basisKeyboardLayoutID isEqualToString:sourceID]) {
            chosenItem = item;
        }

        [self.basisKeyboardLayoutButton.menu addItem:item];
    }

    [self.basisKeyboardLayoutButton selectItem:(chosenItem ? chosenItem : usKeyboardLayoutItem)];
    CFRelease(list);

    self.selectionKeyComboBox.usesDataSource = NO;
    [self.selectionKeyComboBox removeAllItems];
    [self.selectionKeyComboBox addItemsWithObjectValues:@[
        kDefaultKeys,
        @"asdfghjkl",
        @"asdfzxcvb"
    ]];

    NSString *ckeys = [[NSUserDefaults standardUserDefaults] stringForKey:kCandidateKeys];
    if (!ckeys || [ckeys stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        ckeys = kDefaultKeys;
    }

    [self.selectionKeyComboBox setStringValue:ckeys];
}

- (IBAction)updateBasisKeyboardLayoutAction:(id)sender
{
    NSString *sourceID = [[self.basisKeyboardLayoutButton selectedItem] representedObject];
    if (sourceID) {
        [[NSUserDefaults standardUserDefaults] setObject:sourceID forKey:kBasisKeyboardLayoutPreferenceKey];
    }
}

- (IBAction)changeSelectionKeyAction:(id)sender
{
    NSString *keys = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (keys.length != 9 ||
        ![keys canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        [self.selectionKeyComboBox setStringValue:kDefaultKeys];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCandidateKeys];
        NSBeep();
        return;
    }

    [self.selectionKeyComboBox setStringValue:keys];
    if ([keys isEqualToString:kDefaultKeys]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCandidateKeys];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:keys forKey:kCandidateKeys];
    }
}

@end
