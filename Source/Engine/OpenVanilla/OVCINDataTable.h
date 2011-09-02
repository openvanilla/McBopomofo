//
// OVCINDataTable.h
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

#ifndef OVCINDataTable_h
#define OVCINDataTable_h

#include <string>
#include <vector>
#include <cstdlib>
#include <cstring>
#include <iostream>

#include "OVFileHelper.h"
#include "OVUTF8Helper.h"
#include "OVWildcard.h"

#include <map>

namespace OpenVanilla {
    using namespace std;
    
    // CIN := (COMMENT | PROPERTY | KEYNAME | CHARDEF)*
    // EOL := \n|\r
    // COMMENT := ^#.*(EOL)
    // KEY := \w+
    // VALUE := \w([\w\s]*\w)*
    // PROPERTY: ^%(KEY)\s+(VALUE)(EOL)
    // KEYNAME :=
    //   ^%keyname\s+begin(EOL)
    //   ^(KEY)\s+(VALUE)(EOL)
    //   ^%keyname\s+end(EOL)
    // CHARDEF:
    //   ^%chardef\s+begin(EOL)
    //   ^(KEY)\s+(VALUE)(EOL)
    //   ^%chardef\s+end(EOL)   
    
    class OVCINDataTableParser;
    
    class OVFastKeyValuePairMap {        
    public:
        ~OVFastKeyValuePairMap()
        {
            free(m_data);
        }
        
        size_t size()
        {
            return m_index;
        }
        
        pair<string, string> keyValuePairAtIndex(size_t index)
        {
            if (index >= m_index)
                return pair<string, string>();
            
            KVPair* entry = m_data + index;
            return pair<string, string>(entry->key, entry->value);
        }
        
        vector<pair<string, string> > findPairsWithKey(const char* key)
        {
            return fetchValuesFromIndex(findFirstOccuranceOfKey(key), key);
        }
        
        vector<pair<string, string> > findPairsWithWildcard(const OVWildcard& pWildcard)
        {
            const OVWildcard* ptrWildcard = &pWildcard;            
        
            if (pWildcard.isCaseSensitive() != m_caseSensitive) {
                OVWildcard newWildcard(pWildcard.expression(), pWildcard.matchOneChar(), pWildcard.matchZeroOrMoreChar(), m_caseSensitive);
                ptrWildcard = &newWildcard;
            }
            
            const OVWildcard& wildcard = *ptrWildcard;
            
            string headString = wildcard.longestHeadMatchString();
            insensitivizeString(headString);
            size_t hSLength = headString.length();
            
            size_t start = findFirstOccuranceOfKey(headString.c_str(), true);
            vector<pair<string, string> > result;
            
            for (size_t index = start; index < m_index; index++) {
                KVPair* entry = m_data + index;
                string keyString = entry->key;
                
                // if no more head matchZeroOrMoreChar
                string keySubstr = keyString.substr(0, hSLength);
                insensitivizeString(keySubstr);
                if (keySubstr > headString)
                    break;
                
                if (wildcard.match(keyString)) 
                    result.push_back(pair<string, string>(keyString, entry->value));
            }
            
            return result;
        }
    protected:
        friend class OVCINDataTableParser;
        
        OVFastKeyValuePairMap(size_t initSize, size_t growSize, bool caseSensitive = false)
            : m_index(0)
            , m_size(initSize ? initSize : 1)
            , m_growSize(growSize)
            , m_caseSensitive(caseSensitive)
        {
            m_data = (KVPair*)calloc(1, sizeof(KVPair) * m_size);
        }
        
        
        void add(char* key, char* value) 
        {            
            KVPair* entry = m_data + m_index;        
            entry->key = key;
            entry->value = value;            
            
            m_index++;
            if (m_index == m_size)
                grow();
        }
                
        void sortAndFreeze()
        {
            m_size = m_index;
            
            if (m_caseSensitive)
                qsort(m_data, m_index, sizeof(KVPair), OVFastKeyValuePairMap::qsortCompareCaseSensitive);
            else
                qsort(m_data, m_index, sizeof(KVPair), OVFastKeyValuePairMap::qsortCompare);
        }
        
        void insensitivizeString(string& str)
        {
            if (m_caseSensitive)
                return;
                        
            for (string::iterator iter = str.begin() ; iter != str.end() ; ++iter)
                *iter = tolower(*iter);
        }
        
    protected:
        vector<pair<string, string> > fetchValuesFromIndex(size_t start, const char* key)
        {
            vector<pair<string, string> > result;
            for (size_t index = start ; index < m_index; index++) {
                KVPair* entry = m_data + index;
                
                if (compareString(entry->key, key) <= 0) {
                    result.push_back(pair<string, string>(entry->key, entry->value));
                }
                else {
                    break;
                }
            }
            
            return result;
        }
        
        size_t findFirstOccuranceOfKey(const char* key, bool closest = false)
        {
            if (!m_index)
                return m_index;
            
            size_t mid, low = 0, high = m_index - 1;
            
            while (low <= high) {
                mid = (low + high) / 2;
                
                char* entryKey = (m_data + mid)->key;
                int cmp = compareString(key, entryKey);
                
                if (!cmp) {
                    if (!mid)
                        return mid;
                    
                    size_t oneUp = mid - 1;
                    if (!compareString(key, (m_data + oneUp)->key))
                        high = oneUp;
                    else
                        return mid;
                }
                else {
                    if (closest) {
                        if (mid > 0) {
                            if (compareString(key, (m_data + mid - 1)->key) > 0 && compareString(key, entryKey) <= 0)
                                return mid;
                        }
                    }                
                    
                    if (cmp < 0) {
                        if (!mid) {
                            if (closest)
                                return 0;
                                
                            return m_index;
                        }
                            
                        high = mid - 1;
                    }
                    else {
                        if (low + 1 >= m_index)
                            return m_index;
                        
                        low = mid + 1;
                    }
                }
            }
            
            return m_index;
        }
    
        int compareString(const char* a, const char* b)
        {
            #ifndef WIN32
            return m_caseSensitive ? strcmp(a, b) : strcasecmp(a, b);
            #else
            return m_caseSensitive ? strcmp(a, b) : _stricmp(a, b);
            #endif
        }
    
        static int qsortCompare(const void* a, const void* b)
        {
            int cmp;            
            char* aa = ((const KVPair*)a)->key;
            char* bb = ((const KVPair*)b)->key;
            
            #ifndef WIN32
            if (!(cmp = strcasecmp(aa, bb)))
            #else
            if (!(cmp = _stricmp(aa, bb)))
            #endif
                return aa == bb ? 0 : (aa > bb ? 1 : -1);
            else
                return cmp;
        }

        static int qsortCompareCaseSensitive(const void* a, const void* b)
        {
            int cmp;            
            char* aa = ((const KVPair*)a)->key;
            char* bb = ((const KVPair*)b)->key;
            
            if (!(cmp = strcmp(aa, bb)))
                return aa == bb ? 0 : (aa > bb ? 1 : -1);
            else
                return cmp;
        }

        
        void grow()
        {
            size_t growSize = m_growSize ? m_growSize : m_size;
            KVPair* newData = (KVPair*)malloc(sizeof(KVPair) * (m_size + growSize));
            memcpy(newData, m_data, sizeof(KVPair) * m_size);
            memset(newData + m_size, 0, sizeof(KVPair) * growSize);

            KVPair* tmp = m_data;
            m_data = newData;
            free(tmp);

            m_size += growSize;
        }

    protected:
        struct KVPair {
            char* key;
            char* value;
        };
                
        bool m_caseSensitive;
        size_t m_growSize;
        size_t m_size;
        size_t m_index;
        KVPair* m_data;
    };
    
    class OVCINDataTable {
    public:
        ~OVCINDataTable()
        {
            if (m_propertyMap)
                delete m_propertyMap;
            if (m_keynameMap)
                delete m_keynameMap;
            if (m_chardefMap)
                delete m_chardefMap;                
            if (m_data)
                free (m_data);            
        }
        
        string findProperty(const string& key)
        {
            vector<pair<string, string> > result = m_propertyMap->findPairsWithKey(key.c_str());
            if (result.size()) return result[0].second;
            return string();
        }
        
        string findKeyname(const string& key)
        {
            vector<pair<string, string> > result = m_keynameMap->findPairsWithKey(key.c_str());
            if (result.size()) return result[0].second;
            return string();            
        }
        
        vector<string> findChardef(const string& key)
        {
            vector<pair<string, string> > ret = m_chardefMap->findPairsWithKey(key.c_str());
            vector<string> result;
            vector<pair<string, string> >::iterator iter= ret.begin();
            
            for ( ; iter != ret.end(); iter++)
                result.push_back((*iter).second);
                
            return result;
        }
        
        vector<pair<string, string> > findChardefWithWildcard(const OVWildcard& wildcard)
        {
            return m_chardefMap->findPairsWithWildcard(wildcard);
        }
        
        OVFastKeyValuePairMap* propertyMap()
        {
            return m_propertyMap;
        }
        
        OVFastKeyValuePairMap* keynameMap()
        {
            return m_keynameMap;
        }
        
        OVFastKeyValuePairMap* chardefMap()
        {
            return m_chardefMap;
        }
        
    protected:
        friend class OVCINDataTableParser;
        OVCINDataTable(char* data, OVFastKeyValuePairMap* propertyMap, OVFastKeyValuePairMap* keynameMap, OVFastKeyValuePairMap* chardefMap)
            : m_data(data)
            , m_propertyMap(propertyMap)
            , m_keynameMap(keynameMap)
            , m_chardefMap(chardefMap)
        {
        }        
     
        char* m_data;
        OVFastKeyValuePairMap* m_propertyMap;
        OVFastKeyValuePairMap* m_keynameMap;
        OVFastKeyValuePairMap* m_chardefMap;
    };
    
    
    
    class OVCINDataTableParser {
    public:
        enum {
            NoFileError,
            SeekError,
            EmptyFileError,
            MemoryAllocationError,
            ReadError,
            NoDataError = EmptyFileError
        };
        
        OVCINDataTableParser()
            : m_data(0)
            , m_lastError(0)
        {
        }
        
        ~OVCINDataTableParser()
        {
            if (m_data)
                free(m_data);
        }
        
        int lastError()
        {
            return m_lastError;
        }

        OVCINDataTable* CINDataTableFromFileName(const string& filename, bool caseSensitive = false)
        {
            if (m_data) {
                free(m_data);
                m_data = 0;
            }
            
            FILE* f = OVFileHelper::OpenStream(filename);
            if (!f) {
                m_lastError = NoFileError;
                return 0;
            }

            OVCINDataTable* table;
            OVCINDataTableParser parser;
            table = parser.CINDataTableFromFileStream(f, caseSensitive);
            fclose(f);
            return table;
        }
        
        OVCINDataTable* CINDataTableFromString(const char* string, bool caseSensitive = false)
        {
            if (m_data) {
                free(m_data);
                m_data = 0;
            }
            
            size_t len = strlen(string);
            if (!len) {
                m_lastError = NoDataError;
                return 0;                
            }
            
            m_data = (char*)calloc(1, len + 1);
            if (!m_data) {
                m_lastError = MemoryAllocationError;
                return 0;
            }
            
            memcpy(m_data, string, len);
                        
            return CINDataTableFromRetainedData(caseSensitive);
        }

        
        OVCINDataTable* CINDataTableFromFileStream(FILE* stream, bool caseSensitive = false)
        {
            if (m_data) {
                free(m_data);
                m_data = 0;
            }
            
            if (!stream) {
                m_lastError = NoFileError;
                return 0;
            }
                
            if (fseek(stream, 0, SEEK_END) == -1) {
                m_lastError = SeekError;
                return 0;
            }
            
            size_t size;
            if (!(size = ftell(stream))) {
                m_lastError = EmptyFileError;
                return 0;
            }
            
            if (fseek(stream, 0, SEEK_SET) == -1) {
                m_lastError = SeekError;
                return 0;
            }
            
            m_data = (char*)calloc(1, size + 1);
            if (!m_data) {
                m_lastError = MemoryAllocationError;
                return 0;
            }
            
            if (fread(m_data, 1, size, stream) != size) {
                m_lastError = ReadError;
                return 0;
            }
                        
            return CINDataTableFromRetainedData(caseSensitive);
        }
        
    protected:
        OVCINDataTable* CINDataTableFromRetainedData(bool caseSensitive)
        {
            OVFastKeyValuePairMap* propertyMap = new OVFastKeyValuePairMap(16, 0, caseSensitive);
            if (!propertyMap) {
                free(m_data);
                m_lastError = MemoryAllocationError;
                return 0;
            }
            
            OVFastKeyValuePairMap* keynameMap = new OVFastKeyValuePairMap(64, 0, caseSensitive);
            if (!keynameMap) {
                free(m_data);
                delete propertyMap;
                m_lastError = MemoryAllocationError;
                return 0;
            }
            
            OVFastKeyValuePairMap* chardefMap = new OVFastKeyValuePairMap(1024, 0, caseSensitive);
            if (!chardefMap) {
                free(m_data);
                delete propertyMap;
                delete keynameMap;
                m_lastError = MemoryAllocationError;
                return 0;
            }
            
            m_scanner = m_data;
            
            char first;
            int blockMode = 0;
            
            while (first = *m_scanner) {
                if (blockMode) {
                    if (first == '\r' || first == '\n') {
                        m_scanner++;
                        continue;
                    }
                    
                    char* key = m_scanner;
                    char* value = const_cast<char*>("");
                    char endingChar = skipToSpaceCharOrLineEndAndMarkAndForward();

                    if (endingChar == '\r' || endingChar == '\n') {
                        ;
                    }
                    else {
                        endingChar = skipUntilNonSpaceChar();
                        if (endingChar == '\r' || endingChar == '\n') {
                            ;
                        }
                        else {
                            value = m_scanner;
                            skipToLineEndAndMarkAndForwardWithoutTrailingSpace();
                        }
                    }

                    if (blockMode == 1) {                        
                        if (!strcmp(key, "%keyname") && !strcmp(value, "end")) {
                            blockMode = 0;
                        }
                        else {
                            if (!caseSensitive)
                                makeLowerCase(key);
                        
                            keynameMap->add(key, value);
                        }
                    }
                    else if (blockMode == 2) {
                        if (!strcmp(key, "%chardef") && !strcmp(value, "end")) {
                            blockMode = 0;
                        }

                        else {
                            if (!caseSensitive)
                                makeLowerCase(key);

                            chardefMap->add(key, value);
                        }
                    }
                        
                    continue;
                }
                
                
                if (first == '#') {
                    skipUntilNextLine();
                    continue;
                }
                
                if (first == '%') {
                    m_scanner++;

                    char* key;
                    char* value = const_cast<char*>("");
                    
                    if (*(key = m_scanner)) {
                        char endingChar = skipToSpaceCharOrLineEndAndMarkAndForward();

                        if (endingChar == '\r' || endingChar == '\n') {
                            ;
                        }
                        else {
                            endingChar = skipUntilNonSpaceChar();
                            if (endingChar == '\r' || endingChar == '\n') {
                                ;
                            }
                            else {
                                value = m_scanner;
                                skipToLineEndAndMarkAndForwardWithoutTrailingSpace();
                            }
                        }
                        
                        if (!strcmp(key, "keyname") && !strcmp(value, "begin")) {
                            blockMode = 1;
                        }
                        else if (!strcmp(key, "chardef") && !strcmp(value, "begin")) {
                            blockMode = 2;
                        }
                        else {
                            propertyMap->add(key, value);
                        }
                    }
                    
                    continue;
                }
                
                m_scanner++;
            }
            
            propertyMap->sortAndFreeze();
            keynameMap->sortAndFreeze();
            chardefMap->sortAndFreeze();
            
            OVCINDataTable* table = new OVCINDataTable(m_data, propertyMap, keynameMap, chardefMap);
            
            if (!table) {
                free(m_data);
                delete propertyMap;
                delete keynameMap;
                delete chardefMap;
                m_lastError = MemoryAllocationError;
                return 0;
            }
            else {
                m_data = 0;
            }
            
            return table;
        }

        void skipUntilNextLine()
        {
            skipUntilEitherCRLF();
            skipUntilNeitherCRLF();
        }
        
        void skipUntilEitherCRLF()
        {
            char nextChar;
            while (nextChar = *m_scanner) {
                if (nextChar == '\r' || nextChar == '\n') break;
                m_scanner++;
            }
        }
        
        void skipUntilNeitherCRLF()
        {
            char nextChar;
            while (nextChar = *m_scanner) {
                if (!(nextChar == '\r' || nextChar == '\n')) break;
                m_scanner++;
            }
        }
        
        void skipToLineEndAndMarkAndForwardWithoutTrailingSpace()
        {
            char nextChar;
            while (nextChar = *m_scanner) {
                if (nextChar == ' ' || nextChar == '\t') {
                    char* begin = m_scanner;
                    
                    m_scanner++;                    
                    while (nextChar = *m_scanner) {
                        if (!(nextChar == ' ' || nextChar == '\t')) break;
                        m_scanner++;
                    }
                        
                    if (nextChar == '\n' || nextChar == '\r') {
                        *begin = 0;
                        m_scanner++;
                        return;
                    }
                    else {
                        m_scanner++;
                        continue;
                    }
                }                
                
                if (nextChar == '\n' || nextChar == '\r') {
                    *m_scanner = 0;
                    m_scanner++;
                    return;
                }
                
                m_scanner++;
            }            
        }
        
        char skipToSpaceCharOrLineEndAndMarkAndForward()
        {
            char nextChar;
            while (nextChar = *m_scanner) {
                if (nextChar == ' ' || nextChar == '\t' || nextChar == '\n' || nextChar == '\r') {
                    *m_scanner = 0;
                    m_scanner++;
                    return nextChar;
                }
                
                m_scanner++;
            }

			return 0;
        }
        
        char skipUntilNonSpaceChar()
        {
            char nextChar;
            while (nextChar = *m_scanner) {
                if (!(nextChar == ' ' || nextChar == '\t'))
                    return nextChar;
                    
                m_scanner++;
            }

			return 0;
        }
        
        void makeLowerCase(char* ptr)
        {
            while (*ptr) {
                *ptr = tolower(*ptr);
                ptr++;
            }
        }
        
    protected:
        char* m_data;
        char* m_scanner;
        int m_lastError;
        
    public:
        static const map<string, string> QuickParseProperty(const string& filename)
        {
            map<string, string> properties;
            FILE* stream = OVFileHelper::OpenStream(filename);
            
            if (!stream)
                return properties;
            
            while (!feof(stream)) {
                char buffer[256];
                fgets(buffer, sizeof(buffer) - 1, stream);
                
                if (!*buffer)
                    continue;
            
                if (*buffer == '#')
                    continue;
                    
                pair<string, string> pv = SplitPropertyString(buffer + 1);
                if (pv.first == "keyname")
                    break;
                    
                properties[pv.first] = pv.second;
            }
            
            fclose(stream);
            return properties;
        }
        
        static pair<string, string> SplitPropertyString(const char* str)
        {
            const char* scanner = str;
            while (*scanner) {
                if (*scanner == ' ' || *scanner == '\t' || *scanner == '\r' || *scanner == '\n')
                    break;
                scanner++;
            }
            
            string property = string(str, (size_t)(scanner - str));
            
            while (*scanner) {
                if (*scanner != ' ' && *scanner != '\t')
                    break;
                scanner++;
            }
            
            const char* begin = scanner;
            while (*scanner) {
                if (*scanner == '\r' || *scanner == '\n')
                    break;
                scanner++;
            }
            
            string value = string(begin, (size_t)(scanner - begin));
            return pair<string, string>(property, value);
        }
    };
};

#endif
