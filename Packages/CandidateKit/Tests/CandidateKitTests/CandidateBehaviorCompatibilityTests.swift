import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateBehaviorCompatibilityTests: XCTestCase {
    func testCrossColumnSelectionPreservesOverlapInsteadOfNearestCenter() {
        let row = CandidateLayoutRow(items: [
            item(1, y: 0, height: 25), item(2, y: 25, height: 75),
        ])
        XCTAssertEqual(row.candidatePreservingInterval(20...100), 1)
        XCTAssertEqual(row.candidatePreservingInterval(nil), 1)
        XCTAssertEqual(row.candidatePreservingInterval(110...120), 2)
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

    private func item(
        _ index: Int, y: CGFloat, height: CGFloat
    ) -> CandidateLayoutItem {
        CandidateLayoutItem(
            candidateIndex: index, frame: NSRect(x: 0, y: y, width: 28, height: height),
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
