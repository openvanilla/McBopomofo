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

import Carbon
import Cocoa
import InfoCollector

struct KeyboardLayoutOption: Identifiable, Hashable {
    let id: String
    let localizedName: String
}

@MainActor
final class PreferencesViewModel: NSObject, ObservableObject {
    private var defaultsObserver: NSObjectProtocol?
    @Published private(set) var basisKeyboardLayoutOptions: [KeyboardLayoutOption] = []

    var keyboardLayout: KeyboardLayout {
        get { Preferences.keyboardLayout }
        set {
            objectWillChange.send()
            Preferences.keyboardLayout = newValue
        }
    }

    var basisKeyboardLayout: String {
        get { Preferences.basisKeyboardLayout }
        set {
            objectWillChange.send()
            Preferences.basisKeyboardLayout = newValue
        }
    }

    var candidateKeys: String {
        get {
            let keys = Preferences.candidateKeys
            if keys.isEmpty {
                return Preferences.defaultCandidateKeys
            }
            return keys
        }
        set {
            let keys =
                newValue
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            objectWillChange.send()
            do {
                try Preferences.validate(candidateKeys: keys)
                Preferences.candidateKeys = keys
                candidateKeysError = nil
            } catch Preferences.CandidateKeyError.empty {
                candidateKeysError = nil
            } catch {
                candidateKeysError = error.localizedDescription
                NSAlert(error: error).runModal()
            }
        }
    }

    @Published var candidateKeysError: String?

    var chooseCandidateUsingSpace: Bool {
        get { Preferences.chooseCandidateUsingSpace }
        set {
            objectWillChange.send()
            Preferences.chooseCandidateUsingSpace = newValue
        }
    }

    var selectPhraseAfterCursorAsCandidate: Bool {
        get { Preferences.selectPhraseAfterCursorAsCandidate }
        set {
            objectWillChange.send()
            Preferences.selectPhraseAfterCursorAsCandidate = newValue
        }
    }

    var moveCursorAfterSelectingCandidate: Bool {
        get { Preferences.moveCursorAfterSelectingCandidate }
        set {
            objectWillChange.send()
            Preferences.moveCursorAfterSelectingCandidate = newValue
        }
    }

    var allowMovingCursorWhenChoosingCandidates: MovingCursorKey {
        get { Preferences.allowMovingCursorWhenChoosingCandidates }
        set {
            objectWillChange.send()
            Preferences.allowMovingCursorWhenChoosingCandidates = newValue
        }
    }

    var useHorizontalCandidateList: Bool {
        get { Preferences.useHorizontalCandidateList }
        set {
            objectWillChange.send()
            Preferences.useHorizontalCandidateList = newValue
        }
    }

    var candidateListTextSize: CGFloat {
        get { Preferences.candidateListTextSize }
        set {
            objectWillChange.send()
            Preferences.candidateListTextSize = newValue
        }
    }

    var candidateListTextSizeOptions: [CGFloat] {
        let defaultSizes: [CGFloat] = [12, 14, 16, 18, 24, 32, 64, 96]
        let currentSize = CGFloat(Int(Preferences.candidateListTextSize))
        if defaultSizes.contains(currentSize) {
            return defaultSizes
        }
        return (defaultSizes + [currentSize]).sorted()
    }

    var letterBehavior: Int {
        get { Preferences.letterBehavior }
        set {
            objectWillChange.send()
            Preferences.letterBehavior = newValue
        }
    }

    var shiftEnterEnabled: Bool {
        get { Preferences.shiftEnterEnabled }
        set {
            objectWillChange.send()
            Preferences.shiftEnterEnabled = newValue
        }
    }

    var escToCleanInputBuffer: Bool {
        get { Preferences.escToCleanInputBuffer }
        set {
            objectWillChange.send()
            Preferences.escToCleanInputBuffer = newValue
        }
    }

    var beepUponInputError: Bool {
        get { Preferences.beepUponInputError }
        set {
            objectWillChange.send()
            Preferences.beepUponInputError = newValue
        }
    }

    var checkForUpdatesAutomatically: Bool {
        get {
            UserDefaults.standard.object(forKey: "CheckUpdateAutomatically") as? Bool ?? true
        }
        set {
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "CheckUpdateAutomatically")
        }
    }

    var useCustomUserPhraseLocation: Bool {
        get { Preferences.useCustomUserPhraseLocation }
        set {
            objectWillChange.send()
            Preferences.useCustomUserPhraseLocation = newValue
            if newValue && Preferences.customUserPhraseLocation.isEmpty {
                Preferences.customUserPhraseLocation =
                    UserPhraseLocationHelper.defaultUserPhraseLocation
            }
        }
    }

    var customUserPhraseLocation: String {
        get { Preferences.customUserPhraseLocation }
        set {
            let path = newValue.trimmingCharacters(in: .whitespaces)
            if !path.isEmpty && !FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.createDirectory(
                    atPath: path, withIntermediateDirectories: true)
            }
            objectWillChange.send()
            Preferences.customUserPhraseLocation = path
        }
    }

    var addPhraseHookEnabled: Bool {
        get { Preferences.addPhraseHookEnabled }
        set {
            objectWillChange.send()
            Preferences.addPhraseHookEnabled = newValue
        }
    }

    var addPhraseHookPath: String {
        get { Preferences.addPhraseHookPath }
        set {
            objectWillChange.send()
            Preferences.addPhraseHookPath = newValue
        }
    }

    var chineseConversionStyle: ChineseConversionStyle {
        get { Preferences.chineseConversionStyle }
        set {
            objectWillChange.send()
            Preferences.chineseConversionStyle = newValue
        }
    }

    var controlEnterOutput: ControlEnterOutput {
        get { Preferences.controlEnterOutput }
        set {
            objectWillChange.send()
            Preferences.controlEnterOutput = newValue
        }
    }

    var big5InputEnabled: Bool {
        get { Preferences.big5InputEnabled }
        set {
            objectWillChange.send()
            Preferences.big5InputEnabled = newValue
        }
    }

    var repeatedPunctuationToSelectCandidateEnabled: Bool {
        get { Preferences.repeatedPunctuationToSelectCandidateEnabled }
        set {
            objectWillChange.send()
            Preferences.repeatedPunctuationToSelectCandidateEnabled = newValue
        }
    }

    var showBopomofoFontAnnotationSupportItemInInputMenu: Bool {
        get { Preferences.showBopomofoFontAnnotationSupportItemInInputMenu }
        set {
            objectWillChange.send()
            Preferences.showBopomofoFontAnnotationSupportItemInInputMenu = newValue
        }
    }

    @Published private(set) var latestSystemReport = ""

    var effectiveUserPhraseLocation: String {
        if !useCustomUserPhraseLocation || customUserPhraseLocation.isEmpty {
            return UserPhraseLocationHelper.defaultUserPhraseLocation
        }
        return customUserPhraseLocation
    }

    var customUserPhraseLocationText: String {
        if useCustomUserPhraseLocation {
            return customUserPhraseLocation
        }
        return ""
    }

    override init() {
        super.init()
        Preferences.populateDefaults()
        loadBasisKeyboardLayoutOptions()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    func chooseUserPhraseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: effectiveUserPhraseLocation)

        if panel.runModal() == .OK, let url = panel.url {
            customUserPhraseLocation = url.path
        }
    }

    func openUserPhraseFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: effectiveUserPhraseLocation))
    }

    func openSystemInfoReport() {
        Task { @MainActor in
            await openSystemInfoReportAsync()
        }
    }

    func openSystemInfoReportAsync() async {
        var report = ""
        report += await InfoCollector.generate()
        report += Preferences.createReport()
        latestSystemReport = report

        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let randomName = "SystemInfoReport-\(UUID().uuidString).txt"
        let fileURL = tempDir.appendingPathComponent(randomName)
        do {
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(fileURL)
        } catch {
            NSLog("Failed to write report to temporary file: \(error)")
        }
    }

    private func loadBasisKeyboardLayoutOptions() {
        let list = TISCreateInputSourceList(nil, true).takeRetainedValue() as! [TISInputSource]
        var options: [KeyboardLayoutOption] = []

        for source in list {
            func getString(_ key: CFString) -> String? {
                if let ptr = TISGetInputSourceProperty(source, key) {
                    return String(Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue())
                }
                return nil
            }

            func getBool(_ key: CFString) -> Bool? {
                if let ptr = TISGetInputSourceProperty(source, key) {
                    return Unmanaged<CFBoolean>.fromOpaque(ptr).takeUnretainedValue()
                        == kCFBooleanTrue
                }
                return nil
            }

            guard
                getString(kTISPropertyInputSourceCategory)
                    == String(kTISCategoryKeyboardInputSource),
                getBool(kTISPropertyInputSourceIsASCIICapable) == true,
                getString(kTISPropertyInputSourceType) == String(kTISTypeKeyboardLayout),
                let sourceID = getString(kTISPropertyInputSourceID),
                let localizedName = getString(kTISPropertyLocalizedName)
            else {
                continue
            }

            options.append(KeyboardLayoutOption(id: sourceID, localizedName: localizedName))
        }

        if options.isEmpty {
            options = [
                KeyboardLayoutOption(
                    id: "com.apple.keylayout.US",
                    localizedName: NSLocalizedString("U.S.", comment: "")),
                KeyboardLayoutOption(
                    id: "com.apple.keylayout.ABC",
                    localizedName: NSLocalizedString("ABC", comment: "")),
            ]
        }

        basisKeyboardLayoutOptions = options
    }
}
