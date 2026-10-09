import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class VerticalCandidateControllerTests: XCTestCase {
    func testDefaultOverflowHeightIncludesNineRowsAndPartialRowPeek() {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        let candidates = (0..<27).map { Candidate(displayString: "\($0)") }
        let layout = VerticalCandidateLayoutEngine.layout(
            candidates: candidates,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics,
            numberingAnchor: 0,
            scrollerStyle: .legacy
        )

        XCTAssertTrue(layout.hasVerticalScroller)
        XCTAssertEqual(layout.windowSize.height, 274, accuracy: 0.000_001)
        XCTAssertEqual(layout.documentSize.height, layout.items.last?.frame.maxY)
        XCTAssertEqual(
            layout.items.prefix(9).map(\.indexText),
            [
                "1", "2", "3", "4", "5", "6", "7", "8", "9",
            ])
        XCTAssertEqual(layout.items[9].indexText, "")
    }

    func testShortListsFitLastCandidateAfterReplacingLongList() throws {
        for expandable in [false, true] {
            let controller = VerticalCandidateController(expandable: expandable)
            for count in [1, 5, controller.configuration.pageSize] {
                controller.replaceCandidates(
                    (0..<30).map { Candidate(displayString: "字\($0)") }, initialSelectedIndex: 29)
                controller.replaceCandidates(
                    (0..<count).map { Candidate(displayString: "字\($0)") },
                    initialSelectedIndex: count - 1)

                let lastItem = try XCTUnwrap(controller.currentLayout.items.last)
                XCTAssertEqual(controller.currentLayout.windowSize.height, lastItem.frame.maxY)
                XCTAssertEqual(controller.currentLayout.documentSize.height, lastItem.frame.maxY)
                XCTAssertEqual(controller.window?.frame.height, lastItem.frame.maxY)
                XCTAssertFalse(controller.currentLayout.hasVerticalScroller)
                XCTAssertFalse(controller.currentLayout.hasHorizontalScroller)
            }
        }
    }

    func testConfiguredMinimumRowsCanLeaveBlankSpace() throws {
        var configuration = try CandidateConfiguration(
            orientation: .vertical,
            pageSize: 3,
            verticalMinimumVisibleRows: 5
        )
        configuration.allowsExpansion = false
        let candidates = [Candidate(displayString: "Only")]
        let layout = VerticalCandidateLayoutEngine.layout(
            candidates: candidates,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics,
            numberingAnchor: 0,
            scrollerStyle: .overlay
        )

        XCTAssertEqual(layout.windowSize.height, 144)
        XCTAssertEqual(layout.items.count, 1)
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
