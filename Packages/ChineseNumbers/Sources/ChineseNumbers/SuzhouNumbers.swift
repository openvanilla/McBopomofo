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

/// Helps to convert Arabic numbers to Sushou numbers (蘇州碼, A kind of
/// ancient Chinese number)
public class SuzhouNumbers: NSObject {

    static private let verticalDigits: [Character: String] = [
        "0": "〇", "1": "〡", "2": "〢", "3": "〣", "4": "〤",
        "5": "〥", "6": "〦", "7": "〧", "8": "〨", "9": "〩",
    ]
    static private let horizontalDigits: [Character: String] = [
        "1": "一", "2": "二", "3": "三",
    ]
    static private let placeNames = [
        "", "十", "百", "千",
        "万", "十万", "百万", "千万",
        "億", "十億", "百億", "千億",
        "兆", "十兆", "百兆", "千兆",
        "京", "十京", "百京", "千京",
        "垓", "十垓", "百垓", "千垓",
        "秭", "十秭", "百秭", "千秭",
        "穰", "十穰", "百穰", "千穰",
    ]

    /// Converts an Arabic number to a Suzhou number
    /// - Parameters:
    ///   - intPart: The integer part of the number
    ///   - decPart: The decimal part of the number
    ///   - unit: An additional string representing the unit like 元, 两, etc.
    ///   - preferInitialVertical: If vertical digits like 〡,〢, and 〣 are
    ///         preferred than 一, 二 and 三.
    /// - Returns: The output
    @objc static public func generate(
        intPart: String, decPart: String,
        unit: String = "",
        preferInitialVertical: Bool = true
    ) -> String {
        var intTrimmed = intPart.trimmingZerosAtStart()
        let decTrimmed = decPart.trimmingZerosAtEnd()
        var output = ""
        var trimmedZeroCounts = 0

        if decTrimmed.isEmpty {
            let trimmed = intTrimmed.trimmingZerosAtEnd()
            trimmedZeroCounts = intTrimmed.count - trimmed.count
            intTrimmed = trimmed
        }
        if intTrimmed.isEmpty {
            intTrimmed = "0"
        }

        let joined = intTrimmed + decTrimmed
        var isVertical = preferInitialVertical
        for c in joined {
            switch c {
            case "1", "2", "3":
                output += isVertical ? verticalDigits[c]! : horizontalDigits[c]!
                isVertical = !isVertical
            default:
                output += verticalDigits[c]!
                isVertical = preferInitialVertical
            }
        }
        if output.count == 1 && trimmedZeroCounts == 0 {
            return output + unit
        }
        if output.count == 1 && trimmedZeroCounts == 1 {
            let c = intTrimmed[intTrimmed.startIndex]
            switch c {
            case "1":
                return "〸" + unit
            case "2":
                return "〹" + unit
            case "3":
                return "〺" + unit
            default:
                break
            }
        }
        let place = intTrimmed.count + trimmedZeroCounts - 1
        return output + (output.count > 1 ? "\n" : "") + placeNames[place] + unit
    }
}
