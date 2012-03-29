//
// VTHorizontalCandidateView.m
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

#import "VTHorizontalCandidateView.h"

// use these instead of MIN/MAX macro to keep compilers happy with pedantic warnings on
NS_INLINE CGFloat min(CGFloat a, CGFloat b) { return a < b ? a : b; }
NS_INLINE CGFloat max(CGFloat a, CGFloat b) { return a > b ? a : b; }

@implementation VTHorizontalCandidateView

@synthesize highlightedIndex = _highlightedIndex;
@synthesize action = _action;
@synthesize target = _target;

- (void)dealloc
{
    [_keyLabels release];
    [_displayedCandidates release];
    [_keyLabelAttrDict release];
    [_candidateAttrDict release];
    [_CJKCandidateAttrDict release];
    [_elementWidths release];
    [super dealloc];
}

- (void)setKeyLabels:(NSArray *)labels displayedCandidates:(NSArray *)candidates
{
    NSUInteger count = min([labels count], [candidates count]);
    id tmp;
    
    tmp = _keyLabels;
    _keyLabels = [[labels subarrayWithRange:NSMakeRange(0, count)] retain];
    [tmp release];
    
    tmp = _displayedCandidates;
    _displayedCandidates = [[candidates subarrayWithRange:NSMakeRange(0, count)] retain];
    [tmp release];
    
    NSMutableArray *newWidths = [NSMutableArray array];
    
    NSSize baseSize = NSMakeSize(10240.0, 10240.0);
    for (NSUInteger index = 0; index < count; index++) {
        NSRect labelRect = [[_keyLabels objectAtIndex:index] boundingRectWithSize:baseSize options:NSStringDrawingUsesLineFragmentOrigin attributes:_keyLabelAttrDict];
        
        // TODO: Handle CJK text drawing
        NSRect candidateRect = [[_displayedCandidates objectAtIndex:index] boundingRectWithSize:baseSize options:NSStringDrawingUsesLineFragmentOrigin attributes:_candidateAttrDict];
        
        CGFloat width = max(labelRect.size.width, candidateRect.size.width) + _cellPadding;
        [newWidths addObject:[NSNumber numberWithDouble:width]];
    }
    
    tmp = _elementWidths;
    _elementWidths = [newWidths retain];
    [tmp release];
}

- (void)setKeyLabelFont:(NSFont *)labelFont candidateFont:(NSFont *)candidateFont CJKCandidateFont:(NSFont *)candidateFontCJK
{
    NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [paraStyle setAlignment:NSCenterTextAlignment];
    
    id tmp;
    tmp = _keyLabelAttrDict;
    _keyLabelAttrDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                         labelFont, NSFontAttributeName,
                         paraStyle, NSParagraphStyleAttributeName,
                         [NSColor textColor], NSForegroundColorAttributeName,
                          nil] retain];
    [tmp release];
    
    tmp = _candidateAttrDict;
    _candidateAttrDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                           candidateFont, NSFontAttributeName,
                           paraStyle, NSParagraphStyleAttributeName,
                           [NSColor textColor], NSForegroundColorAttributeName,
                           nil] retain];
    [tmp release];
    
    tmp = _CJKCandidateAttrDict;
    _CJKCandidateAttrDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                              candidateFontCJK, NSFontAttributeName,
                              paraStyle, NSParagraphStyleAttributeName,
                              [NSColor textColor], NSForegroundColorAttributeName,
                              nil] retain];
    [tmp release];


    CGFloat labelFontSize = [labelFont pointSize];
    CGFloat candidateFontSize = max([candidateFont pointSize], [candidateFontCJK pointSize]);
    CGFloat biggestSize = max(labelFontSize, candidateFontSize);
    
    _keyLabelHeight = ceil(labelFontSize * 1.20);
    _candidateTextHeight = ceil(candidateFontSize * 1.20);
    _cellPadding = ceil(biggestSize / 2.0);
}


- (NSSize)sizeForView
{
    NSSize result = NSMakeSize(0.0, 0.0);
    if ([_elementWidths count]) {    
        for (NSNumber *w in _elementWidths) {
            result.width += [w doubleValue];
        }
        
        result.width += [_elementWidths count];
        result.height = _keyLabelHeight + _candidateTextHeight + 1.0;
    }
    
    return result;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *white = [NSColor whiteColor];
    NSColor *darkGray = [NSColor colorWithDeviceWhite:0.7 alpha:1.0];
    NSColor *lightGray = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];
    
    NSRect bounds = [self bounds];
    
    [white setFill];
    [NSBezierPath fillRect:bounds];
    
    [[NSColor darkGrayColor] setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(bounds.size.width, 0.0) toPoint:NSMakePoint(bounds.size.width, bounds.size.height)];

    NSUInteger count = [_elementWidths count];
    CGFloat accuWidth = 0.0;    
    
    for (NSUInteger index = 0; index < count; index++) {
        NSDictionary *activeCandidateAttr = _candidateAttrDict;
        CGFloat currentWidth = [[_elementWidths objectAtIndex:index] doubleValue];
        NSRect labelRect = NSMakeRect(accuWidth, 0.0, currentWidth, _keyLabelHeight);
        NSRect candidateRect = NSMakeRect(accuWidth, _keyLabelHeight + 1.0, currentWidth, _candidateTextHeight);

        if (index == _highlightedIndex) {
            [darkGray setFill];
        }
        else {
            [lightGray setFill];
        }
        
        [NSBezierPath fillRect:labelRect];
        [[_keyLabels objectAtIndex:index] drawInRect:labelRect withAttributes:_keyLabelAttrDict];
        
        if (index == _highlightedIndex) {
            [[NSColor selectedTextBackgroundColor] setFill];
            
            activeCandidateAttr = [[_candidateAttrDict mutableCopy] autorelease];
            [(NSMutableDictionary *)activeCandidateAttr setObject:[NSColor selectedTextColor] forKey:NSForegroundColorAttributeName];
        }
        else {
            [white setFill];
        }        
        
        [NSBezierPath fillRect:candidateRect];
        [[_displayedCandidates objectAtIndex:index] drawInRect:candidateRect withAttributes:activeCandidateAttr];
        
        accuWidth += currentWidth + 1.0;
    }
}

- (NSUInteger)findHitIndex:(NSEvent *)theEvent
{
    NSUInteger result = NSUIntegerMax;
    
    NSPoint location = [self convertPoint:[theEvent locationInWindow] toView:nil];
    if (!NSPointInRect(location, [self bounds])) {
        return result;
    }
    
    NSUInteger count = [_elementWidths count];    
    CGFloat accuWidth = 0.0;
    for (NSUInteger index = 0; index < count; index++) {
        CGFloat currentWidth = [[_elementWidths objectAtIndex:index] doubleValue];

        if (location.x >= accuWidth && location.x <= accuWidth + currentWidth) {
            result = index;
            break;
        }
        
        accuWidth += currentWidth + 1.0;        
    }
    
    return result;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSUInteger newIndex = [self findHitIndex:theEvent];
    _trackingHighlightedIndex = _highlightedIndex;

    if (newIndex != NSUIntegerMax) {
        _highlightedIndex = newIndex;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSUInteger newIndex = [self findHitIndex:theEvent];
    BOOL triggerAction = NO;

    if (newIndex == _highlightedIndex) {
        triggerAction = YES;
    }
    else {
        _highlightedIndex = _trackingHighlightedIndex;
    }

    _trackingHighlightedIndex = 0;
    [self setNeedsDisplay:YES];

    if (triggerAction && _target && _action) {
        [_target performSelector:_action withObject:self];            
    }
}

@end
