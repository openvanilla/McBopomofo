#!/usr/bin/env python3
"""
Count phrase occurrences in a corpus.

Reads a list of phrases and counts how many times each appears in the
configured corpus file. Supports parallel processing for faster counting.
"""

import argparse
import configparser
import multiprocessing
from pathlib import Path

# Import centralized project paths
from curation import CONFIG_FILE

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"


# Load corpus configuration
config = configparser.ConfigParser()
config.read(CONFIG_FILE)
corpus_path = Path(config.get("data", "corpus_path")).expanduser()

# Store corpus content globally for multiprocessing workers
# Not ideal, but sufficient for this use case
bigstring = ""
try:
    with open(corpus_path, encoding="utf-8") as handle:
        bigstring = handle.read()
except OSError as e:
    print(f"Error reading corpus: {e}")
    raise


def count_string(substring: str) -> tuple[str, int, bool]:
    """
    Count occurrences of a substring in the corpus.

    Args:
        substring: The phrase to count

    Returns:
        Tuple of (substring, count, success_status)
    """
    if bigstring and substring:
        return substring, bigstring.count(substring), True
    return "", 0, False


def load_phrases_from_file(file_path: Path) -> list[str]:
    """
    Load phrases from a file.

    Args:
        file_path: Path to file containing one phrase per line

    Returns:
        List of phrases (first word on each line)
    """
    phrases: list[str] = []

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
    """
    Load phrases from standard input.

    Returns:
        List of phrases (first word on each line)
    """
    phrases: list[str] = []

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

    # Determine number of cores to use
    if args.j and args.j <= max_cores:
        ncores = args.j
    else:
        ncores = max_cores

    # Load phrases
    if args.phraselist == "-":
        allstrings = load_phrases_from_stdin()
    else:
        allstrings = load_phrases_from_file(Path(args.phraselist))

    # Count occurrences in parallel
    with multiprocessing.Pool(ncores) as pool:
        results = pool.map_async(count_string, allstrings).get(9999999)

    # Filter successful results and print
    outputs = [(phrase, count) for phrase, count, state in results if state]
    for phrase, count in outputs:
        print(f"{phrase}\t{count}")


if __name__ == "__main__":
    main()
