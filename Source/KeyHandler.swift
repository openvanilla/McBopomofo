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

    var inputText: String? {
        event.characters
    }

    var charCode: UInt16 {
        guard let inputText = inputText, inputText.count > 0 else {
            return 0
        }
        let first = inputText[inputText.startIndex].utf16.first!
        return first
    }

    var keyCode: UInt16 {
        event.keyCode
    }

    var flags: NSEvent.ModifierFlags {
        event.modifierFlags
    }

    var cursorForwardKey: KeyCode {
        useVerticalMode ? .down : .right
    }

    var cursorBackwardKey: KeyCode {
        useVerticalMode ? .up : .left
    }

    var extraChooseCandidateKey: KeyCode {
        useVerticalMode ? .left : .down
    }

    var absorbedArrowKey: KeyCode {
        useVerticalMode ? .right : .up
    }

    var verticalModeOnlyChooseCandidateKey: KeyCode {
        useVerticalMode ? absorbedArrowKey : .none
    }

    init(event: NSEvent, isVerticalMode: Bool) {
        self.event = event
        self.useVerticalMode = isVerticalMode
    }
}

typealias KeyHandlerStateCallback = (InputState) -> ()
typealias KeyHandlerErrorCallback = () -> ()

@objc protocol KeyHandlerDelegate: AnyObject {
    func keyHandlerRequestCurrentInputtingState(_ handler: KeyHandler) -> InputStateInputting
    func keyHandler(_ handler: KeyHandler, requestWriteUserPhrase state: InputStateMarking ) -> Bool

    func keyHandler(_ handler: KeyHandler, isCharCodeValidBmpfReading charCode:UInt16 ) -> Bool
    func keyHandler(_ handler: KeyHandler, insertCharCodeToBmpfReading charCode:UInt16 ) -> Void

}


class KeyHandler: NSObject {
    var delegate: KeyHandlerDelegate?

    @objc func handle(_ input: KeyHandlerInput,
                             currentState: InputState,
                             stateCallback: @escaping KeyHandlerStateCallback,
                             errorCallback: @escaping KeyHandlerErrorCallback
    ) -> Bool {
        guard let delegate = delegate else {
            return false
        }

        // if the inputText is empty, it's a function key combination, we ignore it
        guard let inputText = input.inputText else {
            return false
        }
        if inputText.isEmpty {
            return false
        }

        let flags = input.flags
        let charCode = input.charCode
        let keyCode = input.keyCode
        let emacsKey = EmacsKeyHelper.detect(charCode: charCode, flags: flags)

        // if the composing buffer is empty and there's no reading, and there is some function key combination, we ignore it
        let isFunctionKey = flags.contains(.command) || flags.contains(.control) || flags.contains(.option) || flags.contains(.numericPad)
        if currentState is InputStateInputting == false && isFunctionKey {
            return false
        }

        // Caps Lock processing : if Caps Lock is on, temporarily disable bopomofo.
        if charCode == 8 ||
            charCode == 13 ||
            keyCode == input.absorbedArrowKey.rawValue ||
            keyCode == input.cursorForwardKey.rawValue ||
            keyCode == input.cursorBackwardKey.rawValue {
            // do nothing if backspace is pressed -- we ignore the key
        } else if flags.contains(.capsLock) {
            // process all possible combination, we hope.
            stateCallback(InputStateEmpty())

            // first commit everything in the buffer.
            if flags.contains(.shift) {
                return false
            }

            // if ASCII but not printable, don't use insertText:replacementRange: as many apps don't handle non-ASCII char insertions.
            if charCode < 0x80 && isprint(Int32(charCode)) == 0 {
                return false
            }
            stateCallback(InputStateCommitting(poppedText: inputText.lowercased()))
            stateCallback(InputStateEmpty())
            return true
        }

        if flags.contains(.numericPad) {
            if keyCode != KeyCode.left.rawValue &&
                keyCode != KeyCode.right.rawValue &&
                keyCode != KeyCode.down.rawValue &&
                keyCode != KeyCode.up.rawValue &&
                charCode != 32 &&
                isprint(Int32(charCode)) != 0 {
                stateCallback(InputStateEmpty())
                stateCallback(InputStateCommitting(poppedText: inputText.lowercased()))
                stateCallback(InputStateEmpty())
                return true
            }
        }

        // candidates?

        if let state = currentState as? InputStateMarking {
            // ESC
            if charCode == 27 {
                let inputting = InputStateInputting(composingBuffer: state.composingBuffer, cursorIndex: state.cursorIndex)
                stateCallback(inputting)
                return true
            }
            // Enter
            if charCode == 13 {
                if delegate.keyHandler(self, requestWriteUserPhrase: state) == false {
                    errorCallback()
                    return true
                }
                let inputting = InputStateInputting(composingBuffer: state.composingBuffer, cursorIndex: state.cursorIndex)
                stateCallback(inputting)
                return true
            }
            // Shift + left
            if (keyCode == input.cursorBackwardKey.rawValue || emacsKey == .backward) && flags.contains(.shift) {
                var index = state.markerIndex
                if index > 0 {
                    index -= 1
                    let marking = InputStateMarking(composingBuffer: state.composingBuffer, cursorIndex: state.cursorIndex, markerIndex: state.markerIndex)
                    stateCallback(marking)
                } else {
                    errorCallback()
                }
                return true
            }
            if (keyCode == input.cursorForwardKey.rawValue || emacsKey == .forward) && flags.contains(.shift) {
                var index = state.markerIndex
                if index < state.composingBuffer.count {
                    index += 1
                    let marking = InputStateMarking(composingBuffer: state.composingBuffer, cursorIndex: state.cursorIndex, markerIndex: state.markerIndex)
                    stateCallback(marking)
                } else {
                    errorCallback()
                }
                return true
            }
        }




        return false
    }

}
