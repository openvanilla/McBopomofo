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

#include <filesystem>
#include <iostream>

#include "ParselessLM.h"
#include "gtest/gtest.h"

namespace McBopomofo {

TEST(ParselessLMTest, SanityCheckTest)
{
    constexpr const char* data_path = "data.txt";
    if (!std::filesystem::exists(data_path)) {
        GTEST_SKIP();
    }

    ParselessLM lm;
    bool status = lm.open(data_path);
    ASSERT_TRUE(status);

    ASSERT_TRUE(lm.hasUnigramsForKey("ㄕ"));
    ASSERT_TRUE(lm.hasUnigramsForKey("ㄕˋ-ㄕˊ"));
    ASSERT_TRUE(lm.hasUnigramsForKey("_punctuation_list"));

    auto unigrams = lm.unigramsForKey("ㄕ");
    ASSERT_GT(unigrams.size(), 0);

    unigrams = lm.unigramsForKey("ㄕˋ-ㄕˊ");
    ASSERT_GT(unigrams.size(), 0);

    unigrams = lm.unigramsForKey("_punctuation_list");
    ASSERT_GT(unigrams.size(), 0);

    lm.close();
}

}; // namespace McBopomofo
