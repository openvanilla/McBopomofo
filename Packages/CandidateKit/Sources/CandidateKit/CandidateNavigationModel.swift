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

internal struct CandidatePresentationState {
    var selection = -1
    var page = 0
    var expanded = false
    var shortcutOrigin = 0
    var minimumDocumentHeight: CGFloat = 0
}

internal enum CandidateViewportRequest {
    case verticalAnchor(Int)
}

internal struct CandidateNavigationDecision {
    var selection: Int
    var page: Int?
    var expanded: Bool?
    var viewport: CandidateViewportRequest?
    var ensuresSelectionVisible = false
}

internal struct CandidateNavigationContext {
    var state: CandidatePresentationState
    var kind: CandidatePanelKind
    var orientation: CandidateOrientation
    var count: Int
    var pageSize: Int
    var advanceOnExpansion: Bool
    var bands: [CandidateLayoutRow]
    var expandedBands: [CandidateLayoutRow]

    func projected(in bands: [CandidateLayoutRow], band: Int, movingBackward: Bool) -> Int? {
        guard bands.indices.contains(band) else { return nil }
        let sourceIndex = max(state.selection, 0)
        let source = bands.lazy.compactMap { $0.item(for: sourceIndex) }.first
        return bands[band].candidatePreservingInterval(
            source.map { orientation.itemInterval($0.frame) },
            movingBackward: movingBackward,
            orientation: orientation
        )
    }
}

internal enum CandidateNavigationReducer {
    static func resolve(
        _ input: CandidateNavigation, wrapping: Bool,
        context c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        guard c.count > 0 else { return nil }
        let arrows: Set<CandidateNavigation> = [
            .up, .down, .left, .right, .itemForward, .itemBackward,
        ]
        if c.state.selection < 0, arrows.contains(input),
            !(c.orientation == .vertical && (input == .left || input == .right))
        {
            return CandidateNavigationDecision(selection: 0)
        }
        let result: CandidateNavigationDecision?
        switch c.kind {
        case .vertical: result = vertical(input, wrapping: wrapping, c)
        case .horizontalPaged: result = paged(input, wrapping: wrapping, c)
        case .horizontalExpandable, .verticalExpandable:
            let intent = c.orientation.expandableNavigation(input)
            result = expandable(intent, wrapping: wrapping, c)
        }
        return result ?? (c.state.selection < 0 ? CandidateNavigationDecision(selection: 0) : nil)
    }

    private static func bounded(_ requested: Int, count: Int, wrapping: Bool) -> Int {
        if wrapping { return (requested % count + count) % count }
        return min(max(requested, 0), count - 1)
    }

    private static func paged(
        _ input: CandidateNavigation, wrapping: Bool,
        _ c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        guard c.bands.indices.contains(c.state.page) else { return nil }
        let band = c.bands[c.state.page].candidateIndexes
        guard !band.isEmpty else { return nil }
        if input == .home { return .init(selection: 0) }
        if input == .end { return .init(selection: c.count - 1) }
        let backward: Set<CandidateNavigation> = [
            .left, .itemBackward, .up, .pageUp, .pageBackward,
        ]
        let delta = backward.contains(input) ? -1 : 1
        let sequential = [.left, .right, .itemBackward, .itemForward].contains(input)
        if sequential, let slot = band.firstIndex(of: max(c.state.selection, 0)),
            band.indices.contains(slot + delta)
        {
            return .init(selection: band[slot + delta])
        }
        let page = bounded(c.state.page + delta, count: c.bands.count, wrapping: wrapping)
        guard wrapping || c.bands.indices.contains(c.state.page + delta) else { return nil }
        let targetBand = c.bands[page].candidateIndexes
        let target =
            sequential
            ? (delta > 0 ? targetBand.first : targetBand.last)
            : targetBand.first
        return target.map { .init(selection: $0, page: page) }
    }

    private static func vertical(
        _ input: CandidateNavigation, wrapping: Bool,
        _ c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        let current = max(c.state.selection, 0)
        if input == .home { return .init(selection: 0, viewport: .verticalAnchor(0)) }
        if input == .end { return .init(selection: c.count - 1, ensuresSelectionVisible: true) }
        let backward = [.up, .itemBackward, .left, .pageUp, .pageBackward].contains(input)
        let delta = backward ? -1 : 1
        if [.up, .down, .itemForward, .itemBackward].contains(input) {
            let index = bounded(current + delta, count: c.count, wrapping: wrapping)
            return index == c.state.selection ? nil : .init(selection: index)
        }
        guard c.count > c.pageSize else { return nil }
        let requested = current + delta * c.pageSize
        let index =
            wrapping && !(0..<c.count).contains(requested)
            ? (backward ? c.count - 1 : 0) : bounded(requested, count: c.count, wrapping: false)
        guard index != c.state.selection || wrapping else { return nil }
        return .init(selection: index, viewport: index == 0 ? .verticalAnchor(0) : nil)
    }

    private static func expandable(
        _ input: CandidateNavigation, wrapping: Bool,
        _ c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        let current = max(c.state.selection, 0)
        let bands = c.state.expanded ? c.bands : c.expandedBands
        if c.state.expanded,
            !bands.contains(where: { $0.candidateIndexes.contains(c.state.selection) })
        {
            return .init(selection: 0)
        }
        let currentBand = bands.firstIndex { $0.candidateIndexes.contains(current) } ?? 0
        let compact = c.bands.first?.candidateIndexes ?? []
        let backward = [.left, .itemBackward, .up, .pageBackward, .pageUp].contains(input)
        let delta = backward ? -1 : 1
        if input == .home || input == .end {
            let indexes =
                c.state.expanded && bands.indices.contains(currentBand)
                ? bands[currentBand].candidateIndexes : compact
            return (input == .home ? indexes.first : indexes.last).map { .init(selection: $0) }
        }
        if [.left, .right, .itemBackward, .itemForward].contains(input) {
            if c.state.expanded, current == 0, backward, !wrapping {
                return .init(selection: 0, expanded: false)
            }
            let index = bounded(current + delta, count: c.count, wrapping: wrapping)
            guard wrapping || index != c.state.selection else { return nil }
            return .init(selection: index, expanded: c.state.expanded || !compact.contains(index))
        }
        if !c.state.expanded {
            guard c.count > compact.count else { return nil }
            if backward {
                guard wrapping else { return nil }
                return .init(
                    selection: c.projected(in: bands, band: bands.count - 1, movingBackward: true)
                        ?? current,
                    expanded: true)
            }
            let advances = c.orientation == .horizontal && c.advanceOnExpansion
            let index =
                advances
                ? c.projected(in: bands, band: currentBand + 1, movingBackward: false) ?? current
                : current
            return .init(selection: index, expanded: true)
        }
        if backward, currentBand == 0, !wrapping {
            return .init(selection: min(current, compact.last ?? current), expanded: false)
        }
        // Page keys and host page actions advance one row or column in expanded layouts.
        let requested = currentBand + delta
        // Crossing either end wraps to the boundary band, not the modulo remainder.
        let targetBand =
            wrapping && !bands.indices.contains(requested)
            ? (backward ? bands.count - 1 : 0)
            : bounded(requested, count: bands.count, wrapping: false)
        guard wrapping || targetBand != currentBand,
            let index = c.projected(in: bands, band: targetBand, movingBackward: backward)
        else { return nil }
        return .init(selection: index)
    }
}
