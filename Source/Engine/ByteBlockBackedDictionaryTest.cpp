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

#include "ByteBlockBackedDictionary.h"
#include "gtest/gtest.h"

namespace McBopomofo {

TEST(ByteBlockBackedDictionaryTest, EmptyCStringParseSuccessfully) {
  constexpr char data[] = "";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
}

TEST(ByteBlockBackedDictionaryTest, Simple1) {
  constexpr char data[] = "key1 value1";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.getValues("key1").at(0), "value1");
}

TEST(ByteBlockBackedDictionaryTest, Simple2) {
  constexpr char data[] = "key1 value1\n";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.getValues("key1").at(0), "value1");
}

TEST(ByteBlockBackedDictionaryTest, EncodingAgnostic1) {
  constexpr char data[] = u8"smile 😊";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.getValues("smile").at(0), u8"😊");
}

TEST(ByteBlockBackedDictionaryTest, EncodingAgnostic2) {
  constexpr char data[] =
      "Nobel-Laureate "
      "\xe9\x81\x94\xe8\xb3\xb4\xe5\x96\x87\xe5\x98\x9b";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.getValues("Nobel-Laureate").at(0),
            "\xe9\x81\x94\xe8\xb3\xb4\xe5\x96\x87\xe5\x98\x9b");
}

TEST(ByteBlockBackedDictionaryTest, KeyOnly1) {
  constexpr char data[] = "key1";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.issues().size(), 1);
  ASSERT_EQ(dict.issues().at(0).type,
            ByteBlockBackedDictionary::Issue::Type::MISSING_SECOND_COLUMN);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 1);
}

TEST(ByteBlockBackedDictionaryTest, KeyOnly2) {
  constexpr char data[] = "\nkey1\n";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.issues().size(), 1);
  ASSERT_EQ(dict.issues().at(0).type,
            ByteBlockBackedDictionary::Issue::Type::MISSING_SECOND_COLUMN);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 2);
}

TEST(ByteBlockBackedDictionaryTest, KeyOnly3) {
  constexpr char data[] = "key1      ";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.issues().size(), 1);
  ASSERT_EQ(dict.issues().at(0).type,
            ByteBlockBackedDictionary::Issue::Type::MISSING_SECOND_COLUMN);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 1);
}

TEST(ByteBlockBackedDictionaryTest, KeyOnly4) {
  constexpr char data[] = "   key1      \n";
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.issues().size(), 1);
  ASSERT_EQ(dict.issues().at(0).type,
            ByteBlockBackedDictionary::Issue::Type::MISSING_SECOND_COLUMN);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 1);
}

TEST(ByteBlockBackedDictionaryTest, KeyOnly5) {
  constexpr char data[] = {'k', 'e', 'y', '1'};
  ByteBlockBackedDictionary dict;
  ASSERT_TRUE(dict.parse(data, sizeof(data)));
  ASSERT_EQ(dict.issues().size(), 1);
  ASSERT_EQ(dict.issues().at(0).type,
            ByteBlockBackedDictionary::Issue::Type::MISSING_SECOND_COLUMN);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 1);
}

TEST(ByteBlockBackedDictionaryTest, TrailingSpacesInValuesAreStripped) {
  constexpr char data[] = "some_key  some_value \t \nanother another_value ";
  ByteBlockBackedDictionary dict;
  bool result = dict.parse(data, sizeof(data));
  ASSERT_TRUE(result);
  ASSERT_EQ(dict.getValues("some_key").at(0), "some_value");
  ASSERT_EQ(dict.getValues("another").at(0), "another_value");
}

TEST(ByteBlockBackedDictionaryTest, ValueColumnThenKeyColumn) {
  constexpr char data[] = "many words in value    key";
  ByteBlockBackedDictionary dict;
  bool result =
      dict.parse(data, sizeof(data),
                 ByteBlockBackedDictionary::ColumnOrder::VALUE_THEN_KEY);
  ASSERT_TRUE(result);
  ASSERT_TRUE(dict.hasKey("key"));
  ASSERT_EQ(dict.getValues("key").size(), 1);
  ASSERT_EQ(dict.getValues("key").at(0), "many words in value");
}

TEST(ByteBlockBackedDictionaryTest, ValueColumnThenKeyColumnWithTrailingSpace) {
  constexpr char data[] = "many words in value    key   \nanother value key";
  ByteBlockBackedDictionary dict;
  bool result =
      dict.parse(data, sizeof(data),
                 ByteBlockBackedDictionary::ColumnOrder::VALUE_THEN_KEY);
  ASSERT_TRUE(result);
  ASSERT_TRUE(dict.hasKey("key"));
  ASSERT_EQ(dict.getValues("key").size(), 2);
  ASSERT_EQ(dict.getValues("key").at(0), "many words in value");
  ASSERT_EQ(dict.getValues("key").at(1), "another value");
}

TEST(ByteBlockBackedDictionaryTest, NullCharacterNotAllowed) {
  constexpr char data[] = {'k', ' ', 'v', '\n', 'a', 0, ' ', 'b', '\n'};
  ByteBlockBackedDictionary dict;
  bool result = dict.parse(data, sizeof(data));
  ASSERT_FALSE(result);

  auto issues = dict.issues();
  ASSERT_EQ(issues.size(), 1);
  ASSERT_EQ(issues[0].type,
            ByteBlockBackedDictionary::Issue::Type::NULL_CHARACTER_IN_TEXT);
  ASSERT_EQ(issues[0].lineNumber, 2);
}

TEST(ByteBlockBackedDictionaryTest, NullCharacterNotAllowedLarge) {
  constexpr size_t size = 16 * 1024 * 1024;
  std::unique_ptr<char[]> data(new char[size]);
  memset(data.get(), ' ', size);
  data.get()[size - 2] = '\0';

  ByteBlockBackedDictionary dict;
  bool result = dict.parse(data.get(), size);
  ASSERT_FALSE(result);
}

TEST(ByteBlockBackedDictionaryTest, NullCharacterNotAllowedLargeTestIssues) {
  constexpr size_t size = 16 * 1024 * 1024 + 7;
  std::unique_ptr<char[]> data(new char[size]);
  memset(data.get(), ' ', size);
  data[size - 2] = '\0';
  data[5] = '\n';
  data[size - 3] = '\n';
  memset(data.get() + 1024, '\n', 1024);

  ByteBlockBackedDictionary dict;
  bool result = dict.parse(data.get(), size);
  ASSERT_FALSE(result);
  ASSERT_EQ(dict.issues().size(), 1);
  ASSERT_EQ(dict.issues().at(0).type,
            ByteBlockBackedDictionary::Issue::Type::NULL_CHARACTER_IN_TEXT);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 1027);
}

TEST(ByteBlockBackedDictionaryTest, ComplexEntries) {
  constexpr char data[] =
      "\n"
      "# comment\n"
      "key1\tvalue1\n"
      "key2 \tvalue2\r\n"
      "key3 \t value3\n"
      "\n"
      "key1 value1 1\n"
      "key2 value2 2\n"
      "\r\n"
      "key3  value3 3\n"
      "error_key4\n"
      "error_key5  \n"
      "  error_key6  \n"
      "\n"
      "key1 value1\t2 \n"
      "key2 value2 2\n"
      "key3 value3\t3\n"
      "\n"
      "  # spaces/tabs in the value are included verbatim\n"
      "key1 \t value1 \t 3 # comment  \n";

  ByteBlockBackedDictionary dict;
  bool result = dict.parse(data, sizeof(data));
  ASSERT_TRUE(result);

  ASSERT_TRUE(dict.hasKey("key1"));
  ASSERT_FALSE(dict.hasKey("key42"));

  ASSERT_EQ(dict.issues().size(), 3);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 11);
  ASSERT_EQ(dict.issues().at(1).lineNumber, 12);
  ASSERT_EQ(dict.issues().at(2).lineNumber, 13);

  ASSERT_EQ(dict.getValues("key1").size(), 4);
  ASSERT_EQ(dict.getValues("key1").at(0), "value1");
  ASSERT_EQ(dict.getValues("key1").at(1), "value1 1");
  ASSERT_EQ(dict.getValues("key1").at(2), "value1\t2");
  ASSERT_EQ(dict.getValues("key1").at(3), "value1 \t 3 # comment");
}

TEST(ByteBlockBackedDictionaryTest, ComplexEntriesValueThenKey) {
  constexpr char data[] =
      "\n"
      "# comment\n"
      "value1\tkey1\n"
      "value2 \tkey2\r\n"
      "value3 \t key3\n"
      "\n"
      "value1 1 key1\n"
      "value2 2 key2\n"
      "\r\n"
      "value3 3  key3\n"
      "error_value4\n"
      "error_value5  \n"
      "  error_value6  \n"
      "\n"
      "value1 \t 2   key1\n"
      "value2 2  key2\n"
      "value3\t3  key3\n"
      "\n"
      "  # spaces/tabs in the value are included verbatim\n"
      "value1 \t 3 # comment    key1 \n"
      "value1 \t key1  # comment\n";

  ByteBlockBackedDictionary dict;
  bool result =
      dict.parse(data, sizeof(data),
                 ByteBlockBackedDictionary::ColumnOrder::VALUE_THEN_KEY);
  ASSERT_TRUE(result);

  ASSERT_TRUE(dict.hasKey("key1"));
  ASSERT_FALSE(dict.hasKey("key42"));

  ASSERT_EQ(dict.issues().size(), 3);
  ASSERT_EQ(dict.issues().at(0).lineNumber, 11);
  ASSERT_EQ(dict.issues().at(1).lineNumber, 12);
  ASSERT_EQ(dict.issues().at(2).lineNumber, 13);

  ASSERT_EQ(dict.getValues("key1").size(), 4);
  ASSERT_EQ(dict.getValues("key1").at(0), "value1");
  ASSERT_EQ(dict.getValues("key1").at(1), "value1 1");
  ASSERT_EQ(dict.getValues("key1").at(2), "value1 \t 2");
  ASSERT_EQ(dict.getValues("key1").at(3), "value1 \t 3 # comment");

  // This may be surprising, but it really has to do with the fact that we made
  // this choice to keep the parsing simple.
  ASSERT_EQ(dict.getValues("comment").at(0), "value1 \t key1  #");
}

}  // namespace McBopomofo
