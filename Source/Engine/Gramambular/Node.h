//
// Node.h
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

#ifndef Node_h
#define Node_h

#include <limits>
#include <vector>
#include "LanguageModel.h"

namespace Formosa {
    namespace Gramambular {
        using namespace std;

        class Node {
        public:
            Node();
            Node(const string& inKey, const vector<Unigram>& inUnigrams, const vector<Bigram>& inBigrams);
            
            void primeNodeWithPreceedingKeyValues(const vector<KeyValuePair>& inKeyValues);
            
            bool isCandidateFixed() const;
            const vector<KeyValuePair>& candidates() const;
            void selectCandidateAtIndex(size_t inIndex = 0, bool inFix = true);
            void selectFloatingCandidateAtIndex(size_t index, double score);
            void resetCandidate();
            
            const string& key() const;
            double score() const;
            const KeyValuePair currentKeyValue() const;
            double highestUnigramScore() const;
            
        protected:
            const LanguageModel* m_LM;
            
            string m_key;
            double m_score;
            
            vector<Unigram> m_unigrams;
            vector<KeyValuePair> m_candidates;
            map<string, size_t> m_valueUnigramIndexMap;
            map<KeyValuePair, vector<Bigram> > m_preceedingGramBigramMap;
            
            bool m_candidateFixed;
            size_t m_selectedUnigramIndex;
            
            friend ostream& operator<<(ostream& inStream, const Node& inNode);
        };

        inline ostream& operator<<(ostream& inStream, const Node& inNode)
        {
            inStream << "(node,key:" << inNode.m_key << ",fixed:" << (inNode.m_candidateFixed ? "true" : "false")
                << ",selected:" << inNode.m_selectedUnigramIndex
                << "," << inNode.m_unigrams << ")";
            return inStream;
        }

        inline Node::Node()
            : m_candidateFixed(false)
            , m_selectedUnigramIndex(0)
            , m_score(0.0)
        {
        }

        inline Node::Node(const string& inKey, const vector<Unigram>& inUnigrams, const vector<Bigram>& inBigrams)
            : m_key(inKey)
            , m_unigrams(inUnigrams)
            , m_candidateFixed(false)
            , m_selectedUnigramIndex(0)
            , m_score(0.0)
        {
            stable_sort(m_unigrams.begin(), m_unigrams.end(), Unigram::ScoreCompare);
            
            if (m_unigrams.size()) {
                m_score = m_unigrams[0].score;
            }
            
            size_t i = 0;
            for (vector<Unigram>::const_iterator ui = m_unigrams.begin() ; ui != m_unigrams.end() ; ++ui) {
                m_valueUnigramIndexMap[(*ui).keyValue.value] = i;
                i++;
                
                m_candidates.push_back((*ui).keyValue);
            }
            
            for (vector<Bigram>::const_iterator bi = inBigrams.begin() ; bi != inBigrams.end() ; ++bi) {
                m_preceedingGramBigramMap[(*bi).preceedingKeyValue].push_back(*bi);
            }
        }
        
        inline void Node::primeNodeWithPreceedingKeyValues(const vector<KeyValuePair>& inKeyValues)
        {
            size_t newIndex = m_selectedUnigramIndex;
            double max = m_score;

            if (!isCandidateFixed()) {
                for (vector<KeyValuePair>::const_iterator kvi = inKeyValues.begin() ; kvi != inKeyValues.end() ; ++kvi) {
                    map<KeyValuePair, vector<Bigram> >::const_iterator f = m_preceedingGramBigramMap.find(*kvi);
                    if (f != m_preceedingGramBigramMap.end()) {
                        const vector<Bigram>& bigrams = (*f).second;
                        
                        for (vector<Bigram>::const_iterator bi = bigrams.begin() ; bi != bigrams.end() ; ++bi) {
                            const Bigram& bigram = *bi;
                            if (bigram.score > max) {
                                map<string, size_t>::const_iterator uf = m_valueUnigramIndexMap.find((*bi).keyValue.value);
                                if (uf != m_valueUnigramIndexMap.end()) {
                                    newIndex = (*uf).second;
                                    max = bigram.score;
                                }
                            }
                        }
                    }
                }
            }

            if (m_score != max) {
                m_score = max;
            }
            
            if (newIndex != m_selectedUnigramIndex) {
                m_selectedUnigramIndex = newIndex;
            }
        }
        
        inline bool Node::isCandidateFixed() const
        {
            return m_candidateFixed;
        }
        
        inline const vector<KeyValuePair>& Node::candidates() const
        {
            return m_candidates;
        }

        inline void Node::selectCandidateAtIndex(size_t inIndex, bool inFix)
        {
            if (inIndex >= m_unigrams.size()) {
                m_selectedUnigramIndex = 0;
            }
            else {
                m_selectedUnigramIndex = inIndex;
            }            
            
            m_candidateFixed = inFix;
            m_score = 99;
        }        

        inline void Node::selectFloatingCandidateAtIndex(size_t index, double score) {
            if (index >= m_unigrams.size()) {
                m_selectedUnigramIndex = 0;
            } else {
                m_selectedUnigramIndex = index;
            }
            m_candidateFixed = false;
            m_score = score;
        }

        inline void Node::resetCandidate()
        {
            m_selectedUnigramIndex = 0;
            m_candidateFixed = 0;
            if (m_unigrams.size()) {
                m_score = m_unigrams[0].score;
            }
        }
        
        inline const string& Node::key() const
        {
            return m_key;
        }
        
        inline double Node::score() const
        {
            return m_score;
        }

        inline double Node::highestUnigramScore() const {
            if (m_unigrams.empty()) {
                return 0.0;
            }
            return m_unigrams[0].score;
        }
        
        inline const KeyValuePair Node::currentKeyValue() const
        {
            if(m_selectedUnigramIndex >= m_unigrams.size()) {
                return KeyValuePair();
            }
            else {
                return m_candidates[m_selectedUnigramIndex];
            }
        }        
    }
}

#endif
