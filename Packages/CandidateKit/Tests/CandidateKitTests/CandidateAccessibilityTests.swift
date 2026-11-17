import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateAccessibilityTests: XCTestCase {
    private func uniformCandidates(_ count: Int) -> [Candidate] {
        (0..<count).map { _ in Candidate(displayString: "天") }
    }

    func testAccessibilityIdentitySelectionAndConfirmationAcrossRebuilds() throws {
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            var configuration = CandidateConfiguration.default
            configuration.orientation = orientation
            configuration.allowsExpansion = false
            configuration.animationDuration = 0
            let controller = CandidateController(configuration: configuration)
            controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 0)
            controller.visible = true
            defer { controller.visible = false }
            let item = controller.accessibilityItems[20]
            item.setAccessibilityFocused(true)

            XCTAssertEqual(controller.selectionIndex, 20)
            XCTAssertTrue(controller.accessibilityItems[20] === item)
            XCTAssertTrue(item.isAccessibilitySelected())
            XCTAssertTrue(
                (controller.canvasView.accessibilitySelectedChildren()?.first
                    as? CandidateAccessibilityItem) === item)
            XCTAssertTrue(
                controller.scrollView.documentVisibleRect.intersects(
                    try XCTUnwrap(controller.currentLayout.item(for: 20)).frame))

            let view = try XCTUnwrap(controller.renderer[20])
            let window = try XCTUnwrap(controller.window)
            XCTAssertEqual(
                item.accessibilityFrame(),
                window.convertToScreen(view.convert(view.bounds, to: nil)))
            var confirmed: Int?
            controller.onConfirmation = { index, _ in confirmed = index }
            XCTAssertTrue(item.accessibilityPerformPress())
            XCTAssertEqual(confirmed, 20)

            controller.replaceCandidates([Candidate(displayString: "新")], initialSelectedIndex: 0)
            XCTAssertFalse(item.accessibilityPerformPress())
            controller.visible = false
            XCTAssertTrue(controller.canvasView.accessibilityVisibleChildren()?.isEmpty == true)
            XCTAssertFalse(controller.accessibilityItems[0].accessibilityPerformPress())
        }
    }

    func testAccessibilityVisibleChildrenAndPageActions() throws {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false
        configuration.animationDuration = 0
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(100), initialSelectedIndex: 0)
        controller.visible = true
        defer { controller.visible = false }

        let actions = try XCTUnwrap(controller.canvasView.accessibilityCustomActions())
        XCTAssertEqual(
            actions.map(\.name),
            ["Previous Page", "Next Page"].map {
                Bundle.module.localizedString(forKey: $0, value: nil, table: nil)
            })
        XCTAssertEqual(controller.canvasView.accessibilityChildren()?.count, 100)
        XCTAssertLessThan(
            try XCTUnwrap(controller.canvasView.accessibilityVisibleChildren()).count, 100)

        XCTAssertTrue(actions[1].handler?() == true)
        XCTAssertEqual(controller.selectionIndex, 9)
        XCTAssertTrue(actions[0].handler?() == true)
        XCTAssertEqual(controller.selectionIndex, 0)
        XCTAssertFalse(controller.isExpanded)
    }

    func testActionHintUsesDetailWithoutReplacingAccessibilityReading() throws {
        let delegate = SpokenCandidateDelegate()
        delegate.detail = "⇧ ⏎"
        let controller = CandidateController()
        controller.keyLabels = []
        controller.delegate = delegate
        controller.reloadData()
        controller.visible = true
        defer { controller.visible = false }
        XCTAssertEqual(controller.renderer[0]?.detailText, "⇧ ⏎")
        XCTAssertEqual(controller.accessibilityItems[0].accessibilityLabel(), "中間的中")
        XCTAssertEqual(controller.accessibilityItems[0].accessibilityHelp(), "中")
    }
}

@MainActor
private final class SpokenCandidateDelegate: NSObject, CandidateControllerDelegate {
    var explanationRequests = 0
    var detail: String?
    func candidateCountForController(_ controller: CandidateController) -> UInt { 1 }
    func candidateController(_ controller: CandidateController, candidateAtIndex index: UInt)
        -> String
    {
        "中"
    }
    func candidateController(_ controller: CandidateController, detailAtIndex index: UInt)
        -> String?
    {
        detail
    }
    func candidateController(
        _ controller: CandidateController, accessibilityReadingAtIndex index: UInt
    ) -> String? {
        "ㄓㄨㄥ"
    }
    func candidateController(
        _ controller: CandidateController, requestExplanationFor candidate: String, reading: String
    ) -> String? {
        explanationRequests += 1
        XCTAssertEqual(reading, "ㄓㄨㄥ")
        return "中間的中"
    }
    func candidateController(
        _ controller: CandidateController, didSelectCandidateAtIndex index: UInt
    ) {}
}
