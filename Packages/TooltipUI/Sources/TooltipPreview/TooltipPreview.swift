import Cocoa
import TooltipUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var tooltipController: TooltipController?

    var tooltipLocation: NSPoint {
        var point = NSPoint(x: 100, y: 100)
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            point = NSPoint(x: frame.minX + 300, y: frame.maxY - 20)
        }
        return point
    }

    var text = "Hello, World!"

    @objc func showTooltip() {
        tooltipController?.show(tooltip: text, at: tooltipLocation)
    }

    @objc func hideTooltip() {
        tooltipController?.hide()
    }


    func applicationDidFinishLaunching(_ notification: Notification) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let controller = TooltipController()
        self.tooltipController = controller

        // Create a minimal menu so the app can quit.
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let showItem = NSMenuItem(
            title: "Show Tooltip",
            action: #selector(showTooltip),
            keyEquivalent: ""
        )
        showItem.target = self
        appMenu.addItem(showItem)
        let hideItem = NSMenuItem(
            title: "Hide Tooltip",
            action: #selector(hideTooltip),
            keyEquivalent: ""
        )
        hideItem.target = self
        appMenu.addItem(hideItem)
        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit TooltipDemoApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        app.mainMenu = mainMenu

        app.activate(ignoringOtherApps: true)
        showTooltip()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

let delegate = AppDelegate()

@main
struct TooltipPreviewMain {
    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}
