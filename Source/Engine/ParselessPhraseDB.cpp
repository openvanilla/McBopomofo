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

#include "ParselessPhraseDB.h"

#include <cassert>
#include <cstring>

namespace McBopomofo {

ParselessPhraseDB::ParselessPhraseDB(
    const char* buf, size_t length, bool validate_pragma)
    : begin_(buf)
    , end_(buf + length)
{
    assert(buf != nullptr);
    assert(length > 0);

    if (validate_pragma) {
        assert(length > SORTED_PRAGMA_HEADER.length());

        std::string_view header(buf, SORTED_PRAGMA_HEADER.length());
        assert(header == SORTED_PRAGMA_HEADER);

        begin_ += header.length();
    }
}

std::vector<std::string_view> ParselessPhraseDB::findRows(
    const std::string_view& key)
{
    std::vector<std::string_view> rows;

    const char* ptr = findFirstMatchingLine(key);
    if (ptr == nullptr) {
        return rows;
    }

    while (ptr + key.length() <= end_
        && memcmp(ptr, key.data(), key.length()) == 0) {
        const char* eol = ptr;

        while (eol != end_ && *eol != '\n') {
            ++eol;
        }

        rows.emplace_back(ptr, eol - ptr);
        if (eol == end_) {
            break;
        }

        ptr = ++eol;
    }

    return rows;
}

// Implements a binary search that returns the pointer to the first matching
// row. In its core it's just a standard binary search, but we use backtracking
// to locate the line start. We also check the previous line to see if the
// current line is actually the first matching line: if the previous line is
// less to the key and the current line starts exactly with the key, then
// the current line is the first matching line.
const char* ParselessPhraseDB::findFirstMatchingLine(
    const std::string_view& key)
{
    if (key.empty()) {
        return begin_;
    }

    const char* top = begin_;
    const char* bottom = end_;

    while (top < bottom) {
        const char* mid = top + (bottom - top) / 2;
        const char* ptr = mid;

        if (ptr != begin_) {
            --ptr;
        }

        while (ptr != begin_ && *ptr != '\n') {
            --ptr;
        }

        const char* prev = nullptr;
        if (*ptr == '\n') {
            prev = ptr;
            ++ptr;
        }

        // ptr is now in the "current" line we're interested in.
        if (ptr + key.length() > end_) {
            // not enough data to compare at this point, bail.
            break;
        }

        int current_cmp = memcmp(ptr, key.data(), key.length());

        if (current_cmp > 0) {
            bottom = mid - 1;
            continue;
        }

        if (current_cmp < 0) {
            top = mid + 1;
            continue;
        }

        if (!prev) {
            return ptr;
        }

        // Move the prev so that it reaches the previous line.
        if (prev != begin_) {
            --prev;
        }
        while (prev != begin_ && *prev != '\n') {
            --prev;
        }
        if (*prev == '\n') {
            ++prev;
        }

        int prev_cmp = memcmp(prev, key.data(), key.length());

        // This is the first occurrence.
        if (prev_cmp < 0 && current_cmp == 0) {
            return ptr;
        }

        // This is not, which means ptr is "larger" than the keyData.
        bottom = mid - 1;
    }

    return nullptr;
}

std::vector<std::string> ParselessPhraseDB::reverseFindRows(
    const std::string_view& value)
{
    std::vector<std::string> rows;

    const char* recordBegin = begin_;

    while (recordBegin < end_) {
        const char* ptr = recordBegin;

        // skip over the key to find the field separator
        while (ptr < end_ && *ptr != ' ') {
            ++ptr;
        }
        // skip over the field separator. there should be just one, but loop just in case.
        while (ptr < end_ && *ptr == ' ') {
            ++ptr;
        }

        // now walk to the end of this record
        const char* recordEnd = ptr;
        while (recordEnd < end_ && *recordEnd != '\n') {
            ++recordEnd;
        }

        if (ptr + value.length() < end_ && memcmp(ptr, value.data(), value.length()) == 0) {
            // prefix match, add entire record to return value
            rows.emplace_back(recordBegin, recordEnd - recordBegin);
        }

        // skip over to the next line start
        recordBegin = recordEnd;
        while (recordBegin < end_ && *recordBegin == '\n') {
            ++recordBegin;
        }
    }

    return rows;
}

}; // namespace McBopomofo
