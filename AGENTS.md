# AGENTS.md

McBopomofo (小麥注音輸入法) is a Traditional Chinese Bopomofo input method for macOS. Built with Swift (UI/state), Objective-C++ (bridge), and C++ (engine), using Input Method Kit (IMK).

## Build Commands

### Xcode (Recommended)
Open `McBopomofo.xcodeproj`, select **McBopomofoInstaller** scheme, Build: ⌘+B, Run: ⌘+R

### Command Line
```bash
xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoInstaller -configuration Debug build
xcodebuild -project McBopomofo.xcodeproj -target McBopomofo -configuration Debug build
```

### Release Build
```bash
xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoInstaller -configuration Release build
```

## Lint & Format
```bash
swift format -i --configuration .swift-format Source/**/*.swift
swift format --check --configuration .swift-format Source/**/*.swift
```

Config (`.swift-format`): line length 100, 4-space indent, max 1 blank line

## Testing

### Swift Tests
```bash
# Run all
xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoTests -configuration Debug test

# Single test method
xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoTests -configuration Debug test -only-testing:McBopomofoTests/PreferencesTests/testKeyboardLayout

# Single test class
xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoTests -configuration Debug test -only-testing:McBopomofoTests/PreferencesTests
```

### C++ Tests
```bash
cd Source/Engine && mkdir -p build && cd build
cmake -DENABLE_TEST=ON .. && make && ctest
./McBopomofoLMLibTest --gtest_filter=TestName  # Single test
```

## Code Style

### General
- **Never use emoji** in code (except `Source/Data/`)
- **Language:** English or Traditional Chinese only (no Simplified Chinese)
- **License:** Include MIT header on new files

### Swift: Imports
```swift
import Cocoa          // System first
import Foundation
import InputMethodKit
@testable import McBopomofo  // Test last
```

### Swift: Types & Naming
```swift
@objc var candidateCount: Int { get }  // Explicit types for properties
private let kKeyboardLayoutKey = "KeyboardLayout"  // k prefix for private keys

// PascalCase: InputState, KeyHandler
// camelCase: composingBuffer, candidateCount
// Enum cases: lowercase (case standard, case eten)
```

### Swift: Error Handling
```swift
guard let data = loadData() else { return defaultValue }

do {
    try performRiskyOperation()
} catch {
    logError("Failed: \(error)")
}
```

### Objective-C++ Bridge
- Use `UTF8Helper`/`NSStringUtils` for string conversion (never manual)
- Manage C++ lifetimes with `std::shared_ptr` in `init`/`dealloc`
- Keep methods small: forward to engine, return Foundation types

### C++ Engine
- C++17: use `std::vector`, `std::unordered_map`, `std::optional`
- Namespaces: `McBopomofo`, `Formosa::Gramambular2`, `Formosa::Mandarin`
- Keep algorithms deterministic and side-effect free

### State Machine
- Treat `InputState` subclasses as immutable; create new state on transition
- Extend by adding new states, not booleans

## Architecture

### Key Components
| Layer | Files | Purpose |
|-------|-------|---------|
| UI | `InputMethodController.swift` | IMK entry point |
| State | `InputState.swift` | State machine |
| Bridge | `KeyHandler.mm` | ObjC++ bridge |
| Engine | `McBopomofoLM.cpp` | Language model |
| Mandarin | `Mandarin.cpp` | Bopomofo syllable handling |

### Fuzzy Pinyin (近似音)
Implemented in language model (`McBopomofoLM.cpp`) and syllable layer (`Mandarin.cpp`).

**Supported Fuzzy Pairs:**
| Type | Pairs |
|------|-------|
| Consonant | ㄅ↔ㄆ, ㄍ↔ㄎ, ㄐ↔ㄑ, ㄓ↔ㄗ, ㄔ↔ㄘ, ㄕ↔ㄙ |
| Vowel | ㄛ↔ㄜ, ㄣ↔ㄥ |
| Tone | 一聲↔二聲↔三聲 |

**Key methods:** `BopomofoSyllable::fuzzyVariants()`, `McBopomofoLM::getFuzzyVariantReadings()`, `McBopomofoLM::getUnigrams()`. Skip special readings (starting with `_`).

## Preferences

Add new preferences in `Source/Preferences.swift`:
```swift
private let kNewFeatureKey = "NewFeatureKey"

@UserDefault(key: kNewFeatureKey, defaultValue: false)
@objc static var newFeatureEnabled: Bool
```

Update `allKeys` array for preference synchronization.

## Dictionary Data
```bash
cd Source/Data
make tidy sort check all    # Recommended workflow
make all                    # Generate data.txt, data-plain-bpmf.txt
```

Critical: `BPMFMappings.txt` and `phrase.occ` must be sorted with C locale:
```bash
LC_ALL=C sort -o BPMFMappings.txt BPMFMappings.txt
LC_ALL=C sort -o phrase.occ phrase.occ
```

## Local Packages
`Packages/` contains Swift Package dependencies: `CandidateUI`, `NSStringUtils`, `OpenCCBridge`, `SystemCharacterInfo`

## Things to Avoid
- Don't replace AppKit with SwiftUI (runtime depends on NSWindow/XIB)
- Don't bypass Objective-C++ bridge to access engine directly
- Don't hardcode user data paths; use preference APIs
- Don't apply fuzzy matching to special readings (starting with `_`)

## Reference Files

| File | Purpose |
|------|---------|
| `Source/InputMethodController.swift` | IMK entry point |
| `Source/InputState.swift` | State machine |
| `Source/KeyHandler.mm` | ObjC++ bridge |
| `Source/Preferences.swift` | User preferences |
| `Source/Engine/McBopomofoLM.cpp` | Language model, fuzzy matching |
| `Source/Engine/Mandarin/Mandarin.cpp` | Syllable handling, fuzzy variants |
