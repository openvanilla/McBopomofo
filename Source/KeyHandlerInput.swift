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
    private var keyCode: UInt16
    private var flags: NSEvent.ModifierFlags
    private var cursorForwardKey: KeyCode
    private var cursorBackwardKey: KeyCode
    private var extraChooseCandidateKey: KeyCode
    private var absorbedArrowKey: KeyCode
    private var verticalModeOnlyChooseCandidateKey: KeyCode
    @objc private (set) var emacsKey: McBopomofoEmacsKey

    @objc init(inputText: String?, keyCode: UInt16, charCode: UInt16, flags: NSEvent.ModifierFlags, isVerticalMode: Bool) {
        self.inputText = inputText
        self.keyCode = keyCode
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
        NSLog("self.keyCode \(self.keyCode)")
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
