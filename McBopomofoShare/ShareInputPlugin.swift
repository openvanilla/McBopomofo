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

protocol ShareInputPlugin {
    func matchingProviders(in providers: [NSItemProvider]) -> [NSItemProvider]
    func loadPhraseEntries(from providers: [NSItemProvider], completion: @escaping (Result<[String], any Error>) -> Void)
}

enum ShareInputError: Hashable, LocalizedError {
    case failedToLoadSharedText
    case failedToDecodeSharedText
    case failedToLoadContact
    case failedToParseContact
    case phraseTooLong(String, maxLength: Int)
    case containsNonChineseCharacters(String)
    case noDisplayablePhraseEntries

    var errorDescription: String? {
        switch self {
        case .failedToLoadSharedText:
            return NSLocalizedString("share.error.failedToLoadSharedText", comment: "")
        case .failedToDecodeSharedText:
            return NSLocalizedString("share.error.failedToDecodeSharedText", comment: "")
        case .failedToLoadContact:
            return NSLocalizedString("share.error.failedToLoadContact", comment: "")
        case .failedToParseContact:
            return NSLocalizedString("share.error.failedToParseContact", comment: "")
        case let .phraseTooLong(phrase, maxLength):
            return String(
                format: NSLocalizedString("share.error.phraseTooLong", comment: ""),
                locale: Locale.current,
                phrase,
                maxLength
            )
        case let .containsNonChineseCharacters(phrase):
            return String(
                format: NSLocalizedString("share.error.containsNonChineseCharacters", comment: ""),
                locale: Locale.current,
                phrase
            )
        case .noDisplayablePhraseEntries:
            return NSLocalizedString("share.error.noDisplayablePhraseEntries", comment: "")
        }
    }
}

struct ShareInputErrorGroup: LocalizedError {
    let errors: [ShareInputError]

    var errorDescription: String? {
        let descriptions = errors.compactMap(\.errorDescription)
        guard !descriptions.isEmpty else {
            return nil
        }
        guard descriptions.count > 1 else {
            return descriptions[0]
        }

        let header = NSLocalizedString("share.error.multipleErrorsHeader", comment: "")
        let details = descriptions.map { "• \($0)" }.joined(separator: "\n")
        return "\(header)\n\(details)"
    }
}

struct PhraseEntrySanitizationResult {
    let entries: [String]
    let errors: [ShareInputError]
}

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
