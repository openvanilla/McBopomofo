# CandidateUI

Copyright (c) 2022 and onwards The McBopomofo Authors.

CandidateUI provides the Cocoa candidate window implementation shared by the
McBopomofo input method targets. It bundles a base `CandidateController` with
ready-to-use horizontal and vertical variants that expose an Objective-C
compatible delegate API, making it easy to embed the UI in IMK and AppKit based
projects.

## Features

- Horizontal and vertical `NSWindowController` subclasses ready for IMK/AppKit
  hosts
- Delegate driven data source with optional readings and explanations
- Configurable key labels, candidate fonts, tooltip text, and accessibility
  notifications
- Built-in pagination and highlight navigation helpers for keyboard control
- Objective-C bridging annotations for seamless use from mixed Swift/ObjC code

## Requirements

- macOS 10.15 or later (AppKit based host process)
- Swift 5.9 or newer (Xcode 15.3 or newer)
- Interactions must occur on the main queue because the window is UI backed

## Installation

Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../Packages/CandidateUI"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["CandidateUI"]
    ),
]
```

When integrating outside the McBopomofo repository, replace the local path with
the corresponding Git URL and version requirement.

## Usage

Choose either `HorizontalCandidateController` or `VerticalCandidateController`
depending on the layout you want.

### 1. Implement the delegate

Adopt `CandidateControllerDelegate` to expose candidates, optional readings,
and selection callbacks:

```swift
@MainActor
final class DemoDelegate: NSObject, CandidateControllerDelegate {
    private let entries = ["ZhuYin", "Input Method", "McBopomofo"]
    private let readings = ["zhu4", "shu1", "mai4"]

    func candidateCountForController(_ controller: CandidateController) -> UInt {
        UInt(entries.count)
    }

    func candidateController(_ controller: CandidateController, candidateAtIndex index: UInt) -> String {
        entries[Int(index)]
    }

    func candidateController(_ controller: CandidateController, readingAtIndex index: UInt) -> String? {
        readings[Int(index)]
    }

    func candidateController(
        _ controller: CandidateController,
        requestExplanationFor candidate: String,
        reading: String
    ) -> String? {
        nil
    }

    func candidateController(_ controller: CandidateController, didSelectCandidateAtIndex index: UInt) {
        print("Selected candidate: \(entries[Int(index)])")
    }
}
```

### 2. Configure the controller

Instantiate the controller on the main thread, assign the delegate, and adjust
appearance hints. Call `reloadData()` after mutating underlying candidate data.

```swift
let controller = VerticalCandidateController()
controller.delegate = DemoDelegate()
controller.keyLabels = ["1", "2", "3"].map { CandidateKeyLabel(key: $0, displayedText: $0) }
controller.keyLabelFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
controller.candidateFont = NSFont.systemFont(ofSize: 18)
controller.tooltip = NSLocalizedString("Press arrow keys to browse candidates", comment: "Candidate window tooltip")
controller.set(windowTopLeftPoint: NSPoint(x: 320, y: 400), bottomOutOfScreenAdjustmentHeight: 24)
controller.visible = true
```

`set(windowTopLeftPoint:bottomOutOfScreenAdjustmentHeight:)` keeps the window
visible by nudging it back on screen when it would otherwise cross a screen
edge.

### 3. React to keyboard events

Use the navigation helpers to mirror the IMK key handling semantics:

```swift
@discardableResult
func handleCandidateNavigation(event: NSEvent, controller: CandidateController) -> Bool {
    guard let specialKey = event.specialKey else { return false }
    switch specialKey {
    case .rightArrow: return controller.showNextPage()
    case .leftArrow: return controller.showPreviousPage()
    case .downArrow: return controller.highlightNextCandidate()
    case .upArrow: return controller.highlightPreviousCandidate()
    default: return false
    }
}
```

For number keys, call `candidateIndexAtKeyLabelIndex(_:)` to translate the
pressed label into a candidate index (`UInt.max` signals “not available”). When
a new selection is confirmed, invoke the delegate’s
`candidateController(_:didSelectCandidateAtIndex:)` method to commit the choice
back to your input pipeline.

### Objective-C integration

All public controllers and protocols are annotated with `@objc`. Import the
generated umbrella header (for example through `McBopomofo-Bridging-Header.h`)
to drive the UI from Objective-C or Objective-C++ sources.

## Testing

Run the package tests with:

```bash
swift test --package-path Packages/CandidateUI
```

The test suite covers pagination, selection handling, and layout options for
both horizontal and vertical controllers.

## License

This package is released under the MIT license. The full text is available in
the source file headers.
