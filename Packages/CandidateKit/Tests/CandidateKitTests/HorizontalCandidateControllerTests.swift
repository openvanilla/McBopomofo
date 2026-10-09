import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class HorizontalCandidateControllerTests: XCTestCase {
    private let screenshotCandidates = [
        "小麥注音", "注音", "因", "音", "陰", "姻", "殷", "茵", "慇",
        "氤", "痕", "暗", "壅", "湮", "惜", "裡", "絪", "袒",
        "闇", "駰", "銦", "蔭", "諳", "垔", "馨", "洇", "湮", "愔", "禋", "絪",
    ].map { Candidate(displayString: $0) }

    func testDefaultMetricsMatchSpecification() {
        let metrics = CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 16),
            requestedIndexFont: .systemFont(ofSize: 8)
        )

        XCTAssertEqual(metrics.itemHeight, 28)
        XCTAssertEqual(metrics.leadingPadding, 4)
        XCTAssertEqual(metrics.indexSlotWidth, 11)
        XCTAssertEqual(metrics.indexCandidateGap, 2)
        XCTAssertEqual(metrics.candidateDetailGap, 11)
        XCTAssertEqual(metrics.trailingPadding, 9)
        XCTAssertEqual(metrics.baseCellWidth, 42)
        XCTAssertEqual(metrics.detailFont.pointSize, 12)
        XCTAssertEqual(metrics.cornerRadius, 6)
        XCTAssertEqual(metrics.dragActivationDistance, 3)
    }

    func testEmptyIndexLabelsRemoveTheReservedColumn() throws {
        let configuration = try CandidateConfiguration(indexLabels: "")
        let candidates = (0..<9).map { _ in Candidate(displayString: "永") }
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: candidates,
            configuration: configuration,
            metrics: defaultMetrics
        )

        XCTAssertEqual(defaultMetrics.baseCellWidth(showsIndexColumn: false), 34)
        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].items.map(\.frame.width), Array(repeating: 34, count: 9))
    }

    func testExpandableConfigurationDistributesOnlyFirstPageAndKeepsFollowingPagesNatural() throws {
        let configuration = CandidateConfiguration.default
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: screenshotCandidates,
            configuration: configuration,
            metrics: defaultMetrics
        )
        XCTAssertGreaterThan(pages.count, 2)

        let firstPage = pages[0]
        let firstLayout = HorizontalCandidateLayoutEngine.pagedLayout(
            pages: pages,
            pageIndex: 0,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics
        )
        let firstNaturalWidth = try XCTUnwrap(firstPage.items.last).frame.maxX
        let distributedWidth =
            (firstLayout.windowSize.width - firstNaturalWidth)
            / CGFloat(firstPage.items.count)

        XCTAssertLessThanOrEqual(firstPage.items.count, configuration.pageSize)
        XCTAssertEqual(firstLayout.windowSize.width, max(firstNaturalWidth, 384))
        XCTAssertEqual(
            try XCTUnwrap(firstLayout.items.last).frame.maxX, firstLayout.windowSize.width,
            accuracy: 0.000_001)
        for (index, pair) in zip(firstPage.items, firstLayout.items).enumerated() {
            XCTAssertEqual(
                pair.1.frame.width,
                pair.0.frame.width + distributedWidth,
                accuracy: 0.000_001
            )
            XCTAssertEqual(
                pair.1.frame.minX,
                pair.0.frame.minX + CGFloat(index) * distributedWidth,
                accuracy: 0.000_001
            )
        }

        let middlePage = pages[1]
        let middleLayout = HorizontalCandidateLayoutEngine.pagedLayout(
            pages: pages,
            pageIndex: 1,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics
        )
        XCTAssertEqual(middleLayout.windowSize.width, 384)
        XCTAssertEqual(middleLayout.items.map(\.frame), middlePage.items.map(\.frame))

        let finalPageIndex = pages.index(before: pages.endIndex)
        let finalPage = pages[finalPageIndex]
        let finalLayout = HorizontalCandidateLayoutEngine.pagedLayout(
            pages: pages,
            pageIndex: finalPageIndex,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics
        )

        XCTAssertEqual(finalLayout.items.map(\.frame), finalPage.items.map(\.frame))
        XCTAssertEqual(
            finalLayout.windowSize.width,
            384
        )
        XCTAssertLessThan(
            try XCTUnwrap(finalLayout.items.last).frame.maxX,
            finalLayout.windowSize.width
        )
    }

    func testNonexpandingPagesUseNaturalWidthsWithoutDistribution() throws {
        for pageSize in [4, 9] {
            let configuration = try CandidateConfiguration(
                allowsExpansion: false, pageSize: pageSize)
            let pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: screenshotCandidates,
                configuration: configuration,
                metrics: defaultMetrics
            )
            XCTAssertGreaterThan(pages.count, 2)
            var widths: [CGFloat] = []
            for pageIndex in pages.indices {
                let page = pages[pageIndex]
                let layout = HorizontalCandidateLayoutEngine.pagedLayout(
                    pages: pages,
                    pageIndex: pageIndex,
                    keyLabels: defaultKeyLabels,
                    configuration: configuration,
                    metrics: defaultMetrics
                )
                let naturalWidth = try XCTUnwrap(page.items.last).frame.maxX
                XCTAssertEqual(layout.items.map(\.frame), page.items.map(\.frame))
                XCTAssertEqual(layout.windowSize.width, naturalWidth)
                XCTAssertEqual(layout.documentSize.width, naturalWidth)
                widths.append(naturalWidth)
            }
            XCTAssertLessThan(try XCTUnwrap(widths.last), try XCTUnwrap(widths.first))
        }
    }

    func testOneOversizedCandidateAlwaysOccupiesOnePage() {
        let candidates = [Candidate(displayString: String(repeating: "永", count: 100))]
        let pages = HorizontalCandidateLayoutEngine.packedPages(
            candidates: candidates,
            configuration: .default,
            metrics: defaultMetrics
        )

        XCTAssertEqual(pages.count, 1)
        XCTAssertEqual(pages[0].items.count, 1)
        XCTAssertEqual(pages[0].items[0].frame.width, 384)
    }

    func testNonexpandingLongListAt24PointsFitsAvailableScreenWidth() throws {
        let configuration = try CandidateConfiguration(
            allowsExpansion: false, candidateFontSize: 24)
        let candidates = (1...201).map { Candidate(displayString: "選字\($0)", detail: "說明") }
        let unconstrainedMetrics = CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 24),
            requestedIndexFont: .systemFont(ofSize: 12))
        let firstEightWidth = candidates.prefix(8).reduce(CGFloat.zero) {
            $0 + unconstrainedMetrics.intrinsicWidth(for: $1, showsIndexColumn: true)
        }
        for availableWidth in [320, 1024, firstEightWidth, 1920] {
            let metrics = CandidateMetrics(
                requestedCandidateFont: .systemFont(ofSize: 24),
                requestedIndexFont: .systemFont(ofSize: 12), availableWidth: availableWidth)
            let pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates, configuration: configuration, metrics: metrics)
            XCTAssertEqual(pages.flatMap(\.candidateIndexes), Array(candidates.indices))
            if availableWidth == firstEightWidth {
                XCTAssertEqual(pages[0].items.count, 8)
                XCTAssertEqual(pages[1].candidateIndexes.first, 8)
            }
            for pageIndex in pages.indices {
                let layout = HorizontalCandidateLayoutEngine.pagedLayout(
                    pages: pages, pageIndex: pageIndex, keyLabels: defaultKeyLabels,
                    configuration: configuration, metrics: metrics)
                XCTAssertLessThanOrEqual(layout.items.count, configuration.pageSize)
                XCTAssertLessThanOrEqual(layout.windowSize.width, availableWidth)
                XCTAssertEqual(layout.windowSize.width, try XCTUnwrap(layout.items.last).frame.maxX)
                XCTAssertEqual(layout.items.map(\.frame), pages[pageIndex].items.map(\.frame))
            }
        }
    }

    func testNonexpandingPagesHonorConfiguredSelectionKeyCount() throws {
        for keys in ["asdf", "123456789", "123456789abcdef"] {
            let configuration = try CandidateConfiguration(
                allowsExpansion: false,
                indexLabels: keys, pageSize: keys.count, animationDuration: 0)
            let controller = CandidateController(configuration: configuration)
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

    func testConfigurationValidation() throws {
        XCTAssertThrowsError(try CandidateConfiguration(pageSize: 0))
        XCTAssertNoThrow(try CandidateConfiguration(pageSize: 15))
        XCTAssertThrowsError(try CandidateConfiguration(pageSize: 16))
        XCTAssertThrowsError(try CandidateConfiguration(indexLabels: "１２３"))
        XCTAssertNoThrow(try CandidateConfiguration(indexLabels: ""))
        XCTAssertNoThrow(try CandidateConfiguration(indexLabels: "1 1"))

        var mutatedConfiguration = CandidateConfiguration.default
        mutatedConfiguration.pageSize = 0
        XCTAssertThrowsError(try mutatedConfiguration.validate())
    }

    func testPagedNavigationSelectsFirstCandidateOfEachPage() {
        let controller = HorizontalCandidateController(expandable: false)
        controller.replaceCandidates(screenshotCandidates, initialSelectedIndex: 6)
        controller.visible = true
        defer { controller.visible = false }

        XCTAssertEqual(controller.candidates[controller.selectionIndex].displayString, "殷")
        XCTAssertTrue(controller.navigate(.down))
        XCTAssertEqual(controller.currentPageIndex, 1)
        XCTAssertEqual(controller.selectionIndex, 9)
        XCTAssertEqual(controller.candidates[controller.selectionIndex].displayString, "氤")
        XCTAssertEqual(controller.currentLayout.item(for: 9)?.indexText, "1")

        XCTAssertTrue(controller.navigate(.up))
        XCTAssertEqual(controller.currentPageIndex, 0)
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
