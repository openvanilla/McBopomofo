//
// OVFileHelper.h
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

#ifndef OVFileHelper_h
#define OVFileHelper_h

#if defined(__APPLE__)
    #include <dirent.h>
    #include <stdio.h>
#else
	#include <windows.h>
    #include <shlobj.h>
	#include <stdio.h>
#endif

#include <sys/stat.h>

#include <fstream>
#include <algorithm>
#include <vector>
#include "OVWildcard.h"
#include "OVUTF8Helper.h"

namespace OpenVanilla {
    using namespace std;

    class OVFileHelper {
    public:
        static FILE* OpenStream(const string& filename, const string& mode = "rb")
        {
            #ifndef WIN32
            return fopen(filename.c_str(), mode.c_str());
            #else
        	FILE* stream = NULL;
        	errno_t err = _wfopen_s(&stream, OVUTF16::FromUTF8(filename).c_str(), OVUTF16::FromUTF8(mode).c_str());
            return err ? 0 : stream;
            #endif
        }
        
        static void OpenOFStream(ofstream& stream, const string& filename, ios_base::openmode openMode)
        {
            #ifndef WIN32
            stream.open(filename.c_str(), openMode);
            #else
            stream.open(OVUTF16::FromUTF8(filename).c_str(), openMode);
            #endif
        }

        static void OpenIFStream(ifstream& stream, const string& filename, ios_base::openmode openMode)
        {
            #ifndef WIN32
            stream.open(filename.c_str(), openMode);
            #else
            stream.open(OVUTF16::FromUTF8(filename).c_str(), openMode);
            #endif
        }
        
        // use free(), not delete[], to free the block allocated
        static pair<char*, size_t> SlurpFile(const string& filename, bool addOneByteOfStringTerminationPadding = false)
        {
            FILE* stream = OpenStream(filename);
            char* buf = 0;
            size_t size = 0;
            if (stream) {
                if (!fseek(stream, 0, SEEK_END)) {
                    long lsize = ftell(stream);
                    if (lsize) {
                        size = (size_t)lsize;
                        if (!fseek(stream, 0, SEEK_SET)) {
                            buf = (char*)calloc(1, (size_t)size + (addOneByteOfStringTerminationPadding ? 1 : 0));
                            if (buf) {
                                if (fread(buf, size, 1, stream) != 1) {
                                    free(buf);
                                    buf = 0;
                                    size = 0;
                                }
                            }
                            else {
                                size = 0;
                            }
                        }
                        else {
                            size = 0;
                        }
                    }
                }
                
                fclose(stream);
            }

            return pair<char*, size_t>(buf, size);
        }
    };
    
    class OVFileTimestamp {
    public:
        #if defined(__APPLE__)
        OVFileTimestamp(__darwin_time_t timestamp = 0, long subtimestamp = 0)
        #elif defined(WIN32)
        OVFileTimestamp(time_t timestamp = 0, time_t subtimestamp = 0)
        #else
            #error We don't know about Linux yet, sorry.
        #endif
            : m_timestamp(timestamp)
            , m_subtimestamp(subtimestamp)
        {
        }
        
        OVFileTimestamp(const OVFileTimestamp& timestamp)
            : m_timestamp(timestamp.m_timestamp)
            , m_subtimestamp(timestamp.m_subtimestamp)
        {
        }
        
        OVFileTimestamp& operator=(const OVFileTimestamp& timestamp)
        {
            m_timestamp = timestamp.m_timestamp;
            m_subtimestamp = timestamp.m_subtimestamp;
            return *this;
        }
        

        bool operator==(OVFileTimestamp& another)
        {
            return (m_timestamp == another.m_timestamp) && (m_subtimestamp == another.m_subtimestamp);
        }
        
        bool operator!=(OVFileTimestamp& another)
        {
            return (m_timestamp != another.m_timestamp) || (m_subtimestamp != another.m_subtimestamp);
        }

        bool operator<(OVFileTimestamp& another)
        {
            return (m_timestamp < another.m_timestamp) || ((m_timestamp == another.m_timestamp) && m_subtimestamp < another.m_subtimestamp);
        }        

        bool operator>(OVFileTimestamp& another)
        {
            return (m_timestamp > another.m_timestamp) || ((m_timestamp == another.m_timestamp) && m_subtimestamp > another.m_subtimestamp);        
        }        


    protected:
        #if defined(__APPLE__)
        __darwin_time_t m_timestamp;
        long m_subtimestamp;
        #elif defined(WIN32)
        time_t m_timestamp;
        time_t m_subtimestamp;
        #else
            #error We don't know about Linux yet, sorry.
        #endif
    };


    class OVPathHelper {
    public:
        static char Separator()
        {
            #ifndef WIN32
                return '/';
            #else
                return '\\';
            #endif
        }
        
        
        static const string DirectoryFromPath(const string& path)
        {
            string realPath = OVPathHelper::NormalizeByExpandingTilde(path);
            if (OVPathHelper::PathExists(realPath) && OVPathHelper::IsDirectory(realPath))
                return realPath;

            char separator = OVPathHelper::Separator();
            
            if (!realPath.length())
                return string(".");
                
            for (size_t index = realPath.length() - 1; index >= 0 ; index--) {
                if (realPath[index] == separator) {
                    if (index) {
                        // reserve the \\ on Windows
                        if (realPath[index-1] == '\\')
                            return realPath.substr(0, index + 1);
                        else
                            return realPath.substr(0, index);
                    }
                    else
                        return realPath.substr(0, 1);
                }
                
                // if we run into : (like C:) on Windows
                if (realPath[index] == ':')
                    return realPath.substr(0, index + 1) + Separator();
                
                if (!index) break;
            }
            
            return string(".");
        }
        
        static const string FilenameWithoutPath(const string &path)
        {
            char separator = OVPathHelper::Separator();
            
            if (!path.length())
                return string();
                
            for (size_t index = path.length() - 1; index >= 0 ; index--) {
                if (path[index] == separator)
                    return path.substr(index + 1, path.length() - (index + 1));
                    
                if (!index) break;                    
            }
            
            return path;
        }
        
        static const string FilenameWithoutExtension(const string &path)
        {
            char separator = OVPathHelper::Separator();
            if (!path.length())
                return string();

            for (size_t index = path.length() - 1; index >= 0 ; index--) {                
                if (path[index] == separator)
                    break;
                    
                if (path[index] == '.')
                    return path.substr(0, index);                

                if (!index) break;                    
            }
            
            return path;
        }
        
        static const string ChopTrailingSeparator(const string& path)
        {
            if (path.length() == 1 && path[0] == Separator())
                return path;

            string result;
                        
            if (path.length()) {
                if (path[path.length() - 1] == Separator())
                    result = path.substr(0, path.length() - 1);
                else
                    result = path;
            }
            
            return result;
        }
        
        static const string ChopLeadingSeparator(const string& path)
        {
            if (path.length() == 1 && path[0] == Separator())
                return path;

            string result;
            if (path.length()) {
                if (path[0] == Separator()) {
                    result = path.substr(1, path.length() - 1);
                }
                else {
                    result = path;
                }
            }
            return result;
        }
        
        static const string PathCat(const string& s1, const string& s2)
        {
            if (s2.length())
                return ChopTrailingSeparator(s1) + Separator() + ChopLeadingSeparator(s2);
            else
                return s1;
        }
        
        static const string Normalize(const string& path)
        {
            string newPath;
            size_t length = path.length();
            for (size_t index = 0; index < length; index++) {
                if (path[index] == '/' || path[index] == '\\') {
                    if (index < length - 1) {
                        if (path[index+1] == '/' || path[index+1] == '\\')
                            index++;
                    }
                    
                    newPath += Separator();
                }
                else
                    newPath += path[index];
            }
            
            return ChopTrailingSeparator(newPath);
        }
        
        static const bool PathExists(const string& path)
        {
            #ifndef WIN32
            struct stat buf;
            return !stat(path.c_str(), &buf);
            #else
            struct _stat buf;
            wstring wpath = OVUTF16::FromUTF8(path);
            return !_wstat(wpath.c_str(), &buf);
            #endif
        }
        
        static const bool IsDirectory(const string& path)
        {
            #ifndef WIN32
            struct stat buf;            
            if (!stat(path.c_str(), &buf))
            {
                if (buf.st_mode & S_IFDIR)
                    return true;
            }
            #else
            struct _stat buf;
            wstring wpath = OVUTF16::FromUTF8(path);
            if (!_wstat(wpath.c_str(), &buf))
            {
                if (buf.st_mode & S_IFDIR)
                    return true;
            }
            #endif
            return false;
		}
                    
        static const OVFileTimestamp TimestampForPath(const string& path)
        {
            OVFileTimestamp timestamp;
            #if defined(__APPLE__)
            struct stat buf;
            if (!stat(path.c_str(), &buf))
            {            
                timestamp = OVFileTimestamp(buf.st_mtimespec.tv_sec, buf.st_mtimespec.tv_nsec);
            }
            #elif defined(WIN32)
            struct _stat buf;
            wstring wpath = OVUTF16::FromUTF8(path);
            if (!_wstat(wpath.c_str(), &buf))
            {
                timestamp = OVFileTimestamp(buf.st_mtime);
            }
            #else
                #error Sorry, no idea for Linux yet.
            #endif
            return timestamp;
        }

        static bool RemoveEverythingAtPath(const string& path);                
        static const string NormalizeByExpandingTilde(const string& path);
    };
    
    class OVDirectoryHelper {
    public:
        static bool MakeDirectory(const string& path)
        {
            #ifndef WIN32
            return !mkdir(path.c_str(), S_IRWXU);
            #else
            wstring wpath = OVUTF16::FromUTF8(path);
            return CreateDirectoryW(wpath.c_str(), NULL) == TRUE;
            #endif
        }
        
        static bool MakeDirectoryWithImmediates(const string& path)
        {            
            string realPath = OVPathHelper::NormalizeByExpandingTilde(path);
            
            if (OVPathHelper::PathExists(realPath) && OVPathHelper::IsDirectory(realPath)) {
                return true;
            }
            
            string lastPart = OVPathHelper::DirectoryFromPath(realPath);      
            
            if (lastPart != realPath && !OVPathHelper::PathExists(lastPart)) {
                if (!MakeDirectoryWithImmediates(lastPart))
                    return false;
            }
            
            return MakeDirectory(realPath);
        }
        
        static bool CheckDirectory(const string& path)
        {
            string realPath = OVPathHelper::NormalizeByExpandingTilde(path);
            if (OVPathHelper::PathExists(realPath))
                return OVPathHelper::IsDirectory(realPath);
                
            return MakeDirectoryWithImmediates(realPath);
        }
                
        static const vector<string> Glob(const string& directory, const string& pattern = "*", const string& excludePattern = "", size_t depth = 1)
        {
            string sanitizedDirectory = OVPathHelper::NormalizeByExpandingTilde(directory);
            
            OVWildcard expression(pattern);
            OVWildcard negativeExpression(excludePattern);
            vector<string> dirResult;
            vector<string> fileResult;
            struct dirent** namelist = NULL;
            
            #ifndef WIN32
            int count = scandir(sanitizedDirectory.c_str(), &namelist, NULL, NULL);            
            for (int index = 0; index < count; index++) {
                struct dirent* entry = namelist[index];
                bool isDir = entry->d_type == DT_DIR;
                string name = entry->d_name;
            #else
            vector<pair<string, bool> > foundFiles;
            WIN32_FIND_DATAW findData;
			HANDLE findHandle = FindFirstFileW(OVUTF16::FromUTF8(OVPathHelper::PathCat(sanitizedDirectory, "*.*")).c_str(), &findData);
            if (findHandle != INVALID_HANDLE_VALUE) {
                foundFiles.push_back(pair<string, bool>(OVUTF8::FromUTF16(findData.cFileName), (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0));
                
                while (FindNextFileW(findHandle, &findData))
                {
                    foundFiles.push_back(pair<string, bool>(OVUTF8::FromUTF16(findData.cFileName), (findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0));
                }
                FindClose(findHandle);
            }
            
            size_t count = foundFiles.size();
            for (size_t index = 0; index < count; index++) {
                string name = foundFiles[index].first;
                bool isDir = foundFiles[index].second;
            #endif
                
                if ((!depth || depth > 1) && isDir && name != "." && name != "..") {                    
                    vector<string> subResult = Glob(OVPathHelper::PathCat(sanitizedDirectory, name), pattern, excludePattern, depth ? depth - 1 : 0);
                    vector<string>::iterator iter = subResult.begin();
                    for ( ; iter != subResult.end() ; iter++)
                        dirResult.push_back(*iter);
                }
                
                if (name != "." && name != ".." && expression.match(name) && !negativeExpression.match(name)) {
                    fileResult.push_back(OVPathHelper::PathCat(sanitizedDirectory, name));
                }
            
			#ifndef WIN32
                free(entry);
			#endif
            }            
            
            #ifndef WIN32
            if (count != -1)
                free(namelist);
            #endif

            sort(dirResult.begin(), dirResult.end());
            sort(fileResult.begin(), fileResult.end());
            for (vector<string>::iterator iter = dirResult.begin() ; iter != dirResult.end(); iter++)
                fileResult.push_back(*iter);

            return fileResult;
        }
    
        static const string TempDirectory()
        {
        #ifndef WIN32
            return string("/tmp");
        #else
            WCHAR path[MAX_PATH + 1];
            GetTempPathW(MAX_PATH, path);
            return OVUTF8::FromUTF16(path);
        #endif
        }
        
        static const string GenerateTempFilename(const string& prefix = "temp")
        {
            string pattern = OVPathHelper::PathCat(TempDirectory(), prefix + "-" + "XXXXXXXX");
            #ifndef WIN32
            char *p = (char*)calloc(1, pattern.length() + 1);
            strcpy(p, pattern.c_str());
            char *r = mktemp(p);
            if (!r) {
                free(p);
                return string();
            }        
            string result = r;
            free(p);
            return result;
            #else
            wstring wp = OVUTF16::FromUTF8(pattern);
            size_t length = wp.length() + 1;
            wchar_t* p = (wchar_t*)calloc(1, length * sizeof(wchar_t));
            wcscpy_s(p, length, wp.c_str());
            errno_t err = _wmktemp_s(p, length);
            if (err != 0) {
                free(p);
                return string();
            }
            
            string result = OVUTF8::FromUTF16(p);
            free(p);
            return result;
        
            #endif
        }
        
        static const string UserHomeDirectory()
        {
        #ifndef WIN32
            const char* homePath = getenv("HOME");
            if (homePath)
                return string(homePath);
            return TempDirectory();
        #else
            WCHAR path[MAX_PATH + 1];
            HRESULT error = SHGetFolderPathW(NULL, CSIDL_PROFILE, NULL, SHGFP_TYPE_CURRENT, path);
            if (!error) {
                return OVUTF8::FromUTF16(path);
            }
            return TempDirectory();
        #endif
        }
        
        static const string UserApplicationDataDirectory(const string& applicationName)
        {
        #if defined(__APPLE__)
            return OVPathHelper::PathCat(UserHomeDirectory(), OVPathHelper::PathCat("/Library/", applicationName));
        #elif defined(WIN32)
            WCHAR path[MAX_PATH + 1];
            HRESULT error = SHGetFolderPathW(NULL, CSIDL_APPDATA, NULL, SHGFP_TYPE_CURRENT, path);
            if (!error) {
				return OVPathHelper::PathCat(OVUTF8::FromUTF16(path), applicationName);
			}
			return OVPathHelper::PathCat(TempDirectory(), applicationName);
        #else
            return OVPathHelper::PathCat(UserHomeDirectory(), string(".") + applicationName);
        #endif
        }
        
        static const string UserApplicationSupportDataDirectory(const string& applicationName)
        {
        #ifdef __APPLE__
            return OVPathHelper::PathCat(UserHomeDirectory(), OVPathHelper::PathCat("/Library/Application Support", applicationName));
        #else
            return UserApplicationDataDirectory(applicationName);
        #endif            
        }
        
        static const string UserPreferencesDirectory(const string& applicationName)
        {
            #ifdef __APPLE__
            return OVPathHelper::NormalizeByExpandingTilde("~/Library/Preferences");
            #else
            return UserApplicationDataDirectory(applicationName);
            #endif
        }
    
    };
    
    inline const string OVPathHelper::NormalizeByExpandingTilde(const string& path)
    {
        string newPath = Normalize(path);
        
        if (newPath.length()) {
            if (newPath[0] == '~') {
                newPath = OVPathHelper::PathCat(OVDirectoryHelper::UserHomeDirectory(), newPath.substr(1, newPath.length()));
            }
        }
        
        return newPath;  
    }

    inline bool OVPathHelper::RemoveEverythingAtPath(const string& path)
    {
        if (!PathExists(path)) return false;
        
        if (IsDirectory(path)) {
            vector<string> files = OVDirectoryHelper::Glob(path, "*", "", 0);
            vector<string>::iterator iter = files.begin();
            for ( ; iter != files.end(); iter++) {
                if (!RemoveEverythingAtPath(*iter))
                    return false;
            }
            
            #ifndef WIN32
            return !rmdir(path.c_str());
            #else
            wstring wpath = OVUTF16::FromUTF8(path);
            return RemoveDirectoryW(wpath.c_str()) == TRUE;
            #endif            
        }
        else {
            #ifndef WIN32
            return !unlink(path.c_str());
            #else
            wstring wpath = OVUTF16::FromUTF8(path);
            return DeleteFileW(wpath.c_str()) == TRUE;
            #endif                            
        }
    }
};

#endif
