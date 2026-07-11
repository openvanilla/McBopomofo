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

import SwiftUI

let preferencesWindowWidth: CGFloat = 480

private func localized(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

struct PreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesViewModel
    @State private var selectedTab: PreferencesTab = .basic
    @State private var measuredContentHeight: PreferencesContentHeight?

    var body: some View {
        selectedTab.contentView
            .environmentObject(preferences)
            .frame(width: preferencesWindowWidth, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: PreferencesContentHeightKey.self,
                        value: PreferencesContentHeight(
                            tab: selectedTab, height: geometry.size.height))
                }
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .onPreferenceChange(PreferencesContentHeightKey.self) { measurement in
                guard let measurement else {
                    return
                }
                guard measuredContentHeight != measurement else {
                    return
                }
                measuredContentHeight = measurement
            }
            .background(
                WindowToolbarConfigurator(
                    selectedTab: $selectedTab,
                    contentHeight: selectedContentHeight))
    }

    private var selectedContentHeight: CGFloat? {
        guard measuredContentHeight?.tab == selectedTab else {
            return nil
        }
        return measuredContentHeight?.height
    }
}

private struct PreferencesContentHeight: Equatable {
    let tab: PreferencesTab
    let height: CGFloat
}

private struct PreferencesContentHeightKey: PreferenceKey {
    static var defaultValue: PreferencesContentHeight?

    static func reduce(
        value: inout PreferencesContentHeight?,
        nextValue: () -> PreferencesContentHeight?
    ) {
        value = nextValue() ?? value
    }
}

enum PreferencesTab: CaseIterable, Identifiable {
    case basic
    case userPhrases
    case advanced

    var id: Self { self }
    var title: String { localized(configuration.title) }
    var imageName: String { configuration.imageName }

    @ViewBuilder
    var contentView: some View {
        switch self {
        case .basic:
            BasicPreferencesView()
        case .userPhrases:
            UserPhrasesPreferencesView()
        case .advanced:
            AdvancedPreferencesView()
        }
    }

    private var configuration: (title: String, imageName: String) {
        switch self {
        case .basic: ("Basic", "switch.2")
        case .userPhrases: ("User Phrases", "folder")
        case .advanced: ("Advanced", "gearshape")
        }
    }
}

private struct WindowToolbarConfigurator: NSViewRepresentable {
    @Binding var selectedTab: PreferencesTab
    let contentHeight: CGFloat?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.configure(
                    window: window,
                    selectedTab: selectedTab,
                    contentHeight: contentHeight)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.selectedTab = selectedTab
        DispatchQueue.main.async {
            if let window = nsView.window {
                context.coordinator.configure(
                    window: window,
                    selectedTab: selectedTab,
                    contentHeight: contentHeight)
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
        private var hasAppliedContentHeight = false
        private var pendingTab: PreferencesTab?
        private var resizingTransitionGeneration: Int?
        private var transitionStartFrame: NSRect?
        private var transitionGeneration = 0

        init(selectedTab: Binding<PreferencesTab>) {
            _selectedTab = selectedTab
        }

        func configure(
            window: NSWindow,
            selectedTab: PreferencesTab,
            contentHeight: CGFloat?
        ) {
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

            let toolbarTab = pendingTab ?? selectedTab
            window.title = toolbarTab.title
            window.toolbar?.selectedItemIdentifier = Self.identifier(for: toolbarTab)
            if let contentHeight {
                if pendingTab == selectedTab {
                    resizeForPendingTransition(
                        window: window,
                        contentHeight: contentHeight)
                } else {
                    resize(
                        window: window,
                        contentHeight: contentHeight,
                        animate: hasAppliedContentHeight)
                }
                hasAppliedContentHeight = true
            }
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
            item.image = NSImage(
                systemSymbolName: tab.imageName, accessibilityDescription: tab.title)
            item.target = self
            item.action = #selector(selectToolbarItem(_:))
            return item
        }

        @objc private func selectToolbarItem(_ sender: NSToolbarItem) {
            guard let tab = Self.tab(for: sender.itemIdentifier) else {
                return
            }

            transitionGeneration += 1
            let generation = transitionGeneration
            sender.toolbar?.selectedItemIdentifier = sender.itemIdentifier
            window?.title = tab.title

            if tab == selectedTab {
                pendingTab = nil
                resizingTransitionGeneration = nil
                transitionStartFrame = nil
                restoreContentVisibility(generation: generation)
                return
            }

            pendingTab = tab
            guard
                let window,
                window.isVisible,
                let contentView = window.contentView
            else {
                selectedTab = tab
                pendingTab = nil
                return
            }
            transitionStartFrame = window.frame

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.05
                contentView.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                guard let self, generation == self.transitionGeneration else {
                    return
                }
                self.selectedTab = tab
            }
        }

        private func resizeForPendingTransition(window: NSWindow, contentHeight: CGFloat) {
            let generation = transitionGeneration
            guard resizingTransitionGeneration != generation else {
                return
            }
            resizingTransitionGeneration = generation
            if let transitionStartFrame {
                window.setFrame(transitionStartFrame, display: true, animate: false)
            }

            resize(
                window: window,
                contentHeight: contentHeight,
                animate: true
            ) { [weak self, weak window] in
                guard
                    let self,
                    let window,
                    generation == self.transitionGeneration
                else {
                    return
                }
                self.pendingTab = nil
                self.resizingTransitionGeneration = nil
                self.transitionStartFrame = nil
                guard let contentView = window.contentView else {
                    return
                }
                contentView.alphaValue = 0
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.05
                    contentView.animator().alphaValue = 1
                }
            }
        }

        private func restoreContentVisibility(generation: Int) {
            guard let contentView = window?.contentView else {
                return
            }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.05
                contentView.animator().alphaValue = 1
            } completionHandler: { [weak self] in
                guard let self, generation == self.transitionGeneration else {
                    return
                }
                self.resizingTransitionGeneration = nil
            }
        }

        private func resize(
            window: NSWindow,
            contentHeight: CGFloat,
            animate: Bool,
            completion: @escaping () -> Void = {}
        ) {
            let targetContentSize = NSSize(
                width: preferencesWindowWidth,
                height: contentHeight)
            let currentContentSize = window.contentView?.frame.size ?? .zero

            guard
                abs(currentContentSize.width - targetContentSize.width) > 0.5
                    || abs(currentContentSize.height - targetContentSize.height) > 0.5
            else {
                completion()
                return
            }

            var frame = window.frameRect(
                forContentRect: NSRect(origin: .zero, size: targetContentSize))
            frame.origin.x = window.frame.origin.x
            frame.origin.y = window.frame.maxY - frame.height
            guard animate else {
                window.setFrame(frame, display: true, animate: false)
                completion()
                return
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                window.animator().setFrame(frame, display: true)
            } completionHandler: {
                completion()
            }
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
        FormBody {
            PreferenceRow(localized("Bopomofo Keyboard Layout:")) {
                Picker("", selection: $preferences.keyboardLayout) {
                    ForEach(KeyboardLayout.allCasesForPreferences, id: \.rawValue) { layout in
                        Text(localized(layout.name)).tag(layout)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            PreferenceRow(localized("Alphanumeric Keyboard Layout:")) {
                Picker("", selection: $preferences.basisKeyboardLayout) {
                    ForEach(preferences.basisKeyboardLayoutOptions) { layout in
                        Text(layout.localizedName).tag(layout.id)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            Divider()
                .padding(.vertical, 5)

            PreferenceRow(localized("Selection Keys:")) {
                ComboBoxTextField(
                    text: $preferences.candidateKeys,
                    suggestions: Preferences.suggestedCandidateKeys
                )
                .frame(width: 220)
            }

            PreferenceRow {
                Toggle(
                    localized("Space key chooses candidate"),
                    isOn: $preferences.chooseCandidateUsingSpace)
            }

            PreferenceRow(localized("Show Candidate Phrase:")) {
                Picker("", selection: $preferences.selectPhraseAfterCursorAsCandidate) {
                    Text(localized("Before the cursor (like Hanin)")).tag(false)
                    Text(localized("After the cursor (like MS IME)")).tag(true)
                }
                .labelsHidden()
                .pickerStyle(RadioGroupPickerStyle())
                .fixedSize()
            }

            PreferenceRow {
                Toggle(
                    localized("Move cursor after selection"),
                    isOn: $preferences.moveCursorAfterSelectingCandidate)
            }

            PreferenceRow(localized("When Selecting Candidates:")) {
                Picker("", selection: $preferences.allowMovingCursorWhenChoosingCandidates) {
                    Text(localized("Disabled")).tag(MovingCursorKey.disabled)
                    Text(localized("JK keys move the cursor")).tag(MovingCursorKey.useJK)
                    Text(localized("HL keys move the cursor")).tag(MovingCursorKey.useHL)
                }
                .labelsHidden()
                .fixedSize()
            }

            PreferenceRow(localized("Candidate List Style:")) {
                Picker("", selection: $preferences.useHorizontalCandidateList) {
                    Text(localized("Vertical")).tag(false)
                    Text(localized("Horizontal")).tag(true)
                }
                .labelsHidden()
                .pickerStyle(RadioGroupPickerStyle())
                .fixedSize()
            }

            PreferenceRow(localized("Candidate Text Size:")) {
                Picker("", selection: $preferences.candidateListTextSize) {
                    ForEach(preferences.candidateListTextSizeOptions, id: \.self) { size in
                        Text("\(Int(size))").tag(size)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            Divider()
                .padding(.vertical, 5)

            PreferenceRow(localized("Shift + Letter Keys:")) {
                Picker("", selection: $preferences.letterBehavior) {
                    Text(localized("Input uppercase letters directly")).tag(0)
                    Text(localized("Input lowercased letters to buffer")).tag(1)
                }
                .labelsHidden()
                .pickerStyle(RadioGroupPickerStyle())
                .fixedSize()
            }

            PreferenceRow(localized("Shift + Enter Key:")) {
                Toggle(
                    localized("Trigger associated phrases"), isOn: $preferences.shiftEnterEnabled)
            }

            PreferenceRow(localized("ESC Key:")) {
                Toggle(
                    localized("ESC key clears entire input buffer"),
                    isOn: $preferences.escToCleanInputBuffer)
            }

            Divider()
                .padding(.vertical, 5)

            PreferenceRow {
                Toggle(
                    localized("Beep upon input error"), isOn: $preferences.beepUponInputError)
            }

            PreferenceRow {
                Toggle(
                    localized("Check for updates automatically"),
                    isOn: $preferences.checkForUpdatesAutomatically)
            }
        }
    }
}

private struct UserPhrasesPreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesViewModel

    var body: some View {
        FormBody {
            VStack(alignment: .leading, spacing: 8) {
                Text(localized("User Phrase Location:"))

                HStack(spacing: 8) {
                    Picker("", selection: $preferences.useCustomUserPhraseLocation) {
                        Text(localized("Default")).tag(false)
                        Text(localized("Custom")).tag(true)
                    }
                    .labelsHidden()
                    .fixedSize()

                    TextField(
                        "",
                        text: Binding(
                            get: { preferences.customUserPhraseLocationText },
                            set: { preferences.customUserPhraseLocation = $0 }
                        )
                    )
                    .disabled(!preferences.useCustomUserPhraseLocation)

                    Button {
                        preferences.chooseUserPhraseFolder()
                    } label: {
                        Image(systemName: "folder")
                    }
                    .disabled(!preferences.useCustomUserPhraseLocation)
                    .help(localized("Choose folder"))
                }

                Button {
                    preferences.openUserPhraseFolder()
                } label: {
                    Text(preferences.effectiveUserPhraseLocation)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .buttonStyle(.plain)
                .controlSize(.small)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
                .help(localized("Open folder"))

                Text(
                    localized(
                        "You can specify the folder to store user phrases to the folder of Google Drive, DropBox and so on so you can backup the phrases."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            }

            Divider()
                .padding(.vertical, 5)

            VStack(alignment: .leading, spacing: 8) {
                Text(localized("After Adding a New Phrase:"))

                Toggle(localized("Run a shell script"), isOn: $preferences.addPhraseHookEnabled)

                HStack(spacing: 8) {
                    Text(localized("Path:"))
                    TextField("", text: $preferences.addPhraseHookPath)
                }

                Text(
                    localized(
                        "You can run a script to use git to backup your phrases. The script will run in the folder of your user phrases folder."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AdvancedPreferencesView: View {
    @EnvironmentObject private var preferences: PreferencesViewModel

    var body: some View {
        FormBody {
            PreferenceRow(localized("Chinese Conversion Style:")) {
                Picker("", selection: $preferences.chineseConversionStyle) {
                    Text(localized("Convert output")).tag(ChineseConversionStyle.output)
                    Text(localized("Convert models")).tag(ChineseConversionStyle.model)
                }
                .labelsHidden()
                .pickerStyle(RadioGroupPickerStyle())
                .fixedSize()
            }

            PreferenceRow(localized("Ctrl + Enter Key:")) {
                Picker("", selection: $preferences.controlEnterOutput) {
                    ForEach(ControlEnterOutput.allCasesForPreferences, id: \.rawValue) { output in
                        Text(localized(output.name)).tag(output)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }

            PreferenceRow(localized("Ctrl + ` Key:")) {
                Toggle(localized("Input Big 5 Code"), isOn: $preferences.big5InputEnabled)
            }

            PreferenceRow(localized("Punctuation Symbols:")) {
                Toggle(
                    localized("Repeated key to next candidate"),
                    isOn: $preferences.repeatedPunctuationToSelectCandidateEnabled)
            }

            PreferenceRow {
                Text(
                    localized(
                        "When enabled, if you type \"Shift+,\" repeatedly with the standard layout, it will produce symbols like < and 《."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 232, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }

            PreferenceRow(localized("Bopomofo Font Annotation Support:")) {
                Toggle(
                    localized("Show toggle in input menu"),
                    isOn: $preferences.showBopomofoFontAnnotationSupportItemInInputMenu)
            }

            Divider()
                .padding(.vertical, 5)

            PreferenceRow {
                VStack(alignment: .leading, spacing: 8) {
                    Button(localized("Create System Report")) {
                        preferences.openSystemInfoReport()
                    }

                    Text(
                        localized(
                            "You can create a system report and attach it when filing an issue, so the developers can help you better."
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct FormBody<Content: View>: View {
    @State private var labelWidth: CGFloat = 0
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .environment(\.preferenceLabelWidth, labelWidth)
        .onPreferenceChange(PreferenceLabelWidthKey.self) { measuredWidth in
            guard abs(labelWidth - measuredWidth) > 0.5 else {
                return
            }
            labelWidth = measuredWidth
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct PreferenceRow<Content: View>: View {
    @Environment(\.preferenceLabelWidth) private var labelWidth

    let title: String?
    @ViewBuilder let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let title {
                Text(title)
                    .fixedSize()
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: PreferenceLabelWidthKey.self,
                                value: geometry.size.width)
                        }
                    }
                    .frame(width: labelWidth, alignment: .trailing)
            } else {
                Spacer()
                    .frame(width: labelWidth)
            }
            content
            Spacer(minLength: 0)
        }
    }
}

private struct PreferenceLabelWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PreferenceLabelWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    fileprivate var preferenceLabelWidth: CGFloat {
        get { self[PreferenceLabelWidthEnvironmentKey.self] }
        set { self[PreferenceLabelWidthEnvironmentKey.self] = newValue }
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

        func controlTextDidEndEditing(_ notification: Notification) {
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

extension KeyboardLayout {
    fileprivate static var allCasesForPreferences: [KeyboardLayout] {
        [.standard, .eten, .hsu, .eten26, .hanyuPinyin, .IBM]
    }
}

extension ControlEnterOutput {
    fileprivate static var allCasesForPreferences: [ControlEnterOutput] {
        [.off, .bpmfReading, .htmlRuby, .brailleUnicode, .hanyuPinyin, .brailleAscii]
    }
}
