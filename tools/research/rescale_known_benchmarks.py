#!/usr/bin/env python3
"""Rescale the provisional discoveries_known rows to the baked registry.

The benchmark files derive discoveries_known from the cumulative number of
registry items targeted by each year: min / low / typical / high / max =
0.15 / 0.35 / 0.70 / 0.90 / 1.00 x the target (BENCHMARKS_1200.md,
BENCHMARKS_1800.md "Rescale when the block is baked", BENCHMARKS_2400.md,
BENCHMARKS_3000.md). The 1800-2400 and 2400-3000 rows were written before those
blocks existed (about 90 items per 50 years, 5,184 by 3000); the baked registry
holds 4,164 items by 2400 and 5,737 by 3000. This recomputes the rows after 1800
from data/research (items with design year <= the row's year) with the same
shares. The 1800 row and every earlier file stay fixed, and the 2400 join row is
written identically into both files.

    python tools/research/rescale_known_benchmarks.py           # rewrite the two files
    python tools/research/rescale_known_benchmarks.py --check   # report only
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SHARES = {"min": 0.15, "low": 0.35, "typical": 0.70, "high": 0.90, "max": 1.00}
FILES = {2400: ROOT / "docs/research/benchmarks_2400.json", 3000: ROOT / "docs/research/benchmarks_3000.json"}
FIRST_RESCALED = 1900


def targets() -> dict[int, int]:
    sys.path.insert(0, str(ROOT / "tools" / "sim"))
    import gamedata as gd
    years = []
    for block in gd.manifest_blocks():
        years += [float(it["proposed_year"]) for it in json.loads((ROOT / block["data"]).read_text(encoding="utf-8"))["items"]]
    return {y: sum(1 for v in years if v <= y) for y in range(600, 3001, 100)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    target = targets()
    for window, path in FILES.items():
        data = json.loads(path.read_text(encoding="utf-8"))
        rows = data["metrics"]["discoveries_known"]["years"]
        for year in sorted(rows, key=float):
            y = int(float(year))
            if y < FIRST_RESCALED:
                continue
            new = {k: int(round(target[y] * s)) for k, s in SHARES.items()}
            if {k: rows[year][k] for k in SHARES} != new:
                print(f"{path.name} {year}: {[rows[year][k] for k in SHARES]} -> {[new[k] for k in SHARES]} (target {target[y]})")
            rows[year].update(new)
        note = ("discoveries_known rows after 1800 are 0.15/0.35/0.70/0.90/1.00 x the baked registry's cumulative target "
                "(tools/research/rescale_known_benchmarks.py)")
        data["metrics"]["discoveries_known"]["note"] = note
        if window == 3000:
            data["description"] = data["description"].replace("discoveries_known is provisional until registry blocks after 1200 exist.",
                                                              "discoveries_known follows the baked registry (tools/research/rescale_known_benchmarks.py).")
        if not args.check:
            path.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
