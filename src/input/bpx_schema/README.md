# BPX JSON schema (third-party)

`bpx_schema.json` is **not authored by the BattMo developers**. It is the JSON schema of the
Battery Parameter eXchange (BPX) standard, generated from the official BPX Python package:

- Package: [`bpx`](https://pypi.org/project/bpx/) version **1.1.1**
- Source: <https://github.com/FaradayInstitution/BPX>
- Copyright (c) 2022 University of Oxford
- License: MIT, see [`LICENSE`](LICENSE) in this directory (copied unchanged from the package)

The schema is used by `src/input/bpx.jl` to validate BPX files before they are converted to
BattMo cell parameters. The conversion of legacy BPX v0.x files to the v1.x layout in
`src/input/bpx.jl` (`migrate_legacy_bpx`) is likewise adapted from `bpx/_migrations.py` of the
same package, under the same license.

## Updating to a new BPX release

The schema file is the output of the package, unmodified. To regenerate it (in a separate
virtual environment):

```sh
python -m venv bpx-env
bpx-env/bin/python -m pip install bpx==<version>      # Windows: bpx-env\Scripts\python
bpx-env/bin/python -c "import bpx, json; json.dump(bpx.BPX.model_json_schema(by_alias=True), open('bpx_schema.json', 'w'), indent=2)"
```

Then:

1. Replace `bpx_schema.json`, and `LICENSE` if the license text changed.
2. Update the package version above and `BPX_SCHEMA_VERSION` in `src/input/bpx.jl`.
3. Check the BPX change log for new or changed parameters, update the conversion in
   `src/input/bpx.jl` where needed, and run `test/test_bpx.jl`.
