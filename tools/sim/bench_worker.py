"""The simulator bench's worker side: the numbers that can be set, how a set of
them becomes one society, and the flat yearly row the dashboard draws.

Every run is its own process (bench.py), so setting a game number here is a
plain assignment on the loaded modules: nothing is written to the game.
"""
from __future__ import annotations

import importlib
import json
import math
import re
import sys
import time
import traceback
from pathlib import Path

SIM = Path(__file__).resolve().parent
sys.path.insert(0, str(SIM))

# Modules whose constants are game numbers read from the GDScript.
KNOB_MODULES = ("model", "crisis", "fabric")
SKIP_NAMES = {"R", "YEAR", "MONTH", "TIER_LAST", "ON", "RESEARCH_TEAMS", "DIFFUSION_TEAM", "PROBE_POLICY_MAGNITUDE"}
# Landmarks past the 600-year registry's own list (run.py MILESTONES) are
# picked from the catalog's key thresholds, one near each of these years.
LANDMARK_YEARS = (660, 800, 950, 1100, 1250, 1400, 1550, 1700, 1850, 2000, 2150, 2300, 2450, 2600, 2750, 2900)
UNMEASURED_AT_START = ("labor_efficiency", "infant_mortality", "child_mortality_1_4", "life_expectancy", "food_per_worker", "intake", "diet",
                       "goods_per_head", "household_goods", "field_strength", "watch", "drill", "armed", "land_yield", "output", "extracted", "goods_made")
NESTED = {"alloc": "work_", "cohorts": "age_", "capacities": "cap_", "per_line": "line_", "harvest": "harvest_",
          "crisis_by_cause": "crisisby_", "effects": "eff_", "source_health": "source_"}


def _number(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def _sources(module) -> dict:
    """name -> (game file, comment above it), read from the module's own source."""
    out = {}
    lines = Path(module.__file__).read_text(encoding="utf-8").splitlines()
    for i, line in enumerate(lines):
        m = re.match(r"^([A-Z][A-Z0-9_]*) = ", line)
        if not m:
            continue
        text = " ".join(lines[i:i + 4])
        f = re.search(r'"(scripts/[\w/]+\.gd)"', text)
        note = []
        j = i - 1
        while j >= 0 and lines[j].startswith("#"):
            note.insert(0, lines[j].lstrip("# ").strip())
            j -= 1
        inline = re.search(r"#\s*(.+)$", line)
        if inline and not note:
            note = [inline.group(1)]
        out[m.group(1)] = (f.group(1) if f else "", " ".join(note))
    return out


def knob_catalog() -> list[dict]:
    """Every number that can be set, with the value the game has now."""
    import gamedata as gd
    knobs = []
    for mod_name in KNOB_MODULES:
        module = importlib.import_module(mod_name)
        src = _sources(module)
        for name, value in vars(module).items():
            if not name.isupper() or name.startswith("_") or name in SKIP_NAMES:
                continue
            file, note = src.get(name, ("", ""))
            if _number(value):
                knobs.append({"id": f"{mod_name}.{name}", "name": name, "value": float(value), "file": file, "note": note, "whole": isinstance(value, int)})
            elif isinstance(value, dict) and value and all(_number(v) for v in value.values()):
                for key, v in value.items():
                    knobs.append({"id": f"{mod_name}.{name}.{key}", "name": f"{name} · {key}", "value": float(v), "file": file, "note": note, "whole": False})
    constants = gd.load_constants()
    for field, value in vars(constants).items():
        if _number(value):
            knobs.append({"id": f"c.{field}", "name": field.upper(), "value": float(value), "file": "", "note": "", "whole": False})
    doc = json.loads((SIM / "params.json").read_text(encoding="utf-8"))
    flat = gd.load_params()
    for section, values in doc.items():
        if section.startswith("_") or section == "calibrated" or not isinstance(values, dict):
            continue
        for key, entry in values.items():
            if key.startswith("_") or not _number(flat.get(key)):
                continue
            note = entry.get("source", "") if isinstance(entry, dict) else ""
            knobs.append({"id": f"p.{key}", "name": key, "value": float(flat[key]), "file": "", "note": note, "whole": False, "section": section})
    for key, note in (("tune_research_pace", "times the daily progress on every question (1 = the game as it is)"),
                      ("tune_adoption_pace", "times how fast households take up what is learned"),
                      ("tune_cap_scale", "times the ceiling each age puts on what knowledge can give"),
                      ("tune_burden_scale", "times the early ages' burden on births and infants")):
        knobs.append({"id": f"p.{key}", "name": key, "value": 1.0, "file": "", "note": note, "whole": False, "section": "tune"})
    return knobs


def apply_knobs(knobs: dict) -> tuple[dict, dict]:
    """Set the module numbers now; return (params overrides, constants overrides)."""
    p_over, c_over = {}, {}
    for kid, value in (knobs or {}).items():
        parts = kid.split(".")
        value = float(value)
        if parts[0] == "p":
            p_over[parts[1]] = value
        elif parts[0] == "c":
            c_over[parts[1]] = value
        elif parts[0] in KNOB_MODULES:
            module = importlib.import_module(parts[0])
            if len(parts) == 2:
                old = getattr(module, parts[1])
                setattr(module, parts[1], int(round(value)) if isinstance(old, int) else value)
            else:
                getattr(module, parts[1])[parts[2]] = value
    return p_over, c_over


def build(spec: dict, seed: int):
    """One society from the dashboard's numbers."""
    p_over, c_over = apply_knobs(spec.get("knobs"))
    import gamedata as gd
    import simlib
    from model import Scenario, Surrogate
    constants = gd.load_constants()
    for field, value in c_over.items():
        setattr(constants, field, value)
    data = (constants, gd.Catalog(constants))
    p = simlib.params(p_over)
    p["crises"] = bool(spec.get("crises", True))
    table, sites = simlib.scenarios()
    path = spec.get("path") or "balanced"
    d = dict(table.get(f"path_{path}", table["path_balanced"]))
    d.pop("_doc", None)
    d["site"] = spec.get("site", "good")
    d["start_population"] = int(spec.get("start_population", 120))
    if spec.get("research"):
        d["research"] = {k: int(v) for k, v in spec["research"].items()}
    d["ambition"] = spec.get("ambition") or "makers"
    d["path"] = path
    if spec.get("mode") == "split":
        d["manual"] = {k: float(v) for k, v in spec.get("manual", {}).items() if float(v) > 0}
        d.pop("labor", None)
    d["expand"] = "leaders" if spec.get("towns") else ""
    phases = []
    for ph in spec.get("phases") or []:
        one = {"from": float(ph["from"])}
        if ph.get("manual"):
            one["manual"] = {k: float(v) for k, v in ph["manual"].items() if float(v) > 0}
        elif ph.get("path"):
            one["path"] = ph["path"]
            one["labor"] = dict(d.get("labor", {}))
        phases.append(one)
    if phases:
        first = {"from": 0.0}
        if d.get("manual"):
            first["manual"] = dict(d["manual"])
        else:
            first["path"] = path
        d["phases"] = [first] + sorted(phases, key=lambda x: x["from"])
    d["site_profile"] = {k: float(v) for k, v in (spec.get("site_profile") or {}).items()}
    scenario = Scenario.from_dict("bench", d, sites)
    if spec.get("shocks"):
        from shock_world import ShockSurrogate
        return ShockSurrogate(scenario, seed, p, data)
    return Surrogate(scenario, seed, p, data)


def _r(v):
    v = float(v)
    if not math.isfinite(v):
        return None
    if v == 0.0:
        return 0
    return float(f"{v:.5g}")


def flatten(row: dict, prev: dict | None) -> dict:
    """The dashboard's row: numbers only, one level, with the yearly rates."""
    import standing
    out = {}
    for k, v in row.items():
        if _number(v) or hasattr(v, "dtype") and getattr(v, "shape", None) == ():
            out[k] = _r(v)
        elif isinstance(v, bool):
            out[k] = 1 if v else 0
    out["food_alarm"] = 1 if row.get("fed_guard") else 0
    for key, prefix in NESTED.items():
        for k, v in (row.get(key) or {}).items():
            out[prefix + str(k)] = _r(v)
    art = row.get("artifacts") or {}
    out["art_count"], out["art_studied"] = art.get("count", 0), art.get("studied", 0)
    pop = max(1.0, float(row["population"]))
    for k, v in (row.get("cohorts") or {}).items():
        out["ageshare_" + k] = _r(100.0 * float(v) / pop)
    if prev is not None:
        dt = max(1e-9, float(row["year"]) - float(prev["year"]))
        mid = max(1.0, 0.5 * (pop + float(prev["population"])))
        out["births_rate"] = _r((float(row["births"]) - float(prev["births"])) / dt / mid * 1000.0)
        out["deaths_rate"] = _r((float(row["deaths"]) - float(prev["deaths"])) / dt / mid * 1000.0)
        out["crisis_rate"] = _r((float(row["crisis_deaths"]) - float(prev["crisis_deaths"])) / dt / mid * 1000.0)
        out["growth"] = _r(((pop / max(1.0, float(prev["population"]))) ** (1.0 / dt) - 1.0) * 100.0)
        out["learned_year"] = _r((float(row["known"]) - float(prev["known"])) / dt)
    try:
        for k, v in standing.readings(row, {}).items():
            if not k.startswith("_"):
                out["st_" + k] = _r(100.0 * float(v))
    except Exception:
        pass
    out["focus"] = str(row.get("focus", ""))
    if prev is None:
        # Before the first day these are not yet measured (0, or the bare life table).
        for k in list(out):
            if k in UNMEASURED_AT_START or k.startswith(("st_", "cap_", "eff_")):
                out[k] = None
    return out


def landmarks(cat) -> list[dict]:
    import run as run_cli
    ids = [m for m in run_cli.MILESTONES if m in cat.index]
    keys = [r for r in cat.rows if r.get("key_threshold") and r.get("registry")]
    for year in LANDMARK_YEARS:
        near = min(keys, key=lambda r: abs(float(r["design_year"]) - year), default=None)
        if near and near["id"] not in ids:
            ids.append(near["id"])
    out = []
    for rid in ids:
        r = cat.rows[cat.index[rid]]
        out.append({"id": rid, "name": r.get("name", rid), "line": r.get("line", ""), "design": float(r.get("design_year", -1)),
                    "low": float(r.get("band_low", 0)), "high": float(r.get("band_high", 0))})
    return sorted(out, key=lambda x: x["design"])


def _below_normal() -> None:
    """The player's game comes first: runs take what the machine has spare."""
    try:
        if sys.platform == "win32":
            import ctypes
            k = ctypes.windll.kernel32
            k.SetPriorityClass(k.GetCurrentProcess(), 0x00004000)
        else:
            import os
            os.nice(10)
    except Exception:
        pass


def run_seed(spec: dict, seed: int, queue) -> None:
    """Process entry: run one world, sending each recorded year as it is reached."""
    try:
        _below_normal()
        started = time.time()
        sur = build(spec, seed)
        raw = sur.snapshot
        state = {"prev": None}

        def snapshot():
            row = raw()
            queue.put(("row", seed, flatten(row, state["prev"])))
            state["prev"] = row
            return row

        sur.snapshot = snapshot
        result = sur.run(int(spec["years"]), float(spec.get("record_every", 1.0)))
        cat = sur.cat
        learned = [[round(day / 365.0, 1), cat.rows[cat.index[rid]].get("name", rid), line] for day, rid, line in result["discoveries"]]
        reached = {rid: day / 365.0 for day, rid, _l in result["discoveries"]}
        marks = {m["id"]: (round(reached[m["id"]], 1) if m["id"] in reached else None) for m in landmarks(cat)}
        crises = []
        if getattr(sur, "crises", None) is not None:
            crises = [{"year": round(float(c["start"]) / 365.0, 1), "type": str(c["type"]), "deaths": round(float(c["deaths"]), 1), "severe": bool(c["severe"])}
                      for c in sur.crises.history]
        queue.put(("done", seed, {"seconds": round(time.time() - started, 1), "learned": learned, "marks": marks, "crises": crises}))
    except Exception:
        queue.put(("error", seed, traceback.format_exc()))
