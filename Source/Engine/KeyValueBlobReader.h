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

#ifndef SOURCE_ENGINE_KEYVALUEBLOBREADER_H_
#define SOURCE_ENGINE_KEYVALUEBLOBREADER_H_

#include <cstddef>
#include <functional>
#include <iostream>
#include <string_view>

// A reader for text-based, blank-separated key-value pairs in a binary blob.
//
// This reader is suitable for reading language model files that entirely
// consist of key-value pairs. Leading or trailing spaces are ignored.
// Lines that start with "#" are treated as comments. Values cannot contain
// spaces. Any space after the value string is parsed is ignored. This implies
// that after a blank, anything that comes after the value can be used as
// comment. Both ' ' and  '\t' are treated as blank characters, and the parser
// is agnostic to how lines are ended, and so LF, CR LF, and CR are all valid
// line endings.
//
// std::string_view is used to allow returning results efficiently. As a result,
// the blob is a const char* and will never be mutated. This implies, for
// example, read-only mmap can be used to parse large files.
namespace McBopomofo {

class KeyValueBlobReader {
 public:
  enum class State : int {
    // There are no more key-value pairs in this blob.
    END = 0,
    // The reader has produced a new key-value pair.
    HAS_PAIR = 1,
    // An error is encountered and the parsing stopped.
    ERROR = -1,
    // Internal-only state: the parser can continue parsing.
    CAN_CONTINUE = 2
  };

  struct KeyValue {
    constexpr KeyValue() : key(""), value("") {}
    constexpr KeyValue(std::string_view k, std::string_view v)
        : key(k), value(v) {}

    bool operator==(const KeyValue& another) const {
      return key == another.key && value == another.value;
    }

    std::string_view key;
    std::string_view value;
  };

  KeyValueBlobReader(const char* blob, size_t size)
      : current_(blob), end_(blob + size) {}

  // Parse the next key-value pair and return the state of the reader. If `out`
  // is passed, out will be set to the produced key-value pair if there is one.
  State Next(KeyValue* out = nullptr);

 private:
  State SkipUntil(const std::function<bool(char)>& f);
  State SkipUntilNot(const std::function<bool(char)>& f);

  const char* current_;
  const char* end_;
  State state_ = State::CAN_CONTINUE;
};

std::ostream& operator<<(std::ostream&, const KeyValueBlobReader::KeyValue&);

}  // namespace McBopomofo

#endif  // SOURCE_ENGINE_KEYVALUEBLOBREADER_H_
