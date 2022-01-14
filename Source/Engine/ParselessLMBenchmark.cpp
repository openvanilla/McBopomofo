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

#include "FastLM.h"
#include "ParselessLM.h"

namespace {

using FastLM = Formosa::Gramambular::FastLM;
using ParselessLM = McBopomofo::ParselessLM;

static const char* kDataPath = "data.txt";
static const char* kLegacyDataPath = "data-legacy.txt";
static const char* kUnigramSearchKey = "ㄕˋ-ㄕˊ";

static void BM_ParselessLMOpenClose(benchmark::State& state)
{
    assert(std::filesystem::exists(kDataPath));
    for (auto _ : state) {
        ParselessLM lm;
        lm.open(kDataPath);
        lm.close();
    }
}
BENCHMARK(BM_ParselessLMOpenClose);

static void BM_FastLMOpenClose(benchmark::State& state)
{
    assert(std::filesystem::exists(kLegacyDataPath));
    for (auto _ : state) {
        FastLM lm;
        lm.open(kLegacyDataPath);
        lm.close();
    }
}
BENCHMARK(BM_FastLMOpenClose);

static void BM_ParselessLMFindUnigrams(benchmark::State& state)
{
    assert(std::filesystem::exists(kDataPath));
    ParselessLM lm;
    lm.open(kDataPath);
    for (auto _ : state) {
        lm.unigramsForKey(kUnigramSearchKey);
    }
    lm.close();
}
BENCHMARK(BM_ParselessLMFindUnigrams);

static void BM_FastLMFindUnigrams(benchmark::State& state)
{
    assert(std::filesystem::exists(kLegacyDataPath));
    FastLM lm;
    lm.open(kLegacyDataPath);
    for (auto _ : state) {
        lm.unigramsForKey(kUnigramSearchKey);
    }
    lm.close();
}
BENCHMARK(BM_FastLMFindUnigrams);

}; // namespace

BENCHMARK_MAIN();
