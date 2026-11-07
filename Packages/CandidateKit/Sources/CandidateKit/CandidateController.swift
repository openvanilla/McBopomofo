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

@objc(CKCandidateOrientation)
public enum CandidateOrientation: Int, Sendable {
    case horizontal
    case vertical
}

@objc(CKCandidateNavigation)
public enum CandidateNavigation: Int, Sendable {
    case left
    case right
    case up
    case down
    case pageUp
    case pageDown
    case home
    case end
    /// Steps to the previous candidate and wraps from the first to the last, like Shift-Tab.
    case itemBackward
    /// Steps to the next candidate and wraps from the last to the first, like Tab.
    case itemForward
}

public enum CandidateConfigurationError: Error, Equatable, LocalizedError {
    case invalidPageSize(Int)
    case invalidVerticalMaximumVisibleColumns(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidPageSize(let value):
            "Candidate page size must be between 1 and 15. Received \(value)."
        case .invalidVerticalMaximumVisibleColumns(let value):
            "Vertical maximum visible columns must be at least 1. Received \(value)."
        }
    }
}

public struct CandidateConfiguration: Equatable, Sendable {
    public var orientation: CandidateOrientation
    public var allowsExpansion: Bool
    public var pageSize: Int
    /// Render key labels after the candidate, replacing its detail and omitting the index column.
    public var showsKeyLabelsAsDetails: Bool
    public var animationDuration: TimeInterval
    public var verticalMaximumVisibleColumns: Int
    /// Whether `handleKeyEvent(_:)` handles Space, Tab, arrow, page, Home, End, and Return keys.
    public var handlesNavigationKeys: Bool
    /// Whether `handleKeyEvent(_:)` commits the candidate whose index label matches the key.
    public var handlesIndexLabelKeys: Bool

    public init(
        orientation: CandidateOrientation = .horizontal,
        allowsExpansion: Bool = true,
        pageSize: Int = 9,
        showsKeyLabelsAsDetails: Bool = false,
        animationDuration: TimeInterval = 0.2,
        verticalMaximumVisibleColumns: Int = 5,
        handlesNavigationKeys: Bool = true,
        handlesIndexLabelKeys: Bool = true
    ) {
        self.orientation = orientation
        self.allowsExpansion = allowsExpansion
        self.pageSize = pageSize
        self.showsKeyLabelsAsDetails = showsKeyLabelsAsDetails
        self.animationDuration = animationDuration
        self.verticalMaximumVisibleColumns = verticalMaximumVisibleColumns
        self.handlesNavigationKeys = handlesNavigationKeys
        self.handlesIndexLabelKeys = handlesIndexLabelKeys
    }

    // Key labels shown as details replace the index column.
    func showsIndexColumn(for keyLabels: [CandidateKeyLabel]) -> Bool {
        !keyLabels.isEmpty && !showsKeyLabelsAsDetails
    }

    public static var `default`: CandidateConfiguration {
        CandidateConfiguration()
    }

    /// The fields are freely mutable, so the controller validates a configuration when it
    /// receives one.
    public func validate() throws {
        guard (1...15).contains(pageSize) else {
            throw CandidateConfigurationError.invalidPageSize(pageSize)
        }
        guard verticalMaximumVisibleColumns >= 1 else {
            throw CandidateConfigurationError.invalidVerticalMaximumVisibleColumns(
                verticalMaximumVisibleColumns)
        }
    }
}

extension Character {
    fileprivate var isPrintableASCII: Bool {
        unicodeScalars.count == 1
            && unicodeScalars.first.map { (0x20...0x7E).contains($0.value) } == true
    }
}

@objc(CKCandidate)
public final class Candidate: NSObject {
    @objc public let displayString: String
    @objc public let detail: String?
    @objc public var accessibilityReading: String?

    @objc public init(displayString: String, detail: String? = nil) {
        self.displayString = displayString
        self.detail = detail?.isEmpty == true ? nil : detail
        super.init()
    }
}

@objc(CKCandidateKeyLabel)
public final class CandidateKeyLabel: NSObject {
    @objc public let key: String
    @objc public let displayedText: String

    @objc public init(key: String, displayedText: String) {
        self.key = key
        self.displayedText = displayedText
        super.init()
    }
}

@MainActor
@objc(CKCandidateControllerDelegate)
public protocol CandidateControllerDelegate: AnyObject {
    func candidateCountForController(_ controller: CandidateController) -> UInt
    func candidateController(_ controller: CandidateController, candidateAtIndex index: UInt)
        -> String
    func candidateController(_ controller: CandidateController, detailAtIndex index: UInt)
        -> String?
    func candidateController(
        _ controller: CandidateController,
        requestExplanationFor candidate: String,
        reading: String
    ) -> String?
    func candidateController(
        _ controller: CandidateController, didSelectCandidateAtIndex index: UInt)

    @objc optional func candidateController(
        _ controller: CandidateController,
        accessibilityReadingAtIndex index: UInt
    ) -> String?
}

@MainActor
@objc(CKCandidateController)
public class CandidateController: NSWindowController {
    @objc public weak var delegate: (any CandidateControllerDelegate)?

    public var onSelectionChange: ((Int, Candidate) -> Void)?
    public var onConfirmation: ((Int, Candidate) -> Void)?

    @objc public var tooltip = "" {
        didSet {
            guard tooltip != oldValue else { return }
            finishFrameTransition()
            rebuildLayout()
        }
    }

    @objc public var candidateFont: NSFont {
        didSet {
            guard candidateFont != oldValue else {
                return
            }
            finishFrameTransition()
            rebuildLayout()
        }
    }

    /// Only the font family is used; the label size always follows `candidateFont`.
    @objc public var keyLabelFont: NSFont {
        didSet {
            guard keyLabelFont != oldValue else {
                return
            }
            finishFrameTransition()
            rebuildLayout()
        }
    }

    @objc public var keyLabels: [CandidateKeyLabel] {
        didSet {
            guard
                !keyLabels.elementsEqual(
                    oldValue, by: { $0.key == $1.key && $0.displayedText == $1.displayedText })
            else {
                return
            }
            finishFrameTransition()
            rebuildLayout()
        }
    }

    public private(set) var configuration: CandidateConfiguration
    public private(set) var candidates: [Candidate] = []
    public private(set) var clientAppearance: NSAppearance?
    public private(set) var clientBundleIdentifier: String?
    private var previewAccentColor: NSColor?

    @_spi(CandidatePreview)
    public static func previewCandidateItem(_ text: String) -> (
        view: NSView, setColors: (NSColor, NSColor) -> Void
    ) {
        let font = NSFont.systemFont(ofSize: CandidateStyle.Typography.referenceSize)
        let metrics = CandidateMetrics(
            requestedCandidateFont: font, requestedIndexFont: font)
        let candidate = Candidate(displayString: text)
        let item = CandidateItemView(
            frame: NSRect(
                x: 0, y: 0,
                width: metrics.intrinsicWidth(for: candidate, showsIndexColumn: true),
                height: metrics.itemHeight),
            candidate: candidate, candidateIndex: 0, indexText: "1", showsIndexText: true,
            selected: true, selectionColors: .system, metrics: metrics,
            reservesIndexSlot: true, showsDetail: false, alignedCandidateWidth: nil)
        return (
            item,
            { background, foreground in
                item.selectionColors = CandidateSelectionColors(
                    background: background, foreground: foreground)
            }
        )
    }

    // Preview-only injection uses the same resolver and item updates as a client accent.
    @_spi(CandidatePreview)
    public func previewAccent(_ color: NSColor?) -> (background: NSColor, foreground: NSColor) {
        previewAccentColor = color
        refreshContentTheme()
        var colors = (resolvedSelectionColors.background, resolvedSelectionColors.foreground)
        canvasView.effectiveAppearance.performAsCurrentDrawingAppearance {
            colors = (
                colors.0.usingColorSpace(.sRGB) ?? colors.0,
                colors.1.usingColorSpace(.sRGB) ?? colors.1
            )
        }
        return colors
    }

    /// `UInt.max` while there are no candidates. Assigned values clamp to the last candidate.
    @objc public var selectedCandidateIndex: UInt {
        get {
            selectionIndex < 0 ? UInt.max : UInt(selectionIndex)
        }
        set {
            setSelection(Int(clamping: newValue))
        }
    }

    internal var selectionIndex = -1

    @objc public var visible: Bool {
        get { window?.isVisible == true }
        set {
            let wasVisible = visible
            if newValue {
                guard !candidates.isEmpty else {
                    window?.orderOut(nil)
                    return
                }
                if !wasVisible {
                    updateLayout()
                }
                window?.orderFrontRegardless()
                notifyAccessibilityPresentation(wasVisible: wasVisible)
            } else {
                finishFrameTransition()
                window?.orderOut(nil)
            }
        }
    }

    internal let candidatePanel: CandidatePanel
    internal let backdropView: CandidateBackdropView
    internal let contentView: CandidateContentView
    internal let scrollView: NSScrollView
    internal let canvasView: CandidateCanvasView

    internal var currentLayout = CandidatePanelLayout.empty
    private var layoutScreenSize = NSSize.zero
    internal let renderer = CandidateRenderer()
    internal var accessibilityItems: [CandidateAccessibilityItem] = []
    internal var isExpanded = false
    internal var verticalNumberingAnchor = 0
    // Widths of the current candidates' text by font, so repeated layouts reuse them.
    private var textWidths: [NSFontDescriptor: [String: CGFloat]] = [:]
    internal var isFrameTransitionActive: Bool { frameTransitionDriver != nil }
    internal var lastPlacementContext: CandidatePlacementContext?
    internal var frameTransitionDriver: CandidateTransitionDriver?
    public private(set) var placementSide: CandidatePlacementSide?
    internal var resolvedSelectionColors = CandidateSelectionColors.system

    public convenience init() {
        self.init(configuration: .default)
    }

    public init(configuration: CandidateConfiguration) {
        // Passing an invalid configuration here is a programming error. Values that are only
        // known at run time go through apply(configuration:), which reports them instead.
        do {
            try configuration.validate()
        } catch {
            preconditionFailure(error.localizedDescription)
        }
        self.configuration = configuration
        self.candidateFont = .systemFont(ofSize: CandidateStyle.Typography.referenceSize)
        self.keyLabelFont = .systemFont(ofSize: NSFont.systemFontSize)
        self.keyLabels = "1234567890".map {
            CandidateKeyLabel(key: String($0), displayedText: String($0))
        }

        let panel = CandidatePanel()
        let canvas = CandidateCanvasView(frame: .zero)
        let scroll = NSScrollView(frame: .zero)
        let content = CandidateContentView(scrollView: scroll)
        let backdrop = CandidateBackdropView(contentView: content)
        self.candidatePanel = panel
        self.canvasView = canvas
        self.scrollView = scroll
        self.backdropView = backdrop
        self.contentView = content

        super.init(window: panel)

        panel.contentView = backdrop
        panel.onManualMove = { [weak self] origin in
            self?.movePanelManually(to: origin)
        }
        canvas.candidateController = self
        scroll.documentView = canvas
        scroll.drawsBackground = false
        scroll.contentView.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = NSScroller.preferredScrollerStyle
        scroll.contentView.postsBoundsChangedNotifications = true
        canvas.onAppearanceChange = { [weak self] in
            self?.refreshContentTheme()
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(clipViewBoundsDidChange),
            name: NSView.boundsDidChangeNotification, object: scroll.contentView)
        NotificationCenter.default.addObserver(
            self, selector: #selector(preferredScrollerStyleDidChange),
            name: NSScroller.preferredScrollerStyleDidChangeNotification, object: nil)
        refreshTheme()
    }

    public required init?(coder: NSCoder) {
        nil
    }

    @objc private func clipViewBoundsDidChange(_ notification: Notification) {
        scrollBoundsDidChange()
    }

    @objc private func preferredScrollerStyleDidChange(_ notification: Notification) {
        handlePreferredScrollerStyleChange(to: NSScroller.preferredScrollerStyle)
    }

    internal func refreshTheme() {
        candidatePanel.appearance = clientAppearance
        backdropView.synchronizeAppearance(clientAppearance)
        refreshContentTheme()
        candidatePanel.contentView?.needsDisplay = true
        backdropView.needsDisplay = true
        canvasView.needsDisplay = true
        scrollView.needsDisplay = true
        scrollView.verticalScroller?.needsDisplay = true
        scrollView.horizontalScroller?.needsDisplay = true
    }

    internal func refreshContentTheme() {
        // Content inherits the glass appearance, which can differ from the client's scheme.
        resolvedSelectionColors = CandidateThemeResolver.resolvedSelectionColors(
            appearance: canvasView.effectiveAppearance,
            clientBundleIdentifier: clientBundleIdentifier,
            accentOverride: previewAccentColor
        )
        for case let itemView as CandidateItemView in canvasView.subviews {
            itemView.selectionColors = resolvedSelectionColors
        }
    }

    // Connecting or disconnecting a mouse can change the preferred style while the panel is open.
    internal func handlePreferredScrollerStyleChange(to style: NSScroller.Style) {
        finishFrameTransition()
        scrollView.scrollerStyle = style
        guard !candidates.isEmpty else {
            return
        }
        rebuildLayout()
    }

    // The input method always hides the panel before reconfiguring it, and the preview
    // repositions it afterward, so applying a configuration only needs to rebuild the layout.
    public func apply(configuration newConfiguration: CandidateConfiguration) throws {
        try newConfiguration.validate()
        guard newConfiguration != configuration else {
            return
        }
        finishFrameTransition()
        configuration = newConfiguration
        resetPresentationState()
        rebuildLayout()
    }

    @objc(synchronizeThemeWithClientAppearance:clientBundleIdentifier:)
    public func synchronizeTheme(
        clientAppearance: NSAppearance?,
        clientBundleIdentifier: String?
    ) {
        self.clientAppearance = clientAppearance
        self.clientBundleIdentifier = clientBundleIdentifier
        refreshTheme()
    }

    @objc public func reloadData() {
        guard let delegate else {
            replaceCandidates([], initialSelectedIndex: 0)
            return
        }

        let count = Int(delegate.candidateCountForController(self))
        let newCandidates = (0..<count).map { index in
            let unsignedIndex = UInt(index)
            let candidate = Candidate(
                displayString: delegate.candidateController(self, candidateAtIndex: unsignedIndex),
                detail: delegate.candidateController(self, detailAtIndex: unsignedIndex)
            )
            candidate.accessibilityReading = delegate.candidateController?(
                self, accessibilityReadingAtIndex: unsignedIndex)
            return candidate
        }
        replaceCandidates(newCandidates, initialSelectedIndex: 0)
    }

    /// A non-empty list always has a selection, so `initialSelectedIndex` clamps to its bounds.
    public func replaceCandidates(_ newCandidates: [Candidate], initialSelectedIndex: Int) {
        finishFrameTransition()
        candidates = newCandidates
        // Keep only widths for the current list, so the cache stays bounded.
        textWidths.removeAll()
        resetAccessibilityItems()
        selectionIndex =
            candidates.isEmpty ? -1 : min(max(initialSelectedIndex, 0), candidates.count - 1)
        resetPresentationState()
        rebuildLayout()
        emitSelectionChange(from: -1)
    }

    public func show(
        near anchorRect: NSRect,
        usesVerticalText: Bool = false,
        compositionRect: NSRect? = nil,
        compositionLeadingX: CGFloat? = nil,
        compositionTrailingXProvider: (() -> CGFloat)? = nil
    ) {
        guard !candidates.isEmpty, let window else {
            window?.orderOut(nil)
            return
        }

        finishFrameTransition()
        lastPlacementContext = CandidatePlacementContext(
            anchorRect: anchorRect,
            usesVerticalText: usesVerticalText,
            compositionRect: compositionRect,
            compositionLeadingX: compositionLeadingX,
            compositionTrailingXProvider: compositionTrailingXProvider
        )
        let wasVisible = window.isVisible
        updateLayout()
        window.orderFrontRegardless()
        notifyAccessibilityPresentation(wasVisible: wasVisible)
    }

    public func centerOnMainScreen() {
        finishFrameTransition()
        guard let screen = NSScreen.main ?? NSScreen.screens.first, let window else {
            return
        }
        // Centering needs the final window size, even while the panel is still hidden.
        if !visible {
            updateLayout()
        }
        let visibleFrame = screen.visibleFrame
        let point = NSPoint(
            x: visibleFrame.midX - window.frame.width / 2,
            y: visibleFrame.midY + window.frame.height / 2
        )
        movePanelManually(to: NSPoint(x: point.x, y: point.y - window.frame.height))
    }

    internal func movePanelManually(to origin: NSPoint) {
        finishFrameTransition()
        guard let window else { return }
        window.setFrameOrigin(origin)
        // A manual position replaces the composition anchor until the host supplies a new one.
        lastPlacementContext = nil
        placementSide = nil
        if layoutAvailableSize != layoutScreenSize {
            rebuildLayout()
        }
    }

    @objc(navigate:)
    @discardableResult
    public func navigate(_ navigation: CandidateNavigation) -> Bool {
        guard visible, !candidates.isEmpty else {
            return false
        }
        finishFrameTransition()

        var context = CandidateNavigationContext(
            kind: panelKind, selection: selectionIndex,
            count: candidates.count, pageSize: effectivePageSize)
        switch panelKind {
        case .horizontalPaged:
            context.pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates, keyLabels: keyLabels, configuration: configuration,
                metrics: metrics, maximumWidth: layoutAvailableWidth
            ).map(\.candidateIndexes)
        case .verticalExpandable:
            context.expanded = isExpanded
        case .vertical:
            break
        }
        guard let decision = CandidateNavigationReducer.resolve(navigation, context: context)
        else {
            // A key that cannot move the selection still brings it back into view.
            ensureSelectionVisible()
            return false
        }
        if let expansion = decision.expanded, expansion != isExpanded {
            performExpansionTransition(expanding: expansion, targetSelection: decision.selection)
        } else {
            setSelection(decision.selection)
        }
        return true
    }

    @objc(handleKeyEvent:)
    @discardableResult
    public func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard visible else {
            return false
        }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) || flags.contains(.control) {
            return false
        }

        if configuration.handlesNavigationKeys {
            if event.charactersIgnoringModifiers == " " && !flags.contains(.option) {
                showNextPage()
                return true
            }

            if event.keyCode == 48 {
                guard !flags.contains(.option) else {
                    return false
                }
                return navigate(flags.contains(.shift) ? .itemBackward : .itemForward)
            }

            if !flags.contains(.shift) && !flags.contains(.option) {
                let navigation: CandidateNavigation?
                switch event.specialKey {
                case .leftArrow:
                    navigation = .left
                case .rightArrow:
                    navigation = .right
                case .upArrow:
                    navigation = .up
                case .downArrow:
                    navigation = .down
                case .pageUp:
                    navigation = .pageUp
                case .pageDown:
                    navigation = .pageDown
                case .home:
                    navigation = .home
                case .end:
                    navigation = .end
                default:
                    navigation = nil
                }
                if let navigation {
                    return navigate(navigation)
                }
            }

            if (event.keyCode == 36 || event.keyCode == 76)
                && !flags.contains(.shift)
                && !flags.contains(.option)
            {
                confirmSelectedCandidate()
                return true
            }
        }

        guard configuration.handlesIndexLabelKeys,
            !flags.contains(.option),
            !flags.contains(.shift),
            let characters = event.charactersIgnoringModifiers,
            characters.count == 1,
            !characters.allSatisfy(\.isWhitespace)
        else {
            return false
        }
        return commitCandidate(matchingIndexLabel: Character(characters))
    }

    @objc @discardableResult
    public func highlightNextCandidate() -> Bool {
        navigate(configuration.orientation == .vertical ? .down : .right)
    }

    @objc @discardableResult
    public func highlightPreviousCandidate() -> Bool {
        navigate(configuration.orientation == .vertical ? .up : .left)
    }

    @objc @discardableResult
    public func showNextPage() -> Bool {
        navigate(.pageDown)
    }

    @objc @discardableResult
    public func showPreviousPage() -> Bool {
        navigate(.pageUp)
    }

    @objc public func candidateIndexAtKeyLabelIndex(_ index: UInt) -> UInt {
        guard visible, let resolved = relativeCandidateIndex(at: Int(index)) else {
            return UInt.max
        }
        return UInt(resolved)
    }

    public func candidateIndex(forIndexLabel label: Character) -> Int? {
        guard let position = indexLabelPosition(matching: label) else {
            return nil
        }
        return relativeCandidateIndex(at: position)
    }

    @discardableResult
    public func commitCandidate(matchingIndexLabel label: Character) -> Bool {
        guard let index = candidateIndex(forIndexLabel: label) else {
            return false
        }
        confirmCandidate(at: index)
        return true
    }

    @objc public func confirmSelectedCandidate() {
        confirmCandidate(at: selectionIndex)
    }

    internal var panelKind: CandidatePanelKind {
        CandidatePanelKind.resolve(configuration: configuration)
    }

    internal var metrics: CandidateMetrics {
        CandidateMetrics(
            requestedCandidateFont: candidateFont,
            requestedIndexFont: keyLabelFont,
            keyLabelDetails: configuration.showsKeyLabelsAsDetails
                ? keyLabels.prefix(configuration.pageSize).map(\.displayedText) : nil,
            measureText: { [weak self] text, font in
                self?.measuredWidth(of: text, font: font)
                    ?? CandidateMetrics.textWidth(text, font: font)
            }
        )
    }

    private func measuredWidth(of text: String, font: NSFont) -> CGFloat {
        if let width = textWidths[font.fontDescriptor]?[text] {
            return width
        }
        let width = CandidateMetrics.textWidth(text, font: font)
        textWidths[font.fontDescriptor, default: [:]][text] = width
        return width
    }

    internal var effectivePageSize: Int {
        currentLayout.pageSize ?? configuration.pageSize
    }

    private var layoutAvailableHeight: CGFloat {
        layoutAvailableSize.height - contentView.headerHeight
    }

    internal var layoutAvailableWidth: CGFloat {
        layoutAvailableSize.width
    }

    internal var layoutAvailableSize: NSSize {
        if let context = lastPlacementContext {
            let size = placementScreen(for: context.anchorRect).visibleFrame.size
            return NSSize(width: max(1, size.width), height: max(1, size.height))
        }
        return window?.screen?.visibleFrame.size ?? NSScreen.main?.visibleFrame.size
            ?? NSSize(
                width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    }

    internal func resetPresentationState() {
        isExpanded = false
        verticalNumberingAnchor = 0
        scrollView.contentView.scroll(to: .zero)
    }

    // The input method reconfigures the hidden panel several times before showing it,
    // so a hidden panel waits until it is shown to build its layout.
    internal func rebuildLayout() {
        guard visible else {
            return
        }
        updateLayout()
    }

    private func updateLayout() {
        let preservedScrollOrigin = scrollView.contentView.bounds.origin
        let newLayout = makeCurrentLayout()
        currentLayout = newLayout
        render(layout: newLayout, preservedScrollOrigin: preservedScrollOrigin)
    }

    // Besides building the layout, this records the screen size, configures the header,
    // and syncs isExpanded to the selection.
    internal func makeCurrentLayout() -> CandidatePanelLayout {
        layoutScreenSize = layoutAvailableSize
        let metrics = self.metrics
        contentView.configure(title: candidates.isEmpty ? "" : tooltip, metrics: metrics)
        var newLayout: CandidatePanelLayout
        switch panelKind {
        case .verticalExpandable:
            newLayout = VerticalCandidateLayoutEngine.expandableLayout(
                candidates: candidates,
                keyLabels: keyLabels,
                configuration: configuration,
                metrics: metrics,
                selectedIndex: selectionIndex,
                expanded: isExpanded,
                scrollerStyle: scrollView.scrollerStyle,
                maximumWidth: layoutAvailableWidth,
                maximumHeight: layoutAvailableHeight
            )
            if !isExpanded, selectionIndex >= (newLayout.pageSize ?? configuration.pageSize) {
                isExpanded = true
                newLayout = expandedLayout
            }
        case .horizontalPaged:
            let pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates,
                keyLabels: keyLabels,
                configuration: configuration,
                metrics: metrics,
                maximumWidth: layoutAvailableWidth
            )
            newLayout = HorizontalCandidateLayoutEngine.pagedLayout(
                pages: pages,
                pageIndex: pages.firstIndex { $0.candidateIndexes.contains(selectionIndex) } ?? 0,
                keyLabels: keyLabels,
                metrics: metrics
            )
        case .vertical:
            newLayout = VerticalCandidateLayoutEngine.layout(
                candidates: candidates,
                keyLabels: keyLabels,
                configuration: configuration,
                metrics: metrics,
                numberingAnchor: verticalNumberingAnchor,
                scrollerStyle: scrollView.scrollerStyle,
                maximumWidth: layoutAvailableWidth,
                maximumHeight: layoutAvailableHeight
            )
        }
        reserveHeader(in: &newLayout)
        return newLayout
    }

    private func reserveHeader(in layout: inout CandidatePanelLayout) {
        layout.reserveHeader(
            height: contentView.headerHeight,
            minimumWidth: min(layoutAvailableWidth, contentView.minimumHeaderWidth))
    }

    internal func render(layout: CandidatePanelLayout, preservedScrollOrigin: NSPoint) {
        synchronizeItemViews(with: layout)
        configureScrollers(for: layout)

        updateWindowSize(layout.windowSize)
        // AppKit can round fractional window sizes. Match the accepted size during redraws,
        // just as expansion transitions do, so selection changes cannot shift the border.
        let acceptedWindowSize = window?.frame.size ?? layout.windowSize
        layoutContent(size: acceptedWindowSize)
        backdropView.frame = NSRect(origin: .zero, size: acceptedWindowSize)
        scrollView.contentView.scroll(to: clampedScrollOrigin(preservedScrollOrigin))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        ensureSelectionVisible()
        if visible {
            NSAccessibility.post(element: canvasView, notification: .layoutChanged)
        }
    }

    private func synchronizeItemViews(with layout: CandidatePanelLayout) {
        let metrics = self.metrics
        let reservesIndexSlot = configuration.showsIndexColumn(for: keyLabels)
        renderer.synchronize(
            layout: layout, candidates: candidates, metrics: metrics,
            reservesIndexSlot: reservesIndexSlot,
            selection: selectionIndex, colors: resolvedSelectionColors, canvas: canvasView,
            makeItem: {
                makeItemView(for: $0, metrics: metrics, reservesIndexSlot: reservesIndexSlot)
            })
        backdropView.cornerRadius = layout.cornerRadius
    }

    internal func configureScrollers(for layout: CandidatePanelLayout) {
        scrollView.hasVerticalScroller = layout.hasVerticalScroller
        scrollView.hasHorizontalScroller = layout.hasHorizontalScroller
        scrollView.verticalScrollElasticity = layout.hasVerticalScroller ? .automatic : .none
        scrollView.horizontalScrollElasticity = layout.hasHorizontalScroller ? .automatic : .none
    }

    internal func layoutContent(size: NSSize) {
        contentView.frame = NSRect(origin: .zero, size: size)
        contentView.needsLayout = true
        contentView.layoutSubtreeIfNeeded()
    }

    internal func makeItemView(
        for item: CandidateLayoutItem,
        metrics: CandidateMetrics,
        reservesIndexSlot: Bool
    ) -> CandidateItemView {
        let view = CandidateItemView(
            frame: item.frame,
            candidate: candidates[item.candidateIndex],
            candidateIndex: item.candidateIndex,
            indexText: item.indexText,
            showsIndexText: item.showsIndexText,
            selected: item.candidateIndex == selectionIndex,
            selectionColors: resolvedSelectionColors,
            metrics: metrics,
            reservesIndexSlot: reservesIndexSlot,
            showsDetail: item.showsDetail,
            alignedCandidateWidth: item.alignedCandidateWidth
        )
        view.outerCornerRadius = currentLayout.cornerRadius
        view.onSelect = { [weak self] index in
            guard self?.isFrameTransitionActive == false else { return }
            // A clicked candidate is already on screen, so the viewport stays where it is.
            self?.setSelection(index, alignsViewportToPage: false)
        }
        view.onConfirm = { [weak self] index in
            guard self?.isFrameTransitionActive == false else { return }
            self?.confirmCandidate(at: index)
        }
        return view
    }

    internal func updateWindowSize(_ size: NSSize) {
        applyWindowFramePreservingTopLeft(reanchoredWindowFrame(for: size), display: true)
    }

    internal func windowFrame(topLeft: NSPoint, size: NSSize) -> NSRect {
        NSRect(
            x: topLeft.x,
            y: topLeft.y - size.height,
            width: size.width,
            height: size.height
        )
    }

    private func applyWindowFramePreservingTopLeft(_ frame: NSRect, display: Bool = false) {
        guard let window else { return }
        window.setFrame(frame, display: false)
        // Preserve the interpolated top-left after AppKit accepts and rounds the size.
        // Deriving the origin from the requested height alone can move the top edge.
        let topLeft = NSPoint(x: frame.minX, y: frame.maxY)
        if window.frame.minX != topLeft.x || window.frame.maxY != topLeft.y {
            window.setFrameTopLeftPoint(topLeft)
        }
        if display { window.displayIfNeeded() }
    }

    internal func finishFrameTransition() {
        frameTransitionDriver?.finish()
    }

    internal func reanchoredWindowFrame(for size: NSSize) -> NSRect {
        guard let window else {
            return .zero
        }
        guard let context = lastPlacementContext else {
            let topLeft = NSPoint(x: window.frame.minX, y: window.frame.maxY)
            let bounds = window.screen?.visibleFrame ?? screenFrame(containing: topLeft)
            let fitted = CandidatePlacementEngine.fittedTopLeft(
                topLeft, windowSize: size, bounds: bounds)
            // Manual placement replaces the text anchor, but resizing still respects screen bounds.
            return windowFrame(topLeft: fitted, size: size)
        }
        let result = placementResult(for: size, context: context)
        placementSide = result.side
        return windowFrame(topLeft: result.topLeft, size: size)
    }

    internal func placementResult(
        for windowSize: NSSize,
        context: CandidatePlacementContext
    ) -> CandidatePlacementResult {
        var requiredSize = windowSize
        if panelKind == .verticalExpandable, !isExpanded,
            candidates.count > effectivePageSize
        {
            var expanded = expandedLayout
            reserveHeader(in: &expanded)
            requiredSize = expanded.windowSize
        }
        return CandidatePlacementEngine.place(
            windowSize: windowSize,
            requiredSize: requiredSize,
            anchorRect: context.anchorRect,
            screen: placementScreen(for: context.anchorRect),
            usesVerticalText: context.usesVerticalText,
            compositionRect: context.compositionRect,
            compositionLeadingX: context.compositionLeadingX ?? context.anchorRect.minX,
            compositionTrailingX: {
                context.compositionTrailingXProvider?() ?? context.anchorRect.maxX
            }
        )
    }

    private func placementScreen(for anchorRect: NSRect) -> CandidateScreenGeometry {
        let screenGeometries = NSScreen.screens.map {
            CandidateScreenGeometry(frame: $0.frame, visibleFrame: $0.visibleFrame)
        }
        let fallbackScreen = (NSScreen.main ?? NSScreen.screens.first).map {
            CandidateScreenGeometry(frame: $0.frame, visibleFrame: $0.visibleFrame)
        }
        return CandidatePlacementEngine.screen(
            for: anchorRect,
            screens: screenGeometries,
            fallback: fallbackScreen
        )
    }

    internal func setSelection(_ requestedIndex: Int, alignsViewportToPage: Bool = true) {
        finishFrameTransition()
        let newIndex =
            candidates.isEmpty ? -1 : min(max(requestedIndex, 0), candidates.count - 1)

        guard newIndex != selectionIndex else {
            renderer[newIndex]?.needsDisplay = true
            return
        }

        let previousIndex = selectionIndex
        selectionIndex = newIndex
        if alignsViewportToPage, panelKind == .vertical, abs(newIndex - previousIndex) > 1,
            candidates.count > effectivePageSize
        {
            let pageSize = effectivePageSize
            let pageStart = newIndex / pageSize * pageSize
            let movingForward = newIndex > previousIndex
            let row =
                movingForward
                ? min(pageStart + pageSize, candidates.count) - 1 : pageStart
            if let frame = currentLayout.item(for: row)?.frame,
                !scrollView.contentView.bounds.contains(frame)
            {
                let anchor = movingForward ? max(0, row + 1 - pageSize) : row
                scrollVertical(toAnchor: anchor)
            }
        }
        rebuildLayout()
        emitSelectionChange(from: previousIndex)
    }

    internal func confirmCandidate(at index: Int) {
        guard visible, candidates.indices.contains(index) else {
            return
        }
        let candidate = candidates[index]
        onConfirmation?(index, candidate)
        delegate?.candidateController(self, didSelectCandidateAtIndex: UInt(index))
    }

    internal func relativeCandidateIndex(at relativeIndex: Int) -> Int? {
        guard visible, relativeIndex >= 0, relativeIndex < effectivePageSize else {
            return nil
        }

        let indexes: [Int]
        switch panelKind {
        case .horizontalPaged:
            indexes = currentLayout.items.map(\.candidateIndex)
        case .verticalExpandable:
            // Shortcuts number the column that holds the selection, or the compact column.
            let column = isExpanded ? max(selectionIndex, 0) / effectivePageSize : 0
            let start = column * effectivePageSize
            indexes = Array(start..<min(start + effectivePageSize, candidates.count))
        case .vertical:
            let start = verticalNumberingAnchor
            indexes = Array(start..<min(start + effectivePageSize, candidates.count))
        }

        guard indexes.indices.contains(relativeIndex) else {
            return nil
        }
        return indexes[relativeIndex]
    }

    internal func indexLabelPosition(matching label: Character) -> Int? {
        guard label.isPrintableASCII, !label.isWhitespace else {
            return nil
        }
        return keyLabels.prefix(effectivePageSize).firstIndex { keyLabel in
            keyLabel.key.count == 1 && keyLabel.key.first == label
        }
    }

    internal func emitSelectionChange(from previousIndex: Int) {
        notifyAccessibilitySelection()
        guard selectionIndex != previousIndex, candidates.indices.contains(selectionIndex) else {
            return
        }
        let candidate = candidates[selectionIndex]
        onSelectionChange?(selectionIndex, candidate)
    }

    internal func performExpansionTransition(expanding: Bool, targetSelection: Int) {
        guard let window else { return }
        finishFrameTransition()
        let previousSelection = selectionIndex
        defer { emitSelectionChange(from: previousSelection) }
        let startWindowFrame = window.frame
        isExpanded = expanding
        selectionIndex = targetSelection
        let targetLayout = makeCurrentLayout()
        currentLayout = targetLayout
        let previousSide = placementSide
        let targetWindowFrame = reanchoredWindowFrame(for: targetLayout.windowSize)
        if previousSide != placementSide {
            render(layout: targetLayout, preservedScrollOrigin: .zero)
            return
        }

        // The first column stays in place in both layouts, so only the window animates.
        // Expanding shows the new columns at once and lets the growing window reveal them.
        // Collapsing keeps the old columns until the shrinking window has hidden them.
        if expanding {
            synchronizeItemViews(with: targetLayout)
        }
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.verticalScrollElasticity = .none
        scrollView.horizontalScrollElasticity = .none
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)

        let driver = CandidateTransitionDriver(
            duration: configuration.animationDuration,
            window: window,
            update: { [weak self] progress in
                guard let self else { return }
                let frame = NSRect.interpolated(
                    from: startWindowFrame,
                    to: targetWindowFrame,
                    progress: progress
                )
                applyWindowFramePreservingTopLeft(frame)
                let acceptedWindowSize = window.frame.size
                backdropView.frame = NSRect(origin: .zero, size: acceptedWindowSize)
                layoutContent(size: acceptedWindowSize)
                canvasView.rowWashAlpha = expanding ? progress : 1 - progress
                backdropView.layoutSubtreeIfNeeded()
                window.displayIfNeeded()
            },
            completion: { [weak self] in
                guard let self else { return }
                render(layout: targetLayout, preservedScrollOrigin: .zero)
                if targetLayout.hasVerticalScroller || targetLayout.hasHorizontalScroller,
                    scrollView.scrollerStyle != .legacy
                {
                    scrollView.flashScrollers()
                }
                backdropView.layoutSubtreeIfNeeded()
                window.displayIfNeeded()
                frameTransitionDriver = nil
            }
        )
        frameTransitionDriver = driver
        driver.start()
    }

    internal var expandedLayout: CandidatePanelLayout {
        VerticalCandidateLayoutEngine.expandableLayout(
            candidates: candidates, keyLabels: keyLabels, configuration: configuration,
            metrics: metrics, selectedIndex: selectionIndex, expanded: true,
            scrollerStyle: scrollView.scrollerStyle,
            maximumWidth: layoutAvailableWidth,
            maximumHeight: layoutAvailableHeight
        )
    }

    internal func scrollVertical(toAnchor anchor: Int) {
        let origin = NSPoint(x: 0, y: CGFloat(anchor) * metrics.rowPitch)
        scrollView.contentView.scroll(to: clampedScrollOrigin(origin))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        scrollBoundsDidChange()
    }

    internal func ensureSelectionVisible() {
        guard selectionIndex >= 0,
            let frame = currentLayout.item(for: selectionIndex)?.frame,
            currentLayout.hasVerticalScroller || currentLayout.hasHorizontalScroller
        else {
            return
        }
        let visible = scrollView.contentView.bounds
        let horizontal = currentLayout.hasHorizontalScroller
        let viewport = horizontal ? visible.minX...visible.maxX : visible.minY...visible.maxY
        let item = horizontal ? frame.minX...frame.maxX : frame.minY...frame.maxY
        var target = viewport.lowerBound
        if item.lowerBound < viewport.lowerBound {
            target = item.lowerBound
        } else if item.upperBound > viewport.upperBound {
            target = item.upperBound - (viewport.upperBound - viewport.lowerBound)
        } else {
            return
        }
        let origin = horizontal ? NSPoint(x: target, y: 0) : NSPoint(x: 0, y: target)
        scrollView.contentView.scroll(to: clampedScrollOrigin(origin))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    internal func clampedScrollOrigin(_ origin: NSPoint) -> NSPoint {
        let maximumY = max(0, currentLayout.documentSize.height - currentLayout.viewportSize.height)
        let maximumX = max(0, currentLayout.documentSize.width - currentLayout.viewportSize.width)
        return NSPoint(x: min(max(origin.x, 0), maximumX), y: min(max(origin.y, 0), maximumY))
    }

    internal func scrollBoundsDidChange() {
        guard panelKind == .vertical else {
            return
        }
        let anchor = numberingAnchor(atOffset: scrollView.contentView.bounds.minY)
        if anchor != verticalNumberingAnchor {
            verticalNumberingAnchor = anchor
            updateVerticalIndexLabels()
        }
    }

    internal func updateVerticalIndexLabels() {
        for view in renderer.itemViews {
            let relative = view.candidateIndex - verticalNumberingAnchor
            let isNumbered = relative >= 0 && relative < effectivePageSize
            view.indexText =
                isNumbered && keyLabels.indices.contains(relative)
                ? keyLabels[relative].displayedText
                : ""
            view.showsIndexText = isNumbered
        }
    }

    // A row takes the first label once the row above it is more than half scrolled away.
    internal func numberingAnchor(atOffset offset: CGFloat) -> Int {
        let metrics = self.metrics
        let row = Int((max(0, offset) + metrics.itemHeight / 2) / metrics.rowPitch)
        return min(row, max(candidates.count - 1, 0))
    }

    internal func screenFrame(containing point: NSPoint) -> NSRect {
        NSScreen.screens.first(where: { $0.frame.contains(point) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? .zero
    }
}
