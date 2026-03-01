// Copyright (c) 2022 and onwards Lukhnos Liu.
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

#ifndef SRC_ENGINE_GRAMAMBULAR2_CONTEXTUAL_USER_MODEL_H_
#define SRC_ENGINE_GRAMAMBULAR2_CONTEXTUAL_USER_MODEL_H_

#include <cmath>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "language_model.h"

namespace Formosa::Gramambular2 {

class ContextualUserModel {
 public:
  explicit ContextualUserModel(std::shared_ptr<LanguageModel> baseLM,
                               double discount = 0.5,
                               double decayHalfLife = 20.0)
      : baseLM_(std::move(baseLM)),
        discount_(discount),
        decayHalfLife_(decayHalfLife) {}

  static constexpr const char* kStartSentinel = "_START_";

  struct Suggestion {
    std::string value;
    double logScore;
  };

  // Record a user selection.
  void observe(const std::string& leftReading, const std::string& leftValue,
               const std::string& currentReading,
               const std::string& currentValue, double timestamp);

  // Get the best suggestion for a reading in context.
  std::optional<Suggestion> suggest(const std::string& leftReading,
                                    const std::string& leftValue,
                                    const std::string& currentReading,
                                    double timestamp) const;

  // Add an explicit user phrase (e.g., from "Add to Dictionary").
  void addExplicitPhrase(const std::string& reading, const std::string& value);

  // Persistence.
  bool saveToFile(const std::string& path) const;
  bool loadFromFile(const std::string& path);

  // Four-level KN backoff scoring.
  double bigramScore(const std::string& leftKey,
                     const std::string& reading, const std::string& value,
                     double timestamp) const;
  double continuationScore(const std::string& reading,
                           const std::string& value) const;
  double baseScore(const std::string& reading,
                   const std::string& value) const;
  double decomposedScore(const std::string& reading,
                         const std::string& value) const;

 private:
  struct Observation {
    double decayedCount = 0.0;
    double lastTimestamp = 0.0;
  };

  // BigramKey: (leftReading:leftValue, currentReading)
  using BigramKey = std::pair<std::string, std::string>;
  using CandidateMap = std::map<std::string, Observation>;

  double getDecayedCount(const BigramKey& key, const std::string& value,
                         double timestamp) const;
  double getDecayedContextTotal(const BigramKey& key, double timestamp) const;
  size_t getTypeCount(const BigramKey& key) const;
  size_t getContinuationCount(const std::string& reading,
                              const std::string& value) const;
  size_t uniqueWordsForReading(const std::string& reading) const;
  double decayFactor(double elapsed) const;

  // Split a combined reading "ㄗˋ-ㄏㄨㄟˋ" into {"ㄗˋ", "ㄏㄨㄟˋ"}.
  static std::vector<std::string> splitReading(const std::string& reading);

  // Split a multi-character value into individual characters (UTF-8 aware).
  static std::vector<std::string> splitValue(const std::string& value);

  std::shared_ptr<LanguageModel> baseLM_;
  double discount_;
  double decayHalfLife_;

  std::map<BigramKey, CandidateMap> bigrams_;
  // continuationCounts_[reading][value] = number of distinct left contexts.
  std::map<std::string, std::map<std::string, size_t>> continuationCounts_;
  size_t totalUniqueBigrams_ = 0;

  static constexpr double kFloorProbability = 1e-10;
};

}  // namespace Formosa::Gramambular2

#endif  // SRC_ENGINE_GRAMAMBULAR2_CONTEXTUAL_USER_MODEL_H_
