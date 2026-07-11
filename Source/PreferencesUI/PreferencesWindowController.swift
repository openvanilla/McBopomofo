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
        window.setContentSize(NSSize(
            width: preferencesWindowWidth,
            height: preferencesInitialContentHeight))

        super.init(window: window)
        shouldCascadeWindows = false
        positionWindow(on: NSScreen.main ?? NSScreen.screens.first)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        if window?.isVisible != true {
            positionWindowNearInputMenuScreen()
        }
        super.showWindow(sender)
        DispatchQueue.main.async { [weak self] in
            self?.positionWindowNearInputMenuScreen()
        }
    }

    func showAndActivate() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func positionWindowNearInputMenuScreen() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main ?? NSScreen.screens.first

        positionWindow(on: screen)
    }

    private func positionWindow(on screen: NSScreen?) {
        guard let window, let visibleFrame = screen?.visibleFrame else {
            return
        }

        let padding: CGFloat = 24
        var frame = window.frame
        let preferredX = visibleFrame.maxX - frame.width - padding
        let preferredY = visibleFrame.maxY - frame.height - padding
        let minimumX = visibleFrame.minX + padding
        let minimumY = visibleFrame.minY + padding

        frame.origin.x = preferredX >= minimumX
            ? preferredX
            : visibleFrame.minX + max(0, (visibleFrame.width - frame.width) / 2)
        frame.origin.y = preferredY >= minimumY
            ? preferredY
            : visibleFrame.minY + max(0, (visibleFrame.height - frame.height) / 2)
        window.setFrame(frame, display: false)
    }
}
