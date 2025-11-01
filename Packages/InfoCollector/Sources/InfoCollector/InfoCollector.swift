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

@objc
public class InfoCollector: NSObject {
    @MainActor
    @available(iOS 13.0.0, macOS 10.15, *)
    public static func generate() async -> String {
        await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
            InfoCollector.generate { string in
                continuation.resume(returning: string)
            }
        }
    }

    @MainActor
    public static func generate(callback: @escaping (String) -> Void) {
        let plugins: [InfoCollectorPlugin] = [
            MachineModelCollectorPlugin(),
            MacVersionCollectorPlugin(),
            SystemLanguageSettingsCollectorPlugin(),
            KeyboardTypeCollectorPlugin(),
            ActiveInputSourceListCollectorPlugin(),
            DefaultWebBrowserCollectorPlugin(),
            SafaruVersionCollectorPlugin(),
            AppVersionCollectorPlugin(),
        ]

        let group = DispatchGroup()
        var string = ""
        let lock = NSLock()

        for plugin in plugins {
            group.enter()
            plugin.collect { result in
                if case .success(let info) = result {
                    lock.lock()
                    string.append(info + "\n")
                    lock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            callback(string)
        }
    }
}
