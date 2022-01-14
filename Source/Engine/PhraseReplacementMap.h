#ifndef PHRASEREPLACEMENTMAP_H
#define PHRASEREPLACEMENTMAP_H

#include <string>
#include <map>
#include <iostream>

namespace McBopomofo {

class PhraseReplacementMap
{
public:
    PhraseReplacementMap();
    ~PhraseReplacementMap();

    bool open(const char *path);
    void close();
    const std::string valueForKey(const std::string& key);

protected:
    std::map<std::string_view, std::string_view> keyValueMap;
    int fd;
    void *data;
    size_t length;
};

}

#endif
