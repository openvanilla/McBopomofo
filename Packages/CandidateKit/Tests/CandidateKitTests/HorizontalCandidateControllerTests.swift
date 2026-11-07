import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class HorizontalCandidateControllerTests: XCTestCase {
    private let screenshotCandidates = [
        "小麥注音", "注音", "因", "音", "陰", "姻", "殷", "茵", "慇", "氤",
        "痕", "暗", "壅", "湮", "惜", "裡", "絪", "袒", "闇", "駰",
        "銦", "蔭", "諳", "垔", "馨", "洇", "湮", "愔", "禋", "絪",
    ].map { Candidate(displayString: $0) }

    func testDefaultMetricsMatchSpecification() {
        let metrics = CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 16),
            requestedIndexFont: .systemFont(ofSize: 8)
        )

        XCTAssertEqual(metrics.itemHeight, 28)
        XCTAssertEqual(metrics.baseCellWidth(showsIndexColumn: true), 42)
    }

    func testEmptyIndexLabelsRemoveTheReservedColumn() {
        let candidates = (0..<9).map { _ in Candidate(displayString: "永") }
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: candidates,
            keyLabels: [],
            configuration: .default,
            metrics: defaultMetrics
        )

        XCTAssertEqual(defaultMetrics.baseCellWidth(showsIndexColumn: false), 34)
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].items.map(\.frame.width), Array(repeating: 34, count: 9))
    }

    func testOneOversizedCandidateAlwaysOccupiesOnePage() {
        let candidates = [Candidate(displayString: String(repeating: "永", count: 100))]
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: candidates,
            keyLabels: defaultKeyLabels,
            configuration: .default,
            metrics: defaultMetrics,
            maximumWidth: 1024
        )

        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].items.count, 1)
        XCTAssertEqual(pages[0].items[0].frame.width, 1024)
    }

    func testLongCandidateUsesNaturalWidthWhenItFitsTheScreen() throws {
        let candidate = Candidate(displayString: String(repeating: "永", count: 40))
        let metrics = defaultMetrics
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: [candidate], keyLabels: defaultKeyLabels, configuration: .default,
            metrics: metrics, maximumWidth: 1024)
        let item = try XCTUnwrap(pages.first?.items.first)
        XCTAssertEqual(
            item.frame.width, metrics.intrinsicWidth(for: candidate, showsIndexColumn: true))
    }

    func testLongListAt24PointsFitsAvailableWidth() throws {
        let configuration = CandidateConfiguration.default
        let candidates = (1...201).map { Candidate(displayString: "選字\($0)", detail: "說明") }
        let metrics = CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 24),
            requestedIndexFont: .systemFont(ofSize: 12))
        let firstEightWidth = candidates.prefix(8).reduce(CGFloat.zero) {
            $0 + metrics.intrinsicWidth(for: $1, showsIndexColumn: true)
        }
        for availableWidth in [320, 1024, firstEightWidth, 1920] {
            let pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates, keyLabels: defaultKeyLabels,
                configuration: configuration, metrics: metrics, maximumWidth: availableWidth)
            XCTAssertEqual(pages.flatMap(\.candidateIndexes), Array(candidates.indices))
            if availableWidth == firstEightWidth {
                XCTAssertEqual(pages[0].items.count, 8)
                XCTAssertEqual(pages[1].candidateIndexes.first, 8)
            }
            for pageIndex in pages.indices {
                let layout = HorizontalCandidateLayoutEngine.pagedLayout(
                    pages: pages, pageIndex: pageIndex, keyLabels: defaultKeyLabels,
                    metrics: metrics)
                XCTAssertLessThanOrEqual(layout.items.count, configuration.pageSize)
                XCTAssertLessThanOrEqual(layout.windowSize.width, availableWidth)
                XCTAssertEqual(layout.windowSize.width, try XCTUnwrap(layout.items.last).frame.maxX)
                XCTAssertEqual(layout.documentSize.width, layout.windowSize.width)
                XCTAssertEqual(layout.items.map(\.frame), pages[pageIndex].items.map(\.frame))
            }
            // Pages keep their natural widths, so the short last page is narrower than the first.
            let pageWidths = pages.map { $0.items.last?.frame.maxX ?? 0 }
            XCTAssertLessThan(try XCTUnwrap(pageWidths.last), try XCTUnwrap(pageWidths.first))
        }
    }

    func testPagesHonorConfiguredSelectionKeyCount() throws {
        for keys in ["asdf", "123456789", "123456789abcdef"] {
            let configuration = CandidateConfiguration(
                pageSize: keys.count, animationDuration: 0)
            let controller = CandidateController(configuration: configuration)
            controller.keyLabels = keys.map {
                CandidateKeyLabel(key: String($0), displayedText: String($0))
            }
            let candidates = (0..<(keys.count * 2 + 1)).map {
                Candidate(displayString: String(repeating: "字", count: $0 % 4 + 1))
            }
            controller.replaceCandidates(candidates, initialSelectedIndex: 2)
            controller.visible = true
            defer { controller.visible = false }
            for page in 0..<3 {
                let start = page * keys.count
                let indexes = Array(start..<min(start + keys.count, candidates.count))
                XCTAssertEqual(controller.currentLayout.items.map(\.candidateIndex), indexes)
                let naturalWidth = try XCTUnwrap(controller.currentLayout.items.last).frame.maxX
                XCTAssertEqual(controller.currentLayout.windowSize.width, naturalWidth)
                XCTAssertEqual(
                    try XCTUnwrap(controller.window).frame.width, naturalWidth, accuracy: 1)
                for (slot, index) in indexes.enumerated() {
                    XCTAssertEqual(
                        controller.candidateIndexAtKeyLabelIndex(UInt(slot)), UInt(index))
                    let item = try XCTUnwrap(controller.currentLayout.item(for: index))
                    XCTAssertEqual(item.indexText, String(Array(keys)[slot]))
                    XCTAssertLessThanOrEqual(
                        item.frame.maxX, controller.currentLayout.windowSize.width)
                }
                if page < 2 { XCTAssertTrue(controller.showNextPage()) }
            }
            XCTAssertFalse(controller.showNextPage())
            XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(1), UInt.max)
        }
    }

    func testConfigurationValidation() {
        XCTAssertThrowsError(try CandidateConfiguration(pageSize: 0).validate())
        XCTAssertNoThrow(try CandidateConfiguration(pageSize: 15).validate())
        XCTAssertThrowsError(try CandidateConfiguration(pageSize: 16).validate())
        XCTAssertThrowsError(
            try CandidateConfiguration(verticalMaximumVisibleColumns: 0).validate())
        XCTAssertThrowsError(
            try CandidateController().apply(configuration: CandidateConfiguration(pageSize: 0)))
    }

    func testPagedNavigationSelectsFirstCandidateOfEachPage() {
        let controller = HorizontalCandidateController()
        controller.replaceCandidates(screenshotCandidates, initialSelectedIndex: 6)
        controller.visible = true
        defer { controller.visible = false }

        XCTAssertEqual(controller.candidates[controller.selectionIndex].displayString, "殷")
        XCTAssertTrue(controller.navigate(.down))
        XCTAssertEqual(controller.currentLayout.items.first?.candidateIndex, 9)
        XCTAssertEqual(controller.selectionIndex, 9)
        XCTAssertEqual(controller.candidates[controller.selectionIndex].displayString, "氤")
        XCTAssertEqual(controller.currentLayout.item(for: 9)?.indexText, "1")

        XCTAssertTrue(controller.navigate(.up))
        XCTAssertEqual(controller.currentLayout.items.first?.candidateIndex, 0)
        XCTAssertEqual(controller.selectionIndex, 0)
    }

    private var defaultMetrics: CandidateMetrics {
        CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 16),
            requestedIndexFont: .systemFont(ofSize: 8)
        )
    }

    private var defaultKeyLabels: [CandidateKeyLabel] {
        "1234567890".map {
            CandidateKeyLabel(key: String($0), displayedText: String($0))
        }
    }
}
