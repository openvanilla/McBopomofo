//
// OVBenchmark.h
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

#ifndef OVBenchmark_h
#define OVBenchmark_h

#include <ctime>

namespace OpenVanilla {
    using namespace std;

    class OVBenchmark
    {
    public:
        OVBenchmark()
            : m_used(false)
            , m_running(false)
            , m_start(0)
            , m_elapsedTicks(0)
            , m_elapsedSeconds(0.0)
        {            
        }
        
    	void start()
    	{
            m_used = true;
            m_running = true;
    		m_elapsedSeconds = 0.0;
    		m_elapsedTicks = 0;
    		m_start = clock();
    	}

    	void stop()
    	{
            if (m_running) {
                update();
                m_running = false;            
    		}
    	}

    	clock_t elapsedTicks() 
    	{ 
    	    if (!m_used)
                return 0;
            
    	    if (m_running)
                update();
    	    
    	    return m_elapsedTicks;
    	}
    	
    	double elapsedSeconds()
    	{
    	    if (!m_used)
                return 0;
                
    	    if (m_running)
                update();
                
    	    return m_elapsedSeconds;
    	}

    protected:
        void update()
        {
		    m_elapsedTicks = clock() - m_start;
		    m_elapsedSeconds = static_cast<double>(m_elapsedTicks) / CLOCKS_PER_SEC;                
        }
        
        bool m_used;
        bool m_running;
    	clock_t m_start;
    	clock_t m_elapsedTicks;
    	double m_elapsedSeconds;
    };
};

#endif
