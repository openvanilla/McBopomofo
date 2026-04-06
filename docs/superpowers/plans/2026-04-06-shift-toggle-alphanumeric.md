# SHIFT Toggle Alphanumeric Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pressing SHIFT alone (press and release without other keys in between) toggles between Bopomofo and alphanumeric (English) input modes. Pressing SHIFT again toggles back.

**Architecture:** Add an `isAlphanumericMode` instance flag to `McBopomofoInputMethodController`. Detect SHIFT press-and-release via `flagsChanged` events (SHIFT down → SHIFT up with no `keyDown` in between). In alphanumeric mode, return `false` from `handle(_:client:)` to let macOS pass keystrokes through as-is. Show a `NotifierController` notification on toggle. Reset to Bopomofo mode on `deactivateServer`.

**Tech Stack:** Swift, macOS Input Method Kit (IMK), XCTest

**Spec:** User request — SHIFT toggles Chinese↔English, visual notification on switch.

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `Source/InputMethodController.swift` | Add alphanumeric mode flag, SHIFT detection in `handle(_:client:)`, reset in `deactivateServer` |
| Modify | `Source/Localizable.strings` (if exists) | Add localized strings for "English Mode" / "Bopomofo Mode" |

No new files needed. This is a small, focused change in a single file.

---

### Task 1: Add alphanumeric mode flag and SHIFT detection

**Files:**
- Modify: `Source/InputMethodController.swift:47-57` (properties)
- Modify: `Source/InputMethodController.swift:220-259` (handle method, flagsChanged)
- Modify: `Source/InputMethodController.swift:183-188` (deactivateServer)

- [ ] **Step 1: Add instance properties for alphanumeric mode and SHIFT tracking**

In `McBopomofoInputMethodController`, add these properties after the existing declarations (after line 57):

```swift
/// Whether the input method is in alphanumeric (English) passthrough mode.
var isAlphanumericMode = false

/// Tracks whether SHIFT was pressed without any other key in between,
/// to distinguish a bare SHIFT press from SHIFT+key combos.
private var shiftPressed = false
```

- [ ] **Step 2: Rewrite the `flagsChanged` handling in `handle(_:client:)`**

Replace the existing flagsChanged handling block (lines 227-258) with SHIFT toggle detection. The logic:
1. When SHIFT goes down (`.shift` flag present), set `shiftPressed = true`
2. When SHIFT goes up (`.shift` flag absent after being pressed), if `shiftPressed` is still true, it was a bare SHIFT press → toggle mode
3. Any `keyDown` event between SHIFT down and up will set `shiftPressed = false` (handled in step 3)

Replace the TWO `if event.type == .flagsChanged` blocks (lines 227-258, note the second block is dead code) with:

```swift
if event.type == .flagsChanged {
    let shiftOnly = event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .shift
    if shiftOnly {
        // SHIFT key went down
        shiftPressed = true
    } else if shiftPressed {
        // A modifier changed while shiftPressed was true.
        // If SHIFT is no longer held, this is a SHIFT release.
        if !event.modifierFlags.contains(.shift) {
            shiftPressed = false
            // Only toggle if composing buffer is empty
            if state is InputState.Empty || state is InputState.Deactivated {
                isAlphanumericMode.toggle()
                let message = isAlphanumericMode ? "英數" : "注音"
                NotifierController.notify(message: message)
            }
        }
    }
    // If in active input state (not Empty), suppress flagsChanged
    if !(state is InputState.Empty) && !(state is InputState.Deactivated) {
        return true
    }
    return false
}
```

- [ ] **Step 3: Cancel SHIFT toggle when other keys are pressed**

In the `handle(_:client:)` method, right after the `flagsChanged` block and before the keyDown processing (before line 261 `var textFrame = NSRect.zero`), add:

```swift
// Any non-flagsChanged event cancels the pending SHIFT toggle
shiftPressed = false
```

- [ ] **Step 4: In alphanumeric mode, pass keystrokes through**

Right after the `shiftPressed = false` line added in Step 3, add the alphanumeric passthrough:

```swift
if isAlphanumericMode {
    return false
}
```

This returns `false` to tell macOS the input method didn't handle the event, so the raw keystroke passes through to the app.

- [ ] **Step 5: Reset alphanumeric mode on deactivation**

In `deactivateServer(_:)` (line 183), add before `keyHandler.clear()`:

```swift
isAlphanumericMode = false
shiftPressed = false
```

- [ ] **Step 6: Reset alphanumeric mode on activation**

In `activateServer(_:)` (line 169), add after `currentClient = client`:

```swift
isAlphanumericMode = false
shiftPressed = false
```

- [ ] **Step 7: Build and verify**

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj -scheme McBopomofoInstaller -configuration Debug build 2>&1 | tail -5
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Manual test**

1. Install: `open ~/Library/Developer/Xcode/DerivedData/McBopomofo-*/Build/Products/Debug/McBopomofoInstaller.app`
2. Open TextEdit, switch to 小麥注音
3. Press and release SHIFT alone → should see "英數" notification, typing produces English
4. Press and release SHIFT alone again → should see "注音" notification, typing produces Bopomofo
5. Press SHIFT+A (capital letter) → should NOT toggle mode
6. While composing (buffer not empty), SHIFT should NOT toggle

- [ ] **Step 9: Commit**

```bash
git add Source/InputMethodController.swift
git commit -m "feat: add SHIFT key toggle between Bopomofo and alphanumeric modes

Pressing SHIFT alone (press and release without other keys) toggles
between Bopomofo input and alphanumeric passthrough. A floating
notification shows the current mode. Mode resets to Bopomofo when
the input method is deactivated or reactivated."
```

---

## Notes

- **No persistent preference**: Alphanumeric mode is per-session. When switching apps or input methods, it resets to Bopomofo. This matches the behavior of most Chinese input methods.
- **SHIFT+key combos**: The `shiftPressed` flag is cleared on any `keyDown`, so SHIFT+A for capital letters works normally without triggering a toggle.
- **Buffer protection**: Toggle only fires when the composing buffer is empty (`state is InputState.Empty`), preventing accidental mode switches mid-composition.
- **Dead code cleanup**: The second `if event.type == .flagsChanged` block (lines 240-258) was unreachable dead code. This plan replaces both blocks with a single, correct implementation.
