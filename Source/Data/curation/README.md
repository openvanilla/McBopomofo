# McBopomofo Curation Tools

Python package containing dictionary data curation tools for McBopomofo.

## Installation

For development (editable mode):
```bash
cd Source/Data/curation
pip install -e .
```

For notebook support:
```bash
pip install -e ".[notebook]"
```

## Tools

After installation, the following command-line tools are available:

- `mcbpmf-compile` - Main build script: combines all source files into data.txt
- `mcbpmf-compile-plain` - Builds data-plain-bpmf.txt for traditional Bopomofo mode
- `mcbpmf-build-freq` - Generates PhraseFreq.txt from phrase.occ and exclusion.txt
- `mcbpmf-derive-phrases` - Generates associated phrase suggestions
- `mcbpmf-validate-scores` - Validates and scores dictionary data quality
- `mcbpmf-filter-non-cjk` - Filters out non-CJK characters

## Development

Run tests:
```bash
pytest
```

With coverage:
```bash
pytest --cov=curation
```

## Notebooks

The `notebooks/` directory contains Jupyter notebooks for data analysis and verification:
- `playground.ipynb` - Term score verification and analysis
