import SwiftUI

@MainActor
@objc(PreferencesUiWindowController)
final class PreferencesUiWindowController: NSWindowController {
    private let preferences: PreferencesViewModel

    convenience init() {
        self.init(preferences: PreferencesViewModel())
    }

    @objc
    override convenience init(window: NSWindow?) {
        self.init(preferences: PreferencesViewModel())
    }

    @objc(initWithWindowNibName:)
    convenience init(windowNibName: NSNib.Name) {
        self.init(preferences: PreferencesViewModel())
    }

    @objc(initWithWindowNibName:owner:)
    convenience init(windowNibName: NSNib.Name, owner: Any?) {
        self.init(preferences: PreferencesViewModel())
    }

    init(preferences: PreferencesViewModel) {
        self.preferences = preferences

        let rootView = PreferencesView()
            .environmentObject(preferences)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)

        window.title = NSLocalizedString("McBopomofo Preferences", comment: "")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 478, height: 318)
        window.contentMaxSize = NSSize(width: 478, height: 565)
        window.center()

        super.init(window: window)
        shouldCascadeWindows = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showAndActivate() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
