#!/usr/bin/env python3
"""
Main data compiler for McBopomofo dictionary.

Combines all source files (heterophony, mappings, frequencies, punctuation,
symbols, macros) into a single compiled data.txt file for the language model.
"""

import argparse
import sys

from .compiler_utils import HEADER, convert_vks_rows_to_sorted_kvs_rows

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

# Constants
UNK_LOG_FREQ = -99.0
H_DEFLT_FREQ = -6.8

# Module-level data structures (used throughout compilation)
bpmf_chars: dict[str, list[str]] = {}
bpmf_phrases: dict[str, list[str]] = {}
phrases: dict[str, float | str] = {}
bpmf_phon1: dict[str, str] = {}
bpmf_phon2: dict[str, str] = {}
bpmf_phon3: dict[str, str] = {}
bpmf_hetero: dict[str, str] = {}


def load_heterophony_file(file_path: str, target_dict: dict[str, str]) -> None:
    """
    Load heterophony pronunciation mappings from file.

    Args:
        file_path: Path to heterophony list file
        target_dict: Dictionary to populate with character -> pronunciation mappings
    """
    try:
        with open(file_path, encoding="utf-8") as f:
            for line in f:
                if not line or line[0] == "#":
                    continue

                elements = line.rstrip().split()
                if len(elements) >= 2:
                    target_dict[elements[0]] = elements[1]

    except OSError as e:
        print(f"Error reading {file_path}: {e}")


def load_bpmf_base(file_path: str) -> None:
    """
    Load base BPMF character mappings.

    Populates both bpmf_chars and bpmf_phrases module-level dictionaries.

    Args:
        file_path: Path to BPMFBase.txt file
    """
    with open(file_path, encoding="utf-8") as f:
        for line in f:
            if not line or line[0] == "#":
                continue

            elements = line.rstrip().split()
            if len(elements) < 5:
                continue

            elements[4]
            mykey = elements[0]
            myvalue = elements[1]

            # Add to both dictionaries
            if mykey in bpmf_chars:
                bpmf_chars[mykey].append(myvalue)
            else:
                bpmf_chars[mykey] = [myvalue]

            if mykey in bpmf_phrases:
                bpmf_phrases[mykey].append(myvalue)
            else:
                bpmf_phrases[mykey] = [myvalue]


def load_bpmf_mappings(file_path: str) -> None:
    """
    Load multi-character phrase BPMF mappings.

    Populates bpmf_phrases module-level dictionary.

    Args:
        file_path: Path to BPMFMappings.txt file
    """
    with open(file_path, encoding="utf-8") as f:
        for line in f:
            if not line or line[0] == "#":
                continue

            elements = line.rstrip().split()
            if not elements:
                continue

            mykey = elements.pop(0)
            myvalue = "-".join(elements)

            if mykey in bpmf_phrases:
                bpmf_phrases[mykey].append(myvalue)
            else:
                bpmf_phrases[mykey] = [myvalue]


def load_phrase_frequencies(file_path: str) -> None:
    """
    Load phrase frequency scores.

    Populates phrases module-level dictionary, maintaining order from BPMFBase.

    Args:
        file_path: Path to PhraseFreq.txt file
    """
    # Populate phrases dict with entries from BPMFBase.txt first
    # This maintains order for rarely used characters
    for key in bpmf_chars:
        phrases[key] = UNK_LOG_FREQ

    with open(file_path, encoding="utf-8") as f:
        for line in f:
            if not line or line[0] == "#":
                continue

            elements = line.rstrip().split()
            if len(elements) < 2:
                continue

            mykey = elements.pop(0)
            myvalue = elements.pop(0)

            # Verify key exists in bpmf_phrases
            if mykey not in bpmf_phrases:
                sys.exit(f"[ERROR] {mykey} key mismatches.")

            phrases[mykey] = myvalue


def generate_output_entries() -> list[tuple[str, str, float | str]]:
    """
    Generate output entries from loaded data with heterophony handling.

    Returns:
        List of (character/phrase, reading, score) tuples
    """
    output: list[tuple[str, str, float | str]] = []

    for mykey, myvalue in phrases.items():
        readings = bpmf_phrases.get(mykey)

        if not readings:
            continue

        # Multi-character phrases (Chinese characters are typically 3 bytes in UTF-8)
        if len(mykey) > 3:
            for r in readings:
                output.append((mykey, r, myvalue))
            continue

        # Single characters with heterophony handling
        for r in readings:
            # Primary heterophony (highest priority)
            if mykey not in bpmf_phon1:
                output.append((mykey, r, myvalue))
                continue
            elif str(bpmf_phon1[mykey]) == r:
                output.append((mykey, r, myvalue))
                continue

            # Secondary heterophony (50% frequency reduction)
            elif mykey not in bpmf_phon2:
                output.append((mykey, r, H_DEFLT_FREQ))
                continue
            elif str(bpmf_phon2[mykey]) == r:
                # log(1/2) = -0.69314718055994 (50% frequency reduction)
                if float(myvalue) - 0.69314718055994 > H_DEFLT_FREQ:
                    output.append((mykey, r, float(myvalue) - 0.69314718055994))
                    continue
                else:
                    output.append((mykey, r, H_DEFLT_FREQ))
                    continue

            # Tertiary heterophony (25% frequency: 50% * 50%)
            elif mykey not in bpmf_phon3:
                output.append((mykey, r, H_DEFLT_FREQ))
                continue
            elif str(bpmf_phon3[mykey]) == r:
                # log(1/2*1/2) = -0.69314718055994*2 (25% frequency)
                if float(myvalue) - 0.69314718055994 * 2 > H_DEFLT_FREQ:
                    output.append((mykey, r, float(myvalue) - 0.69314718055994 * 2))
                    continue
                else:
                    output.append((mykey, r, H_DEFLT_FREQ))
                    continue

            # Rare/unlisted heterophony pronunciations get default frequency
            output.append((mykey, r, H_DEFLT_FREQ))

    return output


def cook(
    heterophony1_path: str,
    heterophony2_path: str,
    heterophony3_path: str,
    phrase_freq_path: str,
    bpmf_mappings_path: str,
    bpmf_base_path: str,
    punctuations_path: str,
    symbols_path: str,
    macros_path: str,
    output_path: str,
) -> None:
    """
    Compile all dictionary source files into final data.txt.

    Args:
        heterophony1_path: Path to primary heterophony list
        heterophony2_path: Path to secondary heterophony list
        heterophony3_path: Path to tertiary heterophony list
        phrase_freq_path: Path to phrase frequencies file
        bpmf_mappings_path: Path to BPMF phrase mappings
        bpmf_base_path: Path to BPMF base character mappings
        punctuations_path: Path to punctuation mappings
        symbols_path: Path to symbol mappings
        macros_path: Path to macro mappings
        output_path: Path to output data.txt file
    """
    # Load heterophony priorities
    load_heterophony_file(heterophony1_path, bpmf_phon1)
    load_heterophony_file(heterophony2_path, bpmf_phon2)
    load_heterophony_file(heterophony3_path, bpmf_phon3)

    # Load base character mappings
    load_bpmf_base(bpmf_base_path)

    # Load phrase mappings
    load_bpmf_mappings(bpmf_mappings_path)

    # Load frequency scores
    load_phrase_frequencies(phrase_freq_path)

    # Generate main output entries
    output = generate_output_entries()

    # Add punctuation mappings
    with open(punctuations_path, encoding="utf-8") as punctuations_file:
        for line in punctuations_file:
            row = line.rstrip().split(" ")
            assert len(row) == 3
            output.append(tuple(row))

    # Add symbol mappings
    with open(symbols_path, encoding="utf-8") as symbols_file:
        for line in symbols_file:
            row = line.rstrip().split(" ")
            assert len(row) == 3, row
            output.append(tuple(row))

    # Add macro mappings
    with open(macros_path, encoding="utf-8") as macro_file:
        for line in macro_file:
            row = line.rstrip().split(" ")
            assert len(row) == 3, row
            output.append(tuple(row))

    # Convert and sort output
    output = convert_vks_rows_to_sorted_kvs_rows(output)

    # Write final output file
    with open(output_path, "w", encoding="utf-8") as fout:
        fout.write(HEADER)

        for row in output:
            if isinstance(row[-1], float):
                fout.write(f"{row[0]} {row[1]} {row[2]:f}\n")
            else:
                fout.write(f"{row[0]} {row[1]} {row[2]}\n")


def main() -> None:
    """Main entry point for data compiler."""
    parser = argparse.ArgumentParser(description="cook phrases database")
    parser.add_argument("--heterophony1", required=True)
    parser.add_argument("--heterophony2", required=True)
    parser.add_argument("--heterophony3", required=True)
    parser.add_argument("--phrase_freq", required=True)
    parser.add_argument("--bpmf_mappings", required=True)
    parser.add_argument("--bpmf_base", required=True)
    parser.add_argument("--punctuations", required=True)
    parser.add_argument("--symbols", required=True)
    parser.add_argument("--macros", required=True)
    parser.add_argument("--output", required=True)

    args = parser.parse_args()
    cook(
        heterophony1_path=args.heterophony1,
        heterophony2_path=args.heterophony2,
        heterophony3_path=args.heterophony3,
        phrase_freq_path=args.phrase_freq,
        bpmf_mappings_path=args.bpmf_mappings,
        bpmf_base_path=args.bpmf_base,
        punctuations_path=args.punctuations,
        symbols_path=args.symbols,
        macros_path=args.macros,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
