//
//  BopomofoIconRenderView.m
//  Lettuce
//
//  Created by Lukhnos D. Liu on 9/3/12.
//
//

#import "BopomofoIconRenderView.h"

@implementation BopomofoIconRenderView
- (void)drawRect:(NSRect)dirtyRect
{
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform scaleBy:[self bounds].size.width / 16.0];
    [transform concat];

    NSRect boundsRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);

    if ([self bounds].size.width > 16.0) {
        boundsRect.origin.x += 0.5;
    }
    
    boundsRect.size.width -= 1.0;

    [NSGraphicsContext saveGraphicsState];

    NSColor *darkGrayColor = [NSColor colorWithDeviceWhite:0.3 alpha:1.0];
    [darkGrayColor setFill];
    [[NSBezierPath bezierPathWithRoundedRect:boundsRect xRadius:2.0 yRadius:2.0] fill];
    [NSGraphicsContext restoreGraphicsState];


    NSInteger fontSize = ([self bounds].size.width > 16.0) ? 14.0 : 13.5;

    NSString *text = @"ㄅ";
    NSString *fontName = @"BiauKai";

    NSColor *textColor = nil;
    textColor = [NSColor colorWithDeviceWhite:1.0 alpha:1.0];
    NSMutableDictionary *attrDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     textColor, NSForegroundColorAttributeName,
                                     [NSFont fontWithName:fontName size:fontSize], NSFontAttributeName,
                                     nil];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:text attributes:attrDict];

    NSRect textBounds = [attrString boundingRectWithSize:boundsRect.size options:NSStringDrawingUsesLineFragmentOrigin];

    NSPoint textOrigin;
    textOrigin.x = boundsRect.origin.x + (boundsRect.size.width - textBounds.size.width) / 2.0;
    textOrigin.y = boundsRect.origin.y;

    attrString = [[NSAttributedString alloc] initWithString:text attributes:attrDict];
    [attrString drawAtPoint:textOrigin];    
}
@end
