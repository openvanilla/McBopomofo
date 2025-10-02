# McBopomofo Copilot Instructions

## Project Context
- Input method for macOS built with AppKit/IMKit in Swift and bridged Objective-C++, backed by the C++ language model in `Source/Engine`.
- Build and run with Xcode target `McBopomofo Installer`; Swift front end pulls helper frameworks from the local `Packages/` directory.
- Dictionary assets and generation scripts live in `Source/Data`; compiled blobs are stored in `Source/Data/bin`.
- Tests cover both layers: Swift XCTest-style suites in `McBopomofoTests` and GoogleTest cases in `Source/Engine/*Test.cpp` via CMake.
- Preserve the existing MIT license banner on any new source file.

## Swift & AppKit Guidelines
- Keep AppKit and IMKit work in Swift classes (`InputMethodController`, `PreferencesWindowController`, etc.) and limit scope with `private`/`fileprivate` helpers.
- Use the `Preferences` static properties and property wrappers in `Source/Preferences.swift` instead of accessing `UserDefaults` directly; add new keys beside the existing constants.
- Localize UI strings through `NSLocalizedString("…", comment: "")` and update the `.strings` files under `Base.lproj`, `en.lproj`, and `zh-Hant.lproj` when text changes.
- Follow the established flow: `InputMethodController` drives menu actions, `KeyHandler` mediates IM events, and `InputState` models state transitions.
- Perform UI work on the main thread; reuse existing helper methods or notifications rather than introducing ad-hoc dispatch queues.
- Interact with the engine through `KeyHandler`/`LanguageModelManager` bridges instead of duplicating C++ logic in Swift.

## State Machine Design
- Treat `InputState` subclasses as immutable snapshots; always create a new state object when the IM transitions instead of mutating existing instances.
- Funnel key handling through `KeyHandler` so state transitions originate from one place and UI updates flow from the current state.
- Keep UI and engine in sync by deriving candidate lists, composing buffers, and menu options from the state object rather than scattered flags.
- Extend the state machine by adding new `InputState` subclasses plus explicit transitions; avoid adding booleans that bypass the existing states.

## Objective-C++ Bridge Guidelines
- Manage engine lifetimes in `.mm` files by allocating in `init`, cleaning up in `dealloc`, and wrapping pointers in `std::shared_ptr` when passing to C++ APIs.
- Surface new engine capabilities by extending bridge classes (`KeyHandler`, `LanguageModelManager`) and declaring them in `McBopomofo-Bridging-Header.h`.
- Convert between `NSString` and `std::string` with `UTF8Helper`/`NSStringUtils`; avoid hand-written UTF conversions or raw buffers.
- Keep bridge methods small: forward inputs to the engine and return plain values or Foundation types that Swift can consume.

## C++ Engine Guidelines
- Stick to the existing C++17 style that uses `std::vector`, `std::unordered_map`, `std::optional`, and `std::string_view` as in `McBopomofoLM.cpp`.
- Place new engine code inside the current namespaces (`McBopomofo`, `Formosa::Gramambular2`, `Formosa::Mandarin`) and reuse helper classes from `gramambular2`.
- Reuse the blob readers (`KeyValueBlobReader`, `ParselessPhraseDB`, `PhraseReplacementMap`) when touching serialized resources; prefer augmenting them over inventing new formats.
- Keep algorithms deterministic and side-effect free; logging and macOS-specific behavior should stay in the Objective-C++ layer.

## Tests and Tooling
- Add Swift tests under `McBopomofoTests` using the `Testing` module with `@Suite`, `@Test`, and `#expect` macros; snapshot and restore `UserDefaults` like `PreferencesTests`.
- Register new engine tests in `Source/Engine/CMakeLists.txt`, include them in the `McBopomofoLMLibTest` target, and use GoogleTest assertions.
- When dictionary data changes, regenerate artifacts via the make targets in `Source/Data` and check updated binaries into `Source/Data/bin`.
- Keep shell scripts such as `Source/add-phrase-hook.sh` POSIX-compliant and aligned with the existing shebang and style.

## Things to Avoid
- Avoid replacing AppKit windows with SwiftUI or Combine; the runtime depends on NSWindow/XIB assets.
- Do not bypass the bridge to talk to the engine directly from Swift; IMKit lifecycle assumptions require the Objective-C++ layer.
- Refrain from hardcoding paths to user data; use the preference APIs and helper lookups.
- Keep large dictionary blobs or generated files untouched unless the change specifically targets them.

## Reference Files
- `Source/InputMethodController.swift`: IMK entry point coordinating candidate menus and preferences.
- `Source/KeyHandler.mm`: Objective-C++ bridge between Swift events and the engine.
- `Source/Engine/McBopomofoLM.cpp`: Core language model logic and unigram handling.
- `McBopomofoTests/PreferencesTests.swift`: Example of the Swift `Testing` suite setup and patterns.
- `Source/Engine/CMakeLists.txt`: Engine build configuration and test registration.



Note: https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions#creating-path-specific-custom-instructions-1