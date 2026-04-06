# Abbreviated Bopomofo Input (簡拼/縮打) Design

## Overview

Add abbreviated input support to McBopomofo, allowing users to type only the consonant (聲母) of a Bopomofo syllable instead of the full syllable. The system matches partial input against dictionary phrases, prioritizing multi-character phrase matches.

Example: typing `ㄊ ㄕ ㄍ` (three consonants) matches "圖書館" without needing to type `ㄊㄨˊ ㄕㄨ ㄍㄨㄢˇ`.

## Requirements

- **Mixed mode**: Any syllable position can be either a full syllable or an abbreviated consonant-only input. The system handles both transparently.
- **Dual trigger mechanism**: Abbreviated consonants are sent to the reading grid via (1) automatic detection when a consonant is followed by another consonant, and (2) explicit trigger via Space/Enter when the buffer contains only a consonant.
- **Phrase-first ranking**: Leverage ReadingGrid's existing Viterbi walk to naturally favor multi-character phrase matches over individual character matches.
- **Standard layout only**: Initial implementation supports only the Standard (標準) keyboard layout.
- **Always on**: No preference toggle; the feature is integrated into the normal input flow without disrupting full-syllable input.
- **No minimum length**: Even a single consonant is accepted as abbreviated input.

## Architecture

### Approach: Language Model Layer Expansion

Changes are concentrated in the language model layer (`ParselessLM` / `ParselessPhraseDB`). When a reading key contains abbreviated consonants, the LM performs prefix matching instead of exact matching. ReadingGrid and KeyHandler require minimal changes.

This was chosen over two alternatives:
- **Pre-built abbreviated dictionary** (rejected): Would massively inflate dictionary size and complicate the data pipeline, especially for user-defined phrases.
- **ReadingGrid-layer expansion** (rejected): Would cause exponential DAG growth when multiple consonants are combined, creating the highest performance risk.

## Detailed Design

### 1. Consonant Detection and Submission

#### The 21 Bopomofo Consonants

ㄅ ㄆ ㄇ ㄈ ㄉ ㄊ ㄋ ㄌ ㄍ ㄎ ㄏ ㄐ ㄑ ㄒ ㄓ ㄔ ㄕ ㄖ ㄗ ㄘ ㄙ

#### Automatic Trigger

In `BopomofoReadingBuffer::combineKey()`, when the buffer contains only a consonant and the new key press is also a consonant:

1. Emit the current consonant as an abbreviated reading into the ReadingGrid.
2. Clear the buffer and begin composing the new consonant.

#### Explicit Trigger

When the user presses Space or Enter while the buffer contains only a consonant (no middle vowel, vowel, or tone marker), emit the consonant as an abbreviated reading.

#### Identification

A `BopomofoSyllable` with only the consonant component set (middleVowel, vowel, toneMarker all empty) is naturally distinguishable as an abbreviated input. No additional flags or markers are needed.

### 2. Language Model Prefix Matching

#### Current Behavior

`ParselessLM::getUnigrams(key)` performs exact binary search in `ParselessPhraseDB`. For example, `ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ` returns unigrams for "圖書館".

#### New Behavior

When a key contains abbreviated syllables (consonant-only segments), the LM switches to prefix matching mode.

#### Trie Index

A new Trie structure is built at data load time (`open()` phase), alongside the existing binary-search index:

- **Node granularity**: Each Trie level corresponds to one syllable position in the reading key.
- **Branching**: Each node branches by full syllable values (approximately 400 possible syllables).
- **Leaf data**: Pointers to the unigram entries in the existing phrase database.

#### Query Algorithm

For a key like `ㄊ-ㄕ-ㄍ`:

```
Level 0 (ㄊ): consonant-only → traverse ALL child nodes starting with ㄊ
             (ㄊㄚ, ㄊㄞ, ㄊㄨˊ, ㄊㄧㄢ, ...)
Level 1 (ㄕ): consonant-only → traverse ALL child nodes starting with ㄕ
             (ㄕㄨ, ㄕㄨㄟˇ, ㄕ, ...)
Level 2 (ㄍ): consonant-only → traverse ALL child nodes starting with ㄍ
             (ㄍㄨㄢˇ, ㄍㄜ, ...)
→ Collect all leaf nodes reached, return their unigrams
```

For a mixed key like `ㄊㄨˊ-ㄕ-ㄍㄨㄢˇ`:

```
Level 0 (ㄊㄨˊ): full syllable → exact match, traverse single child
Level 1 (ㄕ):    consonant-only → traverse all ㄕ* children
Level 2 (ㄍㄨㄢˇ): full syllable → exact match, traverse single child
→ Narrower result set, higher relevance
```

#### Score Penalty

Abbreviated matches receive a score penalty to prevent them from outranking exact matches:

- Full syllable match: original unigram score
- Contains abbreviated syllable(s): original score + penalty (initial value: -1.0, subject to tuning)

This ensures that when a user types a complete syllable, the candidates from exact matching always rank above abbreviated matches.

### 3. ReadingGrid Integration

#### Minimal Changes

The ReadingGrid core logic (`insertReading`, `expandGridAt`, `walk`) remains largely unchanged:

- **`hasUnigrams(reading)`**: Must return `true` for abbreviated readings (consonant-only syllables) by delegating to the LM's prefix matching.
- **`expandGridAt()`**: When building multi-syllable spans, the combined key (e.g., `ㄊ-ㄕ-ㄍ`) is passed to `getUnigrams()`. The LM layer handles the prefix expansion transparently.
- **Viterbi walk**: No changes. Long phrases naturally score higher than combinations of single characters.

#### Reading Replacement on Selection

When a user selects an abbreviated match (e.g., "圖書館" from `ㄊ-ㄕ-ㄍ`), the abbreviated readings in the grid are replaced with the candidate's full readings (`ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ`). This ensures subsequent Viterbi walks use correct full syllables.

### 4. Composing Buffer Display

While the user types abbreviated input, the composing buffer displays the consonant symbols directly:

```
Input: ㄊ ㄕ ㄍ
Display: ㄊㄕㄍ
```

The display updates to the selected text only after the user confirms a candidate.

## Edge Cases

| Case | Handling |
|------|----------|
| Consonants that are valid standalone syllables (ㄓ, ㄔ, ㄕ, ㄖ, ㄗ, ㄘ, ㄙ) | Treated as both exact match (higher score) and abbreviated prefix match simultaneously |
| User-defined phrases | Added to the Trie at load time; automatically support abbreviated input |
| Associated phrases (聯想詞) | Unaffected; triggered by confirmed text, independent of input method |
| Backspace on abbreviated reading | Normal deletion from the grid, same as full readings |
| Punctuation and special keys | Not part of abbreviated logic; existing behavior preserved |
| No candidates found for abbreviation | The consonant remains in the grid; user can continue typing vowel/tone to complete the syllable |

## Performance

- **Trie memory**: ~400 syllables per level, max depth 8 (dictionary max phrase length). With ~160K entries, estimated overhead < 10 MB.
- **Query latency**: Trie branches converge quickly at deeper levels due to limited real phrase combinations. Estimated < 1ms per query. Benchmark during development; add caching if needed.
- **No impact on full-syllable input**: Exact matches bypass the Trie entirely, using the existing binary search path.

## Scope

### In Scope
- Consonant-only abbreviated input for Standard keyboard layout
- Trie-based prefix matching in ParselessLM
- Automatic and explicit trigger mechanisms
- Score penalty for abbreviated matches
- Reading replacement on candidate selection

### Out of Scope (Future Work)
- Other keyboard layouts (Eten, Hsu, Eten26, IBM, HanyuPinyin)
- Consonant + partial vowel abbreviation (e.g., ㄊㄨ without tone)
- Frequency learning / adaptive ranking for abbreviated input
- Abbreviated input in user phrase editing mode
