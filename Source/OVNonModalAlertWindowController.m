//
//  OVNonModalAlertWindowController.m
//  OpenVanilla
//
//  Created by Lukhnos Liu on 10/17/12.
//  Copyright (c) 2012 The OpenVanilla Project. All rights reserved.
//

#import "OVNonModalAlertWindowController.h"

@implementation OVNonModalAlertWindowController
@synthesize titleTextField = _titleTextField;
@synthesize contentTextField = _contentTextField;
@synthesize confirmButton = _confirmButton;
@synthesize cancelButton = _cancelButton;
@synthesize delegate = _delegate;

+ (OVNonModalAlertWindowController *)sharedInstance
{
    static OVNonModalAlertWindowController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OVNonModalAlertWindowController alloc] initWithWindowNibName:@"OVNonModalAlertWindowController"];
        [instance window];
    });
    return instance;
}

// Suppress the use of the MIN/MAX macros
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu-statement-expression"

- (void)showWithTitle:(NSString *)title content:(NSString *)content confirmButtonTitle:(NSString *)confirmTitle cancelButtonTitle:(NSString *)cancelButtonTitle cancelAsDefault:(BOOL)cancelAsDefault delegate:(id <OVNonModalAlertWindowControllerDelegate>)delegate;
{
    // cancel previous alert
    if (self.window.visible) {
        if ([_delegate respondsToSelector:@selector(nonModalAlertWindowControllerDidCancel:)]) {
            [_delegate nonModalAlertWindowControllerDidCancel:self];
        }
    }

    _delegate = delegate;

    NSRect oldFrame = self.confirmButton.frame;
    [self.confirmButton setTitle:confirmTitle];
    [self.confirmButton sizeToFit];

    NSRect newFrame = self.confirmButton.frame;

    newFrame.size.width = MAX(90.0, (newFrame.size.width + 10.0));
    newFrame.origin.x += (oldFrame.size.width - newFrame.size.width);
    [self.confirmButton setFrame:newFrame];

    if (cancelButtonTitle) {
        [self.cancelButton setTitle:cancelButtonTitle];
        [self.cancelButton sizeToFit];
        NSRect adjustedFrame = self.cancelButton.frame;
        adjustedFrame.size.width = MAX(90.0, (adjustedFrame.size.width + 10.0));
        adjustedFrame.origin.x = newFrame.origin.x - adjustedFrame.size.width;
        self.cancelButton.frame = adjustedFrame;
        self.cancelButton.hidden = NO;
    }
    else {
        self.cancelButton.hidden = YES;
    }

    self.cancelButton.nextKeyView = self.confirmButton;
    self.confirmButton.nextKeyView = self.cancelButton;

    if (cancelButtonTitle) {
        if (cancelAsDefault) {
            [self.window setDefaultButtonCell:self.cancelButton.cell];
        }
        else {
            self.cancelButton.keyEquivalent = @" ";
            [self.window setDefaultButtonCell:self.confirmButton.cell];
        }
    }
    else {
        [[self window] setDefaultButtonCell:self.confirmButton.cell];
    }

    self.titleTextField.stringValue = title;

    oldFrame = [self.contentTextField frame];
    self.contentTextField.stringValue = content;

    NSRect infiniteHeightFrame = oldFrame;
    infiniteHeightFrame.size.width -= 4.0;
    infiniteHeightFrame.size.height = 10240;
    newFrame = [content boundingRectWithSize:infiniteHeightFrame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.contentTextField.font}];
    newFrame.size.width = MAX(newFrame.size.width, oldFrame.size.width);
    newFrame.size.height += 4.0;
    newFrame.origin = oldFrame.origin;
    newFrame.origin.y -= (newFrame.size.height - oldFrame.size.height);
    [self.contentTextField setFrame:newFrame];

    NSRect windowFrame = [[self window] frame];
    windowFrame.size.height += (newFrame.size.height - oldFrame.size.height);

    self.window.level = CGShieldingWindowLevel() + 1;
    [self.window setFrame:windowFrame display:YES];
    [self.window center];
    [self.window makeKeyAndOrderFront:self];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

#pragma GCC diagnostic pop

- (IBAction)confirmButtonAction:(id)sender
{
    [_delegate nonModalAlertWindowControllerDidConfirm:self];
    [self.window orderOut:self];
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self cancel:sender];
}

- (void)cancel:(id)sender
{
    if ([_delegate respondsToSelector:@selector(nonModalAlertWindowControllerDidCancel:)]) {
        [_delegate nonModalAlertWindowControllerDidCancel:self];
    }

    _delegate = nil;
    [self.window orderOut:self];
}

@end
