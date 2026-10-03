"""Dry years in the water ledger, for the surrogate: a mirror of
scripts/dry_water.gd (every constant read from the game).

A dry year dries each town's near springs by its depth (the season's dryness
plus the luck of the crisis's own draw), ramping in and out; the store falls,
and once it runs out the thirst kills at the engine's own rate (thirst_rate,
consequence_engine.gd "Dehydration"). The dry year's own smaller toll
(toll_share, cause "Drought") is the heat, the failed forage and foul water.

The surrogate has no per-town water ledger. At a dry year's onset it runs the
engine's forecast arithmetic (dry_water.gd forecast) for one nominal town of
the people: its need, the households' fetch at the near river (within a
kilometre), its carriers (Logistics + 0.22 of Food, 28 a day each at the
day's labour efficiency, the builders' wells), its storage days (vessels,
storage pits, open work area), its store full, carrying ordered at once (as
crisis_unattended.gd answers) for 90 days. The day-by-day dead of thirst it
returns are taken as the sub-steps pass.
"""
from __future__ import annotations

import math

import gdparse as g

DW = "scripts/dry_water.gd"
ON = g.game_file_exists(DW)


def _k(name, default):
    # Not optional once the engine has the rule: a renamed constant warns (check.py --strict).
    return float(g.const(DW, name, default=default, optional=False)) if ON else float(default)


RISE_DAYS = _k("RISE_DAYS", 30.0)
FALL_DAYS = _k("FALL_DAYS", 30.0)
DEPTH_LUCK = _k("DEPTH_LUCK", 0.18)
DEPTH_MAX = _k("DEPTH_MAX", 0.95)
DRAW_MEDIAN = _k("DRAW_MEDIAN", 0.002)
DRAW_SEV = _k("DRAW_SEV", 4.0)
DEEP_WELL_HOLD = _k("DEEP_WELL_HOLD", 0.7)
WELLS_HOLD = _k("WELLS_HOLD", 0.5)
CONVEY_FAIL = _k("CONVEY_FAIL", 0.5)
FAR_POOLS = _k("FAR_POOLS", 0.40)
FAR_FAIL = _k("FAR_FAIL", 0.5)
FAR_KM = _k("FAR_KM", 10.0)
FAR_SELF = _k("FAR_SELF", 0.5)
CARRY_REACH = _k("CARRY_REACH", 0.5)
TOLL_K = _k("TOLL_K", 2.0)
TOLL_HELD_CUT = _k("TOLL_HELD_CUT", 0.5)
THIRST_BASE = _k("THIRST_BASE", 0.35)
THIRST_RAMP = _k("THIRST_RAMP", 5.0)
THIRST_RAMP_DAYS = _k("THIRST_RAMP_DAYS", 4.0)
DRAW_CAP = _k("DRAW_CAP", 1.35)
CISTERN_DAYS = _k("CISTERN_DAYS", 2.5)
WATERWORKS_WATER = float(g.const("scripts/built_fabric.gd", "WATERWORKS_WATER", default=0.30, optional=True))


def clamp(v, lo, hi):
    return lo if v < lo else hi if v > hi else v


def thirst_rate(intake: float, shortage_days: float) -> float:
    deficit = clamp(1.0 - intake, 0.0, 1.0)
    ramp = clamp((shortage_days - 1.0) / THIRST_RAMP_DAYS, 0.0, 1.0)
    return deficit ** 3 * (THIRST_BASE + ramp * THIRST_RAMP)


def luck(sev: float, draw: float) -> float:
    return math.log(max(draw, 1e-9) / (DRAW_MEDIAN * (1.0 + DRAW_SEV * sev)))


def depth(sev: float, draw: float) -> float:
    return clamp(sev + DEPTH_LUCK * luck(sev, draw), 0.0, DEPTH_MAX)


def ramp(start: float, end: float, day: float) -> float:
    return clamp((day - start) / RISE_DAYS, 0.0, 1.0) * clamp((end - day) / FALL_DAYS, 0.0, 1.0)


def held_by(deep_well: bool, wells_cover: float) -> float:
    return 1.0 - (1.0 - (DEEP_WELL_HOLD if deep_well else 0.0)) * (1.0 - WELLS_HOLD * clamp(wells_cover, 0.0, 1.0))


def collect(parts: dict, loss: float, held: float, reach: float) -> dict:
    """dry_water.gd collect."""
    accessible = bool(parts.get("accessible", True))
    need = float(parts.get("need", 0.0))
    cap = float(parts.get("cap", need * DRAW_CAP))
    lost = clamp(loss * (1.0 - clamp(held, 0.0, 1.0)), 0.0, 1.0)
    flow = float(parts.get("flow", 1.0))
    near = (1.0 - lost) * min(cap, float(parts.get("near", 0.0))) * flow if accessible else 0.0
    far = 0.0
    if loss > 0.0 and accessible:
        far = min(FAR_POOLS * need * clamp(reach, 0.0, 2.0) * (1.0 - FAR_FAIL * loss), float(parts.get("organized", 0.0)) / (1.0 + FAR_KM * 0.16)) * flow
    household = (1.0 - lost) * float(parts.get("household", 0.0)) * flow if accessible else 0.0
    conveyed = min(float(parts.get("line", 0.0)) * (1.0 - CONVEY_FAIL * loss), max(0.0, cap - household))
    rain = float(parts.get("rain", 0.0)) * (1.0 - loss)
    return {"collected": min(cap + float(parts.get("cistern", 0.0)), near + far + conveyed + rain), "near": near, "far": far, "lost": lost}


def toll_share(sev: float, held_intake: float) -> float:
    return DRAW_MEDIAN * (1.0 + DRAW_SEV * sev) * TOLL_K * (1.0 - TOLL_HELD_CUT * clamp(held_intake, 0.0, 1.0))


def town_forecast(parts: dict, people: float, capacity: float, start: float, end: float, dep: float,
                  carry_from: float = 0.0, carry_days: float = 90.0, held: float = 0.0) -> dict:
    """dry_water.gd forecast for one town from the dry year's first day: the
    store full (capacity less a day's drinking), the order to carry from
    `carry_from` for `carry_days`. {deaths: [dead of thirst each day], held}."""
    store = max(0.0, capacity - people)
    shortage = 0.0
    dead = 0.0
    deaths = []
    drunk_sum = 0.0
    need_sum = 0.0
    day = start + 1.0
    while day <= end:
        scale = max(0.0, people - dead) / people
        p = dict(parts)
        for key in ("need", "cap", "near", "household", "organized", "rain", "cistern"):
            p[key] = float(parts.get(key, 0.0)) * scale
        water_far = CARRY_REACH if carry_from < day <= carry_from + carry_days else 0.0
        got = collect(p, dep * ramp(start, end, day), held, FAR_SELF + water_far)
        drinking = people * scale
        available = min(capacity * scale, store + got["collected"])
        drink = min(drinking, available)
        rest = max(0.0, available - drink)
        store = max(0.0, rest - min(rest, p["need"] - drinking))
        intake = drink / max(0.001, drinking)
        shortage = shortage + 1.0 if intake < 0.98 else max(0.0, shortage - 2.0)
        today = (people - dead) * thirst_rate(intake, shortage) / 365.0
        dead += today
        deaths.append(today)
        drunk_sum += drink
        need_sum += drinking
        day += 1.0
    return {"deaths": deaths, "held": drunk_sum / need_sum if need_sum > 0 else 1.0}


def nominal_town(sim) -> dict:
    """The surrogate's one nominal town for a dry year (see the module note)."""
    pop = max(1.0, float(sim.population))
    need = pop
    collectors = sim.workers("Logistics") + sim.workers("Food") * 0.22
    labor = clamp(float(getattr(sim, "labor_eff", 0.72)), 0.2, 1.2)
    wells = sim.fabric.works_on("water") if hasattr(sim, "fabric") else 0.0
    organized = collectors * 28.0 * labor * (1.0 + clamp(sim.eff("haul_capacity"), -0.4, 1.5)) * (1.0 + WATERWORKS_WATER * wells)
    household = need * 1.18
    days = 3.0 + (2.0 if sim.completed_names("Storage Pits") else 0.0)
    parts = {"need": need, "cap": need * DRAW_CAP, "near": household + organized, "household": household, "flow": 1.0,
             "organized": organized, "line": 0.0, "rain": 0.0, "cistern": 0.0, "accessible": True}
    return {"parts": parts, "people": pop, "capacity": pop * days, "held": held_by(False, wells)}


# ---------------------------------------------------------------------------
# Parity with the engine: tests/test_dry_years_drain_water.gd runs the engine's
# forecast on these cases and must get the numbers written here.
PARITY = "dry_water_parity.json"


def _parity_cases() -> list:
    def town(name, people, need, household, organized, capacity, held=0.0, line=0.0):
        return {"name": name, "people": people, "capacity": capacity, "start": 21556.0, "end": 21682.0, "sev": 0.33415129256561904,
                "draw": 0.06018884114340828, "carry_from": 21580.0,
                "parts": {"need": need, "cap": need * DRAW_CAP, "near": household + organized, "household": household, "flow": 1.0,
                          "organized": organized, "line": line, "rain": 0.0, "cistern": 0.0, "held": held, "accessible": True}}
    wells = held_by(False, 0.161)
    return [town("Ashleyfire", 114.84, 122.30, 144.31, 450.97, 728.28, wells),
            town("Ashleyfire, poor works", 114.84, 122.30, 144.31, 112.74, 344.52, 0.0),
            town("Ashleyfire, deep well", 114.84, 122.30, 144.31, 450.97, 728.28, held_by(True, 0.161)),
            town("Ashleyfire, a water line", 114.84, 122.30, 144.31, 450.97, 728.28, wells, 114.84)]


def parity(write: bool = False) -> int:
    import json
    from pathlib import Path
    path = Path(__file__).resolve().parent / PARITY
    cases = _parity_cases()
    for case in cases:
        got = town_forecast(case["parts"], case["people"], case["capacity"], case["start"], case["end"],
                            depth(case["sev"], case["draw"]), carry_from=case["carry_from"], held=case["parts"]["held"])
        case["thirst"] = round(sum(got["deaths"]), 4)
        case["held"] = round(got["held"], 5)
    if write:
        path.write_text(json.dumps(cases, indent=1) + chr(10), encoding="utf-8")
        print("wrote", path)
        return 0
    saved = json.loads(path.read_text(encoding="utf-8")) if path.exists() else []
    bad = [c["name"] for c, s in zip(cases, saved) if abs(c["thirst"] - s["thirst"]) > 0.01 or abs(c["held"] - s["held"]) > 0.0005]
    if bad or len(saved) != len(cases):
        print("PARITY FAIL (the surrogate's dry-year water no longer matches the fixture the engine test checks):", bad or "case count")
        return 1
    for c in cases:
        print(f"{c['name']}: {c['thirst']:.2f} dead of thirst, {c['held']:.3f} drank")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(parity(write="--write" in sys.argv))
