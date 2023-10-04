#include "PhraseReplacementMap.h"

#include <fcntl.h>
#include <fstream>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

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

    length = (size_t)sb.st_size;

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

}
