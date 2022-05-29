//
// Walker.h
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

#ifndef WALKER_H_
#define WALKER_H_

#include <algorithm>
#include <vector>

#include "Grid.h"

namespace Formosa {
namespace Gramambular {

constexpr int kDroppedPathScore = -999;

class Walker {
public:
  explicit Walker(Grid *inGrid);
  const std::vector<NodeAnchor> reverseWalk(
      size_t location, double accumulatedScore = 0.0,
      std::string joinedPhrase = "",
      std::vector<std::string> longPhrases = std::vector<std::string>());

protected:
  Grid *m_grid;
};

inline Walker::Walker(Grid *inGrid) : m_grid(inGrid) {}

inline const std::vector<NodeAnchor>
Walker::reverseWalk(size_t location, double accumulatedScore,
                    std::string joinedPhrase,
                    std::vector<std::string> longPhrases) {
  if (!location || location > m_grid->width()) {
    return std::vector<NodeAnchor>();
  }

  std::vector<std::vector<NodeAnchor>> paths;

  std::vector<NodeAnchor> nodes = m_grid->nodesEndingAt(location);

  stable_sort(nodes.begin(), nodes.end(),
              [](const Formosa::Gramambular::NodeAnchor &a,
                 const Formosa::Gramambular::NodeAnchor &b) {
                return a.node->score() > b.node->score();
              });

  if (nodes[0].node->score() >= kSelectedCandidateScore) {
    // If the user ever choosed a candidate on a node, we should only use the
    // path based on the selected candidate and ignore other paths.
    auto node = nodes[0];

    node.accumulatedScore = accumulatedScore + node.node->score();
    std::vector<NodeAnchor> path =
        reverseWalk(location - node.spanningLength, (node).accumulatedScore);
    path.insert(path.begin(), node);
    paths.push_back(path);
  } else if (longPhrases.size() > 0) {
    std::vector<NodeAnchor> path;

    for (std::vector<NodeAnchor>::iterator ni = nodes.begin();
         ni != nodes.end(); ++ni) {
      if (!ni->node) {
        continue;
      }
      std::string joinedValue = joinedPhrase;
      joinedValue.insert(0, ni->node->currentKeyValue().value);
      // If some nodes with only a character composed a result as a long phease,
      // we just give up the path and give it a really low score.
      //
      // For example, in a sentense "我這樣覺得", we have a longer phrase
      // 覺得, and we found there is another path may ends with "覺" and
      // "得", we just ignore the path since finally "我/這樣/覺得" and
      // "我/這/樣/覺/得" are excatly the same for the users.
      if (std::find(longPhrases.begin(), longPhrases.end(), joinedValue) !=
          longPhrases.end()) {
        ni->accumulatedScore = kDroppedPathScore;
        path.insert(path.begin(), *ni);
        paths.push_back(path);
        continue;
      }

      ni->accumulatedScore = accumulatedScore + ni->node->score();

      if (joinedValue.size() >= longPhrases[0].size()) {
        path = reverseWalk(location - ni->spanningLength, ni->accumulatedScore,
                           "", std::vector<std::string>());
      } else {
        path = reverseWalk(location - ni->spanningLength, ni->accumulatedScore,
                           joinedValue, longPhrases);
      }
      path.insert(path.begin(), *ni);
      paths.push_back(path);
    }
  } else {
    // Let's see if we have longer phrases in the position in the grid.
    std::vector<std::string> newLongPhrases;
    for (std::vector<NodeAnchor>::iterator ni = nodes.begin();
         ni != nodes.end(); ++ni) {
      if (!ni->node) {
        continue;
      }
      if (ni->spanningLength > 1) {
        longPhrases.push_back(ni->node->currentKeyValue().value);
      }
    }

    stable_sort(
        newLongPhrases.begin(), newLongPhrases.end(),
        [](std::string a, std::string b) { return a.size() > b.size(); });

    for (std::vector<NodeAnchor>::iterator ni = nodes.begin();
         ni != nodes.end(); ++ni) {
      if (!ni->node) {
        continue;
      }

      ni->accumulatedScore = accumulatedScore + ni->node->score();
      std::vector<NodeAnchor> path;
      if (ni->spanningLength > 1) {
        path = reverseWalk(location - ni->spanningLength, ni->accumulatedScore,
                           "", std::vector<std::string>());
      } else {
        path = reverseWalk(location - ni->spanningLength, ni->accumulatedScore,
                           ni->node->currentKeyValue().value, newLongPhrases);
      }
      path.insert(path.begin(), *ni);
      paths.push_back(path);
    }
  }

  if (!paths.size()) {
    return std::vector<NodeAnchor>();
  }

  std::vector<NodeAnchor> *result = &*(paths.begin());
  for (std::vector<std::vector<NodeAnchor>>::iterator pi = paths.begin();
       pi != paths.end(); ++pi) {
    if (pi->back().accumulatedScore > result->back().accumulatedScore) {
      result = &*pi;
    }
  }

  return *result;
}
} // namespace Gramambular
} // namespace Formosa

#endif
