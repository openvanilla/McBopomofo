//
// OVStringHelper.h
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

#ifndef OVStringHelper_h
#define OVStringHelper_h

#include <string>
#include <sstream>
#include <vector>

namespace OpenVanilla {
    using namespace std;

    class OVStringHelper {
    public:
        static const vector<string> SplitBySpacesOrTabsWithDoubleQuoteSupport(const string& text)
        {
            vector<string> result;            
            size_t index = 0, last = 0, length = text.length();
            while (index < length) {
				if (text[index] == '\"') {
					index++;
					string tmp;
					while (index < length) {
						if (text[index] == '\"') {
							index++;
							break;
						}
						
						if (text[index] == '\\' && index + 1 < length) {
							index++;
							char c = text[index];
							switch (c) {
							case 'r':
								tmp += '\r';
								break;
							case 'n':
								tmp += '\n';
								break;
							case '\"':
								tmp += '\"';
								break;
							case '\\':
								tmp += '\\';
								break;
							}
						}
						else {
							tmp += text[index];
						}
						
						index++;
					}
					result.push_back(tmp);
				}
	
                if (text[index] != ' ' && text[index] != '\t') {                    
                    last = index;
                    while (index < length) {
                        if (text[index] == ' ' || text[index] == '\t') {
                            if (index - last)
                                result.push_back(text.substr(last, index - last));
                            break;
                        }
                        index++;
                    }
                    
                    if (index == length && index - last)
                        result.push_back(text.substr(last, index - last));
                }
                
                index++;
            }
            
            return result;
        }
	
        static const vector<string> SplitBySpacesOrTabs(const string& text)
        {
            vector<string> result;            
            size_t index = 0, last = 0, length = text.length();
            while (index < length) {
                if (text[index] != ' ' && text[index] != '\t') {                    
                    last = index;
                    while (index < length) {
                        if (text[index] == ' ' || text[index] == '\t') {
                            if (index - last)
                                result.push_back(text.substr(last, index - last));
                            break;
                        }
                        index++;
                    }
                    
                    if (index == length && index - last)
                        result.push_back(text.substr(last, index - last));
                }
                
                index++;
            }
            
            return result;
        }
        
        static const vector<string> Split(const string& text, char c)
        {
            vector<std::string> result;
            size_t index = 0, last = 0, length = text.length();
            while (index < length) {
                while (index < length) {
                    if (text[index] == c) {
                        result.push_back(text.substr(last, index - last));
                        last = index + 1;
                        break;
                    }
                    index++;            
                }

                index++;
            }

            if (last <= index) {
                result.push_back(text.substr(last, index - last));           
            }

            return result;
        }
        
        // named after Cocoa's NSString -stringByReplacingOccurrencesOfString:WithString:, horrible
        static const string StringByReplacingOccurrencesOfStringWithString(const string& source, const string& substr, const string& replacement)
        {
            if (!substr.length())
                return source;
            
            size_t pos;
            if ((pos = source.find(substr)) >= source.length())
                return source;

            return source.substr(0, pos) + replacement + StringByReplacingOccurrencesOfStringWithString(source.substr(pos + substr.length()), substr, replacement);
        }

        static const string Join(const vector<string>& vec)
        {
            string result;
            for (vector<string>::const_iterator iter = vec.begin(); iter != vec.end() ; ++iter)
                result += *iter;
                
            return result;
        }

        static const string Join(const vector<string>& vec, const string& separator)
        {
            return Join(vec.begin(), vec.end(), separator);
        }

        static const string Join(const vector<string>& vec, size_t from, size_t size, const string& separator)
        {
            return Join(vec.begin() + from, vec.begin() + from + size, separator);
        }

        static const string Join(vector<string>::const_iterator begin, vector<string>::const_iterator end, const string& separator)
        {
            string result;
            for (vector<string>::const_iterator iter = begin ; iter != end ; ) {
                result += *iter;
                if (++iter != end)
                    result += separator;
            }
            return result;
        }
        
        static const string PercentEncode(const string& text)
        {
            stringstream sst;
            sst << hex;

            for (string::const_iterator i = text.begin() ; i != text.end() ; ++i) {
                if ((*i >= '0' && *i <= '9') || (*i >= 'A' && *i <= 'Z') || (*i >= 'a' && *i <= 'z') || *i == '-' || *i == '_' || *i == '.' || *i == '~') {
                    sst << (char)*i;
        		}
                else {
                    sst << '%';
                    sst.width(2);
                    sst.fill('0');
                    unsigned char c = *i;
                    sst << (unsigned int)c;
                }
            }

            return sst.str();            
        }
    };
}

#endif
