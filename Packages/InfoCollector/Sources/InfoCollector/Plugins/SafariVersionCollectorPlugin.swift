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

struct SafariVersionCollectorPlugin: InfoCollectorPlugin {
    var name: String { "Safari version collector" }

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        // Try standard install location first
        let safariPath = "/Applications/Safari.app"
        if let bundle = Bundle(path: safariPath) ?? Bundle(url: URL(fileURLWithPath: safariPath)) {
            let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
            let build = bundle.infoDictionary?["CFBundleVersion"] as? String
            if let short, let build {
                callback(.success("- Safari \(short) (\(build))"))
                return
            } else if let short {
                callback(.success("- Safari \(short)"))
                return
            } else if let build {
                callback(.success("- Safari build \(build)"))
                return
            }
        }

        // Fallback: search common locations in case Safari is relocated
        let candidateDirs = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
        ]
        for dir in candidateDirs {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                if let safariApp = contents.first(where: {
                    $0.caseInsensitiveCompare("Safari.app") == .orderedSame
                }) {
                    let full = (dir as NSString).appendingPathComponent(safariApp)
                    if let bundle = Bundle(path: full) ?? Bundle(url: URL(fileURLWithPath: full)) {
                        let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
                        let build = bundle.infoDictionary?["CFBundleVersion"] as? String
                        if let short, let build {
                            callback(.success("- Safari \(short) (\(build))"))
                            return
                        } else if let short {
                            callback(.success("- Safari \(short)"))
                            return
                        } else if let build {
                            callback(.success("- Safari build \(build)"))
                            return
                        }
                    }
                }
            }
        }

        // If we reach here, we couldn't determine the version
        struct SafariNotFoundError: LocalizedError {
            var errorDescription: String? { "Safari.app not found or no version info available" }
        }
        callback(.failure(SafariNotFoundError()))
    }
}
