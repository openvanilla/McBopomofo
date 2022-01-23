import Foundation

class InputState: NSObject {
}

class InputStateDeactive: InputState {
}

class InputStateEmpty: InputState {
}

class InputStateCommitting: InputState {
    @objc private(set) var poppedText: String = ""

    @objc convenience init(poppedText: String) {
        self.init()
        self.poppedText = poppedText
    }
}

class InputStateInputting: InputState {
    @objc private(set) var composingBuffer: String = ""
    @objc private(set) var cursorIndex: UInt = 0
    @objc var poppedText: String = ""

    @objc init(composingBuffer: String, cursorIndex: UInt) {
        self.composingBuffer = composingBuffer
        self.cursorIndex = cursorIndex
    }
}

class InputStateMarking: InputStateInputting {
    @objc private(set) var markerIndex: UInt = 0
    @objc private(set) var markedRange: NSRange = NSRange(location: 0, length: 0)
    @objc var tooltip: String {
        return ""
    }

    @objc init(composingBuffer: String, cursorIndex: UInt, markerIndex: UInt) {
        super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
        self.markerIndex = markerIndex
        let begin = min(cursorIndex, markerIndex)
        let end = max(cursorIndex, markerIndex)
        self.markedRange = NSMakeRange(Int(begin), Int( end - begin))
    }
}

class InputStateChoosingCandidate: InputStateInputting {
    var markingRang: NSRange = NSRange(location: 0, length: 0)
    var candidates: [String] = []
}
