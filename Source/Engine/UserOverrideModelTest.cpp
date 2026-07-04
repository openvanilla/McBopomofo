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

#include <memory>
#include <string>
#include <vector>

#include "UserOverrideModel.h"
#include "gtest/gtest.h"

namespace McBopomofo {

namespace {
constexpr double kFakeNow = 1657772432;
constexpr int kCapacity = 5;
constexpr double kHalflife = 5400.0;  // 1.5 hr.
}  // namespace

TEST(UserOverrideModelTest, BasicOperation) {
  UserOverrideModel uom(kCapacity, kHalflife);
  std::string key = "abc";
  std::string candidate = "v";
  uom.observe(key, candidate, kFakeNow);

  auto v = uom.suggest(key, kFakeNow);
  ASSERT_EQ(v.candidate, candidate);

  v = uom.suggest(key, kFakeNow + kHalflife * 1);
  ASSERT_EQ(v.candidate, candidate);
  v = uom.suggest(key, kFakeNow + kHalflife * 5);
  ASSERT_EQ(v.candidate, candidate);
  v = uom.suggest(key, kFakeNow + kHalflife * 10);
  ASSERT_EQ(v.candidate, candidate);
  v = uom.suggest(key, kFakeNow + kHalflife * 20);
  ASSERT_EQ(v.candidate, candidate);

  // The suggestion is no longer valid after ~30 hours.
  v = uom.suggest(key, kFakeNow + kHalflife * 21);
  ASSERT_TRUE(v.empty());
}

TEST(UserOverrideModelTest, FreshVsFrequent) {
  UserOverrideModel uom(kCapacity, kHalflife);
  std::string key = "abc";
  std::string olderValue = "older";
  std::string newerValue = "newer";

  uom.observe(key, olderValue, kFakeNow);
  uom.observe(key, olderValue, kFakeNow + kHalflife * 1);
  uom.observe(key, olderValue, kFakeNow + kHalflife * 2);
  uom.observe(key, olderValue, kFakeNow + kHalflife * 3);
  uom.observe(key, olderValue, kFakeNow + kHalflife * 4);
  uom.observe(key, newerValue, kFakeNow + kHalflife * 5);
  uom.observe(key, newerValue, kFakeNow + kHalflife * 5.25);

  // Even if newerValue is more recent, olderValue is used more frequently,
  // and so initially olderValue is still suggested.
  auto v = uom.suggest(key, kFakeNow + kHalflife * 7);
  ASSERT_EQ(v.candidate, olderValue);
  v = uom.suggest(key, kFakeNow + kHalflife * 20);
  ASSERT_EQ(v.candidate, olderValue);
  v = uom.suggest(key, kFakeNow + kHalflife * 22);
  ASSERT_EQ(v.candidate, olderValue);

  // At this point, even if olderValue hasn't expired yet, but the
  // less-frequently observed newerValue is fresher.
  uom.observe(key, newerValue, kFakeNow + kHalflife * 23);
  v = uom.suggest(key, kFakeNow + kHalflife * 23.5);
  ASSERT_EQ(v.candidate, newerValue);

  v = uom.suggest(key, kFakeNow + kHalflife * 25);
  ASSERT_EQ(v.candidate, newerValue);

  v = uom.suggest(key, kFakeNow + kHalflife * 45);
  ASSERT_TRUE(v.empty());
}

TEST(UserOverrideModelTest, LRUBehavior) {
  UserOverrideModel uom(2, kHalflife);
  uom.observe("abc", "x", kFakeNow);
  uom.observe("def", "y", kFakeNow + kHalflife);
  uom.observe("ghi", "z", kFakeNow + kHalflife * 2);

  auto v = uom.suggest("ghi", kFakeNow + kHalflife * 3);
  ASSERT_EQ(v.candidate, "z");

  v = uom.suggest("def", kFakeNow + kHalflife * 4);
  ASSERT_EQ(v.candidate, "y");

  // abc evicted.
  v = uom.suggest("abc", kFakeNow + kHalflife * 5);
  ASSERT_TRUE(v.empty());

  uom.observe("jkl", "p", kFakeNow + kHalflife * 6);

  v = uom.suggest("ghi", kFakeNow + kHalflife * 7);
  ASSERT_EQ(v.candidate, "z");

  // def evicted.
  v = uom.suggest("def", kFakeNow + kHalflife * 7);
  ASSERT_TRUE(v.empty());
}

TEST(UserOverrideModelTest, RemembersExactPhraseReplacement) {
  class TestLM : public Formosa::Gramambular2::LanguageModel {
   public:
    std::vector<Unigram> getUnigrams(const std::string& reading) override {
      if (reading == "zi") {
        return {Unigram("自", -2.75471392), Unigram("字", -3.40268807)};
      }
      if (reading == "hui") {
        return {Unigram("會", -2.42504751), Unigram("彙", -4.69631935)};
      }
      if (reading == "zi-hui") {
        return {Unigram("字彙", -5.86913810),
                Unigram("自會", -6.48892685)};
      }
      return {};
    }

    bool hasUnigrams(const std::string& reading) override {
      return reading == "zi" || reading == "hui" || reading == "zi-hui";
    }
  };

  using Formosa::Gramambular2::ReadingGrid;

  UserOverrideModel uom(kCapacity, kHalflife);
  auto languageModel = std::make_shared<TestLM>();

  ReadingGrid observedGrid(languageModel);
  observedGrid.setPreferExactPhraseMatchForFullInput(true);
  ASSERT_TRUE(observedGrid.insertReading("zi"));
  ASSERT_TRUE(observedGrid.insertReading("hui"));
  ReadingGrid::WalkResult beforeOverride = observedGrid.walk();
  ASSERT_EQ(beforeOverride.valuesAsStrings(), (std::vector<std::string>{"字彙"}));

  ASSERT_TRUE(observedGrid.overrideCandidate(
      1, ReadingGrid::Candidate("zi-hui", "自會")));
  ReadingGrid::WalkResult afterOverride = observedGrid.walk();
  ASSERT_EQ(afterOverride.valuesAsStrings(), (std::vector<std::string>{"自會"}));
  uom.observe(beforeOverride, afterOverride, 1, kFakeNow);

  ReadingGrid queryGrid(languageModel);
  queryGrid.setPreferExactPhraseMatchForFullInput(true);
  ASSERT_TRUE(queryGrid.insertReading("zi"));
  ASSERT_TRUE(queryGrid.insertReading("hui"));
  ReadingGrid::WalkResult exactWalk = queryGrid.walk();
  ASSERT_EQ(exactWalk.valuesAsStrings(), (std::vector<std::string>{"字彙"}));

  UserOverrideModel::Suggestion suggestion = uom.suggest(exactWalk, 1, kFakeNow);
  ASSERT_EQ(suggestion.candidate, "自會");
}

}  // namespace McBopomofo
