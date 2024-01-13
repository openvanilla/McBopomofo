import Foundation

public class SuzhouNumbers: NSObject {

    static private let verticalDigits: [Character: String] = [
        "0": "〇", "1": "〡", "2": "〢", "3": "〣", "4": "〤",
        "5": "〥", "6": "〦", "7": "〧", "8": "〨", "9": "〩"
    ]
    static private let horizontalDigits: [Character: String] = [
        "1": "一", "2": "二", "3": "三"
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

    @objc static public func generate(intPart: String, decPart: String,
                               unit: String = "",
                               preferInitialVertical: Bool = true ) -> String {
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
            case "0", "1", "2":
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
        return output + "\n" + placeNames[place] + unit
    }
}
