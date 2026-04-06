#!/usr/bin/env python3
"""Generate random test cases for McBopomofo abbreviated/auto-commit input testing.

Picks 20 random phrases (2-4 characters) from the dictionary and generates
the key sequence needed to type them, with some syllables missing tone markers
to test the auto-commit and toneless expansion features.

Usage: python3 tools/generate-test-cases.py [--seed N] [--count N]
"""

import random
import argparse
import sys
from pathlib import Path

# Standard Bopomofo keyboard layout mapping (composedString -> key sequence)
BPMF_TO_KEY = {
    # Consonants
    "ㄅ": "1", "ㄆ": "q", "ㄇ": "a", "ㄈ": "z",
    "ㄉ": "2", "ㄊ": "w", "ㄋ": "s", "ㄌ": "x",
    "ㄍ": "e", "ㄎ": "d", "ㄏ": "c",
    "ㄐ": "r", "ㄑ": "f", "ㄒ": "v",
    "ㄓ": "5", "ㄔ": "t", "ㄕ": "g", "ㄖ": "b",
    "ㄗ": "y", "ㄘ": "h", "ㄙ": "n",
    # Middle vowels
    "ㄧ": "u", "ㄨ": "j", "ㄩ": "m",
    # Vowels
    "ㄚ": "8", "ㄛ": "i", "ㄜ": "k", "ㄝ": ",",
    "ㄞ": "9", "ㄟ": "o", "ㄠ": "l", "ㄡ": ".",
    "ㄢ": "0", "ㄣ": "p", "ㄤ": ";", "ㄥ": "/",
    "ㄦ": "-",
    # Tones
    "ˊ": "6", "ˇ": "3", "ˋ": "4", "˙": "7",
}

# Consonant characters for detecting auto-commit points
CONSONANTS = set("ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙ")
TONES = set("ˊˇˋ˙")


def syllable_to_keys(syllable: str) -> str:
    """Convert a composed bopomofo syllable to key sequence."""
    keys = ""
    i = 0
    while i < len(syllable):
        # Try matching longest first (all are single chars in this case)
        ch = syllable[i]
        if ch in BPMF_TO_KEY:
            keys += BPMF_TO_KEY[ch]
        i += 1
    return keys


def has_consonant(syllable: str) -> bool:
    """Check if a syllable starts with a consonant."""
    return len(syllable) > 0 and syllable[0] in CONSONANTS


def has_tone(syllable: str) -> bool:
    """Check if a syllable has an explicit tone marker."""
    return any(c in TONES for c in syllable)


def get_tone_char(syllable: str) -> str:
    """Get the tone character from a syllable, or empty string."""
    for c in syllable:
        if c in TONES:
            return c
    return ""


def strip_tone(syllable: str) -> str:
    """Remove tone marker from a syllable."""
    return "".join(c for c in syllable if c not in TONES)


def generate_key_sequence(syllables: list[str], skip_tone_mode: str = "smart") -> tuple[str, str]:
    """Generate key sequence with selective tone omission.

    skip_tone_mode:
      - "full": type all tones (baseline test)
      - "smart": skip tones where auto-commit would trigger (consonant→consonant)
      - "aggressive": skip all tones except last syllable

    Returns (key_sequence, annotation) where annotation describes what was skipped.
    """
    keys = ""
    annotations = []

    for i, syllable in enumerate(syllables):
        is_last = (i == len(syllables) - 1)
        next_has_consonant = (not is_last and has_consonant(syllables[i + 1]))
        curr_has_consonant = has_consonant(syllable)
        tone = get_tone_char(syllable)

        if skip_tone_mode == "full":
            # Type everything including tones, use space for 1st tone
            if has_tone(syllable):
                keys += syllable_to_keys(syllable)
            else:
                keys += syllable_to_keys(syllable) + " "
        elif skip_tone_mode == "smart":
            # Skip tone only when: current has consonant AND next starts with consonant
            if curr_has_consonant and next_has_consonant and not is_last:
                keys += syllable_to_keys(strip_tone(syllable))
                annotations.append(f"{syllable}→省聲調")
            elif has_tone(syllable):
                keys += syllable_to_keys(syllable)
            else:
                keys += syllable_to_keys(syllable) + " "
        elif skip_tone_mode == "aggressive":
            if is_last:
                if has_tone(syllable):
                    keys += syllable_to_keys(syllable)
                else:
                    keys += syllable_to_keys(syllable) + " "
            else:
                keys += syllable_to_keys(strip_tone(syllable))
                if tone:
                    annotations.append(f"{syllable}→省{tone}")

    return keys, ", ".join(annotations) if annotations else "全部有聲調"


def load_phrases(data_path: str) -> list[tuple[str, str, list[str]]]:
    """Load phrases from data.txt.

    Returns list of (reading, value, syllables) where syllables is the split reading.
    """
    phrases = []
    with open(data_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or line.startswith("_"):
                continue
            if "MACRO@" in line:
                continue
            parts = line.split(" ")
            if len(parts) < 3:
                continue
            reading, value, score = parts[0], parts[1], parts[2]
            syllables = reading.split("-")
            char_count = len(value)
            # Only phrases with 2-4 characters, matching syllable count
            if 2 <= char_count <= 4 and char_count == len(syllables):
                try:
                    score_val = float(score)
                except ValueError:
                    continue
                # Filter for reasonably common phrases (score > -8)
                if score_val > -8:
                    phrases.append((reading, value, syllables))
    return phrases


def has_auto_commit_point(syllables: list[str]) -> bool:
    """Check if this phrase has at least one consonant→consonant boundary."""
    for i in range(len(syllables) - 1):
        if has_consonant(syllables[i]) and has_consonant(syllables[i + 1]):
            return True
    return False


def main():
    parser = argparse.ArgumentParser(description="Generate McBopomofo test cases")
    parser.add_argument("--seed", type=int, default=None, help="Random seed")
    parser.add_argument("--count", type=int, default=20, help="Number of test cases")
    parser.add_argument("--data", type=str,
                        default=str(Path(__file__).parent.parent / "Source/Data/data.txt"),
                        help="Path to data.txt")
    parser.add_argument("--mode", choices=["smart", "full", "aggressive"], default="smart",
                        help="Tone skipping mode")
    args = parser.parse_args()

    if args.seed is not None:
        random.seed(args.seed)
    else:
        seed = random.randint(0, 99999)
        random.seed(seed)
        print(f"Seed: {seed}\n")

    phrases = load_phrases(args.data)
    if not phrases:
        print("Error: no phrases found", file=sys.stderr)
        sys.exit(1)

    # Prefer phrases with auto-commit points
    with_ac = [p for p in phrases if has_auto_commit_point(p[2])]
    without_ac = [p for p in phrases if not has_auto_commit_point(p[2])]

    # Pick ~15 with auto-commit points, ~5 without (as baseline)
    n_ac = min(args.count - 5, len(with_ac))
    n_no_ac = min(5, len(without_ac))
    if n_ac + n_no_ac < args.count:
        n_ac = min(args.count - n_no_ac, len(with_ac))

    selected = random.sample(with_ac, n_ac) + random.sample(without_ac, n_no_ac)
    random.shuffle(selected)

    print(f"# McBopomofo Auto-commit Test Cases (mode: {args.mode})")
    print(f"# {len(selected)} phrases, {n_ac} with auto-commit points")
    print()
    print(f"| # | 期望 | 按鍵 | 注音 | 省略 | 實際結果 |")
    print(f"|---|------|------|------|------|----------|")

    for i, (reading, value, syllables) in enumerate(selected, 1):
        keys, annotation = generate_key_sequence(syllables, args.mode)
        reading_display = "-".join(syllables)
        print(f"| {i} | {value} | `{keys}` | {reading_display} | {annotation} | |")

    print()
    print("## 使用方式")
    print("1. 安裝最新 build 的 McBopomofo")
    print("2. 切換到小麥注音輸入法")
    print("3. 逐一輸入「按鍵」欄的鍵序")
    print("4. 在「實際結果」欄填入輸出")
    print("5. 比對「期望」與「實際結果」，標記 PASS/FAIL")


if __name__ == "__main__":
    main()
