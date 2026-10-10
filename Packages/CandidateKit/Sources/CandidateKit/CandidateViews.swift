// Copyright (c) 2026 and onwards The McBopomofo Authors.
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

import AppKit
import QuartzCore

internal struct CandidatePanelDragTracker {
    private(set) var didDrag = false
    private var startingPointerLocation: NSPoint?
    private var pointerOffset = NSPoint.zero
    private var activationDistance: CGFloat = 0

    mutating func begin(
        pointerLocation: NSPoint,
        windowOrigin: NSPoint,
        activationDistance: CGFloat
    ) {
        startingPointerLocation = pointerLocation
        pointerOffset = NSPoint(
            x: pointerLocation.x - windowOrigin.x,
            y: pointerLocation.y - windowOrigin.y
        )
        self.activationDistance = max(0, activationDistance)
        didDrag = false
    }

    mutating func updatedWindowOrigin(pointerLocation: NSPoint) -> NSPoint? {
        guard let startingPointerLocation else {
            return nil
        }
        let deltaX = pointerLocation.x - startingPointerLocation.x
        let deltaY = pointerLocation.y - startingPointerLocation.y
        guard didDrag || hypot(deltaX, deltaY) > activationDistance else {
            return nil
        }
        didDrag = true
        return NSPoint(
            x: pointerLocation.x - pointerOffset.x,
            y: pointerLocation.y - pointerOffset.y
        )
    }

    mutating func end() -> Bool {
        let shouldSuppressClick = didDrag
        startingPointerLocation = nil
        pointerOffset = .zero
        didDrag = false
        return shouldSuppressClick
    }
}

internal final class CandidatePanel: NSPanel {
    private var dragTracker = CandidatePanelDragTracker()
    var onManualMove: ((NSPoint) -> Void)?
    var dragActivationDistance: CGFloat = 0

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isReleasedWhenClosed = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            dragTracker.begin(
                pointerLocation: convertPoint(toScreen: event.locationInWindow),
                windowOrigin: frame.origin,
                activationDistance: dragActivationDistance
            )
        case .leftMouseDragged:
            let pointerLocation = convertPoint(toScreen: event.locationInWindow)
            if let origin = dragTracker.updatedWindowOrigin(pointerLocation: pointerLocation) {
                if let onManualMove {
                    onManualMove(origin)
                } else {
                    setFrameOrigin(origin)
                }
                return
            }
        case .leftMouseUp:
            if dragTracker.end() {
                return
            }
        default:
            break
        }
        super.sendEvent(event)
    }
}

internal final class CandidateBackdropView: NSView {
    var cornerRadius = CandidateStyle.Decoration.defaultCornerRadius {
        didSet {
            needsLayout = true
        }
    }

    private let effectView: NSView
    private let contentView: NSView
    private let glassContentContainer: NSView?
    private let appearanceCorrectionView: NSVisualEffectView?
    private let maskLayer = CAShapeLayer()

    init(contentView: NSView) {
        self.contentView = contentView
        if #available(macOS 26.0, *), let glassView = Self.makeStableGlassView() {
            let container = NSView()
            let correctionView = NSVisualEffectView()
            correctionView.material = .hudWindow
            correctionView.blendingMode = .behindWindow
            correctionView.state = .active
            correctionView.isHidden = true
            container.addSubview(correctionView)
            container.addSubview(contentView)
            glassView.contentView = container
            effectView = glassView
            glassContentContainer = container
            appearanceCorrectionView = correctionView
        } else {
            let visualEffectView = NSVisualEffectView()
            visualEffectView.material = .hudWindow
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.state = .active
            visualEffectView.addSubview(contentView)
            effectView = visualEffectView
            glassContentContainer = nil
            appearanceCorrectionView = nil
        }

        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.mask = maskLayer
        addSubview(effectView)
    }

    required init?(coder: NSCoder) {
        nil
    }

    @available(macOS 26.0, *)
    private static func makeStableGlassView() -> NSGlassEffectView? {
        let glass = NSGlassEffectView()
        // This undocumented mode keeps glass in its inherited light/dark scheme.
        // Fall back to HUD vibrancy if either accessor disappears in a future OS.
        guard glass.responds(to: NSSelectorFromString("_adaptiveAppearance")),
            glass.responds(to: NSSelectorFromString("set_adaptiveAppearance:"))
        else { return nil }
        glass.setValue(1, forKey: "_adaptiveAppearance")
        glass.style = .regular
        return glass
    }

    var effectAppearanceName: NSAppearance.Name {
        effectView.effectiveAppearance.name
    }

    var usesLiquidGlass: Bool {
        if #available(macOS 26.0, *) {
            return effectView is NSGlassEffectView
        }
        return false
    }

    var usesHUDVibrancy: Bool {
        effectView is NSVisualEffectView
    }

    var isAppearanceCorrectionActive: Bool {
        appearanceCorrectionView?.isHidden == false
    }

    var appearanceCorrectionName: NSAppearance.Name? {
        appearanceCorrectionView?.effectiveAppearance.name
    }

    func synchronizeAppearance(_ appearance: NSAppearance?) {
        self.appearance = appearance
        effectView.appearance = appearance
        if #available(macOS 26.0, *), let glassView = effectView as? NSGlassEffectView {
            // Let glass propagate its adaptive appearance to the content hierarchy.
            // Adaptation is disabled at construction, so the inherited scheme stays stable.
            glassView.tintColor = nil
            appearanceCorrectionView?.appearance = appearance
            appearanceCorrectionView?.isHidden = !Self.requiresAppearanceCorrection(
                clientAppearance: appearance,
                systemAppearance: NSApplication.shared.effectiveAppearance
            )
        }
        effectView.needsDisplay = true
        needsDisplay = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func layout() {
        super.layout()
        effectView.frame = bounds
        if #available(macOS 26.0, *), let glassView = effectView as? NSGlassEffectView {
            glassView.cornerRadius = 0
            glassView.contentView?.frame = glassView.bounds
            glassContentContainer?.frame = glassView.bounds
            appearanceCorrectionView?.frame = glassView.bounds
            contentView.frame = glassView.bounds
        } else {
            contentView.frame = effectView.bounds
        }
        updateMask()
    }

    static func requiresAppearanceCorrection(
        clientAppearance: NSAppearance?,
        systemAppearance: NSAppearance
    ) -> Bool {
        guard let clientAppearance else {
            return false
        }
        return isDark(clientAppearance) != isDark(systemAppearance)
    }

    private static func isDark(_ appearance: NSAppearance) -> Bool {
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private func updateMask() {
        let rect = bounds
        let radius = min(cornerRadius, rect.height / 2, rect.width / 2)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.frame = rect
        maskLayer.path = path
        CATransaction.commit()
    }
}

internal final class CandidateContentView: NSView {
    let titleView = NSTextField(labelWithString: "")
    let scrollView: NSScrollView
    var headerHeight: CGFloat = 0
    var padding: CGFloat = 0

    init(scrollView: NSScrollView) {
        self.scrollView = scrollView
        super.init(frame: .zero)
        titleView.lineBreakMode = .byTruncatingTail
        titleView.textColor = .secondaryLabelColor
        addSubview(titleView)
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) { nil }

    func configure(title: String, metrics: CandidateMetrics) {
        titleView.stringValue = title
        titleView.toolTip = title.isEmpty ? nil : title
        titleView.font = .systemFont(ofSize: metrics.scaledAuxiliary(11))
        padding = metrics.scaledAuxiliary(8)
        headerHeight = title.isEmpty ? 0 : ceil(titleView.intrinsicContentSize.height) + padding
        titleView.isHidden = title.isEmpty
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let contentHeight = max(0, bounds.height - headerHeight)
        scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: contentHeight)
        titleView.frame = NSRect(
            x: padding, y: contentHeight + padding / 2,
            width: max(0, bounds.width - padding * 2), height: max(0, headerHeight - padding))
    }
}

internal final class CandidateCanvasView: NSView {
    weak var candidateController: CandidateController?

    override func isAccessibilityElement() -> Bool { true }
    override func accessibilityRole() -> NSAccessibility.Role? { .list }
    override func accessibilityLabel() -> String? {
        let title = candidateController?.tooltip ?? ""
        return title.isEmpty ? nil : title
    }
    override func accessibilityChildren() -> [Any]? {
        guard candidateController?.visible == true else { return [] }
        var children: [Any] = candidateController?.accessibilityChildren ?? []
        if let control = candidateController?.renderedControlView {
            children += control.accessibilityChildren() ?? []
        }
        return children
    }
    override func accessibilityVisibleChildren() -> [Any]? {
        guard let controller = candidateController, controller.visible else { return [] }
        var children: [Any] = controller.accessibilityChildren.filter { item in
            controller.currentLayout.item(for: item.index)?.frame.intersects(visibleRect) == true
        }
        if let control = controller.renderedControlView {
            children += control.accessibilityChildren() ?? []
        }
        return children
    }
    override func accessibilitySelectedChildren() -> [Any]? {
        candidateController?.accessibilityChildren.filter { $0.isAccessibilitySelected() } ?? []
    }
    override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
        candidateController?.accessibilityNavigationActions
    }
    override func setAccessibilitySelectedChildren(_ children: [Any]?) {
        guard let item = children?.first as? CandidateAccessibilityItem,
            item.controller === candidateController else { return }
        item.setAccessibilitySelected(true)
    }
    var onAppearanceChange: (() -> Void)?
    var separatorRects: [NSRect] = [] {
        didSet { needsDisplay = true }
    }
    var rowWashRect: NSRect? {
        didSet { needsDisplay = true }
    }
    var rowWashAlpha: CGFloat = 1 {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }

    var rowWashOpacity: CGFloat {
        effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? CandidateStyle.Decoration.darkRowWashOpacity
            : CandidateStyle.Decoration.lightRowWashOpacity
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
        onAppearanceChange?()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let rowWashRect, rowWashRect.intersects(dirtyRect) {
            NSColor.white.withAlphaComponent(rowWashOpacity * rowWashAlpha).setFill()
            rowWashRect.fill()
        }

        NSColor.separatorColor.setFill()
        for separator in separatorRects where separator.intersects(dirtyRect) {
            separator.fill()
        }
    }
}

internal final class CandidateItemView: NSView {
    let candidateIndex: Int
    var indexText: String {
        didSet {
            needsDisplay = true
        }
    }
    var showsIndexText: Bool {
        didSet {
            needsDisplay = true
        }
    }
    var selected: Bool {
        didSet {
            needsDisplay = true
        }
    }
    var selectionColors: CandidateSelectionColors {
        didSet {
            needsDisplay = true
        }
    }
    var onSelect: ((Int) -> Void)?
    var onConfirm: ((Int) -> Void)?
    var outerCornerRadius = CandidateStyle.Decoration.defaultCornerRadius {
        didSet { needsDisplay = true }
    }

    private let candidate: Candidate
    private let metrics: CandidateMetrics
    private let reservesIndexSlot: Bool
    private let showsDetail: Bool
    private let alignedCandidateWidth: CGFloat?

    var detailText: String? {
        guard showsDetail else { return nil }
        if metrics.keyLabelDetailWidth != nil {
            return showsIndexText && !indexText.isEmpty ? indexText : nil
        }
        return candidate.detail
    }

    init(
        frame: NSRect,
        candidate: Candidate,
        candidateIndex: Int,
        indexText: String,
        showsIndexText: Bool,
        selected: Bool,
        selectionColors: CandidateSelectionColors,
        metrics: CandidateMetrics,
        reservesIndexSlot: Bool,
        showsDetail: Bool,
        alignedCandidateWidth: CGFloat?
    ) {
        self.candidate = candidate
        self.candidateIndex = candidateIndex
        self.indexText = indexText
        self.showsIndexText = showsIndexText
        self.selected = selected
        self.selectionColors = selectionColors
        self.metrics = metrics
        self.reservesIndexSlot = reservesIndexSlot
        self.showsDetail = showsDetail
        self.alignedCandidateWidth = alignedCandidateWidth
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool { false }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {}

    override func draw(_ dirtyRect: NSRect) {
        if selected {
            selectionColors.background.setFill()
            let inset = CandidateStyle.Decoration.selectionInset
            let radius = max(0, outerCornerRadius - inset)
            NSBezierPath(
                roundedRect: bounds.insetBy(dx: inset, dy: inset),
                xRadius: radius,
                yRadius: radius
            ).fill()
        }

        var x = metrics.leadingPadding
        if reservesIndexSlot {
            if showsIndexText && !indexText.isEmpty {
                drawText(
                    indexText,
                    font: metrics.indexFont,
                    color: selected ? selectionColors.foreground : .secondaryLabelColor,
                    rect: NSRect(
                        x: x,
                        y: 0,
                        width: metrics.indexSlotWidth,
                        height: bounds.height
                    ),
                    alignment: .center
                )
            }
            x += metrics.indexSlotWidth + metrics.indexCandidateGap
        } else {
            x = metrics.trailingPadding
        }

        let availableWidth = max(0, bounds.width - x - metrics.trailingPadding)
        let intrinsicCandidateWidth = ceil(
            metrics.width(of: candidate.displayString, font: metrics.candidateFont)
        )
        let desiredCandidateWidth = alignedCandidateWidth ?? intrinsicCandidateWidth
        let detailTextWidth = detailText.map {
            ceil(metrics.width(of: $0, font: metrics.detailFont))
        } ?? 0

        if let detail = detailText {
            let candidateWidth = min(
                desiredCandidateWidth,
                max(
                    0,
                    availableWidth - metrics.candidateDetailGap
                        - CandidateStyle.Layout.minimumDetailEm * metrics.candidateFont.pointSize
                )
            )
            drawText(
                candidate.displayString,
                font: metrics.candidateFont,
                color: selected ? selectionColors.foreground : .labelColor,
                rect: NSRect(x: x, y: 0, width: candidateWidth, height: bounds.height)
            )
            let detailX = x + candidateWidth + metrics.candidateDetailGap
            drawText(
                detail,
                font: metrics.detailFont,
                color: selected ? selectionColors.foreground : .secondaryLabelColor,
                rect: NSRect(
                    x: detailX,
                    y: 0,
                    width: min(
                        detailTextWidth,
                        max(0, bounds.width - detailX - metrics.trailingPadding)
                    ),
                    height: bounds.height
                )
            )
        } else {
            drawText(
                candidate.displayString,
                font: metrics.candidateFont,
                color: selected ? selectionColors.foreground : .labelColor,
                rect: NSRect(x: x, y: 0, width: availableWidth, height: bounds.height)
            )
        }
        super.draw(dirtyRect)
    }

    override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else {
            return
        }
        if event.clickCount >= 2 {
            onConfirm?(candidateIndex)
        } else {
            onSelect?(candidateIndex)
        }
    }

    private func drawText(
        _ text: String,
        font: NSFont,
        color: NSColor,
        rect: NSRect,
        alignment: NSTextAlignment = .left
    ) {
        guard rect.width > 0 else {
            return
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
        ]
        let textHeight = ceil(font.boundingRectForFont.height)
        let drawingRect = NSRect(
            x: rect.minX,
            y: floor(rect.midY - textHeight / 2),
            width: rect.width,
            height: textHeight
        )
        NSAttributedString(string: text, attributes: attributes).draw(
            with: drawingRect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine]
        )
    }
}

internal final class CandidateControlView: NSView {
    private var accessibilityButtons: [CandidateAccessibilityButton] = []

    override func isAccessibilityElement() -> Bool { false }
    override func accessibilityChildren() -> [Any]? { accessibilityButtons }
    var onExpand: (() -> Void)?

    private let metrics: CandidateMetrics
    private let imageView = NSImageView()

    init(frame: NSRect, metrics: CandidateMetrics) {
        self.metrics = metrics
        super.init(frame: frame)
        addSubview(imageView)
        configureImages()
        accessibilityButtons = [CandidateAccessibilityButton(
            view: self,
            title: NSLocalizedString("Expand", bundle: .module, comment: "Candidate accessibility action"),
            rect: bounds, enabled: true
        ) { [weak self] in self?.onExpand?() }]
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var isOpaque: Bool { false }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        configureImages()
        needsDisplay = true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {}

    override func draw(_ dirtyRect: NSRect) {
        NSColor.separatorColor.setFill()
        NSRect(x: 0, y: 0, width: CandidateStyle.Decoration.separatorThickness,
            height: bounds.height).fill()
        super.draw(dirtyRect)
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard bounds.contains(location) else {
            return
        }
        onExpand?()
    }

    private func configureImages() {
        imageView.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(
                pointSize: metrics.scaledAuxiliary(CandidateStyle.Controls.expandSymbol), weight: .medium))
        imageView.contentTintColor = .tertiaryLabelColor
        let side = metrics.scaledAuxiliary(CandidateStyle.Controls.imageBox)
        imageView.frame = NSRect(
            x: CandidateStyle.Decoration.separator + metrics.scaledAuxiliary(CandidateStyle.Controls.expandLeading),
            y: bounds.midY - side / 2,
            width: side,
            height: side
        )
    }
}
