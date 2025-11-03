# InfoCollector

Copyright (c) 2022 and onwards The McBopomofo Authors.

InfoCollector is a Swift package that gathers diagnostic information about the
current macOS environment. McBopomofo uses it to build human-readable reports
when helping users troubleshoot issues, and it can be embedded in other tools
that need the same style of snapshot.

## Features

- Collects data asynchronously on the main actor and returns a single plain-text
  report
- Plugin architecture (`InfoCollectorPlugin`) that lets you add or swap data
  sources without changing the core API
- Ready-made collectors for hardware, language, and input-related settings:
  - Machine model, CPU, memory size, and clock speed
  - macOS version
  - Preferred languages, locale, and regional metadata
  - Attached keyboards reported by IOKit (vendor/product identifiers, transport, location)
  - Enabled input sources from HIToolbox
  - Default web browser via Launch Services
  - Installed Safari version
  - Host app version/build (reads the main bundle)

## Requirements

- Swift 5.9 or newer
- macOS 10.15 or newer (uses AppKit, Carbon/HIToolbox, and IOKit APIs that are
  unavailable on other platforms)

## Usage

### Async/Await

```swift
import InfoCollector

@MainActor
func printReport() async {
    let report = await InfoCollector.generate()
    print(report)
}
```

### Callback-based

```swift
import InfoCollector

InfoCollector.generate { report in
    print(report)
}
```

Both entry points schedule each plugin concurrently and concatenate their
results into a single newline-separated string.

## Extending with Custom Plugins

```swift
struct DiskSpaceCollector: InfoCollectorPlugin {
    let name = "Disk space collector"

    func collect(callback: @escaping (Result<String, Error>) -> Void) {
        let available = /* compute available disk space */
        callback(.success("- Free Disk: \(available)"))
    }
}
```

Register custom plugins by creating your own array and invoking them before or
after calling the built-ins.

## Testing

Run the package tests with:

```bash
swift test
```

Tests require macOS because they exercise AppKit and IOKit-backed collectors.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
