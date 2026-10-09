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
import CoreVideo
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
    var screen: CandidateScreenGeometry
}

internal struct CandidatePlacementContext {
    var anchorRect: NSRect
    var compositionLeadingX: CGFloat?
    var compositionTrailingXProvider: (() -> CGFloat)?

    func clearingCompositionEdges() -> CandidatePlacementContext {
        CandidatePlacementContext(
            anchorRect: anchorRect,
            compositionLeadingX: nil,
            compositionTrailingXProvider: nil
        )
    }
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
        return intersecting ?? fallback ?? CandidateScreenGeometry(frame: .zero, visibleFrame: .zero)
    }

    static func place(
        windowSize: NSSize,
        anchorRect: NSRect,
        screen: CandidateScreenGeometry,
        compositionLeadingX: CGFloat,
        compositionTrailingX: () -> CGFloat
    ) -> CandidatePlacementResult {
        let bounds = screen.visibleFrame
        let below = NSPoint(x: anchorRect.minX, y: anchorRect.minY - anchorGap)
        let above = NSPoint(x: anchorRect.minX, y: anchorRect.maxY + anchorGap + windowSize.height)
        let verticalOptions: [(CandidatePlacementSide, NSPoint, Bool)] = [
            (.below, below, below.y - windowSize.height >= bounds.minY),
            (.above, above, above.y <= bounds.maxY),
        ]
        let placement: (CandidatePlacementSide, NSPoint)
        if let option = verticalOptions.first(where: { $0.2 }) {
            placement = (option.0, option.1)
        } else {
            let sideTop = max(anchorRect.maxY, bounds.minY + windowSize.height)
            let left = compositionLeadingX - anchorGap - windowSize.width
            // Resolve the host's trailing edge only when right-side placement is necessary.
            placement = left >= bounds.minX
                ? (.left, NSPoint(x: left, y: sideTop))
                : (.right, NSPoint(x: compositionTrailingX() + anchorGap, y: sideTop))
        }
        let fitted = fittedTopLeft(placement.1, windowSize: windowSize, bounds: bounds)
        return CandidatePlacementResult(topLeft: fitted, side: placement.0, screen: screen)
    }

    static func fittedTopLeft(_ point: NSPoint, windowSize: NSSize, bounds: NSRect) -> NSPoint {
        NSPoint(
            x: max(bounds.minX, min(point.x, bounds.maxX - windowSize.width)),
            y: min(bounds.maxY, max(point.y, bounds.minY + windowSize.height))
        )
    }

    static func shouldAnimateMovement(from start: NSPoint, to end: NSPoint, rowHeight: CGFloat) -> Bool {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        // Measure travel in candidate-row units so the threshold follows the visible type scale.
        guard rowHeight.isFinite, rowHeight > 0 else { return false }
        return hypot(deltaX, deltaY) / rowHeight > 1
    }

    private static func intersectionArea(_ lhs: NSRect, _ rhs: NSRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else {
            return 0
        }
        return max(intersection.width, 0) * max(intersection.height, 0)
    }
}

internal enum CandidateMotionCurve {
    static func value(at progress: CGFloat) -> CGFloat {
        let phase = min(max(progress, 0), 1)
        return (1 - cos(.pi * phase)) / 2
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

internal enum CandidateWindowFrameInterpolator {
    static func interpolated(
        from start: NSRect,
        to end: NSRect,
        progress: CGFloat
    ) -> NSRect {
        let left = interpolate(start.minX, end.minX, progress: progress)
        let top = interpolate(start.maxY, end.maxY, progress: progress)
        let width = interpolate(start.width, end.width, progress: progress)
        let height = interpolate(start.height, end.height, progress: progress)
        return NSRect(
            x: left,
            y: top - height,
            width: width,
            height: height
        )
    }

    private static func interpolate(_ start: CGFloat, _ end: CGFloat, progress: CGFloat) -> CGFloat
    {
        start + (end - start) * progress
    }

}

@MainActor
internal protocol CandidateTransitionClock: AnyObject {
    var now: CFTimeInterval { get }
    func start(onFrame: @escaping @MainActor () -> Void)
    func stop()
}

@MainActor
internal final class CandidateTransitionDriver {
    private final class DisplayLinkCallbackProxy: @unchecked Sendable {
        private let lock = NSLock()
        private let onFrame: @MainActor () -> Void
        private var isMainThreadUpdatePending = false

        init(onFrame: @escaping @MainActor () -> Void) {
            self.onFrame = onFrame
        }

        func requestFrame() {
            lock.lock()
            guard !isMainThreadUpdatePending else {
                lock.unlock()
                return
            }
            isMainThreadUpdatePending = true
            lock.unlock()

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.lock.lock()
                self.isMainThreadUpdatePending = false
                self.lock.unlock()
                self.onFrame()
            }
        }
    }

    private let duration: TimeInterval
    private let clock: (any CandidateTransitionClock)?
    private weak var window: NSWindow?
    private let update: (CGFloat) -> Void
    private let completion: () -> Void
    private var windowDisplayLink: AnyObject?
    private var legacyDisplayLink: CVDisplayLink?
    private var displayLinkCallbackProxy: DisplayLinkCallbackProxy?
    private var startingTime: CFTimeInterval = 0
    private var hasCompleted = false

    init(
        duration: TimeInterval,
        window: NSWindow?,
        clock: (any CandidateTransitionClock)? = nil,
        update: @escaping (CGFloat) -> Void,
        completion: @escaping () -> Void
    ) {
        self.duration = duration
        self.clock = clock
        self.window = window
        self.update = update
        self.completion = completion
    }

    func start() {
        guard duration > 0 else {
            complete()
            return
        }
        startingTime = clock?.now ?? CACurrentMediaTime()
        update(0)
        if let clock {
            clock.start { [weak self] in self?.tick() }
            return
        }
        if #available(macOS 14.0, *), let window {
            let displayLink = window.displayLink(
                target: self,
                selector: #selector(windowDisplayLinkDidFire)
            )
            displayLink.add(to: .main, forMode: .common)
            windowDisplayLink = displayLink
            return
        }

        startLegacyDisplayLink()
    }

    private func startLegacyDisplayLink() {
        let callbackProxy = DisplayLinkCallbackProxy { [weak self] in
            self?.tick()
        }
        var newDisplayLink: CVDisplayLink?
        let displayID =
            (window?.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
            as? NSNumber)?.uint32Value
            ?? CGMainDisplayID()
        guard CVDisplayLinkCreateWithCGDisplay(displayID, &newDisplayLink) == kCVReturnSuccess,
            let newDisplayLink
        else {
            complete()
            return
        }
        displayLinkCallbackProxy = callbackProxy
        legacyDisplayLink = newDisplayLink
        let callbackResult = CVDisplayLinkSetOutputCallback(
            newDisplayLink,
            { _, _, _, _, _, userInfo in
                guard let userInfo else { return kCVReturnSuccess }
                let callbackProxy = Unmanaged<DisplayLinkCallbackProxy>
                    .fromOpaque(userInfo)
                    .takeUnretainedValue()
                callbackProxy.requestFrame()
                return kCVReturnSuccess
            },
            Unmanaged.passUnretained(callbackProxy).toOpaque()
        )
        guard callbackResult == kCVReturnSuccess,
            CVDisplayLinkStart(newDisplayLink) == kCVReturnSuccess
        else {
            stopDisplayLink()
            complete()
            return
        }
    }

    func finish() {
        guard !hasCompleted else {
            return
        }
        stopDisplayLink()
        complete()
    }

    func cancel() {
        guard !hasCompleted else {
            return
        }
        hasCompleted = true
        stopDisplayLink()
    }

    private func tick() {
        guard !hasCompleted else {
            return
        }
        let elapsed = (clock?.now ?? CACurrentMediaTime()) - startingTime
        let linearProgress = min(max(elapsed / duration, 0), 1)
        if linearProgress >= 1 {
            complete()
        } else {
            update(CandidateMotionCurve.value(at: linearProgress))
        }
    }

    private func complete() {
        guard !hasCompleted else {
            return
        }
        hasCompleted = true
        stopDisplayLink()
        update(1)
        completion()
    }

    private func stopDisplayLink() {
        clock?.stop()
        if #available(macOS 14.0, *) {
            (windowDisplayLink as? CADisplayLink)?.invalidate()
        }
        windowDisplayLink = nil
        guard let legacyDisplayLink else {
            displayLinkCallbackProxy = nil
            return
        }
        CVDisplayLinkStop(legacyDisplayLink)
        CVDisplayLinkSetOutputCallback(legacyDisplayLink, nil, nil)
        self.legacyDisplayLink = nil
        displayLinkCallbackProxy = nil
    }

    @objc private func windowDisplayLinkDidFire() {
        tick()
    }
}
