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

#ifndef SOURCE_ENGINE_PARSELESSLM_H_
#define SOURCE_ENGINE_PARSELESSLM_H_

#include <memory>
#include <string>
#include <vector>

#include "LanguageModel.h"
#include "ParselessPhraseDB.h"

namespace McBopomofo {

class ParselessLM : public Formosa::Gramambular::LanguageModel {
public:
    ~ParselessLM() override;

    bool open(const std::string_view& path);
    void close();

    const std::vector<Formosa::Gramambular::Bigram> bigramsForKeys(
        const std::string& preceedingKey, const std::string& key) override;
    const std::vector<Formosa::Gramambular::Unigram> unigramsForKey(
        const std::string& key) override;
    bool hasUnigramsForKey(const std::string& key) override;

private:
    int fd_ = -1;
    void* data_ = nullptr;
    size_t length_ = 0;
    std::unique_ptr<ParselessPhraseDB> db_;
};

}; // namespace McBopomofo

#endif // SOURCE_ENGINE_PARSELESSLM_H_
