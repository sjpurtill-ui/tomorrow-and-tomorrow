#!/usr/bin/env python3
"""Drift check: fails (exit 1) when the surrogate leaves its calibration tolerances.

    python tools/sim/check.py            # compare against every ground-truth run
    python tools/sim/check.py --strict   # also fail on stale truth / changed formulas

Three checks:
1. Calibration: surrogate vs real-engine truth runs within calibrate.TOLERANCES.
2. Truth freshness: the game files each truth run was generated from (hashes in
   its .meta.json) vs the files now. Stale truth means "re-run run_truth.py".
3. Formula drift: model.py transcribes some long engine formulas; if a watched
   source line changed since the last fit (params.json _formula_hashes), the
   transcription must be revisited.
"""
from __future__ import annotations

import argparse
import json
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import calibrate  # noqa: E402
import gdparse  # noqa: E402
import run_truth  # noqa: E402
import simlib  # noqa: E402

SIM = Path(__file__).resolve().parent


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--jobs", type=int, default=16)
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
        print("FAIL: no ground truth (python tools/sim/run_truth.py)")
        return 1
    doc = json.loads((SIM / "params.json").read_text(encoding="utf-8"))
    calibrated = {k: v for k, v in doc.get("calibrated", {}).items() if not k.startswith("_")}
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        score, comps = calibrate.evaluate(truths, calibrated, args.seeds, pool)
    md, failures = calibrate.table(truths, comps)
    print(md)
    problems = []
    if failures:
        problems.append(f"{failures} calibration metric(s) outside tolerance (score {score:.1f})")
    # Truth freshness against the files the surrogate just read (the revision, or the tree).
    now = run_truth.fingerprint_at(rev) if rev else {k: {v} for k, v in run_truth.source_fingerprint().items()}
    stale = []
    for path in sorted((SIM / "ground_truth").glob("*.meta.json")):
        meta = json.loads(path.read_text(encoding="utf-8"))
        then = meta.get("sources_at_launch") or meta.get("worktree_dirty_sources") or {}
        changed = [k for k, v in then.items() if k in now and v not in now[k]]
        if changed:
            stale.append(f"{path.name.replace('.meta.json', '')}: {', '.join(changed)}")
    if rev:
        tree = run_truth.source_fingerprint()
        ahead = [k for k, v in tree.items() if k in now and v not in now[k]]
        if ahead:
            print("\nNOTE: the working tree has uncommitted engine changes the truth has not seen: " + ", ".join(ahead) +
                  ". Tools that read the tree (run/tune/matrix/sweep) follow them; re-run run_truth.py to recalibrate.")
    drift = []
    for key, old in doc.get("_formula_hashes", {}).items():
        file, anchor = key.split("::", 1)
        if gdparse.line_hash(file, anchor) != old:
            drift.append(f"{file}: {anchor}")
    for w in gdparse.WARNINGS:
        print("WARNING (parser fallback):", w)
    if stale:
        print("\nSTALE truth (game files changed since the run; re-run tools/sim/run_truth.py):")
        print("\n".join("  " + s for s in stale))
    if drift:
        print("\nFORMULA DRIFT (re-transcribe in model.py, then calibrate):")
        print("\n".join("  " + d for d in drift))
    if args.strict and (stale or drift or gdparse.WARNINGS):
        problems.append("stale truth / formula drift / parser fallback (--strict)")
    if problems:
        print("\nFAIL: " + "; ".join(problems))
        return 1
    print(f"\nOK: {len(truths)} truth runs within tolerance (score {score:.1f})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
