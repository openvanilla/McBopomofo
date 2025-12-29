import argparse

from .compiler_utils import HEADER, normalize_bpmfvs_reading

# Max 7 variants are recorded (variants 0-6) according to bpmfvs's make_font.rb
MAX_VARIANTS = 7

NO_ANNOTATION_SUFFIX = "na"

# bpmfvs's fonts are created so that:
#   character without IVS = the character with the primary Bopomofo annotation
#   character with IVS 0 = the character WITHOUT any Bopomofo annotation
#   character with IVS n = the character with the n-th heterophonic annotation
IVS_START = 0xE01E0


def update_variant_mappings(
    input_path, bpmf_base_path, bpmf_mappings_path, output_path
):
    supported_characters = set()
    supported_bpmf_readings = {}
    variant_mappings = {}
    output_lines = []

    with open(bpmf_base_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            cols = line.split()
            if len(cols) < 2:
                continue

            character = cols[0]
            supported_characters.add(character)

            reading = cols[1]
            if character in supported_bpmf_readings:
                supported_bpmf_readings[character].add(reading)
            else:
                supported_bpmf_readings[character] = {reading}

    # BPMFMappings.txt is needed because some phrases, such as 南 read as ㄋㄚˊ
    # (which is from Sanskrit), are only read thay way and are only found in
    # that file, not BPMFBase.txt.
    with open(bpmf_mappings_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            cols = line.split()
            if len(cols) < 2:
                continue

            values = cols[0]
            readings = cols[1:]
            if len(values) != len(readings):
                raise ValueError(
                    f"Malformed BPMFMappings, mismatched reading count at line: {line}"
                )

            for character, reading in zip(values, readings):
                if character not in supported_characters:
                    # Don't add anything such as Japanese kanjis not found in
                    # BPMFBase.txt, since those don't have Bopomofo
                    # annotations in bpmfvs's fonts.
                    continue

                if character in supported_bpmf_readings:
                    supported_bpmf_readings[character].add(reading)
                else:
                    supported_bpmf_readings[character] = {reading}

    with open(input_path, "r", encoding="utf-8") as f:
        line_num = 0
        for line in f:
            line_num += 1
            line = line.strip()
            if not line or line.startswith("#"):
                continue

            row = line.split()
            if len(row) < 4:
                raise ValueError(f"Malformed row at line {line_num}")

            character = row[0]
            readings = row[3:]
            normalized_readings = [normalize_bpmfvs_reading(r) for r in readings if r]

            if character in variant_mappings:
                variant_mappings[character].extend(normalized_readings)
            else:
                variant_mappings[character] = normalized_readings

    with open(output_path, "w", encoding="utf-8") as output:
        for character, readings in variant_mappings.items():
            for variant_index, reading in enumerate(readings):
                if variant_index >= MAX_VARIANTS:
                    print(f"Skipping extra variant {variant_index} for {character}")
                    continue

                # If not listed in BPMFBase.txt, skip.
                if not (
                    character in supported_bpmf_readings
                    and reading in supported_bpmf_readings[character]
                ):
                    continue

                ivs_codepoint = IVS_START + variant_index
                ivs_char = chr(ivs_codepoint)

                if variant_index == 0:
                    # Base character mapping.
                    output_lines.append(f"{character}-{reading} {character}\n")

                    # Add Variant 0 to the db file too.
                    #
                    # Adding "$char-unk" for future-proofing, so that if a user
                    # "defines" a previouly unseen reading, Variant 0 can be used
                    # with an additional pre-composed Bopomofo annotation block
                    # from bpmfvs's fonts' PUA area to complete the character.
                    output_lines.append(
                        f"{character}-{NO_ANNOTATION_SUFFIX} {character}{ivs_char}\n")
                else:
                    output_lines.append(
                        f"{character}-{reading} {character}{ivs_char}\n"
                    )
        output_lines = sorted(output_lines, key=lambda x: x.encode("utf-8"))
        output.write(HEADER)
        output.writelines(output_lines)


def main():
    parser = argparse.ArgumentParser(
        description="update the reading-annotation variants db from bpmfvs"
    )
    parser.add_argument(
        "--input", required=True, help="path to bpmfvs's phonic_table_Z.txt"
    )
    parser.add_argument(
        "--bpmf_base", required=True, help="path to McBopomofo's BPMFBase.txt"
    )
    parser.add_argument(
        "--bpmf_mappings", required=True, help="path to McBopomofo's BPMFMappings.txt"
    )
    parser.add_argument("--output", default="bpmfvs-variants.txt")
    args = parser.parse_args()
    update_variant_mappings(
        input_path=args.input,
        bpmf_base_path=args.bpmf_base,
        bpmf_mappings_path=args.bpmf_mappings,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
