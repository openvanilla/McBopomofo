def check_if_bpmf_mappings_matches():
    issues = []
    with open("BPMFMappings.txt", encoding="utf-8") as f:
        for line in f:
            components = line.strip().split(" ")
            first = components[0]
            if len(first) != len(components) - 1:
                issues.append(f"Length mismatch: {line.strip()}")
    return issues

def check_if_readings_in_bpmf_mappings_contains_non_bpmf():
    issues = []
    bpmf = (
        "ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦㄧㄨㄩˊˇˋ˙"
    )
    with open("BPMFMappings.txt", encoding="utf-8") as f:
        for line in f:
            components = line.strip().split()[1:]
            for c in components:
                if any(char not in bpmf for char in c):
                    issues.append(f"Non bpmf {c} in {line.strip()}")
                    break
    return issues

def compare_bpmf_mappings_with_phrase_occ():
    issues = []
    bpmf_mappings_phrases = set()
    phrase_occ_phrases = set()
    with open("BPMFMappings.txt", encoding="utf-8") as f:
        for line in f:
            components = line.strip().split(" ")
            first = components[0]
            if len(first) > 1:
                bpmf_mappings_phrases.add(first)
    with open("phrase.occ", encoding="utf-8") as f:
        for line in f:
            components = line.strip().split(" ")
            first = components[0]
            if len(first) > 1:
                phrase_occ_phrases.add(first)
    missing_in_phrase_occ = bpmf_mappings_phrases - phrase_occ_phrases
    missing_in_bpmf_mappings = phrase_occ_phrases - bpmf_mappings_phrases
    if missing_in_phrase_occ:
        issues.append(f"Missing in phrase.occ: {missing_in_phrase_occ}")
    if missing_in_bpmf_mappings:
        issues.append(f"Missing in BPMFMappings.txt: {missing_in_bpmf_mappings}")
    return issues


def main():
    all_issues = []
    all_issues.extend(check_if_bpmf_mappings_matches())
    all_issues.extend(check_if_readings_in_bpmf_mappings_contains_non_bpmf())
    all_issues.extend(compare_bpmf_mappings_with_phrase_occ())

    for issue in all_issues:
        print(issue)

    if all_issues:
        raise RuntimeError(f"Data check failed with {len(all_issues)} issue(s).")

if __name__ == "__main__":
    main()
