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

    NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRoundedRect:boundsRect xRadius:2.0 yRadius:2.0];
    if (self.textMenuIcon) {
        [[NSColor colorWithDeviceWhite:0.95 alpha:1.0] setFill];
        [[NSColor colorWithDeviceWhite:0.6 alpha:1.0] setStroke];
        [backgroundPath fill];

        NSRect innerBoundRect = boundsRect;
        innerBoundRect.size.width -= 1.0;
        innerBoundRect.size.height -= 1.0;
        innerBoundRect.origin.x += 0.5;
        innerBoundRect.origin.y += 0.5;
        backgroundPath = [NSBezierPath bezierPathWithRoundedRect:innerBoundRect xRadius:2.0 yRadius:2.0];
        [backgroundPath stroke];

        [NSGraphicsContext saveGraphicsState];
        NSBezierPath *coveringPath = [NSBezierPath bezierPath];
        [coveringPath appendBezierPathWithArcWithCenter:NSMakePoint(16.0, 1.0) radius:14.0 startAngle:0.0 endAngle:360.0];
        [coveringPath setClip];

        [[NSColor colorWithDeviceWhite:0.3 alpha:1.0] setStroke];
        backgroundPath = [NSBezierPath bezierPathWithRoundedRect:innerBoundRect xRadius:2.0 yRadius:2.0];
        [backgroundPath stroke];
        [NSGraphicsContext restoreGraphicsState];
    }
    else {
        if (self.plainBopomofoIcon) {
            if ([self bounds].size.width > 16.0) {
                [[NSColor colorWithDeviceWhite:0.3 alpha:1.0] setFill];
            }
            else {
                [[NSColor colorWithDeviceWhite:0.1 alpha:1.0] setFill];
            }
        }
        else {
            [[NSColor colorWithDeviceWhite:0.3 alpha:1.0] setFill];
        }
        [backgroundPath fill];
    }


    CGFloat fontSize = ([self bounds].size.width > 16.0) ? 14.0 : 13.0;
    NSString *text = @"ㄅ";
    NSString *fontName = @"BiauKai";

    NSColor *textColor = nil;

    if (self.textMenuIcon) {
        textColor = [NSColor blackColor];
    }
    else if (self.plainBopomofoIcon) {
        textColor = [NSColor colorWithDeviceWhite:0.95 alpha:1.0];
    }
    else {
        textColor = [NSColor colorWithDeviceWhite:1.0 alpha:1.0];
    }

    NSMutableDictionary *attrDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     textColor, NSForegroundColorAttributeName,
                                     [NSFont fontWithName:fontName size:fontSize], NSFontAttributeName,
                                     nil];
    NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:text attributes:attrDict] autorelease];

    NSRect textBounds = [attrString boundingRectWithSize:boundsRect.size options:NSStringDrawingUsesLineFragmentOrigin];

    NSPoint textOrigin;
    textOrigin.x = boundsRect.origin.x + (boundsRect.size.width - textBounds.size.width) / 2.0;
    textOrigin.y = boundsRect.origin.y;

    [attrString drawAtPoint:textOrigin];

    if (self.plainBopomofoIcon) {
        NSBezierPath *coveringPath = [NSBezierPath bezierPath];
        [coveringPath appendBezierPathWithArcWithCenter:NSMakePoint(16.0, -3.0) radius:13.0 startAngle:0.0 endAngle:360.0];
        [coveringPath setClip];

        if (!([self bounds].size.width > 16.0)) {
            [[NSColor colorWithDeviceWhite:0.6 alpha:1.0] setFill];
        }
        else {
            [[NSColor colorWithDeviceWhite:0.65 alpha:1.0] setFill];
        }

        [backgroundPath fill];
        
        [attrDict setObject:[NSColor colorWithDeviceWhite:1.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
        [attrString setAttributes:attrDict range:NSMakeRange(0, [text length])];
        [attrString drawAtPoint:textOrigin];
    }
}
@end
