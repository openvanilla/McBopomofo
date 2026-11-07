import AppKit
import XCTest

@testable import CandidateKit

@MainActor
final class CandidatePlacementTests: XCTestCase {
    func testPlacementReservesExpandedHeightIncludingHeaderAndLegacyScroller() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        for title in ["", "候選字提示"] {
            let configuration = CandidateConfiguration(
                orientation: .vertical, animationDuration: 10)
            let controller = CandidateController(configuration: configuration)
            controller.scrollView.scrollerStyle = .legacy
            controller.replaceCandidates(
                (0..<54).map { _ in Candidate(displayString: "字") }, initialSelectedIndex: 0)
            controller.tooltip = title
            controller.centerOnMainScreen()
            controller.visible = true
            defer { controller.visible = false }
            let compactSize = controller.currentLayout.windowSize
            let expandedHeight =
                controller.expandedLayout.windowSize.height + controller.currentLayout.headerHeight
            XCTAssertGreaterThan(expandedHeight, compactSize.height + 1)
            let anchor = NSRect(
                x: bounds.midX, y: bounds.minY + compactSize.height + 6, width: 10, height: 20)
            XCTAssertGreaterThanOrEqual(anchor.minY - 5 - compactSize.height, bounds.minY)
            XCTAssertLessThan(anchor.maxY + 5 + expandedHeight, bounds.maxY)

            controller.show(near: anchor)
            XCTAssertEqual(controller.placementSide, .above)
            let compactFrame = try XCTUnwrap(controller.window?.frame)
            XCTAssertEqual(compactFrame.minY, anchor.maxY + 5, accuracy: 1)
            XCTAssertTrue(controller.navigate(.right))
            XCTAssertEqual(controller.placementSide, .above)
            XCTAssertTrue(controller.isFrameTransitionActive)
            controller.finishFrameTransition()
            XCTAssertEqual(controller.window?.frame.minY, compactFrame.minY)
            XCTAssertTrue(controller.navigate(.left))
            XCTAssertEqual(controller.placementSide, .above)
            XCTAssertTrue(controller.isFrameTransitionActive)
            controller.finishFrameTransition()
            XCTAssertEqual(controller.window?.frame, compactFrame)
        }
    }

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
        // The origin lies below both screens, and the rectangle overlaps the right one more.
        XCTAssertEqual(
            CandidatePlacementEngine.screen(
                for: NSRect(x: -10, y: -10, width: 40, height: 30),
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

    func testNavigationStaysOnScreenForAnchoredAndDraggedPlacement() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            for anchored in [true, false] {
                for duration in [0.0, 0.2] {
                    var configuration = CandidateConfiguration.default
                    configuration.orientation = orientation
                    configuration.animationDuration = duration
                    let controller = CandidateController(configuration: configuration)
                    controller.replaceCandidates(
                        (0..<80).map { _ in Candidate(displayString: "字") }, initialSelectedIndex: 0
                    )
                    let anchor = NSRect(x: bounds.maxX - 20, y: bounds.midY, width: 10, height: 20)
                    if anchored {
                        controller.show(near: anchor)
                    } else {
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

    func testSidePlacementReservesExpandedWidthForBothTextOrientations() throws {
        let bounds = try XCTUnwrap(NSScreen.main?.visibleFrame)
        for usesVerticalText in [false, true] {
            for style: NSScroller.Style in [.overlay, .legacy] {
                let configuration = CandidateConfiguration(
                    orientation: .vertical, animationDuration: 10,
                    verticalMaximumVisibleColumns: 2)
                let controller = CandidateController(configuration: configuration)
                controller.candidateFont = .systemFont(ofSize: floor(bounds.height / 22))
                controller.scrollView.scrollerStyle = style
                controller.replaceCandidates(
                    (0..<30).map { _ in Candidate(displayString: "字") }, initialSelectedIndex: 0)
                controller.centerOnMainScreen()
                controller.visible = true
                defer { controller.visible = false }
                let compactSize = controller.currentLayout.windowSize
                let anchor = NSRect(
                    x: bounds.minX + compactSize.width + 10, y: bounds.midY,
                    width: 10, height: 20)
                XCTAssertGreaterThan(compactSize.height, bounds.height / 2)
                XCTAssertGreaterThan(
                    controller.expandedLayout.windowSize.width, anchor.minX - bounds.minX)
                XCTAssertLessThan(
                    anchor.maxX + 5 + controller.expandedLayout.windowSize.width, bounds.maxX)

                controller.show(near: anchor, usesVerticalText: usesVerticalText)
                XCTAssertEqual(controller.placementSide, .right)
                let compactFrame = try XCTUnwrap(controller.window?.frame)
                XCTAssertTrue(controller.navigate(.right))
                XCTAssertEqual(controller.placementSide, .right)
                XCTAssertTrue(controller.isFrameTransitionActive)
                controller.finishFrameTransition()
                XCTAssertEqual(controller.window?.frame.minX, compactFrame.minX)

                XCTAssertTrue(controller.navigate(.left))
                XCTAssertEqual(controller.placementSide, .right)
                XCTAssertTrue(controller.isFrameTransitionActive)
                controller.finishFrameTransition()
                XCTAssertEqual(controller.window?.frame, compactFrame)
            }
        }
    }

    func testInitialWidthFitsCandidatesBeyondFirstPage() throws {
        let configuration = CandidateConfiguration(
            orientation: .vertical, allowsExpansion: false, pageSize: 1)
        let candidates = (0..<20).map { Candidate(displayString: $0 == 19 ? "ＷＷＷＷ" : "iiii") }
        let controller = CandidateController(configuration: configuration)
        controller.replaceCandidates(candidates, initialSelectedIndex: 0)
        controller.show(near: NSRect(x: 400, y: 500, width: 20, height: 20))
        defer { controller.visible = false }

        let metrics = controller.metrics
        let widest = try XCTUnwrap(controller.currentLayout.item(for: 19))
        XCTAssertGreaterThan(
            widest.frame.width, ceil(metrics.width(of: "ＷＷＷＷ", font: metrics.candidateFont)))
        XCTAssertEqual(controller.window?.frame.size, controller.currentLayout.windowSize)
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
}
