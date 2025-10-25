# RomanNumbers

RomanNumbers is a Swift package that converts decimal numbers into Roman
numerals. It powers parts of the McBopomofo input method project where formatted
Roman numerals are needed in Swift and Objective-C contexts.

## Features

- Supports integer values from 0 through 3999
- Offers three output styles via `RomanNumbersStyle`: `alphabets`,
  `fullWidthUpper` (Unicode U+2160–U+216F), and `fullWidthLower` (Unicode
  U+2170–U+217F)
- Accepts either `Int` input or decimal text strings
- Throws descriptive errors (`RomanNumbersErrors`) when the source value is out of range or invalid
- Marked with `@objc` so the conversion APIs are reachable from Objective-C code

## Installation

Add RomanNumbers to the `dependencies` section of your `Package.swift`:

```swift
.dependencies([
    .package(path: "Packages/RomanNumbers")
])
```

Then link the library from a target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RomanNumbers", package: "RomanNumbers")
    ]
)
```

If you vend the package from another repository, replace the `.package` path
with the appropriate `.package(url: "...", from: "...")` declaration.

## Usage

```swift
import RomanNumbers

let number = 2025
let standard = try RomanNumbers.convert(input: number)
let upperFullWidth = try RomanNumbers.convert(input: number, style: .fullWidthUpper)
let lowerFromText = try RomanNumbers.convert(string: "3999", style: .fullWidthLower)

print(standard)        // "MMXXV"
print(upperFullWidth)  // Unicode Roman numeral letters in the U+2160 block
print(lowerFromText)   // Unicode Roman numeral letters in the U+2170 block
```

## Error Handling

`RomanNumbers.convert` throws values of `RomanNumbersErrors`:

- `tooLarge`: the input exceeds 3999
- `tooSmall`: the input is negative
- `invalidInput`: the string argument cannot be parsed as an integer

These errors conform to `LocalizedError`, providing human-readable descriptions
suitable for UI presentation.

## Testing

Run the package tests with:

```bash
swift test
```

The suite exercises every conversion style and covers edge cases for the
supported numeric range.

## License

RomanNumbers ships as part of McBopomofo. Refer to the repository's root
`LICENSE` file for licensing terms.
