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

#include <cstdio>
#include <filesystem>
#include <string>

#include "UserPhrasesLM.h"
#include "gtest/gtest.h"

namespace McBopomofo {

TEST(UserPhrasesLMTest, LenientReading) {
  constexpr char kTestData[] = "value1 reading1\nvalue2 \nvalue3 reading2";

  UserPhrasesLM lm;
  ASSERT_TRUE(lm.load(kTestData, sizeof(kTestData)));
  EXPECT_TRUE(lm.hasUnigrams("reading1"));
  EXPECT_FALSE(lm.hasUnigrams("value2"));

  // Anything after the error won't be parsed, so reading2 won't be found.
  EXPECT_FALSE(lm.hasUnigrams("reading2"));

  std::vector<Formosa::Gramambular2::LanguageModel::Unigram> results =
      lm.getUnigrams("reading1");
  EXPECT_EQ(results[0].value(), "value1");
  EXPECT_EQ(results[0].score(), UserPhrasesLM::kUserUnigramScore);
}

}  // namespace McBopomofo
