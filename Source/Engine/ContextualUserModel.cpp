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

#include "ContextualUserModel.h"

#include <cmath>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

namespace McBopomofo {

namespace {

constexpr char kFileHeader[] = "# mcbopomofo-contextual-user-model v1";

// A candidate generalizes to an unseen context only after it has been
// confirmed in at least this many distinct contexts.
constexpr size_t kMinContextsForGeneralization = 2;

// Decayed evidence below this is treated as absent so that stale entries
// stop producing suggestions.
constexpr double kMinSuggestionProbability = 0.25;

std::string CombineReadingValue(const std::string& reading,
                                const std::string& value) {
  return std::string("(") + reading + "," + value + ")";
}

bool IsPunctuation(const Formosa::Gramambular2::ReadingGrid::NodePtr& node) {
  const std::string& reading = node->reading();
  return !reading.empty() && reading[0] == '_';
}

bool ContainsSeparator(const std::string& s) {
  return s.find('\t') != std::string::npos ||
         s.find('\n') != std::string::npos || s.find('\r') != std::string::npos;
}

// The context marker for the node preceding `it` in a walk, or kStartContext
// if there is none or it is punctuation.
std::string ContextBefore(
    const std::vector<Formosa::Gramambular2::ReadingGrid::NodePtr>& nodes,
    std::vector<Formosa::Gramambular2::ReadingGrid::NodePtr>::const_iterator
        it) {
  if (it == nodes.cbegin()) {
    return ContextualUserModel::kStartContext;
  }
  --it;
  if (IsPunctuation(*it)) {
    return ContextualUserModel::kStartContext;
  }
  return CombineReadingValue((*it)->reading(), (*it)->currentUnigram().value());
}

std::vector<std::string> SplitByTab(const std::string& line) {
  std::vector<std::string> fields;
  size_t start = 0;
  while (true) {
    size_t pos = line.find('\t', start);
    if (pos == std::string::npos) {
      fields.push_back(line.substr(start));
      break;
    }
    fields.push_back(line.substr(start, pos - start));
    start = pos + 1;
  }
  return fields;
}

bool ParseFiniteDouble(const std::string& s, double* out) {
  if (s.empty()) {
    return false;
  }
  try {
    size_t consumed = 0;
    double value = std::stod(s, &consumed);
    if (consumed != s.size() || !std::isfinite(value)) {
      return false;
    }
    *out = value;
    return true;
  } catch (...) {
    return false;
  }
}

}  // namespace

ContextualUserModel::ContextualUserModel(size_t capacity,
                                         double decayHalfLifeSeconds)
    : capacity_(capacity > 0 ? capacity : kDefaultCapacity),
      decayHalfLifeSeconds_(decayHalfLifeSeconds > 0
                                ? decayHalfLifeSeconds
                                : kDefaultDecayHalfLifeSeconds) {}

double ContextualUserModel::decayedCount(const CandidateStats& stats,
                                         double timestamp) const {
  double elapsed = timestamp - stats.timestamp;
  if (elapsed <= 0) {
    return stats.count;
  }
  return stats.count * std::exp2(-elapsed / decayHalfLifeSeconds_);
}

void ContextualUserModel::observe(
    const Formosa::Gramambular2::ReadingGrid::WalkResult&
        walkBeforeUserOverride,
    const Formosa::Gramambular2::ReadingGrid::WalkResult& walkAfterUserOverride,
    size_t cursor, double timestamp) {
  if (walkBeforeUserOverride.totalReadings !=
      walkAfterUserOverride.totalReadings) {
    return;
  }

  size_t actualCursor = 0;
  auto currentNodeIt = walkAfterUserOverride.findNodeAt(cursor, &actualCursor);
  if (currentNodeIt == walkAfterUserOverride.nodes.cend()) {
    return;
  }

  // Same cutoff as UserOverrideModel: learning phrases longer than 3
  // characters was found to be meaningless.
  if ((*currentNodeIt)->spanningLength() > 3) {
    return;
  }

  if (actualCursor == 0) {
    return;
  }
  --actualCursor;
  auto prevHeadNodeIt = walkBeforeUserOverride.findNodeAt(actualCursor);
  if (prevHeadNodeIt == walkBeforeUserOverride.nodes.cend()) {
    return;
  }

  // The same three cases UserOverrideModel distinguishes. When the user
  // breaks a longer phrase into a 1-character candidate, the observation is
  // based on the walk after the override and must not be force-boosted;
  // when the user builds a longer phrase out of shorter nodes, the
  // suggestion must be force-boosted to beat the individually higher-scored
  // characters.
  const auto& currentNode = *currentNodeIt;
  const auto& prevHeadNode = *prevHeadNodeIt;
  bool forceHighScoreOverride =
      currentNode->spanningLength() > prevHeadNode->spanningLength();
  bool breakingUp =
      currentNode->spanningLength() == 1 && prevHeadNode->spanningLength() > 1;

  const auto& contextWalk =
      breakingUp ? walkAfterUserOverride : walkBeforeUserOverride;
  auto headIt = breakingUp ? currentNodeIt : prevHeadNodeIt;

  std::string context = ContextBefore(contextWalk.nodes, headIt);
  observe(context, (*headIt)->reading(), currentNode->currentUnigram().value(),
          timestamp, forceHighScoreOverride);
}

ContextualUserModel::Suggestion ContextualUserModel::suggest(
    const Formosa::Gramambular2::ReadingGrid::WalkResult& currentWalk,
    size_t cursor, double timestamp) const {
  auto nodeIter = currentWalk.findNodeAt(cursor);
  if (nodeIter == currentWalk.nodes.cend()) {
    return {};
  }
  std::string context = ContextBefore(currentWalk.nodes, nodeIter);
  return suggest(context, (*nodeIter)->reading(), timestamp);
}

void ContextualUserModel::observe(const std::string& context,
                                  const std::string& reading,
                                  const std::string& candidate,
                                  double timestamp,
                                  bool forceHighScoreOverride) {
  if (reading.empty() || candidate.empty() || context.empty()) {
    return;
  }
  if (ContainsSeparator(context) || ContainsSeparator(reading) ||
      ContainsSeparator(candidate)) {
    return;
  }

  std::string key = context + "\t" + reading;
  CandidateMap entry;
  auto mapIter = lruMap_.find(key);
  if (mapIter != lruMap_.end()) {
    entry = mapIter->second->second;
  }

  CandidateStats& stats = entry[candidate];
  stats.count = decayedCount(stats, timestamp) + 1.0;
  stats.timestamp = timestamp;
  stats.forceHighScoreOverride = forceHighScoreOverride;

  touch(key, std::move(entry));
}

ContextualUserModel::Suggestion ContextualUserModel::suggest(
    const std::string& context, const std::string& reading,
    double timestamp) const {
  std::string key = context + "\t" + reading;

  Continuation continuation = continuationFor(reading);
  auto continuationProbability = [&](const std::string& candidate) {
    if (continuation.totalContexts == 0) {
      return 0.0;
    }
    auto it = continuation.contextsPerCandidate.find(candidate);
    if (it == continuation.contextsPerCandidate.end()) {
      return 0.0;
    }
    return static_cast<double>(it->second) /
           static_cast<double>(continuation.totalContexts);
  };

  std::string bestCandidate;
  double bestProbability = 0;
  bool bestForce = false;

  auto mapIter = lruMap_.find(key);
  if (mapIter != lruMap_.end()) {
    const CandidateMap& entry = mapIter->second->second;
    double total = 0;
    size_t types = 0;
    for (const auto& [candidate, stats] : entry) {
      double count = decayedCount(stats, timestamp);
      if (count > 0) {
        total += count;
        ++types;
      }
    }

    // Absolute discounting only makes sense while there is at least one
    // discount's worth of evidence; below that, decayed-out entries fall
    // through to the continuation level.
    if (total >= kDiscount && types > 0) {
      double lambda = kDiscount * static_cast<double>(types) / total;
      for (const auto& [candidate, stats] : entry) {
        double count = decayedCount(stats, timestamp);
        if (count <= 0) {
          continue;
        }
        double probability = std::max(count - kDiscount, 0.0) / total +
                             lambda * continuationProbability(candidate);
        if (probability > bestProbability) {
          bestProbability = probability;
          bestCandidate = candidate;
          bestForce = stats.forceHighScoreOverride;
        }
      }
    }
  }

  if (bestCandidate.empty()) {
    // No usable evidence in this exact context: generalize through the
    // continuation level, but only for candidates confirmed in enough
    // distinct contexts. Suggestions from this level are never
    // force-boosted.
    for (const auto& [candidate, contexts] :
         continuation.contextsPerCandidate) {
      if (contexts < kMinContextsForGeneralization) {
        continue;
      }
      double probability = continuationProbability(candidate);
      if (probability > bestProbability) {
        bestProbability = probability;
        bestCandidate = candidate;
        bestForce = false;
      }
    }
  }

  if (bestCandidate.empty() || bestProbability < kMinSuggestionProbability) {
    return {};
  }
  return {bestCandidate, bestForce};
}

ContextualUserModel::Continuation ContextualUserModel::continuationFor(
    const std::string& reading) const {
  Continuation result;
  std::string suffix = "\t" + reading;
  for (const auto& [key, entry] : lruList_) {
    if (key.size() < suffix.size() ||
        key.compare(key.size() - suffix.size(), suffix.size(), suffix) != 0) {
      continue;
    }
    for (const auto& [candidate, stats] : entry) {
      if (stats.count > 0) {
        ++result.contextsPerCandidate[candidate];
        ++result.totalContexts;
      }
    }
  }
  return result;
}

void ContextualUserModel::touch(const std::string& key, CandidateMap entry) {
  auto mapIter = lruMap_.find(key);
  if (mapIter != lruMap_.end()) {
    lruList_.erase(mapIter->second);
    lruMap_.erase(mapIter);
  }

  lruList_.emplace_front(key, std::move(entry));
  lruMap_[key] = lruList_.begin();

  while (lruList_.size() > capacity_) {
    lruMap_.erase(lruList_.back().first);
    lruList_.pop_back();
  }
}

std::optional<ContextualUserModel::LoadStats> ContextualUserModel::loadFromFile(
    const std::string& path) {
  std::ifstream file(path);
  if (!file.is_open()) {
    return std::nullopt;
  }

  LoadStats stats;
  std::list<KeyEntryPair> newList;
  std::map<std::string, std::list<KeyEntryPair>::iterator> newMap;

  std::string line;
  while (std::getline(file, line)) {
    if (line.empty() || line[0] == '#') {
      continue;
    }
    std::vector<std::string> fields = SplitByTab(line);
    if (fields.size() != 6) {
      ++stats.skipped;
      continue;
    }
    const std::string& context = fields[0];
    const std::string& reading = fields[1];
    const std::string& candidate = fields[2];
    double count = 0;
    double timestamp = 0;
    if (context.empty() || reading.empty() || candidate.empty() ||
        !ParseFiniteDouble(fields[3], &count) || count <= 0 ||
        !ParseFiniteDouble(fields[4], &timestamp) || timestamp < 0 ||
        (fields[5] != "0" && fields[5] != "1")) {
      ++stats.skipped;
      continue;
    }

    std::string key = context + "\t" + reading;
    auto mapIter = newMap.find(key);
    if (mapIter == newMap.end()) {
      newList.emplace_front(key, CandidateMap());
      mapIter = newMap.emplace(key, newList.begin()).first;
    } else {
      // Move to the front so that later lines (saved most-recent-last) end
      // up as the most recently used.
      newList.splice(newList.begin(), newList, mapIter->second);
    }
    CandidateStats& candidateStats = mapIter->second->second[candidate];
    candidateStats.count = count;
    candidateStats.timestamp = timestamp;
    candidateStats.forceHighScoreOverride = fields[5] == "1";
    ++stats.loaded;
  }

  while (newList.size() > capacity_) {
    newMap.erase(newList.back().first);
    newList.pop_back();
  }

  lruList_ = std::move(newList);
  lruMap_ = std::move(newMap);
  return stats;
}

std::string ContextualUserModel::serialize() const {
  std::ostringstream out;
  out << kFileHeader << "\n";
  // Least recently used first, so that loading restores the same order.
  for (auto it = lruList_.crbegin(); it != lruList_.crend(); ++it) {
    std::vector<std::string> parts = SplitByTab(it->first);
    const std::string& context = parts[0];
    const std::string& reading = parts[1];
    for (const auto& [candidate, stats] : it->second) {
      out << context << "\t" << reading << "\t" << candidate << "\t"
          << stats.count << "\t" << stats.timestamp << "\t"
          << (stats.forceHighScoreOverride ? "1" : "0") << "\n";
    }
  }
  return out.str();
}

bool ContextualUserModel::saveToFile(const std::string& path) const {
  std::string tmpPath = path + ".tmp";
  {
    std::ofstream file(tmpPath, std::ios::trunc);
    if (!file.is_open()) {
      return false;
    }
    file << serialize();
    file.flush();
    if (!file.good()) {
      file.close();
      std::remove(tmpPath.c_str());
      return false;
    }
  }
  if (std::rename(tmpPath.c_str(), path.c_str()) != 0) {
    std::remove(tmpPath.c_str());
    return false;
  }
  return true;
}

}  // namespace McBopomofo
