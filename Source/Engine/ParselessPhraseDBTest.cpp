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
#include <map>
#include <sstream>
#include <vector>

#include "ParselessPhraseDB.h"
#include "gtest/gtest-death-test.h"
#include "gtest/gtest.h"

using StringViews = std::vector<std::string_view>;

namespace McBopomofo {

static bool VectorsEqual(
    const std::vector<std::string_view>& a, const std::vector<std::string>& b)
{
    if (a.size() != b.size()) {
        return false;
    }

    size_t s = a.size();
    for (size_t i = 0; i < s; i++) {
        if (a[i] != b[i]) {
            return false;
        }
    }
    return true;
}

TEST(ParselessPhraseDBTest, Simple)
{
    std::string data = "a 1";
    ParselessPhraseDB db(data.c_str(), data.length());

    const char* first = db.findFirstMatchingLine("a");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "a 1", 3), 0);

    first = db.findFirstMatchingLine("a ");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "a 1", 3), 0);

    first = db.findFirstMatchingLine("a 1");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "a 1", 3), 0);
}

TEST(ParselessPhraseDBTest, NotFound)
{
    std::string data = "a 1\na 2\na 3\nb 1";
    ParselessPhraseDB db(data.c_str(), data.length());
    EXPECT_EQ(db.findFirstMatchingLine("c"), nullptr);
    EXPECT_EQ(db.findFirstMatchingLine("A"), nullptr);
}

TEST(ParselessPhraseDBTest, FindRowsLongerExample)
{
    std::string data = "a 1\na 2\na 3\nb 42\nb 1\nb 2\nc 7\nd 1";
    ParselessPhraseDB db(data.c_str(), data.length());

    EXPECT_EQ(db.findRows("a"), (StringViews { "a 1", "a 2", "a 3" }));
    EXPECT_EQ(db.findRows("b"), (StringViews { "b 42", "b 1", "b 2" }));
    EXPECT_EQ(db.findRows("c"), (StringViews { "c 7" }));
    EXPECT_EQ(db.findRows("d"), (StringViews { "d 1" }));
    EXPECT_EQ(db.findRows("e"), (StringViews {}));
    EXPECT_EQ(db.findRows("A"), (StringViews {}));
}

TEST(ParselessPhraseDBTest, FindFirstMatchingLineLongerExample)
{
    std::string data = "a 1\na 2\na 3\nb 42\nb 1\nb 2\nc 7\nd 1";
    ParselessPhraseDB db(data.c_str(), data.length());

    const char* first = db.findFirstMatchingLine("a");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "a 1", 3), 0);

    db.findFirstMatchingLine("a 1");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "a 1", 3), 0);

    first = db.findFirstMatchingLine("b");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "b 42", 4), 0);

    first = db.findFirstMatchingLine("c");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "c 7", 3), 0);

    first = db.findFirstMatchingLine("d");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "d 1", 3), 0);

    first = db.findFirstMatchingLine("d 1");
    EXPECT_NE(first, nullptr);
    EXPECT_EQ(memcmp(first, "d 1", 3), 0);

    first = db.findFirstMatchingLine("d 2");
    EXPECT_EQ(first, nullptr);
}

TEST(ParselessPhraseDBTest, InvalidConstructorArguments)
{
    EXPECT_DEATH((ParselessPhraseDB { nullptr, 1 }), "buf != nullptr");
    EXPECT_DEATH((ParselessPhraseDB { nullptr, 0 }), "buf != nullptr");
    EXPECT_DEATH((ParselessPhraseDB { "", 0 }), "length > 0");
    EXPECT_DEATH((ParselessPhraseDB { "a", 1, /*validate_pragma=*/true }),
        "length > SORTED_PRAGMA_HEADER\\.length\\(\\)");
}

TEST(ParselessPhraseDBTest, PragmaGuard)
{
    std::string buf1 = std::string(SORTED_PRAGMA_HEADER) + "a";
    std::string buf2 = "#" + buf1;
    std::string buf3 = buf1;
    buf3[3] = 'x';

    ParselessPhraseDB { buf1.c_str(), buf1.length(), /*validate_pragma=*/true };
    EXPECT_DEATH(
        (ParselessPhraseDB { buf2.c_str(), buf2.length(), /*validate_pragma=*/
            true }),
        "==");
    EXPECT_DEATH(
        (ParselessPhraseDB { buf3.c_str(), buf3.length(), /*validate_pragma=*/
            true }),
        "==");
}

TEST(ParselessPhraseDBTest, StressTest)
{
    constexpr const char* data_path = "data.txt";
    if (!std::filesystem::exists(data_path)) {
        GTEST_SKIP();
    }

    FILE* f = fopen(data_path, "r");
    ASSERT_NE(f, nullptr);
    int status = fseek(f, 0L, SEEK_END);
    ASSERT_EQ(status, 0);
    size_t length = ftell(f);
    std::unique_ptr<char[]> buf(new char[length]);
    status = fseek(f, 0L, SEEK_SET);
    ASSERT_EQ(status, 0);
    size_t items_read = fread(buf.get(), length, 1, f);
    ASSERT_EQ(items_read, 1);
    fclose(f);

    std::stringstream sstr(std::string(buf.get(), length));
    std::string line;
    std::map<std::string, std::vector<std::string>> key_to_lines;

    // Skip the pragma line.
    std::getline(sstr, line);

    while (!sstr.eof()) {
        std::getline(sstr, line);
        if (line == "") {
            continue;
        }

        std::stringstream linest(line);
        std::string key;
        linest >> key;
        key_to_lines[key].push_back(line);
    }

    ParselessPhraseDB db(buf.get(), length, /*validate_pragma=*/true);
    for (const auto& it : key_to_lines) {
        std::vector<std::string_view> rows = db.findRows(it.first + " ");
        ASSERT_TRUE(VectorsEqual(rows, it.second));
    }
}

TEST(ParselessPhraseDBTest, LookUpByValue)
{
    std::string data = "a 1\nb 1 \nc 2\nd 3";
    ParselessPhraseDB db(data.c_str(), data.length());

    std::vector<std::string> rows;
    rows = db.reverseFindRows("1");
    ASSERT_EQ(rows, (std::vector<std::string> { "a 1", "b 1 " }));

    rows = db.reverseFindRows("2");
    ASSERT_EQ(rows, (std::vector<std::string> { "c 2" }));

    // This is a quirk of the function, but is actually valid.
    rows = db.reverseFindRows("2\n");
    ASSERT_EQ(rows, (std::vector<std::string> { "c 2" }));

    rows = db.reverseFindRows("22");
    ASSERT_TRUE(rows.empty());

    rows = db.reverseFindRows("3\n");
    ASSERT_TRUE(rows.empty());

    rows = db.reverseFindRows("4");
    ASSERT_TRUE(rows.empty());
}

}; // namespace McBopomofo
