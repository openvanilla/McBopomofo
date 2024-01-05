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

#ifndef SRC_ENGINE_USERPHRASESLM_H_
#define SRC_ENGINE_USERPHRASESLM_H_

#include "gramambular2/language_model.h"
#include <iostream>
#include <map>
#include <string>
#include <utility>
#include <vector>

namespace McBopomofo {

class UserPhrasesLM : public Formosa::Gramambular2::LanguageModel {
public:
    UserPhrasesLM();
    ~UserPhrasesLM() override;

    bool isLoaded();
    bool open(const char* path);
    void close();
    void dump();

    std::vector<Formosa::Gramambular2::LanguageModel::Unigram> getUnigrams(const std::string& key) override;
    bool hasUnigrams(const std::string& key) override;

protected:
    struct Row {
        Row(std::string_view k, std::string_view v)
            : key(std::move(k))
            , value(std::move(v))
        {
        }
        const std::string_view key;
        const std::string_view value;
    };

    std::map<std::string_view, std::vector<Row>> keyRowMap;
    int fd;
    void* data;
    size_t length;
};

} // namespace McBopomofo

#endif // SRC_ENGINE_USERPHRASESLM_H_
