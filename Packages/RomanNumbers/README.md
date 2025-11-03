# RomanNumbers

Copyright (c) 2022 and onwards The McBopomofo Authors.

RomanNumbers converts decimal integers into Roman numerals and exposes the API
to both Swift and Objective-C callers. It powers McBopomofo features that
present formatted numerals inside the candidate window and user preferences.

## Requirements

- macOS 10.15 or later
- Swift 5.9 or later
- No external dependencies (Foundation only)

## Features

- Accepts `Int` and decimal `String` inputs via convenience overloads.
- Supports three presentation styles through `RomanNumbersStyle`: `alphabets`,
  `fullWidthUpper` (U+2160 block), and `fullWidthLower` (U+2170 block).
- Handles canonical ligatures for 11 and 12 in the full-width styles (`Ⅺ`, `Ⅻ`, `ⅺ`, `ⅻ`).
- Throws typed `RomanNumbersErrors` (`tooLarge`, `tooSmall`, `invalidInput`) with localized descriptions suitable for UI.
- Annotated with `@objc` so the converter is callable from Objective-C or Swift/Objective-C mixed targets.

## Usage

```swift
import RomanNumbers

let value = 2025
let classic = try RomanNumbers.convert(input: value)            // "MMXXV"
let fullUpper = try RomanNumbers.convert(input: value, style: .fullWidthUpper)
let fromText = try RomanNumbers.convert(string: "3999", style: .fullWidthLower)
```

Objective-C callers can interact with the same API:

```objectivec
@import RomanNumbers;

NSError *error = nil;
NSString *roman = [RomanNumbers convertWithInt:2025 style:RomanNumbersStyleAlphabets error:&error];
```

## Error Handling

Wrap conversions in `do { try ... } catch` (Swift) or check the `NSError`
pointer (Objective-C). The helper enforces the inclusive range 0…3999 and
validates that string input is numeric.

## Testing

Run the package tests locally with:

```bash
swift test --package-path Packages/RomanNumbers
```

The suite covers every style, the special-case ligatures, and boundary values.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
