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
    @objc private (set) var useVerticalMode: Bool
    @objc private (set) var inputText: String?
    @objc private (set) var keyCode: UInt16
    @objc private (set) var flags: NSEvent.ModifierFlags
    @objc private (set) var charCode: UInt16
    @objc private (set) var cursorForwardKey: KeyCode
    @objc private (set) var cursorBackwardKey: KeyCode
    @objc private (set) var extraChooseCandidateKey: KeyCode
    @objc private (set) var absorbedArrowKey: KeyCode
    @objc private (set) var verticalModeOnlyChooseCandidateKey: KeyCode
    @objc private (set) var emacsKey: McBopomofoEmacsKey

    @objc init(event: NSEvent, isVerticalMode: Bool) {
        self.inputText = event.characters
        self.keyCode = event.keyCode
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

    @objc var isEnter: Bool {
        self.keyCode == KeyCode.enter.rawValue
    }

    @objc var isUp: Bool {
        self.keyCode == KeyCode.up.rawValue
    }

    @objc var isDown: Bool {
        self.keyCode == KeyCode.down.rawValue
    }

    @objc var isLeft: Bool {
        NSLog("isLeft called \(self.keyCode == KeyCode.left.rawValue)")
        return self.keyCode == KeyCode.left.rawValue
    }

    @objc var isRight: Bool {
        NSLog("isRight called \(self.keyCode == KeyCode.right.rawValue)")
        return self.keyCode == KeyCode.right.rawValue
    }

    @objc var isPageUp: Bool {
        self.keyCode == KeyCode.pageUp.rawValue
    }

    @objc var isPageDown: Bool {
        self.keyCode == KeyCode.pageDown.rawValue
    }

    @objc var isHome: Bool {
        self.keyCode == KeyCode.home.rawValue
    }

    @objc var isEnd: Bool {
        self.keyCode == KeyCode.end.rawValue
    }

    @objc var isDelete: Bool {
        self.keyCode == KeyCode.delete.rawValue
    }

    @objc var isCursorBackward: Bool {
        self.keyCode == cursorBackwardKey.rawValue
    }

    @objc var isCursorForward: Bool {
        self.keyCode == cursorForwardKey.rawValue
    }

    @objc var isAbsorbedArrowKey: Bool {
        self.keyCode == absorbedArrowKey.rawValue
    }

    @objc var isExtraChooseCandidateKey: Bool {
        self.keyCode == extraChooseCandidateKey.rawValue
    }

    @objc var isVerticalModeOnlyChooseCandidateKey: Bool {
        self.keyCode == verticalModeOnlyChooseCandidateKey.rawValue
    }

}

