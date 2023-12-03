// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

import Cocoa

fileprivate class VerticalKeyLabelStripView: NSView {
    var keyLabelFont: NSFont = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    var labelOffsetY: CGFloat = 0
    var keyLabels: [String] = []
    var highlightedIndex: Int = -1

    override var isFlipped: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        var bigSurOrHigher = false
        if #available(macOS 10.16, *) {
            bigSurOrHigher = true
        }

        let bounds = self.bounds
        if !bigSurOrHigher {
            NSColor.white.setFill()
            NSBezierPath.fill(bounds)
        }

        let count = UInt(keyLabels.count)
        if count == 0 {
            return
        }
        let cellHeight: CGFloat = bounds.size.height / CGFloat(count)
        let black = NSColor.black
        let darkGray = NSColor(deviceWhite: 0.7, alpha: 1.0)
        let lightGray = NSColor(deviceWhite: 0.8, alpha: 1.0)

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.setParagraphStyle(NSParagraphStyle.default)
        paraStyle.alignment = .center

        let textAttr: [NSAttributedString.Key: AnyObject] =
            bigSurOrHigher ? [
                .font: keyLabelFont,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paraStyle]
            : [
                .font: keyLabelFont,
                .foregroundColor: black,
                .paragraphStyle: paraStyle]
        let textAttrHighlighted: [NSAttributedString.Key: AnyObject] = [
            .font: keyLabelFont,
            .foregroundColor: NSColor.selectedControlTextColor,
            .paragraphStyle: paraStyle]
        for index in 0..<count {
            let textRect = NSRect(x: 0.0, y: CGFloat(index) * cellHeight + labelOffsetY, width: bounds.size.width, height: cellHeight - labelOffsetY)
            var cellRect = NSRect(x: 0.0, y: CGFloat(index) * cellHeight, width: bounds.size.width, height: cellHeight)
            if !bigSurOrHigher && index + 1 < count {
                cellRect.size.height -= 1.0
            }

            let text = keyLabels[Int(index)]
            if bigSurOrHigher {
                if index == highlightedIndex {
                    NSColor.selectedControlColor.setFill()
                    NSBezierPath.fill(cellRect)
                }
                (text as NSString).draw(in: textRect, withAttributes: (index == highlightedIndex) ? textAttrHighlighted : textAttr)
            } else {
                (index == highlightedIndex ? darkGray : lightGray).setFill()
                NSBezierPath.fill(cellRect)
                (text as NSString).draw(in: textRect, withAttributes: textAttr)
            }
        }
    }
}

private let kCandidateTextPadding: CGFloat = 24.0
private let kCandidateTextLeftMargin: CGFloat = 8.0
private let kCandidateTextPaddingWithMandatedTableViewPadding: CGFloat = 18.0
private let kCandidateTextLeftMarginWithMandatedTableViewPadding: CGFloat = 0.0

// Only used in macOS 10.15 (Catalina) or lower
private class BackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath.fill(self.bounds)
    }
}

@objc(VTVerticalCandidateController)
public class VerticalCandidateController: CandidateController {
    private var keyLabelStripView: VerticalKeyLabelStripView
    private var scrollView: NSScrollView
    private var tableView: NSTableView
    private var candidateTextParagraphStyle: NSMutableParagraphStyle
    private var candidateTextPadding: CGFloat = kCandidateTextPadding
    private var candidateTextLeftMargin: CGFloat = kCandidateTextLeftMargin
    private var maxCandidateAttrStringWidth: CGFloat = 0
    private let tooltipPadding: CGFloat = 2.0
    private var tooltipView: NSTextField

    public init() {
        var bigSurOrHigher = false
        if #available(macOS 10.16, *) {
            bigSurOrHigher = true
        }

        var contentRect = NSRect(x: 128.0, y: 128.0, width: 0.0, height: 0.0)
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        let panel = NSPanel(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        panel.level = NSWindow.Level(Int(kCGPopUpMenuWindowLevel) + 1)
        panel.hasShadow = true

        if bigSurOrHigher {
            panel.backgroundColor = .clear
            panel.isOpaque = false

            let effect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
            effect.blendingMode = .behindWindow
            effect.material = .popover
            effect.state = .active
            effect.maskImage = .mask(withCornerRadius: 4)
            panel.contentView = effect
        } else {
            panel.contentView = BackgroundView()
        }

        tooltipView = NSTextField(frame: NSRect.zero)
        tooltipView.isEditable = false
        tooltipView.isSelectable = false
        tooltipView.isBezeled = false
        tooltipView.drawsBackground = true
        tooltipView.lineBreakMode = .byTruncatingTail

        contentRect.origin = NSPoint.zero
        var stripRect = contentRect
        stripRect.size.width = 10.0
        keyLabelStripView = VerticalKeyLabelStripView(frame: stripRect)
        panel.contentView?.addSubview(keyLabelStripView)

        var scrollViewRect = contentRect
        scrollViewRect.origin.x = stripRect.size.width
        scrollViewRect.size.width -= stripRect.size.width
        scrollView = NSScrollView(frame: scrollViewRect)
        scrollView.verticalScrollElasticity = .none
        scrollView.contentView.postsBoundsChangedNotifications = true
        if bigSurOrHigher {
            scrollView.drawsBackground = false
            scrollView.contentView.drawsBackground = false
        }

        tableView = NSTableView(frame: contentRect)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "candidate"))
        column.dataCell = NSTextFieldCell()
        column.isEditable = false

        candidateTextPadding = kCandidateTextPadding
        candidateTextLeftMargin = kCandidateTextLeftMargin

        tableView.addTableColumn(column)
        tableView.intercellSpacing = NSSize(width: 0.0, height: 1.0)
        tableView.headerView = nil
        tableView.allowsMultipleSelection = false
        tableView.allowsEmptySelection = false
        if bigSurOrHigher {
            tableView.backgroundColor = .clear
        }
        if #available(macOS 10.16, *) {
            tableView.style = .fullWidth
            candidateTextPadding = kCandidateTextPaddingWithMandatedTableViewPadding
            candidateTextLeftMargin = kCandidateTextLeftMarginWithMandatedTableViewPadding
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

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(boundsChange),
                                               name: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func reloadData() {
        maxCandidateAttrStringWidth = ceil(candidateFont.pointSize + candidateTextPadding)
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

    var scrollTimer: Timer?

    @objc func boundsChange() {
        let visibleRect = tableView.visibleRect
        let visibleRowIndexes = tableView.rows(in: visibleRect)
        let selected = selectedCandidateIndex

        if selected == UInt.max || visibleRowIndexes.contains(Int(selected)) == false {
            keyLabelStripView.highlightedIndex = -1
            keyLabelStripView.setNeedsDisplay(keyLabelStripView.frame)
        }

        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { timer in
            self.tableView.scrollRowToVisible(visibleRowIndexes.lowerBound)
            self.scrollTimer?.invalidate()
            self.scrollTimer = nil
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
                keyLabelStripView.highlightedIndex = newHilightIndex
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
            // firstVisibleRow cannot be larger than selectedRow.
            if selectedRow >= firstVisibleRow {
                keyLabelStripView.highlightedIndex = selectedRow - firstVisibleRow
            } else {
                keyLabelStripView.highlightedIndex = -1
            }

            keyLabelStripView.setNeedsDisplay(keyLabelStripView.frame)
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
            if newIndex >= itemCount - 1 {
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
        if newIndex == UInt.max {
            return false
        }

        if forward {
            if newIndex >= itemCount - 1 {
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

        var tooltipHeight: CGFloat = 0
        var tooltipWidth: CGFloat = 0

        if !tooltip.isEmpty {
            tooltipView.stringValue = tooltip
            let size = tooltipView.intrinsicContentSize
            tooltipWidth = size.width + tooltipPadding * 2
            tooltipHeight = size.height + tooltipPadding * 2
            self.window?.contentView?.addSubview(tooltipView)
        } else {
            tooltipView.removeFromSuperview()
        }

        let candidateFontSize = ceil(candidateFont.pointSize)
        let keyLabelFontSize = ceil(keyLabelFont.pointSize)
        let fontSize = max(candidateFontSize, keyLabelFontSize)

        var keyLabelCount = UInt(keyLabels.count)
        var scrollerWidth: CGFloat = 0.0
        if count <= keyLabelCount {
            keyLabelCount = count
            scrollView.hasVerticalScroller = false
        } else {
            scrollView.hasVerticalScroller = true
            scrollerWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: NSScroller.preferredScrollerStyle)
        }

        keyLabelStripView.keyLabelFont = keyLabelFont
        let actualKeyLabels = keyLabels[0..<Int(keyLabelCount)].map { $0.displayedText }
        keyLabelStripView.keyLabels = actualKeyLabels
        keyLabelStripView.labelOffsetY = (keyLabelFontSize >= candidateFontSize) ? 0.0 : floor((candidateFontSize - keyLabelFontSize) / 2.0)

        let rowHeight = ceil(fontSize * 1.25)
        tableView.rowHeight = rowHeight

        var maxKeyLabelWidth = keyLabelFontSize
        let textAttr: [NSAttributedString.Key: AnyObject] = [.font: keyLabelFont]
        let boundingBox = NSSize(width: 1600.0, height: 1600.0)

        for label in actualKeyLabels {
            let rect = (label as NSString).boundingRect(with: boundingBox, options: .usesLineFragmentOrigin, attributes: textAttr)
            maxKeyLabelWidth = max(rect.size.width, maxKeyLabelWidth)
        }

        let rowSpacing = tableView.intercellSpacing.height
        let stripWidth = ceil(maxKeyLabelWidth * 1.20)
        let tableViewStartWidth = ceil(maxCandidateAttrStringWidth + scrollerWidth)
        let windowWidth = max(stripWidth + 1.0 + tableViewStartWidth, tooltipWidth)
        let windowHeight = CGFloat(keyLabelCount) * (rowHeight + rowSpacing) + tooltipHeight

        var frameRect = self.window?.frame ?? NSRect.zero
        let topLeftPoint = NSMakePoint(frameRect.origin.x, frameRect.origin.y + frameRect.size.height)

        frameRect.size = NSMakeSize(windowWidth, windowHeight)
        frameRect.origin = NSMakePoint(topLeftPoint.x, topLeftPoint.y - frameRect.size.height)

        keyLabelStripView.frame = NSRect(x: 0.0, y: 0, width: stripWidth, height: windowHeight - tooltipHeight)
        scrollView.frame = NSRect(x: stripWidth + 1.0, y: 0, width: (windowWidth - stripWidth - 1), height: windowHeight - tooltipHeight)
        tooltipView.frame = NSRect(x: tooltipPadding, y: windowHeight - tooltipHeight + tooltipPadding, width: windowWidth, height: tooltipHeight)
        self.window?.setFrame(frameRect, display: false)
    }


}

extension NSImage {
    static func mask(withCornerRadius radius: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: radius * 2, height: radius * 2), flipped: false) {
            NSBezierPath(roundedRect: $0, xRadius: radius, yRadius: radius).fill()
            NSColor.black.set()
            return true
        }
        
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        
        return image
    }
}
