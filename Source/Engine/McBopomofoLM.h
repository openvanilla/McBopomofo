#ifndef MCBOPOMOFOLM_H
#define MCBOPOMOFOLM_H

#include <stdio.h>
#include "FastLM.h"

namespace McBopomofo {

using namespace Formosa::Gramambular;

class McBopomofoLM : public LanguageModel {
public:
    McBopomofoLM();
    ~McBopomofoLM();

    void loadLanguageModel(const char* languageModelDataPath);
    void loadUserPhrases(const char* m_userPhrasesDataPath,
                         const char* m_excludedPhrasesDataPath);

    const vector<Bigram> bigramsForKeys(const string& preceedingKey, const string& key);
    const vector<Unigram> unigramsForKey(const string& key);
    bool hasUnigramsForKey(const string& key);

protected:
    FastLM m_languageModel;
    FastLM m_userPhrases;
    FastLM m_excludedPhrases;
};
};

#endif
