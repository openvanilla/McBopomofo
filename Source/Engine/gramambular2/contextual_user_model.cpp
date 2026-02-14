// Copyright (c) 2022 and onwards Lukhnos Liu.
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

#include "contextual_user_model.h"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <limits>
#include <sstream>

namespace Formosa::Gramambular2 {

double ContextualUserModel::decayFactor(double elapsed) const {
  if (elapsed <= 0.0) return 1.0;
  return std::exp(-std::log(2.0) * elapsed / decayHalfLife_);
}

void ContextualUserModel::observe(const std::string& leftReading,
                                  const std::string& leftValue,
                                  const std::string& currentReading,
                                  const std::string& currentValue,
                                  double timestamp) {
  std::string leftKey = leftReading + ":" + leftValue;
  BigramKey bkey{leftKey, currentReading};

  auto& candidates = bigrams_[bkey];
  auto it = candidates.find(currentValue);
  if (it == candidates.end()) {
    candidates[currentValue] = {1.0, timestamp};
    totalUniqueBigrams_++;

    continuationCounts_[currentReading][currentValue]++;
  } else {
    double elapsed = timestamp - it->second.lastTimestamp;
    it->second.decayedCount =
        it->second.decayedCount * decayFactor(elapsed) + 1.0;
    it->second.lastTimestamp = timestamp;
  }
}

std::optional<ContextualUserModel::Suggestion> ContextualUserModel::suggest(
    const std::string& leftReading, const std::string& leftValue,
    const std::string& currentReading, double timestamp) const {
  std::string leftKey = leftReading + ":" + leftValue;

  std::map<std::string, double> scores;

  BigramKey bkey{leftKey, currentReading};
  auto bIt = bigrams_.find(bkey);
  if (bIt != bigrams_.end()) {
    for (const auto& [val, obs] : bIt->second) {
      scores[val] = bigramScore(leftKey, currentReading, val, timestamp);
    }
  }

  auto cIt = continuationCounts_.find(currentReading);
  if (cIt != continuationCounts_.end()) {
    for (const auto& [val, cnt] : cIt->second) {
      if (scores.find(val) == scores.end()) {
        scores[val] = bigramScore(leftKey, currentReading, val, timestamp);
      }
    }
  }

  if (scores.empty()) {
    return std::nullopt;
  }

  std::string bestValue;
  double bestScore = -std::numeric_limits<double>::infinity();
  for (const auto& [val, score] : scores) {
    if (score > bestScore) {
      bestScore = score;
      bestValue = val;
    }
  }

  double logScore = bestScore > 0 ? std::log(bestScore) : std::log(kFloorProbability);
  return Suggestion{bestValue, logScore};
}

void ContextualUserModel::addExplicitPhrase(const std::string& reading,
                                            const std::string& value) {
  double initialCount = 1.0 / discount_;
  std::string leftKey = std::string(kStartSentinel) + ":";
  BigramKey bkey{leftKey, reading};
  auto& candidates = bigrams_[bkey];
  if (candidates.find(value) == candidates.end()) {
    candidates[value] = {initialCount, 0.0};
    totalUniqueBigrams_++;
    continuationCounts_[reading][value]++;
  } else {
    candidates[value].decayedCount = initialCount;
  }
}

double ContextualUserModel::bigramScore(const std::string& leftKey,
                                        const std::string& reading,
                                        const std::string& value,
                                        double timestamp) const {
  BigramKey bkey{leftKey, reading};
  double c = getDecayedCount(bkey, value, timestamp);
  double cTotal = getDecayedContextTotal(bkey, timestamp);

  if (cTotal < discount_) {
    return continuationScore(reading, value);
  }

  double discounted = std::max(c - discount_, 0.0) / cTotal;
  double lambda =
      discount_ * static_cast<double>(getTypeCount(bkey)) / cTotal;
  return discounted + lambda * continuationScore(reading, value);
}

double ContextualUserModel::continuationScore(const std::string& reading,
                                              const std::string& value) const {
  double nPlus =
      static_cast<double>(getContinuationCount(reading, value));
  if (totalUniqueBigrams_ == 0) {
    return baseScore(reading, value);
  }

  double total = static_cast<double>(totalUniqueBigrams_);
  double discounted = std::max(nPlus - discount_, 0.0) / total;
  double lambda =
      discount_ * static_cast<double>(uniqueWordsForReading(reading)) / total;
  return discounted + lambda * baseScore(reading, value);
}

double ContextualUserModel::baseScore(const std::string& reading,
                                      const std::string& value) const {
  auto unigrams = baseLM_->getUnigrams(reading);
  for (const auto& u : unigrams) {
    if (u.value() == value) {
      return std::exp(u.score());
    }
  }
  return decomposedScore(reading, value);
}

double ContextualUserModel::decomposedScore(const std::string& reading,
                                            const std::string& value) const {
  auto syllables = splitReading(reading);
  auto characters = splitValue(value);
  if (syllables.size() != characters.size() || syllables.empty()) {
    return kFloorProbability;
  }

  double product = 1.0;
  for (size_t i = 0; i < syllables.size(); i++) {
    auto unis = baseLM_->getUnigrams(syllables[i]);
    double charProb = kFloorProbability;
    for (const auto& u : unis) {
      if (u.value() == characters[i]) {
        charProb = std::exp(u.score());
        break;
      }
    }
    product *= charProb;
  }
  return product;
}

double ContextualUserModel::getDecayedCount(const BigramKey& key,
                                            const std::string& value,
                                            double timestamp) const {
  auto bIt = bigrams_.find(key);
  if (bIt == bigrams_.end()) return 0.0;
  auto cIt = bIt->second.find(value);
  if (cIt == bIt->second.end()) return 0.0;
  double elapsed = timestamp - cIt->second.lastTimestamp;
  return cIt->second.decayedCount * decayFactor(elapsed);
}

double ContextualUserModel::getDecayedContextTotal(const BigramKey& key,
                                                   double timestamp) const {
  auto bIt = bigrams_.find(key);
  if (bIt == bigrams_.end()) return 0.0;
  double total = 0.0;
  for (const auto& [val, obs] : bIt->second) {
    double elapsed = timestamp - obs.lastTimestamp;
    total += obs.decayedCount * decayFactor(elapsed);
  }
  return total;
}

size_t ContextualUserModel::getTypeCount(const BigramKey& key) const {
  auto bIt = bigrams_.find(key);
  if (bIt == bigrams_.end()) return 0;
  return bIt->second.size();
}

size_t ContextualUserModel::getContinuationCount(
    const std::string& reading, const std::string& value) const {
  auto rIt = continuationCounts_.find(reading);
  if (rIt == continuationCounts_.end()) return 0;
  auto vIt = rIt->second.find(value);
  if (vIt == rIt->second.end()) return 0;
  return vIt->second;
}

size_t ContextualUserModel::uniqueWordsForReading(
    const std::string& reading) const {
  auto rIt = continuationCounts_.find(reading);
  if (rIt == continuationCounts_.end()) return 0;
  return rIt->second.size();
}

std::vector<std::string> ContextualUserModel::splitReading(
    const std::string& reading) {
  std::vector<std::string> result;
  std::string current;
  for (size_t i = 0; i < reading.size(); ++i) {
    if (reading[i] == '-') {
      if (!current.empty()) {
        result.push_back(current);
        current.clear();
      }
    } else {
      current += reading[i];
    }
  }
  if (!current.empty()) {
    result.push_back(current);
  }
  return result;
}

std::vector<std::string> ContextualUserModel::splitValue(
    const std::string& value) {
  std::vector<std::string> result;
  size_t i = 0;
  while (i < value.size()) {
    unsigned char c = static_cast<unsigned char>(value[i]);
    size_t charLen = 1;
    if (c >= 0xF0) {
      charLen = 4;
    } else if (c >= 0xE0) {
      charLen = 3;
    } else if (c >= 0xC0) {
      charLen = 2;
    }
    if (i + charLen <= value.size()) {
      result.push_back(value.substr(i, charLen));
    }
    i += charLen;
  }
  return result;
}

bool ContextualUserModel::saveToFile(const std::string& path) const {
  std::ofstream out(path);
  if (!out.is_open()) return false;

  for (const auto& [bkey, candidates] : bigrams_) {
    for (const auto& [value, obs] : candidates) {
      out << bkey.first << "\t" << bkey.second << "\t" << value << "\t"
          << obs.decayedCount << "\t" << obs.lastTimestamp << "\n";
    }
  }
  return true;
}

bool ContextualUserModel::loadFromFile(const std::string& path) {
  std::ifstream in(path);
  if (!in.is_open()) return false;

  bigrams_.clear();
  continuationCounts_.clear();
  totalUniqueBigrams_ = 0;

  std::string line;
  while (std::getline(in, line)) {
    if (line.empty() || line[0] == '#') continue;
    std::istringstream iss(line);
    std::string leftKey, reading, value;
    double count, timestamp;
    if (!(iss >> leftKey >> reading >> value >> count >> timestamp)) continue;

    BigramKey bkey{leftKey, reading};
    bigrams_[bkey][value] = {count, timestamp};
    totalUniqueBigrams_++;

    continuationCounts_[reading][value]++;
  }
  return true;
}

}  // namespace Formosa::Gramambular2
