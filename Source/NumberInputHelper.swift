import ChineseNumbers
import Foundation
import Playgrounds
import RomanNumbers

@objc
class NumberInputHelper: NSObject {
    @objc
    static func cadiddatesFor(numberString: String) -> [String] {
        if numberString.isEmpty {
            return []
        }
        var intPart = ""
        var decPart = ""
        let components = numberString.split(separator: ".")
        if components.count > 0 {
            intPart = String(components[0])
        }
        if components.count > 1 {
            decPart = String(components[1])
        }
        var result = [
            ChineseNumbers.generate(intPart: intPart, decPart: decPart, digitCase: .lowercase),
            ChineseNumbers.generate(intPart: intPart, decPart: decPart, digitCase: .uppercase),
        ]

        if let intNumber = Int(intPart),
            intNumber > 0 && intNumber <= 3999
        {
            do {
                try result.append(RomanNumbers.convert(input: intNumber, style: .alphabets))
            } catch {}
            do {
                try result.append(RomanNumbers.convert(input: intNumber, style: .fullWidthLower))
            } catch {}
            do {
                try result.append(RomanNumbers.convert(input: intNumber, style: .fullWidthUpper))
            } catch {}
        }

        return result
    }

}
