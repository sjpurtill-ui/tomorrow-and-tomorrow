#!/usr/bin/env python3
"""Turn Phase 3 campaign-probe output into long-horizon ground truth.

    Godot --headless --path <worktree> res://tests/research_600_campaign_probe.tscn -- --years=600 ... > rc.log
    python tools/sim/ingest_rc.py rc.log [more.log ...]

Reads RC_ROW / RC_SUMMARY lines (tests/research_600_campaign_probe.gd) and writes
tools/sim/ground_truth/rc_<scenario>_<seed>_<years>y.json in the truth format
calibrate.py/check.py understand. These runs carry no per-discovery list, so
they calibrate population, vital rates, food, education and discovery totals
(and milestone years), not discoveries by line per decade.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

TRUTH = Path(__file__).resolve().parent / "ground_truth"


def main(paths: list[str]) -> int:
    runs: dict = {}
    for path in paths:
        for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
            for tag in ("RC_ROW ", "RC_SUMMARY "):
                at = line.find(tag)
                if at < 0:
                    continue
                data = json.loads(line[at + len(tag):])
                key = (data["scenario"], int(data["seed"]))
                run = runs.setdefault(key, {"rows": [], "summary": {}})
                if tag == "RC_ROW ":
                    data["known"] = data.get("discoveries")
                    run["rows"].append(data)
                else:
                    run["summary"] = data
    TRUTH.mkdir(exist_ok=True)
    for (scenario, seed), run in runs.items():
        years = int(run["summary"].get("years") or max(r["year"] for r in run["rows"]))
        mapped = scenario if scenario in ("sensible", "poor", "ai") else f"rc_{scenario}"
        out = {"schema": "sim_truth/1", "source": "tests/research_600_campaign_probe.gd", "scenario": mapped, "seed": seed, "years": years,
               "rows": sorted(run["rows"], key=lambda r: r["year"]), "discoveries": None,
               "milestones": run["summary"].get("milestones", {}), "per_50": run["summary"].get("per_50", {})}
        dest = TRUTH / f"rc_{scenario}_{seed}_{years}y.json"
        dest.write_text(json.dumps(out), encoding="utf-8")
        print(f"wrote {dest.name}: {len(out['rows'])} rows")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
