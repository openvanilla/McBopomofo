#include "UserPhrasesLM.h"
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <fstream>
#include <unistd.h>

using namespace Formosa::Gramambular;
using namespace McBopomofo;

UserPhrasesLM::UserPhrasesLM()
    : fd(-1)
    , data(0)
    , length(0)
{
}

UserPhrasesLM::~UserPhrasesLM()
{
    if (data) {
        close();
    }
}

bool UserPhrasesLM::open(const char *path)
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

    data = mmap(NULL, length, PROT_WRITE, MAP_PRIVATE, fd, 0);
    if (!data) {
        ::close(fd);
        return false;
    }

    char *head = (char *)data;
    char *end = (char *)data + length;
    char c;
    Row row;

start:
    // EOF -> end
    if (head == end) {
        goto end;
    }

    c = *head;
    // \s -> error
    if (c == ' ') {
        goto error;
    }
    // \n -> start
    else if (c == '\n') {
        head++;
        goto start;
    }

    // \w -> record column star, state1
    row.value = head;
    head++;
    // fall through to state 1

state1:
    // EOF -> error
    if (head == end) {
        goto error;
    }

    c = *head;
    // \n -> error
    if (c == '\n') {
        goto error;
    }
    // \s -> state2 + zero out ending + record column start
    else if (c == ' ') {
        *head = 0;
        head++;
        row.key = head;
        goto state2;
    }

    // \w -> state1
    head++;
    goto state1;

state2:
    if (head == end) {
        *head = 0;
        head++;
        keyRowMap[row.key].push_back(row);
        goto end;
    }

    c = *head;
    // \s -> error
    if (c == ' ' || c == '\n') {
        *head = 0;
        head++;
        keyRowMap[row.key].push_back(row);
        if (c == ' ') {
            goto state3;
        }
        goto start;
    }

    // \w -> state 2
    head++;
    goto state2;

state3:
    if (head == end) {
        *head = 0;
        head++;
        keyRowMap[row.key].push_back(row);
        goto end;
    }

    c = *head;
    if (c == '\n') {
        goto start;
    }

    head++;
    goto state3;

error:
    close();
    return false;

end:
    static const char *space = " ";
    Row emptyRow;
    emptyRow.key = space;
    emptyRow.value = space;
    keyRowMap[space].push_back(emptyRow);

    return true;
}

void UserPhrasesLM::close()
{
    if (data) {
        munmap(data, length);
        ::close(fd);
        data = 0;
    }

    keyRowMap.clear();
}

void UserPhrasesLM::dump()
{
    size_t rows = 0;
    for (map<const char *, vector<Row> >::const_iterator i = keyRowMap.begin(), e = keyRowMap.end(); i != e; ++i) {
        const vector<Row>& r = (*i).second;
        for (vector<Row>::const_iterator ri = r.begin(), re = r.end(); ri != re; ++ri) {
            const Row& row = *ri;
            cerr << row.key << " " << row.value << "\n";
            rows++;
        }
    }
}

const vector<Bigram> UserPhrasesLM::bigramsForKeys(const string& preceedingKey, const string& key)
{
    return vector<Bigram>();
}

const vector<Unigram> UserPhrasesLM::unigramsForKey(const string& key)
{
    vector<Unigram> v;
    map<const char *, vector<Row> >::const_iterator i = keyRowMap.find(key.c_str());

    if (i != keyRowMap.end()) {
        for (vector<Row>::const_iterator ri = (*i).second.begin(), re = (*i).second.end(); ri != re; ++ri) {
            Unigram g;
            const Row& r = *ri;
            g.keyValue.key = r.key;
            g.keyValue.value = r.value;
            g.score = 0.0;
            v.push_back(g);
        }
    }

    return v;
}

bool UserPhrasesLM::hasUnigramsForKey(const string& key)
{
    return keyRowMap.find(key.c_str()) != keyRowMap.end();
}

