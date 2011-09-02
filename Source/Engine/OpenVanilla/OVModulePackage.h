//
// OVModulePackage.h
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

#ifndef OVModulePackage_h
#define OVModulePackage_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVFrameworkInfo.h>
    #include <OpenVanilla/OVModule.h>
#else
    #include "OVFrameworkInfo.h"
    #include "OVModule.h"
#endif

#ifdef WIN32
	#define OVEXPORT __declspec(dllexport)
#else
	#define OVEXPORT
#endif

namespace OpenVanilla {
    using namespace std;
    
    class OVModuleClassWrapperBase : public OVBase {
    public:
        virtual OVModule* newModule()
		{
			// this member function can't be abstract, or vector<OVModuleClassWrapperBase> wouldn't instantiate under VC++ 2005
			return 0;
		}
    };
    
    template<class T> class OVModuleClassWrapper : public OVModuleClassWrapperBase {
    public:
        virtual OVModule* newModule()
        {
            return new T;
        }        
    };
    
    // we encourage people to do the real initialization in initialize
    class OVModulePackage : OVBase {
    public:
        ~OVModulePackage()
        {
            vector<OVModuleClassWrapperBase*>::iterator iter = m_moduleVector.begin();
            for ( ; iter != m_moduleVector.end(); ++iter)
                delete *iter;
        }
        virtual bool initialize(OVPathInfo* , OVLoaderService* loaderService)
        {
            // in your derived class, add class wrappers to m_moduleVector
            return true;
        }
        
        virtual void finalize()
        {
        }
        
        virtual size_t numberOfModules(OVLoaderService*)
        {
            return m_moduleVector.size();
        }
        
        virtual OVModule* moduleAtIndex(size_t index, OVLoaderService*)
        {
            if (index > m_moduleVector.size()) return 0;
            return m_moduleVector[index]->newModule();
        }
    
    protected:
        vector<OVModuleClassWrapperBase*> m_moduleVector;
    };
};

#endif
