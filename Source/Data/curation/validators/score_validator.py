"""Extremely dumb self-check, is in need to adopt algorithms from the engine."""
import sys

from curation import PROJECT_ROOT

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2013 and onwards The McBopomofo Authors"
__license__ = "MIT"

XXXXXXX = [
    "ㄕㄨ˙",
    "ㄌㄧ˙",
    "ㄒㄧ˙",
    "ㄍㄨ˙",
    "ㄊㄞ˙",
    "ㄨㄚ˙",
    "ㄋㄞ˙",
    "ㄒㄧㄝ˙",
    "ㄌㄡ˙",
    "ㄌㄨ˙",
    "ㄐㄧㄝ˙",
    "ㄉㄧ˙",
    "ㄍㄨㄥ˙",
    "ㄌㄠ˙",
]


def seg_pick(
    phrases: dict[str, list[tuple[str, float]]],
    thisbpmf: str,
    segcand: str = "",
    segscore: float = 0,
) -> tuple[str, float]:
    """Pick the segment with highest score from phrases dict."""
    myscore = -9999.99
    mycand = ""
    if thisbpmf not in phrases:
        print(thisbpmf)
        sys.exit(1)
    for a, b in phrases[thisbpmf]:
        if myscore < b:
            mycand = a
            myscore = b
    segcand += mycand
    segscore += myscore
    return (segcand, segscore)


def two_char_walk(
    phrases: dict[str, list[tuple[str, float]]], bpmf2walk: str
) -> tuple[str, float]:
    bpmfinput = bpmf2walk.split("-")
    candidate = []
    # 1-2
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX:
        segcand = ""
        segscore = 0
        for mybpmf in bpmfinput:
            if mybpmf not in phrases:
                print(mybpmf)
                print(bpmf2walk)
                sys.exit(0)
            (segcand, segscore) = seg_pick(phrases, mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 12
    thisbpmf = "-".join(bpmfinput[0:2])
    if thisbpmf in phrases:
        segcand = ""
        segscore = 0
        (segcand, segscore) = seg_pick(phrases, thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    if candidate == []:
        print(bpmf2walk)
        sys.exit()
    return candidate[0]


def three_char_walk(
    phrases: dict[str, list[tuple[str, float]]], bpmf2walk: str
) -> tuple[str, float]:
    bpmfinput = bpmf2walk.split("-")
    candidate = []
    # 1-2-3 and 1-23
    if bpmfinput[0] not in XXXXXXX and bpmfinput[1] not in XXXXXXX and bpmfinput[2] not in XXXXXXX:
        segcand = ""
        segscore = 0
        mybpmf = bpmfinput[0]
        if mybpmf not in phrases:
            print(mybpmf)
            print(bpmf2walk)
            sys.exit(0)
        (segcand, segscore) = seg_pick(phrases, mybpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[1:3])
        (a, b) = two_char_walk(phrases, thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123
    thisbpmf = "-".join(bpmfinput[0:3])
    if thisbpmf in phrases:
        segcand = ""
        segscore = 0
        (segcand, segscore) = seg_pick(phrases, thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 12-3
    if bpmfinput[2] not in XXXXXXX and "-".join(bpmfinput[0:2]) in phrases:
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:2])
        (segcand, segscore) = seg_pick(phrases, thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[2]
        if mybpmf not in phrases:
            print(mybpmf)
            print(bpmf2walk)
            sys.exit(0)
        (segcand, segscore) = seg_pick(phrases, mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def four_char_walk(
    phrases: dict[str, list[tuple[str, float]]], bpmf2walk: str
) -> tuple[str, float]:
    bpmfinput = bpmf2walk.split("-")
    candidate = []
    # 1-2-3-4, 1-23-4, 1-2-34, 1-234
    if (
        bpmfinput[0] not in XXXXXXX
        and bpmfinput[1] not in XXXXXXX
        and bpmfinput[2] not in XXXXXXX
        and bpmfinput[3] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        mybpmf = bpmfinput[0]
        (segcand, segscore) = seg_pick(phrases, mybpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[1:4])
        (a, b) = three_char_walk(phrases, thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12-3-4, 12-34
    if (
        bpmfinput[2] not in XXXXXXX
        and bpmfinput[3] not in XXXXXXX
        and "-".join(bpmfinput[0:2]) in phrases
    ):
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:2])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[2:4])
        (a, b) = two_char_walk(phrases, thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123-4
    if bpmfinput[3] not in XXXXXXX and "-".join(bpmfinput[0:3]) in phrases:
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:3])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[3]
        (segcand, segscore) = seg_pick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 1234
    thisbpmf = "-".join(bpmfinput[0:4])
    if thisbpmf in phrases:
        segcand = ""
        segscore = 0
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def five_char_walk(
    phrases: dict[str, list[tuple[str, float]]], bpmf2walk: str
) -> tuple[str, float]:
    bpmfinput = bpmf2walk.split("-")
    candidate = []
    # 1-2345(expand)
    if (
        bpmfinput[0] not in XXXXXXX
        and bpmfinput[1] not in XXXXXXX
        and bpmfinput[2] not in XXXXXXX
        and bpmfinput[3] not in XXXXXXX
        and bpmfinput[4] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        mybpmf = bpmfinput[0]
        (segcand, segscore) = seg_pick(mybpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[1:5])
        (a, b) = four_char_walk(phrases, thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12-345(expand)
    if (
        "-".join(bpmfinput[0:2]) in phrases
        and bpmfinput[2] not in XXXXXXX
        and bpmfinput[3] not in XXXXXXX
        and bpmfinput[4] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:2])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[2:5])
        (a, b) = three_char_walk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123-45(expand)
    if (
        "-".join(bpmfinput[0:3]) in phrases
        and bpmfinput[3] not in XXXXXXX
        and bpmfinput[4] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:3])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[3:5])
        (a, b) = two_char_walk(phrases, thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 1234-5
    if "-".join(bpmfinput[0:4]) in phrases and bpmfinput[4] not in XXXXXXX:
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:4])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[4]
        (segcand, segscore) = seg_pick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 12345
    if "-".join(bpmfinput[0:5]) in phrases:
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:5])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def six_char_walk(
    phrases: dict[str, list[tuple[str, float]]], bpmf2walk: str
) -> tuple[str, float]:
    bpmfinput = bpmf2walk.split("-")
    candidate = []
    # 1-23456(exp)
    if (
        bpmfinput[0] not in XXXXXXX
        and bpmfinput[1] not in XXXXXXX
        and bpmfinput[2] not in XXXXXXX
        and bpmfinput[3] not in XXXXXXX
        and bpmfinput[4] not in XXXXXXX
        and bpmfinput[5] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        mybpmf = bpmfinput[0]
        (segcand, segscore) = seg_pick(mybpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[1:6])
        (a, b) = four_char_walk(phrases, thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12-3456(exp)
    if (
        "-".join(bpmfinput[0:2]) in phrases
        and bpmfinput[2] not in XXXXXXX
        and bpmfinput[3] not in XXXXXXX
        and bpmfinput[4] not in XXXXXXX
        and bpmfinput[5] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:2])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[2:6])
        (a, b) = three_char_walk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 123-456(exp)
    if (
        "-".join(bpmfinput[0:3]) in phrases
        and bpmfinput[3] not in XXXXXXX
        and bpmfinput[4] not in XXXXXXX
        and bpmfinput[5] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:3])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[3:6])
        (a, b) = three_char_walk(thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 1234-56(exp)
    if (
        "-".join(bpmfinput[0:4]) in phrases
        and bpmfinput[4] not in XXXXXXX
        and bpmfinput[5] not in XXXXXXX
    ):
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:4])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        thisbpmf = "-".join(bpmfinput[4:6])
        (a, b) = two_char_walk(phrases, thisbpmf)
        segcand += a
        segscore += b
        candidate.append((segcand, segscore))
    # 12345-6
    if "-".join(bpmfinput[0:5]) in phrases and bpmfinput[5] not in XXXXXXX:
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:5])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        mybpmf = bpmfinput[5]
        (segcand, segscore) = seg_pick(mybpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    # 123456
    if "-".join(bpmfinput[0:6]) in phrases:
        segcand = ""
        segscore = 0
        thisbpmf = "-".join(bpmfinput[0:6])
        (segcand, segscore) = seg_pick(thisbpmf, segcand, segscore)
        candidate.append((segcand, segscore))
    #
    candidate.sort(key=lambda x: x[1], reverse=True)
    return candidate[0]


def check_bpmf_output(phrases: dict[str, list[tuple[str, float]]], bpmf2chk: str) -> None:
    if len(bpmf2chk.split("-")) == 2:
        (a, b) = two_char_walk(phrases, bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print(f"{c} {d:f} {a} {b:f}")
    if len(bpmf2chk.split("-")) == 3:
        (a, b) = three_char_walk(phrases, bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print(f"{c} {d:f} {a} {b:f}")
    if len(bpmf2chk.split("-")) == 4:
        (a, b) = four_char_walk(phrases, bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print(f"{c} {d:f} {a} {b:f}")
    if len(bpmf2chk.split("-")) == 5:
        (a, b) = five_char_walk(phrases, bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print(f"{c} {d:f} {a} {b:f}")
    if len(bpmf2chk.split("-")) == 6:
        (a, b) = six_char_walk(phrases, bpmf2chk)
        (c, d) = phrases[bpmf2chk][0]
        if (a, b) != (c, d):
            print(f"{c} {d:f} {a} {b:f}")


def main() -> None:
    """Main entry point for score validation."""
    phrases: dict[str, list[tuple[str, float]]] = {}
    data_file = PROJECT_ROOT / "data.txt"
    try:
        with open(data_file, encoding="utf-8") as handle:
            for line in handle:
                if line and line[0] == "#":
                    continue
                if "_" in line:
                    continue
                elements = line.rstrip().split()
                if len(elements[1].split("-")) > 6:
                    continue
                if elements[1] not in phrases:
                    phrases[elements[1]] = []
                phrases[elements[1]].append((elements[0], float(elements[2])))
    except OSError as e:
        print(f"Error reading {data_file}: {e}")
        sys.exit(1)
    for mybpmf in phrases:
        if len(phrases[mybpmf]) > 1:
            phrases[mybpmf].sort(key=lambda x: x[1], reverse=True)
        check_bpmf_output(phrases, mybpmf)


if __name__ == "__main__":
    main()
