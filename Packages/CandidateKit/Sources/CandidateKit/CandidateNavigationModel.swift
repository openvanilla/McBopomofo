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

internal struct CandidateNavigationDecision {
    var selection: Int
    var expanded: Bool?
}

internal struct CandidateNavigationContext {
    var kind: CandidatePanelKind
    var selection: Int
    var count: Int
    var pageSize: Int
    var pages: [[Int]] = []
    var expanded = false

    // Expanded columns hold pageSize candidates each, and rows line up across columns.
    var columnCount: Int {
        (count + pageSize - 1) / pageSize
    }

    func column(_ column: Int) -> Range<Int> {
        column * pageSize..<min((column + 1) * pageSize, count)
    }

    // Moves to another column while keeping the current row, clamped to a short final column.
    func sameRow(in column: Int) -> Int {
        min(column * pageSize + selection % pageSize, count - 1)
    }

    // Arrow keys stop at either end of the list.
    func clamped(_ index: Int) -> Int {
        min(max(index, 0), count - 1)
    }

    // Item steps continue from one end of the list to the other.
    func wrapped(_ index: Int) -> Int {
        (index % count + count) % count
    }
}

internal enum CandidateNavigationReducer {
    static func resolve(
        _ input: CandidateNavigation,
        context c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        guard c.count > 0 else { return nil }
        let decision: CandidateNavigationDecision?
        switch c.kind {
        case .vertical: decision = vertical(input, c)
        case .horizontalPaged: decision = paged(input, c)
        case .verticalExpandable: decision = expandable(input, c)
        }
        // A decision that changes neither the selection nor the expansion is unhandled.
        guard let decision,
            decision.selection != c.selection || (decision.expanded ?? c.expanded) != c.expanded
        else { return nil }
        return decision
    }

    private static func paged(
        _ input: CandidateNavigation,
        _ c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        switch input {
        case .home: return .init(selection: 0)
        case .end: return .init(selection: c.count - 1)
        // Pages hold consecutive candidates, so item moves step through the whole list.
        case .left: return .init(selection: c.clamped(c.selection - 1))
        case .right: return .init(selection: c.clamped(c.selection + 1))
        case .itemBackward: return .init(selection: c.wrapped(c.selection - 1))
        case .itemForward: return .init(selection: c.wrapped(c.selection + 1))
        case .up, .pageUp, .down, .pageDown:
            let delta = input == .up || input == .pageUp ? -1 : 1
            guard let page = c.pages.firstIndex(where: { $0.contains(c.selection) }),
                c.pages.indices.contains(page + delta)
            else { return nil }
            return c.pages[page + delta].first.map { .init(selection: $0) }
        }
    }

    private static func vertical(
        _ input: CandidateNavigation,
        _ c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        switch input {
        case .home: return .init(selection: 0)
        case .end: return .init(selection: c.count - 1)
        case .up: return .init(selection: c.clamped(c.selection - 1))
        case .down: return .init(selection: c.clamped(c.selection + 1))
        case .itemBackward: return .init(selection: c.wrapped(c.selection - 1))
        case .itemForward: return .init(selection: c.wrapped(c.selection + 1))
        case .left, .pageUp, .right, .pageDown:
            guard c.count > c.pageSize else { return nil }
            let delta = input == .left || input == .pageUp ? -c.pageSize : c.pageSize
            return .init(selection: c.clamped(c.selection + delta))
        }
    }

    private static func expandable(
        _ input: CandidateNavigation,
        _ c: CandidateNavigationContext
    ) -> CandidateNavigationDecision? {
        let current = c.selection
        let currentColumn = current / c.pageSize
        let compact = c.column(0)
        // Stepping out of the first column expands the panel.
        func stepping(to index: Int) -> CandidateNavigationDecision {
            .init(selection: index, expanded: c.expanded || !compact.contains(index))
        }
        switch input {
        case .home, .end:
            let indexes = c.expanded ? c.column(currentColumn) : compact
            return .init(selection: input == .home ? indexes.lowerBound : indexes.upperBound - 1)
        case .up:
            // Moving up from the first candidate collapses an expanded panel.
            if c.expanded, current == 0 { return .init(selection: 0, expanded: false) }
            return stepping(to: c.clamped(current - 1))
        case .down: return stepping(to: c.clamped(current + 1))
        case .itemBackward: return stepping(to: c.wrapped(current - 1))
        case .itemForward: return stepping(to: c.wrapped(current + 1))
        case .left, .pageUp:
            guard c.expanded else { return nil }
            // Moving back from the first column collapses the panel.
            if currentColumn == 0 { return .init(selection: current, expanded: false) }
            return .init(selection: c.sameRow(in: currentColumn - 1))
        case .right, .pageDown:
            guard c.expanded else {
                return c.count > compact.count ? .init(selection: current, expanded: true) : nil
            }
            // Page keys and host page actions advance one column in expanded layouts.
            return .init(selection: c.sameRow(in: min(currentColumn + 1, c.columnCount - 1)))
        }
    }
}
