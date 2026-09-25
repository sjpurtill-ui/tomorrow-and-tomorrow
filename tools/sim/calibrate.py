#!/usr/bin/env python3
"""Fit the surrogate's free constants to real headless engine runs.

    python tools/sim/calibrate.py              # compare only (table)
    python tools/sim/calibrate.py --fit        # fit 'fit': true params, write params.json 'calibrated'
    python tools/sim/calibrate.py --fit --rounds 3 --seeds 3

Ground truth: tools/sim/ground_truth/<scenario>_<seed>_<years>y.json produced by
run_truth.py (the real engine, headless). Each truth run is compared with the
mean of ``--seeds`` surrogate runs of the same scenario at checkpoint years.
Tolerances (TOLERANCES below) are the stated acceptance bands; check.py fails
when any metric leaves them.
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
import gamedata as gd  # noqa: E402
import gdparse  # noqa: E402
import simlib  # noqa: E402

SIM = Path(__file__).resolve().parent
CHECKPOINTS = [5, 10, 25, 50, 75, 100, 150, 200, 300, 400, 500, 600]
# metric: (kind, tolerance). rel: |s-t| <= tol*max(|t|, floor); abs: |s-t| <= tol.
TOLERANCES = {
    "population": ("rel", 0.15, 50.0),
    "life_expectancy": ("abs", 4.0, 0),
    "infant_mortality": ("rel", 0.20, 50.0),
    "food_days": ("rel", 0.35, 25.0),
    "food_security": ("abs", 0.08, 0),
    "health": ("abs", 0.08, 0),
    "known": ("rel", 0.25, 12.0),
    "scholarship": ("rel", 0.15, 2.0),
    "education": ("abs", 0.10, 0),
    # Discovery mix: sum |surrogate - real| over real total. Engine seed-to-seed
    # noise (sensible 74119 vs 5150, 100 y) is 0.40 by line x decade, 0.06 by line.
    "lines_per_decade": ("abs", 0.55, 0),
    "lines_total": ("abs", 0.15, 0),
    "decades_total": ("abs", 0.20, 0),
    "art_studied": ("abs", 1.5, 0),
    "art_science": ("abs", 0.04, 0),
    "art_allure": ("abs", 0.10, 0),
}
# Formula lines transcribed into model.py; check.py warns when the game line changes.
FORMULA_ANCHORS = [
    ("scripts/discovery_system.gd", "var probability: float = discovery.chance"),
    ("scripts/discovery_system.gd", "team_scale=researchers if"),
    ("scripts/discovery_system.gd", "var support_multiplier:="),
    ("scripts/discovery_system.gd", "return (0.45+0.55*staffing)"),
    ("scripts/discovery_system.gd", "return (0.85+_research_draw"),
    ("scripts/society_model.gd", "var spread:=(0.00035+teaching+practice+directed)"),
    ("scripts/society_model.gd", "var combined:=clampf("),
    ("scripts/consequence_engine.gd", "var food_security_target := clampf("),
    ("scripts/consequence_engine.gd", "var health_target := clampf("),
    ("scripts/consequence_engine.gd", "var cohesion_target := clampf("),
    ("scripts/consequence_engine.gd", "var material_target := clampf("),
    ("scripts/consequence_engine.gd", "var knowledge_gain := observers"),
    ("scripts/consequence_engine.gd", "mortality_components[\"Hunger\"]=maxf("),
    ("scripts/game_state.gd", "var factor:=lerpf(0.12,1.08,health)"),
    ("scripts/game_state.gd", "var multiplier:=1.0+maxf(0.0,0.72-health)"),
    ("scripts/game_state.gd", "var neonatal_rate:=clampf("),
    ("scripts/game_state.gd", "var maternal_rate:=clampf("),
    ("scripts/game_state.gd", "var health_factor:=lerpf(1.90,0.64"),
    ("scripts/food_system.gd", "result[\"Fresh plants\"]=workers*gathering_weight"),
    ("scripts/food_system.gd", "var early:=clampf(0.06+"),
    ("scripts/food_system.gd", "var burden_target:=clampf("),
    ("scripts/artifact_collection.gd", "return {\"weight\":weight,\"total_weight\":total"),
    ("scripts/artifact_culture.gd", "var collection:=ALLURE_COLLECTION"),
]


def row_at(rows: list, year: float):
    best = min(rows, key=lambda r: abs(r["year"] - year)) if rows else None
    return best if best is not None and abs(best["year"] - year) < 0.6 else None


def metric(row: dict, key: str):
    if key.startswith("art_"):
        a = row.get("artifacts", {})
        return {"art_studied": a.get("studied"), "art_science": a.get("science"), "art_allure": a.get("allure")}[key]
    return row.get(key)


def simulate_truth(args) -> dict:
    """Worker: surrogate runs for one truth spec (scenario, years) averaged over seeds."""
    scenario, years, seeds, overrides = args
    p = simlib.params(overrides)
    results = [simlib.run(scenario, 1000 + s, years, p) for s in range(seeds)]
    return {"rows": [r["rows"] for r in results], "discoveries": [r["discoveries"] for r in results]}


def compare(truth: dict, sim: dict) -> dict:
    years = int(truth["years"])
    out = {}
    for y in [c for c in CHECKPOINTS if c <= years]:
        t = row_at(truth["rows"], y)
        if t is None:
            continue
        for key in TOLERANCES:
            if key in ("lines_per_decade", "lines_total", "decades_total"):
                continue
            tv = metric(t, key)
            svals = [metric(row_at(rows, y) or {}, key) for rows in sim["rows"]]
            svals = [v for v in svals if v is not None]
            if tv is None or not svals:
                continue
            if key.startswith("art_") and "artifacts" not in truth["scenario"]:
                continue
            out[(key, y)] = (float(tv), float(np.mean(svals)))
    # discoveries by line x decade (engine probes that record every discovery)
    if not truth.get("discoveries"):
        return out
    real = simlib.per_decade(truth["discoveries"], years)
    total = max(1.0, sum(real.values()))
    sims = [simlib.per_decade(d, years) for d in sim["discoveries"]]
    keys = set(real) | {k for s in sims for k in s}
    dev = sum(abs(real.get(k, 0) - np.mean([s.get(k, 0) for s in sims])) for k in keys)
    out[("lines_per_decade", years)] = (total, dev / total)
    for name, index in (("lines_total", 0), ("decades_total", 1)):
        agg_r, agg_s = {}, {}
        for k, v in real.items():
            agg_r[k[index]] = agg_r.get(k[index], 0) + v
        for sim_counts in sims:
            for k, v in sim_counts.items():
                agg_s[k[index]] = agg_s.get(k[index], 0) + v / len(sims)
        dev = sum(abs(agg_r.get(k, 0) - agg_s.get(k, 0)) for k in set(agg_r) | set(agg_s))
        out[(name, years)] = (total, dev / total)
    return out


# Documented gaps (docs/research/SURROGATE_SIM.md): reported, never failing.
KNOWN_GAPS = {
    ("ai", "known"): "AI seats research ~1.3x faster in the engine than the surrogate at equal emphasis (cause not isolated)",
    ("ai", "lines_per_decade"): "AI rotation of emphasis is approximated", ("ai", "lines_total"): "AI rotation of emphasis is approximated",
    ("ai", "decades_total"): "follows the AI research gap",
    ("poor", "population"): "poor-site population falls ~20% faster than the engine's (monthly labor re-planning vs daily); populations < 60 are noisy",
    ("poor", "decades_total"): "follows the poor-site population gap (fewer researchers)",
    ("*", "food_days"): "timing of Storage Pits / Public Stores builds (settlement construction queue) is approximated",
}


def gap(scenario: str, key: str) -> str | None:
    return KNOWN_GAPS.get((scenario, key)) or KNOWN_GAPS.get(("*", key))


def within(key: str, t: float, s: float) -> bool:
    kind, tol, floor = TOLERANCES[key]
    if key in ("lines_per_decade", "lines_total", "decades_total"):
        # t is the real discovery count: Poisson noise grows as counts shrink.
        return s <= tol * max(1.0, (150.0 / max(1.0, t)) ** 0.5)
    if kind == "rel":
        return abs(s - t) <= tol * max(abs(t), floor)
    return abs(s - t) <= tol


def score(comparisons: list[dict]) -> float:
    total = 0.0
    for comp in comparisons:
        for (key, _y), (t, s) in comp.items():
            kind, tol, floor = TOLERANCES[key]
            if key in ("lines_per_decade", "lines_total", "decades_total"):
                err = s / (tol * max(1.0, (150.0 / max(1.0, t)) ** 0.5))
            else:
                err = (s - t) / (tol * max(abs(t), floor)) if kind == "rel" else (s - t) / tol
            total += min(err * err, 25.0)
    return total


def evaluate(truths: list[dict], overrides: dict, seeds: int, pool) -> tuple[float, list[dict]]:
    jobs = [(t["scenario"], int(t["years"]), seeds, overrides) for t in truths]
    sims = list(pool.map(simulate_truth, jobs))
    comps = [compare(t, s) for t, s in zip(truths, sims)]
    return score(comps), comps


def table(truths: list[dict], comps: list[dict]) -> tuple[str, int]:
    lines = ["| truth run | metric | year | real | surrogate | tolerance | ok |", "|---|---|---:|---:|---:|---|:-:|"]
    failures = 0
    for truth, comp in zip(truths, comps):
        for (key, y), (t, s) in sorted(comp.items(), key=lambda kv: (kv[0][0], kv[0][1])):
            ok = within(key, t, s)
            known_gap = None if ok else gap(truth["scenario"], key)
            failures += 0 if ok or known_gap else 1
            kind, tol, floor = TOLERANCES[key]
            tol_text = f"±{tol:.0%}" if kind == "rel" else f"±{tol:g}"
            if key in ("lines_per_decade", "lines_total", "decades_total"):
                tol_text = f"≤{tol * max(1.0, (150.0 / max(1.0, t)) ** 0.5):.0%} of real"
                t_text, s_text = f"{t:.0f} found", f"{s:.0%} off"
            else:
                t_text, s_text = f"{t:.3g}", f"{s:.3g}"
            mark = "✓" if ok else ("gap" if known_gap else "✗")
            lines.append(f"| {truth['_path'].replace('.json', '')} | {key} | {y} | {t_text} | {s_text} | {tol_text} | {mark} |")
    return "\n".join(lines), failures


def fit_space() -> dict:
    doc = json.loads((SIM / "params.json").read_text(encoding="utf-8"))
    space = {}
    for section, values in doc.items():
        if section.startswith("_") or section == "calibrated" or not isinstance(values, dict):
            continue
        for key, entry in values.items():
            if isinstance(entry, dict) and entry.get("fit") and isinstance(entry.get("value"), (int, float)) and not isinstance(entry.get("value"), bool):
                space[key] = float(entry["value"])
    return space


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fit", action="store_true")
    ap.add_argument("--rounds", type=int, default=2)
    ap.add_argument("--seeds", type=int, default=2)
    ap.add_argument("--only", nargs="*", default=None, help="fit only these params")
    ap.add_argument("--jobs", type=int, default=16)
    ap.add_argument("--report", type=Path, default=SIM / "calibration_report.json")
    ap.add_argument("--rev", default="auto", help="game revision to read ('auto': HEAD when the truth came from HEAD's files, else the working tree; '' = working tree)")
    args = ap.parse_args()
    import os
    import run_truth as _rt
    rev = _rt.truth_revision() if args.rev == "auto" else args.rev
    if rev:
        os.environ["SIM_GAME_REV"] = rev
        print(f"reading game files from {rev[:10]} (the revision the truth runs were launched from)")
    else:
        print("reading game files from the working tree")
    truths = simlib.truth_runs()
    if not truths:
        print("no ground truth in tools/sim/ground_truth (run tools/sim/run_truth.py)")
        return 2
    doc = json.loads((SIM / "params.json").read_text(encoding="utf-8"))
    current = dict(doc.get("calibrated", {}))
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        best_score, comps = evaluate(truths, current, args.seeds, pool)
        print(f"start score {best_score:.1f}")
        if args.fit:
            space = fit_space()
            if args.only:
                space = {k: v for k, v in space.items() if k in args.only}
            steps = {k: (abs(v) * 0.35 if v else 0.2) for k, v in space.items()}
            for rnd in range(args.rounds):
                for key in space:
                    base = current.get(key, space[key])
                    improved = False
                    for direction in (1.0, -1.0):
                        trial = dict(current)
                        cand = base + direction * steps[key]
                        if key.endswith("_rate") or key in ("throughput", "knowledge_effective_factor", "food_buffer", "storage_base_rations", "settlement_population"):
                            cand = max(1e-6, cand)
                        trial[key] = cand
                        sc, cp = evaluate(truths, trial, args.seeds, pool)
                        if sc < best_score:
                            best_score, comps, current = sc, cp, trial
                            improved = True
                            print(f"  round {rnd} {key} -> {cand:.5g}  score {sc:.1f}", flush=True)
                            break
                    if not improved:
                        steps[key] *= 0.5
            doc["calibrated"] = {k: (round(v, 6) if isinstance(v, float) else v) for k, v in current.items()}
            doc["calibrated"]["_fitted"] = time.strftime("%Y-%m-%d %H:%M") + f" score {best_score:.1f} on {len(truths)} truth runs"
            doc["_formula_hashes"] = {f"{p}::{a}": gdparse.line_hash(p, a) for p, a in FORMULA_ANCHORS}
            (SIM / "params.json").write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    md, failures = table(truths, comps)
    print(md)
    print(f"\nscore {best_score:.1f}; {failures} metric(s) outside tolerance")
    report = {"score": best_score, "failures": failures, "calibrated": current, "table_md": md,
              "comparisons": [{"truth": t["_path"], "rows": [[k, y, tv, sv, bool(within(k, tv, sv))] for (k, y), (tv, sv) in c.items()]} for t, c in zip(truths, comps)]}
    args.report.write_text(json.dumps(report, indent=1, ensure_ascii=False), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
