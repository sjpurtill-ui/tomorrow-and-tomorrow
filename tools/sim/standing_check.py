#!/usr/bin/env python3
"""Standing against the age in the fast sim (standing.gd, standing_scale.gd).

    python tools/sim/standing_check.py [--seeds 2] [--years 600] [--jobs 12] [--json out.json]

Two parts, about two minutes on 12 processes:

1. THE NINE BY PATH. Every people-first path (path_*) and two postures of the
   arts on the balanced path (arts_cunning, arts_persuasion: their costs are
   simulated, model.py Scenario.posture), read through standing.py at years
   25, 75, 150, 300 and 600. Flags:
     TRIVIALLY MAXED  a strength at 97% or more on the balanced path, or on a
                      path that does not lean toward it;
     IMPOSSIBLE       a strength no path lifts past 70% by year 600;
     FOCUS LOW        a path that does not lift its own strength past 70%.
2. THE ARTS PAY AND COST. The balanced temper in leaders.py's raid world
   (neighbours from year 40, envy raids by standing.gd's rules) with no
   posture, with cunning and with persuasion: raids, raids seen coming,
   repelled, the dead and the stores taken, against the people, discoveries
   and stores the posture costs.
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

CHECK_YEARS = [25, 75, 150, 300, 600]
PATHS = ["path_balanced", "path_growth", "path_making", "path_war", "path_learning", "path_building"]
# What each scenario leans toward: the strengths it should raise.
# (Growth raises people, none of the nine by itself; making's goods a head
# are held at the barter ceiling in the surrogate, a known gap.)
FOCUS = {"path_war": ["might"], "path_learning": ["genius"], "path_building": ["splendor"], "path_making": ["wealth"],
         "arts_cunning": ["cunning"], "arts_persuasion": ["persuasion"], "lean_stores": ["wealth"], "lean_hold": ["endurance"], "lean_order": ["order"], "lean_reach": ["reach"]}
# The arts' postures: what they cost (people away, the work shifted, gifts
# from the stores) and what they read (an able envoy or chief scout, agents,
# treaties kept, ties, how well the others are known).
POSTURES = {
    "": {},
    "cunning": {"away": 0.004, "shift": {"Survey": 5.0}, "scout_skill": 0.85, "agents": 3, "caught": 2, "intel": 0.55},
    "persuasion": {"away": 0.003, "away_envoys": 0.0015, "shift": {"Administration": 3.0}, "gifts": 0.3, "envoy_skill": 0.85,
                   "openness": 0.65, "familiarity": 0.3, "treaties": 3},
    # Leaning the other strengths the paths leave alone: an able steward and
    # more hands at administration; carriers and roads and more peoples met.
    "order": {"shift": {"Administration": 6.0}, "steward_skill": 0.85},
    "reach": {"shift": {"Logistics": 6.0}, "met_extra": 3},
}
ARTS = {"arts_cunning": "cunning", "arts_persuasion": "persuasion", "lean_order": "order", "lean_reach": "reach", "lean_stores": "", "lean_hold": ""}
# The base each lean starts from: lean_stores the growth path with the
# sustenance ambition (the deepest reserve); lean_hold the builders' path
# (walls) with the same ambition.
BASE = {"lean_stores": {"path": "growth", "ambition": "sustenance"}, "lean_hold": {"path": "building", "ambition": "sustenance"}}
# The raid world's neighbours hold this plenty (standing.gd reads their own
# month; a played world's computer peoples read 0.45-0.59 at year 75), and
# are harder than the engine's envy floor (ENVY_RAID_FLOOR 0.35) so that
# raids come often enough to weigh what the arts change: the same raids, met
# with or without them.
NEIGHBOUR_WEALTH = 0.45
RAID_ENVY_FLOOR = 0.2
# The people the arts are tried on in the raid world: one that raises works
# and is raided for them (the balanced temper raises none and is never raided).
RAID_TEMPER = "cautious-caring"


def run_path(args):
    name, seed, years = args
    constants, cat = simlib.data()
    table, sites = simlib.scenarios()
    from model import Scenario, Surrogate
    base = dict(table["path_balanced" if name in ARTS else name])
    base.update(BASE.get(name, {}))
    posture = POSTURES[ARTS.get(name, "")]
    base["posture"] = posture
    scenario = Scenario.from_dict(name, base, sites)
    model = Surrogate(scenario, seed, simlib.params(), (constants, cat))
    rows = model.run(years)["rows"]
    out = {}
    for y in CHECK_YEARS:
        if y > years:
            continue
        row = min(rows, key=lambda r: abs(r["year"] - y))
        out[y] = S.readings(row, posture)
        out[y]["_population"] = row["population"]
        out[y]["_known"] = row["known"]
        out[y]["_food_days"] = row["food_days"]
    return name, seed, out


def run_raids(args):
    posture_name, seed, years, site = args
    constants, cat = simlib.data()
    _table, sites = simlib.scenarios()
    import leaders as L
    from model import Scenario
    scenario = Scenario.from_dict(f"arts:{posture_name or 'none'}", {"site": site, "research": {}, "labor": {}, "posture": POSTURES[posture_name]}, sites)
    model = L.LeaderSurrogate(scenario, seed, simlib.params({"neighbour_wealth": NEIGHBOUR_WEALTH, "envy_floor": RAID_ENVY_FLOOR}), (constants, cat), L.ARCHETYPES[RAID_TEMPER])
    rows = model.run(years)["rows"]
    last = rows[-1]
    lived = max(1.0, sum(float(r["population"]) for r in rows))
    arts = S.readings(last, POSTURES[posture_name])
    return posture_name, seed, {"population": last["population"], "known": last["known"], "food_days": last["food_days"],
                                "raids": last["raids"], "seen": last["seen"], "repelled": last["repelled"],
                                "raid_deaths_per_1000py": last["raid_deaths"] / lived * 1000.0, "raid_stores": last["raid_stores"],
                                "gifts_given": last.get("gifts_given", 0.0), "persuasion": arts["persuasion"], "cunning": arts["cunning"]}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", type=int, default=2)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--jobs", type=int, default=12)
    ap.add_argument("--site", default="good")
    ap.add_argument("--json", type=Path, default=None)
    args = ap.parse_args()
    t0 = time.time()
    names = PATHS + list(ARTS)
    jobs = [(n, s, args.years) for n in names for s in range(1, args.seeds + 1)]
    raid_jobs = [(p, s, args.years, args.site) for p in ["", "cunning", "persuasion"] for s in range(1, args.seeds + 3)]
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        path_results = list(pool.map(run_path, jobs))
        raid_results = list(pool.map(run_raids, raid_jobs))
    by: dict = {}
    for name, _seed, out in path_results:
        for y, r in out.items():
            for k, v in r.items():
                by.setdefault(name, {}).setdefault(y, {}).setdefault(k, []).append(v)
    mean = {n: {y: {k: float(np.mean(v)) for k, v in ks.items()} for y, ks in ys.items()} for n, ys in by.items()}
    print(f"STANDING AGAINST THE AGE: {len(names)} scenarios x {args.seeds} seeds x {args.years} years ({time.time() - t0:.0f}s)")
    print("Each strength in points of 100: 50 a typical people of the age, 80 the best-documented, 100 the most the age has seen.\n")
    head = "".join(f"{k[:6]:>8s}" for k in S.NINE)
    flags = []
    for y in [y for y in CHECK_YEARS if y <= args.years]:
        print(f"year {y}")
        print(f"  {'scenario':18s}{head}{'people':>9s}{'known':>7s}{'food d':>7s}")
        for n in names:
            r = mean[n][y]
            print(f"  {n:18s}" + "".join(f"{r[k] * 100:8.0f}" for k in S.NINE) + f"{r['_population']:9.0f}{r['_known']:7.0f}{r['_food_days']:7.0f}")
            for k in S.NINE:
                if r[k] >= 0.97 and (n == "path_balanced" or k not in FOCUS.get(n, [])):
                    flags.append(f"TRIVIALLY MAXED  {k} {r[k] * 100:.0f} on {n} at year {y}")
        print()
    final = max(y for y in CHECK_YEARS if y <= args.years)
    for k in S.NINE:
        best = max(mean[n][y][k] for n in names for y in mean[n])
        if best < 0.7:
            flags.append(f"IMPOSSIBLE       {k}: no path past {best * 100:.0f}")
    for n, ks in FOCUS.items():
        for k in ks:
            best = max(mean[n][y][k] for y in mean[n])
            if best < 0.7:
                flags.append(f"FOCUS LOW        {n} lifts {k} only to {best * 100:.0f}")
    # The arts' pay and cost in the raid world.
    rb: dict = {}
    for p, _seed, out in raid_results:
        for k, v in out.items():
            rb.setdefault(p or "none", {}).setdefault(k, []).append(v)
    rmean = {p: {k: float(np.mean(v)) for k, v in ks.items()} for p, ks in rb.items()}
    print(f"THE ARTS PAY AND COST: the {RAID_TEMPER} temper in the raid world, {args.years} years, {args.site} site, {args.seeds} seeds")
    cols = ["persuasion", "cunning", "raids", "seen", "repelled", "raid_deaths_per_1000py", "raid_stores", "gifts_given", "population", "known", "food_days"]
    print(f"  {'posture':12s}" + "".join(f"{c[:10]:>12s}" for c in cols))
    for p, r in rmean.items():
        print(f"  {p:12s}" + "".join(f"{r[c]:12.2f}" if r[c] < 100 else f"{r[c]:12.0f}" for c in cols))
    report = {"years": args.years, "seeds": args.seeds, "strengths": mean, "arts": rmean, "flags": flags}
    print()
    print("\n".join(flags) if flags else "No strength trivially maxed or out of reach.")
    if args.json:
        args.json.write_text(json.dumps(report, indent=1, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
