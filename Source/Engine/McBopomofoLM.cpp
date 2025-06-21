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
#include <limits>
#include <string>
#include <utility>
#include <vector>

#include "gramambular2/reading_grid.h"

namespace McBopomofo {

static constexpr std::string_view kMacroPrefix = "MACRO@";
static constexpr double kMacroScore = -8.0;

void McBopomofoLM::loadLanguageModel(const char* languageModelDataPath) {
  if (languageModelDataPath) {
    languageModel_.close();
    languageModel_.open(languageModelDataPath);
  }
}

bool McBopomofoLM::isDataModelLoaded() const {
  return languageModel_.isLoaded();
}

void McBopomofoLM::loadAssociatedPhrasesV2(const char* associatedPhrasesPath) {
  if (associatedPhrasesPath) {
    associatedPhrasesV2_.close();
    associatedPhrasesV2_.open(associatedPhrasesPath);
  }
}

void McBopomofoLM::loadUserPhrases(const char* userPhrasesDataPath,
                                   const char* excludedPhrasesDataPath) {
  userPhrases_.close();
  excludedPhrases_.close();

  if (userPhrasesDataPath) {
    userPhrases_.open(userPhrasesDataPath);
  }
  if (excludedPhrasesDataPath) {
    excludedPhrases_.open(excludedPhrasesDataPath);
  }
}

bool McBopomofoLM::isAssociatedPhrasesV2Loaded() const {
  return associatedPhrasesV2_.isLoaded();
}

void McBopomofoLM::loadPhraseReplacementMap(const char* phraseReplacementPath) {
  if (phraseReplacementPath) {
    phraseReplacement_.close();
    phraseReplacement_.open(phraseReplacementPath);
  }
}

std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
McBopomofoLM::getUnigrams(const std::string& key) {
  if (key == " ") {
    std::vector<Formosa::Gramambular2::LanguageModel::Unigram> spaceUnigrams;
    spaceUnigrams.emplace_back(" ", 0);
    return spaceUnigrams;
  }

  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> allUnigrams;
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> userUnigrams;

  std::unordered_set<std::string> excludedValues;
  std::unordered_set<std::string> insertedValues;

  if (excludedPhrases_.hasUnigrams(key)) {
    std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
        excludedUnigrams = excludedPhrases_.getUnigrams(key);
    std::transform(excludedUnigrams.begin(), excludedUnigrams.end(),
                   std::inserter(excludedValues, excludedValues.end()),
                   [](const Formosa::Gramambular2::LanguageModel::Unigram& u) {
                     return u.value();
                   });
  }

  if (userPhrases_.hasUnigrams(key)) {
    std::vector<Formosa::Gramambular2::LanguageModel::Unigram> rawUserUnigrams =
        userPhrases_.getUnigrams(key);
    userUnigrams = filterAndTransformUnigrams(rawUserUnigrams, excludedValues,
                                              insertedValues);
  }

  if (languageModel_.hasUnigrams(key)) {
    std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
        rawGlobalUnigrams = languageModel_.getUnigrams(key);
    allUnigrams = filterAndTransformUnigrams(rawGlobalUnigrams, excludedValues,
                                             insertedValues);
  }

  // This relies on the fact that we always use the default separator.
  bool isKeyMultiSyllable =
      key.find(Formosa::Gramambular2::ReadingGrid::kDefaultSeparator) !=
      std::string::npos;

  // If key is multi-syllabic (for example, ㄉㄨㄥˋ-ㄈㄢˋ), we just
  // insert all collected userUnigrams on top of the unigrams fetched from
  // the database. If key is mono-syllabic (for example, ㄉㄨㄥˋ), then
  // we'll have to rewrite the collected userUnigrams.
  //
  // This is because, by default, user unigrams have a score of 0, which
  // guarantees that grid walks will choose them. This is problematic,
  // however, when a single-syllabic user phrase is competing with other
  // multisyllabic phrases that start with the same syllable. For example,
  // if a user has 丼 for ㄉㄨㄥˋ, and because that unigram has a score
  // of 0, no other phrases in the database that start with ㄉㄨㄥˋ would
  // be able to compete with it. Without the rewrite, ㄉㄨㄥˋ-ㄗㄨㄛˋ
  // would always result in "丼" + "作" instead of "動作" because the
  // node for "丼" would dominate the walk.
  if (isKeyMultiSyllable || allUnigrams.empty()) {
    allUnigrams.insert(allUnigrams.begin(), userUnigrams.begin(),
                       userUnigrams.end());
  } else if (!userUnigrams.empty()) {
    // Find the highest score from the existing allUnigrams.
    double topScore = std::numeric_limits<double>::lowest();
    for (const auto& unigram : allUnigrams) {
      if (unigram.score() > topScore) {
        topScore = unigram.score();
      }
    }

    // Boost by a very small number. This is the score for user phrases.
    constexpr double epsilon = 0.000000001;
    double boostedScore = topScore + epsilon;

    std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
        rewrittenUserUnigrams;
    for (const auto& unigram : userUnigrams) {
      rewrittenUserUnigrams.emplace_back(
          Formosa::Gramambular2::LanguageModel::Unigram(unigram.value(),
                                                        boostedScore));
    }
    allUnigrams.insert(allUnigrams.begin(), rewrittenUserUnigrams.begin(),
                       rewrittenUserUnigrams.end());
  }

  return allUnigrams;
}

bool McBopomofoLM::hasUnigrams(const std::string& key) {
  if (key == " ") {
    return true;
  }

  if (!excludedPhrases_.hasUnigrams(key)) {
    return userPhrases_.hasUnigrams(key) || languageModel_.hasUnigrams(key);
  }

  return !getUnigrams(key).empty();
}

std::string McBopomofoLM::getReading(const std::string& value) const {
  std::vector<ParselessLM::FoundReading> foundReadings =
      languageModel_.getReadings(value);
  double topScore = std::numeric_limits<double>::lowest();
  std::string topValue;
  for (const auto& foundReading : foundReadings) {
    if (foundReading.score > topScore) {
      topValue = foundReading.reading;
      topScore = foundReading.score;
    }
  }
  return topValue;
}

std::vector<AssociatedPhrasesV2::Phrase> McBopomofoLM::findAssociatedPhrasesV2(
    const std::string& prefixValue,
    const std::vector<std::string>& prefixReadings) const {
  return associatedPhrasesV2_.findPhrases(prefixValue, prefixReadings);
}

void McBopomofoLM::setPhraseReplacementEnabled(bool enabled) {
  phraseReplacementEnabled_ = enabled;
}

bool McBopomofoLM::phraseReplacementEnabled() const {
  return phraseReplacementEnabled_;
}

void McBopomofoLM::setExternalConverterEnabled(bool enabled) {
  externalConverterEnabled_ = enabled;
}

bool McBopomofoLM::externalConverterEnabled() const {
  return externalConverterEnabled_;
}

void McBopomofoLM::setExternalConverter(
    std::function<std::string(const std::string&)> externalConverter) {
  externalConverter_ = std::move(externalConverter);
}

void McBopomofoLM::setMacroConverter(
    std::function<std::string(const std::string&)> macroConverter) {
  macroConverter_ = std::move(macroConverter);
}

std::string McBopomofoLM::convertMacro(const std::string& input) {
  if (macroConverter_ != nullptr) {
    return macroConverter_(input);
  }
  return input;
}

std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
McBopomofoLM::filterAndTransformUnigrams(
    const std::vector<Formosa::Gramambular2::LanguageModel::Unigram> unigrams,
    const std::unordered_set<std::string>& excludedValues,
    std::unordered_set<std::string>& insertedValues) {
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> results;

  for (auto&& unigram : unigrams) {
    std::vector<std::string> annotations;
    // excludedValues filters out the unigrams with the original value.
    // insertedValues filters out the ones with the converted value
    const std::string& originalValue = unigram.value();
    if (excludedValues.find(originalValue) != excludedValues.end()) {
      continue;
    }

    std::string value = originalValue;
    if (phraseReplacementEnabled_) {
      std::string replacement = phraseReplacement_.valueForKey(value);
      if (!replacement.empty()) {
        annotations.emplace_back("replacement applied");
        value = replacement;
      }
    }
    if (macroConverter_ != nullptr) {
      std::string replacement = macroConverter_(value);
      if (value != replacement) {
        annotations.emplace_back("macro expanded");
        value = replacement;
      }
    }

    // Check if the string is an unsupported macro
    if (unigram.score() == kMacroScore && value.size() > kMacroPrefix.size() &&
        value.compare(0, kMacroPrefix.size(), kMacroPrefix) == 0) {
      continue;
    }

    if (externalConverterEnabled_ && externalConverter_ != nullptr) {
      std::string replacement = externalConverter_(value);
      if (value != replacement) {
        annotations.emplace_back("external converter applied");
        value = replacement;
      }
    }
    if (insertedValues.find(value) == insertedValues.end()) {
      results.emplace_back(value, unigram.score(), originalValue, annotations);
      insertedValues.insert(value);
    }
  }
  return results;
}

void McBopomofoLM::loadLanguageModel(std::unique_ptr<ParselessPhraseDB> db) {
  languageModel_.close();
  languageModel_.open(std::move(db));
}

void McBopomofoLM::loadAssociatedPhrasesV2(
    std::unique_ptr<ParselessPhraseDB> db) {
  associatedPhrasesV2_.close();
  associatedPhrasesV2_.open(std::move(db));
}

void McBopomofoLM::loadUserPhrases(const char* data, size_t length) {
  userPhrases_.close();
  userPhrases_.load(data, length);
}

void McBopomofoLM::loadExcludedPhrases(const char* data, size_t length) {
  excludedPhrases_.close();
  excludedPhrases_.load(data, length);
}

void McBopomofoLM::loadPhraseReplacementMap(const char* data, size_t length) {
  phraseReplacement_.close();
  phraseReplacement_.load(data, length);
}

}  // namespace McBopomofo
