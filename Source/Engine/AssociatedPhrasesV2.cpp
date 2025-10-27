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

#include "AssociatedPhrasesV2.h"

#include <algorithm>
#include <cstdlib>
#include <limits>
#include <memory>
#include <sstream>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

#include "UTF8Helper.h"

namespace McBopomofo {

static constexpr char kSeparatorChar = '-';

namespace {
enum class RowParseState { kParsingValue, kParsingReading };
}  // namespace

// Find the score in a string of the form /^(.+?)\s((-?)\d+(\.?)\d+)$/.
static double GetScoreInRow(const std::string_view& v) {
  const auto* it = v.cbegin();
  const auto* end = v.cend();

  while (it != end) {
    if (*it == ' ') {
      ++it;
      break;
    }
    ++it;
  }

  if (it == end) {
    return std::numeric_limits<double>::lowest();
  }

  return std::stod(std::string(it, end));
}

// Parse an associated phrases entry to the Phrase struct.
static AssociatedPhrasesV2::Phrase PhraseFromRow(const std::string_view& v) {
  const auto* it = v.cbegin();
  const auto* end = v.cend();

  std::stringstream sst;
  std::vector<std::string> readings;

  RowParseState state = RowParseState::kParsingValue;
  const auto* prev = it;
  while (it != end) {
    if (*it == ' ' || *it == kSeparatorChar) {
      switch (state) {
        case RowParseState::kParsingValue:
          // Switch to parsing readings.
          state = RowParseState::kParsingReading;
          sst << std::string{prev, it};
          break;
        case RowParseState::kParsingReading:
          // Switch to parsing values.
          state = RowParseState::kParsingValue;
          readings.emplace_back(std::string{prev, it});
          break;
      }

      if (*it == ' ') {
        break;
      }

      prev = ++it;
      continue;
    }

    ++it;
  }

  return {sst.str(), readings};
}

AssociatedPhrasesV2::~AssociatedPhrasesV2() { close(); }

bool AssociatedPhrasesV2::open(const char* path) {
  if (db_ != nullptr) {
    return false;
  }

  bool result = mmapedFile_.open(path);
  if (!result) {
    return false;
  }

  db_ = std::make_unique<ParselessPhraseDB>(
      mmapedFile_.data(), mmapedFile_.length(), /*validate_pragma=*/true);
  return true;
}

void AssociatedPhrasesV2::close() {
  db_ = nullptr;
  mmapedFile_.close();
}

bool AssociatedPhrasesV2::isLoaded() const { return db_ != nullptr; }

bool AssociatedPhrasesV2::open(std::unique_ptr<ParselessPhraseDB> db) {
  if (db_ != nullptr) {
    return false;
  }

  db_ = std::move(db);
  return true;
}

std::vector<AssociatedPhrasesV2::Phrase> AssociatedPhrasesV2::findPhrases(
    const std::string& prefixValue,
    const std::vector<std::string>& prefixReadings) const {
  if (prefixValue.empty()) {
    return {};
  }

  if (prefixReadings.empty()) {
    std::string internalPrefix = prefixValue + kSeparatorChar;
    return findPhrases(internalPrefix);
  }

  std::vector<std::string> values = Split(prefixValue);
  if (values.size() != prefixReadings.size()) {
    return {};
  }

  std::stringstream sst;
  for (size_t i = 0, s = values.size(); i < s; ++i) {
    sst << values[i];
    sst << kSeparatorChar;
    sst << prefixReadings[i];
    sst << kSeparatorChar;
  }
  return findPhrases(sst.str());
}

std::vector<AssociatedPhrasesV2::Phrase> AssociatedPhrasesV2::findPhrases(
    const std::string& internalPrefix) const {
  if (db_ == nullptr) {
    return {};
  }

  std::vector<std::string_view> matchingRows = db_->findRows(internalPrefix);
  if (matchingRows.empty()) {
    return {};
  }

  using RowScorePair = std::pair<std::string_view, double>;

  std::vector<RowScorePair> scoredRows;
  for (const auto& strviews : matchingRows) {
    scoredRows.emplace_back(strviews, GetScoreInRow(strviews));
  }

  std::stable_sort(
      scoredRows.begin(), scoredRows.end(),
      [](const auto& r1, const auto& r2) { return r1.second > r2.second; });

  // Dedup the phrases with the same value. Since the vector is now ranked,
  // higher-ranking values will be retained.
  std::unordered_set<std::string> dedupSet;
  std::vector<AssociatedPhrasesV2::Phrase> phrases;
  for (const auto& rspair : scoredRows) {
    Phrase p = PhraseFromRow(rspair.first);
    if (dedupSet.find(p.value) != dedupSet.cend()) {
      continue;
    }
    dedupSet.insert(p.value);
    phrases.emplace_back(std::move(p));
  }
  return phrases;
}

std::string AssociatedPhrasesV2::Phrase::combinedReading() const {
  return CombineReadings(readings);
}

std::vector<std::string> AssociatedPhrasesV2::SplitReadings(
    const std::string& combinedReading) {
  std::vector<std::string> readings;
  if (combinedReading.empty()) {
    return readings;
  }

  auto it = combinedReading.cbegin();
  auto end = combinedReading.cend();

  auto prev = it;

  while (it != end) {
    if (*it == kSeparatorChar) {
      readings.emplace_back(std::string(prev, it));
      prev = ++it;
      continue;
    }
    ++it;
  }
  readings.emplace_back(std::string(prev, it));

  return readings;
}

std::string AssociatedPhrasesV2::CombineReadings(
    const std::vector<std::string>& readings) {
  std::stringstream sst;
  for (size_t i = 0, s = readings.size(); i < s; ++i) {
    sst << readings[i];
    if (i + 1 < s) {
      sst << kSeparatorChar;
    }
  }
  return sst.str();
}

}  // namespace McBopomofo
