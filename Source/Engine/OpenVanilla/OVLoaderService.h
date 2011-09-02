//
// OVLoaderService.h
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

#ifndef OVLoaderService_h
#define OVLoaderService_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVBase.h>
    #include <OpenVanilla/OVDatabaseService.h>
    #include <OpenVanilla/OVEncodingService.h>
    #include <OpenVanilla/OVKey.h>
#else
    #include "OVBase.h"
    #include "OVDatabaseService.h"
    #include "OVEncodingService.h"
    #include "OVKey.h"
#endif

#include <iostream>
#include <sstream>

namespace OpenVanilla {
    using namespace std;

    class OVLogEmitter : public OVBase {
    public:
        virtual const string sectionName() const = 0;
        virtual void setSectionName(const string& sectionName) = 0;
        virtual void emitLog(const string& logEntry) = 0;
    };
    
    class OVLogStringBuffer : public stringbuf {
    public:
        OVLogStringBuffer(OVLogEmitter* logEmitter = 0)
            : m_logEmitter(logEmitter)
        {
        }
        
        virtual int sync() {
            if (str().length()) {
                if (m_logEmitter)
                    m_logEmitter->emitLog(str());
                else
                    cerr << "Log: " << str();

                str(string());
            }
            
            // clear the buffer
            return 0;
        }
    
        virtual OVLogEmitter* logEmitter() const
        {
            return m_logEmitter;
        }
        
        virtual void setLogEmitter(OVLogEmitter* logEmitter)
        {
            m_logEmitter = logEmitter;
        }
    
    protected:
        OVLogEmitter* m_logEmitter;
    };

    class OVLoaderService : public OVBase {
    public:
        virtual void beep() = 0;
        virtual void notify(const string& message) = 0;
        virtual void HTMLNotify(const string& content) = 0;

        virtual const string locale() const = 0;
        virtual const OVKey makeOVKey(int characterCode, bool alt = false, bool opt = false, bool ctrl = false, bool shift = false, bool command = false, bool capsLock = false, bool numLock = false) = 0;
        virtual const OVKey makeOVKey(const string& receivedString, bool alt = false, bool opt = false, bool ctrl = false, bool shift = false, bool command = false, bool capsLock = false, bool numLock = false) = 0;

        virtual ostream& logger(const string& sectionName = "") = 0;
        
        virtual OVDatabaseService* defaultDatabaseService() = 0;
        virtual OVDatabaseService* CINDatabaseService() = 0;
        virtual OVDatabaseService* SQLiteDatabaseService() = 0;
        
        virtual OVEncodingService* encodingService() = 0;
        
		virtual void __reserved1(const string&) = 0;
        virtual void __reserved2(const string&) = 0;
        virtual void __reserved3(const string&) = 0;
		virtual void __reserved4(const string&) = 0;
		virtual const string __reserved5() const = 0;
		virtual void __reserved6(const string&) = 0;
		virtual void __reserved7(const string&, const string &) = 0;
        virtual void* __reserved8(const string&) = 0;
    };
};

#endif
