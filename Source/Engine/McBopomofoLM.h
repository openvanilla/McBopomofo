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

#ifndef SRC_ENGINE_MCBOPOMOFOLM_H_
#define SRC_ENGINE_MCBOPOMOFOLM_H_

#include <functional>
#include <memory>
#include <string>
#include <unordered_set>
#include <vector>

#include "AssociatedPhrasesV2.h"
#include "ParselessLM.h"
#include "PhraseReplacementMap.h"
#include "UserPhrasesLM.h"
#include "gramambular2/language_model.h"

namespace McBopomofo {

// McBopomofoLM manages the input method's language models and performs text
// and macro conversions.
//
// When the reading grid requests unigrams from McBopomofoLM, the LM combines
// and transforms the unigrams from the primary language model and user phrases.
// The process is
//
// 1. Get the original unigrams.
// 2. Drop the unigrams from the user-exclusion list.
// 3. Replace the unigram values specified by the user phrase replacement map.
// 4. Transform the unigram values with an external converter, if supplied.
// 5. Remove any duplicates.
//
// McBopomofoLM itself is not responsible for reloading custom models (user
// phrases, excluded phrases, and replacement map). The LM's owner, usually the
// input method controller, needs to take care of checking for updates and
// telling McBopomofoLM to reload as needed.
class McBopomofoLM : public Formosa::Gramambular2::LanguageModel {
 public:
  McBopomofoLM() = default;

  McBopomofoLM(const McBopomofoLM&) = delete;
  McBopomofoLM(McBopomofoLM&&) = delete;
  McBopomofoLM& operator=(const McBopomofoLM&) = delete;
  McBopomofoLM& operator=(McBopomofoLM&&) = delete;

  // Loads (or reloads, if already loaded) the primary language model data file.
  void loadLanguageModel(const char* languageModelDataPath);

  bool isDataModelLoaded() const;

  // Loads (or reloads if already loaded) the associated phrases data file.
  void loadAssociatedPhrasesV2(const char* associatedPhrasesPath);

  bool isAssociatedPhrasesV2Loaded() const;

  // Loads (or reloads if already loaded) both the user phrases and the excluded
  // phrases files. If one argument is passed a nullptr, that file will not
  // be loaded or reloaded.
  void loadUserPhrases(const char* userPhrasesDataPath,
                       const char* excludedPhrasesDataPath);

  // Loads (or reloads if already loaded) the phrase replacement mapping file.
  void loadPhraseReplacementMap(const char* phraseReplacementPath);

  // Returns a list of unigrams for the reading. For example, if the reading is
  // "ㄇㄚ", the return may be [unigram("嗎"), unigram("媽") and so on.
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> getUnigrams(
      const std::string& key) override;

  bool hasUnigrams(const std::string& key) override;

  std::string getReading(const std::string& value) const;

  std::vector<AssociatedPhrasesV2::Phrase> findAssociatedPhrasesV2(
      const std::string& prefixValue,
      const std::vector<std::string>& prefixReadings) const;

  void setPhraseReplacementEnabled(bool enabled);
  bool phraseReplacementEnabled() const;

  void setExternalConverterEnabled(bool enabled);
  bool externalConverterEnabled() const;
  void setExternalConverter(
      std::function<std::string(const std::string&)> externalConverter);

  void setMacroConverter(
      std::function<std::string(const std::string&)> macroConverter);
  std::string convertMacro(const std::string& input);

  // Methods to allow loading in-memory data for testing purposes.
  void loadLanguageModel(std::unique_ptr<ParselessPhraseDB> db);
  void loadAssociatedPhrasesV2(std::unique_ptr<ParselessPhraseDB> db);
  void loadUserPhrases(const char* data, size_t length);
  void loadExcludedPhrases(const char* data, size_t length);
  void loadPhraseReplacementMap(const char* data, size_t length);

 protected:
  // Filters and converts the input unigrams and returns a new list of unigrams.
  // Unigrams whose values are found in `excludedValues` are removed, and the
  // kept values will be inserted to the `insertedValues` set.
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
  filterAndTransformUnigrams(
      const std::vector<Formosa::Gramambular2::LanguageModel::Unigram> unigrams,
      const std::unordered_set<std::string>& excludedValues,
      std::unordered_set<std::string>& insertedValues);

  ParselessLM languageModel_;
  UserPhrasesLM userPhrases_;
  UserPhrasesLM excludedPhrases_;
  PhraseReplacementMap phraseReplacement_;
  AssociatedPhrasesV2 associatedPhrasesV2_;

  bool phraseReplacementEnabled_ = false;

  bool externalConverterEnabled_ = false;
  std::function<std::string(const std::string&)> externalConverter_;

  std::function<std::string(const std::string&)> macroConverter_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_MCBOPOMOFOLM_H_
