// Copyright (c) 2026 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import AppKit
import CandidateKit

@MainActor
final class PlacementDebugOverlayController {
    struct Scenario {
        var shortcut: String
        var title: String
        var anchorRect: NSRect
        var compositionRect: NSRect?
        var placementSide: CandidatePlacementSide
    }

    private var overlayWindow: PlacementDebugPanel?
    nonisolated(unsafe) private var candidateWindowObservations: [NSObjectProtocol] = []

    deinit {
        for observation in candidateWindowObservations {
            NotificationCenter.default.removeObserver(observation)
        }
    }

    func show(
        scenario: Scenario,
        on screen: NSScreen,
        candidateWindow: NSWindow
    ) {
        stopObservingCandidateWindow()

        let overlayWindow = makeOverlayWindow(frame: screen.visibleFrame)
        guard let debugView = overlayWindow.contentView as? PlacementDebugView else {
            return
        }
        debugView.screenFrame = screen.visibleFrame
        debugView.scenario = scenario
        debugView.candidateWindow = candidateWindow
        debugView.needsDisplay = true

        observe(candidateWindow: candidateWindow, debugView: debugView)
        overlayWindow.orderFrontRegardless()
        self.overlayWindow = overlayWindow
    }

    func hide() {
        stopObservingCandidateWindow()
        overlayWindow?.orderOut(nil)
    }

    private func makeOverlayWindow(frame: NSRect) -> PlacementDebugPanel {
        if let overlayWindow, overlayWindow.frame == frame {
            return overlayWindow
        }

        overlayWindow?.orderOut(nil)
        let window = PlacementDebugPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 2)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = PlacementDebugView(frame: NSRect(origin: .zero, size: frame.size))
        return window
    }

    private func observe(candidateWindow: NSWindow, debugView: PlacementDebugView) {
        let notifications: [Notification.Name] = [
            NSWindow.didMoveNotification,
            NSWindow.didResizeNotification,
        ]
        candidateWindowObservations = notifications.map { name in
            NotificationCenter.default.addObserver(
                forName: name,
                object: candidateWindow,
                queue: .main
            ) { [weak debugView] _ in
                MainActor.assumeIsolated {
                    debugView?.needsDisplay = true
                }
            }
        }
    }

    private func stopObservingCandidateWindow() {
        for observation in candidateWindowObservations {
            NotificationCenter.default.removeObserver(observation)
        }
        candidateWindowObservations.removeAll()
    }
}

private final class PlacementDebugPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

@MainActor
private final class PlacementDebugView: NSView {
    var screenFrame = NSRect.zero
    var scenario: PlacementDebugOverlayController.Scenario?
    weak var candidateWindow: NSWindow?

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.clear.setFill()
        dirtyRect.fill(using: .copy)
        guard let scenario, let candidateWindow else {
            return
        }

        let candidateRect = localRect(candidateWindow.frame)
        let anchorRect = localRect(scenario.anchorRect)
        let compositionRect = scenario.compositionRect.map(localRect)
        let referenceRect = compositionRect ?? anchorRect
        let referenceLabelRect: NSRect
        if let compositionRect = scenario.compositionRect {
            referenceLabelRect = drawReference(
                rect: localRect(compositionRect),
                color: .systemPurple,
                label: "TALL COMPOSITION",
                side: scenario.placementSide,
                candidateRect: candidateRect
            )
        } else {
            referenceLabelRect = drawReference(
                rect: anchorRect,
                color: .systemOrange,
                label: "ANCHOR 20 × 20 pt",
                side: scenario.placementSide,
                candidateRect: candidateRect
            )
        }

        drawCandidateOutline(candidateRect)
        let gapLabelRect = drawGap(
            side: scenario.placementSide,
            anchorRect: anchorRect,
            compositionRect: compositionRect,
            candidateRect: candidateRect,
            avoiding: [referenceRect, referenceLabelRect, candidateRect]
        )
        let headerObstructions =
            [referenceRect, referenceLabelRect, candidateRect]
            + [gapLabelRect].compactMap { $0 }
        drawHeader(for: scenario, avoiding: headerObstructions)
    }

    private func localRect(_ screenRect: NSRect) -> NSRect {
        screenRect.offsetBy(dx: -screenFrame.minX, dy: -screenFrame.minY)
    }

    @discardableResult
    private func drawReference(
        rect: NSRect,
        color: NSColor,
        label: String,
        side: CandidatePlacementSide,
        candidateRect: NSRect
    ) -> NSRect {
        color.withAlphaComponent(0.18).setFill()
        rect.fill()

        let path = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        let dash: [CGFloat] = [6, 4]
        path.setLineDash(dash, count: dash.count, phase: 0)
        path.lineWidth = 3
        color.setStroke()
        path.stroke()

        let labelSize = measuredBadgeSize(label, fontSize: 12)
        let verticalCenterOrigin = NSPoint(
            x: rect.maxX + 10,
            y: rect.midY - labelSize.height / 2
        )
        let preferredOrigins: [NSPoint]
        if rect.height > bounds.height / 2 {
            let leftOrigin = NSPoint(
                x: rect.minX - labelSize.width - 10,
                y: rect.midY - labelSize.height / 2
            )
            preferredOrigins =
                side == .left
                ? [leftOrigin, verticalCenterOrigin]
                : [verticalCenterOrigin, leftOrigin]
        } else if side == .below {
            preferredOrigins = [
                NSPoint(x: rect.minX, y: rect.maxY + 8),
                verticalCenterOrigin,
                NSPoint(
                    x: rect.minX - labelSize.width - 10,
                    y: rect.midY - labelSize.height / 2
                ),
            ]
        } else {
            preferredOrigins = [
                NSPoint(x: rect.minX, y: rect.minY - labelSize.height - 8),
                verticalCenterOrigin,
                NSPoint(
                    x: rect.minX - labelSize.width - 10,
                    y: rect.midY - labelSize.height / 2
                ),
                NSPoint(x: rect.minX, y: rect.maxY + 8),
            ]
        }
        let labelOrigin = availableBadgeOrigin(
            size: labelSize,
            preferredOrigins: preferredOrigins,
            avoiding: [rect, candidateRect]
        )
        return drawBadge(
            label,
            preferredOrigin: labelOrigin,
            backgroundColor: color,
            fontSize: 12
        )
    }

    private func drawCandidateOutline(_ rect: NSRect) {
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: -2, dy: -2), xRadius: 9, yRadius: 9)
        path.lineWidth = 3
        NSColor.systemGreen.setStroke()
        path.stroke()
    }

    private func drawGap(
        side: CandidatePlacementSide,
        anchorRect: NSRect,
        compositionRect: NSRect?,
        candidateRect: NSRect,
        avoiding obstructions: [NSRect]
    ) -> NSRect? {
        let start: NSPoint
        let end: NSPoint
        let horizontal: Bool

        switch side {
        case .below:
            let x = anchorRect.maxX + 8
            start = NSPoint(x: x, y: candidateRect.maxY)
            end = NSPoint(x: x, y: anchorRect.minY)
            horizontal = false
        case .above:
            let x = anchorRect.maxX + 8
            start = NSPoint(x: x, y: anchorRect.maxY)
            end = NSPoint(x: x, y: candidateRect.minY)
            horizontal = false
        case .left:
            guard let compositionRect else { return nil }
            let y = candidateRect.minY - 12
            start = NSPoint(x: candidateRect.maxX, y: y)
            end = NSPoint(x: compositionRect.minX, y: y)
            horizontal = true
        case .right:
            guard let compositionRect else { return nil }
            let y = candidateRect.minY - 12
            start = NSPoint(x: compositionRect.maxX, y: y)
            end = NSPoint(x: candidateRect.minX, y: y)
            horizontal = true
        }

        let distance = horizontal ? abs(end.x - start.x) : abs(end.y - start.y)
        drawDimensionLine(from: start, to: end, horizontal: horizontal)

        let label = String(format: "%.1f pt GAP", distance)
        let labelSize = measuredBadgeSize(label, fontSize: 11)
        let preferredOrigins: [NSPoint]
        switch side {
        case .below:
            preferredOrigins = [
                NSPoint(x: candidateRect.minX, y: candidateRect.minY - labelSize.height - 10),
                NSPoint(
                    x: candidateRect.maxX + 10,
                    y: candidateRect.midY - labelSize.height / 2
                ),
                NSPoint(x: anchorRect.maxX + 16, y: anchorRect.maxY + 10),
            ]
        case .above:
            preferredOrigins = [
                NSPoint(x: candidateRect.minX, y: candidateRect.maxY + 10),
                NSPoint(
                    x: candidateRect.maxX + 10,
                    y: candidateRect.midY - labelSize.height / 2
                ),
                NSPoint(x: anchorRect.maxX + 16, y: anchorRect.minY - labelSize.height - 10),
            ]
        case .left:
            preferredOrigins = [
                NSPoint(
                    x: candidateRect.maxX - labelSize.width - 12,
                    y: candidateRect.minY - labelSize.height - 10
                ),
                NSPoint(x: candidateRect.minX, y: candidateRect.maxY + 10),
                NSPoint(
                    x: candidateRect.minX - labelSize.width - 10,
                    y: candidateRect.midY - labelSize.height / 2
                ),
            ]
        case .right:
            preferredOrigins = [
                NSPoint(
                    x: candidateRect.minX + 12,
                    y: candidateRect.minY - labelSize.height - 10
                ),
                NSPoint(x: candidateRect.minX, y: candidateRect.maxY + 10),
                NSPoint(
                    x: candidateRect.maxX + 10,
                    y: candidateRect.midY - labelSize.height / 2
                ),
            ]
        }
        let labelOrigin = availableBadgeOrigin(
            size: labelSize,
            preferredOrigins: preferredOrigins,
            avoiding: obstructions
        )
        return drawBadge(
            label,
            preferredOrigin: labelOrigin,
            backgroundColor: .systemRed,
            fontSize: 11
        )
    }

    private func drawDimensionLine(
        from start: NSPoint,
        to end: NSPoint,
        horizontal: Bool
    ) {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        let tick: CGFloat = 4
        if horizontal {
            path.move(to: NSPoint(x: start.x, y: start.y - tick))
            path.line(to: NSPoint(x: start.x, y: start.y + tick))
            path.move(to: NSPoint(x: end.x, y: end.y - tick))
            path.line(to: NSPoint(x: end.x, y: end.y + tick))
        } else {
            path.move(to: NSPoint(x: start.x - tick, y: start.y))
            path.line(to: NSPoint(x: start.x + tick, y: start.y))
            path.move(to: NSPoint(x: end.x - tick, y: end.y))
            path.line(to: NSPoint(x: end.x + tick, y: end.y))
        }
        path.lineWidth = 2
        NSColor.systemRed.setStroke()
        path.stroke()
    }

    private func drawHeader(
        for scenario: PlacementDebugOverlayController.Scenario,
        avoiding obstructions: [NSRect]
    ) {
        let title =
            "\(scenario.shortcut)  •  \(scenario.title)  •  "
            + "RESULT: \(scenario.placementSide.debugName)"
        let detail =
            scenario.compositionRect == nil
            ? "Orange: anchor   Green: candidate window   Red: measured gap"
            : "Purple: tall composition   Vertical space outside it: 10 pt at top and bottom   Green: candidate window"
        let titleSize = measuredBadgeSize(title, fontSize: 14)
        let detailSize = measuredBadgeSize(detail, fontSize: 12)
        let groupSize = NSSize(
            width: max(titleSize.width, detailSize.width),
            height: titleSize.height + detailSize.height + 6
        )
        let groupOrigin = headerOrigin(
            size: groupSize,
            avoiding: obstructions
        )
        drawBadge(
            title,
            preferredOrigin: NSPoint(x: groupOrigin.x, y: groupOrigin.y + detailSize.height + 6),
            backgroundColor: NSColor.black.withAlphaComponent(0.82),
            fontSize: 14
        )
        drawBadge(
            detail,
            preferredOrigin: groupOrigin,
            backgroundColor: NSColor.black.withAlphaComponent(0.72),
            fontSize: 12
        )
    }

    private func headerOrigin(size: NSSize, avoiding obstructions: [NSRect]) -> NSPoint {
        let margin: CGFloat = 16
        let origins = [
            NSPoint(x: bounds.minX + margin, y: bounds.maxY - size.height - margin),
            NSPoint(x: bounds.maxX - size.width - margin, y: bounds.maxY - size.height - margin),
            NSPoint(x: bounds.minX + margin, y: bounds.minY + margin),
            NSPoint(x: bounds.maxX - size.width - margin, y: bounds.minY + margin),
        ]
        return origins.first { origin in
            let rect = NSRect(origin: origin, size: size)
            return obstructions.allSatisfy { !rect.intersects($0.insetBy(dx: -12, dy: -12)) }
        } ?? origins[0]
    }

    private func availableBadgeOrigin(
        size: NSSize,
        preferredOrigins: [NSPoint],
        avoiding obstructions: [NSRect]
    ) -> NSPoint {
        let margin: CGFloat = 8
        let cornerOrigins = [
            NSPoint(x: bounds.minX + margin, y: bounds.minY + margin),
            NSPoint(x: bounds.maxX - size.width - margin, y: bounds.minY + margin),
            NSPoint(x: bounds.minX + margin, y: bounds.maxY - size.height - margin),
            NSPoint(x: bounds.maxX - size.width - margin, y: bounds.maxY - size.height - margin),
        ]
        let candidateOrigins = (preferredOrigins + cornerOrigins).map {
            constrainedBadgeOrigin($0, size: size)
        }
        let expandedObstructions = obstructions.map { $0.insetBy(dx: -6, dy: -6) }
        if let available = candidateOrigins.first(where: { origin in
            let rect = NSRect(origin: origin, size: size)
            return expandedObstructions.allSatisfy { !rect.intersects($0) }
        }) {
            return available
        }
        return candidateOrigins.min { lhs, rhs in
            let lhsArea = totalIntersectionArea(
                of: NSRect(origin: lhs, size: size),
                with: expandedObstructions
            )
            let rhsArea = totalIntersectionArea(
                of: NSRect(origin: rhs, size: size),
                with: expandedObstructions
            )
            return lhsArea < rhsArea
        } ?? constrainedBadgeOrigin(.zero, size: size)
    }

    private func totalIntersectionArea(of rect: NSRect, with obstructions: [NSRect]) -> CGFloat {
        obstructions.reduce(0) { result, obstruction in
            let intersection = rect.intersection(obstruction)
            guard !intersection.isNull else {
                return result
            }
            return result + max(intersection.width, 0) * max(intersection.height, 0)
        }
    }

    private func constrainedBadgeOrigin(_ preferredOrigin: NSPoint, size: NSSize) -> NSPoint {
        NSPoint(
            x: min(max(preferredOrigin.x, bounds.minX + 8), bounds.maxX - size.width - 8),
            y: min(max(preferredOrigin.y, bounds.minY + 8), bounds.maxY - size.height - 8)
        )
    }

    @discardableResult
    private func drawBadge(
        _ text: String,
        preferredOrigin: NSPoint,
        backgroundColor: NSColor,
        fontSize: CGFloat
    ) -> NSRect {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let padding = NSSize(width: 9, height: 5)
        let size = NSSize(
            width: ceil(textSize.width) + padding.width * 2,
            height: ceil(textSize.height) + padding.height * 2
        )
        let origin = constrainedBadgeOrigin(preferredOrigin, size: size)
        let rect = NSRect(origin: origin, size: size)
        backgroundColor.setFill()
        NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()
        (text as NSString).draw(
            at: NSPoint(x: rect.minX + padding.width, y: rect.minY + padding.height),
            withAttributes: attributes
        )
        return rect
    }

    private func measuredBadgeSize(_ text: String, fontSize: CGFloat) -> NSSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        ]
        let textSize = (text as NSString).size(withAttributes: attributes)
        return NSSize(width: ceil(textSize.width) + 18, height: ceil(textSize.height) + 10)
    }
}

extension CandidatePlacementSide {
    fileprivate var debugName: String {
        switch self {
        case .below:
            "BELOW ANCHOR"
        case .above:
            "ABOVE ANCHOR"
        case .left:
            "LEFT OF COMPOSITION"
        case .right:
            "RIGHT OF COMPOSITION"
        }
    }
}
