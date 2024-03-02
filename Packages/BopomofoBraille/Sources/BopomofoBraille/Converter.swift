import Foundation

/// Convert Bopomofo to Braille and vice versa.
@objc public class BopomofoBrailleConverter: NSObject {
    /// Convert from Bopomofo to Braille.
    @objc(convertFromBopomofo:)
    public static func convert(bopomofo: String) -> String {
        var output = ""
        var readHead = 0
        let length = bopomofo.count

        while readHead < length {
            let target = min(3, length - readHead - 1)
            var found = false
            for i in (0...target).reversed() {
                let start = bopomofo.index(bopomofo.startIndex, offsetBy: readHead)
                let end = bopomofo.index(bopomofo.startIndex, offsetBy: readHead + i)
                let substring = bopomofo[start...end]
                do {
                    let b = try BopomofoSyllable(rawValue: String(substring))
                    output += b.braille
                    readHead += i + 1
                    found = true
                    break
                } catch {
                    // pass
                }
            }
            if !found {
                let start = bopomofo.index(bopomofo.startIndex, offsetBy: readHead)
                let end = bopomofo.index(bopomofo.startIndex, offsetBy: readHead)
                let substring = bopomofo[start...end]
                if let punctuation = Punctuation(rawValue: String(substring)) {
                    output += punctuation.braille
                    readHead += 1
                    found = true
                }
            }

            if !found {
                let start = bopomofo.index(bopomofo.startIndex, offsetBy: readHead)
                output += bopomofo[start...start]
                readHead += 1
            }
        }

        return output
    }

    /// Convert from Bopomofo to Braille.
    @objc(convertFromBraille:)
    public static func convert(braille: String) -> String {
        var output = ""
        var readHead = 0
        let length = braille.count

        while readHead < length {
            var target = min(2, length - readHead - 1)
            var found = false
            if target > 0 {
                for i in (1...target).reversed() {
                    let start = braille.index(braille.startIndex, offsetBy: readHead)
                    let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                    let substring = braille[start...end]
                    do {
                        let b = try BopomofoSyllable(braille: String(substring))
                        output += b.rawValue
                        readHead += i + 1
                        found = true
                        break
                    } catch {
                        // pass
                    }
                }
            }

            if !found {
                target = min(3, length - readHead - 1)
                for i in (0...target).reversed() {
                    let start = braille.index(braille.startIndex, offsetBy: readHead)
                    let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                    let substring = braille[start...end]
                    if let punc = Punctuation(braille: String(substring)) {
                        output += punc.rawValue
                        readHead += i + 1
                        found = true
                        break
                    }
                }
            }

            if !found {
                let start = braille.index(braille.startIndex, offsetBy: readHead)
                output += braille[start...start]
                readHead += 1
            }
        }

        return output
    }

    @objc(convertBrailleToTokens:)
    public static func convert(brailleToTokens braille: String) -> [Any] {
        var output: [Any] = []
        var readHead = 0
        var text = ""
        let length = braille.count

        while readHead < length {
            var target = min(2, length - readHead - 1)
            var found = false
            if target > 0 {
                for i in (1...target).reversed() {
                    let start = braille.index(braille.startIndex, offsetBy: readHead)
                    let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                    let substring = braille[start...end]
                    do {
                        let b = try BopomofoSyllable(braille: String(substring))
                        readHead += i + 1
                        if !text.isEmpty {
                            output.append(text)
                            text = ""
                        }
                        output.append(b)
                        found = true
                        break
                    } catch {
                        // pass
                    }
                }
            }

            if !found {
                target = min(3, length - readHead - 1)
                for i in (0...target).reversed() {
                    let start = braille.index(braille.startIndex, offsetBy: readHead)
                    let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                    let substring = braille[start...end]
                    if let punctuation = Punctuation(braille: String(substring)) {
                        text += punctuation.rawValue
                        readHead += i + 1
                        found = true
                        break
                    }
                }
            }

            if !found {
                let start = braille.index(braille.startIndex, offsetBy: readHead)
                text += braille[start...start]
                readHead += 1
            }
        }

        if !text.isEmpty {
            output.append(text)
            text = ""
        }

        return output
    }
}
