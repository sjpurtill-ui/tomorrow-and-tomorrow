#!/usr/bin/env python3
"""People-first balance suite: every path, the extremes and the switches, one report.

    python tools/sim/paths.py                         # suite people_first, 3 seeds, 1200 years
    python tools/sim/paths.py --suite paths --years 600 --seeds 2
    python tools/sim/paths.py --names path_war split_war_heavy --years 300
    python tools/sim/paths.py --set '{"some_param": 1.2}' --json out.json

The suites live in scenarios.json ("suites"):
* path_<p>: the leaders' own work on each path (work_paths.gd: growth, making,
  war, learning, building, balanced), one town, as the truth probe runs it;
* towns_<p>: the same, founding a town every 30 years when stores allow (a
  computer people);
* split_<n>: the ruler's own split (balanced, big and dumb, small and smart,
  war-heavy, making-heavy), the leader feeding the town only on the alarm;
* switch_<n>: one split until year 200, another after.

The report gives, per scenario at years 300 / 600 / 1200: people, output per
worker (economy_system.gd output value: food + materials x 2 + goods x 6, in
rations, over those who can work), discoveries, goods a head, the watch's
field strength, infant deaths, life expectancy and growth; the founding years
(0-60); milestone years against their bands; and flags: the balanced peoples
outside the historical bands (docs/research/benchmarks_*.json), extreme paths
past "a little extra" (more than 25% of the typical-to-high gap beyond the
high value), and dominated paths (another of the same kind - the leaders'
paths, the computer peoples with towns, the ruler's splits - at least as good
on people, knowledge, field strength, output per worker, goods a head and infant
deaths, and as far ahead of the calendar, better on one by 3% or 3 years).
"""
from __future__ import annotations

import argparse
import json
import math
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import simlib  # noqa: E402

SIM = Path(__file__).resolve().parent
DOCS = SIM.parent.parent / "docs" / "research"
CHECK_YEARS = [300, 600, 1200, 1800, 2400]
MILESTONES = {"writing": "pictographic_records", "bronze": "bronze_alloying", "place value": "place_value",
              "alphabet": "consonantal_alphabet", "iron": "bloomery_smelting", "coinage": "die_struck_coinage",
              "geometry": "axiomatic_geometry_compendium", "paper": "paper_making", "printing": "printing_process",
              "calculus": "differential_calculus"}
BALANCED = ("path_balanced", "towns_balanced", "split_balanced")
EXTRA = 0.25   # "a little extra": up to a quarter of the typical-to-high gap past the high value


def run_job(job):
    name, seed, years, overrides, every = job
    p = simlib.params(overrides or None)
    res = simlib.run(name, seed, years, p, record_every=every)
    found = {rid: day / 365.0 for day, rid, _line in res["discoveries"]}
    return {"name": name, "seed": seed, "rows": res["rows"], "milestones": {k: found.get(v) for k, v in MILESTONES.items()}}


def at(rows, year, tol=1.0):
    best = min(rows, key=lambda r: abs(r["year"] - year))
    return best if abs(best["year"] - year) <= tol else None


def mean(values):
    vals = [v for v in values if v is not None and not (isinstance(v, float) and math.isnan(v))]
    return float(np.mean(vals)) if vals else float("nan")


def growth(rows, a, b):
    ra, rb = at(rows, a, 5.5), at(rows, b, 5.5)
    if not ra or not rb or ra["population"] <= 0 or rb["population"] <= 0:
        return None
    return math.log(rb["population"] / ra["population"]) / (b - a) * 100.0


def benchmarks() -> dict:
    """metric -> year -> (min, low, typical, high, max), from docs/research/benchmarks_*.json."""
    out: dict = {}
    for path in sorted(DOCS.glob("benchmarks_[0-9]*.json")):
        doc = json.loads(path.read_text(encoding="utf-8"))
        for key, metric in doc.get("metrics", {}).items():
            for year, v in (metric.get("years") or {}).items():
                try:
                    out.setdefault(key, {})[int(year)] = (v.get("min"), v.get("low"), v.get("typical"), v.get("high"), v.get("max"))
                except (TypeError, ValueError):
                    continue
    return out


def band(bench: dict, key: str, year: int):
    years = bench.get(key) or {}
    return years.get(year)


def summarize(runs: list, years: int) -> dict:
    """Mean over seeds of each reported metric at each check year."""
    out = {}
    for y in [c for c in CHECK_YEARS if c <= years]:
        rows = [at(r["rows"], y, 5.5) for r in runs]
        if any(x is None for x in rows):
            continue
        prev = {300: 150, 600: 300, 1200: 600, 1800: 1200, 2400: 1800}[y]
        out[y] = {
            "people": mean([x["population"] for x in rows]),
            "output_per_worker": mean([x["output"] / max(1.0, x["able"]) for x in rows]),
            "known": mean([x["known"] for x in rows]),
            "goods_per_head": mean([x["goods_per_head"] for x in rows]),
            "field_strength": mean([x["field_strength"] for x in rows]),
            "might_per_head": mean([x["might"] / max(1.0, x["population"]) for x in rows]),
            "infant_mortality": mean([x["infant_mortality"] for x in rows]),
            "life_expectancy": mean([x["life_expectancy"] for x in rows]),
            "growth_pct": mean([growth(r["rows"], prev, y) for r in runs]),
            "food_labor_share": mean([x["alloc"]["Food"] for x in rows]),
            "defense_labor_share": mean([x["alloc"]["Defense"] for x in rows]),
            "watch_of_people": mean([100.0 * x["watch"] / max(1.0, x["population"]) for x in rows]),
            "hunger_per_1000": mean([1000.0 * x["hunger_toll"] / max(1.0, x["person_years"]) for x in rows]),
            "towns": mean([x["towns"] for x in rows]),
            "lead": mean([x["lead"] for x in rows]),
        }
    return out


def founding(runs: list) -> dict:
    pops = {y: mean([at(r["rows"], y)["population"] if at(r["rows"], y) else None for r in runs]) for y in (0, 7.5, 15, 30, 60)}
    lows = [min((x for x in r["rows"] if x["year"] <= 60.5), key=lambda x: x["population"]) for r in runs]
    b = mean([at(r["rows"], 7.5)["births"] if at(r["rows"], 7.5) else None for r in runs])
    d = mean([at(r["rows"], 7.5)["deaths"] if at(r["rows"], 7.5) else None for r in runs])
    return {"pop": pops, "low": mean([x["population"] for x in lows]), "low_year": mean([x["year"] for x in lows]), "births": b, "deaths": d}


def fmt(v, digits=0):
    if v is None or (isinstance(v, float) and math.isnan(v)):
        return "-"
    if abs(v) >= 10000:
        return f"{v:,.0f}"
    return f"{v:,.{digits}f}"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--suite", default="people_first")
    ap.add_argument("--names", nargs="*", default=None)
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--seed0", type=int, default=1)
    ap.add_argument("--years", type=int, default=1200)
    ap.add_argument("--jobs", type=int, default=12)
    ap.add_argument("--every", type=float, default=2.5, help="years between recorded rows")
    ap.add_argument("--set", default="", help="JSON dict of params overrides (a what-if)")
    ap.add_argument("--json", type=Path, default=None)
    args = ap.parse_args()
    doc = json.loads((SIM / "scenarios.json").read_text(encoding="utf-8"))
    names = args.names or doc.get("suites", {}).get(args.suite)
    if not names:
        print(f"no suite {args.suite!r} in scenarios.json")
        return 2
    overrides = json.loads(args.set) if args.set else {}
    jobs = [(n, s, args.years, overrides, args.every) for n in names for s in range(args.seed0, args.seed0 + args.seeds)]
    t0 = time.time()
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        results = list(pool.map(run_job, jobs))
    by: dict = {}
    for r in results:
        by.setdefault(r["name"], []).append(r)
    bench = benchmarks()
    summary = {n: summarize(by[n], args.years) for n in names}
    print(f"suite {args.suite}: {len(names)} scenarios x {args.seeds} seeds x {args.years} years in {time.time() - t0:.0f}s"
          + (f"  (what-if {overrides})" if overrides else ""))

    years = [y for y in CHECK_YEARS if y <= args.years]
    print("\nPeople / output per worker / discoveries / goods a head / field strength / infant deaths per 1,000 / life expectancy / growth %/yr")
    for y in years:
        print(f"\n  year {y}")
        print(f"  {'scenario':20s} {'people':>9s} {'out/wk':>7s} {'known':>6s} {'goods/hd':>8s} {'field':>8s} {'IMR':>5s} {'e0':>5s} {'grow%':>6s} {'food%':>6s} {'watch%':>6s} {'towns':>5s} {'lead':>5s}")
        for n in names:
            m = summary[n].get(y)
            if not m:
                continue
            print(f"  {n:20s} {fmt(m['people']):>9s} {fmt(m['output_per_worker'], 2):>7s} {fmt(m['known']):>6s} {fmt(m['goods_per_head'], 1):>8s} "
                  f"{fmt(m['field_strength']):>8s} {fmt(m['infant_mortality']):>5s} {fmt(m['life_expectancy'], 1):>5s} {fmt(m['growth_pct'], 2):>6s} "
                  f"{fmt(m['food_labor_share'], 1):>6s} {fmt(m['watch_of_people'], 1):>6s} {fmt(m['towns']):>5s} {fmt(m['lead']):>5s}")

    print("\nFounding years (people at 0 / 7.5 / 15 / 30 / 60; the low and its year; births and deaths in years 0-7.5)")
    for n in names:
        f = founding(by[n])
        pops = " / ".join(fmt(f["pop"][y], 0) for y in (0, 7.5, 15, 30, 60))
        print(f"  {n:20s} {pops:>32s}   low {fmt(f['low'], 1)} at {fmt(f['low_year'], 0)}   births {fmt(f['births'])} deaths {fmt(f['deaths'])}")

    print("\nMilestone years (mean of the seeds that reached them; band low-high from the research data)")
    constants, cat = simlib.data()
    head = []
    for label, rid in MILESTONES.items():
        row = cat.rows[cat.index[rid]] if rid in cat.index else {}
        head.append(f"{label}[{row.get('band_low', '?'):.0f}-{row.get('band_high', '?'):.0f}]" if row.get("band_low") is not None else label)
    print("  " + f"{'scenario':20s} " + " ".join(f"{h:>18s}" for h in head))
    early = []
    for n in names:
        cells = []
        for label, rid in MILESTONES.items():
            ys = [r["milestones"][label] for r in by[n] if r["milestones"][label] is not None]
            row = cat.rows[cat.index[rid]] if rid in cat.index else {}
            mark = ""
            if ys and row.get("band_low") is not None and np.mean(ys) < float(row["band_low"]):
                mark = " <"
                early.append((n, label, float(np.mean(ys)), float(row["band_low"])))
            cells.append((f"{np.mean(ys):.0f}/{len(ys)}" if ys else "-") + mark)
        print("  " + f"{n:20s} " + " ".join(f"{c:>18s}" for c in cells))

    print("\nFlags")
    flags = 0
    metrics = ["population", "infant_mortality", "life_expectancy", "growth_pct", "food_labor_share", "defense_labor_share"]
    key_of = {"population": "people", "infant_mortality": "infant_mortality", "life_expectancy": "life_expectancy", "growth_pct": "growth_pct",
              "food_labor_share": "food_labor_share", "defense_labor_share": "defense_labor_share"}
    for n in names:
        for y in years:
            m = summary[n].get(y)
            if not m:
                continue
            for metric in metrics:
                b = band(bench, metric, y)
                if not b or any(v is None for v in b):
                    continue
                lo_b, low, typical, high, hi_b = b
                v = m[key_of[metric]]
                lower_better = metric in ("infant_mortality",)
                worst, best = (max(low, high), min(low, high))
                span = (low, high) if low <= high else (high, low)
                if v < lo_b or v > hi_b:
                    print(f"  OUT OF BOUNDS  {n} year {y} {metric} {fmt(v, 2)} (plausible {lo_b}-{hi_b})")
                    flags += 1
                elif n in BALANCED and not (span[0] <= v <= span[1]):
                    print(f"  BALANCED OUTSIDE BAND  {n} year {y} {metric} {fmt(v, 2)} (low-high {low}-{high})")
                    flags += 1
                elif n not in BALANCED and metric in ("population", "infant_mortality", "life_expectancy"):
                    gap = abs(high - typical) * EXTRA
                    beyond = (v < high - gap) if lower_better else (v > high + gap)
                    if beyond:
                        print(f"  MORE THAN A LITTLE EXTRA  {n} year {y} {metric} {fmt(v, 2)} (high {high}, a little extra to {fmt(high - gap if lower_better else high + gap, 1)})")
                        flags += 1
    for n, label, y, low in early:
        if n in BALANCED:
            print(f"  BALANCED BEFORE BAND  {n} {label} at {y:.0f} (band low {low:.0f})")
            flags += 1
    final = max(y for y in years if all(summary[n].get(y) for n in names)) if years else None
    if final:
        # Each path's payoff counts: people, knowledge, field strength, output per
        # worker, goods a head, infant deaths (fewer is better) and years ahead of
        # the calendar (3 or more counts).
        keys = [("people", True), ("known", True), ("field_strength", True), ("output_per_worker", True), ("goods_per_head", True), ("infant_mortality", False)]
        group = lambda n: "split" if n.startswith(("split_", "switch_")) else n.split("_", 1)[0]
        for a in names:
            for b in names:
                if a == b or group(a) != group(b):
                    continue
                ma, mb = summary[a][final], summary[b][final]
                better = sum(1 for k, up in keys if (ma[k] > mb[k] * 1.03 if up else ma[k] < mb[k] * 0.97))
                worse = sum(1 for k, up in keys if (ma[k] < mb[k] * 0.97 if up else ma[k] > mb[k] * 1.03))
                better += ma["lead"] - mb["lead"] >= 3.0
                worse += mb["lead"] - ma["lead"] >= 3.0
                if better and not worse:
                    print(f"  DOMINATED  {b} by {a} at year {final} (people, knowledge, field strength, output, goods, infant deaths, lead)")
                    flags += 1
    print(f"  {flags} flag(s)")
    if args.json:
        args.json.write_text(json.dumps({"suite": args.suite, "names": names, "years": args.years, "seeds": args.seeds, "set": overrides,
                                         "summary": {n: {str(y): v for y, v in s.items()} for n, s in summary.items()},
                                         "founding": {n: founding(by[n]) for n in names}, "runs": results}), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
