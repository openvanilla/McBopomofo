# CLAUDE.md

This file provides guidance specifically to Claude Code (claude.ai/code) when working with this repository.

For comprehensive project documentation, architecture details, build instructions, and development guidelines, please refer to:

- **AGENTS.md** - Main project documentation for all AI coding assistants
- **Source/Data/AGENTS.md** - Dictionary data-specific documentation for AI coding assistants

These files contain detailed information about:

- Project overview and system requirements
- Building and running the application
- Architecture (Swift, Objective-C++, C++ layers)
- State machine implementation
- Development guidelines and best practices
- Testing procedures
- Dictionary data management

Please consult AGENTS.md for all development tasks.

## Build Notes (Fork-specific)

Command-line build **must** use `-scheme` + `-destination` (not `-target`), otherwise local SPM package dependencies fail:

```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofoInstaller \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  build
```

## State Machine Notes

`InputState` has multiple "empty" states that must all be handled consistently:

- `InputState.Empty` — normal idle state
- `InputState.EmptyIgnoringPreviousState` — after backspace clears last character
- `InputState.Deactivated` — input method deactivated

Any logic that checks "is the input buffer empty?" must account for all three.
