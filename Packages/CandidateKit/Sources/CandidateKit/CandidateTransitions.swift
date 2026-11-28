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
import QuartzCore

@objc(CKCandidatePlacementSide)
public enum CandidatePlacementSide: Int, Sendable {
    case below
    case above
    case left
    case right
}

internal struct CandidateScreenGeometry: Equatable {
    var frame: NSRect
    var visibleFrame: NSRect
}

internal struct CandidatePlacementResult: Equatable {
    var topLeft: NSPoint
    var side: CandidatePlacementSide
}

internal struct CandidatePlacementContext {
    var anchorRect: NSRect
    var usesVerticalText: Bool
    var compositionRect: NSRect?
    var compositionLeadingX: CGFloat?
    var compositionTrailingXProvider: (() -> CGFloat)?
}

internal enum CandidatePlacementEngine {
    static let anchorGap: CGFloat = 5

    static func screen(
        for anchorRect: NSRect,
        screens: [CandidateScreenGeometry],
        fallback: CandidateScreenGeometry?
    ) -> CandidateScreenGeometry {
        var intersecting: CandidateScreenGeometry?
        var largestArea: CGFloat = 0
        for screen in screens {
            if screen.frame.contains(anchorRect.origin) { return screen }
            let area = intersectionArea(screen.frame, anchorRect)
            if area > largestArea {
                largestArea = area
                intersecting = screen
            }
        }
        return intersecting ?? fallback
            ?? CandidateScreenGeometry(frame: .zero, visibleFrame: .zero)
    }

    static func place(
        windowSize: NSSize,
        requiredSize: NSSize? = nil,
        anchorRect: NSRect,
        screen: CandidateScreenGeometry,
        usesVerticalText: Bool = false,
        compositionRect: NSRect? = nil,
        compositionLeadingX: CGFloat,
        compositionTrailingX: () -> CGFloat
    ) -> CandidatePlacementResult {
        let bounds = screen.visibleFrame
        let requiredSize = NSSize(
            width: max(windowSize.width, requiredSize?.width ?? windowSize.width),
            height: max(windowSize.height, requiredSize?.height ?? windowSize.height))
        let textRect = usesVerticalText ? compositionRect ?? anchorRect : anchorRect
        let sides: [CandidatePlacementSide] =
            usesVerticalText ? [.left, .right, .below, .above] : [.below, .above, .left, .right]
        let sideTop = anchorRect.maxY
        var placement: (CandidatePlacementSide, NSPoint) = (.below, anchorRect.origin)
        for side in sides {
            let point: NSPoint
            let fits: Bool
            switch side {
            case .below:
                point = NSPoint(x: anchorRect.minX, y: textRect.minY - anchorGap)
                fits = point.y - requiredSize.height >= bounds.minY
            case .above:
                point = NSPoint(
                    x: anchorRect.minX, y: textRect.maxY + anchorGap + windowSize.height)
                fits = textRect.maxY + anchorGap + requiredSize.height <= bounds.maxY
            case .left:
                let leadingX = usesVerticalText ? textRect.minX : compositionLeadingX
                point = NSPoint(x: leadingX - anchorGap - windowSize.width, y: sideTop)
                fits = leadingX - anchorGap - requiredSize.width >= bounds.minX
            case .right:
                // Resolve the host's trailing edge only when right-side placement is necessary.
                let trailingX = usesVerticalText ? textRect.maxX : compositionTrailingX()
                point = NSPoint(x: trailingX + anchorGap, y: sideTop)
                fits = point.x + requiredSize.width <= bounds.maxX
            }
            placement = (side, point)
            if fits { break }
        }
        let fitted = fittedTopLeft(placement.1, windowSize: windowSize, bounds: bounds)
        return CandidatePlacementResult(topLeft: fitted, side: placement.0)
    }

    static func fittedTopLeft(_ point: NSPoint, windowSize: NSSize, bounds: NSRect) -> NSPoint {
        NSPoint(
            x: max(bounds.minX, min(point.x, bounds.maxX - windowSize.width)),
            y: min(bounds.maxY, max(point.y, bounds.minY + windowSize.height))
        )
    }

    private static func intersectionArea(_ lhs: NSRect, _ rhs: NSRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        return intersection.width * intersection.height
    }
}

extension NSRect {
    static func interpolated(from start: NSRect, to end: NSRect, progress: CGFloat) -> NSRect {
        NSRect(
            x: start.origin.x + (end.origin.x - start.origin.x) * progress,
            y: start.origin.y + (end.origin.y - start.origin.y) * progress,
            width: start.width + (end.width - start.width) * progress,
            height: start.height + (end.height - start.height) * progress
        )
    }
}

@MainActor
internal final class CandidateTransitionDriver {
    private let duration: TimeInterval
    private weak var window: NSWindow?
    private let update: (CGFloat) -> Void
    private let completion: () -> Void
    private var windowDisplayLink: AnyObject?
    private var fallbackTimer: Timer?
    private var startingTime: CFTimeInterval = 0
    private var hasCompleted = false

    init(
        duration: TimeInterval,
        window: NSWindow?,
        update: @escaping (CGFloat) -> Void,
        completion: @escaping () -> Void
    ) {
        self.duration = duration
        self.window = window
        self.update = update
        self.completion = completion
    }

    func start() {
        guard duration > 0 else {
            finish()
            return
        }
        startingTime = CACurrentMediaTime()
        update(0)
        if #available(macOS 14.0, *), let window {
            let displayLink = window.displayLink(
                target: self,
                selector: #selector(windowDisplayLinkDidFire)
            )
            displayLink.add(to: .main, forMode: .common)
            windowDisplayLink = displayLink
            return
        }

        // macOS 13 has no window display link, so a timer drives the frames there.
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        fallbackTimer = timer
    }

    func finish() {
        guard !hasCompleted else {
            return
        }
        hasCompleted = true
        stopDisplayLink()
        update(1)
        completion()
    }

    private func tick() {
        guard !hasCompleted else {
            return
        }
        let elapsed = CACurrentMediaTime() - startingTime
        let linearProgress = min(max(elapsed / duration, 0), 1)
        if linearProgress >= 1 {
            finish()
        } else {
            // Ease in and out along a half cosine wave.
            update((1 - cos(.pi * linearProgress)) / 2)
        }
    }

    private func stopDisplayLink() {
        if #available(macOS 14.0, *) {
            (windowDisplayLink as? CADisplayLink)?.invalidate()
        }
        windowDisplayLink = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    @objc private func windowDisplayLinkDidFire() {
        tick()
    }
}
