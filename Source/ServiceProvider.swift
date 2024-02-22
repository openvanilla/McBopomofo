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
import BopomofoBraille

@objc protocol ServiceProviderDelegate: NSObjectProtocol {
    @objc(serviceProvider:didRequestInsertReading:)
    func serviceProvider(_ provider:ServiceProvider, didRequestInsertReading: String)
    @objc(serviceProviderDidRequestCommitting:)
    func serviceProvider(didRequestCommitting provider:ServiceProvider) -> String
}

class ServiceProvider: NSObject {
    weak var delegate: ServiceProviderDelegate?

    func extractReading(from firstWord:String) -> String {
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
                if let converted = OpenCCBridge.shared.convertTraditional(candidate),
                    let match = LanguageModelManager.reading(for: converted) {
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

    @objc func addReading(_ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let string = pasteboard.string(forType: .string)
        else {
            return
        }
        var output = ""
        for c in string {
            output += String(c)
            if let converted = OpenCCBridge.shared.convertTraditional(String(c)),
               let reading = LanguageModelManager.reading(for:converted) {
                if reading.isEmpty == false && reading.starts(with: "_") == false {
                    output += "(\(reading))"
                }
            }
        }
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

    @objc func convertToReadings(_ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let string = pasteboard.string(forType: .string)
        else {
            return
        }
        var output = ""
        for c in string {

            if let converted = OpenCCBridge.shared.convertTraditional(String(c)),
               let reading = LanguageModelManager.reading(for:converted) {
                if reading.isEmpty == false && reading.starts(with: "_") == false {
                    output += reading
                } else {
                    output += String(c)
                }
            } else {
                output += String(c)
            }
        }
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

    @objc func convertToBraille(_ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let string = pasteboard.string(forType: .string)
        else {
            return
        }
        var output = ""
        for c in string {

            if let converted = OpenCCBridge.shared.convertTraditional(String(c)),
               let reading = LanguageModelManager.reading(for:converted) {
                if reading.isEmpty == false && reading.starts(with: "_") == false {
                    output += BopomofoBrailleConverter.convert(bopomofo: reading)
                } else {
                    output += BopomofoBrailleConverter.convert(bopomofo: String(c))
                }
            } else {
                output += BopomofoBrailleConverter.convert(bopomofo: String(c))
            }
        }
        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

    @objc func convertBrailleToChineseText(_ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let string = pasteboard.string(forType: .string)
        else {
            return
        }
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

        pasteboard.clearContents()
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.writeObjects([output as NSString])
    }

}
