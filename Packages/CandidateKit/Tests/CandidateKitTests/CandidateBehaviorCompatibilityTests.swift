import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateBehaviorCompatibilityTests: XCTestCase {
    func testCrossRowSelectionPreservesOverlapInsteadOfNearestCenter() {
        let row = CandidateLayoutRow(items: [
            item(1, x: 0, width: 25), item(2, x: 25, width: 75),
        ])
        XCTAssertEqual(row.candidatePreservingInterval(20...100, movingBackward: false), 1)
        XCTAssertEqual(row.candidatePreservingInterval(20...100, movingBackward: true), 2)
        XCTAssertEqual(row.candidatePreservingInterval(nil, movingBackward: true), 1)
        XCTAssertEqual(row.candidatePreservingInterval(110...120, movingBackward: false), 2)
    }

    func testVerticalPageCallbackSeesUpdatedViewport() throws {
        let configuration = try CandidateConfiguration(
            orientation: .vertical, allowsExpansion: false,
            animationDuration: 0)
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(
            (0..<30).map { _ in Candidate(displayString: "字") },
            initialSelectedIndex: 3)
        controller.visible = true
        defer { controller.visible = false }
        var observations: [(Int, CGFloat, Int)] = []
        controller.onSelectionChange = { [weak controller] _, index, _ in
            guard let controller else { return }
            observations.append(
                (
                    index, controller.scrollView.contentView.bounds.minY,
                    controller.verticalNumberingAnchor
                ))
        }
        XCTAssertTrue(controller.navigate(.pageDown))
        XCTAssertEqual(observations.count, 1)
        XCTAssertEqual(observations.first?.0, 12)
        XCTAssertEqual(observations.first?.1, 261)
        XCTAssertEqual(observations.first?.2, 9)
    }

    private func item(_ index: Int, x: CGFloat, y: CGFloat = 0, width: CGFloat)
        -> CandidateLayoutItem
    {
        CandidateLayoutItem(
            candidateIndex: index, frame: NSRect(x: x, y: y, width: width, height: 28),
            indexText: "", showsIndexText: false, showsDetail: false, alignedCandidateWidth: nil)
    }

    func testVerticalPagingClampsSelectionAndRejectsSinglePage() throws {
        let configuration = try CandidateConfiguration(
            orientation: .vertical, allowsExpansion: false,
            indexLabels: "asdf", pageSize: 4, animationDuration: 0)
        for count in [3, 4, 10] {
            let controller = CandidateController(configuration: configuration)
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
}
