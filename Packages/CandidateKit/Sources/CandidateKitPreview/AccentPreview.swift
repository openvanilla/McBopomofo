// Copyright (c) 2026 and onwards The McBopomofo Authors.
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
@_spi(CandidatePreview) import CandidateKit

@MainActor
final class AccentPreviewController {
    private let applyAccent: (NSColor?) -> (background: NSColor, foreground: NSColor)?
    private var window: NSWindow?
    private var usesSystemColor = false
    private let colorWell = NSColorWell()
    private let original = AccentSwatch()
    private let adjusted = AccentSwatch()
    private let status = NSTextField(labelWithString: "")
    private let originalContrast = NSTextField(labelWithString: "")
    private let adjustedContrast = NSTextField(labelWithString: "")
    private lazy var presets = NSSegmentedControl(
        labels: ["Bright", "System"], trackingMode: .selectOne,
        target: self, action: #selector(selectPreset))

    init(applyAccent: @escaping (NSColor?) -> (background: NSColor, foreground: NSColor)?) {
        self.applyAccent = applyAccent
    }

    func show(on screen: NSScreen?) {
        if window == nil {
            makeWindow(on: screen)
            useBrightSample()
        }
        refresh()
        window?.makeKeyAndOrderFront(nil)
    }

    func refresh() {
        guard window != nil,
            let colors = applyAccent(usesSystemColor ? nil : colorWell.color)
        else { return }
        original.background = usesSystemColor ? colors.background : colorWell.color
        original.foreground = usesSystemColor ? colors.foreground : .white
        adjusted.background = colors.background
        adjusted.foreground = colors.foreground
        let before = contrast(original.background, original.foreground)
        let after = contrast(adjusted.background, adjusted.foreground)
        status.stringValue = usesSystemColor ? "System color"
            : before < 4.5 ? "Darkened" : "Unchanged"
        originalContrast.stringValue = String(format: "%.2f:1", before)
        adjustedContrast.stringValue = String(format: "%.2f:1", after)
    }

    @objc private func changeColor() {
        usesSystemColor = false
        presets.selectedSegment = -1
        refresh()
    }

    @objc private func useBrightSample() {
        colorWell.color = NSColor(
            srgbRed: 195 / 255, green: 211 / 255, blue: 247 / 255, alpha: 1)
        changeColor()
        presets.selectedSegment = 0
    }

    @objc private func useSystemSelection() {
        usesSystemColor = true
        presets.selectedSegment = 1
        refresh()
    }

    @objc private func selectPreset() {
        switch presets.selectedSegment {
        case 0: useBrightSample()
        case 1: useSystemSelection()
        default: break
        }
    }

    private func makeWindow(on screen: NSScreen?) {
        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 16
        content.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        colorWell.color = .white
        colorWell.isContinuous = true
        colorWell.target = self
        colorWell.action = #selector(changeColor)
        colorWell.setAccessibilityLabel("Custom accent color")
        colorWell.controlSize = .small
        colorWell.widthAnchor.constraint(equalToConstant: 36).isActive = true
        presets.controlSize = .small
        presets.font = .systemFont(ofSize: 12)
        presets.setAccessibilityLabel("Accent samples")
        let controls = NSStackView(views: [label("Accent", size: 12), colorWell, NSView(), presets])
        controls.spacing = 6
        content.addArrangedSubview(controls)

        let heading = label("Contrast", size: 11)
        heading.alignment = .right
        let comparison = NSStackView(views: [
            heading,
            swatchRow("Original", swatch: original, value: originalContrast),
            swatchRow("Selection", swatch: adjusted, value: adjustedContrast),
        ])
        comparison.orientation = .vertical
        comparison.alignment = .trailing
        comparison.spacing = 10
        heading.widthAnchor.constraint(equalToConstant: 64).isActive = true
        content.addArrangedSubview(comparison)
        let divider = NSBox()
        divider.boxType = .separator
        content.addArrangedSubview(divider)
        divider.widthAnchor.constraint(equalTo: comparison.widthAnchor).isActive = true
        status.font = .systemFont(ofSize: 12, weight: .medium)
        status.textColor = .secondaryLabelColor
        let footer = NSStackView(views: [
            status, label("Threshold: Contrast < 4.5:1", size: 11),
        ])
        footer.orientation = .vertical
        footer.alignment = .leading
        footer.spacing = 4
        content.addArrangedSubview(footer)
        controls.widthAnchor.constraint(equalTo: comparison.widthAnchor).isActive = true
        footer.widthAnchor.constraint(equalTo: comparison.widthAnchor).isActive = true
        status.widthAnchor.constraint(equalTo: comparison.widthAnchor).isActive = true
        for row in content.arrangedSubviews {
            row.trailingAnchor.constraint(
                lessThanOrEqualTo: content.trailingAnchor,
                constant: -content.edgeInsets.right
            ).isActive = true
        }

        let panel = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 260),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        panel.title = "Accent Colors"
        panel.isReleasedWhenClosed = false
        panel.contentView = content
        panel.setContentSize(content.fittingSize)
        if let frame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: frame.minX + 20, y: frame.minY + 20))
        }
        window = panel
    }

    private func label(_ text: String, size: CGFloat = 13) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = .systemFont(ofSize: size)
        field.textColor = .secondaryLabelColor
        return field
    }

    private func swatchRow(
        _ title: String, swatch: AccentSwatch, value: NSTextField
    ) -> NSStackView {
        value.font = .systemFont(ofSize: 13)
        value.alignment = .right
        value.widthAnchor.constraint(equalToConstant: 64).isActive = true
        value.setAccessibilityLabel("\(title) text contrast")
        let name = label(title, size: 12)
        name.widthAnchor.constraint(equalToConstant: 64).isActive = true
        let row = NSStackView(views: [name, swatch, value])
        row.spacing = 12
        swatch.widthAnchor.constraint(equalToConstant: swatch.fittingSize.width).isActive = true
        swatch.heightAnchor.constraint(equalToConstant: swatch.fittingSize.height).isActive = true
        return row
    }

    private func contrast(_ background: NSColor, _ foreground: NSColor) -> CGFloat {
        // Independently measure rendered swatch colors using WCAG relative luminance.
        // https://www.w3.org/WAI/WCAG22/Techniques/general/G18.html
        func luminance(_ color: NSColor) -> CGFloat {
            guard let rgb = color.usingColorSpace(.sRGB) else { return 0 }
            let channels = [rgb.redComponent, rgb.greenComponent, rgb.blueComponent].map {
                $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
            }
            return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722
        }
        let first = luminance(background), second = luminance(foreground)
        return (max(first, second) + 0.05) / (min(first, second) + 0.05)
    }
}

@MainActor
private final class AccentSwatch: NSView {
    private let sample = CandidateController.previewCandidateItem("小麥注音")
    var background: NSColor = .white { didSet { sample.setColors(background, foreground) } }
    var foreground: NSColor = .white { didSet { sample.setColors(background, foreground) } }

    override var fittingSize: NSSize { sample.view.frame.size }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true
        addSubview(sample.view)
    }

    required init?(coder: NSCoder) { nil }
}
