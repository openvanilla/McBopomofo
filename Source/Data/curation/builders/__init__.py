"""Data builders and processors for McBopomofo dictionary curation.

This submodule contains library modules for building dictionary data:
- frequency_builder: Generates frequency data from occurrence counts
- phrase_deriver: Derives associated phrases from dictionary data

Note: Pure CLI scripts with side effects have been moved to scripts/ directory.
"""

__all__ = [
    "frequency_builder",
    "phrase_deriver",
]
