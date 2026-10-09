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
@_spi(CandidatePreview) import CandidateKit

@MainActor
final class PreviewAppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private let controller = CandidateController()
    private var eventMonitor: Any?
    private var keyReceiverWindow: NSWindow?
    private var previewAppearance: NSAppearance?
    private var backgroundWindow: NSWindow?
    private var backgroundIndex = 0
    private var sample = PreviewSample.candidates
    private var selectionKeys = "123456789"
    private let fontSizes: [CGFloat] = [12, 16, 24, 32]
    private let keySets = ["123456789", "asdfzxcvb"]
    private lazy var accentPreview = AccentPreviewController { [weak self] color in
        self?.controller.previewAccent(color)
    }
    private let placementDebugOverlay = PlacementDebugOverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        application.mainMenu = makeMainMenu()
        installKeyReceiverWindow()
        installEventMonitor()
        application.activate(ignoringOtherApps: true)
        controller.onSelectionChange = { text, index, _ in print("Highlighted \(index): \(text)") }
        controller.onConfirmation = { text, index, _ in print("Confirmed \(index): \(text)") }
        configureFromArguments()
        print("CandidatePreview controls:")
        print("  Arrows, Page Up/Down, Home/End, Tab/Shift-Tab: navigate")
        print("  Selection keys and Return: confirm; action samples use the displayed Shift hints")
        print("  Command-1/2: horizontal/vertical; Command-3/4: expandable/paged")
        print("  Command-0: center; Command-5/6/7: above/left/right placement; Command-8: hide guides")
        print("  Samples: switch candidate data; Layout: choose font size and selection keys")
        print("  Appearance: choose theme, backdrop, or accent color comparison")
        print("  --sample=\(PreviewSample.allCases.map(\.rawValue).joined(separator: "|"))")
        print("  --vertical --paged --expanded --last --light --dark --letter-keys --font-size=24")
    }

    func applicationWillTerminate(_ notification: Notification) {
        placementDebugOverlay.hide()
        if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @objc private func selectOrientation(_ sender: NSMenuItem) {
        var configuration = controller.configuration
        configuration.orientation = sender.tag == 0 ? .horizontal : .vertical
        apply(configuration)
    }

    @objc private func selectDisplayMode(_ sender: NSMenuItem) {
        var configuration = controller.configuration
        configuration.allowsExpansion = sender.tag == 0
        apply(configuration)
    }

    @objc private func selectFontSize(_ sender: NSMenuItem) {
        var configuration = controller.configuration
        configuration.candidateFontSize = fontSizes[sender.tag]
        apply(configuration)
    }

    @objc private func selectKeys(_ sender: NSMenuItem) {
        selectionKeys = keySets[sender.tag]
        reloadSample()
    }

    @objc private func selectSample(_ sender: NSMenuItem) {
        sample = PreviewSample.allCases[sender.tag]
        reloadSample()
    }

    private func apply(_ configuration: CandidateConfiguration) {
        let labels = controller.keyLabels
        try! controller.apply(configuration: configuration)
        controller.keyLabels = labels
        centerCandidateWindow()
        controller.visible = true
        reportCandidateWindow()
    }

    private func reloadSample(initialSelectedIndex: Int = 0) {
        var configuration = controller.configuration
        configuration.indexLabels = sample == .associated ? "" : selectionKeys
        configuration.pageSize = selectionKeys.count
        configuration.showsKeyLabelsAsDetails = sample.usesShiftedKeys
        configuration.hostHandlesIndexLabelKeys = !sample.usesShiftedKeys
        controller.tooltip = sample.header
        try! controller.replaceCandidates(sample.entries, initialSelectedIndex: initialSelectedIndex,
            applying: configuration)
        controller.keyLabels = sample == .associated ? [] : selectionKeys.map {
            CandidateKeyLabel(key: String($0),
                displayedText: sample.usesShiftedKeys ? "⇧ \($0)" : String($0))
        }
        centerCandidateWindow()
        controller.visible = true
        reportCandidateWindow()
    }

    @objc private func centerCandidateWindow() {
        placementDebugOverlay.hide()
        controller.centerOnMainScreen()
    }

    @objc private func showAboveAnchor() {
        guard let screen = previewScreen else { return }
        showDebugPlacement(
            shortcut: "⌘5", title: "ABOVE ANCHOR",
            anchor: NSRect(x: screen.visibleFrame.midX, y: screen.visibleFrame.minY + 10,
                width: 20, height: 20),
            composition: nil, screen: screen)
    }

    @objc private func showLeftOfComposition() {
        guard let screen = previewScreen else { return }
        let frame = screen.visibleFrame
        let anchor = NSRect(x: frame.maxX - 30, y: frame.minY + 10,
            width: 20, height: frame.height - 20)
        showDebugPlacement(shortcut: "⌘6", title: "LEFT OF COMPOSITION",
            anchor: anchor, composition: anchor, screen: screen)
    }

    @objc private func showRightOfComposition() {
        guard let screen = previewScreen else { return }
        let frame = screen.visibleFrame
        let anchor = NSRect(x: frame.minX + 10, y: frame.minY + 10,
            width: 20, height: frame.height - 20)
        showDebugPlacement(shortcut: "⌘7", title: "RIGHT OF COMPOSITION",
            anchor: anchor, composition: anchor, screen: screen)
    }

    @objc private func hidePlacementDebugOverlay() { placementDebugOverlay.hide() }

    @objc private func selectAppearance(_ sender: NSMenuItem) {
        previewAppearance = sender.tag == 0 ? nil
            : NSAppearance(named: sender.tag == 1 ? .aqua : .darkAqua)
        synchronizePreviewTheme()
    }

    @objc private func selectBackground(_ sender: NSMenuItem) { showBackground(sender.tag) }

    @objc private func showAccentPreview() { accentPreview.show(on: previewScreen) }

    private func showBackground(_ index: Int) {
        backgroundIndex = index
        guard index != 0 else { backgroundWindow?.orderOut(nil); return }
        guard let screen = previewScreen else { return }
        let window = backgroundWindow ?? NSWindow(contentRect: screen.visibleFrame,
            styleMask: .borderless, backing: .buffered, defer: false)
        window.setFrame(screen.visibleFrame, display: false)
        window.backgroundColor = index == 1 ? .white : .black
        window.isOpaque = true
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .normal
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        backgroundWindow = window
    }

    private var previewScreen: NSScreen? { controller.window?.screen ?? NSScreen.main }

    private func synchronizePreviewTheme() {
        controller.synchronizeTheme(clientAppearance: previewAppearance,
            clientBundleIdentifier: Bundle.main.bundleIdentifier)
        accentPreview.refresh()
    }

    private func showDebugPlacement(
        shortcut: String, title: String, anchor: NSRect, composition: NSRect?, screen: NSScreen
    ) {
        guard let candidateWindow = controller.window else { return }
        controller.show(near: anchor, compositionLeadingX: composition?.minX,
            compositionTrailingXProvider: composition.map { rect in { rect.maxX } })
        guard let placementSide = controller.placementSide else { return }
        placementDebugOverlay.show(
            scenario: PlacementDebugOverlayController.Scenario(
                shortcut: shortcut, title: title, anchorRect: anchor,
                compositionRect: composition, placementSide: placementSide),
            on: candidateWindow.screen ?? screen, candidateWindow: candidateWindow)
        reportCandidateWindow()
    }

    private func reportCandidateWindow() {
        guard let window = controller.window else { return }
        print("Candidate window number: \(window.windowNumber), frame: \(window.frame), "
            + "visible: \(window.isVisible), scale: \(window.backingScaleFactor), "
            + "font size: \(controller.candidateFont.pointSize), sample: \(sample.rawValue)")
    }

    private func installKeyReceiverWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: .borderless, backing: .buffered, defer: false)
        window.alphaValue = 0.001
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.orderFront(nil)
        window.makeKey()
        keyReceiverWindow = window
    }

    private func installEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event: event) == true ? nil : event
        }
    }

    private func handle(event: NSEvent) -> Bool {
        // Leave color-picker sliders and text entry to their native responders.
        if event.window is NSColorPanel || event.window?.firstResponder is NSTextView {
            return false
        }
        guard controller.visible else { return false }
        let modifiers = event.modifierFlags.intersection([.shift, .option, .command, .control])
        if sample == .associated && (event.keyCode == 36 || event.keyCode == 76) {
            guard modifiers == .shift else { return false }
            controller.confirmSelectedCandidate()
            return true
        }
        if sample.usesShiftedKeys && modifiers == .shift,
            let key = (event.characters(byApplyingModifiers: []) ?? event.charactersIgnoringModifiers)?.lowercased(),
            key.count == 1, selectionKeys.contains(key) {
            return controller.commitCandidate(matchingIndexLabel: Character(key))
        }
        return controller.handleKeyEvent(event)
    }

    private func configureFromArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        if let value = arguments.first(where: { $0.hasPrefix("--sample=") }) {
            sample = PreviewSample(rawValue: String(value.dropFirst("--sample=".count))) ?? .candidates
        } else if arguments.contains("--many-candidates") {
            sample = .longList
        } else if arguments.contains("--short-list") {
            sample = .shortList
        }
        if arguments.contains("--letter-keys") { selectionKeys = keySets[1] }
        if arguments.contains("--dark") { previewAppearance = NSAppearance(named: .darkAqua) }
        else if arguments.contains("--light") { previewAppearance = NSAppearance(named: .aqua) }
        var configuration = controller.configuration
        configuration.orientation = arguments.contains("--vertical") ? .vertical : .horizontal
        configuration.allowsExpansion = !arguments.contains("--paged")
        if let value = arguments.first(where: { $0.hasPrefix("--font-size=") }),
            let size = Double(value.dropFirst("--font-size=".count)), fontSizes.contains(CGFloat(size)) {
            configuration.candidateFontSize = CGFloat(size)
        }
        try! controller.apply(configuration: configuration)
        synchronizePreviewTheme()
        reloadSample(initialSelectedIndex: arguments.contains("--last") ? sample.entries.count - 1 : 0)
        if arguments.contains("--expanded") {
            _ = controller.navigate(configuration.orientation == .vertical ? .right : .down)
        }
        if arguments.contains("--tooltip") { controller.tooltip = "聯想詞" }
        if arguments.contains("--black-background") { showBackground(2) }
        if arguments.contains("--accent") { showAccentPreview() }
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        let selected: Bool
        switch item.action {
        case #selector(selectOrientation):
            selected = item.tag == (controller.configuration.orientation == .horizontal ? 0 : 1)
        case #selector(selectDisplayMode):
            selected = item.tag == (controller.configuration.allowsExpansion ? 0 : 1)
        case #selector(selectFontSize):
            selected = fontSizes[item.tag] == controller.configuration.candidateFontSize
        case #selector(selectKeys): selected = keySets[item.tag] == selectionKeys
        case #selector(selectSample): selected = PreviewSample.allCases[item.tag] == sample
        case #selector(selectAppearance):
            selected = item.tag == (previewAppearance == nil ? 0 : previewAppearance?.name == .aqua ? 1 : 2)
        case #selector(selectBackground): selected = item.tag == backgroundIndex
        default: return true
        }
        item.state = selected ? .on : .off
        return true
    }

    private func makeMainMenu() -> NSMenu {
        let main = NSMenu()
        @discardableResult
        func addMenu(_ title: String, to parent: NSMenu, action: Selector? = nil,
            choices: [String] = [], keys: [String] = []) -> NSMenu {
            let menu = NSMenu(title: title)
            for (index, title) in choices.enumerated() {
                let item = menu.addItem(withTitle: title, action: action,
                    keyEquivalent: keys.indices.contains(index) ? keys[index] : "")
                item.target = self
                item.tag = index
            }
            parent.addItem(withTitle: title, action: nil, keyEquivalent: "").submenu = menu
            return menu
        }
        let application = addMenu("CandidatePreview", to: main)
        application.addItem(withTitle: "Quit CandidatePreview",
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let layout = addMenu("Layout", to: main)
        addMenu("Orientation", to: layout, action: #selector(selectOrientation),
            choices: ["Horizontal", "Vertical"], keys: ["1", "2"])
        addMenu("Display Mode", to: layout, action: #selector(selectDisplayMode),
            choices: ["Expandable", "Paged"], keys: ["3", "4"])
        layout.addItem(.separator())
        addMenu("Font Size", to: layout, action: #selector(selectFontSize),
            choices: fontSizes.map { "\(Int($0)) pt" })
        addMenu("Selection Keys", to: layout, action: #selector(selectKeys), choices: keySets)
        addMenu("Samples", to: main, action: #selector(selectSample),
            choices: PreviewSample.allCases.map(\.title))
        let appearance = addMenu("Appearance", to: main)
        addMenu("Theme", to: appearance, action: #selector(selectAppearance),
            choices: ["System", "Light", "Dark"], keys: ["s", "l", "d"])
        addMenu("Background", to: appearance, action: #selector(selectBackground),
            choices: ["Desktop", "White", "Black"], keys: ["t", "w", "b"])
        appearance.addItem(.separator())
        appearance.addItem(withTitle: "Accent Color Comparison…",
            action: #selector(showAccentPreview), keyEquivalent: "a").target = self
        let placement = addMenu("Placement", to: main)
        for (title, action, key) in [
            ("Center", #selector(centerCandidateWindow), "0"),
            ("Above Anchor", #selector(showAboveAnchor), "5"),
            ("Left of Composition", #selector(showLeftOfComposition), "6"),
            ("Right of Composition", #selector(showRightOfComposition), "7"),
            ("Hide Guides", #selector(hidePlacementDebugOverlay), "8"),
        ] {
            placement.addItem(withTitle: title, action: action, keyEquivalent: key).target = self
        }
        return main
    }
}

@main
enum CandidatePreviewMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = PreviewAppDelegate()
        application.delegate = delegate
        application.run()
    }
}
