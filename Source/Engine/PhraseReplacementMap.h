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

#ifndef SRC_ENGINE_PHRASEREPLACEMENTMAP_H_
#define SRC_ENGINE_PHRASEREPLACEMENTMAP_H_

#include <iostream>
#include <map>
#include <string>

#include "MemoryMappedFile.h"

namespace McBopomofo {

class PhraseReplacementMap {
 public:
  PhraseReplacementMap() = default;
  PhraseReplacementMap(const PhraseReplacementMap&) = delete;
  PhraseReplacementMap(PhraseReplacementMap&&) = delete;
  PhraseReplacementMap& operator=(const PhraseReplacementMap&) = delete;
  PhraseReplacementMap& operator=(PhraseReplacementMap&&) = delete;

  bool open(const char* path);
  void close();

  // Allows loading existing in-memory data. It's the caller's responsibility
  // to make sure that data outlives this instance.
  bool load(const char* data, size_t length);

  std::string valueForKey(const std::string& key) const;

 protected:
  std::map<std::string_view, std::string_view> keyValueMap_;
  MemoryMappedFile mmapedFile_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_PHRASEREPLACEMENTMAP_H_
