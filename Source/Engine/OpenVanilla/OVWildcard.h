//
// OVWildcard.h
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

#ifndef OVWildcard_h
#define OVWildcard_h

#include <iostream>
#include <string>
#include <vector>
#include <cctype>

namespace OpenVanilla {
    using namespace std;

	class OVWildcard {
	public:
		OVWildcard(const string& expression, char matchOneChar = '?', char matchZeroOrMoreChar = '*', bool matchEndOfLine = true, bool caseSensitive = false)
		    : m_caseSensitive(caseSensitive)
		    , m_expression(expression)
		    , m_matchEndOfLine(matchEndOfLine)
		    , m_matchOneChar(matchOneChar)
		    , m_matchZeroOrMoreChar(matchZeroOrMoreChar)
		{
            size_t index;
            for (index = 0; index < expression.length(); index++) {
                if (expression[index] == matchOneChar || expression[index] == matchZeroOrMoreChar) break;
            }
            
            m_longestHeadMatchString = expression.substr(0, index);
            
			for (string::size_type i = 0; i < expression.length(); i++) {
				char c = expression[i];
				if (c == matchOneChar) {
					m_states.push_back(State(AnyOne, 0));
				}
				else if (c == matchZeroOrMoreChar) {
					char nextChar = 0;
					string::size_type j;
					for (j = i + 1; j < expression.length(); j++) {
						char k = expression[j];
						if (k != matchZeroOrMoreChar) {
							if (k == matchOneChar) k = -1;
						
							nextChar = k;
							break;
						}		
					}

					i = j;
					m_states.push_back(State(AnyUntil, nextChar));					
				}
				else {
					m_states.push_back(State(Exact, c));
				}
			}
		}

		bool match(const string& target, size_t fromState = 0) const
		{
			string::size_type i = 0, slength = target.length();
			vector<State>::size_type j, vlength = m_states.size();
			
			for (j = fromState; j < vlength; j++) {
				State state = m_states[j];
				Directive d = state.first;
				int k = state.second;

				if (i >= slength) {
					if (d == AnyUntil && !k) return true;
					return false;
				}
				
				switch (d) {
					case Exact:
						if (!equalChars(target[i], k)) return false;
						i++;
						break;

					case AnyOne:
						i++;
						break;

					case AnyUntil:
						if (k == -1) {
							// means *?, equals ?, so just advance one character
							i++;
						}
						else if (k == 0) {
							// until end, always true
							return true;
						}
						else {
							bool found = false;
                            string::size_type backIndex;
                            
                            for (backIndex = slength - 1; backIndex >= i; backIndex--) {
								if (equalChars(target[backIndex], k)) {
                                    string substring = target.substr(backIndex + 1, slength - (backIndex + 1));
                                    
                                    if (match(substring, j + 1)) {
                                        found = true;
                                        i = backIndex + 1;
                                        break;
                                    }
                                }
                                
                                if (!backIndex)
                                    break;
                            }
                            
                            if (!found)
                                return false;
						}						
						
						break;
				}				
			}
			
			if (m_matchEndOfLine && i != slength)
			    return false;

			return true;
		}
		
		const string longestHeadMatchString() const
		{
            return m_longestHeadMatchString;
		}
		
		const string expression() const
		{
            return m_expression;
		}
		
		bool isCaseSensitive() const
		{
            return m_caseSensitive;
		}
		
		char matchOneChar() const
		{
            return m_matchOneChar;
		}
		
		char matchZeroOrMoreChar() const
		{
            return m_matchZeroOrMoreChar;
		}
		
		friend ostream& operator<<(ostream& stream, const OVWildcard& wildcard);
		
	protected:
		enum Directive {
			Exact,
			AnyOne,
			AnyUntil
		};
		
		typedef pair<Directive, int> State;
		
		bool equalChars(char a, char b) const
		{
		    if (m_caseSensitive)
                return a == b;
            else
                return tolower(a) == tolower(b);
		}
	    
        bool m_caseSensitive;
		bool m_matchEndOfLine;
        char m_matchOneChar;
        char m_matchZeroOrMoreChar;
		vector<State> m_states;
		
        string m_expression;
        string m_longestHeadMatchString;
        
    public:
        static const bool Match(const string& text, const string& expression, char matchOneChar = '?', char matchZeroOrMoreChar = '*', bool matchEndOfLine = true, bool caseSensitive = false)
        {
            OVWildcard exp(expression, matchOneChar, matchZeroOrMoreChar, matchEndOfLine, caseSensitive);            
            return exp.match(text);
        }
        
        static const vector<OVWildcard> WildcardsFromStrings(const vector<string>& expressions, char matchOneChar = '?', char matchZeroOrMoreChar = '*', bool matchEndOfLine = true, bool caseSensitive = false)
        {
            vector<OVWildcard> result;
            vector<string>::const_iterator iter = expressions.begin();
            for ( ; iter != expressions.end(); iter++)
                result.push_back(OVWildcard(*iter, matchOneChar, matchZeroOrMoreChar, matchEndOfLine, caseSensitive));
            
            return result;
        }
        
        static bool MultiWildcardMatchAny(const string& target, const vector<string>& expressions, char matchOneChar = '?', char matchZeroOrMoreChar = '*', bool matchEndOfLine = true, bool caseSensitive = false)
        {
            return MultiWildcardMatchAny(target, WildcardsFromStrings(expressions, matchOneChar, matchZeroOrMoreChar, matchEndOfLine, caseSensitive));
        }
        
        static bool MultiWildcardMatchAny(const string& target, const vector<OVWildcard>& expressions)
        {
            vector<OVWildcard>::const_iterator iter = expressions.begin();
            for ( ; iter != expressions.end(); iter++) {
                if ((*iter).match(target))
                    return true;
            }
            
            return false;
        }
	};

	inline ostream& operator<<(ostream& stream, const OVWildcard& wildcard)
	{
		vector<OVWildcard::State>::size_type i, size = wildcard.m_states.size();
		for (i = 0; i < size; i++) {
			const OVWildcard::State& state = wildcard.m_states[i];
			stream << "State " << i << ": " << state.first << ", " << state.second << endl;
		}
		
		return stream;
	}
}

#endif
