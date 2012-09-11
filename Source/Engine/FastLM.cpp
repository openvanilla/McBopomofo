//
// FastLM.h: A fast unigram language model for Gramambular
//
// Copyright (c) 2012 Lukhnos Liu (http://lukhnos.org)
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

#include "FastLM.h"
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <fstream>

using namespace Formosa::Gramambular;

FastLM::FastLM()
    : fd(-1)
    , data(0)
    , length(0)
{
}

FastLM::~FastLM()
{
    if (data) {
        close();
    }
}

bool FastLM::open(const char *path)
{
    if (data) {
        return false;
    }

	fd = ::open(path, O_RDONLY);
	if (fd == -1) {
		return false;
	}

    struct stat sb;
	if (fstat(fd, &sb) == -1) {
		return false;
	}

    length = (size_t)sb.st_size;

	data = mmap(NULL, length, PROT_WRITE, MAP_PRIVATE, fd, 0);
	if (!data) {
        ::close(fd);
		return false;
	}

    // we have 5 states
    // 0
    //  end -> end
    //  lf -> forward, go to 0
    //  space -> error
    //  other -> record ptr, forward, goto 1
    // 1
    //  end -> error
    //  lf -> error
    //  space -> zero out, check length, record ptr, go to 2
    //  other -> forward, go to 1
    // 2
    //  lf -> error
    //  end -> error
    //  space -> zero out, check length, record ptr, go to 3
    //  other -> forward, go to 2
    // 3
    //  end -> error
    //  lf -> save row, zero out, go to 0
    //  space -> error
    //  other -> forward, go to 3


    char *head = (char *)data;
    char *end = (char *)data + length;
    char c;
    Row row;

state0:
    if (head == end) {
        goto end;
    }

    c = *head;
    if (c == '\n') {
        head++;
        goto state0;
    }
    else if (c == ' ') {
        goto error;
    }

    row.value = head;
    head++;
    // fall through state 1

state1:
    if (head == end) {
        goto error;
    }

    c = *head;
    if (c == '\n') {
        goto error;
    }
    else if (c == ' ') {
        if (row.value == head) {
            goto error;
        }

        *head = 0;
        head++;
        row.key = head;
        goto state2;
    }

    head++;
    goto state1;

state2:
    if (head == end) {
        goto error;
    }

    c = *head;
    if (c == '\n') {
        goto error;
    }
    else if (c == ' ') {
        if (row.key == head) {
            goto error;
        }

        *head = 0;
        head++;
        row.logProbability = head;
        goto state3;
    }

    head++;
    goto state2;

state3:
    if (head == end) {
        goto error;
    }

    c = *head;
    if (c == '\n') {
        if (row.logProbability == head) {
            goto error;
        }

        *head = 0;
        head++;
        keyRowMap[row.key].push_back(row);
        goto state0;
    }

    if (c == ' ') {
        goto error;
    }

    head++;
    goto state3;

error:
    close();
    return false;

end:
    static const char *space = " ";
    static const char *zero = "0.0";
    Row emptyRow;
    emptyRow.key = space;
    emptyRow.value = space;
    emptyRow.logProbability = zero;
    keyRowMap[space].push_back(emptyRow);

    return true;
}

void FastLM::close()
{
    if (data) {
        munmap(data, length);
        ::close(fd);
        data = 0;
    }

    keyRowMap.clear();
}

void FastLM::dump()
{
    size_t rows = 0;
    for (map<const char *, vector<Row> >::const_iterator i = keyRowMap.begin(), e = keyRowMap.end(); i != e; ++i) {
        const vector<Row>& r = (*i).second;
        for (vector<Row>::const_iterator ri = r.begin(), re = r.end(); ri != re; ++ri) {
            const Row& row = *ri;
            cerr << row.key << " " << row.value << " " << row.logProbability << "\n";
            rows++;
        }
    }
}

const vector<Bigram> FastLM::bigramsForKeys(const string& preceedingKey, const string& key)
{
    return vector<Bigram>();
}

const vector<Unigram> FastLM::unigramsForKeys(const string& key)
{
    vector<Unigram> v;
    map<const char *, vector<Row> >::const_iterator i = keyRowMap.find(key.c_str());

    if (i != keyRowMap.end()) {
        for (vector<Row>::const_iterator ri = (*i).second.begin(), re = (*i).second.end(); ri != re; ++ri) {
            Unigram g;
            const Row& r = *ri;
            g.keyValue.key = r.key;
            g.keyValue.value = r.value;
            g.score = atof(r.logProbability);
            v.push_back(g);
        }
    }

    return v;
}

bool FastLM::hasUnigramsForKey(const string& key)
{
    return keyRowMap.find(key.c_str()) != keyRowMap.end();
}
