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

internal struct CandidateAnimationTrack {
    var item: CandidateLayoutItem?
    var control: CandidateControlLayout?
    var usesDestinationView: Bool
    var initialFrame: NSRect
    var finalFrame: NSRect
    var initialOpacity: CGFloat
    var finalOpacity: CGFloat

    func reversed() -> Self {
        var result = self
        swap(&result.initialFrame, &result.finalFrame)
        swap(&result.initialOpacity, &result.finalOpacity)
        return result
    }
}

internal enum CandidateAnimationPlanner {
    // A canonical compact-to-expanded scene is reversible; views are bound by the renderer.
    static func tracks(
        compact: CandidatePanelLayout,
        expanded: CandidatePanelLayout,
        orientation: CandidateOrientation,
        expanding: Bool
    ) -> [CandidateAnimationTrack] {
        let compactItems = Dictionary(uniqueKeysWithValues: compact.items.map { ($0.candidateIndex, $0) })
        let firstBand = Set(expanded.rows.first?.candidateIndexes ?? [])
        var tracks: [CandidateAnimationTrack] = []
        for destination in expanded.items {
            guard let source = compactItems[destination.candidateIndex] else {
                // Newly revealed candidates stay opaque and stationary behind the viewport clip.
                tracks.append(.init(item: destination, usesDestinationView: expanding,
                    initialFrame: destination.frame, finalFrame: destination.frame,
                    initialOpacity: 1, finalOpacity: 1))
                continue
            }
            if firstBand.contains(destination.candidateIndex) {
                tracks.append(.init(
                    item: expanding ? destination : source,
                    usesDestinationView: true,
                    initialFrame: source.frame, finalFrame: destination.frame, initialOpacity: 1, finalOpacity: 1))
                continue
            }
            let destinationInterval = orientation.itemInterval(destination.frame)
            tracks.append(.init(item: destination, usesDestinationView: expanding,
                initialFrame: shifted(destination.frame, by: -destinationInterval.upperBound, orientation: orientation),
                finalFrame: destination.frame,
                initialOpacity: 0, finalOpacity: 1))
            // The visible panel before the transition supplies the outgoing or returning edge.
            let viewport = expanding ? compact.viewportSize : expanded.viewportSize
            let boundary = orientation.itemInterval(NSRect(origin: .zero, size: viewport)).upperBound
            let sourceInterval = orientation.itemInterval(source.frame)
            tracks.append(.init(item: source, usesDestinationView: !expanding,
                initialFrame: source.frame,
                finalFrame: shifted(source.frame, by: boundary - sourceInterval.lowerBound, orientation: orientation),
                initialOpacity: 1, finalOpacity: 0))
        }
        if let control = compact.control {
            let alignedFrame = control.frame.offsetBy(dx: expanded.windowSize.width - control.frame.maxX, dy: 0)
            tracks.append(.init(control: control, usesDestinationView: !expanding,
                initialFrame: control.frame, finalFrame: alignedFrame,
                initialOpacity: 1, finalOpacity: 0))
        }
        return expanding ? tracks : tracks.map { $0.reversed() }
    }

    private static func shifted(
        _ frame: NSRect,
        by distance: CGFloat,
        orientation: CandidateOrientation
    ) -> NSRect {
        var result = frame
        if orientation == .horizontal {
            result.origin.x += distance
        } else {
            result.origin.y += distance
        }
        return result
    }

}
