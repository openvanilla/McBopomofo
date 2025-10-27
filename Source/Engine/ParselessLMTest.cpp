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

#include <filesystem>
#include <iostream>
#include <memory>
#include <utility>
#include <vector>

#include "ParselessLM.h"
#include "gtest/gtest.h"

namespace McBopomofo {

constexpr char kSample[] = R"(
# format org.openvanilla.mcbopomofo.sorted
ㄅㄚ 八 -3.27631260
ㄅㄚ 吧 -3.59800309
ㄅㄚ 巴 -3.80233706
ㄅㄚ-ㄅㄞˇ 八百 -4.67026409
ㄅㄚ-ㄅㄞˇ 捌佰 -7.26686119
ㄅㄚ˙ 吧 -3.59800309
)";

TEST(ParselessLMTest, IdempotentClose) {
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));

  ParselessLM lm;
  EXPECT_TRUE(lm.open(std::move(db)));
  lm.close();

  // Safe to do so.
  lm.close();
}

TEST(ParselessLMTest, OpenFailsIfAlreadyOpened) {
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));

  ParselessLM lm;
  EXPECT_TRUE(lm.open(std::move(db)));

  auto db2 = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_FALSE(lm.open(std::move(db2)));
}

TEST(ParselessLMTest, UnopenedInstanceReturnsNothing) {
  ParselessLM lm;
  EXPECT_FALSE(lm.hasUnigrams("八"));
}

TEST(ParselessLMTest, ReturnsResults) {
  ParselessLM lm;
  auto db = std::make_unique<ParselessPhraseDB>(kSample, sizeof(kSample));
  EXPECT_TRUE(lm.open(std::move(db)));

  using Unigram = Formosa::Gramambular2::LanguageModel::Unigram;
  std::vector<Unigram> unigrams = lm.getUnigrams("ㄅㄚ-ㄅㄞˇ");
  EXPECT_EQ(unigrams.size(), 2);
  EXPECT_EQ(unigrams[0].value(), "八百");
  EXPECT_NEAR(unigrams[0].score(), -4.67026409, 0.00000001);
  EXPECT_EQ(unigrams[1].value(), "捌佰");
  EXPECT_NEAR(unigrams[1].score(), -7.26686119, 0.00000001);

  std::vector<ParselessLM::FoundReading> readings = lm.getReadings("吧");
  EXPECT_EQ(readings.size(), 2);
  EXPECT_EQ(readings[0].reading, "ㄅㄚ");
  EXPECT_NEAR(readings[0].score, -3.59800309, 0.00000001);
  EXPECT_EQ(readings[1].reading, "ㄅㄚ˙");
  EXPECT_NEAR(readings[1].score, -3.59800309, 0.00000001);
}

TEST(ParselessLMTest, SanityCheckTest) {
  constexpr const char* data_path = "data.txt";
  if (!std::filesystem::exists(data_path)) {
    GTEST_SKIP();
  }

  ParselessLM lm;
  bool status = lm.open(data_path);
  ASSERT_TRUE(status);

  ASSERT_TRUE(lm.hasUnigrams("ㄕ"));
  ASSERT_TRUE(lm.hasUnigrams("ㄕˋ-ㄕˊ"));
  ASSERT_TRUE(lm.hasUnigrams("_punctuation_list"));

  auto unigrams = lm.getUnigrams("ㄕ");
  ASSERT_GT(unigrams.size(), 0);

  unigrams = lm.getUnigrams("ㄕˋ-ㄕˊ");
  ASSERT_GT(unigrams.size(), 0);

  unigrams = lm.getUnigrams("_punctuation_list");
  ASSERT_GT(unigrams.size(), 0);

  std::vector<ParselessLM::FoundReading> found_readings;
  found_readings = lm.getReadings("不存在的詞");
  ASSERT_TRUE(found_readings.empty());

  found_readings = lm.getReadings("讀音");
  ASSERT_EQ(found_readings.size(), 1);

  found_readings = lm.getReadings("鑰匙");
  ASSERT_GT(found_readings.size(), 1);

  found_readings = lm.getReadings("得");
  ASSERT_GT(found_readings.size(), 1);
  ASSERT_EQ(found_readings[0].reading, "ㄉㄜˊ");

  lm.close();
}

}  // namespace McBopomofo
