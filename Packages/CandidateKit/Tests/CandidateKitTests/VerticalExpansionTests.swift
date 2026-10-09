import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class VerticalExpansionTests: XCTestCase {
    func testRightExpandsBeforeMovingEvenWithAdvanceOption() throws {
        let controller = makeController(count: 30, selected: 2)
        defer { controller.visible = false }
        var configuration = controller.configuration
        configuration.advancesSelectionWhenExpanding = true
        try controller.apply(configuration: configuration)
        var selections: [Int] = []
        controller.onSelectionChange = { _, index, _ in selections.append(index) }
        let firstFrame = controller.currentLayout.item(for: 2)?.frame

        XCTAssertTrue(controller.navigate(.right))
        XCTAssertTrue(controller.isExpanded)
        XCTAssertEqual(controller.selectionIndex, 2)
        XCTAssertEqual(controller.currentLayout.item(for: 2)?.frame, firstFrame)
        XCTAssertTrue(selections.isEmpty)
        XCTAssertNil(controller.currentLayout.control)

        XCTAssertTrue(controller.navigate(.right))
        XCTAssertEqual(controller.selectionIndex, 11)
        XCTAssertEqual(selections, [11])
        XCTAssertEqual(controller.currentLayout.rows.map { $0.items.count }, [9, 9, 9, 3])
        XCTAssertEqual(controller.relativeCandidateIndex(at: 0), 9)
        XCTAssertEqual(controller.relativeCandidateIndex(at: 8), 17)
        XCTAssertEqual(
            controller.currentLayout.items.filter(\.showsIndexText).map(\.candidateIndex),
            Array(9..<18))
    }

    func testColumnNavigationClampsShortFinalColumnAndCollapsesFromFirst() {
        let controller = makeController(count: 20, selected: 7)
        defer { controller.visible = false }
        XCTAssertTrue(controller.navigate(.right))
        XCTAssertTrue(controller.navigate(.right))
        XCTAssertEqual(controller.selectionIndex, 16)
        XCTAssertTrue(controller.navigate(.right))
        XCTAssertEqual(controller.selectionIndex, 19)
        XCTAssertFalse(controller.navigate(.right))
        XCTAssertTrue(controller.navigate(.left))
        XCTAssertEqual(controller.selectionIndex, 10)
        XCTAssertTrue(controller.navigate(.left))
        XCTAssertEqual(controller.selectionIndex, 1)
        XCTAssertTrue(controller.navigate(.left))
        XCTAssertFalse(controller.isExpanded)
        XCTAssertEqual(controller.selectionIndex, 1)
        XCTAssertEqual(controller.currentLayout.items.count, 9)
        XCTAssertNil(controller.currentLayout.control)
    }

    func testDownAcrossFirstColumnExpandsAndHomeEndStayInColumn() {
        let controller = makeController(count: 20, selected: 8)
        defer { controller.visible = false }
        XCTAssertTrue(controller.navigate(.down))
        XCTAssertTrue(controller.isExpanded)
        XCTAssertEqual(controller.selectionIndex, 9)
        XCTAssertTrue(controller.navigate(.end))
        XCTAssertEqual(controller.selectionIndex, 17)
        XCTAssertTrue(controller.navigate(.home))
        XCTAssertEqual(controller.selectionIndex, 9)
        XCTAssertTrue(controller.navigate(.up))
        XCTAssertEqual(controller.selectionIndex, 8)
    }

    func testHorizontalOverflowStopsAtFinalColumnWithoutTrailingGap() throws {
        for style in [NSScroller.Style.legacy, .overlay] {
            let controller = makeController(count: 80, selected: 0)
            defer { controller.visible = false }
            controller.handlePreferredScrollerStyleChange(to: style)
            XCTAssertTrue(controller.navigate(.right))
            XCTAssertTrue(controller.scrollView.hasHorizontalScroller)
            XCTAssertFalse(controller.scrollView.hasVerticalScroller)
            controller.selectedCandidateIndex = 72
            let lastColumn = try XCTUnwrap(controller.currentLayout.item(for: 72))
            XCTAssertEqual(
                controller.scrollView.contentView.bounds.maxX, lastColumn.frame.maxX, accuracy: 1)
            XCTAssertEqual(controller.currentLayout.documentSize.width, lastColumn.frame.maxX)
            XCTAssertLessThanOrEqual(
                lastColumn.frame.maxY, controller.scrollView.contentView.bounds.maxY)
            XCTAssertTrue(controller.navigate(.left))
            XCTAssertEqual(controller.selectionIndex, 63)
        }
    }

    func testPageNavigationPreservesRowAndReturnsToFirstColumn() {
        let controller = makeController(count: 100, selected: 2)
        defer { controller.visible = false }
        XCTAssertTrue(controller.navigate(.right))
        XCTAssertTrue(controller.navigate(.pageDown))
        XCTAssertEqual(controller.selectionIndex, 11)
        XCTAssertTrue(controller.navigate(.pageUp))
        XCTAssertEqual(controller.selectionIndex, 2)
        XCTAssertTrue(controller.navigate(.pageUp))
        XCTAssertFalse(controller.isExpanded)
    }

    private func makeController(count: Int, selected: Int) -> VerticalCandidateController {
        let controller = VerticalCandidateController()
        var configuration = controller.configuration
        configuration.animationDuration = 0
        try! controller.apply(configuration: configuration)
        controller.replaceCandidates(
            (0..<count).map { Candidate(displayString: "字\($0)") }, initialSelectedIndex: selected)
        controller.centerOnMainScreen()
        controller.visible = true
        return controller
    }
}
