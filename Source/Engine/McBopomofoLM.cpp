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

#include "McBopomofoLM.h"
#include <algorithm>
#include <iterator>
#include <unordered_set>

using namespace McBopomofo;

McBopomofoLM::McBopomofoLM()
{
}

McBopomofoLM::~McBopomofoLM()
{
    m_languageModel.close();
    m_userPhrases.close();
    m_excludedPhrases.close();
    m_phraseReplacement.close();
}

void McBopomofoLM::loadLanguageModel(const char* languageModelDataPath)
{
    if (languageModelDataPath) {
        m_languageModel.close();
        m_languageModel.open(languageModelDataPath);
    }
}

void McBopomofoLM::loadUserPhrases(const char* userPhrasesDataPath,
                                   const char* excludedPhrasesDataPath)
{
    if (userPhrasesDataPath) {
        m_userPhrases.close();
        m_userPhrases.open(userPhrasesDataPath);
    }
    if (excludedPhrasesDataPath) {
        m_excludedPhrases.close();
        m_excludedPhrases.open(excludedPhrasesDataPath);
    }
}

void McBopomofoLM::loadPhraseReplacementMap(const char* phraseReplacementPath) {
    if (phraseReplacementPath) {
        m_phraseReplacement.close();
        m_phraseReplacement.open(phraseReplacementPath);
    }
}

const vector<Bigram> McBopomofoLM::bigramsForKeys(const string& preceedingKey, const string& key)
{
    return vector<Bigram>();
}

const vector<Unigram> McBopomofoLM::unigramsForKey(const string& key)
{
    vector<Unigram> unigrams;
    vector<Unigram> userUnigrams;

    // Use unordered_set so that you don't have to do O(n*m)
    unordered_set<string> excludedValues;
    unordered_set<string> userValues;

    if (m_excludedPhrases.hasUnigramsForKey(key)) {
        vector<Unigram> excludedUnigrams = m_excludedPhrases.unigramsForKey(key);
        transform(excludedUnigrams.begin(), excludedUnigrams.end(),
                  inserter(excludedValues, excludedValues.end()),
                  [](const Unigram &u) { return u.keyValue.value; });
    }

    if (m_userPhrases.hasUnigramsForKey(key)) {
        vector<Unigram> rawUserUnigrams = m_userPhrases.unigramsForKey(key);
        vector<Unigram> filterredUserUnigrams = m_userPhrases.unigramsForKey(key);

        for (auto&& unigram : rawUserUnigrams) {
            if (excludedValues.find(unigram.keyValue.value) == excludedValues.end()) {
                filterredUserUnigrams.push_back(unigram);
            }
        }

        transform(filterredUserUnigrams.begin(), filterredUserUnigrams.end(),
                  inserter(userValues, userValues.end()),
                  [](const Unigram &u) { return u.keyValue.value; });

        if (m_phraseReplacementEnabled) {
            for (auto&& unigram : filterredUserUnigrams) {
                string value = unigram.keyValue.value;
                string replacement = m_phraseReplacement.valueForKey(value);
                if (replacement != "") {
                    unigram.keyValue.value = replacement;
                }
                unigrams.push_back(unigram);
            }
        } else {
            unigrams = filterredUserUnigrams;
        }
    }

    if (m_languageModel.hasUnigramsForKey(key)) {
        vector<Unigram> globalUnigrams = m_languageModel.unigramsForKey(key);

        for (auto&& unigram : globalUnigrams) {
            string value = unigram.keyValue.value;
            if (excludedValues.find(value) == excludedValues.end() &&
                userValues.find(value) == userValues.end()) {
                if (m_phraseReplacementEnabled) {
                    string replacement = m_phraseReplacement.valueForKey(value);
                    if (replacement != "") {
                        unigram.keyValue.value = replacement;
                    }
                }
                unigrams.push_back(unigram);
            }
        }
    }

    unigrams.insert(unigrams.begin(), userUnigrams.begin(), userUnigrams.end());
    return unigrams;
}

bool McBopomofoLM::hasUnigramsForKey(const string& key)
{
    if (!m_excludedPhrases.hasUnigramsForKey(key)) {
        return m_userPhrases.hasUnigramsForKey(key) ||
        m_languageModel.hasUnigramsForKey(key);
    }

    return unigramsForKey(key).size() > 0;
}

void McBopomofoLM::setPhraseReplacementEnabled(bool enabled)
{
    m_phraseReplacementEnabled = enabled;
}

bool McBopomofoLM::phraseReplacementEnabled()
{
    return m_phraseReplacementEnabled;
}

