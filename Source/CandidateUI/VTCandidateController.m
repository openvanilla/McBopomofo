//
// VTCandidateController.m
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

#import "VTCandidateController.h"


@implementation VTCandidateController
@synthesize delegate = _delegate;
@synthesize keyLabels = _keyLabels;
@synthesize keyLabelFont = _keyLabelFont;
@synthesize candidateFont = _candidateFont;
@synthesize CJKCandidateFont = _CJKCandidateFont;

- (void)dealloc
{
    [_keyLabels release];
    [_keyLabelFont release];
    [_candidateFont release];
    [_CJKCandidateFont release];
    [super dealloc];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // populate the default values        
        _keyLabels = [[NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", nil] retain];
        _keyLabelFont = [[NSFont systemFontOfSize:14.0] retain];
        _candidateFont = [[NSFont systemFontOfSize:18.0] retain];
        _CJKCandidateFont = [_candidateFont retain];
    }
    
    return self;
}

- (void)reloadData
{
}

- (BOOL)showNextPage
{
    return NO;
}

- (BOOL)showPreviousPage
{
    return NO;
}

- (BOOL)highlightNextCandidate
{
    return NO;
}

- (BOOL)highlightPreviousCandidate
{
    return NO;
}

- (void)setWindowTopLeftPoint:(NSPoint)topLeftPoint bottomOutOfScreenAdjustmentHeight:(CGFloat)height
{
    NSPoint adjustedPoint = topLeftPoint;
    CGFloat adjustedHeight = height;
    
    // first, locate the screen the point is in
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect frame = [screen visibleFrame];
        if (topLeftPoint.x >= NSMinX(frame) && topLeftPoint.x <= NSMaxX(frame)) {
            screenFrame = frame;
            break;
        }
    }
    
    // make sure we don't have any erratic value
    if (adjustedHeight > screenFrame.size.height / 2.0) {
        adjustedHeight = 0.0;
    }
    
    NSSize windowSize = [[self window] frame].size;
    
    // bottom beneath the screen?
    if (adjustedPoint.y - windowSize.height < NSMinY(screenFrame)) {
        adjustedPoint.y = topLeftPoint.y + adjustedHeight + windowSize.height;
    }
    
    // top over the screen?
    if (adjustedPoint.y >= NSMaxY(screenFrame)) {
        adjustedPoint.y = NSMaxY(screenFrame) - 1.0;
    }
    
    // right
    if (adjustedPoint.x + windowSize.width >= NSMaxX(screenFrame)) {
        adjustedPoint.x = NSMaxX(screenFrame) - windowSize.width;
    }
    
    // left
    if (adjustedPoint.x < NSMinX(screenFrame)) {
        adjustedPoint.x = NSMinX(screenFrame);
    }
    
    [[self window] setFrameTopLeftPoint:adjustedPoint];
}

- (NSUInteger)candidateIndexAtKeyLabelIndex:(NSUInteger)index
{
    return NSUIntegerMax;
}

- (BOOL)visible
{
    return [[self window] isVisible];
}

- (void)setVisible:(BOOL)visible
{
    if (visible) {
        [[self window] orderFront:self];
    }
    else {
        [[self window] orderOut:self];
    }
}

- (NSPoint)windowTopLeftPoint
{
    NSRect frameRect = [[self window] frame];
    return NSMakePoint(frameRect.origin.x, frameRect.origin.y + frameRect.size.height);
}

- (void)setWindowTopLeftPoint:(NSPoint)topLeftPoint
{
    [self setWindowTopLeftPoint:topLeftPoint bottomOutOfScreenAdjustmentHeight:0.0];
}

- (NSUInteger)selectedCandidateIndex
{
    return NSUIntegerMax;
}

- (void)setSelectedCandidateIndex:(NSUInteger)newIndex
{
}
@end
