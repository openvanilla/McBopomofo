# InputSourceHelper

Copyright (c) 2022 and onwards The McBopomofo Authors.

InputSourceHelper wraps the Carbon Text Input Source (TIS) APIs in a small Swift
utility so you can enumerate, enable, and disable keyboard input sources without
dropping into Core Foundation manually. It is used by McBopomofo to ensure its
input method bundle is registered and all input modes are enabled.

## Requirements

- macOS 10.15 or later (relies on Carbon TIS)
- Swift 5.9 or later
- App must link against `Carbon.framework`

## Key Capabilities

- `allInstalledInputSources()` returns every `TISInputSource` currently visible
  to the system.
- `inputSource(for: stringValue:)` locates an input source by any TIS property
  key (such as `kTISPropertyBundleID`).
- `enable(inputSource:)` and `disable(inputSource:)` toggle a specific source.
- `enableAllInputMode(for:)` and `enable(inputMode:for:)` activate every mode,
  or a single mode, bundled with the specified input method.
- `registerInputSource(at:)` wraps `TISRegisterInputSource` for installing
  bundles at runtime (requires user approval on modern macOS).

## Usage

```swift
import InputSourceHelper

let bundleID = "com.openvanilla.McBopomofo.McBopomofoIMK"

if InputSourceHelper.enableAllInputMode(for: bundleID) {
    print("All input modes are now enabled.")
} else {
    print("At least one mode could not be enabled.")
}

if let source = InputSourceHelper.inputSource(for: kTISPropertyInputSourceID, stringValue: bundleID) {
    _ = InputSourceHelper.enable(inputSource: source)
}
```

## Integration Tips

- The helper returns raw `TISInputSource` references. Cast properties using
  `Unmanaged` APIs if you need additional metadata.
- Wrap enable/disable calls in error handling; macOS may decline changes without
  proper permissions or user approval.
- Always run these APIs on the main thread when interacting with AppKit text
  input subsystems.
- Avoid shipping debug `print` output in production code; replace it with your
  project's logging facility if needed.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
