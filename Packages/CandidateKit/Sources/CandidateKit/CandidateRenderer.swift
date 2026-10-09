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

@MainActor
internal final class CandidateRenderer {
    private struct ItemBinding {
        var view: CandidateItemView
        var identity: ObjectIdentifier
        var layout: CandidateLayoutItem
        var fonts: [NSFont]
        var keyLabelsAsDetails: Bool
    }
    private var bindings: [Int: ItemBinding] = [:]
    private var activeMotions: [(CandidateAnimationTrack, NSView)] = []
    private var temporaryViews: [NSView] = []
    private(set) var control: CandidateControlView?
    var temporaryViewCount: Int { temporaryViews.count }
    var itemViews: some Sequence<CandidateItemView> { bindings.values.lazy.map(\.view) }
    subscript(index: Int) -> CandidateItemView? { bindings[index]?.view }

    func synchronize(layout: CandidatePanelLayout, candidates: [Candidate], metrics: CandidateMetrics,
                     selection: Int, colors: CandidateSelectionColors, canvas: CandidateCanvasView,
                     makeItem: (CandidateLayoutItem) -> CandidateItemView,
                     makeControl: (CandidateControlLayout) -> CandidateControlView) {
        canvas.frame = NSRect(origin: .zero, size: layout.documentSize)
        let fonts = [metrics.candidateFont, metrics.indexFont, metrics.detailFont]
        let surviving = Set(layout.items.map(\.candidateIndex))
        for index in Array(bindings.keys) where !surviving.contains(index) {
            bindings.removeValue(forKey: index)?.view.removeFromSuperview()
        }
        for item in layout.items {
            let identity = ObjectIdentifier(candidates[item.candidateIndex])
            let old = bindings[item.candidateIndex]
            let view: CandidateItemView
            if let old, old.identity == identity, old.layout == item, old.fonts == fonts,
                old.keyLabelsAsDetails == (metrics.keyLabelDetailWidth != nil) {
                view = old.view
            } else {
                old?.view.removeFromSuperview()
                view = makeItem(item)
                canvas.addSubview(view)
                bindings[item.candidateIndex] = ItemBinding(view: view, identity: identity, layout: item, fonts: fonts,
                    keyLabelsAsDetails: metrics.keyLabelDetailWidth != nil)
            }
            view.frame = item.frame
            view.alphaValue = 1
            view.indexText = item.indexText
            view.showsIndexText = item.showsIndexText
            view.selected = item.candidateIndex == selection
            view.selectionColors = colors
            view.outerCornerRadius = layout.cornerRadius
        }
        control?.removeFromSuperview()
        control = layout.control.map(makeControl)
        if let control { canvas.addSubview(control) }
        canvas.rowWashRect = layout.rowWashRect
        canvas.rowWashAlpha = 1
        canvas.separatorRects = layout.separatorRects
    }

    func bind(tracks: [CandidateAnimationTrack], canvas: NSView,
              makeItem: (CandidateLayoutItem) -> CandidateItemView,
              makeControl: (CandidateControlLayout) -> CandidateControlView) {
        finishMotions()
        for track in tracks {
            let view: NSView?
            if track.usesDestinationView {
                view = track.item.flatMap { self[$0.candidateIndex] } ?? control
            } else {
                view = track.item.map(makeItem) ?? track.control.map(makeControl)
                if let view {
                    canvas.addSubview(view)
                    temporaryViews.append(view)
                }
            }
            if let view { activeMotions.append((track, view)) }
        }
        applyMotions(progress: 0)
    }

    func applyMotions(progress: CGFloat) {
        for (track, view) in activeMotions {
            view.frame = .interpolated(from: track.initialFrame, to: track.finalFrame, progress: progress)
            view.alphaValue = track.initialOpacity + (track.finalOpacity - track.initialOpacity) * progress
        }
    }

    func finishMotions() {
        applyMotions(progress: 1)
        temporaryViews.forEach { $0.removeFromSuperview() }
        temporaryViews.removeAll()
        activeMotions.removeAll()
    }
}
