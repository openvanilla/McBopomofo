import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateAcceptanceTests: XCTestCase {
    func testEmptyAndSingleCandidateLifecycle() {
        let controller = CandidateController()
        var notifications: [Int] = []
        controller.onSelectionChange = { _, index, _ in notifications.append(index) }

        controller.replaceCandidates([], initialSelectedIndex: 0)
        controller.visible = true

        XCTAssertEqual(controller.currentLayout.windowSize, .zero)
        XCTAssertEqual(controller.currentLayout.documentSize, .zero)
        XCTAssertTrue(controller.currentLayout.items.isEmpty)
        XCTAssertEqual(controller.selectionIndex, -1)
        XCTAssertTrue(notifications.isEmpty)
        XCTAssertFalse(controller.visible)

        controller.replaceCandidates(
            [Candidate(displayString: "永")],
            initialSelectedIndex: 0
        )

        XCTAssertEqual(controller.selectionIndex, 0)
        XCTAssertEqual(notifications, [0])
        XCTAssertNil(controller.currentLayout.control)
        XCTAssertFalse(controller.currentLayout.hasVerticalScroller)
        XCTAssertEqual(controller.currentLayout.cornerRadius, 8)
        XCTAssertEqual(
            controller.currentLayout.windowSize.width,
            controller.currentLayout.items[0].frame.width
        )

        controller.replaceCandidates(uniformCandidates(3), initialSelectedIndex: 100)
        XCTAssertEqual(controller.selectionIndex, 2)
        XCTAssertEqual(notifications, [0, 2])
    }

    func testSmallPageSizesKeepEmBudgetAndReserveBlankLabels() throws {
        for pageSize in 1...3 {
            let configuration = try CandidateConfiguration(
                indexLabels: "1",
                pageSize: pageSize
            )
            let candidates = uniformCandidates(6)
            let pages = HorizontalCandidateLayoutEngine.packedPages(
                candidates: candidates,
                configuration: configuration,
                metrics: defaultMetrics
            )
            let layout = HorizontalCandidateLayoutEngine.pagedLayout(
                pages: pages,
                pageIndex: 0,
                keyLabels: [CandidateKeyLabel(key: "1", displayedText: "1")],
                configuration: configuration,
                metrics: defaultMetrics
            )

            XCTAssertEqual(pages[0].items.count, pageSize)
            XCTAssertEqual(
                HorizontalCandidateLayoutEngine.horizontalBudget(
                    configuration: configuration,
                    metrics: defaultMetrics
                ),
                384
            )
            XCTAssertEqual(layout.items[0].indexText, "1")
            XCTAssertTrue(layout.items.allSatisfy(\.showsIndexText))
            XCTAssertTrue(layout.items.dropFirst().allSatisfy { $0.indexText.isEmpty })
        }
    }

    func testDuplicateAndSpaceLabelsCommitOnlyTheFirstMatch() throws {
        let configuration = try CandidateConfiguration(indexLabels: "1 1", pageSize: 4)
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(4), initialSelectedIndex: 3)
        controller.visible = true
        var confirmedIndexes: [Int] = []
        controller.onConfirmation = { _, index, _ in confirmedIndexes.append(index) }

        XCTAssertTrue(controller.commitCandidate(matchingIndexLabel: "1"))
        XCTAssertFalse(controller.commitCandidate(matchingIndexLabel: " "))

        XCTAssertEqual(confirmedIndexes, [0])
        controller.visible = false
    }

    func testVerticalDetailFitDecisionCanChangeAfterFullMeasurement() throws {
        let configuration = try CandidateConfiguration(
            orientation: .vertical,
            pageSize: 1
        )
        let candidates = [
            Candidate(displayString: String(repeating: "i", count: 30), detail: "d"),
            Candidate(displayString: String(repeating: "Ｗ", count: 13)),
        ]
        let initial = VerticalCandidateLayoutEngine.layout(
            candidates: candidates,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics,
            numberingAnchor: 0,
            scrollerStyle: .overlay,
            measuredIndexes: [0]
        )
        let fullyMeasured = VerticalCandidateLayoutEngine.layout(
            candidates: candidates,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics,
            numberingAnchor: 0,
            scrollerStyle: .overlay,
            measuredIndexes: nil
        )
        let noFit = VerticalCandidateLayoutEngine.layout(
            candidates: [
                Candidate(displayString: String(repeating: "W", count: 80), detail: "detail")
            ],
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics,
            numberingAnchor: 0,
            scrollerStyle: .overlay,
            measuredIndexes: nil
        )

        XCTAssertTrue(initial.items[0].showsDetail)
        XCTAssertFalse(fullyMeasured.items[0].showsDetail)
        XCTAssertGreaterThan(fullyMeasured.windowSize.width, initial.windowSize.width)
        XCTAssertFalse(noFit.items[0].showsDetail)
    }

    func testExpansionAdvanceOptionAndPageUpCollapseBoundary() throws {
        var stationaryConfiguration = CandidateConfiguration.default
        stationaryConfiguration.animationDuration = 0
        let stationary = CandidateController(configuration: stationaryConfiguration)
        stationary.replaceCandidates(uniformCandidates(80), initialSelectedIndex: 0)
        stationary.visible = true
        XCTAssertTrue(stationary.navigate(.down))
        XCTAssertEqual(stationary.selectionIndex, 0)
        stationary.visible = false

        var advancingConfiguration = stationaryConfiguration
        advancingConfiguration.advancesSelectionWhenExpanding = true
        let advancing = CandidateController(configuration: advancingConfiguration)
        advancing.replaceCandidates(uniformCandidates(80), initialSelectedIndex: 0)
        advancing.visible = true
        XCTAssertTrue(advancing.navigate(.down))
        XCTAssertEqual(advancing.selectionIndex, 6)
        advancing.visible = false

        let collapsing = CandidateController(configuration: stationaryConfiguration)
        collapsing.replaceCandidates(uniformCandidates(80), initialSelectedIndex: 0)
        collapsing.visible = true
        XCTAssertTrue(collapsing.navigate(.down))
        collapsing.finishFrameTransition()
        collapsing.scrollExpanded(toTopRow: 1)

        XCTAssertTrue(collapsing.navigate(.pageUp))
        XCTAssertFalse(collapsing.isExpanded)
        collapsing.visible = false
    }

    func testNavigationBoundariesAndWrappingAcrossPanelKinds() throws {
        var pagedConfiguration = try CandidateConfiguration(pageSize: 3)
        pagedConfiguration.allowsExpansion = false
        let paged = CandidateController(configuration: pagedConfiguration)
        paged.replaceCandidates(uniformCandidates(8), initialSelectedIndex: 2)
        paged.visible = true

        XCTAssertTrue(paged.navigate(.right))
        XCTAssertEqual(paged.selectionIndex, 3)
        XCTAssertTrue(paged.navigate(.left))
        XCTAssertEqual(paged.selectionIndex, 2)

        paged.selectedCandidateIndex = 1
        XCTAssertTrue(paged.navigate(.pageDown))
        XCTAssertEqual(paged.selectionIndex, 3)

        paged.selectedCandidateIndex = 7
        XCTAssertFalse(paged.navigate(.right))
        XCTAssertEqual(paged.selectionIndex, 7)
        XCTAssertTrue(paged.navigate(.right, wrapping: true))
        XCTAssertEqual(paged.selectionIndex, 0)
        XCTAssertTrue(paged.navigate(.left, wrapping: true))
        XCTAssertEqual(paged.selectionIndex, 7)
        paged.visible = false

        var verticalConfiguration = CandidateConfiguration.default
        verticalConfiguration.orientation = .vertical
        verticalConfiguration.allowsExpansion = false
        let vertical = CandidateController(configuration: verticalConfiguration)
        vertical.replaceCandidates(uniformCandidates(8), initialSelectedIndex: 0)
        vertical.visible = true

        XCTAssertFalse(vertical.navigate(.up))
        XCTAssertEqual(vertical.selectionIndex, 0)
        XCTAssertTrue(vertical.navigate(.up, wrapping: true))
        XCTAssertEqual(vertical.selectionIndex, 7)
        XCTAssertFalse(vertical.navigate(.down))
        XCTAssertTrue(vertical.navigate(.down, wrapping: true))
        XCTAssertEqual(vertical.selectionIndex, 0)
        vertical.visible = false

        var expandableConfiguration = CandidateConfiguration.default
        expandableConfiguration.animationDuration = 0
        let expandable = CandidateController(configuration: expandableConfiguration)
        expandable.replaceCandidates(uniformCandidates(20), initialSelectedIndex: 0)
        expandable.visible = true
        XCTAssertTrue(expandable.navigate(.down))
        XCTAssertTrue(expandable.isExpanded)
        XCTAssertTrue(expandable.navigate(.left, wrapping: true))
        XCTAssertEqual(expandable.selectionIndex, 19)
        XCTAssertTrue(expandable.isExpanded)
        expandable.visible = false
    }

    func testSuspendedPageHomeAndEndResultsMatchEachPanel() {
        var pagedConfiguration = CandidateConfiguration.default
        pagedConfiguration.allowsExpansion = false
        for (navigation, expectedIndex) in [
            (CandidateNavigation.pageDown, 9),
            (.pageForward, 9),
            (.pageUp, 0),
            (.pageBackward, 0),
            (.home, 0),
            (.end, 19),
        ] {
            let result = suspendedResult(
                configuration: pagedConfiguration,
                navigation: navigation
            )
            XCTAssertEqual(result.selectionIndex, expectedIndex)
        }

        var expandableConfiguration = CandidateConfiguration.default
        expandableConfiguration.animationDuration = 0
        for navigation in [CandidateNavigation.pageDown, .pageForward] {
            let result = suspendedResult(
                configuration: expandableConfiguration,
                navigation: navigation
            )
            XCTAssertEqual(result.selectionIndex, 0)
            XCTAssertTrue(result.isExpanded)
        }
        for (navigation, expectedIndex) in [
            (CandidateNavigation.pageUp, 0),
            (.pageBackward, 0),
            (.home, 0),
            (.end, 8),
        ] {
            let result = suspendedResult(
                configuration: expandableConfiguration,
                navigation: navigation
            )
            XCTAssertEqual(result.selectionIndex, expectedIndex)
        }

        expandableConfiguration.advancesSelectionWhenExpanding = true
        let advancingPageForward = suspendedResult(
            configuration: expandableConfiguration,
            navigation: .pageForward
        )
        XCTAssertEqual(advancingPageForward.selectionIndex, 6)
        XCTAssertTrue(advancingPageForward.isExpanded)
        let advancingPageDown = suspendedResult(
            configuration: expandableConfiguration,
            navigation: .pageDown
        )
        XCTAssertEqual(advancingPageDown.selectionIndex, 6)
        XCTAssertTrue(advancingPageDown.isExpanded)

        var verticalConfiguration = CandidateConfiguration.default
        verticalConfiguration.orientation = .vertical
        verticalConfiguration.allowsExpansion = false
        for navigation in [
            CandidateNavigation.right, .pageDown, .pageForward,
        ] {
            XCTAssertEqual(
                suspendedResult(
                    configuration: verticalConfiguration,
                    navigation: navigation
                ).selectionIndex,
                9
            )
        }
        for navigation in [
            CandidateNavigation.left, .pageUp, .pageBackward, .home,
        ] {
            XCTAssertEqual(
                suspendedResult(
                    configuration: verticalConfiguration,
                    navigation: navigation
                ).selectionIndex,
                0
            )
        }
        XCTAssertEqual(
            suspendedResult(
                configuration: verticalConfiguration,
                navigation: .end
            ).selectionIndex,
            19
        )
    }

    func testKeyboardPolicyFiltersModifiersAndCanBeDisabled() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(3), initialSelectedIndex: 0)
        controller.visible = true
        var confirmations: [Int] = []
        controller.onConfirmation = { _, index, _ in confirmations.append(index) }

        XCTAssertFalse(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 124, characters: "\u{F703}", modifiers: .command))
            )
        )
        XCTAssertFalse(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 124, characters: "\u{F703}", modifiers: .control))
            )
        )
        XCTAssertFalse(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 36, characters: "\r", modifiers: .shift))
            )
        )
        XCTAssertFalse(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 36, characters: "\r", modifiers: .option))
            )
        )
        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 36, characters: "\r", modifiers: []))
            )
        )
        XCTAssertFalse(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 18, characters: "1", modifiers: .option))
            )
        )
        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 18, characters: "1", modifiers: []))
            )
        )
        XCTAssertEqual(confirmations, [0, 0])
        controller.visible = false

        var disabledConfiguration = CandidateConfiguration.default
        disabledConfiguration.hostHandlesNavigationKeys = false
        disabledConfiguration.hostHandlesIndexLabelKeys = false
        let disabled = CandidateController(configuration: disabledConfiguration)
        disabled.replaceCandidates(uniformCandidates(3), initialSelectedIndex: 0)
        disabled.visible = true
        XCTAssertFalse(
            disabled.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 124, characters: "\u{F703}", modifiers: []))
            )
        )
        XCTAssertFalse(
            disabled.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 18, characters: "1", modifiers: []))
            )
        )
        disabled.visible = false
    }

    func testDelegateReloadPreservesDetailsContextsAndAbsoluteIndexes() {
        let delegate = AcceptanceDelegate()
        let controller = CandidateController()
        controller.delegate = delegate

        controller.reloadData()

        XCTAssertEqual(controller.candidates.map(\.displayString), delegate.entries)
        XCTAssertNil(controller.candidates[0].detail)
        XCTAssertEqual(controller.candidates[1].detail, "reading")
        let context = controller.candidates[1].context as AnyObject?
        XCTAssertTrue(context === delegate.contexts[1])
        XCTAssertEqual(delegate.highlightedIndexes, [0])

        controller.visible = true
        XCTAssertTrue(controller.navigate(.right))
        controller.confirmSelectedCandidate()

        XCTAssertEqual(delegate.highlightedIndexes, [0, 1])
        XCTAssertEqual(delegate.selectedIndexes, [1])
        controller.visible = false
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

    private func uniformCandidates(_ count: Int) -> [Candidate] {
        (0..<count).map { _ in Candidate(displayString: "永") }
    }

    private func suspendedResult(
        configuration: CandidateConfiguration,
        navigation: CandidateNavigation
    ) -> (selectionIndex: Int, isExpanded: Bool) {
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(20), initialSelectedIndex: -1)
        controller.visible = true
        _ = controller.navigate(navigation)
        let result = (controller.selectionIndex, controller.isExpanded)
        controller.visible = false
        return result
    }

    private func keyEvent(
        keyCode: UInt16,
        characters: String,
        modifiers: NSEvent.ModifierFlags
    ) -> NSEvent? {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        )
    }
}

@MainActor
private final class AcceptanceDelegate: NSObject, CandidateControllerDelegate {
    let entries = ["甲", "乙", "丙"]
    let readings = ["", "reading", ""]
    let contexts = [NSObject(), NSObject(), NSObject()]
    var highlightedIndexes: [UInt] = []
    var selectedIndexes: [UInt] = []

    func candidateCountForController(_ controller: CandidateController) -> UInt {
        UInt(entries.count)
    }

    func candidateController(
        _ controller: CandidateController,
        candidateAtIndex index: UInt
    ) -> String {
        entries[Int(index)]
    }

    func candidateController(
        _ controller: CandidateController,
        readingAtIndex index: UInt
    ) -> String? {
        readings[Int(index)]
    }

    func candidateController(
        _ controller: CandidateController,
        requestExplanationFor candidate: String,
        reading: String
    ) -> String? {
        nil
    }

    func candidateController(
        _ controller: CandidateController,
        didSelectCandidateAtIndex index: UInt
    ) {
        selectedIndexes.append(index)
    }

    func candidateController(
        _ controller: CandidateController,
        didHighlightCandidateAtIndex index: UInt
    ) {
        highlightedIndexes.append(index)
    }

    func candidateController(
        _ controller: CandidateController,
        contextAtIndex index: UInt
    ) -> Any? {
        contexts[Int(index)]
    }
}
