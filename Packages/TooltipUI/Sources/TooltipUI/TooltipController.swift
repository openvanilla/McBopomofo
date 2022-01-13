import Cocoa

public class TooltipController: NSWindowController {
    let backgroundColor =  NSColor(calibratedHue: 0.16, saturation: 0.22, brightness: 0.97, alpha: 1.0)
    var messageTextField: NSTextField
    var tooltip: String  = "" {
        didSet {
            messageTextField.stringValue = tooltip
            adjustSize()
        }
    }

    public init() {
        let contentRect = NSRect(x: 128.0, y: 128.0, width: 300.0, height: 20.0)
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        let panel = NSPanel(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
        panel.level = NSWindow.Level(Int(kCGPopUpMenuWindowLevel))
        panel.hasShadow = true

        messageTextField = NSTextField()
        messageTextField.isEditable = false
        messageTextField.isSelectable = false
        messageTextField.isBezeled = false
        messageTextField.textColor = .black
        messageTextField.drawsBackground = true
        messageTextField.backgroundColor = backgroundColor
        messageTextField.font = .systemFont(ofSize: NSFont.systemFontSize(for: .small))
        panel.contentView?.addSubview(messageTextField)

        super.init(window: panel)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc(showTooltip:atPoint:)
    public func show(tooltip: String, at point: NSPoint) {
        self.tooltip = tooltip
        window?.orderFront(nil)
        set(windowLocation: point)
    }

    @objc
    public func hide() {
        window?.orderOut(nil)
    }

    private func set(windowLocation location: NSPoint) {
        var newPoint = location
        if location.y > 5 {
            newPoint.y -= 5
        }
        window?.setFrameTopLeftPoint(newPoint)
    }

    private func adjustSize() {
        let attrString = messageTextField.attributedStringValue;
        var rect = attrString.boundingRect(with: NSSize(width: 1600.0, height: 1600.0), options: .usesLineFragmentOrigin)
        rect.size.width += 10
        messageTextField.frame = rect
        window?.setFrame(rect, display: true)
    }

}
