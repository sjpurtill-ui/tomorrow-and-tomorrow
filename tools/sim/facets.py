"""Per-century facets from surrogate rows, and flags against docs/research/benchmarks_600.json."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np

import gamedata as gd

ROOT = Path(__file__).resolve().parent.parent.parent
BENCH_PATH = ROOT / "docs/research/benchmarks_600.json"
SIM_BENCH = Path(__file__).resolve().parent / "benchmarks.json"

# facet name -> (label, format, higher_is_better or None)
FACETS = {
    "population": ("Population", "{:,.0f}", True),
    "growth_pct": ("Growth %/yr (since previous century)", "{:+.2f}", None),
    "life_expectancy": ("Life expectancy", "{:.1f}", True),
    "infant_mortality": ("Infant mortality /1000", "{:.0f}", False),
    "child_mortality_1_4": ("Child mortality 1-4 /1000", "{:.0f}", False),
    "maternal_per_100k": ("Maternal deaths /100k births", "{:.0f}", False),
    "tfr": ("Total fertility", "{:.2f}", None),
    "cbr": ("Crude birth rate /1000", "{:.1f}", None),
    "cdr": ("Crude death rate /1000", "{:.1f}", False),
    "food_per_worker": ("Food per food worker (rations/day)", "{:.2f}", True),
    "food_security": ("Food security", "{:.2f}", True),
    "food_share": ("Food labor share %", "{:.1f}", False),
    "defense_share": ("Defense labor share %", "{:.1f}", None),
    "diet": ("Diet quality", "{:.2f}", True),
    "health": ("Health", "{:.2f}", True),
    "labor_efficiency": ("Labor efficiency", "{:.2f}", True),
    "cap_production": ("Production capacity", "{:.2f}", True),
    "craft_output": ("Craft output (effect)", "{:.3f}", True),
    "tool_quality": ("Tool quality (effect)", "{:.3f}", True),
    "cap_infrastructure": ("Infrastructure capacity", "{:.2f}", True),
    "housing_ratio": ("Housing ratio", "{:.2f}", True),
    "construction_rate": ("Construction rate (effect)", "{:.3f}", True),
    "cap_logistics": ("Logistics capacity", "{:.2f}", True),
    "trade_capacity": ("Trade reach (effect)", "{:.3f}", True),
    "ecology": ("Ecology", "{:.2f}", True),
    "ground_health": ("Wild ground health (mean)", "{:.2f}", True),
    "cap_institutions": ("Institutions capacity", "{:.2f}", True),
    "legitimacy": ("Legitimacy", "{:.2f}", True),
    "state_capacity": ("State capacity (effect)", "{:.3f}", True),
    "cap_security": ("Security capacity", "{:.2f}", True),
    "warfare_readiness": ("Military readiness (effect)", "{:.3f}", True),
    "cap_culture": ("Culture capacity", "{:.2f}", True),
    "cohesion": ("Cohesion", "{:.2f}", True),
    "known": ("Discoveries known", "{:.0f}", True),
    "per_century": ("Discoveries this century", "{:.0f}", True),
    "per_50": ("Registry items of the block learned in it %", "{:.0f}", True),
    "education": ("Education index", "{:.2f}", True),
    "art_found": ("Artifacts held", "{:.1f}", True),
    "art_studied": ("Artifacts studied", "{:.1f}", True),
    "art_bonus": ("Artifact research bonus", "{:.3f}", True),
    "allure": ("Allure", "{:.2f}", True),
}
BENCH_KEYS = {"life_expectancy": "life_expectancy", "infant_mortality": "infant_mortality", "child_mortality_1_4": "child_mortality_1_4",
              "maternal_per_100k": "maternal_per_100k", "tfr": "tfr", "cbr": "cbr", "cdr": "cdr", "growth_pct": "growth_pct",
              "population": "population", "food_share": "food_labor_share", "per_50": "discoveries_per_50_years",
              "defense_share": "defense_labor_share"}


def benchmarks() -> dict:
    """R3's benchmarks_600.json when present, else tools/sim/benchmarks.json."""
    for path in (BENCH_PATH, SIM_BENCH):
        if path.exists():
            data = json.loads(path.read_text(encoding="utf-8"))
            data["_source"] = str(path.relative_to(ROOT)).replace("\\", "/")
            return data
    return {"metrics": {}, "milestones": {"ids": []}, "_source": "none"}


def bench_at(bench: dict, metric: str, year: float) -> dict | None:
    m = bench.get("metrics", {}).get(metric)
    if not m or "years" not in m:
        return None
    pts = sorted((float(y), v) for y, v in m["years"].items())
    if year <= pts[0][0]:
        return dict(pts[0][1])
    for (y0, v0), (y1, v1) in zip(pts, pts[1:]):
        if year <= y1:
            t = (year - y0) / (y1 - y0)
            return {k: v0[k] + (v1[k] - v0[k]) * t for k in v0 if k in v1}
    return dict(pts[-1][1])


def flag(bench: dict, facet: str, year: float, value: float) -> str:
    metric = BENCH_KEYS.get(facet)
    if metric is None or value is None:
        return ""
    b = bench_at(bench, metric, year)
    if not b:
        return ""
    better = bench["metrics"][metric].get("better", "higher")
    lo_b, hi_b = min(b["min"], b["max"]), max(b["min"], b["max"])
    if value < lo_b or value > hi_b:
        return "OUT OF BOUNDS"
    if better == "neither":
        lo, hi = min(b["low"], b["high"]), max(b["low"], b["high"])
        return "within" if lo <= value <= hi else ("below low" if value < lo else "ABOVE HIGH")
    sign = 1.0 if better == "higher" else -1.0
    if sign * value < sign * b["low"]:
        return "below low"
    if sign * value > sign * b["high"]:
        # benchmarks_600.json allowed_deviation: a facet may exceed 'high' by a
        # share of |high - typical|; beyond that it is superhuman.
        share = float(bench.get("allowed_deviation", {}).get("facet_over_high_fraction_of_typical_to_high_gap", 0.0))
        allowance = share * abs(b["high"] - b["typical"])
        return "ABOVE HIGH" if sign * value > sign * b["high"] + allowance else "above high (allowed)"
    return "within"


def century_facets(result: dict, cat, years: int, step: int = 100) -> dict:
    """{century: {facet: value}} from one run's yearly rows and discovery list."""
    rows = {int(round(r["year"])): r for r in result["rows"]}
    design = {cat.ids[i]: float(cat.design_year[i]) for i in range(cat.n) if cat.registry[i]}
    found = [(day / 365.0, rid) for day, rid, _line in result["discoveries"]]
    out = {}
    prev = rows.get(0)
    for c in range(step, years + 1, step):
        r = rows.get(c)
        if r is None or prev is None:
            continue
        span = c - int(round(prev["year"]))
        births = r["births"] - prev["births"]
        deaths = r["deaths"] - prev["deaths"]
        maternal = r["maternal"] - prev["maternal"]
        mean_pop = max(1.0, (r["population"] + prev["population"]) * 0.5)
        mean_women = max(1.0, np.mean([rows[y]["women_15_45"] for y in range(c - span, c + 1) if y in rows]))
        f = {
            "population": r["population"],
            "growth_pct": ((max(1.0, r["population"]) / max(1.0, prev["population"])) ** (1.0 / span) - 1.0) * 100.0,
            "life_expectancy": r["life_expectancy"], "infant_mortality": r["infant_mortality"], "child_mortality_1_4": r["child_mortality_1_4"],
            "maternal_per_100k": maternal / max(1.0, births) * 1e5, "tfr": births / span / mean_women * 30.0,
            "cbr": births / span / mean_pop * 1000.0, "cdr": deaths / span / mean_pop * 1000.0,
            "food_per_worker": r["food_per_worker"], "food_security": r["food_security"], "food_share": r["food_share"], "diet": r["diet"],
            "defense_share": r.get("defense_share", 0.0),
            "health": r["health"], "labor_efficiency": r["labor_efficiency"],
            "cap_production": r["capacities"]["production"], "craft_output": r["craft_output"], "tool_quality": r["tool_quality"],
            "cap_infrastructure": r["capacities"]["infrastructure"], "housing_ratio": r["housing_ratio"], "construction_rate": r["construction_rate"],
            "cap_logistics": r["capacities"]["logistics"], "trade_capacity": r["trade_capacity"],
            "ecology": r["ecology"], "ground_health": float(np.mean([r["source_health"][k] for k in ("gather", "hunt", "fish")])),
            "cap_institutions": r["capacities"]["institutions"], "legitimacy": r["legitimacy"], "state_capacity": r["state_capacity"],
            "cap_security": r["capacities"]["security"], "warfare_readiness": r["warfare_readiness"],
            "cap_culture": r["capacities"]["culture"], "cohesion": r["cohesion"],
            "known": r["known"], "per_century": sum(1 for y, _ in found if c - step <= y < c), "education": r["education"],
            "art_found": r["artifacts"]["count"], "art_studied": r["artifacts"]["studied"], "art_bonus": r["artifacts"]["research_bonus"],
            "allure": r["artifacts"]["allure"],
        }
        # per_50 for the block ending at this century (benchmark definition).
        block = (c - 50, c)
        targeted = [rid for rid, y in design.items() if block[0] <= y < block[1]]
        learned = {rid for y, rid in found if block[0] <= y < block[1]}
        f["per_50"] = 100.0 * len([rid for rid in targeted if rid in learned]) / max(1, len(targeted))
        for li, line in enumerate(gd.LINES):
            f[f"line_{line}"] = sum(1 for y, rid in found if c - step <= y < c and cat.rows[cat.index[rid]]["line"] == line)
        out[c] = f
        prev = r
    return out


def mean_facets(runs: list[dict]) -> dict:
    """Average {century: {facet: value}} over seeds."""
    out = {}
    for c in sorted({c for r in runs for c in r}):
        keys = {k for r in runs if c in r for k in r[c]}
        out[c] = {k: float(np.mean([r[c][k] for r in runs if c in r and r[c].get(k) is not None])) for k in keys}
    return out
