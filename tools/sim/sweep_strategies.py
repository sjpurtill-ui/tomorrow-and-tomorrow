#!/usr/bin/env python3
"""Strategy sweep: do research tradeoffs balance, or does some strategy win everything?

    python tools/sim/sweep_strategies.py                     # ~300 strategies x 4 seeds x 600 years (< 10 min on 24 processes)
    python tools/sim/sweep_strategies.py --random 100 --seeds 2 --years 300   # quick look

Strategies (all on the calibrated good site, delegated labor):
  * baselines: balanced (2 on every line), sensible (probe emphasis)
  * random mixes: Dirichlet over the 12 lines (22 emphasis units, like sensible), with a
    random Knowledge labor share (5-25 %: the research-focus cost below)
  * focused pairs and triples: 12 units split over 2-3 lines
  * timing shifts: research-heavy first then food/health, and the reverse; at 100/200/300

Opportunity cost, as the engine has it: research emphasis only divides the
Knowledge workers among questions (discovery_system.gd research_capacity_for);
it takes nobody from other work. What does cost labor is the Knowledge labor
share (the settlement's research focus): those people come out of construction,
crafting, extraction, logistics, survey, administration and defense in
proportion, while food labor is still held up by the survival guard
(GovernmentPeopleSystem._apply_survival_guard). The surrogate's `knowledge_share`
knob does exactly that, so "crushing research" shows up as lower production,
infrastructure, logistics, institutions and security.

Analysis per century: Pareto front over the outcome facets, strategies that
dominate `balanced` everywhere (free lunches), strictly dominant/degenerate
strategies, and benchmark-lead violations. Margins come from
docs/research/benchmarks_600.json "allowed_deviation": milestones may land up to
20 % before the design year, never before band_low or after band_high; a facet
may pass "high" by 15 % of |high - typical|. Without that block the placeholders
are +25 % milestone lead and high + 10 %.
Output: docs/research/STRATEGY_SWEEP.md (+ .json).
"""
from __future__ import annotations

import argparse
import itertools
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

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "docs/research/STRATEGY_SWEEP"
OUTCOMES = ["population", "life_expectancy", "infant_mortality", "food_security", "health", "cap_production", "cap_infrastructure",
            "cap_logistics", "cap_institutions", "cap_security", "cap_culture", "ecology", "known", "education"]
SENSIBLE = {"demography": 2, "nutrition": 3, "health": 3, "labor": 2, "knowledge": 2, "production": 3, "infrastructure": 2,
            "logistics": 1, "ecology": 1, "institutions": 1, "security": 1, "culture": 1}


def strategies(n_random: int, rng: np.random.Generator) -> list[dict]:
    out = [{"name": "balanced", "research": dict.fromkeys(gd.LINES, 2), "knowledge_share": -1, "kind": "baseline"},
           {"name": "sensible", "research": SENSIBLE, "knowledge_share": -1, "kind": "baseline"}]
    for i in range(n_random):
        w = rng.dirichlet(np.full(12, 0.7)) * 22
        units = np.floor(w).astype(int)
        for j in np.argsort(-(w - units))[: 22 - units.sum()]:
            units[j] += 1
        units = np.minimum(units, 12)
        share = float(rng.choice([5.2, 10.0, 17.5, 25.0]))
        out.append({"name": f"mix{i:03d}", "research": dict(zip(gd.LINES, units.tolist())), "knowledge_share": share, "kind": "random"})
    for a, b in itertools.combinations(gd.LINES, 2):
        out.append({"name": f"pair:{a}+{b}", "research": {l: (6 if l in (a, b) else 0) for l in gd.LINES}, "knowledge_share": -1, "kind": "pair"})
    for a, b, c in [tuple(rng.choice(gd.LINES, 3, replace=False)) for _ in range(40)]:
        out.append({"name": f"triple:{a}+{b}+{c}", "research": {l: (4 if l in (a, b, c) else 0) for l in gd.LINES}, "knowledge_share": -1, "kind": "triple"})
    heavy = {**dict.fromkeys(gd.LINES, 0), "knowledge": 8, "production": 4, "institutions": 4, "infrastructure": 3, "logistics": 3}
    care = {**dict.fromkeys(gd.LINES, 0), "nutrition": 6, "health": 6, "demography": 5, "labor": 3, "ecology": 2}
    for switch in (100, 200, 300):
        out.append({"name": f"research-first->care@{switch}", "kind": "timing",
                    "phases": [{"from": 0, "research": heavy, "knowledge_share": 20.0}, {"from": switch, "research": care, "knowledge_share": 5.2}]})
        out.append({"name": f"care-first->research@{switch}", "kind": "timing",
                    "phases": [{"from": 0, "research": care, "knowledge_share": 5.2}, {"from": switch, "research": heavy, "knowledge_share": 20.0}]})
    out.append({"name": "crush-research", "research": {**dict.fromkeys(gd.LINES, 1), "knowledge": 12}, "knowledge_share": 30.0, "kind": "extreme"})
    return out


def _run(args):
    strat, seed, years = args
    override = {"site": "good", "labor": simlib.scenarios()[0]["sensible"]["labor"], "research": strat.get("research", {}),
                "knowledge_share": float(strat.get("knowledge_share", -1)), "phases": strat.get("phases", [])}
    result = simlib.run("sensible", seed, years, simlib.params(), scenario_override=override)
    constants, cat = simlib.data()
    return strat["name"], facets.century_facets(result, cat, years, step=100), simlib.milestone_years(result, milestone_ids())


def milestone_ids():
    return facets.benchmarks().get("milestones", {}).get("ids") or []


def margins(bench: dict) -> tuple[float, float, str]:
    lead = bench.get("allowed_deviation") or {}
    m = float(lead.get("milestone_early_fraction", 0.25))
    o = float(lead.get("facet_over_high_fraction_of_typical_to_high_gap", -1.0))
    src = (f"docs/research/benchmarks_600.json allowed_deviation (milestones up to {m:.0%} early but never before band_low or after band_high; "
           f"facets up to {o:.0%} of |high - typical| past high)") if lead else "placeholder (+25 % milestone lead, high + 10 %)"
    return m, o, src


def better(f: str, a: float, b: float, eps: float) -> int:
    """+1 if a better than b by more than eps (relative), -1 if worse, 0 tie."""
    up = facets.FACETS[f][2]
    diff = (a - b) if up else (b - a)
    scale = max(abs(b), 1e-6)
    return 1 if diff > eps * scale else -1 if diff < -eps * scale else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--random", type=int, default=160)
    ap.add_argument("--seeds", type=int, default=4)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--jobs", type=int, default=24)
    ap.add_argument("--eps", type=float, default=0.03, help="relative tie band for dominance (seed noise)")
    args = ap.parse_args()
    t0 = time.time()
    rng = np.random.default_rng(600)
    strats = strategies(args.random, rng)
    constants, cat = simlib.data()
    bench = facets.benchmarks()
    lead_frac, out_margin, margin_src = margins(bench)
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        outs = list(pool.map(_run, [(s, 1 + k, args.years) for s in strats for k in range(args.seeds)], chunksize=2))
    fac, mil = {}, {}
    for name, f, m in outs:
        fac.setdefault(name, []).append(f)
        mil.setdefault(name, []).append(m)
    mean = {n: facets.mean_facets(v) for n, v in fac.items()}
    centuries = list(range(100, args.years + 1, 100))
    kinds = {s["name"]: s.get("kind", "") for s in strats}
    report = {"generated": time.strftime("%Y-%m-%d %H:%M"), "strategies": len(strats), "seeds": args.seeds, "years": args.years,
              "margins": {"milestone_lead": lead_frac, "outcome": out_margin, "source": margin_src}, "centuries": {}}
    for c in centuries:
        names = [n for n in mean if c in mean[n]]
        vals = {n: mean[n][c] for n in names}
        dominated_by = {n: [] for n in names}
        for a in names:
            for b in names:
                if a == b:
                    continue
                cmp = [better(f, vals[a][f], vals[b][f], args.eps) for f in OUTCOMES]
                if min(cmp) >= 0 and max(cmp) > 0:
                    dominated_by[b].append(a)
        front = [n for n in names if not dominated_by[n]]
        free_lunch = [n for n in names if n != "balanced" and "balanced" in names and
                      all(better(f, vals[n][f], vals["balanced"][f], args.eps) >= 0 for f in OUTCOMES) and
                      sum(better(f, vals[n][f], vals["balanced"][f], args.eps) > 0 for f in OUTCOMES) >= len(OUTCOMES) // 2]
        dominates_count = {n: sum(1 for m in names if n in dominated_by[m]) for n in names}
        strict = [n for n in names if dominates_count[n] == len(names) - 1]
        exceed = []
        for n in names:
            for f, metric in facets.BENCH_KEYS.items():
                b = facets.bench_at(bench, metric, c)
                v = vals[n].get(f)
                if not b or v is None or bench["metrics"][metric].get("better") not in ("higher", "lower"):
                    continue
                hi = b["high"]
                if (bench["metrics"][metric]["better"] == "higher" and v > hi * (1 + out_margin)) or \
                   (bench["metrics"][metric]["better"] == "lower" and v < hi * (1 - out_margin)):
                    exceed.append({"strategy": n, "facet": f, "value": v, "high": hi})
        report["centuries"][c] = {"front": front, "front_size": len(front), "free_lunch_vs_balanced": free_lunch, "strictly_dominant": strict,
                                  "top_dominators": sorted(dominates_count.items(), key=lambda kv: -kv[1])[:8], "benchmark_exceedances": exceed,
                                  "ranges": {f: [min(v[f] for v in vals.values()), float(np.median([v[f] for v in vals.values()])), max(v[f] for v in vals.values())] for f in OUTCOMES}}
    # milestone leads
    leads = []
    for n, runs in mil.items():
        for rid in milestone_ids():
            if rid not in cat.index:
                continue
            row = cat.rows[cat.index[rid]]
            design, band_low, band_high = row.get("design_year"), row.get("band_low", 0.0), row.get("band_high", 1e9)
            ys = [r.get(rid) for r in runs if r.get(rid) is not None]
            if design and ys:
                mean_year = float(np.mean(ys))
                why = "too early" if mean_year < max(band_low, design * (1 - lead_frac)) else "late" if mean_year > band_high else ""
                if why:
                    leads.append({"strategy": n, "milestone": rid, "mean_year": mean_year, "design": design, "why": why})
    report["milestone_leads"] = leads
    # tradeoff table: what each focused line buys/costs at 300 and 600 vs balanced
    tradeoffs = {}
    for n in mean:
        if kinds.get(n) in ("pair", "baseline"):
            continue
        row = {}
        for c in (300, args.years):
            if c not in mean[n] or c not in mean["balanced"]:
                continue
            row[c] = {f: mean[n][c][f] - mean["balanced"][c][f] for f in OUTCOMES}
        tradeoffs[n] = row
    report["tradeoffs"] = tradeoffs
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.with_suffix(".json").write_text(json.dumps(report, indent=0, default=float), encoding="utf-8")
    write_md(report, mean, kinds, centuries, time.time() - t0, args)
    print(f"wrote {OUT.with_suffix('.md').relative_to(ROOT)} ({len(strats)} strategies x {args.seeds} seeds, {time.time() - t0:.0f} s)")
    return 0


def write_md(report, mean, kinds, centuries, seconds, args) -> None:
    fmt = {f: facets.FACETS[f][1] for f in OUTCOMES}
    md = [f"# Strategy sweep ({report['strategies']} strategies × {args.seeds} seeds × {args.years} years, surrogate)", "",
          f"Generated {report['generated']} by `python tools/sim/sweep_strategies.py --random {args.random} --seeds {args.seeds} --years {args.years}` in {seconds:.0f} s. "
          "Model and its calibration: `docs/research/SURROGATE_SIM.md`. Lead margins: " + report["margins"]["source"] + ".", "",
          "Outcome facets compared: " + ", ".join(facets.FACETS[f][0] for f in OUTCOMES) +
          f". A strategy dominates another when it is at least as good on every facet (within ±{args.eps:.0%} seed noise) and better on one.", "",
          "## Summary", "", "| century | Pareto front | strategies ≥ balanced on every facet (free lunch) | strictly dominant | outcomes past high + margin |",
          "|---:|---:|---|---|---:|"]
    for c in centuries:
        r = report["centuries"].get(c)
        if not r:
            continue
        fl = ", ".join(r["free_lunch_vs_balanced"][:6]) + (" …" if len(r["free_lunch_vs_balanced"]) > 6 else "") or "none"
        md.append(f"| {c} | {r['front_size']} of {len(mean)} | {fl} ({len(r['free_lunch_vs_balanced'])}) | {', '.join(r['strictly_dominant']) or 'none'} | {len(r['benchmark_exceedances'])} |")
    last = report["centuries"].get(centuries[-1], {})
    md += ["", "## Tradeoffs of the extreme and timed strategies (Δ vs balanced)", "",
           "| strategy | century | " + " | ".join(facets.FACETS[f][0] for f in OUTCOMES) + " |", "|---|---:|" + "---:|" * len(OUTCOMES)]
    for n, row in report["tradeoffs"].items():
        if kinds.get(n) not in ("timing", "extreme"):
            continue
        for c, d in row.items():
            md.append(f"| {n} | {c} | " + " | ".join(fmt[f].format(d[f]) if not fmt[f].startswith("{:,") else f"{d[f]:+,.0f}" for f in OUTCOMES) + " |")
    md += ["", f"## Spread of outcomes at year {centuries[-1]} (min / median / max over all strategies)", "", "| facet | min | median | max |", "|---|---:|---:|---:|"]
    for f, (lo, med, hi) in last.get("ranges", {}).items():
        md.append(f"| {facets.FACETS[f][0]} | {fmt[f].format(lo)} | {fmt[f].format(med)} | {fmt[f].format(hi)} |")
    md += ["", "## Most dominant strategies by century", ""]
    for c in centuries:
        r = report["centuries"].get(c)
        if r:
            md.append(f"- **{c}**: " + ", ".join(f"{n} (beats {k})" for n, k in r["top_dominators"][:5]))
    md += ["", "## Benchmark lead violations", ""]
    if report["milestone_leads"]:
        early = [x for x in report["milestone_leads"] if x["why"] == "too early"]
        late = [x for x in report["milestone_leads"] if x["why"] == "late"]
        md.append(f"{len(early)} strategy × milestone pairs land too early and {len(late)} land after band_high.")
        md.append("")
        md.append("| strategy | milestone | mean year | design year | problem |")
        md.append("|---|---|---:|---:|---|")
        for x in (early + late)[:60]:
            md.append(f"| {x['strategy']} | {x['milestone']} | {x['mean_year']:.0f} | {x['design']:.0f} | {x['why']} |")
    else:
        md.append("Every strategy lands every benchmark milestone inside its allowed window.")
    ex = [(c, e) for c in centuries for e in report["centuries"].get(c, {}).get("benchmark_exceedances", [])]
    md += ["", f"{len(ex)} strategy × century × metric outcomes are better than the era's benchmark high by more than the allowed deviation."]
    if ex:
        md += ["", "| century | strategy | metric | value | high |", "|---:|---|---|---:|---:|"]
        for c, e in ex[:80]:
            md.append(f"| {c} | {e['strategy']} | {facets.FACETS[e['facet']][0]} | {facets.FACETS[e['facet']][1].format(e['value'])} | {e['high']:g} |")
    OUT.with_suffix(".md").write_text("\n".join(md) + "\n", encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main())
