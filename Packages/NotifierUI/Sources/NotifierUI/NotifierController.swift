import Cocoa

protocol NotifierWindowDelegate: AnyObject {
    func windowDidBecomeClicked(_ window: NotifierWindow)
}

class NotifierWindow: NSWindow {
    weak var clickDelegate: NotifierWindowDelegate?

    override func mouseDown(with event: NSEvent) {
        clickDelegate?.windowDidBecomeClicked(self)
    }
}

let kWindowWidth: CGFloat = 160.0
let kWindowHeight: CGFloat = 80.0

public class NotifierController: NSWindowController, NotifierWindowDelegate {
    private var messageTextField: NSTextField

    private var message: String = "" {
        didSet {
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.setParagraphStyle(NSParagraphStyle.default)
            paraStyle.alignment = .center
            let attr: [NSAttributedString.Key: AnyObject] = [
                .foregroundColor: foregroundColor,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .regular)),
                .paragraphStyle: paraStyle
            ]
            let attrString = NSAttributedString(string: message, attributes: attr)
            messageTextField.attributedStringValue = attrString
            let width = window?.frame.width ?? kWindowWidth
            let rect = attrString.boundingRect(with: NSSize(width: width, height: 1600), options: .usesLineFragmentOrigin)
            let height = rect.height
            let x = messageTextField.frame.origin.x
            let y = ((window?.frame.height ?? kWindowHeight) - height) / 2
            let newFrame = NSRect(x: x, y: y, width: width, height: height)
            messageTextField.frame = newFrame
        }
    }
    private var shouldStay: Bool = false
    private var backgroundColor: NSColor = .black {
        didSet {
            self.window?.backgroundColor = backgroundColor
            self.messageTextField.backgroundColor = backgroundColor
        }
    }
    private var foregroundColor: NSColor = .white {
        didSet {
            self.messageTextField.textColor = foregroundColor
        }
    }
    private var waitTimer: Timer?
    private var fadeTimer: Timer?

    private static var instanceCount = 0
    private static var lastLocation = NSPoint.zero

    @objc public static func notify(message: String, stay: Bool = false) {
        let controller = NotifierController()
        controller.message = message
        controller.shouldStay = stay
        controller.show()
    }

    static func increaseInstanceCount() {
        instanceCount += 1
    }

    static func decreaseInstanceCount() {
        instanceCount -= 1
        if instanceCount < 0 {
            instanceCount = 0
        }
    }

    public init() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect.zero
        let contentRect = NSRect(x: 0, y: 0, width: kWindowWidth, height: kWindowHeight)
        var windowRect = contentRect
        windowRect.origin.x = screenRect.maxX - windowRect.width - 10
        windowRect.origin.y = screenRect.maxY - windowRect.height - 10
        let styleMask: NSWindow.StyleMask = [.borderless]
        let panel = NotifierWindow(contentRect: windowRect, styleMask: styleMask, backing: .buffered, defer: false)
        panel.level = NSWindow.Level(Int(kCGPopUpMenuWindowLevel))
        panel.hasShadow = true
        panel.backgroundColor = backgroundColor

        messageTextField = NSTextField()
        messageTextField.frame = contentRect
        messageTextField.isEditable = false
        messageTextField.isSelectable = false
        messageTextField.isBezeled = false
        messageTextField.textColor = foregroundColor
        messageTextField.drawsBackground = true
        messageTextField.backgroundColor = backgroundColor
        messageTextField.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
        panel.contentView?.addSubview(messageTextField)

        super.init(window: panel)

        panel.clickDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStartLocation() {
        if NotifierController.instanceCount == 0 {
            return
        }
        let lastLocation = NotifierController.lastLocation
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect.zero
        var windowRect = self.window?.frame ?? NSRect.zero
        windowRect.origin.x = lastLocation.x
        windowRect.origin.y = lastLocation.y - 10 - windowRect.height

        if windowRect.origin.y < screenRect.minY {
            return
        }

        self.window?.setFrame(windowRect, display: true)
    }

    func moveIn() {
        let afterRect = self.window?.frame ?? NSRect.zero
        NotifierController.lastLocation = afterRect.origin
        var beforeRect = afterRect
        beforeRect.origin.y += 10
        window?.setFrame(beforeRect, display: true)
        window?.orderFront(self)
        window?.setFrame(afterRect, display: true, animate: true)
    }

    func show() {
        setStartLocation()
        moveIn()
        NotifierController.increaseInstanceCount()
        waitTimer = Timer.scheduledTimer(timeInterval: shouldStay ? 5 : 1, target: self, selector: #selector(fadeOut), userInfo: nil, repeats: false)
    }

    @objc func doFadeOut(_ timer: Timer) {
        let opacity = self.window?.alphaValue ?? 0
        if opacity <= 0 {
            self.close()
        } else {
            self.window?.alphaValue = opacity - 0.2
        }
    }

    @objc func fadeOut() {
        waitTimer?.invalidate()
        waitTimer = nil
        NotifierController.decreaseInstanceCount()
        fadeTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(doFadeOut(_:)), userInfo: nil, repeats: true)
    }

    public override func close() {
        waitTimer?.invalidate()
        waitTimer = nil
        fadeTimer?.invalidate()
        fadeTimer = nil
        super.close()
    }

    func windowDidBecomeClicked(_ window: NotifierWindow) {
        self.fadeOut()
    }
}
