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
import CoreText

// Descriptors and strings are immutable snapshots; no AppKit view crosses this boundary.
private struct TextMeasureKey: Hashable, @unchecked Sendable {
    let text: String
    let descriptor: NSFontDescriptor
}

private struct TextMeasureRequest: @unchecked Sendable {
    let key: TextMeasureKey
    let font: CTFont

    init(text: String, font: NSFont) {
        key = TextMeasureKey(text: text, descriptor: font.fontDescriptor)
        self.font = font as CTFont
    }

    func measure() -> CGFloat {
        let string = NSAttributedString(string: key.text,
            attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font])
        let line = CTLineCreateWithAttributedString(string)
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }
}

private actor TextMeasureWorker {
    func measure(_ batch: [TextMeasureRequest]) -> [TextMeasureKey: CGFloat] {
        var result: [TextMeasureKey: CGFloat] = [:]
        for request in batch {
            if Task.isCancelled { break }
            result[request.key] = request.measure()
        }
        return result
    }
}

@MainActor
internal final class CandidateTextMeasurements {
    private let worker = TextMeasureWorker()
    private var cache: [TextMeasureKey: CGFloat] = [:]
    private var requests: [TextMeasureRequest] = []
    private var pending: Task<Void, Never>?
    private(set) var generation = 0
    private(set) var synchronousMeasurementCount = 0
    private(set) var backgroundMeasurementCount = 0
    private(set) var isComplete = true
    var onCompletion: (() -> Void)?

    func width(of text: String, font: NSFont) -> CGFloat {
        let request = TextMeasureRequest(text: text, font: font)
        if let cached = cache[request.key] { return cached }
        let width = request.measure()
        cache[request.key] = width
        synchronousMeasurementCount += 1
        return width
    }

    func contains(_ candidate: Candidate, metrics: CandidateMetrics) -> Bool {
        cache[TextMeasureKey(text: candidate.displayString, descriptor: metrics.candidateFont.fontDescriptor)] != nil
            && (candidate.detail == nil || cache[TextMeasureKey(text: candidate.detail!, descriptor: metrics.detailFont.fontDescriptor)] != nil)
    }

    func begin(candidates: [Candidate], metrics: CandidateMetrics) {
        cancel()
        requests = candidates.flatMap { candidate in
            [TextMeasureRequest(text: candidate.displayString, font: metrics.candidateFont)]
                + (candidate.detail.map { [TextMeasureRequest(text: $0, font: metrics.detailFont)] } ?? [])
        }
        // Retain only the active data set, bounding the cache without an arbitrary entry limit.
        let activeKeys = Set(requests.map(\.key))
        cache = cache.filter { activeKeys.contains($0.key) }
        isComplete = requests.allSatisfy { cache[$0.key] != nil }
    }

    func prime(_ candidates: [Candidate], indexes: some Sequence<Int>, metrics: CandidateMetrics) {
        for index in indexes where candidates.indices.contains(index) {
            _ = width(of: candidates[index].displayString, font: metrics.candidateFont)
            if let detail = candidates[index].detail { _ = width(of: detail, font: metrics.detailFont) }
        }
    }

    func resume(batchSize: Int) {
        guard pending == nil, !isComplete else { return }
        let revision = generation
        pending = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.generation == revision else { return }
                var seen: Set<TextMeasureKey> = []
                var batch: [TextMeasureRequest] = []
                let limit = max(batchSize, 1)
                // A lazy collection can evaluate a filter repeatedly while resolving indices.
                // Keep deduplication in a single pass so membership cannot change between reads.
                for request in self.requests {
                    guard self.cache[request.key] == nil,
                        seen.insert(request.key).inserted else { continue }
                    batch.append(request)
                    if batch.count == limit { break }
                }
                if batch.isEmpty {
                    self.isComplete = true
                    self.pending = nil
                    self.onCompletion?()
                    return
                }
                let result = await self.worker.measure(batch)
                guard !Task.isCancelled, self.generation == revision else { return }
                self.backgroundMeasurementCount += result.count
                self.cache.merge(result) { old, _ in old }
                await Task.yield()
            }
        }
    }

    func cancel() {
        generation += 1
        pending?.cancel()
        pending = nil
    }

    deinit { pending?.cancel() }
}
