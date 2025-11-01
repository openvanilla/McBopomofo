# TooltipUI

Copyright (c) 2022 and onwards The McBopomofo Authors.

TooltipUI presents a non-activating tooltip window on macOS. McBopomofo uses it
to explain candidate window actions and display quick hints while keeping the
input method focused.

## Requirements

- macOS 10.15 or later
- Swift 5.9 or later
- Link against AppKit (uses `NSPanel`, `NSTextField`, and screen positioning
  helpers)

## Features

- Shows a borderless, non-activating panel that floats above normal windows.
- Automatically resizes to fit the provided text while keeping padding around
  the content.
- Positions the tooltip near a requested top-left point and clamps it to the
  visible screen region.
- Offers `@objc` selectors so Objective-C callers can show or hide the tooltip.

## Usage

```swift
import TooltipUI

let tooltip = TooltipController()
tooltip.show(tooltip: "按下 ⌘ 空白 可以切換輸入法", at: NSEvent.mouseLocation)

DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    tooltip.hide()
}
```

Objective-C integration looks similar:

```objectivec
@import TooltipUI;

TooltipController *tooltip = [[TooltipController alloc] init];
[tooltip showTooltip:@"Press ⌘ Space" atPoint:[NSEvent mouseLocation]];
```

## Integration Tips

- Create and interact with the controller on the main thread; AppKit windows are
  not thread-safe.
- Keep a strong reference to the controller for as long as the tooltip should
  stay visible.
- Provide succinct messages; the controller expands the window to fit the text
  but keeps a modest maximum width.
- The tooltip panel is non-activating, so it will not steal focus from the
  current application.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
