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

#include "reading_grid.h"

#include <algorithm>
#include <chrono>
#include <limits>
#include <stack>
#include <string>
#include <utility>
#include <vector>

namespace Formosa::Gramambular2 {

void ReadingGrid::clear() {
  cursor_ = 0;
  readings_.clear();
  spans_.clear();
}

void ReadingGrid::setCursor(size_t cursor) {
  assert(cursor <= readings_.size());
  cursor_ = cursor;
}

void ReadingGrid::setReadingSeparator(const std::string& separator) {
  separator_ = separator;
}

bool ReadingGrid::insertReading(const std::string& reading) {
  if (reading.empty() || reading == separator_) {
    return false;
  }

  if (!lm_.hasUnigrams(reading)) {
    return false;
  }

  readings_.insert(readings_.begin() + static_cast<ptrdiff_t>(cursor_),
                   reading);
  expandGridAt(cursor_);
  update();

  // Cursor must only move after update().
  ++cursor_;
  return true;
}

bool ReadingGrid::deleteReadingBeforeCursor() {
  if (!cursor_) {
    return false;
  }

  readings_.erase(readings_.begin() + static_cast<ptrdiff_t>(cursor_ - 1),
                  readings_.begin() + static_cast<ptrdiff_t>(cursor_));
  // Cursor must decrement for grid-shrinking and update to work.
  --cursor_;
  shrinkGridAt(cursor_);
  update();
  return true;
}

bool ReadingGrid::deleteReadingAfterCursor() {
  if (cursor_ == readings_.size()) {
    return false;
  }

  readings_.erase(readings_.begin() + static_cast<ptrdiff_t>(cursor_),
                  readings_.begin() + static_cast<ptrdiff_t>(cursor_ + 1));
  shrinkGridAt(cursor_);
  update();
  return true;
}

std::optional<ReadingGrid::NodePtr> ReadingGrid::findInSpan(
    size_t cursor, const std::function<bool(const NodePtr&)>& predicate) const {
  assert(cursor <= readings_.size());
  std::vector<ReadingGrid::NodeInSpan> nodes =
      overlappingNodesAt(cursor == readings_.size() ? cursor - 1 : cursor);

  auto nodesIt = std::find_if(
      nodes.cbegin(), nodes.cend(),
      [&](const NodeInSpan& nodeInSpan) { return predicate(nodeInSpan.node); });

  return nodesIt == nodes.end()
             ? std::nullopt
             : std::optional<ReadingGrid::NodePtr>(nodesIt->node);
}

namespace {

// Defines a vertex of a DAG. This is a mutable data structure used for both
// DAG construction and single-source shortest-path computation.
struct Vertex {
  explicit Vertex(ReadingGrid::NodePtr nodePtr) : node(std::move(nodePtr)) {
    edges.reserve(ReadingGrid::kMaximumSpanLength);
  }
  ReadingGrid::NodePtr node;
  std::vector<Vertex*> edges;

  // Used during topological-sort.
  bool topologicallySorted = false;

  // Used during shortest-path computation. We are actually computing the
  // path with the *largest* weight, hence distance's initial value being
  // negative infinity. If we were to compute the *shortest* weight/distance,
  // we would have initialized this to infinity.
  double distance = -std::numeric_limits<double>::infinity();
  Vertex* prev = nullptr;
};

// Cormen et al. 2001 explains the historical origin of the term "relax."
void Relax(Vertex* u, Vertex* v) {
  // The distance from u to w is simply v's score.
  double w = v->node->score();

  // Since we are computing the largest weight, we update v's distance and prev
  // if the current distance to v is *less* than that of u's plus the distance
  // to v (which is represented by w).
  if (v->distance < u->distance + w) {
    v->distance = u->distance + w;
    v->prev = u;
  }
}

using VertexSpan = std::vector<Vertex>;

// Topological-sorts a DAG that has a single root and returns the vertices in
// topological order. Here, a non-recursive version is implemented using our own
// stack and state definitions, so that we are not constrained by the current
// thread's stack size. This is the equivalent to this recursive version:
//
//  void TopologicalSort(Vertex* v) {
//    for (Vertex* nv : v->edges) {
//      if (!nv->topologicallySorted) {
//        dfs(nv, result);
//      }
//    }
//    v->topologicallySorted = true;
//    result.push_back(v);
//  }
//
// The recursive version is similar to the TOPOLOGICAL-SORT algorithm found in
// Cormen et al. 2001.
std::vector<Vertex*> TopologicalSort(Vertex* root) {
  std::vector<Vertex*> result;
  struct State {
    explicit State(Vertex* vv) : v(vv), edgeIter(v->edges.begin()) {}
    Vertex* v;
    std::vector<Vertex*>::iterator edgeIter;
  };
  std::stack<State> stack;
  stack.emplace(root);

  while (!stack.empty()) {
    State& state = stack.top();
    Vertex* v = state.v;

    if (state.edgeIter != v->edges.end()) {
      Vertex* nv = *state.edgeIter;
      ++state.edgeIter;
      if (!nv->topologicallySorted) {
        stack.emplace(nv);
        continue;
      }
    }

    v->topologicallySorted = true;
    result.push_back(v);
    stack.pop();
  }

  return result;
}

int64_t GetEpochNowInMicroseconds() {
  auto now = std::chrono::system_clock::now();
  int64_t timestamp =
      std::chrono::time_point_cast<std::chrono::microseconds>(now)
          .time_since_epoch()
          .count();
  return timestamp;
}

}  // namespace

// Find the weightiest path in the grid graph. The path represents the most
// likely hidden chain of events from the observations. We use the
// DAG-SHORTEST-PATHS algorithm in Cormen et al. 2001 to compute such path.
// Instead of computing the path with the shortest distance, though, we compute
// the path with the longest distance (so the weightiest), since with log
// probability a larger value means a larger probability. The algorithm runs in
// O(|V| + |E|) time for G = (V, E) where G is a DAG. This means the walk is
// fairly economical even when the grid is large.
ReadingGrid::WalkResult ReadingGrid::walk() {
  WalkResult result;
  if (spans_.empty()) {
    return result;
  }
  int64_t start = GetEpochNowInMicroseconds();

  std::vector<VertexSpan> vspans(spans_.size(), VertexSpan());
  size_t vertices = 0;
  size_t edges = 0;
  for (size_t i = 0, len = spans_.size(); i < len; ++i) {
    const ReadingGrid::Span& span = spans_[i];
    for (size_t j = 1, maxSpanLen = span.maxLength(); j <= maxSpanLen; ++j) {
      NodePtr p = span.nodeOf(j);
      if (p != nullptr) {
        vspans[i].emplace_back(std::move(p));
        ++vertices;
      }
    }
  }
  result.vertices = vertices;

  Vertex terminal(std::make_shared<ReadingGrid::Node>(
      "_TERMINAL_", 0, std::vector<LanguageModel::Unigram>()));
  for (size_t i = 0, vspansLen = vspans.size(); i < vspansLen; ++i) {
    for (Vertex& v : vspans[i]) {
      size_t nextVertexPos = i + v.node->spanningLength();
      if (nextVertexPos == vspansLen) {
        v.edges.push_back(&terminal);
        continue;
      }

      for (Vertex& nv : vspans[nextVertexPos]) {
        v.edges.push_back(&nv);
        ++edges;
      }
    }
  }
  result.edges = edges;

  Vertex root(std::make_shared<ReadingGrid::Node>(
      "_ROOT_", 0, std::vector<LanguageModel::Unigram>()));
  root.distance = 0;
  for (Vertex& v : vspans[0]) {
    root.edges.push_back(&v);
  }

  std::vector<Vertex*> ordered = TopologicalSort(&root);
  for (auto it = ordered.rbegin(), rend = ordered.rend(); it != rend; ++it) {
    Vertex* u = *it;
    for (Vertex* v : u->edges) {
      Relax(u, v);
    }
  }

  std::vector<NodePtr> walked;
  size_t totalReadingLen = 0;
  Vertex* it = &terminal;
  while (it->prev != nullptr) {
    walked.push_back(it->prev->node);
    it = it->prev;
    totalReadingLen += it->node->spanningLength();
  }

  assert(totalReadingLen == readings_.size());
  assert(walked.size() >= 2);
  result.totalReadings = totalReadingLen;
  result.nodes = std::vector<NodePtr>(walked.rbegin() + 1, walked.rend());
  result.elapsedMicroseconds = GetEpochNowInMicroseconds() - start;
  return result;
}

std::vector<ReadingGrid::Candidate> ReadingGrid::candidatesAt(size_t loc) {
  std::vector<ReadingGrid::Candidate> result;
  if (readings_.empty()) {
    return result;
  }

  if (loc > readings_.size()) {
    return result;
  }

  std::vector<NodeInSpan> nodes =
      overlappingNodesAt(loc == readings_.size() ? loc - 1 : loc);

  // Sort nodes by reading length.
  std::stable_sort(
      nodes.begin(), nodes.end(), [](const auto& n1, const auto& n2) {
        return n1.node->spanningLength() > n2.node->spanningLength();
      });

  for (const NodeInSpan& nodeInSpan : nodes) {
    for (const LanguageModel::Unigram& unigram : nodeInSpan.node->unigrams()) {
      result.emplace_back(nodeInSpan.node->reading(), unigram.value());
    }
  }
  return result;
}

bool ReadingGrid::overrideCandidate(
    size_t loc, const ReadingGrid::Candidate& candidate,
    ReadingGrid::Node::OverrideType overrideType) {
  return overrideCandidate(loc, &candidate.reading, candidate.value,
                           overrideType);
}

bool ReadingGrid::overrideCandidate(
    size_t loc, const std::string& candidate,
    ReadingGrid::Node::OverrideType overrideType) {
  return overrideCandidate(loc, nullptr, candidate, overrideType);
}

void ReadingGrid::expandGridAt(size_t loc) {
  if (!loc || loc == spans_.size()) {
    spans_.insert(spans_.begin() + static_cast<ptrdiff_t>(loc), Span());
    return;
  }
  spans_.insert(spans_.begin() + static_cast<ptrdiff_t>(loc), Span());
  removeAffectedNodes(loc);
}

void ReadingGrid::shrinkGridAt(size_t loc) {
  if (loc == spans_.size()) {
    return;
  }
  spans_.erase(spans_.begin() + static_cast<ptrdiff_t>(loc));
  removeAffectedNodes(loc);
}

void ReadingGrid::removeAffectedNodes(size_t loc) {
  // Because of the expansion, certain spans now have "broken" nodes. We need
  // to remove those. For example, before:
  //
  // Span index 0   1   2   3
  //                (---)
  //                (-------)
  //            (-----------)
  //
  // After we've inserted a span at 2:
  //
  // Span index 0   1   2   3   4
  //                (---)
  //                (----   ----)
  //            (--------   ----)
  //
  // Similarly for shrinkage, before:
  //
  // Span index 0   1   2   3
  //                (---)
  //                (-------)
  //            (-----------)
  //
  // After we've deleted the span at 2:
  //
  // Span index 0   1   2   3   4
  //                (---)
  //                XXXXX
  //            XXXXXXXXX
  //
  if (spans_.empty()) {
    return;
  }
  size_t affectedLength = kMaximumSpanLength - 1;
  size_t begin = loc <= affectedLength ? 0 : loc - affectedLength;
  size_t end = loc >= 1 ? loc - 1 : 0;
  for (size_t i = begin; i <= end; ++i) {
    spans_[i].removeNodesOfOrLongerThan(loc - i + 1);
  }
}

void ReadingGrid::insert(size_t loc, const ReadingGrid::NodePtr& node) {
  assert(loc < spans_.size());
  spans_[loc].add(node);
}

std::string ReadingGrid::combineReading(
    std::vector<std::string>::const_iterator begin,
    std::vector<std::string>::const_iterator end) {
  std::string result;
  for (auto iter = begin; iter != end;) {
    result += *iter;
    ++iter;
    if (iter != end) {
      result += separator_;
    }
  }
  return result;
}

bool ReadingGrid::hasNodeAt(size_t loc, size_t readingLen,
                            const std::string& reading) {
  if (loc > spans_.size()) {
    return false;
  }
  const NodePtr& n = spans_[loc].nodeOf(readingLen);
  if (n == nullptr) {
    return false;
  }
  return reading == n->reading();
}

void ReadingGrid::update() {
  size_t begin =
      (cursor_ <= kMaximumSpanLength) ? 0 : cursor_ - kMaximumSpanLength;
  size_t end = cursor_ + kMaximumSpanLength;
  if (end > readings_.size()) {
    end = readings_.size();
  }

  for (size_t pos = begin; pos < end; pos++) {
    for (size_t len = 1; len <= kMaximumSpanLength && pos + len <= end; len++) {
      std::string combinedReading =
          combineReading(readings_.begin() + static_cast<ptrdiff_t>(pos),
                         readings_.begin() + static_cast<ptrdiff_t>(pos + len));

      if (!hasNodeAt(pos, len, combinedReading)) {
        auto unigrams = lm_.getUnigrams(combinedReading);
        if (unigrams.empty()) {
          continue;
        }

        insert(pos, std::make_shared<Node>(combinedReading, len, unigrams));
      }
    }
  }
}

bool ReadingGrid::overrideCandidate(
    size_t loc, const std::string* reading, const std::string& value,
    ReadingGrid::Node::OverrideType overrideType) {
  if (loc > readings_.size()) {
    return false;
  }

  std::vector<NodeInSpan> overlappingNodes =
      overlappingNodesAt(loc == readings_.size() ? loc - 1 : loc);
  NodeInSpan overridden;
  for (NodeInSpan& nis : overlappingNodes) {
    if (reading != nullptr && nis.node->reading() != *reading) {
      continue;
    }

    if (nis.node->selectOverrideUnigram(value, overrideType)) {
      overridden = nis;
      break;
    }
  }

  if (overridden.node == nullptr) {
    // Nothing gets overridden.
    return false;
  }

  for (size_t i = overridden.spanIndex;
       i < overridden.spanIndex + overridden.node->spanningLength() &&
       i < spans_.size();
       ++i) {
    // We also need to reset *all* nodes that share the same location in the
    // span. For example, if previously the two walked nodes are "A BC" where
    // A and BC are two nodes with overrides. The user now chooses "DEF" which
    // is a node that shares the same span location with "A". The node with BC
    // will be reset as it's part of the overlapping node, but A is not.
    std::vector<NodeInSpan> nodes = overlappingNodesAt(i);
    for (NodeInSpan& nis : nodes) {
      if (nis.node != overridden.node) {
        nis.node->reset();
      }
    }
  }
  return true;
}

std::vector<ReadingGrid::NodeInSpan> ReadingGrid::overlappingNodesAt(
    size_t loc) const {
  std::vector<ReadingGrid::NodeInSpan> results;

  if (spans_.empty() || loc >= spans_.size()) {
    return results;
  }

  // First, get all nodes from the span at location.
  for (size_t i = 1, len = spans_[loc].maxLength(); i <= len; ++i) {
    NodePtr ptr = spans_[loc].nodeOf(i);
    if (ptr != nullptr) {
      ReadingGrid::NodeInSpan element{.node = std::move(ptr), .spanIndex = loc};
      results.emplace_back(std::move(element));
    }
  }

  size_t begin = loc - std::min(loc, kMaximumSpanLength - 1);
  for (size_t i = begin; i < loc; ++i) {
    size_t beginLen = loc - i + 1;
    size_t endLen = spans_[i].maxLength();
    for (size_t j = beginLen; j <= endLen; ++j) {
      NodePtr ptr = spans_[i].nodeOf(j);
      if (ptr != nullptr) {
        ReadingGrid::NodeInSpan element{.node = std::move(ptr), .spanIndex = i};
        results.emplace_back(std::move(element));
      }
    }
  }

  return results;
}

LanguageModel::Unigram ReadingGrid::Node::currentUnigram() const {
  return unigrams_.empty() ? LanguageModel::Unigram{} : *unigramIter_;
}

std::string ReadingGrid::Node::value() const {
  return unigrams_.empty() ? "" : unigramIter_->value();
}

double ReadingGrid::Node::score() const {
  if (unigrams_.empty()) {
    return 0;
  }

  switch (overrideType_) {
    case OverrideType::kOverrideValueWithHighScore:
      return kOverridingScore;
    case OverrideType::kOverrideValueWithScoreFromTopUnigram:
      return unigrams_[0].score();
    case OverrideType::kNone:
    default:
      return unigramIter_->score();
  }
}

bool ReadingGrid::Node::isOverridden() const {
  return overrideType_ != OverrideType::kNone;
}

void ReadingGrid::Node::reset() {
  unigramIter_ = unigrams_.begin();
  overrideType_ = OverrideType::kNone;
}

bool ReadingGrid::Node::selectOverrideUnigram(
    const std::string& value, ReadingGrid::Node::OverrideType type) {
  assert(type != ReadingGrid::Node::OverrideType::kNone);
  for (auto it = unigrams_.begin(), end = unigrams_.end(); it != end; ++it) {
    if (value == it->value()) {
      unigramIter_ = it;
      overrideType_ = type;
      return true;
    }
  }
  return false;
}

std::vector<ReadingGrid::NodePtr>::const_iterator
ReadingGrid::WalkResult::findNodeAt(size_t cursor,
                                    size_t* outCursorPastNode) const {
  if (nodes.empty()) {
    return nodes.cend();
  }

  if (cursor > totalReadings) {
    return nodes.cend();
  }

  if (cursor == 0) {
    auto it = nodes.cbegin();
    if (outCursorPastNode != nullptr) {
      *outCursorPastNode = (*it)->spanningLength();
    }
    return it;
  }

  // Covers both the "cursor is right at end" and "cursor is one reading before
  // the end" cases.
  if (cursor >= totalReadings - 1) {
    if (outCursorPastNode != nullptr) {
      *outCursorPastNode = totalReadings;
    }
    return std::next(nodes.cbegin(), static_cast<ptrdiff_t>(nodes.size() - 1));
  }

  size_t accumulated = 0;
  for (auto i = nodes.cbegin(); i != nodes.cend(); ++i) {
    accumulated += (*i)->spanningLength();
    if (accumulated > cursor) {
      if (outCursorPastNode != nullptr) {
        *outCursorPastNode = accumulated;
      }
      return i;
    }
  }

  // Shouldn't happen.
  return nodes.cend();
}

std::vector<std::string> ReadingGrid::WalkResult::valuesAsStrings() const {
  std::vector<std::string> result;
  for (const NodePtr& node : nodes) {
    result.emplace_back(node->value());
  }
  return result;
}

std::vector<std::string> ReadingGrid::WalkResult::readingsAsStrings() const {
  std::vector<std::string> result;
  for (const NodePtr& node : nodes) {
    result.emplace_back(node->reading());
  }
  return result;
}

void ReadingGrid::Span::clear() {
  nodes_.fill(nullptr);
  maxLength_ = 0;
}

void ReadingGrid::Span::add(const ReadingGrid::NodePtr& node) {
  assert(node->spanningLength() > 0 &&
         node->spanningLength() <= kMaximumSpanLength);
  nodes_[node->spanningLength() - 1] = node;
  if (node->spanningLength() >= maxLength_) {
    maxLength_ = node->spanningLength();
  }
}

void ReadingGrid::Span::removeNodesOfOrLongerThan(size_t length) {
  assert(length > 0 && length <= kMaximumSpanLength);
  for (size_t i = length - 1; i < kMaximumSpanLength; ++i) {
    nodes_[i] = nullptr;
  }
  maxLength_ = 0;
  if (length == 1) {
    return;
  }

  size_t i = length - 2;
  while (true) {
    if (nodes_[i] != nullptr) {
      maxLength_ = i + 1;
      return;
    }

    if (i == 0) {
      return;
    }

    --i;
  }
}

ReadingGrid::NodePtr ReadingGrid::Span::nodeOf(size_t length) const {
  assert(length > 0 && length <= kMaximumSpanLength);
  return nodes_[length - 1];
}

std::vector<LanguageModel::Unigram>
ReadingGrid::ScoreRankedLanguageModel::getUnigrams(const std::string& reading) {
  auto unigrams = lm_->getUnigrams(reading);
  std::stable_sort(
      unigrams.begin(), unigrams.end(),
      [](const auto& u1, const auto& u2) { return u1.score() > u2.score(); });
  return unigrams;
}

bool ReadingGrid::ScoreRankedLanguageModel::hasUnigrams(
    const std::string& reading) {
  return lm_->hasUnigrams(reading);
}

}  // namespace Formosa::Gramambular2
