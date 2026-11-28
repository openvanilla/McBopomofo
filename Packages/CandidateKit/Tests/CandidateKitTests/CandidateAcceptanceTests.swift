import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateAcceptanceTests: XCTestCase {
    func testEmptyAndSingleCandidateLifecycle() {
        let controller = CandidateController()
        var notifications: [Int] = []
        controller.onSelectionChange = { index, _ in notifications.append(index) }

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
        controller.visible = true
        defer { controller.visible = false }

        XCTAssertEqual(controller.selectionIndex, 0)
        XCTAssertEqual(notifications, [0])
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

    func testSmallPageSizesReserveBlankLabels() throws {
        for pageSize in 1...3 {
            let configuration = CandidateConfiguration(pageSize: pageSize)
            let candidates = uniformCandidates(6)
            let pages = HorizontalCandidateLayoutEngine.pages(
                candidates: candidates,
                keyLabels: [CandidateKeyLabel(key: "1", displayedText: "1")],
                configuration: configuration,
                metrics: defaultMetrics
            )
            let layout = HorizontalCandidateLayoutEngine.layout(
                pages: pages,
                pageIndex: 0,
                keyLabels: [CandidateKeyLabel(key: "1", displayedText: "1")],
                metrics: defaultMetrics
            )

            XCTAssertEqual(pages[0].items.count, pageSize)
            XCTAssertEqual(layout.items[0].indexText, "1")
            XCTAssertTrue(layout.items.allSatisfy(\.showsIndexText))
            XCTAssertTrue(layout.items.dropFirst().allSatisfy { $0.indexText.isEmpty })
        }
    }

    func testDuplicateLabelsCommitOnlyTheFirstMatch() throws {
        let configuration = CandidateConfiguration(pageSize: 4)
        let controller = CandidateController(configuration: configuration)
        controller.keyLabels = "121".map {
            CandidateKeyLabel(key: String($0), displayedText: String($0))
        }
        controller.replaceCandidates(uniformCandidates(4), initialSelectedIndex: 3)
        controller.visible = true
        var confirmedIndexes: [Int] = []
        controller.onConfirmation = { index, _ in confirmedIndexes.append(index) }

        XCTAssertTrue(controller.commitCandidate(matchingIndexLabel: "1"))

        XCTAssertEqual(confirmedIndexes, [0])
        controller.visible = false
    }

    func testVerticalDetailsHideWhenWidestCandidateLeavesNoRoom() throws {
        let configuration = CandidateConfiguration(
            orientation: .vertical,
            pageSize: 1
        )
        let candidates = [
            Candidate(displayString: String(repeating: "i", count: 30), detail: "d"),
            Candidate(displayString: String(repeating: "Ｗ", count: 13)),
        ]
        let detailFits = VerticalCandidateLayoutEngine.layout(
            candidates: [candidates[0]],
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics,
            numberingAnchor: 0,
            scrollerStyle: .overlay,
            maximumWidth: 256
        )
        let widestLeavesNoRoom = VerticalCandidateLayoutEngine.layout(
            candidates: candidates,
            keyLabels: defaultKeyLabels,
            configuration: configuration,
            metrics: defaultMetrics,
            numberingAnchor: 0,
            scrollerStyle: .overlay,
            maximumWidth: 256
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
            maximumWidth: 256
        )

        XCTAssertTrue(detailFits.items[0].showsDetail)
        XCTAssertFalse(widestLeavesNoRoom.items[0].showsDetail)
        XCTAssertGreaterThan(widestLeavesNoRoom.windowSize.width, detailFits.windowSize.width)
        XCTAssertFalse(noFit.items[0].showsDetail)
    }

    func testNavigationBoundariesAndWrappingAcrossPanelKinds() throws {
        let pagedConfiguration = CandidateConfiguration(pageSize: 3)
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
        XCTAssertTrue(paged.navigate(.itemForward))
        XCTAssertEqual(paged.selectionIndex, 0)
        XCTAssertTrue(paged.navigate(.itemBackward))
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
        XCTAssertTrue(vertical.navigate(.itemBackward))
        XCTAssertEqual(vertical.selectionIndex, 7)
        XCTAssertFalse(vertical.navigate(.down))
        XCTAssertTrue(vertical.navigate(.itemForward))
        XCTAssertEqual(vertical.selectionIndex, 0)
        vertical.visible = false
    }

    func testKeyboardPolicyFiltersModifiersAndCanBeDisabled() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(3), initialSelectedIndex: 0)
        controller.visible = true
        var confirmations: [Int] = []
        controller.onConfirmation = { index, _ in confirmations.append(index) }

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

        controller.selectedCandidateIndex = 2
        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 48, characters: "\t", modifiers: []))
            )
        )
        XCTAssertEqual(controller.selectionIndex, 0)
        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 48, characters: "\t", modifiers: .shift))
            )
        )
        XCTAssertEqual(controller.selectionIndex, 2)
        XCTAssertFalse(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 48, characters: "\t", modifiers: .option))
            )
        )
        XCTAssertEqual(controller.selectionIndex, 2)
        controller.visible = false

        var disabledConfiguration = CandidateConfiguration.default
        disabledConfiguration.handlesIndexLabelKeys = false
        let disabled = CandidateController(configuration: disabledConfiguration)
        disabled.replaceCandidates(uniformCandidates(3), initialSelectedIndex: 0)
        disabled.visible = true
        XCTAssertFalse(
            disabled.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 18, characters: "1", modifiers: []))
            )
        )
        disabled.visible = false
    }

    func testDelegateReloadPreservesDetailsAndAbsoluteIndexes() {
        let delegate = AcceptanceDelegate()
        let controller = CandidateController()
        controller.delegate = delegate

        controller.reloadData()

        XCTAssertEqual(controller.candidates.map(\.displayString), delegate.entries)
        XCTAssertNil(controller.candidates[0].detail)
        XCTAssertEqual(controller.candidates[1].detail, "reading")

        controller.visible = true
        XCTAssertTrue(controller.navigate(.right))
        controller.confirmSelectedCandidate()

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
        detailAtIndex index: UInt
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
}
