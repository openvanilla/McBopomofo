#!/usr/bin/env python3
"""
Audit encoding categories in BPMFBase.txt

Validates that characters are correctly categorized as:
- big5: Characters in Big5 or Big5-HKSCS encoding
- cns: Characters in CNS 11643 encoding but not in Big5/Big5-HKSCS
- utf8: Characters only in UTF-8 (not in Big5/Big5-HKSCS/CNS)

Usage:
    python3 scripts/audit_encoding.py
    # Or after pip install:
    mcbpmf_audit_encoding
"""

import sys
from pathlib import Path

__author__ = "The McBopomofo Authors"
__copyright__ = "Copyright 2024 and onwards The McBopomofo Authors"
__license__ = "MIT"


def can_encode(char: str, encoding: str) -> bool:
    """Check if a character can be encoded in the given encoding."""
    if len(char) != 1:
        return False
    try:
        char.encode(encoding)
        return True
    except (UnicodeEncodeError, LookupError):
        return False


def audit_bpmf_base(file_path: Path) -> int:
    """
    Audit BPMFBase.txt for encoding category mismatches.

    Returns:
        Number of mismatches found
    """
    if not file_path.exists():
        print(f"Error: File not found: {file_path}")
        return 1

    mismatches = 0

    with open(file_path, encoding="utf-8") as f:
        for _line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            parts = line.split()
            if len(parts) != 5:
                continue

            char = parts[0]
            category = parts[4]

            # Check encoding support
            in_big5 = can_encode(char, "big5")
            in_big5hkscs = can_encode(char, "big5hkscs")
            in_cp950 = can_encode(char, "cp950")  # Alternative Big5 encoding

            # CNS 11643 is not widely supported in Python, so we check if it's NOT in Big5
            # A character in CNS category should NOT be encodable in Big5/Big5-HKSCS

            if category == "big5":
                if not (in_big5 or in_big5hkscs or in_cp950):
                    print(f"{char} is not in big5 and big5 HKSCS")
                    mismatches += 1

            elif category == "cns":
                if in_big5 or in_cp950:
                    print(f"{char} is in Big5 encoding")
                    mismatches += 1
                elif in_big5hkscs:
                    print(f"{char} is in big5 HKSCS encoding")
                    mismatches += 1

            elif category == "utf8":
                if in_big5 or in_cp950:
                    print(f"{char} is in big5 encoding")
                    mismatches += 1
                elif in_big5hkscs:
                    print(f"{char} is in big5 HKSCS encoding")
                    mismatches += 1

    return mismatches


def main():
    """Main entry point for CLI usage."""
    # Determine BPMFBase.txt path relative to script location
    script_dir = Path(__file__).parent
    bpmf_base_path = script_dir.parent / "BPMFBase.txt"

    mismatches = audit_bpmf_base(bpmf_base_path)

    if mismatches > 0:
        print(f"\nFound {mismatches} encoding category mismatch(es)")
        sys.exit(1)
    else:
        print("No encoding mismatches found")
        sys.exit(0)


if __name__ == "__main__":
    main()
