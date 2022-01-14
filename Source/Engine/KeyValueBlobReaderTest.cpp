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

#include "KeyValueBlobReader.h"

#include <string>
#include "gtest/gtest.h"

namespace McBopomofo {

using State = KeyValueBlobReader::State;
using KeyValue = KeyValueBlobReader::KeyValue;

TEST(KeyValueBlobReaderTest, EmptyBlob) {
  std::string empty;
  KeyValueBlobReader reader(empty.c_str(), empty.length());
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, EmptyBlobIdempotency) {
  char empty[0];
  KeyValueBlobReader reader(empty, 0);
  EXPECT_EQ(reader.Next(), State::END);
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, BlankBlob) {
  std::string blank = " ";
  KeyValueBlobReader reader(blank.c_str(), blank.length());
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, KeyWithoutValueIsInvalid) {
  std::string empty = "hello";
  KeyValueBlobReader reader(empty.c_str(), empty.length());
  EXPECT_EQ(reader.Next(), State::ERROR);
}

TEST(KeyValueBlobReaderTest, ErrorStateMakesNoMoreProgress) {
  std::string empty = "hello";
  KeyValueBlobReader reader(empty.c_str(), empty.length());
  EXPECT_EQ(reader.Next(), State::ERROR);
  EXPECT_EQ(reader.Next(), State::ERROR);
}

TEST(KeyValueBlobReaderTest, KeyValueSeparatedByNullCharIsInvalid) {
  char bad[] = {'h', 0, 'w'};
  KeyValueBlobReader reader(bad, sizeof(bad));
  EXPECT_EQ(reader.Next(), State::ERROR);
}

TEST(KeyValueBlobReaderTest, SingleKeyValuePair) {
  std::string empty = "hello world\n";
  KeyValueBlobReader reader(empty.c_str(), empty.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, SingleKeyValuePairFromButterWithoutNullEnding) {
  char small[] = {'p', ' ', 'q'};
  KeyValueBlobReader reader(small, sizeof(small));
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"p", "q"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, NullCharInTheMiddleTerminatesParsing) {
  char small[] = {'p', ' ', 'q', ' ', 0, '\n', 'r', ' ', 's'};
  KeyValueBlobReader reader(small, sizeof(small));
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"p", "q"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, SingleKeyValuePairWithoutLFAtEnd) {
  std::string simple = "hello world";
  KeyValueBlobReader reader(simple.c_str(), simple.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, EncodingAgnostic1) {
  std::string simple = u8"smile ☺️";
  KeyValueBlobReader reader(simple.c_str(), simple.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"smile", u8"☺️"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, EncodingAgnostic2) {
  std::string simple = "Nobel-Laureate "
                       "\xe9\x81\x94\xe8\xb3\xb4\xe5\x96\x87\xe5\x98\x9b";
  KeyValueBlobReader reader(simple.c_str(), simple.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (
      KeyValue{"Nobel-Laureate",
               "\xe9\x81\x94\xe8\xb3\xb4\xe5\x96\x87\xe5\x98\x9b"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, ValueDoesNotIncludeSpace) {
  std::string simple = "hello world and all\nanother value";
  KeyValueBlobReader reader(simple.c_str(), simple.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"another", "value"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, TrailingSpaceInValueIsIgnored) {
  std::string simple = "\thello   world        \n\n    foo bar \t\t\t   \n\n\n";
  KeyValueBlobReader reader(simple.c_str(), simple.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"foo", "bar"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, WindowsCRLFSupported) {
  std::string simple = "lorem ipsum\r\nhello world";
  KeyValueBlobReader reader(simple.c_str(), simple.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"lorem", "ipsum"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, MultipleKeyValuePair) {
  std::string multi = "\n   \nhello world\n  foo \t bar  ";
  KeyValueBlobReader reader(multi.c_str(), multi.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"foo", "bar"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, ReadUntilNullChar) {
  char buf[] = {'p', '\t', 'q', '\n', 0, 'r', ' ', 's'};
  KeyValueBlobReader reader(buf, sizeof(buf));
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"p", "q"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, MultipleKeyValuePairWithComments) {
  std::string text = R"(
# comment1
# comment2

# comment3
  hello World
  caffè latte

    # another comment
  foo bar

# comment4
# comment5
)";

  KeyValueBlobReader reader(text.c_str(), text.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "World"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"caffè", "latte"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"foo", "bar"}));
  EXPECT_EQ(reader.Next(), State::END);
}

TEST(KeyValueBlobReaderTest, ValueCommentSupported) {
  std::string text = R"(
  # empty

  hello world#peace
       hello world#peace #peace
hello world#peace  // peace
  caffè latte # café au lait
  foo bar
)";

  KeyValueBlobReader reader(text.c_str(), text.length());
  KeyValue keyValue;
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world#peace"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world#peace"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"hello", "world#peace"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"caffè", "latte"}));
  EXPECT_EQ(reader.Next(&keyValue), State::HAS_PAIR);
  EXPECT_EQ(keyValue, (KeyValue{"foo", "bar"}));
  EXPECT_EQ(reader.Next(), State::END);
}

}  // namespace McBopomofo
