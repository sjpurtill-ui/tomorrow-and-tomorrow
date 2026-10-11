#!/usr/bin/env python3
"""What each settable number moves: raise it by a quarter, run 200 years, compare.

    python tools/sim/bench_scan.py            # writes tools/sim/bench_effects.json (about 15 minutes on 28 processors)
    python tools/sim/bench_scan.py --procs 6  # gentler on a machine in use

The bench shows the result under each number ("raise by a quarter -> by year
200: people +14%"). Numbers that are 0 in the game are left out (a quarter
more of nothing is nothing). A number the plain run does not feel is tried
again on the war path with new towns and on the learning path. Crises are off so that one world's luck does not
drown a small effect; the crisis numbers run with crises on over three worlds
and report only their toll and the people's number, at 5% or more.
Re-run after the game's rules change.
"""
from __future__ import annotations

import argparse
import json
import multiprocessing as mp
import os
import sys
import time
from pathlib import Path

SIM = Path(__file__).resolve().parent
sys.path.insert(0, str(SIM))
import bench_worker as worker  # noqa: E402

YEARS = 200
BUMP = 1.25
OUTPUTS = ["population", "life_expectancy", "infant_mortality", "food_days", "known", "goods_per_head", "field_strength", "home_quality", "crisis_deaths"]
SPEC = {"years": YEARS, "site": "good", "path": "balanced", "mode": "leaders", "ambition": "makers", "towns": False}


# A number that moves nothing in the plain run is tried where it may matter.
ELSEWHERE = {"on the war path with new towns": {"path": "war", "towns": True}, "on the learning path": {"path": "learning"}}


def one(task: tuple) -> tuple:
    kid, value, crises = task[:3]
    setup = task[3] if len(task) > 3 else {}
    worker._below_normal()
    seeds = (1, 2, 3) if crises else (1,)
    total = dict.fromkeys(OUTPUTS, 0.0)
    try:
        for seed in seeds:
            spec = dict(SPEC, **setup, crises=crises, knobs={kid: value} if kid else {})
            row = worker.build(spec, seed).run(YEARS, float(YEARS))["rows"][-1]
            for k in OUTPUTS:
                total[k] += float(row.get(k, 0.0)) / len(seeds)
    except Exception as e:
        return kid, {"_error": f"{type(e).__name__}: {e}"}
    return kid, total


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--procs", type=int, default=max(1, (os.cpu_count() or 4) - 4), help="worlds at once (each at low priority)")
    ap.add_argument("--elsewhere", action="store_true", help="keep bench_effects.json's plain-run results and only re-try the quiet numbers on the other paths")
    args = ap.parse_args()
    knobs = worker.knob_catalog()
    tasks = [("", 0.0, False), ("", 0.0, True)]
    for k in knobs:
        if k["value"] == 0.0:
            continue
        crises = k["id"].startswith("crisis.")
        up = k["value"] * BUMP
        if k["whole"]:
            up = k["value"] + max(1, round(abs(k["value"]) * (BUMP - 1.0)))
        tasks.append((k["id"], up, crises))
    started = time.time()
    base, got = {}, {}
    out = SIM / "bench_effects.json"
    kept = json.loads(out.read_text(encoding="utf-8")) if args.elsewhere and out.exists() else None
    if kept:
        tasks_run = []
        base[False] = kept["base"]
    else:
        tasks_run = tasks
    with mp.get_context("spawn").Pool(args.procs, maxtasksperchild=1) as pool:
        tasks, all_tasks = tasks_run, tasks
        for n, (task, (kid, result)) in enumerate(zip(tasks, pool.imap(one, tasks, chunksize=1))):
            if not kid:
                base[task[2]] = result
            else:
                got[kid] = (task[2], result)
            if n % 40 == 0:
                print(f"{n}/{len(tasks)}  {time.time() - started:.0f}s", flush=True)
    tasks = all_tasks
    effects, failed = (dict(kept["effects"]), dict(kept.get("failed", {}))) if kept else ({}, {})
    for kid, (crises, result) in got.items():
        if "_error" in result:
            failed[kid] = result["_error"]
            continue
        # With crises on, any change reshuffles the luck: only the crises' own
        # toll and the people's number are read, and only a clear move counts.
        floor = 5.0 if crises else 1.0
        moved = {}
        for k in (("population", "crisis_deaths") if crises else OUTPUTS):
            b = base[crises][k]
            if abs(b) > 1e-9:
                pct = (result[k] - b) / abs(b) * 100.0
                if abs(pct) >= floor:
                    moved[k] = round(pct, 1)
        effects[kid] = moved
    # Second pass: the numbers the plain run does not feel, in the other setups.
    values = {t[0]: t[1] for t in tasks if t[0]}
    effects = {kid: moved for kid, moved in effects.items() if kid in values}
    quiet = [kid for kid, moved in effects.items() if not moved and not kid.startswith("crisis.")]
    where = {}
    with mp.get_context("spawn").Pool(args.procs, maxtasksperchild=1) as pool:
        for label, setup in ELSEWHERE.items():
            again = [("", 0.0, False, setup)] + [(kid, values[kid], False, setup) for kid in quiet if kid not in where]
            results = pool.map(one, again, chunksize=1)
            there = results[0][1]
            for kid, result in results[1:]:
                if "_error" in result:
                    continue
                moved = {k: round((result[k] - there[k]) / abs(there[k]) * 100.0, 1) for k in OUTPUTS if abs(there[k]) > 1e-9}
                moved = {k: v for k, v in moved.items() if abs(v) >= 1.0}
                if moved:
                    effects[kid], where[kid] = moved, label
            print(f"{label}: {sum(1 for v in where.values() if v == label)} more numbers move something  {time.time() - started:.0f}s", flush=True)
    doc = {"_doc": "bench_scan.py: percent change at the year below when one number is raised by a quarter (leaders' balanced path, good land, one town).",
           "year": YEARS, "bump": BUMP, "rev": __import__("bench").git_rev(), "base": base[False], "effects": effects, "where": where, "failed": failed}
    out.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    print(f"{len(effects)} numbers scanned, {sum(1 for v in effects.values() if v)} move something, {len(failed)} failed, {time.time() - started:.0f}s")
    for kid, err in failed.items():
        print("FAILED", kid, err)
    return 0


if __name__ == "__main__":
    sys.exit(main())
