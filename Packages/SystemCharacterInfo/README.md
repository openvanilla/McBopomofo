# SystemCharacterInfo

Copyright (c) 2022 and onwards The McBopomofo Authors.

SystemCharacterInfo reads character decomposition data from the macOS private
CoreChineseEngine database. McBopomofo uses it to expose radical and exemplar
information for Traditional Chinese characters inside the user interface.

## Requirements

- macOS 10.15 or later (must include
  `/System/Library/PrivateFrameworks/CoreChineseEngine.framework`)
- Swift 5.9 or later
- Links against `SQLite.swift` (declared in `Package.swift`)
- The host process must have read access to `CharacterAccessibilityData.sqlite`

## Data Source

The package opens the system database located at:

```
/System/Library/PrivateFrameworks/CoreChineseEngine.framework/Versions/A/Resources/CharacterAccessibilityData.sqlite
```

This file is owned by macOS and ships read-only. The helper does not bundle its
own copy, so it will throw an error if the database is missing (for example on
non-macOS platforms).

## API Overview

- `SystemCharacterInfo()` creates a connection to the database (throws if the
  file cannot be opened).
- `read(string:)` looks up a single character and returns a `CharacterInfo`
  struct with:
  - `character`: The canonical character stored in the database
  - `components`: Decomposition data (e.g. radicals or phonetic components)
  - `simplifiedExample` / `traditionalExample`: Example characters when provided
    by Apple
- Throws `SystemCharacterInfoError.notFound` when there is no matching entry.

## Usage

```swift
import SystemCharacterInfo

let service = try SystemCharacterInfo()
let info = try service.read(string: "燈")
print(info.components ?? "") // "火登"
```

Wrap calls in `do`/`catch` to handle missing rows or database access errors:

```swift
 do {
     let info = try service.read(string: "𠮷")
     // use info
 } catch SystemCharacterInfoError.notFound {
     // character is not in the database
 } catch {
     // database could not be opened or another SQLite error occurred
 }
```

## Testing

Unit tests expect the system database to exist, so run them on a macOS host with
CoreChineseEngine available:

```bash
swift test --package-path Packages/SystemCharacterInfo
```

## Privacy & Distribution Notes

- The package reads data from a macOS private framework; review App Store
  guidelines before shipping this functionality to the Mac App Store.
- Do not modify the system database. The helper opens it read-only and caches no
  data.

## License

This package is released under the MIT license. See the header comments in the
source files for the full text.
