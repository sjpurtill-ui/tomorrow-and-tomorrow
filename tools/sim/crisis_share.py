"""The crises' expected share of the age table, for scripts/crisis_background.gd.

The age table (game_state.gd BASELINE_HAZARD_BY_AGE with the early-care
multipliers) is the all-cause benchmark: life expectancy about 25 and infant
mortality about 260 at the founding (docs/research/BENCHMARKS_600.md), crises
included. The crises (crisis_system.gd, crisis_unattended.gd) kill on their
own odds on top, so the daily deaths emit only the age table's background: the
all-cause hazard less the share the crises take on average. This measures that
share for a typical people of each era: the surrogate's balanced path on good
and average land, crises on (tools/sim/crisis.py, the engine's hazards and
tolls), many seeds: 48 to year 200, 8 to year 3,000. In each era window, each age cohort's share is

    crisis deaths in the cohort / deaths the all-cause age table expects there

(both summed over every seed and both sites). Crisis deaths fall by the
crises' own death weights (sickness and hunger hardest on children and the
old; drowning and fire on the default row, heaviest on the old).

    python tools/sim/crisis_share.py                  # measure and print the table
    python tools/sim/crisis_share.py --apply          # also write it into crisis_background.gd

Re-run after a change to the crisis hazards or tolls, the age table or the
founding (the table is measured with the current one applied; two passes
settle it).
"""
from __future__ import annotations

import argparse
import re
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

SIM = Path(__file__).resolve().parent
sys.path.insert(0, str(SIM))

import simlib  # noqa: E402
from model import COH, Scenario, Surrogate, YEAR  # noqa: E402

ROOT = SIM.parent.parent
TARGET = ROOT / "scripts" / "crisis_background.gd"
# Era windows (game years) and the table point each one gives.
WINDOWS = [(0, 10), (10, 30), (30, 60), (60, 100), (100, 200), (200, 350), (350, 500), (500, 700), (700, 950), (950, 1200),
           (1200, 1500), (1500, 1800), (1800, 2100), (2100, 2400), (2400, 2700), (2700, 3000)]
POINTS = [0.0, 20.0, 45.0, 80.0, 150.0, 275.0, 425.0, 600.0, 825.0, 1075.0, 1350.0, 1650.0, 1950.0, 2250.0, 2550.0, 2850.0]
SITES = ["good", "average"]


class Recorder(Surrogate):
    """Records the cohort accumulators at every window edge."""

    def __init__(self, *a, edges=(), **k):
        super().__init__(*a, **k)
        self.edges = sorted(edges)
        self.marks = {}

    def _mark(self, year: int) -> None:
        crisis = self.crises.cohort_deaths.copy() if self.crises is not None else np.zeros(6)
        self.marks[year] = (crisis, self.allcause_coh.copy(), self.person_years_coh.copy())

    def snapshot(self):
        year = round(self.day / YEAR)
        if year in self.edges and year not in self.marks:
            self._mark(year)
        return super().snapshot()

    def run(self, years: int, record_every: float = 1.0) -> dict:
        out = super().run(years, record_every)
        # The last edge: the run's end, whatever the calendar's rounding.
        if years in self.edges and years not in self.marks:
            self._mark(years)
        return out


def run(job):
    site, seed, years = job
    constants, cat = simlib.data()
    table, sites = simlib.scenarios()
    scen = Scenario.from_dict(f"share_{site}", dict(table["path_balanced"], site=site), sites)
    edges = sorted({e for w in WINDOWS for e in w if e <= years})
    m = Recorder(scen, seed, simlib.params({"headless_world": True}), (constants, cat), edges=edges)
    m.run(years, record_every=1.0)
    return {k: tuple(x.tolist() for x in v) for k, v in m.marks.items()}


def measure(seeds_short: int, seeds_long: int, years_long: int, jobs: int) -> list:
    short = max(e for w in WINDOWS[:5] for e in w)
    work = [(s, seed, short) for s in SITES for seed in range(1, seeds_short + 1)]
    work += [(s, 1000 + seed, years_long) for s in SITES for seed in range(1, seeds_long + 1)]
    with ProcessPoolExecutor(jobs) as pool:
        results = list(pool.map(run, work))
    rows = []
    for (a, b), point in zip(WINDOWS, POINTS):
        crisis = np.zeros(6)
        allcause = np.zeros(6)
        people = np.zeros(6)
        for marks in results:
            if a in marks and b in marks:
                crisis += np.array(marks[b][0]) - np.array(marks[a][0])
                allcause += np.array(marks[b][1]) - np.array(marks[a][1])
                people += np.array(marks[b][2]) - np.array(marks[a][2])
        if allcause.sum() <= 0:
            continue
        share = np.clip(crisis / np.maximum(allcause, 1e-9), 0.0, 0.6)
        rows.append({"year": point, "window": (a, b), "share": share, "per_1000": 1000.0 * crisis.sum() / max(1e-9, people.sum()),
                     "allcause_per_1000": 1000.0 * allcause.sum() / max(1e-9, people.sum()), "people_years": float(people.sum())})
    return rows


def gd_table(rows: list) -> str:
    lines = ["const CRISIS_SHARE:Array=["]
    for i, r in enumerate(rows):
        cells = ",".join(f'"{k}":{v:.3f}' for k, v in zip(COH, r["share"]))
        lines.append(f"\t[{r['year']:.1f},{{{cells}}}]" + ("," if i < len(rows) - 1 else ""))
    lines.append("]")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--seeds", type=int, default=48, help="seeds per site for the first 200 years")
    ap.add_argument("--long-seeds", type=int, default=8, help="seeds per site run to --years")
    ap.add_argument("--years", type=int, default=3000)
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--apply", action="store_true", help="write the table into scripts/crisis_background.gd")
    args = ap.parse_args()
    rows = measure(args.seeds, args.long_seeds, args.years, args.jobs)
    print("window      crisis/1000  all-cause/1000  share by cohort (" + ", ".join(COH) + ")")
    for r in rows:
        print(f"{r['window'][0]:4d}-{r['window'][1]:<5d}  {r['per_1000']:9.1f}  {r['allcause_per_1000']:12.1f}   " + " ".join(f"{v:.3f}" for v in r["share"]))
    table = gd_table(rows)
    print(table)
    if args.apply:
        text = TARGET.read_text(encoding="utf-8")
        new = re.sub(r"const CRISIS_SHARE:Array=\[.*?\n\]", table.replace("\\", "\\\\"), text, count=1, flags=re.S)
        if new == text:
            print("crisis_background.gd: table unchanged or not found")
        TARGET.write_text(new, encoding="utf-8", newline="\n")
        print(f"wrote {TARGET.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
