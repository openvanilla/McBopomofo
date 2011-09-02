//
// TISIconRendererView.m
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

#import "TISIconRendererView.h"

@implementation TISIconRendererView
@synthesize selected;
@synthesize favicon;

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect boundsRect = [self bounds];
    
    if (favicon) {
        boundsRect.origin.x += 0.0;
        boundsRect.origin.y += 1.0;
        boundsRect.size.width -= 1.0;
        boundsRect.size.height -= 2.0;
        
        NSBezierPath *roundRectPath = [NSBezierPath bezierPathWithRoundedRect:boundsRect xRadius:1 yRadius:2];
        [[NSColor grayColor] setFill];
        [roundRectPath fill];
        
        boundsRect.origin.x += 0.0;
        boundsRect.origin.y += 1.0;
        boundsRect.size.width -= 1.0;
        boundsRect.size.height -= 1.0;
        
    }
    else {
        boundsRect.origin.x += 0.0;
        boundsRect.origin.y += 1.0;
        boundsRect.size.width -= 1.0;
        boundsRect.size.height -= 1.0;        
    }
    
    NSInteger fontSize = 16;
    if (favicon) {
        fontSize = 11;
    }
    
    NSString *text = @"ㄅ";
    NSString *fontName = @"LiSong Pro";

    NSColor *textColor = nil;
    NSColor *shadowColor = nil;
    if (!selected) {
        textColor = [NSColor blackColor];
        shadowColor = [NSColor colorWithDeviceWhite:0.9 alpha:0.9];
    }
    else {
        shadowColor = [NSColor darkGrayColor];
        textColor = [NSColor colorWithDeviceWhite:1.0 alpha:1.0];
    }
    
    NSShadow *textShadow = [[NSShadow alloc] init];
    [textShadow setShadowColor:shadowColor];
    [textShadow setShadowOffset:NSMakeSize(-1, -1)];
    
    NSMutableDictionary *attrDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              textColor, NSForegroundColorAttributeName,
                              textShadow, NSShadowAttributeName,
                              [NSFont fontWithName:fontName size:fontSize], NSFontAttributeName,                              
                              nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:text attributes:attrDict];

    NSRect textBounds = [attrString boundingRectWithSize:boundsRect.size options:NSStringDrawingUsesLineFragmentOrigin];
    
    NSPoint textOrigin;
    textOrigin.x = boundsRect.origin.x + (boundsRect.size.width - textBounds.size.width) / 2.0;
    
    if (favicon) {
        textOrigin.x += 1;
        textOrigin.y = boundsRect.origin.y;        
    }
    else {
        textOrigin.y = boundsRect.origin.y - 2;
    }
    
    attrString = [[NSAttributedString alloc] initWithString:text attributes:attrDict];    
    [attrString drawAtPoint:textOrigin];
    
}

@end
