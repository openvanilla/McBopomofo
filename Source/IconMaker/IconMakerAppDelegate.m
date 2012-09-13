//
// IconMakerAppDelegate.m
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

#import "IconMakerAppDelegate.h"

@implementation IconMakerAppDelegate

- (void)makeIconForObject:(id)object size:(NSSize)size filename:(NSString *)name
{
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size = size;
    
    NSView *view = nil;
    if ([object isKindOfClass:[NSView class]]) {
        view = object;
        [view setFrame:NSMakeRect(0.0, 0.0, size.width, size.height)];
    }
    else if ([object isKindOfClass:[NSString class]]) {
        view = [[[NSClassFromString(object) alloc] initWithFrame:rect] autorelease];
    }
                                    
    NSImage *image = [[[NSImage alloc] initWithSize:size] autorelease];
    [image lockFocus];
    [view drawRect:rect];
    [image unlockFocus];
    NSData *data = [image TIFFRepresentation];
    [data writeToFile:name atomically:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.selectedTISIconRendererView.selected = YES;
    [self.selectedTISIconRendererView setNeedsDisplay:YES];

    self.faviconRenderView.favicon = YES;
    self.faviconRenderView.selected = YES;
    NSRect oldFrame = [self.faviconRenderView frame];
    [self makeIconForObject:self.faviconRenderView size:NSMakeSize(16, 16) filename:@"/tmp/BopomofoFavicon.tiff"];
    [self.faviconRenderView setFrame:oldFrame];
    [self.faviconRenderView setNeedsDisplay:YES];

    self.bopomofoIconRenderView.textMenuIcon = NO;
    self.bopomofoIconRenderView.plainBopomofoIcon = NO;
    self.bopomofoIconRenderView2x.textMenuIcon = NO;
    self.bopomofoIconRenderView2x.plainBopomofoIcon = NO;
    [self.bopomofoIconRenderView setNeedsDisplay:YES];
    [self.bopomofoIconRenderView2x setNeedsDisplay:YES];

    BopomofoIconRenderView *iconRenderView = [[[BopomofoIconRenderView alloc] init] autorelease];
    iconRenderView.textMenuIcon = NO;
    iconRenderView.plainBopomofoIcon = NO;
    [self makeIconForObject:iconRenderView size:NSMakeSize(16, 16) filename:@"/tmp/Bopomofo.tiff"];
    [self makeIconForObject:iconRenderView size:NSMakeSize(32, 32) filename:@"/tmp/Bopomofo@2x.tiff"];

    iconRenderView.textMenuIcon = NO;
    iconRenderView.plainBopomofoIcon = YES;
    [self makeIconForObject:iconRenderView size:NSMakeSize(16, 16) filename:@"/tmp/PlainBopomofo.tiff"];
    [self makeIconForObject:iconRenderView size:NSMakeSize(32, 32) filename:@"/tmp/PlainBopomofo@2x.tiff"];

    iconRenderView.plainBopomofoIcon = NO;
    iconRenderView.textMenuIcon = YES;
    [self makeIconForObject:iconRenderView size:NSMakeSize(16, 16) filename:@"/tmp/BopomofoTextMenu.tiff"];
    [self makeIconForObject:iconRenderView size:NSMakeSize(32, 32) filename:@"/tmp/BopomofoTextMenu@2x.tiff"];
     
    [self makeIconForObject:iconRenderView size:NSMakeSize(16, 16) filename:@"/tmp/icon_16x16.tiff"];
    [self makeIconForObject:iconRenderView size:NSMakeSize(32, 32) filename:@"/tmp/icon_16x16@2x.tiff"];
    [self makeIconForObject:iconRenderView size:NSMakeSize(32, 32) filename:@"/tmp/icon_32x32.tiff"];
    [self makeIconForObject:iconRenderView size:NSMakeSize(64, 64) filename:@"/tmp/icon_32x32@2x.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(128, 128) filename:@"/tmp/icon_128x128.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(256, 256) filename:@"/tmp/icon_128x128@2x.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(256, 256) filename:@"/tmp/icon_256x256.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(512, 512) filename:@"/tmp/icon_256x256@2x.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(512, 512) filename:@"/tmp/icon_512x512.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(1024, 1024) filename:@"/tmp/icon_512x512@2x.tiff"];

    NSRunAlertPanel(@"Icons Generated", @"TIFF files are placed in /tmp", @"Dismiss", nil, nil);    
}

@end
