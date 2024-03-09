// Copyright (c) 2017 ond onwards The McBopomofo Authors.
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

#ifndef SRC_ENGINE_USEROVERRIDEMODEL_H_
#define SRC_ENGINE_USEROVERRIDEMODEL_H_

#include <list>
#include <map>
#include <string>
#include <utility>

#include "gramambular2/reading_grid.h"

namespace McBopomofo {

class UserOverrideModel {
 public:
  UserOverrideModel(size_t capacity, double decayConstant);

  struct Suggestion {
    Suggestion() = default;
    Suggestion(std::string c, bool f)
        : candidate(std::move(c)), forceHighScoreOverride(f) {}
    std::string candidate;
    bool forceHighScoreOverride = false;

    [[nodiscard]] bool empty() const { return candidate.empty(); }
  };

  void observe(const Formosa::Gramambular2::ReadingGrid::WalkResult&
                   walkBeforeUserOverride,
               const Formosa::Gramambular2::ReadingGrid::WalkResult&
                   walkAfterUserOverride,
               size_t cursor, double timestamp);

  Suggestion suggest(
      const Formosa::Gramambular2::ReadingGrid::WalkResult& currentWalk,
      size_t cursor, double timestamp);

  void observe(const std::string& key, const std::string& candidate,
               double timestamp, bool forceHighScoreOverride = false);

  Suggestion suggest(const std::string& key, double timestamp);

 private:
  struct Override {
    size_t count = 0;
    double timestamp = 0;
    bool forceHighScoreOverride = false;
  };

  struct Observation {
    size_t count;
    std::map<std::string, Override> overrides;

    Observation() : count(0) {}
    void update(const std::string& candidate, double timestamp,
                bool forceHighScoreOverride);
  };

  typedef std::pair<std::string, Observation> KeyObservationPair;

  size_t m_capacity;
  double m_decayExponent;
  std::list<KeyObservationPair> m_lruList;
  std::map<std::string, std::list<KeyObservationPair>::iterator> m_lruMap;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_USEROVERRIDEMODEL_H_
