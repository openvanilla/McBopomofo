# ChineseNumbers

Copyright (c) 2022 and onwards The McBopomofo Authors.

ChineseNumbers converts decimal numbers into Traditional Chinese numeral
strings. It ships with the McBopomofo input method project and exposes `@objc`
entry points so the same conversion logic works in Swift and Objective-C
codebases.

## Features

- Formats integer and decimal sections using lowercase (如「一二三」) or
  uppercase (如「壹貳參」) digits via `ChineseNumbers.Case`
- Supports large magnitudes through `載` by chunking the input into four-digit
  sections (萬、億、兆、京…)
- Emits the `點` separator for fractional values and preserves significant
  trailing digits
- Provides the `SuzhouNumbers` helper for 蘇州碼 output, including unit labels
  and vertical digit preferences
- Includes string utilities for trimming/padding zeros so callers can feed
  pre-validated numeric text
- Fully accessible from Objective-C thanks to `@objc` annotations and `NSObject`
  inheritance

## Installation

Add ChineseNumbers to the `dependencies` section of your `Package.swift`:

```swift
.dependencies([
    .package(path: "Packages/ChineseNumbers")
])
```

Then link the library from a target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ChineseNumbers", package: "ChineseNumbers")
    ]
)
```

If you vend the package from another repository, replace the `.package` path
with the appropriate `.package(url: "…", from: "…")` declaration.

## Usage

```swift
import ChineseNumbers

let integerPart = "1234567890"
let decimalPart = "050"

let lowercase = ChineseNumbers.generate(
    intPart: integerPart,
    decPart: decimalPart,
    digitCase: .lowercase
) // "一十二億三千四百五十六萬七千八百九十點〇五"

let uppercase = ChineseNumbers.generate(
    intPart: integerPart,
    decPart: decimalPart,
    digitCase: .uppercase
) // "壹拾貳億參仟肆佰伍拾陸萬柒仟捌佰玖拾點零伍"

let suzhou = SuzhouNumbers.generate(
    intPart: "123",
    decPart: "40",
    unit: "元",
    preferInitialVertical: true
)
/*
〡二〣〤
百元
*/
```

`ChineseNumbers.generate` expects pre-separated integer and decimal strings so
you can source them from text fields without lossy floating-point conversion.
`SuzhouNumbers.generate` alternates between vertical digits (〡〢〣) and
horizontal strokes (一二三) based on the `preferInitialVertical` flag and
appends the appropriate place name when multiple characters are produced.

## Testing

Run the package tests with:

```bash
swift test
```

The XCTest suite covers zero trimming, lowercase/uppercase conversions,
fractional rendering, and Suzhou numeral generation.

## License

This package is released under the MIT license. The full text is available in
the source file headers.
