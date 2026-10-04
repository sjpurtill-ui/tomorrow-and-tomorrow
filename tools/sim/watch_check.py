#!/usr/bin/env python3
"""How many a computer ruler keeps under arms, and what it costs and changes.

    python tools/sim/watch_check.py [--seeds 2] [--years 600] [--jobs 12] [--json out.json]

The engine's computer rulers hold the watch (the army: watch_military.gd) at
their temper's share of the whole people whenever the leaders' own split keeps
fewer (civilization_controller.gd interim_watch). Until 2026-10-03 that share
was .025 + .055 assertiveness + .035 discipline + .02 risk - .02 empathy (7 in
100 for an even temper, at peace); since then it is the age's own band
(civilization_strategy.gd watch_share: the typical share of the able for an
even temper, twice it for the hardest, half for the gentlest; twice at war).

Two parts, about a minute on 12 processes:

1. THE RULERS' OWN PEOPLE. The five archetypal tempers of leaders.py as
   computer rulers on the good and the poor site, with no hold (the leaders'
   split alone, as the surrogate ran before), the old hold and the age's hold:
   the share of the people under arms, Might (standing.py, the Standing page's
   reading), people, days of food, hunger deaths and discoveries.
2. THEIR RAIDS. The raid world of standing_check.py (the cautious-caring
   people, neighbours from year 40, envy raids by standing.gd's rules) with the
   neighbours keeping what an even-tempered computer ruler keeps under each
   rule, at the readiness the engine's computer peoples hold (0.92): how often
   they raid, how often the raids are repelled, the dead and the stores taken.

Surrogate stand-ins: no war (the age's hold doubles at war; the surrogate has
none), and no neighbours' pressure in the split (GovernmentPeopleSystem
neighbour_threat), so the threatened peoples of a played world keep more than
these do.
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
import simlib  # noqa: E402
import standing as S  # noqa: E402

RULES = ["", "old", "age"]
RULE_NAMES = {"": "split only", "old": "old hold", "age": "age's hold"}
CHECK_YEARS = [50, 100, 300, 600]
NEIGHBOUR_READY = 0.92   # the engine's computer peoples' watch at year 94: 0.90-0.94
RAID_TEMPER = "cautious-caring"


def run_ruler(args):
    name, rule, seed, years, site = args
    import leaders as L
    from model import Scenario
    constants, cat = simlib.data()
    _table, sites = simlib.scenarios()
    scenario = Scenario.from_dict(f"watch:{name}:{rule or 'none'}", {"site": site, "research": {}, "labor": {}}, sites)
    model = L.LeaderSurrogate(scenario, seed, simlib.params({"ruler_hold": rule}), (constants, cat), L.ARCHETYPES[name])
    rows = model.run(years)["rows"]
    out = {}
    for y in CHECK_YEARS:
        if y > years:
            continue
        upto = [r for r in rows if r["year"] <= y + 1e-6]
        at = upto[-1]
        lived = max(1.0, sum(float(r["population"]) for r in upto))
        arms = float(at.get("watch", 0.0)) / max(1.0, float(at["population"]))
        out[y] = {"under_arms": arms, "might": S.readings(at, {})["might"], "population": at["population"], "food_days": at["food_days"],
                  "hunger_rate": at["hunger_deaths"] / lived * 1000.0, "known": at["known"], "food_share": float(at["alloc"]["Food"])}
    return name, rule, site, seed, out


def run_raids(args):
    rule, armed, seed, years, site = args
    import leaders as L
    import standing_check as SC
    from model import Scenario
    constants, cat = simlib.data()
    _table, sites = simlib.scenarios()
    scenario = Scenario.from_dict(f"raids:{rule or 'none'}", {"site": site, "research": {}, "labor": {}}, sites)
    p = simlib.params({"neighbour_wealth": SC.NEIGHBOUR_WEALTH, "envy_floor": SC.RAID_ENVY_FLOOR, "neighbour_under_arms": armed, "neighbour_ready": NEIGHBOUR_READY})
    model = L.LeaderSurrogate(scenario, seed, p, (constants, cat), L.ARCHETYPES[RAID_TEMPER])
    rows = model.run(years)["rows"]
    last = rows[-1]
    lived = max(1.0, sum(float(r["population"]) for r in rows))
    return rule, seed, {"raids": last["raids"], "repelled": last["repelled"], "seen": last["seen"], "raid_deaths_per_1000py": last["raid_deaths"] / lived * 1000.0,
                        "raid_stores": last["raid_stores"], "might_ratio": last["might_ratio"], "population": last["population"]}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", type=int, default=2)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--jobs", type=int, default=12)
    ap.add_argument("--json", type=Path, default=None)
    args = ap.parse_args()
    import leaders as L
    t0 = time.time()
    jobs = [(n, r, s, args.years, site) for site in ["good", "poor"] for n in L.ARCHETYPES for r in RULES for s in range(1, args.seeds + 1)]
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        ruler_results = list(pool.map(run_ruler, jobs))
    by: dict = {}
    for name, rule, site, _seed, out in ruler_results:
        for y, r in out.items():
            for k, v in r.items():
                by.setdefault((site, name, rule), {}).setdefault(y, {}).setdefault(k, []).append(v)
    mean = {key: {y: {k: float(np.mean(v)) for k, v in ks.items()} for y, ks in ys.items()} for key, ys in by.items()}
    print(f"A COMPUTER RULER'S WATCH: 5 tempers x {len(RULES)} rules x 2 sites x {args.seeds} seeds x {args.years} years ({time.time() - t0:.0f}s)")
    print("under arms: in 100 of the whole people; Might: points of 100 (50 a typical people of the age, 100 the most it has seen)\n")
    cols = [("under_arms", "arms/100", lambda v: f"{v * 100:8.1f}"), ("might", "Might", lambda v: f"{v * 100:8.0f}"), ("population", "people", lambda v: f"{v:8.0f}"),
            ("food_days", "food d", lambda v: f"{v:8.0f}"), ("food_share", "food %", lambda v: f"{v:8.1f}"), ("hunger_rate", "hunger", lambda v: f"{v:8.2f}"), ("known", "known", lambda v: f"{v:8.0f}")]
    for site in ["good", "poor"]:
        for y in [y for y in CHECK_YEARS if y <= args.years]:
            print(f"{site} site, year {y}")
            print(f"  {'temper':20s}{'rule':12s}" + "".join(f"{c[1]:>8s}" for c in cols))
            for name in L.ARCHETYPES:
                for rule in RULES:
                    r = mean[(site, name, rule)][y]
                    print(f"  {name:20s}{RULE_NAMES[rule]:12s}" + "".join(c[2](r[c[0]]) for c in cols))
            print()
    # The neighbours an even-tempered computer ruler makes under each rule: its
    # people under arms, the mean over years 50-600 on the good site.
    armed = {}
    for rule in RULES:
        vals = [mean[("good", "balanced", rule)][y]["under_arms"] for y in CHECK_YEARS if y <= args.years]
        armed[rule] = float(np.mean(vals))
    raid_jobs = [(rule, armed[rule], s, args.years, "good") for rule in RULES for s in range(1, args.seeds + 3)]
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        raid_results = list(pool.map(run_raids, raid_jobs))
    rb: dict = {}
    for rule, _seed, out in raid_results:
        for k, v in out.items():
            rb.setdefault(rule, {}).setdefault(k, []).append(v)
    rmean = {rule: {k: float(np.mean(v)) for k, v in ks.items()} for rule, ks in rb.items()}
    print(f"THEIR RAIDS: the {RAID_TEMPER} people in the raid world, neighbours keeping an even-tempered ruler's watch (ready {NEIGHBOUR_READY}), {args.years} years, {args.seeds + 2} seeds")
    rcols = ["raids", "repelled", "seen", "raid_deaths_per_1000py", "raid_stores", "might_ratio", "population"]
    print(f"  {'neighbours':14s}{'arms/100':>10s}" + "".join(f"{c[:10]:>12s}" for c in rcols))
    for rule in RULES:
        r = rmean[rule]
        print(f"  {RULE_NAMES[rule]:14s}{armed[rule] * 100:10.1f}" + "".join(f"{r[c]:12.2f}" if r[c] < 100 else f"{r[c]:12.0f}" for c in rcols))
    if args.json:
        args.json.write_text(json.dumps({"rulers": {"|".join(k): v for k, v in mean.items()}, "neighbours_armed": armed, "raids": rmean}, indent=1, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
