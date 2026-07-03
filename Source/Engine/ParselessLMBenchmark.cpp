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

#include <benchmark/benchmark.h>

#include <cassert>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

#include "ParselessLM.h"

namespace {

using ParselessLM = McBopomofo::ParselessLM;

static const char* kDataPath = "data.txt";
static const char* kUnigramSearchKey = "ㄕˋ-ㄕˊ";

std::vector<std::string> LoadRealKeys() {
  std::ifstream input(kDataPath);
  assert(input.is_open());

  std::vector<std::string> keys;
  std::string line;
  std::getline(input, line);
  while (std::getline(input, line)) {
    const size_t separator = line.find(' ');
    if (separator != std::string::npos) {
      keys.emplace_back(line.substr(0, separator));
    }
  }
  assert(!keys.empty());
  return keys;
}

static void BM_ParselessLMOpenClose(benchmark::State& state) {
  assert(std::filesystem::exists(kDataPath));
  for (auto _ : state) {
    ParselessLM lm;
    lm.open(kDataPath);
    lm.close();
  }
}
BENCHMARK(BM_ParselessLMOpenClose);

static void BM_ParselessLMFindUnigrams(benchmark::State& state) {
  assert(std::filesystem::exists(kDataPath));
  ParselessLM lm;
  lm.open(kDataPath);
  for (auto _ : state) {
    lm.getUnigrams(kUnigramSearchKey);
  }
  lm.close();
}
BENCHMARK(BM_ParselessLMFindUnigrams);

static void BM_ParselessLMHasUnigramsRealKeys(benchmark::State& state) {
  assert(std::filesystem::exists(kDataPath));
  ParselessLM lm;
  lm.open(kDataPath);
  const std::vector<std::string> keys = LoadRealKeys();
  auto key = keys.begin();
  for (auto _ : state) {
    benchmark::DoNotOptimize(lm.hasUnigrams(*key));
    if (++key == keys.end()) {
      key = keys.begin();
    }
  }
  lm.close();
}
BENCHMARK(BM_ParselessLMHasUnigramsRealKeys);

static void BM_ParselessLMFindUnigramsRealKeys(benchmark::State& state) {
  assert(std::filesystem::exists(kDataPath));
  ParselessLM lm;
  lm.open(kDataPath);
  const std::vector<std::string> keys = LoadRealKeys();
  auto key = keys.begin();
  for (auto _ : state) {
    benchmark::DoNotOptimize(lm.getUnigrams(*key));
    if (++key == keys.end()) {
      key = keys.begin();
    }
  }
  lm.close();
}
BENCHMARK(BM_ParselessLMFindUnigramsRealKeys);

static void BM_ParselessLMGetReadingsMissingValue(benchmark::State& state) {
  assert(std::filesystem::exists(kDataPath));
  ParselessLM lm;
  lm.open(kDataPath);
  for (auto _ : state) {
    benchmark::DoNotOptimize(lm.getReadings("missing"));
  }
  lm.close();
}
BENCHMARK(BM_ParselessLMGetReadingsMissingValue);

};  // namespace

BENCHMARK_MAIN();
