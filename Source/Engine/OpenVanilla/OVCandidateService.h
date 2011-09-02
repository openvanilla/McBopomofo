//
// OVCandidateService.h
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

#ifndef OVCandidateService_h
#define OVCandidateService_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVBase.h>
    #include <OpenVanilla/OVKey.h>
    #include <OpenVanilla/OVLoaderService.h>
#else
    #include "OVBase.h"
    #include "OVKey.h"
    #include "OVLoaderService.h"
#endif

namespace OpenVanilla {
    using namespace std;

    class OVCandidateList : public OVBase {
    public:
        virtual void clear() = 0;
        virtual size_t size() const = 0;
        virtual string candidateAtIndex(size_t index) const = 0;
        virtual void setCandidate(size_t index, const string& candidate) = 0;
        virtual void setCandidates(const vector<string>& candidates) = 0;
        virtual void addCandidate(const string& candidate) = 0;
        virtual void addCandidates(const vector<string>& candidates) = 0;
    };
    
    class OVCandidatePanel;
    class OVOneDimensionalCandidatePanel;
    // class OVTwoDimensionalCandidatePanel;
    class OVFreeContentPanel;
    class OVPlainTextCandidatePanel;
    class OVHTMLCandidatePanel;

    class OVCandidatePanel : public OVBase {
    public:
        virtual bool isOneDimensionalPanel() const
        {
            return false;
        }
        
        virtual bool isTwoDimensionalPanel() const
        {
            return false;            
        }
        
        virtual bool isPlainTextPanelPanel() const
        {
            return false;
        }
        
        virtual bool isHTMLPanel() const
        {
            return false;
        }
        
        virtual void hide() = 0;
        virtual void show() = 0;
        virtual void updateDisplay() = 0;
        virtual bool isVisible() = 0;        

		virtual void setPrompt(const string& prompt) = 0;
		virtual string prompt() = 0;

        virtual bool yieldToCandidateEventHandler() = 0;
        virtual void cancelEventHandler() = 0;
        
        virtual void reset() = 0;
    };

    class OVOneDimensionalCandidatePanel : public OVCandidatePanel {
    public:
        virtual bool isOneDimensionalPanel() const
        {
            return true;
        }
        
        virtual bool isHorizontal() const = 0;
        virtual bool isVertical() const = 0;
        
        virtual OVCandidateList* candidateList() = 0;
        
        virtual size_t candidatesPerPage() const = 0;
        virtual void setCandidatesPerPage(size_t number) = 0;
        virtual size_t pageCount() const = 0;
        virtual size_t currentPage() const = 0;
        virtual size_t currentPageCandidateCount() const = 0;
        virtual bool allowsPageWrapping() const = 0;
        virtual void setAllowsPageWrapping(bool allowsPageWrapping) = 0;

        virtual size_t currentHightlightIndex() const = 0;
        virtual void setHighlightIndex(size_t index) = 0;
        virtual size_t currentHightlightIndexInCandidateList() const = 0;

        virtual size_t goToNextPage() = 0;
        virtual size_t goToPreviousPage() = 0;
        virtual size_t goToPage(size_t page) = 0;

        virtual const OVKey candidateKeyAtIndex(size_t index) = 0;
        virtual void setCandidateKeys(const string& asciiKeys, OVLoaderService* loaderService)
        {
            OVKeyVector keys;
            for (size_t index = 0; index < asciiKeys.length(); index++) {
                keys.push_back(loaderService->makeOVKey(asciiKeys[index]));
            }
            
            setCandidateKeys(keys);
            setCandidatesPerPage(asciiKeys.length());
        }
        
        virtual void setCandidateKeys(const OVKeyVector& keys) = 0;        
        virtual void setNextPageKeys(const OVKeyVector& keys) = 0;
        virtual void setPreviousPageKeys(const OVKeyVector& keys) = 0;
        virtual void setNextCandidateKeys(const OVKeyVector& keys) = 0;
        virtual void setPreviousCandidateKeys(const OVKeyVector& keys) = 0;
        virtual void setCancelKeys(const OVKeyVector& keys) = 0;
        virtual void setChooseHighlightedCandidateKeys(const OVKeyVector& keys) = 0;
        
        virtual const OVKeyVector defaultCandidateKeys() const = 0;
        virtual const OVKeyVector defaultNextPageKeys() const = 0;
        virtual const OVKeyVector defaultNextCandidateKeys() const = 0;
        virtual const OVKeyVector defaultPreviousPageKeys() const = 0;
        virtual const OVKeyVector defaultPreviousCandidateKeys() const = 0;
        virtual const OVKeyVector defaultCancelKeys() const = 0;
        virtual const OVKeyVector defaultChooseHighlightedCandidateKeys() const = 0;
    };

    class OVFreeContentStorage : public OVBase {
    public:
        virtual void clear() = 0;
        virtual void setContent(const string& content) = 0;
        virtual void appendContent(const string& content) = 0;
    };

    class OVPlainTextCandidatePanel : public OVCandidatePanel {
    public:
        virtual bool isPlainTextPanelPanel()
        {
            return true;
        }
        
        virtual OVFreeContentStorage* textStorage() = 0;
    };

    class OVHTMLCandidatePanel : public OVCandidatePanel {
    public:
        virtual OVFreeContentStorage* HTMLSourceStorage() = 0;
    };

    class OVCandidateService : public OVBase {
    public:
        virtual OVOneDimensionalCandidatePanel* useHorizontalCandidatePanel()
        {
            return 0;
        }
        
        virtual OVOneDimensionalCandidatePanel* useVerticalCandidatePanel()
        {
            return 0;
        }
        
        virtual OVOneDimensionalCandidatePanel* useOneDimensionalCandidatePanel()
        {
            return useVerticalCandidatePanel();
        }
        
        // virtual OVTwoDimensionalCandidatePanel* twoDimensionalCandidatePanel();
        
        virtual OVPlainTextCandidatePanel* usePlainTextCandidatePanel()
        {
            return 0;
        }
        
        virtual OVHTMLCandidatePanel* useHTMLCandidatePanel()
        {
            return 0;
        }
    };    
};

#endif
