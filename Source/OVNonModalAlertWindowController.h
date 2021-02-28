//
//  OVNonModalAlertWindowController.h
//  OpenVanilla
//
//  Created by Lukhnos Liu on 10/17/12.
//  Copyright (c) 2012 The OpenVanilla Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OVNonModalAlertWindowController;

@protocol OVNonModalAlertWindowControllerDelegate <NSObject>
- (void)nonModalAlertWindowControllerDidConfirm:(OVNonModalAlertWindowController *)controller;

@optional
- (void)nonModalAlertWindowControllerDidCancel:(OVNonModalAlertWindowController *)controller;
@end

@interface OVNonModalAlertWindowController : NSWindowController
{
@private
//    NSTextField *_titleTextField;
//    NSTextField *_contentTextField;
//    NSButton *_confirmButton;
//    NSButton *_cancelButton;
//    id<OVNonModalAlertWindowControllerDelegate> _delegate;
}

+ (OVNonModalAlertWindowController *)sharedInstance;
- (void)showWithTitle:(NSString *)title content:(NSString *)content confirmButtonTitle:(NSString *)confirmTitle cancelButtonTitle:(NSString *)cancelButtonTitle cancelAsDefault:(BOOL)cancelAsDefault delegate:(id<OVNonModalAlertWindowControllerDelegate>)delegate;
- (IBAction)confirmButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;
@property (assign, nonatomic) IBOutlet NSTextField *titleTextField;
@property (assign, nonatomic) IBOutlet NSTextField *contentTextField;
@property (assign, nonatomic) IBOutlet NSButton *confirmButton;
@property (assign, nonatomic) IBOutlet NSButton *cancelButton;
@property (assign, nonatomic) id<OVNonModalAlertWindowControllerDelegate> delegate;
@end
