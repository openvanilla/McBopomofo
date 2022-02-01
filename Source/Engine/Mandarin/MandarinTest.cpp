// Copyright (c) 2022 and onwards Lukhnos Liu
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

#include "Mandarin.h"
#include "gtest/gtest.h"

namespace Formosa {
namespace Mandarin {

static std::string RoundTrip(const std::string& composedString) {
  return BopomofoSyllable::FromComposedString(composedString).composedString();
}

TEST(MandarinTest, FromComposedString) {
  ASSERT_EQ(RoundTrip("ㄅ"), "ㄅ");
  ASSERT_EQ(RoundTrip("ㄅㄧ"), "ㄅㄧ");
  ASSERT_EQ(RoundTrip("ㄅㄧˇ"), "ㄅㄧˇ");
  ASSERT_EQ(RoundTrip("ㄅㄧˇㄆ"), "ㄆㄧˇ");
  ASSERT_EQ(RoundTrip("ㄅㄧˇㄆ"), "ㄆㄧˇ");
  ASSERT_EQ(RoundTrip("e"), "");
  ASSERT_EQ(RoundTrip("é"), "");
  ASSERT_EQ(RoundTrip("ㄅéㄆ"), "ㄅ");
  ASSERT_EQ(RoundTrip("ㄅeㄆ"), "ㄅ");
}

}  // namespace Mandarin
}  // namespace Formosa
