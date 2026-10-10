import AppKit
import XCTest

@_spi(CandidatePreview) @testable import CandidateKit

@MainActor
final class CandidateThemeTests: XCTestCase {
    func testSystemSelectionUsesSemanticBackgroundAndTextInEachAppearance() throws {
        for name in [NSAppearance.Name.aqua, .darkAqua,
            .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua]
        {
            let appearance = try XCTUnwrap(NSAppearance(named: name))
            appearance.performAsCurrentDrawingAppearance {
                let colors = CandidateThemeResolver.selectionColors(perApplicationAccent: nil)
                assertSameColor(colors.background, .selectedContentBackgroundColor)
                assertSameColor(colors.foreground, .alternateSelectedControlTextColor)
            }
        }
    }

    func testBrightAccentsReachWhiteTextContrastWithoutUnnecessaryDimming() throws {
        let accents = [
            NSColor.white,
            NSColor(srgbRed: 1, green: 1, blue: 0, alpha: 1),
            NSColor(srgbRed: 0, green: 1, blue: 1, alpha: 1),
            NSColor(srgbRed: 1, green: 0.5, blue: 0, alpha: 1),
            NSColor(displayP3Red: 1, green: 0.6, blue: 0.2, alpha: 1),
        ]
        for accent in accents {
            let colors = CandidateThemeResolver.selectionColors(perApplicationAccent: accent)
            let original = try rgba(accent)
            let adjusted = try rgba(colors.background)
            XCTAssertLessThanOrEqual(adjusted.red, original.red + 0.000_001)
            XCTAssertLessThanOrEqual(adjusted.green, original.green + 0.000_001)
            XCTAssertLessThanOrEqual(adjusted.blue, original.blue + 0.000_001)
            XCTAssertEqual(adjusted.alpha, 1)
            assertSameColor(colors.foreground, .white)

            // Measure the output against the published WCAG white-text contrast ratio.
            let channels = [adjusted.red, adjusted.green, adjusted.blue].map {
                $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
            }
            let luminance = zip(channels, [0.2126, 0.7152, 0.0722]).reduce(CGFloat(0)) {
                $0 + $1.0 * $1.1
            }
            XCTAssertEqual(1.05 / (luminance + 0.05), 4.5, accuracy: 0.000_001)
        }
    }

    func testThemeSynchronizationUpdatesAppearanceWashAndExistingItems() throws {
        let controller = CandidateController()
        controller.replaceCandidates([Candidate(displayString: "測試")], initialSelectedIndex: 0)
        let darkAppearance = try XCTUnwrap(NSAppearance(named: .darkAqua))

        controller.synchronizeTheme(
            clientAppearance: darkAppearance,
            clientBundleIdentifier: "invalid.bundle.identifier"
        )

        XCTAssertEqual(controller.window?.appearance?.name, .darkAqua)
        XCTAssertEqual(controller.backdropView.effectAppearanceName, .darkAqua)
        XCTAssertEqual(controller.scrollView.effectiveAppearance.name, .darkAqua)
        XCTAssertEqual(controller.canvasView.effectiveAppearance.name, .darkAqua)
        XCTAssertEqual(controller.clientBundleIdentifier, "invalid.bundle.identifier")
        XCTAssertEqual(controller.canvasView.rowWashOpacity, 1 / 8)
        let itemView = try XCTUnwrap(controller.renderer[0])
        XCTAssertEqual(itemView.effectiveAppearance.name, .darkAqua)
        assertSameSelection(itemView.selectionColors, controller.resolvedSelectionColors)
        let systemIsDark =
            NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            == .darkAqua
        if #available(macOS 26.0, *) {
            XCTAssertEqual(controller.backdropView.isAppearanceCorrectionActive, !systemIsDark)
            if !systemIsDark {
                XCTAssertEqual(controller.backdropView.appearanceCorrectionName, .darkAqua)
            }
        }

        controller.synchronizeTheme(
            clientAppearance: NSAppearance(named: .aqua),
            clientBundleIdentifier: nil
        )
        XCTAssertEqual(controller.window?.appearance?.name, .aqua)
        XCTAssertEqual(controller.backdropView.effectAppearanceName, .aqua)
        XCTAssertEqual(controller.scrollView.effectiveAppearance.name, .aqua)
        XCTAssertEqual(controller.canvasView.effectiveAppearance.name, .aqua)
        XCTAssertEqual(controller.canvasView.rowWashOpacity, 1 / 2)
        XCTAssertEqual(itemView.effectiveAppearance.name, .aqua)
        assertSameSelection(itemView.selectionColors, controller.resolvedSelectionColors)

        if #available(macOS 26.0, *) {
            XCTAssertEqual(controller.backdropView.isAppearanceCorrectionActive, systemIsDark)
            if systemIsDark {
                XCTAssertEqual(controller.backdropView.appearanceCorrectionName, .aqua)
            }
        }

        controller.synchronizeTheme(clientAppearance: nil, clientBundleIdentifier: nil)
        XCTAssertFalse(controller.backdropView.isAppearanceCorrectionActive)
    }

    func testStableGlassThemePropagatesAcrossOrientationsAndReloads() throws {
        guard #available(macOS 26.0, *) else { throw XCTSkip("Requires Liquid Glass") }
        for orientation in [CandidateOrientation.horizontal, .vertical] {
            var configuration = CandidateConfiguration.default
            configuration.orientation = orientation
            let controller = CandidateController(configuration: configuration)
            controller.replaceCandidates(
                (0..<60).map { Candidate(displayString: "字\($0)") }, initialSelectedIndex: 12)
            controller.synchronizeTheme(
                clientAppearance: NSAppearance(named: .aqua), clientBundleIdentifier: nil)
            let glass = try XCTUnwrap(controller.backdropView.subviews.first as? NSGlassEffectView)
            XCTAssertEqual((glass.value(forKey: "_adaptiveAppearance") as? NSNumber)?.intValue, 1)
            let content = try XCTUnwrap(glass.contentView)
            XCTAssertNil(content.appearance)

            for name in [NSAppearance.Name.darkAqua, .aqua, .darkAqua] {
                controller.synchronizeTheme(
                    clientAppearance: NSAppearance(named: name), clientBundleIdentifier: nil)
                XCTAssertEqual(controller.window?.appearance?.name, name)
                XCTAssertEqual(glass.effectiveAppearance.name, name)
                XCTAssertEqual((glass.value(forKey: "_adaptiveAppearance") as? NSNumber)?.intValue, 1)
                XCTAssertNil(content.appearance)
                XCTAssertEqual(controller.canvasView.effectiveAppearance.name, name)
                XCTAssertEqual(controller.canvasView.rowWashOpacity, name == .darkAqua ? 1 / 8 : 1 / 2)
                XCTAssertNil(controller.scrollView.appearance)
                XCTAssertNil(controller.scrollView.contentView.appearance)
                XCTAssertNil(controller.canvasView.appearance)
                let item = try XCTUnwrap(controller.renderer[12])
                XCTAssertNil(item.appearance)
                XCTAssertEqual(item.effectiveAppearance.name, name)
                assertSameSelection(
                    item.selectionColors,
                    CandidateThemeResolver.resolvedSelectionColors(
                        appearance: content.effectiveAppearance, clientBundleIdentifier: nil))
            }

            controller.selectedCandidateIndex = 13
            XCTAssertEqual(controller.renderer[13]?.effectiveAppearance.name, .darkAqua)
            controller.replaceCandidates(
                [Candidate(displayString: "新候選字")], initialSelectedIndex: 0)
            XCTAssertEqual(controller.renderer[0]?.effectiveAppearance.name, .darkAqua)
        }
    }

    private func assertSameSelection(
        _ lhs: CandidateSelectionColors,
        _ rhs: CandidateSelectionColors,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertSameColor(lhs.background, rhs.background, file: file, line: line)
        assertSameColor(lhs.foreground, rhs.foreground, file: file, line: line)
    }

    private func rgba(
        _ color: NSColor
    ) throws -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let converted = try XCTUnwrap(color.usingColorSpace(.sRGB))
        return (
            converted.redComponent,
            converted.greenComponent,
            converted.blueComponent,
            converted.alphaComponent
        )
    }

    private func assertSameColor(
        _ lhs: NSColor,
        _ rhs: NSColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let left = lhs.usingColorSpace(.sRGB),
            let right = rhs.usingColorSpace(.sRGB)
        else {
            XCTFail("Colors must resolve to sRGB", file: file, line: line)
            return
        }
        XCTAssertEqual(
            left.redComponent, right.redComponent, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(
            left.greenComponent, right.greenComponent, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(
            left.blueComponent, right.blueComponent, accuracy: 0.000_001, file: file, line: line)
        XCTAssertEqual(
            left.alphaComponent, right.alphaComponent, accuracy: 0.000_001, file: file, line: line)
    }
}
