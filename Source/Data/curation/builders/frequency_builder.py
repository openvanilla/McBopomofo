"""Generate frequency scores for dictionary phrases with logarithmic scaling."""

import math
import sys
from collections import defaultdict
from pathlib import Path

from curation import PROJECT_ROOT

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

FREQUENCY_SCALE = 2.7


def load_phrase_occurrences(file_path: Path) -> dict[str, int]:
    """Load phrase occurrence counts from phrase.occ file."""
    phrases = {}
    try:
        with open(file_path, encoding="utf-8") as f:
            for line in f:
                if not line or line[0] == "#":
                    continue
                elements = line.rstrip().split()
                if len(elements) >= 2:
                    phrases[elements[0]] = int(elements[1])
    except OSError as e:
        print(f"Error reading {file_path}: {e}")
    return phrases


def load_exclusions(file_path: Path) -> dict[str, list[str]]:
    """Load phrase exclusion rules to subtract overlapping counts."""
    exclusion = defaultdict(list)
    try:
        with open(file_path, encoding="utf-8") as f:
            for line in f:
                if not line or line[0] == "#":
                    continue
                elements = line.rstrip().split()
                if len(elements) >= 2 and elements[0] in elements[1]:
                    exclusion[elements[0]].append(elements[1])
    except OSError as e:
        print(f"Error reading {file_path}: {e}")
    return dict(exclusion)


def apply_exclusions(phrases: dict[str, int], exclusion: dict[str, list[str]]) -> None:
    """Apply exclusion rules to phrase counts (modifies phrases in-place)."""
    for key, excluded_phrases in exclusion.items():
        for excluded in excluded_phrases:
            if key in phrases and excluded in phrases:
                phrases[key] -= phrases[excluded]


def calculate_normalization_factor(phrases: dict[str, int], fscale: float) -> float:
    """Calculate normalization factor for frequency scores."""
    return sum(fscale ** (len(p) / 3 - 1) * c for p, c in phrases.items())


def generate_frequency_file(
    output_path: Path, phrases: dict[str, int], fscale: float, norm: float
) -> None:
    """Generate PhraseFreq.txt with logarithmic frequency scores."""
    try:
        with open(output_path, "w", encoding="utf-8") as f:
            for phrase, count in phrases.items():
                effective_count = max(count, 0.5)
                score = math.log(fscale ** (len(phrase) / 3 - 1) * effective_count / norm, 10)
                f.write(f"{phrase} {score:.8f}\n")
    except OSError as e:
        print(f"Error writing {output_path}: {e}")


def main() -> None:
    """Main entry point for frequency builder."""
    if len(sys.argv) > 1:
        sys.exit("This command does not take any argument")
    phrases = load_phrase_occurrences(PROJECT_ROOT / "phrase.occ")
    exclusion = load_exclusions(PROJECT_ROOT / "exclusion.txt")
    apply_exclusions(phrases, exclusion)
    norm = calculate_normalization_factor(phrases, FREQUENCY_SCALE)
    generate_frequency_file(PROJECT_ROOT / "PhraseFreq.txt", phrases, FREQUENCY_SCALE, norm)


if __name__ == "__main__":
    main()
