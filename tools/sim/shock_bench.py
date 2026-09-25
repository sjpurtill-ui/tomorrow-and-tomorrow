"""Benchmark shock keys for the surrogate's epochal-shock log (research_3000).

The base benchmark files give, per window, the historical hazard of each kind of
shock (``shock_widening.hazard_per_game_century``: collapse, pandemic_ge_1pct /
_5pct / _25pct, famine_ge_2pct, economic_crisis, depression, general_war,
total_war, upheaval, invasion_migration) and how far a shock may push a metric
below its band for the checkpoint(s) whose window overlaps it and its recovery
(``shock_widening.types``). This module maps the shock engine's episodes
(``tools/sim/shocks``: type, kind, severity) onto those keys and widening
types, measures the player's rates per game century, and judges a run's facets
against the widened focus bands.

    import shock_bench as sb
    keys = sb.hazard_keys(episode, hist_year)          # e.g. ["pandemic_ge_1pct", "pandemic_ge_5pct"]
    rates = sb.player_rates(shock_log, years)          # {window: {key: per game century}}
    band = sb.widened_band(fs, focus, metric, year, episodes)
    verdict = sb.judge(fs, focus, metric, year, value, episodes)
"""
from __future__ import annotations

import json
from pathlib import Path

from shocks.catalog import hist_year

ROOT = Path(__file__).resolve().parent.parent.parent
KEYS = ["collapse", "pandemic_ge_1pct", "pandemic_ge_5pct", "pandemic_ge_25pct", "famine_ge_2pct", "economic_crisis",
        "depression", "general_war", "total_war", "upheaval", "invasion_migration"]
# Widening type per hazard key, first name the window defines wins.
WIDEN_TYPES = {
    "collapse": ["collapse"],
    "pandemic_ge_1pct": ["pestilence", "pandemic_wave"],
    "pandemic_ge_5pct": ["pestilence", "pandemic_wave", "contact_epidemic"],
    "pandemic_ge_25pct": ["contact_epidemic", "pestilence", "pandemic_wave"],
    "famine_ge_2pct": ["famine"],
    "economic_crisis": ["credit_crisis", "financial_panic"],
    "depression": ["depression", "credit_crisis", "financial_panic"],
    "general_war": ["war"],
    "total_war": ["total_war", "war"],
    "upheaval": ["upheaval", "revolution"],
    "invasion_migration": ["invasion"],
}
# Historical year from which the industrial-era keys exist (TechnologyEras: ~2500 game).
TOTAL_WAR_FROM = 1850.0
DEPRESSION_FROM = 1870.0
DEPRESSION_SEVERITY = 0.45
GENERAL_WAR_SEVERITY = 0.05


def _windows() -> list[dict]:
    out = []
    for path in sorted((ROOT / "docs/research").glob("benchmarks_[0-9]*.json"), key=lambda p: int(p.stem.split("_")[1])):
        data = json.loads(path.read_text(encoding="utf-8"))
        years = sorted(float(y) for m in data.get("metrics", {}).values() for y in m.get("years", {}))
        out.append({"name": path.stem, "start": years[0] if years else 0.0, "end": float(path.stem.split("_")[1]),
                    "widening": data.get("shock_widening") or {}})
    return out


WINDOWS = _windows()


def window_for(year: float) -> dict:
    for w in WINDOWS:
        if w["start"] - 1e-6 <= year <= w["end"] + 1e-6:
            return w
    return WINDOWS[-1]


def hazard_keys(episode: dict, hist: float) -> list[str]:
    """Benchmark hazard keys an episode counts toward (``shocks`` engine type/kind/severity)."""
    t, kind, sev = episode.get("type"), episode.get("kind", ""), float(episode.get("severity", 0.0))
    if t == "pandemic":
        return [k for k, lo in (("pandemic_ge_1pct", 0.01), ("pandemic_ge_5pct", 0.05), ("pandemic_ge_25pct", 0.25)) if sev >= lo]
    if t == "famine":
        return ["famine_ge_2pct"] if sev >= 0.02 else []
    if t == "war":
        keys = ["general_war"] if sev >= GENERAL_WAR_SEVERITY or kind in ("war_of_many_peoples", "grinding_war") else []
        if kind == "war_of_many_peoples" and hist >= TOTAL_WAR_FROM:
            keys.append("total_war")
        return keys
    if t == "economic":
        return ["economic_crisis"] + (["depression"] if hist >= DEPRESSION_FROM and sev >= DEPRESSION_SEVERITY else [])
    if t == "upheaval":
        return ["upheaval"]
    if t == "migration":
        return ["invasion_migration"]
    if t == "collapse":
        return ["collapse"]
    return []


def player_episodes(shock_log: dict, era_by_year: dict | None = None) -> list[dict]:
    """One record per distinct player episode: year, keys, widening types (by window)."""
    seen, out = set(), []
    for e in shock_log.get("player_episodes", []):
        if e.get("episode") in seen:
            continue
        seen.add(e.get("episode"))
        y = float(e["year"])
        era = float((era_by_year or {}).get(int(y), y))
        keys = hazard_keys(e, float(hist_year(era)))
        if keys:
            out.append({"year": y, "keys": keys, "type": e.get("type"), "kind": e.get("kind"), "severity": float(e.get("severity", 0.0))})
    return out


def player_rates(episodes_by_seed: list[list[dict]], years: int) -> dict:
    """{window name: {key: mean episodes per game century}} over seeds."""
    out = {}
    for w in WINDOWS:
        lo, hi = w["start"], min(w["end"], float(years))
        span = max(1e-6, (hi - lo) / 100.0)
        if hi <= lo:
            continue
        rates = {}
        for k in KEYS:
            n = [sum(1 for e in eps if lo < e["year"] <= hi and k in e["keys"]) for eps in episodes_by_seed]
            rates[k] = sum(n) / max(1, len(n)) / span
        out[w["name"]] = rates
    return out


def active_types(year: float, episodes: list[dict]) -> list[tuple[str, dict]]:
    """Widening types of the window judging ``year`` whose shock or recovery overlaps (year - 100, year]."""
    w = window_for(year)
    types = w["widening"].get("types", {})
    out = []
    for e in episodes:
        for k in e["keys"]:
            name = next((t for t in WIDEN_TYPES.get(k, []) if t in types), None)
            if not name:
                continue
            rec = types[name].get("recovery_game_years", [0, 0])
            end = e["year"] + float(rec[-1] if rec else 0.0)
            if e["year"] <= year and end >= year - 100.0:
                out.append((name, types[name]))
    # one application per type and episode year is enough; duplicates of a type compose
    return out


def widened_band(fs, focus, metric: str, year: float, episodes: list[dict]) -> dict | None:
    b = fs.band(focus, metric, year)
    if b is None:
        return None
    w = window_for(year)
    floor = (w["widening"].get("hard_floor") or {}).get(metric)
    for name, spec in active_types(year, episodes):
        mods = (spec.get("metrics") or {}).get(metric)
        if not mods:
            continue
        for field in ("min", "low", "typical", "high", "max"):
            if f"{field}_mult" in mods:
                b[field] = b[field] * float(mods[f"{field}_mult"])
            if f"{field}_add" in mods:
                b[field] = b[field] + float(mods[f"{field}_add"])
    if floor is not None:
        worse_is_lower = b["better"] != "lower"
        for field in ("min", "low"):
            b[field] = max(b[field], floor) if worse_is_lower else min(b[field], floor)
    return b


def judge(fs, focus, metric: str, year: float, value: float, episodes: list[dict]) -> str:
    """FocusBench.judge against the shock-widened band."""
    b = widened_band(fs, focus, metric, year, episodes)
    if b is None or value is None:
        return ""
    eps = 1e-9
    lo_b, hi_b = min(b["min"], b["max"]), max(b["min"], b["max"])
    if value < lo_b - eps or value > hi_b + eps:
        return "OUT OF BOUNDS"
    if b["better"] == "neither":
        lo, hi = min(b["low"], b["high"]), max(b["low"], b["high"])
        return "within" if lo - eps <= value <= hi + eps else ("below low" if value < lo else "ABOVE FOCUS HIGH")
    sign = 1.0 if b["better"] == "higher" else -1.0
    if sign * value < sign * b["low"] - eps:
        return "below low"
    if sign * value > sign * b["high"] + eps:
        allowance = b["allowed_lead"] * abs(b["high"] - b["typical"])
        return "ABOVE FOCUS HIGH" if sign * value > sign * b["high"] + allowance + eps else "above high (allowed)"
    return "within"


def benchmark_hazards() -> dict:
    """{window name: {key: [low, high] per game century}}."""
    return {w["name"]: dict(w["widening"].get("hazard_per_game_century") or {}) for w in WINDOWS if w["widening"]}
