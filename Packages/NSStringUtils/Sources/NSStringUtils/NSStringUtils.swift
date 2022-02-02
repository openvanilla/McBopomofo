import Cocoa

public extension NSString {

    /// Converts the index in an NSString to the index in a Swift string.
    ///
    /// An Emoji might be compose by more than one UTF-16 code points, however
    /// the length of an NSString is only the sum of the UTF-16 code points. It
    /// causes that the NSString and Swift string representation of the same
    /// string have different lengths once the string contains such Emoji. The
    /// method helps to find the index in a Swift string by passing the index
    /// in an NSString.
    func characterIndex(from utf16Index:Int) -> (Int, String) {
        let string = (self as String)
        var length = 0
        for (i, character) in string.enumerated() {
            length += character.utf16.count
            if length > utf16Index {
                return (i, string)
            }
        }
        return (string.count, string)
    }

    @objc func nextUtf16Position(for index: Int) -> Int {
        var (fixedIndex, string) = characterIndex(from: index)
        if fixedIndex < string.count {
            fixedIndex += 1
        }
        return string[..<string.index(string.startIndex, offsetBy: fixedIndex)].utf16.count
    }

    @objc func previousUtf16Position(for index: Int) -> Int {
        var (fixedIndex, string) = characterIndex(from: index)
        if fixedIndex > 0 {
            fixedIndex -= 1
        }
        return string[..<string.index(string.startIndex, offsetBy: fixedIndex)].utf16.count
    }

    @objc var count: Int {
        (self as String).count
    }

    @objc func split() -> [NSString] {
        Array(self as String).map {
            NSString(string: String($0))
        }
    }
}
