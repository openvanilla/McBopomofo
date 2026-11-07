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

// Describes the frame endpoints for one candidate during an expand/collapse
// transition, without holding an AppKit view itself.
internal struct CandidateAnimationTrack {
    var item: CandidateLayoutItem
    // True binds to the persistent view already rendered in the transition's target
    // layout. False asks CandidateRenderer to create a temporary view from item
    // and remove it after the transition. The target is the expanded layout
    // when expanding and the compact layout when collapsing.
    var usesDestinationView: Bool
    var initialFrame: NSRect
    var finalFrame: NSRect

    func reversed() -> Self {
        var result = self
        swap(&result.initialFrame, &result.finalFrame)
        return result
    }
}

internal enum CandidateAnimationPlanner {
    // A canonical compact-to-expanded scene is reversible; views are bound by the renderer.
    // Returns per-view frame endpoints for expansion, or swaps those
    // endpoints for collapse. CandidateRenderer.bind attaches the tracks to views;
    // the controller drives their progress alongside the window's resizing.
    static func tracks(
        compact: CandidatePanelLayout,
        expanded: CandidatePanelLayout,
        expanding: Bool
    ) -> [CandidateAnimationTrack] {
        // Keep candidates shared with the first expanded column visible as they
        // move directly to their new frames. Candidates absent from the compact
        // layout are revealed by the growing clip. Collapse plays these motions
        // backward, with views bound to the compact target.
        let compactItems = Dictionary(
            uniqueKeysWithValues: compact.items.map { ($0.candidateIndex, $0) })
        var tracks: [CandidateAnimationTrack] = []
        for destination in expanded.items {
            guard let source = compactItems[destination.candidateIndex] else {
                // Newly revealed candidates stay opaque and stationary behind the viewport clip.
                tracks.append(
                    .init(
                        item: destination, usesDestinationView: expanding,
                        initialFrame: destination.frame, finalFrame: destination.frame))
                continue
            }
            tracks.append(
                .init(
                    item: expanding ? destination : source,
                    usesDestinationView: true,
                    initialFrame: source.frame, finalFrame: destination.frame))
        }
        return expanding ? tracks : tracks.map { $0.reversed() }
    }
}
