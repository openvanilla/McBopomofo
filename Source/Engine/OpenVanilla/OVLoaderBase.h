//
// OVLoaderBase.h
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

#ifndef OVLoaderBase_h
#define OVLoaderBase_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVModule.h>
#else
    #include "OVModule.h"
#endif

namespace OpenVanilla {
    using namespace std;

    class OVLoader : public OVBase {
    public:
        virtual OVLoaderService* loaderService() = 0;
        virtual OVModule* moduleForIdentifier(const string& identifier) = 0;
        virtual vector<string> moduleIdentifiers() = 0;
        virtual vector<string> moduleIdentifiersForConditions(bool preprocessor, bool inputMethod, bool outputFilter) = 0;
    };

};

#endif
