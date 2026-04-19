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

import BopomofoBraille
import Foundation
import OpenCCBridge

/// Handles stateful conversion requests used by ``McBopomofoService``.
@objc protocol McBopomofoServiceDelegate: NSObjectProtocol {
    /// Inserts a reading into the delegate-managed composing buffer.
    @objc(mcBopomofoService:didRequestInsertReading:)
    func mcBopomofoService(_ service: McBopomofoService, didRequestInsertReading reading: String)

    /// Commits and returns the current composed text from the delegate.
    /// - Returns: The committed text.
    @objc(mcBopomofoServiceDidRequestCommitting:)
    func mcBopomofoServiceDidRequestCommitting(_ service: McBopomofoService) -> String

    /// Resets the delegate-managed composing state.
    @objc(mcBopomofoServiceDidRequestReset:)
    func mcBopomofoServiceDidRequestReset(_ service: McBopomofoService)

    /// Converts a Bopomofo reading to Hanyu Pinyin.
    /// - Returns: The converted Hanyu Pinyin string.
    @objc(mcBopomofoService:didRequestConvertReadingToHanyuPinyin:)
    func mcBopomofoService(
        _ service: McBopomofoService, didRequestConvertReadingToHanyuPinyin reading: String
    ) -> String
}

class McBopomofoService: NSObject {
    weak var delegate: McBopomofoServiceDelegate?

    func extractReading(from firstWord: String) -> String {
        var matches: [String] = []

        // greedily find the longest possible matches
        var matchFrom = firstWord.startIndex
        while matchFrom < firstWord.endIndex {
            let substring = firstWord.suffix(from: matchFrom)
            let substringCount = substring.count

            // if an exact match fails, try dropping successive characters from the end to see
            // if we can find shorter matches
            var drop = 0
            while drop < substringCount {
                let candidate = String(substring.dropLast(drop))
                if let converted = OpenCCBridge.shared.convertToTraditional(candidate),
                   let match = LanguageModelManager.reading(for: converted)
                {
                    // append the match and skip over the matched portion
                    matches.append(match)
                    matchFrom = firstWord.index(matchFrom, offsetBy: substringCount - drop)
                    break
                }
                drop += 1
            }

            if drop >= substringCount {
                // didn't match anything?!
                matches.append("？")
                matchFrom = firstWord.index(matchFrom, offsetBy: 1)
            }
        }

        return matches.joined(separator: "-")
    }

    func addUserPhrase(named name: String) -> Bool {
        guard !name.isEmpty else {
            return false
        }

        let reading = extractReading(from: name)
        guard !reading.isEmpty else {
            return false
        }

        return LanguageModelManager.writeUserPhrase("\(name) \(reading)")
    }

    /// Tokenizes the input string with Apple's tokenizer.
    /// - Parameter string: The input string.
    /// - Returns: An array of token strings and their token types.
    func tokenize(string: String) -> [(String, CFStringTokenizerTokenType)] {
        let cfString = string as CFString
        let tokenizer = CFStringTokenizerCreate(
            nil, cfString, CFRange(location: 0, length: CFStringGetLength(cfString)), 0, nil
        )
        var readHead = 0
        var output: [(String, CFStringTokenizerTokenType)] = []
        while readHead < CFStringGetLength(cfString) {
            let type = CFStringTokenizerAdvanceToNextToken(tokenizer)
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if range.location == kCFNotFound {
                if let subString = CFStringCreateWithSubstring(
                    nil, cfString, CFRangeMake(readHead, 1)
                ) {
                    output.append((subString as String, CFStringTokenizerTokenType.normal))
                }
                readHead += 1
                continue
            }

            if range.location > readHead {
                if let subString = CFStringCreateWithSubstring(
                    nil, cfString, CFRange(location: readHead, length: range.location - readHead)
                ) {
                    output.append((subString as String, CFStringTokenizerTokenType.normal))
                }
            }
            if let subString = CFStringCreateWithSubstring(nil, cfString, range) {
                output.append((subString as String, type))
            }
            readHead = range.location + range.length
        }
        return output
    }

    /// Converts text with reading-aware callbacks.
    /// - Parameters:
    ///   - string: The input string.
    ///   - addSpace: Whether to insert spaces between CJK and ASCII tokens when needed.
    ///   - convertEachCharacter: Whether to process non-phrase tokens character by character.
    ///   - readingFoundCallback: Called when a reading is found for a token or character.
    ///   - readingNotFoundCallback: Called when no reading is found.
    /// - Returns: The transformed string.
    private func process(
        string: String,
        addSpace: Bool,
        convertEachCharacter: Bool,
        readingFoundCallback: (String, String) -> String,
        readingNotFoundCallback: (String) -> String
    ) -> String {
        var output = ""
        let tokens = tokenize(string: string)

        var previousToken: String?
        var previousTokenType: CFStringTokenizerTokenType?

        for tokenTuple in tokens {
            let token = tokenTuple.0
            let type = tokenTuple.1
            if addSpace, let previousToken, let previousTokenType {
                let lastChar = output[output.index(before: output.endIndex)]
                if lastChar != " " {
                    if previousTokenType.contains(.isCJWordMask)
                        && (!type.contains(.isCJWordMask) && token[token.startIndex].isASCII)
                    {
                        output.append(" ")
                    } else if (!previousTokenType.contains(.isCJWordMask)
                        && previousToken[previousToken.index(before: previousToken.endIndex)]
                        .isASCII)
                        && type.contains(.isCJWordMask)
                    {
                        output.append(" ")
                    }
                }
            }
            previousToken = token
            previousTokenType = type

            if let reading = LanguageModelManager.reading(for: token) {
                if reading.isEmpty == false && reading.starts(with: "_") == false {
                    let readings = reading.components(separatedBy: "-")
                    if readings.count == token.count {
                        for (index, c) in token.enumerated() {
                            output += readingFoundCallback(String(c), readings[index])
                        }
                        continue
                    }
                }
            }

            var buffer = ""

            for c in token {
                if let reading = LanguageModelManager.reading(for: String(c)) {
                    if reading.isEmpty == false && reading.starts(with: "_") == false {
                        if convertEachCharacter == false && buffer.isEmpty == false {
                            output += readingNotFoundCallback(buffer)
                            buffer = ""
                        }
                        output += readingFoundCallback(String(c), reading)
                    } else {
                        if convertEachCharacter {
                            output += readingNotFoundCallback("\(c)")
                        } else {
                            buffer += "\(c)"
                        }
                    }
                } else {
                    if convertEachCharacter {
                        output += readingNotFoundCallback("\(c)")
                    } else {
                        buffer += "\(c)"
                    }
                }
            }
            if convertEachCharacter == false && buffer.isEmpty == false {
                output += readingNotFoundCallback(buffer)
            }
        }
        return output
    }

    func addReading(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            "\($0)(\($1))"
        } readingNotFoundCallback: {
            $0
        }
    }

    func addHanyuPinyin(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            let pinyin =
                delegate?.mcBopomofoService(self, didRequestConvertReadingToHanyuPinyin: $1) ?? ""
            return "\($0)(\(pinyin))"
        } readingNotFoundCallback: {
            $0
        }
    }

    func convertToReadings(string: String) -> String {
        process(string: string, addSpace: false, convertEachCharacter: true) {
            $1
        } readingNotFoundCallback: {
            $0
        }
    }

    func convertToHanyuPinyin(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            delegate?.mcBopomofoService(self, didRequestConvertReadingToHanyuPinyin: $1) ?? $1
        } readingNotFoundCallback: {
            $0
        }
    }

    private func convertToBraille(string: String, type: BrailleType) -> String {
        process(string: string, addSpace: true, convertEachCharacter: false) {
            BopomofoBrailleConverter.convert(bopomofo: $1, type: type)
        } readingNotFoundCallback: {
            BopomofoBrailleConverter.convert(bopomofo: $0, type: type)
        }
    }

    func convertToUnicodeBraille(string: String) -> String {
        convertToBraille(string: string, type: .unicode)
    }

    func convertToASCIIBraille(string: String) -> String {
        convertToBraille(string: string, type: .ascii)
    }

    private func convertBrailleToChineseText(string: String, type: BrailleType) -> String {
        delegate?.mcBopomofoServiceDidRequestReset(self)
        var output = ""
        let tokens = BopomofoBrailleConverter.convert(brailleToTokens: string, type: type)

        for token in tokens {
            switch token {
            case let token as BopomofoSyllable:
                delegate?.mcBopomofoService(self, didRequestInsertReading: token.rawValue)
            case let token as String:
                if let string = delegate?.mcBopomofoServiceDidRequestCommitting(self) {
                    output += string
                }
                output += token
            default:
                continue
            }
        }
        if let string = delegate?.mcBopomofoServiceDidRequestCommitting(self) {
            output += string
        }
        return output
    }

    func convertUnicodeBrailleToChineseText(string: String) -> String {
        convertBrailleToChineseText(string: string, type: .unicode)
    }

    func convertASCIIBrailleToChineseText(string: String) -> String {
        convertBrailleToChineseText(string: string, type: .ascii)
    }

    func convertToBpmfAnnotatedText(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            LanguageModelManager.annotateVariant(characters: $0, readings: $1)
        } readingNotFoundCallback: {
            $0
        }
    }
}
