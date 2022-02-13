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
            void insertNode(const Node& inNode, size_t inLocation, size_t inSpanningLength);
            bool hasNodeAtLocationSpanningLengthMatchingKey(size_t inLocation, size_t inSpanningLength, const string& inKey);

            void expandGridByOneAtLocation(size_t inLocation);
            void shrinkGridByOneAtLocation(size_t inLocation);

            size_t width() const;
            vector<NodeAnchor> nodesEndingAt(size_t inLocation);
            vector<NodeAnchor> nodesCrossingOrEndingAt(size_t inLocation);

            // "Freeze" the node with the unigram that represents the selected candidate value.
            // After this, the node that contains the unigram will always be evaluated to that
            // unigram, while all other overlapping nodes will be reset to their initial state
            // (that is, if any of those nodes were "frozen" or fixed, they will be unfrozen.)
            NodeAnchor fixNodeSelectedCandidate(size_t location, const string& value);

            // Similar to fixNodeSelectedCandidate, but instead of "freezing" the node, only
            // boost the unigram that represents the value with an overriding score. This
            // has the same side effect as fixNodeSelectedCandidate, which is that all other
            // overlapping nodes will be reset to their initial state.
            void overrideNodeScoreForSelectedCandidate(size_t location, const string& value, float overridingScore);
            
            const string dumpDOT();
            
        protected:
            vector<Span> m_spans;
        };
        
        inline void Grid::clear()
        {
            m_spans.clear();
        }
        
        inline void Grid::insertNode(const Node& inNode, size_t inLocation, size_t inSpanningLength)
        {            
            if (inLocation >= m_spans.size()) {
                size_t diff = inLocation - m_spans.size() + 1;
                
                for (size_t i = 0 ; i < diff ; i++) {
                    m_spans.push_back(Span());
                }
            }

            m_spans[inLocation].insertNodeOfLength(inNode, inSpanningLength);
        }

        inline bool Grid::hasNodeAtLocationSpanningLengthMatchingKey(size_t inLocation, size_t inSpanningLength, const string& inKey)
        {
            if (inLocation > m_spans.size()) {
                return false;
            }
            
            const Node *n = m_spans[inLocation].nodeOfLength(inSpanningLength);
            if (!n) {
                return false;
            }
            
            return inKey == n->key();
        }

        inline void Grid::expandGridByOneAtLocation(size_t inLocation)
        {
            if (!inLocation || inLocation == m_spans.size()) {
                m_spans.insert(m_spans.begin() + inLocation, Span());
            }
            else {
                m_spans.insert(m_spans.begin() + inLocation, Span());
                for (size_t i = 0 ; i < inLocation ; i++) {
                    // zaps overlapping spans
                    m_spans[i].removeNodeOfLengthGreaterThan(inLocation - i);
                }
            }
        }
        
        inline void Grid::shrinkGridByOneAtLocation(size_t inLocation)
        {
            if (inLocation >= m_spans.size()) {
                return;
            }
            
            m_spans.erase(m_spans.begin() + inLocation);
            for (size_t i = 0 ; i < inLocation ; i++) {
                // zaps overlapping spans
                m_spans[i].removeNodeOfLengthGreaterThan(inLocation - i);
            }
        }

        inline size_t Grid::width() const
        {
            return m_spans.size();
        }
        
        inline vector<NodeAnchor> Grid::nodesEndingAt(size_t inLocation)
        {
            vector<NodeAnchor> result;
            
            if (m_spans.size() && inLocation <= m_spans.size()) {
                for (size_t i = 0 ; i < inLocation ; i++) {
                    Span& span = m_spans[i];
                    if (i + span.maximumLength() >= inLocation) {
                        Node *np = span.nodeOfLength(inLocation - i);
                        if (np) {
                            NodeAnchor na;
                            na.node = np;
                            na.location = i;
                            na.spanningLength = inLocation - i;
                            
                            result.push_back(na);
                        }
                    }
                }
            }
            
            return result;
        }

        inline vector<NodeAnchor> Grid::nodesCrossingOrEndingAt(size_t inLocation)
        {
            vector<NodeAnchor> result;
            
            if (m_spans.size() && inLocation <= m_spans.size()) {
                for (size_t i = 0 ; i < inLocation ; i++) {
                    Span& span = m_spans[i];
                    
                    if (i + span.maximumLength() >= inLocation) {

                        for (size_t j = 1, m = span.maximumLength(); j <= m ; j++) { 
                            
                            if (i + j < inLocation) {
                                continue;
                            }
                            
                            Node *np = span.nodeOfLength(j);
                            if (np) {
                                NodeAnchor na;
                                na.node = np;
                                na.location = i;
                                na.spanningLength = inLocation - i;
                                
                                result.push_back(na);
                            }
                        }
                    }
                }
            }
            
            return result;
        }

        // For nodes found at the location, fix their currently-selected candidate using the supplied string value.
        inline NodeAnchor Grid::fixNodeSelectedCandidate(size_t location, const string& value)
        {
            vector<NodeAnchor> nodes = nodesCrossingOrEndingAt(location);
            NodeAnchor node;
            for (auto nodeAnchor : nodes) {
                auto candidates = nodeAnchor.node->candidates();

                // Reset the candidate-fixed state of every node at the location.
                const_cast<Node*>(nodeAnchor.node)->resetCandidate();

                for (size_t i = 0, c = candidates.size(); i < c; ++i) {
                    if (candidates[i].value == value) {
                        const_cast<Node*>(nodeAnchor.node)->selectCandidateAtIndex(i);
                        node = nodeAnchor;
                        break;;
                    }
                }
            }
            return node;
        }

        inline void Grid::overrideNodeScoreForSelectedCandidate(size_t location, const string& value, float overridingScore)
        {
            vector<NodeAnchor> nodes = nodesCrossingOrEndingAt(location);
            for (auto nodeAnchor : nodes) {
                auto candidates = nodeAnchor.node->candidates();

                // Reset the candidate-fixed state of every node at the location.
                const_cast<Node*>(nodeAnchor.node)->resetCandidate();

                for (size_t i = 0, c = candidates.size(); i < c; ++i) {
                    if (candidates[i].value == value) {
                        const_cast<Node*>(nodeAnchor.node)->selectFloatingCandidateAtIndex(i, overridingScore);
                        break;
                    }
                }
            }
        }
        
        inline const string Grid::dumpDOT()
        {
            stringstream sst;
            sst << "digraph {" << endl;
            sst << "graph [ rankdir=LR ];" << endl;
            sst << "BOS;" << endl;
            
            for (size_t p = 0 ; p < m_spans.size() ; p++) {
                Span& span = m_spans[p];
                for (size_t ni = 0 ; ni <= span.maximumLength() ; ni++) {
                    Node* np = span.nodeOfLength(ni);
                    if (np) {
                        if (!p) {
                            sst << "BOS -> " << np->currentKeyValue().value << ";" << endl;
                        }
                        
                        sst << np->currentKeyValue().value << ";" << endl;
                        
                        if (p + ni < m_spans.size()) {
                            Span& dstSpan = m_spans[p+ni];
                            for (size_t q = 0 ; q <= dstSpan.maximumLength() ; q++) {
                                Node *dn = dstSpan.nodeOfLength(q);
                                if (dn) {
                                    sst << np->currentKeyValue().value << " -> " << dn->currentKeyValue().value << ";" << endl;
                                }
                            }
                        }
                        
                        if (p + ni == m_spans.size()) {
                            sst << np->currentKeyValue().value << " -> " << "EOS;" << endl;
                        }
                    }
                }
            }
            
            sst << "EOS;" << endl;
            sst << "}";
            return sst.str();
        }        
    }
}

#endif
