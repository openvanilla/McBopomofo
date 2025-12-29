import argparse

from .compiler_utils import HEADER, normalize_bpmfvs_reading

PUA_START = 0xF000


def update_pua_mappings(input_path, output_path):
    with open(input_path, "r", encoding="utf-8") as f:
        pua_code = PUA_START
        mappings = []
        line_num = 0

        for line in f:
            line_num += 1
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            cols = line.split()
            if len(cols) != 3:
                raise ValueError(f"Malformed row at line {line_num}")

            bpmf_reading = normalize_bpmfvs_reading(cols[0])

            pua_code += 1
            mappings.append((bpmf_reading, chr(pua_code)))

    mappings = sorted(mappings, key=lambda x: x[0].encode("utf-8"))

    with open(output_path, "w", encoding="utf-8") as output:
        output.write(HEADER)
        for bpmf, pua in mappings:
            output.write(f"{bpmf} {pua}\n")


def main():
    parser = argparse.ArgumentParser(
        description="update the PUA mapping db from bpmfvs"
    )
    parser.add_argument(
        "--input", required=True, help="path to bpmfvs's phonic_types.txt"
    )
    parser.add_argument("--output", default="bpmfvs-pua.txt")
    args = parser.parse_args()
    update_pua_mappings(input_path=args.input, output_path=args.output)


if __name__ == "__main__":
    main()
