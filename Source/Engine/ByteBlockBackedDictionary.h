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

#ifndef SRC_ENGINE_BYTEBLOCKBACKEDDICTIONARY_H_
#define SRC_ENGINE_BYTEBLOCKBACKEDDICTIONARY_H_

#include <string_view>
#include <unordered_map>
#include <vector>

namespace McBopomofo {

// A dictionary backed by a block of bytes, usually read or mapped from a file
// containing plaintext key-value pairs. Lines beginning with "#" are ignored
// as comment lines. Space and tab are considered whitespace characters and
// those at the start and the end of a line are stripped.
//
// The parser supports two modes, key-then-value and value-then-key. With the
// former, the first string in a line is parsed as the key, followed by one or
// more whitespaces, and what follows after that all the way to the end of the
// line, except any trailing whitespaces, are considered the value. This allows
// values to contain whitespaces. In the value-then-key modes, only the last
// non-whitespace-containing string is considered the key; everything else
// leading to the key, except the beginning whitespaces and the last sequence
// of whitespaces leading to the key, is considered the value. This again allows
// values to contain whitespaces in them. Here are two examples:
//
//   # Comments are ignored
//   key     a multiword value
//
//   # key is the last string in the value-then-key mode
//   s o m e  v a l u e    key
//
// If only one column is parsed from a line, a warning will be added to the
// issues list. Issues come with their line numbers (starting from 1), and the
// line is ignored.
//
// No NULL character (ASCII 0) is allowed in the text. Any NULL characters
// found in the text resulting in a parsing error. Note, it is safe to pass
// a null-terminated C string to the parser, which treats it as a special case.
//
// On memory safety: you are responsible for ensuring that the block of bytes
// is alive during the dictionary's lifetime. To gain efficiency, the dictionary
// uses std::string_view instead of copying key and value strings out of the
// text. Therefore, the dictionary must not be used if the block of bytes is
// gone! You can call clear() to clear all such dangling references to the text.
class ByteBlockBackedDictionary {
 public:
  struct Issue {
    enum class Type {
      MISSING_SECOND_COLUMN,
      NULL_CHARACTER_IN_TEXT,
    };

    const Type type;

    // Note these are 1-based number for usability.
    const size_t lineNumber;

    Issue(Type t, size_t n) : type(t), lineNumber(n) {}
  };

  enum class ColumnOrder {
    KEY_THEN_VALUE,
    VALUE_THEN_KEY,
  };

  void clear();
  bool parse(const char* block, size_t size,
             ColumnOrder columnOrder = ColumnOrder::KEY_THEN_VALUE);

  [[nodiscard]] bool hasKey(const std::string_view& key) const;
  [[nodiscard]] std::vector<std::string_view> getValues(
      const std::string_view& key) const;

  const std::vector<Issue>& issues() const { return issues_; }

 private:
  static constexpr size_t MAX_ISSUES = 100;

  std::vector<Issue> issues_;
  std::unordered_map<std::string_view, std::vector<std::string_view>> dict_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_BYTEBLOCKBACKEDDICTIONARY_H_
