#!/usr/bin/env python3
import argparse
import sys

from .compiler_utils import HEADER, convert_vks_rows_to_sorted_kvs_rows

__author__ = "Mengjuei Hsieh and The McBopomofo Authors"
__copyright__ = "Copyright 2012 and onwards The McBopomofo Authors"
__license__ = "MIT"

UNK_LOG_FREQ = -99.0
H_DEFLT_FREQ = -6.8

bpmf_chars = {}
bpmf_phrases = {}
phrases = {}
bpmf_phon1 = {}
bpmf_phon2 = {}
bpmf_phon3 = {}
bpmf_hetero = {}


def cook(
    heterophony1_path,
    heterophony2_path,
    heterophony3_path,
    phrase_freq_path,
    bpmf_mappings_path,
    bpmf_base_path,
    punctuations_path,
    symbols_path,
    macros_path,
    output_path,
):
    try:
        handle = open(heterophony1_path, "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == "#":
            continue
        elements = line.rstrip().split()
        # if elements[0] in bpmf_hetero: break
        bpmf_phon1[elements[0]] = elements[1]
    handle.close()
    try:
        handle = open(heterophony2_path, "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == "#":
            continue
        elements = line.rstrip().split()
        # if elements[0] in bpmf_hetero: break
        bpmf_phon2[elements[0]] = elements[1]
    handle.close()
    try:
        handle = open(heterophony3_path, "r")
    except IOError as e:
        print("({})".format(e))
    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == "#":
            continue
        elements = line.rstrip().split()
        # if elements[0] in bpmf_hetero: break
        bpmf_phon3[elements[0]] = elements[1]
    handle.close()
    # bpmfbase
    handle = open(bpmf_base_path, "r")
    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == "#":
            continue
        elements = line.rstrip().split()
        mytype = elements[4]
        mykey = elements[0]
        myvalue = elements[1]
        # print mykey
        if mykey in bpmf_chars:
            bpmf_chars[mykey].append(myvalue)
        else:
            bpmf_chars[mykey] = []
            bpmf_chars[mykey].append(myvalue)
        if mykey in bpmf_phrases:
            bpmf_phrases[mykey].append(myvalue)
        else:
            bpmf_phrases[mykey] = []
            bpmf_phrases[mykey].append(myvalue)
    handle.close()
    # bpmf-mappings
    handle = open(bpmf_mappings_path, "r")
    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == "#":
            continue
        elements = line.rstrip().split()
        mykey = elements.pop(0)
        myvalue = "-".join(elements)
        # print mykey
        # print myvalue
        if mykey in bpmf_phrases:
            bpmf_phrases[mykey].append(myvalue)
        else:
            bpmf_phrases[mykey] = []
            bpmf_phrases[mykey].append(myvalue)
    handle.close()
    # phrase-freqs
    handle = open(phrase_freq_path, "r")

    output = []

    # Populate phrases dict with entries from BPMFBase.txt first: this is so
    # that the resulting phrases dict will maintain the order from
    # BPMFBase.txt; this is important for rarely used characters.
    for key in bpmf_chars:
        phrases[key] = UNK_LOG_FREQ

    while True:
        line = handle.readline()
        if not line:
            break
        if line[0] == "#":
            continue
        elements = line.rstrip().split()
        mykey = elements.pop(0)
        myvalue = elements.pop(0)
        try:
            readings = bpmf_phrases[mykey]
        except:
            sys.exit("[ERROR] %s key mismatches." % mykey)
        phrases[mykey] = myvalue

    for mykey, myvalue in phrases.items():
        readings = bpmf_phrases.get(mykey)

        if readings:
            # 剛好一個中文字字的長度目前還是 3 (標點、聲調好像都是2)
            if len(mykey) > 3:
                for r in readings:
                    output.append((mykey, r, myvalue))
                    pass
                continue
            else:
                # lookup the table from canonical list
                for r in readings:
                    if mykey not in bpmf_phon1:
                        output.append((mykey, r, myvalue))
                        continue
                    elif str(bpmf_phon1[mykey]) == r:
                        output.append((mykey, r, myvalue))
                        continue
                    elif mykey not in bpmf_phon2:
                        output.append((mykey, r, H_DEFLT_FREQ))
                        continue
                    elif str(bpmf_phon2[mykey]) == r:
                        # l(3/4) = -0.28768207245178 / 頻率打七五折之意
                        # l(1/2) = -0.69314718055994 / 頻率打五折之意
                        if float(myvalue) - 0.69314718055994 > H_DEFLT_FREQ:
                            output.append((mykey, r, float(myvalue) - 0.69314718055994))
                            continue
                        else:
                            output.append((mykey, r, H_DEFLT_FREQ))
                            continue
                    elif mykey not in bpmf_phon3:
                        output.append((mykey, r, H_DEFLT_FREQ))
                        continue
                    elif str(bpmf_phon3[mykey]) == r:
                        # l(3/4*3/4) = -0.28768207245178*2
                        # l(1/2*1/2) = -0.69314718055994*2
                        if float(myvalue) - 0.69314718055994 * 2 > H_DEFLT_FREQ:
                            output.append(
                                (mykey, r, float(myvalue) - 0.69314718055994 * 2)
                            )
                            continue
                        else:
                            output.append((mykey, r, H_DEFLT_FREQ))
                            continue
                    output.append((mykey, r, H_DEFLT_FREQ))
                    # 如果是破音字, set it to default.
                    # 很罕用的注音建議不要列入 heterophony?.list，這樣的話
                    # 就可以直接進來這個 condition
    handle.close()

    with open(punctuations_path) as punctuations_file:
        for line in punctuations_file:
            row = line.rstrip().split(" ")
            assert len(row) == 3
            output.append(tuple(row))

    with open(symbols_path) as symbols_file:
        for line in symbols_file:
            row = line.rstrip().split(" ")
            assert len(row) == 3, row
            output.append(tuple(row))

    with open(macros_path) as macro_file:
        for line in macro_file:
            row = line.rstrip().split(" ")
            assert len(row) == 3, row
            output.append(tuple(row))

    output = convert_vks_rows_to_sorted_kvs_rows(output)
    with open(output_path, "w") as fout:
        fout.write(HEADER)

        for row in output:
            if type(row[-1]) is float:
                fout.write("%s %s %f\n" % row)
            else:
                fout.write("%s %s %s\n" % row)


def main():
    parser = argparse.ArgumentParser(description="cook phrases database")
    parser.add_argument("--heterophony1", required=True)
    parser.add_argument("--heterophony2", required=True)
    parser.add_argument("--heterophony3", required=True)
    parser.add_argument("--phrase_freq", required=True)
    parser.add_argument("--bpmf_mappings", required=True)
    parser.add_argument("--bpmf_base", required=True)
    parser.add_argument("--punctuations", required=True)
    parser.add_argument("--symbols", required=True)
    parser.add_argument("--macros", required=True)
    parser.add_argument("--output", required=True)

    args = parser.parse_args()
    cook(
        heterophony1_path=args.heterophony1,
        heterophony2_path=args.heterophony2,
        heterophony3_path=args.heterophony3,
        phrase_freq_path=args.phrase_freq,
        bpmf_mappings_path=args.bpmf_mappings,
        bpmf_base_path=args.bpmf_base,
        punctuations_path=args.punctuations,
        symbols_path=args.symbols,
        macros_path=args.macros,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
