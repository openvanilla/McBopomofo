//
// OVDateTimeHelper.h
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

#ifndef OVDateTimeHelper_h
#define OVDateTimeHelper_h

#include <ctime>
#include <sstream>
#include <string>

namespace OpenVanilla {
    using namespace std;
    
    class OVDateTimeHelper
    {
    public:
        static time_t GetTimeIntervalSince1970()
        {
            return time(NULL);                        
        }
        
        static time_t GetTimeIntervalSince1970FromString(const string& s)
        {
            stringstream sst;
            sst << s;
            time_t t;
            sst >> t;
            return t;
        }
        
        static const string GetTimeIntervalSince1970AsString()
        {
            stringstream sst;
            sst << time(NULL);
            return sst.str();
        }
        
        static time_t GetTimeIntervalSince1970AtBeginningOfTodayLocalTime()
        {
            time_t t = time(NULL);

			#ifdef WIN32
			struct tm tdata;
			struct tm* td = &tdata;
            if (localtime_s(td, &t))
				return 0;
			#else
            struct tm* td;
			td = localtime(&t);
			#endif

            td->tm_hour = 0;
            td->tm_min = 0;
            td->tm_sec = 0;
            
            return mktime(td);
        }
        
        static const string LocalTimeString()
        {
            time_t t = time(NULL);

			#ifdef WIN32
			struct tm tdata;
			struct tm* td = &tdata;
            if (localtime_s(td, &t))
				return string();
			#else
            struct tm* td;
			td = localtime(&t);
			#endif

            ostringstream sstr;
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_hour << ":";
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_min << ":";
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_sec;
            return sstr.str();
        }
        
        static const string LocalDateTimeString()
        {
            time_t t = time(NULL);

			#ifdef WIN32
			struct tm tdata;
			struct tm* td = &tdata;
            if (localtime_s(td, &t))
				return string();
			#else
            struct tm* td;
			td = localtime(&t);
			#endif
            
            ostringstream sstr;
            sstr.width(4);
            sstr << td->tm_year + 1900 << "-";
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_mon + 1 << "-";
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_mday << " ";
            
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_hour << ":";
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_min << ":";
            sstr.width(2);
            sstr.fill('0');
            sstr << td->tm_sec;
            return sstr.str();
        }
    };
    
};

#endif
