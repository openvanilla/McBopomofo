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
    case pageBackward
    case pageForward
    case home
    case end
    case itemBackward
    case itemForward
}

public enum CandidateConfigurationError: Error, Equatable, LocalizedError {
    case invalidPageSize(Int)
    case invalidIndexLabel(Character)

    public var errorDescription: String? {
        switch self {
        case .invalidPageSize(let value):
            "Candidate page size must be between 1 and 15. Received \(value)."
        case .invalidIndexLabel(let value):
            "Candidate index label must be one printable ASCII character. Received \(value)."
        }
    }
}

public struct CandidateConfiguration: Equatable, Sendable {
    public var orientation: CandidateOrientation
    public var allowsExpansion: Bool
    public var candidateFontSize: CGFloat
    public var indexLabels: String
    public var pageSize: Int
    /// Render key labels after the candidate, replacing its detail and omitting the index column.
    public var showsKeyLabelsAsDetails: Bool
    public var usesWideExpandedCells: Bool
    public var advancesSelectionWhenExpanding: Bool
    public var animationDuration: TimeInterval
    public var horizontalMaximumVisibleRows: Int
    public var verticalMinimumVisibleRows: Int?
    public var verticalMaximumVisibleColumns: Int
    public var hostHandlesNavigationKeys: Bool
    public var hostHandlesIndexLabelKeys: Bool

    public init(
        orientation: CandidateOrientation = .horizontal,
        allowsExpansion: Bool = true,
        candidateFontSize: CGFloat = 16,
        indexLabels: String = "1234567890",
        pageSize: Int = 9,
        showsKeyLabelsAsDetails: Bool = false,
        usesWideExpandedCells: Bool = true,
        advancesSelectionWhenExpanding: Bool = false,
        animationDuration: TimeInterval = 0.2,
        horizontalMaximumVisibleRows: Int = 5,
        verticalMinimumVisibleRows: Int? = nil,
        verticalMaximumVisibleColumns: Int = 5,
        hostHandlesNavigationKeys: Bool = true,
        hostHandlesIndexLabelKeys: Bool = true
    ) throws {
        self.orientation = orientation
        self.allowsExpansion = allowsExpansion
        self.candidateFontSize = candidateFontSize
        self.indexLabels = indexLabels
        self.pageSize = pageSize
        self.showsKeyLabelsAsDetails = showsKeyLabelsAsDetails
        self.usesWideExpandedCells = usesWideExpandedCells
        self.advancesSelectionWhenExpanding = advancesSelectionWhenExpanding
        self.animationDuration = animationDuration
        self.horizontalMaximumVisibleRows = horizontalMaximumVisibleRows
        self.verticalMinimumVisibleRows = verticalMinimumVisibleRows
        self.verticalMaximumVisibleColumns = verticalMaximumVisibleColumns
        self.hostHandlesNavigationKeys = hostHandlesNavigationKeys
        self.hostHandlesIndexLabelKeys = hostHandlesIndexLabelKeys
        try validate()
    }

    public static var `default`: CandidateConfiguration {
        try! CandidateConfiguration()
    }

    public func validate() throws {
        guard (1...15).contains(pageSize) else {
            throw CandidateConfigurationError.invalidPageSize(pageSize)
        }
        for character in indexLabels {
            guard character.isPrintableASCII else {
                throw CandidateConfigurationError.invalidIndexLabel(character)
            }
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
    @objc public let context: Any?
    @objc public var accessibilityReading: String?

    @objc public init(displayString: String, detail: String? = nil, context: Any? = nil) {
        self.displayString = displayString
        self.detail = detail?.isEmpty == true ? nil : detail
        self.context = context
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
    func candidateController(_ controller: CandidateController, readingAtIndex index: UInt)
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
        didHighlightCandidateAtIndex index: UInt
    )
    @objc optional func candidateController(
        _ controller: CandidateController,
        contextAtIndex index: UInt
    ) -> Any?
    @objc optional func candidateController(
        _ controller: CandidateController,
        accessibilityReadingAtIndex index: UInt
    ) -> String?
}

@MainActor
@objc(CKCandidateController)
open class CandidateController: NSWindowController {
    @objc public weak var delegate: (any CandidateControllerDelegate)?

    public var onSelectionChange: ((String, Int, Candidate?) -> Void)?
    public var onConfirmation: ((String, Int, Candidate?) -> Void)?

    @objc public var tooltip = "" {
        didSet {
            guard tooltip != oldValue else { return }
            finishFrameTransition()
            rebuildLayout()
        }
    }

    @objc public var candidateFont: NSFont {
        didSet {
            guard !isApplyingConfiguration,
                candidateFont != oldValue
                    || configuration.candidateFontSize != candidateFont.pointSize
            else {
                return
            }
            finishFrameTransition()
            configuration.candidateFontSize = candidateFont.pointSize
            rebuildLayout()
        }
    }

    @objc public var keyLabelFont: NSFont {
        didSet {
            guard !isApplyingConfiguration, keyLabelFont != oldValue else {
                return
            }
            finishFrameTransition()
            rebuildLayout()
        }
    }

    @objc public var keyLabels: [CandidateKeyLabel] {
        didSet {
            guard !isApplyingConfiguration,
                !keyLabels.elementsEqual(
                    oldValue, by: { $0.key == $1.key && $0.displayedText == $1.displayedText })
            else {
                return
            }
            finishFrameTransition()
            configuration.indexLabels = keyLabels.map(\.key).joined()
            rebuildLayout()
        }
    }

    public private(set) var configuration: CandidateConfiguration
    public var inputCandidates: [Candidate] { candidates }
    public private(set) var candidates: [Candidate] = []
    public private(set) var clientAppearance: NSAppearance?
    public private(set) var clientBundleIdentifier: String?
    private var previewAccentColor: NSColor?

    @_spi(CandidatePreview)
    public static func previewCandidateItem(_ text: String) -> (
        view: NSView, setColors: (NSColor, NSColor) -> Void
    ) {
        let font = NSFont.systemFont(ofSize: CandidateConfiguration.default.candidateFontSize)
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

    @objc public var selectedCandidateIndex: UInt {
        get {
            selectionIndex < 0 ? UInt.max : UInt(selectionIndex)
        }
        set {
            setSelection(newValue == UInt.max ? -1 : Int(newValue))
        }
    }

    @objc public private(set) var selectionIndex: Int {
        get { presentation.selection }
        set { presentation.selection = newValue }
    }

    @objc public var visible: Bool {
        get { window?.isVisible == true }
        set {
            let wasVisible = visible
            if newValue {
                guard !candidates.isEmpty else {
                    window?.orderOut(nil)
                    return
                }
                window?.orderFrontRegardless()
                prepareMeasurements()
                notifyAccessibilityPresentation(wasVisible: wasVisible)
            } else {
                textMeasurements.cancel()
                deferredMeasurementRefresh = false
                finishFrameTransition()
                lastPlacementContext = lastPlacementContext?.clearingCompositionEdges()
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
    internal let renderer = CandidateRenderer()
    internal var renderedControlView: CandidateControlView? { renderer.control }
    internal var accessibilityItems: [CandidateAccessibilityItem] = []
    internal var presentation = CandidatePresentationState()
    internal var currentPageIndex: Int {
        get { presentation.page }
        set { presentation.page = newValue }
    }
    internal var isExpanded: Bool {
        get { presentation.expanded }
        set { presentation.expanded = newValue }
    }
    internal var verticalNumberingAnchor: Int {
        get { presentation.shortcutOrigin }
        set { presentation.shortcutOrigin = newValue }
    }
    internal var verticalMinimumDocumentHeight: CGFloat {
        get { presentation.minimumDocumentHeight }
        set { presentation.minimumDocumentHeight = newValue }
    }
    internal var isPerformingVerticalPageScroll = false
    internal let textMeasurements = CandidateTextMeasurements()
    private var measurementFontDescriptor: NSFontDescriptor?
    internal private(set) var deferredMeasurementRefresh = false
    private var finishesTransitionSynchronously = false
    internal var isFrameTransitionActive = false
    internal var isWindowMovementTransitionActive = false
    internal var lastRequestedTopLeft: NSPoint?
    internal var lastPlacementContext: CandidatePlacementContext?
    internal var frameTransitionDriver: CandidateTransitionDriver?
    internal var transitionClock: (any CandidateTransitionClock)?
    public private(set) var placementSide: CandidatePlacementSide?
    internal var resolvedSelectionColors = CandidateSelectionColors.system
    internal var isApplyingConfiguration = false
    nonisolated(unsafe) internal var scrollObservation: NSObjectProtocol?
    nonisolated(unsafe) internal var systemColorObservation: NSObjectProtocol?
    nonisolated(unsafe) internal var scrollerStyleObservation: NSObjectProtocol?

    public convenience init() {
        self.init(configuration: .default)
    }

    public init(configuration: CandidateConfiguration) {
        self.configuration = configuration
        self.candidateFont = .systemFont(
            ofSize: max(configuration.candidateFontSize, CandidateStyle.Typography.minimumSize)
        )
        let indexFontSize =
            (CandidateStyle.Typography.shortcutEm
            * max(configuration.candidateFontSize, CandidateStyle.Typography.minimumSize)).rounded()
        self.keyLabelFont = .systemFont(ofSize: indexFontSize)
        self.keyLabels = configuration.indexLabels.map {
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

        scrollObservation = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scroll.contentView,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scrollBoundsDidChange()
            }
        }
        systemColorObservation = NotificationCenter.default.addObserver(
            forName: NSColor.systemColorsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshTheme()
            }
        }
        scrollerStyleObservation = NotificationCenter.default.addObserver(
            forName: NSScroller.preferredScrollerStyleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handlePreferredScrollerStyleChange(
                    to: NSScroller.preferredScrollerStyle,
                    forceRebuild: true
                )
            }
        }
        textMeasurements.onCompletion = { [weak self] in
            self?.applyCompletedMeasurements()
        }
        refreshTheme()
    }

    public required init?(coder: NSCoder) {
        nil
    }

    deinit {
        if let scrollObservation {
            NotificationCenter.default.removeObserver(scrollObservation)
        }
        if let systemColorObservation {
            NotificationCenter.default.removeObserver(systemColorObservation)
        }
        if let scrollerStyleObservation {
            NotificationCenter.default.removeObserver(scrollerStyleObservation)
        }
    }

    internal func applyConfigurationValues(_ newConfiguration: CandidateConfiguration) {
        isApplyingConfiguration = true
        configuration = newConfiguration
        candidateFont = .systemFont(
            ofSize: max(newConfiguration.candidateFontSize, CandidateStyle.Typography.minimumSize)
        )
        keyLabelFont = .systemFont(
            ofSize: (CandidateStyle.Typography.shortcutEm
                * max(newConfiguration.candidateFontSize, CandidateStyle.Typography.minimumSize))
                .rounded()
        )
        keyLabels = newConfiguration.indexLabels.map {
            CandidateKeyLabel(key: String($0), displayedText: String($0))
        }
        isApplyingConfiguration = false
    }

    internal func refreshTheme() {
        candidatePanel.appearance = clientAppearance
        backdropView.synchronizeAppearance(clientAppearance)
        refreshContentTheme()
        candidatePanel.contentView?.needsDisplay = true
        backdropView.needsDisplay = true
        canvasView.needsDisplay = true
        renderedControlView?.needsDisplay = true
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

    internal func handlePreferredScrollerStyleChange(
        to style: NSScroller.Style,
        forceRebuild: Bool = false
    ) {
        let styleChanged = scrollView.scrollerStyle != style
        guard styleChanged || forceRebuild else {
            return
        }
        finishFrameTransition()
        scrollView.scrollerStyle = style
        guard isWindowLoaded, !candidates.isEmpty else {
            return
        }

        switch panelKind {
        case .horizontalExpandable where isExpanded, .verticalExpandable where isExpanded:
            let preservedScrollOrigin = scrollView.contentView.bounds.origin
            let newLayout = makeCurrentLayout()
            currentLayout = newLayout
            render(layout: newLayout, preservedScrollOrigin: preservedScrollOrigin)
        case .vertical:
            verticalNumberingAnchor = 0
            scrollView.contentView.scroll(to: .zero)
            let newLayout = makeCurrentLayout()
            currentLayout = newLayout
            render(
                layout: newLayout,
                preservedScrollOrigin: .zero,
                ensuresSelectionVisible: false
            )
        default:
            break
        }
    }

    public func apply(configuration newConfiguration: CandidateConfiguration) throws {
        try newConfiguration.validate()
        guard newConfiguration != configuration else {
            return
        }
        finishFrameTransition()
        let wasVisible = visible
        let changesPanel = panelKind != CandidatePanelKind.resolve(configuration: newConfiguration)
        let placementContext = lastPlacementContext
        if wasVisible, changesPanel {
            window?.orderOut(nil)
        }
        applyConfigurationValues(newConfiguration)
        refreshTheme()
        resetPresentationState()
        rebuildLayout()
        if wasVisible {
            if changesPanel, let placementContext {
                show(
                    near: placementContext.anchorRect,
                    compositionLeadingX: placementContext.compositionLeadingX,
                    compositionTrailingXProvider: placementContext.compositionTrailingXProvider
                )
            } else {
                visible = true
            }
        }
    }

    public func replaceCandidates(
        _ newCandidates: [Candidate],
        initialSelectedIndex: Int,
        applying newConfiguration: CandidateConfiguration
    ) throws {
        try newConfiguration.validate()
        deferredMeasurementRefresh = false
        finishFrameTransition()
        let wasVisible = visible
        let placementContext = lastPlacementContext
        applyConfigurationValues(newConfiguration)
        refreshTheme()
        installCandidates(
            newCandidates,
            initialSelectedIndex: initialSelectedIndex
        )
        if wasVisible, let placementContext {
            show(
                near: placementContext.anchorRect,
                compositionLeadingX: placementContext.compositionLeadingX,
                compositionTrailingXProvider: placementContext.compositionTrailingXProvider
            )
        } else if wasVisible {
            visible = true
        }
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
            replaceCandidates([], initialSelectedIndex: -1)
            return
        }

        let count = Int(delegate.candidateCountForController(self))
        let newCandidates = (0..<count).map { index in
            let unsignedIndex = UInt(index)
            let candidate = Candidate(
                displayString: delegate.candidateController(self, candidateAtIndex: unsignedIndex),
                detail: delegate.candidateController(self, readingAtIndex: unsignedIndex),
                context: delegate.candidateController?(self, contextAtIndex: unsignedIndex)
            )
            candidate.accessibilityReading = delegate.candidateController?(
                self, accessibilityReadingAtIndex: unsignedIndex)
            return candidate
        }
        replaceCandidates(newCandidates, initialSelectedIndex: newCandidates.isEmpty ? -1 : 0)
    }

    public func replaceCandidates(_ newCandidates: [Candidate], initialSelectedIndex: Int) {
        deferredMeasurementRefresh = false
        finishFrameTransition()
        installCandidates(newCandidates, initialSelectedIndex: initialSelectedIndex)
    }

    internal func installCandidates(
        _ newCandidates: [Candidate],
        initialSelectedIndex: Int
    ) {
        candidates = newCandidates
        resetAccessibilityItems()
        selectionIndex =
            candidates.isEmpty || initialSelectedIndex < 0
            ? -1 : min(initialSelectedIndex, candidates.count - 1)
        resetPresentationState()
        rebuildLayout()
        emitSelectionChange(from: -1)
    }

    @objc(setWindowTopLeftPoint:bottomOutOfScreenAdjustmentHeight:)
    public func set(
        windowTopLeftPoint: NSPoint,
        bottomOutOfScreenAdjustmentHeight: CGFloat
    ) {
        finishFrameTransition()
        var point = windowTopLeftPoint
        let screenFrame = screenFrame(containing: point)
        let size = window?.frame.size ?? .zero

        if point.y - size.height < screenFrame.minY {
            point.y += bottomOutOfScreenAdjustmentHeight + size.height
        }
        point = CandidatePlacementEngine.fittedTopLeft(point, windowSize: size, bounds: screenFrame)
        movePanelManually(to: NSPoint(x: point.x, y: point.y - size.height))
    }

    @objc(showNearAnchorRect:)
    public func showNearAnchorRect(_ anchorRect: NSRect) {
        show(near: anchorRect)
    }

    public func show(
        near anchorRect: NSRect,
        compositionLeadingX: CGFloat? = nil,
        compositionTrailingXProvider: (() -> CGFloat)? = nil
    ) {
        guard !candidates.isEmpty, let window else {
            window?.orderOut(nil)
            return
        }

        let context = CandidatePlacementContext(
            anchorRect: anchorRect,
            compositionLeadingX: compositionLeadingX,
            compositionTrailingXProvider: compositionTrailingXProvider
        )
        let previousWidth = layoutAvailableWidth
        lastPlacementContext = context
        if layoutAvailableWidth != previousWidth {
            finishFrameTransition()
            rebuildLayout()
        }
        let result = placementResult(for: currentLayout.windowSize, context: context)
        let previousSide = placementSide
        let previousRequestedTopLeft = lastRequestedTopLeft
        let wasVisible = window.isVisible
        lastPlacementContext = context
        lastRequestedTopLeft = result.topLeft
        placementSide = result.side

        let targetFrame = windowFrame(topLeft: result.topLeft, size: currentLayout.windowSize)
        if !wasVisible || previousSide != result.side {
            finishFrameTransition()
            applyWindowFramePreservingTopLeft(targetFrame, display: true)
        } else {
            let wasRetargetingMovement = isWindowMovementTransitionActive
            if isWindowMovementTransitionActive {
                cancelWindowMovementTransition()
            }
            guard !isFrameTransitionActive else {
                window.orderFrontRegardless()
                return
            }
            let movementStart =
                wasRetargetingMovement
                ? NSPoint(x: window.frame.minX, y: window.frame.maxY)
                : previousRequestedTopLeft
                    ?? NSPoint(x: window.frame.minX, y: window.frame.maxY)
            if CandidatePlacementEngine.shouldAnimateMovement(
                from: movementStart,
                to: result.topLeft,
                rowHeight: metrics.itemHeight
            ) {
                animateWindowFrame(to: targetFrame)
            } else {
                applyWindowFramePreservingTopLeft(targetFrame, display: true)
            }
        }
        window.orderFrontRegardless()
        prepareMeasurements()
        notifyAccessibilityPresentation(wasVisible: wasVisible)
    }

    public func centerOnMainScreen() {
        finishFrameTransition()
        guard let screen = NSScreen.main ?? NSScreen.screens.first, let window else {
            return
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
        lastRequestedTopLeft = NSPoint(x: window.frame.minX, y: window.frame.maxY)
    }

    @discardableResult
    public func navigate(_ navigation: CandidateNavigation, wrapping: Bool = false) -> Bool {
        guard visible, !candidates.isEmpty else {
            return false
        }
        finishFrameTransition()

        let bands =
            panelKind == .horizontalPaged
            ? HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates, configuration: configuration, metrics: metrics)
            : currentLayout.rows
        let context = CandidateNavigationContext(
            state: presentation, kind: panelKind, orientation: configuration.orientation,
            count: candidates.count, pageSize: configuration.pageSize,
            advanceOnExpansion: configuration.advancesSelectionWhenExpanding,
            bands: bands,
            expandedBands: configuration.allowsExpansion && !isExpanded ? expandedRows : bands)
        guard
            let decision = CandidateNavigationReducer.resolve(
                navigation, wrapping: wrapping, context: context)
        else { return false }
        func applyViewportRequest() {
            switch decision.viewport {
            case .verticalAnchor(let anchor): scrollVertical(toAnchor: anchor)
            case nil: break
            }
        }
        if let page = decision.page { currentPageIndex = page }
        if let expansion = decision.expanded, expansion != isExpanded {
            if expansion {
                expandExpandable(selecting: decision.selection)
            } else {
                collapseExpandable()
            }
            applyViewportRequest()
        } else {
            applyViewportRequest()
            setSelection(decision.selection)
        }
        if decision.ensuresSelectionVisible { ensureSelectionVisible() }
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

        if configuration.hostHandlesNavigationKeys {
            if event.keyCode == 48 {
                guard !flags.contains(.option) else {
                    return false
                }
                return navigate(
                    flags.contains(.shift) ? .itemBackward : .itemForward,
                    wrapping: true
                )
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

        guard configuration.hostHandlesIndexLabelKeys,
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
        navigate(.pageForward)
    }

    @objc @discardableResult
    public func showPreviousPage() -> Bool {
        navigate(.pageBackward)
    }

    @objc public func candidateIndexAtKeyLabelIndex(_ index: UInt) -> UInt {
        guard visible, let resolved = relativeCandidateIndex(at: Int(index)) else {
            return UInt.max
        }
        return UInt(resolved)
    }

    @discardableResult
    public func commitCandidate(atRelativeIndex index: Int) -> Bool {
        guard let absoluteIndex = relativeCandidateIndex(at: index) else {
            return false
        }
        confirmCandidate(at: absoluteIndex)
        return true
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
        if selectionIndex < 0 {
            onConfirmation?("", -1, nil)
            return
        }
        guard visible else {
            return
        }
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
            rawCandidateFontSize: configuration.candidateFontSize,
            availableWidth: layoutAvailableWidth,
            measurementStore: textMeasurements
        )
    }

    internal var layoutAvailableWidth: CGFloat {
        if let context = lastPlacementContext {
            return max(1, placementScreen(for: context.anchorRect).visibleFrame.width)
        }
        return window?.screen?.visibleFrame.width ?? NSScreen.main?.visibleFrame.width
            ?? .greatestFiniteMagnitude
    }

    internal func resetPresentationState() {
        currentPageIndex = 0
        isExpanded = false
        verticalNumberingAnchor = 0
        verticalMinimumDocumentHeight = 0
        measurementFontDescriptor = candidateFont.fontDescriptor
        textMeasurements.begin(candidates: candidates, metrics: metrics)
        scrollView.contentView.scroll(to: .zero)
    }

    internal func prepareMeasurements() {
        if measurementFontDescriptor != candidateFont.fontDescriptor {
            measurementFontDescriptor = candidateFont.fontDescriptor
            textMeasurements.begin(candidates: candidates, metrics: metrics)
        }
        guard configuration.orientation == .vertical else { return }
        let viewportCount =
            panelKind == .verticalExpandable && isExpanded
            ? configuration.pageSize * visibleExpandedRowCount + 1
            : max(configuration.pageSize, configuration.verticalMinimumVisibleRows ?? 0) + 1
        let start = min(candidates.count, max(0, verticalNumberingAnchor))
        textMeasurements.prime(
            candidates, indexes: start..<min(start + viewportCount, candidates.count),
            metrics: metrics)
        if selectionIndex >= 0 {
            textMeasurements.prime(
                candidates,
                indexes: selectionIndex..<min(selectionIndex + viewportCount, candidates.count),
                metrics: metrics)
        }
        if visible { textMeasurements.resume(batchSize: configuration.pageSize) }
    }

    internal func applyCompletedMeasurements(animated: Bool = true) {
        guard visible, configuration.orientation == .vertical else { return }
        if isFrameTransitionActive {
            deferredMeasurementRefresh = true
            return
        }
        deferredMeasurementRefresh = false
        guard let window else { return }
        let viewportOrigin = scrollView.contentView.bounds.origin
        let initialFrame = window.frame
        var snapshot = makeCurrentLayout()
        snapshot.windowSize.width = max(currentLayout.windowSize.width, snapshot.windowSize.width)
        currentLayout = snapshot
        guard snapshot.windowSize.width > initialFrame.width else {
            render(
                layout: snapshot, preservedScrollOrigin: viewportOrigin,
                ensuresSelectionVisible: false)
            return
        }
        let bounds =
            window.screen?.visibleFrame
            ?? screenFrame(containing: NSPoint(x: initialFrame.minX, y: initialFrame.maxY))
        let topLeft = CandidatePlacementEngine.fittedTopLeft(
            NSPoint(x: initialFrame.minX, y: initialFrame.maxY),
            windowSize: snapshot.windowSize, bounds: bounds)
        let finalFrame = windowFrame(topLeft: topLeft, size: snapshot.windowSize)
        render(
            layout: snapshot, preservedScrollOrigin: viewportOrigin,
            updatesWindowFrame: false, ensuresSelectionVisible: false)
        let applyFrame: (NSRect) -> Void = { [weak self] frame in
            guard let self else { return }
            self.applyWindowFramePreservingTopLeft(frame)
            let acceptedSize = window.frame.size
            self.backdropView.frame = NSRect(origin: .zero, size: acceptedSize)
            self.layoutContent(size: acceptedSize)
            self.backdropView.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
        }
        if !animated {
            applyFrame(finalFrame)
            scrollView.contentView.scroll(to: clampedScrollOrigin(viewportOrigin))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            return
        }
        startFrameTransition(
            update: { progress in
                applyFrame(
                    CandidateWindowFrameInterpolator.interpolated(
                        from: initialFrame, to: finalFrame, progress: progress))
            },
            completion: { [weak self] in
                guard let self else { return }
                applyFrame(finalFrame)
                self.scrollView.contentView.scroll(to: self.clampedScrollOrigin(viewportOrigin))
                self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
            }
        )
    }

    internal func synchronizePresentationStateForSelection() {
        guard selectionIndex >= 0 else {
            return
        }

        switch panelKind {
        case .verticalExpandable where !isExpanded:
            isExpanded = selectionIndex >= configuration.pageSize
        case .horizontalExpandable where !isExpanded:
            let collapsedRow = HorizontalCandidateLayoutEngine.collapsedRow(
                candidates: candidates,
                configuration: configuration,
                metrics: metrics
            )
            if !collapsedRow.candidateIndexes.contains(selectionIndex) {
                isExpanded = true
            }
        case .horizontalPaged:
            let pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates,
                configuration: configuration,
                metrics: metrics
            )
            if let selectedPage = pages.firstIndex(where: {
                $0.candidateIndexes.contains(selectionIndex)
            }) {
                currentPageIndex = selectedPage
            }
        default:
            break
        }
    }

    internal func rebuildLayout() {
        guard isWindowLoaded else {
            return
        }

        synchronizePresentationStateForSelection()
        let preservedScrollOrigin = scrollView.contentView.bounds.origin
        let newLayout = makeCurrentLayout()
        currentLayout = newLayout
        render(layout: newLayout, preservedScrollOrigin: preservedScrollOrigin)
    }

    internal func makeCurrentLayout() -> CandidatePanelLayout {
        prepareMeasurements()
        let metrics = self.metrics
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
                maximumWidth: layoutAvailableWidth
            )
        case .horizontalExpandable:
            newLayout = HorizontalCandidateLayoutEngine.expandableLayout(
                candidates: candidates,
                keyLabels: keyLabels,
                configuration: configuration,
                metrics: metrics,
                selectedIndex: selectionIndex,
                expanded: isExpanded,
                scrollerStyle: scrollView.scrollerStyle
            )
        case .horizontalPaged:
            let pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates,
                configuration: configuration,
                metrics: metrics
            )
            currentPageIndex = min(max(currentPageIndex, 0), max(pages.count - 1, 0))
            newLayout = HorizontalCandidateLayoutEngine.pagedLayout(
                pages: pages,
                pageIndex: currentPageIndex,
                keyLabels: keyLabels,
                configuration: configuration,
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
                minimumDocumentHeight: verticalMinimumDocumentHeight,
                measuredIndexes: Set(
                    candidates.indices.filter {
                        textMeasurements.contains(candidates[$0], metrics: metrics)
                    })
            )
        }
        contentView.configure(title: candidates.isEmpty ? "" : tooltip, metrics: metrics)
        let screenWidth =
            window?.screen?.visibleFrame.width ?? NSScreen.main?.visibleFrame.width
            ?? newLayout.windowSize.width
        newLayout.reserveHeader(
            height: contentView.headerHeight,
            minimumWidth: min(
                screenWidth,
                contentView.titleView.intrinsicContentSize.width + contentView.padding * 2))
        if newLayout.headerHeight > 0, configuration.orientation == .vertical {
            newLayout.cornerRadius = metrics.scaledAuxiliary(
                CandidateStyle.Decoration.defaultCornerRadius)
        }
        return newLayout
    }

    internal func render(
        layout: CandidatePanelLayout,
        preservedScrollOrigin: NSPoint,
        updatesWindowFrame: Bool = true,
        ensuresSelectionVisible: Bool = true
    ) {
        renderer.synchronize(
            layout: layout, candidates: candidates, metrics: metrics,
            selection: selectionIndex, colors: resolvedSelectionColors, canvas: canvasView,
            makeItem: { makeItemView(for: $0, interactive: true) },
            makeControl: { makeControlView(for: $0, interactive: true) })
        candidatePanel.dragActivationDistance = metrics.dragActivationDistance

        configureScrollers(for: layout)
        backdropView.cornerRadius = layout.cornerRadius

        if updatesWindowFrame {
            updateWindowSize(layout.windowSize)
            // AppKit can round fractional window sizes. Match the accepted size during redraws,
            // just as expansion transitions do, so selection changes cannot shift the border.
            let acceptedWindowSize = window?.frame.size ?? layout.windowSize
            layoutContent(size: acceptedWindowSize)
            backdropView.frame = NSRect(origin: .zero, size: acceptedWindowSize)
        }
        scrollView.contentView.scroll(to: clampedScrollOrigin(preservedScrollOrigin))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        if ensuresSelectionVisible {
            ensureSelectionVisible()
        }
        if visible {
            NSAccessibility.post(element: canvasView, notification: .layoutChanged)
        }
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
        interactive: Bool
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
            reservesIndexSlot: !configuration.indexLabels.isEmpty
                && !configuration.showsKeyLabelsAsDetails,
            showsDetail: item.showsDetail,
            alignedCandidateWidth: item.alignedCandidateWidth
        )
        view.outerCornerRadius = currentLayout.cornerRadius
        if interactive {
            view.onSelect = { [weak self] index in
                guard self?.isFrameTransitionActive == false else { return }
                self?.setSelection(index)
            }
            view.onConfirm = { [weak self] index in
                guard self?.isFrameTransitionActive == false else { return }
                self?.confirmCandidate(at: index)
            }
        }
        return view
    }

    internal func makeControlView(
        for control: CandidateControlLayout,
        interactive: Bool
    ) -> CandidateControlView {
        let view = CandidateControlView(
            frame: control.frame,
            metrics: metrics
        )
        if interactive {
            view.onExpand = { [weak self] in
                guard let self, !isFrameTransitionActive,
                    panelKind == .horizontalExpandable, !isExpanded
                else { return }
                expandExpandable(selecting: max(selectionIndex, 0))
            }
        }
        return view
    }

    internal func updateWindowSize(_ size: NSSize) {
        guard let window else {
            return
        }
        let frame = reanchoredWindowFrame(for: size)
        window.setFrame(frame, display: true)
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

    internal func animateWindowFrame(to targetFrame: NSRect) {
        guard let window, frameTransitionDriver == nil else {
            return
        }
        let startFrame = window.frame
        isWindowMovementTransitionActive = true
        startFrameTransition(
            update: { [weak self] progress in
                self?.applyWindowFramePreservingTopLeft(
                    CandidateWindowFrameInterpolator.interpolated(
                        from: startFrame,
                        to: targetFrame,
                        progress: progress
                    ),
                    display: true
                )
            },
            completion: { [weak self] in
                self?.isWindowMovementTransitionActive = false
            }
        )
    }

    internal func startFrameTransition(
        update: @escaping (CGFloat) -> Void,
        completion: @escaping () -> Void = {}
    ) {
        guard frameTransitionDriver == nil else {
            return
        }
        isFrameTransitionActive = true
        let driver = CandidateTransitionDriver(
            duration: configuration.animationDuration,
            window: window,
            clock: transitionClock,
            update: update,
            completion: { [weak self] in
                completion()
                self?.frameTransitionDriver = nil
                self?.isFrameTransitionActive = false
                if let self, self.deferredMeasurementRefresh {
                    self.applyCompletedMeasurements(animated: !self.finishesTransitionSynchronously)
                }
            }
        )
        frameTransitionDriver = driver
        driver.start()
    }

    internal func finishFrameTransition() {
        guard let driver = frameTransitionDriver else {
            isFrameTransitionActive = false
            isWindowMovementTransitionActive = false
            return
        }
        let wasFinishingSynchronously = finishesTransitionSynchronously
        finishesTransitionSynchronously = true
        defer { finishesTransitionSynchronously = wasFinishingSynchronously }
        driver.finish()
        if frameTransitionDriver === driver {
            frameTransitionDriver = nil
        }
        isFrameTransitionActive = false
        isWindowMovementTransitionActive = false
    }

    internal func cancelWindowMovementTransition() {
        guard isWindowMovementTransitionActive, let driver = frameTransitionDriver else {
            return
        }
        driver.cancel()
        if frameTransitionDriver === driver {
            frameTransitionDriver = nil
        }
        isFrameTransitionActive = false
        isWindowMovementTransitionActive = false
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
            return windowFrame(
                topLeft: fitted,
                size: size
            )
        }
        let result = placementResult(for: size, context: context)
        lastRequestedTopLeft = result.topLeft
        placementSide = result.side
        return windowFrame(topLeft: result.topLeft, size: size)
    }

    internal func placementResult(
        for windowSize: NSSize,
        context: CandidatePlacementContext
    ) -> CandidatePlacementResult {
        CandidatePlacementEngine.place(
            windowSize: windowSize,
            anchorRect: context.anchorRect,
            screen: placementScreen(for: context.anchorRect),
            compositionLeadingX: context.compositionLeadingX ?? context.anchorRect.minX,
            compositionTrailingX: {
                context.compositionTrailingXProvider?() ?? context.anchorRect.maxX
            }
        )
    }

    private func placementScreen(for anchorRect: NSRect) -> CandidateScreenGeometry {
        let screenGeometries = NSScreen.screens.map {
            CandidateScreenGeometry(
                frame: $0.frame,
                visibleFrame: $0.visibleFrame
            )
        }
        let fallbackScreen = (NSScreen.main ?? NSScreen.screens.first).map {
            CandidateScreenGeometry(
                frame: $0.frame,
                visibleFrame: $0.visibleFrame
            )
        }
        return CandidatePlacementEngine.screen(
            for: anchorRect,
            screens: screenGeometries,
            fallback: fallbackScreen
        )
    }

    internal func setSelection(_ requestedIndex: Int) {
        finishFrameTransition()
        let newIndex: Int
        if requestedIndex < 0 || candidates.isEmpty {
            newIndex = -1
        } else {
            newIndex = min(requestedIndex, candidates.count - 1)
        }

        guard newIndex != selectionIndex else {
            renderer[newIndex]?.needsDisplay = true
            return
        }

        let previousIndex = selectionIndex
        selectionIndex = newIndex
        if panelKind == .vertical, newIndex >= 0, previousIndex >= 0,
            newIndex != 0, abs(newIndex - previousIndex) > 1,
            candidates.count > configuration.pageSize
        {
            let pageStart = newIndex / configuration.pageSize * configuration.pageSize
            let movingForward = newIndex > previousIndex
            let row =
                movingForward
                ? min(pageStart + configuration.pageSize, candidates.count) - 1 : pageStart
            if let frame = currentLayout.item(for: row)?.frame,
                !scrollView.contentView.bounds.contains(frame)
            {
                let anchor = movingForward ? max(0, row + 1 - configuration.pageSize) : row
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
        onConfirmation?(candidate.displayString, index, candidate)
        delegate?.candidateController(self, didSelectCandidateAtIndex: UInt(index))
    }

    internal func relativeCandidateIndex(at relativeIndex: Int) -> Int? {
        guard visible, relativeIndex >= 0, relativeIndex < configuration.pageSize else {
            return nil
        }

        let indexes: [Int]
        switch panelKind {
        case .horizontalPaged:
            indexes = currentLayout.rows.first?.candidateIndexes ?? []
        case .horizontalExpandable, .verticalExpandable:
            if isExpanded {
                indexes =
                    currentLayout.row(containing: selectionIndex)?.candidateIndexes
                    ?? currentLayout.rows.first?.candidateIndexes
                    ?? []
            } else {
                indexes = currentLayout.rows.first?.candidateIndexes ?? []
            }
        case .vertical:
            let start = verticalNumberingAnchor
            indexes = Array(start..<min(start + configuration.pageSize, candidates.count))
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
        return keyLabels.prefix(configuration.pageSize).firstIndex { keyLabel in
            keyLabel.key.count == 1 && keyLabel.key.first == label
        }
    }

    internal func expandExpandable(selecting index: Int) {
        let previousIndex = selectionIndex
        let targetIndex = min(max(index, 0), candidates.count - 1)
        if visible, frameTransitionDriver == nil {
            performExpandableTransition(expanding: true, targetSelection: targetIndex)
        } else {
            isExpanded = true
            selectionIndex = targetIndex
            rebuildLayout()
        }
        emitSelectionChange(from: previousIndex)
    }

    internal func collapseExpandable() {
        let collapsed = collapsedNavigationRow
        let previousIndex = selectionIndex
        let targetIndex: Int
        if let finalIndex = collapsed.candidateIndexes.last, selectionIndex > finalIndex {
            targetIndex = finalIndex
        } else {
            targetIndex = selectionIndex
        }
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
        if visible, frameTransitionDriver == nil {
            performExpandableTransition(expanding: false, targetSelection: targetIndex)
        } else {
            isExpanded = false
            selectionIndex = targetIndex
            rebuildLayout()
        }
        emitSelectionChange(from: previousIndex)
    }

    internal var collapsedNavigationRow: CandidateLayoutRow {
        if configuration.orientation == .vertical {
            return VerticalCandidateLayoutEngine.expandableLayout(
                candidates: candidates, keyLabels: keyLabels, configuration: configuration,
                metrics: metrics, selectedIndex: selectionIndex, expanded: false,
                scrollerStyle: scrollView.scrollerStyle
            ).rows.first ?? CandidateLayoutRow(items: [])
        }
        return HorizontalCandidateLayoutEngine.collapsedRow(
            candidates: candidates, configuration: configuration, metrics: metrics
        )
    }

    internal func emitSelectionChange(from previousIndex: Int) {
        notifyAccessibilitySelection()
        guard selectionIndex != previousIndex, candidates.indices.contains(selectionIndex) else {
            return
        }
        let candidate = candidates[selectionIndex]
        onSelectionChange?(candidate.displayString, selectionIndex, candidate)
        delegate?.candidateController?(
            self,
            didHighlightCandidateAtIndex: UInt(selectionIndex)
        )
    }

    internal func performExpandableTransition(expanding: Bool, targetSelection: Int) {
        guard let window, !currentLayout.items.isEmpty else {
            isExpanded = expanding
            selectionIndex = targetSelection
            rebuildLayout()
            return
        }

        let oldLayout = currentLayout
        let oldSelection = selectionIndex
        let startWindowFrame = window.frame
        isExpanded = expanding
        selectionIndex = targetSelection
        let targetLayout = makeCurrentLayout()
        currentLayout = targetLayout
        render(
            layout: targetLayout,
            preservedScrollOrigin: .zero,
            updatesWindowFrame: false,
            ensuresSelectionVisible: false
        )

        let targetWindowFrame = reanchoredWindowFrame(for: targetLayout.windowSize)
        let tracks = CandidateAnimationPlanner.tracks(
            compact: expanding ? oldLayout : targetLayout,
            expanded: expanding ? targetLayout : oldLayout,
            orientation: configuration.orientation,
            expanding: expanding)
        renderer.bind(
            tracks: tracks, canvas: canvasView,
            makeItem: { item in
                let view = makeItemView(for: item, interactive: false)
                view.selected = item.candidateIndex == oldSelection
                return view
            }, makeControl: { makeControlView(for: $0, interactive: false) })
        canvasView.rowWashAlpha = expanding ? 0 : 1
        if !expanding {
            canvasView.rowWashRect = oldLayout.rowWashRect
            canvasView.separatorRects = oldLayout.separatorRects
            canvasView.setFrameSize(oldLayout.documentSize)
        }

        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.verticalScrollElasticity = .none
        scrollView.horizontalScrollElasticity = .none
        let startCorner = oldLayout.cornerRadius
        let targetCorner = targetLayout.cornerRadius

        startFrameTransition(
            update: { [weak self] progress in
                guard let self else { return }
                let frame = CandidateWindowFrameInterpolator.interpolated(
                    from: startWindowFrame,
                    to: targetWindowFrame,
                    progress: progress
                )
                applyWindowFramePreservingTopLeft(frame)
                let acceptedWindowSize = window.frame.size
                backdropView.frame = NSRect(origin: .zero, size: acceptedWindowSize)
                layoutContent(size: acceptedWindowSize)
                renderer.applyMotions(progress: progress)
                canvasView.rowWashAlpha = expanding ? progress : 1 - progress
                backdropView.cornerRadius = startCorner + (targetCorner - startCorner) * progress
                backdropView.layoutSubtreeIfNeeded()
                window.displayIfNeeded()
            },
            completion: { [weak self] in
                guard let self else { return }
                renderer.finishMotions()
                applyWindowFramePreservingTopLeft(targetWindowFrame)
                let acceptedWindowSize = window.frame.size
                backdropView.frame = NSRect(origin: .zero, size: acceptedWindowSize)
                canvasView.setFrameSize(targetLayout.documentSize)
                canvasView.rowWashRect = targetLayout.rowWashRect
                canvasView.rowWashAlpha = 1
                canvasView.separatorRects = targetLayout.separatorRects
                layoutContent(size: acceptedWindowSize)
                configureScrollers(for: targetLayout)
                backdropView.cornerRadius = targetCorner
                scrollView.contentView.scroll(to: clampedScrollOrigin(.zero))
                scrollView.reflectScrolledClipView(scrollView.contentView)
                if targetLayout.hasVerticalScroller || targetLayout.hasHorizontalScroller,
                    scrollView.scrollerStyle != .legacy
                {
                    scrollView.flashScrollers()
                }
                ensureSelectionVisible()
                backdropView.layoutSubtreeIfNeeded()
                window.displayIfNeeded()
            }
        )
    }

    internal var expandedRows: [CandidateLayoutRow] {
        if configuration.orientation == .vertical {
            return VerticalCandidateLayoutEngine.expandableLayout(
                candidates: candidates, keyLabels: keyLabels, configuration: configuration,
                metrics: metrics, selectedIndex: selectionIndex, expanded: true,
                scrollerStyle: scrollView.scrollerStyle
            ).rows
        }
        return HorizontalCandidateLayoutEngine.expandedRows(
            candidates: candidates,
            configuration: configuration,
            metrics: metrics
        )
    }

    internal var visibleExpandedRowCount: Int {
        max(
            configuration.orientation == .horizontal
                ? configuration.horizontalMaximumVisibleRows
                : configuration.verticalMaximumVisibleColumns, 1)
    }

    internal func scrollExpanded(toTopRow requestedTopRow: Int) {
        let maximumTopRow = max(currentLayout.rows.count - visibleExpandedRowCount, 0)
        let topRow = min(max(requestedTopRow, 0), maximumTopRow)
        guard let frame = currentLayout.rows[topRow].items.first?.frame else { return }
        let axis = configuration.orientation
        scrollView.contentView.scroll(
            to: clampedScrollOrigin(axis.scrollPoint(axis.scrollInterval(frame).lowerBound))
        )
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    internal func scrollVertical(toAnchor requestedAnchor: Int) {
        finishFrameTransition()
        let anchor = min(max(requestedAnchor, 0), max(candidates.count - 1, 0))
        let desiredY = CGFloat(anchor) * (metrics.itemHeight + 1)
        let maximumY = max(
            0,
            naturalVerticalDocumentHeight - currentLayout.viewportSize.height
        )
        let targetY = min(desiredY, maximumY)
        let targetViewport = NSRect(
            x: 0,
            y: targetY,
            width: currentLayout.viewportSize.width,
            height: currentLayout.viewportSize.height
        )
        let resolvedAnchor = numberingAnchor(for: targetViewport)
        verticalNumberingAnchor = resolvedAnchor
        verticalMinimumDocumentHeight = naturalVerticalDocumentHeight
        isPerformingVerticalPageScroll = true
        rebuildLayout()
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        isPerformingVerticalPageScroll = false
        verticalNumberingAnchor = resolvedAnchor
        updateVerticalIndexLabels()
    }

    internal var naturalVerticalDocumentHeight: CGFloat {
        guard !candidates.isEmpty else {
            return 0
        }
        return CGFloat(candidates.count) * metrics.itemHeight
            + CGFloat(max(candidates.count - 1, 0))
    }

    internal func ensureSelectionVisible() {
        guard selectionIndex >= 0,
            let frame = currentLayout.item(for: selectionIndex)?.frame,
            currentLayout.hasVerticalScroller || currentLayout.hasHorizontalScroller
        else {
            return
        }
        let visible = scrollView.contentView.bounds
        let axis: CandidateOrientation =
            currentLayout.hasHorizontalScroller ? .vertical : .horizontal
        let viewport = axis.scrollInterval(visible)
        let item = axis.scrollInterval(frame)
        var target = viewport.lowerBound
        let trailingPeek =
            selectionIndex + 1 < candidates.count
            ? (item.upperBound - item.lowerBound)
                * CandidateStyle.Layout.selectedTrailingFraction : 0
        if item.lowerBound < viewport.lowerBound {
            target = item.lowerBound
        } else if item.upperBound + trailingPeek > viewport.upperBound {
            target = item.upperBound + trailingPeek - (viewport.upperBound - viewport.lowerBound)
        } else {
            return
        }
        scrollView.contentView.scroll(to: clampedScrollOrigin(axis.scrollPoint(target)))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    internal func clampedScrollOrigin(_ origin: NSPoint) -> NSPoint {
        let maximumY = max(0, currentLayout.documentSize.height - currentLayout.viewportSize.height)
        let maximumX = max(0, currentLayout.documentSize.width - currentLayout.viewportSize.width)
        return NSPoint(x: min(max(origin.x, 0), maximumX), y: min(max(origin.y, 0), maximumY))
    }

    internal func scrollBoundsDidChange() {
        if panelKind == .verticalExpandable, !isFrameTransitionActive {
            let viewport = scrollView.contentView.bounds
            let indexes = currentLayout.items.filter { $0.frame.intersects(viewport) }.map(
                \.candidateIndex)
            textMeasurements.prime(candidates, indexes: indexes, metrics: metrics)
            if visible { textMeasurements.resume(batchSize: configuration.pageSize) }
            return
        }
        guard panelKind == .vertical, !isPerformingVerticalPageScroll else {
            return
        }
        let viewport = scrollView.contentView.bounds
        let offset = max(0, viewport.minY)
        let anchor = numberingAnchor(for: viewport)
        if anchor != verticalNumberingAnchor {
            verticalNumberingAnchor = anchor
            prepareMeasurements()
            updateVerticalIndexLabels()
        }

        let ordinaryDocumentHeight = max(
            naturalVerticalDocumentHeight,
            offset + currentLayout.viewportSize.height
        )
        if verticalMinimumDocumentHeight > ordinaryDocumentHeight {
            verticalMinimumDocumentHeight = ordinaryDocumentHeight
            currentLayout.documentSize.height = ordinaryDocumentHeight
            canvasView.setFrameSize(currentLayout.documentSize)
        }
    }

    internal func updateVerticalIndexLabels() {
        for view in renderer.itemViews {
            let relative = view.candidateIndex - verticalNumberingAnchor
            let isNumbered = relative >= 0 && relative < configuration.pageSize
            view.indexText =
                isNumbered && keyLabels.indices.contains(relative)
                ? keyLabels[relative].displayedText
                : ""
            view.showsIndexText = isNumbered
        }
    }

    internal func numberingAnchor(for viewport: NSRect) -> Int {
        let offset = max(0, viewport.minY)
        if let item = currentLayout.items.first(where: {
            offset < $0.frame.midY + CandidateStyle.Decoration.separator
        }) {
            return item.candidateIndex
        }
        // Continue the same row thresholds through elastic overscroll and reserved blank rows.
        let pitch = metrics.itemHeight + CandidateStyle.Decoration.separator
        return Int(floor((offset + metrics.itemHeight / 2) / pitch))
    }

    internal func screenFrame(containing point: NSPoint) -> NSRect {
        NSScreen.screens.first(where: { $0.frame.contains(point) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? .zero
    }
}
