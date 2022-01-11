//
// AppDelegate.swift
//
// Copyright (c) 2011 The McBopomofo Project.
//
// Contributors:
//     Mengjuei Hsieh (@mjhsieh)
//     Weizhong Yang (@zonble)
//
// Based on the Syrup Project and the Formosana Library
// by Lukhnos Liu (@lukhnos).
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
//

import Cocoa
import InputMethodKit

private let kCheckUpdateAutomatically = "CheckUpdateAutomatically"
private let kNextUpdateCheckDateKey = "NextUpdateCheckDate"
private let kUpdateInfoEndpointKey = "UpdateInfoEndpoint"
private let kUpdateInfoSiteKey = "UpdateInfoSite"
private let kNextCheckInterval: TimeInterval = 86400.0
private let kTimeoutInterval: TimeInterval = 60.0

@objc (AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate, NonModalAlertWindowControllerDelegate {

    @IBOutlet weak var window: NSWindow?
    private var preferencesWindowController: PreferencesWindowController?
    private var checkTask: URLSessionTask?
    private var updateNextStepURL: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        LTLoadLanguageModel()
        LTLoadUserLanguageModelFile()

        if UserDefaults.standard.object(forKey: kCheckUpdateAutomatically) == nil {
            UserDefaults.standard.set(true, forKey: kCheckUpdateAutomatically)
            UserDefaults.standard.synchronize()
        }
        checkForUpdate()
    }

    @objc func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(windowNibName: "preferences")
        }
        preferencesWindowController?.window?.center()
        preferencesWindowController?.window?.orderFront(self)
    }

    @objc (checkForUpdate)
    func checkForUpdate() {
        checkForUpdate(forced: false)
    }

    @objc (checkForUpdateForced:)
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

        guard let infoDict = Bundle.main.infoDictionary,
              let updateInfoURLString = infoDict[kUpdateInfoEndpointKey] as? String,
              let updateInfoURL = URL(string: updateInfoURLString) else {
            return
        }

        let request = URLRequest(url: updateInfoURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: kTimeoutInterval)

        func showNoUpdateAvailableAlert() {
            NonModalAlertWindowController.shared.show(title: NSLocalizedString("Check for Update Completed", comment: ""), content: NSLocalizedString("You are already using the latest version of McBopomofo.", comment: ""), confirmButtonTitle: NSLocalizedString("OK", comment: ""), cancelButtonTitle: nil, cancelAsDefault: false, delegate: nil)
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer {
                self.checkTask = nil
            }

            if let error = error {
                if forced {
                    let title = NSLocalizedString("Update Check Failed", comment: "")
                    let content = String(format: NSLocalizedString("There may be no internet connection or the server failed to respond.\n\nError message: %@", comment: ""), error.localizedDescription)
                    let buttonTitle = NSLocalizedString("Dismiss", comment: "")

                    DispatchQueue.main.async {
                        NonModalAlertWindowController.shared.show(title: title, content: content, confirmButtonTitle: buttonTitle, cancelButtonTitle: nil, cancelAsDefault: false, delegate: nil)
                    }
                }
                return
            }

            do {
                guard let plist = try PropertyListSerialization.propertyList(from: data ?? Data(), options: [], format: nil) as? [AnyHashable: Any],
                      let remoteVersion = plist[kCFBundleVersionKey] as? String,
                      let infoDict = Bundle.main.infoDictionary
                        else {
                    if forced {
                        DispatchQueue.main.async {
                            showNoUpdateAvailableAlert()
                        }
                    }
                    return
                }

                // TODO: Validate info (e.g. bundle identifier)
                // TODO: Use HTML to display change log, need a new key like UpdateInfoChangeLogURL for this

                let currentVersion = infoDict[kCFBundleVersionKey as String] as? String ?? ""
                let result = currentVersion.compare(remoteVersion, options: .numeric, range: nil, locale: nil)

                if result != .orderedAscending {
                    if forced {
                        DispatchQueue.main.async {
                            showNoUpdateAvailableAlert()
                        }
                    }
                    return
                }

                guard let siteInfoURLString = plist[kUpdateInfoSiteKey] as? String,
                      let siteInfoURL = URL(string: siteInfoURLString) else {
                    if forced {
                        DispatchQueue.main.async {
                            showNoUpdateAvailableAlert()
                        }
                    }
                    return
                }

                self.updateNextStepURL = siteInfoURL

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

                let content = String(format: NSLocalizedString("You're currently using McBopomofo %@ (%@), a new version %@ (%@) is now available. Do you want to visit McBopomofo's website to download the version?%@", comment: ""),
                                     infoDict["CFBundleShortVersionString"] as? String ?? "",
                                     currentVersion,
                                     plist["CFBundleShortVersionString"] as? String ?? "",
                                     remoteVersion,
                                     versionDescription)
                DispatchQueue.main.async {
                    NonModalAlertWindowController.shared.show(title: NSLocalizedString("New Version Available", comment: ""), content: content, confirmButtonTitle: NSLocalizedString("Visit Website", comment: ""), cancelButtonTitle: NSLocalizedString("Not Now", comment: ""), cancelAsDefault: false, delegate: self)
                }

            } catch {
                if forced {
                    DispatchQueue.main.async {
                        showNoUpdateAvailableAlert()
                    }
                }
            }
        }
        checkTask = task
        task.resume()
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
