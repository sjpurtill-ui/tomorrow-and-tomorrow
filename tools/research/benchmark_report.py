#!/usr/bin/env python3
"""Compare research_600_campaign_probe runs with docs/research/benchmarks_600.json.

  python tools/research/benchmark_report.py <log> [<log> ...] [--markdown]

Reads the RC_ROW / RC_SUMMARY lines the probe prints, and for every scenario
and seed reports, at game years 0, 100, 300 and 600, each measured metric
against its plausible range (min..max) and where it sits between the low,
typical and high benchmarks. Benchmark year 0 is measured over the first
decade (year 10), because a founding band's vital rates need years to show.
Also reports milestone landing years against their design bands and the
share of each 50-year block's design items that were learned in that block.
Exit status 1 when any measured value is outside its plausible range, a
milestone lands outside its band, or an effect total exceeded its era ceiling.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BENCHMARKS = os.path.join(ROOT, "docs", "research", "benchmarks_600.json")
DESIGN = os.path.join(ROOT, "data", "research", "research_600.json")
MEASURE_YEAR = {"0": 10, "100": 100, "300": 300, "600": 600}


def load_runs(paths):
    runs = {}
    for path in paths:
        with open(path, encoding="utf-8", errors="replace") as handle:
            for line in handle:
                if line.startswith("RC_ROW "):
                    row = json.loads(line[7:])
                    runs.setdefault((row["scenario"], row["seed"]), {"rows": {}, "summary": None})["rows"][row["year"]] = row
                elif line.startswith("RC_SUMMARY "):
                    row = json.loads(line[11:])
                    runs.setdefault((row["scenario"], row["seed"]), {"rows": {}, "summary": None})["summary"] = row
    return runs


def position(bench, value, better):
    """Where value sits: 'low', 'typical', 'high' band, or OUT if outside min..max."""
    lo, hi = bench["min"], bench["max"]
    if lo > hi:
        lo, hi = hi, lo
    if value < lo or value > hi:
        return "OUT"
    points = [("low", bench["low"]), ("typical", bench["typical"]), ("high", bench["high"])]
    return min(points, key=lambda p: abs(p[1] - value))[0]


def design_blocks():
    counts = {}
    for item in json.load(open(DESIGN, encoding="utf-8"))["items"]:
        block = min(550, int(float(item["proposed_year"]) // 50) * 50)
        counts[block] = counts.get(block, 0) + 1
    return counts


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    markdown = "--markdown" in sys.argv
    bench = json.load(open(BENCHMARKS, encoding="utf-8"))
    blocks = design_blocks()
    runs = load_runs(args)
    failed = False
    for (scenario, seed), run in sorted(runs.items()):
        rows = run["rows"]
        print("\n## %s (seed %s)" % (scenario, seed) if markdown else "\n=== %s seed %s ===" % (scenario, seed))
        if markdown:
            print("| metric | " + " | ".join("y%s" % y for y in MEASURE_YEAR) + " |")
            print("|---|" + "---|" * len(MEASURE_YEAR))
        for metric, spec in bench["metrics"].items():
            key = spec.get("probe_key")
            if not key or key == "per_50":
                continue
            cells = []
            for year, measured in MEASURE_YEAR.items():
                row = rows.get(measured)
                if row is None or key not in row:
                    cells.append("-")
                    continue
                value = float(row[key])
                where = position(spec["years"][year], value, spec["better"])
                if where == "OUT":
                    failed = True
                cells.append("%g (%s)" % (round(value, 1), where))
            if markdown:
                print("| %s | %s |" % (metric, " | ".join(cells)))
            else:
                print("  %-20s %s" % (metric, "  ".join("%-18s" % c for c in cells)))
        summary = run["summary"]
        if summary:
            late = []
            for mid, year in summary["milestones"].items():
                low, target, high = summary["bands"][mid]
                if year < low or year > high:
                    late.append("%s %.0f [%g-%g]" % (mid, year, low, high))
            missing = [m for m in summary["bands"] if m not in summary["milestones"] and summary["bands"][m][2] <= summary["years"]]
            print("  milestones: %s" % ", ".join("%s %.0f" % (m, y) for m, y in sorted(summary["milestones"].items(), key=lambda kv: kv[1])))
            if late or missing:
                failed = True
                print("  OUTSIDE BAND: %s; missing: %s" % (", ".join(late) or "-", ", ".join(missing) or "-"))
            shares = []
            for block, count in sorted((int(k), v) for k, v in summary["per_50"].items()):
                if block in blocks and block < summary["years"]:
                    shares.append("%d:%d/%d=%.0f%%" % (block, count, blocks[block], 100.0 * count / blocks[block]))
            print("  per 50 years: %s" % "  ".join(shares))
            if summary["violations"]:
                failed = True
                print("  CEILING VIOLATIONS: %s" % summary["violations"])
            pinned = {k: v for k, v in summary.get("max_ratio", {}).items() if v >= 0.999}
            print("  channels that reached their ceiling: %s" % (", ".join(sorted(pinned)) or "none"))
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
