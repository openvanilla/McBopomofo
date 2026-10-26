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

extension CandidateOrientation {
    // Rows in the shared navigation model represent columns for vertical layouts.
    func itemInterval(_ frame: NSRect) -> ClosedRange<CGFloat> {
        self == .horizontal ? frame.minX...frame.maxX : frame.minY...frame.maxY
    }

    func scrollInterval(_ frame: NSRect) -> ClosedRange<CGFloat> {
        self == .horizontal ? frame.minY...frame.maxY : frame.minX...frame.maxX
    }

    func scrollPoint(_ offset: CGFloat) -> NSPoint {
        self == .horizontal ? NSPoint(x: 0, y: offset) : NSPoint(x: offset, y: 0)
    }

    func expandableNavigation(_ navigation: CandidateNavigation) -> CandidateNavigation {
        guard self == .vertical else { return navigation }
        switch navigation {
        case .up: return .left
        case .down: return .right
        case .left: return .up
        case .right: return .down
        default: return navigation
        }
    }
}
