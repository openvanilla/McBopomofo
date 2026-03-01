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

#ifndef SRC_ENGINE_GRAMAMBULAR2_WALK_STRATEGY_H_
#define SRC_ENGINE_GRAMAMBULAR2_WALK_STRATEGY_H_

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "reading_grid.h"

namespace Formosa::Gramambular2 {

class ContextualUserModel;

class WalkStrategy {
 public:
  virtual ~WalkStrategy() = default;

  struct WalkInput {
    const std::vector<ReadingGrid::Span>& spans;
    size_t readingLength;
    const std::map<size_t, ReadingGrid::NodePtr>* fixedSpans = nullptr;
    const ContextualUserModel* userModel = nullptr;
    double timestamp = 0.0;
  };

  struct WalkOutput {
    std::vector<ReadingGrid::NodePtr> nodes;
    size_t totalReadings = 0;
    size_t vertices = 0;
    size_t edges = 0;
  };

  virtual WalkOutput walk(const WalkInput& input);
  virtual std::string name() const = 0;
};

class ViterbiStrategy : public WalkStrategy {
 public:
  std::string name() const override { return "Viterbi"; }
};

}  // namespace Formosa::Gramambular2

#endif  // SRC_ENGINE_GRAMAMBULAR2_WALK_STRATEGY_H_
