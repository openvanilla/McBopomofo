//
// Mandarin.h
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

#ifndef Mandarin_h
#define Mandarin_h

#include <iostream>
#include <string>
#include <vector>
#include <map>

namespace Formosa {
    namespace Mandarin {
        using namespace std;
        
        class BopomofoSyllable {
        public:
            typedef unsigned int Component;
            BopomofoSyllable(Component syllable = 0)
                : m_syllable(syllable)
            {
            }
            
            BopomofoSyllable(const BopomofoSyllable& another)
                : m_syllable(another.m_syllable)
            {
            }
            
            ~BopomofoSyllable()
            {
            }
            
            BopomofoSyllable& operator=(const BopomofoSyllable& another)
            {
                m_syllable = another.m_syllable;
                return *this;
            }
            
            // takes the ASCII-form, "v"-tolerant, TW-style Hanyu Pinyin (fong, pong, bong acceptable)            
            static const BopomofoSyllable FromHanyuPinyin(const string& str);
            
            // TO DO: Support accented vowels
            const string HanyuPinyinString(bool includesTone, bool useVForUUmlaut) const;            
            // const string HanyuPinyinString(bool includesTone, bool useVForUUmlaut, bool composeAccentedVowel) const;
            
            // PHT = Pai-hua-tsi
            static const BopomofoSyllable FromPHT(const string& str);
            const string PHTString(bool includesTone) const;
            
            static const BopomofoSyllable FromComposedString(const string& str);
            const string composedString() const;
                      
            void clear()
            {
                m_syllable = 0;
            }
                      
            bool isEmpty() const
            {
                return !m_syllable;
            }
            
            bool hasConsonant() const
            {
                return !!(m_syllable & ConsonantMask);
            }
            
            bool hasMiddleVowel() const
            {
                return !!(m_syllable & MiddleVowelMask);
            }
            bool hasVowel() const
            {
                return !!(m_syllable & VowelMask);
            }
            
            bool hasToneMarker() const
            {
                return !!(m_syllable & ToneMarkerMask);
            }
            
            Component consonantComponent() const
            {
                return m_syllable & ConsonantMask;
            }
            
            Component middleVowelComponent() const
            {
                return m_syllable & MiddleVowelMask;
            }
            
            Component vowelComponent() const
            {
                return m_syllable & VowelMask;
            }
            
            Component toneMarkerComponent() const
            {
                return m_syllable & ToneMarkerMask;
            }
            
            bool operator==(const BopomofoSyllable& another) const
            {
                return m_syllable == another.m_syllable;
            }

            bool operator!=(const BopomofoSyllable& another) const
            {
                return m_syllable != another.m_syllable;
            }
            
            bool isOverlappingWith(const BopomofoSyllable& another) const
            {
                #define IOW_SAND(mask) ((m_syllable & mask) && (another.m_syllable & mask))
                return IOW_SAND(ConsonantMask) || IOW_SAND(MiddleVowelMask) || IOW_SAND(VowelMask) || IOW_SAND(ToneMarkerMask);
                #undef IOW_SAND
            }
            
            // consonants J, Q, X all require the existence of vowel I or UE
            bool belongsToJQXClass() const
            {
                Component consonant = m_syllable & ConsonantMask;
                return (consonant == J || consonant == Q || consonant == X);
            }
            
            // zi, ci, si, chi, chi, shi, ri
            bool belongsToZCSRClass() const
            {
                Component consonant = m_syllable & ConsonantMask;
                return (consonant >= ZH && consonant <= S);
            }
            
            Component maskType() const
            {
                Component mask = 0;                
                mask |= (m_syllable & ConsonantMask) ? ConsonantMask : 0;
                mask |= (m_syllable & MiddleVowelMask) ? MiddleVowelMask : 0;
                mask |= (m_syllable & VowelMask) ? VowelMask : 0;
                mask |= (m_syllable & ToneMarkerMask) ? ToneMarkerMask : 0;
                return mask;
            }
            
            const BopomofoSyllable operator+(const BopomofoSyllable& another) const
            {
                Component newSyllable = m_syllable;
                #define OP_SOVER(mask) if (another.m_syllable & mask) newSyllable = (newSyllable & ~mask) | (another.m_syllable & mask)
                OP_SOVER(ConsonantMask);
                OP_SOVER(MiddleVowelMask);
                OP_SOVER(VowelMask);
                OP_SOVER(ToneMarkerMask);
                #undef OP_SOVER
                return BopomofoSyllable(newSyllable);
            }
            
            BopomofoSyllable& operator+=(const BopomofoSyllable& another)
            {
                #define OPE_SOVER(mask) if (another.m_syllable & mask) m_syllable = (m_syllable & ~mask) | (another.m_syllable & mask)
                OPE_SOVER(ConsonantMask);
                OPE_SOVER(MiddleVowelMask);
                OPE_SOVER(VowelMask);
                OPE_SOVER(ToneMarkerMask);
                #undef OPE_SOVER
                return *this;
            }

            short absoluteOrder() const
            {
                // turn BPMF syllable into a 4*14*4*22 number
                return (short)(m_syllable & ConsonantMask) +
                    (short)((m_syllable & MiddleVowelMask) >> 5) * 22 +
                    (short)((m_syllable & VowelMask) >> 7) * 22 * 4 +
                    (short)((m_syllable & ToneMarkerMask) >> 11) * 22 * 4 * 14;
            }
            
            const string absoluteOrderString() const
            {
                // 5*14*4*22 = 6160, we use a 79*79 encoding to represent that
                short order = absoluteOrder();
                char low  = 48 + (char)(order % 79);
                char high = 48 + (char)(order / 79);
                string result(2, ' ');
                result[0] = low;
                result[1] = high;
                return result;
            }
            
            static BopomofoSyllable FromAbsoluteOrder(short order)
            {
                return BopomofoSyllable(
                    (order % 22) |
                    ((order / 22) % 4) << 5 |
                    ((order / (22 * 4)) % 14) << 7 |
                    ((order / (22 * 4 * 14)) % 5) << 11 
                    );
            }
            
            static BopomofoSyllable FromAbsoluteOrderString(const string& str)
            {
                if (str.length() != 2)
                    return BopomofoSyllable();
                  
                return FromAbsoluteOrder((short)(str[1] - 48) * 79 + (short)(str[0] - 48));
            }

            friend ostream& operator<<(ostream& stream, const BopomofoSyllable& syllable);

            static const Component
                ConsonantMask = 0x001f,	    // 0000 0000 0001 1111, 21 consonants
                MiddleVowelMask = 0x0060,   // 0000 0000 0110 0000, 3 middle vowels
                VowelMask = 0x0780,		    // 0000 0111 1000 0000, 13 vowels
                ToneMarkerMask = 0x3800,	// 0011 1000 0000 0000, 5 tones (tone1 = 0x00)
                B = 0x0001, P = 0x0002, M = 0x0003, F = 0x0004,
                D = 0x0005, T = 0x0006, N = 0x0007, L = 0x0008,
                G = 0x0009, K = 0x000a, H = 0x000b, 
                J = 0x000c, Q = 0x000d, X = 0x000e,
                ZH = 0x000f, CH = 0x0010, SH = 0x0011, R = 0x0012,
                Z = 0x0013, C = 0x0014, S = 0x0015,
                I = 0x0020, U = 0x0040, UE = 0x0060,    // ue = u umlaut (we use the German convention here as an ersatz to the /ju:/ sound)
                A = 0x0080, O = 0x0100, ER = 0x0180, E = 0x0200,
                AI = 0x0280, EI = 0x0300, AO = 0x0380, OU = 0x0400,
                AN = 0x0480, EN = 0x0500, ANG = 0x0580, ENG = 0x0600,
                ERR = 0x0680,
                Tone1 = 0x0000, Tone2 = 0x0800, Tone3 = 0x1000, Tone4 = 0x1800, Tone5 = 0x2000;
            
        protected:
            Component m_syllable;
        };
        
        inline ostream& operator<<(ostream& stream, const BopomofoSyllable& syllable)
        {
            stream << syllable.composedString();
            return stream;
        }        
        
        typedef BopomofoSyllable BPMF;
        
        typedef map<char, vector<BPMF::Component> > BopomofoKeyToComponentMap;
        typedef map<BPMF::Component, char> BopomofoComponentToKeyMap;
        
        class BopomofoKeyboardLayout {
        public:
            static void FinalizeLayouts();
            static const BopomofoKeyboardLayout* StandardLayout();
            static const BopomofoKeyboardLayout* ETenLayout();
            static const BopomofoKeyboardLayout* HsuLayout();
            static const BopomofoKeyboardLayout* ETen26Layout();
            static const BopomofoKeyboardLayout* HanyuPinyinLayout();
            
            // recognizes (case-insensitive): standard, eten, hsu, eten26
            static const BopomofoKeyboardLayout* LayoutForName(const string& name);            
            
            BopomofoKeyboardLayout(const BopomofoKeyToComponentMap& ktcm, const string& name)
                : m_keyToComponent(ktcm)
                , m_name(name)
            {
                for (BopomofoKeyToComponentMap::const_iterator miter = m_keyToComponent.begin() ; miter != m_keyToComponent.end() ; ++miter)
                    for (vector<BPMF::Component>::const_iterator viter = (*miter).second.begin() ; viter != (*miter).second.end() ; ++viter)
                        m_componentToKey[*viter] = (*miter).first;
            }
            
            const string name() const
            {
                return m_name;
            }
            
            char componentToKey(BPMF::Component component) const
            {
                BopomofoComponentToKeyMap::const_iterator iter = m_componentToKey.find(component);
                return (iter == m_componentToKey.end()) ? 0 : (*iter).second;
            }
            
            const vector<BPMF::Component> keyToComponents(char key) const
            {
                BopomofoKeyToComponentMap::const_iterator iter = m_keyToComponent.find(key);
                return (iter == m_keyToComponent.end()) ? vector<BPMF::Component>() : (*iter).second;
            }
            
            const string keySequenceFromSyllable(BPMF syllable) const
            {
                string sequence;
                
                BPMF::Component c;
                char k;
                #define STKS_COMBINE(component) if ((c = component)) { if ((k = componentToKey(c))) sequence += string(1, k); }
                STKS_COMBINE(syllable.consonantComponent());
                STKS_COMBINE(syllable.middleVowelComponent());
                STKS_COMBINE(syllable.vowelComponent());
                STKS_COMBINE(syllable.toneMarkerComponent());
                #undef STKS_COMBINE
                return sequence;
            }
            
            const BPMF syllableFromKeySequence(const string& sequence) const
            {
                BPMF syllable;
                
                for (string::const_iterator iter = sequence.begin() ; iter != sequence.end() ; ++iter)
                {
                    bool beforeSeqHasIorUE = sequenceContainsIorUE(sequence.begin(), iter);
                    bool aheadSeqHasIorUE = sequenceContainsIorUE(iter + 1, sequence.end());
    
                    vector<BPMF::Component> components = keyToComponents(*iter);

                    if (!components.size())
                        continue;
                        
                    if (components.size() == 1) {
                        syllable += BPMF(components[0]);
                        continue;
                    }
                        
                    BPMF head = BPMF(components[0]);
                    BPMF follow = BPMF(components[1]);
                    BPMF ending = components.size() > 2 ? BPMF(components[2]) : follow;
                    
                    // apply the I/UE + E rule
                    if (head.vowelComponent() == BPMF::E && follow.vowelComponent() != BPMF::E)
                    {
                        syllable += beforeSeqHasIorUE ? head : follow;
                        continue;
                    }
                    
                    if (head.vowelComponent() != BPMF::E && follow.vowelComponent() == BPMF::E)
                    {
                        syllable += beforeSeqHasIorUE ? follow : head;
                        continue;
                    }
                    
                    // apply the J/Q/X + I/UE rule, only two components are allowed in the components vector here
                    if (head.belongsToJQXClass() && !follow.belongsToJQXClass()) {
                        if (!syllable.isEmpty()) {
                            if (ending != follow)
                                syllable += ending;
                        }
                        else {
                            syllable += aheadSeqHasIorUE ? head : follow;
                        }
                        
                        continue;
                    }

                    if (!head.belongsToJQXClass() && follow.belongsToJQXClass()) {
                        if (!syllable.isEmpty()) {
                            if (ending != follow)
                                syllable += ending;
                        }
                        else {
                            syllable += aheadSeqHasIorUE ? follow : head;
                        }
                        
                        continue;
                    }

                    // the nasty issue of only one char in the buffer
                    if (iter == sequence.begin() && iter + 1 == sequence.end()) {
                        if (head.hasVowel() || follow.hasToneMarker() || head.belongsToZCSRClass())
                            syllable += head;
                        else {
                            if (follow.hasVowel() || ending.hasToneMarker())
                                syllable += follow;
                            else
                                syllable += ending;
                        }
                            
                        
                        continue;
                    }
                    
                    if (!(syllable.maskType() & head.maskType()) && !endAheadOrAheadHasToneMarkKey(iter + 1, sequence.end())) {
                        syllable += head;
                    }
                    else {
                        if (endAheadOrAheadHasToneMarkKey(iter + 1, sequence.end()) && head.belongsToZCSRClass() && syllable.isEmpty()) {
                            syllable += head;
                        }
                        else if (syllable.maskType() < follow.maskType()) {
                            syllable += follow;
                        }
                        else {
                            syllable += ending;
                        }
                    }
                }
                
                // heuristics for Hsu keyboard layout
                if (this == HsuLayout()) {
                    // fix the left out L to ERR when it has sound, and GI, GUE -> JI, JUE
                    if (syllable.vowelComponent() == BPMF::ENG && !syllable.hasConsonant() && !syllable.hasMiddleVowel()) {
                        syllable += BPMF(BPMF::ERR);
                    }
                    else if (syllable.consonantComponent() == BPMF::G && (syllable.middleVowelComponent() == BPMF::I || syllable.middleVowelComponent() == BPMF::UE)) {
                        syllable += BPMF(BPMF::J);
                    }
                }   
                
                             
                return syllable;
            }
            
            
        protected:
            bool endAheadOrAheadHasToneMarkKey(string::const_iterator ahead, string::const_iterator end) const
            {
                if (ahead == end)
                    return true;
                
                char tone1 = componentToKey(BPMF::Tone1);
                char tone2 = componentToKey(BPMF::Tone2);
                char tone3 = componentToKey(BPMF::Tone3);
                char tone4 = componentToKey(BPMF::Tone4);
                char tone5 = componentToKey(BPMF::Tone5);
                
                if (tone1)
                    if (*ahead == tone1) return true;
                    
                if (*ahead == tone2 || *ahead == tone3 || *ahead == tone4 || *ahead == tone5)
                    return true;
                    
                return false;
            }
            
            bool sequenceContainsIorUE(string::const_iterator start, string::const_iterator end) const
            {
                char iChar = componentToKey(BPMF::I);
                char ueChar = componentToKey(BPMF::UE);
                
                for (; start != end; ++start)
                    if (*start == iChar || *start == ueChar)
                        return true;
                return false;
            }

            string m_name;
            BopomofoKeyToComponentMap m_keyToComponent;
            BopomofoComponentToKeyMap m_componentToKey;

            static const BopomofoKeyboardLayout* c_StandardLayout;
            static const BopomofoKeyboardLayout* c_ETenLayout;
            static const BopomofoKeyboardLayout* c_HsuLayout;
            static const BopomofoKeyboardLayout* c_ETen26Layout;                                    

            // this is essentially an empty layout, but we use pointer semantic to tell the differences--and pass on the responsibility to BopomofoReadingBuffer
            static const BopomofoKeyboardLayout* c_HanyuPinyinLayout;                                    
        };
        
        class BopomofoReadingBuffer {
        public:
            BopomofoReadingBuffer(const BopomofoKeyboardLayout* layout)
                : m_layout(layout)
                , m_pinyinMode(false)
            {
                if (layout == BopomofoKeyboardLayout::HanyuPinyinLayout()) {
                    m_pinyinMode = true;
                    m_pinyinSequence = "";
                }
            }
            
            void setKeyboardLayout(const BopomofoKeyboardLayout* layout)
            {
                m_layout = layout;

                if (layout == BopomofoKeyboardLayout::HanyuPinyinLayout()) {
                    m_pinyinMode = true;
                    m_pinyinSequence = "";
                }
            }
            
            bool isValidKey(char k) const
            {
                if (!m_pinyinMode) {                
                    return m_layout ? (m_layout->keyToComponents(k)).size() > 0 : false;
                }
                
                char lk = tolower(k);
                if (lk >= 'a' && lk <= 'z') {
                    // if a tone marker is already in place                    
                    if (m_pinyinSequence.length()) {
                        char lastc = m_pinyinSequence[m_pinyinSequence.length() - 1];
                        if (lastc >= '2' && lastc <= '5') {
                            return false;
                        }
                        return true;
                    }
                    return true;
                }
                
                if (m_pinyinSequence.length() && (lk >= '2' && lk <= '5')) {
                    return true;
                }
                
                return false;
            }
            
            bool combineKey(char k)
            {
                if (!isValidKey(k))
                    return false;
                    
                if (m_pinyinMode) {
                    m_pinyinSequence += string(1, tolower(k));
                    m_syllable = BPMF::FromHanyuPinyin(m_pinyinSequence);
                    return true;
                }

                string sequence = m_layout->keySequenceFromSyllable(m_syllable) + string(1, k);
                m_syllable = m_layout->syllableFromKeySequence(sequence);
                return true;
            }
            
            void clear()
            {
                m_pinyinSequence.clear();
                m_syllable.clear();
            }
            
            void backspace()
            {
                if (!m_layout)
                    return;
                
                if (m_pinyinMode) {
                    if (m_pinyinSequence.length()) {
                        m_pinyinSequence = m_pinyinSequence.substr(0, m_pinyinSequence.length() - 1);
                    }
                    
                    m_syllable = BPMF::FromHanyuPinyin(m_pinyinSequence);
                    return;
                }
                
                string sequence = m_layout->keySequenceFromSyllable(m_syllable);
                if (sequence.length()) {
                    sequence = sequence.substr(0, sequence.length() - 1);
                    m_syllable = m_layout->syllableFromKeySequence(sequence);
                }
            }
            
            bool isEmpty() const
            {
                return m_syllable.isEmpty();
            }
            
            const string composedString() const
            {
                if (m_pinyinMode) {
                    return m_pinyinSequence;
                }
                
                return m_syllable.composedString();
            }
            
            const BPMF syllable() const
            {
                return m_syllable;
            }
            
            const string standardLayoutQueryString() const
            {
                return BopomofoKeyboardLayout::StandardLayout()->keySequenceFromSyllable(m_syllable);
            }

            const string absoluteOrderQueryString() const
            {
                return m_syllable.absoluteOrderString();
            }
            
            bool hasToneMarker() const
            {
                return m_syllable.hasToneMarker();
            }
            
        protected:
            const BopomofoKeyboardLayout* m_layout;
            BPMF m_syllable;
            
            bool m_pinyinMode;
            string m_pinyinSequence;
        };
    }
}

#endif
