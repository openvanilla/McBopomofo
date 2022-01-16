//
// VerticalCandidateController.swift
//
// Voltaire IME Candidate Controller Module
//
// Copyright (c) 2011-2022 The OpenVanilla Project.
// Beautified by Aiden Pearce.
//
// Contributors:
//     Lukhnos Liu (@lukhnos)
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

import Cocoa

fileprivate class VerticalKeyLabelStripView: NSView {
    var keyLabelFont: NSFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    var labelOffsetY: CGFloat = 0
    var keyLabels: [String] = []
    var highlightedIndex: UInt = UInt.max

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds
        NSColor.clear.setFill() // Disable white base color, just in case.
        NSBezierPath.fill(bounds)

        let count = UInt(keyLabels.count)
        if count == 0 {
            return
        }

        let cellHeight: CGFloat = bounds.size.height / CGFloat(count)

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.setParagraphStyle(NSParagraphStyle.default)
        paraStyle.alignment = .center

        let textAttr: [NSAttributedString.Key: AnyObject] = [
            .font: keyLabelFont,
            .foregroundColor: NSColor.secondaryLabelColor, // The index text color of the non-highlightened candidate
            .paragraphStyle: paraStyle]
        let textAttrHighlight: [NSAttributedString.Key: AnyObject] = [
            .font: keyLabelFont,
            .foregroundColor: NSColor.selectedMenuItemTextColor.withAlphaComponent(0.84), // The index text color of the highlightened candidate
            .paragraphStyle: paraStyle]
        for index in 0..<count {
            let textRect = NSRect(x: 0.0, y: CGFloat(index) * cellHeight + labelOffsetY, width: bounds.size.width, height: cellHeight - labelOffsetY)
            var cellRect = NSRect(x: 0.0, y: CGFloat(index) * cellHeight, width: bounds.size.width, height: cellHeight - 0.0) // Remove the splitting line between the candidate text label

            if index + 1 >= count {
                cellRect.size.height += 1.0
            }

            (index == highlightedIndex ? NSColor.alternateSelectedControlColor : NSColor.controlBackgroundColor).setFill() // The background color of the candidate (highlightened : non-highlightened)
            NSBezierPath.fill(cellRect)
            let text = keyLabels[Int(index)]
            (text as NSString).draw(in: textRect, withAttributes: (index == highlightedIndex ? textAttrHighlight : textAttr))
        }
    }
}

fileprivate class VerticalCandidateTableView: NSTableView {
    override func adjustScroll(_ newVisible: NSRect) -> NSRect {
        var scrollRect = newVisible
        let rowHeightPlusSpacing = rowHeight + intercellSpacing.height
        scrollRect.origin.y = (scrollRect.origin.y / rowHeightPlusSpacing) * rowHeightPlusSpacing
        return scrollRect
    }
}

private let kCandidateTextPadding:CGFloat = 24.0
private let kCandidateTextLeftMargin:CGFloat = 8.0



@objc (VTVerticalCandidateController)
public class VerticalCandidateController: CandidateController {
    private var keyLabelStripView: VerticalKeyLabelStripView
    private var scrollView: NSScrollView
    private var tableView: NSTableView
    private var candidateTextParagraphStyle: NSMutableParagraphStyle
    private var candidateTextPadding: CGFloat = kCandidateTextPadding
    private var candidateTextLeftMargin: CGFloat = kCandidateTextLeftMargin
    private var maxCandidateAttrStringWidth: CGFloat = 0

    public init() {
        var contentRect = NSRect(x: 128.0, y: 128.0, width: 0.0, height: 0.0)
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        let panelView = NSView(frame: contentRect) // We need an NSView as a round-cornered container for the candidate panel.
        let panel = NSPanel(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        panel.level = NSWindow.Level(Int(kCGPopUpMenuWindowLevel) + 1)
        panel.contentView = panelView; // Specify the NSView to the panel as its content view.
        panel.hasShadow = true
        panel.isOpaque = false // Again transparentify the panel. Otherwise, the cornerRadius below will be meaningless.
        panel.backgroundColor = NSColor.clear // One more insurance to transparentify the panel.
        
        // Rounded panelView container.
        panelView.wantsLayer = true
        panelView.layer?.borderColor = NSColor.selectedMenuItemTextColor.withAlphaComponent(0.30).cgColor
        panelView.layer?.borderWidth = 1
        panelView.layer?.cornerRadius = 6.0

        contentRect.origin = NSPoint.zero
        var stripRect = contentRect
        stripRect.size.width = 10.0
        keyLabelStripView = VerticalKeyLabelStripView(frame: stripRect)
        panel.contentView?.addSubview(keyLabelStripView)

        var scrollViewRect = contentRect
        scrollViewRect.origin.x = stripRect.size.width
        scrollViewRect.size.width -= stripRect.size.width
        scrollView = NSScrollView(frame: scrollViewRect)

        scrollView.autohidesScrollers = true // Our aesthetics of UI design has to stay close to Apple.
        scrollView.drawsBackground = true // Allow scrollView to draw background.
		scrollView.backgroundColor = NSColor.clear // Draw a tramsparent background.
        scrollView.verticalScrollElasticity = .none

        tableView = NSTableView(frame: contentRect)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "candidate"))
        column.dataCell = NSTextFieldCell()
        if let dataCell = column.dataCell as? NSTextFieldCell {
            dataCell.textColor = NSColor.labelColor // candidate phrase text color for conveniences of customization.
        }
        column.isEditable = false

        candidateTextPadding = kCandidateTextPadding
        candidateTextLeftMargin = kCandidateTextLeftMargin

        tableView.addTableColumn(column)
        tableView.intercellSpacing = NSSize(width: 0.0, height: 1.0)
        tableView.headerView = nil
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = false
        tableView.backgroundColor = NSColor.clear
        tableView.gridColor = NSColor.clear

        if #available(macOS 11.0, *) {
            tableView.style = .plain
            tableView.enclosingScrollView?.borderType = .noBorder
        }

        scrollView.documentView = tableView
        panel.contentView?.addSubview(scrollView)

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.setParagraphStyle(NSParagraphStyle.default)
        paraStyle.firstLineHeadIndent = candidateTextLeftMargin
        paraStyle.lineBreakMode = .byClipping

        candidateTextParagraphStyle = paraStyle

        super.init(window: panel)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.doubleAction = #selector(rowDoubleClicked(_:))
        tableView.target = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func reloadData() {
        maxCandidateAttrStringWidth = ceil(candidateFont.pointSize * 2.0 + candidateTextPadding)
        tableView.reloadData()
        layoutCandidateView()
        if delegate?.candidateCountForController(self) ?? 0 > 0 {
            selectedCandidateIndex = 0
        }
    }

    public override func showNextPage() -> Bool {
        scrollPageByOne(true)
    }

    public override func showPreviousPage() -> Bool {
        scrollPageByOne(false)
    }

    public override func highlightNextCandidate() -> Bool {
        moveSelectionByOne(true)
    }

    public override func highlightPreviousCandidate() -> Bool {
        moveSelectionByOne(false)
    }

    public override func candidateIndexAtKeyLabelIndex(_ index: UInt) -> UInt {
        guard let delegate = delegate else {
            return UInt.max
        }

        let firstVisibleRow = tableView.row(at: scrollView.documentVisibleRect.origin)
        if firstVisibleRow != -1 {
            let result = UInt(firstVisibleRow) + index
            if result < delegate.candidateCountForController(self) {
                return result
            }
        }

        return UInt.max
    }

    public override var selectedCandidateIndex: UInt {
        get {
            let selectedRow = tableView.selectedRow
            return selectedRow == -1 ? UInt.max : UInt(selectedRow)

        }
        set {
            guard let delegate = delegate else {
                return
            }
            var newIndex = newValue
            let selectedRow = tableView.selectedRow
            let labelCount = keyLabels.count
            let itemCount = delegate.candidateCountForController(self)

            if newIndex == UInt.max {
                if itemCount == 0 {
                    tableView.deselectAll(self)
                    return
                }
                newIndex = 0
            }

            var lastVisibleRow = newValue

            if selectedRow != -1 && itemCount > 0 && itemCount > labelCount {
                if newIndex > selectedRow && (Int(newIndex) - selectedRow) > 1 {
                    lastVisibleRow = min(newIndex + UInt(labelCount) - 1, itemCount - 1)
                }
                // no need to handle the backward case: (newIndex < selectedRow && selectedRow - newIndex > 1)
            }

            if itemCount > labelCount {
                tableView.scrollRowToVisible(Int(lastVisibleRow))
            }
            tableView.selectRowIndexes(IndexSet(integer: Int(newIndex)), byExtendingSelection: false)
        }
    }
}

extension VerticalCandidateController: NSTableViewDataSource, NSTableViewDelegate {

    public func numberOfRows(in tableView: NSTableView) -> Int {
        Int(delegate?.candidateCountForController(self) ?? 0)
    }

    public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let delegate = delegate else {
            return nil
        }
        var candidate = ""
        if row < delegate.candidateCountForController(self) {
            candidate = delegate.candidateController(self, candidateAtIndex: UInt(row))
        }
        let attrString = NSAttributedString(string: candidate, attributes: [
            .font: candidateFont,
            .paragraphStyle: candidateTextParagraphStyle
        ])

        // we do more work than what this method is expected to; normally not a good practice, but for the amount of data (9 to 10 rows max), we can afford the overhead

        // expand the window width if text overflows
        let boundingRect = attrString.boundingRect(with: NSSize(width: 10240.0, height: 10240.0), options: .usesLineFragmentOrigin)
        let textWidth = boundingRect.size.width + candidateTextPadding
        if textWidth > maxCandidateAttrStringWidth {
            maxCandidateAttrStringWidth = textWidth
            layoutCandidateView()
        }

        // keep track of the highlighted index in the key label strip
        let count = UInt(keyLabels.count)
        let selectedRow = tableView.selectedRow

        if selectedRow != -1 {
            var newHilightIndex = 0

            if keyLabelStripView.highlightedIndex != -1 &&
                       (row >= selectedRow + Int(count) || (selectedRow > count && row <= selectedRow - Int(count))) {
                newHilightIndex = -1
            } else {
                let firstVisibleRow = tableView.row(at: scrollView.documentVisibleRect.origin)
                newHilightIndex = selectedRow - firstVisibleRow
                if newHilightIndex < -1 {
                    newHilightIndex = -1
                }
            }

            if newHilightIndex != keyLabelStripView.highlightedIndex && newHilightIndex >= 0 {
                keyLabelStripView.highlightedIndex = UInt(newHilightIndex)
                keyLabelStripView.setNeedsDisplay(keyLabelStripView.frame)
            }

        }
        return attrString
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow != -1 {
            // keep track of the highlighted index in the key label strip
            let firstVisibleRow = tableView.row(at: scrollView.documentVisibleRect.origin)
            keyLabelStripView.highlightedIndex = UInt(selectedRow - firstVisibleRow)
            keyLabelStripView.setNeedsDisplay(keyLabelStripView.frame)

            // fix a subtle OS X "bug" that, since we force the scroller to appear,
            // scrolling sometimes shows a temporarily "broken" scroll bar
            // (but quickly disappears)
            if scrollView.hasVerticalScroller {
                scrollView.verticalScroller?.setNeedsDisplay()
            }
        }
    }

    @objc func rowDoubleClicked(_ sender: Any) {
        let clickedRow = tableView.clickedRow
        if clickedRow != -1 {
            delegate?.candidateController(self, didSelectCandidateAtIndex: UInt(clickedRow))
        }
    }

    func scrollPageByOne(_ forward: Bool) -> Bool {
        guard let delegate = delegate else {
            return false
        }
        let labelCount = UInt(keyLabels.count)
        let itemCount = delegate.candidateCountForController(self)
        if 0 == itemCount {
            return false
        }
        if itemCount <= labelCount {
            return false
        }

        var newIndex = selectedCandidateIndex
        if forward {
            if newIndex == itemCount - 1 {
                return false
            }
            newIndex = min(newIndex + labelCount, itemCount - 1)
        } else {
            if newIndex == 0 {
                return false
            }

            if newIndex < labelCount {
                newIndex = 0
            } else {
                newIndex -= labelCount
            }
        }
        selectedCandidateIndex = newIndex
        return true
    }

    private func moveSelectionByOne(_ forward: Bool) -> Bool {
        guard let delegate = delegate else {
            return false
        }
        let itemCount = delegate.candidateCountForController(self)
        if 0 == itemCount {
            return false
        }
        var newIndex = selectedCandidateIndex
        if forward {
            if newIndex == itemCount - 1 {
                return false
            }
            newIndex += 1
        } else {
            if 0 == newIndex {
                return false
            }
            newIndex -= 1
        }
        selectedCandidateIndex = newIndex
        return true
    }

    private func layoutCandidateView() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) { [self] in
            doLayoutCandidateView()
        }
    }

    private func doLayoutCandidateView() {
        guard let delegate = delegate else {
            return
        }
        let count = delegate.candidateCountForController(self)
        if 0 == count {
            return
        }

        let candidateFontSize = ceil(candidateFont.pointSize)
        let keyLabelFontSize = ceil(keyLabelFont.pointSize)
        let fontSize = max(candidateFontSize, keyLabelFontSize)

        let controlSize: NSControl.ControlSize = fontSize > 36.0 ? .regular : .small

        var keyLabelCount = UInt(keyLabels.count)
        var scrollerWidth: CGFloat = 0.0
        if count <= keyLabelCount {
            keyLabelCount = count
            scrollView.hasVerticalScroller = false
        } else {
            scrollView.hasVerticalScroller = true
            let verticalScroller = scrollView.verticalScroller
            verticalScroller?.controlSize = controlSize
            verticalScroller?.scrollerStyle = .overlay // Aesthetics
            scrollerWidth = NSScroller.scrollerWidth(for: controlSize, scrollerStyle: .overlay) // Aesthetics
        }

        keyLabelStripView.keyLabelFont = keyLabelFont
        keyLabelStripView.keyLabels = Array(keyLabels[0..<Int(keyLabelCount)])
        keyLabelStripView.labelOffsetY = (keyLabelFontSize >= candidateFontSize) ? 0.0 : floor((candidateFontSize - keyLabelFontSize) / 2.0)

        let rowHeight = ceil(fontSize * 1.25)
        tableView.rowHeight = rowHeight

        var maxKeyLabelWidth = keyLabelFontSize
        let textAttr: [NSAttributedString.Key: AnyObject] = [.font: keyLabelFont]
        let boundingBox = NSSize(width: 1600.0, height: 1600.0)

        for label in keyLabels {
            let rect = (label as NSString).boundingRect(with: boundingBox, options: .usesLineFragmentOrigin, attributes: textAttr)
            maxKeyLabelWidth = max(rect.size.width, maxKeyLabelWidth)
        }

        let rowSpacing = tableView.intercellSpacing.height
        let stripWidth = ceil(maxKeyLabelWidth * 1.20)
        let tableViewStartWidth = ceil(maxCandidateAttrStringWidth + scrollerWidth)
        let windowWidth = stripWidth + 0.0 + tableViewStartWidth // Compensation to the removal of the border line between the index labels and the candidate phrase list
        let windowHeight = CGFloat(keyLabelCount) * (rowHeight + rowSpacing)

        var frameRect = self.window?.frame ?? NSRect.zero
        let topLeftPoint = NSMakePoint(frameRect.origin.x, frameRect.origin.y + frameRect.size.height)

        frameRect.size = NSMakeSize(windowWidth, windowHeight)
        frameRect.origin = NSMakePoint(topLeftPoint.x, topLeftPoint.y - frameRect.size.height)

        keyLabelStripView.frame = NSRect(x: 0.0, y: 0.0, width: stripWidth, height: windowHeight)
        scrollView.frame = NSRect(x: stripWidth + 0.0, y: 0.0, width: tableViewStartWidth, height: windowHeight) // Remove the border line between the index labels and the candidate phrase list
        self.window?.setFrame(frameRect, display: false)
    }
}
