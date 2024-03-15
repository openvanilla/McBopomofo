// Copyright (c) 2023 and onwards The McBopomofo Authors.
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

#include <string>

#include "UTF8Helper.h"
#include "gtest/gtest.h"

namespace McBopomofo {

TEST(UTF8HelperTest, CountingAndClampingEmptyString) {
  std::string s;
  ASSERT_EQ(CodePointCount(s), 0);
  ASSERT_EQ(SubstringToCodePoints(s, 0), s);
  ASSERT_EQ(SubstringToCodePoints(s, 1), s);
}

TEST(UTF8HelperTest, CountingAndClampingAsciiStrings) {
  std::string s = "hello, world!";
  ASSERT_EQ(CodePointCount(s), 13);
  ASSERT_EQ(SubstringToCodePoints(s, 0), "");
  ASSERT_EQ(SubstringToCodePoints(s, 5), "hello");
  ASSERT_EQ(SubstringToCodePoints(s, 14), s);
}
// 🂡

TEST(UTF8HelperTest, CountingAndClampingStrings) {
  std::string s = "café🂡火";
  ASSERT_EQ(CodePointCount(s), 6);
  ASSERT_EQ(SubstringToCodePoints(s, 0), "");
  ASSERT_EQ(SubstringToCodePoints(s, 3), "caf");
  ASSERT_EQ(SubstringToCodePoints(s, 4), "café");
  ASSERT_EQ(SubstringToCodePoints(s, 5), "café🂡");
  ASSERT_EQ(SubstringToCodePoints(s, 6), s);
  ASSERT_EQ(SubstringToCodePoints(s, 7), s);
  ASSERT_EQ(SubstringToCodePoints(s, 8), s);
}

TEST(UTF8HelperTest, CountingAndClampingInvalidStrings) {
  // Mangled UTF-8 sequence: \xc3\xa9 = é;
  std::string s = "caf🂡\xa9\xc3火";
  ASSERT_EQ(CodePointCount(s), 4);
  ASSERT_EQ(SubstringToCodePoints(s, 0), "");
  ASSERT_EQ(SubstringToCodePoints(s, 3), "caf");
  ASSERT_EQ(SubstringToCodePoints(s, 4), "caf🂡");
  ASSERT_EQ(SubstringToCodePoints(s, 5), "caf🂡");
  ASSERT_EQ(SubstringToCodePoints(s, 6), "caf🂡");
  ASSERT_EQ(SubstringToCodePoints(s, 7), "caf🂡");
  ASSERT_EQ(SubstringToCodePoints(s, 8), "caf🂡");
}

TEST(UTF8HelperTest, CountingAndClampingPrematurelyTerminatingSequence) {
  // \xc3\xa9 = é;
  std::string s = "\xc3";
  ASSERT_EQ(CodePointCount(s), 0);
  ASSERT_EQ(SubstringToCodePoints(s, 0), "");
  ASSERT_EQ(SubstringToCodePoints(s, 1), "");
  ASSERT_EQ(SubstringToCodePoints(s, 2), "");

  s = "abc\xc3 def";
  ASSERT_EQ(CodePointCount(s), 3);
  ASSERT_EQ(SubstringToCodePoints(s, 0), "");
  ASSERT_EQ(SubstringToCodePoints(s, 1), "a");
  ASSERT_EQ(SubstringToCodePoints(s, 4), "abc");

  // This is an invalid start.
  s = "\xa9";
  ASSERT_EQ(CodePointCount(s), 0);
  ASSERT_EQ(SubstringToCodePoints(s, 0), "");
  ASSERT_EQ(SubstringToCodePoints(s, 1), "");
  ASSERT_EQ(SubstringToCodePoints(s, 2), "");
}

TEST(UTF8HelperTest, Split) {
  std::string input = "落魄江湖載酒行";
  std::vector<std::string> output = Split(input);
  ASSERT_EQ(output.size(), 7);
  ASSERT_EQ(output[0], "落");
  ASSERT_EQ(output[1], "魄");
  ASSERT_EQ(output[2], "江");
  ASSERT_EQ(output[3], "湖");
  ASSERT_EQ(output[4], "載");
  ASSERT_EQ(output[5], "酒");
  ASSERT_EQ(output[6], "行");
}

}  // namespace McBopomofo
