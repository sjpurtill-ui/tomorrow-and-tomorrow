"""Monte Carlo driver for the epochal shock + emergence model.

    python -m tools.sim.shocks.demo                    # full run (all eras + 3000-year campaign)
    python -m tools.sim.shocks.demo --quick            # fewer runs
    python -m tools.sim.shocks.demo --write            # also write docs/research/epochal/MC_RESULTS.md

Reports, per era band: shock frequency per civ per game century against the historical
base-rate ranges in ``catalog.HISTORICAL_BASE_RATES``; loss distributions; recovery times;
cascade chains; how often a court warning preceded a shock; and for the long campaign the
number of peoples alive, births/deaths per century and the share of successor states.
"""
from __future__ import annotations

import argparse
import collections
import os
import sys
import time
from concurrent.futures import ProcessPoolExecutor

import numpy as np

from .catalog import BAND_GROUP, HISTORICAL_BASE_RATES, era_band, hist_year
from .world import World

ERA_RUNS = [("bronze", -2000), ("classical", 0), ("medieval", 1300), ("early_modern", 1650),
            ("industrial", 1900), ("modern", 1990)]
METRICS = ["pandemic>=5%", "pandemic>=25%", "famine>=2%", "climate shock", "collapse", "general war",
           "invasion/migration", "economic crisis", "upheaval", "tech disruption"]
TYPE_METRIC = {"collapse": "collapse", "war": "general war", "migration": "invasion/migration",
               "economic": "economic crisis", "upheaval": "upheaval", "tech": "tech disruption"}
LINEAGE_KINDS = {"successor", "secession", "uprising", "colony"}


def run_one(args):
    seed, mode, H, years, n_start, slots, isolated = args
    rng = np.random.default_rng(seed)
    w = World(rng, n_start=n_start, slots=slots, mode=mode, fixed_H=H, isolated=isolated)
    s = w.state
    civ_years = collections.Counter()
    counts = collections.defaultdict(collections.Counter)      # band -> metric -> n
    losses = collections.defaultdict(list)                    # type -> [(pop loss, inst loss)]
    trackers, recov = [], collections.defaultdict(list)       # type -> years (or None = not recovered)
    chains = collections.Counter()
    warned = collections.Counter()
    onsets_by_type = collections.Counter()
    births, deaths = collections.Counter(), collections.Counter()
    alive_at = {}
    pandemic_max = []
    naive_uid, naive_surv = None, {}
    for y in range(years):
        events, eevents, D = w.step(y)
        if naive_uid is None:
            naive_uid = {int(s["civ_uid"][i]) for i in np.where(s["disease_endowment"] < 0.5)[0] if s["alive"][i]}
        alive = s["alive"]
        H_now = hist_year(s["era_year"])
        bands = [era_band(h) for h in H_now]
        for i in np.where(alive)[0]:
            civ_years[bands[i]] += 1
        mem = s["shock_memory"]
        for e in events:
            ev = e["event"]
            if ev == "spread":
                m, b = e["mortality"], bands[e["civ"]]
                if m >= 0.05:
                    onsets_by_type["pandemic (civ hit >=5%)"] += 1
                    warned["pandemic (civ hit >=5%)"] += int(e["warned"])
                if m >= 0.05:
                    counts[b]["pandemic>=5%"] += 1
                if m >= 0.25:
                    counts[b]["pandemic>=25%"] += 1
                pandemic_max.append(m)
                uid = int(s["civ_uid"][e["civ"]])
                if mem["episodes"][e["episode"]]["virgin"] and uid in naive_uid:
                    naive_surv[uid] = naive_surv.get(uid, 1.0) * (1.0 - m)
            elif ev == "warning":
                warned["_warnings_" + e["type"]] += 1
            elif ev == "onset":
                ep = mem["episodes"][e["episode"]]
                t = ep["type"]
                onsets_by_type[t] += 1
                warned[t] += int(e["warned"])
                if t == "famine" and ep["severity"] >= 0.02:
                    counts[bands[e["origin"]]]["famine>=2%"] += 1
                elif t == "climate":
                    for i in ep["civs"]:
                        counts[bands[i]]["climate shock"] += 1
                elif t == "war":
                    for i in ep["civs"]:
                        counts[bands[i]]["general war"] += 1
                elif t in TYPE_METRIC:
                    counts[bands[e["origin"]]][TYPE_METRIC[t]] += 1
                chain, p = [t], ep["parent"]
                while p is not None and len(chain) < 8:
                    chain.append(mem["episodes"][p]["type"])
                    p = mem["episodes"][p]["parent"]
                chain = [t for k, t in enumerate(reversed(chain)) if k == 0 or t != list(reversed(chain))[k - 1]]
                if len(chain) >= 2:
                    chains[" -> ".join(chain)] += 1
            elif ev == "end":
                ep = mem["episodes"][e["episode"]]
                for i, en in ep["civs"].items():
                    pre = max(1.0, en["pre_pop"])
                    loss = min(1.0, 1.0 - en.get("surv", 1.0) + en.get("emig_frac", 0.0))
                    losses[ep["type"]].append((loss, en["inst_loss"] / max(0.05, en["pre_inst"])))
                    if loss >= 0.05 and ep["type"] != "tech":
                        trackers.append([i, int(s["civ_uid"][i]), 0.95 * pre, en["start"], ep["type"]])
        keep = []
        for tr in trackers:
            i, uid, target, start, typ = tr
            if s["civ_uid"][i] != uid or not alive[i]:
                recov[typ].append(("gone", y - start))
            elif s["pop"][i] >= target:
                recov[typ].append(("ok", y - start))
            else:
                keep.append(tr)
        trackers = keep
        for e in eevents:
            if e["event"] == "birth":
                births[e["kind"]] += 1
        for d in (e for e in eevents if e["event"] in ("union",)):
            deaths["union"] += 1
        for rec in s["emergence_memory"]["records"].values():
            if rec["died"] == y and rec.get("death_kind") in ("absorbed", "dispersed"):
                deaths[rec["death_kind"]] += 1
        if y + 1 in (600, 1200, 3000, years):
            alive_at[y + 1] = int(alive.sum())
    for tr in trackers:
        recov[tr[4]].append(("censored", years - tr[3]))
    return {"civ_years": dict(civ_years), "counts": {k: dict(v) for k, v in counts.items()},
            "losses": {k: v for k, v in losses.items()}, "recov": {k: v for k, v in recov.items()},
            "chains": dict(chains), "warned": dict(warned), "onsets": dict(onsets_by_type),
            "births": dict(births), "deaths": dict(deaths), "alive_at": alive_at,
            "suppressed": s["emergence_memory"]["suppressed"], "pandemic_max": max(pandemic_max or [0]),
            "births_total": sum(births.values()), "naive_loss": [1.0 - v for v in naive_surv.values()]}


def merge(results):
    out = {"civ_years": collections.Counter(), "counts": collections.defaultdict(collections.Counter),
           "losses": collections.defaultdict(list), "recov": collections.defaultdict(list), "chains": collections.Counter(),
           "warned": collections.Counter(), "onsets": collections.Counter(), "births": collections.Counter(),
           "deaths": collections.Counter(), "alive_at": collections.defaultdict(list), "suppressed": 0, "pandemic_max": [],
           "naive_loss": []}
    for r in results:
        out["civ_years"].update(r["civ_years"])
        for b, c in r["counts"].items():
            out["counts"][b].update(c)
        for k, v in r["losses"].items():
            out["losses"][k] += v
        for k, v in r["recov"].items():
            out["recov"][k] += v
        out["chains"].update(r["chains"])
        out["warned"].update(r["warned"])
        out["onsets"].update(r["onsets"])
        out["births"].update(r["births"])
        out["deaths"].update(r["deaths"])
        for k, v in r["alive_at"].items():
            out["alive_at"][k].append(v)
        out["suppressed"] += r["suppressed"]
        out["pandemic_max"].append(r["pandemic_max"])
        out["naive_loss"] += r.get("naive_loss", [])
    return out


def pct(values, q):
    return float(np.percentile(values, q)) if len(values) else float("nan")


def fmt_range(lo, hi):
    return f"{lo:g}-{hi:g}"


def report(era_results, camp, runs_note):
    L = []
    P = L.append
    P("# Epochal shocks: Monte Carlo results\n")
    P(f"Generated by `python -m tools.sim.shocks.demo` ({runs_note}). Rates are events per civ per game century "
      "(lived clock). `ok` = inside the historical range, `LOW`/`HIGH` = outside it.\n")
    P("## Frequency per civ per century vs historical base rates\n")
    header = "| Metric | " + " | ".join(n for n, _ in ERA_RUNS) + " | historical (ancient / medieval-early modern / industrial-modern) |"
    P(header)
    P("|" + "---|" * (len(ERA_RUNS) + 2))
    flags = collections.Counter()
    for met in METRICS:
        row = [met]
        for name, _ in ERA_RUNS:
            r = era_results[name]
            cy = sum(r["civ_years"].values())
            rate = 100.0 * sum(r["counts"][b].get(met, 0) for b in r["counts"]) / max(1, cy)
            lo, hi = HISTORICAL_BASE_RATES[met][BAND_GROUP[name]]
            tag = "ok" if lo <= rate <= hi else ("LOW" if rate < lo else "HIGH")
            flags[tag] += 1
            row.append(f"{rate:.2f} {tag}")
        hb = HISTORICAL_BASE_RATES[met]
        row.append(" / ".join(fmt_range(*hb[g]) for g in ("ancient", "medieval", "modern")))
        P("| " + " | ".join(row) + " |")
    P(f"\n{flags['ok']} of {sum(flags.values())} cells inside the historical range "
      f"({flags['LOW']} low, {flags['HIGH']} high).\n")

    P("## Losses per affected civ (all eras pooled)\n")
    P("| Shock | episodes x civs | pop loss median | p90 | max | institution loss median | p90 |")
    P("|---|---|---|---|---|---|---|")
    pooled = collections.defaultdict(list)
    for name, _ in ERA_RUNS:
        for k, v in era_results[name]["losses"].items():
            pooled[k] += v
    for t in ["pandemic", "famine", "climate", "war", "migration", "collapse", "economic", "upheaval"]:
        v = pooled.get(t, [])
        if not v:
            continue
        a = np.array(v)
        P(f"| {t} | {len(a)} | {pct(a[:, 0], 50):.1%} | {pct(a[:, 0], 90):.1%} | {a[:, 0].max():.1%} | "
          f"{pct(a[:, 1], 50):.0%} | {pct(a[:, 1], 90):.0%} |")
    P("\nPandemic worst single-wave mortality by era (max over runs): " + ", ".join(
        f"{n} {max(era_results[n]['pandemic_max']):.0%}" for n, _ in ERA_RUNS) + ".")
    nl = camp["naive_loss"]
    if nl:
        P(f"\nVirgin-soil contact (campaign, {len(nl)} isolated peoples reached by sea): cumulative deaths across the "
          f"strangers' sickness waves median {pct(nl, 50):.0%}, p90 {pct(nl, 90):.0%}, max {max(nl):.0%}.")
    P("\n## Recovery: years for population to regain 95% of its pre-shock level (loss >= 5%)\n")
    P("| Shock | cases | recovered | median years | p90 years | never (civ ended) | still below at end |")
    P("|---|---|---|---|---|---|---|")
    rec = collections.defaultdict(list)
    for name, _ in ERA_RUNS:
        for k, v in era_results[name]["recov"].items():
            rec[k] += v
    for k, v in camp["recov"].items():
        rec[k] += v
    for t in ["pandemic", "famine", "climate", "war", "migration", "collapse", "economic", "upheaval"]:
        v = rec.get(t, [])
        if not v:
            continue
        ok = [y for s, y in v if s == "ok"]
        P(f"| {t} | {len(v)} | {len(ok) / len(v):.0%} | {pct(ok, 50):.0f} | {pct(ok, 90):.0f} | "
          f"{sum(1 for s, _ in v if s == 'gone') / len(v):.0%} | {sum(1 for s, _ in v if s == 'censored') / len(v):.0%} |")
    P("\n## Cascades (parent chains, all runs)\n")
    ch = collections.Counter()
    for name, _ in ERA_RUNS:
        ch.update(era_results[name]["chains"])
    ch.update(camp["chains"])
    total_onsets = sum(sum(era_results[n]["onsets"].values()) for n, _ in ERA_RUNS) + sum(camp["onsets"].values())
    linked = sum(ch.values())
    P(f"{linked / max(1, total_onsets):.0%} of all shock onsets were triggered or amplified by an earlier shock. "
      "Most common chains of three or more:\n")
    long_chains = [(k, v) for k, v in ch.items() if k.count("->") >= 2]
    for k, v in sorted(long_chains, key=lambda kv: -kv[1])[:10]:
        P(f"- {k}: {v}")
    motif = ["climate", "famine", "migration", "war", "collapse"]

    def has(chain, sub):
        it = iter(chain.split(" -> "))
        return all(x in it for x in sub)
    P(f"\nChains containing climate -> famine -> migration: {sum(v for k, v in ch.items() if has(k, motif[:3]))}; "
      f"... -> war: {sum(v for k, v in ch.items() if has(k, motif[:4]))}; "
      f"full climate -> famine -> migration -> war -> collapse: {sum(v for k, v in ch.items() if has(k, motif))}.")
    coll_chain = sum(v for k, v in ch.items() if k.endswith("collapse"))
    coll_total = sum(era_results[n]["onsets"].get("collapse", 0) for n, _ in ERA_RUNS) + camp["onsets"].get("collapse", 0)
    P(f"Collapses preceded by another shock: {coll_chain / max(1, coll_total):.0%}.")
    P("\n## Court warnings\n")
    P("| Shock | onsets | warned in the previous 20 years | warnings per civ per century |")
    P("|---|---|---|---|")
    cy_all = sum(sum(era_results[n]["civ_years"].values()) for n, _ in ERA_RUNS)
    for t in ["pandemic (civ hit >=5%)", "famine", "war", "migration", "economic", "upheaval", "collapse"]:
        on = sum(era_results[n]["onsets"].get(t, 0) for n, _ in ERA_RUNS)
        wn = sum(era_results[n]["warned"].get(t, 0) for n, _ in ERA_RUNS)
        key = "_warnings_" + t.split(" ")[0]
        nw = sum(era_results[n]["warned"].get(key, 0) for n, _ in ERA_RUNS)
        P(f"| {t} | {on} | {wn / max(1, on):.0%} | {100 * nw / max(1, cy_all):.2f} |")
    P("\n## Emergence: the 3000-year campaign (eras advance with knowledge)\n")
    cy = sum(camp["civ_years"].values())
    P("| Horizon (game years) | peoples alive: median | min | max |")
    P("|---|---|---|---|")
    for hzn in sorted(camp["alive_at"]):
        v = camp["alive_at"][hzn]
        P(f"| {hzn} | {np.median(v):.0f} | {min(v)} | {max(v)} |")
    nb, nd = sum(camp["births"].values()), sum(camp["deaths"].values())
    P(f"\nBirths per civ per century: {100 * nb / cy:.2f}; deaths (absorbed, dispersed, union): {100 * nd / cy:.2f}. "
      f"Births suppressed for lack of a free slot: {camp['suppressed']}.")
    P("\n| Birth kind | count | share |")
    P("|---|---|---|")
    for k, v in sorted(camp["births"].items(), key=lambda kv: -kv[1]):
        P(f"| {k} | {v} | {v / max(1, nb):.0%} |")
    P(f"\nSuccessor states (a parent civ and a lineage claim: successor, secession, uprising, colony): "
      f"{sum(v for k, v in camp['births'].items() if k in LINEAGE_KINDS) / max(1, nb):.0%} of births; "
      f"from a collapse specifically: {camp['births'].get('successor', 0) / max(1, nb):.0%}.")
    P("\n| Death kind | count |")
    P("|---|---|")
    for k, v in sorted(camp["deaths"].items(), key=lambda kv: -kv[1]):
        P(f"| {k} | {v} |")
    P("\nCampaign shock rates by era band (per civ per century):\n")
    P("| Band | civ-centuries | " + " | ".join(METRICS) + " |")
    P("|" + "---|" * (len(METRICS) + 2))
    for band in ["village", "bronze", "classical", "medieval", "early_modern", "industrial", "modern"]:
        cyb = camp["civ_years"].get(band, 0)
        if cyb < 500:
            continue
        P(f"| {band} | {cyb / 100:.0f} | " + " | ".join(f"{100 * camp['counts'][band].get(m, 0) / cyb:.2f}" for m in METRICS) + " |")
    return "\n".join(L) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--runs", type=int, default=12, help="runs per era")
    ap.add_argument("--campaign-runs", type=int, default=8)
    ap.add_argument("--years", type=int, default=600, help="years per fixed-era run")
    ap.add_argument("--campaign-years", type=int, default=3000)
    ap.add_argument("--civs", type=int, default=16)
    ap.add_argument("--slots", type=int, default=36, help="civ slots (game: MAX_RIVAL_CIVILIZATIONS + player)")
    ap.add_argument("--seed", type=int, default=600)
    ap.add_argument("--workers", type=int, default=max(1, (os.cpu_count() or 2) - 1))
    ap.add_argument("--quick", action="store_true")
    ap.add_argument("--write", action="store_true", help="write docs/research/epochal/MC_RESULTS.md")
    a = ap.parse_args(argv)
    if a.quick:
        a.runs, a.campaign_runs = 4, 3
    t0 = time.time()
    jobs = []
    for k, (name, H) in enumerate(ERA_RUNS):
        jobs += [(a.seed + 1000 * k + r, "fixed", H, a.years, a.civs, a.slots, 0) for r in range(a.runs)]
    jobs += [(a.seed + 99_000 + r, "campaign", None, a.campaign_years, a.civs, a.slots, 4) for r in range(a.campaign_runs)]
    with ProcessPoolExecutor(max_workers=a.workers) as ex:
        results = list(ex.map(run_one, jobs))
    era_results = {}
    for k, (name, _) in enumerate(ERA_RUNS):
        era_results[name] = merge(results[k * a.runs:(k + 1) * a.runs])
    camp = merge(results[len(ERA_RUNS) * a.runs:])
    note = (f"{a.runs} runs x {a.years} years per era, {a.campaign_runs} campaign runs x {a.campaign_years} years, "
            f"{a.civs} starting civs, {a.slots} slots, seed {a.seed}")
    text = report(era_results, camp, note)
    sys.stdout.write(text)
    sys.stdout.write(f"\n({time.time() - t0:.0f} s)\n")
    if a.write:
        here = os.path.dirname(os.path.abspath(__file__))
        out = os.path.abspath(os.path.join(here, "..", "..", "..", "docs", "research", "epochal", "MC_RESULTS.md"))
        os.makedirs(os.path.dirname(out), exist_ok=True)
        with open(out, "w", encoding="utf8") as f:
            f.write(text)
        sys.stdout.write(f"wrote {out}\n")


if __name__ == "__main__":
    main()
