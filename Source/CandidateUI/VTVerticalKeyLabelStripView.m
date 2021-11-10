//
// VTVerticalKeyLabelStripView.h
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

#import "VTVerticalKeyLabelStripView.h"

@implementation VTVerticalKeyLabelStripView
@synthesize keyLabelFont = _keyLabelFont;
@synthesize labelOffsetY = _labelOffsetY;
@synthesize keyLabels = _keyLabels;
@synthesize highlightedIndex = _highlightedIndex;

- (void)dealloc
{
    _keyLabelFont = nil;
    _keyLabels = nil;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _keyLabelFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    }
    
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    [[NSColor whiteColor] setFill];
    [NSBezierPath fillRect:bounds];    

    NSUInteger count = [_keyLabels count];    
    if (!count) {
        return;
    }

    CGFloat cellHeight = bounds.size.height / count;    
    NSColor *black = [NSColor blackColor];
    NSColor *darkGray = [NSColor colorWithDeviceWhite:0.7 alpha:1.0];
    NSColor *lightGray = [NSColor colorWithDeviceWhite:0.8 alpha:1.0];

    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSCenterTextAlignment];
    
    NSDictionary *textAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                              _keyLabelFont, NSFontAttributeName,
                              black, NSForegroundColorAttributeName,
                              style, NSParagraphStyleAttributeName,
                              nil];

    for (NSUInteger index = 0; index < count; index++) {
        NSRect textRect = NSMakeRect(0.0, index * cellHeight + _labelOffsetY, bounds.size.width, cellHeight - _labelOffsetY);
        NSRect cellRect = NSMakeRect(0.0, index * cellHeight, bounds.size.width, cellHeight - 1);
        
        // fill in the last cell
        if (index + 1 >= count) {
            cellRect.size.height += 1.0;
        }
        
        if (index == _highlightedIndex) {
            [darkGray setFill];
        }
        else {
            [lightGray setFill];
        }
        
        [NSBezierPath fillRect:cellRect];
        
        NSString *text = [_keyLabels objectAtIndex:index];
        [text drawInRect:textRect withAttributes:textAttr];
    }    
}
@end
