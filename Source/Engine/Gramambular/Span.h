//
// Span.h
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

#ifndef Span_h
#define Span_h

#include <map>
#include <set>
#include <sstream>

#include "Node.h"

namespace Formosa {
namespace Gramambular {
class Span {
 public:
  void clear();
  void insertNodeOfLength(const Node& node, size_t length);
  void removeNodeOfLengthGreaterThan(size_t length);

  Node* nodeOfLength(size_t length);
  size_t maximumLength() const;

 protected:
  std::map<size_t, Node> m_lengthNodeMap;
  size_t m_maximumLength = 0;
};

inline void Span::clear() {
  m_lengthNodeMap.clear();
  m_maximumLength = 0;
}

inline void Span::insertNodeOfLength(const Node& node, size_t length) {
  m_lengthNodeMap[length] = node;
  if (length > m_maximumLength) {
    m_maximumLength = length;
  }
}

inline void Span::removeNodeOfLengthGreaterThan(size_t length) {
  if (length > m_maximumLength) {
    return;
  }

  size_t max = 0;
  std::set<size_t> removeSet;
  for (std::map<size_t, Node>::iterator i = m_lengthNodeMap.begin(),
                                        e = m_lengthNodeMap.end();
       i != e; ++i) {
    if ((*i).first > length) {
      removeSet.insert((*i).first);
    } else {
      if ((*i).first > max) {
        max = (*i).first;
      }
    }
  }

  for (std::set<size_t>::iterator i = removeSet.begin(), e = removeSet.end();
       i != e; ++i) {
    m_lengthNodeMap.erase(*i);
  }

  m_maximumLength = max;
}

inline Node* Span::nodeOfLength(size_t length) {
  std::map<size_t, Node>::iterator f = m_lengthNodeMap.find(length);
  return f == m_lengthNodeMap.end() ? 0 : &(*f).second;
}

inline size_t Span::maximumLength() const { return m_maximumLength; }
}  // namespace Gramambular
}  // namespace Formosa

#endif
