"""Map characters to Bopomofo pronunciations using heterophony and base mappings."""

from pathlib import Path

from curation import PROJECT_ROOT

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"


def load_bpmf_mappings(file_path: Path) -> dict[str, str]:
    """Load BPMF character-to-pronunciation mappings from file."""
    mappings = {}
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
    """Map words in candidate file to their BPMF pronunciations and print."""
    try:
        with open(cand_file, encoding="utf-8") as f:
            for line in f:
                if not line or line[0] == "#":
                    continue
                elements = line.rstrip().split()
                if not elements:
                    continue
                word = elements[0]
                pronunciations = [bpmf_mappings.get(char, "") for char in word]
                phon = " ".join([word] + pronunciations)
                print(phon)
    except OSError as e:
        print(f"Error reading {cand_file}: {e}")


def main() -> None:
    """Main entry point for BPMF mapping."""
    bpmf = {}
    heterophony_file = PROJECT_ROOT / "heterophony1.list"
    bpmf.update(load_bpmf_mappings(heterophony_file))
    bpmf_base_file = PROJECT_ROOT / "BPMFBase.txt"
    base_mappings = load_bpmf_mappings(bpmf_base_file)
    for char, pronunciation in base_mappings.items():
        if char not in bpmf:
            bpmf[char] = pronunciation
    cand_file = PROJECT_ROOT / "cand.occ"
    map_words_to_bpmf(cand_file, bpmf)


if __name__ == "__main__":
    main()
