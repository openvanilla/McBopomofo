import Cocoa
import CandidateUI

typealias Candidate = (candidate: String, reading: String)

class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var horizontal: HorizontalCandidateController = .init()
    lazy var vertical: VerticalCandidateController = .init()
    var candidates: [Candidate]  = []
    let simpleCandidates: [Candidate] = [
        ("天", "ㄊㄧㄢ"),
        ("生", "ㄕㄥ"),
        ("我", "ㄨㄛˇ"),
        ("才", "ㄘㄞˊ"),
        ("必", "ㄅㄧˋ"),
        ("有", "ㄧㄡˇ"),
        ("用", "ㄩㄥˋ"),
    ]

    let longCandidates: [Candidate] = [
        ("天", "ㄊㄧㄢ"),
        ("生", "ㄕㄥ"),
        ("我", "ㄨㄛˇ"),
        ("才", "ㄘㄞˊ"),
        ("必", "ㄅㄧˋ"),
        ("有", "ㄧㄡˇ"),
        ("用", "ㄩㄥˋ"),
        ("千", "ㄑㄧㄢ"),
        ("金", "ㄐㄧㄣ"),
        ("散", "ㄙㄢˋ"),
        ("盡", "ㄐㄧㄣˋ"),
    ]

    var location: NSPoint {
        var point = NSPoint(x: 100, y: 100)
        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            point = NSPoint(x: frame.minX + 300, y: frame.maxY - 20)
        }
        return point
    }

    @objc
    func showHorizontal() {
        vertical.visible = false
        horizontal.tooltip = ""
        candidates = simpleCandidates
        horizontal.reloadData()
        horizontal
            .set(windowTopLeftPoint: location, bottomOutOfScreenAdjustmentHeight: 0)
        horizontal.visible = true
    }

    @objc
    func showHorizontalWithPages() {
        vertical.visible = false
        horizontal.tooltip = ""
        candidates = longCandidates
        horizontal.reloadData()
        horizontal
            .set(windowTopLeftPoint: location, bottomOutOfScreenAdjustmentHeight: 0)
        horizontal.visible = true
    }

    @objc
    func showHorizontalWithTooltip() {
        vertical.visible = false
        horizontal.tooltip = "將進酒"
        candidates = longCandidates
        horizontal.reloadData()
        horizontal
            .set(windowTopLeftPoint: location, bottomOutOfScreenAdjustmentHeight: 0)
        horizontal.visible = true
    }

    @objc
    func showVertical() {
        horizontal.visible = false
        vertical.tooltip = ""
        candidates = simpleCandidates
        vertical.reloadData()
        vertical
            .set(windowTopLeftPoint: location, bottomOutOfScreenAdjustmentHeight: 0)
        vertical.visible = true
    }

    @objc
    func showVerticalWithPages() {
        horizontal.visible = false
        vertical.tooltip = ""
        candidates = longCandidates
        vertical.reloadData()
        vertical
            .set(windowTopLeftPoint: location, bottomOutOfScreenAdjustmentHeight: 0)
        vertical.visible = true
    }

    @objc
    func showVerticalWithTooltip() {
        horizontal.visible = false
        vertical.tooltip = "將進酒"
        candidates = longCandidates
        vertical.reloadData()
        vertical
            .set(windowTopLeftPoint: location, bottomOutOfScreenAdjustmentHeight: 0)
        vertical.visible = true
    }

    @objc
    func applicationDidFinishLaunching(_ notification: Notification) {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        horizontal.delegate = self
        vertical.delegate = self

        // Create a minimal menu so the app can quit.
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        var item = NSMenuItem(
            title: "Show Horizontal Candidates (Simple)",
            action: #selector(showHorizontal),
            keyEquivalent: ""
        )
        item.target = self
        appMenu.addItem(item)

        item = NSMenuItem(
            title: "Show Horizontal Candidates (Paged)",
            action: #selector(showHorizontalWithPages),
            keyEquivalent: ""
        )
        item.target = self
        appMenu.addItem(item)

        item = NSMenuItem(
            title: "Show Horizontal Candidates (Tooltip)",
            action: #selector(showHorizontalWithTooltip),
            keyEquivalent: ""
        )
        item.target = self
        appMenu.addItem(item)

        appMenu.addItem(NSMenuItem.separator())

        item = NSMenuItem(
            title: "Show Vertical Candidates (Simple)",
            action: #selector(showVertical),
            keyEquivalent: ""
        )
        item.target = self
        appMenu.addItem(item)

        item = NSMenuItem(
            title: "Show Vertical Candidates (Paged)",
            action: #selector(showVerticalWithPages),
            keyEquivalent: ""
        )
        item.target = self
        appMenu.addItem(item)

        item = NSMenuItem(
            title: "Show Vertical Candidates (Tooltip)",
            action: #selector(showVerticalWithTooltip),
            keyEquivalent: ""
        )
        item.target = self
        appMenu.addItem(item)

        appMenu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit TooltipDemoApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        app.mainMenu = mainMenu

        app.activate(ignoringOtherApps: true)
        showHorizontal()
    }
}


extension AppDelegate: CandidateControllerDelegate {

    func candidateCountForController(_ controller: CandidateUI.CandidateController) -> UInt {
        UInt(candidates.count)
    }

    func candidateController(_ controller: CandidateUI.CandidateController, candidateAtIndex index: UInt) -> String {
        candidates[Int(index)].candidate
    }

    func candidateController(_ controller: CandidateUI.CandidateController, readingAtIndex index: UInt) -> String? {
        candidates[Int(index)].candidate
    }

    func candidateController(_ controller: CandidateUI.CandidateController, requestExplanationFor candidate: String, reading: String) -> String? {
        nil
    }

    func candidateController(
        _ controller: CandidateUI.CandidateController,
        didSelectCandidateAtIndex index: UInt
    ) {
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

