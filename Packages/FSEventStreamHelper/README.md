# FSEventStreamHelper

Copyright (c) 2022 and onwards The McBopomofo Authors.

FSEventStreamHelper is a tiny macOS utility that wraps Core Services
FSEventStream APIs with a Swift-friendly delegate interface. It watches a single
path for file-system changes and forwards normalized event metadata to your
delegate on the dispatch queue you provide.

## Requirements

- macOS 10.15 or later (relies on `FSEventStream`)
- Swift 5.9 or later
- A serial `DispatchQueue` for event delivery (you provide it when creating the
  helper)

## Usage

```swift
import FSEventStreamHelper

final class DirectoryWatcher: FSEventStreamHelperDelegate {
    private let helper: FSEventStreamHelper

    init(path: String, queue: DispatchQueue = .main) {
        helper = FSEventStreamHelper(path: path, queue: queue)
        helper.delegate = self
        _ = helper.start()
    }

    func helper(_ helper: FSEventStreamHelper, didReceive events: [FSEventStreamHelper.Event]) {
        for event in events {
            print("Changed", event.path, event.flags, event.id)
        }
    }

    deinit {
        helper.stop()
    }
}
```

### Event Details

Each `Event` includes:

- `path`: Absolute path that changed
- `flags`: Raw `FSEventStreamEventFlags` for the change
- `id`: Monotonic `FSEventStreamEventId` supplied by Core Services

Call `start()` to begin watching and `stop()` to tear the stream down. `start()` returns `false` if the helper is already running or if the stream could not be created.

## Integration Tips

- Only one `FSEventStreamHelper` instance can watch a path at a time. Create
  additional helpers for other directories.
- Always balance `start()` with `stop()` (e.g., in `deinit`) to avoid leaking
  the underlying stream.
- The path argument must exist when `start()` runs. Create it ahead of time when
  watching temporary directories.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
