import unittest
from curation.mandarin.grid import *

import sys

SAMPLE_DATA = """ㄉㄜ˙ 的 -3.5160
ㄉㄜ˙ 得 -7.4272
ㄉㄧˊ 的 -3.5160
ㄉㄧˋ 的 -3.5160
ㄋㄧㄢˊ 年 -6.0865
ㄋㄧㄢˊ 粘 -11.2857
ㄋㄧㄢˊ 黏 -11.3369
ㄋㄧㄢˊ-ㄓㄨㄥ 年終 -11.3730
ㄋㄧㄢˊ-ㄓㄨㄥ 年中 -11.6689
ㄍㄠ 高 -7.1716
ㄍㄠ 膏 -11.9287
ㄍㄠ 糕 -12.3908
ㄍㄠ 篙 -13.6243
ㄍㄠ-ㄎㄜ-ㄐㄧˋ 高科技 -9.8424
ㄍㄠ-ㄖㄜˋ 高熱 -6.1526
ㄍㄨㄥ 工 -7.8222
ㄍㄨㄥ 公 -7.8780
ㄍㄨㄥ 共 -8.3820
ㄍㄨㄥ 供 -8.5015
ㄍㄨㄥ 紅 -8.8582
ㄍㄨㄥ 功 -99.0000
ㄍㄨㄥ 宮 -99.0000
ㄍㄨㄥ 弓 -99.0000
ㄍㄨㄥ 恭 -99.0000
ㄍㄨㄥ 攻 -99.0000
ㄍㄨㄥ 躬 -99.0000
ㄍㄨㄥ-ㄙ 公司 -6.2995
ㄎㄜ 科 -7.1711
ㄎㄜ 刻 -10.4505
ㄎㄜ 顆 -10.5743
ㄎㄜ 棵 -11.5041
ㄎㄜ 柯 -99.0000
ㄎㄜ-ㄐㄧˋ 科技 -6.7366
ㄏㄨㄛˇ 火 -3.6966
ㄏㄨㄛˇ 🔥 -8.0000
ㄏㄨㄛˇ-ㄧㄢˋ 火焰 -5.6231
ㄏㄨㄛˇ-ㄧㄢˋ 🔥 -8.0000
ㄐㄧˋ 際 -7.6083
ㄐㄧˋ 計 -7.9267
ㄐㄧˋ 暨 -8.3730
ㄐㄧˋ 技 -8.4508
ㄐㄧˋ 劑 -8.8887
ㄐㄧˋ 濟 -9.5176
ㄐㄧˋ 繼 -9.7153
ㄐㄧˋ 祭 -10.2044
ㄐㄧˋ 繫 -10.4257
ㄐㄧˋ 騎 -10.9399
ㄐㄧˋ 薊 -12.0216
ㄐㄧˋ 冀 -12.0454
ㄐㄧˋ 妓 -99.0000
ㄐㄧˋ 季 -99.0000
ㄐㄧˋ 寄 -99.0000
ㄐㄧˋ 忌 -99.0000
ㄐㄧˋ 既 -99.0000
ㄐㄧˋ 記 -99.0000
ㄐㄧˋ-ㄍㄨㄥ 濟公 -13.3367
ㄐㄧㄣ 金 -7.2901
ㄐㄧㄣ 今 -8.0341
ㄐㄧㄣ 禁 -10.7111
ㄐㄧㄣ 筋 -11.0749
ㄐㄧㄣ 浸 -11.3783
ㄐㄧㄣ 襟 -12.7842
ㄐㄧㄣ 巾 -99.0000
ㄐㄧㄣ 斤 -99.0000
ㄐㄧㄤˇ 獎 -8.6909
ㄐㄧㄤˇ 講 -9.1644
ㄐㄧㄤˇ 蔣 -10.1278
ㄐㄧㄤˇ 槳 -12.4929
ㄐㄧㄤˇ-ㄐㄧㄣ 獎金 -10.3447
ㄒㄧㄢˇ 險 -3.7810
ㄓㄨㄥ 中 -5.8093
ㄓㄨㄥ 鍾 -9.6857
ㄓㄨㄥ 鐘 -9.8776
ㄓㄨㄥ 忠 -99.0000
ㄓㄨㄥ 盅 -99.0000
ㄓㄨㄥ 終 -99.0000
ㄖㄜˋ 熱 -3.6024
ㄙ 斯 -8.0918
ㄙ 思 -9.0064
ㄙ 絲 -9.4959
ㄙ 撕 -12.2591
ㄙ 嘶 -13.5140
ㄙ 司 -99.0000
ㄙ 私 -99.0000
ㄧㄢˋ 焰 -5.4466
ㄨㄟˊ 危 -3.9832
ㄨㄟˊ-ㄒㄧㄢˇ 危險 -4.2623
"""


def segmented_values(nodes):
    return "-".join(n.value for n in nodes)


class TestMandarinGrid(unittest.TestCase):
    def setUp(self):

        self.lm = {}

        for line in SAMPLE_DATA.splitlines():

            reading, value, score = line.split()
            if reading in self.lm:
                self.lm[reading].append((value, float(score)))
            else:
                self.lm[reading] = [(value, float(score))]

    def test_grid1(self):
        readings = (
            "ㄍㄠ-ㄎㄜ-ㄐㄧˋ-ㄍㄨㄥ-ㄙ-ㄉㄜ˙-ㄋㄧㄢˊ-ㄓㄨㄥ-ㄐㄧㄤˇ-ㄐㄧㄣ".split("-")
        )
        walked = most_plausible_walk(readings, self.lm)
        self.assertEqual(segmented_values(walked), "高科技-公司-的-年終-獎金")

    def test_grid2(self):
        readings = "ㄍㄠ-ㄖㄜˋ-ㄏㄨㄛˇ-ㄧㄢˋ-ㄨㄟˊ-ㄒㄧㄢˇ".split("-")
        walked = most_plausible_walk(readings, self.lm)
        self.assertEqual(segmented_values(walked), "高熱-火焰-危險")

    def test_missing_entries_in_lm(self):
        # not in the sample data above
        readings = ["ㄨㄚ"]

        with self.assertRaises(ValueError):
            most_plausible_walk(readings, self.lm)
