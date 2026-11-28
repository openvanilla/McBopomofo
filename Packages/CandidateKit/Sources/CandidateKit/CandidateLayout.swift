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
import CoreText

internal enum CandidatePanelKind {
    case horizontal
    case vertical
    case verticalExpandable

    static func resolve(configuration: CandidateConfiguration) -> CandidatePanelKind {
        switch configuration.orientation {
        case .horizontal:
            .horizontal
        case .vertical:
            configuration.allowsExpansion ? .verticalExpandable : .vertical
        }
    }
}

internal struct CandidateLayoutItem: Equatable {
    var candidateIndex: Int
    var frame: NSRect
    var indexText: String
    var showsIndexText: Bool
    var showsDetail: Bool
    var alignedCandidateWidth: CGFloat?
}

internal struct CandidateLayoutGroup {
    var items: [CandidateLayoutItem]

    var candidateIndexes: [Int] {
        items.map(\.candidateIndex)
    }
}

internal struct CandidatePanelLayout {
    var windowSize: NSSize
    var documentSize: NSSize
    var items: [CandidateLayoutItem]
    var separatorRects: [NSRect]
    var spotlightRect: NSRect?
    var hasVerticalScroller: Bool
    var cornerRadius: CGFloat
    var hasHorizontalScroller = false
    var headerHeight: CGFloat = 0
    var pageSize: Int?

    var viewportSize: NSSize {
        NSSize(width: windowSize.width, height: windowSize.height - headerHeight)
    }

    mutating func reserveHeader(height: CGFloat, minimumWidth: CGFloat) {
        headerHeight = height
        windowSize.height += height
        guard height > 0, !hasHorizontalScroller else { return }
        let extraWidth = max(0, minimumWidth - windowSize.width)
        guard extraWidth > 0 else { return }
        let trailingEdge = documentSize.width
        func widened(_ item: CandidateLayoutItem) -> CandidateLayoutItem {
            var item = item
            if abs(item.frame.maxX - trailingEdge) < 0.5 { item.frame.size.width += extraWidth }
            return item
        }
        items = items.map(widened)
        separatorRects = separatorRects.map {
            NSRect(x: $0.minX, y: $0.minY, width: $0.width + extraWidth, height: $0.height)
        }
        if spotlightRect?.maxX == documentSize.width { spotlightRect?.size.width += extraWidth }
        documentSize.width += extraWidth
        windowSize.width += extraWidth
    }

    static func horizontalSeparators(rowCount: Int, itemHeight: CGFloat, width: CGFloat) -> [NSRect]
    {
        (0..<max(rowCount - 1, 0)).map { row in
            NSRect(
                x: 0,
                y: CGFloat(row) * (itemHeight + CandidateStyle.Decoration.separator)
                    + itemHeight,
                width: width, height: CandidateStyle.Decoration.separatorThickness)
        }
    }

    static let empty = CandidatePanelLayout(
        windowSize: .zero,
        documentSize: .zero,
        items: [],
        separatorRects: [],
        spotlightRect: nil,
        hasVerticalScroller: false,
        cornerRadius: CandidateStyle.Decoration.defaultCornerRadius
    )

    func item(for candidateIndex: Int) -> CandidateLayoutItem? {
        items.first { $0.candidateIndex == candidateIndex }
    }
}

@MainActor
internal struct CandidateMetrics {
    let measureText: (String, NSFont) -> CGFloat
    let candidateFont: NSFont
    let indexFont: NSFont
    let detailFont: NSFont
    let leadingPadding: CGFloat
    let indexSlotWidth: CGFloat
    let keyLabelDetailWidth: CGFloat?
    let indexCandidateGap: CGFloat
    let candidateDetailGap: CGFloat
    let trailingPadding: CGFloat
    let verticalPadding: CGFloat
    let itemHeight: CGFloat
    let auxiliaryScale: CGFloat

    init(
        requestedCandidateFont: NSFont,
        requestedIndexFont: NSFont,
        keyLabelDetails: [String]? = nil,
        measureText: @escaping (String, NSFont) -> CGFloat = CandidateMetrics.textWidth
    ) {
        self.measureText = measureText
        let effectiveSize = max(
            requestedCandidateFont.pointSize, CandidateStyle.Typography.minimumSize)
        let unit = effectiveSize / 4
        candidateFont = requestedCandidateFont.withSize(effectiveSize)
        indexFont = requestedIndexFont.withSize(
            (effectiveSize * CandidateStyle.Typography.shortcutEm).rounded())
        detailFont = .systemFont(ofSize: (unit * CandidateStyle.Typography.detailUnits).rounded())
        leadingPadding = (unit * CandidateStyle.Spacing.leadingUnits).rounded()
        indexSlotWidth = indexFont.pointSize + CandidateStyle.Spacing.shortcutAllowance
        indexCandidateGap = (unit * CandidateStyle.Spacing.shortcutGapUnits).rounded()
        candidateDetailGap = (unit * CandidateStyle.Spacing.detailGapUnits).rounded()
        trailingPadding = (unit * CandidateStyle.Spacing.trailingUnits).rounded()
        verticalPadding = (unit * CandidateStyle.Spacing.verticalUnits).rounded()
        itemHeight = effectiveSize + verticalPadding
        auxiliaryScale = requestedCandidateFont.pointSize / CandidateStyle.Typography.referenceSize
        // Reserve the widest hint before wrapping so shortcut reassignment cannot change row membership.
        let hintFont = detailFont
        keyLabelDetailWidth = keyLabelDetails.map { labels in
            labels.map { ceil(measureText($0, hintFont)) }.max() ?? 0
        }
    }

    var cornerRadius: CGFloat {
        return (CandidateStyle.Decoration.defaultCornerRadius * sqrt(auxiliaryScale)).rounded()
    }

    // Distance from one row's top edge to the next, including the separator between them.
    var rowPitch: CGFloat {
        itemHeight + CandidateStyle.Decoration.separator
    }

    // Padding around the candidate text, plus the index column when it is shown.
    func fixedWidth(showsIndexColumn: Bool) -> CGFloat {
        showsIndexColumn
            ? leadingPadding + indexSlotWidth + indexCandidateGap + trailingPadding
            : trailingPadding * 2
    }

    func baseCellWidth(showsIndexColumn: Bool) -> CGFloat {
        ceil(fixedWidth(showsIndexColumn: showsIndexColumn) + candidateFont.pointSize)
    }

    func intrinsicWidth(for candidate: Candidate, showsIndexColumn: Bool) -> CGFloat {
        let candidateWidth = max(
            ceil(width(of: candidate.displayString, font: candidateFont)),
            candidateFont.pointSize
        )
        let detailWidth =
            keyLabelDetailWidth ?? candidate.detail.map { ceil(width(of: $0, font: detailFont)) }
            ?? 0
        let detailGap = detailWidth > 0 ? candidateDetailGap : 0
        return ceil(
            fixedWidth(showsIndexColumn: showsIndexColumn) + candidateWidth + detailGap
                + detailWidth)
    }

    func width(of string: String, font: NSFont) -> CGFloat {
        measureText(string, font)
    }

    nonisolated static func textWidth(_ string: String, font: NSFont) -> CGFloat {
        let line = CTLineCreateWithAttributedString(
            NSAttributedString(string: string, attributes: [.font: font]))
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }

    func scaledAuxiliary(_ value: CGFloat) -> CGFloat {
        (value * auxiliaryScale).rounded()
    }
}

@MainActor
internal enum HorizontalCandidateLayoutEngine {
    static func pages(
        candidates: [Candidate],
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        maximumWidth: CGFloat = .greatestFiniteMagnitude
    ) -> [CandidateLayoutGroup] {
        let pageWidth = max(1, floor(maximumWidth))
        let labelsEnabled = !keyLabels.isEmpty
        let showsIndex = configuration.showsIndexColumn(for: keyLabels)
        var pages: [CandidateLayoutGroup] = []
        var pageItems: [CandidateLayoutItem] = []
        var x: CGFloat = 0

        for (index, candidate) in candidates.enumerated() {
            let width = min(
                metrics.intrinsicWidth(for: candidate, showsIndexColumn: showsIndex),
                pageWidth
            )
            let exceedsCount = pageItems.count >= configuration.pageSize
            let exceedsWidth = !pageItems.isEmpty && x + width > pageWidth
            if exceedsCount || exceedsWidth {
                pages.append(CandidateLayoutGroup(items: pageItems))
                pageItems = []
                x = 0
            }
            pageItems.append(
                CandidateLayoutItem(
                    candidateIndex: index,
                    frame: NSRect(x: x, y: 0, width: width, height: metrics.itemHeight),
                    indexText: "",
                    showsIndexText: labelsEnabled,
                    showsDetail: configuration.showsKeyLabelsAsDetails || candidate.detail != nil,
                    alignedCandidateWidth: nil
                )
            )
            x += width
        }
        if !pageItems.isEmpty {
            pages.append(CandidateLayoutGroup(items: pageItems))
        }
        return pages
    }

    static func layout(
        pages: [CandidateLayoutGroup],
        pageIndex: Int,
        keyLabels: [CandidateKeyLabel],
        metrics: CandidateMetrics
    ) -> CandidatePanelLayout {
        guard pages.indices.contains(pageIndex) else {
            return .empty
        }
        var page = pages[pageIndex]
        for index in page.items.indices {
            page.items[index].indexText =
                keyLabels.indices.contains(index) ? keyLabels[index].displayedText : ""
        }
        let windowSize = NSSize(
            width: page.items.last?.frame.maxX ?? 0,
            height: metrics.itemHeight
        )
        return CandidatePanelLayout(
            windowSize: windowSize,
            documentSize: windowSize,
            items: page.items,
            separatorRects: [],
            spotlightRect: nil,
            hasVerticalScroller: false,
            cornerRadius: metrics.cornerRadius
        )
    }
}

@MainActor
internal enum VerticalCandidateLayoutEngine {
    // Shrinks the page so that whole rows fit in the available height.
    private static func configurationFittingHeight(
        _ configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        availableHeight: CGFloat
    ) -> CandidateConfiguration {
        let rowCapacity = floor(
            (max(0, availableHeight) + CandidateStyle.Decoration.separator) / metrics.rowPitch)
        var result = configuration
        result.pageSize = max(1, Int(min(CGFloat(configuration.pageSize), rowCapacity)))
        return result
    }

    static func expandableLayout(
        candidates: [Candidate],
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        selectedIndex: Int,
        expanded: Bool,
        scrollerStyle: NSScroller.Style,
        maximumWidth: CGFloat = .greatestFiniteMagnitude,
        maximumHeight: CGFloat = .greatestFiniteMagnitude
    ) -> CandidatePanelLayout {
        var fitted = configurationFittingHeight(
            configuration, metrics: metrics, availableHeight: maximumHeight)
        func columns(expanded: Bool) -> CandidatePanelLayout {
            columnLayout(
                candidates: candidates, keyLabels: keyLabels, configuration: fitted,
                metrics: metrics, selectedIndex: selectedIndex, expanded: expanded,
                scrollerStyle: scrollerStyle, maximumWidth: maximumWidth)
        }
        // Use the same row count before and after expansion, including space for a legacy scroller.
        if scrollerStyle == .legacy {
            let scrollerHeight = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy)
            let height =
                CGFloat(fitted.pageSize) * metrics.rowPitch - CandidateStyle.Decoration.separator
            if height + scrollerHeight > maximumHeight,
                candidates.count > fitted.pageSize * fitted.verticalMaximumVisibleColumns
                    || columns(expanded: true).hasHorizontalScroller
            {
                fitted = configurationFittingHeight(
                    configuration, metrics: metrics, availableHeight: maximumHeight - scrollerHeight
                )
            }
        }
        return columns(expanded: expanded)
    }

    private static func columnLayout(
        candidates: [Candidate],
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        selectedIndex: Int,
        expanded: Bool,
        scrollerStyle: NSScroller.Style,
        maximumWidth: CGFloat
    ) -> CandidatePanelLayout {
        guard !candidates.isEmpty else { return .empty }
        let count = expanded ? candidates.count : min(candidates.count, configuration.pageSize)
        var columns: [CandidateLayoutGroup] = []
        var x: CGFloat = 0
        var height: CGFloat = 0
        for start in stride(from: 0, to: count, by: configuration.pageSize) {
            let members = Array(candidates[start..<min(start + configuration.pageSize, count)])
            let column = layout(
                candidates: members,
                keyLabels: keyLabels,
                configuration: configuration,
                metrics: metrics,
                numberingAnchor: 0,
                scrollerStyle: scrollerStyle,
                maximumWidth: maximumWidth
            )
            height = max(height, column.windowSize.height)
            let isSelectedColumn =
                selectedIndex >= start && selectedIndex < start + configuration.pageSize
            let items = column.items.map { item in
                var item = item
                item.candidateIndex += start
                item.frame.origin.x = x
                item.showsIndexText = item.showsIndexText && (!expanded || isSelectedColumn)
                return item
            }
            columns.append(CandidateLayoutGroup(items: items))
            x += column.windowSize.width + CandidateStyle.Decoration.separator
        }
        let documentWidth = x - CandidateStyle.Decoration.separator
        let separators = CandidatePanelLayout.horizontalSeparators(
            rowCount: columns.map { $0.items.count }.max() ?? 0,
            itemHeight: metrics.itemHeight,
            width: documentWidth
        )
        let visibleColumns = configuration.verticalMaximumVisibleColumns
        let columnLimit: CGFloat
        if columns.count > visibleColumns {
            columnLimit = columns[visibleColumns - 1].items[0].frame.maxX
        } else {
            columnLimit = documentWidth
        }
        let selectedColumn = columns.first { $0.candidateIndexes.contains(selectedIndex) }
        let selectedWidth = selectedColumn?.items.first?.frame.width ?? 0
        let width = min(max(columnLimit, selectedWidth), max(maximumWidth, 1))
        let hasScroller = documentWidth > width
        let scrollerHeight =
            hasScroller && scrollerStyle == .legacy
            ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: scrollerStyle) : 0
        let spotlight =
            expanded
            ? selectedColumn?.items.first.map {
                NSRect(x: $0.frame.minX, y: 0, width: $0.frame.width, height: height)
            } : nil
        return CandidatePanelLayout(
            windowSize: NSSize(width: width, height: height + scrollerHeight),
            documentSize: NSSize(width: documentWidth, height: height),
            items: columns.flatMap(\.items),
            separatorRects: separators,
            spotlightRect: spotlight,
            hasVerticalScroller: false,
            cornerRadius: metrics.cornerRadius,
            hasHorizontalScroller: hasScroller,
            pageSize: configuration.pageSize
        )
    }

    static func layout(
        candidates: [Candidate],
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        numberingAnchor: Int,
        scrollerStyle: NSScroller.Style,
        maximumWidth: CGFloat = .greatestFiniteMagnitude,
        maximumHeight: CGFloat = .greatestFiniteMagnitude
    ) -> CandidatePanelLayout {
        guard !candidates.isEmpty else {
            return .empty
        }
        let configuration = configurationFittingHeight(
            configuration, metrics: metrics, availableHeight: maximumHeight)
        let labelsEnabled = !keyLabels.isEmpty
        let showsIndex = configuration.showsIndexColumn(for: keyLabels)
        let maximumCandidateWidth = max(
            metrics.candidateFont.pointSize,
            candidates.map {
                ceil(metrics.width(of: $0.displayString, font: metrics.candidateFont))
            }.max() ?? 0
        )
        let detailCandidates = candidates.compactMap(\.detail)
        let maximumDetailWidth =
            metrics.keyLabelDetailWidth ?? detailCandidates.map {
                ceil(metrics.width(of: $0, font: metrics.detailFont))
            }.max() ?? 0
        let baseCellWidth = metrics.baseCellWidth(showsIndexColumn: showsIndex)
        // Extra trailing space balances the larger candidate against the smaller index label.
        // It is rounded like the other spacings: a fractional column is narrower than the
        // whole-point window AppKit gives it, which leaves a wider gap beside the highlight.
        let opticalTrailingPadding =
            showsIndex
            ? (metrics.candidateFont.pointSize * CandidateStyle.Spacing.opticalTrailingEm).rounded()
            : 0
        let naturalTrailing = metrics.trailingPadding + opticalTrailingPadding
        let overflowing = candidates.count > configuration.pageSize
        let nativeGutter =
            overflowing ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: scrollerStyle) : 0
        let reservedGutter =
            scrollerStyle == .legacy
            ? nativeGutter
            : max(0, nativeGutter + CandidateStyle.Spacing.overlayClearance - naturalTrailing)
        let widthCap = max(1, maximumWidth - reservedGutter)
        let hasAnyDetail =
            metrics.keyLabelDetailWidth.map { $0 > 0 } ?? candidates.contains { $0.detail != nil }
        let fixedWidth = metrics.fixedWidth(showsIndexColumn: showsIndex) + opticalTrailingPadding
        let labelBudget = max(0, widthCap - fixedWidth)
        let detailBudget = max(0, labelBudget - maximumCandidateWidth - metrics.candidateDetailGap)
        let showsDetails =
            hasAnyDetail
            && detailBudget >= CandidateStyle.Layout.minimumDetailEm
                * metrics.candidateFont.pointSize
        let displayedDetailWidth = showsDetails ? min(maximumDetailWidth, detailBudget) : 0
        let naturalContentWidth = min(
            widthCap,
            max(
                baseCellWidth,
                fixedWidth + maximumCandidateWidth
                    + (showsDetails ? metrics.candidateDetailGap + displayedDetailWidth : 0)
            )
        )

        let adjustedTrailing = max(
            naturalTrailing, nativeGutter + CandidateStyle.Spacing.overlayClearance)
        let itemWidth: CGFloat
        let windowWidth: CGFloat
        if !overflowing {
            itemWidth = naturalContentWidth
            windowWidth = naturalContentWidth
        } else if scrollerStyle == .legacy {
            itemWidth = naturalContentWidth
            windowWidth = naturalContentWidth + nativeGutter
        } else {
            itemWidth = naturalContentWidth - naturalTrailing + adjustedTrailing
            windowWidth = itemWidth
        }

        let visibleRows = min(candidates.count, configuration.pageSize)
        let windowHeight =
            CGFloat(visibleRows) * metrics.rowPitch - CandidateStyle.Decoration.separator
        let documentHeight =
            CGFloat(candidates.count) * metrics.rowPitch - CandidateStyle.Decoration.separator

        let items = candidates.indices.map { index in
            let relativeIndex = index - numberingAnchor
            let isNumbered = relativeIndex >= 0 && relativeIndex < configuration.pageSize
            let indexText =
                isNumbered && keyLabels.indices.contains(relativeIndex)
                ? keyLabels[relativeIndex].displayedText
                : ""
            return CandidateLayoutItem(
                candidateIndex: index,
                frame: NSRect(
                    x: 0,
                    y: CGFloat(index) * metrics.rowPitch,
                    width: itemWidth,
                    height: metrics.itemHeight
                ),
                indexText: indexText,
                showsIndexText: labelsEnabled && isNumbered,
                showsDetail: showsDetails
                    && (configuration.showsKeyLabelsAsDetails || candidates[index].detail != nil),
                alignedCandidateWidth: showsDetails ? maximumCandidateWidth : nil
            )
        }
        let separators = CandidatePanelLayout.horizontalSeparators(
            rowCount: candidates.count, itemHeight: metrics.itemHeight, width: itemWidth
        )
        return CandidatePanelLayout(
            windowSize: NSSize(width: windowWidth, height: windowHeight),
            documentSize: NSSize(width: itemWidth, height: documentHeight),
            items: items,
            separatorRects: separators,
            spotlightRect: nil,
            hasVerticalScroller: overflowing,
            cornerRadius: metrics.cornerRadius,
            pageSize: configuration.pageSize
        )
    }
}
