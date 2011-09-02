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
@synthesize selectedTISIconRendererView;
@synthesize faviconRenderView;
@synthesize window;

- (void)makeIconForObject:(id)object size:(NSSize)size filename:(NSString *)name
{
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size = size;
    
    NSView *view = nil;
    if ([object isKindOfClass:[NSView class]]) {
        view = object;
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
    selectedTISIconRendererView.selected = YES;
    [selectedTISIconRendererView setNeedsDisplay:YES];

    faviconRenderView.favicon = YES;
    faviconRenderView.selected = YES;
    [faviconRenderView setNeedsDisplay:YES];
    
    [self makeIconForObject:@"TISIconRendererView" size:NSMakeSize(16, 16) filename:@"/tmp/Bopomofo.tiff"];
    [self makeIconForObject:selectedTISIconRendererView size:NSMakeSize(16, 16) filename:@"/tmp/BopomofoSelected.tiff"];
    [self makeIconForObject:faviconRenderView size:NSMakeSize(16, 16) filename:@"/tmp/BopomofoFavicon.tiff"];

    
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(32, 32) filename:@"/tmp/Bopomofo-32.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(57, 57) filename:@"/tmp/Bopomofo-57.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(64, 64) filename:@"/tmp/Bopomofo-64.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(72, 72) filename:@"/tmp/Bopomofo-72.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(128, 128) filename:@"/tmp/Bopomofo-128.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(144, 144) filename:@"/tmp/Bopomofo-144.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(256, 256) filename:@"/tmp/Bopomofo-256.tiff"];
    [self makeIconForObject:@"AppIconRendererView" size:NSMakeSize(512, 512) filename:@"/tmp/Bopomofo-512.tiff"];    
    
    NSRunAlertPanel(@"Icons Generated", @"TIFF files are placed in /tmp", @"Dismiss", nil, nil);    
}

@end
