"""Data compilers for McBopomofo dictionary.

This submodule contains tools for compiling dictionary data:
- compiler_utils: Shared utilities for compilation
- main_compiler: Main data compiler that combines all source files
- plain_bpmf_compiler: Plain BPMF data compiler for traditional mode
- update_bpmfvs_pua_db: Update PUA mapping database from bpmfvs
- update_bpmfvs_variant_db: Update the variants database from bpmfvs

Note: Modules are not imported at package level to avoid side effects.
Import them explicitly when needed:
    >>> from curation.compilers import main_compiler
"""

__all__ = [
    "compiler_utils",
    "main_compiler",
    "plain_bpmf_compiler",
    "update_bpmfvs_pua_db",
    "update_bpmfvs_variant_db",
]
