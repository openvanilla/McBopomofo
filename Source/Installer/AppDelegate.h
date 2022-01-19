// Copyright (c) 2012 and onwards The McBopomofo Authors.
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

#import <Cocoa/Cocoa.h>
#import "ArchiveUtil.h"

@interface AppDelegate : NSWindowController <NSApplicationDelegate>
{
@protected
    ArchiveUtil *_archiveUtil;
    NSString *_installingVersion;
    BOOL _upgrading;
    NSButton *__weak _installButton;
    NSButton *__weak _cancelButton;
    NSTextView *__unsafe_unretained _textView;
    NSWindow *__weak _progressSheet;
    NSProgressIndicator *__weak _progressIndicator;
    NSDate *_translocationRemovalStartTime;
    NSInteger _currentVersionNumber;
}
- (IBAction)agreeAndInstallAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@property (weak) IBOutlet NSButton *installButton;
@property (weak) IBOutlet NSButton *cancelButton;    
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSWindow *progressSheet;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@end
