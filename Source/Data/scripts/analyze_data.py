#!/usr/bin/env python3
"""
Analyze McBopomofo dictionary data for score consistency and completeness.

This script reads the compiled data.txt dictionary file and checks for:
- Unigram score consistency vs. constituent characters
- Multi-character unigrams that compete with character sequences
- Missing character definitions that prevent typing certain unigrams
"""

from pathlib import Path

__author__ = "The McBopomofo Authors"
__copyright__ = "Copyright 2024 and onwards The McBopomofo Authors"
__license__ = "MIT"

# Type aliases for clarity
Reading = list[str]
Value = str
Score = float
UnigramData = tuple[Reading, Value, Score]
UnigramChar = tuple[Value, Score]
CompetingUnigram = tuple[Value, Score, Value, Score]
InsufficientEntry = tuple[Reading, Value, Score, list[UnigramChar], Score]

# Constants
EMOJI_SCORE = -8.0
SEPARATOR = "-" * 72


def load_data_file(file_path: Path) -> list[UnigramData]:
    """
    Load and parse data.txt dictionary file.

    Args:
        file_path: Path to data.txt file

    Returns:
        List of (reading, value, score) tuples
    """
    with open(file_path, encoding="utf-8") as f:
        lines = f.readlines()

    # Skip header line and comment lines starting with '_'
    data = [ln.strip().split(" ") for ln in lines[1:] if not ln.startswith("_")]

    # Parse into structured format: ([readings], value, score)
    return [(d[0].split("-"), d[1], float(d[2])) for d in data]


def build_unigram_maps(
    data: list[UnigramData],
) -> tuple[dict[str, UnigramChar], dict[Value, Score], int, int]:
    """
    Build lookup maps for single-character unigrams and all values.

    Args:
        data: List of parsed unigram data

    Returns:
        Tuple of:
        - unigram_1char: Map of reading -> (value, score) for single-char unigrams
        - value_to_score: Map of value -> max score across all readings
        - unigram_1char_count: Count of single-character unigrams
        - unigram_multichar_count: Count of multi-character unigrams
    """
    unigram_1char: dict[str, UnigramChar] = {}
    value_to_score: dict[Value, Score] = {}
    unigram_1char_count = 0
    unigram_multichar_count = 0

    for reading, value, score in data:
        # Skip emojis
        if score == EMOJI_SCORE:
            continue

        # Track maximum score for each value
        if value in value_to_score:
            value_to_score[value] = max(score, value_to_score[value])
        else:
            value_to_score[value] = score

        if len(reading) > 1:
            unigram_multichar_count += 1
            continue

        unigram_1char_count += 1
        key = reading[0]

        # Keep highest-scored value for each reading
        if key in unigram_1char:
            if score > unigram_1char[key][1]:
                unigram_1char[key] = (value, score)
        else:
            unigram_1char[key] = (value, score)

    return unigram_1char, value_to_score, unigram_1char_count, unigram_multichar_count


def analyze_multi_char_unigrams(
    data: list[UnigramData],
    unigram_1char: dict[str, UnigramChar],
    value_to_score: dict[Value, Score],
) -> tuple[
    list[tuple[Reading, Value]],
    list[InsufficientEntry],
    list[InsufficientEntry],
    list[CompetingUnigram],
]:
    """
    Analyze multi-character unigrams for score consistency issues.

    Args:
        data: List of parsed unigram data
        unigram_1char: Map of single-character unigrams
        value_to_score: Map of values to their maximum scores

    Returns:
        Tuple of:
        - faulty: Unigrams with undefined constituent characters
        - indifferents: Unigrams where score = sum of char scores AND value matches chars
        - insufficients: Unigrams where score <= sum of constituent character scores
        - competing_unigrams: Unigrams competing with higher-scored character sequences
    """
    faulty: list[tuple[Reading, Value]] = []
    indifferents: list[InsufficientEntry] = []
    insufficients: list[InsufficientEntry] = []
    competing_unigrams: list[CompetingUnigram] = []

    for reading, value, score in data:
        # Only analyze multi-character unigrams
        if len(reading) < 2:
            continue

        # Skip emojis
        if score == EMOJI_SCORE:
            continue

        # Build composition from individual characters
        comp: list[UnigramChar] = []
        total_score = 0.0
        bad = False

        for char_reading in reading:
            if char_reading not in unigram_1char:
                bad = True
                break

            char_value, char_score = unigram_1char[char_reading]
            total_score += char_score
            comp.append((char_value, char_score))

        if bad:
            faulty.append((reading, value))
            continue

        # Check if unigram score is lower than sum of constituent chars
        if total_score >= score:
            entry = (reading, value, score, comp, score - total_score)
            composed_value = "".join(x[0] for x in comp)

            # Indifferent: same value as constituent chars
            if value == composed_value:
                indifferents.append(entry)
            else:
                # Check if competing with an existing unigram
                if composed_value in value_to_score and value != composed_value:
                    if score < value_to_score[composed_value]:
                        competing_unigrams.append(
                            (value, score, composed_value, value_to_score[composed_value])
                        )
                insufficients.append(entry)

    # Sort by score (descending) for easier analysis
    insufficients.sort(key=lambda i: i[2], reverse=True)
    competing_unigrams.sort(key=lambda i: i[1] - i[3], reverse=True)

    return faulty, indifferents, insufficients, competing_unigrams


def print_analysis_results(
    unigram_1char_count: int,
    unigram_multichar_count: int,
    indifferents: list[InsufficientEntry],
    insufficients: list[InsufficientEntry],
    competing_unigrams: list[CompetingUnigram],
    faulty: list[tuple[Reading, Value]],
) -> None:
    """Print formatted analysis results."""
    print(SEPARATOR)
    print(f"{unigram_1char_count:6d} unigrams with one character")
    print(f"{unigram_multichar_count:6d} unigrams with multiple characters")

    print(SEPARATOR)
    print("summary for unigrams with scores lower than their competing characters:")
    print(f"{len(indifferents):6d} unigrams that are indifferent since the characters are the same")

    insufficient_pct = len(insufficients) / float(unigram_multichar_count) * 100.0
    print(
        f"{len(insufficients):6d} unigrams that are not the top candidate "
        f"({insufficient_pct:.1f}% of unigrams)"
    )
    print("\nof which:")

    # Categorize by length
    insufficients_map: dict[int, list[InsufficientEntry]] = {}
    for length in range(2, 7):
        insufficients_map[length] = [i for i in insufficients if len(i[0]) == length]

    for length in range(2, 7):
        count = len(insufficients_map[length])
        print(f"  {count:6d} {length}-character unigrams")

    print(SEPARATOR)
    print("top insufficient 2-character unigrams")
    for entry in insufficients_map[2][:25]:
        print(entry)

    print(SEPARATOR)
    print("all insufficient 3-character unigrams")
    for entry in insufficients_map[3]:
        print(entry)

    print(SEPARATOR)
    print(
        f"{len(competing_unigrams)} unigrams also compete with unigrams "
        f"from top composing characters"
    )
    print("some samples:")
    for entry in competing_unigrams[:25]:
        print(entry)

    if faulty:
        print(SEPARATOR)
        print("The following unigrams cannot be typed:")
        for f in faulty:
            print(f)


def main() -> None:
    """Main entry point for the analysis script."""
    # Determine data.txt path relative to script location
    script_dir = Path(__file__).parent
    data_file = script_dir.parent / "data.txt"

    if not data_file.exists():
        print(f"Error: {data_file} not found. Run 'make all' first to generate data files.")
        return

    # Load and parse data
    data = load_data_file(data_file)

    # Build lookup maps
    unigram_1char, value_to_score, unigram_1char_count, unigram_multichar_count = (
        build_unigram_maps(data)
    )

    # Analyze multi-character unigrams
    faulty, indifferents, insufficients, competing_unigrams = analyze_multi_char_unigrams(
        data, unigram_1char, value_to_score
    )

    # Print results
    print_analysis_results(
        unigram_1char_count,
        unigram_multichar_count,
        indifferents,
        insufficients,
        competing_unigrams,
        faulty,
    )


if __name__ == "__main__":
    main()
