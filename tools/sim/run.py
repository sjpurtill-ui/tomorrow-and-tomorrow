#!/usr/bin/env python3
"""Run the surrogate: python tools/sim/run.py --scenario sensible --seeds 20 --years 600

Prints per-century means across seeds, milestone years for key thresholds, and
runtime per run. --json writes the full rows for every seed.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gamedata as gd  # noqa: E402
import gdparse  # noqa: E402
import simlib  # noqa: E402

MILESTONES = ["seed_selection", "pit_firing", "token_envelopes", "copper_smelting", "ox_drawn_ard", "solid_wheel_assembly",
              "pictographic_records", "standard_sign_lists", "tin_smelting", "bronze_alloying", "phonetic_notation", "formal_archives",
              "written_law_code", "spoked_wheel_assembly", "place_value", "consonantal_alphabet", "war_chariots", "glassmaking"]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--scenario", default="sensible")
    ap.add_argument("--seeds", type=int, default=1)
    ap.add_argument("--seed0", type=int, default=1)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--params", type=Path, default=None, help="alternate params.json")
    ap.add_argument("--set", nargs="*", default=[], help="param overrides key=value (JSON values)")
    ap.add_argument("--json", type=Path, default=None)
    args = ap.parse_args()
    overrides = {}
    for kv in args.set:
        k, v = kv.split("=", 1)
        overrides[k] = json.loads(v)
    t0 = time.time()
    constants, cat = simlib.data()
    load_s = time.time() - t0
    p = simlib.params(overrides, args.params)
    results, times = [], []
    for s in range(args.seed0, args.seed0 + args.seeds):
        t = time.time()
        results.append(simlib.run(args.scenario, s, args.years, p))
        times.append(time.time() - t)
    for w in gdparse.WARNINGS:
        print("WARNING:", w)
    print(f"scenario={args.scenario} seeds={args.seeds} years={args.years}  load {load_s:.2f}s  "
          f"run {np.mean(times):.2f}s/seed (min {min(times):.2f}, max {max(times):.2f})")
    keys = ["population", "life_expectancy", "infant_mortality", "food_days", "food_security", "health", "known", "scholarship", "education"]
    print("year  " + "  ".join(f"{k[:14]:>14}" for k in keys))
    for y in range(0, args.years + 1, 50 if args.years <= 200 else 100):
        vals = []
        for k in keys:
            xs = [next((r[k] for r in res["rows"] if abs(r["year"] - y) < 0.01), None) for res in results]
            m, sd = simlib.mean_std(xs)
            vals.append(f"{m:>9.1f}+-{sd:<4.1f}" if m is not None else f"{'-':>14}")
        print(f"{y:>4}  " + "  ".join(vals))
    ms = [m for m in MILESTONES if m in cat.index]
    print("\nmilestone years (mean +- sd over seeds; design year and band from research_600.json)")
    for m in ms:
        ys = [simlib.milestone_years(r, [m])[m] for r in results]
        got = [y for y in ys if y is not None]
        row = cat.rows[cat.index[m]]
        band = f"{row.get('design_year', -1):.0f} [{row.get('band_low', 0):.0f}-{row.get('band_high', 0):.0f}]" if row.get("registry") else f"gate {row.get('earliest_year', 0):.0f}"
        mean = f"{np.mean(got):.0f}+-{np.std(got):.0f}" if got else "never"
        print(f"  {m:24s} {mean:>10s}  reached {len(got)}/{len(ys)}  design {band}")
    if args.json:
        args.json.write_text(json.dumps({"scenario": args.scenario, "years": args.years, "runs": results}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
