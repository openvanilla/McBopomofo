import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateInteractionTests: XCTestCase {
    func testDragUsesConfiguredEuclideanThresholdAndSuppressesMouseUp() {
        var tracker = CandidatePanelDragTracker()
        tracker.begin(
            pointerLocation: NSPoint(x: 100, y: 100),
            windowOrigin: NSPoint(x: 50, y: 60),
            activationDistance: 3
        )

        XCTAssertNil(tracker.updatedWindowOrigin(pointerLocation: NSPoint(x: 103, y: 100)))
        let draggedOrigin = tracker.updatedWindowOrigin(
            pointerLocation: NSPoint(x: 103.01, y: 100)
        )
        XCTAssertEqual(draggedOrigin?.x ?? 0, 53.01, accuracy: 0.0001)
        XCTAssertEqual(draggedOrigin?.y, 60)
        XCTAssertTrue(tracker.end())
        XCTAssertFalse(tracker.end())
    }

    func testCandidateViewSingleClickSelectsAndDoubleClickConfirmsDirectly() throws {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 40),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let view = CandidateItemView(
            frame: NSRect(x: 0, y: 0, width: 100, height: defaultMetrics.itemHeight),
            candidate: Candidate(displayString: "Candidate"),
            candidateIndex: 4,
            indexText: "1",
            showsIndexText: true,
            selected: false,
            selectionColors: .system,
            metrics: defaultMetrics,
            reservesIndexSlot: true,
            showsDetail: false,
            alignedCandidateWidth: nil
        )
        window.contentView?.addSubview(view)
        var selectedIndexes: [Int] = []
        var confirmedIndexes: [Int] = []
        view.onSelect = { selectedIndexes.append($0) }
        view.onConfirm = { confirmedIndexes.append($0) }

        view.mouseUp(with: try XCTUnwrap(mouseUpEvent(window: window, clickCount: 1)))
        view.mouseUp(with: try XCTUnwrap(mouseUpEvent(window: window, clickCount: 2)))

        XCTAssertEqual(selectedIndexes, [4])
        XCTAssertEqual(confirmedIndexes, [4])
    }

    func testFrameTransitionSuppressesCandidateActions() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(20), initialSelectedIndex: 0)
        controller.visible = true
        let view = try XCTUnwrap(controller.renderer[1])
        var confirmations: [Int] = []
        controller.onConfirmation = { _, index, _ in confirmations.append(index) }

        controller.isFrameTransitionActive = true
        view.onSelect?(1)
        view.onConfirm?(1)

        XCTAssertEqual(controller.selectionIndex, 0)
        XCTAssertTrue(confirmations.isEmpty)
        controller.visible = false
    }

    func testExpandedPageKeysMoveOneRowWithoutScrollingVisibleSelection() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(80), initialSelectedIndex: 7)
        controller.visible = true
        XCTAssertTrue(controller.navigate(.down))
        XCTAssertTrue(controller.isExpanded)
        XCTAssertEqual(
            controller.currentLayout.rows.firstIndex { $0.candidateIndexes.contains(7) }, 1)

        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 121, modifiers: [], characters: "\u{F72D}"))))

        XCTAssertEqual(controller.selectionIndex, 13)
        XCTAssertEqual(controller.scrollView.contentView.bounds.minY, 0)

        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 116, modifiers: [], characters: "\u{F72C}"))))
        XCTAssertEqual(controller.selectionIndex, 7)
        XCTAssertEqual(controller.scrollView.contentView.bounds.minY, 0)
        controller.visible = false
    }

    func testVerticalPageNavigationPreservesOffsetAndRelativeCommitUsesAnchor() {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 3)
        controller.visible = true
        var confirmedIndex: Int?
        controller.onConfirmation = { _, index, _ in confirmedIndex = index }

        XCTAssertTrue(controller.navigate(.pageDown))
        XCTAssertEqual(controller.verticalNumberingAnchor, 9)
        XCTAssertEqual(controller.selectionIndex, 12)
        XCTAssertEqual(controller.scrollView.contentView.bounds.minY, 9 * 29)
        XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(0), 9)
        XCTAssertTrue(controller.commitCandidate(atRelativeIndex: 2))
        XCTAssertEqual(confirmedIndex, 11)

        controller.scrollVertical(toAnchor: 5)
        controller.selectedCandidateIndex = 8
        XCTAssertTrue(controller.navigate(.pageUp))
        XCTAssertEqual(controller.verticalNumberingAnchor, 0)
        XCTAssertEqual(controller.selectionIndex, 0)
        controller.visible = false
    }

    func testVerticalDynamicNumberingThresholdAndBottomClamp() throws {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(20), initialSelectedIndex: 0)
        controller.visible = true

        controller.scrollView.contentView.scroll(to: NSPoint(x: 0, y: 14))
        controller.scrollBoundsDidChange()
        XCTAssertEqual(controller.verticalNumberingAnchor, 0)

        controller.scrollView.contentView.scroll(to: NSPoint(x: 0, y: 15))
        controller.scrollBoundsDidChange()
        XCTAssertEqual(controller.verticalNumberingAnchor, 1)
        XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(0), 1)
        var confirmedIndex: Int?
        controller.onConfirmation = { _, index, _ in confirmedIndex = index }
        XCTAssertTrue(controller.commitCandidate(atRelativeIndex: 0))
        XCTAssertEqual(confirmedIndex, 1)

        controller.scrollVertical(toAnchor: 18)
        let finalItem = try XCTUnwrap(controller.currentLayout.item(for: 19))
        XCTAssertEqual(
            controller.verticalMinimumDocumentHeight,
            controller.naturalVerticalDocumentHeight
        )
        XCTAssertEqual(controller.scrollView.contentView.bounds.maxY, finalItem.frame.maxY)
        XCTAssertEqual(controller.verticalNumberingAnchor, 11)

        controller.scrollView.contentView.scroll(to: .zero)
        controller.scrollBoundsDidChange()
        XCTAssertEqual(
            controller.verticalMinimumDocumentHeight,
            controller.naturalVerticalDocumentHeight
        )
        controller.visible = false
    }

    func testSuspendedConfirmationPrecedesVisibilityGuard() {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(3), initialSelectedIndex: -1)
        var confirmations: [(String, Int, Candidate?)] = []
        controller.onConfirmation = { confirmations.append(($0, $1, $2)) }

        controller.confirmSelectedCandidate()

        XCTAssertEqual(confirmations.count, 1)
        XCTAssertEqual(confirmations[0].0, "")
        XCTAssertEqual(confirmations[0].1, -1)
        XCTAssertNil(confirmations[0].2)

        controller.selectedCandidateIndex = 0
        controller.confirmSelectedCandidate()
        XCTAssertEqual(confirmations.count, 1)
    }

    func testTabAndShiftTabWrapSequentialSelection() throws {
        let controller = CandidateController()
        controller.replaceCandidates(uniformCandidates(3), initialSelectedIndex: 2)
        controller.visible = true

        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 48, modifiers: [], characters: "\t"))
            )
        )
        XCTAssertEqual(controller.selectionIndex, 0)

        XCTAssertTrue(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 48, modifiers: .shift, characters: "\t"))
            )
        )
        XCTAssertEqual(controller.selectionIndex, 2)

        XCTAssertFalse(
            controller.handleKeyEvent(
                try XCTUnwrap(keyEvent(keyCode: 48, modifiers: .option, characters: "\t"))
            )
        )
        XCTAssertEqual(controller.selectionIndex, 2)
        controller.visible = false
    }

    private var defaultMetrics: CandidateMetrics {
        CandidateMetrics(
            requestedCandidateFont: .systemFont(ofSize: 16),
            requestedIndexFont: .systemFont(ofSize: 8)
        )
    }

    private func uniformCandidates(_ count: Int) -> [Candidate] {
        (0..<count).map { Candidate(displayString: "\($0)") }
    }

    private func mouseUpEvent(
        window: NSWindow,
        locationY: CGFloat = 10,
        clickCount: Int
    ) -> NSEvent? {
        NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: NSPoint(x: 10, y: locationY),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: window.windowNumber,
            context: nil,
            eventNumber: 0,
            clickCount: clickCount,
            pressure: 0
        )
    }

    private func keyEvent(
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags,
        characters: String = "\u{F703}"
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
