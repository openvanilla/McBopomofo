// Copyright (c) 2022 and onwards The McBopomofo Authors.
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

#include "PhraseReplacementMap.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <fstream>

#include "KeyValueBlobReader.h"

namespace McBopomofo {

using std::string;

PhraseReplacementMap::PhraseReplacementMap()
    : fd(-1)
    , data(0)
    , length(0)
{
}

PhraseReplacementMap::~PhraseReplacementMap()
{
    if (data) {
        close();
    }
}

bool PhraseReplacementMap::open(const char* path)
{
    if (data) {
        return false;
    }

    fd = ::open(path, O_RDONLY);
    if (fd == -1) {
        printf("open:: file not exist");
        return false;
    }

    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        printf("open:: cannot open file");
        return false;
    }

    length = static_cast<size_t>(sb.st_size);

    data = mmap(NULL, length, PROT_READ, MAP_SHARED, fd, 0);
    if (!data) {
        ::close(fd);
        return false;
    }

    KeyValueBlobReader reader(static_cast<char*>(data), length);
    KeyValueBlobReader::KeyValue keyValue;
    while (reader.Next(&keyValue) == KeyValueBlobReader::State::HAS_PAIR) {
        keyValueMap[keyValue.key] = keyValue.value;
    }
    return true;
}

void PhraseReplacementMap::close()
{
    if (data) {
        munmap(data, length);
        ::close(fd);
        data = 0;
    }

    keyValueMap.clear();
}

const std::string PhraseReplacementMap::valueForKey(const std::string& key)
{
    auto iter = keyValueMap.find(key);
    if (iter != keyValueMap.end()) {
        const std::string_view v = iter->second;
        return { v.data(), v.size() };
    }
    return string("");
}

} // namespace McBopomofo
