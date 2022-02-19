// Copyright (c) 2007 and onwards Lukhnos Liu
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

#include "Grid.h"

#include <iostream>
#include <string>

namespace Formosa {
namespace Gramambular {

std::string Grid::dumpDOT() {
  std::stringstream sst;
  sst << "digraph {" << std::endl;
  sst << "graph [ rankdir=LR ];" << std::endl;
  sst << "BOS;" << std::endl;

  for (unsigned long p = 0; p < m_spans.size(); p++) {
    Span& span = m_spans[p];
    for (unsigned long ni = 0; ni <= span.maximumLength(); ni++) {
      Node* np = span.nodeOfLength(ni);
      if (np) {
        if (!p) {
          sst << "BOS -> " << np->currentKeyValue().value << ";" << std::endl;
        }

        sst << np->currentKeyValue().value << ";" << std::endl;

        if (p + ni < m_spans.size()) {
          Span& dstSpan = m_spans[p + ni];
          for (unsigned long q = 0; q <= dstSpan.maximumLength(); q++) {
            Node* dn = dstSpan.nodeOfLength(q);
            if (dn) {
              sst << np->currentKeyValue().value << " -> "
                  << dn->currentKeyValue().value << ";" << std::endl;
            }
          }
        }

        if (p + ni == m_spans.size()) {
          sst << np->currentKeyValue().value << " -> "
              << "EOS;" << std::endl;
        }
      }
    }
  }

  sst << "EOS;" << std::endl;
  sst << "}";
  return sst.str();
}

}  // namespace Gramambular
}  // namespace Formosa
