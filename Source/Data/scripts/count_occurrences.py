"""Count phrase occurrences in corpus with parallel processing support."""

import argparse
import configparser
import multiprocessing
from pathlib import Path

from curation import CONFIG_FILE

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

config = configparser.ConfigParser()
config.read(CONFIG_FILE)
corpus_path = Path(config.get("data", "corpus_path")).expanduser()

bigstring = ""
try:
    with open(corpus_path, encoding="utf-8") as handle:
        bigstring = handle.read()
except OSError as e:
    print(f"Error reading corpus: {e}")
    raise


def count_string(substring: str) -> tuple[str, int, bool]:
    """Count occurrences of substring in corpus, return (substring, count, success)."""
    if bigstring and substring:
        return substring, bigstring.count(substring), True
    return "", 0, False


def load_phrases_from_file(file_path: Path) -> list[str]:
    """Load phrases from file (first word on each line)."""
    phrases = []
    try:
        with open(file_path, encoding="utf-8") as handle:
            for line in handle:
                if not line or line[0] == "#":
                    continue
                elements = line.rstrip().split()
                if elements:
                    phrases.append(elements[0])
    except OSError as e:
        print(f"Error reading {file_path}: {e}")
    return phrases


def load_phrases_from_stdin() -> list[str]:
    """Load phrases from standard input (first word on each line)."""
    phrases = []
    try:
        while True:
            line = input()
            if not line or line[0] == "#":
                continue
            elements = line.rstrip().split()
            if elements:
                phrases.append(elements[0])
    except EOFError:
        pass
    return phrases


def main() -> None:
    """Main entry point for phrase occurrence counting."""
    max_cores = multiprocessing.cpu_count()
    parser = argparse.ArgumentParser(description="Count phrase occurrences in corpus")
    parser.add_argument(
        "-j",
        metavar="<nproc>",
        type=int,
        help="specify number of simultaneous search threads",
    )
    parser.add_argument(
        "phraselist",
        help="file with one phrase per line, use - for standard input",
    )
    args = parser.parse_args()
    ncores = args.j if args.j and args.j <= max_cores else max_cores
    if args.phraselist == "-":
        allstrings = load_phrases_from_stdin()
    else:
        allstrings = load_phrases_from_file(Path(args.phraselist))
    with multiprocessing.Pool(ncores) as pool:
        results = pool.map_async(count_string, allstrings).get(9999999)
    outputs = [(phrase, count) for phrase, count, state in results if state]
    for phrase, count in outputs:
        print(f"{phrase}\t{count}")


if __name__ == "__main__":
    main()
