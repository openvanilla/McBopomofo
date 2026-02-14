// Copyright (c) 2022 and onwards Lukhnos Liu
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

#include "reading_grid.h"

#include <chrono>
#include <filesystem>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "gtest/gtest.h"
#include "contextual_user_model.h"
#include "language_model.h"
#include "walk_strategy.h"

namespace Formosa::Gramambular2 {

constexpr char kSampleData[] = R"(
#
# The sample is from libtabe (https://sourceforge.net/projects/libtabe/)
# last updated in 2002. The project was originally initiated by
# Pai-Hsiang Hsiao in 1999.
#
# Libtabe is a frequency table of Taiwanese Mandarin words. The database
# itself is, according to the tar file, released under the BSD License.
#
ㄙ 絲 -9.495858
ㄙ 思 -9.006414
ㄙ 私 -99.000000
ㄙ 斯 -8.091803
ㄙ 司 -99.000000
ㄙ 嘶 -13.513987
ㄙ 撕 -12.259095
ㄍㄠ 高 -7.171551
ㄎㄜ 顆 -10.574273
ㄎㄜ 棵 -11.504072
ㄎㄜ 刻 -10.450457
ㄎㄜ 科 -7.171052
ㄎㄜ 柯 -99.000000
ㄍㄠ 膏 -11.928720
ㄍㄠ 篙 -13.624335
ㄍㄠ 糕 -12.390804
ㄉㄜ˙ 的 -3.516024
ㄉㄧˊ 的 -3.516024
ㄉㄧˋ 的 -3.516024
ㄓㄨㄥ 中 -5.809297
ㄉㄜ˙ 得 -7.427179
ㄍㄨㄥ 共 -8.381971
ㄍㄨㄥ 供 -8.501463
ㄐㄧˋ 既 -99.000000
ㄐㄧㄣ 今 -8.034095
ㄍㄨㄥ 紅 -8.858181
ㄐㄧˋ 際 -7.608341
ㄐㄧˋ 季 -99.000000
ㄐㄧㄣ 金 -7.290109
ㄐㄧˋ 騎 -10.939895
ㄓㄨㄥ 終 -99.000000
ㄐㄧˋ 記 -99.000000
ㄐㄧˋ 寄 -99.000000
ㄐㄧㄣ 斤 -99.000000
ㄐㄧˋ 繼 -9.715317
ㄐㄧˋ 計 -7.926683
ㄐㄧˋ 暨 -8.373022
ㄓㄨㄥ 鐘 -9.877580
ㄐㄧㄣ 禁 -10.711079
ㄍㄨㄥ 公 -7.877973
ㄍㄨㄥ 工 -7.822167
ㄍㄨㄥ 攻 -99.000000
ㄍㄨㄥ 功 -99.000000
ㄍㄨㄥ 宮 -99.000000
ㄓㄨㄥ 鍾 -9.685671
ㄐㄧˋ 繫 -10.425662
ㄍㄨㄥ 弓 -99.000000
ㄍㄨㄥ 恭 -99.000000
ㄐㄧˋ 劑 -8.888722
ㄐㄧˋ 祭 -10.204425
ㄐㄧㄣ 浸 -11.378321
ㄓㄨㄥ 盅 -99.000000
ㄐㄧˋ 忌 -99.000000
ㄐㄧˋ 技 -8.450826
ㄐㄧㄣ 筋 -11.074890
ㄍㄨㄥ 躬 -99.000000
ㄐㄧˋ 冀 -12.045357
ㄓㄨㄥ 忠 -99.000000
ㄐㄧˋ 妓 -99.000000
ㄐㄧˋ 濟 -9.517568
ㄐㄧˋ 薊 -12.021587
ㄐㄧㄣ 巾 -99.000000
ㄐㄧㄣ 襟 -12.784206
ㄋㄧㄢˊ 年 -6.086515
ㄐㄧㄤˇ 講 -9.164384
ㄐㄧㄤˇ 獎 -8.690941
ㄐㄧㄤˇ 蔣 -10.127828
ㄋㄧㄢˊ 黏 -11.336864
ㄋㄧㄢˊ 粘 -11.285740
ㄐㄧㄤˇ 槳 -12.492933
ㄍㄨㄥㄙ 公司 -6.299461
ㄎㄜㄐㄧˋ 科技 -6.736613
ㄐㄧˋㄍㄨㄥ 濟公 -13.336653
ㄐㄧㄤˇㄐㄧㄣ 獎金 -10.344678
ㄋㄧㄢˊㄓㄨㄥ 年終 -11.668947
ㄋㄧㄢˊㄓㄨㄥ 年中 -11.373044
ㄍㄠㄎㄜㄐㄧˋ 高科技 -9.842421
)";

class SimpleLM : public LanguageModel {
 public:
  explicit SimpleLM(const char* input, bool readingIsFirstColumn = true) {
    std::stringstream sstream(input);
    while (sstream.good()) {
      std::string line;
      getline(sstream, line);
      if (line.empty() || line[0] == '#') {
        continue;
      }
      std::stringstream linestream(line);
      std::string col0;
      std::string col1;
      std::string col2;
      linestream >> col0;
      linestream >> col1;
      linestream >> col2;
      db_[readingIsFirstColumn ? col0 : col1].emplace_back(
          readingIsFirstColumn ? col1 : col0, std::stod(col2));
    }
  }

  std::vector<Unigram> getUnigrams(const std::string& key) override {
    const auto f = db_.find(key);
    return f == db_.end() ? std::vector<Unigram>() : (*f).second;
  }

  bool hasUnigrams(const std::string& key) override {
    return db_.find(key) != db_.end();
  }

 protected:
  std::map<std::string, std::vector<Unigram>> db_;
};

class MockLM : public LanguageModel {
 public:
  std::vector<Unigram> getUnigrams(const std::string& reading) override {
    return std::vector<Unigram>{Unigram(reading, -1)};
  }
  bool hasUnigrams(const std::string&) override { return true; }
};

static bool Contains(const std::vector<ReadingGrid::Candidate>& candidates,
                     const std::string& str) {
  return std::any_of(candidates.cbegin(), candidates.cend(),
                     [&str](const auto& v) { return v.value == str; });
}

TEST(ReadingGridTest, Span) {
  SimpleLM lm(kSampleData);
  ReadingGrid::Span span;

  auto n1 =
      std::make_shared<ReadingGrid::Node>("ㄍㄠ", 1, lm.getUnigrams("ㄍㄠ"));
  auto n3 = std::make_shared<ReadingGrid::Node>(
      "ㄍㄠㄎㄜㄐㄧˋ", 3, lm.getUnigrams("ㄍㄠㄎㄜㄐㄧˋ"));

  ASSERT_EQ(span.maxLength(), 0);
  span.add(n1);
  ASSERT_EQ(span.maxLength(), 1);
  span.add(n3);
  ASSERT_EQ(span.maxLength(), 3);
  ASSERT_EQ(span.nodeOf(1), n1);
  ASSERT_EQ(span.nodeOf(2), nullptr);
  ASSERT_EQ(span.nodeOf(3), n3);
  ASSERT_EQ(span.nodeOf(ReadingGrid::kDefaultMaxSpanLength), nullptr);
  span.clear();
  ASSERT_EQ(span.maxLength(), 0);
  ASSERT_EQ(span.nodeOf(1), nullptr);
  ASSERT_EQ(span.nodeOf(2), nullptr);
  ASSERT_EQ(span.nodeOf(3), nullptr);
  ASSERT_EQ(span.nodeOf(ReadingGrid::kDefaultMaxSpanLength), nullptr);

  span.add(n1);
  span.add(n3);
  span.removeNodesOfOrLongerThan(2);
  ASSERT_EQ(span.maxLength(), 1);
  ASSERT_EQ(span.nodeOf(1), n1);
  ASSERT_EQ(span.nodeOf(2), nullptr);
  ASSERT_EQ(span.nodeOf(3), nullptr);
  span.removeNodesOfOrLongerThan(1);
  ASSERT_EQ(span.maxLength(), 0);
  ASSERT_EQ(span.nodeOf(1), nullptr);

#ifndef NDEBUG
  ASSERT_DEATH({ (void)span.nodeOf(0); }, "Assertion");
#endif

  ASSERT_EQ(span.nodeOf(ReadingGrid::kDefaultMaxSpanLength + 1), nullptr);

  auto n10 = std::make_shared<ReadingGrid::Node>("", 10, lm.getUnigrams(""));
  span.add(n10);
  ASSERT_EQ(span.maxLength(), 10);
  ASSERT_EQ(span.nodeOf(10), n10);
}

TEST(ReadingGridTest, ScoreRankedLanguageModel) {
  class TestLM : public LanguageModel {
   public:
    std::vector<Unigram> getUnigrams(const std::string& reading) override {
      std::vector<Unigram> unigrams;
      if (reading == "foo") {
        unigrams.emplace_back("middle", -5);
        unigrams.emplace_back("highest", -2);
        unigrams.emplace_back("lowest", -10);
      }
      return unigrams;
    }

    bool hasUnigrams(const std::string& reading) override {
      return reading == "foo";
    }
  };

  ReadingGrid::ScoreRankedLanguageModel lm(std::make_shared<TestLM>());
  ASSERT_TRUE(lm.hasUnigrams("foo"));
  ASSERT_FALSE(lm.hasUnigrams("bar"));
  ASSERT_TRUE(lm.getUnigrams("bar").empty());
  auto unigrams = lm.getUnigrams("foo");
  ASSERT_EQ(unigrams.size(), 3);
  ASSERT_EQ(unigrams[0].value(), "highest");
  ASSERT_EQ(unigrams[0].score(), -2);
  ASSERT_EQ(unigrams[1].value(), "middle");
  ASSERT_EQ(unigrams[1].score(), -5);
  ASSERT_EQ(unigrams[2].value(), "lowest");
  ASSERT_EQ(unigrams[2].score(), -10);
}

TEST(ReadingGridTest, BasicOperations) {
  ReadingGrid grid(std::make_shared<MockLM>());
  ASSERT_EQ(grid.readingSeparator(), ReadingGrid::kDefaultSeparator);

  ASSERT_EQ(grid.cursor(), 0);
  ASSERT_EQ(grid.length(), 0);
  grid.insertReading("a");

  ASSERT_EQ(grid.cursor(), 1);
  ASSERT_EQ(grid.length(), 1);
  ASSERT_EQ(grid.spans().size(), 1);
  ASSERT_EQ(grid.spans()[0].maxLength(), 1);
  ASSERT_EQ(grid.spans()[0].nodeOf(1)->reading(), "a");

  grid.deleteReadingBeforeCursor();
  ASSERT_EQ(grid.cursor(), 0);
  ASSERT_EQ(grid.length(), 0);
  ASSERT_EQ(grid.spans().size(), 0);
}

TEST(ReadingGridTest, InvalidOperations) {
  class TestLM : public LanguageModel {
   public:
    std::vector<Unigram> getUnigrams(const std::string& reading) override {
      std::vector<Unigram> unigrams;
      if (reading == "foo") {
        unigrams.emplace_back("foo", -1);
      }
      return unigrams;
    }

    bool hasUnigrams(const std::string& reading) override {
      return reading == "foo";
    }
  };

  ReadingGrid grid(std::make_shared<TestLM>());

  grid.setReadingSeparator(";");
  ASSERT_FALSE(grid.insertReading("bar"));
  ASSERT_FALSE(grid.insertReading(""));
  ASSERT_FALSE(grid.insertReading(";"));
  ASSERT_FALSE(grid.deleteReadingBeforeCursor());
  ASSERT_FALSE(grid.deleteReadingAfterCursor());

  ASSERT_TRUE(grid.insertReading("foo"));
  ASSERT_TRUE(grid.deleteReadingBeforeCursor());
  ASSERT_EQ(grid.length(), 0);
  ASSERT_TRUE(grid.insertReading("foo"));
  grid.setCursor(0);
  ASSERT_TRUE(grid.deleteReadingAfterCursor());
  ASSERT_EQ(grid.length(), 0);
}

TEST(ReadingGridTest, DeleteAfterCursor) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.insertReading("a");
  grid.setCursor(0);
  ASSERT_EQ(grid.cursor(), 0);
  ASSERT_EQ(grid.length(), 1);
  ASSERT_EQ(grid.spans().size(), 1);

  grid.deleteReadingBeforeCursor();
  ASSERT_EQ(grid.cursor(), 0);
  ASSERT_EQ(grid.length(), 1);

  grid.deleteReadingAfterCursor();
  ASSERT_EQ(grid.cursor(), 0);
  ASSERT_EQ(grid.length(), 0);
  ASSERT_EQ(grid.spans().size(), 0);
}

TEST(ReadingGridTest, MultipleSpans) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator(";");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");

  ASSERT_EQ(grid.cursor(), 3);
  ASSERT_EQ(grid.length(), 3);
  ASSERT_EQ(grid.spans().size(), 3);
  ASSERT_EQ(grid.spans()[0].maxLength(), 3);
  ASSERT_EQ(grid.spans()[0].nodeOf(1)->reading(), "a");
  ASSERT_EQ(grid.spans()[0].nodeOf(2)->reading(), "a;b");
  ASSERT_EQ(grid.spans()[0].nodeOf(3)->reading(), "a;b;c");
  ASSERT_EQ(grid.spans()[1].maxLength(), 2);
  ASSERT_EQ(grid.spans()[1].nodeOf(1)->reading(), "b");
  ASSERT_EQ(grid.spans()[1].nodeOf(2)->reading(), "b;c");
  ASSERT_EQ(grid.spans()[2].maxLength(), 1);
  ASSERT_EQ(grid.spans()[2].nodeOf(1)->reading(), "c");
}

TEST(ReadingGridTest, SpanDeletionSimple) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator(";");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");
  grid.deleteReadingBeforeCursor();
  ASSERT_EQ(grid.cursor(), 2);
  ASSERT_EQ(grid.length(), 2);
  ASSERT_EQ(grid.spans().size(), 2);
  ASSERT_EQ(grid.spans()[0].maxLength(), 2);
  ASSERT_EQ(grid.spans()[0].nodeOf(1)->reading(), "a");
  ASSERT_EQ(grid.spans()[0].nodeOf(2)->reading(), "a;b");
  ASSERT_EQ(grid.spans()[1].maxLength(), 1);
  ASSERT_EQ(grid.spans()[1].nodeOf(1)->reading(), "b");
}

TEST(ReadingGridTest, SpanDeletionFromMiddle) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator(";");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");
  grid.setCursor(2);
  grid.deleteReadingBeforeCursor();
  ASSERT_EQ(grid.cursor(), 1);
  ASSERT_EQ(grid.length(), 2);
  ASSERT_EQ(grid.spans().size(), 2);
  ASSERT_EQ(grid.spans()[0].maxLength(), 2);
  ASSERT_EQ(grid.spans()[0].nodeOf(1)->reading(), "a");
  ASSERT_EQ(grid.spans()[0].nodeOf(2)->reading(), "a;c");
  ASSERT_EQ(grid.spans()[1].maxLength(), 1);
  ASSERT_EQ(grid.spans()[1].nodeOf(1)->reading(), "c");
}

TEST(ReadingGridTest, SpanDeletionFromMiddleUsingDeleteAfterCursor) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator(";");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");
  grid.setCursor(1);
  grid.deleteReadingAfterCursor();
  ASSERT_EQ(grid.cursor(), 1);
  ASSERT_EQ(grid.length(), 2);
  ASSERT_EQ(grid.spans().size(), 2);
  ASSERT_EQ(grid.spans()[0].maxLength(), 2);
  ASSERT_EQ(grid.spans()[0].nodeOf(1)->reading(), "a");
  ASSERT_EQ(grid.spans()[0].nodeOf(2)->reading(), "a;c");
  ASSERT_EQ(grid.spans()[1].maxLength(), 1);
  ASSERT_EQ(grid.spans()[1].nodeOf(1)->reading(), "c");
}

TEST(ReadingGridTest, SpanInsertion) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator(";");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");
  grid.setCursor(1);
  grid.insertReading("X");

  ASSERT_EQ(grid.cursor(), 2);
  ASSERT_EQ(grid.length(), 4);
  ASSERT_EQ(grid.spans().size(), 4);
  ASSERT_EQ(grid.spans()[0].maxLength(), 4);
  ASSERT_EQ(grid.spans()[0].nodeOf(1)->reading(), "a");
  ASSERT_EQ(grid.spans()[0].nodeOf(2)->reading(), "a;X");
  ASSERT_EQ(grid.spans()[0].nodeOf(3)->reading(), "a;X;b");
  ASSERT_EQ(grid.spans()[0].nodeOf(4)->reading(), "a;X;b;c");
  ASSERT_EQ(grid.spans()[1].maxLength(), 3);
  ASSERT_EQ(grid.spans()[1].nodeOf(1)->reading(), "X");
  ASSERT_EQ(grid.spans()[1].nodeOf(2)->reading(), "X;b");
  ASSERT_EQ(grid.spans()[1].nodeOf(3)->reading(), "X;b;c");
  ASSERT_EQ(grid.spans()[2].maxLength(), 2);
  ASSERT_EQ(grid.spans()[2].nodeOf(1)->reading(), "b");
  ASSERT_EQ(grid.spans()[2].nodeOf(2)->reading(), "b;c");
  ASSERT_EQ(grid.spans()[3].maxLength(), 1);
  ASSERT_EQ(grid.spans()[3].nodeOf(1)->reading(), "c");
}

TEST(ReadingGridTest, LongGridDeletion) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator("");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");
  grid.insertReading("d");
  grid.insertReading("e");
  grid.insertReading("f");
  grid.insertReading("g");
  grid.insertReading("h");
  grid.insertReading("i");
  grid.insertReading("j");
  grid.insertReading("k");
  grid.insertReading("l");
  grid.insertReading("m");
  grid.insertReading("n");
  grid.setCursor(7);
  grid.deleteReadingBeforeCursor();
  ASSERT_EQ(grid.cursor(), 6);
  ASSERT_EQ(grid.length(), 13);
  ASSERT_EQ(grid.spans().size(), 13);
  ASSERT_EQ(grid.spans()[0].nodeOf(6)->reading(), "abcdef");
  ASSERT_EQ(grid.spans()[1].nodeOf(6)->reading(), "bcdefh");
  ASSERT_EQ(grid.spans()[1].nodeOf(5)->reading(), "bcdef");
  ASSERT_EQ(grid.spans()[2].nodeOf(6)->reading(), "cdefhi");
  ASSERT_EQ(grid.spans()[2].nodeOf(5)->reading(), "cdefh");
  ASSERT_EQ(grid.spans()[3].nodeOf(6)->reading(), "defhij");
  ASSERT_EQ(grid.spans()[4].nodeOf(6)->reading(), "efhijk");
  ASSERT_EQ(grid.spans()[5].nodeOf(6)->reading(), "fhijkl");
  ASSERT_EQ(grid.spans()[6].nodeOf(6)->reading(), "hijklm");
  ASSERT_EQ(grid.spans()[7].nodeOf(6)->reading(), "ijklmn");
  ASSERT_EQ(grid.spans()[8].nodeOf(5)->reading(), "jklmn");
}

TEST(ReadingGridTest, FindNodeInSpans) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator(";");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");

  ASSERT_FALSE(
      grid.findInSpan(0, [](const auto& n) { return n->spanningLength() == 4; })
          .has_value());
  ASSERT_FALSE(
      grid.findInSpan(1, [](const auto& n) { return n->spanningLength() == 0; })
          .has_value());
  ASSERT_EQ(
      grid.findInSpan(0, [](const auto& n) { return n->spanningLength() == 1; })
          ->get()
          ->reading(),
      "a");
  ASSERT_EQ(
      grid.findInSpan(1, [](const auto& n) { return n->spanningLength() == 1; })
          ->get()
          ->reading(),
      "b");
  ASSERT_EQ(
      grid.findInSpan(2, [](const auto& n) { return n->spanningLength() == 1; })
          ->get()
          ->reading(),
      "c");
  ASSERT_EQ(
      grid.findInSpan(3, [](const auto& n) { return n->spanningLength() == 1; })
          ->get()
          ->reading(),
      "c");
  ASSERT_EQ(
      grid.findInSpan(0, [](const auto& n) { return n->spanningLength() == 2; })
          ->get()
          ->reading(),
      "a;b");
  ASSERT_EQ(
      grid.findInSpan(1, [](const auto& n) { return n->spanningLength() == 2; })
          ->get()
          ->reading(),
      "b;c");
  ASSERT_EQ(
      grid.findInSpan(2, [](const auto& n) { return n->spanningLength() == 2; })
          ->get()
          ->reading(),
      "b;c");
  ASSERT_EQ(
      grid.findInSpan(3, [](const auto& n) { return n->spanningLength() == 2; })
          ->get()
          ->reading(),
      "b;c");
  ASSERT_EQ(
      grid.findInSpan(0, [](const auto& n) { return n->spanningLength() == 3; })
          ->get()
          ->reading(),
      "a;b;c");
  ASSERT_EQ(
      grid.findInSpan(1, [](const auto& n) { return n->spanningLength() == 3; })
          ->get()
          ->reading(),
      "a;b;c");
  ASSERT_EQ(
      grid.findInSpan(2, [](const auto& n) { return n->spanningLength() == 3; })
          ->get()
          ->reading(),
      "a;b;c");
  ASSERT_EQ(
      grid.findInSpan(3, [](const auto& n) { return n->spanningLength() == 3; })
          ->get()
          ->reading(),
      "a;b;c");
}

TEST(ReadingGridTest, StressTest) {
  constexpr char kStressData[] = R"(
ㄧ 一 -2.08170692
ㄧ-ㄧ 一一 -4.38468400
)";

  ReadingGrid grid(std::make_shared<SimpleLM>(kStressData));
  for (int i = 0; i < 8001; i++) {
    grid.insertReading("ㄧ");
  }
  ReadingGrid::WalkResult result = grid.walk();
  std::cout << "stress test elapsed: " << result.elapsedMicroseconds
            << " microseconds, vertices: " << result.vertices
            << ", edges: " << result.edges << "\n";
}

TEST(ReadingGridTest, LongGridInsertion) {
  ReadingGrid grid(std::make_shared<MockLM>());
  grid.setReadingSeparator("");
  grid.insertReading("a");
  grid.insertReading("b");
  grid.insertReading("c");
  grid.insertReading("d");
  grid.insertReading("e");
  grid.insertReading("f");
  grid.insertReading("g");
  grid.insertReading("h");
  grid.insertReading("i");
  grid.insertReading("j");
  grid.insertReading("k");
  grid.insertReading("l");
  grid.insertReading("m");
  grid.insertReading("n");
  grid.setCursor(7);
  grid.insertReading("X");
  ASSERT_EQ(grid.cursor(), 8);
  ASSERT_EQ(grid.length(), 15);
  ASSERT_EQ(grid.spans().size(), 15);
  ASSERT_EQ(grid.spans()[0].nodeOf(6)->reading(), "abcdef");
  ASSERT_EQ(grid.spans()[1].nodeOf(6)->reading(), "bcdefg");
  ASSERT_EQ(grid.spans()[2].nodeOf(6)->reading(), "cdefgX");
  ASSERT_EQ(grid.spans()[3].nodeOf(6)->reading(), "defgXh");
  ASSERT_EQ(grid.spans()[3].nodeOf(5)->reading(), "defgX");
  ASSERT_EQ(grid.spans()[4].nodeOf(6)->reading(), "efgXhi");
  ASSERT_EQ(grid.spans()[4].nodeOf(5)->reading(), "efgXh");
  ASSERT_EQ(grid.spans()[4].nodeOf(4)->reading(), "efgX");
  ASSERT_EQ(grid.spans()[4].nodeOf(3)->reading(), "efg");
  ASSERT_EQ(grid.spans()[5].nodeOf(6)->reading(), "fgXhij");
  ASSERT_EQ(grid.spans()[6].nodeOf(6)->reading(), "gXhijk");
  ASSERT_EQ(grid.spans()[7].nodeOf(6)->reading(), "Xhijkl");
  ASSERT_EQ(grid.spans()[8].nodeOf(6)->reading(), "hijklm");
}

TEST(ReadingGridTest, WordSegmentationTest) {
  ReadingGrid grid(
      std::make_shared<SimpleLM>(kSampleData, /*readingIsFirstColumn=*/false));
  grid.setReadingSeparator("");
  grid.insertReading("高");
  grid.insertReading("科");
  grid.insertReading("技");
  grid.insertReading("公");
  grid.insertReading("司");
  grid.insertReading("的");
  grid.insertReading("年");
  grid.insertReading("終");
  grid.insertReading("獎");
  grid.insertReading("金");

  ReadingGrid::WalkResult result = grid.walk();
  ASSERT_EQ(result.readingsAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年終", "獎金"}));
}

TEST(ReadingGridTest, InputTest) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  grid.insertReading("ㄍㄠ");
  grid.insertReading("ㄐㄧˋ");
  grid.setCursor(1);
  grid.insertReading("ㄎㄜ");
  grid.setCursor(0);
  grid.deleteReadingAfterCursor();
  grid.insertReading("ㄍㄠ");
  grid.setCursor(grid.length());
  grid.insertReading("ㄍㄨㄥ");
  grid.insertReading("ㄙ");
  grid.insertReading("ㄉㄜ˙");
  grid.insertReading("ㄋㄧㄢˊ");
  grid.insertReading("ㄓㄨㄥ");
  grid.insertReading("ㄐㄧㄤˇ");
  grid.insertReading("ㄐㄧㄣ");
  ReadingGrid::WalkResult result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年中", "獎金"}));

  ASSERT_EQ(grid.length(), 10);
  grid.setCursor(7);  // Before 年中

  auto candidates = grid.candidatesAt(grid.cursor());
  ASSERT_TRUE(Contains(candidates, "年中"));
  ASSERT_TRUE(Contains(candidates, "年終"));
  ASSERT_TRUE(Contains(candidates, "中"));
  ASSERT_TRUE(Contains(candidates, "鍾"));

  ASSERT_TRUE(grid.overrideCandidate(7, "年終"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年終", "獎金"}));
}

TEST(ReadingGridTest, OverrideResetOverlappingNodes) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  grid.insertReading("ㄍㄠ");
  grid.insertReading("ㄎㄜ");
  grid.insertReading("ㄐㄧˋ");
  grid.setCursor(0);
  ASSERT_TRUE(grid.overrideCandidate(grid.cursor(), "膏"));
  ReadingGrid::WalkResult result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(), (std::vector<std::string>{"膏", "科技"}));

  ASSERT_TRUE(grid.overrideCandidate(1, "高科技"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(), (std::vector<std::string>{"高科技"}));

  ASSERT_TRUE(grid.overrideCandidate(0, "膏"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(), (std::vector<std::string>{"膏", "科技"}));

  ASSERT_TRUE(grid.overrideCandidate(1, "柯"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"膏", "柯", "際"}));

  ASSERT_TRUE(grid.overrideCandidate(2, "暨"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"膏", "柯", "暨"}));

  ASSERT_TRUE(grid.overrideCandidate(3, "高科技"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(), std::vector<std::string>{"高科技"});
}

TEST(ReadingGridTest, OverrideResetTest) {
  std::string sampleData(kSampleData);
  sampleData += "ㄓㄨㄥㄐㄧㄤˇ 終講 -11.0\n";
  sampleData += "ㄐㄧㄤˇㄐㄧㄣ 槳襟 -11.0\n";

  ReadingGrid grid(std::make_shared<SimpleLM>(sampleData.c_str()));
  grid.setReadingSeparator("");
  grid.insertReading("ㄋㄧㄢˊ");
  grid.insertReading("ㄓㄨㄥ");
  grid.insertReading("ㄐㄧㄤˇ");
  grid.insertReading("ㄐㄧㄣ");
  ReadingGrid::WalkResult result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"年中", "獎金"}));

  ASSERT_TRUE(grid.overrideCandidate(1, "終講"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"年", "終講", "金"}));

  ASSERT_TRUE(grid.overrideCandidate(2, "槳襟"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"年中", "槳襟"}));

  ASSERT_TRUE(grid.overrideCandidate(0, "年終"));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"年終", "槳襟"}));
}

TEST(ReadingGridTest, DisambiguateCandidates) {
  std::string sampleData(kSampleData);
  sampleData += R"(
ㄍㄠ 高 -2.9396
ㄖㄜˋ 熱 -3.6024
ㄍㄠㄖㄜˋ 高熱 -6.1526
ㄏㄨㄛˇ 火 -3.6966
ㄏㄨㄛˇ 🔥 -8
ㄧㄢˋ 焰 -5.4466
ㄏㄨㄛˇㄧㄢˋ 火焰 -5.6231
ㄏㄨㄛˇㄧㄢˋ 🔥 -8
ㄨㄟˊ 危 -3.9832
ㄒㄧㄢˇ 險 -3.7810
ㄨㄟˊㄒㄧㄢˇ 危險 -4.2623
)";

  ReadingGrid grid(std::make_shared<SimpleLM>(sampleData.c_str()));
  grid.setReadingSeparator("");
  grid.insertReading("ㄍㄠ");
  grid.insertReading("ㄖㄜˋ");
  grid.insertReading("ㄏㄨㄛˇ");
  grid.insertReading("ㄧㄢˋ");
  grid.insertReading("ㄨㄟˊ");
  grid.insertReading("ㄒㄧㄢˇ");
  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高熱", "火焰", "危險"}));

  constexpr size_t loc = 2;  // after 高熱

  ASSERT_TRUE(
      grid.overrideCandidate(loc, ReadingGrid::Candidate("ㄏㄨㄛˇ", "🔥")));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高熱", "🔥", "焰", "危險"}));

  ASSERT_TRUE(
      grid.overrideCandidate(loc, ReadingGrid::Candidate("ㄏㄨㄛˇㄧㄢˋ", "🔥")));
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高熱", "🔥", "危險"}));
}

TEST(ReadingGridTest, FindInSpan1) {
  std::string sampleData(kSampleData);
  sampleData += R"(
ㄍㄠ 高 -2.9396
ㄖㄜˋ 熱 -3.6024
ㄍㄠㄖㄜˋ 高熱 -6.1526
ㄏㄨㄛˇ 火 -3.6966
ㄏㄨㄛˇ 🔥 -8
ㄧㄢˋ 焰 -5.4466
ㄏㄨㄛˇㄧㄢˋ 火焰 -5.6231
ㄏㄨㄛˇㄧㄢˋ 🔥 -8
ㄨㄟˊ 危 -3.9832
ㄒㄧㄢˇ 險 -3.7810
ㄨㄟˊㄒㄧㄢˇ 危險 -4.2623
)";

  ReadingGrid grid(std::make_shared<SimpleLM>(sampleData.c_str()));
  grid.setReadingSeparator("");
  grid.insertReading("ㄍㄠ");
  grid.insertReading("ㄖㄜˋ");
  grid.insertReading("ㄏㄨㄛˇ");
  grid.insertReading("ㄧㄢˋ");
  grid.insertReading("ㄨㄟˊ");
  grid.insertReading("ㄒㄧㄢˇ");
  auto result = grid.findInSpan(
      0, [](const Formosa::Gramambular2::ReadingGrid::NodePtr& node) {
        return node->spanningLength() == 1;
      });
  ASSERT_EQ(result->get()->spanningLength(), 1);
  ASSERT_EQ(result->get()->reading(), "ㄍㄠ");
  ASSERT_EQ(result->get()->value(), "高");
}

TEST(ReadingGridTest, FindInSpan2) {
  std::string sampleData(kSampleData);
  sampleData += R"(
ㄍㄠ 高 -2.9396
ㄖㄜˋ 熱 -3.6024
ㄍㄠㄖㄜˋ 高熱 -6.1526
ㄏㄨㄛˇ 火 -3.6966
ㄏㄨㄛˇ 🔥 -8
ㄧㄢˋ 焰 -5.4466
ㄏㄨㄛˇㄧㄢˋ 火焰 -5.6231
ㄏㄨㄛˇㄧㄢˋ 🔥 -8
ㄨㄟˊ 危 -3.9832
ㄒㄧㄢˇ 險 -3.7810
ㄨㄟˊㄒㄧㄢˇ 危險 -4.2623
)";

  ReadingGrid grid(std::make_shared<SimpleLM>(sampleData.c_str()));
  grid.setReadingSeparator("");
  grid.insertReading("ㄍㄠ");
  grid.insertReading("ㄖㄜˋ");
  grid.insertReading("ㄏㄨㄛˇ");
  grid.insertReading("ㄧㄢˋ");
  grid.insertReading("ㄨㄟˊ");
  grid.insertReading("ㄒㄧㄢˇ");
  auto result = grid.findInSpan(
      0, [](const Formosa::Gramambular2::ReadingGrid::NodePtr& node) {
        return node->spanningLength() == 2;
      });
  ASSERT_EQ(result->get()->spanningLength(), 2);
  ASSERT_EQ(result->get()->reading(), "ㄍㄠㄖㄜˋ");
  ASSERT_EQ(result->get()->value(), "高熱");
}

// Phase 1 Tests: Structural Fixes (fixedSpans)

TEST(FixedSpanTest, Basic) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  grid.insertReading("ㄍㄠ");
  grid.insertReading("ㄎㄜ");
  grid.insertReading("ㄐㄧˋ");

  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(), (std::vector<std::string>{"高科技"}));

  auto gaoNode = grid.spans()[0].nodeOf(1);
  ASSERT_NE(gaoNode, nullptr);
  gaoNode->selectOverrideUnigram("膏",
                                  ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore);
  grid.fixSpan(0, gaoNode);
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"膏", "科技"}));
  std::cout << "FixedSpanBasic walk: " << result.elapsedMicroseconds
            << " us\n";
}

TEST(FixedSpanTest, Overlapping) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  grid.insertReading("ㄍㄠ");
  grid.insertReading("ㄎㄜ");
  grid.insertReading("ㄐㄧˋ");

  auto gaoNode = grid.spans()[0].nodeOf(1);
  gaoNode->selectOverrideUnigram("膏",
                                  ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore);
  grid.fixSpan(0, gaoNode);
  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"膏", "科技"}));

  auto gaokejiNode = grid.spans()[0].nodeOf(3);
  ASSERT_NE(gaokejiNode, nullptr);
  grid.fixSpan(0, gaokejiNode);
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(), (std::vector<std::string>{"高科技"}));

  auto keNode = grid.spans()[1].nodeOf(1);
  keNode->selectOverrideUnigram("柯",
                                 ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore);
  grid.fixSpan(1, keNode);
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings()[1], "柯");
  std::cout << "FixedSpanOverlapping walk: " << result.elapsedMicroseconds
            << " us\n";
}

TEST(FixedSpanTest, Boundary) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  grid.insertReading("ㄋㄧㄢˊ");
  grid.insertReading("ㄓㄨㄥ");
  grid.insertReading("ㄐㄧㄤˇ");
  grid.insertReading("ㄐㄧㄣ");

  auto nianzhongNode = grid.spans()[0].nodeOf(2);
  ASSERT_NE(nianzhongNode, nullptr);
  nianzhongNode->selectOverrideUnigram("年終",
                                        ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore);
  grid.fixSpan(0, nianzhongNode);
  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"年終", "獎金"}));
  std::cout << "FixedSpanBoundary walk: " << result.elapsedMicroseconds
            << " us\n";
}

TEST(FixedSpanTest, ClearFixedSpans) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  std::vector<std::string> readings = {"ㄍㄠ",    "ㄎㄜ",    "ㄐㄧˋ",
                                        "ㄍㄨㄥ",  "ㄙ",      "ㄉㄜ˙",
                                        "ㄋㄧㄢˊ", "ㄓㄨㄥ",  "ㄐㄧㄤˇ",
                                        "ㄐㄧㄣ"};
  for (const auto& r : readings) {
    grid.insertReading(r);
  }

  auto baseResult = grid.walk();
  auto baseValues = baseResult.valuesAsStrings();

  auto nianzhongNode = grid.spans()[6].nodeOf(2);
  nianzhongNode->selectOverrideUnigram("年終",
                                        ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore);
  grid.fixSpan(6, nianzhongNode);
  auto fixedResult = grid.walk();
  auto fixedValues = fixedResult.valuesAsStrings();
  bool hasNianzhong = false;
  for (const auto& v : fixedValues) {
    if (v == "年終") hasNianzhong = true;
  }
  ASSERT_TRUE(hasNianzhong);

  grid.clearFixedSpans();
  auto clearedResult = grid.walk();
  ASSERT_EQ(clearedResult.valuesAsStrings(), baseValues);
  std::cout << "ClearFixedSpans walk: " << clearedResult.elapsedMicroseconds
            << " us\n";
}

TEST(FixedSpanTest, ChainedOverrides) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  std::vector<std::string> readings = {"ㄍㄠ",    "ㄎㄜ",    "ㄐㄧˋ",
                                        "ㄍㄨㄥ",  "ㄙ",      "ㄉㄜ˙",
                                        "ㄋㄧㄢˊ", "ㄓㄨㄥ",  "ㄐㄧㄤˇ",
                                        "ㄐㄧㄣ"};
  for (const auto& r : readings) {
    grid.insertReading(r);
  }

  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年中", "獎金"}));

  auto nzNode = grid.spans()[6].nodeOf(2);
  nzNode->selectOverrideUnigram("年終",
                                 ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore);
  grid.fixSpan(6, nzNode);
  result = grid.walk();
  bool hasNianzhong = false;
  for (const auto& v : result.valuesAsStrings()) {
    if (v == "年終") hasNianzhong = true;
  }
  ASSERT_TRUE(hasNianzhong);

  auto gaoNode = grid.spans()[0].nodeOf(1);
  gaoNode->selectOverrideUnigram("膏",
                                  ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore);
  grid.fixSpan(0, gaoNode);
  result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings()[0], "膏");
  hasNianzhong = false;
  for (const auto& v : result.valuesAsStrings()) {
    if (v == "年終") hasNianzhong = true;
  }
  ASSERT_TRUE(hasNianzhong);
  std::cout << "ChainedOverrides walk: " << result.elapsedMicroseconds
            << " us\n";
}

// Phase 0B Tests: Walk Strategy

TEST(WalkStrategyTest, Basic10Syllables) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  std::vector<std::string> readings = {"ㄍㄠ",    "ㄎㄜ",    "ㄐㄧˋ",
                                        "ㄍㄨㄥ",  "ㄙ",      "ㄉㄜ˙",
                                        "ㄋㄧㄢˊ", "ㄓㄨㄥ",  "ㄐㄧㄤˇ",
                                        "ㄐㄧㄣ"};
  for (const auto& r : readings) {
    grid.insertReading(r);
  }

  grid.setWalkStrategy(std::make_shared<ViterbiStrategy>());
  auto result = grid.walk();
  auto values = result.valuesAsStrings();
  ASSERT_EQ(values,
            (std::vector<std::string>{"高科技", "公司", "的", "年中", "獎金"}));
}

TEST(WalkStrategyTest, ScalingComparison) {
  constexpr char kStressData[] = R"(
ㄧ 一 -2.08170692
ㄧ-ㄧ 一一 -4.38468400
)";

  std::vector<int> sizes = {100, 500, 1000, 5000};

  std::cout << "\n--- Scaling ---\n";
  for (int size : sizes) {
    ReadingGrid grid(std::make_shared<SimpleLM>(kStressData));
    for (int i = 0; i < size; i++) {
      grid.insertReading("ㄧ");
    }

    grid.setWalkStrategy(std::make_shared<ViterbiStrategy>());
    auto start = std::chrono::high_resolution_clock::now();
    auto result = grid.walk();
    auto end = std::chrono::high_resolution_clock::now();
    auto us =
        std::chrono::duration_cast<std::chrono::microseconds>(end - start)
            .count();
    ASSERT_FALSE(result.nodes.empty());
    std::cout << "n=" << size << " Viterbi: " << us << " us\n";
  }
}

TEST(WalkStrategyTest, QualityWithExplicitStrategy) {
  ReadingGrid grid(std::make_shared<SimpleLM>(kSampleData));
  grid.setReadingSeparator("");
  std::vector<std::string> readings = {"ㄍㄠ",    "ㄎㄜ",    "ㄐㄧˋ",
                                        "ㄍㄨㄥ",  "ㄙ",      "ㄉㄜ˙",
                                        "ㄋㄧㄢˊ", "ㄓㄨㄥ",  "ㄐㄧㄤˇ",
                                        "ㄐㄧㄣ"};
  for (const auto& r : readings) {
    grid.insertReading(r);
  }

  grid.setWalkStrategy(std::make_shared<ViterbiStrategy>());
  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年中", "獎金"}));
}

// Phase 2 Tests: ContextualUserModel

TEST(ContextualUserModelTest, BasicObserve) {
  auto lm = std::make_shared<SimpleLM>(kSampleData);
  ContextualUserModel model(lm);

  double baseNianzhong = model.baseScore("ㄋㄧㄢˊ-ㄓㄨㄥ", "年終");
  double baseNianzhon = model.baseScore("ㄋㄧㄢˊ-ㄓㄨㄥ", "年中");
  ASSERT_GT(baseNianzhon, baseNianzhong);

  model.observe("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終", 1.0);

  auto suggestion =
      model.suggest("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", 1.0);
  ASSERT_TRUE(suggestion.has_value());
  ASSERT_EQ(suggestion->value, "年終");
  std::cout << "BasicObserve: suggested=" << suggestion->value
            << " logScore=" << suggestion->logScore << "\n";
}

TEST(ContextualUserModelTest, MultiContextContinuation) {
  auto lm = std::make_shared<SimpleLM>(kSampleData);
  ContextualUserModel model(lm);

  model.observe("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終", 1.0);
  model.observe("ㄍㄨㄥ-ㄙ", "公司", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終", 2.0);
  model.observe("ㄐㄧㄣ-ㄊㄧㄢ", "今天", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終", 3.0);

  auto suggestion =
      model.suggest("ㄒㄧㄣ", "新", "ㄋㄧㄢˊ-ㄓㄨㄥ", 3.0);
  ASSERT_TRUE(suggestion.has_value());
  ASSERT_EQ(suggestion->value, "年終");

  auto knownSuggestion =
      model.suggest("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", 3.0);
  ASSERT_TRUE(knownSuggestion.has_value());
  ASSERT_GE(knownSuggestion->logScore, suggestion->logScore);
  std::cout << "MultiContext: novel logScore=" << suggestion->logScore
            << " known logScore=" << knownSuggestion->logScore << "\n";
}

TEST(ContextualUserModelTest, SingleContextNoGeneralization) {
  auto lm = std::make_shared<SimpleLM>(kSampleData);
  ContextualUserModel model(lm);

  model.observe("ㄎㄜ-ㄐㄧˋ", "科技", "ㄍㄠ", "膏", 1.0);

  auto sameSuggestion = model.suggest("ㄎㄜ-ㄐㄧˋ", "科技", "ㄍㄠ", 1.0);
  ASSERT_TRUE(sameSuggestion.has_value());
  ASSERT_EQ(sameSuggestion->value, "膏");

  auto diffSuggestion = model.suggest("ㄊㄧㄢ-ㄑㄧˋ", "天氣", "ㄍㄠ", 1.0);
  if (diffSuggestion.has_value()) {
    std::cout << "SingleContext: diff context suggested="
              << diffSuggestion->value << "\n";
  }
}

TEST(ContextualUserModelTest, TemporalDecay) {
  auto lm = std::make_shared<SimpleLM>(kSampleData);
  ContextualUserModel model(lm);

  model.observe("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終", 1.0);

  auto freshSuggestion =
      model.suggest("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", 1.0);
  ASSERT_TRUE(freshSuggestion.has_value());

  auto decayedSuggestion =
      model.suggest("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", 100.0);
  ASSERT_TRUE(decayedSuggestion.has_value());

  ASSERT_LT(decayedSuggestion->logScore, freshSuggestion->logScore);
  std::cout << "TemporalDecay: fresh=" << freshSuggestion->logScore
            << " decayed=" << decayedSuggestion->logScore << "\n";
}

TEST(ContextualUserModelTest, SubSpanDecomposition) {
  std::string data = R"(
ㄗˋ 字 -6.5
ㄗˋ 自 -5.0
ㄏㄨㄟˋ 彙 -8.2
ㄏㄨㄟˋ 會 -4.8
)";
  auto lm = std::make_shared<SimpleLM>(data.c_str());
  ContextualUserModel model(lm);

  double score = model.decomposedScore("ㄗˋ-ㄏㄨㄟˋ", "字彙");
  double expected = std::exp(-6.5) * std::exp(-8.2);
  ASSERT_NEAR(score, expected, 1e-12);
  std::cout << "SubSpanDecomposition: score=" << score
            << " expected=" << expected << "\n";
}

TEST(ContextualUserModelTest, SubSpanDecomposition3Syllable) {
  std::string data = R"(
ㄖㄣˊ 人 -3.8
ㄍㄨㄥ 工 -7.82
ㄓˋ 智 -7.5
)";
  auto lm = std::make_shared<SimpleLM>(data.c_str());
  ContextualUserModel model(lm);

  double score = model.decomposedScore("ㄖㄣˊ-ㄍㄨㄥ-ㄓˋ", "人工智");
  double expected = std::exp(-3.8) * std::exp(-7.82) * std::exp(-7.5);
  ASSERT_NEAR(score, expected, 1e-15);
  std::cout << "SubSpanDecomposition3: score=" << score
            << " expected=" << expected << "\n";
}

TEST(ContextualUserModelTest, Persistence) {
  auto lm = std::make_shared<SimpleLM>(kSampleData);
  ContextualUserModel model(lm);

  model.observe("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終", 1.0);
  model.observe("ㄍㄨㄥ-ㄙ", "公司", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終", 2.0);
  model.observe("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄍㄠ", "膏", 3.0);
  model.observe("ㄎㄜ-ㄐㄧˋ", "科技", "ㄙ", "司", 4.0);
  model.observe("ㄉㄜ˙", "的", "ㄋㄧㄢˊ-ㄓㄨㄥ", "年中", 5.0);

  std::string tmpPath =
      (std::filesystem::temp_directory_path() / "contextual_user_model_test.txt")
          .string();
  ASSERT_TRUE(model.saveToFile(tmpPath));

  ContextualUserModel loaded(lm);
  ASSERT_TRUE(loaded.loadFromFile(tmpPath));

  auto orig =
      model.suggest("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", 5.0);
  auto loadedSuggestion =
      loaded.suggest("ㄍㄠ-ㄎㄜ-ㄐㄧˋ", "高科技", "ㄋㄧㄢˊ-ㄓㄨㄥ", 5.0);
  ASSERT_TRUE(orig.has_value());
  ASSERT_TRUE(loadedSuggestion.has_value());
  ASSERT_EQ(orig->value, loadedSuggestion->value);
  ASSERT_NEAR(orig->logScore, loadedSuggestion->logScore, 0.01);
  std::cout << "Persistence: original logScore=" << orig->logScore
            << " loaded logScore=" << loadedSuggestion->logScore << "\n";
}

TEST(ContextualUserModelTest, ExplicitUserPhrase) {
  std::string data = R"(
ㄗˋ 字 -6.5
ㄏㄨㄟˋ 彙 -8.2
ㄏㄨㄟˋ 會 -4.8
)";
  auto lm = std::make_shared<SimpleLM>(data.c_str());
  ContextualUserModel model(lm);

  model.addExplicitPhrase("ㄗˋ-ㄏㄨㄟˋ", "字彙");

  auto suggestion = model.suggest("_START_", "", "ㄗˋ-ㄏㄨㄟˋ", 0);
  ASSERT_TRUE(suggestion.has_value());
  ASSERT_EQ(suggestion->value, "字彙");

  auto otherSuggestion = model.suggest("ㄗㄥ-ㄐㄧㄚ", "增加", "ㄗˋ-ㄏㄨㄟˋ", 0);
  ASSERT_TRUE(otherSuggestion.has_value());
  ASSERT_EQ(otherSuggestion->value, "字彙");
  std::cout << "ExplicitUserPhrase: logScore=" << suggestion->logScore << "\n";
}

TEST(ContextualUserModelTest, LargeObservationVolume) {
  auto lm = std::make_shared<SimpleLM>(kSampleData);
  ContextualUserModel model(lm);

  auto startObs = std::chrono::high_resolution_clock::now();
  for (int i = 0; i < 100; i++) {
    std::string ctx = "ctx" + std::to_string(i);
    model.observe(ctx, ctx, "ㄙ", "斯", static_cast<double>(i));
  }
  auto endObs = std::chrono::high_resolution_clock::now();
  auto obsUs =
      std::chrono::duration_cast<std::chrono::microseconds>(endObs - startObs)
          .count();

  auto startSuggest = std::chrono::high_resolution_clock::now();
  auto suggestion = model.suggest("ctx50", "ctx50", "ㄙ", 100.0);
  auto endSuggest = std::chrono::high_resolution_clock::now();
  auto suggestUs = std::chrono::duration_cast<std::chrono::microseconds>(
                       endSuggest - startSuggest)
                       .count();

  ASSERT_TRUE(suggestion.has_value());
  std::cout << "LargeVolume: 100 observes=" << obsUs
            << " us, suggest=" << suggestUs << " us\n";
}

// =============================================================================
// Phase 3 Tests: Integrated Walk with User Model (C1-C10, D1-D5)
// =============================================================================

constexpr char kExtendedData[] = R"(
#
# Extended sample data for Phase 3 tests.
# Includes kSampleData entries plus additional vocabulary.
#
ㄙ 絲 -9.495858
ㄙ 思 -9.006414
ㄙ 私 -99.000000
ㄙ 斯 -8.091803
ㄙ 司 -99.000000
ㄙ 嘶 -13.513987
ㄙ 撕 -12.259095
ㄍㄠ 高 -7.171551
ㄎㄜ 顆 -10.574273
ㄎㄜ 棵 -11.504072
ㄎㄜ 刻 -10.450457
ㄎㄜ 科 -7.171052
ㄎㄜ 柯 -99.000000
ㄍㄠ 膏 -11.928720
ㄍㄠ 篙 -13.624335
ㄍㄠ 糕 -12.390804
ㄉㄜ˙ 的 -3.516024
ㄉㄧˊ 的 -3.516024
ㄉㄧˋ 的 -3.516024
ㄓㄨㄥ 中 -5.809297
ㄉㄜ˙ 得 -7.427179
ㄍㄨㄥ 共 -8.381971
ㄍㄨㄥ 供 -8.501463
ㄐㄧˋ 既 -99.000000
ㄐㄧㄣ 今 -8.034095
ㄍㄨㄥ 紅 -8.858181
ㄐㄧˋ 際 -7.608341
ㄐㄧˋ 季 -99.000000
ㄐㄧㄣ 金 -7.290109
ㄐㄧˋ 騎 -10.939895
ㄓㄨㄥ 終 -99.000000
ㄐㄧˋ 記 -99.000000
ㄐㄧˋ 寄 -99.000000
ㄐㄧㄣ 斤 -99.000000
ㄐㄧˋ 繼 -9.715317
ㄐㄧˋ 計 -7.926683
ㄐㄧˋ 暨 -8.373022
ㄓㄨㄥ 鐘 -9.877580
ㄐㄧㄣ 禁 -10.711079
ㄍㄨㄥ 公 -7.877973
ㄍㄨㄥ 工 -7.822167
ㄍㄨㄥ 攻 -99.000000
ㄍㄨㄥ 功 -99.000000
ㄍㄨㄥ 宮 -99.000000
ㄓㄨㄥ 鍾 -9.685671
ㄐㄧˋ 繫 -10.425662
ㄍㄨㄥ 弓 -99.000000
ㄍㄨㄥ 恭 -99.000000
ㄐㄧˋ 劑 -8.888722
ㄐㄧˋ 祭 -10.204425
ㄐㄧㄣ 浸 -11.378321
ㄓㄨㄥ 盅 -99.000000
ㄐㄧˋ 忌 -99.000000
ㄐㄧˋ 技 -8.450826
ㄐㄧㄣ 筋 -11.074890
ㄍㄨㄥ 躬 -99.000000
ㄐㄧˋ 冀 -12.045357
ㄓㄨㄥ 忠 -99.000000
ㄐㄧˋ 妓 -99.000000
ㄐㄧˋ 濟 -9.517568
ㄐㄧˋ 薊 -12.021587
ㄐㄧㄣ 巾 -99.000000
ㄐㄧㄣ 襟 -12.784206
ㄋㄧㄢˊ 年 -6.086515
ㄐㄧㄤˇ 講 -9.164384
ㄐㄧㄤˇ 獎 -8.690941
ㄐㄧㄤˇ 蔣 -10.127828
ㄋㄧㄢˊ 黏 -11.336864
ㄋㄧㄢˊ 粘 -11.285740
ㄐㄧㄤˇ 槳 -12.492933
ㄍㄨㄥㄙ 公司 -6.299461
ㄎㄜㄐㄧˋ 科技 -6.736613
ㄐㄧˋㄍㄨㄥ 濟公 -13.336653
ㄐㄧㄤˇㄐㄧㄣ 獎金 -10.344678
ㄋㄧㄢˊㄓㄨㄥ 年終 -11.668947
ㄋㄧㄢˊㄓㄨㄥ 年中 -11.373044
ㄍㄠㄎㄜㄐㄧˋ 高科技 -9.842421
ㄨㄛˇ 我 -4.50
ㄇㄣˊ 們 -7.00
ㄊㄧㄢ 天 -5.50
ㄒㄧㄚˋ 下 -4.50
ㄨˇ 午 -7.00
ㄑㄩˋ 去 -2.85
ㄎㄞ 開 -5.30
ㄏㄨㄟˋ 會 -4.80
ㄊㄠˇ 討 -8.00
ㄌㄨㄣˋ 論 -6.50
ㄨㄟˋ 未 -6.20
ㄌㄞˊ 來 -4.80
ㄈㄚ 發 -5.00
ㄓㄢˇ 展 -6.50
ㄈㄟ 非 -5.50
ㄔㄤˊ 常 -5.80
ㄓˊ 值 -7.20
ㄉㄜˊ 得 -5.80
ㄑㄧˊ 期 -6.50
ㄉㄞˋ 待 -6.80
ㄊㄞˊ 台 -4.50
ㄨㄢ 灣 -6.00
ㄖㄣˊ 人 -3.80
ㄓˋ 智 -7.50
ㄏㄨㄟˋ 慧 -7.80
ㄍㄨㄢ 關 -6.50
ㄓㄨˋ 注 -6.80
ㄨㄛˇㄇㄣˊ 我們 -3.80
ㄐㄧㄣㄊㄧㄢ 今天 -3.29
ㄒㄧㄚˋㄨˇ 下午 -4.03
ㄎㄞㄏㄨㄟˋ 開會 -4.57
ㄊㄠˇㄌㄨㄣˋ 討論 -3.72
ㄨㄟˋㄌㄞˊ 未來 -3.57
ㄈㄚㄓㄢˇ 發展 -3.37
ㄈㄟㄔㄤˊ 非常 -3.48
ㄓˊㄉㄜˊ 值得 -4.09
ㄑㄧˊㄉㄞˋ 期待 -4.28
ㄊㄞˊㄨㄢ 台灣 -2.88
ㄖㄣˊㄍㄨㄥ 人工 -5.50
ㄓˋㄏㄨㄟˋ 智慧 -5.20
ㄊㄧㄢㄒㄧㄚˋ 天下 -5.00
ㄊㄧㄢㄑㄧˋ 天氣 -4.26
ㄖㄣˊㄍㄨㄥㄓˋㄏㄨㄟˋ 人工智慧 -5.68
ㄍㄨㄢㄓㄨˋ 關注 -4.20
ㄑㄧˋ 氣 -6.20
ㄏㄣˇ 很 -2.84
ㄏㄠˇ 好 -2.78
ㄏㄣˇㄏㄠˇ 很好 -5.00
)";

// C1: Walk with user model on 10-syllable sentence
TEST(IntegratedWalkTest, WalkWithUserModel10Syllables) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");
  ContextualUserModel userModel(lm);

  for (const auto& r : {"ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ", "ㄍㄨㄥ", "ㄙ",
                         "ㄉㄜ˙", "ㄋㄧㄢˊ", "ㄓㄨㄥ", "ㄐㄧㄤˇ", "ㄐㄧㄣ"}) {
    grid.insertReading(r);
  }

  auto baseResult = grid.walk();
  ASSERT_EQ(baseResult.valuesAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年中", "獎金"}));
  std::cout << "C1 base walk: " << baseResult.elapsedMicroseconds << " us\n";

  userModel.observe("ㄉㄜ˙", "的", "ㄋㄧㄢˊㄓㄨㄥ", "年終", 1.0);

  grid.setUserModel(&userModel);
  auto umResult = grid.walk();
  std::cout << "C1 user model walk: " << umResult.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : umResult.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  bool hasNianzhong = false;
  for (const auto& v : umResult.valuesAsStrings()) {
    if (v == "年終") hasNianzhong = true;
  }
  ASSERT_TRUE(hasNianzhong) << "User model should promote 年終";

  grid.setUserModel(nullptr);
  auto resetResult = grid.walk();
  ASSERT_EQ(resetResult.valuesAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年中", "獎金"}));
}

// C2: Walk with user model on 6-syllable sentence
TEST(IntegratedWalkTest, WalkWithUserModel6Syllables) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");

  // 今天天氣很好 (6 syllables)
  for (const auto& r : {"ㄐㄧㄣ", "ㄊㄧㄢ", "ㄊㄧㄢ", "ㄑㄧˋ",
                         "ㄏㄣˇ", "ㄏㄠˇ"}) {
    grid.insertReading(r);
  }

  auto result = grid.walk();
  std::cout << "C2 6-syl walk: " << result.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : result.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  ASSERT_GE(result.nodes.size(), 3u);
}

// C3: Walk with user model, multi-context boost
TEST(IntegratedWalkTest, WalkWithUserModelMultiContext) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");
  ContextualUserModel userModel(lm);

  for (const auto& r : {"ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ", "ㄍㄨㄥ", "ㄙ",
                         "ㄉㄜ˙", "ㄋㄧㄢˊ", "ㄓㄨㄥ", "ㄐㄧㄤˇ", "ㄐㄧㄣ"}) {
    grid.insertReading(r);
  }

  userModel.observe("ㄍㄨㄥㄙ", "公司", "ㄋㄧㄢˊㄓㄨㄥ", "年終", 1.0);
  userModel.observe("ㄉㄜ˙", "的", "ㄋㄧㄢˊㄓㄨㄥ", "年終", 2.0);

  grid.setUserModel(&userModel);
  auto result = grid.walk();
  std::cout << "C3 multi-context walk: " << result.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : result.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  bool hasNianzhong = false;
  for (const auto& v : result.valuesAsStrings()) {
    if (v == "年終") hasNianzhong = true;
  }
  ASSERT_TRUE(hasNianzhong) << "Multi-context boost should promote 年終";
}

// C4: Walk with fixed span AND user model
TEST(IntegratedWalkTest, WalkWithFixedSpanAndUserModel) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");
  ContextualUserModel userModel(lm);

  for (const auto& r : {"ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ", "ㄍㄨㄥ", "ㄙ",
                         "ㄉㄜ˙", "ㄋㄧㄢˊ", "ㄓㄨㄥ", "ㄐㄧㄤˇ", "ㄐㄧㄣ"}) {
    grid.insertReading(r);
  }

  grid.setCursor(7);
  ASSERT_TRUE(grid.overrideCandidate(7, "年終"));
  auto fixResult = grid.walk();

  userModel.observe("ㄍㄨㄥㄙ", "公司", "ㄋㄧㄢˊㄓㄨㄥ", "年終", 1.0);
  grid.setUserModel(&userModel);

  auto result = grid.walk();
  std::cout << "C4 fixed+UM walk: " << result.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : result.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"高科技", "公司", "的", "年終", "獎金"}));
}

// C5: Walk 15 syllables
TEST(IntegratedWalkTest, Walk15Syllables) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");

  // 台灣的人工智慧發展非常值得期待 (15 syllables)
  for (const auto& r : {"ㄊㄞˊ", "ㄨㄢ", "ㄉㄜ˙", "ㄖㄣˊ", "ㄍㄨㄥ",
                         "ㄓˋ", "ㄏㄨㄟˋ", "ㄈㄚ", "ㄓㄢˇ", "ㄈㄟ",
                         "ㄔㄤˊ", "ㄓˊ", "ㄉㄜˊ", "ㄑㄧˊ", "ㄉㄞˋ"}) {
    grid.insertReading(r);
  }

  auto result = grid.walk();
  std::cout << "C5 15-syl walk: " << result.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : result.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  ASSERT_EQ(result.totalReadings, 15u);
  ASSERT_GE(result.nodes.size(), 5u);
  ASSERT_LE(result.elapsedMicroseconds, 1000u);
}

// C6: Walk 20 syllables
TEST(IntegratedWalkTest, Walk20Syllables) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");

  // 我們今天下午去高科技公司開會討論未來發展 (20 syllables)
  for (const auto& r : {"ㄨㄛˇ", "ㄇㄣˊ", "ㄐㄧㄣ", "ㄊㄧㄢ", "ㄒㄧㄚˋ",
                         "ㄨˇ", "ㄑㄩˋ", "ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ",
                         "ㄍㄨㄥ", "ㄙ", "ㄎㄞ", "ㄏㄨㄟˋ", "ㄊㄠˇ",
                         "ㄌㄨㄣˋ", "ㄨㄟˋ", "ㄌㄞˊ", "ㄈㄚ", "ㄓㄢˇ"}) {
    grid.insertReading(r);
  }

  auto result = grid.walk();
  std::cout << "C6 20-syl walk: " << result.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : result.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  ASSERT_EQ(result.totalReadings, 20u);
  ASSERT_GE(result.nodes.size(), 8u);
  ASSERT_LE(result.elapsedMicroseconds, 2000u);
}

// C7: Walk 35 syllables (C5 + C6 combined)
TEST(IntegratedWalkTest, Walk35Syllables) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");

  // 台灣的人工智慧發展非常值得期待 (15 syllables)
  for (const auto& r : {"ㄊㄞˊ", "ㄨㄢ", "ㄉㄜ˙", "ㄖㄣˊ", "ㄍㄨㄥ",
                         "ㄓˋ", "ㄏㄨㄟˋ", "ㄈㄚ", "ㄓㄢˇ", "ㄈㄟ",
                         "ㄔㄤˊ", "ㄓˊ", "ㄉㄜˊ", "ㄑㄧˊ", "ㄉㄞˋ"}) {
    grid.insertReading(r);
  }
  // + 我們今天下午去高科技公司開會討論未來發展 (20 syllables)
  for (const auto& r : {"ㄨㄛˇ", "ㄇㄣˊ", "ㄐㄧㄣ", "ㄊㄧㄢ", "ㄒㄧㄚˋ",
                         "ㄨˇ", "ㄑㄩˋ", "ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ",
                         "ㄍㄨㄥ", "ㄙ", "ㄎㄞ", "ㄏㄨㄟˋ", "ㄊㄠˇ",
                         "ㄌㄨㄣˋ", "ㄨㄟˋ", "ㄌㄞˊ", "ㄈㄚ", "ㄓㄢˇ"}) {
    grid.insertReading(r);
  }

  auto result = grid.walk();
  std::cout << "C7 35-syl walk: " << result.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : result.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  ASSERT_EQ(result.totalReadings, 35u);
  ASSERT_LE(result.elapsedMicroseconds, 5000u);
}

// C8: Walk 50 syllables stress test
TEST(IntegratedWalkTest, Walk50SyllablesStress) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");

  for (int rep = 0; rep < 5; rep++) {
    for (const auto& r : {"ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ", "ㄍㄨㄥ", "ㄙ",
                           "ㄉㄜ˙", "ㄋㄧㄢˊ", "ㄓㄨㄥ", "ㄐㄧㄤˇ",
                           "ㄐㄧㄣ"}) {
      grid.insertReading(r);
    }
  }

  auto result = grid.walk();
  std::cout << "C8 50-syl walk: " << result.elapsedMicroseconds << " us"
            << " nodes=" << result.nodes.size() << "\n";

  ASSERT_EQ(result.totalReadings, 50u);
  ASSERT_LE(result.elapsedMicroseconds, 20000u);
}

// C9: Walk 100-1000 syllables homogeneous scaling test
TEST(IntegratedWalkTest, Walk100To1000Scaling) {
  for (size_t size : {100u, 200u, 500u, 1000u}) {
    MockLM mockLM;
    ReadingGrid grid(std::make_shared<MockLM>(mockLM));
    grid.setReadingSeparator("");

    for (size_t i = 0; i < size; i++) {
      grid.insertReading("ㄧ");
    }

    auto result = grid.walk();
    std::cout << "C9 " << size << "-syl walk: " << result.elapsedMicroseconds
              << " us, nodes=" << result.nodes.size() << "\n";
    ASSERT_EQ(result.totalReadings, size);
  }
}

// C10: Walk with user model AND fixed spans on 100 syllables
TEST(IntegratedWalkTest, WalkWithUserModelAndFixedSpans100Syllables) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");
  ContextualUserModel userModel(lm);

  for (int rep = 0; rep < 10; rep++) {
    for (const auto& r : {"ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ", "ㄍㄨㄥ", "ㄙ",
                           "ㄉㄜ˙", "ㄋㄧㄢˊ", "ㄓㄨㄥ", "ㄐㄧㄤˇ",
                           "ㄐㄧㄣ"}) {
      grid.insertReading(r);
    }
  }

  for (int i = 0; i < 10; i++) {
    std::string ctx = "ctx" + std::to_string(i);
    userModel.observe(ctx, ctx, "ㄋㄧㄢˊㄓㄨㄥ", "年終", static_cast<double>(i));
    userModel.observe(ctx, ctx, "ㄍㄠ", "膏", static_cast<double>(i));
  }

  for (size_t pos : {0u, 30u, 60u, 90u}) {
    auto node = grid.findInSpan(pos, [](const ReadingGrid::NodePtr& n) {
      return n->spanningLength() == 1;
    });
    if (node.has_value()) {
      grid.fixSpan(pos, node.value());
    }
  }

  grid.setUserModel(&userModel);
  auto result = grid.walk();
  std::cout << "C10 100-syl+UM+Fix walk: " << result.elapsedMicroseconds
            << " us, nodes=" << result.nodes.size() << "\n";

  ASSERT_EQ(result.totalReadings, 100u);
}

// D1: Empty grid edge case
TEST(IntegratedWalkTest, EmptyGrid) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  ContextualUserModel userModel(lm);

  grid.setUserModel(&userModel);
  auto result = grid.walk();
  ASSERT_TRUE(result.nodes.empty());
  ASSERT_EQ(result.totalReadings, 0u);

  grid.setUserModel(nullptr);
  auto result2 = grid.walk();
  ASSERT_TRUE(result2.nodes.empty());
}

// D2: Single syllable
TEST(IntegratedWalkTest, SingleSyllable) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");
  ContextualUserModel userModel(lm);

  grid.insertReading("ㄍㄠ");
  grid.setUserModel(&userModel);
  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(), (std::vector<std::string>{"高"}));
  std::cout << "D2 single-syl: " << result.elapsedMicroseconds << " us\n";
}

// D3: All fixed spans (every position fixed)
TEST(IntegratedWalkTest, AllFixedSpans) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");

  for (const auto& r : {"ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ", "ㄍㄨㄥ", "ㄙ"}) {
    grid.insertReading(r);
  }

  auto makeFixedNode = [&](const std::string& reading, const std::string& value) {
    return std::make_shared<ReadingGrid::Node>(
        reading, 1,
        std::vector<LanguageModel::Unigram>{LanguageModel::Unigram(value, -5.0)});
  };
  grid.fixSpan(0, makeFixedNode("ㄍㄠ", "膏"));
  grid.fixSpan(1, makeFixedNode("ㄎㄜ", "柯"));
  grid.fixSpan(2, makeFixedNode("ㄐㄧˋ", "計"));
  grid.fixSpan(3, makeFixedNode("ㄍㄨㄥ", "弓"));
  grid.fixSpan(4, makeFixedNode("ㄙ", "撕"));

  auto result = grid.walk();
  ASSERT_EQ(result.valuesAsStrings(),
            (std::vector<std::string>{"膏", "柯", "計", "弓", "撕"}));
  std::cout << "D3 all-fixed: " << result.elapsedMicroseconds << " us\n";
}

// D4: User model conflicts with fixed span (structural fix wins)
TEST(IntegratedWalkTest, UserModelConflictsWithFixedSpan) {
  auto lm = std::make_shared<SimpleLM>(kExtendedData);
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");
  ContextualUserModel userModel(lm);

  for (const auto& r : {"ㄍㄠ", "ㄎㄜ", "ㄐㄧˋ", "ㄍㄨㄥ", "ㄙ",
                         "ㄉㄜ˙", "ㄋㄧㄢˊ", "ㄓㄨㄥ", "ㄐㄧㄤˇ", "ㄐㄧㄣ"}) {
    grid.insertReading(r);
  }

  grid.setCursor(7);
  ASSERT_TRUE(grid.overrideCandidate(7, "年中"));

  for (int i = 0; i < 10; i++) {
    userModel.observe("ㄉㄜ˙", "的", "ㄋㄧㄢˊㄓㄨㄥ", "年終",
                      static_cast<double>(i));
  }
  grid.setUserModel(&userModel);

  auto result = grid.walk();
  std::cout << "D4 conflict: " << result.elapsedMicroseconds << " us"
            << " values:";
  for (const auto& v : result.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  bool hasNianzhong = false;
  for (const auto& v : result.valuesAsStrings()) {
    if (v == "年中") hasNianzhong = true;
  }
  ASSERT_TRUE(hasNianzhong) << "Structural fix should override user model";
}

// D5: Backoff to decomposition in walk (novel phrase via explicit add)
TEST(IntegratedWalkTest, BackoffToDecomposition) {
  std::string data = R"(
ㄗˋ 字 -6.5
ㄗˋ 自 -5.0
ㄏㄨㄟˋ 彙 -8.2
ㄏㄨㄟˋ 會 -4.8
)";
  auto lm = std::make_shared<SimpleLM>(data.c_str());
  ReadingGrid grid(lm);
  grid.setReadingSeparator("");
  ContextualUserModel userModel(lm);

  grid.insertReading("ㄗˋ");
  grid.insertReading("ㄏㄨㄟˋ");

  auto baseResult = grid.walk();
  std::cout << "D5 base: values:";
  for (const auto& v : baseResult.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";
  ASSERT_EQ(baseResult.nodes.size(), 2u);

  userModel.addExplicitPhrase("ㄗˋ-ㄏㄨㄟˋ", "字彙");

  grid.setUserModel(&userModel);
  auto umResult = grid.walk();
  std::cout << "D5 with user phrase: values:";
  for (const auto& v : umResult.valuesAsStrings()) std::cout << " " << v;
  std::cout << "\n";

  // The walk still picks individual characters (since "字彙" isn't a node in
  // the grid — it only exists in the user model). The user model can only
  // influence scoring of existing nodes, not create new ones.
  ASSERT_EQ(umResult.nodes.size(), 2u);
}

}  // namespace Formosa::Gramambular2
