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
#include <vector>

#include "KeyValueBlobReader.h"

namespace McBopomofo {

bool UserPhrasesLM::open(const char* path) {
  if (!mmapedFile_.open(path)) {
    return false;
  }

  // MemoryMappedFile self-closes, and so this is fine.
  return load(mmapedFile_.data(), mmapedFile_.length());
}

void UserPhrasesLM::close() {
  keyRowMap.clear();
  mmapedFile_.close();
}

bool UserPhrasesLM::load(const char* data, size_t length) {
  if (data == nullptr || length == 0) {
    return false;
  }

  keyRowMap.clear();

  KeyValueBlobReader reader(data, length);
  KeyValueBlobReader::KeyValue keyValue;
  while (reader.Next(&keyValue) == KeyValueBlobReader::State::HAS_PAIR) {
    // The format of the user phrases files is a bit different. The first column
    // is the phrase (value) and the second column is the Bopofomo reading. The
    // KeyValueBlobReader::KeyValue's value is the second column, that's why
    // it's used as the key of the keyRowMap here.
    keyRowMap[keyValue.value].emplace_back(keyValue.key);
  }
  return true;
}

std::vector<Formosa::Gramambular2::LanguageModel::Unigram>
UserPhrasesLM::getUnigrams(const std::string& key) {
  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> v;
  auto iter = keyRowMap.find(key);
  if (iter != keyRowMap.end()) {
    const std::vector<std::string_view>& values = iter->second;
    for (const auto& value : values) {
      v.emplace_back(std::string(value), kUserUnigramScore);
    }
  }

  return v;
}

bool UserPhrasesLM::hasUnigrams(const std::string& key) {
  return keyRowMap.find(key) != keyRowMap.end();
}

}  // namespace McBopomofo
