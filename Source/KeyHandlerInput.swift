import Cocoa

@objc enum KeyCode: Int {
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
    @objc private (set) var useVerticalMode: Bool
    @objc private (set) var inputText: String?
    @objc private (set) var charCode: UInt16
    @objc private var keyCode: Int
    @objc private var flags: NSEvent.ModifierFlags
    @objc private var cursorForwardKey: KeyCode
    @objc private var cursorBackwardKey: KeyCode
    @objc private var extraChooseCandidateKey: KeyCode
    @objc private var absorbedArrowKey: KeyCode
    @objc private var verticalModeOnlyChooseCandidateKey: KeyCode
    @objc private (set) var emacsKey: McBopomofoEmacsKey

    @objc init(inputText: String?, keyCode: UInt16, charCode: UInt16, flags: NSEvent.ModifierFlags, isVerticalMode: Bool) {
        self.inputText = inputText
        self.keyCode = Int(keyCode)
        self.charCode = charCode
        self.flags = flags
        self.useVerticalMode = isVerticalMode
        self.emacsKey = EmacsKeyHelper.detect(charCode: charCode, flags: flags)
        self.cursorForwardKey = useVerticalMode ? .down : .right
        self.cursorBackwardKey = useVerticalMode ? .up : .left
        self.extraChooseCandidateKey = useVerticalMode ? .left : .down
        self.absorbedArrowKey = useVerticalMode ? .right : .up
        self.verticalModeOnlyChooseCandidateKey = useVerticalMode ? absorbedArrowKey : .none
        super.init()
    }

    @objc init(event: NSEvent, isVerticalMode: Bool) {
        self.inputText = event.characters
        self.keyCode = Int(event.keyCode)
        self.flags = event.modifierFlags
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

    @objc var isShiftHold: Bool {
        self.flags.contains([.shift])
    }

    @objc var isCommandHold: Bool {
        self.flags.contains([.command])
    }

    @objc var isControlHold: Bool {
        self.flags.contains([.control])
    }

    @objc var isOptionlHold: Bool {
        self.flags.contains([.option])
    }

    @objc var isCapsLockOn: Bool {
        self.flags.contains([.capsLock])
    }

    @objc var isNumericPad: Bool {
        self.flags.contains([.numericPad])
    }

    @objc var isEnter: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.enter
    }

    @objc var isUp: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.up
    }

    @objc var isDown: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.down
    }

    @objc var isLeft: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.left
    }

    @objc var isRight: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.right
    }

    @objc var isPageUp: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.pageUp
    }

    @objc var isPageDown: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.pageDown
    }

    @objc var isHome: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.home
    }

    @objc var isEnd: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.end
    }

    @objc var isDelete: Bool {
        KeyCode(rawValue: self.keyCode) == KeyCode.delete
    }

    @objc var isCursorBackward: Bool {
        KeyCode(rawValue: self.keyCode) == cursorBackwardKey
    }

    @objc var isCursorForward: Bool {
        KeyCode(rawValue: self.keyCode) == cursorForwardKey
    }

    @objc var isAbsorbedArrowKey: Bool {
        KeyCode(rawValue: self.keyCode) == absorbedArrowKey
    }

    @objc var isExtraChooseCandidateKey: Bool {
        KeyCode(rawValue: self.keyCode) == extraChooseCandidateKey
    }

    @objc var isVerticalModeOnlyChooseCandidateKey: Bool {
        KeyCode(rawValue: self.keyCode) == verticalModeOnlyChooseCandidateKey
    }

}

