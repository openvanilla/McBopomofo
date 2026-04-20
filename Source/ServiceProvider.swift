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
/// ``McBopomofoServiceDelegate``.
class ServiceProvider: NSObject {
    private let service: McBopomofoService

    init(service: McBopomofoService) {
        self.service = service
        super.init()
    }

    func extractReading(from firstWord: String) -> String {
        service.extractReading(from: firstWord)
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

        if !service.addUserPhrase(named: firstWord) {
            return
        }
        (NSApp.delegate as? AppDelegate)?.openUserPhrases(self)
    }
}

private let kMaxLength = 3000

extension ServiceProvider {
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

    // MARK: - Add readings

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
                service.addReading(string: input)
            }.joined(separator: "\n")
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
                service.addHanyuPinyin(string: input)
            }.joined(separator: "\n")
        }
    }

    // MARK: - Convert to readings

    /// Converts the selected text to Bopomofo readings.
    @objc func convertToReadings(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, maximumLength: kMaxLength) { string in
            string.components(separatedBy: "\n").map { input in
                service.convertToReadings(string: input)
            }.joined(separator: "\n")
        }
    }

    /// Converts the selected text to Hanyu Pinyin.
    @objc func convertToHanyuPinyin(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, maximumLength: kMaxLength) { string in
            string.components(separatedBy: "\n").map { input in
                service.convertToHanyuPinyin(string: input)
            }.joined(separator: "\n")
        }
    }

    // MARK: - Braille

    /// Converts selected text to Unicode Taiwanese Braille.
    @objc func convertToUnicodeBraille(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, maximumLength: kMaxLength) { string in
            string.components(separatedBy: "\n").map { input in
                service.convertToUnicodeBraille(string: input)
            }.joined(separator: "\n")
        }
    }

    /// Converts selected text to ASCII Taiwanese Braille.
    @objc func convertToASCIIBraille(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, maximumLength: kMaxLength) { string in
            string.components(separatedBy: "\n").map { input in
                service.convertToASCIIBraille(string: input)
            }.joined(separator: "\n")
        }
    }

    /// Converts the selected Unicode Taiwanese Braille to Chinese text.
    @objc func convertUnicodeBrailleToChineseText(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, skipIfOutputIsEmpty: true) { string in
            service.convertUnicodeBrailleToChineseText(string: string)
        }
    }

    /// Converts the selected ASCII Taiwanese Braille to Chinese text.
    @objc func convertASCIIBrailleToChineseText(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, skipIfOutputIsEmpty: true) { string in
            service.convertASCIIBrailleToChineseText(string: string)
        }
    }

    // MARK: - BPMF vs font

    /// Converts the selected text to annotated text for BPMF VS font support.
    @objc func convertToBpmfAnnotatedText(
        _ pasteboard: NSPasteboard, userData _: String?, error _: NSErrorPointer
    ) {
        transformPasteboardString(pasteboard, skipIfOutputIsEmpty: true) { string in
            service.convertToBpmfAnnotatedText(string: string)
        }
    }
}
