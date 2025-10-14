"""Data compilers for McBopomofo dictionary.

This submodule contains tools for compiling dictionary data:
- main_compiler: Main data compiler that combines all source files
- plain_bpmf_compiler: Plain BPMF data compiler for traditional mode
- compiler_utils: Shared utilities for compilation

Note: Modules are not imported at package level to avoid side effects.
Import them explicitly when needed:
    >>> from curation.compilers import main_compiler
"""

__all__ = [
    "main_compiler",
    "plain_bpmf_compiler",
    "compiler_utils",
]
