import Foundation

@objc
public enum RomanNumbersErrors: Int, Error, LocalizedError {
    case tooLarge
    case tooSmall
    case invalidInput

    public var errorDescription: String? {
        switch self {
        case .tooLarge:
            "Cannot be larger than 3999"
        case .tooSmall:
            "Cannot be less than 0"
        case .invalidInput:
            "Input is not a valid integer"
        }
    }
}

@objc public enum RomanNumbersStyle: Int {
    case alphabets
    case fullWidthUpper
    case fullWidthLower
}

struct DigitsMap {
    let digits: [String]
    let tens: [String]
    let hundreds: [String]
    let thousands: [String]
}

extension RomanNumbersStyle {
    var digitsMap: DigitsMap {
        switch self {
        case .alphabets:
            DigitsMap(
                digits: ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"],
                tens: ["", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"],
                hundreds: ["", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"],
                thousands: ["", "M", "MM", "MMM"])
        case .fullWidthUpper:
            DigitsMap(
                digits: ["", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ"],
                tens: ["", "Ⅹ", "ⅩⅩ", "ⅩⅩⅩ", "ⅩⅬ", "Ⅼ", "ⅬⅩ", "ⅬⅩⅩ", "ⅬⅩⅩⅩ", "ⅩⅭ"],
                hundreds: ["", "Ⅽ", "ⅭⅭ", "ⅭⅭⅭ", "ⅭⅮ", "Ⅾ", "ⅮⅭ", "ⅮⅭⅭ", "ⅮⅭⅭⅭ", "ⅭⅯ"],
                thousands: ["", "Ⅿ", "ⅯⅯ", "ⅯⅯⅯ"])
        case .fullWidthLower:
            DigitsMap(
                digits: ["", "ⅰ", "ⅱ", "ⅲ", "ⅳ", "ⅴ", "ⅵ", "ⅶ", "ⅷ", "ⅸ"],
                tens: ["", "ⅹ", "ⅹⅹ", "ⅹⅹⅹ", "ⅹⅼ", "ⅼ", "ⅼⅹ", "ⅼⅹⅹ", "ⅼⅹⅹⅹ", "ⅹⅽ"],
                hundreds: ["", "ⅽ", "ⅽⅽ", "ⅽⅽⅽ", "ⅽⅾ", "ⅾ", "ⅾⅽ", "ⅾⅽⅽ", "ⅾⅽⅽⅽ", "ⅽⅿ"],
                thousands: ["", "ⅿ", "ⅿⅿ", "ⅿⅿⅿ"])
        }
    }
}

@objc
public class RomanNumbers: NSObject {
    @objc(convertWithInt:style:error:)
    public static func convert(input: Int, style: RomanNumbersStyle = .alphabets) throws -> String {
        if input > 3999 {
            throw RomanNumbersErrors.tooLarge
        }
        if input < 0 {
            throw RomanNumbersErrors.tooSmall
        }

        if style == .fullWidthUpper {
            switch input {
            case 11:
                return "Ⅺ"
            case 12:
                return "Ⅻ"
            default:
                break
            }
        }

        if style == .fullWidthLower {
            switch input {
            case 11:
                return "ⅺ"
            case 12:
                return "ⅻ"
            default:
                break
            }

        }

        let thou = input / 1000
        let hund = (input % 1000) / 100
        let ten = (input % 100) / 10
        let digit = input % 10

        let map = style.digitsMap

        let result = map.thousands[thou] + map.hundreds[hund] + map.tens[ten] + map.digits[digit]
        return result
    }

    @objc(convertWithString:style:error:)
    public static func convert(string: String, style: RomanNumbersStyle = .alphabets) throws
        -> String
    {
        guard let number = Int(string) else {
            throw RomanNumbersErrors.invalidInput
        }
        return try convert(input: number, style: style)
    }
}
