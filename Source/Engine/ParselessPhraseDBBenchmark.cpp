// Copyright (c) 2026 and onwards The McBopomofo Authors.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// modify, merge, publish, distribute, sublicense, and/or sell
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

#include <benchmark/benchmark.h>

#include <iomanip>
#include <random>
#include <sstream>
#include <string>
#include <vector>

#include "ParselessPhraseDB.h"

namespace {

constexpr size_t kRowCount = 65536;
constexpr size_t kQueryCount = 1024;
constexpr int kKeyIndexWidth = 5;
constexpr size_t kMinimumValueLength = 16;
constexpr size_t kMaximumValueLength = 64;

std::string MakeKey(size_t index) {
  std::ostringstream stream;
  stream << "key_" << std::setfill('0') << std::setw(kKeyIndexWidth) << index;
  return stream.str();
}

std::string MakeRows() {
  std::ostringstream stream;
  for (size_t i = 0; i < kRowCount; ++i) {
    const size_t valueLength =
        kMinimumValueLength +
        i % (kMaximumValueLength - kMinimumValueLength + 1);
    stream << MakeKey(i) << ' ' << std::string(valueLength, 'v') << '\n';
  }
  return stream.str();
}

std::vector<std::string> MakeQueryKeys() {
  std::vector<std::string> keys;
  keys.reserve(kQueryCount);

  // Fixed seed so benchmark runs search the same uniformly distributed rows
  std::mt19937 random(std::mt19937::default_seed);
  std::uniform_int_distribution<size_t> rowIndex(0, kRowCount - 1);
  for (size_t i = 0; i < kQueryCount; ++i) {
    keys.emplace_back(MakeKey(rowIndex(random)));
  }
  return keys;
}

class BenchmarkDataset {
 public:
  BenchmarkDataset()
      : rows_(MakeRows()),
        database_(rows_.data(), rows_.size()),
        queryKeys_(MakeQueryKeys()) {}

  const McBopomofo::ParselessPhraseDB& database() const { return database_; }
  const std::vector<std::string>& queryKeys() const { return queryKeys_; }

 private:
  std::string rows_;
  McBopomofo::ParselessPhraseDB database_;
  std::vector<std::string> queryKeys_;
};

void BM_ParselessPhraseDBFindFirstMatchingLine(benchmark::State& state) {
  const BenchmarkDataset dataset;
  const auto& database = dataset.database();
  const auto& queryKeys = dataset.queryKeys();

  auto queryKey = queryKeys.begin();
  for (auto _ : state) {
    benchmark::DoNotOptimize(database.findFirstMatchingLine(*queryKey));
    if (++queryKey == queryKeys.end()) {
      queryKey = queryKeys.begin();
    }
  }
}
BENCHMARK(BM_ParselessPhraseDBFindFirstMatchingLine);

void BM_ParselessPhraseDBReverseFindRows(benchmark::State& state) {
  const BenchmarkDataset dataset;
  const auto& database = dataset.database();

  for (auto _ : state) {
    benchmark::DoNotOptimize(database.reverseFindRows("missing"));
  }
}
BENCHMARK(BM_ParselessPhraseDBReverseFindRows);

}  // namespace

BENCHMARK_MAIN();
