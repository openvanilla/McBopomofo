//
// OVEventHandlingContext.h
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

#ifndef OVEventHandlingContext_h
#define OVEventHandlingContext_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVBase.h>
    #include <OpenVanilla/OVCandidateService.h>
    #include <OpenVanilla/OVStringHelper.h>
    #include <OpenVanilla/OVTextBuffer.h>
    #include <OpenVanilla/OVKey.h>
    #include <OpenVanilla/OVLoaderService.h>
#else
    #include "OVBase.h"
    #include "OVCandidateService.h"
    #include "OVStringHelper.h"
    #include "OVTextBuffer.h"
    #include "OVKey.h"
    #include "OVLoaderService.h"
#endif

namespace OpenVanilla {
    using namespace std;
    
    class OVEventHandlingContext : public OVBase {
    public:
        virtual void startSession(OVLoaderService* loaderService)
        {
        }
        
        virtual void stopSession(OVLoaderService* loaderService)
        {
        }
        
        virtual void clear(OVLoaderService* loaderService)
        {
            stopSession(loaderService);
            startSession(loaderService);
        }
        
        virtual bool handleKey(OVKey* key, OVTextBuffer* readingText, OVTextBuffer* composingText, OVCandidateService* candidateService, OVLoaderService* loaderService)
        {
            return false;
        }
        
        virtual bool handleDirectText(const vector<string>& segments, OVTextBuffer* readingText, OVTextBuffer* composingText, OVCandidateService* candidateService, OVLoaderService* loaderService)
        {
            return handleDirectText(OVStringHelper::Join(segments), readingText, composingText, candidateService, loaderService);
        }
        
        virtual bool handleDirectText(const string&, OVTextBuffer* readingText, OVTextBuffer* composingText, OVCandidateService* candidateService, OVLoaderService* loaderService)
        {
            return false;
        }
        
        virtual void candidateCanceled(OVCandidateService* candidateService, OVTextBuffer* readingText, OVTextBuffer* composingText, OVLoaderService* loaderService)
        {
        }
        
        virtual bool candidateSelected(OVCandidateService* candidateService, const string& text, size_t index, OVTextBuffer* readingText, OVTextBuffer* composingText, OVLoaderService* loaderService)
        {
            return true;
        }
        
        virtual bool candidateNonPanelKeyReceived(OVCandidateService* candidateService, const OVKey* key, OVTextBuffer* readingText, OVTextBuffer* composingText, OVLoaderService* loaderService)
        {
            return false;
        }
        
        virtual const string filterText(const string& inputText, OVLoaderService* loaderService)
        {
            return inputText;
        }
    };
};

#endif
