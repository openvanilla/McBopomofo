//
// NodeAnchor.h
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

#ifndef NodeAnchor_h
#define NodeAnchor_h

#include "Node.h"

namespace Formosa {
    namespace Gramambular {
        class NodeAnchor {
        public:
            NodeAnchor();
            const Node *node;
            size_t location;
            size_t spanningLength;
            double accumulatedScore;
        };
        
        inline NodeAnchor::NodeAnchor()
            : node(0)
            , location(0)
            , spanningLength(0)
            , accumulatedScore(0.0)
        {
        }        

        inline ostream& operator<<(ostream& inStream, const NodeAnchor& inAnchor)
        {
            inStream << "{@(" << inAnchor.location << "," << inAnchor.spanningLength << "),";
            if (inAnchor.node) {
                inStream << *(inAnchor.node);
            }
            else {
                inStream << "null";
            }
            inStream << "}";
            return inStream;
        }
        
        inline ostream& operator<<(ostream& inStream, const vector<NodeAnchor>& inAnchor)
        {
            for (vector<NodeAnchor>::const_iterator i = inAnchor.begin() ; i != inAnchor.end() ; ++i) {
                inStream << *i;
                if (i + 1 != inAnchor.end()) {
                    inStream << "<-";
                }
            }
            
            return inStream;            
        }
    }
}

#endif
