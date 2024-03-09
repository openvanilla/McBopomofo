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

namespace McBopomofo {

KeyValueBlobReader::State KeyValueBlobReader::Next(KeyValue* out) {
  static auto new_line = [](char c) { return c == '\n' || c == '\r'; };
  static auto blank = [](char c) { return c == ' ' || c == '\t'; };
  static auto blank_or_newline = [](char c) { return blank(c) || new_line(c); };
  static auto content_char = [](char c) { return !blank(c) && !new_line(c); };

  if (state_ == State::ERROR) {
    return state_;
  }

  const char* key_begin = nullptr;
  size_t key_length = 0;
  const char* value_begin = nullptr;
  size_t value_length = 0;

  while (true) {
    state_ = SkipUntilNot(blank_or_newline);
    if (state_ != State::CAN_CONTINUE) {
      return state_;
    }

    // Check if it's a comment line; if so, read until end of line.
    if (*current_ != '#') {
      break;
    }
    state_ = SkipUntil(new_line);
    if (state_ != State::CAN_CONTINUE) {
      return state_;
    }
  }

  // No need to check whether* current_ is a content_char, since content_char
  // is defined as not blank and not new_line.

  key_begin = current_;
  state_ = SkipUntilNot(content_char);
  if (state_ != State::CAN_CONTINUE) {
    goto error;
  }
  key_length = current_ - key_begin;

  // There should be at least one blank character after the key string.
  if (!blank(*current_)) {
    goto error;
  }

  state_ = SkipUntilNot(blank);
  if (state_ != State::CAN_CONTINUE) {
    goto error;
  }

  if (!content_char(*current_)) {
    goto error;
  }

  value_begin = current_;
  // value must only contain content characters, blanks not are allowed.
  // also, there's no need to check the state after this, since we will always
  // emit the value. This also avoids the situation where trailing spaces in a
  // line would become part of the value.
  SkipUntilNot(content_char);
  value_length = current_ - value_begin;

  // Unconditionally skip until the end of the line. This prevents the case
  // like "foo bar baz\n" where baz should not be treated as the Next key.
  SkipUntil(new_line);

  if (out != nullptr) {
    *out = KeyValue{std::string_view{key_begin, key_length},
                    std::string_view{value_begin, value_length}};
  }
  state_ = State::HAS_PAIR;
  return state_;

error:
  state_ = State::ERROR;
  return state_;
}

KeyValueBlobReader::State KeyValueBlobReader::SkipUntilNot(
    const std::function<bool(char)>& f) {
  while (current_ != end_ && *current_) {
    if (!f(*current_)) {
      return State::CAN_CONTINUE;
    }
    ++current_;
  }

  return State::END;
}

KeyValueBlobReader::State KeyValueBlobReader::SkipUntil(
    const std::function<bool(char)>& f) {
  while (current_ != end_ && *current_) {
    if (f(*current_)) {
      return State::CAN_CONTINUE;
    }
    ++current_;
  }

  return State::END;
}

std::ostream& operator<<(std::ostream& os,
                         const KeyValueBlobReader::KeyValue& kv) {
  os << "(key: " << kv.key << ", value: " << kv.value << ")";
  return os;
}

}  // namespace McBopomofo
