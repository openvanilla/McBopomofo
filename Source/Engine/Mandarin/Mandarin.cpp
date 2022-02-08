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

#include "Mandarin.h"

#include <algorithm>
#include <cctype>

namespace Formosa {
namespace Mandarin {

class PinyinParseHelper {
 public:
  static const bool ConsumePrefix(std::string& target,
                                  const std::string& prefix) {
    if (target.length() < prefix.length()) {
      return false;
    }

    if (target.substr(0, prefix.length()) == prefix) {
      target =
          target.substr(prefix.length(), target.length() - prefix.length());
      return true;
    }

    return false;
  }
};

class BopomofoCharacterMap {
 public:
  static const BopomofoCharacterMap& SharedInstance();

  std::map<BPMF::Component, std::string> componentToCharacter;
  std::map<std::string, BPMF::Component> characterToComponent;

 protected:
  BopomofoCharacterMap();
};

const BPMF BPMF::FromHanyuPinyin(const std::string& str) {
  if (!str.length()) {
    return BPMF();
  }

  std::string pinyin = str;
  transform(pinyin.begin(), pinyin.end(), pinyin.begin(), ::tolower);

  BPMF::Component firstComponent = 0;
  BPMF::Component secondComponent = 0;
  BPMF::Component thirdComponent = 0;
  BPMF::Component toneComponent = 0;

  // lookup consonants and consume them
  bool independentConsonant = false;

  // the y exceptions fist
  if (0) {
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "yuan")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::AN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ying")) {
    secondComponent = BPMF::I;
    thirdComponent = BPMF::ENG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "yung")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::ENG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "yong")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::ENG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "yue")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::E;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "yun")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "you")) {
    secondComponent = BPMF::I;
    thirdComponent = BPMF::OU;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "yu")) {
    secondComponent = BPMF::UE;
  }

  // try the first character
  char c = pinyin.length() ? pinyin[0] : 0;
  switch (c) {
    case 'b':
      firstComponent = BPMF::B;
      pinyin = pinyin.substr(1);
      break;
    case 'p':
      firstComponent = BPMF::P;
      pinyin = pinyin.substr(1);
      break;
    case 'm':
      firstComponent = BPMF::M;
      pinyin = pinyin.substr(1);
      break;
    case 'f':
      firstComponent = BPMF::F;
      pinyin = pinyin.substr(1);
      break;
    case 'd':
      firstComponent = BPMF::D;
      pinyin = pinyin.substr(1);
      break;
    case 't':
      firstComponent = BPMF::T;
      pinyin = pinyin.substr(1);
      break;
    case 'n':
      firstComponent = BPMF::N;
      pinyin = pinyin.substr(1);
      break;
    case 'l':
      firstComponent = BPMF::L;
      pinyin = pinyin.substr(1);
      break;
    case 'g':
      firstComponent = BPMF::G;
      pinyin = pinyin.substr(1);
      break;
    case 'k':
      firstComponent = BPMF::K;
      pinyin = pinyin.substr(1);
      break;
    case 'h':
      firstComponent = BPMF::H;
      pinyin = pinyin.substr(1);
      break;
    case 'j':
      firstComponent = BPMF::J;
      pinyin = pinyin.substr(1);
      break;
    case 'q':
      firstComponent = BPMF::Q;
      pinyin = pinyin.substr(1);
      break;
    case 'x':
      firstComponent = BPMF::X;
      pinyin = pinyin.substr(1);
      break;

    // special hanlding for w and y
    case 'w':
      secondComponent = BPMF::U;
      pinyin = pinyin.substr(1);
      break;
    case 'y':
      if (!secondComponent && !thirdComponent) {
        secondComponent = BPMF::I;
      }
      pinyin = pinyin.substr(1);
      break;
  }

  // then we try ZH, CH, SH, R, Z, C, S (in that order)
  if (0) {
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "zh")) {
    firstComponent = BPMF::ZH;
    independentConsonant = true;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ch")) {
    firstComponent = BPMF::CH;
    independentConsonant = true;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "sh")) {
    firstComponent = BPMF::SH;
    independentConsonant = true;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "r")) {
    firstComponent = BPMF::R;
    independentConsonant = true;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "z")) {
    firstComponent = BPMF::Z;
    independentConsonant = true;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "c")) {
    firstComponent = BPMF::C;
    independentConsonant = true;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "s")) {
    firstComponent = BPMF::S;
    independentConsonant = true;
  }

  // consume exceptions first: (ien, in), (iou, iu), (uen, un), (veng, iong),
  // (ven, vn), (uei, ui), ung but longer sequence takes precedence
  if (0) {
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "veng")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::ENG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "iong")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::ENG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ing")) {
    secondComponent = BPMF::I;
    thirdComponent = BPMF::ENG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ien")) {
    secondComponent = BPMF::I;
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "iou")) {
    secondComponent = BPMF::I;
    thirdComponent = BPMF::OU;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "uen")) {
    secondComponent = BPMF::U;
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ven")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "uei")) {
    secondComponent = BPMF::U;
    thirdComponent = BPMF::EI;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ung")) {
    // f exception
    if (firstComponent == BPMF::F) {
      thirdComponent = BPMF::ENG;
    } else {
      secondComponent = BPMF::U;
      thirdComponent = BPMF::ENG;
    }
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ong")) {
    // f exception
    if (firstComponent == BPMF::F) {
      thirdComponent = BPMF::ENG;
    } else {
      secondComponent = BPMF::U;
      thirdComponent = BPMF::ENG;
    }
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "un")) {
    if (firstComponent == BPMF::J || firstComponent == BPMF::Q ||
        firstComponent == BPMF::X) {
      secondComponent = BPMF::UE;
    } else {
      secondComponent = BPMF::U;
    }
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "iu")) {
    secondComponent = BPMF::I;
    thirdComponent = BPMF::OU;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "in")) {
    secondComponent = BPMF::I;
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "vn")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ui")) {
    secondComponent = BPMF::U;
    thirdComponent = BPMF::EI;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ue")) {
    secondComponent = BPMF::UE;
    thirdComponent = BPMF::E;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, u8"ü")) {
    secondComponent = BPMF::UE;
  }

  // then consume the middle component...
  if (0) {
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "i")) {
    secondComponent = independentConsonant ? 0 : BPMF::I;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "u")) {
    if (firstComponent == BPMF::J || firstComponent == BPMF::Q ||
        firstComponent == BPMF::X) {
      secondComponent = BPMF::UE;
    } else {
      secondComponent = BPMF::U;
    }
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "v")) {
    secondComponent = BPMF::UE;
  }

  // the vowels, longer sequence takes precedence
  if (0) {
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ang")) {
    thirdComponent = BPMF::ANG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "eng")) {
    thirdComponent = BPMF::ENG;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "err")) {
    thirdComponent = BPMF::ERR;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ai")) {
    thirdComponent = BPMF::AI;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ei")) {
    thirdComponent = BPMF::EI;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ao")) {
    thirdComponent = BPMF::AO;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "ou")) {
    thirdComponent = BPMF::OU;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "an")) {
    thirdComponent = BPMF::AN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "en")) {
    thirdComponent = BPMF::EN;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "er")) {
    thirdComponent = BPMF::ERR;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "a")) {
    thirdComponent = BPMF::A;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "o")) {
    thirdComponent = BPMF::O;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "e")) {
    if (secondComponent) {
      thirdComponent = BPMF::E;
    } else {
      thirdComponent = BPMF::ER;
    }
  }

  // at last!
  if (0) {
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "1")) {
    toneComponent = BPMF::Tone1;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "2")) {
    toneComponent = BPMF::Tone2;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "3")) {
    toneComponent = BPMF::Tone3;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "4")) {
    toneComponent = BPMF::Tone4;
  } else if (PinyinParseHelper::ConsumePrefix(pinyin, "5")) {
    toneComponent = BPMF::Tone5;
  }

  return BPMF(firstComponent | secondComponent | thirdComponent |
              toneComponent);
}

const std::string BPMF::HanyuPinyinString(bool includesTone,
                                          bool useVForUUmlaut) const {
  std::string consonant, middle, vowel, tone;

  Component cc = consonantComponent(), mvc = middleVowelComponent(),
            vc = vowelComponent();
  bool hasNoMVCOrVC = !(mvc || vc);

  switch (cc) {
    case B:
      consonant = "b";
      break;
    case P:
      consonant = "p";
      break;
    case M:
      consonant = "m";
      break;
    case F:
      consonant = "f";
      break;
    case D:
      consonant = "d";
      break;
    case T:
      consonant = "t";
      break;
    case N:
      consonant = "n";
      break;
    case L:
      consonant = "l";
      break;
    case G:
      consonant = "g";
      break;
    case K:
      consonant = "k";
      break;
    case H:
      consonant = "h";
      break;
    case J:
      consonant = "j";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case Q:
      consonant = "q";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case X:
      consonant = "x";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case ZH:
      consonant = "zh";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case CH:
      consonant = "ch";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case SH:
      consonant = "sh";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case R:
      consonant = "r";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case Z:
      consonant = "z";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case C:
      consonant = "c";
      if (hasNoMVCOrVC) middle = "i";
      break;
    case S:
      consonant = "s";
      if (hasNoMVCOrVC) middle = "i";
      break;
  }

  switch (mvc) {
    case I:
      if (!cc) {
        consonant = "y";
      }

      middle = (!vc || cc) ? "i" : "";
      break;
    case U:
      if (!cc) {
        consonant = "w";
      }
      middle = (!vc || cc) ? "u" : "";
      break;
    case UE:
      if (!cc) {
        consonant = "y";
      }

      if ((cc == N || cc == L) && vc != E) {
        middle = useVForUUmlaut ? "v" : "ü";
      } else {
        middle = "u";
      }

      break;
  }

  switch (vc) {
    case A:
      vowel = "a";
      break;
    case O:
      vowel = "o";
      break;
    case ER:
      vowel = "e";
      break;
    case E:
      vowel = "e";
      break;
    case AI:
      vowel = "ai";
      break;
    case EI:
      vowel = "ei";
      break;
    case AO:
      vowel = "ao";
      break;
    case OU:
      vowel = "ou";
      break;
    case AN:
      vowel = "an";
      break;
    case EN:
      vowel = "en";
      break;
    case ANG:
      vowel = "ang";
      break;
    case ENG:
      vowel = "eng";
      break;
    case ERR:
      vowel = "er";
      break;
  }

  // combination rules

  // ueng -> ong, but note "weng"
  if ((mvc == U || mvc == UE) && vc == ENG) {
    middle = "";
    vowel = (cc == J || cc == Q || cc == X)
                ? "iong"
                : ((!cc && mvc == U) ? "eng" : "ong");
  }

  // ien, uen, üen -> in, un, ün ; but note "wen", "yin" and "yun"
  if (mvc && vc == EN) {
    if (cc) {
      vowel = "n";
    } else {
      if (mvc == UE) {
        vowel = "n";  // yun
      } else if (mvc == U) {
        vowel = "en";  // wen
      } else {
        vowel = "in";  // yin
      }
    }
  }

  // iou -> iu
  if (cc && mvc == I && vc == OU) {
    middle = "";
    vowel = "iu";
  }

  // ieng -> ing
  if (mvc == I && vc == ENG) {
    middle = "";
    vowel = "ing";
  }

  // uei -> ui
  if (cc && mvc == U && vc == EI) {
    middle = "";
    vowel = "ui";
  }

  if (includesTone) {
    switch (toneMarkerComponent()) {
      case Tone2:
        tone = "2";
        break;
      case Tone3:
        tone = "3";
        break;
      case Tone4:
        tone = "4";
        break;
      case Tone5:
        tone = "5";
        break;
    }
  }

  return consonant + middle + vowel + tone;
}

const BPMF BPMF::FromComposedString(const std::string& str) {
  BPMF syllable;
  auto iter = str.begin();
  while (iter != str.end()) {
    // This is a naive implementation and we bail early at anything we don't
    // recognize. A sound implementation would require to either use a trie for
    // the Bopomofo character map or to split the input by codepoints. This
    // suffices for now.

    // Illegal.
    if (!(*iter & 0x80)) {
      break;
    }

    size_t utf8_length = -1;

    // These are the code points for the tone markers.
    if ((*iter & (0x80 | 0x40)) && !(*iter & 0x20)) {
      utf8_length = 2;
    } else if ((*iter & (0x80 | 0x40 | 0x20)) && !(*iter & 0x10)) {
      utf8_length = 3;
    } else {
      // Illegal.
      break;
    }

    if (iter + (utf8_length - 1) == str.end()) {
      break;
    }

    std::string component = std::string(iter, iter + utf8_length);
    const std::map<std::string, BPMF::Component>& charToComp =
        BopomofoCharacterMap::SharedInstance().characterToComponent;
    std::map<std::string, BPMF::Component>::const_iterator result =
        charToComp.find(component);
    if (result == charToComp.end()) {
      break;
    } else {
      syllable += BPMF((*result).second);
    }
    iter += utf8_length;
  }
  return syllable;
}

const std::string BPMF::composedString() const {
  std::string result;
#define APPEND(c)                                                         \
  if (syllable_ & c)                                                     \
  result +=                                                               \
      (*BopomofoCharacterMap::SharedInstance().componentToCharacter.find( \
           syllable_ & c))                                               \
          .second
  APPEND(ConsonantMask);
  APPEND(MiddleVowelMask);
  APPEND(VowelMask);
  APPEND(ToneMarkerMask);
#undef APPEND
  return result;
}



const BopomofoCharacterMap& BopomofoCharacterMap::SharedInstance() {
  static BopomofoCharacterMap* map = new BopomofoCharacterMap();
  return *map;
}

BopomofoCharacterMap::BopomofoCharacterMap() {
  characterToComponent[u8"ㄅ"] = BPMF::B;
  characterToComponent[u8"ㄆ"] = BPMF::P;
  characterToComponent[u8"ㄇ"] = BPMF::M;
  characterToComponent[u8"ㄈ"] = BPMF::F;
  characterToComponent[u8"ㄉ"] = BPMF::D;
  characterToComponent[u8"ㄊ"] = BPMF::T;
  characterToComponent[u8"ㄋ"] = BPMF::N;
  characterToComponent[u8"ㄌ"] = BPMF::L;
  characterToComponent[u8"ㄎ"] = BPMF::K;
  characterToComponent[u8"ㄍ"] = BPMF::G;
  characterToComponent[u8"ㄏ"] = BPMF::H;
  characterToComponent[u8"ㄐ"] = BPMF::J;
  characterToComponent[u8"ㄑ"] = BPMF::Q;
  characterToComponent[u8"ㄒ"] = BPMF::X;
  characterToComponent[u8"ㄓ"] = BPMF::ZH;
  characterToComponent[u8"ㄔ"] = BPMF::CH;
  characterToComponent[u8"ㄕ"] = BPMF::SH;
  characterToComponent[u8"ㄖ"] = BPMF::R;
  characterToComponent[u8"ㄗ"] = BPMF::Z;
  characterToComponent[u8"ㄘ"] = BPMF::C;
  characterToComponent[u8"ㄙ"] = BPMF::S;
  characterToComponent[u8"ㄧ"] = BPMF::I;
  characterToComponent[u8"ㄨ"] = BPMF::U;
  characterToComponent[u8"ㄩ"] = BPMF::UE;
  characterToComponent[u8"ㄚ"] = BPMF::A;
  characterToComponent[u8"ㄛ"] = BPMF::O;
  characterToComponent[u8"ㄜ"] = BPMF::ER;
  characterToComponent[u8"ㄝ"] = BPMF::E;
  characterToComponent[u8"ㄞ"] = BPMF::AI;
  characterToComponent[u8"ㄟ"] = BPMF::EI;
  characterToComponent[u8"ㄠ"] = BPMF::AO;
  characterToComponent[u8"ㄡ"] = BPMF::OU;
  characterToComponent[u8"ㄢ"] = BPMF::AN;
  characterToComponent[u8"ㄣ"] = BPMF::EN;
  characterToComponent[u8"ㄤ"] = BPMF::ANG;
  characterToComponent[u8"ㄥ"] = BPMF::ENG;
  characterToComponent[u8"ㄦ"] = BPMF::ERR;
  characterToComponent[u8"ˊ"] = BPMF::Tone2;
  characterToComponent[u8"ˇ"] = BPMF::Tone3;
  characterToComponent[u8"ˋ"] = BPMF::Tone4;
  characterToComponent[u8"˙"] = BPMF::Tone5;

  for (std::map<std::string, BPMF::Component>::iterator iter =
           characterToComponent.begin();
       iter != characterToComponent.end(); ++iter)
    componentToCharacter[(*iter).second] = (*iter).first;
}

#define ASSIGNKEY1(m, vec, k, val) \
  m[k] = (vec.clear(), vec.push_back((BPMF::Component)val), vec)
#define ASSIGNKEY2(m, vec, k, val1, val2)                    \
  m[k] = (vec.clear(), vec.push_back((BPMF::Component)val1), \
          vec.push_back((BPMF::Component)val2), vec)
#define ASSIGNKEY3(m, vec, k, val1, val2, val3)              \
  m[k] = (vec.clear(), vec.push_back((BPMF::Component)val1), \
          vec.push_back((BPMF::Component)val2),              \
          vec.push_back((BPMF::Component)val3), vec)

static BopomofoKeyboardLayout* CreateStandardLayout() {
  std::vector<BPMF::Component> vec;
  BopomofoKeyToComponentMap ktcm;

  ASSIGNKEY1(ktcm, vec, '1', BPMF::B);
  ASSIGNKEY1(ktcm, vec, 'q', BPMF::P);
  ASSIGNKEY1(ktcm, vec, 'a', BPMF::M);
  ASSIGNKEY1(ktcm, vec, 'z', BPMF::F);
  ASSIGNKEY1(ktcm, vec, '2', BPMF::D);
  ASSIGNKEY1(ktcm, vec, 'w', BPMF::T);
  ASSIGNKEY1(ktcm, vec, 's', BPMF::N);
  ASSIGNKEY1(ktcm, vec, 'x', BPMF::L);
  ASSIGNKEY1(ktcm, vec, 'e', BPMF::G);
  ASSIGNKEY1(ktcm, vec, 'd', BPMF::K);
  ASSIGNKEY1(ktcm, vec, 'c', BPMF::H);
  ASSIGNKEY1(ktcm, vec, 'r', BPMF::J);
  ASSIGNKEY1(ktcm, vec, 'f', BPMF::Q);
  ASSIGNKEY1(ktcm, vec, 'v', BPMF::X);
  ASSIGNKEY1(ktcm, vec, '5', BPMF::ZH);
  ASSIGNKEY1(ktcm, vec, 't', BPMF::CH);
  ASSIGNKEY1(ktcm, vec, 'g', BPMF::SH);
  ASSIGNKEY1(ktcm, vec, 'b', BPMF::R);
  ASSIGNKEY1(ktcm, vec, 'y', BPMF::Z);
  ASSIGNKEY1(ktcm, vec, 'h', BPMF::C);
  ASSIGNKEY1(ktcm, vec, 'n', BPMF::S);
  ASSIGNKEY1(ktcm, vec, 'u', BPMF::I);
  ASSIGNKEY1(ktcm, vec, 'j', BPMF::U);
  ASSIGNKEY1(ktcm, vec, 'm', BPMF::UE);
  ASSIGNKEY1(ktcm, vec, '8', BPMF::A);
  ASSIGNKEY1(ktcm, vec, 'i', BPMF::O);
  ASSIGNKEY1(ktcm, vec, 'k', BPMF::ER);
  ASSIGNKEY1(ktcm, vec, ',', BPMF::E);
  ASSIGNKEY1(ktcm, vec, '9', BPMF::AI);
  ASSIGNKEY1(ktcm, vec, 'o', BPMF::EI);
  ASSIGNKEY1(ktcm, vec, 'l', BPMF::AO);
  ASSIGNKEY1(ktcm, vec, '.', BPMF::OU);
  ASSIGNKEY1(ktcm, vec, '0', BPMF::AN);
  ASSIGNKEY1(ktcm, vec, 'p', BPMF::EN);
  ASSIGNKEY1(ktcm, vec, ';', BPMF::ANG);
  ASSIGNKEY1(ktcm, vec, '/', BPMF::ENG);
  ASSIGNKEY1(ktcm, vec, '-', BPMF::ERR);
  ASSIGNKEY1(ktcm, vec, '3', BPMF::Tone3);
  ASSIGNKEY1(ktcm, vec, '4', BPMF::Tone4);
  ASSIGNKEY1(ktcm, vec, '6', BPMF::Tone2);
  ASSIGNKEY1(ktcm, vec, '7', BPMF::Tone5);

  return new BopomofoKeyboardLayout(ktcm, "Standard");
}

static BopomofoKeyboardLayout* CreateIBMLayout() {
  std::vector<BPMF::Component> vec;
  BopomofoKeyToComponentMap ktcm;

  ASSIGNKEY1(ktcm, vec, '1', BPMF::B);
  ASSIGNKEY1(ktcm, vec, '2', BPMF::P);
  ASSIGNKEY1(ktcm, vec, '3', BPMF::M);
  ASSIGNKEY1(ktcm, vec, '4', BPMF::F);
  ASSIGNKEY1(ktcm, vec, '5', BPMF::D);
  ASSIGNKEY1(ktcm, vec, '6', BPMF::T);
  ASSIGNKEY1(ktcm, vec, '7', BPMF::N);
  ASSIGNKEY1(ktcm, vec, '8', BPMF::L);
  ASSIGNKEY1(ktcm, vec, '9', BPMF::G);
  ASSIGNKEY1(ktcm, vec, '0', BPMF::K);
  ASSIGNKEY1(ktcm, vec, '-', BPMF::H);
  ASSIGNKEY1(ktcm, vec, 'q', BPMF::J);
  ASSIGNKEY1(ktcm, vec, 'w', BPMF::Q);
  ASSIGNKEY1(ktcm, vec, 'e', BPMF::X);
  ASSIGNKEY1(ktcm, vec, 'r', BPMF::ZH);
  ASSIGNKEY1(ktcm, vec, 't', BPMF::CH);
  ASSIGNKEY1(ktcm, vec, 'y', BPMF::SH);
  ASSIGNKEY1(ktcm, vec, 'u', BPMF::R);
  ASSIGNKEY1(ktcm, vec, 'i', BPMF::Z);
  ASSIGNKEY1(ktcm, vec, 'o', BPMF::C);
  ASSIGNKEY1(ktcm, vec, 'p', BPMF::S);
  ASSIGNKEY1(ktcm, vec, 'a', BPMF::I);
  ASSIGNKEY1(ktcm, vec, 's', BPMF::U);
  ASSIGNKEY1(ktcm, vec, 'd', BPMF::UE);
  ASSIGNKEY1(ktcm, vec, 'f', BPMF::A);
  ASSIGNKEY1(ktcm, vec, 'g', BPMF::O);
  ASSIGNKEY1(ktcm, vec, 'h', BPMF::ER);
  ASSIGNKEY1(ktcm, vec, 'j', BPMF::E);
  ASSIGNKEY1(ktcm, vec, 'k', BPMF::AI);
  ASSIGNKEY1(ktcm, vec, 'l', BPMF::EI);
  ASSIGNKEY1(ktcm, vec, ';', BPMF::AO);
  ASSIGNKEY1(ktcm, vec, 'z', BPMF::OU);
  ASSIGNKEY1(ktcm, vec, 'x', BPMF::AN);
  ASSIGNKEY1(ktcm, vec, 'c', BPMF::EN);
  ASSIGNKEY1(ktcm, vec, 'v', BPMF::ANG);
  ASSIGNKEY1(ktcm, vec, 'b', BPMF::ENG);
  ASSIGNKEY1(ktcm, vec, 'n', BPMF::ERR);
  ASSIGNKEY1(ktcm, vec, 'm', BPMF::Tone2);
  ASSIGNKEY1(ktcm, vec, ',', BPMF::Tone3);
  ASSIGNKEY1(ktcm, vec, '.', BPMF::Tone4);
  ASSIGNKEY1(ktcm, vec, '/', BPMF::Tone5);

  return new BopomofoKeyboardLayout(ktcm, "IBM");
}

static BopomofoKeyboardLayout* CreateETenLayout() {
  std::vector<BPMF::Component> vec;
  BopomofoKeyToComponentMap ktcm;

  ASSIGNKEY1(ktcm, vec, 'b', BPMF::B);
  ASSIGNKEY1(ktcm, vec, 'p', BPMF::P);
  ASSIGNKEY1(ktcm, vec, 'm', BPMF::M);
  ASSIGNKEY1(ktcm, vec, 'f', BPMF::F);
  ASSIGNKEY1(ktcm, vec, 'd', BPMF::D);
  ASSIGNKEY1(ktcm, vec, 't', BPMF::T);
  ASSIGNKEY1(ktcm, vec, 'n', BPMF::N);
  ASSIGNKEY1(ktcm, vec, 'l', BPMF::L);
  ASSIGNKEY1(ktcm, vec, 'v', BPMF::G);
  ASSIGNKEY1(ktcm, vec, 'k', BPMF::K);
  ASSIGNKEY1(ktcm, vec, 'h', BPMF::H);
  ASSIGNKEY1(ktcm, vec, 'g', BPMF::J);
  ASSIGNKEY1(ktcm, vec, '7', BPMF::Q);
  ASSIGNKEY1(ktcm, vec, 'c', BPMF::X);
  ASSIGNKEY1(ktcm, vec, ',', BPMF::ZH);
  ASSIGNKEY1(ktcm, vec, '.', BPMF::CH);
  ASSIGNKEY1(ktcm, vec, '/', BPMF::SH);
  ASSIGNKEY1(ktcm, vec, 'j', BPMF::R);
  ASSIGNKEY1(ktcm, vec, ';', BPMF::Z);
  ASSIGNKEY1(ktcm, vec, '\'', BPMF::C);
  ASSIGNKEY1(ktcm, vec, 's', BPMF::S);
  ASSIGNKEY1(ktcm, vec, 'e', BPMF::I);
  ASSIGNKEY1(ktcm, vec, 'x', BPMF::U);
  ASSIGNKEY1(ktcm, vec, 'u', BPMF::UE);
  ASSIGNKEY1(ktcm, vec, 'a', BPMF::A);
  ASSIGNKEY1(ktcm, vec, 'o', BPMF::O);
  ASSIGNKEY1(ktcm, vec, 'r', BPMF::ER);
  ASSIGNKEY1(ktcm, vec, 'w', BPMF::E);
  ASSIGNKEY1(ktcm, vec, 'i', BPMF::AI);
  ASSIGNKEY1(ktcm, vec, 'q', BPMF::EI);
  ASSIGNKEY1(ktcm, vec, 'z', BPMF::AO);
  ASSIGNKEY1(ktcm, vec, 'y', BPMF::OU);
  ASSIGNKEY1(ktcm, vec, '8', BPMF::AN);
  ASSIGNKEY1(ktcm, vec, '9', BPMF::EN);
  ASSIGNKEY1(ktcm, vec, '0', BPMF::ANG);
  ASSIGNKEY1(ktcm, vec, '-', BPMF::ENG);
  ASSIGNKEY1(ktcm, vec, '=', BPMF::ERR);
  ASSIGNKEY1(ktcm, vec, '2', BPMF::Tone2);
  ASSIGNKEY1(ktcm, vec, '3', BPMF::Tone3);
  ASSIGNKEY1(ktcm, vec, '4', BPMF::Tone4);
  ASSIGNKEY1(ktcm, vec, '1', BPMF::Tone5);

  return new BopomofoKeyboardLayout(ktcm, "ETen");
}

static BopomofoKeyboardLayout* CreateHsuLayout() {
  std::vector<BPMF::Component> vec;
  BopomofoKeyToComponentMap ktcm;

  ASSIGNKEY1(ktcm, vec, 'b', BPMF::B);
  ASSIGNKEY1(ktcm, vec, 'p', BPMF::P);
  ASSIGNKEY2(ktcm, vec, 'm', BPMF::M, BPMF::AN);
  ASSIGNKEY2(ktcm, vec, 'f', BPMF::F, BPMF::Tone3);
  ASSIGNKEY2(ktcm, vec, 'd', BPMF::D, BPMF::Tone2);
  ASSIGNKEY1(ktcm, vec, 't', BPMF::T);
  ASSIGNKEY2(ktcm, vec, 'n', BPMF::N, BPMF::EN);
  ASSIGNKEY3(ktcm, vec, 'l', BPMF::L, BPMF::ENG, BPMF::ERR);
  ASSIGNKEY2(ktcm, vec, 'g', BPMF::G, BPMF::ER);
  ASSIGNKEY2(ktcm, vec, 'k', BPMF::K, BPMF::ANG);
  ASSIGNKEY2(ktcm, vec, 'h', BPMF::H, BPMF::O);
  ASSIGNKEY3(ktcm, vec, 'j', BPMF::J, BPMF::ZH, BPMF::Tone4);
  ASSIGNKEY2(ktcm, vec, 'v', BPMF::Q, BPMF::CH);
  ASSIGNKEY2(ktcm, vec, 'c', BPMF::X, BPMF::SH);
  ASSIGNKEY1(ktcm, vec, 'r', BPMF::R);
  ASSIGNKEY1(ktcm, vec, 'z', BPMF::Z);
  ASSIGNKEY2(ktcm, vec, 'a', BPMF::C, BPMF::EI);
  ASSIGNKEY2(ktcm, vec, 's', BPMF::S, BPMF::Tone5);
  ASSIGNKEY2(ktcm, vec, 'e', BPMF::I, BPMF::E);
  ASSIGNKEY1(ktcm, vec, 'x', BPMF::U);
  ASSIGNKEY1(ktcm, vec, 'u', BPMF::UE);
  ASSIGNKEY1(ktcm, vec, 'y', BPMF::A);
  ASSIGNKEY1(ktcm, vec, 'i', BPMF::AI);
  ASSIGNKEY1(ktcm, vec, 'w', BPMF::AO);
  ASSIGNKEY1(ktcm, vec, 'o', BPMF::OU);

  return new BopomofoKeyboardLayout(ktcm, "Hsu");
}

static BopomofoKeyboardLayout* CreateETen26Layout() {
  std::vector<BPMF::Component> vec;
  BopomofoKeyToComponentMap ktcm;

  ASSIGNKEY1(ktcm, vec, 'b', BPMF::B);
  ASSIGNKEY2(ktcm, vec, 'p', BPMF::P, BPMF::OU);
  ASSIGNKEY2(ktcm, vec, 'm', BPMF::M, BPMF::AN);
  ASSIGNKEY2(ktcm, vec, 'f', BPMF::F, BPMF::Tone2);
  ASSIGNKEY2(ktcm, vec, 'd', BPMF::D, BPMF::Tone5);
  ASSIGNKEY2(ktcm, vec, 't', BPMF::T, BPMF::ANG);
  ASSIGNKEY2(ktcm, vec, 'n', BPMF::N, BPMF::EN);
  ASSIGNKEY2(ktcm, vec, 'l', BPMF::L, BPMF::ENG);
  ASSIGNKEY2(ktcm, vec, 'v', BPMF::G, BPMF::Q);
  ASSIGNKEY2(ktcm, vec, 'k', BPMF::K, BPMF::Tone4);
  ASSIGNKEY2(ktcm, vec, 'h', BPMF::H, BPMF::ERR);
  ASSIGNKEY2(ktcm, vec, 'g', BPMF::ZH, BPMF::J);
  ASSIGNKEY2(ktcm, vec, 'c', BPMF::SH, BPMF::X);
  ASSIGNKEY1(ktcm, vec, 'y', BPMF::CH);
  ASSIGNKEY2(ktcm, vec, 'j', BPMF::R, BPMF::Tone3);
  ASSIGNKEY2(ktcm, vec, 'q', BPMF::Z, BPMF::EI);
  ASSIGNKEY2(ktcm, vec, 'w', BPMF::C, BPMF::E);
  ASSIGNKEY1(ktcm, vec, 's', BPMF::S);
  ASSIGNKEY1(ktcm, vec, 'e', BPMF::I);
  ASSIGNKEY1(ktcm, vec, 'x', BPMF::U);
  ASSIGNKEY1(ktcm, vec, 'u', BPMF::UE);
  ASSIGNKEY1(ktcm, vec, 'a', BPMF::A);
  ASSIGNKEY1(ktcm, vec, 'o', BPMF::O);
  ASSIGNKEY1(ktcm, vec, 'r', BPMF::ER);
  ASSIGNKEY1(ktcm, vec, 'i', BPMF::AI);
  ASSIGNKEY1(ktcm, vec, 'z', BPMF::AO);
  return new BopomofoKeyboardLayout(ktcm, "ETen26");
}

static BopomofoKeyboardLayout* CreateHanyuPinyinLayout() {
  BopomofoKeyToComponentMap ktcm;
  return new BopomofoKeyboardLayout(ktcm, "HanyuPinyin");
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::StandardLayout() {
  static BopomofoKeyboardLayout* layout = CreateStandardLayout();
  return layout;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::ETenLayout() {
  static BopomofoKeyboardLayout* layout = CreateETenLayout();
  return layout;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::HsuLayout() {
  static BopomofoKeyboardLayout* layout = CreateHsuLayout();
  return layout;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::ETen26Layout() {
  static BopomofoKeyboardLayout* layout = CreateETen26Layout();
  return layout;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::IBMLayout() {
  static BopomofoKeyboardLayout* layout = CreateIBMLayout();
  return layout;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::HanyuPinyinLayout() {
  static BopomofoKeyboardLayout* layout = CreateHanyuPinyinLayout();
  return layout;
}

}  // namespace Mandarin
}  // namespace Formosa
