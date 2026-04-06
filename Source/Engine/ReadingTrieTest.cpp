#include <gtest/gtest.h>

#include <set>

#include "ReadingTrie.h"

namespace McBopomofo {

TEST(ReadingTrieTest, EmptyTrieReturnsNoResults) {
  ReadingTrie trie;
  auto results = trie.findAbbreviated("ㄅ");
  EXPECT_TRUE(results.empty());
}

TEST(ReadingTrieTest, ExactMatchSingleSyllable) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);
  trie.insert("ㄅㄚ", "吧", -4.0);

  auto results = trie.findAbbreviated("ㄅ");
  ASSERT_EQ(results.size(), 2);
  EXPECT_EQ(results[0].value(), "八");
  EXPECT_EQ(results[1].value(), "吧");
}

TEST(ReadingTrieTest, AbbreviatedMultiSyllable) {
  ReadingTrie trie;
  trie.insert("ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ", "圖書館", -5.0);
  trie.insert("ㄊㄞˋ-ㄕㄠˇ-ㄍㄜˋ", "太少個", -9.0);

  auto results = trie.findAbbreviated("ㄊ-ㄕ-ㄍ");
  ASSERT_EQ(results.size(), 2);

  std::set<std::string> values;
  for (const auto& u : results) values.insert(u.value());
  EXPECT_TRUE(values.count("圖書館"));
  EXPECT_TRUE(values.count("太少個"));
}

TEST(ReadingTrieTest, MixedAbbreviatedAndFull) {
  ReadingTrie trie;
  trie.insert("ㄊㄨˊ-ㄕㄨ-ㄍㄨㄢˇ", "圖書館", -5.0);
  trie.insert("ㄊㄨˊ-ㄕˋ-ㄍㄨㄢˇ", "土石管", -9.0);

  auto results = trie.findAbbreviated("ㄊㄨˊ-ㄕ-ㄍㄨㄢˇ");
  ASSERT_EQ(results.size(), 2);
}

TEST(ReadingTrieTest, FullKeyReturnsExactMatch) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);
  trie.insert("ㄅㄞˊ", "白", -4.0);

  auto results = trie.findAbbreviated("ㄅㄚ");
  ASSERT_EQ(results.size(), 1);
  EXPECT_EQ(results[0].value(), "八");
}

TEST(ReadingTrieTest, NoMatchReturnsEmpty) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);

  auto results = trie.findAbbreviated("ㄍ");
  EXPECT_TRUE(results.empty());
}

TEST(ReadingTrieTest, HasAbbreviatedUnigrams) {
  ReadingTrie trie;
  trie.insert("ㄅㄚ", "八", -3.0);

  EXPECT_TRUE(trie.hasAbbreviatedUnigrams("ㄅ"));
  EXPECT_TRUE(trie.hasAbbreviatedUnigrams("ㄅㄚ"));
  EXPECT_FALSE(trie.hasAbbreviatedUnigrams("ㄍ"));
}

}  // namespace McBopomofo
