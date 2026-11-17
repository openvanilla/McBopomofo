import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class VerticalCandidateControllerTests: XCTestCase {
    func testLongCandidatesUseScreenWidthInsteadOfFixedEmLimit() throws {
        let configuration = CandidateConfiguration(orientation: .vertical)
        for characterCount in [40, 100] {
            let candidate = Candidate(displayString: String(repeating: "永", count: characterCount))
            let metrics = defaultMetrics
            let layout = VerticalCandidateLayoutEngine.expandableLayout(
                candidates: [candidate], keyLabels: defaultKeyLabels,
                configuration: configuration, metrics: metrics, selectedIndex: 0,
                expanded: false, scrollerStyle: .overlay, maximumWidth: 1024)
            let naturalWidth =
                metrics.intrinsicWidth(for: candidate, showsIndexColumn: true)
                + metrics.candidateFont.pointSize * CandidateStyle.Spacing.opticalTrailingEm
            XCTAssertEqual(layout.windowSize.width, min(naturalWidth, 1024))
        }
    }

    func testHeightLimitFitsWholeRows() throws {
        let configuration = CandidateConfiguration(orientation: .vertical)
        let candidates = (0..<20).map { _ in Candidate(displayString: "字") }
        for (height, expectedRows) in [(28.0, 1), (85.0, 2), (86.0, 3), (260.0, 9), (347.0, 9)] {
            let layout = VerticalCandidateLayoutEngine.layout(
                candidates: candidates, keyLabels: defaultKeyLabels,
                configuration: configuration, metrics: defaultMetrics, numberingAnchor: 0,
                scrollerStyle: .overlay, maximumHeight: height)
            XCTAssertEqual(layout.pageSize, expectedRows)
            XCTAssertEqual(layout.windowSize.height, CGFloat(expectedRows) * 29 - 1)
            XCTAssertLessThanOrEqual(layout.windowSize.height, height)
        }
    }

    func testScreenHeightUpdatesPagingNumberingAndExpansion() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        for expandable in [false, true] {
            for style: NSScroller.Style in [.overlay, .legacy] {
                let configuration = CandidateConfiguration(
                    orientation: .vertical, allowsExpansion: expandable, animationDuration: 0,
                    verticalMaximumVisibleColumns: 2)
                let controller = CandidateController(configuration: configuration)
                controller.candidateFont = .systemFont(ofSize: floor(bounds.height / 7))
                controller.scrollView.scrollerStyle = style
                controller.tooltip = "提示"
                controller.replaceCandidates(
                    (0..<45).map { _ in Candidate(displayString: "字") }, initialSelectedIndex: 0)
                controller.show(near: NSRect(x: bounds.midX, y: bounds.midY, width: 10, height: 20))
                defer { controller.visible = false }
                let pageSize = controller.effectivePageSize
                XCTAssertGreaterThan(pageSize, 0)
                XCTAssertLessThan(pageSize, configuration.pageSize)
                XCTAssertEqual(controller.configuration.pageSize, 9)
                XCTAssertLessThanOrEqual(controller.currentLayout.windowSize.height, bounds.height)
                XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(UInt(pageSize)), UInt.max)
                XCTAssertNil(
                    controller.candidateIndex(forIndexLabel: Character(String(pageSize + 1))))

                if expandable {
                    XCTAssertTrue(controller.navigate(.right))
                    XCTAssertTrue(controller.isExpanded)
                    XCTAssertEqual(controller.effectivePageSize, pageSize)
                    XCTAssertEqual(
                        controller.currentLayout.items.filter { $0.frame.minX == 0 }.count,
                        pageSize)
                    XCTAssertTrue(controller.navigate(.right))
                } else {
                    XCTAssertTrue(controller.navigate(.pageDown))
                    XCTAssertEqual(controller.verticalNumberingAnchor, pageSize)
                }
                XCTAssertEqual(controller.selectionIndex, pageSize)
                for slot in 0..<pageSize {
                    XCTAssertEqual(
                        controller.candidateIndexAtKeyLabelIndex(UInt(slot)), UInt(pageSize + slot))
                    XCTAssertEqual(
                        controller.renderer[pageSize + slot]?.indexText, String(slot + 1))
                }
                var confirmedIndex: Int?
                controller.onConfirmation = { index, _ in confirmedIndex = index }
                XCTAssertTrue(
                    controller.commitCandidate(matchingIndexLabel: Character(String(pageSize))))
                XCTAssertEqual(confirmedIndex, pageSize * 2 - 1)

                controller.candidateFont = .systemFont(ofSize: 16)
                XCTAssertEqual(controller.effectivePageSize, 9)
            }
        }
    }

    func testLegacyScrollerSpaceIsReservedBeforeExpansion() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        let configuration = CandidateConfiguration(
            orientation: .vertical, animationDuration: 0, verticalMaximumVisibleColumns: 1)
        let controller = CandidateController(configuration: configuration)
        controller.candidateFont = .systemFont(ofSize: floor((bounds.height - 2) / 5.25))
        controller.scrollView.scrollerStyle = .overlay
        controller.replaceCandidates(
            (0..<30).map { _ in Candidate(displayString: "字") }, initialSelectedIndex: 0)
        // Measure against the main screen rather than whichever screen the hidden window reports.
        controller.centerOnMainScreen()
        controller.visible = true
        defer { controller.visible = false }
        let overlayRows = controller.effectivePageSize
        controller.handlePreferredScrollerStyleChange(to: .legacy)
        let legacyRows = controller.effectivePageSize
        XCTAssertLessThan(legacyRows, overlayRows)
        XCTAssertTrue(controller.navigate(.right))
        XCTAssertEqual(controller.effectivePageSize, legacyRows)
        XCTAssertTrue(controller.currentLayout.hasHorizontalScroller)
        XCTAssertLessThanOrEqual(controller.currentLayout.windowSize.height, bounds.height)
        controller.handlePreferredScrollerStyleChange(to: .overlay)
        XCTAssertEqual(controller.effectivePageSize, overlayRows)
    }

    func testDefaultOverflowHeightFitsExactlyNineRows() {
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
        XCTAssertEqual(layout.windowSize.height, 260, accuracy: 0.000_001)
        XCTAssertEqual(layout.windowSize.height, layout.items[8].frame.maxY)
        XCTAssertGreaterThan(layout.items[9].frame.minY, layout.windowSize.height)
        XCTAssertEqual(layout.documentSize.height, layout.items.last?.frame.maxY)
        XCTAssertEqual(
            layout.items.prefix(9).map(\.indexText),
            [
                "1", "2", "3", "4", "5", "6", "7", "8", "9",
            ])
        XCTAssertEqual(layout.items[9].indexText, "")
    }

    func testExpandableLayoutFitsWholeRowsAndColumns() throws {
        for fontSize: CGFloat in [16, 24, 32] {
            let metrics = CandidateMetrics(
                requestedCandidateFont: .systemFont(ofSize: fontSize),
                requestedIndexFont: .systemFont(ofSize: 8)
            )
            for scrollerStyle: NSScroller.Style in [.overlay, .legacy] {
                for expanded in [false, true] {
                    let configuration = CandidateConfiguration(
                        orientation: .vertical, verticalMaximumVisibleColumns: 2)
                    let candidates = (0..<28).map {
                        Candidate(displayString: String(repeating: "字", count: $0 / 9 + 1))
                    }
                    let layout = VerticalCandidateLayoutEngine.expandableLayout(
                        candidates: candidates, keyLabels: defaultKeyLabels,
                        configuration: configuration, metrics: metrics, selectedIndex: 0,
                        expanded: expanded, scrollerStyle: scrollerStyle)
                    let visibleColumns = expanded ? 2 : 1
                    let lastVisibleItem = try XCTUnwrap(
                        layout.item(for: visibleColumns * configuration.pageSize - 1))
                    let scrollerHeight =
                        expanded && scrollerStyle == .legacy
                        ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: scrollerStyle) : 0

                    XCTAssertEqual(layout.windowSize.width, lastVisibleItem.frame.maxX)
                    XCTAssertEqual(
                        layout.windowSize.height, lastVisibleItem.frame.maxY + scrollerHeight)
                    XCTAssertEqual(layout.hasHorizontalScroller, expanded)
                    XCTAssertFalse(layout.hasVerticalScroller)
                    if expanded {
                        let firstHiddenItem = try XCTUnwrap(
                            layout.item(for: visibleColumns * configuration.pageSize))
                        XCTAssertGreaterThan(firstHiddenItem.frame.minX, layout.windowSize.width)
                    }
                }
            }
        }
    }

    func testSelectionScrollDoesNotRevealAnExtraPartialRowOrColumn() throws {
        for expandable in [false, true] {
            for scrollerStyle: NSScroller.Style in [.overlay, .legacy] {
                let configuration = CandidateConfiguration(
                    orientation: .vertical, allowsExpansion: expandable,
                    verticalMaximumVisibleColumns: 2)
                let controller = CandidateController(configuration: configuration)
                controller.scrollView.scrollerStyle = scrollerStyle
                controller.replaceCandidates(
                    (0..<45).map { _ in Candidate(displayString: "字") }, initialSelectedIndex: 0)
                controller.centerOnMainScreen()
                controller.visible = true
                defer { controller.visible = false }
                if expandable {
                    XCTAssertTrue(controller.navigate(.right))
                    controller.finishFrameTransition()
                }
                let lastVisibleIndex = expandable ? 17 : 8
                controller.selectedCandidateIndex = UInt(lastVisibleIndex)
                XCTAssertEqual(controller.scrollView.contentView.bounds.origin, .zero)

                controller.selectedCandidateIndex = UInt(lastVisibleIndex + 1)
                let selectedItem = try XCTUnwrap(
                    controller.currentLayout.item(for: lastVisibleIndex + 1))
                let viewport = controller.scrollView.contentView.bounds
                if expandable {
                    XCTAssertEqual(viewport.maxX, selectedItem.frame.maxX)
                    let secondColumnFirstItem = controller.currentLayout.item(
                        for: configuration.pageSize)
                    XCTAssertEqual(viewport.minX, secondColumnFirstItem?.frame.minX)
                } else {
                    XCTAssertEqual(viewport.maxY, selectedItem.frame.maxY)
                    XCTAssertEqual(viewport.minY, controller.currentLayout.items[1].frame.minY)
                }
            }
        }
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
                controller.centerOnMainScreen()
                controller.visible = true
                defer { controller.visible = false }

                let lastItem = try XCTUnwrap(controller.currentLayout.items.last)
                XCTAssertEqual(controller.currentLayout.windowSize.height, lastItem.frame.maxY)
                XCTAssertEqual(controller.currentLayout.documentSize.height, lastItem.frame.maxY)
                XCTAssertEqual(controller.window?.frame.height, lastItem.frame.maxY)
                XCTAssertFalse(controller.currentLayout.hasVerticalScroller)
                XCTAssertFalse(controller.currentLayout.hasHorizontalScroller)
            }
        }
    }

    func testVerticalPagingClampsSelectionAndRejectsSinglePage() throws {
        let configuration = CandidateConfiguration(
            orientation: .vertical, allowsExpansion: false, pageSize: 4, animationDuration: 0)
        for count in [3, 4, 10] {
            let controller = CandidateController(configuration: configuration)
            controller.keyLabels = "asdf".map {
                CandidateKeyLabel(key: String($0), displayedText: String($0))
            }
            controller.replaceCandidates(
                (0..<count).map { _ in Candidate(displayString: "字") },
                initialSelectedIndex: 2)
            controller.visible = true
            defer { controller.visible = false }
            if count <= 4 {
                XCTAssertFalse(controller.showNextPage())
                XCTAssertFalse(controller.showPreviousPage())
                XCTAssertEqual(controller.selectionIndex, 2)
            } else {
                XCTAssertTrue(controller.showNextPage())
                XCTAssertEqual(controller.selectionIndex, 6)
                XCTAssertTrue(controller.showNextPage())
                XCTAssertEqual(controller.selectionIndex, 9)
                XCTAssertFalse(controller.showNextPage())
                XCTAssertTrue(controller.showPreviousPage())
                XCTAssertEqual(controller.selectionIndex, 5)
                XCTAssertTrue(controller.showPreviousPage())
                XCTAssertEqual(controller.selectionIndex, 1)
                XCTAssertTrue(controller.showPreviousPage())
                XCTAssertEqual(controller.selectionIndex, 0)
                XCTAssertFalse(controller.showPreviousPage())
            }
        }
    }

    func testSelectionBeyondFirstColumnIsExpandedVisibleAndNumbered() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        for (columns, longIndex) in [(5, 54), (1, 72)] {
            for restoresAfterShow in [false, true] {
                let controller = CandidateController(
                    configuration: CandidateConfiguration(
                        orientation: .vertical, animationDuration: 10,
                        verticalMaximumVisibleColumns: columns))
                controller.scrollView.scrollerStyle = .overlay
                // Returning from a dictionary menu reloads from index zero, shows the window,
                // then restores the previous selection. Otherwise the list is shown with the
                // selection already beyond the first column.
                controller.replaceCandidates(
                    (0..<90).map {
                        Candidate(
                            displayString: $0 == longIndex
                                ? String(repeating: "長", count: 20) : "候選\($0)")
                    }, initialSelectedIndex: restoresAfterShow ? 0 : 76)
                controller.show(
                    near: NSRect(x: bounds.midX, y: bounds.midY, width: 10, height: 20))
                if restoresAfterShow {
                    controller.selectedCandidateIndex = 76
                }
                defer { controller.visible = false }

                XCTAssertTrue(controller.isExpanded)
                XCTAssertFalse(controller.isFrameTransitionActive)
                let selected = try XCTUnwrap(controller.currentLayout.item(for: 76))
                XCTAssertTrue(controller.scrollView.documentVisibleRect.contains(selected.frame))
                XCTAssertEqual(controller.selectionIndex, 76)
                XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(4), 76)
            }
        }
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
