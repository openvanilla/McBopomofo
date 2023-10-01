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
import InputMethodKit
import FSEventStreamHelper

private let kCheckUpdateAutomatically = "CheckUpdateAutomatically"
private let kNextUpdateCheckDateKey = "NextUpdateCheckDate"
private let kUpdateInfoEndpointKey = "UpdateInfoEndpoint"
private let kUpdateInfoSiteKey = "UpdateInfoSite"
private let kNextCheckInterval: TimeInterval = 86400.0
private let kTimeoutInterval: TimeInterval = 60.0

struct VersionUpdateReport {
    var siteUrl: URL?
    var currentShortVersion: String = ""
    var currentVersion: String = ""
    var remoteShortVersion: String = ""
    var remoteVersion: String = ""
    var versionDescription: String = ""
}

enum VersionUpdateApiResult {
    case shouldUpdate(report: VersionUpdateReport)
    case noNeedToUpdate
    case ignored
}

enum VersionUpdateApiError: Error, LocalizedError {
    case connectionError(message: String)

    var errorDescription: String? {
        switch self {
        case .connectionError(let message):
            return String(format: NSLocalizedString("There may be no internet connection or the server failed to respond.\n\nError message: %@", comment: ""), message)
        }
    }
}

struct VersionUpdateApi {
    static func check(forced: Bool, callback: @escaping (Result<VersionUpdateApiResult, Error>) -> ()) -> URLSessionTask? {
        guard let infoDict = Bundle.main.infoDictionary,
              let updateInfoURLString = infoDict[kUpdateInfoEndpointKey] as? String,
              let updateInfoURL = URL(string:(updateInfoURLString + (forced ? "?manual=yes" : ""))) else {
            return nil
        }

        let request = URLRequest(url: updateInfoURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kTimeoutInterval)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    forced ?
                            callback(.failure(VersionUpdateApiError.connectionError(message: error.localizedDescription))) :
                            callback(.success(.ignored))
                }
                return
            }

            do {
                guard let plist = try PropertyListSerialization.propertyList(from: data ?? Data(), options: [], format: nil) as? [AnyHashable: Any],
                      let remoteVersion = plist[kCFBundleVersionKey] as? String,
                      let infoDict = Bundle.main.infoDictionary
                        else {
                    DispatchQueue.main.async {
                        forced ? callback(.success(.noNeedToUpdate)) : callback(.success(.ignored))
                    }
                    return
                }

                // TODO: Validate info (e.g. bundle identifier)
                // TODO: Use HTML to display change log, need a new key like UpdateInfoChangeLogURL for this

                let currentVersion = infoDict[kCFBundleVersionKey as String] as? String ?? ""
                let result = currentVersion.compare(remoteVersion, options: .numeric, range: nil, locale: nil)

                if result != .orderedAscending {
                    DispatchQueue.main.async {
                        forced ? callback(.success(.noNeedToUpdate)) : callback(.success(.ignored))
                    }
                    return
                }

                guard let siteInfoURLString = plist[kUpdateInfoSiteKey] as? String,
                      let siteInfoURL = URL(string: siteInfoURLString)
                        else {
                    DispatchQueue.main.async {
                        forced ? callback(.success(.noNeedToUpdate)) : callback(.success(.ignored))
                    }
                    return
                }

                var report = VersionUpdateReport(siteUrl: siteInfoURL)
                var versionDescription = ""
                let versionDescriptions = plist["Description"] as? [AnyHashable: Any]
                if let versionDescriptions = versionDescriptions {
                    var locale = "en"
                    let supportedLocales = ["en", "zh-Hant", "zh-Hans"]
                    let preferredTags = Bundle.preferredLocalizations(from: supportedLocales)
                    if let first = preferredTags.first {
                        locale = first
                    }
                    versionDescription = versionDescriptions[locale] as? String ?? versionDescriptions["en"] as? String ?? ""
                    if !versionDescription.isEmpty {
                        versionDescription = "\n\n" + versionDescription
                    }
                }
                report.currentShortVersion = infoDict["CFBundleShortVersionString"] as? String ?? ""
                report.currentVersion = currentVersion
                report.remoteShortVersion = plist["CFBundleShortVersionString"] as? String ?? ""
                report.remoteVersion = remoteVersion
                report.versionDescription = versionDescription
                DispatchQueue.main.async {
                    callback(.success(.shouldUpdate(report: report)))
                }
            } catch {
                DispatchQueue.main.async {
                    forced ? callback(.success(.noNeedToUpdate)) : callback(.success(.ignored))
                }
            }
        }
        task.resume()
        return task
    }
}

@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, NonModalAlertWindowControllerDelegate {

    @IBOutlet weak var window: NSWindow?
    private var preferencesWindowController: PreferencesWindowController?
    private var checkTask: URLSessionTask?
    private var updateNextStepURL: URL?
    private var fsStreamHelper: FSEventStreamHelper?

    func updateUserPhrases() {
        NSLog("updateUserPhrases called \(LanguageModelManager.dataFolderPath)")
        LanguageModelManager.loadUserPhrases()
        LanguageModelManager.loadUserPhraseReplacement()

        fsStreamHelper?.delegate = nil
        fsStreamHelper?.stop()
        fsStreamHelper = FSEventStreamHelper(path: LanguageModelManager.dataFolderPath, queue: DispatchQueue(label: "User Phrases"))
        fsStreamHelper?.delegate = self
        _ = fsStreamHelper?.start()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        LanguageModelManager.setupDataModelValueConverter()
        updateUserPhrases()

        if UserDefaults.standard.object(forKey: kCheckUpdateAutomatically) == nil {
            UserDefaults.standard.set(true, forKey: kCheckUpdateAutomatically)
            UserDefaults.standard.synchronize()
        }

        NotificationCenter.default.addObserver(forName: .userPhraseLocationDidChange, object: nil, queue: OperationQueue.main) { notification in
            self.updateUserPhrases()
        }

        NSApp.servicesProvider = ServiceProvider()

        checkForUpdate()
    }

    @objc func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(windowNibName: "preferences")
        }
        preferencesWindowController?.window?.center()
        preferencesWindowController?.window?.orderFront(self)
    }

    @objc(checkForUpdate)
    func checkForUpdate() {
        checkForUpdate(forced: false)
    }

    @objc(checkForUpdateForced:)
    func checkForUpdate(forced: Bool) {
        if checkTask != nil {
            // busy
            return
        }

        // time for update?
        if !forced {
            if UserDefaults.standard.bool(forKey: kCheckUpdateAutomatically) == false {
                return
            }
            let now = Date()
            let date = UserDefaults.standard.object(forKey: kNextUpdateCheckDateKey) as? Date ?? now
            if now.compare(date) == .orderedAscending {
                return
            }
        }

        let nextUpdateDate = Date(timeInterval: kNextCheckInterval, since: Date())
        UserDefaults.standard.set(nextUpdateDate, forKey: kNextUpdateCheckDateKey)

        checkTask = VersionUpdateApi.check(forced: forced) { result in
            defer {
                self.checkTask = nil
            }
            switch result {
            case .success(let apiResult):
                switch apiResult {
                case .shouldUpdate(let report):
                    self.updateNextStepURL = report.siteUrl
                    let content = String(format: NSLocalizedString("You're currently using McBopomofo %@ (%@), a new version %@ (%@) is now available. Do you want to visit McBopomofo's website to download the version?%@", comment: ""),
                            report.currentShortVersion,
                            report.currentVersion,
                            report.remoteShortVersion,
                            report.remoteVersion,
                            report.versionDescription)
                    NonModalAlertWindowController.shared.show(title: NSLocalizedString("New Version Available", comment: ""), content: content, confirmButtonTitle: NSLocalizedString("Visit Website", comment: ""), cancelButtonTitle: NSLocalizedString("Not Now", comment: ""), cancelAsDefault: false, delegate: self)
                case .noNeedToUpdate:
                    NonModalAlertWindowController.shared.show(title:NSLocalizedString("Check for Update Completed", comment: ""), content:NSLocalizedString("McBopomofo is up to date.", comment: ""),  confirmButtonTitle:NSLocalizedString("OK", comment: ""), cancelButtonTitle:nil, cancelAsDefault: false, delegate: self)
                case .ignored:
                    break
                }
            case .failure(let error):
                switch error {
                case VersionUpdateApiError.connectionError(let message):
                    let title = NSLocalizedString("Update Check Failed", comment: "")
                    let content = String(format: NSLocalizedString("There may be no internet connection or the server failed to respond.\n\nError message: %@", comment: ""), message)
                    let buttonTitle = NSLocalizedString("Dismiss", comment: "")
                    NonModalAlertWindowController.shared.show(title: title, content: content, confirmButtonTitle: buttonTitle, cancelButtonTitle: nil, cancelAsDefault: false, delegate: nil)
                default:
                    break
                }
            }
        }
    }

    func nonModalAlertWindowControllerDidConfirm(_ controller: NonModalAlertWindowController) {
        if let updateNextStepURL = updateNextStepURL {
            NSWorkspace.shared.open(updateNextStepURL)
        }
        updateNextStepURL = nil
    }

    func nonModalAlertWindowControllerDidCancel(_ controller: NonModalAlertWindowController) {
        updateNextStepURL = nil
    }
}

extension AppDelegate: FSEventStreamHelperDelegate {
    func helper(_ helper: FSEventStreamHelper, didReceive events: [FSEventStreamHelper.Event]) {
        DispatchQueue.main.async {
            LanguageModelManager.loadUserPhrases()
            LanguageModelManager.loadUserPhraseReplacement()
        }
    }
}

extension AppDelegate {
    private func open(userFileAt path: String) {
        func checkIfUserFilesExist() -> Bool {
            if !LanguageModelManager.checkIfUserLanguageModelFilesExist() {
                let content = String(format: NSLocalizedString("Please check the permission of the path at \"%@\".", comment: ""), LanguageModelManager.dataFolderPath)
                NonModalAlertWindowController.shared.show(title: NSLocalizedString("Unable to create the user phrase file.", comment: ""), content: content, confirmButtonTitle: NSLocalizedString("OK", comment: ""), cancelButtonTitle: nil, cancelAsDefault: false, delegate: nil)
                return false
            }
            return true
        }

        if !checkIfUserFilesExist() {
            return
        }
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }

    @objc func openUserPhrases(_ sender: Any?) {
        open(userFileAt: LanguageModelManager.userPhrasesDataPathMcBopomofo)
    }

    @objc func openExcludedPhrasesPlainBopomofo(_ sender: Any?) {
        open(userFileAt: LanguageModelManager.excludedPhrasesDataPathPlainBopomofo)
    }

    @objc func openExcludedPhrasesMcBopomofo(_ sender: Any?) {
        open(userFileAt: LanguageModelManager.excludedPhrasesDataPathMcBopomofo)
    }

    @objc func openPhraseReplacementMcBopomofo(_ sender: Any?) {
        open(userFileAt: LanguageModelManager.phraseReplacementDataPathMcBopomofo)
    }
}
