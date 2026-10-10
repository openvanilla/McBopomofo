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

internal enum CandidatePanelKind {
    case horizontalExpandable
    case horizontalPaged
    case verticalExpandable
    case vertical

    static func resolve(configuration: CandidateConfiguration) -> CandidatePanelKind {
        switch configuration.orientation {
        case .horizontal:
            configuration.allowsExpansion ? .horizontalExpandable : .horizontalPaged
        case .vertical:
            configuration.allowsExpansion ? .verticalExpandable : .vertical
        }
    }
}

internal struct CandidateControlLayout {
    var frame: NSRect
}

internal struct CandidateLayoutItem: Equatable {
    var candidateIndex: Int
    var frame: NSRect
    var indexText: String
    var showsIndexText: Bool
    var showsDetail: Bool
    var alignedCandidateWidth: CGFloat?
}

internal struct CandidateLayoutRow {
    var items: [CandidateLayoutItem]

    var candidateIndexes: [Int] {
        items.map(\.candidateIndex)
    }

    func item(for candidateIndex: Int) -> CandidateLayoutItem? {
        items.first { $0.candidateIndex == candidateIndex }
    }

    func candidatePreservingInterval(
        _ source: ClosedRange<CGFloat>?,
        movingBackward: Bool,
        orientation: CandidateOrientation = .horizontal
    ) -> Int? {
        guard let source else { return items.first?.candidateIndex }
        var leadingMatch: Int?
        for item in items {
            let interval = orientation.itemInterval(item.frame)
            guard interval.lowerBound < source.upperBound,
                source.lowerBound < interval.upperBound
            else { continue }
            if leadingMatch != nil { return item.candidateIndex }
            if !movingBackward || interval.lowerBound >= source.lowerBound {
                return item.candidateIndex
            }
            leadingMatch = item.candidateIndex
        }
        return leadingMatch ?? items.last?.candidateIndex
    }
}

internal struct CandidatePanelLayout {
    var windowSize: NSSize
    var documentSize: NSSize
    var items: [CandidateLayoutItem]
    var rows: [CandidateLayoutRow]
    var separatorRects: [NSRect]
    var rowWashRect: NSRect?
    var control: CandidateControlLayout?
    var hasVerticalScroller: Bool
    var cornerRadius: CGFloat
    var hasHorizontalScroller = false
    var headerHeight: CGFloat = 0

    var viewportSize: NSSize {
        NSSize(width: windowSize.width, height: windowSize.height - headerHeight)
    }

    mutating func reserveHeader(height: CGFloat, minimumWidth: CGFloat) {
        headerHeight = height
        windowSize.height += height
        guard height > 0, !hasHorizontalScroller else { return }
        let extraWidth = max(0, minimumWidth - windowSize.width)
        guard extraWidth > 0 else { return }
        let trailingEdge = control?.frame.minX ?? documentSize.width
        func widened(_ item: CandidateLayoutItem) -> CandidateLayoutItem {
            var item = item
            if abs(item.frame.maxX - trailingEdge) < 0.5 { item.frame.size.width += extraWidth }
            return item
        }
        items = items.map(widened)
        rows = rows.map { CandidateLayoutRow(items: $0.items.map(widened)) }
        separatorRects = separatorRects.map {
            NSRect(x: $0.minX, y: $0.minY, width: $0.width + extraWidth, height: $0.height)
        }
        if rowWashRect?.maxX == documentSize.width { rowWashRect?.size.width += extraWidth }
        control?.frame.origin.x += extraWidth
        documentSize.width += extraWidth
        windowSize.width += extraWidth
    }

    static func horizontalSeparators(rowCount: Int, itemHeight: CGFloat, width: CGFloat) -> [NSRect]
    {
        (0..<max(rowCount - 1, 0)).map { row in
            NSRect(
                x: 0, y: CGFloat(row) * (itemHeight + 1) + itemHeight,
                width: width, height: CandidateStyle.Decoration.separatorThickness)
        }
    }

    static let empty = CandidatePanelLayout(
        windowSize: .zero,
        documentSize: .zero,
        items: [],
        rows: [],
        separatorRects: [],
        rowWashRect: nil,
        control: nil,
        hasVerticalScroller: false,
        cornerRadius: CandidateStyle.Decoration.defaultCornerRadius
    )

    func item(for candidateIndex: Int) -> CandidateLayoutItem? {
        items.first { $0.candidateIndex == candidateIndex }
    }

    func row(containing candidateIndex: Int) -> CandidateLayoutRow? {
        rows.first { $0.candidateIndexes.contains(candidateIndex) }
    }

}

@MainActor
internal struct CandidateMetrics {
    let measurementStore: CandidateTextMeasurements?
    let availableWidth: CGFloat
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
    let cornerRadius: CGFloat
    let dragActivationDistance: CGFloat
    let auxiliaryScale: CGFloat

    init(
        requestedCandidateFont: NSFont,
        requestedIndexFont: NSFont,
        keyLabelDetails: [String]? = nil,
        rawCandidateFontSize: CGFloat? = nil,
        availableWidth: CGFloat = .greatestFiniteMagnitude,
        measurementStore: CandidateTextMeasurements? = nil
    ) {
        self.measurementStore = measurementStore
        self.availableWidth = availableWidth
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
        cornerRadius = CandidateStyle.Decoration.defaultCornerRadius
        dragActivationDistance = CandidateStyle.Interaction.dragActivationDistance
        auxiliaryScale =
            (rawCandidateFontSize ?? requestedCandidateFont.pointSize)
            / CandidateStyle.Typography.referenceSize
        // Reserve the widest hint before wrapping so shortcut reassignment cannot change row membership.
        let hintFont = detailFont
        keyLabelDetailWidth = keyLabelDetails.map { labels in
            labels.map {
                ceil(
                    measurementStore?.width(of: $0, font: hintFont)
                        ?? Self.textWidth($0, font: hintFont))
            }.max() ?? 0
        }

    }

    var baseCellWidth: CGFloat {
        baseCellWidth(showsIndexColumn: true)
    }

    func baseCellWidth(showsIndexColumn: Bool) -> CGFloat {
        let showsIndexColumn = showsIndexColumn && keyLabelDetailWidth == nil
        let candidateFloor = candidateFont.pointSize
        let indexWidth = showsIndexColumn ? indexSlotWidth : 0
        let leadingInset = showsIndexColumn ? leadingPadding : trailingPadding
        let indexGap = showsIndexColumn ? indexCandidateGap : 0
        return ceil(
            leadingInset + indexWidth + indexGap + candidateFloor + trailingPadding
        )
    }

    func intrinsicWidth(for candidate: Candidate, showsIndexColumn: Bool) -> CGFloat {
        let showsIndexColumn = showsIndexColumn && keyLabelDetailWidth == nil
        let candidateWidth = max(
            ceil(width(of: candidate.displayString, font: candidateFont)),
            candidateFont.pointSize
        )
        let detailWidth =
            keyLabelDetailWidth ?? candidate.detail.map { ceil(width(of: $0, font: detailFont)) }
            ?? 0
        let indexWidth = showsIndexColumn ? indexSlotWidth : 0
        let leadingInset = showsIndexColumn ? leadingPadding : trailingPadding
        let indexGap = showsIndexColumn ? indexCandidateGap : 0
        let detailGap = detailWidth > 0 ? candidateDetailGap : 0
        return ceil(
            leadingInset + indexWidth + indexGap + candidateWidth + detailGap + detailWidth
                + trailingPadding
        )
    }

    func width(of string: String, font: NSFont) -> CGFloat {
        measurementStore?.width(of: string, font: font) ?? Self.textWidth(string, font: font)
    }

    static func textWidth(_ string: String, font: NSFont) -> CGFloat {
        (string as NSString).size(withAttributes: [.font: font]).width
    }

    func scaledAuxiliary(_ value: CGFloat) -> CGFloat {
        (value * auxiliaryScale).rounded()
    }
}

@MainActor
internal enum HorizontalCandidateLayoutEngine {
    static func packedPages(
        candidates: [Candidate],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics
    ) -> [CandidateLayoutRow] {
        guard !candidates.isEmpty else {
            return []
        }
        let budget = horizontalBudget(configuration: configuration, metrics: metrics)
        let pageWidth =
            configuration.allowsExpansion ? budget : max(1, floor(metrics.availableWidth))
        let showsIndex = !configuration.indexLabels.isEmpty
        let baseCellWidth = metrics.baseCellWidth(showsIndexColumn: showsIndex)
        var rows: [CandidateLayoutRow] = []
        var rowItems: [CandidateLayoutItem] = []
        var x: CGFloat = 0

        for (index, candidate) in candidates.enumerated() {
            let width = min(
                max(
                    metrics.intrinsicWidth(for: candidate, showsIndexColumn: showsIndex),
                    baseCellWidth),
                budget
            )
            let exceedsCount = rowItems.count >= configuration.pageSize
            let exceedsWidth = !rowItems.isEmpty && x + width > pageWidth
            if exceedsCount || exceedsWidth {
                rows.append(CandidateLayoutRow(items: rowItems))
                rowItems = []
                x = 0
            }
            rowItems.append(
                CandidateLayoutItem(
                    candidateIndex: index,
                    frame: NSRect(x: x, y: 0, width: width, height: metrics.itemHeight),
                    indexText: "",
                    showsIndexText: showsIndex,
                    showsDetail: configuration.showsKeyLabelsAsDetails || candidate.detail != nil,
                    alignedCandidateWidth: nil
                )
            )
            x += width
        }
        if !rowItems.isEmpty {
            rows.append(CandidateLayoutRow(items: rowItems))
        }
        return rows
    }

    static func collapsedRow(
        candidates: [Candidate],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics
    ) -> CandidateLayoutRow {
        packedPages(candidates: candidates, configuration: configuration, metrics: metrics).first
            ?? CandidateLayoutRow(items: [])
    }

    static func expandedRows(
        candidates: [Candidate],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics
    ) -> [CandidateLayoutRow] {
        guard !candidates.isEmpty else {
            return []
        }
        let budget = horizontalBudget(configuration: configuration, metrics: metrics)
        let targetCellWidth =
            metrics.candidateFont.pointSize
            * (configuration.usesWideExpandedCells
                ? CandidateStyle.Layout.wideCellEm : CandidateStyle.Layout.regularCellEm)
        let columnCount = min(
            configuration.pageSize, max(1, Int((budget / targetCellWidth).rounded())))
        let columnWidth = budget / CGFloat(columnCount)
        let showsIndex = !configuration.indexLabels.isEmpty
        let spans = candidates.map {
            min(
                columnCount,
                max(
                    1,
                    Int(
                        ceil(
                            metrics.intrinsicWidth(for: $0, showsIndexColumn: showsIndex)
                                / columnWidth))))
        }
        let breaks = CandidateLineBreaker.partition(
            spans: spans, capacity: columnCount, itemLimit: configuration.pageSize)
        let rows = breaks.map { range in
            var occupied = 0
            return CandidateLayoutRow(
                items: range.map { index in
                    defer { occupied += spans[index] }
                    return CandidateLayoutItem(
                        candidateIndex: index,
                        frame: NSRect(
                            x: CGFloat(occupied) * columnWidth, y: 0,
                            width: CGFloat(spans[index]) * columnWidth, height: metrics.itemHeight),
                        indexText: "", showsIndexText: showsIndex,
                        showsDetail: configuration.showsKeyLabelsAsDetails
                            || candidates[index].detail != nil, alignedCandidateWidth: nil)
                })
        }
        return rows
    }

    static func pagedLayout(
        pages: [CandidateLayoutRow],
        pageIndex: Int,
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics
    ) -> CandidatePanelLayout {
        guard pages.indices.contains(pageIndex) else {
            return .empty
        }
        let showsIndex = !configuration.indexLabels.isEmpty
        var row = pages[pageIndex]
        for index in row.items.indices {
            row.items[index].indexText =
                keyLabels.indices.contains(index)
                ? keyLabels[index].displayedText
                : ""
            row.items[index].showsIndexText = showsIndex
        }
        let naturalWidth = row.items.last?.frame.maxX ?? 0
        let isFinalPage = pageIndex == pages.index(before: pages.endIndex)
        let candidateWidth =
            configuration.allowsExpansion && pages.count > 1
            ? max(naturalWidth, horizontalBudget(configuration: configuration, metrics: metrics))
            : naturalWidth
        if configuration.allowsExpansion, pageIndex == pages.startIndex, !isFinalPage,
            !row.items.isEmpty
        {
            let distributedWidth =
                max(0, candidateWidth - naturalWidth)
                / CGFloat(row.items.count)
            var x: CGFloat = 0
            for index in row.items.indices {
                row.items[index].frame.origin.x = x
                row.items[index].frame.size.width += distributedWidth
                x = row.items[index].frame.maxX
            }
            if let lastIndex = row.items.indices.last {
                row.items[lastIndex].frame.size.width +=
                    candidateWidth
                    - row.items[lastIndex].frame.maxX
            }
        }
        let windowSize = NSSize(
            width: candidateWidth,
            height: metrics.itemHeight
        )
        return CandidatePanelLayout(
            windowSize: windowSize,
            documentSize: windowSize,
            items: row.items,
            rows: [row],
            separatorRects: [],
            rowWashRect: nil,
            control: nil,
            hasVerticalScroller: false,
            cornerRadius: CandidateStyle.Decoration.horizontalCornerRadius
        )
    }

    static func expandableLayout(
        candidates: [Candidate],
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        selectedIndex: Int,
        expanded: Bool,
        scrollerStyle: NSScroller.Style
    ) -> CandidatePanelLayout {
        guard !candidates.isEmpty else {
            return .empty
        }
        if !expanded {
            let packed = packedPages(
                candidates: candidates,
                configuration: configuration,
                metrics: metrics
            )
            var row = packed[0]
            let showsIndex = !configuration.indexLabels.isEmpty
            for index in row.items.indices {
                row.items[index].indexText =
                    keyLabels.indices.contains(index)
                    ? keyLabels[index].displayedText
                    : ""
                row.items[index].showsIndexText = showsIndex
            }
            let naturalWidth = row.items.last?.frame.maxX ?? 0
            let hasOverflow = packed.count > 1
            let controlWidth = expandControlWidth(metrics: metrics)
            let windowSize = NSSize(
                width: naturalWidth + (hasOverflow ? controlWidth : 0),
                height: metrics.itemHeight
            )
            let control =
                hasOverflow
                ? CandidateControlLayout(
                    frame: NSRect(
                        x: naturalWidth,
                        y: 0,
                        width: controlWidth,
                        height: metrics.itemHeight
                    )
                )
                : nil
            return CandidatePanelLayout(
                windowSize: windowSize,
                documentSize: windowSize,
                items: row.items,
                rows: [row],
                separatorRects: [],
                rowWashRect: nil,
                control: control,
                hasVerticalScroller: false,
                cornerRadius: CandidateStyle.Decoration.horizontalCornerRadius
            )
        }

        var rows = expandedRows(
            candidates: candidates,
            configuration: configuration,
            metrics: metrics
        )
        let selectedRow = rows.firstIndex { $0.candidateIndexes.contains(selectedIndex) }
        let showsIndex = !configuration.indexLabels.isEmpty
        for rowIndex in rows.indices {
            for itemIndex in rows[rowIndex].items.indices {
                let relativeIndex = itemIndex
                rows[rowIndex].items[itemIndex].frame.origin.y =
                    CGFloat(rowIndex)
                    * (metrics.itemHeight + 1)
                rows[rowIndex].items[itemIndex].indexText =
                    keyLabels.indices.contains(relativeIndex)
                    ? keyLabels[relativeIndex].displayedText
                    : ""
                rows[rowIndex].items[itemIndex].showsIndexText =
                    showsIndex
                    && rowIndex == selectedRow
            }
        }

        let width = horizontalBudget(configuration: configuration, metrics: metrics)
        let naturalHeight =
            CGFloat(rows.count) * metrics.itemHeight
            + CGFloat(max(rows.count - 1, 0))
        let maximumHeight =
            (CGFloat(configuration.horizontalMaximumVisibleRows)
                + CandidateStyle.Layout.partialNextBandFraction)
            * metrics.itemHeight
            + CGFloat(configuration.horizontalMaximumVisibleRows - 1)
        let hasScroller = naturalHeight > maximumHeight
        let scrollerWidth =
            hasScroller && scrollerStyle == .legacy
            ? NSScroller.scrollerWidth(
                for: .regular,
                scrollerStyle: scrollerStyle
            )
            : 0
        let windowHeight = hasScroller ? maximumHeight : naturalHeight
        let documentHeight = naturalHeight
        let separators = CandidatePanelLayout.horizontalSeparators(
            rowCount: rows.count, itemHeight: metrics.itemHeight, width: width
        )
        let rowWash = selectedRow.map { rowIndex in
            NSRect(
                x: 0,
                y: CGFloat(rowIndex) * (metrics.itemHeight + 1),
                width: width,
                height: metrics.itemHeight
            )
        }
        let items = rows.flatMap(\.items)
        return CandidatePanelLayout(
            windowSize: NSSize(width: width + scrollerWidth, height: windowHeight),
            documentSize: NSSize(width: width, height: documentHeight),
            items: items,
            rows: rows,
            separatorRects: separators,
            rowWashRect: rowWash,
            control: nil,
            hasVerticalScroller: hasScroller,
            cornerRadius: CandidateStyle.Decoration.horizontalCornerRadius
        )
    }

    static func horizontalBudget(
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics
    ) -> CGFloat {
        max(
            1,
            min(
                CandidateStyle.Layout.horizontalWidthEm * metrics.candidateFont.pointSize,
                metrics.availableWidth - horizontalWidthReserve(metrics: metrics)))
    }

    static func horizontalWidthReserve(metrics: CandidateMetrics) -> CGFloat {
        // Keep the established packing allowance, including independent rounding at small sizes.
        let packingReserve =
            CandidateStyle.Decoration.separator
            + metrics.scaledAuxiliary(CandidateStyle.Layout.packingLeadingReserve)
            + metrics.scaledAuxiliary(CandidateStyle.Controls.imageBox)
            + metrics.scaledAuxiliary(CandidateStyle.Layout.packingTrailingReserve)
        return max(packingReserve, expandControlWidth(metrics: metrics))
    }

    static func expandControlWidth(metrics: CandidateMetrics) -> CGFloat {
        CandidateStyle.Decoration.separator
            + metrics.scaledAuxiliary(CandidateStyle.Controls.expandLeading)
            + metrics.scaledAuxiliary(CandidateStyle.Controls.imageBox)
            + metrics.scaledAuxiliary(CandidateStyle.Controls.expandTrailing)
    }
}

@MainActor
internal enum VerticalCandidateLayoutEngine {
    static func expandableLayout(
        candidates: [Candidate],
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        selectedIndex: Int,
        expanded: Bool,
        scrollerStyle: NSScroller.Style,
        maximumWidth: CGFloat = .greatestFiniteMagnitude
    ) -> CandidatePanelLayout {
        guard !candidates.isEmpty else { return .empty }
        let count = expanded ? candidates.count : min(candidates.count, configuration.pageSize)
        var columns: [CandidateLayoutRow] = []
        var x: CGFloat = 0
        var height: CGFloat = 0
        for start in stride(from: 0, to: count, by: configuration.pageSize) {
            let members = Array(candidates[start..<min(start + configuration.pageSize, count)])
            let known = metrics.measurementStore.map { store in
                Set(members.indices.filter { store.contains(members[$0], metrics: metrics) })
            }
            let column = layout(
                candidates: members,
                keyLabels: keyLabels,
                configuration: configuration,
                metrics: metrics,
                numberingAnchor: 0,
                scrollerStyle: scrollerStyle,
                measuredIndexes: known
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
            columns.append(CandidateLayoutRow(items: items))
            x += column.windowSize.width + 1
        }
        let documentWidth = x - 1
        let separators = CandidatePanelLayout.horizontalSeparators(
            rowCount: columns.map { $0.items.count }.max() ?? 0,
            itemHeight: metrics.itemHeight,
            width: documentWidth
        )
        let visibleColumns = max(configuration.verticalMaximumVisibleColumns, 1)
        let columnLimit: CGFloat
        if columns.count > visibleColumns {
            let peekColumn = columns[visibleColumns].items[0].frame
            columnLimit =
                peekColumn.minX
                + peekColumn.width * CandidateStyle.Layout.partialNextBandFraction
        } else {
            columnLimit = documentWidth
        }
        let width = min(columnLimit, max(maximumWidth, 1))
        let hasScroller = documentWidth > width
        let scrollerHeight =
            hasScroller && scrollerStyle == .legacy
            ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: scrollerStyle) : 0
        let selectedColumn = columns.first { $0.candidateIndexes.contains(selectedIndex) }
        let wash =
            expanded
            ? selectedColumn?.items.first.map {
                NSRect(x: $0.frame.minX, y: 0, width: $0.frame.width, height: height)
            } : nil
        return CandidatePanelLayout(
            windowSize: NSSize(width: width, height: height + scrollerHeight),
            documentSize: NSSize(width: documentWidth, height: height),
            items: columns.flatMap(\.items),
            rows: columns,
            separatorRects: separators,
            rowWashRect: wash,
            control: nil,
            hasVerticalScroller: false,
            cornerRadius: metrics.cornerRadius,
            hasHorizontalScroller: hasScroller
        )
    }

    static func layout(
        candidates: [Candidate],
        keyLabels: [CandidateKeyLabel],
        configuration: CandidateConfiguration,
        metrics: CandidateMetrics,
        numberingAnchor: Int,
        scrollerStyle: NSScroller.Style,
        minimumDocumentHeight: CGFloat = 0,
        measuredIndexes: Set<Int>? = nil
    ) -> CandidatePanelLayout {
        guard !candidates.isEmpty else {
            return .empty
        }
        let labelsEnabled = !configuration.indexLabels.isEmpty
        let showsIndex = labelsEnabled && !configuration.showsKeyLabelsAsDetails
        let samples = candidates.enumerated().compactMap { index, candidate in
            measuredIndexes == nil || measuredIndexes!.contains(index) ? candidate : nil
        }
        let maximumCandidateWidth = max(
            metrics.candidateFont.pointSize,
            samples.map {
                ceil(metrics.width(of: $0.displayString, font: metrics.candidateFont))
            }.max() ?? 0
        )
        let detailCandidates = samples.compactMap(\.detail)
        let maximumDetailWidth =
            metrics.keyLabelDetailWidth ?? detailCandidates.map {
                ceil(metrics.width(of: $0, font: metrics.detailFont))
            }.max() ?? 0
        let indexWidth = showsIndex ? metrics.indexSlotWidth : 0
        let leadingInset = showsIndex ? metrics.leadingPadding : metrics.trailingPadding
        let indexGap = showsIndex ? metrics.indexCandidateGap : 0
        let baseCellWidth = metrics.baseCellWidth(showsIndexColumn: showsIndex)
        // Extra trailing space balances the larger candidate against the smaller index label.
        let opticalTrailingPadding =
            showsIndex
            ? metrics.candidateFont.pointSize * CandidateStyle.Spacing.opticalTrailingEm : 0
        let naturalTrailing = metrics.trailingPadding + opticalTrailingPadding
        let overflowing = candidates.count > configuration.pageSize
        let nativeGutter =
            overflowing ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: scrollerStyle) : 0
        let reservedGutter =
            scrollerStyle == .legacy
            ? nativeGutter
            : max(0, nativeGutter + CandidateStyle.Spacing.overlayClearance - naturalTrailing)
        let widthCap = max(
            1,
            min(
                CandidateStyle.Layout.verticalWidthEm * metrics.candidateFont.pointSize,
                metrics.availableWidth - reservedGutter))
        let hasAnyDetail =
            metrics.keyLabelDetailWidth.map { $0 > 0 }
            ?? candidates.contains { $0.detail != nil }
        let fixedWidth = leadingInset + indexWidth + indexGap + naturalTrailing
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

        let minimumRows = configuration.verticalMinimumVisibleRows ?? 0
        let visibleRows = max(min(candidates.count, configuration.pageSize), minimumRows)
        let peekHeight =
            overflowing
            ? metrics.itemHeight * CandidateStyle.Layout.partialNextBandFraction : 0
        let windowHeight =
            CGFloat(visibleRows) * metrics.itemHeight
            + CGFloat(max(visibleRows - 1, 0))
            + peekHeight
        let naturalDocumentHeight =
            CGFloat(candidates.count) * metrics.itemHeight
            + CGFloat(max(candidates.count - 1, 0))
        let documentHeight = max(naturalDocumentHeight, minimumDocumentHeight)

        var rows: [CandidateLayoutRow] = []
        for index in candidates.indices {
            let relativeIndex = index - numberingAnchor
            let isNumbered = relativeIndex >= 0 && relativeIndex < configuration.pageSize
            let indexText =
                isNumbered && keyLabels.indices.contains(relativeIndex)
                ? keyLabels[relativeIndex].displayedText
                : ""
            let item = CandidateLayoutItem(
                candidateIndex: index,
                frame: NSRect(
                    x: 0,
                    y: CGFloat(index) * (metrics.itemHeight + 1),
                    width: itemWidth,
                    height: metrics.itemHeight
                ),
                indexText: indexText,
                showsIndexText: labelsEnabled && isNumbered,
                showsDetail: showsDetails
                    && (configuration.showsKeyLabelsAsDetails || candidates[index].detail != nil),
                alignedCandidateWidth: showsDetails ? maximumCandidateWidth : nil
            )
            rows.append(CandidateLayoutRow(items: [item]))
        }
        let separators = CandidatePanelLayout.horizontalSeparators(
            rowCount: candidates.count, itemHeight: metrics.itemHeight, width: itemWidth
        )
        return CandidatePanelLayout(
            windowSize: NSSize(width: windowWidth, height: windowHeight),
            documentSize: NSSize(width: itemWidth, height: documentHeight),
            items: rows.flatMap(\.items),
            rows: rows,
            separatorRects: separators,
            rowWashRect: nil,
            control: nil,
            hasVerticalScroller: overflowing,
            cornerRadius: metrics.cornerRadius
        )
    }

}
