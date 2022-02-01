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

import Foundation

/// Utilities to convert the length of an NSString and a Swift string.
class StringUtils: NSObject {

    /// Converts the index in an NSString to the index in a Swift string.
    ///
    /// An Emoji might be compose by more than one UTF-16 code points, however
    /// the length of an NSString is only the sum of the UTF-16 code points. It
    /// causes that the NSString and Swift string representation of the same
    /// string have different lengths once the string contains such Emoji. The
    /// method helps to find the index in a Swift string by passing the index
    /// in an NSString.
    static func convertToCharIndex(from utf16Index: Int, in string: String) -> Int {
        var length = 0
        for (i, character) in string.enumerated() {
            if length >= utf16Index {
                return i
            }
            length += character.utf16.count
        }
        return string.count
    }

    @objc (nextUtf16PositionForIndex:in:)
    static func nextUtf16Position(for index: Int, in string: String) -> Int {
        var index = convertToCharIndex(from: index, in: string)
        if index < string.count {
            index += 1
        }
        let count = string[..<string.index(string.startIndex, offsetBy: index)].utf16.count
        return count
    }

    @objc (previousUtf16PositionForIndex:in:)
    static func previousUtf16Position(for index: Int, in string: String) -> Int {
        var index = convertToCharIndex(from: index, in: string)
        if index > 0 {
            index -= 1
        }
        let count = string[..<string.index(string.startIndex, offsetBy: index)].utf16.count
        return count
    }
}

extension NSString {
    @objc var count: Int {
        (self as String).count
    }
}
