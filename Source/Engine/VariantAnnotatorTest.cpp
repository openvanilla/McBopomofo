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
#include "gtest/gtest.h"

namespace McBopomofo {

constexpr std::string_view kTestVariantsData =
    u8"# format org.openvanilla.mcbopomofo.sorted\n"
    u8"一-na 一\U000E01E0\n"
    u8"一-ㄧ 一\n"
    u8"一-ㄧˊ 一\U000E01E1\n"
    u8"一-ㄧˋ 一\U000E01E2\n"
    u8"個-na 個\U000E01E0\n"
    u8"個-ㄍㄜˇ 個\U000E01E2\n"
    u8"個-ㄍㄜˋ 個\n"
    u8"個-ㄍㄜ˙ 個\U000E01E1";

constexpr std::string_view kTestPUAData =
    u8"# format org.openvanilla.mcbopomofo.sorted\n"
    u8"ㄍㄚˋ \uF145\n"
    u8"ㄧㄚˊ \uF4BB";

static std::unique_ptr<VariantAnnotator> CreateLoadedAnnotator() {
  auto annotator = std::make_unique<VariantAnnotator>();
  annotator->loadVariantsMap(ParselessPhraseDB::CreateValidatedDB(
      kTestVariantsData.data(), kTestVariantsData.length()));
  annotator->loadPUAMap(ParselessPhraseDB::CreateValidatedDB(
      kTestPUAData.data(), kTestPUAData.length()));
  EXPECT_TRUE(annotator->loaded());
  return annotator;
}

TEST(VariantAnnotatorTest, EmptyState) {
  VariantAnnotator annotator;
  EXPECT_FALSE(annotator.loaded());

  VariantAnnotator::Result result =
      annotator.annotateSingleCharacter("個", "ㄍㄜˋ");
  EXPECT_TRUE(result.annotatedString.empty());
  EXPECT_FALSE(result.hasPUACodePoints);
  EXPECT_FALSE(result.hasVariantSelectors);

  VariantAnnotator::CombinedResult combinedResult =
      annotator.annotate({"個"}, {"ㄍㄜˋ"});
  EXPECT_TRUE(combinedResult.annotatedString.empty());
  EXPECT_FALSE(combinedResult.hasPUACodePoints);
  EXPECT_FALSE(combinedResult.hasVariantSelectors);
}

TEST(VariantAnnotatorTest, SingleCharacterAnnotationWithTheDefaultCharacter) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::Result result =
      annotator->annotateSingleCharacter("個", "ㄍㄜˋ");
  EXPECT_EQ(result.annotatedString, "個");
  EXPECT_FALSE(result.hasVariantSelectors);
  EXPECT_FALSE(result.hasPUACodePoints);
}

TEST(VariantAnnotatorTest, SingleCharacterAnnotationWithVariantSelector) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::Result result =
      annotator->annotateSingleCharacter("個", "ㄍㄜ˙");
  EXPECT_EQ(result.annotatedString, u8"個\U000E01E1");
  EXPECT_TRUE(result.hasVariantSelectors);
  EXPECT_FALSE(result.hasPUACodePoints);
}

TEST(VariantAnnotatorTest, SingleCharacterAnnotationWithVariant0AndPUA) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::Result result =
      annotator->annotateSingleCharacter("個", "ㄍㄚˋ");
  EXPECT_EQ(result.annotatedString, u8"個\U000E01E0\uF145");
  EXPECT_TRUE(result.hasVariantSelectors);
  EXPECT_TRUE(result.hasPUACodePoints);
}

TEST(VariantAnnotatorTest, SingleCharacterAnnotationWithVariant0AndNoPUA) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::Result result =
      annotator->annotateSingleCharacter("個", "ㄍ");
  EXPECT_EQ(result.annotatedString, u8"個\U000E01E0");
  EXPECT_TRUE(result.hasVariantSelectors);
  EXPECT_FALSE(result.hasPUACodePoints);
}

TEST(VariantAnnotatorTest, SingleCharacterAnnotationWithUnknownCharacter) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::Result result =
      annotator->annotateSingleCharacter("人", "ㄖㄣˊ");
  EXPECT_EQ(result.annotatedString, u8"人");
  EXPECT_FALSE(result.hasVariantSelectors);
  EXPECT_FALSE(result.hasPUACodePoints);
}

TEST(VariantAnnotatorTest, AnnotateCharacters) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::CombinedResult result = annotator->annotate(
      {"個", "人", "一", "個", "人", "一", "個"},
      {"ㄍㄜˋ", "ㄖㄣˊ", "ㄧˊ", "ㄍㄜ˙", "ㄖㄣˊ", "ㄧ", "ㄍㄚˋ"});
  EXPECT_EQ(result.annotatedString,
            u8"個人一\U000E01E1個\U000E01E1人一個\U000E01E0\uF145");
  EXPECT_TRUE(result.hasVariantSelectors);
  EXPECT_TRUE(result.hasPUACodePoints);
  EXPECT_EQ(result.accumulatedStringLength.size(), 8);
  EXPECT_EQ(result.accumulatedStringLength[0], 0);
  EXPECT_EQ(result.accumulatedStringLength[1], strlen(u8"個"));
  EXPECT_EQ(result.accumulatedStringLength[3], strlen(u8"個人一\U000E01E1"));
  EXPECT_EQ(result.accumulatedStringLength[6],
            strlen(u8"個人一\U000E01E1個\U000E01E1人一"));
  EXPECT_EQ(result.accumulatedStringLength[7], result.annotatedString.size());
}

TEST(VariantAnnotatorTest, AnnotateCharactersWithMismatchedArguments) {
#ifdef NDEBUG
  GTEST_SKIP();
#endif
  auto annotator = CreateLoadedAnnotator();
  EXPECT_DEATH((annotator->annotate({"個", "人", "一", "個", "人", "一", "個"},
                                    {"ㄍㄜˋ", "ㄖㄣˊ"})),
               "values.+readings");
}

TEST(VariantAnnotatorTest, AnnotateCharactersWithAllDefaults) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::CombinedResult result = annotator->annotate(
      {"個", "人", "一", "個", "人", "一", "個"},
      {"ㄍㄜˋ", "ㄖㄣˊ", "ㄧ", "ㄍㄜˋ", "ㄖㄣˊ", "ㄧ", "ㄍㄜˋ"});
  EXPECT_EQ(result.annotatedString, "個人一個人一個");
  EXPECT_FALSE(result.hasVariantSelectors);
  EXPECT_FALSE(result.hasPUACodePoints);
}

TEST(VariantAnnotatorTest, AnnotateCharactersWithVariant0AndPUA) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::CombinedResult result = annotator->annotate(
      {"個", "人", "一", "個", "人", "一", "個"},
      {"ㄍㄜˋ", "ㄖㄣˊ", "ㄧ", "ㄍㄜˋ", "ㄖㄣˊ", "ㄧ", "ㄍㄚˋ"});
  EXPECT_EQ(result.annotatedString, u8"個人一個人一個\U000E01E0\uF145");
  EXPECT_TRUE(result.hasVariantSelectors);
  EXPECT_TRUE(result.hasPUACodePoints);
}

TEST(VariantAnnotatorTest, AnnotateCharactersWithVariant0ButNoPUA) {
  auto annotator = CreateLoadedAnnotator();
  VariantAnnotator::CombinedResult result = annotator->annotate(
      {"個", "人", "一", "個", "人", "一", "個"},
      {"ㄍㄜˋ", "ㄖㄣˊ", "ㄧ", "ㄍㄜˋ", "ㄖㄣˊ", "ㄧ", "ㄍ"});
  EXPECT_EQ(result.annotatedString, u8"個人一個人一個\U000E01E0");
  EXPECT_TRUE(result.hasVariantSelectors);
  EXPECT_FALSE(result.hasPUACodePoints);
}

}  // namespace McBopomofo
