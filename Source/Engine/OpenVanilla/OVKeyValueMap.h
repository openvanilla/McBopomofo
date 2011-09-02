//
// OVKeyValueMap.h
//
// Copyright (c) 2007-2010 Lukhnos D. Liu
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

#ifndef OVKeyValueMap_h
#define OVKeyValueMap_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVBase.h>
#else
    #include "OVBase.h"
#endif

#include <sstream>

namespace OpenVanilla {
    using namespace std;
    
    class OVKeyValueMapInterface : public OVBase {
    public:
        virtual bool isReadOnly() = 0;
        virtual bool setKeyStringValue(const string& key, const string& value) = 0;
        virtual bool hasKey(const string& key) = 0;
        virtual const string stringValueForKey(const string& key) = 0;
        
        virtual bool setKeyIntValue(const string& key, int value)
        {
            stringstream sstr;
            sstr << value;
            return setKeyStringValue(key, sstr.str());
        }
        
        virtual bool setKeyBoolValue(const string& key, bool value)
        {
            if (value)
                return setKeyStringValue(key, "true");
            
            return setKeyStringValue(key, "false");
        }
        
        virtual int intValueForKey(const string& key)
        {
            string value = stringValueForKey(key);
            return atoi(value.c_str());
        }
        
        virtual const string stringValueForKeyWithDefault(const string& key, const string& defaultValue = "", bool setIfNotFound = true)
        {
            if (hasKey(key))
                return stringValueForKey(key);
            
            if (setIfNotFound)
                setKeyStringValue(key, defaultValue);
            
            return defaultValue;
        }
        
        virtual const string operator[](const string& key)
        {
            return stringValueForKey(key);
        }
        
        virtual bool isKeyTrue(const string& key)
        {
            if (!hasKey(key))
                return false;
              
            string value = stringValueForKey(key);
            
            if (atoi(value.c_str()) > 0)
                return true;
                
            if (value == "true")
                return true;
            
            return false;
        }
    };
    
    class OVKeyValueMapImpl : public OVKeyValueMapInterface {
    public:
        virtual bool shouldDelete() = 0;
        virtual OVKeyValueMapImpl* copy() = 0;
    };
        
    class OVKeyValueMap : public OVKeyValueMapInterface {
    public:
        OVKeyValueMap(OVKeyValueMapImpl* keyValueMapImpl = 0)
            : m_keyValueMapImpl(keyValueMapImpl)
        {
        }
        
        OVKeyValueMap(const OVKeyValueMap& aKeyValueMap)
        {
            m_keyValueMapImpl = aKeyValueMap.m_keyValueMapImpl ? aKeyValueMap.m_keyValueMapImpl->copy() : 0;
        }
        
        ~OVKeyValueMap()
        {
            if (m_keyValueMapImpl) {
                if (m_keyValueMapImpl->shouldDelete()) {
                    delete m_keyValueMapImpl;
                }                
            }
        }
        
        OVKeyValueMap& operator=(const OVKeyValueMap& aKeyValueMap)
        {
            if (m_keyValueMapImpl) {
                if (m_keyValueMapImpl->shouldDelete()) {
                    delete m_keyValueMapImpl;
                }             
				
				m_keyValueMapImpl = 0;
            }

            m_keyValueMapImpl = aKeyValueMap.m_keyValueMapImpl ? aKeyValueMap.m_keyValueMapImpl->copy() : 0;
            return *this;
        }

    public:
        virtual bool isReadOnly()
        {
            return m_keyValueMapImpl ? m_keyValueMapImpl->isReadOnly() : true;
        }
        
        virtual bool setKeyStringValue(const string& key, const string& value)
        {
            return m_keyValueMapImpl ? m_keyValueMapImpl->setKeyStringValue(key, value) : false;
        }
        
        virtual bool hasKey(const string& key)
        {
            return m_keyValueMapImpl ? m_keyValueMapImpl->hasKey(key) : false;
        }
        
        virtual const string stringValueForKey(const string& key)
        {
            return m_keyValueMapImpl ? m_keyValueMapImpl->stringValueForKey(key) : string();
        }
        
        virtual const string stringValueForKeyWithDefault(const string& key, const string& defaultValue = "", bool setIfNotFound = true)
        {
            return m_keyValueMapImpl ? m_keyValueMapImpl->stringValueForKeyWithDefault(key, defaultValue, setIfNotFound) : string();
        }
        
    protected:
        OVKeyValueMapImpl* m_keyValueMapImpl;
    };
};

#endif
