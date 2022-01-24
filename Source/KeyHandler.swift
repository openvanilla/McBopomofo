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

class KeyHandlerInput: NSObject {
    private (set) var event: NSEvent
    private (set) var useVerticalMode: Bool

    @objc var inputText: String? {
        event.characters
    }

    @objc var charCode: UInt16 {
        guard let inputText = inputText, inputText.count > 0 else {
            return 0
        }
        let first = inputText[inputText.startIndex].utf16.first!
        return first
    }

    @objc var keyCode: UInt16 {
        event.keyCode
    }

    @objc var flags: NSEvent.ModifierFlags {
        event.modifierFlags
    }

    @objc var cursorForwardKey: KeyCode {
        useVerticalMode ? .down : .right
    }

    @objc var cursorBackwardKey: KeyCode {
        useVerticalMode ? .up : .left
    }

    @objc var extraChooseCandidateKey: KeyCode {
        useVerticalMode ? .left : .down
    }

    @objc var absorbedArrowKey: KeyCode {
        useVerticalMode ? .right : .up
    }

    @objc var verticalModeOnlyChooseCandidateKey: KeyCode {
        useVerticalMode ? absorbedArrowKey : .none
    }

    init(event: NSEvent, isVerticalMode: Bool) {
        self.event = event
        self.useVerticalMode = isVerticalMode
    }
}
