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

#ifndef SRC_ENGINE_USERPHRASESLM_H_
#define SRC_ENGINE_USERPHRASESLM_H_

#include <map>
#include <string>
#include <vector>

#include "ByteBlockBackedDictionary.h"
#include "MemoryMappedFile.h"
#include "gramambular2/language_model.h"

namespace McBopomofo {

class UserPhrasesLM : public Formosa::Gramambular2::LanguageModel {
 public:
  UserPhrasesLM() = default;
  UserPhrasesLM(const UserPhrasesLM&) = delete;
  UserPhrasesLM(UserPhrasesLM&&) = delete;
  UserPhrasesLM& operator=(const UserPhrasesLM&) = delete;
  UserPhrasesLM& operator=(UserPhrasesLM&&) = delete;

  bool open(const char* path);
  void close();

  // Allows loading existing in-memory data. It's the caller's responsibility
  // to make sure that data outlives this instance.
  bool load(const char* data, size_t length);

  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> getUnigrams(
      const std::string& key) override;
  bool hasUnigrams(const std::string& key) override;

  std::vector<ByteBlockBackedDictionary::Issue> getParsingIssues() const;

  static constexpr double kUserUnigramScore = 0;

 protected:
  MemoryMappedFile mmapedFile_;
  ByteBlockBackedDictionary dictionary_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_USERPHRASESLM_H_
