<!-- Also symlinked as CLAUDE.md -->
# AGENTS.md

This file provides guidance to AI coding assistants when working with code in this repository.

<metadata>

- **Scope**: McBopomofo development (Swift/ObjC++/C++)
- **Load if**: Working on McBopomofo codebase
- **Related**: `Source/Data/AGENTS.md`, `algorithm.md`

</metadata>

## CRITICAL (Primacy Zone)

<required>

**Before editing any file**:
1. Verify branch: `git branch --show-current`
2. Verify worktree: `pwd`
3. Read current master: `git show master:<file>`

**When adding C++ source files**: Update BOTH
`Source/Engine/CMakeLists.txt` AND
`McBopomofo.xcodeproj/project.pbxproj` — verify Xcode
build locally before PR.

**C++ standard**: C++17 only. No C++20/C++23 features.

**Always**: Conventional Commits, no emoji, English or
Traditional Chinese only.

</required>

## Project Overview

McBopomofo (小麥注音輸入法) is a Traditional Chinese input method engine for macOS that enables users to input Traditional Chinese characters using the Bopomofo phonetic system (注音符號). The project is built with Swift (UI/state management), Objective-C++ (bridge layer), and C++ (core engine), using macOS Input Method Kit (IMK) framework.

<context>

## System Requirements

**Runtime:** macOS 11.0 (Big Sur) or later

**Development:**
- macOS 14.7 or later
- Xcode 15.3 or later
- Python 3.9 (for dictionary data generation)

</context>

## Building and Running

### Xcode Project Structure

The project contains these main **targets**:
- `McBopomofo`: Main input method bundle
- `McBopomofoInstaller`: Installer app (recommended for development)
- `Data`: Dictionary data generation
- `McBopomofoTests`: Swift test suite

**Build configurations:** Debug, Release (default when building from command line)

**Available schemes:** McBopomofo, McBopomofoInstaller, Data, plus individual schemes for local packages (BopomofoBraille, CandidateUI, ChineseNumbers, FSEventStreamHelper, InputSourceHelper, NotifierUI, NSStringUtils, OpenCCBridge, SystemCharacterInfo, TooltipUI)

### Primary Development Workflow

1. Open `McBopomofo.xcodeproj` in Xcode
2. Select the **"McBopomofoInstaller"** target
3. Build and run to install McBopomofo
4. The installer automatically kills and restarts the input method process

**Important:** macOS limits how many times an input method process can be killed in a single login session. If installation stops working after multiple installs, log out and log back in.

### Command-Line Build

Build the installer:

```bash
xcodebuild -project McBopomofo.xcodeproj -target McBopomofoInstaller -configuration Debug build
```

Build the main input method:

```bash
xcodebuild -project McBopomofo.xcodeproj -target McBopomofo -configuration Debug build
```

Build dictionary data only:

```bash
xcodebuild -project McBopomofo.xcodeproj -target Data -configuration Debug build
```

### Running Tests

#### Swift Tests
- Target: `McBopomofoTests` in Xcode
- Framework: XCTest with Swift `Testing` module
- Run in Xcode with Cmd+U or test navigator

#### C++ Engine Tests

```bash
cd Source/Engine
mkdir build && cd build
cmake -DENABLE_TEST=ON ..
make
ctest
```

To run directly: `./McBopomofoLMLibTest`

The C++ tests use Google Test framework and are defined in `Source/Engine/CMakeLists.txt`.

### Dictionary Data Generation

Dictionary data must be regenerated when modifying phrase mappings or frequency data.

Generate and validate:

```bash
cd Source/Data
make all
make sort
make check
make tidy
```

Both `BPMFMappings.txt` and `phrase.occ` must be sorted with C locale:

```bash
LC_ALL=C sort -o BPMFMappings.txt BPMFMappings.txt
LC_ALL=C sort -o phrase.occ phrase.occ
```

**For detailed dictionary data documentation**, see `Source/Data/AGENTS.md` which covers file formats, editing workflows, Python tools, and troubleshooting.

<context>

## GitHub Copilot Configuration

GitHub Copilot uses `.github/copilot-instructions.md` for its custom instructions. That file references this AGENTS.md for comprehensive context but includes essential guidelines inline since Copilot cannot automatically load AGENTS.md.

For GitHub Copilot-specific configuration, see:
- `.github/copilot-instructions.md` - Repository-wide Copilot instructions
- `.github/instructions/Data.instructions.md` - Path-specific instructions for Source/Data

</context>

<context>

## Architecture Overview

McBopomofo uses a three-layer architecture (Swift/Objective-C++/C++). For detailed architecture and algorithm documentation, see:
- `algorithm.md`: Comprehensive technical documentation (Chinese)
- [Wiki: 程式架構](https://github.com/openvanilla/McBopomofo/wiki/程式架構): Program architecture
- [Wiki: Gramambular 演算法](https://github.com/openvanilla/McBopomofo/wiki/程式架構_Gramambular): Gramambular algorithm

</context>

## Key Files Reference

- `Source/InputMethodController.swift` -- Main IMK entry point, coordinates candidate menus and preferences
- `Source/InputState.swift` -- State machine base and all state implementations
- `Source/KeyHandler.mm` -- Objective-C++ bridge between Swift events and C++ engine
- `Source/LanguageModelManager.mm` -- Wraps C++ language model for Swift consumption
- `Source/Engine/McBopomofoLM.cpp` -- Core language model logic and unigram processing
- `Source/Engine/Mandarin/Mandarin.cpp` -- Bopomofo syllable processing and keyboard layouts
- `Source/Engine/gramambular2/` -- Text segmentation algorithms (HMM-based)
- `Source/Data/Makefile` -- Dictionary data build system
- `Source/Data/AGENTS.md` -- Comprehensive dictionary data documentation
- `algorithm.md` -- Detailed algorithm explanation (Chinese)
- `McBopomofoTests/PreferencesTests.swift` -- Example Swift Testing suite patterns

## Development Guidelines

### Branch & Worktree Discipline

<required>

- **Before editing any file**: Confirm the correct branch
  with `git branch --show-current` and the correct
  worktree with `pwd`.
- Never edit files on one branch intending them for
  another. If a worktree exists for the target branch,
  switch to it first.
- When working with multiple worktrees, always use
  absolute paths to avoid ambiguity.

</required>

### General

<required>

- **Never use emoji** in code, comments, documentation, or generated content outside `Source/Data/`. Emoji are permitted only within dictionary data files in `Source/Data` where mappings include emoji.
- **Language restriction:** Use only English or Traditional Chinese. Simplified Chinese is prohibited in all documentation, comments, and reviews.
- **Date/time format:** When noting "last updated" or timestamps in documentation, always use full ISO 8601 datetime in UTC+8 timezone (e.g., `2025-10-12T14:30:00+08:00`). Use the `date` command to get the current system time and adjust to UTC+8 if needed.

</required>

### Conventional Commits

<required>

- **MUST use Conventional Commits format** for all git commits and pull requests
- Format: `type(scope): description`
- Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Examples:
  - `feat(input): add new keyboard layout support`
  - `fix(engine): correct syllable composition for edge case`
  - `docs(readme): update installation instructions`
  - `refactor(state): simplify state transition logic`
- Keep descriptions concise and in present tense
- See: https://www.conventionalcommits.org/

</required>

### Swift & AppKit

<required>

- Use `Preferences` static properties and property wrappers instead of direct `UserDefaults` access
- Localize all UI strings with `NSLocalizedString("…", comment: "")` and update `.strings` files in `Base.lproj`, `en.lproj`, `zh-Hant.lproj`
- Perform UI work on main thread; use existing helpers/notifications rather than ad-hoc dispatch queues
- Interact with engine through `KeyHandler`/`LanguageModelManager` bridges, not directly
- Keep AppKit/IMKit work in Swift classes with `private`/`fileprivate` scope

</required>

### State Machine

<required>

- Treat `InputState` subclasses as immutable; always create new state objects on transitions
- Funnel all key handling through `KeyHandler` for consistent state transitions
- Derive UI and candidate lists from state object, not scattered flags
- Extend by adding new `InputState` subclasses with explicit transitions, not booleans

</required>

### Objective-C++ Bridge

<required>

- Manage C++ object lifetimes in `.mm` files with proper `init`/`dealloc`
- Use `std::shared_ptr` when passing to C++ APIs
- Surface engine capabilities by extending bridge classes and declaring in `McBopomofo-Bridging-Header.h`
- Convert between `NSString` and `std::string` using `UTF8Helper` and Foundation methods, not manual conversion
- Keep bridge methods small: forward to engine, return Foundation types

</required>

### C++ Engine

<required>

- **Standard: C++17 only** — Do not use C++20 or C++23
  features. C++17 is set in all CMakeLists.txt files and
  the Xcode project; do not upgrade without maintainer
  approval.
- Follow C++17 style with `std::vector`,
  `std::unordered_map`, `std::optional`,
  `std::string_view`
- Place code in existing namespaces: `McBopomofo`,
  `Formosa::Gramambular2`, `Formosa::Mandarin`
- Reuse blob readers (`MemoryMappedFile`,
  `ParselessPhraseDB`, `PhraseReplacementMap`)
- Keep algorithms deterministic and side-effect free;
  logging stays in Objective-C++ layer

</required>

<forbidden>

- C++20 features: `std::format`, concepts, ranges,
  coroutines, three-way comparison (`<=>`), `consteval`,
  `std::span`
- C++23 features: `std::expected`, `std::mdspan`,
  `std::print`, `std::stacktrace`
- Any other C++20/C++23 library or language feature not
  available in C++17
- Upgrading `CMAKE_CXX_STANDARD` or
  `CLANG_CXX_LANGUAGE_STANDARD` without maintainer
  approval

</forbidden>

### Code-First Verification

<required>

- **Before writing new algorithm code**: Read the current
  implementation in master first
  (`git show master:<file>`).
- New code must extend or improve the current algorithm,
  never regress to a previous version.
- Compare your implementation against HEAD before
  committing.

</required>

<context>

Documentation (`algorithm.md`, wiki) may lag behind
actual code. Source code is authoritative; docs are
educational and may be stale.

</context>

### Build System Integration

<required>

- **Dual build system updates**: When adding or removing C++
  source files (`.cpp`, `.h`), update BOTH:
  - `Source/Engine/CMakeLists.txt` (for C++ test builds)
  - `McBopomofo.xcodeproj/project.pbxproj` (for Xcode builds)
  Forgetting one causes linker errors in the other build
  system.
- **Surgical `.pbxproj` edits only**: `.pbxproj` is a fragile
  generated format. Only add or remove specific entries
  (PBXBuildFile, PBXFileReference, PBXSourcesBuildPhase).
  Never regenerate entire sections, change deployment target,
  build settings, or unrelated entries.
- **Pre-PR build verification**: Before creating a PR, verify
  the Xcode build succeeds locally:
  ```
  xcodebuild -project McBopomofo.xcodeproj -target McBopomofo -configuration Debug build
  ```
  This catches missing compile sources, wrong type references,
  and include errors that CI will also catch.
- **Stacked branch independence**: Each branch in a stacked PR
  series must compile independently on its own base. Don't
  defer build integration (e.g., adding Xcode compile sources)
  to a later branch if the source files are introduced in an
  earlier branch.

</required>

<forbidden>

- Regenerating entire `.pbxproj` sections
- Changing deployment target or build settings in `.pbxproj`
  unless explicitly requested
- Creating a PR without verifying the Xcode build locally
- Introducing source files in one stacked branch but deferring
  their build system registration to a later branch

</forbidden>

### PR Review Responses

<required>

- Before defending code in review responses, **re-read
  the current master implementation** of the code area
  being critiqued.
- If a reviewer says code regresses or duplicates old
  patterns, verify by comparing against master before
  responding.

</required>

<forbidden>

- Rationalizing architectural issues as
  "bounded in practice"
- Defending implementation details without first
  verifying the critique against master

</forbidden>

### Testing

<required>

- **Swift tests:** Use Swift `Testing` module with `@Suite`, `@Test`, `#expect` macros in `McBopomofoTests/`
- **C++ tests:** Add to `Source/Engine/CMakeLists.txt` in `McBopomofoLMLibTest` target, use GoogleTest
- **Mixed tests:** Use Objective-C++ (`.mm`) with bridging header for Swift-C++ interop
- Snapshot/restore `UserDefaults` in tests (see `PreferencesTests.swift`)

</required>

<context>

### Dictionary Data Modifications

For dictionary data modifications, see [Wiki: 詞庫開發說明](https://github.com/openvanilla/McBopomofo/wiki/詞庫開發說明) or `Source/Data/AGENTS.md` for detailed workflows.

</context>

## Things to Avoid

<forbidden>

- Don't replace AppKit windows with SwiftUI or Combine; runtime depends on NSWindow/XIB
- Don't bypass the Objective-C++ bridge to access engine from Swift directly
- Don't hardcode paths to user data; use preference APIs
- Don't modify large dictionary blobs unless specifically targeting them
- Don't add generic development practices or obvious instructions

</forbidden>

<context>

## Local Packages

The `Packages/` directory contains local Swift Package dependencies:
- `BopomofoBraille`: Braille output support
- `CandidateUI`: Candidate window rendering
- `ChineseNumbers`: Chinese numeral conversion
- `FSEventStreamHelper`: File system monitoring
- `InputSourceHelper`: Input source management
- `NotifierUI`: User notifications
- `NSStringUtils`: String utility functions
- `OpenCCBridge`: Traditional/Simplified Chinese conversion (wraps SwiftyOpenCC)
- `SystemCharacterInfo`: Character information lookup (uses SQLite.swift)
- `TooltipUI`: Tooltip display

These are referenced directly by Xcode project, not through Package.swift.

### External Package Dependencies

The project also depends on these external Swift packages (resolved automatically by Xcode):
- `swift-toolchain-sqlite` (1.0.4): Low-level SQLite bindings from Swift toolchain
- `SQLite.swift` (0.15.4): Swift wrapper for SQLite3
- `SwiftyOpenCC` (2.0.0-beta): Swift wrapper for OpenCC (Chinese text conversion)

## Claude Code Automation

- **Hooks & skills** live in `.claude/` (settings.json, hooks/, skills/)
- PostToolUse hook auto-formats C++/ObjC files via `xcrun clang-format -i`
- PreToolUse hook blocks edits to generated data files in `Source/Data/`
- `/engine-test` skill: build and run C++ engine tests
- **Context threshold**: 60% — use `/clear` to reset

## Multi-Branch Workflow

- Use `git worktree add` to edit other branches without switching the main worktree
- Example: `git worktree add ../McBopomofo-<label> <branch-name>`
- Always `git worktree remove` when done

</context>

<related>

- `Source/Data/AGENTS.md` - Dictionary data guide
- `.github/copilot-instructions.md` - GitHub Copilot config
- `.github/instructions/Data.instructions.md` - Copilot Data/ config
- `algorithm.md` - Algorithm documentation (Chinese)
- [Wiki: 程式架構](https://github.com/openvanilla/McBopomofo/wiki/程式架構)
- [Wiki: 詞庫開發說明](https://github.com/openvanilla/McBopomofo/wiki/詞庫開發說明)

</related>

## ACTION (Recency Zone)

<required>

**Quick references** (see CRITICAL section for full
pre-edit checklist):

- Build: McBopomofoInstaller target
- Swift tests: Xcode (Cmd+U)
- C++ tests: `cd Source/Engine && mkdir -p build && cd build && cmake -DENABLE_TEST=ON .. && make && ctest`
- Dictionary: `cd Source/Data && make all sort check`
- Xcode build verify: `xcodebuild -project McBopomofo.xcodeproj -target McBopomofo -configuration Debug build`

</required>
