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

// Product dimensions are expressed separately from algorithm and platform constants.
internal enum CandidateStyle {
    enum Typography {
        static let minimumSize: CGFloat = 8
        static let referenceSize: CGFloat = 16
        static let shortcutEm: CGFloat = 0.5625
        static let detailUnits: CGFloat = 3
    }
    enum Spacing {
        static let leadingUnits: CGFloat = 1
        static let shortcutGapUnits: CGFloat = 0.5
        static let detailGapUnits: CGFloat = 2.75
        static let trailingUnits: CGFloat = 2.25
        static let verticalUnits: CGFloat = 3
        static let shortcutAllowance: CGFloat = 2
        static let opticalTrailingEm: CGFloat = 0.125
        static let overlayClearance: CGFloat = 2
    }
    enum Controls {
        static let imageBox: CGFloat = 16
        static let expandSymbol: CGFloat = 11
        static let expandLeading: CGFloat = 5
        static let expandTrailing: CGFloat = 6
    }
    enum Decoration {
        static let separator: CGFloat = 1
        static let separatorThickness: CGFloat = 0.5
        static let defaultCornerRadius: CGFloat = 6
        static let horizontalCornerRadius: CGFloat = 8
        static let selectionInset: CGFloat = 2
        static let lightRowWashOpacity: CGFloat = 1 / 2
        static let darkRowWashOpacity: CGFloat = 1 / 8
    }
    enum Layout {
        static let packingLeadingReserve: CGFloat = 4
        static let packingTrailingReserve: CGFloat = 7
        static let horizontalWidthEm: CGFloat = 24
        static let verticalWidthEm: CGFloat = 16
        static let wideCellEm: CGFloat = 4
        static let regularCellEm: CGFloat = 2.5
        static let partialNextBandFraction: CGFloat = 0.5
        static let minimumDetailEm: CGFloat = 1
        static let selectedTrailingFraction: CGFloat = 0.5
    }
    enum Interaction {
        static let dragActivationDistance: CGFloat = 3
    }
}

internal enum CandidateLineBreaker {
    // Compare complete suffix solutions: row count, raggedness, then earliest break length.
    static func partition(spans: [Int], capacity: Int, itemLimit: Int) -> [Range<Int>] {
        guard !spans.isEmpty else { return [] }
        struct Solution {
            var rows: Int
            var penalty: Int
            var next: Int
        }
        var suffix = Array(repeating: Solution(rows: Int.max, penalty: Int.max, next: 0), count: spans.count + 1)
        suffix[spans.count] = Solution(rows: 0, penalty: 0, next: spans.count)
        for start in spans.indices.reversed() {
            var used = 0
            for end in start..<min(spans.count, start + itemLimit) {
                used += min(capacity, max(1, spans[end]))
                if used > capacity { break }
                let next = end + 1
                let blank = next == spans.count ? 0 : capacity - used
                let candidate = Solution(rows: suffix[next].rows + 1,
                    penalty: suffix[next].penalty + blank * blank, next: next)
                let current = suffix[start]
                if candidate.rows < current.rows
                    || (candidate.rows == current.rows && candidate.penalty < current.penalty)
                    || (candidate.rows == current.rows && candidate.penalty == current.penalty && candidate.next > current.next) {
                    suffix[start] = candidate
                }
            }
        }
        var ranges: [Range<Int>] = []
        var cursor = 0
        while cursor < spans.count {
            let next = suffix[cursor].next
            ranges.append(cursor..<next)
            cursor = next
        }
        return ranges
    }
}
