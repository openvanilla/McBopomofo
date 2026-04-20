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

import Cocoa
import CoreServices

class ShareViewController: NSViewController {
    private let inputPlugins: [any ShareInputPlugin] = [
        ContactShareInputPlugin(),
        PlainTextShareInputPlugin(),
    ]
    private var phraseEntries: [String] = []

    private let phraseEntriesTextView = NSTextView(frame: .zero)
    private let scrollView = NSScrollView()
    @IBOutlet var sendButton: NSButton!
    @IBOutlet var cancelButton: NSButton!
    @IBOutlet var shareTitle: NSTextField!

    override var nibName: NSNib.Name? {
        return NSNib.Name("ShareViewController")
    }

    override func loadView() {
        super.loadView()
        configurePhraseEntriesView()
        loadPhraseEntries()
        cancelButton.title = NSLocalizedString("Cancel", comment: "")
        sendButton.title = NSLocalizedString("Add", comment: "")
        shareTitle.stringValue = NSLocalizedString("Add User Phrases", comment: "")
        sendButton.isEnabled = false
    }

    private func configurePhraseEntriesView() {
        phraseEntriesTextView.isEditable = false
        phraseEntriesTextView.isSelectable = true
        phraseEntriesTextView.drawsBackground = false
        phraseEntriesTextView.isHorizontallyResizable = false
        phraseEntriesTextView.isVerticallyResizable = true
        phraseEntriesTextView.autoresizingMask = [.width]
        phraseEntriesTextView.string = NSLocalizedString("share.loadingContent", comment: "")
        phraseEntriesTextView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        phraseEntriesTextView.textContainerInset = NSSize(width: 0, height: 8)
        phraseEntriesTextView.textContainer?.widthTracksTextView = true
        phraseEntriesTextView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = phraseEntriesTextView

        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -44),
        ])
    }

    private func loadPhraseEntries() {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            phraseEntriesTextView.string = NSLocalizedString("share.noInputItems", comment: "")
            return
        }

        let providers = providers(from: inputItems)

        if providers.isEmpty {
            phraseEntriesTextView.string = NSLocalizedString("share.noSupportedContent", comment: "")
            return
        }

        guard let selectedMatch = inputPlugins.lazy
            .map({ plugin in (plugin: plugin, providers: plugin.matchingProviders(in: providers)) })
            .first(where: { !$0.providers.isEmpty })
        else {
            phraseEntriesTextView.string = NSLocalizedString("share.noSupportedContent", comment: "")
            return
        }

        selectedMatch.plugin.loadPhraseEntries(from: selectedMatch.providers) { result in
            switch result {
            case let .success(entries):
                let uniqueEntries = Array(Set(entries)).sorted()
                self.phraseEntries = uniqueEntries
                self.sendButton.isEnabled = !uniqueEntries.isEmpty
                self.phraseEntriesTextView.string = uniqueEntries.joined(separator: "\n")
            case let .failure(error):
                self.phraseEntries = []
                self.sendButton.isEnabled = false
                self.phraseEntriesTextView.string = error.localizedDescription
            }
        }
    }

    private func providers(from inputItems: [NSExtensionItem]) -> [NSItemProvider] {
        let attachmentProviders = inputItems
            .compactMap(\.attachments)
            .flatMap { $0 }

        if !attachmentProviders.isEmpty {
            return attachmentProviders
        }

        let attributedTexts = inputItems
            .compactMap(\.attributedContentText?.string)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !attributedTexts.isEmpty else {
            return []
        }

        let merged = attributedTexts.joined(separator: "\n")
        return [NSItemProvider(object: merged as NSString)]
    }

    private func writePhraseEntriesToTemporaryFile(_ entries: [String]) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "McBopomofoShare",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileURL = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("txt")
        let content = entries.joined(separator: "\n")
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func customURL(for fileURL: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "mcbopomofo"
        components.host = "add_phrase"
        components.queryItems = [
            URLQueryItem(name: "file", value: fileURL.path),
        ]
        return components.url
    }

    private func completeSharingRequest() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @IBAction func send(_ sender: AnyObject?) {
        let entries = Array(Set(phraseEntries)).sorted()
        guard !entries.isEmpty else {
            phraseEntriesTextView.string = NSLocalizedString("share.noDisplayablePhraseEntries", comment: "")
            return
        }

        sendButton.isEnabled = false
        cancelButton.isEnabled = false

        do {
            let fileURL = try writePhraseEntriesToTemporaryFile(entries)
            guard let customURL = customURL(for: fileURL) else {
                phraseEntriesTextView.string = NSLocalizedString("share.failedToCreateUrl", comment: "")
                sendButton.isEnabled = true
                cancelButton.isEnabled = true
                return
            }

            if NSWorkspace.shared.open(customURL) {
                completeSharingRequest()
            } else {
                phraseEntriesTextView.string = NSLocalizedString("share.failedToOpenApp", comment: "")
                sendButton.isEnabled = true
                cancelButton.isEnabled = true
            }
        } catch {
            phraseEntriesTextView.string = NSLocalizedString("share.failedToWriteTempFile", comment: "")
            sendButton.isEnabled = true
            cancelButton.isEnabled = true
        }
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }

}
