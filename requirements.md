# Requirements: Contextual User Model for McBopomofo

<metadata>

- **Scope**: Contextual user model design and implementation
  requirements across 6 functional requirements (FR-0
  through FR-5) mapped to Job Stories and EARS acceptance
  criteria
- **Load if**: Working on the user model, dynamic span
  length, or KeyHandler user-adaptation features
- **Related**: `algorithm.md`, `AGENTS.md`,
  `Source/Engine/ContextualUserModel.h`,
  `Source/Engine/gramambular2/`
- **Format**: Job Stories (situation-based motivation) +
  EARS (testable acceptance criteria) + structured XML
  tags per smith conventions

</metadata>

## 1. Context

<context>

### Problem Statement

McBopomofo learns user candidate preferences through
`UserOverrideModel`, an in-memory LRU cache keyed by an
exact (context, reading) match. It has two structural
limitations:

- **No persistence**: learned preferences are lost every
  time the input method restarts.
- **No generalization**: exact-key matching means a
  candidate the user has confirmed in many different
  contexts receives no boost at all in a context it has
  never been seen in.

The wider score landscape (`kOverridingScore = 42` for
forced overrides, score 0 for user phrases with the
`topScore + epsilon` single-syllable rewrite in
`McBopomofoLM`) is retained as-is: it is how candidate
overrides are expressed to the walk, and replacing it is
out of scope for this effort.

### Algorithm Background

PR #777 replaced the old DAG+TopologicalSort+Relax walk
with a ~30-line forward-pass Viterbi DP in
`ReadingGrid::walk()`. The algorithm runs in O(|V|+|E|)
time on the reading lattice and is the canonical walk
implementation on master. **This effort does not touch the
walk algorithm.** An earlier attempt (PR #779) extracted
the walk behind a `WalkStrategy` abstraction and threaded
the user model through the forward pass; that design was
dropped after maintainer feedback -- the abstraction was
speculative (YAGNI) and the model integration belongs at
the KeyHandler call sites, not inside the walk. The
dynamic-span-length portion of #779 was carved out into
PR #844. Walk details are documented in `algorithm.md`
(updated in PR #785).

### Solution Overview

`ContextualUserModel` is a drop-in successor to
`UserOverrideModel`:

```
Model (Source/Engine/ContextualUserModel.{h,cpp}):
  Two-level interpolated Kneser-Ney scoring
    Level 1: discounted user bigram counts
    Level 2: continuation probability
             (distinct-context counts, per reading)
  Insufficient evidence -> empty suggestion
    -> walk falls back to base LM scores naturally
       (lower backoff levels are implicit)

Persistence:
  contextual-user-model.txt (TSV v1, atomic save)
  Survives restarts; observations decay by wall-clock
  time; LRU-bounded

Integration (KeyHandler):
  Same observe()/suggest() walk-based interface as
  UserOverrideModel; suggestions applied through the
  existing overrideCandidate() + re-walk; the walk
  algorithm itself is untouched
```

</context>

### Design Principles

<required>

1. **The walk algorithm is untouched.** No strategy
   abstraction, no model hooks in the forward pass, no
   structural-fix bookkeeping inside the grid. User
   preferences enter the walk exclusively through the
   existing `overrideCandidate()` mechanism, exactly as
   they do today with `UserOverrideModel`.

2. **Drop-in interface compatibility.** `observe()` and
   `suggest()` take the same walk-based arguments as
   `UserOverrideModel`, including the three observe cases
   (same-length override; phrase building with
   `forceHighScoreOverride`; phrase breaking judged from
   the post-override walk) and the punctuation /
   sentence-start `"()"` context marker. KeyHandler call
   sites swap models without reshaping.

3. **Self-contained model, implicit base LM.** The model
   holds no pointer to the base language model. When it
   has no or too little evidence it returns an empty
   suggestion; the caller leaves the grid alone and the
   walk falls back to base LM scores naturally. This makes
   the base-LM levels of the Kneser-Ney backoff implicit
   and eliminates the base-LM lifetime coupling (and the
   aliasing-`shared_ptr` construction it would have
   required) by construction.

4. **Data safety by separation.** The model reads and
   writes only its own file, `contextual-user-model.txt`,
   in the user data folder. User phrase files are never
   touched, and `UserOverrideModel` had no persisted data
   to begin with, so there is no migration risk and no
   data-loss risk.

5. **Each PR compiles and passes tests independently.**
   The implementation lands as PR #844 (dynamic span,
   base master), PR #780 (model, base master), and
   PR #781 (KeyHandler integration, base #780).

</required>

---

## 2. Job Story Map

### Backbone: Functional Jobs

Four functional jobs organize the 6 functional
requirements:

- **J1: Match All Dictionary Entries** (dynamic span)
- **J2: Learn User Preferences** (scoring model)
- **J3: Persist Learning** (save/load/wire)
- **J4: Maintain Codebase** (docs/cleanup)

### Body: Job Stories by Job

**J1: Match All Dictionary Entries**

- When dictionary entries exceed 8 syllables, I want
  dynamic span length so all entries can match -- FR-1

**J2: Learn User Preferences**

- When I repeatedly choose a candidate in a specific
  context, I want the system to learn this with proper
  statistical backing so I get context-appropriate
  suggestions -- FR-2
- When I have confirmed a candidate in several different
  contexts, I want it suggested in contexts I have not
  typed before, so learning generalizes -- FR-2

**J3: Persist Learning**

- When I select candidates during typing, I want the
  ObjC++/Swift layer to wire through to the C++ engine so
  my selections drive learning -- FR-3
- When I restart the input method, I want my learned
  preferences preserved so I do not start from
  scratch -- FR-2, FR-3

**J4: Maintain Codebase**

- When algorithm documentation is stale, I want it updated
  to match actual code so AI agents do not regress to old
  algorithms -- FR-0
- When the legacy model is fully replaced and proven, I
  want its dead code removed so the codebase is
  simpler -- FR-4

### Walking Skeleton (MVP)

FR-0 -> FR-1 -> FR-2 -> FR-3

This path delivers a working end-to-end contextual user
model: documentation updated (FR-0), span infrastructure
generalized (FR-1), scoring model created (FR-2), and
integrated into the macOS input method (FR-3). FR-4
(legacy removal) and FR-5 (migration assessment) are
post-MVP follow-ups.

---

## 3. Functional Requirements

### FR-0: Algorithm Documentation Update

**Job Story**: When algorithm documentation describes a
walk algorithm or scoring model that differs from the
current design, I want `algorithm.md` to accurately reflect
both the Viterbi DP walk (PR #777) and the scoring model
rationale (smoothing algorithm comparison leading to the
two-level interpolated KN design), so contributors,
reviewers, and AI agents do not misunderstand the
algorithms, regress to prior implementations, or re-derive
design decisions that were already resolved -- as occurred
in PR #779, where outdated pseudocode in `algorithm.md` was
copied verbatim into new code.

<required>

**Acceptance Criteria** (EARS):

- WHEN the walk algorithm section is read, THE SYSTEM
  documentation SHALL describe Viterbi DP (forward pass +
  backward pass), not DAG shortest-path with topological
  sort.
- WHEN the algorithm steps are documented, THE SYSTEM
  documentation SHALL present a 2-step process: (a) forward
  pass computing cumulative scores via relaxation, (b)
  backward pass reconstructing the optimal path from the DP
  table.
- WHEN the DP state is documented, THE SYSTEM documentation
  SHALL describe the per-position state structure
  (cumulative score, backpointer to source position and
  source node).
- WHEN the lattice structure is explained, THE SYSTEM
  documentation SHALL state that the linear lattice provides
  natural topological order, eliminating the need for
  explicit topological sort.
- WHEN the scoring model is explained, THE SYSTEM
  documentation SHALL note that log-probabilities make
  larger scores better (relaxation uses `>` not `<`).
- WHEN performance is documented, THE SYSTEM documentation
  SHALL characterize the walk as O(|V|+|E|) on the lattice
  and cite measured stress-test figures.
- WHEN file or line references appear, THE SYSTEM
  documentation SHALL match the actual code on master.
- WHEN smoothing algorithm alternatives are presented,
  THE SYSTEM documentation SHALL compare at minimum:
  Absolute Discounting, Standard Kneser-Ney, Modified
  Kneser-Ney, Bayesian/Dirichlet, Witten-Bell,
  Jelinek-Mercer, and Stupid Backoff, with pros, cons,
  and applicability to the sparse-user-data-with-strong-
  base-LM scenario.
- WHEN the rationale for the KN continuation level is
  explained, THE SYSTEM documentation SHALL present the
  single-context over-generalization problem (a word
  observed in only one context should not dominate in
  unrelated contexts) as the key insight distinguishing
  KN's continuation probability from simpler methods.
- WHEN the scoring design is documented, THE SYSTEM
  documentation SHALL present the two-level interpolated
  KN model with the implicit base-LM fallback (empty
  suggestion), not a four-level backoff chain.
- WHEN temporal decay is documented, THE SYSTEM
  documentation SHALL present the exponential decay formula
  with the half-life unit (seconds) and explain the
  parameter's effect on balancing recent preferences
  against long-term base LM scores.
- WHEN smoothing references are listed, THE SYSTEM
  documentation SHALL cite: (a) Jurafsky & Martin SLP3
  Ch. 3 (Smoothing, Backoff vs Interpolation, Kneser-Ney)
  and Appendix C (Kneser-Ney detail), (b) Manning &
  Schutze FSNLP Ch. 6 sections 6.3-6.4 (Good-Turing,
  Katz backoff, linear interpolation), (c) Chen & Goodman
  (1999) for the definitive empirical comparison.

</required>

<context>

**Motivation**:

- PR #779 regression incident: outdated DAG pseudocode in
  `algorithm.md` was copied into new code, regressing walk
  performance by roughly an order of magnitude on the
  8001-reading stress test.
- The postmortem identified anchoring bias on formatted
  docs as the root cause.
- This FR ensures documentation stays synchronized with
  code.

**Scoring Model Citations**:

- Jurafsky & Martin, SLP3 Ch. 3 Sec. 3.4+ (Smoothing,
  Backoff vs Interpolation, Kneser-Ney) and Appendix C
  (Kneser-Ney detail)
- Manning & Schutze, FSNLP Ch. 6 Sec. 6.3-6.4
  (Good-Turing, Katz backoff, linear interpolation)
- Chen, S. F. & Goodman, J. (1999). An empirical study of
  smoothing techniques for language modeling. *Computer
  Speech & Language*, 13(4), 359-394.

</context>

**Tests**: N/A (documentation only).

**Status**: In review | **PR**: #785
| **Branch**: `docs/algorithm_viterbi`

---

### FR-1: Dynamic Span Length

**Job Story**: When the base dictionary contains entries
longer than 8 syllables, I want the reading grid to support
spans of any length determined by the language model, so I
can match all dictionary entries without artificial
truncation.

<required>

**Acceptance Criteria** (EARS):

- WHEN the language model reports a maximum key
  length N > 0 via `maxKeyLength()`, THE SYSTEM SHALL set
  the grid's maximum span length to N.
- WHEN the language model reports a maximum key length of
  0 (the default, meaning "unknown"), THE SYSTEM SHALL
  default the maximum span length to
  `kDefaultMaxSpanLength = 8`.
- WHEN a span is queried via `nodeOf()` for a length
  exceeding its capacity, THE SYSTEM SHALL return a null
  sentinel (a const reference to a null `NodePtr`) without
  undefined behavior.
- WHEN a node is added to a span with spanning length
  exceeding current capacity, THE SYSTEM SHALL grow the
  span's vector to accommodate it.
- WHILE the grid is operating, THE SYSTEM SHALL use the
  runtime maximum span length (not a compile-time
  constant) as the loop bound when expanding the grid.
- WHEN `Span::nodeOf()` is called, THE SYSTEM SHALL keep
  the const-reference return introduced in #841 (no
  `shared_ptr` copies).
- WHEN all changes are complete, THE SYSTEM SHALL pass all
  21 baseline ReadingGrid tests unchanged.

</required>

<context>

**Design**:

The `LanguageModel` interface gains an optional method:

```cpp
virtual size_t maxKeyLength() const { return 0; }
```

`Span::nodes_` changes from `std::array<NodePtr, 8>` to
`std::vector<NodePtr>`, grown on demand. The constant
`kMaximumSpanLength` is renamed `kDefaultMaxSpanLength`
and is used only as the fallback when the language model
does not report a maximum key length. The walk algorithm
is completely untouched: master's forward-pass Viterbi DP
from PR #777 stays as-is.

**Files Modified** (per PR #844):

- `language_model.h` -- added `virtual size_t
  maxKeyLength() const` with default 0
- `reading_grid.h` -- `Span::nodes_`: `std::array` to
  `std::vector`; `kMaximumSpanLength` renamed
  `kDefaultMaxSpanLength`; runtime max span length
- `reading_grid.cpp` -- span window driven by the runtime
  maximum span length
- `reading_grid_test.cpp` -- new `DynamicSpanLength` test

**Implementation Notes**:

- Out-of-range `nodeOf()` lookups return a null sentinel
  instead of asserting, since dynamically sized vectors
  make assertion-based bounds checking inappropriate.
- Backward compatibility: existing `LanguageModel`
  subclasses inherit `maxKeyLength() { return 0; }`, so
  the grid defaults to 8 and behavior is identical.
- The 8001-reading StressTest shows no regression
  (median 1499us vs 1580us on master, identical vertex
  and edge counts).

</context>

**Tests**:

- **1.T1** `ReadingGridTest::DynamicSpanLength`: spans
  longer than 8 build and walk correctly when the LM
  reports a larger `maxKeyLength()` (Pass)
- **1.T2** All 21 baseline `ReadingGridTest` cases: no
  regression from the vector change (Pass)

<forbidden>

- Walk algorithm changes (the walk is untouched)
- Any user model scoring (FR-2)

</forbidden>

**Status**: In review | **PR**: #844
| **Branch**: `refactor/dynamic_span`

---

### FR-2: Contextual User Model (Interpolated KN)

**Job Story**: When I repeatedly choose a candidate in a
specific left context (e.g., always picking a particular
word after "company"), I want the system to learn this
preference using principled statistical smoothing, so I get
context-appropriate suggestions instead of generic ones --
and when I have confirmed the same candidate in several
different contexts, I want it suggested in contexts I have
never typed before.

<required>

**Acceptance Criteria** (EARS):

- WHEN `observe()` is called with the walks before and
  after a user override, THE SYSTEM SHALL derive the
  context from the walk *before* the override (the context
  the user actually saw) and record the same three cases
  as `UserOverrideModel`: same-length override, phrase
  building (with `forceHighScoreOverride`), and phrase
  breaking judged from the post-override walk.
- WHEN there is no usable preceding node (sentence start,
  or the preceding node is punctuation), THE SYSTEM SHALL
  use the start-context marker `"()"`.
- WHEN a suggestion is requested for a context and reading,
  THE SYSTEM SHALL return the best candidate and its
  `forceHighScoreOverride` flag, or an empty suggestion if
  evidence is insufficient.
- WHEN computing the bigram-level score with total decayed
  evidence `c_total >= d`, THE SYSTEM SHALL use
  `max(c(w) - d, 0) / c_total + lambda * P_cont(w | r)`
  with `lambda = d * types / c_total` and discount
  `d = 0.5`.
- WHEN total decayed evidence is below the discount d,
  THE SYSTEM SHALL NOT apply the bigram level and SHALL
  fall through to the continuation level.
- WHEN computing the continuation probability, THE SYSTEM
  SHALL normalize per reading:
  `P_cont(w | r) = N1+(., r, w) / sum_w' N1+(., r, w')`,
  where `N1+(., r, w)` is the number of distinct left
  contexts in which candidate w was selected for reading
  r. The denominator is the sum over candidates of that
  reading, NOT the total number of unique bigrams.
- WHEN suggesting from the continuation level (a context
  the candidate has never been seen in), THE SYSTEM SHALL
  require the candidate to have been confirmed in at least
  2 distinct contexts (`kMinContextsForGeneralization`).
- WHEN suggesting from the continuation level, THE SYSTEM
  SHALL never set `forceHighScoreOverride` (soft
  suggestion only).
- WHEN the best candidate's probability is below the
  minimum suggestion probability 0.25
  (`kMinSuggestionProbability`), THE SYSTEM SHALL return
  an empty suggestion.
- WHEN an empty suggestion is returned, THE SYSTEM (the
  caller) SHALL leave the grid alone so the walk falls
  back to base LM scores naturally; the model SHALL NOT
  reference the base language model.
- WHEN temporal decay is applied, THE SYSTEM SHALL compute
  `count * 2^(-(t - t_obs) / halfLife)` where t is
  wall-clock time in seconds and halfLife defaults to
  5400 seconds (90 minutes,
  `kDefaultDecayHalfLifeSeconds`).
- WHILE storing observations, THE SYSTEM SHALL bound the
  number of (context, reading) entries with an LRU cap,
  default 500 (`kDefaultCapacity`).
- WHEN `observe()` receives arguments containing tab or
  newline characters, THE SYSTEM SHALL reject the
  observation (they would corrupt the persistence format).
- WHEN the model is saved, THE SYSTEM SHALL write the TSV
  v1 format: header line
  `# mcbopomofo-contextual-user-model v1` followed by
  tab-separated fields context, reading, candidate, count,
  timestamp, force(0|1).
- WHEN `saveToFile()` runs, THE SYSTEM SHALL write to a
  temporary file and rename it into place (atomic save),
  returning false on any I/O failure.
- WHEN `loadFromFile()` runs, THE SYSTEM SHALL validate
  all fields, reject NaN/Inf/negative counts, skip
  malformed lines while counting them (`LoadStats`), and
  on success replace the current state; if the file cannot
  be opened, THE SYSTEM SHALL return `std::nullopt`
  without touching the state.
- WHEN the model is loaded after saving, THE SYSTEM SHALL
  produce identical suggestion results (round-trip
  fidelity), and `serialize()` SHALL produce exactly the
  bytes `saveToFile()` writes (snapshot API for off-thread
  writes).
- WHILE the class exists, THE SYSTEM SHALL delete the copy
  constructor and copy assignment (the LRU map holds
  iterators into the LRU list; copies would alias the
  original).

</required>

<context>

**Why ContextualUserModel replaces UserOverrideModel**:

The model is deliberately a drop-in successor: same
walk-based `observe()`/`suggest()` interface, same three
observe cases, same start-context convention. What it adds:

1. **Persistence across restarts** -- `UserOverrideModel`
   is in-memory only; every learned preference dies with
   the process.
2. **Generalization to unseen contexts** -- the
   continuation level suggests a candidate in a context it
   has never been seen in, provided the user confirmed it
   in enough distinct contexts. Exact-key matching cannot
   do this.

**Design** -- two-level interpolated KN with implicit base:

```
Level 1 (bigram), when c_total >= d:
  P_KN(w | context, reading)
    = max(c(w) - d, 0) / c_total
      + lambda * P_cont(w | reading)
  where lambda = d * types(context, reading) / c_total

Level 2 (continuation), per-reading normalization:
  P_cont(w | reading)
    = N1+(., reading, w) / sum_w' N1+(., reading, w')
  Generalizes only if the candidate was confirmed in
  >= 2 distinct contexts; never force-boosted.

Implicit base level:
  best probability < 0.25, or no evidence
    -> empty suggestion -> caller leaves grid alone
    -> walk uses base LM scores
  (No pointer to the base LM anywhere in the model.)
```

**The "丼 Problem"** (design breakthrough): if a word is
observed ONLY after "牛肉" (beef), should it dominate in
unrelated contexts like "天氣" (weather)? With
unconditional generalization it would. With the KN
continuation count, a single-context word
(`N1+ = 1 < 2`) does not generalize, and the base LM
correctly wins in unrelated contexts. A word confirmed in
two or more distinct contexts earns (soft) generalization.

**Temporal decay**: each observation decays by wall-clock
time:

```
decayedCount(t) = count * 2^(-(t - t_observed) / halfLife)
```

with halfLife = 5400 seconds (90 minutes) by default. An
observation made 90 minutes ago carries half its original
weight; stale preferences fade and the base LM reasserts
itself.

**Files Created** (per PR #780):

- `Source/Engine/ContextualUserModel.h` -- class, API,
  constants (`McBopomofo` namespace, NOT gramambular2)
- `Source/Engine/ContextualUserModel.cpp` -- KN scoring,
  observe/suggest, decay, LRU, persistence
- `Source/Engine/ContextualUserModelTest.cpp` -- 12 tests
- `Source/Engine/CMakeLists.txt` -- new sources and test

**Implementation Notes**:

- Continuation statistics are derived from the LRU store
  on demand (`continuationFor()`), so there is a single
  source of truth and eviction stays consistent.
- The model is not thread-safe by design; the input method
  accesses it from a single thread, and `serialize()`
  exists precisely so file writes can happen off-thread on
  a snapshot.

</context>

**Tests** (per PR #780, `ContextualUserModelTest`):

- **2.T1** `BasicObserveAndSuggest`: an observation in a
  context yields the candidate in the same context (Pass)
- **2.T2** `GeneralizesAfterMultipleContexts`: a candidate
  confirmed in >= 2 distinct contexts is suggested in an
  unseen context (Pass)
- **2.T3** `ExactContextBeatsContinuation`: exact-context
  evidence outranks continuation generalization (Pass)
- **2.T4** `TemporalDecay`: old observations decay; the
  suggestion disappears once evidence falls below
  threshold (Pass)
- **2.T5** `ForceHighScoreOverrideIsRemembered`: the force
  flag round-trips through observe/suggest (Pass)
- **2.T6** `RejectsSeparatorCharacters`: tab/newline in
  arguments rejected (Pass)
- **2.T7** `CapacityEviction`: LRU cap evicts the oldest
  (context, reading) entries (Pass)
- **2.T8** `PersistenceRoundTrip`: save/load preserves
  `suggest()` results (Pass)
- **2.T9** `LoadSkipsMalformedLines`: malformed lines are
  skipped and counted; valid lines load (Pass)
- **2.T10** `SerializeMatchesSavedFile`: `serialize()`
  equals the bytes written by `saveToFile()` (Pass)
- **2.T11** `LoadReturnsNulloptForMissingFile`: missing
  file leaves state untouched (Pass)
- **2.T12** `WalkBasedObserveAndSuggest`: walk-based API
  derives contexts like `UserOverrideModel` (Pass)

<forbidden>

- Any reference to the base language model from the model
  (the base-LM levels are implicit)
- Walk algorithm hooks or grid members for the model
- KeyHandler wiring (FR-3)

</forbidden>

**Status**: In review | **PR**: #780
| **Branch**: `feat/contextual_user_model`

---

### FR-3: KeyHandler Integration

**Job Story**: When I select candidates during typing in
macOS, I want the ObjC++/Swift layer to wire my selections
through to the C++ engine's contextual user model, so my
preferences are learned in real time and preserved across
app restarts.

<required>

**Acceptance Criteria** (EARS):

- WHEN `KeyHandler` needs user adaptation, THE SYSTEM
  SHALL use `_contextualUserModel` in place of
  `_userOverrideModel` at the existing call sites, with no
  reshaping of the call sites.
- WHEN a user inserts a reading, THE SYSTEM SHALL query
  `suggest()` and, if a suggestion exists, apply it through
  the existing `overrideCandidate()` (using the suggestion's
  `forceHighScoreOverride` flag to pick the override type)
  followed by a re-walk -- the same pattern used with
  `UserOverrideModel`.
- WHEN a user selects a candidate, THE SYSTEM SHALL call
  `observe()` in `fixNodeWithReading` using the walk
  captured *before* the override re-walk, so the recorded
  context is what the user actually saw.
- WHILE the input mode is Plain Bopomofo, THE SYSTEM SHALL
  skip `observe()` (persistent learning must not be
  polluted by single-character selections).
- WHEN the app starts, THE SYSTEM SHALL load the model
  once (from AppDelegate) from `contextual-user-model.txt`
  in the user data folder.
- WHEN an observation is recorded, THE SYSTEM SHALL take a
  `serialize()` snapshot on the main thread and write it
  atomically on a serial background queue, so input
  handling never blocks on disk I/O.
- WHILE the model file is written, THE SYSTEM SHALL touch
  only `contextual-user-model.txt`; user phrase files
  SHALL remain untouched.
- WHEN all changes are complete, THE SYSTEM SHALL pass the
  existing KeyHandler XCTest suites.

</required>

<context>

**Design**:

The swap is intentionally minimal because the interfaces
are compatible:

```
Insert reading:
  walk -> _contextualUserModel.suggest(walk, cursor, now)
  if suggestion: grid.overrideCandidate(...) -> re-walk

Select candidate (fixNodeWithReading):
  prevWalk captured before override
  override + re-walk
  if inputMode != PlainBopomofo:
    _contextualUserModel.observe(prevWalk, walkAfter,
                                 cursor, now)
    snapshot = model.serialize()   // main thread
    async write on serial queue    // atomic temp+rename

App startup (AppDelegate):
  LanguageModelManager loads contextual-user-model.txt
```

**Files Modified** (per PR #781):

- `Source/KeyHandler.mm` -- swap `_userOverrideModel` for
  `_contextualUserModel` at existing call sites; Plain
  Bopomofo observe guard
- `Source/LanguageModelManager.{h,mm}` -- model instance,
  load/save with serialized snapshot + serial queue
- `Source/LanguageModelManager+Privates.h` -- property
  swap
- `Source/AppDelegate.swift` -- load once at startup

**Implementation Notes**:

- **Only one model is active.** After this PR,
  `KeyHandler` consults only `ContextualUserModel`;
  `UserOverrideModel` is no longer constructed or called
  by KeyHandler. Its source files remain in tree (unused)
  until FR-4 removes them after the new model has baked.
  There is no dual-model period in the shipped code path.
- **No base-LM lifetime coupling.** The model holds no
  base-language-model reference, so no aliasing
  `shared_ptr` is needed anywhere; the use-after-free
  class of lifetime issues is eliminated by construction.
- **Behavior changes** (intended): learning persists
  across restarts; suggestions generalize to unseen
  contexts; Plain Bopomofo selections are no longer
  observed.

</context>

**Tests**:

- **3.T1** XCTest: KeyHandlerBopomofo suite -- end-to-end
  input behavior with the new model (per PR #781)
- **3.T2** XCTest: KeyHandlerPlainBopomofo suite -- Plain
  Bopomofo mode, observe skipped (per PR #781)

<forbidden>

- Removing `UserOverrideModel` sources (FR-4)
- Synchronous file I/O on the input thread
- Writing to any file other than
  `contextual-user-model.txt`

</forbidden>

**Status**: In review | **PR**: #781 (base: #780)
| **Branch**: `feat/keyhandler_user_model`

---

### FR-4: Legacy Code Removal (Follow-up)

**Job Story**: When the contextual user model is fully
integrated and proven in releases, I want the unused
`UserOverrideModel` sources removed, so the codebase does
not carry a dead duplicate of the adaptation mechanism.

<required>

**Acceptance Criteria** (EARS):

- WHEN removal is complete, THE SYSTEM SHALL have no
  `UserOverrideModel.{h,cpp}` source files and no
  references to `UserOverrideModel` in any source file.
- WHEN removal is complete, THE SYSTEM SHALL still pass
  all C++ engine tests and all XCTests with no behavior
  change for end users.
- WHILE removing the legacy model, THE SYSTEM SHALL keep
  `kOverridingScore` and the `OverrideType` machinery in
  `reading_grid.h` -- they are the active override
  mechanism used by `ContextualUserModel` suggestions, not
  legacy code.
- IF removal breaks a test, THEN THE SYSTEM SHALL fix the
  test to use the new mechanisms (not restore old code).

</required>

<context>

**Scope note**: the removal scope is deliberately narrow.
Earlier drafts of this document proposed also removing
`kOverridingScore = 42`, `kOverrideValueWithHighScore`,
and the `topScore + epsilon` user-phrase rewrite. Those
mechanisms remain in active use -- suggestions are applied
through `overrideCandidate()` -- and replacing them is a
separate design question, out of scope here.

</context>

**Tests**: full C++ + XCTest suites after removal.

**Status**: TODO (follow-up issue after #781 bakes)
| **PR**: TBD | **Branch**: TBD

---

### FR-5: Migration Assessment (Follow-up)

**Job Story**: When upgrading to the contextual user
model, I want certainty that no existing user data is lost
or altered, so the upgrade is safe by default.

<required>

**Acceptance Criteria** (EARS):

- WHEN the new model ships, THE SYSTEM SHALL NOT migrate,
  rewrite, back up, or otherwise touch user phrase files;
  they remain the authoritative user vocabulary, consumed
  by `UserPhrasesLM` exactly as before.
- WHEN the new model ships, THE SYSTEM SHALL NOT attempt
  to migrate `UserOverrideModel` data: it was in-memory
  only, so there is no persisted data to migrate.
- WHEN `contextual-user-model.txt` is absent at startup,
  THE SYSTEM SHALL start with an empty model (cold start)
  without error.

</required>

<context>

**Resolution of the earlier migration plan**: an earlier
draft specified converting `UserPhrasesLM` entries into
model observations with a version marker and backup file.
This is unnecessary for correctness -- the model file is
purely additive, user phrases keep working through
`UserPhrasesLM`/`McBopomofoLM` untouched, and a cold-start
model simply learns from use. Whether to optionally seed
the model from user phrases is an open follow-up question,
tracked as a follow-up issue, not a requirement.

</context>

**Tests**: cold start covered by
`LoadReturnsNulloptForMissingFile` (FR-2 2.T11).

**Status**: Follow-up issue (assessment; no migration
required) | **PR**: N/A

---

## 4. Non-Functional Requirements

### NFR-1: Performance

<required>

- WHILE processing the 8001-reading StressTest, THE SYSTEM
  SHALL show no walk regression from the dynamic-span
  change (measured: median 1499us vs 1580us on master,
  identical vertex and edge counts; PR #844).
- WHILE recording observations, THE SYSTEM SHALL never
  block input handling on disk I/O (snapshot on the input
  thread, write on a serial background queue; PR #781).
- WHILE the LRU store is at capacity (500 entries),
  THE SYSTEM SHALL keep `suggest()` latency negligible
  relative to a keystroke (map lookups over bounded
  per-reading candidate sets).

</required>

### NFR-2: Backward Compatibility

<required>

- WHEN `LanguageModel` subclasses do not override
  `maxKeyLength()`, THE SYSTEM SHALL default to span
  length 8 with behavior identical to the fixed-array
  implementation.
- WHEN `contextual-user-model.txt` does not exist,
  THE SYSTEM SHALL behave like a freshly installed input
  method (no errors, no suggestions until learned).
- WHEN the model has no evidence for a context/reading,
  THE SYSTEM SHALL produce exactly the walk results the
  base LM produces (empty suggestion leaves the grid
  untouched).
- WHEN all PRs land, THE SYSTEM SHALL pass all
  pre-existing engine tests and XCTests.

</required>

### NFR-3: Build System Constraints

<required>

- WHEN adding C++ source files, THE SYSTEM SHALL update
  both the relevant `CMakeLists.txt` and
  `McBopomofo.xcodeproj/project.pbxproj`.
- WHILE building, THE SYSTEM SHALL use the project-wide
  C++ standard (currently C++20 in both
  `Source/Engine/CMakeLists.txt` and the Xcode project).
- WHEN each PR is checked out independently, THE SYSTEM
  SHALL compile without errors on its own base.

</required>

---

## 5. Implementation Phases

### Phase Dependencies

<context>

```
FR-0 (docs)        independent, base master
FR-1 (#844)        independent, base master
FR-2 (#780)        independent, base master
FR-3 (#781)        depends on FR-2 (base: #780)
FR-4 (removal)     follow-up, after FR-3 bakes
FR-5 (migration)   follow-up assessment (no migration
                   required for correctness)
```

The dynamic-span work (FR-1) and the user model work
(FR-2/FR-3) are independent tracks; neither depends on
the other.

</context>

### PR Map

| Work | Branch | PR | Base | Status |
|------|--------|----|------|--------|
| Algorithm doc (FR-0) | `docs/algorithm_viterbi` | #785 | master | Open |
| This document | `docs/user_model_requirements` | #786 | master | Open |
| AGENTS.md guardrails | `docs/agents_guardrails` | #787 | master | Open |
| Dynamic span (FR-1) | `refactor/dynamic_span` | #844 | master | Open |
| Contextual user model (FR-2) | `feat/contextual_user_model` | #780 | master | Open |
| KeyHandler integration (FR-3) | `feat/keyhandler_user_model` | #781 | #780 | Open |
| Legacy removal (FR-4) | TBD | TBD | -- | Follow-up issue |
| Migration assessment (FR-5) | -- | -- | -- | Follow-up issue |

Superseded: PR #779 (`refactor/walk_strategy`) bundled a
`WalkStrategy` abstraction, `fixedSpans_`, and walk-time
model integration. Per maintainer feedback the abstraction
was dropped (YAGNI; the walk needs no extension points),
and the surviving piece -- dynamic span length -- was
carved out into #844. Closed/merged context: PR #777
(Viterbi walk) is merged; PR #784 (C++17 enforcement) is
closed -- the project has since moved to C++20.

---

## 6. Known Limitations and Deferred Work

<context>

- **L1** (FR-3, Low): Single-threaded model by design --
  `ContextualUserModel` is not thread-safe; it is accessed
  from the input thread only, and file writes use a
  `serialize()` snapshot on a serial queue. If the input
  method ever goes multi-threaded, access needs a mutex.
- **L2** (FR-2, Low): TSV persistence assumes fields
  contain no tabs/newlines; `observe()` enforces this by
  rejecting such arguments, so the constraint is validated
  at the only write path.
- **L3** (FR-2, Accepted): Fixed parameters (d = 0.5,
  half-life 5400 s, capacity 500, generalization threshold
  2, minimum probability 0.25) are design choices, not
  estimated from data; revisit only with field feedback.
- **L4** (FR-4, Deferred): `UserOverrideModel` sources
  remain in tree, unused, until the new model has baked in
  releases.

Resolved relative to earlier drafts:

- *Save on every selection (sync I/O)* -- resolved: saves
  snapshot via `serialize()` and write asynchronously on a
  serial queue (atomic temp+rename).
- *No capacity/eviction for the bigram store* -- resolved:
  LRU cap, default 500 contexts.
- *Aliasing `shared_ptr` fragility* -- eliminated by
  construction: the model holds no base-LM pointer at all,
  so the base-LM lifetime coupling and its use-after-free
  risk no longer exist in the design.
- *`loadFromFile` parsing fragility* -- resolved: all
  fields validated, NaN/Inf/negative rejected, malformed
  lines skipped and counted.
- *Dual model active* -- resolved: after #781 only
  `ContextualUserModel` is consulted by KeyHandler.
- *`fixedSpans_` invalidation* -- moot: `fixedSpans_` does
  not exist; the design was dropped with #779.

</context>

---

## 7. Test Summary

### C++ Engine Tests

- **ReadingGridTest** (22 on #844): 21 baseline + 1 new
  `DynamicSpanLength`
- **ContextualUserModelTest** (12 on #780): KN scoring,
  generalization, decay, force flag, separators, LRU
  eviction, persistence round-trip, malformed-line
  handling, serialize parity, missing file, walk-based API

### XCTests

- **KeyHandlerBopomofoTests / KeyHandlerPlainBopomofoTests**:
  existing suites exercised against the swapped model
  (PR #781); Plain Bopomofo additionally validates that
  observation is skipped

### Performance Reference Points

- **StressTest** (8001 readings): median 1499us with
  dynamic span vs 1580us on master; identical
  vertex/edge counts (PR #844)
- **Model writes**: off the input thread by construction
  (`serialize()` snapshot + serial queue, PR #781)

---

## 8. Appendices

### Appendix A: Design Decision Log

- **Drop the WalkStrategy abstraction** (was FR-2 in
  earlier drafts): per maintainer feedback on PR #779 the
  pluggable walk interface, the speculative algorithm
  variants (Pruned Viterbi, MMSEG, Segment Viterbi), and
  walk-time model hooks were removed as YAGNI. The walk
  stays exactly as merged in PR #777.
- **Drop `fixedSpans_`** (was FR-3 in earlier drafts):
  session-scoped structural locking duplicated what
  `overrideCandidate()` already provides; the existing
  override mechanism is sufficient and battle-tested.
- **Two-level KN with implicit base** (FR-2): instead of a
  four-level backoff that queries the base LM and
  decomposes unknown readings, the model returns an empty
  suggestion when evidence is insufficient and the walk
  falls back naturally. Simpler, no base-LM coupling, same
  user-visible behavior at the fallback boundary.
- **Per-reading continuation normalization** (FR-2):
  `P_cont(w | r)` is normalized over the candidates of
  reading r, not over all unique bigrams. This makes the
  continuation level a proper distribution over the actual
  decision the IME faces (which candidate for this
  reading) and keeps probabilities comparable with the
  0.25 suggestion threshold.
- **KN discount d = 0.5, applied only when total decayed
  evidence >= d** (FR-2): retains half of a single
  observation's evidence; skipping the discount below the
  threshold avoids discounting the only evidence to zero.
- **Generalization threshold of 2 distinct contexts**
  (FR-2): the "丼 problem" resolution -- single-context
  words must not colonize unrelated contexts.
- **Continuation suggestions never force-boosted** (FR-2):
  generalized evidence is weaker than exact-context
  evidence; it must not trigger the score-42 hard
  override.
- **Wall-clock decay, half-life 5400 s** (FR-2): decay in
  seconds (not "observation units") makes the model's
  forgetting rate independent of typing speed.
- **Drop-in interface parity with UserOverrideModel**
  (FR-2/FR-3): same observe/suggest shapes and override
  cases means the KeyHandler diff is a swap, not a
  redesign, and behavior differences are attributable to
  the model alone.
- **Separate data file** (FR-3): the model owns
  `contextual-user-model.txt` exclusively; user phrase
  files are never read or written by it, making data loss
  impossible by construction.
- **No base-LM pointer** (FR-2/FR-3): removes the aliasing
  `shared_ptr` and every base-LM lifetime hazard from the
  design rather than documenting them as limitations.

### Appendix B: File Inventory

**Files Created** (PR #780):

- `Source/Engine/ContextualUserModel.h`
- `Source/Engine/ContextualUserModel.cpp`
- `Source/Engine/ContextualUserModelTest.cpp`

**Files Modified**:

- `algorithm.md` (FR-0, PR #785): Viterbi DP walk
  documentation, scoring model rationale, verified
  file/line references
- `requirements.md` (this document, PR #786)
- `Source/Engine/gramambular2/language_model.h` (FR-1,
  PR #844): `maxKeyLength()` virtual
- `Source/Engine/gramambular2/reading_grid.h` /
  `reading_grid.cpp` (FR-1, PR #844): vector-based spans,
  `kDefaultMaxSpanLength`, runtime span window
- `Source/Engine/gramambular2/reading_grid_test.cpp`
  (FR-1, PR #844): `DynamicSpanLength` test
- `Source/Engine/CMakeLists.txt` (FR-2, PR #780): model
  sources and test target
- `Source/KeyHandler.mm`,
  `Source/LanguageModelManager.{h,mm}`,
  `Source/LanguageModelManager+Privates.h`,
  `Source/AppDelegate.swift` (FR-3, PR #781): model swap,
  load at startup, async snapshot save

**Files To Delete (FR-4, follow-up)**:

- `Source/Engine/UserOverrideModel.h`
- `Source/Engine/UserOverrideModel.cpp`

---

<related>

## 9. References

**Primary (NLP-specific Viterbi and language modeling)**:

1. Jurafsky, D. & Martin, J. H. (2025). *Speech and
   Language Processing* (3rd ed. draft). Stanford
   University.
   - Appendix A: Hidden Markov Models -- Viterbi algorithm
     as DP on trellis
   - Chapter 3: N-gram Language Models -- maximum
     likelihood estimation, log-probability scoring
   - Chapter 3, Sec. 3.4+: Smoothing -- Laplace, backoff
     vs interpolation, Kneser-Ney
   - Appendix C: Kneser-Ney Smoothing -- detailed
     derivation and Modified KN
   - URL: https://web.stanford.edu/~jurafsky/slp3/

2. Manning, C. D. & Schutze, H. (1999). *Foundations of
   Statistical Natural Language Processing*. MIT Press.
   - Chapter 9: Markov Models -- Viterbi, trellis
     algorithms
   - Chapter 6: n-gram Models -- MLE, Kneser-Ney smoothing
   - Chapter 6, Sec. 6.3: Good-Turing estimation
   - Chapter 6, Sec. 6.4: Combining Estimators -- linear
     interpolation, Katz backoff
   - URL: https://nlp.stanford.edu/fsnlp/

**Smoothing and backoff**:

3. Chen, S. F. & Goodman, J. (1999). An empirical study of
   smoothing techniques for language modeling. *Computer
   Speech & Language*, 13(4), 359-394.
   - Definitive empirical comparison of Jelinek-Mercer,
     Katz, Witten-Bell, Absolute Discounting, KN,
     Modified KN
   - Establishes interpolated KN as gold standard
   - Interpolation vs backoff analysis

**Secondary (general algorithm)**:

4. Cormen, T. H., Leiserson, C. E., Rivest, R. L. &
   Stein, C. (2022). *Introduction to Algorithms*
   (4th ed.). MIT Press.
   - Chapter 22.4: Topological sort -- DAG shortest paths
     (historical context for the pre-#777 algorithm)

**Requirements engineering**:

5. Mavin, A. et al. (2009). Easy Approach to Requirements
   Syntax (EARS). IEEE International Requirements
   Engineering Conference.

6. Cohn, M. (2024). *User Stories Applied*. Job Story
   format adapted from Intercom and Klement (2013).

</related>
