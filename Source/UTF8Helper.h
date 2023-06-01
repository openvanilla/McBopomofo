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

#ifndef SRC_UTF8HELPER_H_
#define SRC_UTF8HELPER_H_

#include <string>

namespace McBopomofo {

// Count the number of code points of a string encoded in UTF-8. If it
// encounters an invalid UTF-8 sequence, the returned value is the number of
// code points up to before that invalid sequence.
size_t CodePointCount(const std::string& s);

// Clamp the string by the cp code points. If the string is shorter, the result
// is a copy of s. If s contains some invalid UTF-8 sequence, the returned value
// will be the string clamped up to before that invalid sequence.
std::string SubstringToCodePoints(const std::string& s, size_t cp);

}  // namespace McBopomofo

#endif  // SRC_UTF8HELPER_H_
