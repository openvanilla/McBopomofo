//
// OVKey.h
//
// Copyright (c) 2007-2010 Lukhnos D. Liu and Weizhong Yang
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

#ifndef OVKey_h
#define OVKey_h

namespace OpenVanilla {
    using namespace std;
    
    // keyCode() is 0 if receivedString() is a non-ASCII glyph/string
    class OVKeyInterface : public OVBase {
    public:
        virtual const string receivedString() const = 0;
        virtual unsigned int keyCode() const = 0;
        virtual bool isAltPressed() const = 0;
        virtual bool isOptPressed() const = 0;
        virtual bool isCtrlPressed() const = 0;
        virtual bool isShiftPressed() const = 0;
        virtual bool isCommandPressed() const = 0;
        virtual bool isNumLockOn() const = 0;
        virtual bool isCapsLockOn() const = 0;
        
        // a direct text key carries a composed glyph (or a string) that semantically differs from the intended keystroke
        // (i.e. a half-width char stroke but with a composed, full-width char output)
        virtual bool isDirectTextKey() const = 0;
    };

    class OVKeyImpl : public OVKeyInterface {
    public:
        virtual bool shouldDelete() const = 0;
        virtual OVKeyImpl* copy() = 0;
    };

    class OVKey : public OVKeyInterface {
    public:
        OVKey(OVKeyImpl* keyImpl = 0)
            : m_keyImpl(keyImpl)
        {
        }
        
        OVKey(const OVKey& aKey)
        {
            m_keyImpl = aKey.m_keyImpl ? aKey.m_keyImpl->copy() : 0;
        }
        
        ~OVKey()
        {
            if (m_keyImpl) {
                if (m_keyImpl->shouldDelete()) {
                    delete m_keyImpl;
                }                
            }
        }
        
        OVKey& operator=(const OVKey& aKey)
        {
            if (m_keyImpl) {
                if (m_keyImpl->shouldDelete()) {
                    delete m_keyImpl;
                }
				
				m_keyImpl = 0;
            }
		
            m_keyImpl = aKey.m_keyImpl ? aKey.m_keyImpl->copy() : 0;
            return *this;
        }
                
        virtual bool operator==(const OVKey& key) const
        {
            if (isAltPressed() == key.isAltPressed() && isOptPressed() == key.isOptPressed() && isCtrlPressed() == key.isCtrlPressed() && isShiftPressed() == key.isShiftPressed() && isCommandPressed() == key.isCommandPressed())
                if (!keyCode() && !key.keyCode())
                    return receivedString() == key.receivedString();
                else
                    return keyCode() == key.keyCode();

            return false;
        }
        
        virtual bool operator<(const OVKey& key) const
        {            
            if (keyCode() < key.keyCode()) return true;
            if (keyCode() > key.keyCode()) return false;

            if (!keyCode() && !key.keyCode()) {
                if (receivedString() < key.receivedString()) return true;
                if (receivedString() > key.receivedString()) return false;
            }

            if (isAltPressed() != key.isAltPressed()) {
                if (key.isAltPressed()) return true;
                if (isAltPressed()) return false;
            }
            
            if (isOptPressed() != key.isOptPressed()) {
                if (key.isOptPressed()) return true;
                if (isOptPressed()) return false;
            }
            
            if (isCtrlPressed() != key.isCtrlPressed()) {
                if (key.isCtrlPressed()) return true;
                if (isCtrlPressed()) return false;
            }

            if (isShiftPressed() != key.isShiftPressed()) {
                if (key.isShiftPressed()) return true;
                if (isShiftPressed()) return false;
            }

            if (isCommandPressed() != key.isCommandPressed()) {
                if (key.isCommandPressed()) return true;
                if (isCommandPressed()) return false;
            }

            if (isNumLockOn() != key.isNumLockOn()) {
                if (key.isNumLockOn()) return true;
                if (isNumLockOn()) return false;
            }

            if (isCapsLockOn() != key.isCapsLockOn()) {
                if (key.isCapsLockOn()) return true;
                if (isCapsLockOn()) return false;
            }

            return false;
        }
    
    public:
        virtual const string receivedString() const
        {
            return m_keyImpl ? m_keyImpl->receivedString() : string();
        }
        
        virtual unsigned int keyCode() const
        {
            return m_keyImpl ? m_keyImpl->keyCode() : 0;
        }
        
        virtual bool isAltPressed() const
        {
            return m_keyImpl ? m_keyImpl->isAltPressed() : false;
        }
        
        virtual bool isOptPressed() const
        {
            return m_keyImpl ? m_keyImpl->isOptPressed() : false;
        }
        
        virtual bool isCtrlPressed() const
        {
            return m_keyImpl ? m_keyImpl->isCtrlPressed() : false;
        }
        
        virtual bool isShiftPressed() const
        {
            return m_keyImpl ? m_keyImpl->isShiftPressed() : false;
        }
        
        virtual bool isCommandPressed() const
        {
            return m_keyImpl ? m_keyImpl->isCommandPressed() : false;
        }
        
        virtual bool isNumLockOn() const
        {
            return m_keyImpl ? m_keyImpl->isNumLockOn() : false;
        }
        
        virtual bool isCapsLockOn() const
        {
            return m_keyImpl ? m_keyImpl->isCapsLockOn() : false;
        }
        
        virtual bool isDirectTextKey() const
        {
            return m_keyImpl ? m_keyImpl->isDirectTextKey() : false;            
        }
        
        virtual bool isKeyCodePrintable() const
        {
            if (keyCode() >= 32 && keyCode() <= 126)
                return true;
            
            return false;
        }
        
        virtual bool isKeyCodeNumeric() const
        {
            if (keyCode() >= '0' && keyCode() <= '9')
                return true;
            
            return false;
        }
        
        virtual bool isKeyCodeAlpha() const
        {
            if (keyCode() >= 'A' && keyCode() <= 'Z' || keyCode() >= 'a' && keyCode() <= 'z')
                return true;
            
            return false;
        }
        
        virtual bool isCombinedFunctionKey() const
        {
            return isCtrlPressed() || isAltPressed() || isOptPressed() || isCommandPressed();
        }
        
        virtual bool isPrintable() const
        {
            size_t rssize = receivedString().size();
            unsigned int code = keyCode();
                        
            if (!rssize)
                return false;
                
            if (rssize > 1)
                return true;
                
            return ((code < 128 && isprint((char)code)) || code > 128);
        }

    protected:
        OVKeyImpl* m_keyImpl;                
    };
    
    typedef vector<OVKey> OVKeyVector;

    class OVKeyCode {
    public:
        enum {
            Delete = 127,
            Backspace = 8,
            Up = 30, 
            Down = 31, 
            Left = 28, 
            Right = 29,
            Home = 1,
            End = 4,
            PageUp = 11,
            PageDown = 12,
            Tab = 9,
            Esc = 27,
            Space = 32,
            Return = 13,
            Enter = Return,
            LeftShift = 0x10001,
            RightShift = 0x10002,
            CapsLock = 0x10010,
            MacEnter = 0x10020,
            F1 = 0x11001,
            F2 = 0x11002,
            F3 = 0x11003,
            F4 = 0x11004,
            F5 = 0x11005,
            F6 = 0x11006,
            F7 = 0x11007,
            F8 = 0x11008,
            F9 = 0x11009,
            F10 = 0x11010,          
        };        
    };

    class OVKeyMask {
    public:
        enum {
            Alt = 0x0001,
            Opt = 0x0002,
            AltOpt = 0x0003,
            Ctrl = 0x0004,
            Shift = 0x008,
            Command = 0x0010,
            NumLock = 0x0020,
            CapsLock = 0x0040,
            DirectText = 0x0080
        };        
    };
};

#endif
