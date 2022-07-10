with open('data.txt') as f:
    lines = f.readlines()

data = [ln.strip().split(' ') for ln in lines[1:] if not ln.startswith('_')]

data = [(d[0].split('-'), d[1], float(d[2])) for d in data]

unigram_1char = {}
value_to_score = {}

unigram_1char_count = 0
unigram_multichar_count = 0

for (r, v, s) in data:
    # Skip emojis.
    if s == -8:
        continue

    if v in value_to_score:
        if s > value_to_score[v]:
            value_to_score[v] = s
    else:
        value_to_score[v] = s

    if len(r) > 1:
        unigram_multichar_count += 1
        continue
    unigram_1char_count += 1

    k = r[0]
    if k in unigram_1char:
        if s > unigram_1char[k][1]:
            unigram_1char[k] = (v, s)
    else:
        unigram_1char[k] = (v, s)

faulty = []
indifferents = []
insufficients = []
competing_unigrams = []

for (r, v, s) in data:
    if len(r) < 2:
        continue

    # Skip all emojis.
    if s == -8:
        continue

    comp = []
    ts = 0
    bad = False
    for x in r:
        if x not in unigram_1char:
            bad = True
            break

        uv, us = unigram_1char[x]
        ts += us
        comp.append((uv, us))

    if bad:
        faulty.append((r, v))
        continue

    if ts >= s:
        i = (r, v, s, comp, (s - ts))

        k = ''.join([x[0] for x in comp])

        if v == k:
            indifferents.append(i)
        else:
            if k in value_to_score and v != k:
                if s < value_to_score[k]:
                    competing_unigrams.append((v, s, k, value_to_score[k]))
            insufficients.append(i)

insufficients = sorted(insufficients, key=lambda i: i[2], reverse=True)
competing_unigrams = sorted(
    competing_unigrams, key=lambda i: i[1] - i[3], reverse=True)

separator = '-' * 72
print(separator)
print('%6d unigrams with one character' % unigram_1char_count)
print('%6d unigrams with multiple characters' % unigram_multichar_count)

print(separator)
print('summary for unigrams with scores lower than their competing characters:')
print('%6d unigrams that are indifferent since the characters are the same' %
      len(indifferents))
print('%6d unigrams that are not the top candidate (%.1f%% of unigrams)' %
      (len(insufficients),
       len(insufficients) / float(unigram_multichar_count) * 100.0))
print('\nof which:')

insufficients_map = {}
for x in range(2, 7):
    insufficients_map[x] = [i for i in insufficients if len(i[0]) == x]

print('  %6d 2-character unigrams' % len(insufficients_map[2]))
print('  %6d 3-character unigrams' % len(insufficients_map[3]))
print('  %6d 4-character unigrams' % len(insufficients_map[4]))
print('  %6d 5-character unigrams' % len(insufficients_map[5]))
print('  %6d 6-character unigrams' % len(insufficients_map[6]))

print(separator)
print('top insufficient 2-character unigrams')
for i in insufficients_map[2][:25]:
    print(i)

print(separator)
print('all insufficient 3-character unigrams')
for i in insufficients_map[3]:
    print(i)

print(separator)
print('%d unigrams also compete with unigrams from top composing characters' %
      len(competing_unigrams))
print('some samples:')
for i in competing_unigrams[:25]:
    print(i)

if faulty:
    print(separator)
    print('The following unigrams cannot be typed:')
    for f in faulty:
        print(f)
