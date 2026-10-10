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

// AppKit invokes these synchronous callbacks on the main thread, but its older
// accessibility declarations are not actor-isolated. No value leaves this thread.
private struct AccessibilityValue<Value>: @unchecked Sendable { let value: Value }
private func accessibilityUI<Element, Value>(
    _ element: Element, _ operation: @MainActor @Sendable (Element) -> Value
) -> Value {
    let input = AccessibilityValue(value: element)
    return MainActor.assumeIsolated { AccessibilityValue(value: operation(input.value)) }.value
}

// These elements survive view rebuilds so VoiceOver can keep its current position.
@MainActor
internal final class CandidateAccessibilityItem: NSAccessibilityElement {
    weak var controller: CandidateController?
    let index: Int
    private let candidate: Candidate
    private lazy var spokenLabel: String = {
        guard let controller, let reading = candidate.accessibilityReading ?? candidate.detail,
            let explanation = controller.delegate?.candidateController(
                controller, requestExplanationFor: candidate.displayString, reading: reading),
            !explanation.isEmpty
        else { return candidate.displayString }
        return explanation
    }()

    init(controller: CandidateController, index: Int, candidate: Candidate) {
        self.controller = controller
        self.index = index
        self.candidate = candidate
        super.init()
    }

    private var isCurrent: Bool {
        guard let controller, controller.visible, controller.candidates.indices.contains(index) else { return false }
        return controller.candidates[index] === candidate
    }

    override func isAccessibilityElement() -> Bool { accessibilityUI(self) { $0.isCurrent } }
    override func accessibilityRole() -> NSAccessibility.Role? { .row }
    override func accessibilityParent() -> Any? { accessibilityUI(self) { $0.controller?.canvasView } }
    override func accessibilityWindow() -> Any? { accessibilityUI(self) { $0.controller?.window } }
    override func accessibilityTopLevelUIElement() -> Any? { accessibilityUI(self) { $0.controller?.window } }
    override func accessibilityLabel() -> String? { accessibilityUI(self) { $0.spokenLabel } }
    override func accessibilityIndex() -> Int { index }
    override func accessibilityCustomActions() -> [NSAccessibilityCustomAction]? {
        accessibilityUI(self) { $0.controller?.accessibilityNavigationActions }
    }
    override func isAccessibilitySelected() -> Bool { accessibilityUI(self) { $0.isCurrent && $0.controller?.selectionIndex == $0.index } }
    override func isAccessibilityFocused() -> Bool { isAccessibilitySelected() }

    override func accessibilityHelp() -> String? {
        accessibilityUI(self) { element in
            guard let controller = element.controller else { return nil }
            let label = controller.renderer[element.index]?.indexText ?? ""
            return [label, element.candidate.accessibilityReading ?? element.candidate.detail ?? ""]
                .filter { !$0.isEmpty }.joined(separator: ", ")
        }
    }

    override func accessibilityFrame() -> NSRect {
        accessibilityUI(self) { element in
            guard element.isCurrent, let controller = element.controller, let view = controller.renderer[element.index],
                let window = view.window else { return .zero }
            let rect = view.convert(view.bounds, to: nil)
            return window.convertToScreen(rect)
        }
    }

    override func setAccessibilityFocused(_ focused: Bool) {
        accessibilityUI(self) { if focused && $0.isCurrent { $0.controller?.setSelection($0.index) } }
    }

    override func setAccessibilitySelected(_ selected: Bool) {
        accessibilityUI(self) { if selected && $0.isCurrent { $0.controller?.setSelection($0.index) } }
    }

    override func accessibilityPerformPress() -> Bool {
        accessibilityUI(self) { element in
            guard element.isCurrent, let controller = element.controller else { return false }
            controller.setSelection(element.index)
            controller.confirmCandidate(at: element.index)
            return true
        }
    }
}

@MainActor
internal final class CandidateAccessibilityButton: NSAccessibilityElement {
    weak var view: NSView?
    let rect: NSRect
    let action: () -> Void

    init(view: NSView, title: String, rect: NSRect, enabled: Bool, action: @escaping () -> Void) {
        self.view = view
        self.rect = rect
        self.action = action
        super.init()
        setAccessibilityRole(.button)
        setAccessibilityLabel(title)
        setAccessibilityEnabled(enabled)
        setAccessibilityParent(view)
    }

    override func accessibilityFrame() -> NSRect {
        accessibilityUI(self) { element in
            guard let view = element.view, let window = view.window else { return .zero }
            return window.convertToScreen(view.convert(element.rect, to: nil))
        }
    }

    override func accessibilityParent() -> Any? {
        accessibilityUI(self) { $0.view?.superview }
    }

    override func accessibilityPerformPress() -> Bool {
        accessibilityUI(self) { element in
            guard element.isAccessibilityEnabled(), element.view?.window?.isVisible == true else { return false }
            element.action()
            return true
        }
    }
}

extension CandidateController {
    internal var accessibilityNavigationActions: [NSAccessibilityCustomAction] {
        guard visible else { return [] }
        var actions = [
            NSAccessibilityCustomAction(name: NSLocalizedString("Previous Page", bundle: .module, comment: "Candidate accessibility action")) { [weak self] in
                self?.navigate(.pageUp) == true
            },
            NSAccessibilityCustomAction(name: NSLocalizedString("Next Page", bundle: .module, comment: "Candidate accessibility action")) { [weak self] in
                self?.navigate(.pageDown) == true
            },
        ]
        if configuration.allowsExpansion, candidates.count > collapsedNavigationRow.items.count {
            let expanded = isExpanded
            actions.insert(NSAccessibilityCustomAction(
                name: expanded
                    ? NSLocalizedString("Collapse", bundle: .module, comment: "Candidate accessibility action")
                    : NSLocalizedString("Expand", bundle: .module, comment: "Candidate accessibility action")
            ) { [weak self] in
                guard let self, self.visible else { return false }
                if expanded { self.collapseExpandable() }
                else { self.expandExpandable(selecting: max(self.selectionIndex, 0)) }
                return true
            }, at: 0)
        }
        return actions
    }

    internal func resetAccessibilityItems() {
        accessibilityItems = candidates.enumerated().map {
            CandidateAccessibilityItem(controller: self, index: $0.offset, candidate: $0.element)
        }
    }

    internal var accessibilityChildren: [CandidateAccessibilityItem] {
        guard visible else { return [] }
        return currentLayout.items.compactMap { item in
            accessibilityItems.indices.contains(item.candidateIndex)
                ? accessibilityItems[item.candidateIndex] : nil
        }
    }

    internal func notifyAccessibilitySelection() {
        guard visible else { return }
        NSAccessibility.post(element: canvasView, notification: .selectedChildrenChanged)
        if accessibilityItems.indices.contains(selectionIndex) {
            NSAccessibility.post(element: accessibilityItems[selectionIndex], notification: .focusedUIElementChanged)
        }
    }

    internal func notifyAccessibilityPresentation(wasVisible: Bool) {
        guard !wasVisible, visible, let window else { return }
        NSAccessibility.post(element: window, notification: .created)
        NSAccessibility.post(element: window, notification: .focusedWindowChanged)
        notifyAccessibilitySelection()
    }
}
