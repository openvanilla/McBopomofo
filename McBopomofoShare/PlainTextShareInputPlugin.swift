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
import UniformTypeIdentifiers

struct PhraseEntryExtractionResult {
    let entries: [String]
    let errors: [ShareInputError]
}

final class PlainTextPhraseEntryExtractor {
    private let sanitizer = PhraseEntrySanitizer()
    private let maxPhraseLength = 8

    func phraseEntries(from text: String) -> PhraseEntryExtractionResult {
        let segments = text
            .components(separatedBy: sentenceSeparators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var accepted: [String] = []
        var errors: [ShareInputError] = []

        for segment in segments {
            guard segment.count <= maxPhraseLength else {
                errors.append(.phraseTooLong(segment, maxLength: maxPhraseLength))
                continue
            }
            accepted.append(segment)
        }

        let sanitization = sanitizer.sanitize(accepted)
        return PhraseEntryExtractionResult(
            entries: sanitization.entries,
            errors: (errors + sanitization.errors).uniqued()
        )
    }

    private var sentenceSeparators: CharacterSet {
        var set = CharacterSet.newlines
        set.formUnion(.punctuationCharacters)
        return set
    }
}

final class PlainTextShareInputPlugin: ShareInputPlugin {
    private let extractor = PlainTextPhraseEntryExtractor()

    func matchingProviders(in providers: [NSItemProvider]) -> [NSItemProvider] {
        providers.filter {
            $0.canLoadObject(ofClass: NSString.self) || preferredTextTypeIdentifier(for: $0) != nil
        }
    }

    func loadPhraseEntries(from providers: [NSItemProvider], completion: @escaping (Result<[String], any Error>) -> Void) {
        let group = DispatchGroup()
        let lock = NSLock()
        var allEntries: [String] = []
        var allErrors: [ShareInputError] = []

        for provider in providers {
            group.enter()
            if provider.canLoadObject(ofClass: NSString.self) {
                provider.loadObject(ofClass: NSString.self) { object, error in
                    defer { group.leave() }

                    if let error {
                        NSLog("Failed to load text object: %@", error.localizedDescription)
                        lock.lock()
                        allErrors.append(.failedToLoadSharedText)
                        lock.unlock()
                        return
                    }

                    guard let text = object as? String else {
                        lock.lock()
                        allErrors.append(.failedToDecodeSharedText)
                        lock.unlock()
                        return
                    }

                    let result = self.extractor.phraseEntries(from: text)
                    lock.lock()
                    allEntries.append(contentsOf: result.entries)
                    allErrors.append(contentsOf: result.errors)
                    lock.unlock()
                }
                continue
            }

            guard let typeIdentifier = preferredTextTypeIdentifier(for: provider) else {
                group.leave()
                continue
            }

            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                defer { group.leave() }

                if let error {
                    NSLog("Failed to load text data: %@", error.localizedDescription)
                    lock.lock()
                    allErrors.append(.failedToLoadSharedText)
                    lock.unlock()
                    return
                }

                guard let data,
                      let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode)
                else {
                    lock.lock()
                    allErrors.append(.failedToDecodeSharedText)
                    lock.unlock()
                    return
                }

                let result = self.extractor.phraseEntries(from: text)
                lock.lock()
                allEntries.append(contentsOf: result.entries)
                allErrors.append(contentsOf: result.errors)
                lock.unlock()
            }
        }

        group.notify(queue: .main) {
            let uniqueErrors = allErrors.uniqued()
            if !uniqueErrors.isEmpty {
                completion(.failure(ShareInputErrorGroup(errors: uniqueErrors)))
                return
            }

            let uniqueEntries = Array(Set(allEntries)).sorted()
            guard !uniqueEntries.isEmpty else {
                completion(.failure(ShareInputError.noDisplayablePhraseEntries))
                return
            }

            completion(.success(uniqueEntries))
        }
    }

    private func preferredTextTypeIdentifier(for provider: NSItemProvider) -> String? {
        let preferredTypes = [
            UTType.utf8PlainText.identifier,
            UTType.plainText.identifier,
            UTType.text.identifier,
            "public.utf16-external-plain-text",
            "public.utf16-plain-text",
            "public.rtf",
        ]

        return preferredTypes.first { provider.hasItemConformingToTypeIdentifier($0) }
    }
}
