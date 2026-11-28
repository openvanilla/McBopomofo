import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class VerticalExpansionTests: XCTestCase {
    func testWideLaterColumnIsFullyVisibleAndScrollingIsStable() throws {
        for style: NSScroller.Style in [.overlay, .legacy] {
            for length in [40, 300] {
                let controller = makeController(count: 54, selected: 0)
                defer { controller.visible = false }
                controller.handlePreferredScrollerStyleChange(to: style)
                controller.replaceCandidates(
                    (0..<54).map {
                        Candidate(
                            displayString: String(repeating: "字", count: $0 < 45 ? 2 : length))
                    }, initialSelectedIndex: 0)
                XCTAssertTrue(controller.navigate(.right))
                let initialWidth = controller.currentLayout.windowSize.width
                controller.selectedCandidateIndex = 45

                let item = try XCTUnwrap(controller.currentLayout.item(for: 45))
                let viewport = controller.scrollView.documentVisibleRect
                XCTAssertGreaterThan(controller.currentLayout.windowSize.width, initialWidth)
                XCTAssertLessThanOrEqual(
                    controller.currentLayout.windowSize.width, controller.layoutAvailableWidth)
                XCTAssertTrue(viewport.contains(item.frame))
                XCTAssertEqual(controller.renderer[45]?.frame, item.frame)
                XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(0), 45)
                controller.ensureSelectionVisible()
                XCTAssertEqual(controller.scrollView.documentVisibleRect, viewport)
            }
        }
    }

    func testRightExpandsBeforeMoving() throws {
        let controller = makeController(count: 30, selected: 2)
        defer { controller.visible = false }
        var selections: [Int] = []
        controller.onSelectionChange = { index, _ in selections.append(index) }
        let firstFrame = controller.currentLayout.item(for: 2)?.frame

        XCTAssertTrue(controller.navigate(.right))
        XCTAssertTrue(controller.isExpanded)
        XCTAssertEqual(controller.selectionIndex, 2)
        XCTAssertEqual(controller.currentLayout.item(for: 2)?.frame, firstFrame)
        XCTAssertTrue(selections.isEmpty)

        XCTAssertTrue(controller.navigate(.right))
        XCTAssertEqual(controller.selectionIndex, 11)
        XCTAssertEqual(selections, [11])
        XCTAssertEqual(Set(controller.currentLayout.items.map(\.frame.minX)).count, 4)
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
        controller.apply(configuration: configuration)
        controller.replaceCandidates(
            (0..<count).map { Candidate(displayString: "字\($0)") }, initialSelectedIndex: selected)
        controller.centerOnMainScreen()
        controller.visible = true
        return controller
    }
}
