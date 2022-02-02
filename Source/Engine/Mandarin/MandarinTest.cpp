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

TEST(MandarinTest, SimpleCompositions) {
  BopomofoSyllable syllable;
  syllable += BopomofoSyllable(BopomofoSyllable::X);
  syllable += BopomofoSyllable(BopomofoSyllable::I);
  ASSERT_EQ(syllable.composedString(), "ㄒㄧ");

  syllable.clear();
  syllable += BopomofoSyllable(BopomofoSyllable::Z);
  syllable += BopomofoSyllable(BopomofoSyllable::ANG);
  syllable += BopomofoSyllable(BopomofoSyllable::Tone4);
  ASSERT_EQ(syllable.composedString(), "ㄗㄤˋ");
}

TEST(MandarinTest, StandardLayout) {
  BopomofoReadingBuffer buf(BopomofoKeyboardLayout::StandardLayout());
  buf.combineKey('w');
  buf.combineKey('9');
  buf.combineKey('6');
  ASSERT_EQ(buf.composedString(), "ㄊㄞˊ");
}

TEST(MandarinTest, StandardLayoutCombination) {
  BopomofoReadingBuffer buf(BopomofoKeyboardLayout::StandardLayout());
  buf.combineKey('w');
  buf.combineKey('9');
  buf.combineKey('6');
  ASSERT_EQ(buf.composedString(), "ㄊㄞˊ");

  buf.backspace();
  ASSERT_EQ(buf.composedString(), "ㄊㄞ");

  buf.combineKey('y');
  ASSERT_EQ(buf.composedString(), "ㄗㄞ");

  buf.combineKey('4');
  ASSERT_EQ(buf.composedString(), "ㄗㄞˋ");

  buf.combineKey('3');
  ASSERT_EQ(buf.composedString(), "ㄗㄞˇ");
}

TEST(MandarinTest, ETenLayout) {
  BopomofoReadingBuffer buf(BopomofoKeyboardLayout::ETenLayout());
  buf.combineKey('x');
  buf.combineKey('8');
  ASSERT_EQ(buf.composedString(), "ㄨㄢ");
}

TEST(MandarinTest, ETen26Layout) {
  BopomofoReadingBuffer buf(BopomofoKeyboardLayout::ETen26Layout());
  buf.combineKey('q');
  buf.combineKey('m');  // AN in the vowel state
  buf.combineKey('k');  // Tone 4 in the tone state
  ASSERT_EQ(buf.composedString(), "ㄗㄢˋ");
}

TEST(MandarinTest, HsuLayout) {
  BopomofoReadingBuffer buf(BopomofoKeyboardLayout::HsuLayout());
  buf.combineKey('f');
  buf.combineKey('a');  // EI when in the vowel state
  buf.combineKey('f');  // Tone 3 when in the tone state
  ASSERT_EQ(buf.composedString(), "ㄈㄟˇ");
}

TEST(MandarinTest, IBMLayout) {
  BopomofoReadingBuffer buf(BopomofoKeyboardLayout::IBMLayout());
  buf.combineKey('9');
  buf.combineKey('s');
  buf.combineKey('g');
  buf.combineKey('m');
  ASSERT_EQ(buf.composedString(), "ㄍㄨㄛˊ");
}

}  // namespace Mandarin
}  // namespace Formosa
