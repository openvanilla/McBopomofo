# Abbreviated Bopomofo Input (簡拼) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable consonant-only abbreviated input in McBopomofo so users can type phrases without completing full syllables.

**Architecture:** New `ReadingTrie` class indexes dictionary entries by syllable for efficient prefix matching. `ParselessLM` builds the trie at load time and delegates abbreviated queries to it. `McBopomofoLM` and `KeyHandler` are modified minimally to support consonant-only readings.

**Tech Stack:** C++17, Google Test, Objective-C++, XCTest (Swift)

**Spec:** `docs/superpowers/specs/2026-04-06-abbreviated-bopomofo-input-design.md`

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `Source/Engine/ReadingTrie.h` | Trie data structure for syllable-level prefix matching |
| Create | `Source/Engine/ReadingTrie.cpp` | Trie implementation |
| Create | `Source/Engine/ReadingTrieTest.cpp` | Unit tests for ReadingTrie |
| Modify | `Source/Engine/Mandarin/Mandarin.h:60` | Add `isConsonantOnly()` to BopomofoSyllable |
| Modify | `Source/Engine/Mandarin/MandarinTest.cpp` | Test isConsonantOnly() |
| Modify | `Source/Engine/ParselessLM.h:37-67` | Add trie member and abbreviated query methods |
| Modify | `Source/Engine/ParselessLM.cpp:37-172` | Build trie on open(), implement abbreviated queries |
| Modify | `Source/Engine/ParselessLMTest.cpp` | Test abbreviated query via ParselessLM |
| Modify | `Source/Engine/McBopomofoLM.h:60-173` | Add abbreviated query delegation |
| Modify | `Source/Engine/McBopomofoLM.cpp:138-231` | Route abbreviated keys through trie |
| Modify | `Source/Engine/McBopomofoLMTest.cpp` | Test abbreviated query via McBopomofoLM |
| Modify | `Source/Engine/CMakeLists.txt:10-32,86-97` | Add ReadingTrie files and test |
| Modify | `Source/KeyHandler.mm:452-577` | Emit consonant-only readings to grid |
| Modify | `McBopomofoTests/KeyHandlerBopomofoTests.swift` | End-to-end abbreviated input tests |

---

### Task 1: Add `isConsonantOnly()` to BopomofoSyllable

**Files:**
- Modify: `Source/Engine/Mandarin/Mandarin.h:60-67`
- Test: `Source/Engine/Mandarin/MandarinTest.cpp`

- [ ] **Step 1: Write failing test for isConsonantOnly()**

Add to `Source/Engine/Mandarin/MandarinTest.cpp`:

```cpp
TEST(MandarinTest, IsConsonantOnly) {
  // Consonant-only syllables
  ASSERT_TRUE(BPMF::FromComposedString("ㄅ").isConsonantOnly());
  ASSERT_TRUE(BPMF::FromComposedString("ㄊ").isConsonantOnly());
  ASSERT_TRUE(BPMF::FromComposedString("ㄕ").isConsonantOnly());
  ASSERT_TRUE(BPMF::FromComposedString("ㄍ").isConsonantOnly());

  // Full syllables - should return false
  ASSERT_FALSE(BPMF::FromComposedString("ㄅㄚ").isConsonantOnly());
  ASSERT_FALSE(BPMF::FromComposedString("ㄊㄨˊ").isConsonantOnly());
  ASSERT_FALSE(BPMF::FromComposedString("ㄕㄨ").isConsonantOnly());

  // Standalone vowels - should return false
  ASSERT_FALSE(BPMF::FromComposedString("ㄚ").isConsonantOnly());
  ASSERT_FALSE(BPMF::FromComposedString("ㄧ").isConsonantOnly());

  // Tone-only - should return false
  ASSERT_FALSE(BPMF::FromComposedString("ˊ").isConsonantOnly());

  // Empty - should return false
  ASSERT_FALSE(BPMF().isConsonantOnly());
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Source/Engine/Mandarin && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/MandarinTest --gtest_filter=MandarinTest.IsConsonantOnly`

Expected: Compilation error — `isConsonantOnly` is not a member of `BopomofoSyllable`.

- [ ] **Step 3: Implement isConsonantOnly()**

In `Source/Engine/Mandarin/Mandarin.h`, after line 67 (`bool hasToneMarker() const`), add:

```cpp
  bool isConsonantOnly() const {
    return hasConsonant() && !hasMiddleVowel() && !hasVowel() &&
           !hasToneMarker();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd Source/Engine/Mandarin && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/MandarinTest --gtest_filter=MandarinTest.IsConsonantOnly`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Source/Engine/Mandarin/Mandarin.h Source/Engine/Mandarin/MandarinTest.cpp
git commit -m "feat: add isConsonantOnly() to BopomofoSyllable"
```

---

### Task 2: Create ReadingTrie class

**Files:**
- Create: `Source/Engine/ReadingTrie.h`
- Create: `Source/Engine/ReadingTrie.cpp`
- Create: `Source/Engine/ReadingTrieTest.cpp`
- Modify: `Source/Engine/CMakeLists.txt`

- [ ] **Step 1: Write failing test for ReadingTrie**

Create `Source/Engine/ReadingTrieTest.cpp`:

```cpp
#include <gtest/gtest.h>

#include "ReadingTrie.h"

namespace McBopomofo {

TEST(ReadingTrieTest, EmptyTrieReturnsNoResults) {
  ReadingTrie trie;
  auto results = trie.findAbbreviated("ㄅ");
  EXPECT_TRUE(results.empty());
}

TEST(ReadingTrieTest, ExactMatchSingleSyllable) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);
  trie.insert("ㄅㄚ", "吧", -4.0);

  // Abbreviated: ㄅ should match both
  auto results = trie.findAbbreviated("ㄅ");
  ASSERT_EQ(results.size(), 2);
  EXPECT_EQ(results[0].value(), "八");
  EXPECT_EQ(results[1].value(), "吧");
}

TEST(ReadingTrieTest, AbbreviatedMultiSyllable) {
  ReadingTrie trie;
  trie.insert("ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ", "圖書館", -5.0);
  trie.insert("ㄊㄞˋ-ㄕ-ㄍㄜ", "太少個", -8.0);

  // All abbreviated: ㄊ-ㄕ-ㄍ
  auto results = trie.findAbbreviated("ㄊ-ㄕ-ㄍ");
  ASSERT_EQ(results.size(), 2);

  // Check values exist (order may vary)
  std::set<std::string> values;
  for (const auto& u : results) values.insert(u.value());
  EXPECT_TRUE(values.count("圖書館"));
  EXPECT_TRUE(values.count("太少個"));
}

TEST(ReadingTrieTest, MixedAbbreviatedAndFull) {
  ReadingTrie trie;
  trie.insert("ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ", "圖書館", -5.0);
  trie.insert("ㄊㄨˊ-ㄕˋ-ㄍㄨㄢˇ", "土石管", -9.0);

  // Mixed: first and third exact, second abbreviated
  auto results = trie.findAbbreviated("ㄊㄨˊ-ㄕ-ㄍㄨㄢˇ");
  ASSERT_EQ(results.size(), 2);
}

TEST(ReadingTrieTest, FullKeyReturnsExactMatch) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);
  trie.insert("ㄅㄞˊ", "白", -4.0);

  // Full key should return only exact match
  auto results = trie.findAbbreviated("ㄅㄚ");
  ASSERT_EQ(results.size(), 1);
  EXPECT_EQ(results[0].value(), "八");
}

TEST(ReadingTrieTest, NoMatchReturnsEmpty) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);

  auto results = trie.findAbbreviated("ㄍ");
  EXPECT_TRUE(results.empty());
}

TEST(ReadingTrieTest, HasAbbreviatedUnigrams) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);

  EXPECT_TRUE(trie.hasAbbreviatedUnigrams("ㄅ"));
  EXPECT_TRUE(trie.hasAbbreviatedUnigrams("ㄅㄚ"));
  EXPECT_FALSE(trie.hasAbbreviatedUnigrams("ㄍ"));
}

}  // namespace McBopomofo
```

- [ ] **Step 2: Create ReadingTrie header**

Create `Source/Engine/ReadingTrie.h`:

```cpp
#ifndef SRC_ENGINE_READINGTRIE_H_
#define SRC_ENGINE_READINGTRIE_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "Mandarin/Mandarin.h"
#include "gramambular2/language_model.h"

namespace McBopomofo {

class ReadingTrie {
 public:
  using Unigram = Formosa::Gramambular2::LanguageModel::Unigram;

  ReadingTrie() = default;

  // Insert an entry. key is a hyphen-separated reading like "ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ".
  void insert(const std::string& key, const std::string& value, double score);

  // Find unigrams matching a key that may contain abbreviated (consonant-only)
  // syllables. Full syllables are matched exactly; consonant-only syllables
  // match any syllable starting with that consonant.
  std::vector<Unigram> findAbbreviated(const std::string& key) const;

  // Returns true if findAbbreviated would return non-empty results.
  bool hasAbbreviatedUnigrams(const std::string& key) const;

  void clear();

 private:
  struct Node {
    std::unordered_map<std::string, std::unique_ptr<Node>> children;
    std::vector<std::pair<std::string, double>> entries;  // value, score
  };

  // Split a hyphen-separated key into syllables.
  static std::vector<std::string> splitKey(const std::string& key);

  // Check if a composed syllable string represents a consonant-only syllable.
  static bool isAbbreviated(const std::string& syllable);

  // Extract the consonant portion from a composed syllable string.
  static std::string consonantOf(const std::string& syllable);

  // Recursive search helper.
  void findRecursive(const Node* node,
                     const std::vector<std::string>& syllables, size_t depth,
                     std::vector<Unigram>& results) const;

  // Recursive existence check helper.
  bool hasRecursive(const Node* node,
                    const std::vector<std::string>& syllables,
                    size_t depth) const;

  Node root_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_READINGTRIE_H_
```

- [ ] **Step 3: Implement ReadingTrie**

Create `Source/Engine/ReadingTrie.cpp`:

```cpp
#include "ReadingTrie.h"

#include <sstream>

namespace McBopomofo {

using BPMF = Formosa::Mandarin::BopomofoSyllable;

void ReadingTrie::insert(const std::string& key, const std::string& value,
                         double score) {
  auto syllables = splitKey(key);
  Node* current = &root_;
  for (const auto& syllable : syllables) {
    auto it = current->children.find(syllable);
    if (it == current->children.end()) {
      current->children[syllable] = std::make_unique<Node>();
    }
    current = current->children[syllable].get();
  }
  current->entries.emplace_back(value, score);
}

std::vector<ReadingTrie::Unigram> ReadingTrie::findAbbreviated(
    const std::string& key) const {
  auto syllables = splitKey(key);
  if (syllables.empty()) return {};

  std::vector<Unigram> results;
  findRecursive(&root_, syllables, 0, results);
  return results;
}

bool ReadingTrie::hasAbbreviatedUnigrams(const std::string& key) const {
  auto syllables = splitKey(key);
  if (syllables.empty()) return false;
  return hasRecursive(&root_, syllables, 0);
}

void ReadingTrie::clear() { root_.children.clear(); }

std::vector<std::string> ReadingTrie::splitKey(const std::string& key) {
  std::vector<std::string> result;
  std::istringstream stream(key);
  std::string token;
  while (std::getline(stream, token, '-')) {
    if (!token.empty()) {
      result.push_back(token);
    }
  }
  return result;
}

bool ReadingTrie::isAbbreviated(const std::string& syllable) {
  auto bpmf = BPMF::FromComposedString(syllable);
  return bpmf.isConsonantOnly();
}

std::string ReadingTrie::consonantOf(const std::string& syllable) {
  auto bpmf = BPMF::FromComposedString(syllable);
  BPMF consonantOnly(bpmf.consonantComponent());
  return consonantOnly.composedString();
}

void ReadingTrie::findRecursive(const Node* node,
                                const std::vector<std::string>& syllables,
                                size_t depth,
                                std::vector<Unigram>& results) const {
  if (depth == syllables.size()) {
    for (const auto& entry : node->entries) {
      results.emplace_back(entry.first, entry.second);
    }
    return;
  }

  const auto& syllable = syllables[depth];

  if (isAbbreviated(syllable)) {
    // Consonant-only: match all children whose consonant matches.
    std::string targetConsonant = syllable;
    for (const auto& [childKey, childNode] : node->children) {
      if (consonantOf(childKey) == targetConsonant) {
        findRecursive(childNode.get(), syllables, depth + 1, results);
      }
    }
  } else {
    // Full syllable: exact match only.
    auto it = node->children.find(syllable);
    if (it != node->children.end()) {
      findRecursive(it->second.get(), syllables, depth + 1, results);
    }
  }
}

bool ReadingTrie::hasRecursive(const Node* node,
                               const std::vector<std::string>& syllables,
                               size_t depth) const {
  if (depth == syllables.size()) {
    return !node->entries.empty();
  }

  const auto& syllable = syllables[depth];

  if (isAbbreviated(syllable)) {
    std::string targetConsonant = syllable;
    for (const auto& [childKey, childNode] : node->children) {
      if (consonantOf(childKey) == targetConsonant) {
        if (hasRecursive(childNode.get(), syllables, depth + 1)) {
          return true;
        }
      }
    }
    return false;
  } else {
    auto it = node->children.find(syllable);
    if (it == node->children.end()) return false;
    return hasRecursive(it->second.get(), syllables, depth + 1);
  }
}

}  // namespace McBopomofo
```

- [ ] **Step 4: Add files to CMakeLists.txt**

In `Source/Engine/CMakeLists.txt`, add `ReadingTrie.h` and `ReadingTrie.cpp` to the `McBopomofoLMLib` library target (after line 31, before the closing parenthesis on line 32):

```cmake
        ReadingTrie.h
        ReadingTrie.cpp
```

Add `ReadingTrieTest.cpp` to the test target (after line 97, before the closing parenthesis):

```cmake
                ReadingTrieTest.cpp
```

- [ ] **Step 5: Build and run tests**

Run: `cd Source/Engine && cmake -DENABLE_TEST=1 -S . -B build && make -C build McBopomofoLMLibTest && ./build/McBopomofoLMLibTest --gtest_filter=ReadingTrieTest.*`

Expected: All 7 ReadingTrieTest tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Source/Engine/ReadingTrie.h Source/Engine/ReadingTrie.cpp Source/Engine/ReadingTrieTest.cpp Source/Engine/CMakeLists.txt
git commit -m "feat: add ReadingTrie for abbreviated syllable matching"
```

---

### Task 3: Integrate ReadingTrie into ParselessLM

**Files:**
- Modify: `Source/Engine/ParselessLM.h`
- Modify: `Source/Engine/ParselessLM.cpp`
- Modify: `Source/Engine/ParselessLMTest.cpp`

- [ ] **Step 1: Write failing tests for abbreviated query**

Add to `Source/Engine/ParselessLMTest.cpp`:

```cpp
namespace {
constexpr char kAbbreviatedSample[] = R"(# format org.openvanilla.mcbopomofo.sorted
ㄅㄚ 八 -3.27631260
ㄅㄚ 吧 -3.59800309
ㄅㄚˊ 拔 -5.43164490
ㄅㄚ-ㄅㄚ 爸爸 -5.10000000
ㄅㄞˊ 白 -4.00000000
ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ 圖書館 -5.50000000
ㄊㄞˋ-ㄕㄠˇ-ㄍㄜˋ 太少個 -9.00000000
)";
}

TEST(ParselessLMTest, AbbreviatedSingleConsonant) {
  ParselessLM lm;
  auto db = std::make_unique<ParselessPhraseDB>(
      kAbbreviatedSample, strlen(kAbbreviatedSample));
  ASSERT_TRUE(lm.open(std::move(db)));

  // ㄅ should match all ㄅ* single-syllable entries
  EXPECT_TRUE(lm.hasAbbreviatedUnigrams("ㄅ"));
  auto results = lm.getAbbreviatedUnigrams("ㄅ");
  EXPECT_GE(results.size(), 3);  // 八, 吧, 拔 (白 starts with ㄅ but has ㄞ vowel - ㄅ matches consonant)

  // Verify score penalty is applied
  for (const auto& u : results) {
    EXPECT_LT(u.score(), 0);  // All scores should be negative (penalized)
  }
}

TEST(ParselessLMTest, AbbreviatedMultiSyllable) {
  ParselessLM lm;
  auto db = std::make_unique<ParselessPhraseDB>(
      kAbbreviatedSample, strlen(kAbbreviatedSample));
  ASSERT_TRUE(lm.open(std::move(db)));

  // ㄊ-ㄕ-ㄍ should match 圖書館 and 太少個
  auto results = lm.getAbbreviatedUnigrams("ㄊ-ㄕ-ㄍ");
  ASSERT_EQ(results.size(), 2);

  std::set<std::string> values;
  for (const auto& u : results) values.insert(u.value());
  EXPECT_TRUE(values.count("圖書館"));
  EXPECT_TRUE(values.count("太少個"));
}

TEST(ParselessLMTest, AbbreviatedNoMatch) {
  ParselessLM lm;
  auto db = std::make_unique<ParselessPhraseDB>(
      kAbbreviatedSample, strlen(kAbbreviatedSample));
  ASSERT_TRUE(lm.open(std::move(db)));

  EXPECT_FALSE(lm.hasAbbreviatedUnigrams("ㄍ-ㄍ-ㄍ"));
  auto results = lm.getAbbreviatedUnigrams("ㄍ-ㄍ-ㄍ");
  EXPECT_TRUE(results.empty());
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd Source/Engine && cmake -DENABLE_TEST=1 -S . -B build && make -C build McBopomofoLMLibTest && ./build/McBopomofoLMLibTest --gtest_filter=ParselessLMTest.Abbreviated*`

Expected: Compilation error — `hasAbbreviatedUnigrams` and `getAbbreviatedUnigrams` not found.

- [ ] **Step 3: Add abbreviated methods to ParselessLM header**

In `Source/Engine/ParselessLM.h`, add includes and new methods. After `#include "ParselessPhraseDB.h"` (line 32), add:

```cpp
#include "ReadingTrie.h"
```

After the `hasUnigrams` declaration (line 54), add:

```cpp
  // Abbreviated (簡拼) query methods. These use a trie index to match
  // consonant-only syllables against all possible completions.
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
  getAbbreviatedUnigrams(const std::string& key);
  bool hasAbbreviatedUnigrams(const std::string& key);
```

After the `db_` member (line 66), add:

```cpp
  ReadingTrie trie_;
  static constexpr double kAbbreviatedScorePenalty = -1.0;
```

- [ ] **Step 4: Implement abbreviated methods in ParselessLM**

In `Source/Engine/ParselessLM.cpp`, add a helper to build the trie, called from `open()`.

After the existing `open(const char* path)` method (line 48), add a private helper. But since it's a method on a class, we'll add it inline. Modify the `open(const char* path)` method to build the trie after opening:

Replace `Source/Engine/ParselessLM.cpp` lines 41-48 with:

```cpp
bool ParselessLM::open(const char* path) {
  if (!mmapedFile_.open(path)) {
    return false;
  }
  db_ = std::unique_ptr<ParselessPhraseDB>(new ParselessPhraseDB(
      mmapedFile_.data(), mmapedFile_.length(), /*validate_pragma=*/true));
  buildTrie();
  return true;
}
```

Replace the `open(unique_ptr<ParselessPhraseDB>)` method (lines 55-62) with:

```cpp
bool ParselessLM::open(std::unique_ptr<ParselessPhraseDB> db) {
  if (db_ != nullptr) {
    return false;
  }
  db_ = std::move(db);
  buildTrie();
  return true;
}
```

Add the `close()` method update (after line 53):

```cpp
void ParselessLM::close() {
  mmapedFile_.close();
  db_ = nullptr;
  trie_.clear();
}
```

Add the `buildTrie()`, `getAbbreviatedUnigrams()`, and `hasAbbreviatedUnigrams()` implementations before the closing namespace brace:

```cpp
void ParselessLM::buildTrie() {
  if (db_ == nullptr) return;

  // Iterate all rows by scanning through the database content.
  // We use findRows with empty prefix to get all rows, but that won't work
  // with the current API. Instead, we parse the getUnigrams results for
  // each entry found by the trie. The trie is built by scanning the raw data.
  //
  // Since ParselessPhraseDB stores data as lines of "key value score\n",
  // we iterate through all lines to build the trie.
  const char* ptr = db_->begin();
  const char* end = db_->end();

  // Skip pragma header if present.
  if (ptr < end && *ptr == '#') {
    while (ptr < end && *ptr != '\n') ++ptr;
    if (ptr < end) ++ptr;
  }

  while (ptr < end) {
    const char* lineStart = ptr;

    // Find key (first space-delimited field)
    while (ptr < end && *ptr != ' ') ++ptr;
    std::string key(lineStart, ptr);

    // Skip space
    if (ptr < end) ++ptr;

    // Find value (second space-delimited field)
    const char* valueStart = ptr;
    while (ptr < end && *ptr != ' ') ++ptr;
    std::string value(valueStart, ptr);

    // Skip space
    if (ptr < end) ++ptr;

    // Find score (rest until newline)
    const char* scoreStart = ptr;
    while (ptr < end && *ptr != '\n') ++ptr;
    double score = 0;
    if (scoreStart < ptr) {
      score = std::stod(std::string(scoreStart, ptr));
    }

    // Skip newline
    if (ptr < end) ++ptr;

    if (!key.empty() && !value.empty()) {
      trie_.insert(key, value, score);
    }
  }
}

std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
ParselessLM::getAbbreviatedUnigrams(const std::string& key) {
  auto results = trie_.findAbbreviated(key);
  // Apply score penalty
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> penalized;
  penalized.reserve(results.size());
  for (const auto& u : results) {
    penalized.emplace_back(u.value(), u.score() + kAbbreviatedScorePenalty);
  }
  return penalized;
}

bool ParselessLM::hasAbbreviatedUnigrams(const std::string& key) {
  return trie_.hasAbbreviatedUnigrams(key);
}
```

Also add the `buildTrie()` private method declaration to the header. In `Source/Engine/ParselessLM.h`, after the `kAbbreviatedScorePenalty` line, add:

```cpp
  void buildTrie();
```

And expose `begin()` / `end()` from `ParselessPhraseDB`. In `Source/Engine/ParselessPhraseDB.h`, add public accessors:

```cpp
  const char* begin() const { return begin_; }
  const char* end() const { return end_; }
```

- [ ] **Step 5: Run tests**

Run: `cd Source/Engine && cmake -DENABLE_TEST=1 -S . -B build && make -C build McBopomofoLMLibTest && ./build/McBopomofoLMLibTest --gtest_filter=ParselessLMTest.Abbreviated*`

Expected: All 3 abbreviated tests PASS.

- [ ] **Step 6: Run all existing tests to verify no regressions**

Run: `cd Source/Engine && ./build/McBopomofoLMLibTest`

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add Source/Engine/ParselessLM.h Source/Engine/ParselessLM.cpp Source/Engine/ParselessPhraseDB.h Source/Engine/ParselessLMTest.cpp
git commit -m "feat: add abbreviated query support to ParselessLM via ReadingTrie"
```

---

### Task 4: Integrate abbreviated queries into McBopomofoLM

**Files:**
- Modify: `Source/Engine/McBopomofoLM.h`
- Modify: `Source/Engine/McBopomofoLM.cpp`
- Modify: `Source/Engine/McBopomofoLMTest.cpp`

- [ ] **Step 1: Write failing test**

Add to `Source/Engine/McBopomofoLMTest.cpp`:

```cpp
TEST(McBopomofoLMTest, AbbreviatedQuery) {
  McBopomofoLM lm;
  constexpr char kData[] = R"(# format org.openvanilla.mcbopomofo.sorted
ㄅㄚ 八 -3.27631260
ㄅㄚ 吧 -3.59800309
ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ 圖書館 -5.50000000
)";
  auto db = std::make_unique<ParselessPhraseDB>(kData, strlen(kData));
  lm.loadLanguageModel(std::move(db));

  // Abbreviated single consonant
  EXPECT_TRUE(lm.hasUnigrams("ㄅ"));
  auto results = lm.getUnigrams("ㄅ");
  EXPECT_GE(results.size(), 2);

  // Abbreviated multi-syllable
  EXPECT_TRUE(lm.hasUnigrams("ㄊ-ㄕ-ㄍ"));
  auto multiResults = lm.getUnigrams("ㄊ-ㄕ-ㄍ");
  ASSERT_EQ(multiResults.size(), 1);
  EXPECT_EQ(multiResults[0].value(), "圖書館");

  // Full key still works as before
  EXPECT_TRUE(lm.hasUnigrams("ㄅㄚ"));
  auto fullResults = lm.getUnigrams("ㄅㄚ");
  ASSERT_GE(fullResults.size(), 2);
  EXPECT_EQ(fullResults[0].value(), "八");
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd Source/Engine && cmake -DENABLE_TEST=1 -S . -B build && make -C build McBopomofoLMLibTest && ./build/McBopomofoLMLibTest --gtest_filter=McBopomofoLMTest.AbbreviatedQuery`

Expected: FAIL — `hasUnigrams("ㄅ")` returns false because the current implementation only does exact matching.

- [ ] **Step 3: Modify McBopomofoLM to support abbreviated queries**

In `Source/Engine/McBopomofoLM.cpp`, modify `hasUnigrams()` (lines 221-231). Add a helper to detect abbreviated keys, then fall back to abbreviated query:

Add this helper function at the top of the file (after the namespace opening):

```cpp
static bool ContainsAbbreviatedSyllable(const std::string& key) {
  std::istringstream stream(key);
  std::string token;
  while (std::getline(stream, token, '-')) {
    if (!token.empty()) {
      auto syllable =
          Formosa::Mandarin::BopomofoSyllable::FromComposedString(token);
      if (syllable.isConsonantOnly()) {
        return true;
      }
    }
  }
  return false;
}
```

Add `#include <sstream>` to the includes at the top.

Replace the `hasUnigrams` method (lines 221-231):

```cpp
bool McBopomofoLM::hasUnigrams(const std::string& key) {
  if (key == " ") {
    return true;
  }

  if (!excludedPhrases_.hasUnigrams(key)) {
    if (userPhrases_.hasUnigrams(key) || languageModel_.hasUnigrams(key)) {
      return true;
    }
    // Fall back to abbreviated matching if key contains consonant-only syllables.
    if (ContainsAbbreviatedSyllable(key)) {
      return languageModel_.hasAbbreviatedUnigrams(key);
    }
    return false;
  }

  return !getUnigrams(key).empty();
}
```

Modify `getUnigrams` (lines 138-218) to include abbreviated results. After the existing logic that builds `allUnigrams` (before the return on line 218), add abbreviated results:

Before the final `return allUnigrams;`, insert:

```cpp
  // If key contains abbreviated syllables and we have no exact matches,
  // or to supplement exact matches, query the trie.
  if (ContainsAbbreviatedSyllable(key)) {
    auto abbreviatedUnigrams = languageModel_.getAbbreviatedUnigrams(key);
    // Filter out duplicates already in allUnigrams.
    for (const auto& u : abbreviatedUnigrams) {
      if (insertedValues.find(u.value()) == insertedValues.end()) {
        allUnigrams.push_back(u);
        insertedValues.insert(u.value());
      }
    }
  }
```

- [ ] **Step 4: Run test**

Run: `cd Source/Engine && cmake -DENABLE_TEST=1 -S . -B build && make -C build McBopomofoLMLibTest && ./build/McBopomofoLMLibTest --gtest_filter=McBopomofoLMTest.AbbreviatedQuery`

Expected: PASS

- [ ] **Step 5: Run all existing tests**

Run: `cd Source/Engine && ./build/McBopomofoLMLibTest`

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Source/Engine/McBopomofoLM.h Source/Engine/McBopomofoLM.cpp Source/Engine/McBopomofoLMTest.cpp
git commit -m "feat: integrate abbreviated queries into McBopomofoLM"
```

---

### Task 5: Modify KeyHandler to emit consonant-only readings

**Files:**
- Modify: `Source/KeyHandler.mm:452-577`

This is the most delicate change. We modify the BPMF key handling section so that:
1. **Auto-trigger**: When buffer has consonant-only and new key is also a consonant, emit the old consonant as a reading.
2. **Explicit trigger**: When Space/Enter is pressed with consonant-only buffer, emit it as a reading.

- [ ] **Step 1: Add consonant-only auto-trigger logic**

In `Source/KeyHandler.mm`, find the section after `_bpmfReadingBuffer->combineKey((char)charCode);` (line 460). The current code checks `if (!_bpmfReadingBuffer->hasToneMarker())` and returns early. We need to intercept *before* combineKey when the buffer already has a consonant-only syllable and the new key would also be a consonant.

Replace lines 457-470 with:

```objc
    // see if it's valid BPMF reading
    bool isValidKey = _bpmfReadingBuffer->isValidKey((char)charCode);
    if (!skipBpmfHandling && isValidKey) {
        // Abbreviated input: if buffer has consonant-only and new key is a consonant,
        // emit the current consonant as an abbreviated reading before processing the new key.
        if (!_bpmfReadingBuffer->isEmpty() &&
            _bpmfReadingBuffer->syllable().isConsonantOnly()) {
            // Check if the new key would start a new consonant (i.e., the new key
            // maps to a consonant component).
            Formosa::Mandarin::BopomofoReadingBuffer testBuffer(_bpmfReadingBuffer->keyboardLayout());
            testBuffer.combineKey((char)charCode);
            if (!testBuffer.isEmpty() && testBuffer.syllable().isConsonantOnly()) {
                // The new key is also a consonant. Emit the current consonant.
                std::string reading = _bpmfReadingBuffer->syllable().composedString();
                if (_languageModel->hasUnigrams(reading)) {
                    _grid->insertReading(reading);
                    [self _walk];
                }
                _bpmfReadingBuffer->clear();
            }
        }

        _bpmfReadingBuffer->combineKey((char)charCode);
        keyConsumedByReading = YES;

        // if we have a tone marker, we have to insert the reading to the
        // builder in other words, if we don't have a tone marker, we just
        // update the composing buffer
        if (!_bpmfReadingBuffer->hasToneMarker()) {
            stateCallback([self buildInputtingState]);
            return YES;
        }
    }
```

- [ ] **Step 2: Add explicit trigger for consonant-only + Space/Enter**

The existing `composeReading` logic on line 500-504 already handles Space/Enter when buffer is non-empty:

```objc
composeReading |= (!_bpmfReadingBuffer->isEmpty() && (charCode == 32 || charCode == 13));
```

This means when the user presses Space with a consonant-only buffer like "ㄊ", `composeReading` becomes true. Then on line 507, `reading = _bpmfReadingBuffer->syllable().composedString()` produces "ㄊ". On line 510, `_languageModel->hasUnigrams(reading)` is called.

With our McBopomofoLM changes from Task 4, `hasUnigrams("ㄊ")` now returns true (via abbreviated matching). So **the explicit trigger already works** — no additional code changes needed for Space/Enter.

- [ ] **Step 3: Run existing C++ tests for regression**

Run: `cd Source/Engine && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/McBopomofoLMLibTest && cd Mandarin && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/MandarinTest && cd ../gramambular2 && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/gramambular2_test`

Expected: All C++ tests PASS.

- [ ] **Step 4: Commit**

```bash
git add Source/KeyHandler.mm
git commit -m "feat: emit consonant-only readings for abbreviated input"
```

---

### Task 6: ReadingGrid integration test

**Files:**
- Modify: `Source/Engine/gramambular2/reading_grid_test.cpp`

- [ ] **Step 1: Write integration test**

Add to `Source/Engine/gramambular2/reading_grid_test.cpp`. This test verifies that ReadingGrid correctly walks a grid with abbreviated readings when backed by an LM that supports them.

First, we need to create a test LM that supports abbreviated queries. Add this test at the end of the file:

```cpp
// A test LM that simulates abbreviated input support.
class AbbreviatedLM : public Formosa::Gramambular2::LanguageModel {
 public:
  std::vector<Unigram> getUnigrams(const std::string& reading) override {
    auto it = data_.find(reading);
    if (it != data_.end()) return it->second;
    return {};
  }
  bool hasUnigrams(const std::string& reading) override {
    return data_.find(reading) != data_.end();
  }
  void addEntry(const std::string& reading, const std::string& value,
                double score) {
    data_[reading].emplace_back(value, score);
  }
 private:
  std::unordered_map<std::string, std::vector<Unigram>> data_;
};

TEST(ReadingGridTest, AbbreviatedReadingsWalk) {
  auto lm = std::make_shared<AbbreviatedLM>();
  // Single consonant entries (abbreviated single chars)
  lm->addEntry("ㄊ", "他", -4.0);
  lm->addEntry("ㄕ", "是", -3.5);
  lm->addEntry("ㄍ", "個", -4.5);

  // Multi-syllable abbreviated phrase
  lm->addEntry("ㄊ-ㄕ-ㄍ", "圖書館", -5.0);

  Formosa::Gramambular2::ReadingGrid grid(lm);
  grid.insertReading("ㄊ");
  grid.insertReading("ㄕ");
  grid.insertReading("ㄍ");

  auto result = grid.walk();
  ASSERT_FALSE(result.vertices.empty());

  // The walk should prefer "圖書館" (span=3, score=-5.0)
  // over "他"+"是"+"個" (sum of scores: -4.0 + -3.5 + -4.5 = -12.0)
  // Since -5.0 > -12.0, the phrase wins.
  std::string combined;
  for (const auto& node : result.vertices) {
    combined += node->value();
  }
  EXPECT_EQ(combined, "圖書館");
}
```

- [ ] **Step 2: Run test**

Run: `cd Source/Engine/gramambular2 && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/gramambular2_test --gtest_filter=ReadingGridTest.AbbreviatedReadingsWalk`

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add Source/Engine/gramambular2/reading_grid_test.cpp
git commit -m "test: add ReadingGrid integration test for abbreviated input"
```

---

### Task 7: End-to-end KeyHandler tests (Swift)

**Files:**
- Modify: `McBopomofoTests/KeyHandlerBopomofoTests.swift`

- [ ] **Step 1: Write abbreviated input test**

Add test methods to `KeyHandlerBopomofoTests.swift`. These tests simulate typing consonant-only keys and verify the composing buffer and candidate behavior.

```swift
// MARK: - Abbreviated Input (簡拼) Tests

func testAbbreviatedInputAutoTrigger() {
    // Type ㄊ (key 'w' on standard layout) then ㄕ (key 'g')
    // Since both are consonants, ㄊ should auto-emit as abbreviated reading
    // when ㄕ is pressed.
    let input1 = KeyHandlerInput(
        inputText: "w", keyCode: 0, charCode: UInt16(Character("w").asciiValue!),
        flags: [], isVerticalMode: false)
    var state: InputState = InputState.Empty()
    handler.handle(input: input1, state: state) { newState in
        state = newState
    } errorCallback: {
    }
    // After typing ㄊ alone, should still be in composing buffer (not yet emitted)
    XCTAssertTrue(state is InputState.Inputting)

    let input2 = KeyHandlerInput(
        inputText: "g", keyCode: 0, charCode: UInt16(Character("g").asciiValue!),
        flags: [], isVerticalMode: false)
    handler.handle(input: input2, state: state) { newState in
        state = newState
    } errorCallback: {
    }
    // After typing ㄕ, ㄊ should have been emitted as abbreviated reading
    // and ㄕ should be in the composing buffer
    XCTAssertTrue(state is InputState.Inputting)
}

func testAbbreviatedInputExplicitTrigger() {
    // Type ㄊ then Space - consonant should be emitted as abbreviated reading
    let input1 = KeyHandlerInput(
        inputText: "w", keyCode: 0, charCode: UInt16(Character("w").asciiValue!),
        flags: [], isVerticalMode: false)
    var state: InputState = InputState.Empty()
    handler.handle(input: input1, state: state) { newState in
        state = newState
    } errorCallback: {
    }

    let spaceInput = KeyHandlerInput(
        inputText: " ", keyCode: 0, charCode: 32,
        flags: [], isVerticalMode: false)
    handler.handle(input: spaceInput, state: state) { newState in
        state = newState
    } errorCallback: {
    }
    // The consonant-only reading should have been accepted
    XCTAssertTrue(state is InputState.Inputting || state is InputState.ChoosingCandidate)
}
```

- [ ] **Step 2: Build and run Swift tests**

Run: `cd /Users/maxmilian/commeet/McBopomofo && xcodebuild -scheme McBopomofo -configuration Debug test -only-testing:McBopomofoTests/KeyHandlerBopomofoTests/testAbbreviatedInputAutoTrigger -only-testing:McBopomofoTests/KeyHandlerBopomofoTests/testAbbreviatedInputExplicitTrigger 2>&1 | tail -20`

Expected: PASS (or adjust test based on actual KeyHandlerInput constructor — consult `McBopomofoTests/KeyHandlerBopomofoTests.swift` for the correct initializer pattern used in existing tests).

- [ ] **Step 3: Run all Swift tests for regression**

Run: `cd /Users/maxmilian/commeet/McBopomofo && xcodebuild -scheme McBopomofo -configuration Debug test 2>&1 | tail -30`

Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add McBopomofoTests/KeyHandlerBopomofoTests.swift
git commit -m "test: add end-to-end abbreviated input tests for KeyHandler"
```

---

## Review Checkpoint

After Task 7, all layers are complete:

1. **BopomofoSyllable** — `isConsonantOnly()` helper
2. **ReadingTrie** — syllable-level trie for prefix matching
3. **ParselessLM** — builds trie on load, provides `getAbbreviatedUnigrams()`
4. **McBopomofoLM** — routes abbreviated keys through trie via `ContainsAbbreviatedSyllable()`
5. **KeyHandler** — emits consonant-only readings (auto + explicit trigger)
6. **ReadingGrid** — no changes needed, works via existing Viterbi walk
7. **Tests** — unit tests at each layer + integration + end-to-end

Run the full test suite to verify everything works:

```bash
# C++ tests
cd Source/Engine && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/McBopomofoLMLibTest
cd Source/Engine/Mandarin && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/MandarinTest
cd Source/Engine/gramambular2 && cmake -DENABLE_TEST=1 -S . -B build && make -C build && ./build/gramambular2_test

# Swift tests
cd /Users/maxmilian/commeet/McBopomofo && xcodebuild -scheme McBopomofo -configuration Debug test
```
