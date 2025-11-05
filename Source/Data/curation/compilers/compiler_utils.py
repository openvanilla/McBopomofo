__author__ = "Lukhnos Liu and The McBopomofo Authors"
__copyright__ = "Copyright 2022 and onwards The McBopomofo Authors"
__license__ = "MIT"


HEADER = "# format org.openvanilla.mcbopomofo.sorted\n"


def convert_vks_rows_to_sorted_kvs_rows(
    vks_rows: list[tuple[str, str, float | str]],
) -> list[tuple[str, str, str]]:
    """Convert value-key-score rows to key-value-score rows, sorted by key."""
    key_to_vss = {}

    for value, key, score in vks_rows:
        if type(score) is float:
            score = f"{score:f}"

        if key not in key_to_vss:
            key_to_vss[key] = []

        key_to_vss[key].append((value, score))

    keys = sorted(key_to_vss.keys(), key=lambda k: k.encode("utf-8"))

    output = []
    for key in keys:
        vs_rows = sorted(key_to_vss[key], key=lambda vs: float(vs[1]), reverse=True)
        for vs_row in vs_rows:
            output.append((key, vs_row[0], vs_row[1]))

    return output
