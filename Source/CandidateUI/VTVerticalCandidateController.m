//
// VTVerticalCandidateController.m
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

#import "VTVerticalCandidateController.h"
#import "VTVerticalKeyLabelStripView.h"
#import "VTVerticalCandidateTableView.h"

// use these instead of MIN/MAX macro to keep compilers happy with pedantic warnings on
NS_INLINE CGFloat min(CGFloat a, CGFloat b) { return a < b ? a : b; }
NS_INLINE CGFloat max(CGFloat a, CGFloat b) { return a > b ? a : b; }

static const CGFloat kCandidateTextPadding = 24.0;
static const CGFloat kCandidateTextLeftMargin = 8.0;

@interface VTVerticalCandidateController (Private) <NSTableViewDataSource, NSTableViewDelegate>
- (void)rowDoubleClicked:(id)sender;
- (BOOL)scrollPageByOne:(BOOL)forward;
- (BOOL)moveSelectionByOne:(BOOL)forward;
- (void)layoutCandidateView;
@end

@implementation VTVerticalCandidateController

- (void)dealloc
{
    [_candidateTextParagraphStyle release];
    [_keyLabelStripView release];
    [_scrollView release];
    [_tableView release];
    [super dealloc];
}

- (id)init
{
    NSRect contentRect = NSMakeRect(128.0, 128.0, 0.0, 0.0);
    NSUInteger styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask;
    
    NSPanel *panel = [[[NSPanel alloc] initWithContentRect:contentRect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO] autorelease];
    [panel setLevel:CGShieldingWindowLevel() + 1];
    [panel setHasShadow:YES];

    self = [self initWithWindow:panel];
    if (self) {
        _candidateTextParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [_candidateTextParagraphStyle setFirstLineHeadIndent:kCandidateTextLeftMargin];
        [_candidateTextParagraphStyle setLineBreakMode:NSLineBreakByClipping];
        
        contentRect.origin = NSMakePoint(0.0, 0.0);
        
        NSRect stripRect = contentRect;
        stripRect.size.width = 10.0;
        _keyLabelStripView = [[VTVerticalKeyLabelStripView alloc] initWithFrame:stripRect];
        
        [[panel contentView] addSubview:_keyLabelStripView];
        
        NSRect scrollViewRect = contentRect;
        scrollViewRect.origin.x = stripRect.size.width;
        scrollViewRect.size.width -= stripRect.size.width;
        
        _scrollView = [[NSScrollView alloc] initWithFrame:scrollViewRect];        
        
        // >=10.7 only, elastic scroll causes some drawing issues with visible scroller, so we disable it
        if ([_scrollView respondsToSelector:@selector(setVerticalScrollElasticity:)]) {
            [_scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
        }
        
        _tableView = [[VTVerticalCandidateTableView alloc] initWithFrame:contentRect];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        
        NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"candidate"] autorelease];    
        [column setEditable:NO];
        
        [_tableView addTableColumn:column];
        [_tableView setIntercellSpacing:NSMakeSize(0.0, 1.0)];
        [_tableView setHeaderView:nil];
        [_tableView setAllowsMultipleSelection:NO];
        [_tableView setAllowsEmptySelection:YES];
        [_tableView setDoubleAction:@selector(rowDoubleClicked:)];
        [_tableView setTarget:self];

        [_scrollView setDocumentView:_tableView];
        [[panel contentView] addSubview:_scrollView];
    }
    
    return self;
}

- (void)reloadData
{
    _maxCandidateAttrStringWidth = ceil([_candidateFont pointSize] * 2.0 + kCandidateTextPadding);

    [_tableView reloadData];
    [self layoutCandidateView];
    
    if ([_delegate candidateCountForController:self]) {
        self.selectedCandidateIndex = 0;
    }
}

- (BOOL)showNextPage
{
    return [self scrollPageByOne:YES];
}

- (BOOL)showPreviousPage
{
    return [self scrollPageByOne:NO];
}

- (BOOL)highlightNextCandidate
{
    return [self moveSelectionByOne:YES];
}

- (BOOL)highlightPreviousCandidate
{
    return [self moveSelectionByOne:NO];    
}

- (NSUInteger)candidateIndexAtKeyLabelIndex:(NSUInteger)index
{
    NSInteger firstVisibleRow = [_tableView rowAtPoint:[_scrollView documentVisibleRect].origin];
    if (firstVisibleRow != -1) {
        NSUInteger result = firstVisibleRow + index;
        if (result < [_delegate candidateCountForController:self]) {
            return result;
        }
    }
        
    return NSUIntegerMax;
}

- (NSUInteger)selectedCandidateIndex
{
    NSInteger selectedRow = [_tableView selectedRow];
    return (selectedRow == -1) ? NSUIntegerMax : selectedRow;
}

- (void)setSelectedCandidateIndex:(NSUInteger)newIndex
{
    NSInteger selectedRow = [_tableView selectedRow];

    NSUInteger labelCount = [_keyLabels count];
    NSUInteger itemCount = [_delegate candidateCountForController:self];
    
    NSUInteger lastVisibleRow = newIndex;
    
    if (selectedRow != -1 && itemCount > 0 && itemCount > labelCount) {
        if (newIndex > selectedRow && (newIndex - selectedRow) > 1) {
            lastVisibleRow = min(newIndex + labelCount - 1, itemCount - 1);            
        }
        
        // no need to handle the backward case: (newIndex < selectedRow && selectedRow - newIndex > 1)
    }
    
    if (itemCount > labelCount) {
        [_tableView scrollRowToVisible:lastVisibleRow];
    }
    
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
}


@end


@implementation VTVerticalCandidateController (Private)
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_delegate candidateCountForController:self];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *candidate = @"";

    // rendering can occur when the delegate is already gone or data goes stale; in that case we ignore it    

    if (row < [_delegate candidateCountForController:self]) {
        candidate = [_delegate candidateController:self candidateAtIndex:row];
    }

    NSAttributedString *attrString = [[[NSAttributedString alloc] initWithString:candidate attributes:[NSDictionary dictionaryWithObjectsAndKeys:_candidateFont, NSFontAttributeName, _candidateTextParagraphStyle, NSParagraphStyleAttributeName, nil]] autorelease];    
    
    // we do more work than what this method is expected to; normally not a good practice, but for the amount of data (9 to 10 rows max), we can afford the overhead
    
    // expand the window width if text overflows
    NSRect boundingRect = [attrString boundingRectWithSize:NSMakeSize(10240.0, 10240.0) options:NSStringDrawingUsesLineFragmentOrigin];
    CGFloat textWidth = boundingRect.size.width + kCandidateTextPadding;
    if (textWidth > _maxCandidateAttrStringWidth) {
        _maxCandidateAttrStringWidth = textWidth;
        [self layoutCandidateView];
    }
    
    // keep track of the highlighted index in the key label strip
    NSUInteger count = [_keyLabels count];
    NSInteger selectedRow = [_tableView selectedRow];    
    if (selectedRow != -1) {
        // cast this into signed integer to make our life easier
        NSInteger newHilightIndex;
        
        if (_keyLabelStripView.highlightedIndex != -1 && (row >= selectedRow + count || (selectedRow > count && row <= selectedRow - count))) {
            newHilightIndex = -1;
        }
        else {
            NSInteger firstVisibleRow = [_tableView rowAtPoint:[_scrollView documentVisibleRect].origin];
            
            newHilightIndex = selectedRow - firstVisibleRow; 
            if (newHilightIndex < -1) {
                newHilightIndex = -1;
            }
        }
        
        if (newHilightIndex != _keyLabelStripView.highlightedIndex) {
            _keyLabelStripView.highlightedIndex = newHilightIndex;
            [_keyLabelStripView setNeedsDisplay:YES];            
        }
    }

    // fix a subtle on 10.7 that, since we force the scroller to appear, scrolling sometimes shows a temporarily "broken" scroll bar (but quickly disappears)
    if ([_scrollView hasVerticalScroller]) {
        [[_scrollView verticalScroller] setNeedsDisplay];
    }
    
    return attrString;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger selectedRow = [_tableView selectedRow];
    if (selectedRow != -1) {        
        // keep track of the highlighted index in the key label strip        
        NSInteger firstVisibleRow = [_tableView rowAtPoint:[_scrollView documentVisibleRect].origin];
        _keyLabelStripView.highlightedIndex = selectedRow - firstVisibleRow;
        [_keyLabelStripView setNeedsDisplay:YES];
    }    
}

- (void)rowDoubleClicked:(id)sender
{
    NSInteger clickedRow = [_tableView clickedRow];
    if (clickedRow != -1) {
        [_delegate candidateController:self didSelectCandidateAtIndex:clickedRow];
    }
}

- (BOOL)scrollPageByOne:(BOOL)forward
{
    NSUInteger labelCount = [_keyLabels count];
    NSUInteger itemCount = [_delegate candidateCountForController:self];
    
    if (0 == itemCount) {
        return NO;
    }
    
    if (itemCount <= labelCount) {
        return NO;
    }
    
    NSUInteger newIndex = self.selectedCandidateIndex;

    if (forward) {
        if (newIndex == itemCount - 1) {
            return NO;
        }
        
        newIndex = min(newIndex + labelCount, itemCount - 1);
    }
    else {
        if (newIndex == 0) {
            return NO;
        }
        
        if (newIndex < labelCount) {
            newIndex = 0;
        }
        else {
            newIndex -= labelCount;
        }
    }
    
    self.selectedCandidateIndex = newIndex;    
    return YES;    
}

- (BOOL)moveSelectionByOne:(BOOL)forward
{
    NSUInteger itemCount = [_delegate candidateCountForController:self];
    
    if (0 == itemCount) {
        return NO;
    }
    
    NSUInteger newIndex = self.selectedCandidateIndex;
    
    if (forward) {
        if (newIndex == itemCount - 1) {
            return NO;
        }
        
        newIndex++;
    }
    else {
        if (0 == newIndex) {
            return NO;
        }

        newIndex--;
    }
    
    self.selectedCandidateIndex = newIndex;    
    return YES;
}
                           
- (void)layoutCandidateView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(deferredLayoutCandidateView) object:nil];
    [self performSelector:@selector(deferredLayoutCandidateView) withObject:nil afterDelay:0.0];
}

- (void)deferredLayoutCandidateView
{
    NSUInteger count = [_delegate candidateCountForController:self];
    if (!count) {
        return;
    }
    
    CGFloat candidateFontSize = ceil([_candidateFont pointSize]);
    CGFloat keyLabelFontSize = ceil([_keyLabelFont pointSize]);
    CGFloat fontSize = max(candidateFontSize, keyLabelFontSize);
    
    NSControlSize controlSize = (fontSize > 36.0) ? NSRegularControlSize : NSSmallControlSize;
    
    NSUInteger keyLabelCount = [_keyLabels count];
    CGFloat scrollerWidth = 0.0;
    if (count <= keyLabelCount) {
        keyLabelCount = count;
        [_scrollView setHasVerticalScroller:NO];
    }
    else {
        [_scrollView setHasVerticalScroller:YES];

        NSScroller *verticalScroller = [_scrollView verticalScroller];
        [verticalScroller setControlSize:controlSize];
        
        // calling >=10.7 only API
        if ([verticalScroller respondsToSelector:@selector(setScrollerStyle:)]) {
            [verticalScroller setScrollerStyle:NSScrollerStyleLegacy];
            scrollerWidth = [NSScroller scrollerWidthForControlSize:controlSize scrollerStyle:NSScrollerStyleLegacy];
        }
        else {
            // not on >=10.7
            scrollerWidth = [NSScroller scrollerWidthForControlSize:controlSize];
        }
    }

    _keyLabelStripView.keyLabelFont = _keyLabelFont;
    _keyLabelStripView.keyLabels = [_keyLabels subarrayWithRange:NSMakeRange(0, keyLabelCount)];
    _keyLabelStripView.labelOffsetY = (keyLabelFontSize >= candidateFontSize) ? 0.0 : floor((candidateFontSize - keyLabelFontSize) / 2.0);
    
    CGFloat rowHeight = ceil(fontSize * 1.25);
    [_tableView setRowHeight:rowHeight];
    
    CGFloat rowSpacing = [_tableView intercellSpacing].height;    
    CGFloat stripWidth = ceil(keyLabelFontSize * 1.20);
    CGFloat tableViewStartWidth = ceil(_maxCandidateAttrStringWidth + scrollerWidth);;
    CGFloat windowWidth = stripWidth + 1.0 + tableViewStartWidth;
    CGFloat windowHeight = keyLabelCount * (rowHeight + rowSpacing);
    
    NSRect frameRect = [[self window] frame];
    NSPoint topLeftPoint = NSMakePoint(frameRect.origin.x, frameRect.origin.y + frameRect.size.height);
    
    frameRect.size = NSMakeSize(windowWidth, windowHeight);
    frameRect.origin = NSMakePoint(topLeftPoint.x, topLeftPoint.y - frameRect.size.height);    
    
    [_keyLabelStripView setFrame:NSMakeRect(0.0, 0.0, stripWidth, windowHeight)];
    [_scrollView setFrame:NSMakeRect(stripWidth + 1.0, 0.0, tableViewStartWidth, windowHeight)];
    [[self window] setFrame:frameRect display:YES];
}
@end
