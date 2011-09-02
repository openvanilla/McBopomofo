//
// AppIconRendererView.m
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

#import "AppIconRendererView.h"


@implementation AppIconRendererView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        
//        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//        CGContextRef context = CGBitmapContextCreate(NULL, frame.size.width, frame.size.height, 8, frame.size.width, colorSpace, 0);
//        CGColorSpaceRelease(colorSpace);
        
//        imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:frame.size.width pixelsHigh:frame.size.height bitsPerSample:8 samplesPerPixel:1 hasAlpha:NO isPlanar:NO colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:0 bitsPerPixel:0];
        
        NSRect bounds;
        bounds.origin = NSZeroPoint;
        bounds.size = frame.size;

        
        
        image = [[NSImage alloc] initWithSize:frame.size];
        [image lockFocus];
        
        
        CIContext *imageContext = [[NSGraphicsContext currentContext] CIContext];

        CIFilter *filter = [CIFilter filterWithName:@"CIRandomGenerator"];
        [filter setDefaults];
        
//        CIContext *imageContext = [CIContext contextWithCGContext:context options:nil];
        
        CIImage *output = [filter valueForKey:@"outputImage"];
        
        CIFilter *mono = [CIFilter filterWithName:@"CIColorMonochrome"];
        [mono setDefaults];
        [mono setValue:output forKey:@"inputImage"];
        
        CIColor *color = [[[CIColor alloc] initWithColor:[NSColor blackColor]] autorelease];
        
        [mono setValue:color forKey:@"inputColor"];
        [mono setValue:[NSNumber numberWithDouble:1.0] forKey:@"inputIntensity"];
        output = [mono valueForKey:@"outputImage"];

        CIFilter *blur = [CIFilter filterWithName:@"CIMotionBlur"];
        [blur setDefaults];
        [blur setValue:output forKey:@"inputImage"];
        [blur setValue:[NSNumber numberWithDouble:25.0] forKey:@"inputRadius"];
        [blur setValue:[NSNumber numberWithDouble:0.0] forKey:@"inputAngle"];
        output = [blur valueForKey:@"outputImage"];
        
        
        [imageContext drawImage:output inRect:[self bounds] fromRect:[self bounds]];

        
        NSColor *transWhite = [NSColor colorWithDeviceWhite:0.9 alpha:0.2];
        NSColor *transBlack = [NSColor colorWithDeviceWhite:0.5 alpha:0.3];
        
        NSGradient *gradient = // [[[NSGradient alloc] initWithStartingColor:transBlack endingColor:transWhite] autorelease];
        [[[NSGradient alloc] initWithColorsAndLocations:
                                 transBlack, 0.0,
//                                 [NSColor darkGrayColor], 0.1,
                                 transWhite, 0.5,                                 
//                                 [NSColor darkGrayColor], 0.9,
                                 transBlack, 1.0,
                                 nil] autorelease];
//        bounds.size.width /= 2;
        [gradient drawInRect:bounds angle:0.0];
        
//        bounds.origin.x += bounds.size.width;
//        [gradient drawInRect:bounds angle:180.0];
        
//        CGBitmapContextCreateImage(context);
        
//        CGColorSpaceRef colorColorSpace = CGColorSpaceCreateDeviceRGB();
//        CGImageRef tmpImage = CGBitmapContextCreateImage(context);
//        image = CGImageCreateCopyWithColorSpace(tmpImage, colorColorSpace);
//        CGImageRelease(tmpImage);
//        CGColorSpaceRelease(colorColorSpace);

        
        
//        CGContextRelease(context);
        
        [image unlockFocus];
        
//        NSLog(@"%@", [image representations]);

//        [image addRepresentation:imageRep];
//        NSLog(@"%@", [image representations]);

//        for (NSBitmapImageRep *rep in [image representations]) {
//            [rep setColorSpaceName:NSDeviceWhiteColorSpace];
//        }
    }
    
    return self;
}

- (void)dealloc
{
//    CGImageRelease(image);
    [image release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect boundRect = [self bounds];
    CGFloat radius = 1.0;
    
    if (boundRect.size.width > 16.0 && boundRect.size.width <= 32.0) {
        boundRect.origin.x += 1.0;
        boundRect.origin.y += 1.0;
        boundRect.size.width -= 2.0;
        boundRect.size.height -= 2.0;        
        radius = 2.0;
    }
    else if (boundRect.size.width > 32.0) {
        boundRect.origin.x += 5.0;
        boundRect.origin.y += 5.0;
        boundRect.size.width -= 10.0;
        boundRect.size.height -= 10.0;
        radius = 7.0;
    }

    NSShadow *imageShadow = [[[NSShadow alloc] init] autorelease];
    [imageShadow setShadowOffset:NSMakeSize(1.0, -1.0)];
    [imageShadow setShadowColor:[NSColor darkGrayColor]];
    [imageShadow setShadowBlurRadius:radius / 2];
   
    
    NSBezierPath *clipPath = [NSBezierPath bezierPathWithRoundedRect:boundRect xRadius:radius yRadius:radius];
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [imageShadow set];
    [[NSColor whiteColor] setFill];
    [clipPath fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];

    [clipPath setClip];

    [image drawInRect:boundRect fromRect:boundRect operation:NSCompositeCopy fraction:1.0];
    
    NSString *text = @"ㄅ";
    
    if ([self bounds].size.width >= 32.0) {
        text = @"ㄅㄆ\nㄇㄈ";
    }

    NSFont *font = [NSFont fontWithName:@"LiSong Pro" size:boundRect.size.width * 0.40];
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowOffset:NSMakeSize(1.0, 1.0)];
    // [shadow setShadowBlurRadius:2.0];
    // [NSFont boldSystemFontOfSize:48.0];
    
    
    NSColor *textColor = [NSColor whiteColor];
    
    NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          font, NSFontAttributeName,
                          textColor, NSForegroundColorAttributeName,
                          shadow, NSShadowAttributeName,
                          nil];
    
    NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString:text attributes:attr] autorelease];
    
    NSRect textRect = [attrStr boundingRectWithSize:boundRect.size options:NSStringDrawingUsesLineFragmentOrigin];
    
    textRect.origin.x = boundRect.origin.x + (boundRect.size.width - textRect.size.width) / 2.0;
    textRect.origin.y = boundRect.origin.y + (boundRect.size.height - textRect.size.height) / 2.0;
    
    textRect.origin.y += boundRect.size.height * 0.025;
    
    [attrStr drawInRect:textRect];
    

//    NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithCGImage:image] autorelease];
//    
//    [imageRep colorizeByMappingGray:0.2 toColor:[NSColor greenColor] blackMapping:[NSColor darkGrayColor] whiteMapping:[NSColor redColor]];
    
//    NSImage *img = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
//    NSLog(@"%@", [img representations]);
//    
//    [img drawInRect:[self bounds] fromRect:[self bounds] operation:NSCompositeCopy fraction:1.0];
//    [img release];
    
    // [image drawRepresentation:imageRep inRect:[self bounds]];
    // [imageRep draw];
//    [imageRep drawInRect:[self bounds] fromRect:[self bounds] operation:NSCompositeCopy fraction:1.0 respectFlipped:YES hints:nil];
}

@end
