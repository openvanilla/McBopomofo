"""McBopomofo dictionary data curation tools.

This package provides tools for building, compiling, validating, and analyzing
dictionary data for the McBopomofo Traditional Chinese input method.

Project Path Configuration:
---------------------------
The package exports centralized path constants for consistent file access:
    >>> from curation import PROJECT_ROOT, CONFIG_FILE
    >>> print(PROJECT_ROOT)  # .../Source/Data/
    >>> print(CONFIG_FILE)   # .../Source/Data/textpool.rc

All scripts and modules should import these constants instead of computing
paths relatively.

Submodules:
-----------
builders : Data building and processing tools
    - frequency_builder: Generates frequency data from occurrence counts
    - occurrence_counter: Counts phrase occurrences in text corpus
    - phrase_deriver: Derives associated phrases from dictionary data

compilers : Data compilation tools
    - main_compiler: Main data compiler combining all source files
    - plain_bpmf_compiler: Plain BPMF data compiler for traditional mode
    - compiler_utils: Shared utilities for compilation

validators : Validation and analysis tools
    - score_validator: Validates and tests dictionary data quality
    - data_analyzer: Analyzes dictionary data and generates reports

utils : General utilities
    - bpmf_mapper: Bopomofo phonetic mapping helper
    - text_filter: Text filtering utilities for CJK characters

Usage:
------
Import specific modules:
    >>> from curation.builders import frequency_builder
    >>> from curation.compilers import main_compiler

Or import entire submodules:
    >>> from curation import builders, compilers, validators, utils

Import project paths:
    >>> from curation import PROJECT_ROOT, CONFIG_FILE
"""

__version__ = "0.1.0"

# Project path configuration
# All scripts and modules should import these constants for consistent path resolution
from pathlib import Path

# Project root is Source/Data/ directory (where pyproject.toml lives)
PROJECT_ROOT = Path(__file__).parent.parent
CONFIG_FILE = PROJECT_ROOT / "textpool.rc"

# Submodules are available but not imported to avoid side effects
# Import them explicitly when needed:
#   >>> from curation import builders
#   >>> from curation.builders import frequency_builder

__all__ = [
    "builders",
    "compilers",
    "validators",
    "utils",
    "PROJECT_ROOT",
    "CONFIG_FILE",
]
