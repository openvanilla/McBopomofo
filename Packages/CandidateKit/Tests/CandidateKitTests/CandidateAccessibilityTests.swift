import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateAccessibilityTests: XCTestCase {
    private func uniformCandidates(_ count: Int) -> [Candidate] {
        (0..<count).map { _ in Candidate(displayString: "天") }
    }

    func testAccessibilityActionLocalizations() throws {
        let translations = [
            "Expand": "展開", "Collapse": "收合", "Previous Page": "上一頁", "Next Page": "下一頁",
        ]
        for language in ["en", "zh-Hant"] {
            let localization = try XCTUnwrap(Bundle.module.localizations.first {
                $0.caseInsensitiveCompare(language) == .orderedSame
            })
            let path = try XCTUnwrap(Bundle.module.path(forResource: localization, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            for (key, translation) in translations {
                XCTAssertEqual(bundle.localizedString(forKey: key, value: nil, table: nil),
                               language == "en" ? key : translation)
            }
        }
    }

    func testTooltipReservesHeaderWithoutChangingViewportHeight() throws {
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            for expandable in [false, true] {
                var configuration = CandidateConfiguration.default
                configuration.orientation = orientation
                configuration.allowsExpansion = expandable
                configuration.animationDuration = 0
                let controller = CandidateController(configuration: configuration)
                controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 0)
                controller.visible = true
                defer { controller.visible = false }
                let initialSize = controller.currentLayout.windowSize
                controller.tooltip = "聯想詞"
                controller.backdropView.layoutSubtreeIfNeeded()

                XCTAssertEqual(controller.contentView.titleView.stringValue, "聯想詞")
                XCTAssertFalse(controller.contentView.titleView.isHidden)
                XCTAssertGreaterThan(controller.currentLayout.headerHeight, 0)
                XCTAssertEqual(controller.currentLayout.viewportSize.height, initialSize.height)
                XCTAssertEqual(controller.scrollView.frame.maxY, controller.currentLayout.viewportSize.height)
                XCTAssertGreaterThanOrEqual(controller.contentView.titleView.frame.minY, controller.scrollView.frame.maxY)
                XCTAssertTrue(controller.contentView.bounds.contains(controller.contentView.titleView.frame))

                controller.selectedCandidateIndex = 29
                controller.finishFrameTransition()
                controller.backdropView.layoutSubtreeIfNeeded()
                let last = try XCTUnwrap(controller.currentLayout.item(for: 29))
                XCTAssertTrue(controller.scrollView.documentVisibleRect.intersects(last.frame))
                XCTAssertEqual(controller.currentLayout.viewportSize.height, controller.scrollView.frame.height)
                if controller.currentLayout.hasVerticalScroller {
                    XCTAssertEqual(controller.scrollView.documentVisibleRect.maxY, last.frame.maxY, accuracy: 1)
                }

                controller.selectedCandidateIndex = 0
                if controller.isExpanded { controller.collapseExpandable() }
                controller.finishFrameTransition()
                controller.tooltip = ""
                XCTAssertTrue(controller.contentView.titleView.isHidden)
                XCTAssertEqual(controller.currentLayout.windowSize.height, initialSize.height)
            }
        }
    }

    func testAccessibilityIdentitySelectionAndConfirmationAcrossRebuilds() throws {
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            var configuration = CandidateConfiguration.default
            configuration.orientation = orientation
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
            XCTAssertTrue((controller.canvasView.accessibilitySelectedChildren()?.first as? CandidateAccessibilityItem) === item)
            XCTAssertTrue(controller.scrollView.documentVisibleRect.intersects(try XCTUnwrap(controller.currentLayout.item(for: 20)).frame))

            let view = try XCTUnwrap(controller.renderer[20])
            let window = try XCTUnwrap(controller.window)
            XCTAssertEqual(item.accessibilityFrame(), window.convertToScreen(view.convert(view.bounds, to: nil)))
            var confirmed: Int?
            controller.onConfirmation = { _, index, _ in confirmed = index }
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
        configuration.animationDuration = 0
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(100), initialSelectedIndex: 0)
        controller.visible = true
        defer { controller.visible = false }

        let actions = try XCTUnwrap(controller.canvasView.accessibilityCustomActions())
        XCTAssertEqual(actions.map(\.name), ["Expand", "Previous Page", "Next Page"].map {
            Bundle.module.localizedString(forKey: $0, value: nil, table: nil)
        })
        XCTAssertTrue(actions[0].handler?() == true)
        XCTAssertTrue(controller.isExpanded)
        XCTAssertNil(controller.renderedControlView)
        XCTAssertEqual(controller.canvasView.accessibilityChildren()?.count, 100)
        XCTAssertLessThan(try XCTUnwrap(controller.canvasView.accessibilityVisibleChildren()).count, 100)

        let expandedActions = try XCTUnwrap(controller.canvasView.accessibilityCustomActions())
        XCTAssertEqual(expandedActions[0].name,
                       Bundle.module.localizedString(forKey: "Collapse", value: nil, table: nil))
        XCTAssertTrue(expandedActions.last?.handler?() == true)
        XCTAssertEqual(controller.selectionIndex, 9)
        XCTAssertTrue(expandedActions[1].handler?() == true)
        XCTAssertEqual(controller.selectionIndex, 0)
        XCTAssertTrue(expandedActions[0].handler?() == true)
        XCTAssertFalse(controller.isExpanded)
    }

    func testActionHintUsesDetailWithoutReplacingAccessibilityReading() throws {
        let delegate = SpokenCandidateDelegate()
        delegate.detail = "⇧ ⏎"
        let configuration = try CandidateConfiguration(indexLabels: "")
        let controller = CandidateController(configuration: configuration)
        controller.delegate = delegate
        controller.reloadData()
        controller.visible = true
        defer { controller.visible = false }
        XCTAssertTrue(controller.keyLabels.isEmpty)
        XCTAssertEqual(controller.renderer[0]?.detailText, "⇧ ⏎")
        XCTAssertEqual(controller.accessibilityItems[0].accessibilityLabel(), "中間的中")
        XCTAssertEqual(controller.accessibilityItems[0].accessibilityHelp(), "ㄓㄨㄥ")
    }

}

@MainActor
private final class SpokenCandidateDelegate: NSObject, CandidateControllerDelegate {
    var explanationRequests = 0
    var detail: String?
    func candidateCountForController(_ controller: CandidateController) -> UInt { 1 }
    func candidateController(_ controller: CandidateController, candidateAtIndex index: UInt) -> String { "中" }
    func candidateController(_ controller: CandidateController, readingAtIndex index: UInt) -> String? { detail }
    func candidateController(_ controller: CandidateController, accessibilityReadingAtIndex index: UInt) -> String? { "ㄓㄨㄥ" }
    func candidateController(_ controller: CandidateController, requestExplanationFor candidate: String, reading: String) -> String? {
        explanationRequests += 1
        XCTAssertEqual(reading, "ㄓㄨㄥ")
        return "中間的中"
    }
    func candidateController(_ controller: CandidateController, didSelectCandidateAtIndex index: UInt) {}
}
