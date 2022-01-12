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
}

void McBopomofoLM::loadLanguageModel(const char* languageModelDataPath)
{
    m_languageModel.close();
    m_languageModel.open(languageModelDataPath);
}

void McBopomofoLM::loadUserPhrases(const char* userPhrasesDataPath,
                                   const char* excludedPhrasesDataPath)
{
    m_userPhrases.close();
    m_userPhrases.open(userPhrasesDataPath);
    m_excludedPhrases.close();
    m_excludedPhrases.open(excludedPhrasesDataPath);
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

        for (auto&& unigram : rawUserUnigrams) {
            if (excludedValues.find(unigram.keyValue.value) == excludedValues.end()) {
                userUnigrams.push_back(unigram);
            }
        }

        transform(userUnigrams.begin(), userUnigrams.end(),
                  inserter(userValues, userValues.end()),
                  [](const Unigram &u) { return u.keyValue.value; });
    }

    if (m_languageModel.hasUnigramsForKey(key)) {
        vector<Unigram> globalUnigrams = m_languageModel.unigramsForKey(key);

        for (auto&& unigram : globalUnigrams) {
            if (excludedValues.find(unigram.keyValue.value) == excludedValues.end() &&
                userValues.find(unigram.keyValue.value) == userValues.end()) {
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
