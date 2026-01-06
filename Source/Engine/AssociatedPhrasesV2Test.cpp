// Copyright (c) 2024 and onwards The McBopomofo Authors.
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

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "AssociatedPhrasesV2.h"
#include "gtest/gtest.h"

namespace McBopomofo {

constexpr char kSample[] = R"(
# format org.openvanilla.mcbopomofo.sorted
一-ㄧ-一-ㄧ -4.3849
一-ㄧ-下-ㄒㄧㄚˋ -3.6225
一-ㄧ-九-ㄐㄧㄡˇ-九-ㄐㄧㄡˇ -4.1645
一-ㄧ-九-ㄐㄧㄡˇ-八-ㄅㄚ -4.4382
一-ㄧ-些-ㄒㄧㄝ -3.3862
一-ㄧ-件-ㄐㄧㄢˋ -4.4434
一-ㄧ-份-ㄈㄣˋ -4.5500
一-ㄧ-位-ㄨㄟˋ -4.1953
一-ㄧ-個-ㄍㄜ˙ -2.9779
一-ㄧ-個-ㄍㄜ˙-人-ㄖㄣˊ -4.2035
一-ㄧ-個-ㄍㄜ˙-月-ㄩㄝˋ -4.4501
不-ㄅㄨˋ-只-ㄓˇ -4.2502
不-ㄅㄨˋ-只-ㄓˇ-是-ㄕˋ -4.5019
不-ㄅㄨˋ-可-ㄎㄜˇ -3.6897
文-ㄨㄣˊ-書-ㄕㄨ-處-ㄔㄨˇ-理-ㄌㄧˇ -5.7488
文-ㄨㄣˊ-書-ㄕㄨ-處-ㄔㄨˋ-理-ㄌㄧˇ -5.7488
)";

TEST(AssociatedPhrasesV2Test, IdempotentClose) {
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));

  AssociatedPhrasesV2 phrases;
  EXPECT_TRUE(phrases.open(std::move(db)));
  phrases.close();

  // Safe to do so.
  phrases.close();
}

TEST(AssociatedPhrasesV2Test, UnopenedInstanceReturnsNothing) {
  AssociatedPhrasesV2 phrases;
  EXPECT_TRUE(phrases.findPhrases("", {}).empty());
}

TEST(AssociatedPhrasesV2Test, ReturnsSortedResults) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));

  std::vector<AssociatedPhrasesV2::Phrase> results =
      phrases.findPhrases("一", {});
  EXPECT_EQ(results[0].value, "一個");
  EXPECT_EQ(results[0].readings, (std::vector<std::string>{"ㄧ", "ㄍㄜ˙"}));
}

TEST(AssociatedPhrasesV2Test, ReturnsSortedResultsWithReadings) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));

  std::vector<AssociatedPhrasesV2::Phrase> results =
      phrases.findPhrases("一", {"ㄧ"});
  EXPECT_EQ(results[0].value, "一個");

  results = phrases.findPhrases("一個", {"ㄧ", "ㄍㄜ˙"});
  EXPECT_EQ(results[0].value, "一個人");
}

TEST(AssociatedPhrasesV2Test, ResultsOnlyBeginWithTheSamePrefix) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));

  std::vector<AssociatedPhrasesV2::Phrase> results =
      phrases.findPhrases("一", {"ㄧ"});
  for (const auto& phrase : results) {
    EXPECT_TRUE(phrase.value.find("不-") == std::string::npos);
  }
}

TEST(AssociatedPhrasesV2Test, ReturnsNothingWithEmptyPrefix) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));
  EXPECT_TRUE(phrases.findPhrases("", {}).empty());
}

TEST(AssociatedPhrasesV2Test, ReturnsNothingIfPrefixNotFound) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));
  EXPECT_TRUE(phrases.findPhrases("二", {}).empty());
}

TEST(AssociatedPhrasesV2Test, ReturnsNothingWithMismatchingValueReadingCount) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));
  EXPECT_TRUE(phrases.findPhrases("一個", {"ㄍㄜ˙"}).empty());
  EXPECT_TRUE(phrases.findPhrases("個", {"ㄧ", "ㄍㄜ˙"}).empty());
}

TEST(AssociatedPhrasesV2Test, ReturnsNothingAfterClosing) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));
  EXPECT_FALSE(phrases.findPhrases("一", {}).empty());

  phrases.close();
  EXPECT_TRUE(phrases.findPhrases("一", {}).empty());

  phrases.close();
  EXPECT_TRUE(phrases.findPhrases("一", {}).empty());
}

TEST(AssociatedPhrasesV2Test, CombineReadings) {
  AssociatedPhrasesV2::Phrase p1("", {});
  EXPECT_EQ(p1.combinedReading(), "");

  AssociatedPhrasesV2::Phrase p2("a", {"A"});
  EXPECT_EQ(p2.combinedReading(), "A");

  AssociatedPhrasesV2::Phrase p3("ab", {"A", "B"});
  EXPECT_EQ(p3.combinedReading(), "A-B");
}

TEST(AssociatedPhrasesV2Test, SplitReadings) {
  std::vector<std::string> result = AssociatedPhrasesV2::SplitReadings("");
  EXPECT_TRUE(result.empty());

  result = AssociatedPhrasesV2::SplitReadings("A");
  EXPECT_EQ(result, (std::vector<std::string>{"A"}));
  result = AssociatedPhrasesV2::SplitReadings("A-B");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "B"}));
  result = AssociatedPhrasesV2::SplitReadings("A-B-C");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "B", "C"}));

  // Pathological cases, but should still yield the following results.
  result = AssociatedPhrasesV2::SplitReadings("A-B-");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "B", ""}));
  result = AssociatedPhrasesV2::SplitReadings("A- B -");
  EXPECT_EQ(result, (std::vector<std::string>{"A", " B ", ""}));
  result = AssociatedPhrasesV2::SplitReadings("A -B- ");
  EXPECT_EQ(result, (std::vector<std::string>{"A ", "B", " "}));
  result = AssociatedPhrasesV2::SplitReadings("A-B ");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "B "}));
  result = AssociatedPhrasesV2::SplitReadings("A-B--");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "B", "", ""}));
  result = AssociatedPhrasesV2::SplitReadings("-");
  EXPECT_EQ(result, (std::vector<std::string>{"", ""}));

  // Edge cases: _punctuation_- and similar ones need to be treated carefully.
  result = AssociatedPhrasesV2::SplitReadings("_foo_-");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo_-"}));
  result = AssociatedPhrasesV2::SplitReadings("foo_-");
  EXPECT_EQ(result, (std::vector<std::string>{"foo_-"}));
  result = AssociatedPhrasesV2::SplitReadings("_foo_--_bar_-");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo_-", "_bar_-"}));
  result = AssociatedPhrasesV2::SplitReadings("_foo_-_bar_-");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo_-_bar_-"}));
  result = AssociatedPhrasesV2::SplitReadings("_foo_--");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo_-", ""}));
  result = AssociatedPhrasesV2::SplitReadings("-_foo_-");
  EXPECT_EQ(result, (std::vector<std::string>{"", "_foo_-"}));
  result = AssociatedPhrasesV2::SplitReadings("A-_foo_--B");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "_foo_-", "B"}));
  result = AssociatedPhrasesV2::SplitReadings("A-_foo_---B");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "_foo_-", "", "B"}));
  result = AssociatedPhrasesV2::SplitReadings("-_foo_-");
  EXPECT_EQ(result, (std::vector<std::string>{"", "_foo_-"}));
  result = AssociatedPhrasesV2::SplitReadings("_--_foo_-");
  EXPECT_EQ(result, (std::vector<std::string>{"_-", "_foo_-"}));

  // Edge cases: _punctuation__ needs to be split correctly
  result = AssociatedPhrasesV2::SplitReadings("foo__-");
  EXPECT_EQ(result, (std::vector<std::string>{"foo__", ""}));
  result = AssociatedPhrasesV2::SplitReadings("_foo__-_bar_-");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo__", "_bar_-"}));
  result = AssociatedPhrasesV2::SplitReadings("A-_foo__-B");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "_foo__", "B"}));
  result = AssociatedPhrasesV2::SplitReadings("A-_foo__--B");
  EXPECT_EQ(result, (std::vector<std::string>{"A", "_foo__", "", "B"}));
  result = AssociatedPhrasesV2::SplitReadings("_foo_--_foo__-B");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo_-", "_foo__", "B"}));
  result = AssociatedPhrasesV2::SplitReadings("_foo__-_foo_--B");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo__", "_foo_-", "B"}));
  result = AssociatedPhrasesV2::SplitReadings("__-_foo_-");
  EXPECT_EQ(result, (std::vector<std::string>{"__", "_foo_-"}));
  result = AssociatedPhrasesV2::SplitReadings("__--_foo_-");
  EXPECT_EQ(result, (std::vector<std::string>{"__", "", "_foo_-"}));

  // This is actually malformed, but still good to test.
  result = AssociatedPhrasesV2::SplitReadings("_foo_-_foo_--B");
  EXPECT_EQ(result, (std::vector<std::string>{"_foo_-_foo_-", "B"}));
}

TEST(AssociatedPhrasesV2Test, ReturnsDeduplicatedResults) {
  AssociatedPhrasesV2 phrases;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(phrases.open(std::move(db)));

  std::vector<AssociatedPhrasesV2::Phrase> results =
      phrases.findPhrases("文", {});
  EXPECT_EQ(results.size(), 1);
  EXPECT_EQ(results[0].value, "文書處理");
  EXPECT_EQ(results[0].readings,
            (std::vector<std::string>{"ㄨㄣˊ", "ㄕㄨ", "ㄔㄨˇ", "ㄌㄧˇ"}));
}

}  // namespace McBopomofo
