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

#include "ReadingTrie.h"

#include <sstream>

namespace McBopomofo {

using BPMF = Formosa::Mandarin::BopomofoSyllable;

void ReadingTrie::insert(const std::string& key, const std::string& value,
                         double score) {
  auto syllables = splitKey(key);
  Node* current = &root_;
  for (const auto& syllable : syllables) {
    auto it = current->children.find(syllable);
    if (it == current->children.end()) {
      current->children[syllable] = std::make_unique<Node>();
      // Build consonant index for abbreviated lookups.
      std::string consonant = consonantOf(syllable);
      if (!consonant.empty()) {
        current->consonantIndex[consonant].push_back(syllable);
      }
    }
    current = current->children[syllable].get();
  }
  current->entries.emplace_back(value, score);
}

std::vector<ReadingTrie::Unigram> ReadingTrie::findAbbreviated(
    const std::string& key) const {
  auto syllables = splitKey(key);
  if (syllables.empty()) return {};
  std::vector<Unigram> results;
  findRecursive(&root_, syllables, 0, results);
  return results;
}

bool ReadingTrie::hasAbbreviatedUnigrams(const std::string& key) const {
  auto syllables = splitKey(key);
  if (syllables.empty()) return false;
  return hasRecursive(&root_, syllables, 0);
}

void ReadingTrie::clear() { root_.children.clear(); }

bool ReadingTrie::containsAbbreviatedSyllable(const std::string& key) {
  auto syllables = splitKey(key);
  for (const auto& s : syllables) {
    if (isAbbreviated(s)) {
      return true;
    }
  }
  return false;
}

std::vector<std::string> ReadingTrie::splitKey(const std::string& key) {
  std::vector<std::string> result;
  std::istringstream stream(key);
  std::string token;
  while (std::getline(stream, token, '-')) {
    if (!token.empty()) {
      result.push_back(token);
    }
  }
  return result;
}

bool ReadingTrie::isAbbreviated(const std::string& syllable) {
  auto bpmf = BPMF::FromComposedString(syllable);
  return bpmf.isConsonantOnly();
}

std::string ReadingTrie::consonantOf(const std::string& syllable) {
  auto bpmf = BPMF::FromComposedString(syllable);
  BPMF consonantOnly(bpmf.consonantComponent());
  return consonantOnly.composedString();
}

void ReadingTrie::findRecursive(const Node* node,
                                const std::vector<std::string>& syllables,
                                size_t depth,
                                std::vector<Unigram>& results) const {
  if (depth == syllables.size()) {
    for (const auto& entry : node->entries) {
      results.emplace_back(entry.first, entry.second);
    }
    return;
  }

  const auto& syllable = syllables[depth];

  if (isAbbreviated(syllable)) {
    // Use pre-built consonant index instead of scanning all children.
    auto indexIt = node->consonantIndex.find(syllable);
    if (indexIt != node->consonantIndex.end()) {
      for (const auto& childKey : indexIt->second) {
        auto childIt = node->children.find(childKey);
        if (childIt != node->children.end()) {
          findRecursive(childIt->second.get(), syllables, depth + 1, results);
        }
      }
    }
  } else {
    auto it = node->children.find(syllable);
    if (it != node->children.end()) {
      findRecursive(it->second.get(), syllables, depth + 1, results);
    }
  }
}

bool ReadingTrie::hasRecursive(const Node* node,
                               const std::vector<std::string>& syllables,
                               size_t depth) const {
  if (depth == syllables.size()) {
    return !node->entries.empty();
  }

  const auto& syllable = syllables[depth];

  if (isAbbreviated(syllable)) {
    auto indexIt = node->consonantIndex.find(syllable);
    if (indexIt != node->consonantIndex.end()) {
      for (const auto& childKey : indexIt->second) {
        auto childIt = node->children.find(childKey);
        if (childIt != node->children.end()) {
          if (hasRecursive(childIt->second.get(), syllables, depth + 1)) {
            return true;
          }
        }
      }
    }
    return false;
  } else {
    auto it = node->children.find(syllable);
    if (it == node->children.end()) return false;
    return hasRecursive(it->second.get(), syllables, depth + 1);
  }
}

}  // namespace McBopomofo
