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

class ServiceProvider: NSObject {
    @objc func addUserPhrase(_ pasteboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let string = pasteboard.string(forType: .string),
              let firstWord = string.components(separatedBy: .whitespacesAndNewlines).first
        else {
            return
        }
        
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
                if let match = LanguageModelManager.reading(for: candidate) {
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
        LanguageModelManager.writeUserPhrase("\(firstWord) \(reading)")
        (NSApp.delegate as? AppDelegate)?.openUserPhrases(self)
    }
}
