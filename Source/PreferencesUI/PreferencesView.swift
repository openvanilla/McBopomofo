import SwiftUI

let leftRowWidth: CGFloat = 214

private func localized(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

struct PreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesViewModel
    @State private var selectedTab: PreferencesTab = .basic

    var body: some View {
        Group {
            switch selectedTab {
            case .basic:
                BasicPreferencesView()
            case .userPhrases:
                UserPhrasesPreferencesView()
            case .advanced:
                AdvancedPreferencesView()
            }
        }
        .environmentObject(preferences)
        .frame(width: 478, height: selectedTab.contentHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(WindowToolbarConfigurator(selectedTab: $selectedTab))
    }
}

enum PreferencesTab: CaseIterable, Identifiable {
    case basic
    case userPhrases
    case advanced

    var id: String {
        switch self {
        case .basic:
            "basic"
        case .userPhrases:
            "userPhrases"
        case .advanced:
            "advanced"
        }
    }

    var title: String {
        switch self {
        case .basic:
            localized("Basic")
        case .userPhrases:
            localized("User Phrases")
        case .advanced:
            localized("Advanced")
        }
    }

    var imageName: String {
        switch self {
        case .basic:
            "switch.2"
        case .userPhrases:
            "folder"
        case .advanced:
            "gearshape"
        }
    }

    var contentHeight: CGFloat {
        switch self {
        case .basic:
            585
        case .userPhrases:
            318
        case .advanced:
            390
        }
    }
}

private struct WindowToolbarConfigurator: NSViewRepresentable {
    @Binding var selectedTab: PreferencesTab

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.configure(window: window, selectedTab: selectedTab)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.selectedTab = selectedTab
        DispatchQueue.main.async {
            if let window = nsView.window {
                context.coordinator.configure(window: window, selectedTab: selectedTab)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedTab: $selectedTab)
    }

    final class Coordinator: NSObject, NSToolbarDelegate {
        private static let toolbarIdentifier = NSToolbar.Identifier("PreferencesToolbar")
        private static let basicIdentifier = NSToolbarItem.Identifier("PreferencesToolbar.basic")
        private static let userPhrasesIdentifier =
            NSToolbarItem.Identifier("PreferencesToolbar.userPhrases")
        private static let advancedIdentifier =
            NSToolbarItem.Identifier("PreferencesToolbar.advanced")

        @Binding var selectedTab: PreferencesTab
        private weak var window: NSWindow?
        private var appliedTab: PreferencesTab?

        init(selectedTab: Binding<PreferencesTab>) {
            _selectedTab = selectedTab
        }

        func configure(window: NSWindow, selectedTab: PreferencesTab) {
            self.window = window

            if window.toolbar?.identifier != Self.toolbarIdentifier {
                let toolbar = NSToolbar(identifier: Self.toolbarIdentifier)
                toolbar.allowsUserCustomization = false
                toolbar.autosavesConfiguration = false
                toolbar.displayMode = .iconAndLabel
                toolbar.sizeMode = .regular
                toolbar.delegate = self

                window.toolbar = toolbar
                window.toolbarStyle = .preference
            }

            window.title = selectedTab.title
            window.toolbar?.selectedItemIdentifier = Self.identifier(for: selectedTab)
            resize(window: window, for: selectedTab, animate: appliedTab != nil)
            appliedTab = selectedTab
        }

        func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            [
                Self.basicIdentifier,
                Self.userPhrasesIdentifier,
                Self.advancedIdentifier,
            ]
        }

        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            toolbarDefaultItemIdentifiers(toolbar)
        }

        func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            toolbarDefaultItemIdentifiers(toolbar)
        }

        func toolbar(
            _ toolbar: NSToolbar,
            itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
            willBeInsertedIntoToolbar flag: Bool
        ) -> NSToolbarItem? {
            guard let tab = Self.tab(for: itemIdentifier) else {
                return nil
            }

            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = tab.title
            item.paletteLabel = tab.title
            item.toolTip = tab.title
            item.image = NSImage(systemSymbolName: tab.imageName, accessibilityDescription: tab.title)
            item.target = self
            item.action = #selector(selectToolbarItem(_:))
            return item
        }

        @objc private func selectToolbarItem(_ sender: NSToolbarItem) {
            guard let tab = Self.tab(for: sender.itemIdentifier) else {
                return
            }
            selectedTab = tab
            sender.toolbar?.selectedItemIdentifier = sender.itemIdentifier
            window?.title = tab.title
            if let window {
                resize(window: window, for: tab, animate: true)
            }
            appliedTab = tab
        }

        private func resize(window: NSWindow, for tab: PreferencesTab, animate: Bool) {
            let targetContentSize = NSSize(width: 478, height: tab.contentHeight)
            let currentContentSize = window.contentView?.frame.size ?? .zero

            guard abs(currentContentSize.width - targetContentSize.width) > 0.5
                || abs(currentContentSize.height - targetContentSize.height) > 0.5
            else {
                return
            }

            var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: targetContentSize))
            frame.origin.x = window.frame.origin.x
            frame.origin.y = window.frame.maxY - frame.height
            window.setFrame(frame, display: true, animate: animate)
        }

        private static func identifier(for tab: PreferencesTab) -> NSToolbarItem.Identifier {
            switch tab {
            case .basic:
                basicIdentifier
            case .userPhrases:
                userPhrasesIdentifier
            case .advanced:
                advancedIdentifier
            }
        }

        private static func tab(for identifier: NSToolbarItem.Identifier) -> PreferencesTab? {
            switch identifier {
            case basicIdentifier:
                .basic
            case userPhrasesIdentifier:
                .userPhrases
            case advancedIdentifier:
                .advanced
            default:
                nil
            }
        }
    }
}

private struct BasicPreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesViewModel

    var body: some View {
        FormBody(height: 565) {
            PreferenceRow(localized("Bopomofo Keyboard Layout:")) {
                Picker("", selection: $preferences.keyboardLayout) {
                    ForEach(KeyboardLayout.allCasesForPreferences, id: \.rawValue) { layout in
                        Text(localized(layout.name)).tag(layout)
                    }
                }
                .labelsHidden()
            }

            PreferenceRow(localized("Alphanumeric Keyboard Layout:")) {
                Picker("", selection: $preferences.basisKeyboardLayout) {
                    ForEach(preferences.basisKeyboardLayoutOptions) { layout in
                        Text(layout.localizedName).tag(layout.id)
                    }
                }
                .labelsHidden()
            }

            Divider()

            PreferenceRow(localized("Selection Keys:")) {
                ComboBoxTextField(text: $preferences.candidateKeys, suggestions: Preferences.suggestedCandidateKeys)
                    .frame(width: 220)
            }

            PreferenceRow("") {
                Toggle(localized("Space key chooses candidate"), isOn: $preferences.chooseCandidateUsingSpace)
            }

            PreferenceRow(localized("Show Candidate Phrase:")) {
                VStack(alignment: .leading, spacing: 6) {
                    RadioButton(
                        title: localized("Before the cursor (like Hanin)"),
                        isSelected: !preferences.selectPhraseAfterCursorAsCandidate
                    ) {
                        preferences.selectPhraseAfterCursorAsCandidate = false
                    }
                    RadioButton(
                        title: localized("After the cursor (like MS IME)"),
                        isSelected: preferences.selectPhraseAfterCursorAsCandidate
                    ) {
                        preferences.selectPhraseAfterCursorAsCandidate = true
                    }
                }
            }

            PreferenceRow("") {
                Toggle(localized("Move cursor after selection"), isOn: $preferences.moveCursorAfterSelectingCandidate)
            }

            PreferenceRow(localized("When Selecting Candidates:")) {
                Picker("", selection: $preferences.allowMovingCursorWhenChoosingCandidates) {
                    Text(localized("Disabled")).tag(MovingCursorKey.disabled)
                    Text(localized("JK keys move the cursor")).tag(MovingCursorKey.useJK)
                    Text(localized("HL keys move the cursor")).tag(MovingCursorKey.useHL)
                }
                .labelsHidden()
            }

            PreferenceRow(localized("Candidate List Style:")) {
                VStack(alignment: .leading, spacing: 6) {
                    RadioButton(title: localized("Vertical"), isSelected: !preferences.useHorizontalCandidateList) {
                        preferences.useHorizontalCandidateList = false
                    }
                    RadioButton(title: localized("Horizontal"), isSelected: preferences.useHorizontalCandidateList) {
                        preferences.useHorizontalCandidateList = true
                    }
                }
            }

            PreferenceRow(localized("Candidate Text Size:")) {
                Picker("", selection: $preferences.candidateListTextSize) {
                    ForEach(preferences.candidateListTextSizeOptions, id: \.self) { size in
                        Text("\(Int(size))").tag(size)
                    }
                }
                .labelsHidden()
            }

            Divider()

            PreferenceRow(localized("Shift + Letter Keys:")) {
                VStack(alignment: .leading, spacing: 6) {
                    RadioButton(title: localized("Input uppercase letters directly"), isSelected: preferences.letterBehavior == 0) {
                        preferences.letterBehavior = 0
                    }
                    RadioButton(title: localized("Input lowercased letters to buffer"), isSelected: preferences.letterBehavior == 1) {
                        preferences.letterBehavior = 1
                    }
                }
            }

            PreferenceRow(localized("Shift + Enter Key:")) {
                Toggle(localized("Trigger associated phrases"), isOn: $preferences.shiftEnterEnabled)
            }

            PreferenceRow(localized("ESC Key:")) {
                Toggle(localized("ESC key clears entire input buffer"), isOn: $preferences.escToCleanInputBuffer)
            }

            PreferenceRow("") {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(localized("Beep upon input error"), isOn: $preferences.beepUponInputError)
                    Spacer()
                        .frame(height: 20)
                    Toggle(localized("Check for updates automatically"), isOn: $preferences.checkForUpdatesAutomatically)
                }
            }
        }
    }
}

private struct UserPhrasesPreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesViewModel

    var body: some View {
        FormBody(height: 318) {
            VStack(alignment: .leading, spacing: 14) {
                Text(localized("User Phrase Location:"))
                    .font(.headline)

                HStack(spacing: 12) {
                    Picker("", selection: $preferences.useCustomUserPhraseLocation) {
                        Text(localized("Default")).tag(false)
                        Text(localized("Custom")).tag(true)
                    }
                    .labelsHidden()
                    .frame(width: 96)

                    TextField("", text: Binding(
                        get: { preferences.customUserPhraseLocationText },
                        set: { preferences.customUserPhraseLocation = $0 }
                    ))
                        .disabled(!preferences.useCustomUserPhraseLocation)

                    Button {
                        preferences.chooseUserPhraseFolder()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!preferences.useCustomUserPhraseLocation)
                    .help(localized("Choose folder"))

                    Button {
                        preferences.openUserPhraseFolder()
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderless)
                    .help(localized("Open folder"))
                }

                Text(preferences.effectiveUserPhraseLocation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(localized("You can specify the folder to store user phrases to the folder of Google Drive, DropBox and so on so you can backup the phrases."))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(localized("After Adding a New Phrase:"))
                    .font(.headline)

                Toggle(localized("Run a shell script"), isOn: $preferences.addPhraseHookEnabled)

                HStack(spacing: 8) {
                    Text(localized("Path:"))
                        .font(.headline)
                    TextField("", text: $preferences.addPhraseHookPath)
                }

                Text(localized("You can run a script to use git to backup your phrases. The script will run in the folder of your user phrases folder."))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AdvancedPreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesViewModel

    var body: some View {
        FormBody(height: 330) {
            PreferenceRow(localized("Chinese Conversion Style:")) {
                VStack(alignment: .leading, spacing: 6) {
                    RadioButton(title: localized("Convert output"), isSelected: preferences.chineseConversionStyle == .output) {
                        preferences.chineseConversionStyle = .output
                    }
                    RadioButton(title: localized("Convert models"), isSelected: preferences.chineseConversionStyle == .model) {
                        preferences.chineseConversionStyle = .model
                    }
                }
            }

            PreferenceRow(localized("Ctrl + Enter Key:")) {
                Picker("", selection: $preferences.controlEnterOutput) {
                    ForEach(ControlEnterOutput.allCasesForPreferences, id: \.rawValue) { output in
                        Text(localized(output.name)).tag(output)
                    }
                }
                .labelsHidden()
                .frame(width: 220)
            }

            PreferenceRow(localized("Ctrl + ` Key:")) {
                Toggle(localized("Input Big 5 Code"), isOn: $preferences.big5InputEnabled)
            }

            PreferenceRow(localized("Punctuation Symbols:")) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(localized("Repeated key to next candidate"), isOn: $preferences.repeatedPunctuationToSelectCandidateEnabled)

                    Text(localized("When enabled, if you type \"Shift+,\" repeatedly with the standard layout, it will produce symbols like < and 《."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 250, alignment: .leading)
                }
            }

            Spacer()
                .frame(height: 18)

            PreferenceRow(localized("Bopomofo Font Annotation Support:")) {
                Toggle(localized("Show toggle in input menu"), isOn: $preferences.showBopomofoFontAnnotationSupportItemInInputMenu)
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                Spacer()
                    .frame(width: leftRowWidth)

                VStack(alignment: .leading, spacing: 8) {
                    Button(localized("Create System Report")) {
                        preferences.openSystemInfoReport()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary)

                    Text(localized("You can create a system report and attach it when filing an issue, so the developers can help you better."))
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 230, alignment: .leading)
                }
            }
        }
    }
}

private struct FormBody<Content: View>: View {
    let height: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
    }
}

private struct PreferenceRow<Content: View>: View {
    private let labelWidth: CGFloat = leftRowWidth
    private let columnSpacing: CGFloat = 12

    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: columnSpacing) {
            Text(title)
                .font(.headline)
                .frame(width: labelWidth, alignment: .trailing)
                .padding(.top, 2)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.55))
                    .font(.system(size: 14))
                    .frame(width: 14)
                Text(title)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct ComboBoxTextField: NSViewRepresentable {
    @Binding var text: String
    let suggestions: [String]

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.usesDataSource = false
        comboBox.completes = true
        comboBox.numberOfVisibleItems = suggestions.count
        comboBox.addItems(withObjectValues: suggestions)
        comboBox.delegate = context.coordinator
        return comboBox
    }

    func updateNSView(_ nsView: NSComboBox, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSComboBoxDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            updateText(notification)
        }

        func controlTextDidChange(_ notification: Notification) {
            updateText(notification)
        }

        private func updateText(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else {
                return
            }
            text = comboBox.stringValue
        }
    }
}

private extension KeyboardLayout {
    static var allCasesForPreferences: [KeyboardLayout] {
        [.standard, .eten, .hsu, .eten26, .hanyuPinyin, .IBM]
    }
}

private extension ControlEnterOutput {
    static var allCasesForPreferences: [ControlEnterOutput] {
        [.off, .bpmfReading, .htmlRuby, .brailleUnicode, .hanyuPinyin, .brailleAscii]
    }
}
