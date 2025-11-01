# BopomofoBraille

Copyright (c) 2022 and onwards The McBopomofo Authors.

BopomofoBraille is a Swift package that converts between Taiwanese Bopomofo (注
音符號) and Taiwanese Braille (臺灣點字). It powers the Braille typing feature
in McBopomofo’s Service menu and can also be embedded in standalone projects
that need to translate between these two writing systems.

## Installation

Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(path: "../Packages/BopomofoBraille"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["BopomofoBraille"]
    ),
]
```

When using the package outside of the McBopomofo repository, replace the local
path with the corresponding Git URL and version requirement.

## Usage

The primary entry point is `BopomofoBrailleConverter`. It exposes two static
conversion methods:

```swift
let bpmf = "ㄓㄨㄥㄨㄣˊㄓㄨˋㄧㄣ"
let braille = BopomofoBrailleConverter.convert(bopomofo: bpmf)

let roundTrip = BopomofoBrailleConverter.convert(braille: braille)
// roundTrip == bpmf
```

Both conversions preserve whitespace, punctuation, Latin letters, and digits
according to the Taiwanese Braille standard. Invalid syllables fall back to
spacing rules so that mixed-content strings remain legible.

### Working With Individual Syllables

`BopomofoSyllable` provides validation and direct access to the Braille for a
single syllable:

```swift
let syllable = try BopomofoSyllable(rawValue: "ㄉㄧˋ")
print(syllable.braille) // ⠙⠡⠐

let reversed = try BopomofoSyllable(braille: "⠋⠪⠂")
print(reversed.rawValue) // ㄊㄧㄠˊ
```

Specialised token types such as `Letter`, `Digit`, and punctuation helpers are
exposed for callers that need finer control over parsing.

## Testing

Run the package test suite with:

```bash
swift test --package-path Packages/BopomofoBraille
```

The tests cover round-trip conversion, syllable validation, and edge cases for
Latin letters, digits, and punctuation.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
