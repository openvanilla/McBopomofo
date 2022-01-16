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

#include "ParselessLM.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <memory>

McBopomofo::ParselessLM::~ParselessLM() { close(); }

bool McBopomofo::ParselessLM::open(const std::string_view& path)
{
    if (data_) {
        return false;
    }

    fd_ = ::open(path.data(), O_RDONLY);
    if (fd_ == -1) {
        return false;
    }

    struct stat sb;
    if (fstat(fd_, &sb) == -1) {
        ::close(fd_);
        fd_ = -1;
        return false;
    }

    length_ = static_cast<size_t>(sb.st_size);

    data_ = mmap(NULL, length_, PROT_READ, MAP_SHARED, fd_, 0);
    if (data_ == nullptr) {
        ::close(fd_);
        fd_ = -1;
        length_ = 0;
        return false;
    }

    db_ = std::unique_ptr<ParselessPhraseDB>(new ParselessPhraseDB(
        static_cast<char*>(data_), length_, /*validate_pragme=*/
        true));
    return true;
}

void McBopomofo::ParselessLM::close()
{
    if (data_ != nullptr) {
        munmap(data_, length_);
        ::close(fd_);
        fd_ = -1;
        length_ = 0;
        data_ = nullptr;
    }
}

const std::vector<Formosa::Gramambular::Bigram>
McBopomofo::ParselessLM::bigramsForKeys(
    const std::string& preceedingKey, const std::string& key)
{
    return std::vector<Formosa::Gramambular::Bigram>();
}

const std::vector<Formosa::Gramambular::Unigram>
McBopomofo::ParselessLM::unigramsForKey(const std::string& key)
{
    if (db_ == nullptr) {
        return std::vector<Formosa::Gramambular::Unigram>();
    }

    std::vector<Formosa::Gramambular::Unigram> results;
    for (const auto& row : db_->findRows(key + " ")) {
        Formosa::Gramambular::Unigram unigram;

        // Move ahead until we encounter the first space. This is the key.
        auto it = row.begin();
        while (it != row.end() && *it != ' ') {
            ++it;
        }

        unigram.keyValue.key = std::string(row.begin(), it);

        // Read past the space.
        if (it != row.end()) {
            ++it;
        }

        if (it != row.end()) {
            // Now it is the start of the value portion.
            auto value_begin = it;

            // Move ahead until we encounter the second space. This is the
            // value.
            while (it != row.end() && *it != ' ') {
                ++it;
            }
            unigram.keyValue.value = std::string(value_begin, it);
        }

        // Read past the space. The remainder, if it exists, is the score.
        if (it != row.end()) {
            ++it;
        }

        if (it != row.end()) {
            unigram.score = std::stod(std::string(it, row.end()));
        }
        results.push_back(unigram);
    }
    return results;
}

bool McBopomofo::ParselessLM::hasUnigramsForKey(const std::string& key)
{
    if (db_ == nullptr) {
        return false;
    }

    return db_->findFirstMatchingLine(key + " ") != nullptr;
}
