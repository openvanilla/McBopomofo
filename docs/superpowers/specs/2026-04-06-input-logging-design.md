# Input Logging for Word Frequency Analysis

## Goal

Log every committed phrase with its Bopomofo reading to a local TSV file, enabling word frequency analysis to improve the input method's language model and candidate ranking.

## Data Format

Tab-separated values in `~/Library/Logs/McBopomofo/input-log-YYYY-MM.tsv`:

```
2026-04-06T14:30:00+08:00	ㄐㄧㄣ-ㄊㄧㄢ	今天
2026-04-06T14:30:01+08:00		Hello
```

| Column | Description |
|--------|-------------|
| timestamp | ISO 8601 with UTC+8 timezone |
| reading | Bopomofo reading with `-` separator; empty for non-Bopomofo commits (alphanumeric, punctuation) |
| text | The committed text string |

No header row. One line per commit event.

## Configuration

- Always on, no UI toggle, no Preferences entry
- This is a local-only, personal-use feature for the fork

## Architecture

### 1. InputState.Committing -- add `reading` property

**File:** `Source/InputState.swift` (lines 103-116)

Add an optional `reading` property to `InputState.Committing`:

```swift
@objc(InputStateCommitting)
class Committing: InputState {
    @objc private(set) var poppedText: String = ""
    @objc private(set) var reading: String = ""

    @objc convenience init(poppedText: String) {
        self.init()
        self.poppedText = poppedText
    }

    @objc convenience init(poppedText: String, reading: String) {
        self.init()
        self.poppedText = poppedText
        self.reading = reading
    }
}
```

The single-arg `initWithPoppedText:` is preserved for backward compatibility -- sites that commit non-Bopomofo text (alphanumeric, punctuation, space) continue using it with reading defaulting to `""`.

### 2. KeyHandler.mm -- pass reading when available

For commit sites where `_grid` contains reading data, extract readings and use the new two-arg initializer. The reading is obtained from `_latestWalk.nodes` by joining each node's reading.

**Sites that get reading (Bopomofo commit paths):**

| Line(s) | Context | How to get reading |
|----------|---------|-------------------|
| 311 | Force commit (Enter) | `_latestWalk.nodes` joined readings |
| 579 | Plain Bopomofo single candidate auto-commit | `candidateReading` already available |
| 621, 747, 761 | Space/grid commit | `_latestWalk.nodes` joined readings |
| 1258 | Candidate selection commit | `_latestWalk.nodes` joined readings |
| 1312, 1442 | Single candidate auto-select | candidate's `.reading` property |

**Sites that stay with empty reading (non-Bopomofo):**

| Line(s) | Context |
|----------|---------|
| 389, 400 | Alphanumeric pass-through (shift key) |
| 625 | Space character commit |
| 727 | Feature input (numbers, dates, Big5 codes) |
| 2115, 2161 | Ctrl+punctuation, other special input |

A helper method will be added to KeyHandler to extract the full reading string from `_latestWalk`:

```objc
- (NSString *)_currentReadingString {
    NSMutableArray *readings = [[NSMutableArray alloc] init];
    for (const auto& node : _latestWalk.nodes) {
        [readings addObject:@(node->reading().c_str())];
    }
    return [readings componentsJoinedByString:@" "];
}
```

### 3. InputLogger.swift -- new logger class

**File:** `Source/InputLogger.swift` (new file)

```swift
class InputLogger {
    static let shared = InputLogger()

    private let queue = DispatchQueue(label: "org.openvanilla.McBopomofo.inputLogger")
    private var fileHandle: FileHandle?
    private var currentMonth: String = ""
    private let logDirectory: URL

    private init() {
        logDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/McBopomofo")
    }

    func log(text: String, reading: String) {
        queue.async { self._log(text: text, reading: reading) }
    }
}
```

Internal implementation:
- `_log()` checks if month changed, opens/rotates file handle if needed
- Creates directory with `createDirectory(withIntermediateDirectories: true)`
- Writes one TSV line: `timestamp \t reading \t text \n`
- Uses `FileHandle.seekToEndOfFile()` + `write()` for append
- Timestamp: `ISO8601DateFormatter` with timezone `+08:00`

### 4. InputMethodController.swift -- invoke logger

**File:** `Source/InputMethodController.swift` (line ~542)

In `handle(state: InputState.Committing, ...)`, add logging call:

```swift
private func handle(state: InputState.Committing, previous: InputState, client: Any?) {
    // ... existing code ...
    let poppedText = state.poppedText
    if !poppedText.isEmpty {
        InputLogger.shared.log(text: poppedText, reading: state.reading)
        commit(text: poppedText, client: client)
    }
    // ... existing code ...
}
```

## File Changes Summary

| File | Change |
|------|--------|
| `Source/InputState.swift` | Add `reading` property to `Committing` |
| `Source/KeyHandler.mm` | Add `_currentReadingString` helper; pass reading at Bopomofo commit sites |
| `Source/InputLogger.swift` | New file: singleton logger with monthly rotation |
| `Source/InputMethodController.swift` | Add `InputLogger.shared.log()` call in Committing handler |

## What NOT to change

- No Preferences UI or toggle
- No C++ engine changes
- No changes to other InputState subclasses
- No changes to dictionary data

## Testing

- Manual: type phrases, check `~/Library/Logs/McBopomofo/input-log-2026-04.tsv` contains correct entries
- Verify alphanumeric commits have empty reading column
- Verify Bopomofo commits have correct reading
- Verify monthly rotation by checking file naming
