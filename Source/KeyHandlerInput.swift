import Cocoa

@objc enum KeyCode: UInt16 {
    case none = 0
    case enter = 76
    case up = 126
    case down = 125
    case left = 123
    case right = 124
    case pageUp = 116
    case pageDown = 121
    case home = 115
    case end = 119
    case delete = 117
}

@objc class KeyHandlerInput: NSObject {
    @objc private (set) var event: NSEvent
    @objc private (set) var useVerticalMode: Bool

    @objc var inputText: String? {
        event.characters
    }

    @objc var keyCode: UInt16 {
        event.keyCode
    }

    @objc var flags: NSEvent.ModifierFlags {
        event.modifierFlags
    }

    @objc private (set) var charCode: UInt16
    @objc private (set) var cursorForwardKey: KeyCode
    @objc private (set) var cursorBackwardKey: KeyCode
    @objc private (set) var extraChooseCandidateKey: KeyCode
    @objc private (set) var absorbedArrowKey: KeyCode
    @objc private (set) var verticalModeOnlyChooseCandidateKey: KeyCode
    @objc private (set) var emacsKey: McBopomofoEmacsKey

    @objc init(event: NSEvent, isVerticalMode: Bool) {
        self.event = event
        self.useVerticalMode = isVerticalMode
        let charCode: UInt16 = {
            guard let inputText = event.characters, inputText.count > 0 else {
                return 0
            }
            let first = inputText[inputText.startIndex].utf16.first!
            return first
        }()

        self.charCode = charCode
        self.emacsKey = EmacsKeyHelper.detect(charCode: charCode, flags: event.modifierFlags)
        self.cursorForwardKey = useVerticalMode ? .down : .right
        self.cursorBackwardKey = useVerticalMode ? .up : .left
        self.extraChooseCandidateKey = useVerticalMode ? .left : .down
        self.absorbedArrowKey = useVerticalMode ? .right : .up
        self.verticalModeOnlyChooseCandidateKey = useVerticalMode ? absorbedArrowKey : .none
        super.init()
    }
}
