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

namespace McBopomofo {

McBopomofoLM::McBopomofoLM()
{
}

McBopomofoLM::~McBopomofoLM()
{
    m_languageModel.close();
    m_emojiModel.close();
    m_userPhrases.close();
    m_excludedPhrases.close();
    m_phraseReplacement.close();
    m_associatedPhrases.close();
}

void McBopomofoLM::loadLanguageModel(const char* languageModelDataPath)
{
    if (languageModelDataPath) {
        m_languageModel.close();
        m_languageModel.open(languageModelDataPath);
    }
}

bool McBopomofoLM::isDataModelLoaded()
{
    return m_languageModel.isLoaded();
}

bool McBopomofoLM::isEmojiModelLoaded()
{
    return m_emojiModel.isLoaded();
}

void McBopomofoLM::setEmojiInputEnabled(bool enabled)
{
    m_emojiInputEnabled = enabled;
}
bool McBopomofoLM::emojiInputEnabled()
{
    return m_emojiInputEnabled;
}

void McBopomofoLM::loadAssociatedPhrases(const char* associatedPhrasesPath)
{
    if (associatedPhrasesPath) {
        m_associatedPhrases.close();
        m_associatedPhrases.open(associatedPhrasesPath);
    }
}

bool McBopomofoLM::isAssociatedPhrasesLoaded()
{
    return m_associatedPhrases.isLoaded();
}

void McBopomofoLM::loadEmojiModel(const char* emojiModelPath)
{
    if (emojiModelPath) {
        m_emojiModel.close();
        m_emojiModel.open(emojiModelPath);
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

void McBopomofoLM::loadPhraseReplacementMap(const char* phraseReplacementPath)
{
    if (phraseReplacementPath) {
        m_phraseReplacement.close();
        m_phraseReplacement.open(phraseReplacementPath);
    }
}

const std::vector<Formosa::Gramambular::Bigram> McBopomofoLM::bigramsForKeys(const std::string& preceedingKey, const std::string& key)
{
    return std::vector<Formosa::Gramambular::Bigram>();
}

const std::vector<Formosa::Gramambular::Unigram> McBopomofoLM::unigramsForKey(const std::string& key)
{
    if (key == " ") {
        std::vector<Formosa::Gramambular::Unigram> spaceUnigrams;
        Formosa::Gramambular::Unigram g;
        g.keyValue.key = " ";
        g.keyValue.value = " ";
        g.score = 0;
        spaceUnigrams.push_back(g);
        return spaceUnigrams;
    }

    std::vector<Formosa::Gramambular::Unigram> allUnigrams;
    std::vector<Formosa::Gramambular::Unigram> emojiUnigrams;
    std::vector<Formosa::Gramambular::Unigram> userUnigrams;

    std::unordered_set<std::string> excludedValues;
    std::unordered_set<std::string> insertedValues;

    if (m_excludedPhrases.hasUnigramsForKey(key)) {
        std::vector<Formosa::Gramambular::Unigram> excludedUnigrams = m_excludedPhrases.unigramsForKey(key);
        transform(excludedUnigrams.begin(), excludedUnigrams.end(),
            inserter(excludedValues, excludedValues.end()),
            [](const Formosa::Gramambular::Unigram& u) { return u.keyValue.value; });
    }

    if (m_userPhrases.hasUnigramsForKey(key)) {
        std::vector<Formosa::Gramambular::Unigram> rawUserUnigrams = m_userPhrases.unigramsForKey(key);
        userUnigrams = filterAndTransformUnigrams(rawUserUnigrams, excludedValues, insertedValues);
    }

    if (m_emojiModel.hasUnigramsForKey(key) && m_emojiInputEnabled) {
        std::vector<Formosa::Gramambular::Unigram> rawEmojiUnigrams = m_emojiModel.unigramsForKey(key);
        emojiUnigrams = filterAndTransformUnigrams(rawEmojiUnigrams, excludedValues, insertedValues);
    }

    if (m_languageModel.hasUnigramsForKey(key)) {
        std::vector<Formosa::Gramambular::Unigram> rawGlobalUnigrams = m_languageModel.unigramsForKey(key);
        allUnigrams = filterAndTransformUnigrams(rawGlobalUnigrams, excludedValues, insertedValues);
    }

    allUnigrams.insert(allUnigrams.begin(), userUnigrams.begin(), userUnigrams.end());
    allUnigrams.insert(allUnigrams.end(), emojiUnigrams.begin(), emojiUnigrams.end());
    return allUnigrams;
}

bool McBopomofoLM::hasUnigramsForKey(const std::string& key)
{
    if (key == " ") {
        return true;
    }

    if (!m_excludedPhrases.hasUnigramsForKey(key)) {
        return m_userPhrases.hasUnigramsForKey(key) || m_languageModel.hasUnigramsForKey(key);
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

void McBopomofoLM::setExternalConverterEnabled(bool enabled)
{
    m_externalConverterEnabled = enabled;
}

bool McBopomofoLM::externalConverterEnabled()
{
    return m_externalConverterEnabled;
}

void McBopomofoLM::setExternalConverter(std::function<std::string(std::string)> externalConverter)
{
    m_externalConverter = externalConverter;
}

const std::vector<Formosa::Gramambular::Unigram> McBopomofoLM::filterAndTransformUnigrams(const std::vector<Formosa::Gramambular::Unigram> unigrams, const std::unordered_set<std::string>& excludedValues, std::unordered_set<std::string>& insertedValues)
{
    std::vector<Formosa::Gramambular::Unigram> results;

    for (auto&& unigram : unigrams) {
        // excludedValues filters out the unigrams with the original value.
        // insertedValues filters out the ones with the converted value
        std::string originalValue = unigram.keyValue.value;
        if (excludedValues.find(originalValue) != excludedValues.end()) {
            continue;
        }

        std::string value = originalValue;
        if (m_phraseReplacementEnabled) {
            std::string replacement = m_phraseReplacement.valueForKey(value);
            if (replacement != "") {
                value = replacement;
            }
        }
        if (m_externalConverterEnabled && m_externalConverter) {
            std::string replacement = m_externalConverter(value);
            value = replacement;
        }
        if (insertedValues.find(value) == insertedValues.end()) {
            Formosa::Gramambular::Unigram g;
            g.keyValue.value = value;
            g.keyValue.key = unigram.keyValue.key;
            g.score = unigram.score;
            results.push_back(g);
            insertedValues.insert(value);
        }
    }
    return results;
}

const std::vector<std::string> McBopomofoLM::associatedPhrasesForKey(const std::string& key)
{
    return m_associatedPhrases.valuesForKey(key);
}

bool McBopomofoLM::hasAssociatedPhrasesForKey(const std::string& key)
{
    return m_associatedPhrases.hasValuesForKey(key);
}

} // namespace McBopomofo
