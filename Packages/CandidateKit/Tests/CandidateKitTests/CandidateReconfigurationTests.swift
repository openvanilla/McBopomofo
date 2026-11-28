import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateReconfigurationTests: XCTestCase {
    func testShortcutHintsFollowKeysInDetailAcrossLayouts() throws {
        // Expansion only applies to vertical panels.
        let panels: [(CandidateOrientation, Bool)] = [
            (.horizontal, false), (.vertical, false), (.vertical, true),
        ]
        for (orientation, expandable) in panels {
            let configuration = CandidateConfiguration(
                orientation: orientation, allowsExpansion: expandable,
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
                XCTAssertEqual(
                    controller.metrics.indexSlotWidth,
                    controller.metrics.indexFont.pointSize + 2)
                for selection in [0, 2, 4, 10, 29] {
                    controller.selectedCandidateIndex = UInt(selection)
                    var hintedIndexes = Set<Int>()
                    for slot in 0..<3 {
                        let index = controller.candidateIndexAtKeyLabelIndex(UInt(slot))
                        guard index != UInt.max else { continue }
                        hintedIndexes.insert(Int(index))
                        let view = try XCTUnwrap(controller.renderer[Int(index)])
                        XCTAssertEqual(view.detailText, "⇧ \(slot + 1)")
                    }
                    for view in controller.renderer.itemViews
                    where !hintedIndexes.contains(view.candidateIndex) {
                        XCTAssertNil(view.detailText)
                    }
                }
            }
        }
    }

    func testSelectionKeyChangesUpdateRenderedLabelsAndPageMapping() throws {
        // Expansion only applies to vertical panels.
        let panels: [(CandidateOrientation, Bool)] = [
            (.horizontal, false), (.vertical, false), (.vertical, true),
        ]
        for (orientation, expandable) in panels {
            var configuration = CandidateConfiguration.default
            configuration.orientation = orientation
            configuration.allowsExpansion = expandable
            configuration.animationDuration = 0
            let controller = CandidateController(configuration: configuration)
            controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 0)
            controller.visible = true
            defer { controller.visible = false }

            for keys in ["asdf", "123456789", "asdfzxcvb"] {
                configuration.pageSize = keys.count
                controller.apply(configuration: configuration)
                controller.keyLabels = keys.map {
                    CandidateKeyLabel(key: String($0), displayedText: String($0))
                }
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
                    controller.onConfirmation = { index, _ in confirmedIndex = index }
                    XCTAssertTrue(
                        controller.commitCandidate(matchingIndexLabel: Character(label)))
                    XCTAssertEqual(confirmedIndex, Int(index))
                }
            }
        }
    }

    func testReplacementPublishesOnlyTheFinalSelectionAndLayout() throws {
        let controller = VerticalCandidateController()
        controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 20)
        controller.visible = true
        defer { controller.visible = false }
        var selections: [Int] = []
        controller.onSelectionChange = { [weak controller] index, candidate in
            guard let controller else { return }
            selections.append(index)
            XCTAssertEqual(index, 23)
            XCTAssertTrue(candidate === controller.candidates[index])
            XCTAssertTrue(
                controller.scrollView.documentVisibleRect.intersects(
                    controller.currentLayout.item(for: index)!.frame))
        }
        controller.replaceCandidates(uniformCandidates(24), initialSelectedIndex: 23)
        XCTAssertEqual(selections, [23])
        XCTAssertEqual(controller.candidates.count, 24)
    }

    func testHiddenPanelMigrationPreservesSelectionAndVisibility() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 12)
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false

        controller.apply(configuration: configuration)

        XCTAssertEqual(controller.panelKind, .vertical)
        XCTAssertEqual(controller.selectionIndex, 12)
        XCTAssertFalse(controller.visible)
    }

    func testHiddenChangesApplyWhenShown() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(5), initialSelectedIndex: 0)
        controller.tooltip = "提示"
        controller.candidateFont = .systemFont(ofSize: 24)
        XCTAssertTrue(controller.currentLayout.items.isEmpty)

        controller.show(near: NSRect(x: bounds.midX, y: bounds.midY, width: 10, height: 20))
        defer { controller.visible = false }

        XCTAssertEqual(controller.currentLayout.items.count, 5)
        XCTAssertGreaterThan(controller.currentLayout.headerHeight, 0)
        XCTAssertEqual(
            controller.currentLayout.items.first?.frame.height, controller.metrics.itemHeight)
        XCTAssertEqual(controller.window?.frame.size, controller.currentLayout.windowSize)
    }

    func testLayoutConfigurationAndPublicFontPropertiesRecomputeGeometry() {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(80), initialSelectedIndex: 0)
        controller.centerOnMainScreen()
        controller.visible = true
        defer { controller.visible = false }
        let originalItemHeight = controller.metrics.itemHeight
        controller.candidateFont = .systemFont(ofSize: 20)
        XCTAssertGreaterThan(controller.metrics.itemHeight, originalItemHeight)
        XCTAssertEqual(
            controller.currentLayout.items.first?.frame.height, controller.metrics.itemHeight)

        controller.keyLabels = []
        XCTAssertTrue(controller.currentLayout.items.allSatisfy { !$0.showsIndexText })

        var configuration = controller.configuration
        configuration.pageSize = 3
        configuration.handlesIndexLabelKeys = false
        controller.apply(configuration: configuration)

        XCTAssertEqual(controller.configuration, configuration)
        XCTAssertEqual(controller.metrics.itemHeight, 35)
        XCTAssertEqual(controller.currentLayout.windowSize, controller.window?.frame.size)
    }

    func testVerticalScrollerStyleChangeKeepsSelectionVisible() {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(40), initialSelectedIndex: 20)
        controller.centerOnMainScreen()
        controller.visible = true
        defer { controller.visible = false }
        controller.scrollView.contentView.scroll(to: NSPoint(x: 0, y: 100))
        let targetStyle: NSScroller.Style =
            controller.scrollView.scrollerStyle == .overlay ? .legacy : .overlay

        controller.handlePreferredScrollerStyleChange(to: targetStyle)

        XCTAssertEqual(controller.scrollView.scrollerStyle, targetStyle)
        XCTAssertEqual(controller.selectionIndex, 20)
        let selectedItem = controller.currentLayout.item(for: 20)!
        XCTAssertTrue(controller.scrollView.documentVisibleRect.contains(selectedItem.frame))
    }

    func testLongMenuTitleFitsWhenScreenHasRoom() throws {
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            let configuration = CandidateConfiguration(orientation: orientation)
            let controller = CandidateController(configuration: configuration)
            controller.replaceCandidates(
                [Candidate(displayString: "增加權重"), Candidate(displayString: "取消")],
                initialSelectedIndex: 0)
            controller.centerOnMainScreen()
            controller.visible = true
            defer { controller.visible = false }
            controller.tooltip = "您想要提升 \"舊家\" 這個詞彙的權重嗎？"
            for fontSize: CGFloat in [16, 24, 32] {
                controller.candidateFont = .systemFont(ofSize: fontSize)
                controller.backdropView.layoutSubtreeIfNeeded()
                let title = controller.contentView.titleView
                let cell = try XCTUnwrap(title.cell)
                XCTAssertLessThan(
                    controller.contentView.minimumHeaderWidth, controller.layoutAvailableWidth)
                XCTAssertGreaterThanOrEqual(title.frame.width, cell.cellSize.width)
                XCTAssertTrue(cell.expansionFrame(withFrame: title.bounds, in: title).isEmpty)
            }
            controller.tooltip = String(repeating: "提示", count: 200)
            XCTAssertLessThanOrEqual(
                controller.currentLayout.windowSize.width, controller.layoutAvailableWidth)
        }
    }

    func testTooltipReservesHeaderWithoutChangingViewportHeight() throws {
        // Expansion only applies to vertical panels.
        let panels: [(CandidateOrientation, Bool)] = [
            (.horizontal, false), (.vertical, false), (.vertical, true),
        ]
        for (orientation, expandable) in panels {
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
            XCTAssertEqual(
                controller.scrollView.frame.maxY, controller.currentLayout.viewportSize.height)
            XCTAssertGreaterThanOrEqual(
                controller.contentView.titleView.frame.minY, controller.scrollView.frame.maxY)
            XCTAssertTrue(
                controller.contentView.bounds.contains(controller.contentView.titleView.frame))

            controller.selectedCandidateIndex = 29
            controller.finishFrameTransition()
            controller.backdropView.layoutSubtreeIfNeeded()
            let last = try XCTUnwrap(controller.currentLayout.item(for: 29))
            XCTAssertTrue(controller.scrollView.documentVisibleRect.intersects(last.frame))
            XCTAssertEqual(
                controller.currentLayout.viewportSize.height,
                controller.scrollView.frame.height)
            if controller.currentLayout.hasVerticalScroller {
                XCTAssertEqual(
                    controller.scrollView.documentVisibleRect.maxY, last.frame.maxY,
                    accuracy: 1)
            }

            controller.selectedCandidateIndex = 0
            if controller.isExpanded { XCTAssertTrue(controller.navigate(.left)) }
            controller.finishFrameTransition()
            controller.tooltip = ""
            XCTAssertTrue(controller.contentView.titleView.isHidden)
            XCTAssertEqual(controller.currentLayout.windowSize.height, initialSize.height)
        }
    }

    private func uniformCandidates(_ count: Int) -> [Candidate] {
        (0..<count).map { Candidate(displayString: "\($0)") }
    }
}
