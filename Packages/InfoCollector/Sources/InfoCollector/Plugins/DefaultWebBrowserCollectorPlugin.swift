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

struct DefaultWebBrowserCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Default web browser collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        // Prefer https; fall back to http if needed
        if let appURL = LSCopyDefaultApplicationURLForURL(
            URL(string: "https://apple.com")! as CFURL, .all, nil)?.takeRetainedValue() as URL?
        {
            let bundle = Bundle(url: appURL)
            let displayName =
                bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle?.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
                ?? (appURL.deletingPathExtension().lastPathComponent)
            let bundleID = bundle?.bundleIdentifier ?? "unknown.bundle.id"
            callback(.success("- Default Browser: \(displayName) (\(bundleID))"))
            return
        }

        // Fallback to Launch Services by role handler for http if the URL lookup fails
        if let handlerCF = LSCopyDefaultHandlerForURLScheme("http" as CFString) {
            let handler = handlerCF.takeRetainedValue() as String
            let path = NSWorkspace.shared.urlForApplication(withBundleIdentifier: handler)
            let displayName = path?.deletingPathExtension().lastPathComponent ?? handler
            callback(.success("- Default Browser: \(displayName) (\(handler))"))
            return
        }

        struct NoDefaultBrowserError: LocalizedError {
            var errorDescription: String? { "No default browser configured" }
        }
        callback(.failure(NoDefaultBrowserError()))
    }
}
