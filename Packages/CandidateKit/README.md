# CandidateKit

Copyright (c) 2026 and onwards The McBopomofo Authors.

CandidateKit provides horizontal and vertical candidate windows for AppKit and
InputMethodKit applications. It supports paged and expandable layouts, custom
selection keys and fonts, candidate details, keyboard navigation, and VoiceOver.

## Requirements

- macOS 13 or later
- Swift 6.2 or later
- Candidate windows must be used on the main actor

## Integration

Add `Packages/CandidateKit` as a local Swift package dependency in Xcode, then
link the `CandidateKit` library product to the application target. Import
`CandidateKit` in Swift files that use the candidate window.

## Usage

Use `VerticalCandidateController` or `HorizontalCandidateController` and provide
the candidates through a `CandidateControllerDelegate`:

```swift
import AppKit
import CandidateKit

@MainActor
final class ExampleCandidates: NSObject, CandidateControllerDelegate {
    private let candidates = ["小麥注音", "注音", "因"]

    func candidateCountForController(_ controller: CandidateController) -> UInt {
        UInt(candidates.count)
    }

    func candidateController(
        _ controller: CandidateController, candidateAtIndex index: UInt
    ) -> String {
        candidates[Int(index)]
    }

    func candidateController(
        _ controller: CandidateController, readingAtIndex index: UInt
    ) -> String? {
        nil
    }

    func candidateController(
        _ controller: CandidateController,
        requestExplanationFor candidate: String,
        reading: String
    ) -> String? {
        nil
    }

    func candidateController(
        _ controller: CandidateController, didSelectCandidateAtIndex index: UInt
    ) {
        print(candidates[Int(index)])
    }
}

@MainActor
final class ExampleHost {
    private let candidates = ExampleCandidates()
    let controller = VerticalCandidateController()

    func showCandidates(near anchor: NSRect) {
        controller.delegate = candidates
        controller.keyLabels = ["1", "2", "3"].map {
            CandidateKeyLabel(key: $0, displayedText: $0)
        }
        controller.reloadData()
        controller.show(near: anchor)
    }
}
```

Keep the delegate alive for as long as the window is used. Its reference in the
controller is weak. Call `reloadData()` again whenever the candidate data
changes. `readingAtIndex` and `requestExplanationFor` can return `nil` when no
detail or explanation is available.

Configure fonts, selection labels, orientation, and expansion through the
controller's properties and `configuration`. Hosts can pass eligible key events
to `handleKeyEvent(_:)` or use the navigation methods directly.

## Preview and tests

Run these commands from the McBopomofo repository root. The preview is a
standalone macOS application for inspecting candidate layouts and interactions;
it does not install or run an input method.

### Launch the preview

```sh
swift run --package-path Packages/CandidateKit CandidateKitPreview
```

The default preview uses the `candidates` sample, horizontal orientation,
expansion enabled, 16 pt text, numeric selection keys (`123456789`), and the
system appearance. The first candidate is selected.

Options can be combined, for example:

```sh
swift run --package-path Packages/CandidateKit CandidateKitPreview --sample=plain-associated --vertical --letter-keys --font-size=24
swift run --package-path Packages/CandidateKit CandidateKitPreview --sample=long-list --vertical --expanded --last
swift run --package-path Packages/CandidateKit CandidateKitPreview --paged --dark --black-background --accent
```

### Command-line options

| Option | Behavior |
| --- | --- |
| `--sample=NAME` | Select one of the eight samples listed below. Defaults to `candidates`; an unrecognized name also uses `candidates`. |
| `--vertical` | Use a vertical candidate window instead of the default horizontal window. |
| `--paged` | Disable expansion and use paged navigation. |
| `--expanded` | Send an initial expansion-direction navigation action: Right for vertical windows or Down for horizontal windows. Use with expansion enabled and enough candidates to expand. |
| `--last` | Initially select the last candidate in the sample. |
| `--letter-keys` | Use `asdfzxcvb` instead of `123456789` for selection keys. |
| `--font-size=SIZE` | Set the candidate font size to `12`, `16`, `24`, or `32` pt. Other values leave the default 16 pt size unchanged. |
| `--light` | Use the light appearance instead of following the system. |
| `--dark` | Use the dark appearance instead of following the system. Takes precedence over `--light`. |
| `--black-background` | Show a black backdrop behind the candidate window. This is independent of its appearance. |
| `--accent` | Open the accent color comparison window. |
| `--tooltip` | Set the candidate window header to `聯想詞`. |
| `--short-list` | Select the `short-list` sample when `--sample` is absent. |
| `--many-candidates` | Select the `long-list` sample when `--sample` is absent. Takes precedence over `--short-list`. |

Use the `--sample=NAME` and `--font-size=SIZE` forms with an equals sign.
`--sample` takes precedence over both sample shortcut flags. `--expanded` does
not override `--paged`; it sends a navigation action under the selected display
mode.

### Samples

| `--sample` value | Contents and purpose |
| --- | --- |
| `candidates` | Chinese candidates beginning with `小麥注音`, `注音`, and `因`, with ordinary selection labels. |
| `associated` | Automatic associated phrases with a `注音…` header and trailing `⇧ ⏎` hints. Press Shift-Return to confirm the highlighted phrase. |
| `plain-associated` | Associated phrases with trailing `⇧ 1` or `⇧ a` hints. Press Shift plus the indicated selection key to confirm. |
| `numbers` | Three representations of 123, including `一百二十三` and `壹佰貳拾參`, with shifted selection-key hints. |
| `icu` | Foundation text-transform results with shifted selection-key hints. |
| `details` | Candidates with optional trailing details, a header, and a long detail for checking alignment and truncation. |
| `short-list` | Five candidates for checking a short list. |
| `long-list` | 201 candidates for checking expansion, scrolling, and navigation near the end of a list. |

Shifted selection-key hints follow the current page, row, or column. Unselected
hints use the detail color; selected hints use the selection text color.
Switch to `candidates` to compare trailing hints with ordinary leading labels.
These samples supply demonstration data, not input-method conversion logic.

### Menus and keyboard controls

The preview provides four menus in addition to its application menu. Choice
submenus mark the current setting with a checkmark. Changing orientation,
display mode, or font size preserves the active sample and its selection-key
hints.

| Menu | Controls |
| --- | --- |
| Layout | Horizontal (Command-1), Vertical (Command-2), Expandable (Command-3), Paged (Command-4); font sizes 12, 16, 24, and 32 pt; numeric or letter selection keys. |
| Samples | All eight samples listed above. |
| Appearance | System (Command-S), Light (Command-L), or Dark (Command-D) theme; Desktop (Command-T), White (Command-W), or Black (Command-B) backdrop; Accent Color Comparison (Command-A). Theme and backdrop are independent. |
| Placement | Center (Command-0), Above Anchor (Command-5), Left of Composition (Command-6), Right of Composition (Command-7), and Hide Guides (Command-8). |

Use arrow keys, Page Up/Down, Home/End, and Tab/Shift-Tab to navigate. Ordinary
samples support selection keys and Return to confirm; action samples use the
Shift combinations displayed beside their candidates. The terminal prints
highlight and confirmation events. Quit the preview with Command-Q.

In expanded layouts, Page Down advances one row horizontally or one column
vertically, and Page Up moves back one row or column. These keys match the host
page actions and accessibility page actions rather than jumping a full viewport.
Home and End select the first and last candidates in the current row or column.
Tab and Shift-Tab move through candidates and wrap at either end of the list.
The input method uses the same navigation rules for modern candidate windows.

### Run tests

Run the complete package test suite:

```sh
swift test --package-path Packages/CandidateKit
```

Use `--filter` to run a specific test class, for example:

```sh
swift test --package-path Packages/CandidateKit --filter VerticalExpansionTests
swift test --package-path Packages/CandidateKit --filter CandidateAccessibilityTests
swift test --package-path Packages/CandidateKit --filter CandidatePlacementTests
```

## License

CandidateKit is released under the MIT license. The full license text appears
in the library source file headers.
