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

#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
#if defined(__AVX512F__)
#include <immintrin.h>

#include <cstdint>
#else
#error AVX512 support required
#endif
#endif

#include "ByteBlockBackedDictionary.h"

namespace McBopomofo {

namespace {

const char* AdvanceToNextNonWhitespace(const char* ptr, const char* end) {
  while (ptr != end) {
    if (const char c = *ptr; c != ' ' && c != '\t') {
      break;
    }
    ++ptr;
  }
  return ptr;
}

const char* AdvanceToNextCRLF(const char* ptr, const char* end) {
  while (ptr != end) {
    if (const char c = *ptr; c == '\r' || c == '\n') {
      break;
    }
    ++ptr;
  }
  return ptr;
}

const char* AdvanceToNextContentCharacter(const char* ptr, const char* end,
                                          size_t& lineCounter) {
  while (ptr != end) {
    const char c = *ptr;

    if (c == '\n') {
      ++lineCounter;
    }

    if (c != ' ' && c != '\t' && c != '\r' && c != '\n') {
      break;
    }
    ++ptr;
  }
  return ptr;
}

const char* AdvanceToNextNonContentCharacter(const char* ptr, const char* end) {
  while (ptr != end) {
    if (const char c = *ptr; c == ' ' || c == '\t' || c == '\r' || c == '\n') {
      break;
    }
    ++ptr;
  }
  return ptr;
}

#ifndef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
const char* FindFirstNULL(const char* ptr, const char* end,
                          size_t* firstLineNumber = nullptr) {
  const char* i = ptr;
  while (i != end) {
    if (*i == 0) {
      break;
    }
    ++i;
  }

  // Only count the line number if there is indeed a NULL.
  if (i != end && firstLineNumber != nullptr) {
    size_t lineCounter = 1;
    while (ptr != i) {
      if (*ptr == '\n') {
        ++lineCounter;
      }
      ++ptr;
    }
    *firstLineNumber = lineCounter;
  }

  return i;
}
#endif

bool IsCRLF(char c) { return c == '\n' || c == '\r'; }

bool IsWhitespace(char c) { return c == ' ' || c == '\t'; }

#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512

const char* AVX512_AdvanceToNextCRLF(const char* ptr,
                                     const char* unaligned32End,
                                     const char* end) {
  const __m256i lfs = _mm256_set1_epi8('\n');
  const __m256i crs = _mm256_set1_epi8('\r');

  while (ptr < unaligned32End) {
    const __m256i block = _mm256_loadu_epi8(ptr);
    const __mmask32 foundLFs = _mm256_cmpeq_epi8_mask(block, lfs);
    const __mmask32 foundCRs = _mm256_cmpeq_epi8_mask(block, crs);
    const __mmask32 mask = _kor_mask32(foundLFs, foundCRs);
    if (mask != 0) {
      return ptr + _tzcnt_u32(mask);
    }

    ptr += 32;
  }

  return AdvanceToNextCRLF(ptr, end);
}

// Four chars: 0x09 (T), 0x0a (L), 0x0d (C), 0x20 (S)
// T maps to 0x01
// L maps to 0x02
// C maps to 0x04
// T|L|C = 0x07
// S maps to 0x08
alignas(32) constexpr uint8_t LO_NIBBLES_LOOKUP[32] = {
    0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02,
    0x00, 0x00, 0x04, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x01, 0x02, 0x00, 0x00, 0x04, 0x00, 0x00,
};

alignas(32) constexpr uint8_t HI_NIBBLES_LOOKUP[32] = {
    0x07, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x08, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
};

const char* AVX512_AdvanceToNextNonContentCharacter(const char* ptr,
                                                    const char* unaligned32End,
                                                    const char* end) {
  while (ptr < unaligned32End) {
    const __m256i input = _mm256_loadu_epi8(ptr);

    const __m256i mask = _mm256_set1_epi8(0x0f);
    const __m256i loNibbles = _mm256_and_si256(input, mask);
    const __m256i hiNibbles =
        _mm256_and_si256(_mm256_srli_epi16(input, 4), mask);
    const __m256i loTbl =
        _mm256_load_si256(reinterpret_cast<const __m256i*>(LO_NIBBLES_LOOKUP));
    const __m256i lo = _mm256_shuffle_epi8(loTbl, loNibbles);
    const __m256i hiTbl =
        _mm256_load_si256(reinterpret_cast<const __m256i*>(HI_NIBBLES_LOOKUP));
    const __m256i hi = _mm256_shuffle_epi8(hiTbl, hiNibbles);
    const __m256i intersection = _mm256_and_si256(lo, hi);
    const __mmask32 nonContentMask =
        _mm256_cmpneq_epi8_mask(intersection, _mm256_setzero_si256());
    if (nonContentMask != 0) {
      return ptr + _tzcnt_u32(nonContentMask);
    }
    ptr += 32;
  }

  return AdvanceToNextNonContentCharacter(ptr, end);
}

constexpr uintptr_t ALIGN64 = 64;
constexpr uintptr_t ALIGN64_MASK = ALIGN64 - 1;

const char* AVX512_FindFirstNULL(const char* ptr, const char* end,
                                 size_t* firstLineNumber = nullptr) {
  const char* i = ptr;
  bool found = false;
  if ((reinterpret_cast<uintptr_t>(i) & ALIGN64_MASK) != 0) {
    const char* headEnd = reinterpret_cast<const char*>(
        reinterpret_cast<uintptr_t>(i + ALIGN64_MASK) & ~ALIGN64_MASK);
    headEnd = headEnd < end ? headEnd : end;
    while (i != headEnd) {
      if (*i == '\0') {
        found = true;
        break;
      }
      ++i;
    }
  }

  if (!found && i != end) {
    const char* middleEnd = reinterpret_cast<const char*>(
        reinterpret_cast<uintptr_t>(end) & ~ALIGN64_MASK);
    const __m512i zeros = _mm512_setzero_si512();
    while (i != middleEnd) {
      const __m512i block = _mm512_load_si512(i);
      const __mmask64 mask = _mm512_cmpeq_epi8_mask(block, zeros);
      if (mask != 0) {
        found = true;
        i += _tzcnt_u32(mask);
        break;
      }
      i += ALIGN64;
    }
  }

  if (!found) {
    while (i != end) {
      if (*i == 0) {
        found = true;
        break;
      }
      ++i;
    }
  }

  if (!found || firstLineNumber == nullptr) {
    return i;
  }

  size_t lineCounter = 1;
  if ((reinterpret_cast<uintptr_t>(ptr) & ALIGN64_MASK) != 0) {
    const char* headEnd = reinterpret_cast<const char*>(
        reinterpret_cast<uintptr_t>(ptr + ALIGN64_MASK) & ~ALIGN64_MASK);
    headEnd = headEnd < i ? headEnd : i;
    while (ptr != headEnd) {
      if (*ptr == '\n') {
        ++lineCounter;
      }
      ++ptr;
    }
  }

  if (ptr != i) {
    const char* middleEnd = reinterpret_cast<const char*>(
        reinterpret_cast<uintptr_t>(i) & ~ALIGN64_MASK);
    const __m512i linefeeds = _mm512_set1_epi8('\n');
    while (ptr != middleEnd) {
      const __m512i block = _mm512_load_si512(ptr);
      const __mmask64 mask = _mm512_cmpeq_epi8_mask(block, linefeeds);
      lineCounter += _mm_popcnt_u64(mask);
      ptr += ALIGN64;
    }
  }

  while (ptr != i) {
    if (*ptr == '\n') {
      ++lineCounter;
    }
    ++ptr;
  }
  *firstLineNumber = lineCounter;
  return i;
}

#endif

}  // namespace

void ByteBlockBackedDictionary::clear() {
  dict_.clear();
  issues_.clear();
}

bool ByteBlockBackedDictionary::parse(const char* block, size_t size,
                                      ColumnOrder columnOrder) {
  if (block == nullptr) {
    return false;
  }

  if (size == 0) {
    return false;
  }

  clear();

  // Special case if block is a null-ended C string. This is the only place
  // NUL is allowed.
  if (block[size - 1] == 0) {
    --size;
  }

  const char* ptr = block;
  const char* end = ptr + size;

#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
  const char* unaligned32End =
      reinterpret_cast<const char*>(reinterpret_cast<uintptr_t>(end) - 32);
  if (unaligned32End < ptr) {
    unaligned32End = ptr;
  }
#endif

  // Validate that no NULL characters are in the text.
  size_t errorAtLine = 0;
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
  const char* ctrlCharPtr = AVX512_FindFirstNULL(ptr, end, &errorAtLine);
#else
  const char* ctrlCharPtr = FindFirstNULL(ptr, end, &errorAtLine);
#endif

  if (ctrlCharPtr != end) {
    issues_.emplace_back(Issue::Type::NULL_CHARACTER_IN_TEXT, errorAtLine);
    return false;
  }

  size_t lineCounter = 1;

  if (columnOrder == ColumnOrder::KEY_THEN_VALUE) {
    while (ptr != end) {
      ptr = AdvanceToNextContentCharacter(ptr, end, lineCounter);
      if (ptr == end) {
        break;
      }

      if (*ptr == '#') {
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
        ptr = AVX512_AdvanceToNextCRLF(ptr, unaligned32End, end);
#else
        ptr = AdvanceToNextCRLF(ptr, end);
#endif
        continue;
      }

      const char* keyStart = ptr;
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
      ptr = AVX512_AdvanceToNextNonContentCharacter(ptr, unaligned32End, end);
#else
      ptr = AdvanceToNextNonContentCharacter(ptr, end);
#endif
      const char* keyEnd = ptr;

      ptr = AdvanceToNextNonWhitespace(ptr, end);
      if (ptr == end || IsCRLF(*ptr)) {
        if (issues_.size() < MAX_ISSUES) {
          issues_.emplace_back(Issue::Type::MISSING_SECOND_COLUMN, lineCounter);
        }

        continue;
      }

      const char* valueStart = ptr;
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
      ptr = AVX512_AdvanceToNextCRLF(ptr, unaligned32End, end);
#else
      ptr = AdvanceToNextCRLF(ptr, end);
#endif
      const char* valueEnd = ptr;

      if (valueEnd == valueStart) {
        if (issues_.size() < MAX_ISSUES) {
          issues_.emplace_back(Issue::Type::MISSING_SECOND_COLUMN, lineCounter);
        }
        continue;
      }

      // Strip the trailing space in the value. If valuePtr already equals
      // valueStart at this point, the following test won't be true, since
      // *valueStart is a content character.
      if (IsWhitespace(*(valueEnd - 1))) {
        // DO NOT MOVE the next assignment before the test. In other words,
        // do not do IsWhitespace(*valuePtr) first. Benchmarking showed that
        // this extra load upfront resulted in performance penalty on x86_64.
        const char* valuePtr = valueEnd - 1;
        do {
          --valuePtr;
        } while (IsWhitespace(*valuePtr) && valuePtr != valueStart);
        valueEnd = valuePtr + 1;

        // This may be an assertion, but let's just be safe.
        if (valuePtr == valueStart) {
          if (issues_.size() < MAX_ISSUES) {
            issues_.emplace_back(Issue::Type::MISSING_SECOND_COLUMN,
                                 lineCounter);
          }
          continue;
        }
      }

      std::string_view key(keyStart, keyEnd - keyStart);
      std::string_view value(valueStart, valueEnd - valueStart);
      dict_[key].emplace_back(value);
    }
  } else {
    while (ptr != end) {
      ptr = AdvanceToNextContentCharacter(ptr, end, lineCounter);
      if (ptr == end) {
        break;
      }

      if (*ptr == '#') {
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
        ptr = AVX512_AdvanceToNextCRLF(ptr, unaligned32End, end);
#else
        ptr = AdvanceToNextCRLF(ptr, end);
#endif
        continue;
      }

      const char* valueStart = ptr;
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
      ptr = AVX512_AdvanceToNextNonContentCharacter(ptr, unaligned32End, end);
#else
      ptr = AdvanceToNextNonContentCharacter(ptr, end);
#endif
      const char* valueEnd = ptr;

      ptr = AdvanceToNextNonWhitespace(ptr, end);
      if (ptr == end || IsCRLF(*ptr)) {
        if (issues_.size() < MAX_ISSUES) {
          issues_.emplace_back(Issue::Type::MISSING_SECOND_COLUMN, lineCounter);
        }
        continue;
      }

      const char* maybeKeyStart = ptr;
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
      ptr = AVX512_AdvanceToNextNonContentCharacter(ptr, unaligned32End, end);
#else
      ptr = AdvanceToNextNonContentCharacter(ptr, end);
#endif
      const char* maybeKeyEnd = ptr;
      if (maybeKeyStart == maybeKeyEnd) {
        if (issues_.size() < MAX_ISSUES) {
          issues_.emplace_back(Issue::Type::MISSING_SECOND_COLUMN, lineCounter);
        }
        continue;
      }

      while (ptr != end) {
        // Skip any trailing space
        if (IsWhitespace(*ptr)) {
          ptr = AdvanceToNextNonWhitespace(ptr, end);
        }

        if (ptr == end || IsCRLF(*ptr)) {
          // We have the real key-value columns, now break.
          break;
        }

        // More content incoming.
        valueEnd = maybeKeyEnd;
        maybeKeyStart = ptr;
#ifdef ENABLE_EXPERIMENTAL_SIMD_SUPPORT_AVX512
        ptr = AVX512_AdvanceToNextNonContentCharacter(ptr, unaligned32End, end);
#else
        ptr = AdvanceToNextNonContentCharacter(ptr, end);
#endif
        maybeKeyEnd = ptr;
      }

      std::string_view key(maybeKeyStart, maybeKeyEnd - maybeKeyStart);
      std::string_view value(valueStart, valueEnd - valueStart);
      dict_[key].emplace_back(value);
    }
  }

  return true;
}

bool ByteBlockBackedDictionary::hasKey(const std::string_view& key) const {
  return dict_.find(key) != dict_.end();
}

std::vector<std::string_view> ByteBlockBackedDictionary::getValues(
    const std::string_view& key) const {
  const auto it = dict_.find(key);
  if (it == dict_.cend()) {
    return {};
  }
  return it->second;
}

}  // namespace McBopomofo
