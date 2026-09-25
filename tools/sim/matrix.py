#!/usr/bin/env python3
"""Line-maximization matrix: what pouring all research emphasis into one line buys and costs.

    python tools/sim/matrix.py --seeds 6 --years 600

Runs balanced, poor and max_<line> for each of the 12 research lines (emphasis 12
on that line, 0 elsewhere; everything else sensible play) with the calibrated
surrogate, and writes docs/research/LINE_MAX_MATRIX.md (+ .json, .tsv): every
facet by century as value and delta vs balanced, flagged against
docs/research/benchmarks_600.json (within / below low / ABOVE HIGH = better than
the best-documented societies of the era, i.e. superhuman / OUT OF BOUNDS).
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "research"))
import facets  # noqa: E402
import focus_bench  # noqa: E402  (per-focus benchmark profiles)
import shock_bench  # noqa: E402  (shock keys and widened bands, research_3000)
import gamedata as gd  # noqa: E402
import simlib  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "docs/research/LINE_MAX_MATRIX"
KEY_FACETS = ["population", "life_expectancy", "infant_mortality", "food_security", "health", "cap_production", "cap_infrastructure",
              "cap_logistics", "cap_institutions", "cap_security", "cap_culture", "known", "education"]
# Which facets each line most directly aims at (for "what it buys").
LINE_TARGETS = {
    "knowledge": ["known", "education", "per_century"], "institutions": ["cap_institutions", "legitimacy", "state_capacity"],
    "culture": ["cap_culture", "cohesion", "allure"], "labor": ["labor_efficiency", "cap_production"],
    "production": ["cap_production", "craft_output", "tool_quality"], "infrastructure": ["cap_infrastructure", "housing_ratio", "construction_rate"],
    "nutrition": ["food_security", "food_per_worker", "diet"], "health": ["health", "life_expectancy", "infant_mortality"],
    "demography": ["population", "infant_mortality", "maternal_per_100k"], "logistics": ["cap_logistics", "trade_capacity"],
    "ecology": ["ecology", "ground_health"], "security": ["cap_security", "warfare_readiness"],
}


def _run(args):
    scenario, seed, years = args[:3]
    shocks = args[3] if len(args) > 3 else False
    # Every matrix run scouts (3 % of people) and staffs artifact study (weight 2)
    # so the artifact facets are comparable; poor keeps its own site and decrees.
    result = simlib.run(scenario, seed, years, simlib.params(), scenario_override={"scouting": 0.03, "study_weight": 2}, shocks=shocks)
    constants, cat = simlib.data()
    era = {int(round(r["year"])): r.get("ceiling_era", r["year"]) for r in result["rows"]}
    episodes = shock_bench.player_episodes(result["shocks"], era) if shocks else []
    return scenario, facets.century_facets(result, cat, years, step=50), episodes


class WidenedBench(focus_bench.FocusBench):
    """FocusBench judging against the shock-widened bands of ``episodes`` (shock_bench.py)."""

    def __init__(self, episodes):
        super().__init__()
        self.episodes = episodes

    def judge(self, focus, metric, year, value):
        return shock_bench.judge(super(), focus, metric, year, value, self.episodes)


def better(facet: str, delta: float) -> float:
    """Signed improvement (positive = better) for facets with a direction."""
    direction = facets.FACETS.get(facet, ("", "", None))[2]
    if direction is None:
        return 0.0
    return delta if direction else -delta


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", type=int, default=6)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--jobs", type=int, default=24)
    ap.add_argument("--shocks", action="store_true", help="opt-in: every scenario lives through epochal shocks (writes docs/research/epochal/LINE_MAX_MATRIX_SHOCKS.*)")
    args = ap.parse_args()
    global OUT
    if args.shocks:
        OUT = ROOT / "docs/research/epochal" / (OUT.name + "_SHOCKS")
    constants, cat = simlib.data()
    bench = facets.benchmarks()
    scenarios = ["balanced", "poor"] + [f"max_{line}" for line in gd.LINES] + [f"lead_{line}" for line in gd.LINES]
    t0 = time.time()
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        outs = list(pool.map(_run, [(s, 1 + k, args.years, args.shocks) for s in scenarios for k in range(args.seeds)]))
    by, eps = {}, {}
    for scenario, fac, ep in outs:
        by.setdefault(scenario, []).append(fac)
        eps.setdefault(scenario, []).extend(ep)
    mean = {s: facets.mean_facets(v) for s, v in by.items()}
    centuries = [c for c in range(100, args.years + 1, 100)]
    names = list(facets.FACETS) + [f"line_{l}" for l in gd.LINES]
    base = mean["balanced"]
    # ---- flat records (json/csv)
    records = []
    for s in scenarios:
        for c in centuries:
            for f in names:
                v = mean[s].get(c, {}).get(f)
                if v is None:
                    continue
                b = base.get(c, {}).get(f)
                records.append({"scenario": s, "century": c, "facet": f, "value": v, "delta_vs_balanced": None if b is None else v - b,
                                "flag": facets.flag(bench, f, c, v)})
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # .tsv, not .csv: Godot imports every .csv in the project as a translation table.
    with open(OUT.with_suffix(".tsv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(records[0]), delimiter="	")
        w.writeheader()
        w.writerows(records)
    OUT.with_suffix(".json").write_text(json.dumps({"generated": time.strftime("%Y-%m-%d %H:%M"), "seeds": args.seeds, "years": args.years,
                                                    "benchmarks": bench.get("_source"), "records": records}, indent=0), encoding="utf-8")
    # ---- focus judgement (tools/research/focus_bench.py): each scenario against its own profile
    fs = focus_bench.FocusBench()
    judgement = {}
    for s in scenarios:
        if s.startswith("max_"):
            research = {l: (12 if l == s[4:] else 0) for l in gd.LINES}
        elif s.startswith("lead_"):
            research = {l: (12 if l == s[5:] else 1) for l in gd.LINES}
        else:
            research = dict.fromkeys(gd.LINES, 2)
        rows = {}
        for c in centuries:
            if c not in mean[s] or c not in base:
                continue
            focus = fs.classify({"research": research}, c)
            jfs = WidenedBench(eps.get(s, [])) if args.shocks else fs
            chk = jfs.check_run(focus, {c: mean[s][c]}, balanced=None if s == "balanced" else {c: base[c]})
            above = [f"{a['flag']} {a['metric']}" for a in chk["flags"] if a["flag"] in ("ABOVE FOCUS HIGH", "OUT OF BOUNDS")]
            unpaid = [f for f, v in chk["costs"].get(float(c), {}).items() if v["status"] == "UNPAID"]
            free = [f for f, v in chk["relative"].get(float(c), {}).items() if v["status"] == "FREE LUNCH"]
            rows[c] = {"focus": focus, "above": above, "unpaid": unpaid, "free_lunch": free}
        judgement[s] = rows
    # ---- markdown
    md = [f"# Research line maximization matrix (surrogate{', epochal shocks on' if args.shocks else ''}, {args.seeds} seeds x {args.years} years)", "",
          f"Generated {time.strftime('%Y-%m-%d %H:%M')} by `python tools/sim/matrix.py --seeds {args.seeds} --years {args.years}{' --shocks' if args.shocks else ''}` "
          f"({time.time() - t0:.0f} s). Surrogate model: `tools/sim` (see `docs/research/SURROGATE_SIM.md` for what it models, "
          f"its calibration against the real engine, and its known gaps). Benchmarks: `{bench.get('_source')}`.", "",
          "Each `max_<line>` run puts the full research emphasis (12) on one line and none on the others; `lead_<line>` puts 12 on the line "
          "and the minimum (1) on each other line, so cross-line foundations keep arriving. Labor, site and decrees are sensible good-site play; "
          "every run scouts with 3 % of its people and staffs artifact study at weight 2. `balanced` puts 2 on every line; `poor` is the poor-site probe scenario. Values are means over seeds; "
          "Δ is against `balanced` at the same century. Flags compare with the benchmark table (within = between the era's low and high; "
          "**ABOVE HIGH** = better than the best-documented societies of the era by more than benchmarks_600.json allowed_deviation, i.e. superhuman; below low = worse than poor societies; "
          "OUT OF BOUNDS = outside min..max plausibility).", "",
          "## Summary", "",
          "| scenario | aims at: Δ at 300 / 600 | biggest costs at 600 (vs balanced) | discoveries by 600 (Δ) | benchmark flags (ABOVE HIGH / below low / OUT) |",
          "|---|---|---|---|---|"]
    for s in scenarios:
        if s == "balanced":
            continue
        line = s.split("_", 1)[1] if s.startswith(("max_", "lead_")) else None
        aims = []
        for f in LINE_TARGETS.get(line, KEY_FACETS[:3]):
            fmt = facets.FACETS.get(f, (f, "{:.2f}", True))[1]
            d3 = mean[s].get(300, {}).get(f, 0) - base.get(300, {}).get(f, 0)
            d6 = mean[s].get(args.years, {}).get(f, 0) - base.get(args.years, {}).get(f, 0)
            aims.append(f"{facets.FACETS.get(f, (f,))[0]} {fmt.format(d3)} / {fmt.format(d6)}")
        losses = []
        for f in names:
            if f.startswith("line_") or f in ("per_century",):
                continue
            v, b = mean[s].get(args.years, {}).get(f), base.get(args.years, {}).get(f)
            if v is None or b is None or facets.FACETS.get(f, ("", "", None))[2] is None:
                continue
            rel = better(f, v - b) / max(1e-6, abs(b))
            losses.append((rel, f, v - b))
        losses.sort()
        cost = ", ".join(f"{facets.FACETS[f][0]} {facets.FACETS[f][1].format(d)}" for rel, f, d in losses[:3] if rel < -0.02) or "none material"
        k6 = mean[s].get(args.years, {}).get("known", 0)
        kb = base.get(args.years, {}).get("known", 0)
        flags = [r["flag"] for r in records if r["scenario"] == s]
        md.append(f"| {s} | {'; '.join(aims)} | {cost} | {k6:.0f} ({k6 - kb:+.0f}) | {flags.count('ABOVE HIGH')} / {flags.count('below low')} / {flags.count('OUT OF BOUNDS')} |")
    md += ["", "### Benchmark violations", ""]
    viol = [r for r in records if r["flag"] in ("ABOVE HIGH", "OUT OF BOUNDS")]
    if not viol:
        md.append("No scenario is better than the era's best-documented societies on any benchmarked metric.")
    else:
        md.append("| scenario | century | metric | value | flag |")
        md.append("|---|---:|---|---:|---|")
        for r in viol:
            fmt = facets.FACETS.get(r["facet"], (r["facet"], "{:.2f}", None))[1]
            md.append(f"| {r['scenario']} | {r['century']} | {facets.FACETS.get(r['facet'], (r['facet'],))[0]} | {fmt.format(r['value'])} | {r['flag']} |")
    low = [r for r in records if r["flag"] == "below low"]
    md += ["", f"{len(low)} value(s) fall below the era's poor-society level (listed per scenario below, marked ▼).", ""]
    md += ["## Detail by scenario", "", "Each cell: value (Δ vs balanced). ▲ = ABOVE HIGH (past the allowed deviation), △ = above high but within the allowance, ▼ = below low, ✗ = out of bounds.", ""]
    for s in scenarios:
        cols = centuries if args.years <= 600 else [c for c in centuries if c % 300 == 0]   # long runs: every third century
        md += [f"### {s}", "", "| facet | " + " | ".join(str(c) for c in cols) + " |", "|---|" + "---:|" * len(cols)]
        for f in names:
            label, fmt, _dir = facets.FACETS.get(f, (f.replace("line_", "discoveries/century: "), "{:.0f}", None))
            cells = []
            for c in cols:
                v = mean[s].get(c, {}).get(f)
                if v is None:
                    cells.append("")
                    continue
                mark = {"ABOVE HIGH": " ▲", "above high (allowed)": " △", "below low": " ▼", "OUT OF BOUNDS": " ✗"}.get(facets.flag(bench, f, c, v), "")
                b = base.get(c, {}).get(f)
                delta = "" if s == "balanced" or b is None else f" ({fmt.format(v - b) if not fmt.startswith('{:,') else f'{v - b:+,.0f}'})"
                if delta and not delta.startswith(" (-") and not delta.startswith(" (+"):
                    delta = " (+" + delta[2:]
                cells.append(fmt.format(v) + delta + mark)
            md.append(f"| {label} | " + " | ".join(cells) + " |")
        md.append("")
    md += ["", "## Focus judgement (docs/research/benchmarks_focus_600.json)", "",
           "Each scenario is classified (`FocusBench.classify`: max_/lead_ runs as their line, balanced and poor as balanced) and judged against its own focus profile, "
           "its required costs and balanced (`check_run`). `poor` is bad play on a poor site, so only plausibility (OUT OF BOUNDS) matters for it.", "",
           "| scenario | " + " | ".join(str(c) for c in centuries) + " |", "|---|" + "---|" * len(centuries)]
    for s_name, rows in judgement.items():
        cells = []
        for c in centuries:
            r = rows.get(c)
            if r is None:
                cells.append("-")
                continue
            probs = r["above"] + [f"UNPAID {u}" for u in r["unpaid"]] + [f"FREE LUNCH {f}" for f in r["free_lunch"]]
            if s_name == "poor":
                probs = [p for p in probs if p.startswith("OUT")]
            cells.append("ok" if not probs else "; ".join(probs))
        md.append(f"| {s_name} | " + " | ".join(cells) + " |")
    OUT.with_suffix(".md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(f"wrote {OUT.with_suffix('.md').relative_to(ROOT)} (+ .json, .tsv) in {time.time() - t0:.0f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
