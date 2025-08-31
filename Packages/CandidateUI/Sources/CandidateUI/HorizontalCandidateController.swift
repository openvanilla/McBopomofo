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

private class HorizontalCandidateView: NSView {
    fileprivate final class CandidateAXItem: NSAccessibilityElement {
        weak var owner: HorizontalCandidateView?
        let index: UInt
        let candidate: String
        let rect: NSRect

        init(owner: HorizontalCandidateView, index: UInt,
             candidate: String,
             rect: NSRect)
        {
            self.owner = owner
            self.index = index
            self.candidate = candidate
            self.rect = rect
        }

        override func accessibilityParent() -> Any? { owner }
        override func accessibilityRole() -> NSAccessibility.Role { .staticText }
        override func accessibilityLabel() -> String? { candidate }
        override func isAccessibilityElement() -> Bool { true }

        func accessibilitySelected() -> Bool {
            index == owner?.highlightedIndex
        }

        override func accessibilityFrame() -> NSRect {
            guard let owner, let window = owner.window else { return .zero }
            let rectInScreen = owner.convert(rect, to: nil)
            return window.convertToScreen(rectInScreen)
        }
    }

    var highlightedIndex: UInt = 0 {
        didSet {
            setNeedsDisplay(bounds)
            // Note: When the selection changes, we need to notify accessibility.
            if highlightedIndex < children.count {
                let child = children[Int(highlightedIndex)]
                NSAccessibility.post(element: child, notification: .focusedUIElementChanged)
                NSAccessibility.post(element: self, notification: .selectedChildrenChanged)
            }
        }
    }

    var action: Selector?
    weak var target: AnyObject?

    private var keyLabels: [String] = []
    private var displayedCandidates: [String] = []
    private var keyLabelHeight: CGFloat = 0
    private var candidateTextHeight: CGFloat = 0
    private var cellPadding: CGFloat = 0
    private var keyLabelAttrDict: [NSAttributedString.Key: AnyObject] = [:]
    private var candidateAttrDict: [NSAttributedString.Key: AnyObject] = [:]
    private var elementWidths: [CGFloat] = []
    private var trackingHighlightedIndex: UInt = .max

    private let tooltipPadding: CGFloat = 2.0
    private var tooltipSize: NSSize = .zero

    override var toolTip: String? {
        didSet {
            if let toolTip = toolTip, !toolTip.isEmpty {
                let baseSize = NSSize(width: 10240.0, height: 10240.0)
                var tooltipRect = (toolTip as NSString).boundingRect(
                    with: baseSize, options: .usesLineFragmentOrigin, attributes: keyLabelAttrDict
                )
                tooltipRect.size.height += tooltipPadding * 2
                tooltipRect.size.width += tooltipPadding * 2
                tooltipSize = tooltipRect.size
            } else {
                tooltipSize = NSSize.zero
            }
        }
    }

    override var isFlipped: Bool {
        true
    }

    var sizeForView: NSSize {
        var result = NSSize.zero

        if !elementWidths.isEmpty {
            result.width = elementWidths.reduce(0, +)
            result.width += CGFloat(elementWidths.count)
            result.height = keyLabelHeight + candidateTextHeight + 1.0
        }

        result.height += tooltipSize.height
        result.width = max(tooltipSize.width, result.width)
        return result
    }

    func set(keyLabels labels: [String], displayedCandidates candidates: [String]) {
        let count = min(labels.count, candidates.count)
        keyLabels = Array(labels[0 ..< count])
        displayedCandidates = Array(candidates[0 ..< count])

        var newWidths = [CGFloat]()
        let baseSize = NSSize(width: 10240.0, height: 10240.0)
        for index in 0 ..< count {
            let labelRect = (keyLabels[index] as NSString).boundingRect(
                with: baseSize, options: .usesLineFragmentOrigin, attributes: keyLabelAttrDict
            )
            let candidateRect = (displayedCandidates[index] as NSString).boundingRect(
                with: baseSize, options: .usesLineFragmentOrigin, attributes: candidateAttrDict
            )
            let cellWidth =
                max(
                    candidateTextHeight,
                    max(labelRect.size.width, candidateRect.size.width)
                ) + cellPadding
            newWidths.append(cellWidth)
        }
        elementWidths = newWidths
    }

    func set(keyLabelFont labelFont: NSFont, candidateFont: NSFont) {
        var bigSurOrHigher = false
        if #available(macOS 10.16, *) {
            bigSurOrHigher = true
        }

        let paraStyle = NSMutableParagraphStyle()
        paraStyle.setParagraphStyle(NSParagraphStyle.default)
        paraStyle.alignment = .center

        if bigSurOrHigher {
            keyLabelAttrDict = [
                .font: labelFont,
                .paragraphStyle: paraStyle,
                .foregroundColor: NSColor.labelColor,
            ]
            candidateAttrDict = [
                .font: candidateFont,
                .paragraphStyle: paraStyle,
                .foregroundColor: NSColor.labelColor,
            ]
        } else {
            keyLabelAttrDict = [
                .font: labelFont,
                .paragraphStyle: paraStyle,
                .foregroundColor: NSColor.black,
            ]
            candidateAttrDict = [
                .font: candidateFont,
                .paragraphStyle: paraStyle,
                .foregroundColor: NSColor.textColor,
            ]
        }

        let labelFontSize = labelFont.pointSize
        let candidateFontSize = candidateFont.pointSize
        let biggestSize = max(labelFontSize, candidateFontSize)

        keyLabelHeight = ceil(labelFontSize * 1.20)
        candidateTextHeight = ceil(candidateFontSize * 1.20)
        cellPadding = ceil(biggestSize / 2.0)
    }

    override func draw(_: NSRect) {
        var bigSurOrHigher = false
        if #available(macOS 10.16, *) {
            bigSurOrHigher = true
        }

        let backgroundColor = NSColor.controlBackgroundColor
        let lightGray = NSColor(deviceWhite: 0.8, alpha: 1.0)
        let darkGray = NSColor(deviceWhite: 0.7, alpha: 1.0)
        let bounds = self.bounds

        if !bigSurOrHigher {
            backgroundColor.setFill()
            NSBezierPath.fill(bounds)
        }
        if let toolTip = toolTip {
            let tooltipFrame = NSRect(
                x: 0, y: 0, width: tooltipSize.width, height: tooltipSize.height
            )
            (toolTip as NSString).draw(in: tooltipFrame, withAttributes: keyLabelAttrDict)
        }

        var accuWidth: CGFloat = 0
        for index in 0 ..< elementWidths.count {
            let currentWidth = elementWidths[index]
            let labelRect = NSRect(
                x: accuWidth, y: tooltipSize.height, width: currentWidth, height: keyLabelHeight
            )
            let candidateRect = NSRect(
                x: accuWidth, y: tooltipSize.height + keyLabelHeight + 1.0, width: currentWidth,
                height: candidateTextHeight
            )

            var activeKeyLabelAttrDict = keyLabelAttrDict
            if bigSurOrHigher {
                if index == highlightedIndex {
                    NSColor.selectedControlColor.setFill()
                    NSBezierPath.fill(labelRect)
                    activeKeyLabelAttrDict[.foregroundColor] = NSColor.selectedControlTextColor
                }
            } else {
                (index == highlightedIndex ? darkGray : lightGray).setFill()
                NSBezierPath.fill(labelRect)
            }
            (keyLabels[index] as NSString).draw(
                in: labelRect, withAttributes: activeKeyLabelAttrDict
            )

            var activeCandidateAttr = candidateAttrDict
            if bigSurOrHigher {
                if index == highlightedIndex {
                    if #available(macOS 10.14, *) {
                        NSColor.controlAccentColor.setFill()
                    } else {
                        NSColor.selectedControlColor.setFill()
                    }
                    NSBezierPath.fill(candidateRect)
                    activeCandidateAttr[.foregroundColor] = NSColor.white
                }
            } else {
                if index == highlightedIndex {
                    NSColor.selectedTextBackgroundColor.setFill()
                    activeCandidateAttr[.foregroundColor] = NSColor.selectedTextColor
                } else {
                    backgroundColor.setFill()
                }
                NSBezierPath.fill(candidateRect)
            }
            (displayedCandidates[index] as NSString).draw(
                in: candidateRect, withAttributes: activeCandidateAttr
            )
            accuWidth += currentWidth + 1.0
        }
    }

    private func findHitIndex(event: NSEvent) -> UInt? {
        let location = convert(event.locationInWindow, to: nil)
        if !NSPointInRect(location, bounds) {
            return nil
        }
        var accuWidth: CGFloat = 0.0
        for index in 0 ..< elementWidths.count {
            let currentWidth = elementWidths[index]

            if location.x >= accuWidth, location.x <= accuWidth + currentWidth {
                return UInt(index)
            }
            accuWidth += currentWidth + 1.0
        }
        return nil
    }

    override func mouseUp(with event: NSEvent) {
        trackingHighlightedIndex = highlightedIndex
        guard let newIndex = findHitIndex(event: event) else {
            return
        }
        highlightedIndex = newIndex
    }

    override func mouseDown(with event: NSEvent) {
        guard let newIndex = findHitIndex(event: event) else {
            return
        }
        select(newIndex: newIndex)
    }

    // MARK: - Acccessibility

    private func select(newIndex: UInt) {
        var triggerAction = false
        if newIndex == highlightedIndex {
            triggerAction = true
        } else {
            highlightedIndex = trackingHighlightedIndex
        }

        trackingHighlightedIndex = 0
        setNeedsDisplay(bounds)
        if triggerAction {
            if let target = target as? NSObject, let action = action {
                target.perform(action, with: self)
            }
        }
    }

    fileprivate var children: [CandidateAXItem] = []

    fileprivate func buildAccesibilityChildren() {
        func accessibilityFrameForCandidate(at index: Int) -> NSRect {
            var accuWidth: CGFloat = 0
            for i in 0 ..< index {
                accuWidth += elementWidths[i] + 1.0
            }
            let width = elementWidths[index]
            let height = keyLabelHeight + candidateTextHeight + 1.0
            let rectInView = NSRect(x: accuWidth, y: tooltipSize.height, width: width, height: height)
            return rectInView
        }

        var children: [CandidateAXItem] = []
        for (index, candidate) in displayedCandidates.enumerated() {
            let rect = accessibilityFrameForCandidate(at: index)
            let keyLabel = keyLabels[index]
            let element = CandidateAXItem(
                owner: self,
                index: UInt(index),
                candidate: candidate,
                rect: rect
            )
            children.append(element)
        }
        self.children = children
    }

    override func accessibilityRole() -> NSAccessibility.Role? {
        .list
    }

    override func isAccessibilityElement() -> Bool {
        false
    }

    override func accessibilityVisibleChildren() -> [Any]? {
        children
    }

    override func accessibilityChildren() -> [Any]? {
        children
    }

    override func accessibilitySelectedChildren() -> [Any]? {
        if highlightedIndex < children.count {
            return [children[Int(highlightedIndex)]]
        }
        return []
    }

    override func accessibilityTitle() -> String? {
        ""
    }
}

@objc(VTHorizontalCandidateController)
public class HorizontalCandidateController: CandidateController {
    private var candidateView: HorizontalCandidateView
    private var prevPageButton: NSButton
    private var nextPageButton: NSButton
    private var currentPage: UInt = 0

    public init() {
        var bigSurOrHigher = false
        if #available(macOS 10.16, *) {
            bigSurOrHigher = true
        }

        var contentRect = NSRect(x: 128.0, y: 128.0, width: 0.0, height: 0.0)
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        let panel = NSPanel(
            contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false
        )
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
        }

        contentRect.origin = NSPoint.zero
        candidateView = HorizontalCandidateView(frame: contentRect)
        panel.contentView?.addSubview(candidateView)
        panel.setAccessibilityRole(.group)

        contentRect.size = NSSize(width: 36.0, height: 20.0)
        nextPageButton = NSButton(frame: contentRect)
        nextPageButton.setButtonType(.momentaryLight)
        nextPageButton.bezelStyle = .smallSquare
        if bigSurOrHigher {
            nextPageButton.isBordered = false
            nextPageButton.attributedTitle = "»".withColor(.controlTextColor)
        } else {
            nextPageButton.title = "»"
        }

        prevPageButton = NSButton(frame: contentRect)
        prevPageButton.setButtonType(.momentaryLight)
        prevPageButton.bezelStyle = .smallSquare
        if bigSurOrHigher {
            prevPageButton.isBordered = false
            prevPageButton.attributedTitle = "«".withColor(.controlTextColor)
        } else {
            prevPageButton.title = "«"
        }

        panel.contentView?.addSubview(nextPageButton)
        panel.contentView?.addSubview(prevPageButton)

        super.init(window: panel)

        candidateView.target = self
        candidateView.action = #selector(candidateViewMouseDidClick(_:))

        nextPageButton.target = self
        nextPageButton.action = #selector(pageButtonAction(_:))

        prevPageButton.target = self
        prevPageButton.action = #selector(pageButtonAction(_:))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func reloadData() {
        candidateView.highlightedIndex = 0
        currentPage = 0
        layoutCandidateView()
    }

    override public func showNextPage() -> Bool {
        guard delegate != nil else {
            return false
        }

        if currentPage + 1 >= pageCount {
            return false
        }

        currentPage += 1
        candidateView.highlightedIndex = 0
        layoutCandidateView()
        return true
    }

    override public func showPreviousPage() -> Bool {
        guard delegate != nil else {
            return false
        }

        if currentPage == 0 {
            return false
        }

        currentPage -= 1
        candidateView.highlightedIndex = 0
        layoutCandidateView()
        return true
    }

    override public func highlightNextCandidate() -> Bool {
        guard let delegate = delegate else {
            return false
        }

        let currentIndex = selectedCandidateIndex
        if currentIndex + 1 >= delegate.candidateCountForController(self) {
            return false
        }
        selectedCandidateIndex = currentIndex + 1
        return true
    }

    override public func highlightPreviousCandidate() -> Bool {
        guard delegate != nil else {
            return false
        }

        let currentIndex = selectedCandidateIndex
        if currentIndex == 0 {
            return false
        }

        selectedCandidateIndex = currentIndex - 1
        return true
    }

    override public func candidateIndexAtKeyLabelIndex(_ index: UInt) -> UInt {
        guard let delegate = delegate else {
            return UInt.max
        }

        let result = currentPage * UInt(keyLabels.count) + index
        return result < delegate.candidateCountForController(self) ? result : UInt.max
    }

    override public var selectedCandidateIndex: UInt {
        get {
            currentPage * UInt(keyLabels.count) + candidateView.highlightedIndex
        }
        set {
            guard let delegate = delegate else {
                return
            }
            let keyLabelCount = UInt(keyLabels.count)
            if newValue < delegate.candidateCountForController(self) {
                currentPage = newValue / keyLabelCount
                candidateView.highlightedIndex = newValue % keyLabelCount
                layoutCandidateView()
            }
        }
    }
}

extension HorizontalCandidateController {
    private var pageCount: UInt {
        guard let delegate = delegate else {
            return 0
        }
        let totalCount = delegate.candidateCountForController(self)
        let keyLabelCount = UInt(keyLabels.count)
        return totalCount / keyLabelCount + ((totalCount % keyLabelCount) != 0 ? 1 : 0)
    }

    private func layoutCandidateView() {
        guard let delegate = delegate else {
            return
        }

        candidateView.set(keyLabelFont: keyLabelFont, candidateFont: candidateFont)
        var candidates = [String]()
        let count = delegate.candidateCountForController(self)
        let keyLabelCount = UInt(keyLabels.count)

        let begin = currentPage * keyLabelCount
        for index in begin ..< min(begin + keyLabelCount, count) {
            let candidate = delegate.candidateController(self, candidateAtIndex: index)
            candidates.append(candidate)
        }
        candidateView.set(
            keyLabels: keyLabels.map { $0.displayedText }, displayedCandidates: candidates
        )
        candidateView.toolTip = tooltip
        var newSize = candidateView.sizeForView
        var frameRect = candidateView.frame
        frameRect.size = newSize
        candidateView.frame = frameRect

        if pageCount > 1 {
            var buttonRect = nextPageButton.frame
            var spacing: CGFloat = 0.0

            if newSize.height < 40.0 {
                buttonRect.size.height = floor(newSize.height / 2)
            } else {
                buttonRect.size.height = 20.0
            }

            if newSize.height >= 60.0 {
                spacing = ceil(newSize.height * 0.1)
            }

            let buttonOriginY = (newSize.height - (buttonRect.size.height * 2.0 + spacing)) / 2.0
            buttonRect.origin = NSPoint(x: newSize.width + 8.0, y: buttonOriginY)
            nextPageButton.frame = buttonRect

            buttonRect.origin = NSPoint(
                x: newSize.width + 8.0, y: buttonOriginY + buttonRect.size.height + spacing
            )
            prevPageButton.frame = buttonRect

            newSize.width += 52.0
            nextPageButton.isHidden = false
            prevPageButton.isHidden = false
        } else {
            nextPageButton.isHidden = true
            prevPageButton.isHidden = true
        }

        frameRect = window?.frame ?? NSRect.zero

        let topLeftPoint = NSMakePoint(
            frameRect.origin.x, frameRect.origin.y + frameRect.size.height
        )
        frameRect.size = newSize
        frameRect.origin = NSMakePoint(topLeftPoint.x, topLeftPoint.y - frameRect.size.height)
        window?.setFrame(frameRect, display: false)
        candidateView.setNeedsDisplay(candidateView.bounds)
        candidateView.buildAccesibilityChildren()
        if Int(candidateView.highlightedIndex) < candidateView.children.count {
            let element = candidateView.children[Int(candidateView.highlightedIndex)]
            NSAccessibility
                .post(element: element, notification: .focusedUIElementChanged)
        }
    }

    @objc fileprivate func pageButtonAction(_ sender: Any) {
        guard let sender = sender as? NSButton else {
            return
        }
        if sender == nextPageButton {
            _ = showNextPage()
        } else if sender == prevPageButton {
            _ = showPreviousPage()
        }
    }

    @objc fileprivate func candidateViewMouseDidClick(_: Any) {
        delegate?.candidateController(self, didSelectCandidateAtIndex: selectedCandidateIndex)
    }
}

extension String {
    func withColor(_ color: NSColor) -> NSAttributedString {
        let attrDict: [NSAttributedString.Key: AnyObject] = [.foregroundColor: color]
        return NSAttributedString(string: self, attributes: attrDict)
    }
}
