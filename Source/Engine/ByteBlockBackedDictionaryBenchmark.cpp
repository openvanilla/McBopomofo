// Copyright (c) 2025 and onwards The McBopomofo Authors.
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

#include <sstream>
#include <string>

#include "ByteBlockBackedDictionary.h"

namespace {

const std::string& GetTestData() {
  static const std::string data = []() {
    std::stringstream sst;

    constexpr int keys = 1024;
    constexpr int values = 128;

    for (int k = 0; k < keys; ++k) {
      int nSpace = k / 128 + 1;
      std::string space(nSpace, ' ');

      std::string keyString = "first_" + std::to_string(k) + space;
      for (int v = 0; v < values; ++v) {
        sst << keyString;
        sst << "second_" << v;
        sst << "\n";
      }

      if ((k % 16) == 0) {
        sst << space << "# comment_" << k << "\n";
      }
    }
    return sst.str();
  }();
  return data;
}

void BM_ByteBlockBackedDictionaryParseTest(benchmark::State& state) {
  const std::string& testData = GetTestData();

  for (auto _ : state) {
    McBopomofo::ByteBlockBackedDictionary dictionary;
    dictionary.parse(testData.c_str(), testData.size());
  }
}
BENCHMARK(BM_ByteBlockBackedDictionaryParseTest);

void BM_ByteBlockBackedDictionaryValueColumnFirstParseTest(
    benchmark::State& state) {
  const std::string& testData = GetTestData();

  for (auto _ : state) {
    McBopomofo::ByteBlockBackedDictionary dictionary;
    dictionary.parse(
        testData.c_str(), testData.size(),
        McBopomofo::ByteBlockBackedDictionary::ColumnOrder::VALUE_THEN_KEY);
  }
}
BENCHMARK(BM_ByteBlockBackedDictionaryValueColumnFirstParseTest);

};  // namespace

BENCHMARK_MAIN();
