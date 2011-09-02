//
// OVFrameworkInfo.h
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

#ifndef OVFrameworkVersion_h
#define OVFrameworkVersion_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVBase.h>
#else
    #include "OVBase.h"
#endif

#include <sstream>

namespace OpenVanilla {
    using namespace std;
    
	class OVFrameworkInfo {
    public:
        static unsigned int MajorVersion()
        {
            return c_MajorVersion;
        }
        
        static unsigned int MinorVersion()
        {
            return c_MinorVersion;
        }
        
        static unsigned int TinyVersion()
        {
            return c_TinyVersion;
        }
        
        static unsigned int Version()
        {
            return ((c_MajorVersion & 0xff) << 24) | ((c_MinorVersion & 0xff)<< 16) | (c_TinyVersion & 0xffff);
        }
        
        static unsigned int BuildNumber()
        {
            return c_FrameworkBuildNumber;
        }
        
        static const string VersionString(bool withBuildNumber = false)
        {
            stringstream s;
            s << c_MajorVersion << "." << c_MinorVersion << "." << c_TinyVersion;
            if (withBuildNumber)
                s << "." << c_FrameworkBuildNumber;
                
            return s.str();
        }
        
        static const string VersionStringWithBuildNumber()
        {
            return VersionString(true);
        }
        
    protected:
        static const unsigned int c_MajorVersion;
        static const unsigned int c_MinorVersion;
        static const unsigned int c_TinyVersion;
        static const unsigned int c_FrameworkBuildNumber;        
    };
};

#endif
