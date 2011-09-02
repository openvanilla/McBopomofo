//
// OVTextBuffer.h
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

#ifndef OVTextBuffer_h
#define OVTextBuffer_h

#if defined(__APPLE__)
    #include <OpenVanilla/OVBase.h>
#else
    #include "OVBase.h"
#endif

namespace OpenVanilla {
    using namespace std;
    
    // Terminologies:
    // * Text buffer = a generic term
    // * Composing text = composing buffer = composition buffer
    //   In Windows speak, "composition buffer" doesn't contain reading
    //   (Reading is a separate concept in Windows)
    //   In Mac speak, "composing buffer" == composing text + reading text
    // * Reading text = currently in-wait-state radicals
    // * Pre-edit, pre-edit area or pre-edit buffer (X11 speak) = composing text + reading
    //   Mac's composing buffer is actually pre-edit in this sense
    
    
    class OVTextBuffer : public OVBase {
    public:
        
        virtual void clear() = 0;
        virtual void setText(const string& text) = 0;
        virtual void appendText(const string& text, bool moveCursor = true) = 0;
        
        // when the text buffer is committed, the buffer itself, along with settings like cursor, and tooltip (for both composing text and reading text), highlight, word segments, and suggested display style (for reading text) are cleared; the combined committed string will be available at composedCommittedText()
        virtual void commit() = 0;
        virtual void commitAsTextSegment() = 0;
        virtual void commit(const string& text) = 0;
        virtual void commitAsTextSegment(const string& text) = 0;

        virtual void updateDisplay() = 0;
        virtual bool isEmpty() const = 0;
        virtual size_t codePointCount() const = 0;
        virtual const string codePointAt(size_t index) const = 0;
        virtual const string composedText() const = 0;
        virtual const string composedCommittedText() const = 0;
        virtual const vector<string> composedCommittedTextSegments() const = 0;        

        // Composing text (composing buffer, composition buffer)-only members
    public:        
        typedef pair<size_t, size_t> RangePair;

        // composing buffer should support these four, but reading buffer doesn't need to (anyway it's meaningless)
        virtual void setCursorPosition(size_t position) = 0;
        virtual size_t cursorPosition() const = 0;
        virtual void showToolTip(const string& text) = 0;
        virtual void clearToolTip() = 0;

        // implementation details: composing buffer might support this, but reading buffer doesn't
        virtual void setHighlightMark(const RangePair& range) = 0;
        
        // word segments: on Windows, this is an independent (though application-dependent) feature, on Mac OS X, word segments cannot overlap with the highlight mark, and also, when the highlight mark is on, the cursor is off
        virtual void setWordSegments(const vector<RangePair>& segments) = 0;
        
        // Reading text only members
    public:
        enum ReadingTextStyle {
            Horizontal = 0,
            Vertical = 1
        };
        
        // this is only for the reading buffer, and is not a required implementation
        virtual void setSuggestedReadingTextStyle(ReadingTextStyle style) = 0;
        virtual ReadingTextStyle defaultReadingTextStyle() const = 0;
    };
};

#endif

