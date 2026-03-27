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

#include "VariantAnnotator.h"

#include <cassert>

static constexpr char kDelimiterChar = ' ';
static constexpr char kSeparatorChar = '-';
static constexpr const char* kUnannotatedReading = "na";

namespace McBopomofo {

static std::string GetSecondColumn(std::string_view row) {
  auto it = row.cbegin();
  while (it != row.cend()) {
    if (*it == kDelimiterChar) {
      ++it;
      break;
    }
    ++it;
  }
  return {it, row.cend()};
}

bool VariantAnnotator::loadPUAFile(const std::filesystem::path& bpmfvsPUAPath) {
  MemoryMappedFile file;
  if (!file.open(bpmfvsPUAPath.c_str())) {
    return false;
  }

  auto db = ParselessPhraseDB::CreateValidatedDB(file.data(), file.length());
  if (!db) {
    file.close();
    return false;
  }

  puaMap_ = std::move(db);
  bpmfvsPUAFile_ = std::move(file);
  return true;
}

bool VariantAnnotator::loadVariantsFile(
    const std::filesystem::path& bpmfvsVariantsPath) {
  MemoryMappedFile file;
  if (!file.open(bpmfvsVariantsPath.c_str())) {
    return false;
  }

  auto db = ParselessPhraseDB::CreateValidatedDB(file.data(), file.length());
  if (!db) {
    file.close();
    return false;
  }

  variantsMap_ = std::move(db);
  bpmfvsVariantsFile_ = std::move(file);
  return true;
}

void VariantAnnotator::loadPUAMap(std::unique_ptr<ParselessPhraseDB> puaMap) {
  bpmfvsPUAFile_.close();
  puaMap_ = std::move(puaMap);
}

void VariantAnnotator::loadVariantsMap(
    std::unique_ptr<ParselessPhraseDB> variantsMap) {
  bpmfvsVariantsFile_.close();
  variantsMap_ = std::move(variantsMap);
}

bool VariantAnnotator::loaded() const {
  return variantsMap_ != nullptr && puaMap_ != nullptr;
}

VariantAnnotator::Result VariantAnnotator::annotateSingleCharacter(
    const std::string& value, const std::string& reading) const {
  if (!loaded()) {
    return {};
  }

  std::string variant = findDefaultOrAnnotatedVariant(value, reading);
  if (!variant.empty()) {
    // If variant != value, a variant selector must have been used.
    bool selectorUsed = variant != value;
    return Result{variant, selectorUsed, false};
  }

  // Now try the fallback.
  variant = findUnannotatedVariant(value);
  if (variant.empty() || variant == reading) {
    return Result{value, false, false};
  }

  std::string puaBlock = findCombinedPUABopomofoReading(reading);
  if (!puaBlock.empty()) {
    // The string is the value + Variant 0 selector + the Bopomofo block in PUA.
    return Result{variant + puaBlock, true, true};
  }

  // Only the unannotated Variant 0 is found.
  return Result{variant, true, false};
}

VariantAnnotator::CombinedResult VariantAnnotator::annotate(
    const std::vector<std::string>& values,
    const std::vector<std::string>& readings) const {
  assert(values.size() == readings.size());

  CombinedResult combinedResult;
  if (values.size() != readings.size()) {
    return combinedResult;
  }

  combinedResult.accumulatedStringLength.push_back(0);

  for (size_t i = 0, s = values.size(); i < s; i++) {
    Result result = annotateSingleCharacter(values[i], readings[i]);
    combinedResult.annotatedString += result.annotatedString;
    combinedResult.hasPUACodePoints |= result.hasPUACodePoints;
    combinedResult.hasVariantSelectors |= result.hasVariantSelectors;
    combinedResult.accumulatedStringLength.push_back(
        combinedResult.annotatedString.length());
  }
  return combinedResult;
}

std::string VariantAnnotator::findCombinedPUABopomofoReading(
    const std::string& reading) const {
  if (puaMap_ == nullptr) {
    return {};
  }

  std::string key = reading + kDelimiterChar;
  std::vector<std::string_view> readings = puaMap_->findRows(key);
  if (readings.empty()) {
    return {};
  }
  return GetSecondColumn(readings[0]);
}

std::string VariantAnnotator::findDefaultOrAnnotatedVariant(
    const std::string& value, const std::string& reading) const {
  if (variantsMap_ == nullptr) {
    return {};
  }

  std::string key = value + kSeparatorChar + reading + kDelimiterChar;
  std::vector<std::string_view> variants = variantsMap_->findRows(key);
  if (variants.empty()) {
    return {};
  }
  return GetSecondColumn(variants[0]);
}

std::string VariantAnnotator::findUnannotatedVariant(
    const std::string& value) const {
  return findDefaultOrAnnotatedVariant(value, kUnannotatedReading);
}

void VariantAnnotator::closeMemoryMapFiles() {
  puaMap_ = nullptr;
  variantsMap_ = nullptr;
  bpmfvsPUAFile_.close();
  bpmfvsVariantsFile_.close();
}

}  // namespace McBopomofo
