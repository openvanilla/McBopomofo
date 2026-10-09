import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateReconfigurationTests: XCTestCase {
    func testShortcutHintsFollowKeysInDetailAcrossLayouts() throws {
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            for expandable in [false, true] {
                let configuration = try CandidateConfiguration(
                    orientation: orientation, allowsExpansion: expandable, indexLabels: "123",
                    pageSize: 3, showsKeyLabelsAsDetails: true, animationDuration: 0)
                let controller = CandidateController(configuration: configuration)
                controller.keyLabels = ["1", "2", "3"].map {
                    CandidateKeyLabel(key: $0, displayedText: "⇧ " + $0)
                }
                controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 0)
                controller.visible = true
                defer { controller.visible = false }
                for size: CGFloat in [12, 16, 32] {
                    controller.candidateFont = .systemFont(ofSize: size)
                    XCTAssertEqual(controller.metrics.indexSlotWidth, controller.metrics.indexFont.pointSize + 2)
                    XCTAssertEqual(controller.metrics.baseCellWidth(showsIndexColumn: true),
                        controller.metrics.baseCellWidth(showsIndexColumn: false))
                    for selection in [0, 2, 4, 10, 29] {
                        controller.selectedCandidateIndex = UInt(selection)
                        var hintedIndexes = Set<Int>()
                        for slot in 0..<3 {
                            let index = controller.candidateIndexAtKeyLabelIndex(UInt(slot))
                            guard index != UInt.max else { continue }
                            hintedIndexes.insert(Int(index))
                            let view = try XCTUnwrap(controller.renderer[Int(index)])
                            XCTAssertEqual(view.detailText, "⇧ \(slot + 1)")
                            var confirmedIndex: Int?
                            controller.onConfirmation = { _, index, _ in confirmedIndex = index }
                            XCTAssertTrue(controller.commitCandidate(matchingIndexLabel: Character(String(slot + 1))))
                            XCTAssertEqual(confirmedIndex, Int(index))
                        }
                        for view in controller.renderer.itemViews where !hintedIndexes.contains(view.candidateIndex) {
                            XCTAssertNil(view.detailText)
                        }
                    }
                }
            }
        }
    }

    func testSelectionKeyChangesUpdateRenderedLabelsAndPageMapping() throws {
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

                for keys in ["asdf", "123456789", "asdfzxcvb"] {
                    configuration.indexLabels = keys
                    configuration.pageSize = keys.count
                    try controller.apply(configuration: configuration)
                    controller.selectedCandidateIndex = 0
                    XCTAssertTrue(controller.showNextPage())
                    let expectedLabels = Array(keys).map(String.init)
                    for (offset, label) in expectedLabels.enumerated() {
                        let index = controller.candidateIndexAtKeyLabelIndex(UInt(offset))
                        guard index != UInt.max else { continue }
                        let view = try XCTUnwrap(controller.renderer[Int(index)])
                        XCTAssertEqual(view.indexText, label)
                        XCTAssertTrue(view.showsIndexText)
                        var confirmedIndex: Int?
                        controller.onConfirmation = { _, index, _ in confirmedIndex = index }
                        XCTAssertTrue(controller.commitCandidate(matchingIndexLabel: Character(label)))
                        XCTAssertEqual(confirmedIndex, Int(index))
                    }
                }
            }
        }
    }

    func testBothReplacementPathsPublishOnlyTheFinalSelectionAndLayout() throws {
        for combined in [false, true] {
            let controller = VerticalCandidateController()
            controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 20)
            controller.visible = true
            defer { controller.visible = false }
            var selections: [Int] = []
            controller.onSelectionChange = { [weak controller] _, index, candidate in
                guard let controller else { return }
                selections.append(index)
                XCTAssertEqual(index, 23)
                XCTAssertTrue(candidate === controller.candidates[index])
                XCTAssertTrue(controller.scrollView.documentVisibleRect.intersects(
                    controller.currentLayout.item(for: index)!.frame))
            }
            let replacement = uniformCandidates(24)
            if combined {
                try controller.replaceCandidates(replacement, initialSelectedIndex: 23,
                    applying: controller.configuration)
            } else {
                controller.replaceCandidates(replacement, initialSelectedIndex: 23)
            }
            XCTAssertEqual(selections, [23])
            XCTAssertEqual(controller.inputCandidates.count, 24)
            XCTAssertEqual(controller.candidates.count, 24)
        }
    }

    func testHiddenPanelMigrationPreservesSelectionAndVisibility() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 12)
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false

        try controller.apply(configuration: configuration)

        XCTAssertEqual(controller.panelKind, .vertical)
        XCTAssertEqual(controller.selectionIndex, 12)
        XCTAssertFalse(controller.visible)
    }

    func testVisiblePanelMigrationPreservesSelectionAndReanchors() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 12)
        let visibleFrame = try XCTUnwrap(NSScreen.main?.visibleFrame)
        let anchor = NSRect(x: visibleFrame.midX, y: visibleFrame.midY, width: 20, height: 20)
        controller.show(near: anchor)
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false

        try controller.apply(configuration: configuration)
        controller.finishFrameTransition()

        XCTAssertTrue(controller.visible)
        XCTAssertEqual(controller.panelKind, .vertical)
        XCTAssertEqual(controller.selectionIndex, 12)
        let placementContext = try XCTUnwrap(controller.lastPlacementContext)
        let expected = controller.placementResult(
            for: controller.currentLayout.windowSize,
            context: placementContext
        )
        let window = try XCTUnwrap(controller.window)
        let devicePixelTolerance = 1 / window.backingScaleFactor
        XCTAssertEqual(window.frame.minX, expected.topLeft.x, accuracy: devicePixelTolerance)
        XCTAssertEqual(window.frame.maxY, expected.topLeft.y, accuracy: devicePixelTolerance)
        controller.visible = false
    }

    func testSuspendedSelectionSurvivesVisiblePanelMigration() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(20), initialSelectedIndex: -1)
        controller.centerOnMainScreen()
        controller.visible = true
        var configuration = CandidateConfiguration.default
        configuration.allowsExpansion = false

        try controller.apply(configuration: configuration)

        XCTAssertTrue(controller.visible)
        XCTAssertEqual(controller.panelKind, .horizontalPaged)
        XCTAssertEqual(controller.selectionIndex, -1)
        controller.visible = false
    }

    func testCombinedConfigurationAndCandidateUpdateBuildsFinalVisibleState() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(20), initialSelectedIndex: 5)
        controller.centerOnMainScreen()
        controller.visible = true
        let windowNumber = controller.window?.windowNumber
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false
        configuration.pageSize = 3
        let replacement = [
            Candidate(displayString: "甲"),
            Candidate(displayString: "乙"),
            Candidate(displayString: "丙"),
            Candidate(displayString: "丁"),
        ]

        try controller.replaceCandidates(
            replacement,
            initialSelectedIndex: 3,
            applying: configuration
        )

        XCTAssertTrue(controller.visible)
        XCTAssertEqual(controller.window?.windowNumber, windowNumber)
        XCTAssertEqual(controller.panelKind, .vertical)
        XCTAssertEqual(controller.candidates.map(\.displayString), ["甲", "乙", "丙", "丁"])
        XCTAssertEqual(controller.selectionIndex, 3)
        XCTAssertEqual(controller.currentLayout.items.count, 4)
        controller.visible = false
    }

    func testLayoutConfigurationAndPublicFontPropertiesRecomputeGeometry() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(80), initialSelectedIndex: 0)
        let originalItemHeight = controller.metrics.itemHeight
        controller.candidateFont = .systemFont(ofSize: 20)
        XCTAssertGreaterThan(controller.metrics.itemHeight, originalItemHeight)
        XCTAssertEqual(
            controller.currentLayout.items.first?.frame.height, controller.metrics.itemHeight)

        controller.keyLabels = []
        XCTAssertTrue(controller.configuration.indexLabels.isEmpty)
        XCTAssertTrue(controller.currentLayout.items.allSatisfy { !$0.showsIndexText })

        var configuration = controller.configuration
        configuration.pageSize = 3
        configuration.usesWideExpandedCells = false
        configuration.horizontalMaximumVisibleRows = 2
        configuration.advancesSelectionWhenExpanding = true
        configuration.verticalMinimumVisibleRows = 4
        configuration.hostHandlesNavigationKeys = false
        configuration.hostHandlesIndexLabelKeys = false
        try controller.apply(configuration: configuration)

        XCTAssertEqual(controller.configuration, configuration)
        XCTAssertEqual(controller.metrics.itemHeight, 35)
        XCTAssertEqual(controller.currentLayout.windowSize, controller.window?.frame.size)
    }

    func testVerticalScrollerStyleChangeResetsViewportButPreservesSelection() {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(40), initialSelectedIndex: 20)
        controller.scrollView.contentView.scroll(to: NSPoint(x: 0, y: 100))
        let targetStyle: NSScroller.Style =
            controller.scrollView.scrollerStyle == .overlay ? .legacy : .overlay

        controller.handlePreferredScrollerStyleChange(to: targetStyle)

        XCTAssertEqual(controller.scrollView.scrollerStyle, targetStyle)
        XCTAssertEqual(controller.scrollView.contentView.bounds.minY, 0)
        XCTAssertEqual(controller.verticalNumberingAnchor, 0)
        XCTAssertEqual(controller.selectionIndex, 20)
    }

    private func uniformCandidates(_ count: Int) -> [Candidate] {
        (0..<count).map { Candidate(displayString: "\($0)") }
    }
}
