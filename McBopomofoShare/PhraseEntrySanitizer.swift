import Foundation

final class PhraseEntrySanitizer {
    func sanitize(_ entries: [String]) -> PhraseEntrySanitizationResult {
        var sanitized: [String] = []
        var errors: [ShareInputError] = []

        for entry in entries {
            let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }

            guard containsOnlyChineseCharacters(trimmed) else {
                errors.append(.containsNonChineseCharacters(trimmed))
                continue
            }

            sanitized.append(trimmed)
        }

        return PhraseEntrySanitizationResult(
            entries: Array(Set(sanitized)).sorted(),
            errors: errors.uniqued()
        )
    }

    private func containsOnlyChineseCharacters(_ text: String) -> Bool {
        !text.isEmpty && text.unicodeScalars.allSatisfy { scalar in
            // Match common CJK Unified Ideographs blocks directly because CharacterSet does not offer a precise built-in "Chinese-only" test here.
            switch scalar.value {
            case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF, 0x20000...0x2A6DF,
                 0x2A700...0x2B73F, 0x2B740...0x2B81F, 0x2B820...0x2CEAF, 0x2CEB0...0x2EBEF,
                 0x30000...0x3134F:
                return true
            default:
                return false
            }
        }
    }
}
