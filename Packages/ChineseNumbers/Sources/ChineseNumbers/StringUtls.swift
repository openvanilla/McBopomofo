import Foundation

internal extension String {
    func trimmingZerosAtStart() -> String {
        var nonZeroFound = false
        let substring =  self.drop { c in
            if nonZeroFound {
                return false
            }
            if c != "0" {
                nonZeroFound = true
                return false
            }
            return true
        }
        return String(substring)
    }

    func trimmingZerosAtEnd() -> String {
        let reversed = String(reversed())
        let trimmed = reversed.trimmingZerosAtStart()
        return String(trimmed.reversed())
    }

    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let currentLength = self.count
        return if currentLength < toLength {
            String(repeatElement(character, count: toLength - currentLength)) + self
        } else {
            self
        }
    }

}
