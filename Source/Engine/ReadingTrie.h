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

 private:
  struct Node {
    std::unordered_map<std::string, std::unique_ptr<Node>> children;
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
