import math
from dataclasses import dataclass


@dataclass
class Node:
    reading: str
    value: str
    score: float


@dataclass
class State:
    from_column: int = 0
    from_node: Node | None = None
    max_score: float = -math.inf


MAX_SPAN_LEN = 8


def most_plausible_walk(
    readings: list[str],
    langmodel: dict[str, list[tuple[str, str | float]]],
    separator: str = "-",
) -> list[Node]:

    rlen = len(readings)

    # Build a grid of rlen columns, each column having MAX_SPAN_LEN spans.
    grid: list[list[Node | None]] = [
        [None for _ in range(MAX_SPAN_LEN)] for _ in range(rlen)
    ]

    for span_from in range(rlen):
        span_to = min(span_from + MAX_SPAN_LEN, rlen)
        span_len = span_to - span_from

        for i in range(span_len):
            reading = separator.join(readings[span_from : span_from + i + 1])

            if i == 0 and not langmodel.get(reading):
                raise ValueError("single-syllable reading must have unigrams")

            unigrams = langmodel.get(reading)
            if not unigrams:
                continue

            # Put the highest-ranked unigram in the grid
            value, score = unigrams[0]

            # Allows score to be string to minimize diffs from roundtripping
            grid[span_from][i] = Node(reading, value, float(score))

    viterbi_states = [State() for _ in range(rlen + 1)]

    viterbi_states[0].max_score = 0

    for i in range(rlen):
        spans = grid[i]

        for j in range(MAX_SPAN_LEN):
            node = spans[j]

            # No span for this length, and that's fine. We guarantee
            # single-syllable readings always have their spans so this
            # must not fail when j == 0.
            if not node:
                continue

            score = viterbi_states[i].max_score + node.score
            target = viterbi_states[i + j + 1]
            if score > target.max_score:
                target.max_score = score
                target.from_node = node
                target.from_column = i

    i = rlen
    walked: list[Node] = []
    while i > 0:
        node = viterbi_states[i].from_node
        assert node is not None
        walked.insert(0, node)
        i = viterbi_states[i].from_column

    return walked
