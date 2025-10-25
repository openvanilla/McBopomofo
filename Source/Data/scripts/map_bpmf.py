#!/usr/bin/env python3
"""
Map characters to their Bopomofo (BPMF) pronunciations.

Reads heterophony and base mapping files to build a pronunciation dictionary,
then maps characters in candidate occurrence file to their pronunciations.
"""

from pathlib import Path

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"


def load_bpmf_mappings(file_path: Path) -> dict[str, str]:
    """
    Load BPMF mappings from a file.

    Args:
        file_path: Path to mapping file (heterophony1.list or BPMFBase.txt)

    Returns:
        Dictionary mapping characters to BPMF pronunciations
    """
    mappings: dict[str, str] = {}

    try:
        with open(file_path, encoding="utf-8") as f:
            for line in f:
                if not line or line[0] == "#":
                    continue

                elements = line.rstrip().split()
                if len(elements) >= 2 and elements[0] not in mappings:
                    mappings[elements[0]] = elements[1]

    except OSError as e:
        print(f"Error reading {file_path}: {e}")

    return mappings


def map_words_to_bpmf(cand_file: Path, bpmf_mappings: dict[str, str]) -> None:
    """
    Map words in candidate file to their BPMF pronunciations.

    Args:
        cand_file: Path to cand.occ file containing words
        bpmf_mappings: Dictionary of character -> BPMF mappings
    """
    try:
        with open(cand_file, encoding="utf-8") as f:
            for line in f:
                if not line or line[0] == "#":
                    continue

                elements = line.rstrip().split()
                if not elements:
                    continue

                word = elements[0]

                # Build pronunciation string
                pronunciations = [bpmf_mappings.get(char, "") for char in word]
                phon = " ".join([word] + pronunciations)

                print(phon)

    except OSError as e:
        print(f"Error reading {cand_file}: {e}")


def main() -> None:
    """Main entry point for BPMF mapping."""
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent

    # Build BPMF mapping dictionary from heterophony and base files
    bpmf: dict[str, str] = {}

    # First load heterophony (takes precedence)
    heterophony_file = data_dir / "heterophony1.list"
    bpmf.update(load_bpmf_mappings(heterophony_file))

    # Then load base mappings
    bpmf_base_file = data_dir / "BPMFBase.txt"
    base_mappings = load_bpmf_mappings(bpmf_base_file)
    # Only add mappings not already in bpmf (heterophony has priority)
    for char, pronunciation in base_mappings.items():
        if char not in bpmf:
            bpmf[char] = pronunciation

    # Map words to pronunciations
    cand_file = data_dir / "cand.occ"
    map_words_to_bpmf(cand_file, bpmf)


if __name__ == "__main__":
    main()
