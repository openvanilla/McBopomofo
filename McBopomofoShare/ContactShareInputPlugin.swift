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

import Contacts
import Foundation
import UniformTypeIdentifiers

final class ContactPhraseEntryExtractor {
    private let sanitizer = PhraseEntrySanitizer()

    func phraseEntries(from contacts: [CNContact]) -> PhraseEntrySanitizationResult {
        let names = contacts
            .compactMap(displayName(for:))
            .map(normalizedName(from:))

        return sanitizer.sanitize(names)
    }

    private func displayName(for contact: CNContact) -> String? {
        let formatter = CNContactFormatter()
        formatter.style = .fullName
        if let name = formatter.string(from: contact), !name.isEmpty {
            return name
        }

        if !contact.organizationName.isEmpty {
            return contact.organizationName
        }

        return nil
    }

    private func normalizedName(from name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


final class ContactShareInputPlugin: ShareInputPlugin {
    private let extractor = ContactPhraseEntryExtractor()

    func matchingProviders(in providers: [NSItemProvider]) -> [NSItemProvider] {
        let vCardType = UTType.vCard.identifier
        return providers.filter { $0.hasItemConformingToTypeIdentifier(vCardType) }
    }

    func loadPhraseEntries(from providers: [NSItemProvider], completion: @escaping (Result<[String], any Error>) -> Void) {
        let group = DispatchGroup()
        let lock = NSLock()
        var allContacts: [CNContact] = []
        var allErrors: [ShareInputError] = []
        let vCardType = UTType.vCard.identifier

        for provider in providers {
            group.enter()
            provider.loadDataRepresentation(forTypeIdentifier: vCardType) { data, error in
                defer { group.leave() }

                if let error {
                    NSLog("Failed to load vCard: %@", error.localizedDescription)
                    lock.lock()
                    allErrors.append(.failedToLoadContact)
                    lock.unlock()
                    return
                }

                guard let data else {
                    lock.lock()
                    allErrors.append(.failedToLoadContact)
                    lock.unlock()
                    return
                }

                do {
                    let contacts = try CNContactVCardSerialization.contacts(with: data)
                    lock.lock()
                    allContacts.append(contentsOf: contacts)
                    lock.unlock()
                } catch {
                    NSLog("Failed to parse vCard: %@", error.localizedDescription)
                    lock.lock()
                    allErrors.append(.failedToParseContact)
                    lock.unlock()
                }
            }
        }

        group.notify(queue: .main) {
            let sanitization = self.extractor.phraseEntries(from: allContacts)
            let uniqueErrors = (allErrors + sanitization.errors).uniqued()
            if !uniqueErrors.isEmpty {
                completion(.failure(ShareInputErrorGroup(errors: uniqueErrors)))
                return
            }

            guard !sanitization.entries.isEmpty else {
                completion(.failure(ShareInputError.noDisplayablePhraseEntries))
                return
            }

            completion(.success(sanitization.entries))
        }
    }
}
