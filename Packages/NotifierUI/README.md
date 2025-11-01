# NotifierUI

Copyright (c) 2022 and onwards The McBopomofo Authors.

NotifierUI provides a lightweight popover-style notification window for macOS
apps. It is used by McBopomofo to display short status messages (such as
input-source changes) without relying on Notification Center.

## Requirements

- macOS 10.15 or later
- Swift 5.9 or later
- Link against AppKit (uses `NSWindowController`, `NSTextField`, and timers)

## Features

- Presents a borderless, shadowed window that animates into view near the
  top-right corner.
- Automatically stacks multiple notifications by tracking the last onscreen position.
- Supports configurable dwell time; pass `stay: true` to keep the message
  visible longer before fading.
- Fades out smoothly and dismisses early when the user clicks the window.
- Exposes a single `NotifierController.notify(message:stay:)` entry point so
  callers stay on the main thread.

## Usage

```swift
import NotifierUI

NotifierController.notify(message: "Input source refreshed")
NotifierController.notify(message: "Dictionary updated", stay: true)
```

The controller creates its own window and timers, so you do not need to manage
lifetimes manually. Each call runs on the main thread; dispatch from background
queues if needed.

## Integration Tips

- Ensure calls occur on the main thread because AppKit window operations are not
  thread-safe.
- Provide succinct messages; the window width is fixed at 160pt and text wraps vertically.
- Avoid reusing the controller instance; `NotifierController.notify` constructs
  a fresh controller per call and handles stacking automatically.

## License

NotifierUI ships under the MIT license. Refer to the repository root `LICENSE` file for full terms.
