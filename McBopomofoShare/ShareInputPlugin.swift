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
