"""Filter text to extract CJK and Bopomofo characters using regex."""
import re
import sys
from contextlib import suppress

__author__ = "@mjhsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

LHan = [
    [0x2E80, 0x2E99],  # Han # So  [26] CJK RADICAL REPEAT, CJK RADICAL RAP
    [0x2E9B, 0x2EF3],  # Han # So  [89] CJK RADICAL CHOKE, CJK RADICAL C-SIMPLIFIED TURTLE
    [0x2F00, 0x2FD5],  # Han # So [214] KANGXI RADICAL ONE, KANGXI RADICAL FLUTE
    0x3005,  # Han # Lm       IDEOGRAPHIC ITERATION MARK
    0x3007,  # Han # Nl       IDEOGRAPHIC NUMBER ZERO
    [0x3021, 0x3029],  # Han # Nl   [9] HANGZHOU NUMERAL ONE, HANGZHOU NUMERAL NINE
    [0x3038, 0x303A],  # Han # Nl   [3] HANGZHOU NUMERAL TEN, HANGZHOU NUMERAL THIRTY
    0x303B,  # Han # Lm       VERTICAL IDEOGRAPHIC ITERATION MARK
    [0x3105, 0x312D],  # bopomofo
    0x02C7,  # bopomofo
    0x02CA,  # bopomofo
    0x02CB,  # bopomofo
    0x02D9,  # bopomofo
    [0x3400, 0x4DB5],  # Han # Lo [6582] CJK UNIFIED IDEOGRAPH-3400, CJK UNIFIED IDEOGRAPH-4DB5
    [0x4E00, 0x9FC3],  # Han # Lo [20932] CJK UNIFIED IDEOGRAPH-4E00, CJK UNIFIED IDEOGRAPH-9FC3
    [
        0xF900,
        0xFA2D,
    ],  # Han # Lo [302] CJK COMPATIBILITY IDEOGRAPH-F900, CJK COMPATIBILITY IDEOGRAPH-FA2D
    [
        0xFA30,
        0xFA6A,
    ],  # Han # Lo  [59] CJK COMPATIBILITY IDEOGRAPH-FA30, CJK COMPATIBILITY IDEOGRAPH-FA6A
    [
        0xFA70,
        0xFAD9,
    ],  # Han # Lo [106] CJK COMPATIBILITY IDEOGRAPH-FA70, CJK COMPATIBILITY IDEOGRAPH-FAD9
    [0x20000, 0x2A6D6],  # Han # Lo [42711] CJK UNIFIED IDEOGRAPH-20000, CJK UNIFIED IDEOGRAPH-2A6D6
    [0x2F800, 0x2FA1D],
]  # Han # Lo [542] CJK COMPATIBILITY IDEOGRAPH-2F800, CJK COMPATIBILITY IDEOGRAPH-2FA1D


def build_re() -> re.Pattern[str]:
    """Build regex pattern for CJK and Bopomofo character ranges."""
    chars = []
    for i in LHan:
        if isinstance(i, list):
            f, t = i
            with suppress(ValueError, OverflowError):
                f = chr(f)
                t = chr(t)
                chars.append(f"{f}-{t}")
        else:
            with suppress(ValueError, OverflowError):
                chars.append(chr(i))
    regex_pattern = re.escape("[{}]+".format("".join(chars)))
    return re.compile(regex_pattern, re.UNICODE)


CJK_PATTERN = build_re()

while True:
    line = sys.stdin.readline()
    if not line:
        break
    lineout = " ".join(re.findall(CJK_PATTERN, line.rstrip()))
    print(lineout)
