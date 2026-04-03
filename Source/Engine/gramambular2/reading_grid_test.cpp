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
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "gtest/gtest.h"
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

}  // namespace Formosa::Gramambular2
