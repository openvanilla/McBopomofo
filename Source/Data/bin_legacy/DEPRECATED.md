# DEPRECATED: Legacy bin/ Tools

**Deprecation Date**: October 2024
**Reason**: Migrated to modern Python package structure

## Migration Status

All active Python tools have been migrated to the new `curation/` package structure with centralized path configuration. This directory preserves 13+ years of tool evolution (2012-2025) for historical reference.

## Migration Map

### Active Python Tools → `curation/` Package

| Legacy Tool | New Location | Notes |
|------------|--------------|-------|
| `cook.py` | `curation/compilers/main_compiler.py` | Main compiler |
| `cook_util.py` | `curation/compilers/compiler_utils.py` | Utility functions |
| `cook-plain-bpmf.py` | `curation/compilers/plain_bpmf_compiler.py` | Plain BPMF mode compiler |
| `buildFreq.py` | `curation/builders/frequency_builder.py` | Frequency builder |
| `derive_associated_phrases.py` | `curation/builders/phrase_deriver.py` | Associated phrases v2 |
| `self-score-test.py` | `curation/validators/score_validator.py` | Quality validation |
| `nonCJK_filter.py` | `curation/utils/text_filter.py` | Text filtering utility |

### CLI Scripts → `scripts/` Directory

| Legacy Tool | New Location | Notes |
|------------|--------------|-------|
| `count.occurrence.py` | `scripts/count_occurrences.py` | Phrase occurrence counter |
| `bpmfmap.py` | `scripts/map_bpmf.py` | BPMF mapping helper |
| Analysis tools | `scripts/analyze_data.py` | Data quality analysis |

### Configuration
- `textpool.rc` → `textpool.rc` (moved to Data/ root)

## Tools Preserved in bin_legacy/

### 🔧 Encoding Audit Tool (Active)
- **File**: `audit_encoding.swift`
- **Purpose**: Validates Big5/CNS/UTF-8 character encoding categories in BPMFBase.txt
- **Usage**: `swift audit_encoding.swift` (from bin_legacy/ directory)
- **Status**: ✅ **Still usable** - Standalone utility, not yet migrated

### 🚀 C Implementation (`C_Version/`)
- **Purpose**: Fast single-phrase occurrence counting in text corpus
- **Usage**: `C_Version/count.bash <phrase>`
- **Status**: ⚠️ **Phased out** - Superseded by Python implementation
- **Note**: Kept for performance comparison and historical reference

### 📦 Sample Preparation (`Sample_Prep/`)
- **Purpose**: Training corpus preparation and filtering
- **Status**: 📚 **Historical reference** - Documents corpus processing methodology

### 🗄️ Disabled Scripts (`disabled/`)
Legacy implementations in multiple languages (Perl, Ruby, Bash).
- **Purpose**: Historical record of implementation evolution
- **Status**: 🔒 **Archived** - Preserved for reference only

## Tool Evolution History

### Phase 1: Multi-Language Era (2005-2012)
- Tools in Perl, Ruby, Bash
- See `disabled/` for original implementations

### Phase 2: Python Migration (2012-2013)
- **2012-08-06** (commit ae062b5): `cook.py` replaced `cook.rb` (Ruby → Python) by Mengjuei Hsieh
- **2012-09-16** (commit 4165346): `buildFreq.py` replaced bash version by Mengjuei Hsieh
- **2013-01-02** (commit afbeea3): `self-score-test.py` added for quality assurance by Mengjuei Hsieh
- **2013-01-21** (commit 765dbd8): C version moved to subdirectory, Python became primary

### Phase 3: Maturation (2014-2023)
- Tools stable and functional
- Minor updates for Python 3 compatibility
- **2022-01-18** (commit 9d60969): Copyright header updates by Lukhnos Liu
- **2022-12-30** (commit cedd379): count.occurrence.py updates by Mengjuei Hsieh

### Phase 4: Modern Features (2024)
- **2024-03-15** (commit d64ebcc): Associated phrases v2 system added by Lukhnos Liu
- **2024-08-25** (commit 07f0b99): Swift encoding audit tool added by zonble
- **2024-10-30** (commit ba112c9): Enhanced associated phrases with punctuation support by zonble

### Phase 5: Package Reorganization (2024-2025)
- **October 2024**: Migration to `curation/` package structure
- **2025-03-08** (commit 3beb004): Final modernization - Black formatting by Lukhnos Liu
- **2025-03-08** (commit 8091198): argparse refactor by Lukhnos Liu
- **Benefit**: Proper Python package, PEP-8 compliant, importable modules

## Why Deprecated?

### Issues with bin/ Structure
1. **Flat organization**: ~30 files in single directory
2. **Mixed purposes**: Library modules, CLI scripts, config, legacy code
3. **Naming inconsistency**: `cook.py`, `cook-plain-bpmf.py`, `buildFreq.py`, `self-score-test.py`
4. **Side effects**: Some modules not safely importable
5. **No packaging**: Not installable via pip/setuptools
6. **Path handling**: Each script calculated paths differently

### Benefits of New Structure
1. **Proper Python package** (`curation/`):
   - Organized submodules: builders, compilers, validators, utils
   - PEP-8 naming: `frequency_builder.py`, `main_compiler.py`
   - Importable without side effects
   - Package installation via pyproject.toml
   - Console script entry points

2. **Clear separation** (`scripts/`):
   - CLI-only tools with side effects
   - Not part of importable package
   - Explicit executable purpose

3. **Centralized configuration**:
   - Single source: `from curation import PROJECT_ROOT, CONFIG_FILE`
   - No path calculation in individual scripts
   - Easy to refactor

4. **Better maintenance**:
   - Type hints and documentation
   - Modern Python practices (pathlib, f-strings)
   - Easier testing and CI/CD

## For Developers

### Using New Structure
```bash
# Recommended: Use Makefile (automatically uses new paths)
make all

# Or call modules directly
python3 -m curation.compilers.main_compiler --output data.txt ...
python3 -m curation.builders.frequency_builder

# After pip install -e .
mcbpmf-compile --output data.txt ...
mcbpmf-build-freq
```

### Path Configuration Pattern
```python
# In any script or module:
from curation import PROJECT_ROOT, CONFIG_FILE

# Use paths directly:
data_file = PROJECT_ROOT / "BPMFBase.txt"
config = configparser.ConfigParser()
config.read(CONFIG_FILE)
```

### Using Legacy Tools
```bash
# Encoding audit (still useful)
cd bin_legacy
swift audit_encoding.swift

# C version (if needed for performance testing)
cd bin_legacy/C_Version
export TEXTPOOL=/path/to/corpus
./count.bash 測試詞
```

## Key Contributors (Historical Credit)

- **Mengjuei Hsieh** (mjhsieh@gmail.com): Original Python implementation (2012-2013), maintained count.occurrence.py
- **Lukhnos Liu** (lukhnos@lukhnos.org): Recent modernization and associated phrases v2 (2024-2025)
- **zonble** (zonble@gmail.com): Encoding audit tool (2024)

## References

- **Package structure docs**: `Source/Data/AGENTS.md`
- **Historical methodology**: `bin_legacy/README` (original documentation)
- **Corpus processing**: `algorithm.md` section "字典資料的生成與使用"
- **Migration discussion**: October 2024 package reorganization

---

Last updated: October 2024
Deprecated from active development but preserved for historical and academic reference.
