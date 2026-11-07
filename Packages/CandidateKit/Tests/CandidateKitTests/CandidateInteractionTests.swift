import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidateInteractionTests: XCTestCase {
    func testDragUsesEuclideanThresholdAndSuppressesMouseUp() {
        var tracker = CandidatePanelDragTracker()
        tracker.begin(
            pointerLocation: NSPoint(x: 100, y: 100),
            windowOrigin: NSPoint(x: 50, y: 60)
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
        let controller = CandidateController(
            configuration: CandidateConfiguration(orientation: .vertical, animationDuration: 10))
        controller.replaceCandidates(uniformCandidates(20), initialSelectedIndex: 0)
        controller.visible = true
        defer { controller.visible = false }
        var confirmations: [Int] = []
        controller.onConfirmation = { index, _ in confirmations.append(index) }

        XCTAssertTrue(controller.navigate(.right))
        XCTAssertTrue(controller.isFrameTransitionActive)
        let view = try XCTUnwrap(controller.renderer[1])
        view.onSelect?(1)
        view.onConfirm?(1)

        XCTAssertEqual(controller.selectionIndex, 0)
        XCTAssertTrue(confirmations.isEmpty)
    }

    func testVerticalPageNavigationPreservesOffsetAndRelativeCommitUsesAnchor() {
        var configuration = CandidateConfiguration.default
        configuration.orientation = .vertical
        configuration.allowsExpansion = false
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(30), initialSelectedIndex: 3)
        controller.visible = true
        var confirmedIndex: Int?
        controller.onConfirmation = { index, _ in confirmedIndex = index }
        var observedViewport: (index: Int, minY: CGFloat, anchor: Int)?
        controller.onSelectionChange = { [weak controller] index, _ in
            guard let controller else { return }
            observedViewport = (
                index, controller.scrollView.contentView.bounds.minY,
                controller.verticalNumberingAnchor
            )
        }

        XCTAssertTrue(controller.navigate(.pageDown))
        // The selection callback already sees the scrolled viewport and its numbering.
        XCTAssertEqual(observedViewport?.index, 12)
        XCTAssertEqual(observedViewport?.minY, 9 * 29)
        XCTAssertEqual(observedViewport?.anchor, 9)
        controller.onSelectionChange = nil
        XCTAssertEqual(controller.verticalNumberingAnchor, 9)
        XCTAssertEqual(controller.selectionIndex, 12)
        XCTAssertEqual(controller.scrollView.contentView.bounds.minY, 9 * 29)
        XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(0), 9)
        XCTAssertTrue(controller.commitCandidate(matchingIndexLabel: "3"))
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
        controller.onConfirmation = { index, _ in confirmedIndex = index }
        XCTAssertTrue(controller.commitCandidate(matchingIndexLabel: "1"))
        XCTAssertEqual(confirmedIndex, 1)

        controller.scrollVertical(toAnchor: 18)
        let finalItem = try XCTUnwrap(controller.currentLayout.item(for: 19))
        XCTAssertEqual(controller.scrollView.contentView.bounds.maxY, finalItem.frame.maxY)
        XCTAssertEqual(controller.verticalNumberingAnchor, 11)

        controller.scrollView.contentView.scroll(to: .zero)
        controller.scrollBoundsDidChange()
        XCTAssertEqual(controller.verticalNumberingAnchor, 0)
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
}
