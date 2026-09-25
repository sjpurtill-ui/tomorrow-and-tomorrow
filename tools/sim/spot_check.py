#!/usr/bin/env python3
"""Later-era real-engine spot check (research_3000).

The 0-200-year truth runs (run_truth.py) calibrate the surrogate where both
start from a founding band. This checks it deep in a later era: the surrogate's
own balanced society at game year Y (known discoveries, adoption, scholarship,
population) seeds BOTH the real engine (tools/sim/truth_probe.tscn with
--start_year/--start_pop/--seed_file, headless) and the surrogate
(Surrogate.seed_state, headless_world like the calibration runs); both then run
N years of sensible play and are compared year by year.

    python tools/sim/spot_check.py --start 2500 --years 40 --run     # write the seed, run the engine (~1-2 h), compare
    python tools/sim/spot_check.py --start 2500 --years 40           # compare against the saved truth only

Truth goes to tools/sim/ground_truth/spot/ (outside calibrate.py's truth set).
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_truth  # noqa: E402
import simlib  # noqa: E402

SIM = Path(__file__).resolve().parent
SPOT = SIM / "ground_truth" / "spot"
METRICS = [("population", "{:,.0f}", 0.25), ("life_expectancy", "{:.1f}", 5.0), ("infant_mortality", "{:.0f}", 0.35),
           ("known", "{:.0f}", 0.25), ("food_security", "{:.2f}", 0.10), ("health", "{:.2f}", 0.10)]


def seed_file(start: int, seed: int) -> Path:
    return SPOT / f"seed_balanced_{seed}_{start}.json"


def truth_file(start: int, years: int, seed: int) -> Path:
    return SPOT / f"spot_sensible_{seed}_{start}_{years}y.json"


def make_seed(start: int, seed: int) -> dict:
    """The surrogate's balanced society (realistic world) at game year ``start``."""
    sur = simlib.make("balanced", seed)
    sur.run(start)
    known = [sur.cat.ids[i] for i in np.where(sur.known)[0]]
    data = {"schema": "sim_spot_seed/1", "start_year": start, "population": int(round(sur.population)),
            "scholarship": float(sur.scholarship), "known": known,
            "adoption": {sur.cat.ids[i]: round(float(sur.adoption[i]), 4) for i in np.where(sur.known)[0]}}
    SPOT.mkdir(parents=True, exist_ok=True)
    seed_file(start, seed).write_text(json.dumps(data), encoding="utf-8")
    return data


def run_engine(start: int, years: int, seed: int, pop: int, godot: str) -> None:
    out = truth_file(start, years, seed)
    t0 = time.time()
    proc = subprocess.run([godot, "--headless", "--path", str(run_truth.ROOT), "res://tools/sim/truth_probe.tscn", "--",
                           "--scenario=sensible", f"--seed={74119}", f"--years={years}", f"--out={out.as_posix()}",
                           f"--start_year={start}", f"--start_pop={pop}", f"--seed_file={seed_file(start, seed).as_posix()}"],
                          capture_output=True, text=True)
    meta = {"start_year": start, "years": years, "commit": run_truth.commit(), "sources_at_launch": run_truth.source_fingerprint(),
            "seconds": time.time() - t0, "returncode": proc.returncode, "stdout_tail": proc.stdout[-2000:], "stderr_tail": proc.stderr[-2000:]}
    out.with_suffix(".meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")


def surrogate_rows(seed_data: dict, years: int, seeds: int) -> list[list[dict]]:
    out = []
    for s in range(seeds):
        sur = simlib.make("sensible", 1000 + s, simlib.params({"headless_world": True}))   # one settlement, like the probe world
        sur.seed_state(float(seed_data["start_year"]), seed_data["known"], seed_data["adoption"], float(seed_data["population"]),
                       float(seed_data["scholarship"]))
        out.append(sur.run(years)["rows"])
    return out


def compare(truth: dict, runs: list[list[dict]], start: int) -> tuple[list[str], int]:
    lines = ["| year | " + " | ".join(f"{m} (real / surrogate)" for m, _f, _t in METRICS) + " |", "|---:|" + "---|" * len(METRICS)]
    fails = 0
    t_rows = {int(r["year"]): r for r in truth["rows"]}
    for y in sorted(t_rows):
        if y % 10 and y != max(t_rows):
            continue
        cells = []
        for m, fmt, tol in METRICS:
            real = t_rows[y].get(m)
            vals = [next((r[m] for r in rows if abs(r["year"] - (start + y)) < 0.01), None) for rows in runs]
            vals = [v for v in vals if v is not None]
            sur = float(np.mean(vals)) if vals else None
            if real is None or sur is None:
                cells.append("-")
                continue
            ok = abs(sur - real) <= (tol if tol >= 1.0 else tol * max(1.0, abs(real)))
            fails += 0 if ok or y == 0 else 1
            cells.append(f"{fmt.format(real)} / {fmt.format(sur)}{'' if ok else ' ✗'}")
        lines.append(f"| {start + y} | " + " | ".join(cells) + " |")
    return lines, fails


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--start", type=int, default=2500)
    ap.add_argument("--years", type=int, default=40)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--run", action="store_true", help="write the seed and run the real engine first")
    ap.add_argument("--pop", type=int, default=25000, help="people at the start: the headless probe world has one settlement, so the "
                    "seed's population is replaced by what one territory carries in that era (about 0.7 of its capacity)")
    ap.add_argument("--godot", default=os.environ.get("GODOT", run_truth.DEFAULT_GODOT))
    ap.add_argument("--md", type=Path, default=None)
    args = ap.parse_args()
    if args.run or not seed_file(args.start, args.seed).exists():
        data = make_seed(args.start, args.seed)
        print(f"seed: year {args.start}, {data['population']:,} people, {len(data['known'])} known, scholarship {data['scholarship']:.0f}")
    data = json.loads(seed_file(args.start, args.seed).read_text(encoding="utf-8"))
    data["population"] = int(args.pop) if args.pop else int(data["population"])
    if args.run:
        run_engine(args.start, args.years, args.seed, int(data["population"]), args.godot)
    path = truth_file(args.start, args.years, args.seed)
    if not path.exists():
        print(f"no truth at {path} (use --run)")
        return 1
    truth = json.loads(path.read_text(encoding="utf-8"))
    runs = surrogate_rows(data, args.years, args.seeds)
    lines, fails = compare(truth, runs, args.start)
    text = "\n".join([f"Spot check from game year {args.start}: {data['population']:,} people, {len(data['known'])} known "
                      f"(real engine {truth.get('seconds', 0):.0f} s; surrogate {args.seeds} seeds). Tolerances: population ±25%, e0 ±5 y, "
                      f"IMR ±35%, known ±25%, food security and health ±0.10.", ""] + lines + ["", f"{fails} value(s) outside tolerance."])
    print(text)
    if args.md:
        args.md.write_text(text + "\n", encoding="utf-8")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
