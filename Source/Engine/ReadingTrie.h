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

#ifndef SRC_ENGINE_READINGTRIE_H_
#define SRC_ENGINE_READINGTRIE_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "Mandarin/Mandarin.h"
#include "gramambular2/language_model.h"

namespace McBopomofo {

class ReadingTrie {
 public:
  using Unigram = Formosa::Gramambular2::LanguageModel::Unigram;

  ReadingTrie() = default;

  void insert(const std::string& key, const std::string& value, double score);
  std::vector<Unigram> findAbbreviated(const std::string& key) const;
  bool hasAbbreviatedUnigrams(const std::string& key) const;
  void clear();

  static bool containsAbbreviatedSyllable(const std::string& key);

 private:
  struct Node {
    std::unordered_map<std::string, std::unique_ptr<Node>> children;
    // Maps consonant string → list of child keys sharing that consonant.
    std::unordered_map<std::string, std::vector<std::string>> consonantIndex;
    std::vector<std::pair<std::string, double>> entries;
  };

  static std::vector<std::string> splitKey(const std::string& key);
  static bool isAbbreviated(const std::string& syllable);
  static std::string consonantOf(const std::string& syllable);

  void findRecursive(const Node* node,
                     const std::vector<std::string>& syllables, size_t depth,
                     std::vector<Unigram>& results) const;
  bool hasRecursive(const Node* node,
                    const std::vector<std::string>& syllables,
                    size_t depth) const;

  Node root_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_READINGTRIE_H_
