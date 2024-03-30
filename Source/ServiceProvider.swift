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

import AppKit
import BopomofoBraille
import OpenCCBridge

class ServiceProvider: NSObject {
    weak var delegate: ServiceProviderDelegate? {
        didSet {
            delegate?.serviceProvider(didRequestReset: self)
        }
    }

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

        let reading = matches.joined(separator: "-")
        return reading
    }

    @objc func addUserPhrase(_ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let string = pasteboard.string(forType: .string),
            let firstWord = string.components(separatedBy: .whitespacesAndNewlines).first
        else {
            return
        }

        if firstWord.isEmpty {
            return
        }

        let reading = extractReading(from: firstWord)

        if reading.isEmpty {
            return
        }

        LanguageModelManager.writeUserPhrase("\(firstWord) \(reading)")
        (NSApp.delegate as? AppDelegate)?.openUserPhrases(self)
    }
}

@objc protocol ServiceProviderDelegate: NSObjectProtocol {
    @objc(serviceProvider:didRequestInsertReading:)
    func serviceProvider(_ provider: ServiceProvider, didRequestInsertReading: String)
    @objc(serviceProviderDidRequestCommitting:)
    func serviceProvider(didRequestCommitting provider: ServiceProvider) -> String
    @objc(serviceProviderDidRequestReset:)
    func serviceProvider(didRequestReset provider: ServiceProvider)
}

// MARK: -

private let kMaxLength = 3000

extension ServiceProvider {

    // MARK: -

    /// Use Apple's tokenizer to tokenize the input string.
    func tokenize(string: String) -> [(String, CFStringTokenizerTokenType)] {
        let cfString = string as CFString
        let tokenizer = CFStringTokenizerCreate(
            nil, cfString, CFRange(location: 0, length: CFStringGetLength(cfString)), 0, nil)
        var readHead = 0
        var output: [(String, CFStringTokenizerTokenType)] = []
        while readHead < CFStringGetLength(cfString) {
            let type = CFStringTokenizerAdvanceToNextToken(tokenizer)
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if range.location == kCFNotFound {
                if let subString = CFStringCreateWithSubstring(
                    nil, cfString, CFRangeMake(readHead, 1))
                {
                    output.append((subString as String, CFStringTokenizerTokenType.normal))
                }
                readHead += 1
                continue
            }

            if range.location > readHead {
                if let subString = CFStringCreateWithSubstring(
                    nil, cfString, CFRange(location: readHead, length: range.location - readHead))
                {
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

    func process(
        string: String,
        readingFoundCallback: (String, String) -> String,
        readingNotFoundCallback: (String) -> String,
        addSpace: Bool = false
    ) -> String {
        var output = ""
        let tokens = tokenize(string: string)
        var previousTokenType: CFStringTokenizerTokenType?

        for tokenTuple in tokens {
            let token = tokenTuple.0
            let type = tokenTuple.1
            if let previousTokenType = previousTokenType {
                let lastChar = output[output.index(output.endIndex, offsetBy: -1)]
                if lastChar != " " {
                    if previousTokenType.contains(.isCJWordMask) && !type.contains(.isCJWordMask) {
                        output.append(" ")
                    }
                    else if !previousTokenType.contains(.isCJWordMask) && type.contains(.isCJWordMask) {
                        output.append(" ")
                    }
                }
            }
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
            for c in token {
                if let reading = LanguageModelManager.reading(for: String(c)) {
                    if reading.isEmpty == false && reading.starts(with: "_") == false {
                        output += readingFoundCallback(String(c), reading)
                    } else {
                        output += readingNotFoundCallback("\(c)")
                    }
                } else {
                    output += readingNotFoundCallback("\(c)")
                }
            }
        }
        return output
    }

    func addReading(string: String) -> String {
        process(string: string) {
            "\($0)(\($1))"
        } readingNotFoundCallback: {
            $0
        }
    }

    @objc func addReading(_ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let string = pasteboard.string(forType: .string), string.count < kMaxLength,
            let converted = OpenCCBridge.shared.convertToTraditional(String(string))
        else {
            return
        }
        let output = converted.components(separatedBy: "\n").map { input in
            addReading(string: input)
        }.joined(separator: "\n")

        if output.isEmpty {
            return
        }
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

    func convertToReadings(string: String) -> String {
        process(string: string) {
            $1
        } readingNotFoundCallback: {
            $0
        }
    }

    @objc func convertToReadings(
        _ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer
    ) {
        guard let string = pasteboard.string(forType: .string), string.count < kMaxLength
        else {
            return
        }
        let output = string.components(separatedBy: "\n").map { input in
            convertToReadings(string: input)
        }.joined(separator: "\n")

        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

    // MARK: - Braille

    func convertToBraille(string: String) -> String {
        process(string: string) {
            BopomofoBrailleConverter.convert(bopomofo: $1)
        } readingNotFoundCallback: {
            BopomofoBrailleConverter.convert(bopomofo: $0)
        }
    }

    @objc func convertToBraille(
        _ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer
    ) {
        guard let string = pasteboard.string(forType: .string), string.count < kMaxLength
        else {
            return
        }
        let output = string.components(separatedBy: "\n").map { input in
            convertToBraille(string: input)
        }.joined(separator: "\n")
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

    func convertBrailleToChineseText(string: String) -> String {
        delegate?.serviceProvider(didRequestReset: self)
        var output = ""
        let tokens = BopomofoBrailleConverter.convert(brailleToTokens: string)

        for token in tokens {
            switch token {
            case let token as BopomofoSyllable:
                delegate?.serviceProvider(self, didRequestInsertReading: token.rawValue)
            case let token as String:
                if let string = delegate?.serviceProvider(didRequestCommitting: self) {
                    output += string
                }
                output += token
            default:
                continue
            }
        }
        if let string = delegate?.serviceProvider(didRequestCommitting: self) {
            output += string
        }
        return output
    }

    @objc func convertBrailleToChineseText(
        _ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer
    ) {
        guard let string = pasteboard.string(forType: .string)
        else {
            return
        }
        let output = convertBrailleToChineseText(string: string)
        if output.isEmpty {
            return
        }

        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

}
