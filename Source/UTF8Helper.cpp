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

#include "UTF8Helper.h"

namespace McBopomofo {
// NOLINTBEGIN(readability-magic-numbers)

// Adapted from https://github.com/lua/lua/blob/master/lutf8lib.c

constexpr char32_t kMaxUnicode = 0x10FFFF;
static inline bool IsContinuationByte(char32_t c) { return (c & 0xC0) == 0x80; }

// Decodes one UTF-8 code point and advances the string iterator past the code
// point. Returns false if i is already at the end, or if the iterated UTF-8
// sequence is not valid.
static inline bool DecodeUTF8(std::string::const_iterator& i,
                              const std::string::const_iterator& end) {
  static const char32_t limits[] = {~(char32_t)0, 0x80,     0x800,
                                    0x10000,      0x200000, 0x4000000};
  if (i == end) {
    return false;
  }

  char32_t c = static_cast<unsigned char>(*i);
  // Consumes the continuation bytes if c is not ASCII.
  if (c >= 0x80) {
    char32_t res = 0;
    size_t count = 0;  // to count number of continuation bytes

    std::string::const_iterator next = i;
    for (; c & 0x40; c <<= 1) {
      ++next;
      if (next == end) {
        // Sequence terminates prematurely. Bail.
        return false;
      }

      ++count;
      char32_t cc = static_cast<unsigned char>(*next);
      if (!IsContinuationByte(cc)) {
        return false;
      }
      // Add lower 6 bits from the continuous byte.
      res = (res << 6) | (cc & 0x3F);
    }
    // Add first byte. Recall c has already been left-shifted (count * 1) times,
    // and so we need to left-shift another (count * 5) bits so the net effect
    // is left-shifting (count * 6) bits.
    res |= ((char32_t)(c & 0x7F) << (count * 5));

    bool invalid = count > 5 || res > kMaxUnicode || res < limits[count] ||
                   (0xd800 <= res && res <= 0xdfff);
    if (invalid) {
      return false;
    }
    for (size_t j = 0; j < count && i != end; j++) {
      ++i;
    }
  }

  // Sequence terminates prematurely.
  if (i == end) {
    return false;
  }

  ++i;
  return true;
}

size_t CodePointCount(const std::string& s) {
  size_t c = 0;
  std::string::const_iterator i = s.cbegin();
  std::string::const_iterator end = s.cend();
  while (i != end) {
    bool r = DecodeUTF8(i, end);
    if (!r) {
      break;
    }
    ++c;
  }

  return c;
}

std::string SubstringToCodePoints(const std::string& s, size_t cp) {
  size_t c = 0;
  std::string::const_iterator i = s.cbegin();
  std::string::const_iterator end = s.cend();
  while (i != end && c < cp) {
    bool r = DecodeUTF8(i, end);
    if (!r) {
      break;
    }
    ++c;
  }

  return {s.cbegin(), i};
}

// NOLINTEND(readability-magic-numbers)
}  // namespace McBopomofo
