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

TEST(UserPhrasesLMTest, LenientReading)
{
    std::string tmp_name
        = std::string(std::filesystem::temp_directory_path() / "test.txt");

    FILE* f = fopen(tmp_name.c_str(), "w");
    ASSERT_NE(f, nullptr);

    fprintf(f, "value1 reading1\n");
    fprintf(f, "value2 \n"); // error line
    fprintf(f, "value3 reading2\n");
    int r = fclose(f);
    ASSERT_EQ(r, 0);

    UserPhrasesLM lm;
    lm.open(tmp_name.c_str());
    ASSERT_TRUE(lm.hasUnigrams("reading1"));
    ASSERT_FALSE(lm.hasUnigrams("value2"));

    // Anything after the error won't be parsed, so reading2 won't be found.
    ASSERT_FALSE(lm.hasUnigrams("reading2"));

    r = remove(tmp_name.c_str());
    ASSERT_EQ(r, 0);
}

} // namespace McBopomofo
