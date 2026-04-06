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
    std::string targetConsonant = syllable;
    for (const auto& [childKey, childNode] : node->children) {
      if (consonantOf(childKey) == targetConsonant) {
        findRecursive(childNode.get(), syllables, depth + 1, results);
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
    std::string targetConsonant = syllable;
    for (const auto& [childKey, childNode] : node->children) {
      if (consonantOf(childKey) == targetConsonant) {
        if (hasRecursive(childNode.get(), syllables, depth + 1)) {
          return true;
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
