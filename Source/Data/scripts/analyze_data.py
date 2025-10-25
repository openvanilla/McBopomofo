"""Analyze dictionary data for score consistency and unigram completeness."""

from pathlib import Path

from curation import PROJECT_ROOT

__author__ = "The McBopomofo Authors"
__copyright__ = "Copyright 2024 and onwards The McBopomofo Authors"
__license__ = "MIT"

Reading = list[str]
Value = str
Score = float
UnigramData = tuple[Reading, Value, Score]
UnigramChar = tuple[Value, Score]
CompetingUnigram = tuple[Value, Score, Value, Score]
InsufficientEntry = tuple[Reading, Value, Score, list[UnigramChar], Score]

EMOJI_SCORE = -8.0
SEPARATOR = "-" * 72


def load_data_file(file_path: Path) -> list[UnigramData]:
    """Load and parse data.txt into (reading, value, score) tuples."""
    with open(file_path, encoding="utf-8") as f:
        lines = f.readlines()
    data = [ln.strip().split(" ") for ln in lines[1:] if not ln.startswith("_")]
    return [(d[0].split("-"), d[1], float(d[2])) for d in data]


def build_unigram_maps(
    data: list[UnigramData],
) -> tuple[dict[str, UnigramChar], dict[Value, Score], int, int]:
    """Build lookup maps for unigrams, return (1char_map, value_scores, 1char_count, multichar_count)."""
    unigram_1char = {}
    value_to_score = {}
    unigram_1char_count = 0
    unigram_multichar_count = 0

    for reading, value, score in data:
        if score == EMOJI_SCORE:
            continue

        if value in value_to_score:
            value_to_score[value] = max(score, value_to_score[value])
        else:
            value_to_score[value] = score

        if len(reading) > 1:
            unigram_multichar_count += 1
            continue

        unigram_1char_count += 1
        key = reading[0]

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
    """Analyze multi-char unigrams for score consistency, return (faulty, indifferents, insufficients, competing)."""
    faulty = []
    indifferents = []
    insufficients = []
    competing_unigrams = []
    for reading, value, score in data:
        if len(reading) < 2:
            continue
        if score == EMOJI_SCORE:
            continue
        comp = []
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
        if total_score >= score:
            entry = (reading, value, score, comp, score - total_score)
            composed_value = "".join(x[0] for x in comp)
            if value == composed_value:
                indifferents.append(entry)
            else:
                if (
                    composed_value in value_to_score
                    and value != composed_value
                    and score < value_to_score[composed_value]
                ):
                    competing_unigrams.append(
                        (value, score, composed_value, value_to_score[composed_value])
                    )
                insufficients.append(entry)
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

    insufficients_map = {}
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
    data_file = PROJECT_ROOT / "data.txt"
    if not data_file.exists():
        print(f"Error: {data_file} not found. Run 'make all' first to generate data files.")
        return
    data = load_data_file(data_file)
    unigram_1char, value_to_score, unigram_1char_count, unigram_multichar_count = (
        build_unigram_maps(data)
    )
    faulty, indifferents, insufficients, competing_unigrams = analyze_multi_char_unigrams(
        data, unigram_1char, value_to_score
    )
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
