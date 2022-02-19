// Copyright (c) 2022 and onwards Lukhnos Liu
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

#include "gtest/gtest.h"
#include <algorithm>
#include <iostream>
#include <map>
#include <vector>
#include <cstdlib>
#include <sstream>
#include "Gramambular.h"

const char* SampleData = R"(
#
# The sample is from libtabe (http://sourceforge.net/projects/libtabe/)
# last updated in 2002. The project was originally initiated by
# Pai-Hsiang Hsiao in 1999.
#
# Libtabe is a frequency table of Taiwanese Mandarin words. The database
# itself is, according to the tar file, released under the BSD License.
#

ㄙ 絲 -9.495858
ㄙ 思 -9.006414
ㄙ 私 -99.000000
ㄙ 斯 -8.091803
ㄙ 司 -99.000000
ㄙ 嘶 -13.513987
ㄙ 撕 -12.259095
ㄍㄠ 高 -7.171551
ㄎㄜ 顆 -10.574273
ㄎㄜ 棵 -11.504072
ㄎㄜ 刻 -10.450457
ㄎㄜ 科 -7.171052
ㄎㄜ 柯 -99.000000
ㄍㄠ 膏 -11.928720
ㄍㄠ 篙 -13.624335
ㄍㄠ 糕 -12.390804
ㄉㄜ˙ 的 -3.516024
ㄉㄧˊ 的 -3.516024
ㄉㄧˋ 的 -3.516024
ㄓㄨㄥ 中 -5.809297
ㄉㄜ˙ 得 -7.427179
ㄍㄨㄥ 共 -8.381971
ㄍㄨㄥ 供 -8.501463
ㄐㄧˋ 既 -99.000000
ㄐㄧㄣ 今 -8.034095
ㄍㄨㄥ 紅 -8.858181
ㄐㄧˋ 際 -7.608341
ㄐㄧˋ 季 -99.000000
ㄐㄧㄣ 金 -7.290109
ㄐㄧˋ 騎 -10.939895
ㄓㄨㄥ 終 -99.000000
ㄐㄧˋ 記 -99.000000
ㄐㄧˋ 寄 -99.000000
ㄐㄧㄣ 斤 -99.000000
ㄐㄧˋ 繼 -9.715317
ㄐㄧˋ 計 -7.926683
ㄐㄧˋ 暨 -8.373022
ㄓㄨㄥ 鐘 -9.877580
ㄐㄧㄣ 禁 -10.711079
ㄍㄨㄥ 公 -7.877973
ㄍㄨㄥ 工 -7.822167
ㄍㄨㄥ 攻 -99.000000
ㄍㄨㄥ 功 -99.000000
ㄍㄨㄥ 宮 -99.000000
ㄓㄨㄥ 鍾 -9.685671
ㄐㄧˋ 繫 -10.425662
ㄍㄨㄥ 弓 -99.000000
ㄍㄨㄥ 恭 -99.000000
ㄐㄧˋ 劑 -8.888722
ㄐㄧˋ 祭 -10.204425
ㄐㄧㄣ 浸 -11.378321
ㄓㄨㄥ 盅 -99.000000
ㄐㄧˋ 忌 -99.000000
ㄐㄧˋ 技 -8.450826
ㄐㄧㄣ 筋 -11.074890
ㄍㄨㄥ 躬 -99.000000
ㄐㄧˋ 冀 -12.045357
ㄓㄨㄥ 忠 -99.000000
ㄐㄧˋ 妓 -99.000000
ㄐㄧˋ 濟 -9.517568
ㄐㄧˋ 薊 -12.021587
ㄐㄧㄣ 巾 -99.000000
ㄐㄧㄣ 襟 -12.784206
ㄋㄧㄢˊ 年 -6.086515
ㄐㄧㄤˇ 講 -9.164384
ㄐㄧㄤˇ 獎 -8.690941
ㄐㄧㄤˇ 蔣 -10.127828
ㄋㄧㄢˊ 黏 -11.336864
ㄋㄧㄢˊ 粘 -11.285740
ㄐㄧㄤˇ 槳 -12.492933
ㄍㄨㄥㄙ 公司 -6.299461
ㄎㄜㄐㄧˋ 科技 -6.736613
ㄐㄧˋㄍㄨㄥ 濟公 -13.336653
ㄐㄧㄤˇㄐㄧㄣ 獎金 -10.344678
ㄋㄧㄢˊㄓㄨㄥ 年終 -11.668947
ㄋㄧㄢˊㄓㄨㄥ 年中 -11.373044
ㄍㄠㄎㄜㄐㄧˋ 高科技 -9.842421
)";

using namespace std;
using namespace Formosa::Gramambular;

class SimpleLM : public LanguageModel
{
 public:
  SimpleLM(const char* input, bool swapKeyValue = false)
  {
    stringstream sstream(input);
    while (sstream.good()) {
      string line;
      getline(sstream, line);

      if (!line.size() || (line.size() && line[0] == '#')) {
        continue;
      }

      stringstream linestream(line);
      string col0;
      string col1;
      string col2;
      linestream >> col0;
      linestream >> col1;
      linestream >> col2;

      Unigram u;

      if (swapKeyValue) {
        u.keyValue.key = col1;
        u.keyValue.value = col0;
      }
      else {
        u.keyValue.key = col0;
        u.keyValue.value = col1;
      }

      u.score = atof(col2.c_str());

      m_db[u.keyValue.key].push_back(u);
    }
  }

  const vector<Bigram> bigramsForKeys(const string &preceedingKey, const string& key) override
  {
    return vector<Bigram>();
  }

  const vector<Unigram> unigramsForKey(const string &key) override
  {
    map<string, vector<Unigram> >::const_iterator f = m_db.find(key);
    return f == m_db.end() ? vector<Unigram>() : (*f).second;
  }

  bool hasUnigramsForKey(const string& key) override
  {
    map<string, vector<Unigram> >::const_iterator f = m_db.find(key);
    return f != m_db.end();
  }

 protected:
  map<string, vector<Unigram> > m_db;
};

TEST(GramambularTest, InputTest) {
  SimpleLM lm(SampleData);

  BlockReadingBuilder builder(&lm);
  builder.insertReadingAtCursor("ㄍㄠ");
  builder.insertReadingAtCursor("ㄐㄧˋ");
  builder.setCursorIndex(1);
  builder.insertReadingAtCursor("ㄎㄜ");
  builder.setCursorIndex(0);
  builder.deleteReadingAfterCursor();
  builder.insertReadingAtCursor("ㄍㄠ");
  builder.setCursorIndex(builder.length());
  builder.insertReadingAtCursor("ㄍㄨㄥ");
  builder.insertReadingAtCursor("ㄙ");
  builder.insertReadingAtCursor("ㄉㄜ˙");
  builder.insertReadingAtCursor("ㄋㄧㄢˊ");
  builder.insertReadingAtCursor("ㄓㄨㄥ");
  builder.insertReadingAtCursor("ㄐㄧㄤˇ");
  builder.insertReadingAtCursor("ㄐㄧㄣ");

  Walker walker(&builder.grid());

  vector<NodeAnchor> walked = walker.reverseWalk(builder.grid().width(), 0.0);
  reverse(walked.begin(), walked.end());

  vector<string> composed;
  for (vector<NodeAnchor>::iterator wi = walked.begin() ; wi != walked.end() ; ++wi) {
    composed.push_back((*wi).node->currentKeyValue().value);
  }
  ASSERT_EQ(composed, (vector<string>{"高科技", "公司", "的", "年中", "獎金"}));
}

TEST(GramambularTest, WordSegmentationTest) {
  SimpleLM lm2(SampleData, true);
  BlockReadingBuilder builder2(&lm2);
  builder2.insertReadingAtCursor("高");
  builder2.insertReadingAtCursor("科");
  builder2.insertReadingAtCursor("技");
  builder2.insertReadingAtCursor("公");
  builder2.insertReadingAtCursor("司");
  builder2.insertReadingAtCursor("的");
  builder2.insertReadingAtCursor("年");
  builder2.insertReadingAtCursor("終");
  builder2.insertReadingAtCursor("獎");
  builder2.insertReadingAtCursor("金");
  Walker walker2(&builder2.grid());

  vector<NodeAnchor> walked = walker2.reverseWalk(builder2.grid().width(), 0.0);
  reverse(walked.begin(), walked.end());

  vector<string> segmented;
  for (vector<NodeAnchor>::iterator wi = walked.begin(); wi != walked.end(); ++wi) {
    segmented.push_back((*wi).node->currentKeyValue().key);
  }
  ASSERT_EQ(segmented, (vector<string>{"高科技", "公司", "的", "年終", "獎金"}));
}
