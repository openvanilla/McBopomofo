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

internal struct CandidateSelectionColors {
    let background: NSColor
    let foreground: NSColor

    static let system = Self(
        background: .selectedContentBackgroundColor,
        foreground: .alternateSelectedControlTextColor
    )
}

@MainActor
internal enum CandidateThemeResolver {
    static func resolvedSelectionColors(
        appearance: NSAppearance,
        clientBundleIdentifier: String?,
        accentOverride: NSColor? = nil
    ) -> CandidateSelectionColors {
        var colors = CandidateSelectionColors.system
        appearance.performAsCurrentDrawingAppearance {
            let perApplicationAccent =
                accentOverride ?? (systemUsesMulticolorAccent
                ? perApplicationAccentColor(bundleIdentifier: clientBundleIdentifier)
                : nil)
            colors = selectionColors(perApplicationAccent: perApplicationAccent)
        }
        return colors
    }

    static func selectionColors(perApplicationAccent: NSColor?) -> CandidateSelectionColors {
        // Translucent or unconvertible accents cannot guarantee contrast over glass.
        guard let color = perApplicationAccent?.usingColorSpace(.sRGB),
            color.alphaComponent == 1
        else {
            return .system
        }

        // WCAG relative luminance and 4.5:1 contrast also cover small shortcut labels.
        // https://www.w3.org/WAI/WCAG22/Techniques/general/G18.html
        let red = linearComponent(color.redComponent)
        let green = linearComponent(color.greenComponent)
        let blue = linearComponent(color.blueComponent)
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let minimumContrast: CGFloat = 4.5
        let maximumLuminance = (1 + 0.05) / minimumContrast - 0.05
        guard luminance > maximumLuminance else {
            return CandidateSelectionColors(background: color, foreground: .white)
        }

        // Scale linear RGB toward black only as far as needed for white text.
        let scale = maximumLuminance / luminance
        return CandidateSelectionColors(
            background: NSColor(
                srgbRed: encodedComponent(red * scale),
                green: encodedComponent(green * scale),
                blue: encodedComponent(blue * scale),
                alpha: 1
            ),
            foreground: .white
        )
    }

    // Standard sRGB transfer functions, paired with the WCAG luminance calculation.
    private static func linearComponent(_ value: CGFloat) -> CGFloat {
        value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    private static func encodedComponent(_ value: CGFloat) -> CGFloat {
        value <= 0.0031308 ? value * 12.92 : 1.055 * pow(value, 1 / 2.4) - 0.055
    }

    static var systemUsesMulticolorAccent: Bool {
        UserDefaults.standard.object(forKey: "AppleAccentColor") == nil
    }

    static func perApplicationAccentColor(bundleIdentifier: String?) -> NSColor? {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else {
            return nil
        }
        let bundle = Bundle(identifier: bundleIdentifier) ?? applicationBundle(bundleIdentifier)
        guard let bundle,
            let colorName = bundle.object(forInfoDictionaryKey: "NSAccentColorName") as? String,
            !colorName.isEmpty
        else {
            return nil
        }
        return NSColor(named: NSColor.Name(colorName), bundle: bundle)
    }

    private static func applicationBundle(_ bundleIdentifier: String) -> Bundle? {
        guard
            let applicationURL = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleIdentifier
            )
        else {
            return nil
        }
        return Bundle(url: applicationURL)
    }
}
