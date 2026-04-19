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

final class CustomUrlHandler {
    private let service: McBopomofoService

    init(service: McBopomofoService) {
        self.service = service
    }

    func handle(_ url: URL) {
        guard url.scheme == "mcbopomofo" else {
            return
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.host == "add_phrase",
            let fileValue = components.queryItems?.first(where: { $0.name == "file" })?.value,
            let fileURL = phraseFileURL(from: fileValue)
        else {
            return
        }

        importUserPhrases(from: fileURL)
    }

    private func phraseFileURL(from value: String) -> URL? {
        let fileURL: URL
        if value.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: value)
        } else if let url = URL(string: value), url.isFileURL {
            fileURL = url
        } else {
            return nil
        }
        let tempDir = FileManager.default.temporaryDirectory.standardizedFileURL
        let standardizedURL = fileURL.standardizedFileURL
        guard standardizedURL.path.hasPrefix(tempDir.path) else {
            return nil
        }
        return standardizedURL
    }

    private func importUserPhrases(from fileURL: URL) {
        let maxFileSize = 1024 * 1024  // 1MB limit
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let fileSize = attributes[.size] as? Int,
            fileSize <= maxFileSize
        else {
            return
        }

        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return
        }

        let names =
            content
            .components(separatedBy: .newlines)
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.hasPrefix("#")
            }
            .flatMap { line in
                line.components(separatedBy: .whitespaces)
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if names.isEmpty {
            return
        }

        let uniqueNames = Array(Set(names)).sorted()
        let added = uniqueNames.filter { service.addUserPhrase(named: $0) }

        if added.isEmpty {
            return
        }

        LanguageModelManager.loadUserPhrases(
            enableForPlainBopomofo: Preferences.enableUserPhrasesInPlainBopomofo)
        LanguageModelManager.loadUserPhraseReplacement()
    }
}
