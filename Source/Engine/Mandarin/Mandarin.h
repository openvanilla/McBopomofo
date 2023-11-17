// Copyright (c) 2006 and onwards Lukhnos Liu
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

#ifndef MANDARIN_H_
#define MANDARIN_H_

#include <cstdint>
#include <iostream>
#include <map>
#include <string>
#include <vector>

namespace Formosa {
namespace Mandarin {

class BopomofoSyllable {
 public:
  typedef uint16_t Component;

  explicit BopomofoSyllable(Component syllable = 0) : syllable_(syllable) {}

  BopomofoSyllable(const BopomofoSyllable&) = default;
  BopomofoSyllable(BopomofoSyllable&& another) = default;
  BopomofoSyllable& operator=(const BopomofoSyllable&) = default;
  BopomofoSyllable& operator=(BopomofoSyllable&&) = default;

  // takes the ASCII-form, "v"-tolerant, TW-style Hanyu Pinyin (fong, pong, bong
  // acceptable)
  static const BopomofoSyllable FromHanyuPinyin(const std::string& str);

  // TO DO: Support accented vowels
  const std::string HanyuPinyinString(bool includesTone,
                                      bool useVForUUmlaut) const;

  static const BopomofoSyllable FromComposedString(const std::string& str);
  const std::string composedString() const;

  void clear() { syllable_ = 0; }

  bool isEmpty() const { return !syllable_; }

  bool hasConsonant() const { return !!(syllable_ & ConsonantMask); }

  bool hasMiddleVowel() const { return !!(syllable_ & MiddleVowelMask); }
  bool hasVowel() const { return !!(syllable_ & VowelMask); }

  bool hasToneMarker() const { return !!(syllable_ & ToneMarkerMask); }

  Component consonantComponent() const { return syllable_ & ConsonantMask; }

  Component middleVowelComponent() const { return syllable_ & MiddleVowelMask; }

  Component vowelComponent() const { return syllable_ & VowelMask; }

  Component toneMarkerComponent() const { return syllable_ & ToneMarkerMask; }

  bool operator==(const BopomofoSyllable& another) const {
    return syllable_ == another.syllable_;
  }

  bool operator!=(const BopomofoSyllable& another) const {
    return syllable_ != another.syllable_;
  }

  bool isOverlappingWith(const BopomofoSyllable& another) const {
#define IOW_SAND(mask) ((syllable_ & mask) && (another.syllable_ & mask))
    return IOW_SAND(ConsonantMask) || IOW_SAND(MiddleVowelMask) ||
           IOW_SAND(VowelMask) || IOW_SAND(ToneMarkerMask);
#undef IOW_SAND
  }

  // consonants J, Q, X all require the existence of vowel I or UE
  bool belongsToJQXClass() const {
    Component consonant = syllable_ & ConsonantMask;
    return (consonant == J || consonant == Q || consonant == X);
  }

  // zi, ci, si, chi, chi, shi, ri
  bool belongsToZCSRClass() const {
    Component consonant = syllable_ & ConsonantMask;
    return (consonant >= ZH && consonant <= S);
  }

  Component maskType() const {
    Component mask = 0;
    mask |= (syllable_ & ConsonantMask) ? ConsonantMask : 0;
    mask |= (syllable_ & MiddleVowelMask) ? MiddleVowelMask : 0;
    mask |= (syllable_ & VowelMask) ? VowelMask : 0;
    mask |= (syllable_ & ToneMarkerMask) ? ToneMarkerMask : 0;
    return mask;
  }

  const BopomofoSyllable operator+(const BopomofoSyllable& another) const {
    Component newSyllable = syllable_;
#define OP_SOVER(mask)                                                \
  if (another.syllable_ & mask) {                                     \
    newSyllable = (newSyllable & ~mask) | (another.syllable_ & mask); \
  }
    OP_SOVER(ConsonantMask);
    OP_SOVER(MiddleVowelMask);
    OP_SOVER(VowelMask);
    OP_SOVER(ToneMarkerMask);
#undef OP_SOVER
    return BopomofoSyllable(newSyllable);
  }

  BopomofoSyllable& operator+=(const BopomofoSyllable& another) {
#define OPE_SOVER(mask)                                           \
  if (another.syllable_ & mask) {                                 \
    syllable_ = (syllable_ & ~mask) | (another.syllable_ & mask); \
  }
    OPE_SOVER(ConsonantMask);
    OPE_SOVER(MiddleVowelMask);
    OPE_SOVER(VowelMask);
    OPE_SOVER(ToneMarkerMask);
#undef OPE_SOVER
    return *this;
  }

  friend std::ostream& operator<<(std::ostream& stream,
                                  const BopomofoSyllable& syllable);

  static constexpr Component
      ConsonantMask = 0x001f,    // 0000 0000 0001 1111, 21 consonants
      MiddleVowelMask = 0x0060,  // 0000 0000 0110 0000, 3 middle vowels
      VowelMask = 0x0780,        // 0000 0111 1000 0000, 13 vowels
      ToneMarkerMask = 0x3800,   // 0011 1000 0000 0000, 5 tones (tone1 = 0x00)
      B = 0x0001, P = 0x0002, M = 0x0003, F = 0x0004, D = 0x0005, T = 0x0006,
      N = 0x0007, L = 0x0008, G = 0x0009, K = 0x000a, H = 0x000b, J = 0x000c,
      Q = 0x000d, X = 0x000e, ZH = 0x000f, CH = 0x0010, SH = 0x0011, R = 0x0012,
      Z = 0x0013, C = 0x0014, S = 0x0015, I = 0x0020, U = 0x0040,
      UE = 0x0060,  // ue = u umlaut (we use the German convention here as an
                    // ersatz to the /ju:/ sound)
      A = 0x0080, O = 0x0100, ER = 0x0180, E = 0x0200, AI = 0x0280, EI = 0x0300,
      AO = 0x0380, OU = 0x0400, AN = 0x0480, EN = 0x0500, ANG = 0x0580,
      ENG = 0x0600, ERR = 0x0680, Tone1 = 0x0000, Tone2 = 0x0800,
      Tone3 = 0x1000, Tone4 = 0x1800, Tone5 = 0x2000;

 protected:
  Component syllable_;
};

inline std::ostream& operator<<(std::ostream& stream,
                                const BopomofoSyllable& syllable) {
  stream << syllable.composedString();
  return stream;
}

typedef BopomofoSyllable BPMF;

typedef std::map<char, std::vector<BPMF::Component> > BopomofoKeyToComponentMap;
typedef std::map<BPMF::Component, char> BopomofoComponentToKeyMap;

class BopomofoKeyboardLayout {
 public:
  static const BopomofoKeyboardLayout* StandardLayout();
  static const BopomofoKeyboardLayout* ETenLayout();
  static const BopomofoKeyboardLayout* HsuLayout();
  static const BopomofoKeyboardLayout* ETen26Layout();
  static const BopomofoKeyboardLayout* IBMLayout();
  static const BopomofoKeyboardLayout* HanyuPinyinLayout();

  BopomofoKeyboardLayout(const BopomofoKeyToComponentMap& ktcm,
                         const std::string& name)
      : m_name(name), m_keyToComponent(ktcm) {
    for (BopomofoKeyToComponentMap::const_iterator miter =
             m_keyToComponent.begin();
         miter != m_keyToComponent.end(); ++miter)
      for (std::vector<BPMF::Component>::const_iterator viter =
               (*miter).second.begin();
           viter != (*miter).second.end(); ++viter)
        m_componentToKey[*viter] = (*miter).first;
  }

  const std::string name() const { return m_name; }

  char componentToKey(BPMF::Component component) const {
    BopomofoComponentToKeyMap::const_iterator iter =
        m_componentToKey.find(component);
    return (iter == m_componentToKey.end()) ? 0 : (*iter).second;
  }

  const std::vector<BPMF::Component> keyToComponents(char key) const {
    BopomofoKeyToComponentMap::const_iterator iter = m_keyToComponent.find(key);
    return (iter == m_keyToComponent.end()) ? std::vector<BPMF::Component>()
                                            : (*iter).second;
  }

  const std::string keySequenceFromSyllable(BPMF syllable) const {
    std::string sequence;

    BPMF::Component c;
    char k;
#define STKS_COMBINE(component)                                 \
  if ((c = component)) {                                        \
    if ((k = componentToKey(c))) sequence += std::string(1, k); \
  }
    STKS_COMBINE(syllable.consonantComponent());
    STKS_COMBINE(syllable.middleVowelComponent());
    STKS_COMBINE(syllable.vowelComponent());
    STKS_COMBINE(syllable.toneMarkerComponent());
#undef STKS_COMBINE
    return sequence;
  }

  const BPMF syllableFromKeySequence(const std::string& sequence) const {
    BPMF syllable;

    for (std::string::const_iterator iter = sequence.begin();
         iter != sequence.end(); ++iter) {
      bool beforeSeqHasIorUE = sequenceContainsIorUE(sequence.begin(), iter);
      bool aheadSeqHasIorUE = sequenceContainsIorUE(iter + 1, sequence.end());

      std::vector<BPMF::Component> components = keyToComponents(*iter);

      if (!components.size()) continue;

      if (components.size() == 1) {
        syllable += BPMF(components[0]);
        continue;
      }

      BPMF head = BPMF(components[0]);
      BPMF follow = BPMF(components[1]);
      BPMF ending = components.size() > 2 ? BPMF(components[2]) : follow;

      // apply the I/UE + E rule
      if (head.vowelComponent() == BPMF::E &&
          follow.vowelComponent() != BPMF::E) {
        syllable += beforeSeqHasIorUE ? head : follow;
        continue;
      }

      if (head.vowelComponent() != BPMF::E &&
          follow.vowelComponent() == BPMF::E) {
        syllable += beforeSeqHasIorUE ? follow : head;
        continue;
      }

      // apply the J/Q/X + I/UE rule, only two components are allowed in the
      // components vector here
      if (head.belongsToJQXClass() && !follow.belongsToJQXClass()) {
        if (!syllable.isEmpty()) {
          if (ending != follow) syllable += ending;
        } else {
          syllable += aheadSeqHasIorUE ? head : follow;
        }

        continue;
      }

      if (!head.belongsToJQXClass() && follow.belongsToJQXClass()) {
        if (!syllable.isEmpty()) {
          if (ending != follow) syllable += ending;
        } else {
          syllable += aheadSeqHasIorUE ? follow : head;
        }

        continue;
      }

      // the nasty issue of only one char in the buffer
      if (iter == sequence.begin() && iter + 1 == sequence.end()) {
        if (head.hasVowel() || follow.hasToneMarker() ||
            head.belongsToZCSRClass()) {
          syllable += head;
        } else {
          if (follow.hasVowel() || ending.hasToneMarker()) {
            syllable += follow;
          } else {
            syllable += ending;
          }
        }

        continue;
      }

      if (!(syllable.maskType() & head.maskType()) &&
          !endAheadOrAheadHasToneMarkKey(iter + 1, sequence.end())) {
        syllable += head;
      } else {
        if (endAheadOrAheadHasToneMarkKey(iter + 1, sequence.end()) &&
            head.belongsToZCSRClass() && syllable.isEmpty()) {
          syllable += head;
        } else if (syllable.maskType() < follow.maskType()) {
          syllable += follow;
        } else {
          syllable += ending;
        }
      }
    }

    // heuristics for Hsu keyboard layout
    if (this == HsuLayout()) {
      // fix the left out L to ERR when it has sound, and GI, GUE -> JI, JUE
      if (syllable.vowelComponent() == BPMF::ENG && !syllable.hasConsonant() &&
          !syllable.hasMiddleVowel()) {
        syllable += BPMF(BPMF::ERR);
      } else if (syllable.consonantComponent() == BPMF::G &&
                 (syllable.middleVowelComponent() == BPMF::I ||
                  syllable.middleVowelComponent() == BPMF::UE)) {
        syllable += BPMF(BPMF::J);
      }
    }

    return syllable;
  }

 protected:
  bool endAheadOrAheadHasToneMarkKey(std::string::const_iterator ahead,
                                     std::string::const_iterator end) const {
    if (ahead == end) return true;

    char tone1 = componentToKey(BPMF::Tone1);
    char tone2 = componentToKey(BPMF::Tone2);
    char tone3 = componentToKey(BPMF::Tone3);
    char tone4 = componentToKey(BPMF::Tone4);
    char tone5 = componentToKey(BPMF::Tone5);

    if (tone1)
      if (*ahead == tone1) return true;

    if (*ahead == tone2 || *ahead == tone3 || *ahead == tone4 ||
        *ahead == tone5)
      return true;

    return false;
  }

  bool sequenceContainsIorUE(std::string::const_iterator start,
                             std::string::const_iterator end) const {
    char iChar = componentToKey(BPMF::I);
    char ueChar = componentToKey(BPMF::UE);

    for (; start != end; ++start)
      if (*start == iChar || *start == ueChar) return true;
    return false;
  }

  std::string m_name;
  BopomofoKeyToComponentMap m_keyToComponent;
  BopomofoComponentToKeyMap m_componentToKey;
};

class BopomofoReadingBuffer {
 public:
  explicit BopomofoReadingBuffer(const BopomofoKeyboardLayout* layout)
      : layout_(layout), pinyin_mode_(false) {
    if (layout == BopomofoKeyboardLayout::HanyuPinyinLayout()) {
      pinyin_mode_ = true;
      pinyin_sequence_ = "";
    }
  }

  void setKeyboardLayout(const BopomofoKeyboardLayout* layout) {
    layout_ = layout;

    if (layout == BopomofoKeyboardLayout::HanyuPinyinLayout()) {
      pinyin_mode_ = true;
      pinyin_sequence_ = "";
    }
  }

  const BopomofoKeyboardLayout* keyboardLayout() const { return layout_; }

  bool isValidKey(char k) const {
    if (!pinyin_mode_) {
      return layout_ ? (layout_->keyToComponents(k)).size() > 0 : false;
    }

    char lk = tolower(k);
    if (lk >= 'a' && lk <= 'z') {
      // if a tone marker is already in place
      if (pinyin_sequence_.length()) {
        char lastc = pinyin_sequence_[pinyin_sequence_.length() - 1];
        if (lastc >= '2' && lastc <= '5') {
          return false;
        }
        return true;
      }
      return true;
    }

    if (pinyin_sequence_.length() && (lk >= '2' && lk <= '5')) {
      return true;
    }

    return false;
  }

  bool combineKey(char k) {
    if (!isValidKey(k)) return false;

    if (pinyin_mode_) {
      pinyin_sequence_ += std::string(1, tolower(k));
      syllable_ = BPMF::FromHanyuPinyin(pinyin_sequence_);
      return true;
    }

    std::string sequence =
        layout_->keySequenceFromSyllable(syllable_) + std::string(1, k);
    syllable_ = layout_->syllableFromKeySequence(sequence);
    return true;
  }

  void clear() {
    pinyin_sequence_.clear();
    syllable_.clear();
  }

  void backspace() {
    if (!layout_) return;

    if (pinyin_mode_) {
      if (pinyin_sequence_.length()) {
        pinyin_sequence_ =
            pinyin_sequence_.substr(0, pinyin_sequence_.length() - 1);
      }

      syllable_ = BPMF::FromHanyuPinyin(pinyin_sequence_);
      return;
    }

    std::string sequence = layout_->keySequenceFromSyllable(syllable_);
    if (sequence.length()) {
      sequence = sequence.substr(0, sequence.length() - 1);
      syllable_ = layout_->syllableFromKeySequence(sequence);
    }
  }

  bool isEmpty() const { return syllable_.isEmpty(); }

  const std::string composedString() const {
    if (pinyin_mode_) {
      return pinyin_sequence_;
    }

    return syllable_.composedString();
  }

  const BPMF syllable() const { return syllable_; }

  const std::string standardLayoutQueryString() const {
    return BopomofoKeyboardLayout::StandardLayout()->keySequenceFromSyllable(
        syllable_);
  }

  bool hasToneMarker() const { return syllable_.hasToneMarker(); }

  bool hasToneMarkerOnly() const {
    return syllable_.hasToneMarker() &&
           !(syllable_.hasConsonant() || syllable_.hasMiddleVowel() ||
             syllable_.hasVowel());
  }

 protected:
  const BopomofoKeyboardLayout* layout_;
  BPMF syllable_;

  bool pinyin_mode_;
  std::string pinyin_sequence_;
};
}  // namespace Mandarin
}  // namespace Formosa

#endif  // MANDARIN_H_
