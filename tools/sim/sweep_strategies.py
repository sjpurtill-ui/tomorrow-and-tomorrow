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
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "research"))
import facets  # noqa: E402
import focus_bench  # noqa: E402  (tools/research/focus_bench.py: per-focus benchmark profiles)
import shock_bench  # noqa: E402  (shock keys and widened bands, research_3000)
import gamedata as gd  # noqa: E402
import simlib  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "docs/research/STRATEGY_SWEEP"
OUTCOMES = ["population", "life_expectancy", "infant_mortality", "food_security", "health", "cap_production", "cap_infrastructure",
            "cap_logistics", "cap_institutions", "cap_security", "cap_culture", "ecology", "known", "education"]
SENSIBLE = {"demography": 2, "nutrition": 3, "health": 3, "labor": 2, "knowledge": 2, "production": 3, "infrastructure": 2,
            "logistics": 1, "ecology": 1, "institutions": 1, "security": 1, "culture": 1}


class WidenedBench(focus_bench.FocusBench):
    """FocusBench judging against the shock-widened bands of ``episodes`` (shock_bench.py)."""

    def __init__(self, episodes):
        super().__init__()
        self.episodes = episodes

    def judge(self, focus, metric, year, value):
        return shock_bench.judge(super(), focus, metric, year, value, self.episodes)


def strategies(n_random: int, rng: np.random.Generator, years: int = 600) -> list[dict]:
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
    for switch in [s for s in (100, 200, 300, 1200, 2400) if s < years]:
        out.append({"name": f"research-first->care@{switch}", "kind": "timing",
                    "phases": [{"from": 0, "research": heavy, "knowledge_share": 20.0}, {"from": switch, "research": care, "knowledge_share": 5.2}]})
        out.append({"name": f"care-first->research@{switch}", "kind": "timing",
                    "phases": [{"from": 0, "research": care, "knowledge_share": 5.2}, {"from": switch, "research": heavy, "knowledge_share": 20.0}]})
    out.append({"name": "crush-research", "research": {**dict.fromkeys(gd.LINES, 1), "knowledge": 12}, "knowledge_share": 30.0, "kind": "extreme"})
    # Exploration-heavy play: scouting parties (share of people out exploring)
    # and artifact study. NOTE: the surrogate models finds and study, but has no
    # scout-attrition model (codex/scout-survival owns that in the game scripts).
    # Canonical focus strategies (docs/research/benchmarks_focus_600.json surrogate_spec):
    # every line focus and archetype, judged against its own profile.
    fs = focus_bench.FocusBench()
    for fname in fs.focus_names():
        # research_3000: every window's focuses and archetypes; the spec of the latest
        # window that defines it, judged from the first window that knows it.
        wins = [w for w in fs.windows if fname in w.focuses and w.start < years]
        specs = [(w.focuses[fname].get("strategy") or {}).get("surrogate_spec") for w in wins]
        specs = [s for s in specs if s]
        if not specs:
            continue
        spec = specs[-1]
        out.append({"name": f"focus:{fname}", "research": spec.get("research", {}), "knowledge_share": float(spec.get("knowledge_share", -1)),
                    "labor": spec.get("labor"), "policies": spec.get("policies", []), "focus_id": fname, "kind": "focus",
                    "judge_from": wins[0].start})
    for share in (0.03, 0.06):
        out.append({"name": f"scouting-heavy@{share:.0%}", "research": dict.fromkeys(gd.LINES, 2), "knowledge_share": -1,
                    "scouting": share, "study_weight": 2, "kind": "extreme"})
    return out


def _run(args):
    strat, seed, years = args[:3]
    shocks = args[3] if len(args) > 3 else False
    override = {"site": "good", "labor": strat.get("labor") or simlib.scenarios()[0]["sensible"]["labor"], "research": strat.get("research", {}),
                "policies": list(strat.get("policies", [])),
                "knowledge_share": float(strat.get("knowledge_share", -1)), "phases": strat.get("phases", []),
                "scouting": float(strat.get("scouting", 0.0)), "study_weight": int(strat.get("study_weight", 0))}
    result = simlib.run("sensible", seed, years, simlib.params(), scenario_override=override, shocks=shocks)
    constants, cat = simlib.data()
    era = {int(round(r["year"])): r.get("ceiling_era", r["year"]) for r in result["rows"]}
    episodes = shock_bench.player_episodes(result["shocks"], era) if shocks else []
    return strat["name"], facets.century_facets(result, cat, years, step=100), simlib.milestone_years(result, milestone_ids()), episodes


def milestone_ids():
    """Milestone ids of every benchmark window (research_3000: all five files)."""
    ids = []
    for path in sorted((ROOT / "docs/research").glob("benchmarks_[0-9]*.json"), key=lambda p: int(p.stem.split("_")[1])):
        for rid in (json.loads(path.read_text(encoding="utf-8")).get("milestones") or {}).get("ids") or []:
            if rid not in ids:
                ids.append(rid)
    return ids


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
    ap.add_argument("--shocks", action="store_true", help="opt-in: every strategy lives through epochal shocks (writes docs/research/epochal/STRATEGY_SWEEP_SHOCKS.*)")
    args = ap.parse_args()
    global OUT
    if args.shocks:
        OUT = ROOT / "docs/research/epochal" / (OUT.name + "_SHOCKS")
    t0 = time.time()
    rng = np.random.default_rng(600)
    strats = strategies(args.random, rng, args.years)
    constants, cat = simlib.data()
    bench = facets.benchmarks()
    lead_frac, out_margin, margin_src = margins(bench)
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        outs = list(pool.map(_run, [(s, 1 + k, args.years, args.shocks) for s in strats for k in range(args.seeds)], chunksize=2))
    fac, mil, eps = {}, {}, {}
    for name, f, m, e in outs:
        fac.setdefault(name, []).append(f)
        mil.setdefault(name, []).append(m)
        eps.setdefault(name, []).append(e)
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
    # Focus profiles (tools/research/focus_bench.py): each strategy is judged
    # against its own focus band, required costs and the balanced run.
    fs = focus_bench.FocusBench()
    by_name = {s["name"]: s for s in strats}
    judged = {}
    for n in mean:
        verdicts = {}
        # With shocks, every shock recorded in any seed widens the bands it overlaps.
        jfs = WidenedBench([x for run in eps.get(n, []) for x in run]) if args.shocks else fs
        for c in centuries:
            if c not in mean[n] or c not in mean.get("balanced", {}):
                continue
            if c <= float(by_name[n].get("judge_from", 0.0)):
                continue   # an archetype is judged only once its window defines it
            focus = fs.classify(by_name[n], c)
            chk = jfs.check_run(focus, {c: mean[n][c]}, balanced={c: mean["balanced"][c]})
            above = [f for f in chk["flags"] if f["flag"] in ("ABOVE FOCUS HIGH", "OUT OF BOUNDS")]
            unpaid = [f for f, v in chk["costs"].get(float(c), {}).items() if v["status"] == "UNPAID"]
            free = [f for f, v in chk["relative"].get(float(c), {}).items() if v["status"] == "FREE LUNCH" and n != "balanced"]
            verdicts[c] = {"focus": focus, "above": above, "unpaid": unpaid, "free_lunch": free, "ok": not above and not unpaid and not free}
        judged[n] = verdicts
    report["focus_judgement"] = judged
    if args.shocks:
        report["shock_rates"] = shock_bench.player_rates([run for runs in eps.values() for run in runs], args.years)
        report["shock_hazards"] = shock_bench.benchmark_hazards()
    # tradeoff table: what each focused line buys/costs at 300 and 600 vs balanced
    tradeoffs = {}
    for n in mean:
        if kinds.get(n) in ("pair", "baseline"):
            continue
        row = {}
        for c in sorted({300, 1200, 2400, args.years}):
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
    md = [f"# Strategy sweep ({report['strategies']} strategies × {args.seeds} seeds × {args.years} years, surrogate{', epochal shocks on' if args.shocks else ''})", "",
          f"Generated {report['generated']} by `python tools/sim/sweep_strategies.py --random {args.random} --seeds {args.seeds} --years {args.years}{' --shocks' if args.shocks else ''}` in {seconds:.0f} s. "
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
    fj = report.get("focus_judgement", {})
    md += ["", "## Focus judgement (docs/research/benchmarks_focus_*.json via tools/research/focus_bench.py)", "",
           "Every run is classified per century (`FocusBench.classify`) and judged against its own focus profile, its required costs and the same-seed balanced run (`check_run`). "
           "A run fails with ABOVE FOCUS HIGH / OUT OF BOUNDS (past its focus band or plausibility), UNPAID (a required cost not paid) or FREE LUNCH (boosted with no cost vs balanced).", "",
           "| century | runs judged | ABOVE FOCUS HIGH / OUT | UNPAID cost | FREE LUNCH | all pass |", "|---:|---:|---:|---:|---:|---:|"]
    for c in centuries:
        rows = [v[c] for v in fj.values() if c in v]
        if rows:
            md.append(f"| {c} | {len(rows)} | {sum(1 for r in rows if r['above'])} | {sum(1 for r in rows if r['unpaid'])} | {sum(1 for r in rows if r['free_lunch'])} | {sum(1 for r in rows if r['ok'])} |")
    md += ["", "Pass rate by window (share of judged strategy-centuries with no failure; `unpaid known only` counts the runs whose only failure is "
           "the balanced blend's discoveries_known cost):", "", "| window | judged | pass | pass rate | unpaid known only |", "|---|---:|---:|---:|---:|"]
    for lo, hi in ((0, 600), (600, 1200), (1200, 1800), (1800, 2400), (2400, 3000)):
        rows = [v[c] for v in fj.values() for c in v if lo < c <= hi]
        if rows:
            only = sum(1 for r in rows if not r["ok"] and not r["above"] and not r["free_lunch"] and r["unpaid"] == ["balanced"])
            md.append(f"| {lo}-{hi} | {len(rows)} | {sum(1 for r in rows if r['ok'])} | {sum(1 for r in rows if r['ok']) / len(rows):.0%} | {only} |")
    if report.get("shock_rates"):
        keys = shock_bench.KEYS
        md += ["", "Shock episodes per game century (all runs) vs the window's benchmark hazard range:", "",
               "| window | " + " | ".join(keys) + " |", "|---|" + "---|" * len(keys)]
        for w, r in report["shock_rates"].items():
            hz = report["shock_hazards"].get(w, {})
            md.append(f"| {w} | " + " | ".join(f"{r[k]:.2f}" + (f" ({hz[k][0]}-{hz[k][1]})" if k in hz else "") for k in keys) + " |")
    fails = [(n, c, v) for n, vs in fj.items() for c, v in vs.items() if not v["ok"]]
    if fails:
        md += ["", "| strategy | century | focus | problem |", "|---|---:|---|---|"]
        for n, c, v in fails[:120]:
            prob = "; ".join([f"{a['flag']} {a['metric']}={a['value']:.4g}" for a in v["above"]] + [f"UNPAID {u}" for u in v["unpaid"]] + [f"FREE LUNCH {f}" for f in v["free_lunch"]])
            md.append(f"| {n} | {c} | {', '.join(f'{k} {w:.2f}' for k, w in v['focus'].items())} | {prob} |")
    focus_rows = [n for n in fj if kinds.get(n) in ("focus",) or n.startswith("scouting")]
    if focus_rows:
        md += ["", "### Canonical focus strategies and scouting (Δ vs balanced at 300 / final year)", "",
               "| strategy | " + " | ".join(facets.FACETS[f][0] for f in OUTCOMES) + " |", "|---|" + "---:|" * len(OUTCOMES)]
        for n in focus_rows:
            row = report["tradeoffs"].get(n, {})
            cells = []
            for f in OUTCOMES:
                a, b = row.get(300, {}).get(f), row.get(args.years, {}).get(f)
                cells.append("/".join("—" if v is None else (f"{v:+,.0f}" if fmt[f].startswith("{:,") else fmt[f].format(v)) for v in (a, b)))
            md.append(f"| {n} | " + " | ".join(cells) + " |")
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
