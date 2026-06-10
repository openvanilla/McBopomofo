// Copyright (c) 2026 and onwards The McBopomofo Authors.
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

#ifndef SRC_ENGINE_CONTEXTUALUSERMODEL_H_
#define SRC_ENGINE_CONTEXTUALUSERMODEL_H_

#include <list>
#include <map>
#include <optional>
#include <string>
#include <utility>

#include "gramambular2/reading_grid.h"

namespace McBopomofo {

// A persistent, context-sensitive user adaptation model.
//
// The model observes the user's candidate selections together with the node
// immediately preceding the selection (the bigram context), and suggests the
// learned candidate when the same reading is later typed in the same or a
// similar context. Scoring uses absolute-discounting interpolated Kneser-Ney:
// a candidate seen in this exact context is scored by its discounted count,
// and the discounted probability mass is given to the continuation
// probability, i.e. how many *distinct* contexts the candidate has been
// selected in. This lets a frequently-confirmed candidate generalize to
// contexts it has never been seen in, which the exact-match UserOverrideModel
// cannot do.
//
// The model deliberately has no reference to the base language model. When it
// has no or too little evidence, suggest() returns an empty Suggestion and the
// caller simply leaves the grid alone, so the walk falls back to the base
// model scores naturally. This makes the base-language-model levels of the
// Kneser-Ney backoff implicit and keeps the model self-contained.
//
// Observations decay exponentially by wall-clock time (half-life in seconds),
// and the number of remembered contexts is bounded by an LRU cap, mirroring
// UserOverrideModel. Unlike UserOverrideModel, the model can be saved to and
// loaded from a file, so adaptation survives restarts.
//
// This class is not thread-safe; the input method accesses it from a single
// thread.
class ContextualUserModel {
 public:
  static constexpr size_t kDefaultCapacity = 500;
  static constexpr double kDefaultDecayHalfLifeSeconds = 5400;  // 90 minutes.
  static constexpr double kDiscount = 0.5;
  // The marker used when there is no usable preceding node (start of the
  // sentence, or the preceding node is punctuation). Matches the empty-node
  // marker UserOverrideModel uses in its observation keys.
  static constexpr char kStartContext[] = "()";

  explicit ContextualUserModel(
      size_t capacity = kDefaultCapacity,
      double decayHalfLifeSeconds = kDefaultDecayHalfLifeSeconds);

  // The LRU map holds iterators into the LRU list, so the default copy and
  // move semantics would leave the copy pointing into the original.
  ContextualUserModel(const ContextualUserModel&) = delete;
  ContextualUserModel& operator=(const ContextualUserModel&) = delete;

  // Same shape as UserOverrideModel::Suggestion, so the call sites in
  // KeyHandler can switch models without changes.
  struct Suggestion {
    Suggestion() = default;
    Suggestion(std::string c, bool f)
        : candidate(std::move(c)), forceHighScoreOverride(f) {}
    std::string candidate;
    bool forceHighScoreOverride = false;

    [[nodiscard]] bool empty() const { return candidate.empty(); }
  };

  // Walk-based API, drop-in compatible with UserOverrideModel. observe()
  // derives the context from the walk *before* the user override, so the
  // recorded context is what the user actually saw when selecting.
  void observe(const Formosa::Gramambular2::ReadingGrid::WalkResult&
                   walkBeforeUserOverride,
               const Formosa::Gramambular2::ReadingGrid::WalkResult&
                   walkAfterUserOverride,
               size_t cursor, double timestamp);

  Suggestion suggest(
      const Formosa::Gramambular2::ReadingGrid::WalkResult& currentWalk,
      size_t cursor, double timestamp) const;

  // Granular API. The context is "(reading,value)" of the preceding node, or
  // kStartContext. Arguments containing tab or newline characters are
  // rejected (they would corrupt the persistence format).
  void observe(const std::string& context, const std::string& reading,
               const std::string& candidate, double timestamp,
               bool forceHighScoreOverride = false);

  Suggestion suggest(const std::string& context, const std::string& reading,
                     double timestamp) const;

  // Persistence. loadFromFile() replaces the current state on success and
  // reports how many entries were loaded and how many malformed lines were
  // skipped; it returns std::nullopt without touching the state if the file
  // cannot be opened. saveToFile() writes to a temporary file first and
  // renames it into place, returning false on any I/O failure.
  struct LoadStats {
    size_t loaded = 0;
    size_t skipped = 0;
  };
  std::optional<LoadStats> loadFromFile(const std::string& path);
  bool saveToFile(const std::string& path) const;

  // The persistence-format snapshot saveToFile() writes. Callers that must
  // not block (e.g. the input thread) can take this cheap in-memory snapshot
  // and write it out on another thread, since the model itself is not
  // thread-safe.
  [[nodiscard]] std::string serialize() const;

  [[nodiscard]] size_t entryCount() const { return lruList_.size(); }

 private:
  struct CandidateStats {
    double count = 0;
    double timestamp = 0;
    bool forceHighScoreOverride = false;
  };

  // One entry per (context, reading) pair; the map holds the candidates the
  // user has selected for that reading in that context.
  using CandidateMap = std::map<std::string, CandidateStats>;
  using KeyEntryPair = std::pair<std::string, CandidateMap>;

  [[nodiscard]] double decayedCount(const CandidateStats& stats,
                                    double timestamp) const;

  // Continuation statistics for a reading: for each candidate, the number of
  // distinct contexts it has been observed in, plus the total across all
  // candidates of the reading. Derived from the LRU store on demand so there
  // is a single source of truth and eviction stays consistent.
  struct Continuation {
    std::map<std::string, size_t> contextsPerCandidate;
    size_t totalContexts = 0;
  };
  [[nodiscard]] Continuation continuationFor(const std::string& reading) const;

  void touch(const std::string& key, CandidateMap entry);

  size_t capacity_;
  double decayHalfLifeSeconds_;
  std::list<KeyEntryPair> lruList_;
  std::map<std::string, std::list<KeyEntryPair>::iterator> lruMap_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_CONTEXTUALUSERMODEL_H_
