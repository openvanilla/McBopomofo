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

struct ArchiveUtil {
    var appName: String
    var targetAppBundleName: String

    init(appName: String, targetAppBundleName: String) {
        self.appName = appName
        self.targetAppBundleName = targetAppBundleName
    }

    // Returns YES if (1) a zip file under
    // Resources/NotarizedArchives/$_appName-$bundleVersion.zip exists, and (2) if
    // Resources/$_invalidAppBundleName does not exist.
    func validateIfNotarizedArchiveExists() -> Bool {
        guard let resourePath = Bundle.main.resourcePath,
              let notarizedArchivesPath = notarizedArchivesPath,
              let notarizedArchive = notarizedArchive,
              let notarizedArchivesContent: [String] = try? FileManager.default.subpathsOfDirectory(atPath: notarizedArchivesPath)
            else {
            return false
        }

        let devModeAppBundlePath = (resourePath as NSString).appendingPathComponent(targetAppBundleName)
        let count = notarizedArchivesContent.count
        let notarizedArchiveExists = FileManager.default.fileExists(atPath: notarizedArchive)
        let devModeAppBundleExists = FileManager.default.fileExists(atPath: devModeAppBundlePath)

        if count > 0 {
            if count != 1 || !notarizedArchiveExists || devModeAppBundleExists {
                let alert = NSAlert()
                alert.alertStyle = .informational
                alert.messageText = "Internal Error"
                alert.informativeText = "devMode installer, expected archive name: \(notarizedArchive), " +
                    "archive exists: \(notarizedArchiveExists), devMode app bundle exists: \(devModeAppBundleExists)"
                alert.addButton(withTitle: "Terminate")
                alert.runModal()
                NSApp.terminate(nil)
            } else {
                return true
            }
        }

        if !devModeAppBundleExists {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Internal Error"
            alert.informativeText = "Dev target bundle does not exist: \(devModeAppBundlePath)"
            alert.addButton(withTitle: "Terminate")
            alert.runModal()
            NSApp.terminate(nil)
        }

        return false
    }

    func unzipNotarizedArchive() -> String? {
        if !self.validateIfNotarizedArchiveExists() {
            return nil
        }
        guard let notarizedArchive = notarizedArchive,
            let resourcePath = Bundle.main.resourcePath else {
            return nil
        }
        let tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
        let arguments: [String] = [notarizedArchive, "-d", tempFilePath]
        let unzipTask = Process()
        unzipTask.launchPath = "/usr/bin/unzip"
        unzipTask.currentDirectoryPath = resourcePath
        unzipTask.arguments = arguments
        unzipTask.launch()
        unzipTask.waitUntilExit()

        assert(unzipTask.terminationStatus == 0, "Must successfully unzipped")
        guard let result = (tempFilePath as NSString).appendingPathExtension(targetAppBundleName) else {
            return nil
        }
        assert(FileManager.default.fileExists(atPath: result), "App bundle must be unzipped at \(resourcePath).")
        return result
    }

    private var notarizedArchivesPath: String? {
        let resourePath = Bundle.main.resourcePath
        let notarizedArchivesPath = resourePath?.appending("NotarizedArchives")
        return notarizedArchivesPath
    }

    private var notarizedArchive: String? {
        guard let notarizedArchivesPath = notarizedArchivesPath,
            let bundleVersion = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String else {
            return nil
        }
        let notarizedArchiveBasename = "\(appName)-r\(bundleVersion).zip"
        let notarizedArchive = notarizedArchivesPath.appending(notarizedArchiveBasename)
        return notarizedArchive
    }

}
