"""Crises for the surrogate: a seeded mirror of crisis_unattended.gd (every
people's crises, answered as the court's silent official would) on the hazards
and magnitudes of crisis_system.gd.

The engine rolls each crisis type once a day at its annual hazard; a monthly
sub-step here rolls each type once at the chance of any onset over the
sub-step's days (two onsets never open within ONSET_GAP days, longer than a
sub-step, so at most one opens per sub-step, in the engine's order). Deaths
come at the turn (40 in 100 of the toll) and at the end (the rest), off the
aggregate cohorts by the cause's own death weights (game_state.gd
_mortality_weights_for), never below the shock floor. Side effects mirror the
answers: sick leave, rations, the roots, store and roof losses, the weariness
of a cairn.

Left out (no counterpart in the surrogate): strangers' sickness (no foreign
contacts: trade stays at its 0.05 floor), the water channel of a dry season,
and timber. Constants are read from the game (gdparse); formula literals are
hand copies checked by calibrate.py FORMULA_ANCHORS.
"""
from __future__ import annotations

import math

import numpy as np

import gdparse as g
import fabric as _fabric

HOME_SICKNESS = _fabric.K["HOME_SICKNESS"]
HOME_FIRE = _fabric.K["HOME_FIRE"]

CS = "scripts/crisis_system.gd"
COH = ["children", "youth", "early_adults", "established_adults", "mature_adults", "elders"]


def _k(name, default):
    return g.const(CS, name, default=default, optional=True)


BASE_SICKNESS = float(_k("BASE_SICKNESS", 0.40))
BASE_FIRE = float(_k("BASE_FIRE", 0.14))
BASE_FLOOD_WET = float(_k("BASE_FLOOD_WET", 0.35))
BASE_FLOOD_DRY = float(_k("BASE_FLOOD_DRY", 0.03))
CROWD_REF = float(_k("CROWD_REF", 0.55))
HEALTH_REF = float(_k("HEALTH_REF", 0.9))
POOL_REF = float(_k("POOL_REF", 0.12))
WATER_SHORT_BETA = float(_k("WATER_SHORT_BETA", 1.5))
CLEAN_WATER_BETA = float(_k("CLEAN_WATER_BETA", 1.5))
WATER_Q_MAX = float(_k("WATER_Q_MAX", 1.2))
SPACED_FIRE_FACTOR = float(_k("SPACED_FIRE_FACTOR", 0.6))
QUIET_AFTER_FOUNDING = int(_k("QUIET_AFTER_FOUNDING", 240))
ONSET_GAP = int(_k("ONSET_GAP", 30))
ACTIVE_MAX = int(_k("ACTIVE_MAX", 2))
FLOOR_SHARE = float(_k("FLOOR_SHARE", 0.7))
FLOOR_PEOPLE = int(_k("FLOOR_PEOPLE", 30))
SEVERE = dict(_k("SEVERE", {"hunger": 0.02, "sickness": 0.05, "stranger": 0.05}))
DEATH_FACTOR = dict(_k("DEATH_FACTOR", {"ration": 0.6, "tend": 1.25, "children_apart": 0.7, "roots": 0.8, "carry": 0.7}))
APART_CUSTOM_FACTOR = float(_k("APART_CUSTOM_FACTOR", 0.4))
MEDICINE_CEILING = _k("MEDICINE_CEILING", [[-5000, 0.35], [1400, 0.45], [1850, 0.8], [1900, 0.9], [1945, 0.95], [2030, 0.95]])
PANDEMIC_EMERGE = _k("PANDEMIC_EMERGE", [[-5000, 0.01], [-3000, 0.08], [-1200, 0.075], [0, 0.055], [1300, 0.08], [1700, 0.07], [1900, 0.035], [2030, 0.03]])
VOLCANIC_NOTABLE = float(_k("VOLCANIC_NOTABLE", 1.3))
DROUGHT_LOOKAHEAD = int(_k("DROUGHT_LOOKAHEAD", 120))
REBUILD_APART_DAYS = int(_k("REBUILD_APART_DAYS", 45))
REBUILD_APART_EFFECTS = dict(_k("REBUILD_APART_EFFECTS", {"labor_multiplier": -0.06, "health_target": -0.01}))
ERA_CURVE = g.const("scripts/technology_eras.gd", "CURVE", default=[[0, -5000], [300, -3000], [800, -500], [1500, 1000], [2000, 1600], [2400, 1800], [2800, 1950], [3000, 2030]])
LEAN_DAYS = float(g.const("scripts/food_care.gd", "LEAN_DAYS", default=20.0, optional=True))
STORE_GATE = float(g.const("scripts/food_care.gd", "STORE_GATE", default=0.5, optional=True))
CAUSE = {"hunger": "Hunger", "sickness": "Illness", "drought": "Dehydration", "cold": "Hunger", "flood": "Drowning", "fire": "Fire"}


def _weights(anchor: str, default: dict) -> np.ndarray:
    w = g.literal_after("scripts/game_state.gd", anchor, default=default)
    return np.array([float(w[k]) for k in COH])


# Death weights by cause (game_state.gd _mortality_weights_for): drowning and
# fire take the default row.
WEIGHTS = {
    "Hunger": _weights('"Hunger": return', {"children": 2.2, "youth": 0.8, "early_adults": 0.7, "established_adults": 0.8, "mature_adults": 1.2, "elders": 2.0}),
    "Illness": _weights('"Illness","Dehydration","Exposure": return', {"children": 1.8, "youth": 0.7, "early_adults": 0.7, "established_adults": 0.9, "mature_adults": 1.4, "elders": 2.6}),
    "_": _weights("\t\t_: return", {"children": 0.8, "youth": 0.25, "early_adults": 0.32, "established_adults": 0.55, "mature_adults": 1.25, "elders": 3.2}),
}
WEIGHTS["Dehydration"] = WEIGHTS["Illness"]


def cause_weights(cause: str) -> np.ndarray:
    return WEIGHTS.get(cause, WEIGHTS["_"])


def ramp(points, x: float) -> float:
    if x <= float(points[0][0]):
        return float(points[0][1])
    for i in range(1, len(points)):
        if x <= float(points[i][0]):
            a, b = points[i - 1], points[i]
            t = (x - float(a[0])) / max(0.0001, float(b[0]) - float(a[0]))
            return float(a[1]) + (float(b[1]) - float(a[1])) * t
    return float(points[-1][1])


def clamp(v, lo, hi):
    return lo if v < lo else hi if v > hi else v


class Crises:
    """One people's crisis state (CrisisSystem.state() for that people)."""

    def __init__(self, sim, seed: int):
        self.sim = sim
        self.rng = np.random.default_rng((int(seed) * 2246822519 + 911) & 0xFFFFFFFF)
        self.immunity = 0.0
        self.pool = -1.0
        self.active: list[dict] = []
        self.last: dict = {}
        self.last_onset = -99999.0
        self.flags = {"apart_custom": False, "spaced": False}
        self.until: dict = {}
        self.echoes: list[dict] = []
        self.mods: list[tuple] = []          # (until_day, {channel: value})
        self.history: list[dict] = []
        self.fires = 0
        self.serial = 0
        # Tallies: deaths by cause and by cohort, onsets by type.
        self.deaths_by_cause: dict = {}
        self.cohort_deaths = np.zeros(6)
        self.total_deaths = 0.0
        self.onsets: dict = {}

    # ----------------------------------------------------------- policy channels
    def policy(self, channel: str) -> float:
        day = self.sim.day
        return sum(float(eff.get(channel, 0.0)) for until, eff in self.mods if until > day)

    def _policy(self, effects: dict, days: float) -> None:
        self.mods.append((self.sim.day + float(days), dict(effects)))

    # ------------------------------------------------------------------ inputs
    def _weather_mean(self, a: float, b: float) -> float:
        total, n, d = 0.0, 0, a
        while d <= b:
            total += self.sim._weather(max(0.0, d))
            n += 1
            d += 6.0
        return total / max(1, n)

    def drought_depth(self, day: float) -> float:
        worst = self._weather_mean(day - 24, day + 36)
        t = day + 6
        while t <= day + DROUGHT_LOOKAHEAD:
            worst = min(worst, self._weather_mean(t - 24, t + 36))
            t += 6
        return clamp(1.0 - worst, 0.0, 0.6)

    def inputs(self, day: float) -> dict:
        s = self.sim
        e = s.eff
        pop = max(1.0, s.population)
        hp, san, ws, de = e("health_protection"), e("sanitation"), e("water_safety"), e("disease_exposure")
        hk = clamp(0.05 + (hp + san + ws) / 3.0 - 0.5 * de, 0.0, 1.0)
        H = ramp(ERA_CURVE, day / 365.0)
        water = 1.0
        deficit = s.last["need"] - s.last["production"]
        first_shortage = s.stored_days * s.last["need"] / deficit if deficit > 0.0 else -1.0
        cap = max(1.0, getattr(s, "carrying_capacity", 0.0) or 1.0)
        return {
            "pop": pop, "crowd": pop / max(1.0, s.housing_capacity), "dens": clamp(pop / 5000.0, 0.02, 1.0),
            "homes_q": float(s.fabric.quality) if hasattr(s, "fabric") else 0.0,
            "health": s.health, "food_days": s.stored_days, "intake": s.last["intake"], "shortage_days": s.shortage_days,
            "first_shortage": first_shortage, "water_q": clamp(water - 0.15 * de + 0.2 * ws + 0.2 * san, 0.0, WATER_Q_MAX),
            "H": H, "med": hk * ramp(MEDICINE_CEILING, H), "inst": float(s.capacities.get("institutions", 0.25)),
            "divers": clamp(s.diet_window, 0.0, 1.0), "trade": 0.05,
            "pressure": max(0.0, pop / cap - 0.85) if getattr(s, "carrying_capacity", 0.0) else 0.0,
            "weather": s._weather(day), "weather_season": self._weather_mean(day - 24, day + 36),
            "season": math.sin((day % 365.0) / 365.0 * 2 * math.pi), "river": "river" in (s.s.site_profile.get("environment_tags") or []),
        }

    def _active(self, kind: str) -> dict | None:
        for c in self.active:
            if c["type"] == kind:
                return c
        return None

    def hazards(self, day: float, x: dict) -> dict:
        """CrisisSystem.hazards (annual rates)."""
        hunger_on = 1.0 if self._active("hunger") else 0.0
        drought_on = 1.0 if self._active("drought") else 0.0
        out = {}
        other = max(0.0, 1.0 - x["weather_season"]) + max(0.0, 0.97 - x["intake"])
        buffer = 0.35 * min(x["food_days"] / 365.0, 1.0) + 0.12 * x["trade"] + 0.06 * x["inst"] + 0.08 * x["divers"] - 0.12
        shortfall = other + 0.6 * x["pressure"] - buffer
        p = 0.0025 * math.exp(min(50.0, 8.0 * shortfall)) + 1.0 / (1.0 + math.exp(-clamp((shortfall - 0.16) / 0.015, -60.0, 60.0)))
        if day - self.last.get("famine", -99999) < 6 * 365:
            p *= 0.15
        out["hunger"] = min(p, 0.95)
        out["hunger_shortfall"] = shortfall
        q = clamp(x["water_q"], 0.0, WATER_Q_MAX)
        water_term = WATER_SHORT_BETA * (1.0 - min(1.0, q)) - CLEAN_WATER_BETA * max(0.0, q - 1.0)
        season_factor = 1.0 + 0.35 * abs(x["season"])
        sick = BASE_SICKNESS * math.exp(1.6 * (x["crowd"] - CROWD_REF) + water_term + 1.5 * (HEALTH_REF - x["health"]) + 0.8 * hunger_on + 0.6 * (self.pool - POOL_REF)) * (1.0 - 0.5 * x["med"]) * season_factor
        if day < self.until.get("after_flood", -1):
            sick *= 2.0
        if drought_on > 0.0:
            sick *= 1.3
        if self.flags["apart_custom"]:
            sick *= 0.85
        sick *= math.exp(-HOME_SICKNESS * x.get("homes_q", 0.0))   # built_fabric.gd (crisis_system.gd)
        out["sickness"] = clamp(sick, 0.0, 3.0)
        out["pestilence_emerge"] = ramp(PANDEMIC_EMERGE, x["H"]) / 100.0 * math.exp(1.6 * (x["dens"] - 0.4) + 1.2 * (x["trade"] - 0.4) + 0.8 * hunger_on + 0.6 * (self.pool - 0.4)) * (1.0 - 0.5 * x["med"])
        fire = BASE_FIRE * math.exp(1.0 * (x["crowd"] - CROWD_REF)) * (1.0 + 1.5 * drought_on + 0.8 * max(0.0, 1.0 - x["weather"])) * (1.0 + 0.3 * max(0.0, -x["season"]))
        if self.flags["spaced"]:
            fire *= SPACED_FIRE_FACTOR
        fire *= math.exp(-HOME_FIRE * x.get("homes_q", 0.0))   # built_fabric.gd (crisis_system.gd)
        if day < self.until.get("burn", -1):
            fire *= 2.0
        out["fire"] = clamp(fire, 0.0, 2.0)
        flood = 0.0
        if x["river"]:
            flood = BASE_FLOOD_WET if x["weather_season"] > 1.03 else BASE_FLOOD_DRY
        out["flood"] = flood
        out["cold"] = VOLCANIC_NOTABLE / 100.0
        return out

    # -------------------------------------------------------------------- step
    def _chance(self, annual: float, days: float) -> float:
        """crisis_unattended.gd _roll over `days` days."""
        if annual <= 0.0:
            return 0.0
        daily = annual / 365.0 if annual >= 1.0 else 1.0 - (1.0 - min(annual, 0.999)) ** (1.0 / 365.0)
        return 1.0 - (1.0 - daily) ** days

    def _roll(self, annual: float, days: float) -> bool:
        return self.rng.random() < self._chance(annual, days)

    def _ready(self, kind: str, day: float, gap: float) -> bool:
        return day - self.last.get(kind, -99999.0) >= gap

    def step(self, day: float, days: float) -> None:
        """One sub-step [day, day + days): crisis_unattended.gd daily()."""
        x = None
        self.immunity *= 0.962 ** (days / 365.0)
        dens = clamp(max(1.0, self.sim.population) / 5000.0, 0.02, 1.0)
        target_pool = clamp(0.1 + 0.6 * dens + 0.3 * 0.05, 0.0, 1.0)
        if self.pool < 0.0:
            self.pool = target_pool
        self.pool += (target_pool - self.pool) * 0.01 * days / 365.0
        end = day + days
        for c in list(self.active):
            if c["phase"] == "open" and c["mid_day"] < end:
                x = x or self.inputs(day)
                self._mid(c, x)
            elif c["phase"] == "mid" and c["end_day"] < end:
                self._end(c, day)
        if day < QUIET_AFTER_FOUNDING:
            return
        if len(self.active) >= ACTIVE_MAX or day - self.last_onset < ONSET_GAP:
            return
        x = x or self.inputs(day)
        h = self.hazards(day, x)
        self._maybe_onset(day, days, x, h)

    def _maybe_onset(self, day: float, days: float, x: dict, h: dict) -> bool:
        for echo in list(self.echoes):
            if echo["day"] <= day + days:
                self.echoes.remove(echo)
                if not self._active("sickness"):
                    c = self._open_sickness(day, x, echo["v"])
                    c["echo_count"] = echo["count"]
                    return True
        hungry_now = (x["shortage_days"] >= 10.0 and x["intake"] < 0.94) or (0 < x["first_shortage"] <= 45 and x["food_days"] < LEAN_DAYS)
        if not self._active("hunger") and self._ready("hunger", day, 300) and (hungry_now or self._roll(h["hunger"], days)):
            self._open_hunger(day, x, h["hunger_shortfall"])
            return True
        if not self._active("drought") and self._ready("drought", day, 300) and x["weather_season"] < 0.88 and x["season"] > -0.45:
            self._open_drought(day, x)
            return True
        if self._ready("cold", day, 730) and self._roll(h["cold"], days):
            self._open_cold(day, x)
            return True
        if not self._active("sickness") and self._ready("sickness", day, 150):
            if self._roll(h["pestilence_emerge"], days):
                self._open_sickness(day, x, self._lognormal(0.06, 0.85, 0.005, 0.35))
                return True
            if self._roll(h["sickness"], days):
                self._open_sickness(day, x, self._lognormal(0.012, 0.8, 0.002, 0.25))
                return True
        if not self._active("flood") and self._ready("flood", day, 365) and self._roll(h["flood"], days):
            self._open_flood(day, x)
            return True
        if not self._active("fire") and self._ready("fire", day, 200) and self._roll(h["fire"], days):
            self._open_fire(day, x)
            return True
        return False

    # ------------------------------------------------------------------ onsets
    def _lognormal(self, median: float, sigma: float, lo: float, hi: float) -> float:
        return clamp(median * math.exp(sigma * self.rng.standard_normal()), lo, hi)

    def _new(self, kind: str, day: float, x: dict, mid: float, end: float, **extra) -> dict:
        self.serial += 1
        c = {"id": self.serial, "type": kind, "start": day, "phase": "open", "pop0": int(x["pop"]), "m": 0.0, "mult": 1.0, "deaths": 0,
             "mid_day": day + mid, "end_day": day + end, "severe": False, **extra}
        self.active.append(c)
        self.last[kind] = day
        self.last_onset = day
        self.onsets[kind] = self.onsets.get(kind, 0) + 1
        return c

    def _plan(self, c: dict, m: float) -> None:
        c["m"] = clamp(m, 0.0, 0.6)
        c["severe"] = c["m"] >= float(SEVERE.get(c["type"], 1.0))

    def _open_hunger(self, day: float, x: dict, shortfall: float) -> None:
        modern = clamp((x["H"] - 1850.0) / 100.0, 0.0, 1.0)
        m = clamp((0.012 + 0.2 * max(0.0, shortfall)) * (1.0 - 0.4 * x["inst"]) * (1.0 - 0.5 * modern) * math.exp(0.5 * self.rng.standard_normal()), 0.002, 0.25)
        c = self._new("hunger", day, x, self.rng.integers(28, 41), self.rng.integers(80, 121))
        self._plan(c, m)
        if c["severe"]:
            self.last["famine"] = day
        self._answer(c, "ration")

    def _mortality(self, v: float, x: dict) -> float:
        """CrisisSystem._mortality for a sickness of this people's own pool."""
        famine = 1.0 if self._active("hunger") else 0.0
        m = v * (0.5 + x["dens"]) * (1.0 - self.immunity) * (1.0 - x["med"]) ** 2 * (1.0 + 0.6 * famine)
        return clamp(m * math.exp(0.35 * self.rng.standard_normal()), 0.0, 0.6)

    def _open_sickness(self, day: float, x: dict, v: float) -> dict:
        c = self._new("sickness", day, x, self.rng.integers(14, 25), self.rng.integers(45, 81), v=v, hunger0=self._active("hunger") is not None)
        self._plan(c, self._mortality(v, x))
        sick = clamp(round(x["pop"] * (0.06 + 3.0 * c["m"])), 3, max(3, int(x["pop"] / 2.0)))
        self._policy({"labor_multiplier": -clamp(sick / max(1.0, x["pop"]) * 0.5, 0.01, 0.05)}, 21)
        self._answer(c, "apart" if self.flags["apart_custom"] else "tend")
        return c

    def _open_drought(self, day: float, x: dict) -> None:
        sev = max(clamp(1.0 - x["weather_season"], 0.0, 0.6), self.drought_depth(day))
        c = self._new("drought", day, x, self.rng.integers(30, 46), self.rng.integers(90, 131), sev=sev)
        self._plan(c, self._lognormal(0.002, 1.0, 0.0, 0.05) * (1.0 + 4.0 * sev))
        self._answer(c, "carry")

    def _open_cold(self, day: float, x: dict) -> None:
        loss = clamp(self.rng.uniform(0.04, 0.12) * (1.0 - 0.5 * x["divers"]) * 1.3, 0.02, 0.2)
        c = self._new("cold", day, x, 40, self.rng.integers(200, 301), sev=loss)
        c["severe"] = True
        self._policy({"food_yield": -loss}, 365)
        self._answer(c, "ration")

    def _spoil(self, share: float) -> None:
        s = self.sim
        s.stored *= 1.0 - clamp(share, 0.0, 1.0)
        s.fresh *= 1.0 - clamp(share, 0.0, 1.0)

    def _roofs(self, x: dict, lo: float, hi: float) -> int:
        s = self.sim
        before = float(s.housing_capacity)
        after = max(float(int(x["pop"] * 0.5)), before - max(1.0, round(before * self.rng.uniform(lo, hi))))
        s.housing_capacity = after
        return int(before - after)

    def _open_flood(self, day: float, x: dict) -> None:
        self._spoil(self.rng.uniform(0.10, 0.35))
        lost = self._roofs(x, 0.08, 0.30)
        c = self._new("flood", day, x, self.rng.integers(20, 31), self.rng.integers(55, 81), house_lost=lost)
        self._plan(c, self._lognormal(0.003, 1.0, 0.0, 0.04))
        self.until["after_flood"] = day + 75

    def _open_fire(self, day: float, x: dict) -> None:
        self._spoil(self.rng.uniform(0.04, 0.22))
        lost = self._roofs(x, 0.08, 0.25)
        c = self._new("fire", day, x, self.rng.integers(12, 21), self.rng.integers(40, 61), house_lost=lost)
        self._plan(c, self._lognormal(0.002, 1.1, 0.0, 0.03))
        self._health(-0.01)
        self.fires += 1
        if self.fires >= 2:
            c["choice"] = "apart"
            self.flags["spaced"] = True
            self._policy(REBUILD_APART_EFFECTS, REBUILD_APART_DAYS)
        else:
            c["choice"] = "rebuild"
            self.sim.housing_capacity += lost * 0.8
            self._policy({"labor_multiplier": -0.08}, 20)

    # ----------------------------------------------------------------- answers
    def _answer(self, c: dict, choice: str) -> None:
        c["choice"] = choice
        if choice == "ration":
            cut = 0.25 if c["type"] == "hunger" else 0.15
            self._policy({"food_demand": -cut, "health_target": -0.02}, 100 if c["type"] != "cold" else 200)
            c["mult"] *= float(DEATH_FACTOR["ration"])
            self._cohesion(-0.005)
        elif choice == "apart":
            c["mult"] *= APART_CUSTOM_FACTOR
            self._cohesion(-0.01)
        elif choice == "tend":
            c["mult"] *= float(DEATH_FACTOR["tend"])
            self._policy({"labor_multiplier": -0.05}, 30)
            self._cohesion(0.01)
        elif choice == "carry":
            self._policy({"labor_multiplier": -0.06}, 90)
            c["mult"] *= float(DEATH_FACTOR["carry"])

    def _mid(self, c: dict, x: dict) -> None:
        c["phase"] = "mid"
        if c["type"] == "sickness" and not c.get("hunger0", True) and self._active("hunger"):
            c["m"] = clamp(c["m"] * 1.6, 0.0, 0.6)
            c["hunger0"] = True
        self._due(c, 0.4)
        if c["type"] == "sickness":
            if c["pop0"] * c["m"] * c["mult"] * 0.6 >= 1.5:
                c["mult"] *= float(DEATH_FACTOR["children_apart"])
                self._cohesion(-0.006)
        elif c["type"] == "hunger":
            if x["food_days"] < STORE_GATE * 25.0 or x["intake"] < 0.95:
                c["mult"] *= float(DEATH_FACTOR["roots"])
                self._policy({"labor_multiplier": -0.08}, 30)
                self.sim.stored += x["pop"] * 0.25

    def _end(self, c: dict, day: float) -> None:
        self._due(c, 0.6)
        if c["type"] == "sickness":
            self.immunity = max(self.immunity, min(0.85, 0.35 + 4.0 * c["m"]))
            self._health(0.15 * c["m"])
            if c["m"] >= 0.02 or c.get("choice") == "apart":
                self.flags["apart_custom"] = True
            v = float(c.get("v", 0.0))
            echoes = int(c.get("echo_count", 0))
            if v >= 0.03 and echoes < 6 and self.rng.random() < min(0.8, 2.0 * v):
                self.echoes.append({"count": echoes + 1, "day": day + int(self.rng.integers(8, 21)) * 365, "v": v * self.rng.uniform(0.35, 0.75)})
        if c["type"] == "fire" and c.get("choice") == "apart":
            self.sim.housing_capacity += float(c.get("house_lost", 0))
        if c["deaths"] > 0:
            self._policy({"labor_multiplier": -0.03}, 20)
        self.active.remove(c)
        self.history.append({"type": c["type"], "start": c["start"], "deaths": c["deaths"], "m": c["m"], "severe": c["severe"]})
        if len(self.history) > 400:
            del self.history[:-400]

    # ---------------------------------------------------------------- effects
    def _due(self, c: dict, share: float) -> None:
        expected = c["pop0"] * c["m"] * c["mult"] * share
        self._kill(c, int(math.floor(expected + self.rng.random())))

    def _kill(self, c: dict, count: int) -> None:
        if count <= 0:
            return
        s = self.sim
        floor_count = max(FLOOR_PEOPLE, round(c["pop0"] * FLOOR_SHARE))
        allowed = min(count, max(0, int(s.population) - floor_count))
        if allowed <= 0:
            return
        cause = CAUSE.get(c["type"], "Hardship")
        share = s.coh * cause_weights(cause)
        if share.sum() <= 1e-9:
            share = s.coh.copy()
        removed = np.minimum(share / max(1e-9, share.sum()) * allowed, s.coh * 0.999)
        s.coh = s.coh - removed
        n = float(removed.sum())
        s.deaths += n
        s._sync()
        c["deaths"] += allowed
        self.total_deaths += n
        self.cohort_deaths += removed
        self.deaths_by_cause[cause] = self.deaths_by_cause.get(cause, 0.0) + n

    def _health(self, delta: float) -> None:
        self.sim.health = clamp(self.sim.health + delta, 0.02, 0.97)

    def _cohesion(self, delta: float) -> None:
        self.sim.cohesion = clamp(self.sim.cohesion + delta, 0.01, 0.99)
