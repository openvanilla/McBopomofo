//
// Mandarin.cpp
//
// Copyright (c) 2006-2010 Lukhnos D. Liu (http://lukhnos.org)
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
//

#include <cctype>
#include <algorithm>
#include "Mandarin.h"

#include "OVUTF8Helper.h"
#include "OVWildcard.h"

namespace Formosa {
namespace Mandarin {
    
using namespace OpenVanilla;

class PinyinParseHelper {
public:
    static const bool ConsumePrefix(string &target, const string &prefix)
    {
        if (target.length() < prefix.length()) {
            return false;
        }
        
        if (target.substr(0, prefix.length()) == prefix) {
            target = target.substr(prefix.length(), target.length() - prefix.length());
            return true;
        }
        
        return false;
    }
};

class BopomofoCharacterMap {
public:
    static const BopomofoCharacterMap& SharedInstance();

    map<BPMF::Component, string> componentToCharacter;
    map<string, BPMF::Component> characterToComponent;

protected:
    BopomofoCharacterMap();
    static BopomofoCharacterMap* c_map;
};

const BPMF BPMF::FromHanyuPinyin(const string& str)
{
    if (!str.length()) {
        return BPMF();
    }
    
    string pinyin = str;
    transform(pinyin.begin(), pinyin.end(), pinyin.begin(), ::tolower);
        
    BPMF::Component firstComponent = 0;
    BPMF::Component secondComponent = 0;
    BPMF::Component thirdComponent = 0;
    BPMF::Component toneComponent = 0;
    
    // lookup consonants and consume them
    bool independentConsonant = false;

    // the y exceptions fist
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "yuan")) { secondComponent = BPMF::UE; thirdComponent = BPMF::AN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ying")) { secondComponent = BPMF::I; thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "yung")) { secondComponent = BPMF::UE; thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "yong")) { secondComponent = BPMF::UE; thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "yue")) { secondComponent = BPMF::UE; thirdComponent = BPMF::E; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "yun")) { secondComponent = BPMF::UE; thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "you")) { secondComponent = BPMF::I; thirdComponent = BPMF::OU; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "yu")) { secondComponent = BPMF::UE; }
    
    
    // try the first character
    char c = pinyin.length() ? pinyin[0] : 0;
    switch (c) {
        case 'b': firstComponent = BPMF::B; pinyin = pinyin.substr(1); break;
        case 'p': firstComponent = BPMF::P; pinyin = pinyin.substr(1); break;
        case 'm': firstComponent = BPMF::M; pinyin = pinyin.substr(1); break;
        case 'f': firstComponent = BPMF::F; pinyin = pinyin.substr(1); break;
        case 'd': firstComponent = BPMF::D; pinyin = pinyin.substr(1); break;
        case 't': firstComponent = BPMF::T; pinyin = pinyin.substr(1); break;
        case 'n': firstComponent = BPMF::N; pinyin = pinyin.substr(1); break;
        case 'l': firstComponent = BPMF::L; pinyin = pinyin.substr(1); break;
        case 'g': firstComponent = BPMF::G; pinyin = pinyin.substr(1); break;
        case 'k': firstComponent = BPMF::K; pinyin = pinyin.substr(1); break;
        case 'h': firstComponent = BPMF::H; pinyin = pinyin.substr(1); break;
        case 'j': firstComponent = BPMF::J; pinyin = pinyin.substr(1); break;
        case 'q': firstComponent = BPMF::Q; pinyin = pinyin.substr(1); break;
        case 'x': firstComponent = BPMF::X; pinyin = pinyin.substr(1); break;        
        
        // special hanlding for w and y
        case 'w': secondComponent = BPMF::U; pinyin = pinyin.substr(1); break;        
        case 'y':
            if (!secondComponent && !thirdComponent) {
                secondComponent = BPMF::I;
            }
            pinyin = pinyin.substr(1);
            break;
    }
    
    // then we try ZH, CH, SH, R, Z, C, S (in that order)
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "zh")) { firstComponent = BPMF::ZH; independentConsonant = true; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ch")) { firstComponent = BPMF::CH; independentConsonant = true; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "sh")) { firstComponent = BPMF::SH; independentConsonant = true; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "r")) { firstComponent = BPMF::R; independentConsonant = true; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "z")) { firstComponent = BPMF::Z; independentConsonant = true; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "c")) { firstComponent = BPMF::C; independentConsonant = true; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "s")) { firstComponent = BPMF::S; independentConsonant = true; }

    // consume exceptions first: (ien, in), (iou, iu), (uen, un), (veng, iong), (ven, vn), (uei, ui), ung
    // but longer sequence takes precedence
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "veng")) { secondComponent = BPMF::UE; thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "iong")) { secondComponent = BPMF::UE; thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ing")) { secondComponent = BPMF::I; thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ien")) { secondComponent = BPMF::I; thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "iou")) { secondComponent = BPMF::I; thirdComponent = BPMF::OU; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "uen")) { secondComponent = BPMF::U; thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ven")) { secondComponent = BPMF::UE; thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "uei")) { secondComponent = BPMF::U; thirdComponent = BPMF::EI; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ung")) { 
        // f exception
        if (firstComponent == BPMF::F) {
            thirdComponent = BPMF::ENG;            
        }
        else {
            secondComponent = BPMF::U; thirdComponent = BPMF::ENG;
        }
    }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ong")) { 
        // f exception
        if (firstComponent == BPMF::F) {
            thirdComponent = BPMF::ENG;            
        }
        else {
            secondComponent = BPMF::U;
            thirdComponent = BPMF::ENG;
        }
    }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "un")) {
        if (firstComponent == BPMF::J || firstComponent == BPMF::Q || firstComponent == BPMF::X) {
            secondComponent = BPMF::UE;
        }
        else {
            secondComponent = BPMF::U;
        }
        thirdComponent = BPMF::EN;
    }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "iu")) { secondComponent = BPMF::I; thirdComponent = BPMF::OU; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "in")) { secondComponent = BPMF::I; thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "vn")) { secondComponent = BPMF::UE; thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ui")) { secondComponent = BPMF::U; thirdComponent = BPMF::EI; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ue")) 
    {
        secondComponent = BPMF::UE; thirdComponent = BPMF::E;
    }
    
    #ifndef _MSC_VER
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ü")) { secondComponent = BPMF::UE; }
    #else
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "\xc3\xbc")) { secondComponent = BPMF::UE; }
    #endif

    // then consume the middle component...
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "i")) { secondComponent = independentConsonant ? 0 : BPMF::I; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "u")) { 
        if (firstComponent == BPMF::J || firstComponent == BPMF::Q || firstComponent == BPMF::X) {
            secondComponent = BPMF::UE;
        }
        else {
            secondComponent = BPMF::U;
        }
    }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "v")) { secondComponent = BPMF::UE; }

    // the vowels, longer sequence takes precedence
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ang")) { thirdComponent = BPMF::ANG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "eng")) { thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "err")) { thirdComponent = BPMF::ERR; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ai")) { thirdComponent = BPMF::AI; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ei")) { thirdComponent = BPMF::EI; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ao")) { thirdComponent = BPMF::AO; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "ou")) { thirdComponent = BPMF::OU; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "an")) { thirdComponent = BPMF::AN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "en")) { thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "er")) { thirdComponent = BPMF::ERR; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "a")) { thirdComponent = BPMF::A; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "o")) { thirdComponent = BPMF::O; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "e")) { 
        if (secondComponent) {
            thirdComponent = BPMF::E;
        }
        else {
            thirdComponent = BPMF::ER;
        }
    }

    // at last!
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "1")) { toneComponent = BPMF::Tone1; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "2")) { toneComponent = BPMF::Tone2; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "3")) { toneComponent = BPMF::Tone3; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "4")) { toneComponent = BPMF::Tone4; }
    else if (PinyinParseHelper::ConsumePrefix(pinyin, "5")) { toneComponent = BPMF::Tone5; }

    return BPMF(firstComponent | secondComponent | thirdComponent | toneComponent);
}

const string BPMF::HanyuPinyinString(bool includesTone, bool useVForUUmlaut) const
{
    string consonant, middle, vowel, tone;
    
    Component cc = consonantComponent(), mvc = middleVowelComponent(), vc = vowelComponent();
    bool hasNoMVCOrVC = !(mvc || vc);
    
    
    switch (cc) {
        case B: consonant = "b"; break;
        case P: consonant = "p"; break;
        case M: consonant = "m"; break;
        case F: consonant = "f"; break;
        case D: consonant = "d"; break;
        case T: consonant = "t"; break;
        case N: consonant = "n"; break;
        case L: consonant = "l"; break;
        case G: consonant = "g"; break;
        case K: consonant = "k"; break;
        case H: consonant = "h"; break;
        case J: consonant = "j"; if (hasNoMVCOrVC) middle = "i"; break;
        case Q: consonant = "q"; if (hasNoMVCOrVC) middle = "i"; break;
        case X: consonant = "x"; if (hasNoMVCOrVC) middle = "i"; break;
        case ZH: consonant = "zh"; if (hasNoMVCOrVC) middle = "i"; break;
        case CH: consonant = "ch"; if (hasNoMVCOrVC) middle = "i"; break;
        case SH: consonant = "sh"; if (hasNoMVCOrVC) middle = "i"; break;
        case R: consonant = "r"; if (hasNoMVCOrVC) middle = "i"; break;
        case Z: consonant = "z"; if (hasNoMVCOrVC) middle = "i"; break;
        case C: consonant = "c"; if (hasNoMVCOrVC) middle = "i"; break;
        case S: consonant = "s"; if (hasNoMVCOrVC) middle = "i"; break;
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
            }
            else {
                middle = "u";
            }
            
            break;
    }
    
    switch (vc) {
        case A: vowel = "a"; break;
        case O: vowel = "o"; break;
        case ER: vowel = "e"; break;
        case E: vowel = "e"; break;
        case AI: vowel = "ai"; break;
        case EI: vowel = "ei"; break;
        case AO: vowel = "ao"; break;
        case OU: vowel = "ou"; break;
        case AN: vowel = "an"; break;
        case EN: vowel = "en"; break;
        case ANG: vowel = "ang"; break;
        case ENG: vowel = "eng"; break;
        case ERR: vowel = "er"; break;        
    }
        
    // combination rules
    
    // ueng -> ong, but note "weng"
    if ((mvc == U || mvc == UE) && vc == ENG) {        
        middle = "";
        vowel = (cc == J || cc == Q || cc == X) ? "iong" : ((!cc && mvc == U) ? "eng" : "ong");
    }

    // ien, uen, üen -> in, un, ün ; but note "wen", "yin" and "yun"
    if (mvc && vc == EN) {
        if (cc) {
            vowel = "n";
        }
        else {
            if (mvc == UE) {
                vowel = "n";    // yun
            }
            else if (mvc == U) {
                vowel = "en";   // wen
            }
            else {
                vowel = "in";   // yin
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
            case Tone2: tone = "2"; break;
            case Tone3: tone = "3"; break;
            case Tone4: tone = "4"; break;
            case Tone5: tone = "5"; break;
        }
    }
    
    return consonant + middle + vowel + tone;
}



const string BPMF::PHTString(bool includesTone) const
{
    string consonant, middle, vowel, tone;
    
    Component cc = consonantComponent(), mvc = middleVowelComponent(), vc = vowelComponent();
    bool hasNoMVCOrVC = !(mvc || vc);    
    
    switch (cc) {
        case B: consonant = "p"; break;
        case P: consonant = "ph"; break;
        case M: consonant = "m"; break;
        case F: consonant = "f"; break;
        case D: consonant = "t"; break;
        case T: consonant = "th"; break;
        case N: consonant = "n"; break;
        case L: consonant = "l"; break;
        case G: consonant = "k"; break;
        case K: consonant = "kh"; break;
        case H: consonant = "h"; break;
        case J: consonant = "ch"; if (mvc != I) middle = "i"; break;
        case Q: consonant = "chh"; if (mvc != I) middle = "i"; break;
        case X: consonant = "hs"; if (mvc != I) middle = "i"; break;
        case ZH: consonant = "ch"; if (hasNoMVCOrVC) middle = "i"; break;
        case CH: consonant = "chh"; if (hasNoMVCOrVC) middle = "i"; break;
        case SH: consonant = "sh"; if (hasNoMVCOrVC) middle = "i"; break;
        case R: consonant = "r"; if (hasNoMVCOrVC) middle = "i"; break;
        case Z: consonant = "ts"; if (hasNoMVCOrVC) middle = "i"; break;
        case C: consonant = "tsh"; if (hasNoMVCOrVC) middle = "i"; break;
        case S: consonant = "s"; if (hasNoMVCOrVC) middle = "i"; break;
    }
    
    switch (mvc) {
        case I:
            middle = "i";
            break;
        case U:
            middle = "u";
            break;            
        case UE:
            middle = "uu";
            break;
    }
    
    switch (vc) {
        case A: vowel = "a"; break;
        case O: vowel = "o"; break;
        case ER: vowel = "e"; break;
        case E: vowel = (!(cc || mvc)) ? "eh" : "e"; break;
        case AI: vowel = "ai"; break;
        case EI: vowel = "ei"; break;
        case AO: vowel = "ao"; break;
        case OU: vowel = "ou"; break;
        case AN: vowel = "an"; break;
        case EN: vowel = "en"; break;
        case ANG: vowel = "ang"; break;
        case ENG: vowel = "eng"; break;
        case ERR: vowel = "err"; break;        
    }

    // ieng -> ing
    if (mvc == I && vc == ENG) {
        middle = "";
        vowel = "ing";
    }
    
    // zh/ch + i without third component -> append h
    if (cc == BPMF::ZH || cc == BPMF::CH) {
        if (!mvc && !vc) {
            vowel = "h";
        }
    }
    
    
    if (includesTone) {
        switch (toneMarkerComponent()) {            
            case Tone2: tone = "2"; break;
            case Tone3: tone = "3"; break;
            case Tone4: tone = "4"; break;
            case Tone5: tone = "5"; break;
        }
    }
    
    return consonant + middle + vowel + tone;
    
}

const BPMF BPMF::FromPHT(const string& str)
{
    if (!str.length()) {
        return BPMF();
    }
    
    string pht = str;
    transform(pht.begin(), pht.end(), pht.begin(), ::tolower);
        
    BPMF::Component firstComponent = 0;
    BPMF::Component secondComponent = 0;
    BPMF::Component thirdComponent = 0;
    BPMF::Component toneComponent = 0;

    #define IF_CONSUME1(k, v) else if (PinyinParseHelper::ConsumePrefix(pht, k)) { firstComponent = v; }    
    
    // consume the first part
    if (0) {}
    IF_CONSUME1("ph", BPMF::P)
    IF_CONSUME1("p", BPMF::B)
    IF_CONSUME1("m", BPMF::M)
    IF_CONSUME1("f", BPMF::F)
    IF_CONSUME1("th", BPMF::T)
    IF_CONSUME1("n", BPMF::N)
    IF_CONSUME1("l", BPMF::L)
    IF_CONSUME1("kh", BPMF::K)
    IF_CONSUME1("k", BPMF::G)
    IF_CONSUME1("chh", BPMF::Q)
    IF_CONSUME1("ch", BPMF::J)
    IF_CONSUME1("hs", BPMF::X)
    IF_CONSUME1("sh", BPMF::SH)
    IF_CONSUME1("r", BPMF::R)
    IF_CONSUME1("tsh", BPMF::C)
    IF_CONSUME1("ts", BPMF::Z)
    IF_CONSUME1("s", BPMF::S)
    IF_CONSUME1("t", BPMF::D)
    IF_CONSUME1("h", BPMF::H)
    
    #define IF_CONSUME2(k, v) else if (PinyinParseHelper::ConsumePrefix(pht, k)) { secondComponent = v; }        
    // consume the second part
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pht, "ing")) { secondComponent = BPMF::I; thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "ih")) { 
        if (firstComponent == BPMF::J) {
            firstComponent = BPMF::ZH;
        }
        else if (firstComponent == BPMF::Q) {
            firstComponent = BPMF::CH;
        }
    }
    IF_CONSUME2("i", BPMF::I)
    IF_CONSUME2("uu", BPMF::UE)
    IF_CONSUME2("u", BPMF::U)
    
    #undef IF_CONSUME1
    #undef IF_CONSUME2
    
    // the vowels, longer sequence takes precedence
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pht, "ang")) { thirdComponent = BPMF::ANG; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "eng")) { thirdComponent = BPMF::ENG; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "err")) { thirdComponent = BPMF::ERR; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "ai")) { thirdComponent = BPMF::AI; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "ei")) { thirdComponent = BPMF::EI; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "ao")) { thirdComponent = BPMF::AO; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "ou")) { thirdComponent = BPMF::OU; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "an")) { thirdComponent = BPMF::AN; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "en")) { thirdComponent = BPMF::EN; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "er")) { thirdComponent = BPMF::ERR; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "a")) { thirdComponent = BPMF::A; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "o")) { thirdComponent = BPMF::O; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "eh")) { thirdComponent = BPMF::E; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "e")) { 
        if (secondComponent) {
            thirdComponent = BPMF::E;
        }
        else {
            thirdComponent = BPMF::ER;
        }
    }

    // fix ch/chh mappings
    Component corresponding = 0;
    if (firstComponent == BPMF::J) {
        corresponding = BPMF::ZH;
    }
    else if (firstComponent == BPMF::Q) {
        corresponding = BPMF::CH;
    }
    
    if (corresponding) {
        if (secondComponent == BPMF::I && !thirdComponent) {
            // if the second component is I and there's no third component, we use the corresponding part
            // firstComponent = corresponding;
        }
        else if (secondComponent == BPMF::U) {
            // if second component is U, we use the corresponding part
            firstComponent = corresponding;
        }
        else if (!secondComponent) {
            // if there's no second component, it must be a corresponding part
            firstComponent = corresponding;
        }
    }
    
    if (secondComponent == BPMF::I) {
        // fixes a few impossible occurances
        switch(firstComponent) {
            case BPMF::ZH:
            case BPMF::CH:
            case BPMF::SH:
            case BPMF::R:
            case BPMF::Z:
            case BPMF::C:
            case BPMF::S:
                secondComponent = 0;
        }
    }
    

    // at last!
    if (0) {}
    else if (PinyinParseHelper::ConsumePrefix(pht, "1")) { toneComponent = BPMF::Tone1; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "2")) { toneComponent = BPMF::Tone2; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "3")) { toneComponent = BPMF::Tone3; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "4")) { toneComponent = BPMF::Tone4; }
    else if (PinyinParseHelper::ConsumePrefix(pht, "5")) { toneComponent = BPMF::Tone5; }

    return BPMF(firstComponent | secondComponent | thirdComponent | toneComponent);
}

const BPMF BPMF::FromComposedString(const string& str)
{
    BPMF syllable;
    vector<string> components = OVUTF8Helper::SplitStringByCodePoint(str);
    for (vector<string>::iterator iter = components.begin() ; iter != components.end() ; ++iter) {
	
		const map<string, BPMF::Component>& charToComp = BopomofoCharacterMap::SharedInstance().characterToComponent;
		map<string, BPMF::Component>::const_iterator result = charToComp.find(*iter);
		if (result != charToComp.end())
        	syllable += BPMF((*result).second);
    }
    
    return syllable;
}

const string BPMF::composedString() const
{
    string result;
    #define APPEND(c) if (m_syllable & c) result += (*BopomofoCharacterMap::SharedInstance().componentToCharacter.find(m_syllable & c)).second
    APPEND(ConsonantMask);
    APPEND(MiddleVowelMask);
    APPEND(VowelMask);
    APPEND(ToneMarkerMask);
    #undef APPEND
    return result;
}

BopomofoCharacterMap* BopomofoCharacterMap::c_map = 0;

const BopomofoCharacterMap& BopomofoCharacterMap::SharedInstance()
{
    if (!c_map)        
        c_map = new BopomofoCharacterMap();
        
    return *c_map;
}

BopomofoCharacterMap::BopomofoCharacterMap()    
{
#ifndef _MSC_VER
    characterToComponent["ㄅ"] = BPMF::B;
    characterToComponent["ㄆ"] = BPMF::P;
    characterToComponent["ㄇ"] = BPMF::M;
    characterToComponent["ㄈ"] = BPMF::F;
    characterToComponent["ㄉ"] = BPMF::D;
    characterToComponent["ㄊ"] = BPMF::T;
    characterToComponent["ㄋ"] = BPMF::N;
    characterToComponent["ㄌ"] = BPMF::L;
    characterToComponent["ㄎ"] = BPMF::K;
    characterToComponent["ㄍ"] = BPMF::G;
    characterToComponent["ㄏ"] = BPMF::H;
    characterToComponent["ㄐ"] = BPMF::J;
    characterToComponent["ㄑ"] = BPMF::Q;
    characterToComponent["ㄒ"] = BPMF::X;
    characterToComponent["ㄓ"] = BPMF::ZH;
    characterToComponent["ㄔ"] = BPMF::CH;
    characterToComponent["ㄕ"] = BPMF::SH;
    characterToComponent["ㄖ"] = BPMF::R;
    characterToComponent["ㄗ"] = BPMF::Z;
    characterToComponent["ㄘ"] = BPMF::C;
    characterToComponent["ㄙ"] = BPMF::S;
    characterToComponent["ㄧ"] = BPMF::I;
    characterToComponent["ㄨ"] = BPMF::U;
    characterToComponent["ㄩ"] = BPMF::UE;
    characterToComponent["ㄚ"] = BPMF::A;
    characterToComponent["ㄛ"] = BPMF::O;
    characterToComponent["ㄜ"] = BPMF::ER;
    characterToComponent["ㄝ"] = BPMF::E;
    characterToComponent["ㄞ"] = BPMF::AI;
    characterToComponent["ㄟ"] = BPMF::EI;
    characterToComponent["ㄠ"] = BPMF::AO;
    characterToComponent["ㄡ"] = BPMF::OU;
    characterToComponent["ㄢ"] = BPMF::AN;
    characterToComponent["ㄣ"] = BPMF::EN;
    characterToComponent["ㄤ"] = BPMF::ANG;
    characterToComponent["ㄥ"] = BPMF::ENG;
    characterToComponent["ㄦ"] = BPMF::ERR;
    characterToComponent["ˊ"] = BPMF::Tone2;
    characterToComponent["ˇ"] = BPMF::Tone3;
    characterToComponent["ˋ"] = BPMF::Tone4;
    characterToComponent["˙"] = BPMF::Tone5;
#else
    characterToComponent["\xe3\x84\x85"] = BPMF::B;
    characterToComponent["\xe3\x84\x86"] = BPMF::P;
    characterToComponent["\xe3\x84\x87"] = BPMF::M;
    characterToComponent["\xe3\x84\x88"] = BPMF::F;
    characterToComponent["\xe3\x84\x89"] = BPMF::D;
    characterToComponent["\xe3\x84\x8a"] = BPMF::T;
    characterToComponent["\xe3\x84\x8b"] = BPMF::N;
    characterToComponent["\xe3\x84\x8c"] = BPMF::L;
    characterToComponent["\xe3\x84\x8e"] = BPMF::K;
    characterToComponent["\xe3\x84\x8d"] = BPMF::G;
    characterToComponent["\xe3\x84\x8f"] = BPMF::H;
    characterToComponent["\xe3\x84\x90"] = BPMF::J;
    characterToComponent["\xe3\x84\x91"] = BPMF::Q;
    characterToComponent["\xe3\x84\x92"] = BPMF::X;
    characterToComponent["\xe3\x84\x93"] = BPMF::ZH;
    characterToComponent["\xe3\x84\x94"] = BPMF::CH;
    characterToComponent["\xe3\x84\x95"] = BPMF::SH;
    characterToComponent["\xe3\x84\x96"] = BPMF::R;
    characterToComponent["\xe3\x84\x97"] = BPMF::Z;
    characterToComponent["\xe3\x84\x98"] = BPMF::C;
    characterToComponent["\xe3\x84\x99"] = BPMF::S;
    characterToComponent["\xe3\x84\xa7"] = BPMF::I;
    characterToComponent["\xe3\x84\xa8"] = BPMF::U;
    characterToComponent["\xe3\x84\xa9"] = BPMF::UE;
    characterToComponent["\xe3\x84\x9a"] = BPMF::A;
    characterToComponent["\xe3\x84\x9b"] = BPMF::O;
    characterToComponent["\xe3\x84\x9c"] = BPMF::ER;
    characterToComponent["\xe3\x84\x9d"] = BPMF::E;
    characterToComponent["\xe3\x84\x9e"] = BPMF::AI;
    characterToComponent["\xe3\x84\x9f"] = BPMF::EI;
    characterToComponent["\xe3\x84\xa0"] = BPMF::AO;
    characterToComponent["\xe3\x84\xa1"] = BPMF::OU;
    characterToComponent["\xe3\x84\xa2"] = BPMF::AN;
    characterToComponent["\xe3\x84\xa3"] = BPMF::EN;
    characterToComponent["\xe3\x84\xa4"] = BPMF::ANG;
    characterToComponent["\xe3\x84\xa5"] = BPMF::ENG;
    characterToComponent["\xe3\x84\xa6"] = BPMF::ERR;
    characterToComponent["\xcb\x8a"] = BPMF::Tone2;
    characterToComponent["\xcb\x87"] = BPMF::Tone3;
    characterToComponent["\xcb\x8b"] = BPMF::Tone4;
    characterToComponent["\xcb\x99"] = BPMF::Tone5;
#endif
    
    for (map<string, BPMF::Component>::iterator iter = characterToComponent.begin() ; iter != characterToComponent.end() ; ++iter)
        componentToCharacter[(*iter).second] = (*iter).first;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::c_StandardLayout = 0;
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::c_ETenLayout = 0;
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::c_HsuLayout = 0;
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::c_ETen26Layout = 0;
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::c_IBMLayout = 0;
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::c_HanyuPinyinLayout = 0;

void BopomofoKeyboardLayout::FinalizeLayouts()
{
    #define FL(x) if (x) { delete x; } x = 0
    FL(c_StandardLayout);
    FL(c_ETenLayout);
    FL(c_HsuLayout);
    FL(c_ETen26Layout);
    FL(c_IBMLayout);
    FL(c_HanyuPinyinLayout);
    #undef FL
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::LayoutForName(const string& name)
{
    if (OVWildcard::Match(name, "standard"))
        return StandardLayout();
        
    if (OVWildcard::Match(name, "eten"))
        return ETenLayout();
        
    if (OVWildcard::Match(name, "hsu"))
        return HsuLayout();
    
    if (OVWildcard::Match(name, "eten26"))
        return ETen26Layout();

    if (OVWildcard::Match(name, "IBM"))
        return IBMLayout();

    if (OVWildcard::Match(name, "hanyupinyin") || OVWildcard::Match(name, "hanyu pinyin") || OVWildcard::Match(name, "hanyu-pinyin") || OVWildcard::Match(name, "pinyin"))
        return HanyuPinyinLayout();

    return 0;
}

#define ASSIGNKEY1(m, vec, k, val) m[k] = (vec.clear(), vec.push_back((BPMF::Component)val), vec)
#define ASSIGNKEY2(m, vec, k, val1, val2) m[k] = (vec.clear(), vec.push_back((BPMF::Component)val1), vec.push_back((BPMF::Component)val2), vec)
#define ASSIGNKEY3(m, vec, k, val1, val2, val3) m[k] = (vec.clear(), vec.push_back((BPMF::Component)val1), vec.push_back((BPMF::Component)val2), vec.push_back((BPMF::Component)val3), vec)

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::StandardLayout()
{
    if (!c_StandardLayout) {
        vector<BPMF::Component> vec;
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
        
        c_StandardLayout = new BopomofoKeyboardLayout(ktcm, "Standard");
    }
    
    return c_StandardLayout;
}
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::IBMLayout()
{
    if (!c_IBMLayout) {
        vector<BPMF::Component> vec;
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
        
        c_IBMLayout = new BopomofoKeyboardLayout(ktcm, "IBM");
    }
    
    return c_IBMLayout;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::ETenLayout()
{
    if (!c_ETenLayout) {
        vector<BPMF::Component> vec;
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
        
        c_ETenLayout = new BopomofoKeyboardLayout(ktcm, "ETen");
    }
    
    return c_ETenLayout;
}

const BopomofoKeyboardLayout* BopomofoKeyboardLayout::HsuLayout()
{
    if (!c_HsuLayout) {
        vector<BPMF::Component> vec;
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
        
        c_HsuLayout = new BopomofoKeyboardLayout(ktcm, "Hsu");
    }
    
    return c_HsuLayout;
}
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::ETen26Layout()
{
    if (!c_ETen26Layout) {
        vector<BPMF::Component> vec;
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
        
        c_ETen26Layout = new BopomofoKeyboardLayout(ktcm, "ETen26");
    }
    
    return c_ETen26Layout;
}
const BopomofoKeyboardLayout* BopomofoKeyboardLayout::HanyuPinyinLayout()
{
    if (!c_HanyuPinyinLayout) {
        BopomofoKeyToComponentMap ktcm;
        c_HanyuPinyinLayout = new BopomofoKeyboardLayout(ktcm, "HanyuPinyin");
    }
    return c_HanyuPinyinLayout;
}


} // namespace Mandarin
} // namespace Formosa
