"""Derive the Schmitt et al. (2026) BPX test fixtures from their registered dataset.

The dataset https://w3id.org/battinfo/dataset/7jnc-cjtw-5h3a-5t52 publishes the
parameter set in two immutable distributions: the file as published (header
"BPX": 1.0, parameters in the layout before the "State" section) and a
conversion to BPX 1.1.0. This script downloads both, checks them against the
SHA-256 sums published in the dataset record, removes the "Validation" section
(6 MB of measured curves that the tests do not use) and writes the result next
to this script. All other content is unchanged.

The SHA-256 sums of the written files are recorded in datasets.toml, which
test_bpx_acceptance.jl checks. Run this script again only when the dataset gets
a new version:

    python make_fixtures.py
"""

from __future__ import annotations

import hashlib
import json
import urllib.request
from pathlib import Path

BASE = "https://pub-5d124607e4b748eea681efca486508ab.r2.dev/parameter-sets/7jnc-cjtw-5h3a-5t52/v1/"
DISTRIBUTIONS = {
    "schmitt_2026_v0_layout.bpx.json": (
        BASE + "IMP5-70-120-H0B_graphite-lnmo_schmitt-2026_validation.bpx.json",
        "29717e566ad0d0acf60a1a46e2b2044d3675e44d4e414dd32bef1bdefbf025a4",
    ),
    "schmitt_2026.bpx.json": (
        BASE + "IMP5-70-120-H0B_graphite-lnmo_schmitt-2026_validation.bpx-v1.json",
        "2e82385fd95e0d61d097b878a3a70bf6cb129afa36d8d4ae4f183699de73a92f",
    ),
}


def main() -> None:
    here = Path(__file__).parent
    for name, (url, expected) in DISTRIBUTIONS.items():
        # The storage host rejects the default urllib user agent
        request = urllib.request.Request(url, headers={"User-Agent": "BattMo.jl-test-fixtures"})
        with urllib.request.urlopen(request) as response:
            raw = response.read()
        actual = hashlib.sha256(raw).hexdigest()
        if actual != expected:
            raise SystemExit(f"{url}: SHA-256 {actual} does not match the dataset record ({expected})")
        data = json.loads(raw)
        data.pop("Validation", None)
        text = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
        (here / name).write_bytes(text.encode("utf-8"))
        print(f"{name}: sha256 {hashlib.sha256(text.encode('utf-8')).hexdigest()}")


if __name__ == "__main__":
    main()
