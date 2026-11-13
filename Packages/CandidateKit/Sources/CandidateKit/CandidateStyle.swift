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
    enum Decoration {
        static let separator: CGFloat = 1
        static let separatorThickness: CGFloat = 0.5
        static let defaultCornerRadius: CGFloat = 8
        static let selectionInset: CGFloat = 2
        static let lightRowWashOpacity: CGFloat = 1 / 2
        static let darkRowWashOpacity: CGFloat = 1 / 8
    }
    enum Layout {
        static let horizontalWidthEm: CGFloat = 24
        static let verticalWidthEm: CGFloat = 16
        static let partialNextBandFraction: CGFloat = 0.5
        static let minimumDetailEm: CGFloat = 1
        static let selectedTrailingFraction: CGFloat = 0.5
    }
    enum Interaction {
        static let dragActivationDistance: CGFloat = 3
    }
}
