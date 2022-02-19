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

#ifndef Walker_h
#define Walker_h

#include <algorithm>

#include "Grid.h"

namespace Formosa {
namespace Gramambular {

class Walker {
 public:
  Walker(Grid* inGrid);
  const std::vector<NodeAnchor> reverseWalk(size_t location,
                                            double accumulatedScore = 0.0);

 protected:
  Grid* m_grid;
};

inline Walker::Walker(Grid* inGrid) : m_grid(inGrid) {}

inline const std::vector<NodeAnchor> Walker::reverseWalk(
    size_t location, double accumulatedScore) {
  if (!location || location > m_grid->width()) {
    return std::vector<NodeAnchor>();
  }

  std::vector<std::vector<NodeAnchor> > paths;

  std::vector<NodeAnchor> nodes = m_grid->nodesEndingAt(location);

  for (std::vector<NodeAnchor>::iterator ni = nodes.begin(); ni != nodes.end();
       ++ni) {
    if (!(*ni).node) {
      continue;
    }

    (*ni).accumulatedScore = accumulatedScore + (*ni).node->score();

    std::vector<NodeAnchor> path =
        reverseWalk(location - (*ni).spanningLength, (*ni).accumulatedScore);
    path.insert(path.begin(), *ni);

    paths.push_back(path);
  }

  if (!paths.size()) {
    return std::vector<NodeAnchor>();
  }

  std::vector<NodeAnchor>* result = &*(paths.begin());
  for (std::vector<std::vector<NodeAnchor> >::iterator pi = paths.begin();
       pi != paths.end(); ++pi) {
    if ((*pi).back().accumulatedScore > result->back().accumulatedScore) {
      result = &*pi;
    }
  }

  return *result;
}
}  // namespace Gramambular
}  // namespace Formosa

#endif
