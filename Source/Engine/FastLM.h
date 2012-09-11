//
// FastLM.h: A fast unigram language model for Gramambular
//
// Copyright (c) 2012 Lukhnos Liu (http://lukhnos.org)
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

#ifndef FASTLM_H
#define FASTLM_H

#include <string>
#include <map>
#include <iostream>
#include "LanguageModel.h"

// this class relies on the fact that we have a space-separated data
// format, and we use mmap and zero-out the separators and line feeds
// to avoid creating new string objects; the parser is a simple DFA

namespace Formosa {
    namespace Gramambular {
        class FastLM : public LanguageModel
        {
        public:
            FastLM();
            ~FastLM();

            bool open(const char *path);
            void close();
            void dump();

            virtual const vector<Bigram> bigramsForKeys(const string& preceedingKey, const string& key);
            virtual const vector<Unigram> unigramsForKeys(const string& key);
            virtual bool hasUnigramsForKey(const string& key);

        protected:
            struct CStringCmp
            {
                bool operator()(const char* s1, const char* s2) const
                {
                    return strcmp(s1, s2) < 0;
                }
            };

            struct Row {
                const char *key;
                const char *value;
                const char *logProbability;
            };

            map<const char *, vector<Row>, CStringCmp> keyRowMap;
            int fd;
            void *data;
            size_t length;
        };

    }
}

#endif
