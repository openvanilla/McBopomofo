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
    // What a view captures when it is created. A change to any of these needs a new view;
    // the frame, index label, selection, and colors are updated in place.
    private struct ItemInputs: Equatable {
        var identity: ObjectIdentifier
        var fonts: [NSFont]
        var keyLabelsAsDetails: Bool
        var reservesIndexSlot: Bool
        var showsDetail: Bool
        var alignedCandidateWidth: CGFloat?
    }
    private struct ItemBinding {
        var view: CandidateItemView
        var inputs: ItemInputs
    }
    private var bindings: [Int: ItemBinding] = [:]
    var itemViews: some Sequence<CandidateItemView> { bindings.values.lazy.map(\.view) }
    subscript(index: Int) -> CandidateItemView? { bindings[index]?.view }

    // Reconciles the persistent canvas views with a layout: reuses matching candidate
    // views, replaces changed ones, removes absent ones, and updates decorations.
    // Here "synchronize" means matching views to layout data; it does
    // not finish an animation.
    func synchronize(
        layout: CandidatePanelLayout, candidates: [Candidate], metrics: CandidateMetrics,
        reservesIndexSlot: Bool,
        selection: Int, colors: CandidateSelectionColors, canvas: CandidateCanvasView,
        makeItem: (CandidateLayoutItem) -> CandidateItemView
    ) {
        canvas.frame = NSRect(origin: .zero, size: layout.documentSize)
        let fonts = [metrics.candidateFont, metrics.indexFont, metrics.detailFont]
        let surviving = Set(layout.items.map(\.candidateIndex))
        for index in Array(bindings.keys) where !surviving.contains(index) {
            bindings.removeValue(forKey: index)?.view.removeFromSuperview()
        }
        for item in layout.items {
            let inputs = ItemInputs(
                identity: ObjectIdentifier(candidates[item.candidateIndex]), fonts: fonts,
                keyLabelsAsDetails: metrics.keyLabelDetailWidth != nil,
                reservesIndexSlot: reservesIndexSlot, showsDetail: item.showsDetail,
                alignedCandidateWidth: item.alignedCandidateWidth)
            let old = bindings[item.candidateIndex]
            let view: CandidateItemView
            if let old, old.inputs == inputs {
                view = old.view
            } else {
                old?.view.removeFromSuperview()
                view = makeItem(item)
                canvas.addSubview(view)
                bindings[item.candidateIndex] = ItemBinding(view: view, inputs: inputs)
            }
            view.frame = item.frame
            view.indexText = item.indexText
            view.showsIndexText = item.showsIndexText
            view.selected = item.candidateIndex == selection
            view.selectionColors = colors
            view.outerCornerRadius = layout.cornerRadius
        }
        canvas.rowWashRect = layout.rowWashRect
        canvas.rowWashAlpha = 1
        canvas.separatorRects = layout.separatorRects
    }
}
