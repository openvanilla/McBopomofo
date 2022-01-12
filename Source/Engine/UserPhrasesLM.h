#ifndef USERPHRASESLM_H
#define USERPHRASESLM_H

#include <stdio.h>

#include <string>
#include <map>
#include <iostream>
#include "LanguageModel.h"

namespace McBopomofo {

using namespace Formosa::Gramambular;

class UserPhrasesLM : public LanguageModel
{
public:
    UserPhrasesLM();
    ~UserPhrasesLM();
    
    bool open(const char *path);
    void close();
    void dump();
    
    virtual const vector<Bigram> bigramsForKeys(const string& preceedingKey, const string& key);
    virtual const vector<Unigram> unigramsForKey(const string& key);
    virtual bool hasUnigramsForKey(const string& key);
    
protected:
    struct CStringCmp
    {
        bool operator()(const char* s1, const char* s2) const
        {
            return strcmp(s1, s2) < 0;
        }
    };
    
    struct Row {
        const char *key;
        const char *value;
    };
    
    map<const char *, vector<Row>, CStringCmp> keyRowMap;
    int fd;
    void *data;
    size_t length;
};

}

#endif
