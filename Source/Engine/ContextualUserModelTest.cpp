// Copyright (c) 2026 and onwards The McBopomofo Authors.
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

#include <cstdio>
#include <fstream>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "ContextualUserModel.h"
#include "gramambular2/reading_grid.h"
#include "gtest/gtest.h"

namespace McBopomofo {

namespace {
constexpr double kFakeNow = 1657772432;
constexpr size_t kCapacity = 5;
constexpr double kHalfLife = 5400.0;  // 1.5 hr.

std::string TempFilePath(const std::string& name) {
  return testing::TempDir() + name;
}
}  // namespace

TEST(ContextualUserModelTest, BasicObserveAndSuggest) {
  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(ㄒㄧㄣ,心)", "ㄒㄧˋ", "係", kFakeNow);

  auto v = model.suggest("(ㄒㄧㄣ,心)", "ㄒㄧˋ", kFakeNow);
  ASSERT_EQ(v.candidate, "係");
  ASSERT_FALSE(v.forceHighScoreOverride);

  // A single observation must not generalize to a different context.
  v = model.suggest("(ㄉㄚˋ,大)", "ㄒㄧˋ", kFakeNow);
  ASSERT_TRUE(v.empty());

  // Nor to a different reading.
  v = model.suggest("(ㄒㄧㄣ,心)", "ㄒㄧ", kFakeNow);
  ASSERT_TRUE(v.empty());
}

TEST(ContextualUserModelTest, GeneralizesAfterMultipleContexts) {
  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(ㄉㄚˋ,大)", "ㄒㄧˋ", "係", kFakeNow);
  model.observe("(ㄒㄧㄠˇ,小)", "ㄒㄧˋ", "係", kFakeNow);

  // Confirmed in two distinct contexts, the candidate now generalizes to a
  // context it has never been seen in.
  auto v = model.suggest("(ㄓㄨㄥ,中)", "ㄒㄧˋ", kFakeNow);
  ASSERT_EQ(v.candidate, "係");
  // Continuation-level suggestions are never force-boosted.
  ASSERT_FALSE(v.forceHighScoreOverride);
}

TEST(ContextualUserModelTest, ExactContextBeatsContinuation) {
  ContextualUserModel model(kCapacity, kHalfLife);
  // "戲" generalizes from two contexts...
  model.observe("(ㄉㄚˋ,大)", "ㄒㄧˋ", "戲", kFakeNow);
  model.observe("(ㄒㄧㄠˇ,小)", "ㄒㄧˋ", "戲", kFakeNow);
  // ...but in this specific context the user picked "係".
  model.observe("(ㄍㄨㄢ,關)", "ㄒㄧˋ", "係", kFakeNow);

  auto v = model.suggest("(ㄍㄨㄢ,關)", "ㄒㄧˋ", kFakeNow);
  ASSERT_EQ(v.candidate, "係");

  v = model.suggest("(ㄉㄚˋ,大)", "ㄒㄧˋ", kFakeNow);
  ASSERT_EQ(v.candidate, "戲");
}

TEST(ContextualUserModelTest, TemporalDecay) {
  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(ㄒㄧㄣ,心)", "ㄒㄧˋ", "係", kFakeNow);

  auto v = model.suggest("(ㄒㄧㄣ,心)", "ㄒㄧˋ", kFakeNow + kHalfLife);
  ASSERT_EQ(v.candidate, "係");

  // A single observation fully decays out after a few half-lives.
  v = model.suggest("(ㄒㄧㄣ,心)", "ㄒㄧˋ", kFakeNow + kHalfLife * 4);
  ASSERT_TRUE(v.empty());

  // Repeated confirmation accumulates evidence and survives much longer.
  for (int i = 0; i < 8; i++) {
    model.observe("(ㄒㄧㄣ,心)", "ㄒㄧˋ", "係", kFakeNow);
  }
  v = model.suggest("(ㄒㄧㄣ,心)", "ㄒㄧˋ", kFakeNow + kHalfLife * 4);
  ASSERT_EQ(v.candidate, "係");
}

TEST(ContextualUserModelTest, ForceHighScoreOverrideIsRemembered) {
  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(ㄗㄥ,增)", "ㄗˋ-ㄏㄨㄟˋ", "字彙", kFakeNow,
                /*forceHighScoreOverride=*/true);

  auto v = model.suggest("(ㄗㄥ,增)", "ㄗˋ-ㄏㄨㄟˋ", kFakeNow);
  ASSERT_EQ(v.candidate, "字彙");
  ASSERT_TRUE(v.forceHighScoreOverride);
}

TEST(ContextualUserModelTest, RejectsSeparatorCharacters) {
  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(a,b)\t", "r", "c", kFakeNow);
  model.observe("(a,b)", "r\n", "c", kFakeNow);
  model.observe("(a,b)", "r", "c\td", kFakeNow);
  ASSERT_EQ(model.entryCount(), 0);
}

TEST(ContextualUserModelTest, CapacityEviction) {
  ContextualUserModel model(2, kHalfLife);
  model.observe("(a,A)", "r1", "c1", kFakeNow);
  model.observe("(b,B)", "r2", "c2", kFakeNow + 1);
  model.observe("(c,C)", "r3", "c3", kFakeNow + 2);
  ASSERT_EQ(model.entryCount(), 2);

  // The least recently used entry is gone.
  ASSERT_TRUE(model.suggest("(a,A)", "r1", kFakeNow + 3).empty());
  ASSERT_EQ(model.suggest("(c,C)", "r3", kFakeNow + 3).candidate, "c3");
}

TEST(ContextualUserModelTest, PersistenceRoundTrip) {
  std::string path = TempFilePath("contextual_user_model_roundtrip.txt");

  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(ㄒㄧㄣ,心)", "ㄒㄧˋ", "係", kFakeNow);
  model.observe("(ㄗㄥ,增)", "ㄗˋ-ㄏㄨㄟˋ", "字彙", kFakeNow,
                /*forceHighScoreOverride=*/true);
  ASSERT_TRUE(model.saveToFile(path));

  ContextualUserModel restored(kCapacity, kHalfLife);
  auto stats = restored.loadFromFile(path);
  ASSERT_TRUE(stats.has_value());
  ASSERT_EQ(stats->loaded, 2);
  ASSERT_EQ(stats->skipped, 0);

  auto v = restored.suggest("(ㄒㄧㄣ,心)", "ㄒㄧˋ", kFakeNow);
  ASSERT_EQ(v.candidate, "係");
  v = restored.suggest("(ㄗㄥ,增)", "ㄗˋ-ㄏㄨㄟˋ", kFakeNow);
  ASSERT_EQ(v.candidate, "字彙");
  ASSERT_TRUE(v.forceHighScoreOverride);

  std::remove(path.c_str());
}

TEST(ContextualUserModelTest, LoadSkipsMalformedLines) {
  std::string path = TempFilePath("contextual_user_model_malformed.txt");
  {
    std::ofstream file(path, std::ios::trunc);
    file << "# mcbopomofo-contextual-user-model v1\n";
    file << "(a,A)\tr1\tc1\t1.0\t" << kFakeNow << "\t0\n";   // good
    file << "(b,B)\tr2\tc2\t1.0\n";                          // missing fields
    file << "(c,C)\tr3\tc3\tnan\t" << kFakeNow << "\t0\n";   // NaN count
    file << "(d,D)\tr4\tc4\tinf\t" << kFakeNow << "\t0\n";   // Inf count
    file << "(e,E)\tr5\tc5\t-1.0\t" << kFakeNow << "\t0\n";  // negative count
    file << "(f,F)\tr6\tc6\t1.0\t" << kFakeNow << "\t2\n";   // bad force flag
    file << "(g,G)\tr7\tc7\t1.0\tabc\t0\n";                  // bad timestamp
  }

  ContextualUserModel model(kCapacity, kHalfLife);
  auto stats = model.loadFromFile(path);
  ASSERT_TRUE(stats.has_value());
  ASSERT_EQ(stats->loaded, 1);
  ASSERT_EQ(stats->skipped, 6);
  ASSERT_EQ(model.suggest("(a,A)", "r1", kFakeNow).candidate, "c1");

  std::remove(path.c_str());
}

TEST(ContextualUserModelTest, SerializeMatchesSavedFile) {
  std::string path = TempFilePath("contextual_user_model_serialize.txt");

  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(ㄒㄧㄣ,心)", "ㄒㄧˋ", "係", kFakeNow);
  ASSERT_TRUE(model.saveToFile(path));

  std::ifstream file(path);
  std::string fileContents((std::istreambuf_iterator<char>(file)),
                           std::istreambuf_iterator<char>());
  ASSERT_EQ(model.serialize(), fileContents);

  std::remove(path.c_str());
}

TEST(ContextualUserModelTest, LoadReturnsNulloptForMissingFile) {
  ContextualUserModel model(kCapacity, kHalfLife);
  model.observe("(a,A)", "r1", "c1", kFakeNow);
  auto stats =
      model.loadFromFile(TempFilePath("contextual_user_model_no_such_file"));
  ASSERT_FALSE(stats.has_value());
  // A failed load leaves the current state untouched.
  ASSERT_EQ(model.entryCount(), 1);
}

namespace {

// A small language model for walk-based tests. The data deliberately scores
// 戲 above 係 so that only a user-model override can produce 係.
class TinyLM : public Formosa::Gramambular2::LanguageModel {
 public:
  TinyLM() {
    db_["ㄍㄨㄢ"] = {{"關", -5.0}};
    db_["ㄒㄧˋ"] = {{"戲", -5.0}, {"係", -6.0}};
  }

  std::vector<Unigram> getUnigrams(const std::string& reading) override {
    auto it = db_.find(reading);
    if (it == db_.end()) {
      return {};
    }
    std::vector<Unigram> result;
    for (const auto& [value, score] : it->second) {
      result.emplace_back(value, score);
    }
    return result;
  }

  bool hasUnigrams(const std::string& reading) override {
    return db_.find(reading) != db_.end();
  }

 private:
  std::map<std::string, std::vector<std::pair<std::string, double>>> db_;
};

}  // namespace

TEST(ContextualUserModelTest, WalkBasedObserveAndSuggest) {
  using Formosa::Gramambular2::ReadingGrid;

  ContextualUserModel model(kCapacity, kHalfLife);

  // The user types 關係 and overrides the default 戲 with 係.
  ReadingGrid grid(std::make_shared<TinyLM>());
  grid.insertReading("ㄍㄨㄢ");
  grid.insertReading("ㄒㄧˋ");
  ReadingGrid::WalkResult walkBefore = grid.walk();
  ASSERT_EQ(walkBefore.nodes.size(), 2);
  ASSERT_EQ(walkBefore.nodes[1]->value(), "戲");

  ASSERT_TRUE(grid.overrideCandidate(
      1, "係", ReadingGrid::Node::OverrideType::kOverrideValueWithHighScore));
  ReadingGrid::WalkResult walkAfter = grid.walk();
  ASSERT_EQ(walkAfter.nodes[1]->value(), "係");

  model.observe(walkBefore, walkAfter, 1, kFakeNow);

  // Later, the user types the same input again. The model suggests the
  // learned candidate for the node at the cursor.
  ReadingGrid grid2(std::make_shared<TinyLM>());
  grid2.insertReading("ㄍㄨㄢ");
  grid2.insertReading("ㄒㄧˋ");
  ReadingGrid::WalkResult freshWalk = grid2.walk();
  ASSERT_EQ(freshWalk.nodes[1]->value(), "戲");

  auto v = model.suggest(freshWalk, 1, kFakeNow + 60);
  ASSERT_EQ(v.candidate, "係");
}

}  // namespace McBopomofo
