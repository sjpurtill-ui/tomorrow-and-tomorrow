#!/usr/bin/env python3
"""Per-era outcomes of a few reference scenarios against the merged 0-3000 benchmarks.

    python tools/sim/era_report.py --seeds 3 --years 3000                 # balanced, sensible, research, poor
    python tools/sim/era_report.py --scenarios balanced --seeds 2 --json out.json
    python tools/sim/era_report.py --shocks                               # inside the epochal-shock world

For every century it prints life expectancy, infant mortality, total fertility,
population, urban share, literacy and discoveries known (mean over seeds) with
the benchmark's low / typical / high at that year, and the focus_bench verdict
of each scenario against its own focus profile (tools/research/focus_bench.py:
classify at that year, judge every benchmarked facet, required costs, free
lunch vs balanced). --md writes the same tables as markdown.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "research"))
import facets  # noqa: E402
import focus_bench  # noqa: E402
import simlib  # noqa: E402

COLUMNS = [("life_expectancy", "life_expectancy", "{:.1f}"), ("infant_mortality", "infant_mortality", "{:.0f}"), ("tfr", "tfr", "{:.2f}"),
           ("population", "population", "{:,.0f}"), ("urban_share", "urban_share_pct", "{:.1f}"), ("literacy", "literacy_pct", "{:.1f}"),
           ("known", "discoveries_known", "{:.0f}"), ("per_50", "discoveries_per_50_years", "{:.0f}"), ("food_share", "food_labor_share", "{:.0f}")]


def _run(args):
    name, seed, years, shocks = args
    result = simlib.run(name, seed, years, simlib.params(), shocks=shocks)
    constants, cat = simlib.data()
    return name, facets.century_facets(result, cat, years, step=100)


def research_of(name: str) -> dict:
    table, _sites = simlib.scenarios()
    spec = table[name]
    return {"research": spec.get("research", {}), "labor": spec.get("labor", {}), "policies": spec.get("policies", []), "phases": spec.get("phases", [])}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--scenarios", nargs="*", default=["balanced", "sensible", "research", "poor"])
    ap.add_argument("--seeds", type=int, default=3)
    ap.add_argument("--years", type=int, default=3000)
    ap.add_argument("--jobs", type=int, default=24)
    ap.add_argument("--shocks", action="store_true")
    ap.add_argument("--json", type=Path, default=None)
    ap.add_argument("--md", type=Path, default=None)
    args = ap.parse_args()
    t0 = time.time()
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        outs = list(pool.map(_run, [(s, 1 + k, args.years, args.shocks) for s in args.scenarios for k in range(args.seeds)]))
    by: dict = {}
    for name, fac in outs:
        by.setdefault(name, []).append(fac)
    mean = {s: facets.mean_facets(v) for s, v in by.items()}
    bench = facets.benchmarks()
    fs = focus_bench.FocusBench()
    md = [f"# Per-era outcomes ({args.seeds} seeds x {args.years} years{', epochal shocks on' if args.shocks else ''})", "",
          f"`python tools/sim/era_report.py --seeds {args.seeds} --years {args.years}{' --shocks' if args.shocks else ''}` "
          f"({time.time() - t0:.0f} s). Each cell: surrogate mean, then the benchmark low / typical / high at that year.", ""]
    report = {"seeds": args.seeds, "years": args.years, "shocks": args.shocks, "scenarios": {}}
    for s in args.scenarios:
        md += [f"## {s}", "", "| year | " + " | ".join(c[0] for c in COLUMNS) + " | verdict |", "|---:|" + "---|" * (len(COLUMNS) + 1)]
        rows = {}
        for c in sorted(mean[s]):
            row = mean[s][c]
            cells = []
            for facet, metric, fmt in COLUMNS:
                v = row.get(facet)
                b = facets.bench_at(bench, metric, c)
                val = fmt.format(v) if v is not None else "n/a"
                if b:
                    val += f" ({fmt.format(b['low'])} / {fmt.format(b['typical'])} / {fmt.format(b['high'])})"
                cells.append(val)
            focus = fs.classify(research_of(s), c)
            base = mean.get("balanced", {}).get(c) if s != "balanced" else None
            chk = fs.check_run(focus, {c: row}, balanced=None if base is None else {c: base})
            bad = [f"{f['metric']} {f['flag']}" for f in chk["flags"] if f["flag"] in ("ABOVE FOCUS HIGH", "OUT OF BOUNDS")]
            low = [f"{f['metric']} low" for f in chk["flags"] if f["flag"] == "below low"]
            unpaid = [f"UNPAID {f}" for f, v in chk["costs"].get(float(c), {}).items() if v["status"] == "UNPAID"]
            free = [f"FREE LUNCH {f}" for f, v in chk["relative"].get(float(c), {}).items() if v["status"] == "FREE LUNCH"]
            verdict = "; ".join(bad + unpaid + free + low) or "ok"
            md.append(f"| {c} | " + " | ".join(cells) + f" | {verdict} |")
            rows[c] = {"facets": row, "focus": focus, "verdict": verdict, "ok": chk["ok"]}
        md.append("")
        report["scenarios"][s] = rows
    text = "\n".join(md) + "\n"
    print(text)
    if args.md:
        args.md.write_text(text, encoding="utf-8")
    if args.json:
        args.json.write_text(json.dumps(report, indent=0, default=float), encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
