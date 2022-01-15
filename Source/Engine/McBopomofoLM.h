// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

#ifndef MCBOPOMOFOLM_H
#define MCBOPOMOFOLM_H

#include "FastLM.h"
#include "PhraseReplacementMap.h"
#include "UserPhrasesLM.h"
#include <unordered_set>

namespace McBopomofo {

using namespace Formosa::Gramambular;

class McBopomofoLM : public LanguageModel {
public:
    McBopomofoLM();
    ~McBopomofoLM();

    void loadLanguageModel(const char* languageModelPath);
    void loadUserPhrases(const char* userPhrasesPath, const char* excludedPhrasesPath);
    void loadPhraseReplacementMap(const char* phraseReplacementPath);

    const vector<Bigram> bigramsForKeys(const string& preceedingKey, const string& key);
    const vector<Unigram> unigramsForKey(const string& key);
    bool hasUnigramsForKey(const string& key);

    void setPhraseReplacementEnabled(bool enabled);
    bool phraseReplacementEnabled();

protected:
    const vector<Unigram> filterAndTransformUnigrams(vector<Unigram> unigrams,
        const std::unordered_set<string>& excludedValues,
        std::unordered_set<string>& insertedValues);

    FastLM m_languageModel;
    UserPhrasesLM m_userPhrases;
    UserPhrasesLM m_excludedPhrases;
    PhraseReplacementMap m_phraseReplacement;
    bool m_phraseReplacementEnabled;
};
};

#endif
