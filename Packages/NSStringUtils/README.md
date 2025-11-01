# NSStringUtils

Copyright (c) 2022 and onwards The McBopomofo Authors.

NSStringUtils extends `NSString` with helpers that make it easier to work with
Swift strings while still interoperating with legacy Cocoa APIs. The extensions
normalize UTF-16 indices so you can move between `NSString` offsets and Swift
grapheme clusters without accidentally splitting composed characters.

## Requirements

- macOS 10.15 or later
- Swift 5.9 or later
- Link against AppKit/Foundation (no additional dependencies)

## Key Extensions

- `characterIndex(from:)` converts a UTF-16 offset (as used by `NSString`) into
  the equivalent Swift `String` character index and returns the bridged string.
- `nextUtf16Position(for:)` and `previousUtf16Position(for:)` advance or retreat
  by one user-perceived character while staying aligned with UTF-16 code units.
- `count` exposes the Swift character count on `NSString` instances.
- `split()` returns an array of single-character `NSString` values, respecting
  composed scalars.

## Usage Example

```swift
import NSStringUtils

let nsString: NSString = "漢字"
let next = nsString.nextUtf16Position(for: 0) // 2: skips the entire first character
let previous = nsString.previousUtf16Position(for: next) // 0
let pieces = nsString.split() // ["漢", "字"] as NSString instances
```

## Integration Tips

- Use these helpers when bridging between Objective-C APIs (which index strings
  by UTF-16) and Swift code that expects character-based indices.
- Always work on the main thread if you are coordinating text input or UI
  updates alongside these helpers.
- The methods allocate intermediate Swift strings internally; reuse results if
  you need to inspect multiple indices within the same string.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
