import Cocoa

/// Represents the states for the input controller.
class InputState: NSObject {
}

/// Represents that the input controller is deactive.
class InputStateDeactive: InputState {
    override var description: String {
        return "<InputStateDeactive>"
    }
}

/// Represents that the composing buffer is empty.
class InputStateEmpty: InputState {
}

/// Represents that the input controller is committing text into client app.
class InputStateCommitting: InputState {
    @objc private(set) var poppedText: String = ""

    @objc convenience init(poppedText: String) {
        self.init()
        self.poppedText = poppedText
    }

    override var description: String {
        return "<InputStateCommitting poppedText:\(poppedText)>"
    }
}

/// Represents that the composing buffer is not empty.
class InputStateNotEmpty: InputState {
    @objc private(set) var composingBuffer: String = ""
    @objc private(set) var cursorIndex: UInt = 0

    @objc init(composingBuffer: String, cursorIndex: UInt) {
        self.composingBuffer = composingBuffer
        self.cursorIndex = cursorIndex
    }

    override var description: String {
        return "<InputStateNotEmpty, composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex)>"
    }
}

/// Represents that the user is inputting text.
class InputStateInputting: InputStateNotEmpty {
    @objc var bpmfReading: String = ""
    @objc var bpmfReadingCursotIndex: UInt8 = 0
    @objc var poppedText: String = ""

    @objc override init(composingBuffer: String, cursorIndex: UInt) {
        super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
    }

    @objc var attributedString: NSAttributedString {
        let attributedSting = NSAttributedString(string: composingBuffer, attributes:  [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 0
        ])
        return attributedSting
    }

    override var description: String {
        return "<InputStateInputting, composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex), poppedText:\(poppedText)>"
    }
}

private let kMinMarkRangeLength = 2
private let kMaxMarkRangeLength = 6


/// Represents that the user is marking a range in the composing buffer.
class InputStateMarking: InputStateNotEmpty {
    @objc private(set) var markerIndex: UInt = 0
    @objc private(set) var markedRange: NSRange = NSRange(location: 0, length: 0)
    @objc var tooltip: String {

        if Preferences.phraseReplacementEnabled {
            return NSLocalizedString("Phrase replacement mode is on. Not suggested to add phrase in the mode.", comment: "")
        }
        if Preferences.chineseConversionStyle == 1 && Preferences.chineseConversionEnabled {
            return NSLocalizedString("Model based Chinese conversion is on. Not suggested to add phrase in the mode.", comment: "")
        }
        if markedRange.length == 0 {
            return ""
        }

        let text = (composingBuffer as NSString).substring(with: markedRange)
        if markedRange.length < kMinMarkRangeLength {
            return String(format: NSLocalizedString("You are now selecting \"%@\". You can add a phrase with two or more characters.", comment: ""), text)
        } else if (markedRange.length > kMaxMarkRangeLength) {
            return String(format: NSLocalizedString("You are now selecting \"%@\". A phrase cannot be longer than %d characters.", comment: ""), text, kMaxMarkRangeLength)
        }
        return String(format: NSLocalizedString("You are now selecting \"%@\". Press enter to add a new phrase.", comment: ""), text)
    }

    @objc var readings: [String] = []

    @objc init(composingBuffer: String, cursorIndex: UInt, markerIndex: UInt) {
        super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
        self.markerIndex = markerIndex
        let begin = min(cursorIndex, markerIndex)
        let end = max(cursorIndex, markerIndex)
        self.markedRange = NSMakeRange(Int(begin), Int(end - begin))
    }

    @objc var attributedString: NSAttributedString {
        let attributedSting = NSMutableAttributedString(string: composingBuffer)
        attributedSting.setAttributes([
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 0
        ], range: NSRange(location: 0, length: markedRange.location))
        attributedSting.setAttributes([
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 1
        ], range: markedRange)
        attributedSting.setAttributes([
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 2
        ], range: NSRange(location: markedRange.location + markedRange.length,
                          length: composingBuffer.count - (markedRange.location + markedRange.length)  ))
        return attributedSting
    }

    override var description: String {
        return "<InputStateMarking, composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex), markedRange:\(markedRange), readings:\(readings)>"
    }
}

/// Represents that the user is choosing in a candidates list.
class InputStateChoosingCandidate: InputStateNotEmpty {
    @objc private(set) var candidates: [String] = []
    @objc private(set) var useVerticalMode: Bool = false

    @objc init(composingBuffer: String, cursorIndex: UInt, candidates: [String], useVerticalMode: Bool) {
        self.candidates = candidates
        self.useVerticalMode = useVerticalMode
        super.init(composingBuffer: composingBuffer, cursorIndex: cursorIndex)
    }

    @objc var attributedString: NSAttributedString {
        let attributedSting = NSAttributedString(string: composingBuffer, attributes:  [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .markedClauseSegment: 0
        ])
        return attributedSting
    }

    override var description: String {
        return "<InputStateChoosingCandidate, candidates:\(candidates), useVerticalMode:\(useVerticalMode), composingBuffer:\(composingBuffer), cursorIndex:\(cursorIndex)>"
    }
}
