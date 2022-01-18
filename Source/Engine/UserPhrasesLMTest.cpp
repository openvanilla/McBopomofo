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

TEST(UserPhreasesLMTest, LenientReading)
{
    std::string tmp_name
        = std::string(std::filesystem::temp_directory_path()) + "test.txt";

    FILE* f = fopen(tmp_name.c_str(), "w");
    ASSERT_NE(f, nullptr);

    fprintf(f, "bar foo\n");
    fprintf(f, "bar \n"); // error line
    fprintf(f, "argh baz\n");
    int r = fclose(f);
    ASSERT_EQ(r, 0);

    UserPhrasesLM lm;
    lm.open(tmp_name.c_str());
    ASSERT_TRUE(lm.hasUnigramsForKey("foo"));
    ASSERT_FALSE(lm.hasUnigramsForKey("bar"));
    ASSERT_FALSE(lm.hasUnigramsForKey("baz"));

    r = remove(tmp_name.c_str());
    ASSERT_EQ(r, 0);
}

} // namespace McBopomofo
