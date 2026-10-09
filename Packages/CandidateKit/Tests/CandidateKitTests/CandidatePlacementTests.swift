import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidatePlacementTests: XCTestCase {
    private let screen = CandidateScreenGeometry(
        frame: NSRect(x: 0, y: 0, width: 1000, height: 800),
        visibleFrame: NSRect(x: 0, y: 20, width: 1000, height: 760)
    )

    func testScreenChoicePrefersOriginContainmentThenLargestIntersection() {
        let left = CandidateScreenGeometry(
            frame: NSRect(x: -1000, y: 0, width: 1000, height: 800),
            visibleFrame: NSRect(x: -1000, y: 20, width: 1000, height: 760)
        )
        let right = screen

        XCTAssertEqual(
            CandidatePlacementEngine.screen(
                for: NSRect(x: -10, y: 100, width: 30, height: 20),
                screens: [left, right],
                fallback: nil
            ),
            left
        )
        XCTAssertEqual(
            CandidatePlacementEngine.screen(
                for: NSRect(x: 990, y: 100, width: 40, height: 20),
                screens: [left, right],
                fallback: nil
            ),
            right
        )
    }

    func testScreenChoiceFallsBackWhenAnchorDoesNotIntersect() {
        XCTAssertEqual(
            CandidatePlacementEngine.screen(
                for: NSRect(x: 2000, y: 2000, width: 20, height: 20),
                screens: [screen],
                fallback: screen
            ),
            screen
        )
    }

    func testPlacementUsesBelowThenAbovePriorityWithFivePointGap() {
        let below = place(anchor: NSRect(x: 100, y: 300, width: 20, height: 20))
        XCTAssertEqual(below.side, .below)
        XCTAssertEqual(below.topLeft, NSPoint(x: 100, y: 295))

        let above = place(anchor: NSRect(x: 100, y: 80, width: 20, height: 20))
        XCTAssertEqual(above.side, .above)
        XCTAssertEqual(above.topLeft, NSPoint(x: 100, y: 205))
    }

    func testPlacementUsesLeftAndLazilyResolvesRightOnlyWhenNeeded() {
        var trailingResolutionCount = 0
        let left = CandidatePlacementEngine.place(
            windowSize: NSSize(width: 200, height: 700),
            anchorRect: NSRect(x: 500, y: 300, width: 20, height: 20),
            screen: screen,
            compositionLeadingX: 500
        ) {
            trailingResolutionCount += 1
            return 520
        }
        XCTAssertEqual(left.side, .left)
        XCTAssertEqual(left.topLeft.x, 295)
        XCTAssertEqual(trailingResolutionCount, 0)

        let right = CandidatePlacementEngine.place(
            windowSize: NSSize(width: 200, height: 700),
            anchorRect: NSRect(x: 100, y: 300, width: 20, height: 20),
            screen: screen,
            compositionLeadingX: 100
        ) {
            trailingResolutionCount += 1
            return 120
        }
        XCTAssertEqual(right.side, .right)
        XCTAssertEqual(right.topLeft.x, 125)
        XCTAssertEqual(trailingResolutionCount, 1)
    }

    func testPlacementClampsHorizontalAndTopEdges() {
        let result = place(anchor: NSRect(x: 950, y: 770, width: 40, height: 20))
        XCTAssertEqual(result.side, .below)
        XCTAssertEqual(result.topLeft.x, 800)
        XCTAssertEqual(result.topLeft.y, 765)
    }

    func testShowNearAnchorSnapsAtThresholdAndRetargetsActiveMovement() throws {
        var configuration = CandidateConfiguration.default
        configuration.animationDuration = 10
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(uniformCandidates(20), initialSelectedIndex: 0)
        let visibleFrame = try XCTUnwrap(NSScreen.main?.visibleFrame)
        let firstAnchor = NSRect(
            x: visibleFrame.midX - 200,
            y: visibleFrame.midY,
            width: 20,
            height: 20
        )

        controller.show(near: firstAnchor)
        XCTAssertEqual(controller.placementSide, .below)
        XCTAssertNil(controller.frameTransitionDriver)

        controller.show(near: firstAnchor.offsetBy(dx: 28, dy: 0))
        XCTAssertNil(controller.frameTransitionDriver)

        controller.show(near: firstAnchor.offsetBy(dx: 57, dy: 0))
        let activeDriver = try XCTUnwrap(controller.frameTransitionDriver)
        XCTAssertTrue(controller.isFrameTransitionActive)

        let latestAnchor = firstAnchor.offsetBy(dx: 100, dy: 0)
        controller.show(near: latestAnchor)
        let retargetedDriver = try XCTUnwrap(controller.frameTransitionDriver)
        XCTAssertFalse(retargetedDriver === activeDriver)
        XCTAssertTrue(controller.isWindowMovementTransitionActive)

        controller.finishFrameTransition()
        XCTAssertFalse(controller.isFrameTransitionActive)
        XCTAssertFalse(controller.isWindowMovementTransitionActive)
        XCTAssertNil(controller.frameTransitionDriver)
        let expected = controller.placementResult(
            for: controller.currentLayout.windowSize,
            context: try XCTUnwrap(controller.lastPlacementContext)
        )
        let finalFrame = try XCTUnwrap(controller.window?.frame)
        XCTAssertEqual(finalFrame.minX, expected.topLeft.x, accuracy: 0.5)
        XCTAssertEqual(finalFrame.maxY, expected.topLeft.y, accuracy: 0.5)
        XCTAssertEqual(finalFrame.size, controller.currentLayout.windowSize)

        let frameAtLatestTarget = controller.window?.frame
        activeDriver.finish()
        XCTAssertEqual(controller.window?.frame, frameAtLatestTarget)
        controller.visible = false
    }

    func testExpansionStaysOnScreenForAnchoredLegacyAndDraggedPlacement() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            for placement in 0..<3 {
                for duration in [0.0, 0.2] {
                    var configuration = CandidateConfiguration.default
                    configuration.orientation = orientation
                    configuration.animationDuration = duration
                    let controller = CandidateController(configuration: configuration)
                    controller.replaceCandidates(
                        (0..<80).map { _ in Candidate(displayString: "字") }, initialSelectedIndex: 0
                    )
                    let anchor = NSRect(x: bounds.maxX - 20, y: bounds.midY, width: 10, height: 20)
                    switch placement {
                    case 0:
                        controller.show(near: anchor)
                    case 1:
                        controller.set(
                            windowTopLeftPoint: NSPoint(x: anchor.maxX, y: anchor.minY),
                            bottomOutOfScreenAdjustmentHeight: anchor.height)
                        controller.visible = true
                    default:
                        controller.centerOnMainScreen()
                        let size = try XCTUnwrap(controller.window?.frame.size)
                        controller.movePanelManually(
                            to: NSPoint(
                                x: bounds.maxX - size.width, y: bounds.minY + 10))
                        controller.visible = true
                    }
                    defer { controller.visible = false }

                    XCTAssertTrue(controller.navigate(orientation == .horizontal ? .down : .right))
                    controller.finishFrameTransition()
                    for selectedIndex in [0, 79, 0] {
                        controller.selectedCandidateIndex = UInt(selectedIndex)
                        let frame = try XCTUnwrap(controller.window?.frame)
                        XCTAssertGreaterThanOrEqual(frame.minX, bounds.minX - 1)
                        XCTAssertLessThanOrEqual(frame.maxX, bounds.maxX + 1)
                        XCTAssertGreaterThanOrEqual(frame.minY, bounds.minY - 1)
                        XCTAssertLessThanOrEqual(frame.maxY, bounds.maxY + 1)
                    }
                }
            }
        }
    }

    func testBackgroundMeasurementWidensWithoutScrollingOrMovingTopLeft() async throws {
        let configuration = try CandidateConfiguration(
            orientation: .vertical, allowsExpansion: false, pageSize: 1)
        let candidates = (0..<20).map { Candidate(displayString: $0 == 19 ? "ＷＷＷＷ" : "iiii") }
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(candidates, initialSelectedIndex: 0)
        controller.show(near: NSRect(x: 400, y: 500, width: 20, height: 20))
        let before = try XCTUnwrap(controller.window?.frame)
        for _ in 0..<300 where !controller.textMeasurements.isComplete {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertTrue(controller.textMeasurements.isComplete)
        controller.finishFrameTransition()
        XCTAssertGreaterThan(controller.window!.frame.width, before.width)
        XCTAssertEqual(controller.window!.frame.minX, before.minX)
        XCTAssertEqual(controller.window!.frame.maxY, before.maxY)
        XCTAssertEqual(controller.scrollView.contentView.bounds.minY, 0)
        controller.visible = false
    }

    func testNonexpandingLongListPagesStayOnScreenAt24Points() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        let configuration = try CandidateConfiguration(
            allowsExpansion: false,
            candidateFontSize: 24, animationDuration: 0)
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(
            (1...201).map { Candidate(displayString: "選字\($0)", detail: "說明") },
            initialSelectedIndex: 0)
        controller.show(near: NSRect(x: bounds.maxX - 20, y: bounds.midY, width: 10, height: 20))
        defer { controller.visible = false }
        var visited: [Int] = []
        repeat {
            let frame = try XCTUnwrap(controller.window?.frame)
            XCTAssertGreaterThanOrEqual(frame.minX, bounds.minX - 1)
            XCTAssertLessThanOrEqual(frame.maxX, bounds.maxX + 1)
            let indexes = controller.currentLayout.items.map(\.candidateIndex)
            XCTAssertEqual(controller.selectedCandidateIndex, UInt(try XCTUnwrap(indexes.first)))
            for (slot, index) in indexes.enumerated() {
                XCTAssertEqual(controller.candidateIndexAtKeyLabelIndex(UInt(slot)), UInt(index))
            }
            if indexes.count < configuration.pageSize {
                XCTAssertEqual(
                    controller.candidateIndexAtKeyLabelIndex(UInt(indexes.count)), UInt.max)
            }
            visited.append(contentsOf: indexes)
        } while controller.showNextPage()
        XCTAssertEqual(visited, Array(0..<201))
        XCTAssertTrue(controller.showPreviousPage())
        XCTAssertEqual(
            controller.selectedCandidateIndex,
            UInt(try XCTUnwrap(controller.currentLayout.items.first).candidateIndex))
    }

    private func place(anchor: NSRect) -> CandidatePlacementResult {
        CandidatePlacementEngine.place(
            windowSize: NSSize(width: 200, height: 100),
            anchorRect: anchor,
            screen: screen,
            compositionLeadingX: anchor.minX,
            compositionTrailingX: { anchor.maxX }
        )
    }

    private func uniformCandidates(_ count: Int) -> [Candidate] {
        (0..<count).map { Candidate(displayString: "\($0)") }
    }
}
