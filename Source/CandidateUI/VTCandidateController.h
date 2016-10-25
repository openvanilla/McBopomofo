//
// VTCandidateController.h
//
// Copyright (c) 2012 Lukhnos D. Liu (http://lukhnos.org)
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

#import <Cocoa/Cocoa.h>

@class VTCandidateController;

@protocol VTCandidateControllerDelegate
- (NSUInteger)candidateCountForController:(VTCandidateController *)controller;
- (NSString *)candidateController:(VTCandidateController *)controller candidateAtIndex:(NSUInteger)index;
- (void)candidateController:(VTCandidateController *)controller didSelectCandidateAtIndex:(NSUInteger)index;
@end

@interface VTCandidateController : NSWindowController
{
@protected
    id<VTCandidateControllerDelegate> _delegate;
    NSArray *_keyLabels;
    NSFont *_keyLabelFont;
    NSFont *_candidateFont;
}

- (void)reloadData;

- (BOOL)showNextPage;
- (BOOL)showPreviousPage;
- (BOOL)highlightNextCandidate;
- (BOOL)highlightPreviousCandidate;

- (void)setWindowTopLeftPoint:(NSPoint)topLeftPoint bottomOutOfScreenAdjustmentHeight:(CGFloat)height;

- (NSUInteger)candidateIndexAtKeyLabelIndex:(NSUInteger)index;

@property (assign, weak, nonatomic) id<VTCandidateControllerDelegate> delegate;
@property (assign, nonatomic) NSUInteger selectedCandidateIndex;

@property (assign, nonatomic) BOOL visible;
@property (assign, nonatomic) NSPoint windowTopLeftPoint;

@property (copy, nonatomic) NSArray *keyLabels;
@property (copy, nonatomic) NSFont *keyLabelFont;
@property (copy, nonatomic) NSFont *candidateFont;
@end
