# McBopomofo Data Source

## Using the Build System

Use Makefile targets (automatically uses new curation/ structure):

```
  make all      # Build all data files
  make sort     # Sort all data files
  make check    # Validate data integrity
  make clean    # Remove generated files
```

## Updating the bpmfvs Databases

The bpmfvs files are precompiled since we work under the assumption that they
are fairly stable. If you need to update them, assuming `$REPO_ROOT` is the
base directory in which you have checked out [bpmfvs](https:
//github.com/ButTaiwan/bpmfvs). Then:

```
python3 -m curation.compilers.update_bpmfvs_pua_db \
  --input $REPO_ROOT/bpmfvs/phonetic/phonic_types.txt
python3 -m curation.compilers.update_bpmfvs_variant_db \
  --input $REPO_ROOT/bpmfvs/phonetic/phonic_table_Z.txt
  --bpmf_base BPMFBase.txt
  --bpmf_mappings BPMFMappings.txt
```

This will update `bpmfvs-pua.txt` and `bpmfvs-variants.txt` respectively. After
that, make a pull request so that the maintainers can review the changes.

## Editorial Rule

See https://github.com/openvanilla/McBopomofo/wiki/詞庫開發說明

