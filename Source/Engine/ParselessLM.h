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

#include "ParselessPhraseDB.h"
#include "gramambular2/language_model.h"

namespace McBopomofo {

class ParselessLM : public Formosa::Gramambular2::LanguageModel {
public:
    ~ParselessLM() override;

    bool isLoaded();
    bool open(const std::string_view& path);
    void close();

    std::vector<Formosa::Gramambular2::LanguageModel::Unigram> getUnigrams(
        const std::string& key) override;
    bool hasUnigrams(const std::string& key) override;

    struct FoundReading {
        std::string reading;
        double score;
    };
    // Look up reading by value. This is specific to ParselessLM only.
    std::vector<FoundReading> getReadings(const std::string& value);

private:
    int fd_ = -1;
    void* data_ = nullptr;
    size_t length_ = 0;
    std::unique_ptr<ParselessPhraseDB> db_;
};

}; // namespace McBopomofo

#endif // SOURCE_ENGINE_PARSELESSLM_H_
