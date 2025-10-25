import argparse
import unicodedata
from collections import defaultdict
from dataclasses import dataclass

PRAGMA = "# format org.openvanilla.mcbopomofo.sorted"
MAX_ENTRIES_PER_PREFIX = 60
EMOJI_SCORE = -8.0


@dataclass
class Entry:
    reading: str
    value: str
    score: float

    _zipped_readings_and_values_computed: bool = False
    _cached_zipped_readings_and_values: list[tuple[str, str]] = None

    def associated_phrase_line(self) -> str:
        """Convert entry to associated phrase format (e.g., 四-ㄙˋ-字-ㄗˋ...)."""
        rvs = self.zipped_readings_and_values()
        if not rvs:
            return None

        if len(rvs) < 2:
            return

        parts = [f"{v}-{r}" for r, v in rvs]

        return "{} {:.4f}".format("-".join(parts), self.score)

    def zipped_readings_and_values(self) -> list[tuple[str, str]]:
        """Return readings and values zipped together (Unicode 'Lo' characters only)."""
        if self._zipped_readings_and_values_computed:
            return self._cached_zipped_readings_and_values

        self._zipped_readings_and_values_computed = True

        if self.reading.startswith("_"):
            return None

        if self.score <= EMOJI_SCORE:
            return None

        if not all(unicodedata.category(c) == "Lo" for c in self.value):
            return None

        reading_parts = self.reading.split("-")
        if len(reading_parts) != len(self.value):
            return None

        self._cached_zipped_readings_and_values = list(zip(reading_parts, self.value, strict=True))
        return self._cached_zipped_readings_and_values

    @classmethod
    def from_line(cls, line):
        reading, value, score = line.strip().split(" ")
        return cls(reading, value, float(score))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", help="source file")
    parser.add_argument("target", help="target file")
    parser.add_argument("punctuation", help="punctuation file")
    args = parser.parse_args()

    source_file = args.source
    target_file = args.target
    punctuation_file = args.punctuation

    with open(source_file) as f:
        if f.readline().strip() != PRAGMA:
            raise ValueError("Invalid source file")
        lines = [line.strip() for line in f]

    with open(punctuation_file) as f:
        punctuation_lines = [line.strip() for line in f]

    entries = [Entry.from_line(line) for line in lines[1:]]

    prefix_entry_map = defaultdict(list)

    for e in entries:
        zipped_rvs = e.zipped_readings_and_values()
        if not zipped_rvs or len(zipped_rvs) < 2:
            continue

        prefix = f"{zipped_rvs[0][1]}-{zipped_rvs[0][0]}"
        prefix_entry_map[prefix].append(e)

    output_lines = []
    keys = sorted(prefix_entry_map.keys(), key=lambda k: k.encode("utf-8"))
    for k in keys:
        entries = sorted(prefix_entry_map[k], key=lambda e: e.score, reverse=True)
        output_lines.extend([e.associated_phrase_line() for e in entries[:MAX_ENTRIES_PER_PREFIX]])

    output_lines += punctuation_lines
    byte_sorted_output_lines = sorted(output_lines, key=lambda x: x.encode("utf-8"))

    with open(target_file, "w") as f:
        print(PRAGMA, file=f)
        for line in byte_sorted_output_lines:
            print(line, file=f)


if __name__ == "__main__":
    main()
