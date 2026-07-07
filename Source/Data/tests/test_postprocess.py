import unittest
from curation.compilers.postprocess import *

SAMPLE_DATA = """ㄋㄧㄢˊ 年 -6.0865
ㄋㄧㄢˊ 粘 -11.2857
ㄋㄧㄢˊ 黏 -11.3369
ㄋㄧㄢˊ-ㄓㄨㄥ 年終 -11.3730
ㄋㄧㄢˊ-ㄓㄨㄥ 年中 -11.6689
ㄏㄠˇ 好 -2.78076369
ㄏㄠˇ-ㄒㄧㄢˇ 好險 -6.36398807
ㄏㄡ-ㄒㄧㄢˇ 好險 -6.36398807
ㄒㄧㄢˇ 顯 -3.57899621
ㄒㄧㄢˇ 險 -3.78145638
ㄓㄨㄥ 中 -5.8093
ㄓㄨㄥ 鍾 -9.6857
ㄓㄨㄥ 鐘 -9.8776
ㄓㄨㄥ 忠 -99.0000
ㄓㄨㄥ 盅 -99.0000
ㄓㄨㄥ 終 -99.0000
"""


class TestPostprocess(unittest.TestCase):
    def setUp(self):

        self.lm = {}

        for line in SAMPLE_DATA.splitlines():

            reading, value, score = line.split()
            if reading in self.lm:
                self.lm[reading].append((value, float(score)))
            else:
                self.lm[reading] = [(value, float(score))]

    def test_find_top_unigram_in_lm(self):
        value, score = find_top_unigram_in_lm(self.lm, "ㄋㄧㄢˊ")
        self.assertEqual(value, "年")
        self.assertLess(score, 0)

        value, score = find_top_unigram_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ")
        self.assertEqual(value, "年終")
        self.assertLess(score, 0)

        self.assertIsNone(find_top_unigram_in_lm(self.lm, "ㄅㄨˋ"))

    def test_find_top_unigram_in_lm_failure(self):
        self.assertIsNone(find_top_unigram_in_lm(self.lm, "ㄇㄟˊ"))

    def test_find_score_in_lm(self):
        s1 = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終")
        s2 = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年中")
        self.assertLess(s2, s1)

    def test_find_score_in_lm_failure_not_found(self):
        self.assertIsNone(find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄉㄧˇ", "年底"))
        self.assertIsNone(find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年鐘"))
        self.assertIsNone(find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥˋ", "年中"))

    def test_find_score_in_lm_failure_mismatching_reading_count(self):
        self.assertIsNone(find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年"))
        self.assertIsNone(find_score_in_lm(self.lm, "ㄋㄧㄢˊ", "年終"))

    def test_replace_score_in_lm(self):
        s = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年中")
        self.assertNotEqual(s, -2.0)

        before = list(self.lm["ㄋㄧㄢˊ-ㄓㄨㄥ"])

        replace_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年中", -2.0)

        after = list(self.lm["ㄋㄧㄢˊ-ㄓㄨㄥ"])
        self.assertNotEqual(before, after)

        s = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年中")
        self.assertEqual(s, -2.0)

    def test_replace_score_in_lm_falure_no_reading(self):
        with self.assertRaises(ValueError):
            replace_score_in_lm(self.lm, "ㄋㄧˊ-ㄓㄨㄥ", "年中", -2.0)

    def test_replace_score_in_lm_falure_no_replacement(self):
        with self.assertRaises(ValueError):
            replace_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年鐘", -2.0)

    def test_promote_over_single_syllables(self):
        v1, s1 = find_top_unigram_in_lm(self.lm, "ㄏㄠˇ")
        v2, s2 = find_top_unigram_in_lm(self.lm, "ㄒㄧㄢˇ")

        self.assertEqual(v1, "好")
        self.assertEqual(v2, "顯")

        before = find_score_in_lm(self.lm, "ㄏㄠˇ-ㄒㄧㄢˇ", "好險")
        self.assertLess(before, s1 + s2)

        promote_over_single_syllables(0, self.lm, "好險", "ㄏㄠˇ-ㄒㄧㄢˇ")
        after = find_score_in_lm(self.lm, "ㄏㄠˇ-ㄒㄧㄢˇ", "好險")
        self.assertGreater(after, s1 + s2)

    def test_promote_over_single_syllables_failures(self):
        # mismatching reading counts
        self.assertIsNone(
            promote_over_single_syllables(0, self.lm, "好", "ㄏㄠˇ-ㄒㄧㄢˇ")
        )
        self.assertIsNone(promote_over_single_syllables(0, self.lm, "好險", "ㄏㄠˇ"))

        # No such reading exists
        self.assertIsNone(
            promote_over_single_syllables(0, self.lm, "好險", "ㄏㄠˋ-ㄒㄧㄢˇ")
        )

        # Some unigrams not found
        self.assertIsNone(
            promote_over_single_syllables(0, self.lm, "好險", "ㄏㄡ-ㄒㄧㄢˇ")
        )

        # Promoting second time is an error
        v1, s1 = find_top_unigram_in_lm(self.lm, "ㄏㄠˇ")
        v2, s2 = find_top_unigram_in_lm(self.lm, "ㄒㄧㄢˇ")
        before = find_score_in_lm(self.lm, "ㄏㄠˇ-ㄒㄧㄢˇ", "好險")
        self.assertTrue(
            promote_over_single_syllables(0, self.lm, "好險", "ㄏㄠˇ-ㄒㄧㄢˇ")
        )
        find_score_in_lm(self.lm, "ㄏㄠˇ-ㄒㄧㄢˇ", "好險")
        self.assertIsNone(
            promote_over_single_syllables(0, self.lm, "好險", "ㄏㄠˇ-ㄒㄧㄢˇ")
        )

    def test_promote_over_peers(self):
        s1 = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終")
        s2 = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年中")
        self.assertLess(s2, s1)

        promote_over_peers(0, self.lm, "年中", "ㄋㄧㄢˊ-ㄓㄨㄥ")
        s1 = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年終")
        s2 = find_score_in_lm(self.lm, "ㄋㄧㄢˊ-ㄓㄨㄥ", "年中")
        self.assertGreater(s2, s1)

    def test_promote_over_peers_failures(self):
        # Not found
        self.assertIsNone(find_score_in_lm(self.lm, "ㄋㄧˊ-ㄓㄨㄥ", "年終"))

        # Promoting an already top unigram is an error
        self.assertIsNone(promote_over_peers(0, self.lm, "年終", "ㄋㄧㄢˊ-ㄓㄨㄥ"))
