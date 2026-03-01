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

#include "walk_strategy.h"

#include <cassert>
#include <limits>
#include <vector>

namespace Formosa::Gramambular2 {

namespace {

struct State {
  size_t fromIndex = 0;
  ReadingGrid::NodePtr fromNode = nullptr;
  double maxScore = -std::numeric_limits<double>::infinity();
};

// Check if a span starting at pos with given length would jump over any
// fixed span (i.e., covers a fixed span start without starting there).
bool JumpsOverFixedSpan(
    size_t pos, size_t length,
    const std::map<size_t, ReadingGrid::NodePtr>& fixedSpans) {
  for (size_t p = pos + 1; p < pos + length; ++p) {
    if (fixedSpans.count(p)) {
      return true;
    }
  }
  return false;
}

}  // namespace

WalkStrategy::WalkOutput WalkStrategy::walk(const WalkInput& input) {
  const auto& spans = input.spans;
  const size_t readingLen = input.readingLength;
  const auto* fixedSpans = input.fixedSpans;

  // Mark positions that are interior to a fixed span as blocked.
  std::vector<bool> blocked(readingLen + 1, false);
  if (fixedSpans) {
    for (const auto& [start, node] : *fixedSpans) {
      for (size_t j = start + 1;
           j < start + node->spanningLength() && j <= readingLen; ++j) {
        blocked[j] = true;
      }
    }
  }

  // Forward-pass DP (Viterbi). Processing positions in index order is
  // equivalent to topological order since edges only point forward.
  std::vector<State> viterbi(readingLen + 1);
  viterbi[0].maxScore = 0.0;

  size_t vertices = 0;
  size_t edges = 0;

  for (size_t i = 0; i < readingLen; ++i) {
    if (viterbi[i].maxScore == -std::numeric_limits<double>::infinity()) {
      continue;
    }

    if (blocked[i]) {
      continue;
    }

    ++vertices;

    // If this position has a fixed span, only that node is considered.
    if (fixedSpans) {
      auto fixIt = fixedSpans->find(i);
      if (fixIt != fixedSpans->end()) {
        const auto& node = fixIt->second;
        ++edges;
        double score = viterbi[i].maxScore + node->score();
        State& target = viterbi[i + node->spanningLength()];
        if (score > target.maxScore) {
          target.maxScore = score;
          target.fromNode = node;
          target.fromIndex = i;
        }
        continue;
      }
    }

    const ReadingGrid::Span& span = spans[i];
    const size_t maxSpanLen = span.maxLength();

    for (size_t spanLen = 1; spanLen <= maxSpanLen; ++spanLen) {
      const ReadingGrid::NodePtr& node = span.nodeOf(spanLen);
      if (node == nullptr) {
        continue;
      }

      size_t end = i + spanLen;

      // Skip if the destination is blocked (interior of a fixed span).
      if (end <= readingLen && blocked[end]) {
        continue;
      }

      // Skip if this span would jump over a fixed span start.
      if (fixedSpans && JumpsOverFixedSpan(i, spanLen, *fixedSpans)) {
        continue;
      }

      ++edges;
      double score = viterbi[i].maxScore + node->score();
      State& target = viterbi[end];
      if (score > target.maxScore) {
        target.maxScore = score;
        target.fromNode = node;
        target.fromIndex = i;
      }
    }
  }

  // Backtrace from the end to reconstruct the path.
  WalkOutput output;
  output.vertices = vertices;
  output.edges = edges;
  size_t totalReadingLen = 0;
  for (size_t curr = readingLen; curr > 0; curr = viterbi[curr].fromIndex) {
    assert(viterbi[curr].fromNode != nullptr);
    totalReadingLen += viterbi[curr].fromNode->spanningLength();
    output.nodes.emplace_back(std::move(viterbi[curr].fromNode));
  }
  std::reverse(output.nodes.begin(), output.nodes.end());
  assert(totalReadingLen == readingLen);
  output.totalReadings = totalReadingLen;
  return output;
}

}  // namespace Formosa::Gramambular2
