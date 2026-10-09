import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateIndependentDesignTests: XCTestCase {
    func testLineBreaksMatchExhaustiveOptimization() {
        func allPartitions(_ spans: [Int], capacity: Int, limit: Int, start: Int = 0) -> [[Range<Int>]] {
            if start == spans.count { return [[]] }
            var result: [[Range<Int>]] = []
            var occupied = 0
            for end in start..<min(spans.count, start + limit) {
                occupied += min(capacity, spans[end])
                if occupied > capacity { break }
                for suffix in allPartitions(spans, capacity: capacity, limit: limit, start: end + 1) {
                    result.append([start..<end + 1] + suffix)
                }
            }
            return result
        }
        for capacity in 2...6 {
            for seed in 0..<40 {
                let spans = (0..<7).map { 1 + ((seed * ($0 + 3) + $0 * $0) % (capacity + 1)) }
                let limit = 1 + seed % 5
                func penalty(_ rows: [Range<Int>]) -> Int {
                    rows.dropLast().reduce(0) { total, row in
                        let blank = capacity - row.reduce(0) { $0 + min(capacity, spans[$1]) }
                        return total + blank * blank
                    }
                }
                let expected = allPartitions(spans, capacity: capacity, limit: limit).sorted {
                    if $0.count != $1.count { return $0.count < $1.count }
                    if penalty($0) != penalty($1) { return penalty($0) < penalty($1) }
                    return $1.map(\.count).lexicographicallyPrecedes($0.map(\.count))
                }.first!
                XCTAssertEqual(CandidateLineBreaker.partition(spans: spans, capacity: capacity, itemLimit: limit), expected)
            }
        }
    }

    func testGridPreservesOrderAndNeverOverlaps() throws {
        let candidates = (0..<40).map { Candidate(displayString: String(repeating: "文", count: ($0 % 11) + 1)) }
        for size: CGFloat in [8, 16, 32] {
            for capacity in [1, 3, 9, 15] {
                let config = try CandidateConfiguration(candidateFontSize: size, pageSize: capacity)
                let metrics = CandidateMetrics(requestedCandidateFont: .systemFont(ofSize: size),
                    requestedIndexFont: .systemFont(ofSize: 8), availableWidth: 260)
                let rows = HorizontalCandidateLayoutEngine.expandedRows(candidates: candidates, configuration: config, metrics: metrics)
                XCTAssertEqual(rows.flatMap(\.candidateIndexes), Array(candidates.indices))
                let budget = HorizontalCandidateLayoutEngine.horizontalBudget(configuration: config, metrics: metrics)
                for row in rows {
                    XCTAssertLessThanOrEqual(row.items.count, capacity)
                    XCTAssertLessThanOrEqual(row.items.last!.frame.maxX, budget + 0.00001)
                    for pair in zip(row.items, row.items.dropFirst()) {
                        XCTAssertLessThanOrEqual(pair.0.frame.maxX, pair.1.frame.minX + 0.00001)
                    }
                }
            }
        }
    }

    func testBackgroundWorkIsVersionedAndHideCancelsPresentationUpdates() async throws {
        let config = try CandidateConfiguration(orientation: .vertical, allowsExpansion: false, pageSize: 3)
        let controller = CandidateController(configuration: config)
        let long = (0..<40).map { Candidate(displayString: String(repeating: "混合🙂Ab", count: 50) + String($0)) }
        controller.replaceCandidates(long, initialSelectedIndex: 0)
        XCTAssertLessThan(controller.textMeasurements.synchronousMeasurementCount, 20)
        controller.visible = true
        await Task.yield()
        let version = controller.textMeasurements.generation
        controller.replaceCandidates([Candidate(displayString: "新")], initialSelectedIndex: 0)
        XCTAssertGreaterThan(controller.textMeasurements.generation, version)
        controller.visible = false
        let size = controller.window!.frame.size
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(controller.visible)
        XCTAssertEqual(controller.window!.frame.size, size)
        XCTAssertEqual(controller.candidates.map(\.displayString), ["新"])
        controller.visible = true
        try await waitForMeasurements(controller)
        controller.visible = false
    }

    func testColdMeasurementBatchesHandleUniqueAndRepeatedRequests() async throws {
        for (count, distinctCount) in [(40, 40), (50, 17)] {
            for batchSize in [1, 9, 15] {
                let store = CandidateTextMeasurements()
                let metrics = CandidateMetrics(
                    requestedCandidateFont: .systemFont(ofSize: 16),
                    requestedIndexFont: .systemFont(ofSize: 9),
                    measurementStore: store)
                let candidates = (0..<count).map {
                    Candidate(displayString: "候選\($0 % distinctCount)", detail: "說明\($0 % 5)")
                }
                var completions = 0
                store.onCompletion = { completions += 1 }
                store.begin(candidates: candidates, metrics: metrics)
                store.resume(batchSize: batchSize)
                for _ in 0..<500 where !store.isComplete {
                    try await Task.sleep(for: .milliseconds(10))
                }
                XCTAssertTrue(store.isComplete)
                XCTAssertEqual(completions, 1)
                XCTAssertEqual(store.backgroundMeasurementCount, distinctCount + 5)
                XCTAssertEqual(store.synchronousMeasurementCount, 0)
                XCTAssertTrue(candidates.allSatisfy { store.contains($0, metrics: metrics) })
                store.cancel()
            }
        }
    }

    func testBackgroundCompletionDoesNotInterruptExpansion() throws {
        let config = try CandidateConfiguration(orientation: .vertical, allowsExpansion: true, animationDuration: 0.2)
        let controller = CandidateController(configuration: config)
        let clock = ManualCandidateTransitionClock()
        controller.transitionClock = clock
        defer { controller.visible = false }
        controller.replaceCandidates((0..<40).map { Candidate(displayString: "候選\($0)") }, initialSelectedIndex: 0)
        controller.visible = true
        // Worker delivery is covered by testColdMeasurementBatchesHandleUniqueAndRepeatedRequests.
        // Deliver its completion synchronously here so window events cannot race this assertion.
        controller.textMeasurements.cancel()
        controller.textMeasurements.prime(controller.candidates,
            indexes: controller.candidates.indices, metrics: controller.metrics)
        guard controller.visible else {
            XCTFail("The candidate window must be visible before navigation.")
            return
        }
        guard controller.navigate(.right) else {
            XCTFail("Right navigation must start vertical expansion.")
            return
        }
        guard controller.isFrameTransitionActive else {
            XCTFail("Expansion must start before measurement completion is delivered.")
            return
        }
        let driver = try XCTUnwrap(controller.frameTransitionDriver)
        XCTAssertEqual(clock.startCount, 1)
        XCTAssertTrue(controller.isExpanded)
        XCTAssertFalse(controller.deferredMeasurementRefresh)
        clock.advance(by: config.animationDuration / 2)
        let frame = try XCTUnwrap(controller.window).frame
        let copies = controller.renderer.temporaryViewCount

        let completion = try XCTUnwrap(controller.textMeasurements.onCompletion)
        completion()
        XCTAssertTrue(controller.deferredMeasurementRefresh)
        XCTAssertTrue(controller.frameTransitionDriver === driver)
        XCTAssertTrue(controller.isFrameTransitionActive)
        XCTAssertEqual(controller.window?.frame, frame)
        XCTAssertEqual(controller.renderer.temporaryViewCount, copies)
        XCTAssertEqual(clock.startCount, 1)

        clock.advance(by: config.animationDuration / 2)
        XCTAssertFalse(controller.isFrameTransitionActive)
        XCTAssertNil(controller.frameTransitionDriver)
        XCTAssertFalse(controller.deferredMeasurementRefresh)
        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(controller.renderer.temporaryViewCount, 0)
        XCTAssertTrue(controller.isExpanded)
        XCTAssertEqual(controller.selectionIndex, 0)

        XCTAssertTrue(controller.navigate(.left))
        XCTAssertTrue(controller.isFrameTransitionActive)
        XCTAssertEqual(clock.startCount, 2)
        controller.visible = false
        let hiddenFrame = controller.window?.frame
        clock.advance(by: config.animationDuration)
        XCTAssertFalse(controller.visible)
        XCTAssertFalse(controller.isFrameTransitionActive)
        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(controller.renderer.temporaryViewCount, 0)
        XCTAssertEqual(controller.window?.frame, hiddenFrame)
    }

    private func waitForMeasurements(_ controller: CandidateController) async throws {
        for _ in 0..<500 where !controller.textMeasurements.isComplete {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertTrue(controller.textMeasurements.isComplete)
    }
}

@MainActor
private final class ManualCandidateTransitionClock: CandidateTransitionClock {
    private(set) var now: CFTimeInterval = 0
    private(set) var startCount = 0
    private var onFrame: (@MainActor () -> Void)?
    var isRunning: Bool { onFrame != nil }

    func start(onFrame: @escaping @MainActor () -> Void) {
        self.onFrame = onFrame
        startCount += 1
    }

    func stop() {
        onFrame = nil
    }

    func advance(by interval: CFTimeInterval) {
        now += interval
        onFrame?()
    }
}
