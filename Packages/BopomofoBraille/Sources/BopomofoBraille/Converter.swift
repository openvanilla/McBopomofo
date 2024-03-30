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

/// Convert Bopomofo to Braille and vice versa.
@objc public class BopomofoBrailleConverter: NSObject {
    private enum ConverterState {
        case initial
        case bpmf
        case digits
        case letters
    }

    /// Convert from Bopomofo to Braille.
    @objc(convertFromBopomofo:)
    public static func convert(bopomofo: String) -> String {
        var state = ConverterState.initial
        var output = ""
        var readHead = 0
        let length = bopomofo.count

        while readHead < length {
            if String(bopomofo[bopomofo.index(bopomofo.startIndex, offsetBy: readHead)]) == " " {
                if output.isEmpty {
                    output += " "
                } else if output[output.index(output.endIndex, offsetBy: -1)] != " " {
                    output += " "
                }
                readHead += 1
                state = .initial
                continue
            }

            if state == .digits {
                let substring = String(
                    bopomofo[bopomofo.index(bopomofo.startIndex, offsetBy: readHead)])
                if let aCase = Digit(rawValue: substring) {
                    output += aCase.braille
                    readHead += 1
                    continue
                }
                let target = min(2, length - readHead - 1)
                var found = false
                for i in (0...target).reversed() {
                    let start = bopomofo.index(bopomofo.startIndex, offsetBy: readHead)
                    let end = bopomofo.index(bopomofo.startIndex, offsetBy: readHead + i)
                    let substring = bopomofo[start...end]
                    if let aCase = DigitRelated(rawValue: String(substring)) {
                        output += aCase.braille
                        readHead += 1
                        found = true
                        break
                    }
                }
                if found {
                    continue
                }
                state = .initial
                output += " "
            }

            if state == .letters {
                let substring = String(
                    bopomofo[bopomofo.index(bopomofo.startIndex, offsetBy: readHead)])
                let lowered = substring.lowercased()
                if ("a"..."z").contains(lowered) {
                    if ("A"..."Z").contains(substring) {
                        output += "⠠"
                    }
                    if let aCase = Letter(rawValue: lowered) {
                        output += aCase.braille
                    }
                    readHead += 1
                    continue
                }
                if let aCase = HalfWidthPunctuation(rawValue: substring) {
                    output += aCase.braille
                    readHead += 1
                    continue
                }
                state = .initial
                output += " "
            }

            do {
                let target = min(3, length - readHead - 1)
                var found = false
                for i in (0...target).reversed() {
                    let start = bopomofo.index(bopomofo.startIndex, offsetBy: readHead)
                    let end = bopomofo.index(bopomofo.startIndex, offsetBy: readHead + i)
                    let substring = bopomofo[start...end]
                    do {
                        let syllable = try BopomofoSyllable(rawValue: String(substring))
                        output += syllable.braille
                        readHead += i + 1
                        state = .bpmf
                        found = true
                        break
                    } catch {
                        // pass
                    }
                }
                if found {
                    continue
                }
            }

            do {
                let substring = String(
                    bopomofo[bopomofo.index(bopomofo.startIndex, offsetBy: readHead)])
                if let punctuation = FullWidthPunctuation(rawValue: substring) {
                    output += punctuation.braille
                    readHead += 1
                    state = .bpmf
                    continue
                }
            }

            let substring = String(
                bopomofo[bopomofo.index(bopomofo.startIndex, offsetBy: readHead)])

            if ("0"..."9").contains(substring) {
                if state != .initial {
                    output += " "
                }
                output += "⠼"
                if let aCase = Digit(rawValue: substring) {
                    output += aCase.braille
                }
                readHead += 1
                state = ConverterState.digits
                continue
            }

            let lowered = substring.lowercased()

            if ("a"..."z").contains(lowered) {
                if state != .initial {
                    output += " "
                }
                if ("A"..."Z").contains(substring) {
                    output += "⠠"
                }
                if let aCase = Letter(rawValue: lowered) {
                    output += aCase.braille
                }
                readHead += 1
                state = .letters
                continue
            }

            if let punctuation = HalfWidthPunctuation(rawValue: substring) {
                if state != .initial {
                    output += " "
                }
                output += punctuation.braille
                readHead += 1
                state = .letters
            }
            if state != .initial {
                output += " "
            }

            output += substring
            readHead += 1
        }

        return output
    }

    /// Convert from Bopomofo to Braille.
    @objc(convertFromBraille:)
    public static func convert(braille: String) -> String {
        var output = ""
        let tokens = self.convert(brailleToTokens: braille)
        for token in tokens {
            if let token = token as? BopomofoSyllable {
                output += token.rawValue
            }
            if let token = token as? String {
                output += token
            }
        }
        return output
    }

    @objc(convertBrailleToTokens:)
    public static func convert(brailleToTokens braille: String) -> [Any] {
        var state = ConverterState.initial
        var output: [Any] = []
        var readHead = 0
        var nonBpmfText = ""
        let length = braille.count

        while readHead < length {

            if String(braille[braille.index(braille.startIndex, offsetBy: readHead)]) == " " {
                if nonBpmfText.isEmpty {
                    nonBpmfText += " "
                }
                else if nonBpmfText[nonBpmfText.index(nonBpmfText.endIndex, offsetBy: -1)] != " " {
                    nonBpmfText += " "
                }
                readHead += 1
                state = .initial
                continue
            }

            if state == .digits {
                let substring = String(
                    braille[braille.index(braille.startIndex, offsetBy: readHead)])
                if let digit = Digit(braille: substring) {
                    nonBpmfText += digit.rawValue
                    readHead += 1
                    continue
                }
                let target = min(7, length - readHead - 1)
                var found = false
                for i in (1...target).reversed() {
                    let start = braille.index(braille.startIndex, offsetBy: readHead)
                    let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                    let substring = braille[start...end]
                    if let punctuation = DigitRelated(braille: String(substring)) {
                        nonBpmfText += punctuation.rawValue
                        readHead += i + 1
                        found = true
                        break
                    }
                }
                if found {
                    continue
                }
                state = .initial
            }

            if state == .letters {
                var substring = String(
                    braille[braille.index(braille.startIndex, offsetBy: readHead)])
                var isUppercase = false
                if substring == "⠠" {
                    // Uppercase1;
                    isUppercase = true
                    substring = String(
                        braille[braille.index(braille.startIndex, offsetBy: readHead + 1)])
                }
                if let letter = Letter(braille: substring) {
                    if isUppercase {
                        nonBpmfText += letter.rawValue.uppercased()
                        readHead += 2
                    } else {
                        nonBpmfText += letter.rawValue
                        readHead += 1
                    }
                    continue
                }

                let target = min(3, length - readHead - 1)
                var found = false
                if target >= 1 {
                    for i in (1...target).reversed() {
                        let start = braille.index(braille.startIndex, offsetBy: readHead)
                        let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                        let substring = braille[start...end]
                        if let punctuation = HalfWidthPunctuation(braille: String(substring)) {
                            nonBpmfText += punctuation.rawValue
                            readHead += i + 1
                            found = true
                            break
                        }
                    }
                }
                if found {
                    continue
                }
                state = .initial
            }

            // BPMF
            do {
                let target = min(2, length - readHead - 1)
                var found = false
                if target > 0 {
                    for i in (1...target).reversed() {
                        let start = braille.index(braille.startIndex, offsetBy: readHead)
                        let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                        let substring = braille[start...end]

                        if substring[substring.index(substring.endIndex, offsetBy: -1)] == " " {
                            // For example, "⠋⠺ " is valid since it could be see as "ㄊㄞ ",
                            // but we want to keep the space in the output.
                            continue
                        }

                        do {
                            let b = try BopomofoSyllable(braille: String(substring))
                            readHead += i + 1
                            if !nonBpmfText.isEmpty {
                                output.append(nonBpmfText)
                                nonBpmfText = ""
                            }
                            output.append(b)
                            state = .bpmf
                            found = true
                            break
                        } catch {
                            // pass
                        }
                    }
                }
                if found {
                    continue
                }
            }
            // FullWidthPunctuation
            do {
                let target = min(4, length - readHead - 1)
                var found = false
                for i in (0...target).reversed() {
                    let start = braille.index(braille.startIndex, offsetBy: readHead)
                    let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                    let substring = braille[start...end]
                    if let punctuation = FullWidthPunctuation(braille: String(substring)) {
                        if state == .initial
                            && punctuation.supposedToBeAtStart == false
                        {
                            continue
                        }
                        nonBpmfText += punctuation.rawValue
                        readHead += i + 1
                        state = .bpmf
                        found = true
                        break
                    }
                }
                if found {
                    continue
                }
            }

            let substring = String(braille[braille.index(braille.startIndex, offsetBy: readHead)])

            if substring == "⠼" {
                let next = String(
                    braille[braille.index(braille.startIndex, offsetBy: readHead + 1)])
                if let digit = Digit(braille: next) {
                    nonBpmfText += digit.rawValue
                    readHead += 2
                    state = .digits
                    continue
                }
            }

            if substring == "⠠" && readHead < braille.count {
                let next = String(
                    braille[braille.index(braille.startIndex, offsetBy: readHead + 1)])
                if let letter = Letter(braille: next) {
                    nonBpmfText += letter.rawValue.uppercased()
                    readHead += 2
                    state = .letters
                    continue
                }
            }

            if let letter = Letter(braille: substring) {
                nonBpmfText += letter.rawValue
                readHead += 1
                state = .letters
                continue
            }

            do {
                let target = min(3, length - readHead - 1)
                var found = false
                for i in (0...target).reversed() {
                    let start = braille.index(braille.startIndex, offsetBy: readHead)
                    let end = braille.index(braille.startIndex, offsetBy: readHead + i)
                    let substring = braille[start...end]
                    if let punctuation = HalfWidthPunctuation(braille: String(substring)) {
                        nonBpmfText += punctuation.rawValue
                        readHead += i + 1
                        state = .letters
                        found = true
                        break
                    }
                }
                if found {
                    continue
                }
            }

            nonBpmfText += substring
            readHead += 1
        }

        if !nonBpmfText.isEmpty {
            output.append(nonBpmfText)
            nonBpmfText = ""
        }

        return output
    }
}
