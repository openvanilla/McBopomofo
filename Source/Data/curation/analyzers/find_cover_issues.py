"""
List the entries in the LM with issues of insufficient score or ambiguous
covers.
"""

import argparse
import math
from ..utils.lmreader import read_raw_lm_entries
import sys


def analyze(input: str, limit: int = -1) -> None:
    cutoff = None if limit <= 0 else limit
    raw_entries = read_raw_lm_entries(input)

    # Filter punctuation entries.
    entries = [entry for entry in raw_entries if not entry[0].startswith("_")]

    data = [(rd.split("-"), val, float(scr)) for rd, val, scr in entries]

    reading_to_emoji: dict[str, list[str]] = {}

    # Keeps track of the highest score a single-char unigram can have.
    reading_to_char_score: dict[str, tuple[str, float]] = {}

    # Keeps track of the highest score a value can have.
    value_to_score: dict[str, float] = {}

    monochar_unigram_count = 0
    multichar_unigram_count = 0
    emoji_count = 0
    macro_count = 0

    for readings, value, score in data:
        # Skip macros
        if value.startswith("MACRO@"):
            macro_count += 1
            continue

        # Tally emojis
        if score == -8:
            emoji_count += 1
            key = "-".join(readings)
            current = reading_to_emoji.get(key, [])
            current.append(value)
            reading_to_emoji[key] = current
            continue

        prev_score = value_to_score.get(value, -math.inf)
        if score > prev_score:
            value_to_score[value] = score

        if len(readings) > 1:
            multichar_unigram_count += 1
        else:
            monochar_unigram_count += 1

            key = readings[0]

            _, prev_score = reading_to_char_score.get(key, ("", -math.inf))
            if score > prev_score:
                reading_to_char_score[key] = (value, score)

    # Unigrams that can never be typed
    faulty: list[tuple[str, str]] = []

    # Multi-char phrases that are overriden by individual characters, but
    # since those characters are exactly the same as those in the phrase,
    # we don't mind ("we are indifferent") that those phrases' score are
    # insufficient.
    indifferents: list[
        tuple[list[str], str, float, list[tuple[str, float]], float, float]
    ] = []

    # Multi-char phrases that are overriden by individual characters with
    # much higher scores in total. These are the problematic phrases we are
    # trying to promote with caution.
    insufficients: list[
        tuple[list[str], str, float, list[tuple[str, float]], float, float]
    ] = []

    # Multi-char, homophonic phrases that compete with each other.
    competing_unigrams: list[tuple[str, float, str, float]] = []

    # Seen readings.
    phrase_readings = set()

    for readings, value, score in data:
        # We only care about multi-character phrases. No emojis.
        if len(readings) < 2 or score == -8:
            continue

        joined_reading = "-".join(readings)
        phrase_readings.add(joined_reading)

        # Keeps track of "competing" values with the same "component"
        # readings.
        comp: list[tuple[str, float]] = []
        ts = 0.0
        bad = False
        for reading in readings:
            if reading not in reading_to_char_score:
                bad = True
                break

            uv, us = reading_to_char_score[reading]
            ts += us
            comp.append((uv, us))

        if bad:
            faulty.append((joined_reading, value))
            continue

        if ts >= score:
            i = (readings, value, score, comp, ts, (score - ts))

            k = "".join([x[0] for x in comp])
            if value == k:
                indifferents.append(i)
            else:
                if k in value_to_score and value != k:
                    # If k also happens to be another phrase.
                    if score < value_to_score[k]:
                        competing_unigrams.append((value, score, k, value_to_score[k]))
                insufficients.append(i)

    # Sort by the phrases' own score, since they represent how frequently
    # they show up in the training corpus.
    insufficients = sorted(insufficients, key=lambda i: i[2], reverse=True)
    indifferents = sorted(indifferents, key=lambda i: i[2], reverse=True)

    # Ditto for competing_unigrams
    competing_unigrams = sorted(competing_unigrams, key=lambda i: i[1], reverse=True)

    def form_entry(heading, e):
        readings, phrase, score, competing_unigrams, their_score, delta = e

        competing_phrase = "+".join(c[0] for c in competing_unigrams)
        reading = "-".join(readings)

        return f"{heading} {phrase} {score:7.4f} < {competing_phrase} {their_score:7.4f} {reading}"

    def print_suppression_if_needed(total):
        if cutoff is not None and total > cutoff:
            print(f"...and {total - cutoff} more entries suppressed")
        print()

    separator = "-" * 72
    print(separator)
    print("Summary")
    print(separator)
    print(f"{monochar_unigram_count:6d} unigrams with one character")
    print(f"{multichar_unigram_count:6d} unigrams with multiple characters")
    print(f"{emoji_count:6d} emojis")
    print(f"{macro_count:6d} macros")
    print()

    print(separator)
    print("Multi-Character Phrases with Issues")
    print(separator)
    print(
        "%d unigrams that are not the top candidate (%.1f%% of unigrams)"
        % (
            len(insufficients),
            len(insufficients) / float(multichar_unigram_count) * 100.0,
        )
    )
    print()
    print("of which:")

    insufficients_map = {}
    for x in range(2, 7):
        entries_xch = [i for i in insufficients if len(i[0]) == x]
        insufficients_map[x] = entries_xch
        print(f"{len(entries_xch):6d} {x}-character unigrams")

    print()
    print(
        f"{len(competing_unigrams)} unigrams also compete with unigrams with top-ranking characters"
    )
    print(
        f"{len(indifferents)} unigrams whose scores are lower than their identical components"
    )
    print()

    for x in range(2, 7):
        entries_xch = insufficients_map[x]

        if not entries_xch:
            continue

        print(separator)
        print(f"Top Insufficient {x}-Character Unigrams")
        print(separator)

        for e in entries_xch[:cutoff]:
            print(form_entry("insufficient", e))
        print_suppression_if_needed(len(entries_xch))

    print(separator)
    print("Top Phrases that Compete with Other 'Peer' Phrases")
    print(separator)
    for entry in competing_unigrams[:cutoff]:
        our_value, our_score, their_value, their_score = entry
        print(
            f"competing {our_value} {our_score:7.4f} < {their_value} {their_score:7.4f}"
        )
    print_suppression_if_needed(len(competing_unigrams))

    print(separator)
    print("Multi-Character Phrases with Issues but We Don't Care")
    print(separator)

    for i in indifferents[:cutoff]:
        print(form_entry("indifferent", i))
    print_suppression_if_needed(len(indifferents))

    if faulty:
        print(separator)
        print("Unigrams that Cannot Be Typed")
        print(separator)
        for f in faulty:
            print(f)
        print()

    keys = reading_to_emoji.keys() - reading_to_char_score.keys() - phrase_readings
    if len(keys) > 0:
        print(separator)
        print("Emojis with No Covering Phrases (But May Have Smaller Covering Phrases)")
        print(separator)
        for k in list(keys)[:cutoff]:
            values = ", ".join(reading_to_emoji[k])
            print(f"{values:<10s} {k}")
        print_suppression_if_needed(len(keys))


def main():
    parser = argparse.ArgumentParser(description="find issues with phrases")
    parser.add_argument("--input", required=True, help="path to the LM file")
    parser.add_argument(
        "--limit", type=int, default=20, help="sample limit (-1 means unlimited)"
    )
    args = parser.parse_args()
    analyze(input=args.input, limit=args.limit)


if __name__ == "__main__":
    main()
