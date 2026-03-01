# Requirements: Contextual User Model for McBopomofo

<metadata>

- **Scope**: Contextual user model design and implementation
  requirements across 9 functional requirements (FR-0
  through FR-8) mapped to Job Stories and EARS acceptance
  criteria
- **Load if**: Working on user model, walk strategy, or
  KN backoff features
- **Related**: `algorithm.md`, `AGENTS.md`,
  `Source/Engine/gramambular2/`
- **Format**: Job Stories (situation-based motivation) +
  EARS (testable acceptance criteria) + structured XML
  tags per smith conventions

</metadata>

## 1. Context

<context>

### Problem Statement

McBopomofo's user preference system has four overlapping
mechanisms with three out-of-domain score hacks:

- **`kOverridingScore = 42`**: arbitrary constant far outside
  log-prob range -- overrides all LM evidence unconditionally
- **`kUserUnigramScore = 0`**: zero score for user phrases --
  user phrases compete unfairly with base LM
- **`topScore + epsilon`**: epsilon boost on top unigram --
  fragile, order-dependent
- **`UserOverrideModel`**: in-memory LRU, not persisted --
  learned preferences lost on restart

These create cascading workarounds: overlapping node resets,
`forceHighScoreOverride` heuristics, and a two-pass walk
pattern in `KeyHandler.mm`. The root cause is that user
preferences are expressed as score hacks rather than as
principled probabilistic evidence.

### Algorithm Background

PR #777 replaced the old DAG+TopologicalSort+Relax walk
algorithm with a ~30-line forward-pass Viterbi DP in
`ReadingGrid::walk()`. The new algorithm runs in O(|V|+|E|)
time on the reading lattice and is the canonical walk
implementation on master (commit 9fa53a6). Details are
documented in `algorithm.md` (updated in PR #785).

### Solution Overview

The contextual user model replaces all four mechanisms with
a three-layer architecture:

```
Session Layer (in-memory, cleared on commit/session end):
  ReadingGrid::fixedSpans_  ->  Viterbi skips alternatives

Scoring Layer (four-level KN backoff):
  User bigram:    P(w | left_context)  <- user observations
  Continuation:   P_cont(w)           <- distinct left ctxs
  Base phrase:    P_base(w)            <- from data.txt
  Decomposed:    Pi P_base(syllable_i) <- fallback

Persistence Layer:
  ContextualUserModel serialized to disk
  (contextual-user-model.txt)
  Survives restarts, observations decay over time
```

</context>

### Design Principles

<required>

1. **Walk algorithm decoupled from ReadingGrid**. The walk
   computation is extracted behind a pluggable abstraction,
   reversing an earlier decision (documented in the original
   Phase 3 requirements) to keep the walk inline. Decoupling
   was adopted after PR #779's first attempt demonstrated
   that coupling the algorithm to grid internals caused
   regressions. The implementation pattern (strategy,
   policy-based, metaprogramming, etc.) is not prescribed
   by these requirements.

2. **Real log-probabilities via four-level KN backoff**.
   No magic scores. User preferences are expressed as
   smoothed log-probabilities that integrate naturally with
   the base language model.

3. **Structural fixes (`fixedSpans_`) are session-only**.
   Cleared on commit. Cross-session preferences come from
   KN-smoothed scores, not hard constraints.

4. **Each phase compiles and passes tests independently**.
   The implementation is structured as 3 stacked PRs
   (#779, #780, #781, each building on the previous)
   plus 4 independent PRs (#784, #785, #786, #787)
   that target master directly.

</required>

---

## 2. Job Story Map

### Backbone: Functional Jobs

Four functional jobs organize the 9 functional
requirements:

- **J1: Accurate Text Segmentation** (walk algorithm)
- **J2: Learn User Preferences** (scoring model)
- **J3: Persist Learning** (save/load/wire)
- **J4: Maintain Codebase** (docs/cleanup)

### Body: Job Stories by Job

**J1: Accurate Text Segmentation**

- When dictionary entries exceed 8 syllables, I want
  dynamic span length so all entries can match -- FR-1
- When the walk algorithm needs extension, I want a
  pluggable strategy interface so alternatives can be
  evaluated without modifying ReadingGrid -- FR-2
- When I select a candidate during composition, I want the
  walk to lock that segment so it cannot be overridden by
  re-walks -- FR-3
- When the user model has context-dependent scores, I want
  the Viterbi forward pass to use them so the walk prefers
  user-observed candidates -- FR-5

**J2: Learn User Preferences**

- When I repeatedly choose a candidate in a specific
  context, I want the system to learn this with proper
  statistical backing so I get context-appropriate
  suggestions -- FR-4

**J3: Persist Learning**

- When I select candidates during typing, I want the
  ObjC++/Swift layer to wire through to the C++ engine so
  my selections drive learning -- FR-6
- When I restart the input method, I want my learned
  preferences preserved so I do not start from
  scratch -- FR-6, FR-8
- When migrating from old format, I want existing user
  phrases converted so no vocabulary is lost -- FR-8

**J4: Maintain Codebase**

- When algorithm documentation is stale, I want it updated
  to match actual code so AI agents do not regress to old
  algorithms -- FR-0
- When legacy mechanisms are fully replaced, I want dead
  code removed so the codebase is simpler -- FR-7

### Walking Skeleton (MVP)

FR-0 -> FR-1 -> FR-2 -> FR-3 -> FR-4 -> FR-5 -> FR-6

This path delivers a working end-to-end contextual user
model: documentation updated (FR-0), grid infrastructure
extended (FR-1 to FR-3), scoring model created (FR-4),
wired into walk (FR-5), and integrated into the macOS input
method (FR-6). FR-7 (cleanup) and FR-8 (migration) are
post-MVP.

---

## 3. Functional Requirements

### FR-0: Algorithm Documentation Update

**Job Story**: When algorithm documentation describes a
walk algorithm or scoring model that differs from the
current design, I want `algorithm.md` to accurately reflect
both the Viterbi DP walk (PR #777) and the scoring model
rationale (smoothing algorithm comparison leading to
four-level KN backoff), so contributors, reviewers, and AI
agents do not misunderstand the algorithms, regress to
prior implementations, or re-derive design decisions that
were already resolved -- as occurred in PR #779, where
outdated pseudocode in `algorithm.md` was copied verbatim
into new code.

<required>

**Acceptance Criteria** (EARS):

- WHEN the walk algorithm section is read, THE SYSTEM
  documentation SHALL describe Viterbi DP (forward pass +
  backward pass), not DAG shortest-path with topological
  sort.
- WHEN the algorithm steps are documented, THE SYSTEM
  documentation SHALL present a 2-step process: (a) forward
  pass computing cumulative scores via relaxation, (b)
  backward pass reconstructing the optimal path from DP
  table.
- WHEN the DP state is documented, THE SYSTEM documentation
  SHALL describe the per-position state structure (cumulative
  score, backpointer to source position and source node).
- WHEN the lattice structure is explained, THE SYSTEM
  documentation SHALL state that the linear lattice provides
  natural topological order, eliminating the need for
  explicit topological sort.
- WHEN the scoring model is explained, THE SYSTEM
  documentation SHALL note that log-probabilities make
  larger scores better (relaxation uses `>` not `<`).
- WHEN performance is documented, THE SYSTEM documentation
  SHALL include time complexity and empirical speedup
  relative to the prior algorithm.
- WHEN pedagogical examples exist in the document, THE
  SYSTEM documentation SHALL preserve them to maintain
  educational continuity with earlier versions.
- WHEN references are listed, THE SYSTEM documentation
  SHALL cite sources for Viterbi on lattice structures
  rather than DAG-specific references.
- WHEN the scoring model problem is documented, THE SYSTEM
  documentation SHALL describe the four legacy score hacks
  and explain why out-of-domain constants fail to integrate
  with probabilistic language models.
- WHEN smoothing algorithm alternatives are presented,
  THE SYSTEM documentation SHALL compare at minimum:
  Absolute Discounting, Standard Kneser-Ney, Modified
  Kneser-Ney, Bayesian/Dirichlet, Witten-Bell,
  Jelinek-Mercer, and Stupid Backoff, with pros, cons,
  and applicability to the sparse-user-data-with-strong-
  base-LM scenario.
- WHEN the rationale for choosing modified Kneser-Ney is
  explained, THE SYSTEM documentation SHALL present the
  single-context over-generalization problem (a word
  observed in only one context should not dominate in
  unrelated contexts) as the key insight distinguishing
  KN's continuation probability from simpler methods.
- WHEN the four-level backoff hierarchy is documented,
  THE SYSTEM documentation SHALL present formulas for:
  (1) user bigram with discounted count and interpolation
  weight, (2) continuation probability based on distinct
  left-context count, (3) base LM phrase lookup, (4)
  sub-span decomposition for phrases absent from the
  base LM.
- WHEN temporal decay is documented, THE SYSTEM
  documentation SHALL present the exponential decay formula
  and explain the half-life parameter's effect on balancing
  recent preferences against long-term base LM scores.
- WHEN smoothing references are listed, THE SYSTEM
  documentation SHALL cite: (a) Jurafsky & Martin SLP3
  Ch. 3 (Smoothing, Backoff vs Interpolation, Kneser-Ney)
  and Appendix C (Kneser-Ney detail), (b) Manning &
  Schutze FSNLP Ch. 6 sections 6.3-6.4 (Good-Turing,
  Katz backoff, linear interpolation), (c) Chen & Goodman
  (1999) for the definitive empirical comparison of
  Jelinek-Mercer, Katz, Witten-Bell, Absolute Discounting,
  KN, and Modified KN.

</required>

<context>

**Files Modified**:

- `algorithm.md` -- 47 insertions, 87 deletions; ~100
  lines of old DAG pseudocode replaced by ~28 lines of
  Viterbi DP

**Implementation Notes**:

- Version bumped from 1.2 to 1.3.
- Pedagogical examples preserved from the original
  document.
- The Viterbi pseudocode matches the actual
  `ReadingGrid::walk()` implementation committed in
  PR #777 (commit 9fa53a6).
- The `State` struct documents: `maxScore` (cumulative),
  `fromIndex` (backpointer position), `fromNode`
  (backpointer node).
- Core observation: log-probability scoring means `>` not
  `<` in relaxation.
- References: Jurafsky & Martin, *SLP3* Ch. 8 (Viterbi);
  vene.ro (lattice shortest paths). Historical reference
  (Cormen DAG) removed.

**Motivation**:

- PR #779 regression incident: outdated DAG pseudocode in
  `algorithm.md` was copied into `walk_strategy.cpp`,
  regressing from ~1ms to ~8ms on 8001 readings.
- Postmortem identified anchoring bias on formatted docs
  as root cause.
- This FR ensures documentation stays synchronized with
  code.

**Algorithm Selection Context**:

Fundamental approaches evaluated (from design plan Phase
0B):

- Viterbi: O(n*L), exact, leverages natural topological
  order -- **selected**
- Beam Search: O(n*K*L), natural Viterbi generalization
  -- **deferred** (top-K requirement not established)
- A*: O(n*L*log n) -- **rejected** (priority queue
  O(log n) > array O(1) when lattice already
  topologically ordered)
- Greedy: O(n) -- **baseline only** (~95% accuracy too
  low)
- Forward-Backward: O(2n*L) -- **research only** (path
  validity issues)

Viterbi family variants analyzed during design (3 are
placeholders for future implementation):

- **Exact Viterbi**: O(n*L), current default.
- **Pruned Viterbi**: delta-pruning, O(n*L') where
  L'<L. Default delta=10.0 (log-prob range -2 to -13,
  so delta=10 should never prune useful edges; delta=3
  might diverge). Referenced: Lazy Viterbi (Feldman et
  al., MIT), FLASH Viterbi (2024).
- **MMSEG**: 3-word-chunk local optimization, ~98.4%
  accuracy (Tsai, 1996). Score-aware variant proposed
  (log-prob scores replace rules 1-3).
- **Segment Viterbi**: Pinch-point detection to segment
  input, exact Viterbi per segment. Faster on realistic
  text, same speed when no pinch points.

Full analysis: plan `mighty-fluttering-pudding.md` Phase
0B + Section G (Algorithm Comparison Notes).

**Scoring Model Problem Statement**:

The legacy system uses four overlapping mechanisms with
three out-of-domain score hacks to express user preferences:

- **kOverridingScore = 42**: arbitrary constant far outside
  log-prob range (-2 to -13) -- overrides all LM evidence
  unconditionally, cannot be interpolated with real
  probabilities
- **kUserUnigramScore = 0**: zero log-prob for user phrases
  -- competes unfairly with base LM multi-syllable
  candidates
- **topScore + epsilon**: fragile epsilon boost on top
  unigram -- order-dependent, only works for single
  syllables
- **UserOverrideModel**: in-memory LRU, not persisted --
  learned preferences lost on restart, produces magic
  score 42

These create cascading workarounds: overlapping node
resets, forceHighScoreOverride heuristics, and a two-pass
walk in the key handler. The root cause is expressing user
preferences as score hacks rather than principled
probabilistic evidence.

**Smoothing Algorithm Comparison**:

Seven smoothing techniques evaluated for sparse user
observations overlaying a strong base LM (~160K entries):

| Technique | Pros | Cons | Verdict |
|-----------|------|------|---------|
| Absolute Discounting | Simple, well-understood | d=0.75 too aggressive for sparse data (most counts 1-2) | Rejected |
| Standard Kneser-Ney | Gold standard for large corpora (Chen & Goodman 1999) | User data too sparse, continuation degenerates; ignores strong base LM | Rejected |
| Modified Kneser-Ney | Highest accuracy on large data | Requires estimating d1,d2,d3+ from n1-n4 statistics; zero counts cause instability | Rejected |
| Bayesian/Dirichlet | Prior weight mu has clear intuitive meaning; perfect for strong-base + sparse-user | No multi-context generalization; no unknown-phrase handling | Partial fit |
| Witten-Bell | No tunable parameters (automatic) | Cannot control prior trust; does not naturally use base model as backoff | Rejected |
| Jelinek-Mercer | Simplest (one-line formula) | Fixed lambda ignores observation count; dynamic lambda becomes Dirichlet | Too simple |
| Stupid Backoff | Trivial | NOT a probability distribution; invalid log-probabilities; designed for Google-scale data | Disqualified |

**Design Breakthrough -- The "丼 Problem"**:

The decisive insight was the "丼 (don, rice bowl) problem":
if a word is observed ONLY after "牛肉" (beef), should it
dominate in unrelated contexts like "天氣" (weather)?

- With Dirichlet alone: "丼" over-generalizes to all
  contexts regardless of observation diversity.
- With KN continuation count: N+(丼)=1 provides weak
  generalization for single-context words, correctly
  falling back to the base LM in unrelated contexts.

This led to the hybrid four-level design combining KN's
continuation probability (for context generalization
control) with base LM integration (like Dirichlet prior)
and sub-span decomposition (novel contribution for unknown
phrases). The comparison and rationale logically lead to
FR-4, which specifies the four-level KN backoff model.

**Scoring Model Citations**:

- Jurafsky & Martin, SLP3 Ch. 3 Sec. 3.4+ (Smoothing,
  Backoff vs Interpolation, Kneser-Ney) and Appendix C
  (Kneser-Ney detail)
- Manning & Schutze, FSNLP Ch. 6 Sec. 6.3-6.4
  (Good-Turing, Katz backoff, linear interpolation)
- Chen, S. F. & Goodman, J. (1999). An empirical study of
  smoothing techniques for language modeling. *Computer
  Speech & Language*, 13(4), 359-394.
- Bilmes, J. A. & Kirchhoff, K. (2003). Factored language
  models and generalized parallel backoff. *Proc. NAACL*.

</context>

**Tests**: N/A (documentation only).

**Phase**: 0 | **PR**: #785
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

- WHEN the language model specifies a maximum key
  length N > 0, THE SYSTEM SHALL set maximum span
  length to N.
- WHEN the language model specifies a maximum key
  length of 0, THE SYSTEM SHALL default maximum span
  length to the default of 8.
- WHEN a span is queried for a length exceeding its
  capacity, THE SYSTEM SHALL return nullptr without
  undefined behavior.
- WHEN a node is added to a span with spanning length
  exceeding capacity, THE SYSTEM SHALL resize to
  accommodate.
- WHILE the grid is operating, THE SYSTEM SHALL use a
  runtime maximum span length (not a compile-time
  constant) as the loop bound when expanding the grid.
- WHEN a language model does not specify a maximum key
  length, THE SYSTEM SHALL use the default value of 0,
  falling back to 8.
- WHEN all changes are complete, THE SYSTEM SHALL pass all
  21 existing ReadingGrid tests.

</required>

<context>

**Design**:

The `LanguageModel` interface gains an optional method:

```cpp
virtual size_t maxKeyLength() const { return 0; }
```

`Span::nodes_` changes from `std::array<NodePtr, 8>` to
`std::vector<NodePtr>`, growing lazily via `resize()` when
nodes of new max length are added. For typical spans
(maxLength 1-4), this is a small vector.

`ReadingGrid` stores `maxSpanLength_` as a member,
initialized from `lm_->maxKeyLength()` at construction
(falling back to `kDefaultMaxSpanLength = 8` when the LM
returns 0).

**Files Modified**:

- `language_model.h` -- added `virtual size_t
  maxKeyLength() const` with default
- `reading_grid.h` -- `Span::nodes_` type: `std::array`
  to `std::vector`; added `maxSpanLength_` member; added
  `kDefaultMaxSpanLength`
- `reading_grid.cpp` -- updated all
  `kMaximumSpanLength` references to `maxSpanLength_`

**Implementation Notes**:

- The existing death test (`nodeOf` assertion) was changed
  to return `nullptr` instead of asserting, since
  dynamic-length vectors make assertion-based bounds
  checking inappropriate.
- `Span::clear()` uses `fill` with nullptr on the vector
  (preserves allocated capacity).
- Backward compatibility: existing `LanguageModel`
  subclasses get default `maxKeyLength() { return 0; }`,
  so the grid defaults to 8.

</context>

**Tests**:

- **1.T1** `ReadingGridTest::Span`: `nodeOf()` returns
  nullptr for out-of-range (updated from death test) (Pass)
- **1.T2** All 21 `ReadingGridTest`: no regression from
  vector change (Pass)

<forbidden>

- Walk algorithm changes (FR-2)
- `fixedSpans_` (FR-3)
- User model scoring (FR-4)

</forbidden>

**Phase**: 1 | **PR**: #779
| **Branch**: `refactor/walk_strategy`

---

### FR-2: Walk Algorithm Abstraction

**Job Story**: When the walk algorithm needs extension
(beam search, MMSEG, segment detection), I want a pluggable
abstraction so alternative algorithms can be evaluated
without modifying ReadingGrid's walk method.

<required>

**Acceptance Criteria** (EARS):

- WHEN a walk algorithm implementation is provided,
  THE SYSTEM SHALL delegate walk computation to that
  implementation.
- WHEN no algorithm is configured, THE SYSTEM SHALL
  default to exact Viterbi.
- WHEN walk is called, THE SYSTEM SHALL pass grid state
  (spans, reading length, fixed spans, user model,
  timestamp) to the configured walk algorithm.
- WHEN the default walk algorithm runs, THE SYSTEM SHALL
  produce identical results to the previous inline walk.
- WHEN multiple walk algorithms are tested, THE SYSTEM
  SHALL confirm they produce identical output.
- WHEN scaling tests run with 100-5000 syllables, THE
  SYSTEM SHALL demonstrate linear scaling across all
  algorithm variants.
- WHEN all changes are complete, THE SYSTEM SHALL pass all
  21 existing ReadingGrid tests with the default
  algorithm.

</required>

<context>

**Design**:

The walk computation is extracted from ReadingGrid into a
separate, replaceable unit. The implementation pattern is
not prescribed -- viable C++ approaches include strategy
pattern, policy-based design, function pointers, or
metaprogramming.

The abstraction receives grid state (spans, reading length,
fixed spans, user model, timestamp) and returns the walk
result. ReadingGrid delegates to the configured algorithm,
measures elapsed time, and returns the result.

All 4 algorithm variants currently use the same Viterbi
implementation. Differentiation (pruning, MMSEG chunking,
segment detection) is deferred per YAGNI -- the
abstraction exists for future extension without requiring
changes to ReadingGrid.

**Files Modified**:

- `walk_strategy.h` -- NEW: walk algorithm abstraction,
  4 algorithm variants, Viterbi implementation declaration
- `walk_strategy.cpp` -- NEW: Viterbi walk implementation
  (extracted from inline walk)
- `reading_grid.h` -- added walk algorithm member and
  setter
- `reading_grid.cpp` -- walk delegates to algorithm;
  post-walk user model overrides
- `CMakeLists.txt` -- added walk algorithm sources
- `McBopomofo.xcodeproj` -- added walk algorithm files to
  Xcode project

**Implementation Notes**:

- All 4 algorithm variants delegate to the same Viterbi
  implementation -- this is intentional. Per YAGNI,
  differentiation is deferred until a second algorithm is
  actually needed. The abstraction exists so that adding
  beam search or MMSEG later requires only implementing a
  new algorithm variant, not changing ReadingGrid.
- The Viterbi implementation is a free function (not a
  method) to avoid coupling to ReadingGrid internals. It
  takes explicit parameters rather than accessing grid
  state.
- The walk input includes fixed spans and user model
  pointers (nullptr-safe), making FR-3 and FR-4
  integration seamless.

</context>

**Tests**:

- **2.T1** `AlgorithmComparisonTest::Basic10Syllables`:
  all 4 strategies produce identical walk on 10-syllable
  input (Pass)
- **2.T2** `AlgorithmComparisonTest::ScalingComparison`:
  all strategies scale linearly with input size
  (100-5000 syllables) (Pass)
- **2.T3** `AlgorithmComparisonTest::QualityComparison`:
  exact strategies (Viterbi, SegmentViterbi) produce
  identical segmentation (Pass)

<forbidden>

- Actual beam search / MMSEG / segment detection logic
  (YAGNI; all variants use Viterbi for now)
- `fixedSpans_` data member (FR-3)
- `ContextualUserModel` class (FR-4)
- User model integration in walk algorithm (FR-5)

</forbidden>

**Phase**: 2 | **PR**: #779
| **Branch**: `refactor/walk_strategy`

---

### FR-3: Structural Fixes (fixedSpans)

**Job Story**: When I select a candidate during
composition, I want the walk algorithm to lock that segment
at its position, so re-walks cannot override my explicit
selection with a different candidate.

<required>

**Acceptance Criteria** (EARS):

- WHEN `fixSpan(position, node)` is called, THE SYSTEM
  SHALL store the node at that position in `fixedSpans_`.
- WHEN a fixedSpan exists at position i, THE SYSTEM SHALL
  use only that node at position i during the Viterbi
  forward pass, skipping all other candidates.
- WHEN positions fall strictly inside a fixedSpan (start+1
  through start+len-1), THE SYSTEM SHALL mark them as
  blocked and skip them in the main loop.
- WHEN an edge would land inside a fixedSpan (not at the
  start), THE SYSTEM SHALL filter it out via
  `JumpsOverFixedSpan()`.
- WHEN two fixedSpans overlap, THE SYSTEM SHALL apply
  last-write-wins: the later `fixSpan()` call clears any
  overlapping existing fixedSpan.
- WHEN `clearFixedSpans()` is called, THE SYSTEM SHALL
  clear all fixed spans and reset override flags.
- WHEN the grid is fully cleared, THE SYSTEM SHALL clear
  fixedSpans along with all other grid state.
- WHEN all changes are complete, THE SYSTEM SHALL pass all
  21 existing `ReadingGridTest` tests.

</required>

<context>

**Design**:

The walk algorithm modification:

```
// Before main loop: compute blocked positions
blocked[j] = true for all j inside a fixedSpan
  (not at start)

for each position i in [0, readingLen):
    if blocked[i]: continue  // inside a fixed span

    if fixedSpans contains i:
        // Only the fixed node participates
        relax(i, i + fixedNode->spanningLength(),
              fixedNode)
        continue

    // Normal processing
    for each spanLen in [1, maxSpanLen]:
        end = i + spanLen
        if JumpsOverFixedSpan(i, end): continue
        node = span.nodeOf(spanLen)
        relax(i, end, node)
```

Key invariant: a fixedSpan at position `i` blocks ALL
other candidates at position `i` (not just same-length
ones). This is stronger than the original specification
(which only blocked same-length candidates) but simpler
and more predictable.

**Files Modified**:

- `reading_grid.h` -- added `fixedSpans_`, `fixSpan()`,
  `clearFixedSpans()`
- `reading_grid.cpp` -- `clear()` clears fixedSpans;
  `walk()` passes fixedSpans to strategy
- `walk_strategy.cpp` -- Viterbi walk implementation:
  blocked-positions array and fixed-span filtering

**Implementation Notes**:

- **Blocked-positions array**: The implementation uses a
  `std::vector<bool> blocked` array computed before the
  main loop. All positions strictly inside a fixedSpan
  (i.e., `start+1` through `start+len-1`) are marked
  blocked. The main loop skips blocked positions entirely.
- **fixedSpan blocks ALL candidates**: Unlike the original
  specification (which proposed blocking only same-length
  candidates), the implementation blocks all candidates at
  a fixed position. This is simpler (no per-length logic),
  more predictable (fixed means fixed), and matches user
  intent (when you fix a segment, you don't want any
  alternative at that position).
- **6 tests, not 10**: The original spec proposed 10 tests
  (1.5.1-1.5.12). The implementation has 6 focused tests
  that cover the essential behaviors. The
  stress/performance tests are covered by the
  `IntegratedWalkTest` suite instead.

</context>

**Tests**:

- **3.T1** `FixedSpanTest::Basic`: walk uses fixedSpan
  node when set (Pass)
- **3.T2** `FixedSpanTest::Overlapping`: two overlapping
  fixedSpans -- last-write-wins (Pass)
- **3.T3** `FixedSpanTest::Boundary`: fixedSpan at middle
  position; adjacent spans resolve correctly (Pass)
- **3.T4** `FixedSpanTest::ClearFixedSpans`:
  `clearFixedSpans()` restores base LM walk result (Pass)
- **3.T5** `FixedSpanTest::ChainedOverrides`: multiple
  non-overlapping fixedSpans coexist correctly (Pass)
- **3.T6** `FixedSpanTest::ClearAlsoResetsFixedSpans`:
  `clear()` resets both grid state and fixedSpans (Pass)

<forbidden>

- `ContextualUserModel` (FR-4)
- User model scoring in walk (FR-5)
- `KeyHandler.mm` changes (FR-6)
- fixedSpan invalidation on reading insert/delete (known
  limitation L6)

</forbidden>

**Phase**: 3 | **PR**: #779
| **Branch**: `refactor/walk_strategy`

---

### FR-4: Contextual User Model (KN Backoff)

**Job Story**: When I repeatedly choose a candidate in a
specific left context (e.g., always picking a particular
word after "company"), I want the system to learn this
preference using principled statistical smoothing, so I get
context-appropriate suggestions instead of generic ones.

<required>

**Acceptance Criteria** (EARS):

- WHEN a bigram observation is recorded with left context,
  reading, value, and timestamp, THE SYSTEM SHALL store
  the observation and update continuation counts.
- WHEN a suggestion is requested for a context and
  reading, THE SYSTEM SHALL return the best candidate's
  value and KN-smoothed log-score, or nothing if no
  observation exists.
- WHEN computing bigram score (Level 1), THE SYSTEM SHALL
  use `max(c(w) - d, 0) / c_total + lambda * P_cont`.
- WHEN computing continuation score (Level 2), THE SYSTEM
  SHALL use `max(N+(w) - d, 0) / N++ + lambda * P_base`.
- WHEN the base LM has the reading (Level 3), THE SYSTEM
  SHALL use `exp(logprob)` from base LM unigrams.
- WHEN the base LM does not have the reading (Level 4),
  THE SYSTEM SHALL decompose the reading into syllables
  and multiply individual probabilities.
- WHEN temporal decay is applied, THE SYSTEM SHALL compute
  `count * exp(-ln2 * (t - t_obs) / halfLife)` with
  halfLife=20 (in units of observations/selections).
- WHEN an explicit phrase is added by the user,
  THE SYSTEM SHALL store the entry with initial
  count = 2.0 (= 1/d).
- WHEN the model is saved to disk, THE SYSTEM SHALL write
  tab-separated format: leftKey, reading, value, count,
  timestamp.
- WHEN the model is loaded after saving, THE SYSTEM SHALL
  produce identical suggestion results (round-trip
  fidelity).
- WHILE operating, THE SYSTEM SHALL use fixed discount
  d=0.5 and floor probability 1e-10.

</required>

<context>

The scoring model problem, smoothing algorithm comparison,
and rationale for choosing modified KN are documented in
FR-0's context section. This FR specifies the four-level
KN backoff design selected through that analysis.

**Design**:

Four-level KN backoff formulas:

```
Level 1 (bigram): P_KN(w | context, reading)
  = max(c(w) - d, 0) / c_total
    + lambda * P_cont(w | reading)
  where lambda = d * |types(context, reading)| / c_total

Level 2 (continuation): P_cont(w | reading)
  = max(N+(w) - d, 0) / N++
    + lambda_cont * P_base(w | reading)
  where N+(w) = distinct left contexts for (reading, w)
        N++ = total unique bigrams

Level 3 (base LM): P_base(w | reading)
  = exp(logprob) from base LM unigrams
  Falls through to Level 4 if not in base LM

Level 4 (decomposed): P_decomp(w | reading)
  = Product of P_base(char_i | syllable_i)
  Returns floor probability (1e-10) for unknown syllables
```

Temporal decay: Each observation count decays
exponentially:

```
decayedCount(t) = rawCount
    * exp(-ln2 * (t - t_observed) / halfLife)
```

With halfLife=20 observations, after 20 user selections the
observation has half its original weight.

**Files Modified**:

- `contextual_user_model.h` -- NEW: `ContextualUserModel`
  class, data types, public API
- `contextual_user_model.cpp` -- NEW: four-level KN
  backoff, observe, suggest, persistence
- `reading_grid.h` -- added
  `setUserModel(const ContextualUserModel*)`
- `CMakeLists.txt` -- added
  `contextual_user_model.h/.cpp`
- `McBopomofo.xcodeproj` -- added contextual_user_model
  files

**Implementation Notes**:

- The "SingleContextNoGeneralization" test (4.T3)
  validates the key advantage of KN over simpler smoothing
  methods: a word seen in only one context (e.g., "don"
  after "beef") should NOT dominate in unrelated contexts.
  The continuation count N+(w)=1 provides very weak
  generalization.
- `addExplicitPhrase()` uses initial count = 2.0
  (= 1/d = 1/0.5). This gives ~50% immediate influence,
  equivalent to "user chose this twice."
- The base LM is accessed through the existing
  `LanguageModel` interface (no new coupling).

</context>

**Tests**:

- **4.T1** `ContextualUserModelTest::BasicObserve`: single
  observation boosts candidate score (Pass)
- **4.T2** `ContextualUserModelTest::MultiContextCont`:
  same word in 3 contexts gets strong continuation
  probability (Pass)
- **4.T3** `ContextualUserModelTest::SingleContextNoGen`:
  word in 1 context does not dominate in unrelated
  contexts (Pass)
- **4.T4** `ContextualUserModelTest::TemporalDecay`: old
  observations decay, score returns toward base LM (Pass)
- **4.T5** `ContextualUserModelTest::SubSpanDecomp`:
  unknown 2-syllable phrase gets product-of-syllable
  score (Pass)
- **4.T6** `ContextualUserModelTest::SubSpanDecomp3Syl`:
  unknown 3-syllable phrase decomposes correctly (Pass)
- **4.T7** `ContextualUserModelTest::Persistence`:
  save/load round-trip preserves `suggest()` results
  (Pass)
- **4.T8** `ContextualUserModelTest::ExplicitUserPhrase`:
  explicit add gives immediate boost (count=2.0) (Pass)
- **4.T9** `ContextualUserModelTest::LargeObsVolume`:
  100 observations, suggest < 100us average (Pass)

<forbidden>

- User model queries during walk (FR-5)
- Post-walk override application (FR-5)
- KeyHandler wiring (FR-6)
- Capacity/eviction for bigram store (known limitation L3)

</forbidden>

**Phase**: 4 | **PR**: #780
| **Branch**: `feat/contextual_user_model`

---

### FR-5: Walk Integration

**Job Story**: When the user model has context-dependent
scores from prior observations, I want the Viterbi forward
pass to use those scores during path computation and apply
soft overrides after the walk, so the walk prefers
user-observed candidates without requiring a second pass.

<required>

**Acceptance Criteria** (EARS):

- WHEN the walk algorithm relaxes an edge, THE SYSTEM
  SHALL query the user model for a suggestion with the
  predecessor node as left context.
- WHEN the walk starts at the root vertex (position 0),
  THE SYSTEM SHALL use `"_START_"` as the sentinel for
  left context reading and value.
- WHEN a user model suggestion has a higher score than the
  base LM, THE SYSTEM SHALL use the suggestion's
  log-score in the Viterbi DP.
- WHEN the backward trace completes, THE SYSTEM SHALL
  apply post-walk soft overrides using
  `kOverrideValueWithScoreFromTopUnigram` for non-overridden
  nodes where the user model suggests a different value.
- WHILE applying post-walk overrides, THE SYSTEM SHALL
  skip nodes where `node->isOverridden()` is true.
- WHEN post-walk overrides are applied, THE SYSTEM SHALL
  track overridden nodes in `userModelOverriddenNodes_`,
  resetting the vector before each walk.
- WHILE both fixedSpans and user model are active,
  THE SYSTEM SHALL enforce priority:
  fixedSpan > user model > base LM.
- WHEN userModel is nullptr, THE SYSTEM SHALL produce
  identical results to walk without user model.
- WHEN walk is called with a timestamp, THE SYSTEM SHALL
  forward it to `suggest()` for temporal decay.

</required>

<context>

**Design**:

Relax() with user model (in walk algorithm):

```
Relax(from, to, node, viterbi, userModel, timestamp):
    leftReading = viterbi[from].fromNode
        ? fromNode->reading() : "_START_"
    leftValue = viterbi[from].fromNode
        ? fromNode->currentUnigram().value() : ""

    score = node->score()  // base LM score

    if userModel != nullptr:
        suggestion = userModel->suggest(
            leftReading, leftValue,
            node->reading(), timestamp)
        if suggestion.has_value():
            score = suggestion->logScore

    total = viterbi[from].maxScore + score
    if total > viterbi[to].maxScore:
        viterbi[to] = {from, node, total}
```

Post-walk overrides (in `ReadingGrid::walk()`):

```
After backward trace produces walk result:
    clear userModelOverriddenNodes_
    for each node in result:
        if node->isOverridden(): continue
        suggestion = userModel_->suggest(
            leftReading, leftValue,
            node->reading(), timestamp)
        if suggestion and suggestion->value
                != node->currentUnigram().value():
            node->overrideValue(suggestion->value,
                kOverrideValueWithScoreFromTopUnigram)
            userModelOverriddenNodes_.push_back(node)
        update leftReading/leftValue from current node
```

**Files Modified**:

- `walk_strategy.cpp` -- Viterbi walk: added user model
  queries in edge relaxation
- `reading_grid.h` -- added `userModel_` member,
  `userModelOverriddenNodes_`
- `reading_grid.cpp` -- post-walk user model override
  logic; reset overrides before each walk

**Implementation Notes**:

- **Priority enforcement**: Test 5.T14 explicitly verifies
  that structural fixes (fixedSpans) always win over user
  model suggestions. This is the correct priority because
  fixedSpans represent explicit user actions in the current
  session, while user model scores are statistical
  preferences.
- **Post-walk overrides use
  `kOverrideValueWithScoreFromTopUnigram`**: This override
  type changes the displayed value but preserves the
  original score, avoiding the score-domain pollution that
  `kOverridingScore = 42` caused.
- **Stress test (8001 readings)**: ~14-15ms on the test
  machine, confirming that user model queries during walk
  add negligible overhead.

</context>

**Tests**:

- **5.T1** `IntegratedWalkTest::WalkWithUserModel10Syl`:
  user model promotes observed candidate in walk (Pass)
- **5.T2** `IntegratedWalkTest::WalkWithUserModel6Syl`:
  6-syllable realistic sentence with user model (Pass)
- **5.T3** `IntegratedWalkTest::WalkWithUserModelMultiCtx`:
  multi-context observations improve generalization (Pass)
- **5.T4** `IntegratedWalkTest::WalkWithFixedSpanAndUM`:
  fixedSpan + user model coexist correctly (Pass)
- **5.T5** `IntegratedWalkTest::Walk15Syllables`:
  15-syllable natural sentence (Pass)
- **5.T6** `IntegratedWalkTest::Walk20Syllables`:
  20-syllable natural sentence (Pass)
- **5.T7** `IntegratedWalkTest::Walk35Syllables`:
  35-syllable combined paragraph (Pass)
- **5.T8** `IntegratedWalkTest::Walk50SyllablesStress`:
  50-syllable stress test (Pass)
- **5.T9** `IntegratedWalkTest::Walk100To1000Scaling`:
  linear scaling verification (100-1000 syllables) (Pass)
- **5.T10** `IntegratedWalkTest::WalkWithUMAndFS100Syl`:
  100 syllables + 10 fixedSpans + user model, within
  2x baseline (Pass)
- **5.T11** `IntegratedWalkTest::EmptyGrid`: empty grid
  with user model: no crash, empty result (Pass)
- **5.T12** `IntegratedWalkTest::SingleSyllable`: single
  syllable with fixedSpan and user model (Pass)
- **5.T13** `IntegratedWalkTest::AllFixedSpans`: every
  position fixed: no choice for Viterbi (Pass)
- **5.T14** `IntegratedWalkTest::UserModelConflictsFS`:
  fixedSpan wins over user model (priority enforcement)
  (Pass)
- **5.T15** `IntegratedWalkTest::BackoffToDecomp`: novel
  phrase scored via sub-span decomposition (Pass)

<forbidden>

- KeyHandler wiring (ObjC++/Swift) (FR-6)
- User model observation from selections (FR-6)
- Persistence (save/load in app lifecycle) (FR-6)

</forbidden>

**Phase**: 5 | **PR**: #780
| **Branch**: `feat/contextual_user_model`

---

### FR-6: KeyHandler Integration

**Job Story**: When I select candidates during typing in
macOS, I want the ObjC++/Swift layer to wire my selections
through to the C++ engine's contextual user model, so my
preferences are learned in real time and preserved across
app restarts.

<required>

**Acceptance Criteria** (EARS):

- WHEN `LanguageModelManager.loadDataModels()` runs,
  THE SYSTEM SHALL create a global `gContextualUserModel`
  and load from `contextual-user-model.txt`.
- WHEN a `KeyHandler` is initialized, THE SYSTEM SHALL
  call `grid.setUserModel()` with the global model
  pointer.
- WHEN `loadDataModels` completes, THE SYSTEM SHALL
  refresh the user model pointer via `setUserModel()`.
- WHEN a user inserts a reading (keystroke), THE SYSTEM
  SHALL perform a single walk per keystroke (no
  suggest-override-re-walk pattern).
- WHEN a user selects a candidate, THE SYSTEM SHALL
  execute: `fixSpan()` -> `walk()` -> `observe()` ->
  `saveToFile()`.
- WHEN `observe()` is called post-selection, THE SYSTEM
  SHALL iterate walked nodes to record (leftContext,
  selection) bigrams.
- WHEN `saveToFile()` is called, THE SYSTEM SHALL write
  the model synchronously to disk.
- WHILE providing the base LM to the contextual user
  model, THE SYSTEM SHALL ensure the base LM outlives
  the contextual user model.
- WHEN all changes are complete, THE SYSTEM SHALL pass all
  15 KeyHandlerBopomofo, 16 KeyHandlerPlainBopomofo, and
  4 UTF8Helper XCTests.

</required>

<context>

**Design**:

New selection flow (simplified from two-pass to one-pass):

```
User selects candidate:
  1. Find node matching selection
  2. grid.fixSpan(position, node)
  3. grid.walk()  // single pass with user model
  4. For each walked node:
       contextualUserModel.observe(
         leftReading, leftValue,
         currentReading, currentValue,
         timestamp)
  5. LanguageModelManager.saveContextualUserModel()
```

Model lifecycle:

```
App startup:
  LanguageModelManager.loadDataModels()
    -> gContextualUserModel.loadFromFile(path)
    -> Create aliasing shared_ptr<LanguageModel>

KeyHandler init:
  grid.setUserModel(&gContextualUserModel)

Each selection:
  grid.fixSpan() + walk() + observe() + save()
```

**Files Modified**:

- `LanguageModelManager+Privates.h` -- added
  `contextualUserModel` property
- `LanguageModelManager.mm` -- global
  `gContextualUserModel`, load/save, aliasing `shared_ptr`
- `KeyHandler.mm` -- wired `setUserModel()`, simplified
  insert (single walk), fixSpan+observe in select
- `McBopomofo.xcodeproj` -- added contextual_user_model
  and walk_strategy files

**Implementation Notes**:

- **Aliasing `shared_ptr`**: The base LM is stack-allocated
  in `LanguageModelManager.mm`. The `ContextualUserModel`
  needs a `shared_ptr` to the base LM. An aliasing
  `shared_ptr` (with a no-op deleter) wraps the stack
  allocation. This is fragile (see Known Limitation L4)
  but avoids ownership changes to the existing LM
  lifecycle.
- **Save on every selection**: `saveToFile()` is called
  synchronously on the main thread after every candidate
  selection. This is a known performance concern (L1)
  but ensures no data loss. Async write with debouncing
  is deferred.
- **Single walk simplification**: The old pattern of walk
  -> UOM suggest -> override -> re-walk is replaced by a
  single `walk()` call. The user model's KN-smoothed
  scores are applied during the Viterbi forward pass, so
  no post-walk re-walk is needed.

</context>

**Tests**:

- **6.T1** XCTest: KeyHandlerBopomofo (15 tests) --
  end-to-end input method behavior with user model (Pass)
- **6.T2** XCTest: KeyHandlerPlainBopomofo (16 tests) --
  Plain Bopomofo mode with user model (Pass)
- **6.T3** XCTest: UTF8Helper (4 tests) -- UTF-8 utility
  functions (unchanged) (Pass)

<forbidden>

- Removing `UserOverrideModel` (FR-7)
- Removing `kOverridingScore = 42` (FR-7)
- Migration of user data (FR-8)
- Async/debounced save (deferred, L1)
- Thread safety for global model (deferred, L2)

</forbidden>

**Phase**: 6 | **PR**: #781
| **Branch**: `feat/keyhandler_user_model`

---

### FR-7: Legacy Code Removal

**Job Story**: When the contextual user model is fully
integrated and proven, I want to remove the four
overlapping legacy mechanisms (UserOverrideModel,
kOverridingScore, kUserUnigramScore,
topScore+epsilon), so I can eliminate dead code and
score-domain pollution from magic constants.

<required>

**Acceptance Criteria** (EARS):

- WHEN Phase 7 is complete, THE SYSTEM SHALL have no
  references to `UserOverrideModel` in any source file.
- WHEN Phase 7 is complete, THE SYSTEM SHALL have no
  `kOverridingScore = 42` constant in `reading_grid.h`.
- WHEN Phase 7 is complete, THE SYSTEM SHALL have no
  `OverrideType::kOverrideValueWithHighScore` enum value.
- WHEN Phase 7 is complete, THE SYSTEM SHALL have no
  `gUserOverrideModel` instance in
  `LanguageModelManager.mm`.
- WHEN Phase 7 is complete, THE SYSTEM SHALL have no
  `_userOverrideModel` member in `KeyHandler.mm`.
- WHILE `UserPhrasesLM` remains, THE SYSTEM SHALL retain
  its excluded-phrase filtering capability.
- WHEN `kUserUnigramScore = 0` is no longer referenced,
  THE SYSTEM SHALL remove the constant.
- WHEN all legacy code is removed, THE SYSTEM SHALL pass
  all 54 C++ tests and all 35 XCTests with no behavior
  change for end users.
- IF removal breaks a test, THEN THE SYSTEM SHALL fix the
  test to use the new mechanisms (not restore old code).

</required>

<context>

**Design**:

Removal sequence (order matters to keep builds green):

1. Remove UOM suggest/observe calls from `KeyHandler.mm`
   (they are now shadowed by `ContextualUserModel` calls)
2. Remove `_userOverrideModel` member and its
   initialization
3. Remove `gUserOverrideModel` from
   `LanguageModelManager.mm`
4. Remove `UserOverrideModel.h/.cpp` source files
5. Remove `kOverridingScore = 42` and
   `kOverrideValueWithHighScore` from `reading_grid.h`
6. Remove the overlapping-node reset logic in
   `reading_grid.cpp` (if still present)
7. Update build files (CMake + Xcode)
8. Run full test suite

**Files Modified**:

- `UserOverrideModel.h` -- DELETE
- `UserOverrideModel.cpp` -- DELETE
- `KeyHandler.mm` -- remove `_userOverrideModel`, UOM
  observe/suggest calls
- `LanguageModelManager.mm` -- remove `gUserOverrideModel`
- `reading_grid.h` -- remove `kOverridingScore`,
  `kOverrideValueWithHighScore`
- `reading_grid.cpp` -- remove overlapping reset logic
  (if present)
- `CMakeLists.txt` -- remove UOM source files
- `McBopomofo.xcodeproj` -- remove UOM files

**Implementation Notes**:

Open questions:

1. **Phase ordering**: Should Phase 8 (migration) run
   before Phase 7 (removal)? Exploration during Phase 6
   revealed that `UserOverrideModel` data is NOT persisted
   to disk -- it's an in-memory LRU cache lost on restart.
   So there is likely nothing to migrate from UOM, only
   from `UserPhrasesLM`.

2. **Feature flag for gradual transition**: Not
   recommended. The dual system (UOM + ContextualUserModel)
   is already active after Phase 6. Phase 7 simply removes
   the legacy half.

3. **Risk**: Users relying on within-session UOM
   preferences will see a behavior change only if the
   `ContextualUserModel` produces different suggestions.
   Since Phase 6 already wires the contextual model, the
   transition should be seamless.

</context>

**Tests**:

- **7.T1** All 54 C++ tests pass -- engine unaffected by
  removal (TODO)
- **7.T2** All 35 XCTests pass -- end-to-end behavior
  preserved (TODO)
- **7.T3** Manual: type and select candidates -- user-facing
  behavior unchanged (TODO)

<forbidden>

- Removing `UserPhrasesLM` (still needed for
  excluded-phrase filtering)
- Removing user data before migration (FR-8)
- Score hack evaluation in `McBopomofoLM` (may be done
  here or in FR-8)

</forbidden>

**Status**: TODO | **Phase**: 7 | **PR**: TBD
| **Branch**: TBD | **Commit**: TBD

---

### FR-8: Migration

**Job Story**: When migrating from the old user phrase
format to the contextual user model, I want existing user
phrases automatically converted, so no vocabulary is lost
and I do not start from scratch after the upgrade.

<required>

**Acceptance Criteria** (EARS):

- WHEN the app starts and no version marker exists,
  THE SYSTEM SHALL run migration from `UserPhrasesLM`
  format to `ContextualUserModel` format.
- WHEN reading `UserPhrasesLM` entries, THE SYSTEM SHALL
  normalize reading separators to match the grid's format.
- WHEN migrating an entry, THE SYSTEM SHALL use
  `"_START_"` as left context (no context available from
  old format).
- WHEN migrating an entry, THE SYSTEM SHALL use
  count = 2.0 (same as `addExplicitPhrase()`).
- WHEN migration completes, THE SYSTEM SHALL backup the
  original user phrase file to `.bak`.
- WHEN migration completes, THE SYSTEM SHALL write a
  version marker to prevent re-migration.
- WHEN migration runs a second time, THE SYSTEM SHALL
  detect the version marker and skip (idempotent).
- IF migrated entries already exist in the contextual
  model, THEN THE SYSTEM SHALL merge without duplicating.
- WHEN migration succeeds, THE SYSTEM SHALL produce valid
  `suggest()` results for all migrated entries.

</required>

<context>

**Design**:

Migration algorithm:

```
1. Check if migration has already run (version marker)
2. If not:
   a. Read UserPhrasesLM file (user-phrases.txt)
   b. For each line "reading value":
      - Normalize reading separator
      - Create ContextualUserModel entry:
        leftKey = "_START_"
        reading = normalized_reading
        value = value
        count = 2.0
        timestamp = now()
   c. Merge into existing ContextualUserModel data
   d. Save ContextualUserModel file
   e. Backup original UserPhrasesLM file
   f. Write version marker
```

Reading separator normalization: The grid uses a
configurable reading separator (default "-"). The
`ContextualUserModel` stores readings as they appear in
the grid. Migration must ensure that readings from
`UserPhrasesLM` (which uses "-" separator) match the
grid's format.

**Files Modified**:

- `LanguageModelManager.mm` -- migration logic in
  `loadDataModels`
- `ContextualUserModel.h/.cpp` -- possible: add
  `mergeFromUserPhrases()` helper

**Implementation Notes**:

Open questions:

1. **Is `UserOverrideModel` data persisted?** Exploration
   found it is NOT -- it's an in-memory LRU cache. So
   Phase 8 scope is limited to `UserPhrasesLM` data.

2. **Excluded phrases**: `UserPhrasesLM` handles both
   user-added phrases and excluded phrases (phrases the
   user has explicitly blocked). Migration should only
   convert user-added phrases, not excluded phrases.

3. **Reading format in UserPhrasesLM**: Need to verify
   whether readings in the user phrase file use hyphens,
   spaces, or concatenation. The migration must handle
   whichever format is found.

</context>

**Tests**:

- **8.T1** Migration round-trip: convert UserPhrasesLM
  entries, load into ContextualUserModel, verify
  `suggest()` (TODO)
- **8.T2** Reading separator normalization: hyphenated
  readings correctly normalized (TODO)
- **8.T3** Idempotent migration: second run does not
  duplicate entries (TODO)
- **8.T4** Backup creation: original file backed up before
  modification (TODO)

<forbidden>

- `UserOverrideModel` data migration (UOM is in-memory
  only, not persisted; nothing to migrate)
- `UserPhrasesLM` removal (may still be needed for
  excluded phrases)
- Excluded-phrase migration (separate concern from user
  preferences)

</forbidden>

**Status**: TODO | **Phase**: 8 | **PR**: TBD
| **Branch**: TBD | **Commit**: TBD

---

## 4. Non-Functional Requirements

### NFR-1: Performance

<required>

- WHILE processing a stress test of 8001 readings,
  THE SYSTEM SHALL complete the walk in under 20ms.
- WHILE processing a 50-syllable input, THE SYSTEM SHALL
  complete the walk in under 20ms.
- WHILE scaling from 100 to 1000 syllables, THE SYSTEM
  SHALL demonstrate linear time scaling.
- WHILE the user model and 10 fixedSpans are active on
  100 syllables, THE SYSTEM SHALL complete the walk within
  2x the baseline (no user model) time.
- WHILE querying `suggest()` after 100 observations,
  THE SYSTEM SHALL return in under 100 microseconds on
  average.

</required>

### NFR-2: Backward Compatibility

<required>

- WHEN new `LanguageModel` subclasses do not override
  `maxKeyLength()`, THE SYSTEM SHALL default to span
  length 8.
- WHEN no walk algorithm is configured, THE SYSTEM SHALL
  default to exact Viterbi and produce identical results
  to the previous inline walk.
- WHEN `userModel` is nullptr, THE SYSTEM SHALL produce
  identical walk results to the pre-user-model
  implementation.
- WHEN all phases are complete, THE SYSTEM SHALL pass all
  pre-existing tests without modification.

</required>

### NFR-3: Build System Constraints

<required>

- WHEN adding C++ source files, THE SYSTEM SHALL update
  both `Source/Engine/CMakeLists.txt` and
  `McBopomofo.xcodeproj/project.pbxproj`.
- WHILE building, THE SYSTEM SHALL use C++17 only (no
  C++20/C++23 features).
- WHEN each stacked PR is checked out independently,
  THE SYSTEM SHALL compile without errors on its own base.

</required>

---

## 5. Implementation Phases

### Phase Dependencies

<context>

```
0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8
```

- **Phase 0**: Algorithm documentation update.
  Prerequisite for AI-assisted development.
- **Phase 1**: Dynamic span length. Depends on 0.
- **Phase 2**: Walk strategy interface. Depends on 1.
- **Phase 3**: Structural fixes. Depends on 2.
- **Phase 4**: Contextual user model. Depends on 2
  (for walk abstraction input).
- **Phase 5**: Walk integration. Depends on 3 and 4.
- **Phase 6**: KeyHandler integration. Depends on 5.
- **Phase 7**: Legacy code removal. Depends on 6.
- **Phase 8**: Migration. Depends on 4.

</context>

### PR Stack

- **Docs: AGENTS.md guardrails**
  `docs/agents_guardrails` | PR #783 | fe48e62 | Open
- **Build: C++17 enforcement**
  `build/cpp_standard_enforcement` | PR #784 | fad05fd
  | Open
- **Docs: This document**
  `docs/user_model_requirements` | Open
- **Docs: Algorithm (Viterbi)**
  `docs/algorithm_viterbi` | PR #785 | fb72feb | Open
- **FR-1 + FR-2 + FR-3**
  `refactor/walk_strategy` | PR #779 | 9f9477d | Open
- **FR-4 + FR-5**
  `feat/contextual_user_model` | PR #780 | c0b2e10 | Open
- **FR-6**
  `feat/keyhandler_user_model` | PR #781 | 5f9397e | Open

### Per-Phase Summary

- **Phase 0** (FR-0): TODO | PR #785 | `algorithm.md`
- **Phase 1** (FR-1): TODO | PR #779 |
  `language_model.h`, `reading_grid.h/.cpp`
- **Phase 2** (FR-2): TODO | PR #779 |
  walk abstraction, `reading_grid.h/.cpp`,
  `CMakeLists.txt`, `.xcodeproj`
- **Phase 3** (FR-3): TODO | PR #779 |
  `reading_grid.h/.cpp`, walk implementation
- **Phase 4** (FR-4): TODO | PR #780 |
  `contextual_user_model.h/.cpp`, `reading_grid.h`,
  `CMakeLists.txt`, `.xcodeproj`
- **Phase 5** (FR-5): TODO | PR #780 |
  walk implementation, `reading_grid.h/.cpp`
- **Phase 6** (FR-6): TODO | PR #781 |
  `LanguageModelManager+Privates.h`,
  `LanguageModelManager.mm`, `KeyHandler.mm`, `.xcodeproj`
- **Phase 7** (FR-7): TODO | Files: see FR-7
- **Phase 8** (FR-8): TODO | Files: see FR-8

---

## 6. Known Limitations and Deferred Work

<context>

- **L1** (FR-6, Medium): Save on every selection (sync
  I/O on main thread) -- `saveToFile()` called
  synchronously after each `observe()`. Should be replaced
  with async write + debouncing.
- **L2** (FR-6, Medium): Thread safety for
  `gContextualUserModel` -- global model accessed from
  main thread only (current assumption). If input method
  goes multi-threaded, needs mutex.
- **L3** (FR-4, Low): No capacity/eviction for bigram
  store -- `bigrams_` map grows without bound. For typical
  usage (hundreds of unique bigrams) this is fine. Power
  users with thousands of selections may need eviction.
- **L4** (FR-6, Low): Aliasing `shared_ptr` fragility --
  stack-allocated LM wrapped in aliasing `shared_ptr` with
  no-op deleter. Works but relies on lifetime guarantee
  that the stack LM outlives the `ContextualUserModel`.
- **L5** (FR-4, Low): `loadFromFile` whitespace parsing
  fragility -- tab-separated parser does not handle edge
  cases (embedded tabs in values, trailing whitespace).
  Sufficient for current data but not robust.
- **L6** (FR-3, Medium): `fixedSpans_` not invalidated
  on reading insert/delete -- inserting or deleting
  readings shifts positions but does not update
  `fixedSpans_` keys. In practice, `fixedSpans_` are
  short-lived (cleared on commit) so this rarely
  manifests.
- **L7** (FR-6, High): Legacy `UserOverrideModel` still
  active -- both UOM and ContextualUserModel are active.
  FR-7 removes UOM.

</context>

---

## 7. Test Summary

### C++ Tests (54 total)

- **ReadingGridTest** (21): core grid operations, span
  management, walk algorithm
- **FixedSpanTest** (6): structural fix constraints in walk
- **AlgorithmComparisonTest** (3): algorithm abstraction,
  equivalence
- **ContextualUserModelTest** (9): KN backoff,
  observe/suggest, persistence
- **IntegratedWalkTest** (15): end-to-end walk with
  fixedSpans + user model

### XCTests (35 total)

- **KeyHandlerBopomofoTests** (15): full Bopomofo input
  method behavior
- **KeyHandlerPlainBopomofoTests** (16): Plain Bopomofo
  mode
- **UTF8HelperTests** (4): UTF-8 utility functions

### Performance Benchmarks

- **StressTest** (8001 readings): ~14-15ms
- **Walk50SyllablesStress** (50 syllables): < 20ms
- **Walk100To1000Scaling** (100-1000 syllables): linear
  scaling
- **WalkWithUserModelAndFixedSpans100** (100 syllables +
  10 fixedSpans + user model): < 2x baseline
- **LargeObservationVolume** (100 observations): suggest
  < 100us avg

---

## 8. Appendices

### Appendix A: Design Decision Log

- **KN discount d=0.5 (fixed)** (FR-4): Not estimated
  from data. Retains 50% of single observation's evidence.
  Balances fast learning vs. overfitting.
- **Four-level backoff chain** (FR-4): bigram ->
  continuation -> base LM -> decomposed. Each level is
  weaker but more robust. Continuation (Level 2) is the
  key innovation for context generalization.
- **Structural fixes session-only** (FR-3): Cleared on
  commit. Cross-session preferences come from KN scores,
  not hard constraints. Avoids persisting stale structural
  overrides.
- **Walk algorithm decoupled** (FR-2): Reverses earlier
  decision to keep walk inline. PR #779's regression
  showed that coupling the algorithm to grid internals
  was the problem. The implementation pattern is not
  prescribed by these requirements.
- **Explicit phrases count=2.0** (FR-4): With d=0.5,
  initial count = 1/d = 2.0 gives ~50% immediate
  influence. Equivalent to "user chose this twice."
- **Sub-span decomposition as floor** (FR-4): For
  phrases not in base LM, multiply constituent syllable
  probabilities. Provides reasonable floor without
  requiring the phrase to be in the dictionary.
- **fixedSpan blocks ALL candidates at position**
  (FR-3): Stronger than original spec (which blocked
  only same-length). Simpler, more predictable, matches
  user intent.
- **Post-walk overrides use
  `kOverrideValueWithScoreFromTopUnigram`** (FR-5):
  Changes displayed value without polluting score domain.
  Unlike `kOverridingScore=42`, preserves real
  log-probability.
- **Aliasing `shared_ptr` for base LM** (FR-6): Avoids
  ownership changes to existing LM lifecycle. Fragile but
  pragmatic for initial integration.
- **Save on every selection** (FR-6): Ensures no data
  loss. Performance concern deferred -- typical save is
  fast for small model files.

### Appendix B: File Inventory

**Files Created**:

- `Source/Engine/gramambular2/walk_strategy.h` (FR-2):
  walk algorithm abstraction, Viterbi implementation
  declaration
- `Source/Engine/gramambular2/walk_strategy.cpp` (FR-2):
  Viterbi walk implementation with fixedSpans + user model
  support
- `Source/Engine/gramambular2/contextual_user_model.h`
  (FR-4): ContextualUserModel class, data types,
  public API
- `Source/Engine/gramambular2/contextual_user_model.cpp`
  (FR-4): four-level KN backoff, observe, suggest,
  persistence

**Files Modified**:

- `algorithm.md` (FR-0): replaced DAG pseudocode with
  Viterbi DP, updated references and version
- `Source/Engine/gramambular2/language_model.h` (FR-1):
  added `maxKeyLength()` virtual method
- `Source/Engine/gramambular2/reading_grid.h`
  (FR-1, FR-2, FR-3, FR-5): dynamic span (vector),
  `maxSpanLength_`, walk algorithm member, `fixedSpans_`,
  `setUserModel()`, `userModelOverriddenNodes_`
- `Source/Engine/gramambular2/reading_grid.cpp`
  (FR-1, FR-2, FR-3, FR-5): `maxSpanLength_` usage, walk
  delegation, post-walk overrides, `clear()` clears
  fixedSpans
- `Source/Engine/gramambular2/reading_grid_test.cpp`
  (FR-1, FR-3, FR-4, FR-5): 54 tests across 5 suites
- `Source/Engine/gramambular2/CMakeLists.txt`
  (FR-2, FR-4): added walk_strategy and
  contextual_user_model sources
- `Packages/McBopomofo/Sources/McBopomofo/LanguageModelManager+Privates.h`
  (FR-6): added `contextualUserModel` property
- `Packages/McBopomofo/Sources/McBopomofo/LanguageModelManager.mm`
  (FR-6): global ContextualUserModel, load/save,
  aliasing shared_ptr
- `Packages/McBopomofo/Sources/McBopomofo/KeyHandler.mm`
  (FR-6): wired contextualUserModel, simplified insert,
  fixSpan+observe in select
- `McBopomofo.xcodeproj/project.pbxproj`
  (FR-2, FR-4, FR-6): added walk_strategy and
  contextual_user_model files

**Files To Delete (FR-7)**:

- `Source/Engine/UserOverrideModel.h` -- replaced by
  ContextualUserModel
- `Source/Engine/UserOverrideModel.cpp` -- replaced by
  ContextualUserModel

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

4. Bilmes, J. A. & Kirchhoff, K. (2003). Factored language
   models and generalized parallel backoff. *Proc. NAACL*.
   - Generalized backoff model theory

**Secondary (general algorithm)**:

5. Cormen, T. H., Leiserson, C. E., Rivest, R. L. &
   Stein, C. (2022). *Introduction to Algorithms*
   (4th ed.). MIT Press.
   - Chapter 22.4: Topological sort -- DAG shortest paths
     (historical context for the pre-#777 algorithm)

**Chinese word segmentation**:

6. Tsai, C. H. (1996). MMSEG: A Word Identification System
   for Mandarin Chinese Text Based on Two Variants of the
   Maximum Matching Algorithm.
   - URL: https://technology.chtsai.org/mmseg/

**Requirements engineering**:

7. Mavin, A. et al. (2009). Easy Approach to Requirements
   Syntax (EARS). IEEE International Requirements
   Engineering Conference.

8. Cohn, M. (2024). *User Stories Applied*. Job Story
   format adapted from Intercom and Klement (2013).

</related>
