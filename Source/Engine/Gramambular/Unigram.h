//
// Unigram.h
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

#ifndef Unigram_h
#define Unigram_h

#include <vector>
#include "KeyValuePair.h"

namespace Formosa {
    namespace Gramambular {
        class Unigram {
        public:
            Unigram();

            KeyValuePair keyValue;
            double score;
            
            bool operator==(const Unigram& inAnother) const;
            bool operator<(const Unigram& inAnother) const;
            
            static bool ScoreCompare(const Unigram& a, const Unigram& b);
        };

        inline ostream& operator<<(ostream& inStream, const Unigram& inGram)
        {
            streamsize p = inStream.precision();
            inStream.precision(6);
            inStream << "(" << inGram.keyValue << "," << inGram.score << ")";
            inStream.precision(p);
            return inStream;
        }
        
        inline ostream& operator<<(ostream& inStream, const vector<Unigram>& inGrams)
        {
            inStream << "[" << inGrams.size() << "]=>{";
            
            size_t index = 0;
            
            for (vector<Unigram>::const_iterator gi = inGrams.begin() ; gi != inGrams.end() ; ++gi, ++index) {
                inStream << index << "=>";
                inStream << *gi;
                if (gi + 1 != inGrams.end()) {
                    inStream << ",";
                }
            }
            
            inStream << "}";
            return inStream;
        }
        
        inline Unigram::Unigram()
            : score(0.0)
        {
        }
        
        inline bool Unigram::operator==(const Unigram& inAnother) const
        {
            return keyValue == inAnother.keyValue && score == inAnother.score;
        }
        
        inline bool Unigram::operator<(const Unigram& inAnother) const
        {
            if (keyValue < inAnother.keyValue) {
                return true;
            }
            else if (keyValue == inAnother.keyValue) {
                return score < inAnother.score;
            }
            return false;
        }

        inline bool Unigram::ScoreCompare(const Unigram& a, const Unigram& b)
        {
            return a.score > b.score;
        }
    }
}

#endif
