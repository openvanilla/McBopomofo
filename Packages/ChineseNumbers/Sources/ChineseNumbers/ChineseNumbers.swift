import Foundation

/// Helps to convert Arabic numbers to Chinese numbers
@objc public class ChineseNumbers: NSObject {

    /// Represents uppercase or lowercase Chinese numbers
    /// - lowercase: like 一、二、三
    /// - uppercase: like 壹、貳、參
    @objc (ChineseNumbersCase)
    public enum Case: Int {
        case lowercase
        case uppercase

        fileprivate var digits: [Character: String] {
            return switch self {
            case .lowercase:
                ["0": "〇", "1": "一", "2": "二", "3": "三", "4": "四", "5": "五", "6": "六", "7": "七", "8": "八", "9": "九"]
            case .uppercase:
                ["0": "零", "1": "壹", "2": "貳", "3": "參", "4": "肆", "5": "伍", "6": "陸", "7": "柒", "8": "捌", "9": "玖"]
            }
        }

        fileprivate var places: [String] {
            return switch self {
            case .lowercase:
                ["千", "百", "十", ""]
            case .uppercase:
                ["仟", "佰", "拾", ""]
            }
        }
    }

    fileprivate static let higherPlaces = ["", "萬", "億", "兆", "京", "垓", "秭", "穰"]

    /// Converts an Arabic number to a Chinese number
    /// - Parameters:
    ///   - intPart: The integer part of the number
    ///   - decPart: The decimal part of the number
    ///   - digitCase: Whether in uppercase or lowercase
    /// - Returns: The output
    @objc static public func generate(intPart: String, decPart: String, digitCase: Case) -> String {

        func convert4Digits(_ subString: Substring, zeroEverHappened:Bool = false) -> String {
            var zeroHappened = zeroEverHappened
            var output = ""
            for i in 0..<4 {
                let c = subString[subString.index(subString.startIndex, offsetBy: i)]
                switch c {
                case " ":
                    continue
                case "0":
                    zeroHappened = true
                    continue
                default:
                    if zeroHappened {
                        output.append(digitCase.digits["0"]!)
                    }
                    zeroHappened = false
                    output.append(digitCase.digits[c]!)
                    output.append(digitCase.places[i])
                }
            }
            return output
        }

        let intTrimmed = intPart.trimmingZerosAtStart()
        let decTrimmed = decPart.trimmingZerosAtEnd()

        var output = ""

        if intTrimmed.isEmpty {
            output.append(digitCase.digits["0"]!)
        } else {
            // 4 digits as a section.
            let intSectionCount = Int(ceil( Double(intTrimmed.count) / 4.0))
            let filledLength = intSectionCount * 4
            let filled = intTrimmed.leftPadding(toLength: filledLength, withPad: " ")
            var readHead = 0
            var zeroEverHappened = false

            while readHead < filledLength {
                let subString = filled[
                    filled.index(filled.startIndex, offsetBy: readHead)
                    ..<
                    filled.index(filled.startIndex, offsetBy: readHead + 4)
                ]
                if subString == "0000" {
                    zeroEverHappened = true
                    readHead += 4
                    continue
                }
                let subOutput = convert4Digits(subString, zeroEverHappened: zeroEverHappened)
                zeroEverHappened = false
                output.append(subOutput)
                let place = (filledLength - readHead) / 4 - 1
                output.append(ChineseNumbers.higherPlaces[place])
                readHead += 4
            }
        }

        if !decTrimmed.isEmpty {
            output.append("點")
            for c in decTrimmed {
                output.append(digitCase.digits[c]!)
            }
        }
        return output
    }

}
