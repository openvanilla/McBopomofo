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

/// Exposes macOS Services for text transformations powered by McBopomofo.
///
/// `ServiceProvider` is the bridge between AppKit's Services infrastructure and
/// the input method's conversion logic. It reads text from the system
/// pasteboard, applies the requested transformation, and writes the result back
/// to the pasteboard when appropriate.
///
/// Stateless conversions, such as adding readings or generating Braille, are
/// handled directly in this type. Stateful conversions that need access to the
/// input method's composing buffer are delegated through
/// ``ServiceProviderDelegate``.
class ServiceProvider: NSObject {
    /// Handles stateful conversion requests that require composing context.
    ///
    /// Assigning a delegate resets its composing state so each service request
    /// starts from a known baseline.
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

    /// Adds the first selected token to the user phrase list.
    @objc func addUserPhrase(_ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer) {
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

/// Handles stateful conversion requests issued by ``ServiceProvider``.
@objc protocol ServiceProviderDelegate: NSObjectProtocol {
    /// Inserts a reading into the delegate-managed composing buffer.
    /// - Parameters:
    ///   - provider: The calling service provider.
    ///   - didRequestInsertReading: The reading to insert.
    @objc(serviceProvider:didRequestInsertReading:)
    func serviceProvider(_ provider: ServiceProvider, didRequestInsertReading: String)

    /// Commits and returns the current composed text from the delegate.
    /// - Parameter provider: The calling service provider.
    /// - Returns: The committed text.
    @objc(serviceProviderDidRequestCommitting:)
    func serviceProvider(didRequestCommitting provider: ServiceProvider) -> String

    /// Resets the delegate-managed composing state.
    /// - Parameter provider: The calling service provider.
    @objc(serviceProviderDidRequestReset:)
    func serviceProvider(didRequestReset provider: ServiceProvider)

    /// Converts a Bopomofo reading to Hanyu Pinyin.
    /// - Parameters:
    ///   - provider: The calling service provider.
    ///   - didRequestConvertReadingToHanyuPinyin: The Bopomofo reading to convert.
    /// - Returns: The converted Hanyu Pinyin string.
    @objc(service:didRequestConvertReadingToHanyuPinyin:)
    func serviceProvider(_ provider: ServiceProvider, didRequestConvertReadingToHanyuPinyin: String) -> String
}

// MARK: -

private let kMaxLength = 3000

extension ServiceProvider {
    // MARK: -

    private func transformPasteboardString(
        _ pasteboard: NSPasteboard,
        maximumLength: Int? = nil,
        skipIfOutputIsEmpty: Bool = false,
        transform: (String) -> String?
    ) {
        guard let string = pasteboard.string(forType: .string) else {
            return
        }

        if let maximumLength, string.count >= maximumLength {
            return
        }

        guard let output = transform(string) else {
            return
        }

        if skipIfOutputIsEmpty, output.isEmpty {
            return
        }

        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
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

    // MARK: - Add readings

    func addReading(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            "\($0)(\($1))"
        } readingNotFoundCallback: {
            $0
        }
    }

    /// Adds Bopomofo readings to the selected text.
    @objc func addReading(_ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer) {
        transformPasteboardString(
            pasteboard,
            maximumLength: kMaxLength,
            skipIfOutputIsEmpty: true
        ) { string in
            guard let converted = OpenCCBridge.shared.convertToTraditional(string) else {
                return nil
            }

            return converted.components(separatedBy: "\n").map { input in
                addReading(string: input)
            }.joined(separator: "\n")
        }
    }

    func addHanyuPinyin(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            let pinyin = delegate?.serviceProvider(self, didRequestConvertReadingToHanyuPinyin: $1) ?? ""
            return "\($0)(\(pinyin))"
        } readingNotFoundCallback: {
            $0
        }
    }

    /// Adds Hanyu Pinyin readings to the selected text.
    @objc func addHanyuPinyin(_ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer) {
        transformPasteboardString(
            pasteboard,
            maximumLength: kMaxLength,
            skipIfOutputIsEmpty: true
        ) { string in
            guard let converted = OpenCCBridge.shared.convertToTraditional(string) else {
                return nil
            }

            return converted.components(separatedBy: "\n").map { input in
                addHanyuPinyin(string: input)
            }.joined(separator: "\n")
        }
    }

    // MARK: - Convert to readings

    func convertToReadings(string: String) -> String {
        process(string: string, addSpace: false, convertEachCharacter: true) {
            $1
        } readingNotFoundCallback: {
            $0
        }
    }

    /// Converts the selected text to Bopomofo readings.
    @objc func convertToReadings(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, maximumLength: kMaxLength) { string in
            string.components(separatedBy: "\n").map { input in
                convertToReadings(string: input)
            }.joined(separator: "\n")
        }
    }

    func convertToHanyuPinyin(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            delegate?.serviceProvider(self, didRequestConvertReadingToHanyuPinyin: $1) ?? $1
        } readingNotFoundCallback: {
            $0
        }
    }

    /// Converts the selected text to Hanyu Pinyin.
    @objc func convertToHanyuPinyin(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, maximumLength: kMaxLength) { string in
            string.components(separatedBy: "\n").map { input in
                convertToHanyuPinyin(string: input)
            }.joined(separator: "\n")
        }
    }

    // MARK: - Braille

    func convertToBraille(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: false) {
            BopomofoBrailleConverter.convert(bopomofo: $1)
        } readingNotFoundCallback: {
            BopomofoBrailleConverter.convert(bopomofo: $0)
        }
    }

    /// Converts selected text to Taiwanese Braille.
    @objc func convertToBraille(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, maximumLength: kMaxLength) { string in
            string.components(separatedBy: "\n").map { input in
                convertToBraille(string: input)
            }.joined(separator: "\n")
        }
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

    /// Converts the selected Taiwanese Braille to Chinese text.
    @objc func convertBrailleToChineseText(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, skipIfOutputIsEmpty: true) { string in
            convertBrailleToChineseText(string: string)
        }
    }

    // MARK: - BPMF vs font

    func convertToBpmfAnnotatedText(string: String) -> String {
        process(string: string, addSpace: true, convertEachCharacter: true) {
            LanguageModelManager.annotateVariant(characters: $0, readings: $1)
        } readingNotFoundCallback: {
            $0
        }
    }

    /// Converts the selected text to annotated text for BPMF VS font support.
    @objc func convertToBpmfAnnotatedText(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, skipIfOutputIsEmpty: true) { string in
            convertToBpmfAnnotatedText(string: string)
        }
    }
}
