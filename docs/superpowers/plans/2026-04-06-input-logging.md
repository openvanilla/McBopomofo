# Input Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Log every committed phrase with its Bopomofo reading to a monthly-rotated TSV file for word frequency analysis.

**Architecture:** Add a `reading` property to `InputState.Committing`, extract readings from `_latestWalk` in KeyHandler.mm before `[self clear]`, and log via a singleton `InputLogger` in the Swift commit handler.

**Tech Stack:** Swift (logger + state), Objective-C++ (reading extraction)

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `Source/InputLogger.swift` | Create | Singleton logger: TSV append, monthly rotation |
| `Source/InputState.swift` | Modify | Add `reading` property to `Committing` class |
| `Source/KeyHandler.mm` | Modify | Add `_walkReadingString` helper; pass reading at Bopomofo commit sites |
| `Source/InputMethodController.swift` | Modify | Call `InputLogger.shared.log()` in Committing handler |
| `McBopomofoTests/InputLoggerTests.swift` | Create | Unit tests for InputLogger |

---

### Task 1: Create InputLogger with tests

**Files:**
- Create: `Source/InputLogger.swift`
- Create: `McBopomofoTests/InputLoggerTests.swift`

- [ ] **Step 1: Write the failing test**

Create `McBopomofoTests/InputLoggerTests.swift`:

```swift
// Copyright (c) 2022 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import Testing

@testable import McBopomofo

@Suite("InputLogger Tests", .serialized)
final class InputLoggerTests {

    let testDir: URL

    init() throws {
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("McBopomofoLogTest-\(UUID().uuidString)")
    }

    deinit {
        try? FileManager.default.removeItem(at: testDir)
    }

    @Test func logWritesTSVLine() throws {
        let logger = InputLogger(logDirectory: testDir)
        logger.log(text: "today", reading: "ㄐㄧㄣ-ㄊㄧㄢ")
        logger.flush()

        let files = try FileManager.default.contentsOfDirectory(
            at: testDir, includingPropertiesForKeys: nil)
        #expect(files.count == 1)
        #expect(files[0].lastPathComponent.hasPrefix("input-log-"))
        #expect(files[0].pathExtension == "tsv")

        let content = try String(contentsOf: files[0], encoding: .utf8)
        let lines = content.split(separator: "\n")
        #expect(lines.count == 1)

        let columns = lines[0].split(separator: "\t", maxSplits: 2)
        #expect(columns.count == 3)
        #expect(columns[1] == "ㄐㄧㄣ-ㄊㄧㄢ")
        #expect(columns[2] == "today")
    }

    @Test func logWithEmptyReading() throws {
        let logger = InputLogger(logDirectory: testDir)
        logger.log(text: "Hello", reading: "")
        logger.flush()

        let files = try FileManager.default.contentsOfDirectory(
            at: testDir, includingPropertiesForKeys: nil)
        let content = try String(contentsOf: files[0], encoding: .utf8)
        let columns = content.split(separator: "\n")[0]
            .split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
        #expect(columns.count == 3)
        #expect(columns[1] == "")
        #expect(columns[2] == "Hello")
    }

    @Test func logMultipleEntriesAppend() throws {
        let logger = InputLogger(logDirectory: testDir)
        logger.log(text: "a", reading: "ㄟ")
        logger.log(text: "b", reading: "ㄅㄧˋ")
        logger.flush()

        let files = try FileManager.default.contentsOfDirectory(
            at: testDir, includingPropertiesForKeys: nil)
        let content = try String(contentsOf: files[0], encoding: .utf8)
        let lines = content.split(separator: "\n")
        #expect(lines.count == 2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofo \
  -destination 'platform=macOS,arch=arm64' \
  test 2>&1 | tail -20
```

Expected: Compilation error -- `InputLogger` not defined.

- [ ] **Step 3: Write InputLogger implementation**

Create `Source/InputLogger.swift`:

```swift
// Copyright (c) 2022 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import Foundation

class InputLogger {

    static let shared = InputLogger(
        logDirectory: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/McBopomofo")
    )

    private let queue = DispatchQueue(label: "org.openvanilla.McBopomofo.inputLogger")
    private var fileHandle: FileHandle?
    private var currentMonth: String = ""
    private let logDirectory: URL

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        return f
    }()

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        f.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        return f
    }()

    init(logDirectory: URL) {
        self.logDirectory = logDirectory
    }

    func log(text: String, reading: String) {
        let timestamp = Self.timestampFormatter.string(from: Date())
        let month = Self.monthFormatter.string(from: Date())
        queue.async { [weak self] in
            self?._log(timestamp: timestamp, month: month, text: text, reading: reading)
        }
    }

    func flush() {
        queue.sync {
            fileHandle?.synchronizeFile()
        }
    }

    private func _log(timestamp: String, month: String, text: String, reading: String) {
        if month != currentMonth {
            fileHandle?.closeFile()
            fileHandle = nil
            currentMonth = month
        }

        if fileHandle == nil {
            _openFile(month: month)
        }

        let sanitizedText = text.replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let sanitizedReading = reading.replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let line = "\(timestamp)\t\(sanitizedReading)\t\(sanitizedText)\n"

        if let data = line.data(using: .utf8) {
            fileHandle?.seekToEndOfFile()
            fileHandle?.write(data)
        }
    }

    private func _openFile(month: String) {
        try? FileManager.default.createDirectory(
            at: logDirectory, withIntermediateDirectories: true)
        let filePath = logDirectory
            .appendingPathComponent("input-log-\(month).tsv")
        if !FileManager.default.fileExists(atPath: filePath.path) {
            FileManager.default.createFile(atPath: filePath.path, contents: nil)
        }
        fileHandle = try? FileHandle(forWritingTo: filePath)
        fileHandle?.seekToEndOfFile()
    }
}
```

- [ ] **Step 4: Add files to Xcode project and run tests**

Add both `Source/InputLogger.swift` and `McBopomofoTests/InputLoggerTests.swift` to the Xcode project (McBopomofo target for source, McBopomofoTests target for test).

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofo \
  -destination 'platform=macOS,arch=arm64' \
  test 2>&1 | tail -20
```

Expected: All 3 InputLogger tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Source/InputLogger.swift McBopomofoTests/InputLoggerTests.swift McBopomofo.xcodeproj/
git commit -m "feat(logging): add InputLogger with monthly TSV rotation"
```

---

### Task 2: Add `reading` property to InputState.Committing

**Files:**
- Modify: `Source/InputState.swift:103-116`

- [ ] **Step 1: Add reading property and new initializer**

In `Source/InputState.swift`, replace the `Committing` class (lines 103-116):

```swift
    /// Represents that the input controller is committing text into client app.
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

        override var description: String {
            "<InputState.Committing poppedText:\(poppedText), reading:\(reading)>"
        }
    }
```

- [ ] **Step 2: Build to verify no regressions**

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofo \
  -destination 'platform=macOS,arch=arm64' \
  build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED. All existing `initWithPoppedText:` call sites still compile (single-arg init preserved).

- [ ] **Step 3: Run tests**

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofo \
  -destination 'platform=macOS,arch=arm64' \
  test 2>&1 | tail -20
```

Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add Source/InputState.swift
git commit -m "feat(state): add reading property to InputState.Committing"
```

---

### Task 3: Add `_walkReadingString` helper to KeyHandler.mm and pass reading at commit sites

**Files:**
- Modify: `Source/KeyHandler.mm`

The critical constraint: `[self clear]` wipes `_latestWalk`, so reading must be extracted **before** clear. The `_walkReadingString` method reads from `_latestWalk.nodes` (not `_grid`).

- [ ] **Step 1: Add `_walkReadingString` helper method**

In `Source/KeyHandler.mm`, after the existing `_currentBpmfReading` method (line 1167), add:

```objc
- (NSString *)_walkReadingString
{
    NSMutableArray *readings = [[NSMutableArray alloc] init];
    for (const auto& node : _latestWalk.nodes) {
        std::string reading = node->reading();
        // Skip punctuation/symbol readings that start with underscore
        if (reading.rfind("_", 0) != 0) {
            [readings addObject:[NSString stringWithUTF8String:reading.c_str()]];
        }
    }
    return [readings componentsJoinedByString:@" "];
}
```

- [ ] **Step 2: Update force-commit (line 311)**

In `handleForceCommitWithStateCallback:` (line 299), the reading must be extracted before `[self clear]` at line 309. Replace lines 308-312:

Before:
```objc
    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
    [self clear];

    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:inputting.composingBuffer];
```

After:
```objc
    InputStateInputting *inputting = (InputStateInputting *)[self buildInputtingState];
    NSString *readingString = [self _walkReadingString];
    [self clear];

    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:inputting.composingBuffer reading:readingString];
```

- [ ] **Step 3: Update Plain Bopomofo single-candidate commit (line 579)**

At line 575-579, the candidate reading is already available. Replace line 579:

Before:
```objc
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:text];
```

After:
```objc
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:text reading:candidateReading];
```

- [ ] **Step 4: Update space-commit with composing buffer (line 621)**

At lines 618-622, extract reading before `[self clear]` at line 624. Replace lines 619-624:

Before:
```objc
                    NSString *composingBuffer = ((InputStateNotEmpty *)state).composingBuffer;
                    if (composingBuffer.length) {
                        InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
                        stateCallback(committing);
                    }
                    [self clear];
```

After:
```objc
                    NSString *composingBuffer = ((InputStateNotEmpty *)state).composingBuffer;
                    if (composingBuffer.length) {
                        NSString *readingString = [self _walkReadingString];
                        InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer reading:readingString];
                        stateCallback(committing);
                    }
                    [self clear];
```

- [ ] **Step 5: Update Big5/feature mode commits (lines 747, 761)**

At lines 744-748 and 758-762, extract reading before `[self clear]`. These commit the composing buffer before entering a special mode. Replace the pattern at both sites:

Line 744-748 -- before:
```objc
            if ([state isKindOfClass:[InputStateInputting class]]) {
                InputStateInputting *current = (InputStateInputting *)state;
                NSString *composingBuffer = current.composingBuffer;
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
```

After:
```objc
            if ([state isKindOfClass:[InputStateInputting class]]) {
                InputStateInputting *current = (InputStateInputting *)state;
                NSString *composingBuffer = current.composingBuffer;
                NSString *readingString = [self _walkReadingString];
                InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer reading:readingString];
```

Apply the same pattern at line 758-762.

- [ ] **Step 6: Update Enter key commit (line 1258)**

At `_handleEnterWithState:` (line 1248), `[self clear]` is called at line 1254 before the commit. Extract reading before clear. Replace lines 1254-1258:

Before:
```objc
    [self clear];

    InputStateInputting *current = (InputStateInputting *)state;
    NSString *composingBuffer = current.composingBuffer;
    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer];
```

After:
```objc
    NSString *readingString = [self _walkReadingString];
    [self clear];

    InputStateInputting *current = (InputStateInputting *)state;
    NSString *composingBuffer = current.composingBuffer;
    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:composingBuffer reading:readingString];
```

- [ ] **Step 7: Update Plain Bopomofo punctuation single-candidate commit (line 1312)**

At lines 1310-1312, candidate reading is available. Replace line 1312:

Before:
```objc
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:candidateState.candidates.firstObject.value];
```

After:
```objc
            InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:candidateState.candidates.firstObject.value reading:candidateState.candidates.firstObject.reading];
```

- [ ] **Step 8: Update associated phrase single-candidate commit (line 1442)**

Same pattern as step 7. At line 1442, replace:

Before:
```objc
                    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:candidateState.candidates.firstObject.value];
```

After:
```objc
                    InputStateCommitting *committing = [[InputStateCommitting alloc] initWithPoppedText:candidateState.candidates.firstObject.value reading:candidateState.candidates.firstObject.reading];
```

- [ ] **Step 9: Build and run all tests**

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofo \
  -destination 'platform=macOS,arch=arm64' \
  test 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED, all tests PASS.

- [ ] **Step 10: Commit**

```bash
git add Source/KeyHandler.mm
git commit -m "feat(logging): pass Bopomofo reading to Committing state"
```

---

### Task 4: Wire InputLogger into InputMethodController

**Files:**
- Modify: `Source/InputMethodController.swift:533-548`

- [ ] **Step 1: Add logging call in Committing handler**

In `Source/InputMethodController.swift`, in the `handle(state: InputState.Committing, ...)` method (line 533), add the logging call. Replace lines 541-543:

Before:
```swift
        let poppedText = state.poppedText
        if !poppedText.isEmpty {
            commit(text: poppedText, client: client)
```

After:
```swift
        let poppedText = state.poppedText
        if !poppedText.isEmpty {
            InputLogger.shared.log(text: poppedText, reading: state.reading)
            commit(text: poppedText, client: client)
```

- [ ] **Step 2: Build and run all tests**

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofo \
  -destination 'platform=macOS,arch=arm64' \
  test 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED, all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add Source/InputMethodController.swift
git commit -m "feat(logging): wire InputLogger into commit handler"
```

---

### Task 5: Manual integration test

- [ ] **Step 1: Build and install**

Run:
```bash
xcodebuild -project McBopomofo.xcodeproj \
  -scheme McBopomofoInstaller \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  build
```

Then run the installer from `build/Debug/McBopomofoInstaller.app`.

- [ ] **Step 2: Type test phrases and verify log**

Switch to McBopomofo input method and type:
1. A Bopomofo phrase (e.g., type keys for "today" to get a Chinese word)
2. An alphanumeric string via Shift key

Then check the log:

```bash
cat ~/Library/Logs/McBopomofo/input-log-2026-04.tsv
```

Expected output (example):
```
2026-04-06T15:30:00+08:00	ㄐㄧㄣ-ㄊㄧㄢ	今天
2026-04-06T15:30:05+08:00		hello
```

- [ ] **Step 3: Final commit (if any fixups needed)**

```bash
git add -A
git commit -m "fix(logging): address integration test findings"
```
