from . import components


def bopomofo_to_component_code(bopomofo_string):
    code = 0
    for char in bopomofo_string:
        if char in components.BOPOMOFO_TO_COMPONENT:
            code |= components.BOPOMOFO_TO_COMPONENT[char]
        else:
            raise ValueError(f"Unknown Bopomofo character: {char}")
    return code


def component_code_to_bopomofo(code):
    bopomofo_chars = []

    consonant = code & components.CONSONANT_MASK
    medial = code & components.MEDIAL_MASK
    rhyme = code & components.RHYME_MASK
    tone = code & components.TONE_MASK

    if consonant:
        bopomofo_chars.append(components.COMPONENT_TO_BOPOMOFO[consonant])
    if medial:
        bopomofo_chars.append(components.COMPONENT_TO_BOPOMOFO[medial])
    if rhyme:
        bopomofo_chars.append(components.COMPONENT_TO_BOPOMOFO[rhyme])
    if tone:
        bopomofo_chars.append(components.COMPONENT_TO_BOPOMOFO[tone])
    return "".join(bopomofo_chars)


def bopomofo_to_compact_representation(bopomofo_string):
    code = bopomofo_to_component_code(bopomofo_string)
    compact = (
        (code & components.CONSONANT_MASK)
        + ((code & components.MEDIAL_MASK) >> 5) * 22
        + ((code & components.RHYME_MASK) >> 7) * 22 * 4
        + ((code & components.TONE_MASK) >> 11) * 22 * 4 * 14
    )
    low = chr(48 + (compact % 79))
    high = chr(48 + (compact // 79))
    return low + high


def compact_representation_to_bopomofo(compact_string):
    if len(compact_string) != 2:
        raise ValueError("Compact representation must be 2 characters long.")
    compact = (ord(compact_string[1]) - 48) * 79 + (ord(compact_string[0]) - 48)
    consonant = compact % 22
    medial = ((compact // 22) % 4) << 5
    rhyme = ((compact // (22 * 4)) % 14) << 7
    tone = ((compact // (22 * 4 * 14)) % 5) << 11
    code = consonant | medial | rhyme | tone
    return component_code_to_bopomofo(code)
