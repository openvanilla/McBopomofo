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

#include <string>

#include "UserOverrideModel.h"
#include "gramambular2/reading_grid.h"
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

constexpr char kSampleData[] = R"(
ㄐㄧ 機 -3.02367199
ㄐㄧ 積 -3.72854036
ㄐㄧ-ㄧㄡˊ 機油 -6.03662914
ㄧㄡˊ 由 -3.00970678
ㄧㄡˊ 油 -3.75900671
)";

class SimpleLM : public Formosa::Gramambular2::LanguageModel {
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

TEST(UserOverrideModelTest, WalkResultSnapshotTest) {
  // See https://github.com/openvanilla/McBopomofo/issues/885.
  // This is a kind of integration test for the following steps:
  // 1. Type ㄐㄧ ㄧㄡˊ -> 機由; this assumes P(機）P(由) > P(機油)
  // 2. Override with 機油 and tell UOM to observe
  // 3. Reset, type ㄐㄧ ㄧㄡˊ -> 機油 -- UOM should suggest the expected
  // override
  // 4. Reset, type ㄐㄧ -> 機
  // 5. Override with 積 and tell UOM to observe
  // 6. Reset, type ㄐㄧ ㄧㄡˊ -> 積由 -- this is expected due to UOM suggestion
  // 7. Override with 機油 and tell UOM to observe
  // 8. Reset, type ㄐㄧ -> 積 due to UOM suggestion
  // 9. Continue to type 由 -> walk result should be 積由, and the UOM should
  //    suggest 機油 as the override candidate.

  std::string sampleData(kSampleData);
  Formosa::Gramambular2::ReadingGrid grid(
      std::make_shared<SimpleLM>(sampleData.c_str()));
  UserOverrideModel uom(kCapacity, kHalflife);
  Formosa::Gramambular2::ReadingGrid::WalkResult walkBefore;
  Formosa::Gramambular2::ReadingGrid::WalkResult walkLatest;
  UserOverrideModel::Suggestion suggestion;
  std::vector<Formosa::Gramambular2::ReadingGrid::NodePtr>::const_iterator
      nodeIter;
  double timestamp = kFakeNow;

  grid.insertReading("ㄐㄧ");
  grid.insertReading("ㄧㄡˊ");
  walkBefore = grid.walk();
  ASSERT_EQ(walkBefore.valuesAsStrings(),
            (std::vector<std::string>{"機", "由"}));

  grid.overrideCandidate(1, "機油");
  walkLatest = grid.walk();
  ASSERT_EQ(walkLatest.valuesAsStrings(), (std::vector<std::string>{"機油"}));

  nodeIter = walkLatest.findNodeAt(1, /*outCursorPastNode=*/nullptr);
  ASSERT_NE(nodeIter, walkLatest.nodes.cend());
  uom.observe(walkBefore, walkLatest, 1, timestamp);
  timestamp += 1.0;

  grid.clear();
  grid.insertReading("ㄐㄧ");
  grid.insertReading("ㄧㄡˊ");
  walkLatest = grid.walk();
  suggestion = uom.suggest(walkLatest, 1, timestamp);
  timestamp += 1.0;
  ASSERT_EQ(suggestion.candidate, "機油");

  grid.clear();
  grid.insertReading("ㄐㄧ");
  walkBefore = grid.walk();
  ASSERT_EQ(walkBefore.valuesAsStrings(), (std::vector<std::string>{"機"}));

  grid.overrideCandidate(0, "積");
  walkLatest = grid.walk();
  ASSERT_EQ(walkLatest.valuesAsStrings(), (std::vector<std::string>{"積"}));

  nodeIter = walkLatest.findNodeAt(0, /*outCursorPastNode=*/nullptr);
  ASSERT_NE(nodeIter, walkLatest.nodes.cend());
  uom.observe(walkBefore, walkLatest, 0, timestamp);
  timestamp += 1.0;

  grid.clear();
  grid.insertReading("ㄐㄧ");
  walkLatest = grid.walk();
  suggestion = uom.suggest(walkLatest, 0, timestamp);
  timestamp += 1.0;
  ASSERT_EQ(suggestion.candidate, "積");

  grid.overrideCandidate(0, "積");
  grid.insertReading("ㄧㄡˊ");

  // THIS MUST BE A COPY OF NODES, otherwise the observation below will not
  // capture the correct state of the grid.
  // See https://github.com/openvanilla/McBopomofo/issues/885.
  //
  // This is wrong:
  //   walkBefore = grid.walk();
  //
  // The following is correct:
  walkBefore = grid.walk().copyWithFixedNodes();

  ASSERT_EQ(walkBefore.valuesAsStrings(),
            (std::vector<std::string>{"積", "由"}));

  grid.overrideCandidate(1, "機油");
  walkLatest = grid.walk();
  ASSERT_EQ(walkLatest.valuesAsStrings(), (std::vector<std::string>{"機油"}));

  nodeIter = walkLatest.findNodeAt(1, /*outCursorPastNode=*/nullptr);
  ASSERT_NE(nodeIter, walkLatest.nodes.cend());
  uom.observe(walkBefore, walkLatest, 1, timestamp);
  timestamp += 1.0;

  grid.clear();
  grid.insertReading("ㄐㄧ");
  walkLatest = grid.walk();
  suggestion = uom.suggest(walkLatest, 0, timestamp);
  timestamp += 1.0;
  ASSERT_EQ(suggestion.candidate, "積");
  grid.overrideCandidate(0, "積");
  grid.insertReading("ㄧㄡˊ");
  walkLatest = grid.walk();
  ASSERT_EQ(walkLatest.valuesAsStrings(),
            (std::vector<std::string>{"積", "由"}));

  suggestion = uom.suggest(walkLatest, 1, timestamp);
  timestamp += 1.0;
  ASSERT_EQ(suggestion.candidate, "機油");
}

}  // namespace McBopomofo
