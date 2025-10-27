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

#include "UserPhrasesLM.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <fstream>
#include <string>
#include <vector>

namespace McBopomofo {

bool UserPhrasesLM::open(const char* path) {
  if (!mmapedFile_.open(path)) {
    return false;
  }

  // MemoryMappedFile self-closes, and so this is fine.
  return load(mmapedFile_.data(), mmapedFile_.length());
}

void UserPhrasesLM::close() {
  dictionary_.clear();
  mmapedFile_.close();
}

bool UserPhrasesLM::load(const char* data, size_t length) {
  if (data == nullptr || length == 0) {
    return false;
  }

  return dictionary_.parse(
      data, length, ByteBlockBackedDictionary::ColumnOrder::VALUE_THEN_KEY);
}
std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
UserPhrasesLM::getUnigrams(const std::string& key) {
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> v;

  std::vector<std::string_view> values = dictionary_.getValues(key);
  for (const auto& value : values) {
    v.emplace_back(std::string(value), kUserUnigramScore);
  }

  return v;
}

bool UserPhrasesLM::hasUnigrams(const std::string& key) {
  return dictionary_.hasKey(key);
}

std::vector<ByteBlockBackedDictionary::Issue> UserPhrasesLM::getParsingIssues()
    const {
  return dictionary_.issues();
}

}  // namespace McBopomofo
