#!/usr/bin/env python3
"""
Generate frequency scores for dictionary phrases.

Reads phrase occurrence counts and exclusion rules, then generates normalized
frequency scores using a logarithmic scale with length-based weighting.
"""

import math
import sys
from collections import defaultdict
from pathlib import Path

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

# Constants
FREQUENCY_SCALE = 2.7


def load_phrase_occurrences(file_path: Path) -> dict[str, int]:
    """
    Load phrase occurrence counts from file.

    Args:
        file_path: Path to phrase.occ file

    Returns:
        Dictionary mapping phrases to occurrence counts
    """
    phrases: dict[str, int] = {}

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
    """
    Load phrase exclusion rules from file.

    Exclusion rules specify phrases whose counts should be subtracted from
    other phrases (e.g., to avoid double-counting).

    Args:
        file_path: Path to exclusion.txt file

    Returns:
        Dictionary mapping phrases to lists of phrases to exclude
    """
    exclusion: dict[str, list[str]] = defaultdict(list)

    try:
        with open(file_path, encoding="utf-8") as f:
            for line in f:
                if not line or line[0] == "#":
                    continue

                elements = line.rstrip().split()
                if len(elements) >= 2:
                    mykey = elements[0]
                    myval = elements[1]

                    # Only exclude if the value contains the key
                    if mykey in myval:
                        exclusion[mykey].append(myval)

    except OSError as e:
        print(f"Error reading {file_path}: {e}")

    return dict(exclusion)


def apply_exclusions(phrases: dict[str, int], exclusion: dict[str, list[str]]) -> None:
    """
    Apply exclusion rules to phrase counts (in-place modification).

    Args:
        phrases: Dictionary of phrase occurrence counts
        exclusion: Dictionary of exclusion rules
    """
    for key, excluded_phrases in exclusion.items():
        for excluded in excluded_phrases:
            if key in phrases and excluded in phrases:
                phrases[key] = phrases[key] - phrases[excluded]


def calculate_normalization_factor(phrases: dict[str, int], fscale: float) -> float:
    """
    Calculate normalization factor for frequency scores.

    Args:
        phrases: Dictionary of phrase occurrence counts
        fscale: Frequency scaling factor

    Returns:
        Normalization factor
    """
    norm = 0.0
    for phrase, count in phrases.items():
        norm += fscale ** (len(phrase) / 3 - 1) * count

    return norm


def generate_frequency_file(
    output_path: Path,
    phrases: dict[str, int],
    fscale: float,
    norm: float,
) -> None:
    """
    Generate PhraseFreq.txt file with logarithmic frequency scores.

    Args:
        output_path: Path to output PhraseFreq.txt file
        phrases: Dictionary of phrase occurrence counts
        fscale: Frequency scaling factor
        norm: Normalization factor
    """
    try:
        with open(output_path, "w", encoding="utf-8") as f:
            for phrase, count in phrases.items():
                # Use 0.5 as minimum count for phrases with count < 1
                effective_count = max(count, 0.5)
                score = math.log(fscale ** (len(phrase) / 3 - 1) * effective_count / norm, 10)
                f.write(f"{phrase} {score:.8f}\n")

    except OSError as e:
        print(f"Error writing {output_path}: {e}")


def main() -> None:
    """Main entry point for frequency builder."""
    if len(sys.argv) > 1:
        sys.exit("This command does not take any argument")

    # Determine file paths relative to current working directory
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent.parent

    phrase_occ_file = data_dir / "phrase.occ"
    exclusion_file = data_dir / "exclusion.txt"
    output_file = data_dir / "PhraseFreq.txt"

    # Load data
    phrases = load_phrase_occurrences(phrase_occ_file)
    exclusion = load_exclusions(exclusion_file)

    # Apply exclusion rules
    apply_exclusions(phrases, exclusion)

    # Calculate normalization factor
    norm = calculate_normalization_factor(phrases, FREQUENCY_SCALE)

    # Generate output file
    generate_frequency_file(output_file, phrases, FREQUENCY_SCALE, norm)


if __name__ == "__main__":
    main()
