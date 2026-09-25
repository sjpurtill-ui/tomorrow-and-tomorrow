#!/usr/bin/env python3
"""Epochal shocks in the surrogate: frequencies, losses, recovery and strategy resilience.

    python tools/sim/shock_report.py                    # 30 strategies x 8 seeds x 600 years, shocks on and off
    python tools/sim/shock_report.py --seeds 3 --years 300 --quick

Every strategy runs twice per seed: without shocks (the calibrated surrogate) and inside
the multi-civ epochal-shock world (``shock_world.py``). Paired differences are the shock
cost. Writes docs/research/epochal/SHOCKS_IN_SURROGATE.md (+ .json).
"""
from __future__ import annotations

import argparse
import collections
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
from shocks.catalog import TYPES  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "docs/research/epochal/SHOCKS_IN_SURROGATE"
OUTCOMES = ["population", "life_expectancy", "infant_mortality", "food_security", "health", "cap_production", "cap_institutions",
            "cap_security", "known", "education"]
RESILIENCE = ["food_reserve", "health_knowledge", "institutions", "diversification", "trade", "density", "legitimacy", "cohesion"]


def strategies(quick: bool) -> list[dict]:
    table = simlib.scenarios()[0]
    labor = table["sensible"]["labor"]
    out = [{"name": "balanced", "scenario": "balanced", "kind": "baseline"},
           {"name": "sensible", "scenario": "sensible", "kind": "baseline"},
           {"name": "research focus", "scenario": "research", "kind": "labor"}]
    lines = gd.LINES if not quick else ["nutrition", "health", "institutions", "knowledge"]
    for line in lines:
        out.append({"name": f"lead_{line}", "scenario": f"lead_{line}", "kind": "line"})
    pols = ["public_assembly", "care_rotation", "water_security", "family_support", "foraging_drive", "conservation_order",
            "expanded_watch", "labor_mobilization", "mass_repression", "rationing"]
    for pol in (pols if not quick else pols[:3]):
        out.append({"name": f"decree:{pol}", "scenario": "sensible", "override": {"policies": [pol]}, "kind": "policy"})
    granary = dict(labor, Food=labor["Food"] + 8.0, Crafting=labor["Crafting"] - 4.0, Construction=labor["Construction"] - 4.0)
    out.append({"name": "granary labor (+8 % food)", "scenario": "sensible", "override": {"labor": granary}, "kind": "labor"})
    lean = dict(labor, Food=labor["Food"] - 6.0, Knowledge=labor["Knowledge"] + 6.0)
    out.append({"name": "lean food (-6 % food, +6 % knowledge)", "scenario": "sensible", "override": {"labor": lean}, "kind": "labor"})
    return out


def _run(args):
    strat, seed, years, shocks = args
    t = time.time()
    r = simlib.run(strat["scenario"], seed, years, simlib.params(), scenario_override=strat.get("override"), shocks=shocks)
    constants, cat = simlib.data()
    fac = facets.century_facets(r, cat, years, step=100)
    return strat["name"], seed, shocks, fac, r.get("shocks"), time.time() - t


def recovery(log: list, threshold: float = 0.03) -> list:
    """(year, loss share, years to regain the pre-shock population or None)."""
    pops = np.array([x["pop_after"] for x in log])
    out, skip_until = [], -1
    for k, x in enumerate(log):
        if x["year"] <= skip_until:
            continue
        loss = 1.0 - x["pop_after"] / max(1.0, x["pop_before"])
        if loss < threshold:
            continue
        # merge a multi-year episode: the trough is the lowest point in the next 10 years
        window = pops[k:k + 10]
        trough = int(np.argmin(window)) + k
        total = 1.0 - pops[trough] / max(1.0, x["pop_before"])
        back = np.where(pops[trough:] >= x["pop_before"])[0]
        years = int(log[trough + back[0]]["year"] - x["year"]) if back.size else None
        out.append((x["year"], total, years))
        skip_until = log[trough]["year"]
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", type=int, default=8)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--jobs", type=int, default=16)
    ap.add_argument("--quick", action="store_true")
    ap.add_argument("--render", action="store_true", help="rewrite the .md from the saved .json without running")
    args = ap.parse_args()
    if args.render:
        rep = json.loads(OUT.with_suffix(".json").read_text(encoding="utf-8"))
        args.seeds, args.years = rep["seeds"], rep["years"]
        dom = {False: rep["dominance"]["off"], True: rep["dominance"]["on"]}
        write_md(rep, dom, list(range(100, rep["years"] + 1, 100)), rep.get("seconds", 0.0), args)
        print(f"rendered {OUT.with_suffix('.md').relative_to(ROOT)}")
        return 0
    t0 = time.time()
    strats = strategies(args.quick)
    kinds = {s["name"]: s["kind"] for s in strats}
    jobs = [(s, 1 + k, args.years, sh) for s in strats for k in range(args.seeds) for sh in (False, True)]
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        outs = list(pool.map(_run, jobs, chunksize=1))
    times = {False: [], True: []}
    fac = collections.defaultdict(dict)       # (name, shocks) -> seed -> facets
    logs = collections.defaultdict(dict)      # name -> seed -> shock log
    for name, seed, sh, f, lg, dt in outs:
        times[sh].append(dt)
        fac[(name, sh)][seed] = f
        if sh:
            logs[name][seed] = lg
    centuries = list(range(100, args.years + 1, 100))
    Y = args.years
    # ---------------------------------------------------------------- world-level rates
    onsets, civ_years, births, deaths = collections.Counter(), collections.Counter(), collections.Counter(), collections.Counter()
    alive_min, alive_max, god_moves, runs = 10 ** 9, 0, 0, 0
    for name, by_seed in logs.items():
        for lg in by_seed.values():
            runs += 1
            for k, v in lg["onsets"].items():
                c, t = k.split(":")
                onsets[(int(c), t)] += v
            for c, v in lg["civ_years"].items():
                civ_years[int(c)] += v
            for k, v in lg["births"].items():
                c, t = k.split(":")
                births[(int(c), t)] += v
            for k, v in lg["deaths"].items():
                c, t = k.split(":")
                deaths[(int(c), t)] += v
            alive_min, alive_max = min(alive_min, min(lg["alive"])), max(alive_max, max(lg["alive"]))
            god_moves += lg["god_moves"]
    # ---------------------------------------------------------------- player-level
    per = {}
    rows_for_fit = []
    for s in strats:
        n = s["name"]
        seeds = sorted(logs[n])
        deaths_type = collections.Counter()
        hits = collections.Counter()
        rec, worst = [], []
        for sd in seeds:
            lg = logs[n][sd]
            dfrac = collections.Counter()
            for x in lg["player"]:
                for t, v in x["by_type"].items():
                    dfrac[t] += v
            for t, v in dfrac.items():
                deaths_type[t] += v / len(seeds)
            seen = set()
            for e in lg["player_episodes"]:
                if e["episode"] not in seen:
                    seen.add(e["episode"])
                    hits[e["type"]] += 1 / len(seeds)
            r = recovery(lg["player"])
            rec += r
            worst.append(max([x[1] for x in r], default=0.0))
            mean_row = {k: float(np.mean([x["row"][k] for x in lg["player"]])) for k in RESILIENCE}
            total_loss = sum(v for t, v in dfrac.items() if t in TYPES)
            per_type = {}
            eps = {e["episode"]: e for e in lg["player_episodes"]}.values()
            for t in ("famine", "pandemic", "collapse", "climate"):
                per_type[t + " hits"] = sum(1 for e in eps if e["type"] == t)
            per_type["pandemic deaths"] = dfrac.get("pandemic", 0.0)
            per_type["collapse deaths"] = dfrac.get("collapse", 0.0)
            per_type["famine (engine est.)"] = dfrac.get("famine_engine_estimate", 0.0)
            per_type["breakaway"] = dfrac.get("breakaway", 0.0)
            rows_for_fit.append((n, mean_row, total_loss, per_type))
        pop_on = [fac[(n, True)][sd].get(Y, {}).get("population") for sd in seeds]
        pop_off = [fac[(n, False)][sd].get(Y, {}).get("population") for sd in seeds]
        cost = [1 - a / b for a, b in zip(pop_on, pop_off) if a and b]
        def cum(key):
            return float(np.mean([sum(x["by_type"].get(key, 0.0) for x in logs[n][sd]["player"]) for sd in seeds]))
        breakaway, colonists, absorbed = cum("breakaway"), cum("colonists"), cum("absorbed_gain")
        net_mig = float(np.mean([sum(x["immig"] - x["emig"] for x in logs[n][sd]["player"]) for sd in seeds]))
        fam_est = float(np.mean([sum(x["by_type"].get("famine_engine_estimate", 0.0) for x in logs[n][sd]["player"]) for sd in seeds]))
        outc = {}
        for f in OUTCOMES:
            on = np.mean([fac[(n, True)][sd].get(Y, {}).get(f, np.nan) for sd in seeds])
            off = np.mean([fac[(n, False)][sd].get(Y, {}).get(f, np.nan) for sd in seeds])
            outc[f] = (float(off), float(on))
        recovered = [x[2] for x in rec if x[2] is not None]
        per[n] = {"kind": kinds[n], "deaths_by_type": dict(deaths_type), "shock_deaths": float(sum(v for t, v in deaths_type.items() if t in TYPES)),
                  "hits_per_century": {t: v / (Y / 100) for t, v in hits.items()}, "breakaway": breakaway, "colonists": colonists, "absorbed_gain": absorbed, "famine_engine_estimate": fam_est, "net_migration": net_mig, "pop_cost_600": float(np.mean(cost)) if cost else None,
                  "pop_cost_sd": float(np.std(cost)) if cost else None, "episodes_3pct": len(rec) / len(seeds),
                  "recovery_median": float(np.median(recovered)) if recovered else None,
                  "unrecovered": sum(1 for x in rec if x[2] is None), "worst_mean": float(np.mean(worst)), "outcomes": outc}
    # ---------------------------------------------------------------- resilience fit
    X = np.array([[r[1][k] for k in RESILIENCE] for r in rows_for_fit])
    yv = np.array([r[2] for r in rows_for_fit])
    Z = (X - X.mean(0)) / np.maximum(1e-9, X.std(0))
    A = np.column_stack([np.ones(len(yv)), Z])
    coef, *_ = np.linalg.lstsq(A, yv, rcond=None)
    corr = {k: float(np.corrcoef(X[:, j], yv)[0, 1]) if X[:, j].std() > 1e-9 else 0.0 for j, k in enumerate(RESILIENCE)}
    type_corr = {}
    for tk in rows_for_fit[0][3]:
        yt = np.array([r[3][tk] for r in rows_for_fit], dtype=float)
        type_corr[tk] = {k: (float(np.corrcoef(X[:, j], yt)[0, 1]) if X[:, j].std() > 1e-9 and yt.std() > 1e-12 else 0.0)
                         for j, k in enumerate(RESILIENCE)}
        type_corr[tk]["_mean"] = float(yt.mean())
    pred = A @ coef
    r2 = 1 - float(((yv - pred) ** 2).sum() / max(1e-12, ((yv - yv.mean()) ** 2).sum()))
    # ---------------------------------------------------------------- dominance on vs off
    def dominance(sh):
        vals = {s["name"]: {f: np.mean([fac[(s["name"], sh)][sd].get(Y, {}).get(f, np.nan) for sd in fac[(s["name"], sh)]]) for f in OUTCOMES}
                for s in strats}
        # tie band: 3 % or two pooled standard errors of a seed mean, whichever is wider
        band = {}
        nseed = max(1, len(fac[(strats[0]["name"], sh)]))
        for f in OUTCOMES:
            rel = [np.std([fac[(s["name"], sh)][sd].get(Y, {}).get(f, np.nan) for sd in fac[(s["name"], sh)]]) / max(1e-9, abs(vals[s["name"]][f]))
                   for s in strats]
            band[f] = max(0.03, 2.0 * float(np.nanmean(rel)) / np.sqrt(nseed))
        names = list(vals)
        beats = collections.Counter()
        dominated = collections.Counter()
        for a in names:
            for b in names:
                if a == b:
                    continue
                cmp = []
                for f in OUTCOMES:
                    up = facets.FACETS[f][2]
                    d = (vals[a][f] - vals[b][f]) * (1 if up else -1)
                    sc = max(abs(vals[b][f]), 1e-6)
                    cmp.append(1 if d > band[f] * sc else -1 if d < -band[f] * sc else 0)
                if min(cmp) >= 0 and max(cmp) > 0:
                    beats[a] += 1
                    dominated[b] += 1
        front = [n for n in names if dominated[n] == 0]
        strict = [n for n in names if beats[n] == len(names) - 1]
        rank_pop = sorted(names, key=lambda n: -vals[n]["population"])
        return {"front": front, "strict": strict, "top": beats.most_common(5), "rank_pop": rank_pop[:5], "vals": vals,
                "pop_band": band["population"]}
    dom = {sh: dominance(sh) for sh in (False, True)}
    report = {"generated": time.strftime("%Y-%m-%d %H:%M"), "seeds": args.seeds, "years": Y, "strategies": len(strats),
              "seconds_per_run": {"off": float(np.mean(times[False])), "on": float(np.mean(times[True])), "on_max": float(max(times[True]))},
              "world": {"onsets": {f"{c}:{t}": v for (c, t), v in onsets.items()}, "civ_years": dict(civ_years),
                        "births": {f"{c}:{t}": v for (c, t), v in births.items()}, "deaths": {f"{c}:{t}": v for (c, t), v in deaths.items()},
                        "alive_range": [alive_min, alive_max], "god_moves": god_moves, "runs": runs},
              "player": per, "resilience_fit": {"coef": dict(zip(["intercept"] + RESILIENCE, map(float, coef))), "corr": corr, "r2": r2,
                                                "n": len(yv), "by_type": type_corr},
              "dominance": {("on" if sh else "off"): {k: v for k, v in d.items() if k != "vals"} for sh, d in dom.items()}}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    report["seconds"] = time.time() - t0
    report["quick"] = bool(args.quick)
    OUT.with_suffix(".json").write_text(json.dumps(report, indent=0, default=float), encoding="utf-8")
    write_md(report, dom, centuries, time.time() - t0, args)
    print(f"wrote {OUT.with_suffix('.md').relative_to(ROOT)} ({len(jobs)} runs, {time.time() - t0:.0f} s; "
          f"{report['seconds_per_run']['on']:.1f} s/run with shocks, {report['seconds_per_run']['off']:.1f} s without)")
    return 0


def headline(rep, dom):
    per = rep["player"]
    vals = list(per.values())
    mean = lambda k: float(np.mean([v[k] for v in vals if v[k] is not None]))
    col = float(np.mean([v["deaths_by_type"].get("collapse", 0.0) for v in vals]))
    pan = float(np.mean([v["deaths_by_type"].get("pandemic", 0.0) for v in vals]))
    rec = [v["recovery_median"] for v in vals if v["recovery_median"] is not None]
    lo = min(per, key=lambda n: per[n]["shock_deaths"])
    hi = max(per, key=lambda n: per[n]["shock_deaths"])
    fit = rep["resilience_fit"]["by_type"]
    fam = sorted(((k, v) for k, v in fit["famine hits"].items() if not k.startswith("_")), key=lambda kv: kv[1])[:3]
    colh = sorted(((k, v) for k, v in fit["collapse deaths"].items() if not k.startswith("_")), key=lambda kv: kv[1])[:2]
    return [
        f"- Over {rep['years']} years the player's people lose on average {mean('shock_deaths'):.0%} of a population directly to shocks "
        f"(collapse {col:.0%}, pestilence {pan:.0%}), in {mean('episodes_3pct'):.1f} episodes of ≥ 3 % loss per run; the worst episode averages "
        f"{mean('worst_mean'):.0%} and the median recovery to the pre-shock population is {np.median(rec) if rec else float('nan'):.0f} years.",
        f"- Collapses also split the people: {mean('breakaway'):.0%} (cumulative) leave with successor or breakaway peoples, roughly offset by "
        f"{mean('absorbed_gain'):.0%} gained by absorbing weaker neighbours, so the end population moves by {-mean('pop_cost_600') + 0.0:+.1%} on average "
        f"but with a seed spread of ±{mean('pop_cost_sd'):.0%}: shocks add variance more than they cut the mean.",
        f"- Least exposed strategy: {lo} ({per[lo]['shock_deaths']:.0%}); most exposed: {hi} ({per[hi]['shock_deaths']:.0%}).",
        "- Famines are prevented by " + ", ".join(f"{k} (r {v:+.2f})" for k, v in fam) + "; collapse deaths fall with "
        + ", ".join(f"{k} (r {v:+.2f})" for k, v in colh) + ". All correlations are modest because strategies move these variables little in this era.",
        f"- Dominance: strictly dominant strategies with shocks off / on: {', '.join(dom[False]['strict']) or 'none'} / {', '.join(dom[True]['strict']) or 'none'}; "
        f"Pareto front {len(dom[False]['front'])} → {len(dom[True]['front'])} of {len(per)}. No strategy becomes immune (lowest cumulative loss "
        f"{per[lo]['shock_deaths']:.0%}) and none becomes a free lunch.",
    ]


def write_md(rep, dom, centuries, seconds, args):
    w, per = rep["world"], rep["player"]
    Y = rep["years"]
    md = [f"# Epochal shocks in the surrogate ({rep['strategies']} strategies × {rep['seeds']} seeds × {Y} years, shocks on vs off)", "",
          f"Generated {rep['generated']} by `python tools/sim/shock_report.py --seeds {args.seeds} --years {Y}{' --quick' if args.quick else ''}` "
          f"in {seconds:.0f} s. Runtime per {Y}-year run inside the process pool (machine shared with other sweeps): "
          f"{rep['seconds_per_run']['off']:.1f} s without shocks, {rep['seconds_per_run']['on']:.1f} s with (max {rep['seconds_per_run']['on_max']:.1f} s). "
          "On an idle machine a single 600-year run takes about 4.4 s either way: the world step costs well under 0.1 s per run.", "",
          "Model: `tools/sim/shock_world.py` puts the calibrated surrogate (`model.Surrogate`) in slot 0 of the epochal-shock world "
          "(`tools/sim/shocks/`, design in `EPOCHAL_SHIFTS.md`). Rival peoples are lightweight rows with a contact/trade/war/alliance graph; "
          "shocks are drawn every game year from each people's current condition and spread through the graph; emergence spawns successor, "
          "breakaway and newcomer peoples and retires absorbed or dispersed ones within a 24-slot budget. All names are generated in-world. "
          "Shocks are **opt-in** (`--shocks` on `run.py`, `matrix.py`, `sweep_strategies.py`; `simlib.run(..., shocks=True)`); the default surrogate is unchanged.", "",
          "Player strategies change the shock state through the surrogate: stored days → food reserve; health_protection/sanitation/water_safety/"
          "disease_exposure effects → health knowledge; institutions capacity + education → institutions; diet window → diversification; "
          "logistics + trade_capacity → trade; crowding → density. Shock outcomes feed back as deaths/emigration (cohorts scaled), a year of lower "
          "harvest and labor output, legitimacy/cohesion hits, lost adoption of known practices (institutions, health, knowledge lines; regrown by the "
          "surrogate's own adoption dynamics), lost stores and destroyed housing.", "",
          "Decrees whose only channels are `labor_multiplier` or `health_target` (care_rotation, water_security, expanded_watch) reproduce "
          "`sensible` exactly: in the surrogate labor efficiency and health already sit at their caps, so those decrees are no-ops with or without shocks.", "",
          "The 600 game years span the village to early-bronze era (historical-equivalent about −5000 to −2600), where the catalog's "
          "rates are low: no coin or credit crises before credit exists, little war escalation, and new crowd diseases only emerging late.", "",
          "## Headline", ""] + headline(rep, dom) + ["",
          "## Shock frequency per people per game century (all peoples in the world)", "",
          "| century | peoples alive (civ-years/100) | " + " | ".join(TYPES) + " |", "|---:|---:|" + "---:|" * len(TYPES)]
    for c in centuries:
        cy = w["civ_years"].get(str(c), w["civ_years"].get(c, 0))
        if not cy:
            continue
        cells = [f"{w['onsets'].get(f'{c}:{t}', 0) / (cy / 100):.2f}" for t in TYPES]
        md.append(f"| {c} | {cy / 100 / w['runs']:.1f} | " + " | ".join(cells) + " |")
    md += ["", "Counts are onsets (an episode that starts in that people); a climate episode or pestilence that spreads is counted once at its origin. "
           "Compare `catalog.HISTORICAL_BASE_RATES` (ancient: famine ≥2 % 0.5–1.5, collapse 0.15–0.5, pandemic ≥5 % 0.2–0.7 per century).", "",
           "## Rise and fall of peoples (per run, per century)", "", "| century | births | kinds | deaths | kinds |", "|---:|---:|---|---:|---|"]
    for c in centuries:
        b = {k.split(":")[1]: v for k, v in w["births"].items() if int(k.split(":")[0]) == c}
        d = {k.split(":")[1]: v for k, v in w["deaths"].items() if int(k.split(":")[0]) == c}
        nr = w["runs"]
        bk = ", ".join(f"{k} {v / nr:.2f}" for k, v in sorted(b.items()))
        dk = ", ".join(f"{k} {v / nr:.2f}" for k, v in sorted(d.items()))
        md.append(f"| {c} | {sum(b.values()) / nr:.2f} | {bk} | {sum(d.values()) / nr:.2f} | {dk} |")
    md += ["", f"Peoples alive ranged {w['alive_range'][0]}–{w['alive_range'][1]} (slot budget 24). The god followed a new people "
           f"{w['god_moves']} time(s) in {w['runs']} runs.", "",
           "## The player's people: losses and recovery by strategy", "",
           "Shock deaths = cumulative share of the population killed directly by shocks over the run (sum of yearly shares: pestilence, war, "
           "collapse, migration). Famine deaths are not in it: the engine declares the famine and cuts the harvest, and the surrogate's own "
           "hunger model decides who dies (column *famine (engine est.)* shows what the standalone engine would have killed). "
           "Breakaway = people who left with seceding provinces, rebels or successor states (+ colonists sent out); absorbed = people gained by union with or assimilation of other peoples. Net migration = cumulative refugees/settlers in minus emigrants out, as a share of population. "
           "Pop shortfall = 1 − population at year " + str(Y) + " with shocks ÷ without (same seed; positive = fewer people with shocks). "
           "Episodes = years with ≥ 3 % population loss (multi-year troughs merged); recovery = years until the pre-shock population is regained.", "",
           "| strategy | shock deaths | by type | famine (engine est.) | breakaway | absorbed | net migration | hits/century (by type) | pop shortfall at " + str(Y) + " | ≥3 % episodes/run | median recovery (y) | never recovered | worst loss |",
           "|---|---:|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|"]
    order = sorted(per, key=lambda n: per[n]["shock_deaths"])
    for n in order:
        x = per[n]
        bt = ", ".join(f"{t} {v:.1%}" for t, v in sorted(x["deaths_by_type"].items(), key=lambda kv: -kv[1]) if v >= 0.0005 and t in TYPES) or "–"
        hc = ", ".join(f"{t} {v:.2f}" for t, v in sorted(x["hits_per_century"].items(), key=lambda kv: -kv[1])) or "–"
        pc = f"{x['pop_cost_600']:+.1%} ± {x['pop_cost_sd']:.1%}" if x["pop_cost_600"] is not None else "–"
        rm = f"{x['recovery_median']:.0f}" if x["recovery_median"] is not None else "–"
        md.append(f"| {n} | {x['shock_deaths']:.1%} | {bt} | {x['famine_engine_estimate']:.1%} | {x['breakaway'] + x['colonists']:.1%} | {x['absorbed_gain']:.1%} | {x['net_migration']:+.1%} | {hc} | {pc} | {x['episodes_3pct']:.2f} | {rm} | {x['unrecovered']} | {x['worst_mean']:.1%} |")
    fit = rep["resilience_fit"]
    md += ["", "## What reduces losses (resilience)", "",
           f"Across all {fit['n']} strategy × seed runs, cumulative shock deaths regressed on the run-mean of each shock-state variable "
           f"(standardized; coefficient = change in cumulative death share per 1 SD; R² = {fit['r2']:.2f}).", "",
           "| variable | correlation with shock deaths | standardized coefficient |", "|---|---:|---:|"]
    for k in RESILIENCE:
        md.append(f"| {k} | {fit['corr'][k]:+.2f} | {fit['coef'][k]:+.4f} |")
    md += ["", "Per shock type (correlation across runs between the run-mean of each variable and that run's count or loss; "
           "negative = the variable protects):", "",
           "| outcome (mean per run) | " + " | ".join(RESILIENCE) + " |", "|---|" + "---:|" * len(RESILIENCE)]
    for tk, row in fit["by_type"].items():
        md.append(f"| {tk} ({row['_mean']:.2f}) | " + " | ".join(f"{row[k]:+.2f}" for k in RESILIENCE) + " |")
    md += ["", "## Outcomes at year " + str(Y) + ": without → with shocks (seed means)", "",
           "| strategy | " + " | ".join(facets.FACETS[f][0] for f in OUTCOMES) + " |", "|---|" + "---:|" * len(OUTCOMES)]
    for n in per:
        cells = []
        for f in OUTCOMES:
            off, on = per[n]["outcomes"][f]
            fmt = facets.FACETS[f][1]
            cells.append(f"{off:,.0f} → {on:,.0f}" if fmt.startswith("{:,") else f"{fmt.format(off)} → {fmt.format(on)}")
        md.append(f"| {n} | " + " | ".join(cells) + " |")
    md += ["", "## Dominance with shocks off vs on (year " + str(Y) + ")", "",
           f"Tie band per facet: 3 % or two pooled standard errors of a seed mean, whichever is wider (population: "
           f"{dom[False]['pop_band']:.0%} off, {dom[True]['pop_band']:.0%} on).", "", "| | off | on |", "|---|---|---|"]
    for key, label in (("front", "Pareto front"), ("strict", "strictly dominant"), ("top", "most dominant (beats n)"), ("rank_pop", "top 5 by population")):
        def fmt_v(v):
            if key == "top":
                return ", ".join(f"{a} ({b})" for a, b in v)
            return ", ".join(v) or "none"
        md.append(f"| {label} | {fmt_v(dom[False][key])} | {fmt_v(dom[True][key])} |")
    OUT.with_suffix(".md").write_text("\n".join(md) + "\n", encoding="utf-8")


if __name__ == "__main__":
    sys.exit(main())
