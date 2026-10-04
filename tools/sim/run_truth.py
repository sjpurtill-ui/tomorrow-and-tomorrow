#!/usr/bin/env python3
"""Produce ground truth for the surrogate by running the REAL engine headless.

    python tools/sim/run_truth.py                      # default calibration set, one engine at a time
    python tools/sim/run_truth.py --runs sensible:74119:50 path_war:74119:15

A spec is scenario:seed:years. ``path_<path>`` runs the probe's sensible
scenario with the leaders' work laid toward that path (truth_probe.gd --path;
work_paths.gd), ``avg_<path>`` the same on an average site (between good and
poor) and ``poor_<path>`` on poor land; the truth file keeps that name so the surrogate runs its own
scenario of the name (scenarios.json) against it.

Each run writes tools/sim/ground_truth/<scenario>_<seed>_<years>y.json via
tools/sim/truth_probe.tscn, plus a .meta.json recording the worktree commit and
hashes of the game files the surrogate mirrors (so check.py can tell when the
truth is stale). Never launches the player's game; always passes --headless and
an explicit --path. About 7 s per simulated year at 120 people plus ~35 s to
start, more as the people grow. One engine at a time by default (--jobs 1):
the user plays the game on this machine, so keep truth runs short.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

SIM = Path(__file__).resolve().parent
ROOT = SIM.parent.parent
TRUTH = SIM / "ground_truth"
DEFAULT_GODOT = r"C:\Users\sjpur\leviathan\tools\godot\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe"
# Post-overhaul truth (docs/PEOPLE_FIRST.md): the leaders' own work on four
# paths, short runs. The pre-overhaul set is kept in ground_truth/archive_pre_people_first/.
DEFAULT_RUNS = [
    "path_balanced:74119:15", "path_balanced:5150:15",
    "path_growth:74119:15", "path_war:74119:15", "path_learning:74119:15",
    "avg_balanced:74119:15", "path_building:74119:15",
]
WATCHED = [
    "scripts/discovery_system.gd", "scripts/society_model.gd", "scripts/game_state.gd",
    "scripts/early_life_conditions.gd", "scripts/food_system.gd", "scripts/consequence_engine.gd",
    "scripts/research_600_catalog.gd", "scripts/technology_eras.gd", "scripts/artifact_collection.gd",
    "data/research/research_600.json",
    "scripts/food_care.gd", "scripts/government_people_system.gd", "scripts/work_paths.gd",
    "scripts/civilian_goods.gd", "scripts/resource_system.gd", "scripts/weapons_stock.gd", "scripts/watch_military.gd",
    "scripts/crisis_background.gd", "scripts/crisis_system.gd", "scripts/crisis_unattended.gd",
    "scripts/built_fabric.gd", "scripts/settlement_construction.gd", "scripts/dry_water.gd",
]


def source_fingerprint() -> dict:
    result = {}
    for rel in WATCHED:
        path = ROOT / rel
        result[rel] = hashlib.sha1(path.read_bytes()).hexdigest()[:12] if path.exists() else None
    effects = hashlib.sha1()
    for path in sorted((ROOT / "data/research/effects").glob("*.json")):
        effects.update(path.read_bytes())
    result["data/research/effects/*.json"] = effects.hexdigest()[:12]
    return result


def fingerprint_at(rev: str) -> dict:
    """source_fingerprint() of a git revision (line endings as checked out on Windows or not)."""
    result = {}
    for rel in WATCHED:
        out = subprocess.run(["git", "-C", str(ROOT), "show", f"{rev}:{rel}"], capture_output=True)
        data = out.stdout if out.returncode == 0 else b""
        crlf = data.replace(bytes([10]), bytes([13, 10]))
        result[rel] = {hashlib.sha1(data).hexdigest()[:12], hashlib.sha1(crlf).hexdigest()[:12]}
    return result


def truth_revision() -> str:
    """HEAD when every truth run was launched from HEAD's game files, else '' (working tree)."""
    at_head = fingerprint_at("HEAD")
    metas = list(TRUTH.glob("*.meta.json"))
    if not metas:
        return ""
    for path in metas:
        src = json.loads(path.read_text(encoding="utf-8")).get("sources_at_launch", {})
        for rel, h in src.items():
            if rel in at_head and h not in at_head[rel]:
                return ""
    return subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()


def commit() -> str:
    try:
        return subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"


def probe_args(scenario: str) -> list[str]:
    """truth_probe.gd arguments for a truth scenario name (path_<p> -> sensible + --path=p)."""
    if scenario.startswith("path_"):
        return ["--scenario=sensible", f"--path={scenario[5:]}"]
    if scenario.startswith("avg_"):
        return ["--scenario=average", f"--path={scenario[4:]}"]
    if scenario.startswith("poor_"):
        return ["--scenario=poorland", f"--path={scenario[5:]}"]
    return [f"--scenario={scenario}"]


def run_one(godot: str, spec: str) -> tuple[str, float, int]:
    scenario, seed, years = spec.split(":")
    out = TRUTH / f"{scenario}_{seed}_{years}y.json"
    fingerprint = source_fingerprint()  # at launch: Godot loads scripts once, at start
    started = time.time()
    proc = subprocess.run([godot, "--headless", "--path", str(ROOT), "res://tools/sim/truth_probe.tscn", "--",
                           *probe_args(scenario), f"--seed={seed}", f"--years={years}", f"--out={out.as_posix()}"],
                          capture_output=True, text=True, encoding="utf-8", errors="replace")
    elapsed = time.time() - started
    if out.exists() and scenario.startswith(("path_", "avg_", "poor_")):
        # The surrogate runs the truth's own scenario name (scenarios.json path_<p>, avg_<p>).
        data = json.loads(out.read_text(encoding="utf-8"))
        data["scenario"] = scenario
        data["path"] = scenario.split("_", 1)[1]
        out.write_text(json.dumps(data), encoding="utf-8")
    meta = {"spec": spec, "commit": commit(), "sources_at_launch": fingerprint,
            "wall_seconds": round(elapsed, 1), "returncode": proc.returncode,
            "generated": time.strftime("%Y-%m-%d %H:%M:%S")}
    (TRUTH / f"{scenario}_{seed}_{years}y.meta.json").write_text(json.dumps(meta, indent=1))
    if proc.returncode != 0 or not out.exists():
        sys.stderr.write(f"[{spec}] FAILED rc={proc.returncode}\n{proc.stdout[-2000:]}\n{proc.stderr[-2000:]}\n")
    return spec, elapsed, proc.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--runs", nargs="*", default=DEFAULT_RUNS, help="scenario:seed:years")
    parser.add_argument("--godot", default=os.environ.get("GODOT", DEFAULT_GODOT))
    parser.add_argument("--jobs", type=int, default=1, help="engines at once (keep 1 while the game is being played)")
    parser.add_argument("--no-dump", action="store_true", help="skip refreshing tools/sim/cache/live_catalog.json")
    args = parser.parse_args()
    TRUTH.mkdir(parents=True, exist_ok=True)
    if not args.no_dump:
        # The surrogate's catalog snapshot must come from the same game files as the truth.
        cache = SIM / "cache" / "live_catalog.json"
        cache.parent.mkdir(exist_ok=True)
        subprocess.run([args.godot, "--headless", "--path", str(ROOT), "-s", "res://tools/sim/dump_catalog.gd", "--", cache.as_posix()],
                       capture_output=True, text=True, encoding="utf-8", errors="replace", check=False)
        print(f"refreshed {cache.relative_to(ROOT)}", flush=True)
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for spec, elapsed, rc in pool.map(lambda s: run_one(args.godot, s), args.runs):
            print(f"{spec}: rc={rc} {elapsed:.0f}s", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
