// Copyright (c) 2024 and onwards The McBopomofo Authors.
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

#ifndef SRC_ENGINE_ASSOCIATEDPHRASESV2_H_
#define SRC_ENGINE_ASSOCIATEDPHRASESV2_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "MemoryMappedFile.h"
#include "ParselessPhraseDB.h"

namespace McBopomofo {

class AssociatedPhrasesV2 {
 public:
  ~AssociatedPhrasesV2();

  bool open(const char* path);
  void close();

  // Allows the use of existing in-memory db.
  bool open(std::unique_ptr<ParselessPhraseDB> db);

  // An associated phrase entry that includes its prefix. For example if an
  // entry is found with the prefix "輸-ㄕㄨ", the entry's value may be
  // 輸入法, and the readings are [ㄕㄨ, ㄖㄨˋ, ㄈㄚˇ].
  struct Phrase {
    Phrase(std::string v, std::vector<std::string> r)
        : value(std::move(v)), readings(std::move(r)) {}

    // Convenience for getting combined reading such as ㄕㄨ-ㄖㄨˋ-ㄈㄚˇ.
    std::string combinedReading() const;

    const std::string value;
    const std::vector<std::string> readings;
  };

  // Returns associated phrases using the prefix value and readings. It assumes
  // that the prefix value consists of the same number of Unicode code points
  // as the number of the readings. For example, a prefixValue of 輸入 should
  // have a prefixReadings of [ㄕㄨ, ㄖㄨˋ].
  //
  // Note though, that we allow a special case where only a single-codepoint
  // prefixValue is given with an *empty* prefixReadings. In that case, the
  // behavior will be exactly like that of our previous implementation of
  // associated phrases, where we were only able to search with single-codepoint
  // prefix values (such as using 輸 to find phrases like 輸入法).
  std::vector<Phrase> findPhrases(
      const std::string& prefixValue,
      const std::vector<std::string>& prefixReadings) const;

  // Convenience for splitting reading, e.g. "ㄕㄨ-ㄖㄨˋ" to ["ㄕㄨ", "ㄖㄨˋ"].
  static std::vector<std::string> SplitReadings(
      const std::string& combinedReading);

  // Convenience for combining e.g. ["ㄕㄨ", "ㄖㄨˋ"] to "ㄕㄨ-ㄖㄨˋ".
  static std::string CombineReadings(const std::vector<std::string>& readings);

 protected:
  std::vector<Phrase> findPhrases(const std::string& internalPrefix) const;

  MemoryMappedFile mmapedFile_;
  std::unique_ptr<ParselessPhraseDB> db_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_ASSOCIATEDPHRASESV2_H_
