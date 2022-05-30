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

import Cocoa

enum KeyCode: UInt16 {
    case none = 0
    case tab = 48
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
    @objc private (set) var useVerticalMode: Bool
    @objc private (set) var inputText: String?
    @objc private (set) var inputTextIgnoringModifiers: String?
    @objc private (set) var charCode: UInt16
    @objc private (set) var keyCode: UInt16
    private var flags: NSEvent.ModifierFlags
    private var cursorForwardKey: KeyCode
    private var cursorBackwardKey: KeyCode
    private var extraChooseCandidateKey: KeyCode
    private var absorbedArrowKey: KeyCode
    private var verticalModeOnlyChooseCandidateKey: KeyCode
    @objc private (set) var emacsKey: McBopomofoEmacsKey

    @objc init(inputText: String?, keyCode: UInt16, charCode: UInt16, flags: NSEvent.ModifierFlags, isVerticalMode: Bool, inputTextIgnoringModifiers: String? = nil) {
        self.inputText = inputText
        self.inputTextIgnoringModifiers = inputTextIgnoringModifiers ?? inputText
        self.keyCode = keyCode
        self.charCode = charCode
        self.flags = flags
        useVerticalMode = isVerticalMode
        emacsKey = EmacsKeyHelper.detect(charCode: charCode, flags: flags)
        cursorForwardKey = useVerticalMode ? .down : .right
        cursorBackwardKey = useVerticalMode ? .up : .left
        extraChooseCandidateKey = useVerticalMode ? .left : .down
        absorbedArrowKey = useVerticalMode ? .right : .up
        verticalModeOnlyChooseCandidateKey = useVerticalMode ? absorbedArrowKey : .none
        super.init()
    }

    @objc init(event: NSEvent, isVerticalMode: Bool) {
        inputText = event.characters
        inputTextIgnoringModifiers = event.charactersIgnoringModifiers
        keyCode = event.keyCode
        flags = event.modifierFlags
        useVerticalMode = isVerticalMode
        let charCode: UInt16 = {
            guard let inputText = event.characters, inputText.count > 0 else {
                return 0
            }
            let first = inputText[inputText.startIndex].utf16.first!
            return first
        }()
        self.charCode = charCode
        emacsKey = EmacsKeyHelper.detect(charCode: charCode, flags: event.modifierFlags)
        cursorForwardKey = useVerticalMode ? .down : .right
        cursorBackwardKey = useVerticalMode ? .up : .left
        extraChooseCandidateKey = useVerticalMode ? .left : .down
        absorbedArrowKey = useVerticalMode ? .right : .up
        verticalModeOnlyChooseCandidateKey = useVerticalMode ? absorbedArrowKey : .none
        super.init()
    }

    override var description: String {
        return "<\(super.description) inputText:\(String(describing: inputText)), inputTextIgnoringModifiers:\(String(describing: inputTextIgnoringModifiers)) charCode:\(charCode), keyCode:\(keyCode), flags:\(flags), cursorForwardKey:\(cursorForwardKey), cursorBackwardKey:\(cursorBackwardKey), extraChooseCandidateKey:\(extraChooseCandidateKey), absorbedArrowKey:\(absorbedArrowKey),  verticalModeOnlyChooseCandidateKey:\(verticalModeOnlyChooseCandidateKey), emacsKey:\(emacsKey), useVerticalMode:\(useVerticalMode)>"
    }

    @objc var isShiftHold: Bool {
        flags.contains([.shift])
    }

    @objc var isCommandHold: Bool {
        flags.contains([.command])
    }

    @objc var isControlHold: Bool {
        flags.contains([.control])
    }

    @objc var isControlHotKey: Bool {
        flags.contains([.control]) && inputText?.first?.isLetter ?? false
    }

    @objc var isOptionHold: Bool {
        flags.contains([.option])
    }

    @objc var isCapsLockOn: Bool {
        flags.contains([.capsLock])
    }

    @objc var isNumericPad: Bool {
        flags.contains([.numericPad])
    }

    @objc var isReservedKey: Bool {
        guard let code = KeyCode(rawValue: keyCode) else {
            return false
        }
        return code.rawValue != KeyCode.none.rawValue
    }

    @objc var isEnter: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.enter
    }

    @objc var isTab: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.tab
    }

    @objc var isUp: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.up
    }

    @objc var isDown: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.down
    }

    @objc var isLeft: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.left
    }

    @objc var isRight: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.right
    }

    @objc var isPageUp: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.pageUp
    }

    @objc var isPageDown: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.pageDown
    }

    @objc var isHome: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.home
    }

    @objc var isEnd: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.end
    }

    @objc var isDelete: Bool {
        KeyCode(rawValue: keyCode) == KeyCode.delete
    }

    @objc var isCursorBackward: Bool {
        KeyCode(rawValue: keyCode) == cursorBackwardKey
    }

    @objc var isCursorForward: Bool {
        KeyCode(rawValue: keyCode) == cursorForwardKey
    }

    @objc var isAbsorbedArrowKey: Bool {
        KeyCode(rawValue: keyCode) == absorbedArrowKey
    }

    @objc var isExtraChooseCandidateKey: Bool {
        KeyCode(rawValue: keyCode) == extraChooseCandidateKey
    }

    @objc var isVerticalModeOnlyChooseCandidateKey: Bool {
        KeyCode(rawValue: keyCode) == verticalModeOnlyChooseCandidateKey
    }

}

@objc enum McBopomofoEmacsKey: UInt16 {
    case none = 0
    case forward = 6 // F
    case backward = 2 // B
    case home = 1 // A
    case end = 5 // E
    case delete = 4 // D
    case nextPage = 22 // V
}

class EmacsKeyHelper: NSObject {
    @objc static func detect(charCode: UniChar, flags: NSEvent.ModifierFlags) -> McBopomofoEmacsKey {
        if flags.contains(.control) {
            return McBopomofoEmacsKey(rawValue: charCode) ?? .none
        }
        return .none;
    }
}
