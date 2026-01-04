// Copyright (c) 2026 and onwards The McBopomofo Authors.
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

#ifndef SRC_ENGINE_VARIANTANNOTATOR_H_
#define SRC_ENGINE_VARIANTANNOTATOR_H_

#include <filesystem>
#include <memory>
#include <string>

#include "MemoryMappedFile.h"
#include "ParselessPhraseDB.h"

namespace McBopomofo {

class VariantAnnotator {
 public:
  // Loads the compiled bpmfvs PUA code point db.
  [[nodiscard]] bool loadPUAFile(const std::filesystem::path& bpmfvsPUAPath);

  // Loads the compiled bpmfvs Unicode Variant Selector db.
  [[nodiscard]] bool loadVariantsFile(
      const std::filesystem::path& bpmfvsVariantsPath);

  // Utility functions to allow loading in-memory data for testing purposes.
  void loadPUAMap(std::unique_ptr<ParselessPhraseDB> puaMap);
  void loadVariantsMap(std::unique_ptr<ParselessPhraseDB> variantsMap);

  // Whether both databases are loaded and the instance is ready to use.
  [[nodiscard]] bool loaded() const;

  struct Result {
    // The string with maybe a variant selector and/or a code point in the PUA.
    std::string annotatedString;

    // Whether the string contains an invisible Unicode variant selector.
    bool hasVariantSelectors = false;

    // Whether the string contains a combined Bopomofo block from the PUA.
    bool hasPUACodePoints = false;
  };

  [[nodiscard]] Result annotateSingleCharacter(
      const std::string& value, const std::string& reading) const;

  // Convenient struct for annotating a series of characters and readings.
  struct CombinedResult {
    std::string annotatedString;

    // A quick look-up table for accumulated string length, for the ease of
    // calculating composed string UTF-8 lengths. If a string represents two
    // code points with UTF-8 lengths of 3 bytes and 4 bytes each, then the
    // index 0 of the vector has value 0, index 1 has value 3, and index 2
    // has value 7. This is for the ease of computing the lengths.
    std::vector<size_t> accumulatedStringLength;

    // Whether the string contains any invisible Unicode variant selectors.
    bool hasVariantSelectors = false;

    // Whether the string contains any Bopomofo reading blocks from the PUA.
    bool hasPUACodePoints = false;
  };

  // Convenient method for annotating a sequence of characters and readings.
  // Mismatched character and reading counts result in an assertion failure.
  [[nodiscard]] CombinedResult annotate(
      const std::vector<std::string>& values,
      const std::vector<std::string>& readings) const;

 protected:
  [[nodiscard]] std::string findCombinedPUABopomofoReading(
      const std::string& reading) const;

  [[nodiscard]] std::string findDefaultOrAnnotatedVariant(
      const std::string& value, const std::string& reading) const;

  [[nodiscard]] std::string findUnannotatedVariant(
      const std::string& value) const;

  void closeMemoryMapFiles();

  std::unique_ptr<ParselessPhraseDB> variantsMap_;
  std::unique_ptr<ParselessPhraseDB> puaMap_;

  MemoryMappedFile bpmfvsVariantsFile_;
  MemoryMappedFile bpmfvsPUAFile_;
};

}  // namespace McBopomofo

#endif  // SRC_ENGINE_VARIANTANNOTATOR_H_
