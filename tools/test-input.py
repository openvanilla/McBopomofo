#!/usr/bin/env python3
"""Interactive McBopomofo input testing tool.

Shows one phrase at a time with its key sequence. You type the actual output
from the input method, then it records PASS/FAIL and moves to the next.

Usage: python3 tools/test-input.py [--seed N] [--count N] [--mode smart]
"""

import random
import argparse
import sys
import json
from datetime import datetime
from pathlib import Path

BPMF_TO_KEY = {
    "ㄅ": "1", "ㄆ": "q", "ㄇ": "a", "ㄈ": "z",
    "ㄉ": "2", "ㄊ": "w", "ㄋ": "s", "ㄌ": "x",
    "ㄍ": "e", "ㄎ": "d", "ㄏ": "c",
    "ㄐ": "r", "ㄑ": "f", "ㄒ": "v",
    "ㄓ": "5", "ㄔ": "t", "ㄕ": "g", "ㄖ": "b",
    "ㄗ": "y", "ㄘ": "h", "ㄙ": "n",
    "ㄧ": "u", "ㄨ": "j", "ㄩ": "m",
    "ㄚ": "8", "ㄛ": "i", "ㄜ": "k", "ㄝ": ",",
    "ㄞ": "9", "ㄟ": "o", "ㄠ": "l", "ㄡ": ".",
    "ㄢ": "0", "ㄣ": "p", "ㄤ": ";", "ㄥ": "/",
    "ㄦ": "-",
    "ˊ": "6", "ˇ": "3", "ˋ": "4", "˙": "7",
}

CONSONANTS = set("ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙ")
TONES = set("ˊˇˋ˙")


def syllable_to_keys(s):
    return "".join(BPMF_TO_KEY.get(c, "") for c in s)


def has_consonant(s):
    return len(s) > 0 and s[0] in CONSONANTS


def has_tone(s):
    return any(c in TONES for c in s)


def strip_tone(s):
    return "".join(c for c in s if c not in TONES)


def generate_key_sequence(syllables, mode="smart"):
    keys = ""
    skipped = []
    for i, syl in enumerate(syllables):
        is_last = i == len(syllables) - 1
        next_con = not is_last and has_consonant(syllables[i + 1])
        curr_con = has_consonant(syl)
        if mode == "smart" and curr_con and next_con and not is_last:
            keys += syllable_to_keys(strip_tone(syl))
            skipped.append(syl)
        elif has_tone(syl):
            keys += syllable_to_keys(syl)
        else:
            keys += syllable_to_keys(syl) + " "
    return keys, skipped


def load_phrases(data_path):
    phrases = []
    with open(data_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or line.startswith("_") or "MACRO@" in line:
                continue
            parts = line.split(" ")
            if len(parts) < 3:
                continue
            reading, value = parts[0], parts[1]
            syllables = reading.split("-")
            n = len(value)
            if 2 <= n <= 4 and n == len(syllables):
                try:
                    score = float(parts[2])
                except ValueError:
                    continue
                if score > -8:
                    phrases.append((reading, value, syllables))
    return phrases


def has_auto_commit_point(syllables):
    for i in range(len(syllables) - 1):
        if has_consonant(syllables[i]) and has_consonant(syllables[i + 1]):
            return True
    return False


BOLD = "\033[1m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"
DIM = "\033[2m"
RESET = "\033[0m"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--count", type=int, default=20)
    parser.add_argument("--mode", choices=["smart", "full", "aggressive"], default="smart")
    parser.add_argument("--data", type=str,
                        default=str(Path(__file__).parent.parent / "Source/Data/data.txt"))
    args = parser.parse_args()

    seed = args.seed if args.seed is not None else random.randint(0, 99999)
    random.seed(seed)

    phrases = load_phrases(args.data)
    with_ac = [p for p in phrases if has_auto_commit_point(p[2])]
    without_ac = [p for p in phrases if not has_auto_commit_point(p[2])]

    n_ac = min(args.count - 5, len(with_ac))
    n_no = min(5, len(without_ac))
    selected = random.sample(with_ac, n_ac) + random.sample(without_ac, n_no)
    random.shuffle(selected)

    results = []
    passed = 0
    failed = 0
    skipped_count = 0

    print(f"\n{BOLD}McBopomofo 輸入測試{RESET}  (seed={seed}, mode={args.mode})")
    print(f"{DIM}在 TextEdit 用小麥注音打「按鍵」序列，對照期望結果。{RESET}")
    print(f"{DIM}y/Enter=正確 n=錯誤(輸入實際結果) s=跳過 q=中止{RESET}\n")

    for i, (reading, expected, syllables) in enumerate(selected, 1):
        keys, skipped_syls = generate_key_sequence(syllables, args.mode)
        reading_display = "-".join(syllables)

        print(f"{BOLD}[{i}/{len(selected)}]{RESET} 期望：{CYAN}{expected}{RESET}")
        print(f"  注音：{reading_display}")
        print(f"  按鍵：{BOLD}{keys}{RESET}")
        if skipped_syls:
            print(f"  {DIM}省聲調：{', '.join(skipped_syls)}{RESET}")

        actual = ""
        final_result = None
        try:
            ans = input(f"  {BOLD}y{RESET}=正確 / {BOLD}n{RESET}=錯誤(輸入實際結果) / {BOLD}s{RESET}=跳過 / {BOLD}q{RESET}=中止：").strip()
        except (EOFError, KeyboardInterrupt):
            print("\n中止測試。")
            results.append({"index": i, "expected": expected, "actual": "",
                            "keys": keys, "reading": reading_display,
                            "skipped_tones": [str(s) for s in skipped_syls], "result": "ABORT"})
            break

        if ans.lower() == "q":
            results.append({"index": i, "expected": expected, "actual": "",
                            "keys": keys, "reading": reading_display,
                            "skipped_tones": [str(s) for s in skipped_syls], "result": "ABORT"})
            print("中止測試。")
            break
        elif ans.lower() == "s":
            skipped_count += 1
            final_result = "SKIP"
            actual = ""
            print(f"  {YELLOW}SKIP{RESET}\n")
        elif ans.lower() == "y" or ans == expected or ans == "":
            passed += 1
            final_result = "PASS"
            actual = expected
            print(f"  {GREEN}PASS ✓{RESET}\n")
        elif ans.lower() == "n":
            try:
                actual = input(f"  實際得到：").strip()
            except (EOFError, KeyboardInterrupt):
                actual = "(未知)"
            failed += 1
            final_result = "FAIL"
            print(f"  {RED}FAIL ✗{RESET}  期望「{expected}」得到「{actual}」\n")
        else:
            # User pasted Chinese or other text — compare directly
            if ans == expected:
                passed += 1
                final_result = "PASS"
                actual = ans
                print(f"  {GREEN}PASS ✓{RESET}\n")
            else:
                failed += 1
                final_result = "FAIL"
                actual = ans
                print(f"  {RED}FAIL ✗{RESET}  期望「{expected}」得到「{actual}」\n")

        results.append({
            "index": i,
            "expected": expected,
            "actual": actual,
            "keys": keys,
            "reading": reading_display,
            "skipped_tones": [str(s) for s in skipped_syls],
            "result": final_result,
        })

    # Summary
    total = passed + failed + skipped_count
    print(f"\n{BOLD}=== 結果 ==={RESET}")
    print(f"  {GREEN}PASS: {passed}{RESET}  {RED}FAIL: {failed}{RESET}  {YELLOW}SKIP: {skipped_count}{RESET}  Total: {total}/{len(selected)}")

    if failed > 0:
        print(f"\n{RED}{BOLD}失敗項目：{RESET}")
        for r in results:
            if r["result"] == "FAIL":
                print(f"  #{r['index']} 期望「{r['expected']}」→「{r['actual']}」  按鍵: {r['keys']}  注音: {r['reading']}")

    # Save results
    outfile = Path(__file__).parent.parent / "docs" / f"test-results-{datetime.now():%Y%m%d-%H%M%S}.json"
    outfile.parent.mkdir(exist_ok=True)
    report = {
        "timestamp": datetime.now().isoformat(),
        "seed": seed,
        "mode": args.mode,
        "summary": {"pass": passed, "fail": failed, "skip": skipped_count, "total": len(selected)},
        "results": results,
    }
    with open(outfile, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    print(f"\n{DIM}結果已存到 {outfile}{RESET}")


if __name__ == "__main__":
    main()
