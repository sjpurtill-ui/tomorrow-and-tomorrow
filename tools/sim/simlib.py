"""Shared loading/running helpers for run.py, calibrate.py, check.py, tune.py, matrix.py."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

import gamedata as gd
from model import Scenario, Surrogate

for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
SIM = Path(__file__).resolve().parent
TRUTH = SIM / "ground_truth"
_DATA = None


def data():
    """Constants + catalog, loaded once per process (0.2 s)."""
    global _DATA
    if _DATA is None:
        constants = gd.load_constants()
        _DATA = (constants, gd.Catalog(constants))
    return _DATA


def scenarios() -> tuple[dict, dict]:
    doc = json.loads((SIM / "scenarios.json").read_text(encoding="utf-8"))
    table = dict(doc["scenarios"])
    gen = doc.get("generated", {}).get("max_line")
    if gen:
        for line in gd.LINES:
            table[f"max_{line}"] = {"site": gen["site"], "labor": gen.get("labor", {}), "research": {l: (gen["weight"] if l == line else 0) for l in gd.LINES}}
            # lead_<line>: the full emphasis on one line, the minimum (1) on every other,
            # so cross-line foundations keep arriving.
            table[f"lead_{line}"] = {"site": gen["site"], "labor": gen.get("labor", {}), "research": {l: (gen["weight"] if l == line else 1) for l in gd.LINES}}
    return table, doc["sites"]


def starting_known() -> list:
    """Knowledge every new world starts with, as recorded by the real engine."""
    for path in sorted(TRUTH.glob("*.json")):
        if path.name.endswith(".meta.json"):
            continue
        try:
            known = json.loads(path.read_text(encoding="utf-8")).get("starting_known")
        except Exception:
            continue
        if known:
            return known
    return ["seasonal_patterns", "edible_resource_recognition", "timber_grading", "fiber_grading", "controlled_flaking",
            "cordage", "hafted_tools", "food_drying", "watch_rotation", "hafted_weapons"]


def params(overrides: dict | None = None, path: Path | None = None) -> dict:
    p = gd.load_params(path)
    p.setdefault("starting_known", starting_known())
    if overrides:
        p.update(overrides)
    return p


def make(name: str, seed: int, p: dict | None = None, scenario_override: dict | None = None) -> Surrogate:
    table, sites = scenarios()
    spec = dict(table[name])
    if scenario_override:
        spec.update(scenario_override)
    return Surrogate(Scenario.from_dict(name, spec, sites), seed, p if p is not None else params(), data())


def run(name: str, seed: int, years: int, p: dict | None = None, record_every: float = 1.0, scenario_override: dict | None = None) -> dict:
    return make(name, seed, p, scenario_override).run(years, record_every)


def truth_runs() -> list[dict]:
    runs = []
    for path in sorted(TRUTH.glob("*.json")):
        if path.name.endswith(".meta.json"):
            continue
        d = json.loads(path.read_text(encoding="utf-8"))
        d["_path"] = path.name
        runs.append(d)
    return runs


def milestone_years(result: dict, ids: list[str]) -> dict:
    found = {rid: day / 365.0 for day, rid, _line in result["discoveries"]}
    return {rid: found.get(rid) for rid in ids}


def per_decade(discoveries: list, years: int, by_line: bool = True) -> dict:
    out: dict = {}
    for day, _rid, line in discoveries:
        decade = int(day / 365.0 // 10 * 10)
        if decade >= years:
            continue
        key = (line, decade) if by_line else decade
        out[key] = out.get(key, 0) + 1
    return out


def mean_std(values):
    arr = np.array([v for v in values if v is not None], dtype=float)
    if arr.size == 0:
        return None, None
    return float(arr.mean()), float(arr.std())
