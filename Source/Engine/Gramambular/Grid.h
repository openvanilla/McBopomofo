//
// Grid.h
//
// Copyright (c) 2007-2010 Lukhnos D. Liu (http://lukhnos.org)
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
//

#ifndef Grid_h
#define Grid_h

#include <map>

#include "NodeAnchor.h"
#include "Span.h"

namespace Formosa {
namespace Gramambular {

class Grid {
 public:
  void clear();
  void insertNode(const Node& node, size_t location, size_t spanningLength);
  bool hasNodeAtLocationSpanningLengthMatchingKey(size_t location,
                                                  size_t spanningLength,
                                                  const std::string& key);

  void expandGridByOneAtLocation(size_t location);
  void shrinkGridByOneAtLocation(size_t location);

  size_t width() const;
  std::vector<NodeAnchor> nodesEndingAt(size_t location);
  std::vector<NodeAnchor> nodesCrossingOrEndingAt(size_t location);

  // "Freeze" the node with the unigram that represents the selected candidate
  // value. After this, the node that contains the unigram will always be
  // evaluated to that unigram, while all other overlapping nodes will be reset
  // to their initial state (that is, if any of those nodes were "frozen" or
  // fixed, they will be unfrozen.)
  NodeAnchor fixNodeSelectedCandidate(size_t location,
                                      const std::string& value);

  // Similar to fixNodeSelectedCandidate, but instead of "freezing" the node,
  // only boost the unigram that represents the value with an overriding score.
  // This has the same side effect as fixNodeSelectedCandidate, which is that
  // all other overlapping nodes will be reset to their initial state.
  void overrideNodeScoreForSelectedCandidate(size_t location,
                                             const std::string& value,
                                             float overridingScore);

  std::string dumpDOT();

 protected:
  std::vector<Span> m_spans;
};

inline void Grid::clear() { m_spans.clear(); }

inline void Grid::insertNode(const Node& node, size_t location,
                             size_t spanningLength) {
  if (location >= m_spans.size()) {
    size_t diff = location - m_spans.size() + 1;

    for (size_t i = 0; i < diff; i++) {
      m_spans.push_back(Span());
    }
  }

  m_spans[location].insertNodeOfLength(node, spanningLength);
}

inline bool Grid::hasNodeAtLocationSpanningLengthMatchingKey(
    size_t location, size_t spanningLength, const std::string& key) {
  if (location > m_spans.size()) {
    return false;
  }

  const Node* n = m_spans[location].nodeOfLength(spanningLength);
  if (!n) {
    return false;
  }

  return key == n->key();
}

inline void Grid::expandGridByOneAtLocation(size_t location) {
  if (!location || location == m_spans.size()) {
    m_spans.insert(m_spans.begin() + location, Span());
  } else {
    m_spans.insert(m_spans.begin() + location, Span());
    for (size_t i = 0; i < location; i++) {
      // zaps overlapping spans
      m_spans[i].removeNodeOfLengthGreaterThan(location - i);
    }
  }
}

inline void Grid::shrinkGridByOneAtLocation(size_t location) {
  if (location >= m_spans.size()) {
    return;
  }

  m_spans.erase(m_spans.begin() + location);
  for (size_t i = 0; i < location; i++) {
    // zaps overlapping spans
    m_spans[i].removeNodeOfLengthGreaterThan(location - i);
  }
}

inline size_t Grid::width() const { return m_spans.size(); }

inline std::vector<NodeAnchor> Grid::nodesEndingAt(size_t location) {
  std::vector<NodeAnchor> result;

  if (m_spans.size() && location <= m_spans.size()) {
    for (size_t i = 0; i < location; i++) {
      Span& span = m_spans[i];
      if (i + span.maximumLength() >= location) {
        Node* np = span.nodeOfLength(location - i);
        if (np) {
          NodeAnchor na;
          na.node = np;
          na.location = i;
          na.spanningLength = location - i;

          result.push_back(na);
        }
      }
    }
  }

  return result;
}

inline std::vector<NodeAnchor> Grid::nodesCrossingOrEndingAt(size_t location) {
  std::vector<NodeAnchor> result;

  if (m_spans.size() && location <= m_spans.size()) {
    for (size_t i = 0; i < location; i++) {
      Span& span = m_spans[i];

      if (i + span.maximumLength() >= location) {
        for (size_t j = 1, m = span.maximumLength(); j <= m; j++) {
          if (i + j < location) {
            continue;
          }

          Node* np = span.nodeOfLength(j);
          if (np) {
            NodeAnchor na;
            na.node = np;
            na.location = i;
            na.spanningLength = location - i;

            result.push_back(na);
          }
        }
      }
    }
  }

  return result;
}

// For nodes found at the location, fix their currently-selected candidate using
// the supplied string value.
inline NodeAnchor Grid::fixNodeSelectedCandidate(size_t location,
                                                 const std::string& value) {
  std::vector<NodeAnchor> nodes = nodesCrossingOrEndingAt(location);
  NodeAnchor node;
  for (auto nodeAnchor : nodes) {
    auto candidates = nodeAnchor.node->candidates();

    // Reset the candidate-fixed state of every node at the location.
    const_cast<Node*>(nodeAnchor.node)->resetCandidate();

    for (size_t i = 0, c = candidates.size(); i < c; ++i) {
      if (candidates[i].value == value) {
        const_cast<Node*>(nodeAnchor.node)->selectCandidateAtIndex(i);
        node = nodeAnchor;
        break;
        ;
      }
    }
  }
  return node;
}

inline void Grid::overrideNodeScoreForSelectedCandidate(
    size_t location, const std::string& value, float overridingScore) {
  std::vector<NodeAnchor> nodes = nodesCrossingOrEndingAt(location);
  for (auto nodeAnchor : nodes) {
    auto candidates = nodeAnchor.node->candidates();

    // Reset the candidate-fixed state of every node at the location.
    const_cast<Node*>(nodeAnchor.node)->resetCandidate();

    for (size_t i = 0, c = candidates.size(); i < c; ++i) {
      if (candidates[i].value == value) {
        const_cast<Node*>(nodeAnchor.node)
            ->selectFloatingCandidateAtIndex(i, overridingScore);
        break;
      }
    }
  }
}

}  // namespace Gramambular
}  // namespace Formosa

#endif
