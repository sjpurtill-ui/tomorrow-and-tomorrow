#!/usr/bin/env python3
"""Tune game-side balance knobs against the 600-year benchmarks with the surrogate.

    python tools/sim/tune.py --baseline                          # current data: milestones + benchmark flags
    python tools/sim/tune.py --sweep tune_research_pace=0.6,0.8,1,1.25
    python tools/sim/tune.py --optimize --seeds 6                # coordinate search, writes a report

Knobs (each maps to a concrete game change; see docs/research/SURROGATE_SIM.md):
  tune_research_pace   x daily research progress      -> discovery_system.gd process_day "*0.12" (or research_years / x)
  tune_era_doubling    years per cost doubling         -> TechnologyEras.DOUBLING
  tune_era_window      free-scholarship window (years) -> TechnologyEras.WINDOW
  tune_adoption_pace   x adoption speed                -> SocietyModel.ADOPTION_PACE
  tune_cap_scale       x era ceilings                  -> SocietyModel.ERA_CEILING_600 (all anchors)
  tune_burden_scale    x (ERA_BURDEN - 1)              -> early_life_conditions.gd ERA_BURDEN (pre-modern mortality)
  tune_line_scale      {line: x} effect magnitudes     -> data/research/effects/<line>.json values

Objective: design-band misses of the benchmark milestones (benchmarks_600.json
milestones.ids, bands from research_600.json) + benchmark metrics at 100/300/600
(sensible play aimed at typical..high, poor play at low..typical) + per_50.
Reports go to tools/sim/reports/.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import facets  # noqa: E402
import gamedata as gd  # noqa: E402
import simlib  # noqa: E402

SIM = Path(__file__).resolve().parent
REPORTS = SIM / "reports"
KNOBS = {"tune_research_pace": (1.0, 0.3), "tune_era_doubling": (None, 10.0), "tune_era_window": (None, 25.0),
         "tune_adoption_pace": (1.0, 0.3), "tune_cap_scale": (1.0, 0.15), "tune_burden_scale": (1.0, 0.3)}
TARGET_ZONE = {"sensible": ("typical", "high"), "research": ("typical", "high"), "poor": ("low", "typical"), "ai": ("low", "high"), "balanced": ("typical", "high")}
CHECK_YEARS = [100, 300, 600]


def _run(args):
    scenario, seed, years, overrides = args
    p = simlib.params(overrides)
    result = simlib.run(scenario, seed, years, p)
    constants, cat = simlib.data()
    return {"facets": facets.century_facets(result, cat, years, step=50), "milestones": milestone_years(result)}


def milestone_ids() -> list[str]:
    ids = facets.benchmarks().get("milestones", {}).get("ids") or []
    return ids or ["copper_smelting", "pictographic_records", "bronze_alloying", "place_value", "consonantal_alphabet"]


def milestone_years(result: dict) -> dict:
    return simlib.milestone_years(result, milestone_ids())


def evaluate(overrides: dict, scenarios: list[str], seeds: int, years: int, pool) -> dict:
    jobs = [(s, 1 + k, years, overrides) for s in scenarios for k in range(seeds)]
    outs = list(pool.map(_run, jobs))
    by = {}
    for (s, _k, _y, _o), out in zip(jobs, outs):
        by.setdefault(s, []).append(out)
    return by


def objective(by: dict, years: int) -> tuple[float, dict]:
    constants, cat = simlib.data()
    bench = facets.benchmarks()
    parts = {"milestones": 0.0, "benchmarks": 0.0, "per_50": 0.0}
    detail = {"milestones": {}, "benchmarks": {}}
    # milestones: sensible play is the design's reference society
    ref = by.get("sensible") or next(iter(by.values()))
    for rid in milestone_ids():
        if rid not in cat.index:
            continue
        row = cat.rows[cat.index[rid]]
        lo, hi = row.get("band_low", 0.0), row.get("band_high", 0.0)
        half = max(5.0, (hi - lo) / 2.0)
        ys = [o["milestones"].get(rid) for o in ref]
        err = 0.0
        for y in ys:
            if y is None:
                err += 9.0 if hi <= years else 0.0
            elif y < lo:
                err += ((lo - y) / half) ** 2
            elif y > hi:
                err += ((y - hi) / half) ** 2
        parts["milestones"] += err / max(1, len(ys))
        got = [y for y in ys if y is not None]
        detail["milestones"][rid] = {"mean": float(np.mean(got)) if got else None, "reached": f"{len(got)}/{len(ys)}", "band": [lo, hi],
                                     "design": row.get("design_year")}
    for scenario, outs in by.items():
        zone = TARGET_ZONE.get(scenario, ("low", "high"))
        mean = facets.mean_facets([o["facets"] for o in outs])
        for year in CHECK_YEARS:
            if year not in mean:
                continue
            for facet, metric in facets.BENCH_KEYS.items():
                b = facets.bench_at(bench, metric, year)
                v = mean[year].get(facet)
                if not b or v is None:
                    continue
                a, z = sorted((b[zone[0]], b[zone[1]]))
                width = max(1e-6, abs(b["high"] - b["low"]))
                err = ((a - v) / width) ** 2 if v < a else ((v - z) / width) ** 2 if v > z else 0.0
                key = "per_50" if facet == "per_50" else "benchmarks"
                parts[key] += min(err, 16.0)
                detail["benchmarks"][f"{scenario}/{facet}/{year}"] = {"value": v, "zone": [a, z], "flag": facets.flag(bench, facet, year, v)}
    total = parts["milestones"] * 2.0 + parts["benchmarks"] + parts["per_50"]
    return total, {"parts": parts, **detail}


def show(label: str, score: float, det: dict) -> None:
    print(f"\n== {label}: objective {score:.2f}  (milestones {det['parts']['milestones']:.2f}, benchmarks {det['parts']['benchmarks']:.2f}, per_50 {det['parts']['per_50']:.2f})")
    print("milestone              mean-year  reached  design [band]")
    for rid, m in det["milestones"].items():
        mean = f"{m['mean']:.0f}" if m["mean"] is not None else "never"
        inside = "" if m["mean"] is None else (" early" if m["mean"] < m["band"][0] else " LATE" if m["mean"] > m["band"][1] else " ok")
        print(f"  {rid:22s} {mean:>8s}{inside:6s} {m['reached']:>6s}  {m['design']:.0f} [{m['band'][0]:.0f}-{m['band'][1]:.0f}]")
    flagged = {k: v for k, v in det["benchmarks"].items() if v["flag"] not in ("within", "")}
    print(f"benchmark flags outside low..high: {len(flagged)} of {len(det['benchmarks'])}")
    for k, v in list(flagged.items())[:30]:
        print(f"  {k:40s} {v['value']:>10.2f}  {v['flag']}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--baseline", action="store_true")
    ap.add_argument("--sweep", default=None, help="knob=v1,v2,...")
    ap.add_argument("--optimize", action="store_true")
    ap.add_argument("--scenarios", default="sensible,poor")
    ap.add_argument("--seeds", type=int, default=4)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--rounds", type=int, default=2)
    ap.add_argument("--jobs", type=int, default=16)
    args = ap.parse_args()
    REPORTS.mkdir(exist_ok=True)
    scenarios = args.scenarios.split(",")
    constants, cat = simlib.data()
    defaults = {"tune_era_doubling": constants.era_doubling, "tune_era_window": constants.era_window}
    report = {"generated": time.strftime("%Y-%m-%d %H:%M"), "scenarios": scenarios, "seeds": args.seeds, "years": args.years, "runs": []}
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        base_score, base_det = objective(evaluate({}, scenarios, args.seeds, args.years, pool), args.years)
        show("current game data", base_score, base_det)
        report["runs"].append({"label": "baseline", "overrides": {}, "score": base_score, "detail": base_det})
        if args.sweep:
            knob, values = args.sweep.split("=")
            for value in values.split(","):
                ov = {knob: float(value)}
                sc, det = objective(evaluate(ov, scenarios, args.seeds, args.years, pool), args.years)
                show(f"{knob}={value}", sc, det)
                report["runs"].append({"label": f"{knob}={value}", "overrides": ov, "score": sc, "detail": det})
        if args.optimize:
            current, best = {}, base_score
            steps = {k: v[1] for k, v in KNOBS.items()}
            for rnd in range(args.rounds):
                for knob in KNOBS:
                    start = current.get(knob, KNOBS[knob][0] if KNOBS[knob][0] is not None else defaults[knob])
                    moved = False
                    for d in (1, -1):
                        trial = dict(current)
                        trial[knob] = max(0.05, start + d * steps[knob])
                        sc, det = objective(evaluate(trial, scenarios, args.seeds, args.years, pool), args.years)
                        print(f"  round {rnd} {knob}={trial[knob]:.3g} -> {sc:.2f} (best {best:.2f})", flush=True)
                        if sc < best:
                            best, current, moved = sc, trial, True
                            report["runs"].append({"label": f"opt r{rnd} {knob}", "overrides": trial, "score": sc, "detail": det})
                            break
                    if not moved:
                        steps[knob] *= 0.5
            sc, det = objective(evaluate(current, scenarios, args.seeds, args.years, pool), args.years)
            show(f"recommended {current}", sc, det)
            report["recommended"] = {"overrides": current, "score": sc, "baseline_score": base_score, "game_changes": game_changes(current, constants)}
            print("\nRecommended game changes:")
            for line in report["recommended"]["game_changes"]:
                print("  " + line)
    stamp = time.strftime("%Y%m%d_%H%M")
    (REPORTS / f"tune_{stamp}.json").write_text(json.dumps(report, indent=1, default=float), encoding="utf-8")
    print(f"\nreport: tools/sim/reports/tune_{stamp}.json")
    return 0


def game_changes(ov: dict, constants) -> list[str]:
    out = []
    if "tune_research_pace" in ov:
        x = ov["tune_research_pace"]
        out.append(f"research pace x{x:.2f}: discovery_system.gd process_day '*0.12' -> '*{0.12 * x:.4f}' (equivalently divide every research_years by {x:.2f})")
    if "tune_era_doubling" in ov:
        out.append(f"TechnologyEras.DOUBLING {constants.era_doubling:g} -> {ov['tune_era_doubling']:.1f}")
    if "tune_era_window" in ov:
        out.append(f"TechnologyEras.WINDOW {constants.era_window:g} -> {ov['tune_era_window']:.1f}")
    if "tune_adoption_pace" in ov:
        out.append(f"SocietyModel.ADOPTION_PACE {constants.adoption_pace:g} -> {constants.adoption_pace * ov['tune_adoption_pace']:.4f}")
    if "tune_cap_scale" in ov:
        out.append(f"SocietyModel.ERA_CEILING_600: multiply every anchor by {ov['tune_cap_scale']:.2f}")
    if "tune_burden_scale" in ov:
        import model
        scaled = {k: round(1.0 + (float(v) - 1.0) * ov["tune_burden_scale"], 2) for k, v in model.ERA_BURDEN.items()}
        out.append(f"early_life_conditions.gd ERA_BURDEN -> {scaled}")
    for line, x in (ov.get("tune_line_scale") or {}).items():
        out.append(f"data/research/effects/{line}.json: multiply effect values by {x:.2f}")
    return out


if __name__ == "__main__":
    sys.exit(main())
