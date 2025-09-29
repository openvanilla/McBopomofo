---
applyTo: "Source/Data/*"
---

These files define the mapping of phrases and words to their Bopomofo representations.

In most cases, developers will add new Chinese characters or phrases rather than delete existing ones. When adding new characters or phrases, please perform the following checks:

## Heterophonic Characters

When adding a new entry—such as a character with a Bopomofo reading—into `BPMFMappings.txt`, check if there is already an entry for the same character with a different Bopomofo reading. If so, this indicates a heterophonic character, and you should review the frequency of each reading.

Often, the new reading will be much less common than the existing one. In such cases, add a comment to indicate that this is a heterophonic character and note the frequency of each reading.

To reflect the lower frequency of the new reading, place the default reading in `heterophony1.list` and the new reading in `heterophony2.list`, and so on.

## Emojis and Symbols

We allow users to input emojis and symbols using Bopomofo. For example, when inputting ㄒㄧㄣ, we have 心 and ❤️‍🔥 in the candidate list. However, emojis and symbols should not be the default candidate of a given Bopomofo reading.
