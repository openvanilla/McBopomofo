from ..compilers.compiler_utils import HEADER


def read_raw_lm_entries(path: str) -> list[tuple[str, str, str]]:
    """Read a McBopomofo LM file and return the raw entries"""

    entries = []

    with open(path) as f:
        lines = f.readlines()

        if not lines or lines[0] != HEADER:
            raise AssertionError(f"{path} is not a sorted McBopomofo LM file")

        for line in lines[1:]:
            # only split with one single whitespace, since split() can split
            # with full-width spaces characters, which we actually want
            reading, value, score = line.strip().split(" ")

            entries.append((reading, value, score))

    return entries


def read_lm(path: str) -> dict[str, list[tuple[str, str]]]:
    """Read a McBopomofo LM file and return the unigram mappings

    Each reading maps to a list of (value, score) pair, but the score is
    in string; this is to minimize diff, since reading floating point numbers
    in and writing it out does not always guarantee to produce the same string
    output, especially when different tools written in different languages
    are involved."""

    lm: dict[str, list[tuple[str, str]]] = {}

    entries = read_raw_lm_entries(path)

    for reading, value, score in entries:
        if reading in lm:
            lm[reading].append((value, score))
        else:
            lm[reading] = [(value, score)]

    return lm
