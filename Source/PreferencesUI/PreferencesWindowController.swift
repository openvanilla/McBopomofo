// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

import SwiftUI

@MainActor
@objc(PreferencesWindowController)
final class PreferencesWindowController: NSWindowController {
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
