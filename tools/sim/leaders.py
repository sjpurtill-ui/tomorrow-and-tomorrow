#!/usr/bin/env python3
"""Leader tendencies in the fast sim: every automated leader plays by one set
of rules, and its temper only moves preferences.

    python tools/sim/leaders.py --seeds 2 --years 600 [--site good|poor|both] [--ambitions] [--shocks] [--json out.json]

An automated leader is a computer ruler (its personality) or the player's own
leaders (the people's tendency, the values they live by: leader_personality.gd
from_values). Both read the same rules. This runs five archetypal tempers (or,
with --ambitions, one temper leaning toward each ambition) through them on the
good and the poor site and asks: is any temper at least as good as another on
every outcome, and does each have a clear strength and a clear cost? About
25 s for the archetypes, 75 s for the ambitions (10 processes).

Rules mirrored here (each names its engine source; constants are parsed from
the GDScript so they cannot drift):

* century ambition: civilization_strategy.gd preferences, by
  leader_personality.gd AMBITION_TEMPER (every ambition open to a ruler);
* daily labor: GovernmentPeopleSystem._allocations_for_focus with the people's
  cultural labor bias (cultural_inheritance.gd WORK) and its wish for food
  work planned as deeper stores (reserve_lean_of), in model.py _allocate_labor;
* the path the work leans toward: work_paths.gd choose by temper (no war or
  neighbours' pull here); each role takes the larger of the path's WORK and
  the ambitions' labor bias, and the reserve the larger of the two leans
  (work_paths.gd lean: one temper's two asks never stack);
* research: the ruler's emphasis (preferences research weights plus the
  controller's culture weights, research_plan in ATTENTION_STEPS steps)
  and the ambition's pace (PeopleDirection.research_multiplier);
* expansion: civilization_strategy.gd expansion_food, expansion_months,
  settle_distance and settle_margin_days, with the founding party of
  SettlementModel.settlement_convoy_quote (40 people or 2 %, 80 stay);
* great works: civilization_controller.gd great_work_orders (motives,
  interval, ambition by wonder_ambition_value, pace), the gates answered by
  civilization_strategy.gd works_answer, outcomes by wonder_concept.gd odds;
* standing: raiders come for stores and works that are envied and not held
  in awe (standing.gd view_of envy, war_loop.gd envy_raid_chance); an
  empathetic ruler's goodwill gifts come from real stores and win treaties
  (civilization_strategy.gd goodwill_gift; a treaty adds trust in standing.gd).

Surrogate stand-ins (not engine numbers): one more good site becomes known
every 30 years (the truth runs' one daughter town per 30 years); a new town's
first harvest comes 25-70 days in; a work's base size is the mean concept form
(6,000 crew-days) and needs no materials here; neighbours are one people per
80 years after first contact, up to three, each the same size with 3 % under
arms; a raid that is not repelled carries off up to a fifth of the stores and
up to one in 170 people, less the better we are guarded.
"""
from __future__ import annotations

import argparse
import collections
import json
import math
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gamedata as gd  # noqa: E402
import gdparse as g  # noqa: E402
import simlib  # noqa: E402
from model import HUNGER_W, INSEC_W, MONTH, YEAR, Scenario, Surrogate, clamp, lerp  # noqa: E402

AXES = ["openness", "discipline", "empathy", "assertiveness", "risk_tolerance"]
TEMPER = g.const("scripts/leader_personality.gd", "AMBITION_TEMPER")
WORK = g.const("scripts/cultural_inheritance.gd", "WORK")
PROFILES = g.const("scripts/cultural_inheritance.gd", "PROFILES")
AMBITIONS = g.const("scripts/people_direction.gd", "AMBITIONS")
RESERVE_FOOD_WISH = float(g.const("scripts/government_people_system.gd", "RESERVE_FOOD_WISH"))
PATH_TEMPER = g.const("scripts/work_paths.gd", "PATH_TEMPER")
PATH_WORK = g.const("scripts/work_paths.gd", "WORK")
PATH_FOOD_LEAN = g.const("scripts/work_paths.gd", "FOOD_LEAN")
SCHOLARLY = float(g.const("scripts/work_paths.gd", "SCHOLARLY"))
BALANCED_BELOW = float(g.const("scripts/work_paths.gd", "BALANCED_BELOW"))
ESTABLISHMENT_DAYS = float(g.const("scripts/civilization_strategy.gd", "ESTABLISHMENT_DAYS"))
EXPANSIONIST_DRIVE = float(g.const("scripts/civilization_strategy.gd", "EXPANSIONIST_DRIVE"))
LONGEST_LOOK = int(g.const("scripts/civilization_strategy.gd", "LONGEST_LOOK_MONTHS"))
WONDER_PAYOFF = g.const("scripts/civilization_strategy.gd", "WONDER_PAYOFF")
MOTIVE_THRESHOLD = float(g.const("scripts/civilization_strategy.gd", "WONDER_MOTIVE_THRESHOLD"))
GOODWILL_FOOD_DAYS = float(g.const("scripts/civilization_strategy.gd", "GOODWILL_FOOD_DAYS"))
AMBITION_RISK = g.const("scripts/wonder_concept.gd", "AMBITION_RISK")
AMBITION_PAY = g.const("scripts/wonder_concept.gd", "AMBITION_PAY")
AMBITION_TRIUMPH = g.const("scripts/wonder_concept.gd", "AMBITION_TRIUMPH")
AMBITION_WORK = g.const("scripts/wonder_concept.gd", "AMBITION_WORK")
OUTCOME_PAY = g.const("scripts/wonder_concept.gd", "OUTCOME_PAY")
ENVY_RAID_FLOOR = float(g.const("scripts/standing.gd", "ENVY_RAID_FLOOR"))
WEALTH_FOOD_DAYS = float(g.const("scripts/standing.gd", "WEALTH_FOOD_DAYS"))
WARRIOR_WEIGHT = float(g.const("scripts/standing.gd", "WARRIOR_WEIGHT"))
NEEDING_OTHERS = g.const("scripts/civilization_strategy.gd", "AMBITIONS_NEEDING_OTHERS")
HALF_LIFE_DAYS = float(g.const("scripts/cultural_inheritance.gd", "HALF_LIFE_DAYS"))
CENTURY_DAYS = float(g.const("scripts/people_direction.gd", "CENTURY_DAYS"))
HARD_YEAR_DEATHS = float(g.const("scripts/civilization_controller.gd", "HARD_YEAR_DEATHS"))
ATTENTION_STEPS = int(g.const("scripts/research_600_catalog.gd", "ATTENTION_STEPS", default=4, optional=True))
TEMPER_LEAN = 0.6           # how far the --ambitions tempers lean from even toward their ambition
GATES = [(0.25, "design"), (0.45, "stores"), (0.70, "labor")]
WORK_BASE = 6000.0          # mean base work of the concept forms (wonder_concept.gd FORMS)
SITE_YEARS = 30.0           # one more good site known every 30 years
NEIGHBOUR_YEARS = 80.0      # one more neighbouring people every 80 years after first contact
NEIGHBOURS_MAX = 3

ARCHETYPES = {
    "cautious-caring": {"openness": .45, "discipline": .5, "empathy": .85, "assertiveness": .2, "risk_tolerance": .15},
    "bold-expansionist": {"openness": .6, "discipline": .3, "empathy": .4, "assertiveness": .7, "risk_tolerance": .9},
    "disciplined-warlike": {"openness": .3, "discipline": .85, "empathy": .25, "assertiveness": .9, "risk_tolerance": .5},
    "open-scholarly": {"openness": .9, "discipline": .55, "empathy": .5, "assertiveness": .3, "risk_tolerance": .3},
    "balanced": {"openness": .5, "discipline": .5, "empathy": .5, "assertiveness": .5, "risk_tolerance": .5},
}


# ------------------------------------------------------------------ the rules
def ambition_fit(ambition: str, p: dict) -> float:
    """leader_personality.gd ambition_fit."""
    return sum(w * p[a] if w >= 0 else -w * (1.0 - p[a]) for a, w in TEMPER[ambition].items())


def choose_ambition(p: dict, peoples_known: int = -1) -> str:
    """civilization_strategy.gd preferences: the best-fitting ambition (ties keep
    the first); ambitions that need other peoples wait until one is known."""
    fit = {a: ambition_fit(a, p) * (.5 if peoples_known == 0 and a in NEEDING_OTHERS else 1.0) for a in TEMPER}
    best = "horizons"
    for a in TEMPER:
        if fit[a] > fit[best]:
            best = a
    return best


def work_path(p: dict) -> str:
    """work_paths.gd choose, calm: the path whose temper fits best above the
    balanced line; learning only for a scholarly temper."""
    best, top = "balanced", BALANCED_BELOW
    for path, weights in PATH_TEMPER.items():
        if path == "learning" and p["openness"] < SCHOLARLY:
            continue
        fit = sum(w * p[a] if w >= 0 else -w * (1.0 - p[a]) for a, w in weights.items())
        if fit > top:
            best, top = path, fit
    return best


def choice_weights(events: list, day: float) -> dict:
    """cultural_inheritance.gd choice_weights: a quarter of every choice ever made,
    plus each event fading with a sixty-year half-life."""
    scores: dict = {}
    for _day, choice, weight in events:
        scores[choice] = scores.get(choice, 0.0) + weight * .25
    for event_day, choice, weight in events:
        scores[choice] = scores.get(choice, 0.0) + weight * .5 ** (max(0.0, day - event_day) / HALF_LIFE_DAYS)
    return scores


def culture_drive(scores: dict) -> float:
    """cultural_inheritance.gd weight(ambition, expansion), current distribution, approximately."""
    total = expansion = 0.0
    for choice, weight in scores.items():
        poles = PROFILES.get(choice, {}).get("ambition", {})
        total += weight * sum(poles.values())
        expansion += weight * poles.get("expansion", 0.0)
    return expansion / total if total > 0 else 0.0


def research_weights(p: dict) -> dict:
    """civilization_strategy.gd preferences research weights, leading goal included."""
    o, d, e, a, r = (p[x] for x in AXES)
    w = {"demography": .25 + e * .9, "nutrition": .3 + e * .6 + (1 - r) * .3, "health": .25 + e * .8, "labor": .2 + d * .6,
         "knowledge": .15 + o * 1.2, "production": .25 + d * .5 + o * .4, "infrastructure": .25 + d * .65, "logistics": .25 + o * .5 + a * .3,
         "ecology": .2 + e * .45 + (1 - r) * .35, "institutions": .2 + d * .65, "security": .15 + a * .8 + d * .5, "culture": .2 + e * .6 + o * .4}
    goals = {"care": e, "learning": o, "security": d * .6 + (1 - r) * .4, "exchange": e * .55 + o * .45, "growth": d * .45 + a * .55}
    domains = {"care": {"health": 1.5, "demography": .7}, "learning": {"knowledge": 1.8, "culture": .4}, "security": {"security": 1.8, "infrastructure": .6, "logistics": .4},
               "exchange": {"logistics": 1.5, "production": .75, "culture": .5}, "growth": {"infrastructure": 1.5, "demography": 1.0, "production": .5}}
    lead = max(goals, key=lambda k: goals[k])
    for k, v in domains[lead].items():
        w[k] += v
    return w


def research_plan(weights: dict, steps: int = -1) -> dict:
    """civilization_strategy.gd research_plan: shares in ATTENTION_STEPS steps; with
    steps enough every weighed field keeps one, the rest by preference, 12 at most."""
    if steps < 0:
        steps = ATTENTION_STEPS
    out = dict.fromkeys(gd.LINES, 0)
    weighed = [k for k in gd.LINES if float(weights.get(k, .1)) > 0.0]
    if not weighed or steps <= 0:
        return out
    left = steps
    if steps >= len(weighed):
        for k in weighed:
            out[k] = 1
        left -= len(weighed)
    for _ in range(left):
        best = max((k for k in weighed if out[k] < 12), key=lambda k: float(weights.get(k, .1)) / (out[k] + 1), default=None)
        if best is None:
            break
        out[best] += 1
    return out


def expansion_months(p: dict, drive: float) -> int:
    """civilization_strategy.gd expansion_months."""
    if drive >= EXPANSIONIST_DRIVE:
        return 1
    caution = (1 - p["risk_tolerance"]) * .6 + (1 - p["assertiveness"]) * .4
    return int(clamp(1 + math.floor(caution * 4.0 + .5), 1, LONGEST_LOOK))


def expansion_plan(p: dict, drive: float) -> dict:
    """civilization_strategy.gd preferences expansion fields, with the controller's drive."""
    return {"food": max(45.0, (45 + (1 - p["risk_tolerance"]) * 40 + p["empathy"] * 15) * (1.0 - drive * .35)),
            "distance": 16 + 24 * p["risk_tolerance"], "margin": ESTABLISHMENT_DAYS * lerp(1.35, .65, p["risk_tolerance"]),
            "months": expansion_months(p, drive)}


def works_answer(key: str, facts: dict, p: dict) -> str:
    """civilization_strategy.gd works_answer."""
    e, a, r = p["empathy"], p["assertiveness"], p["risk_tolerance"]
    enabled = facts.get("enabled", set())
    if key == "design":
        return "grander" if facts.get("ample", True) and facts["feasibility"] >= .85 - .3 * (a * .5 + r * .5) else "practical"
    if key == "stores":
        return "pour" if "pour" in enabled and facts["food_days"] >= 150.0 - 60.0 * r else "protect"
    if key == "labor":
        if a * .5 + (1 - e) * .5 >= .65 and facts.get("hierarchy", .5) >= .65 and facts.get("cohesion", .5) >= .65:
            return "levy"
        if "paid" in enabled and e * .6 + (1 - a) * .4 < .7:
            return "paid"
        return "volunteers"
    return ""


def wonder_motive(kind: str, p: dict) -> float:
    """civilization_strategy.gd wonder_motive."""
    o, d, e, a, r = (p[x] for x in AXES)
    return {"victory": a * .6 + r * .2 + .3, "death": e * .7 + .3, "famine": e * .5 + (1 - r) * .3 + .3, "anniversary": d * .5 + o * .2 + .3,
            "envy": max(a * .7 + (1 - e) * .35, o * .55 + e * .25), "plenty": o * .3 + a * .3 + r * .3 + .15}.get(kind, 0.0)


def wonder_value(ambition: str, f: float, p: dict) -> float:
    """civilization_strategy.gd wonder_ambition_value."""
    r, a = p["risk_tolerance"], p["assertiveness"]
    if f < .45 - .4 * r:
        return -math.inf
    return WONDER_PAYOFF[ambition] ** (a * .5 + r * .5 + .2) * max(.001, f) ** (1.4 - r)


def wonder_interval_days(p: dict) -> float:
    """civilization_strategy.gd wonder_interval_days."""
    return 365.0 * (12.0 - 8.0 * (p["assertiveness"] * .5 + p["risk_tolerance"] * .5))


def odds(score: float, ambition: str) -> dict:
    """wonder_concept.gd odds."""
    risk = AMBITION_RISK[ambition]
    collapse = clamp((1.0 - score) ** 1.6 * .9 * risk, 0, .9)
    flawed = clamp((1.0 - score) * .45 * math.sqrt(risk), 0, 1.0 - collapse)
    triumph = clamp(score * score * .25 * AMBITION_TRIUMPH[ambition], 0, 1.0 - collapse - flawed)
    return {"collapse": collapse, "flawed": flawed, "triumph": triumph}


# --------------------------------------------------------------- the society
class LeaderSurrogate(Surrogate):
    """One people under one temper, by the shared rules above."""

    def __init__(self, scenario, seed, params, data, temper: dict, **kw):
        self.temper = {k: float(temper[k]) for k in AXES}
        # The founding century's ambition, chosen before any other people is known.
        self.ambition = choose_ambition(self.temper, 0)
        self.culture_events = [(0.0, self.ambition, 10.0)]
        self.ambitions_taken = [self.ambition]
        scenario.research = dict.fromkeys(gd.LINES, 0)
        super().__init__(scenario, seed, params, data, **kw)
        self.base_chance = self.chance.copy()
        self.leader_rng = np.random.default_rng((seed * 7919 + 17) & 0xFFFFFFFF)
        self._culture_refresh()
        self.daughters = 0
        self.convoy_until = -1.0
        self.settler_deaths = 0.0
        self.hunger_deaths = 0.0
        self.deaths_by_month: collections.deque = collections.deque(maxlen=25)
        self.hunger_by_month: collections.deque = collections.deque(maxlen=25)
        self.work = None
        self.last_started = -1e9
        self.works_done = self.triumphs = self.follies = 0
        self.folly_deaths = 0.0
        self.splendor = 0.0
        self.raids = self.repelled = 0
        self.raid_deaths = self.raid_stores = 0.0
        self.gifts = 0
        self.gift_food = 0.0
        self.last_gift = -1e9
        self.treaty = False
        self.victory_day = -1e9
        self.construction_diverted = 0.0

    def _culture_refresh(self) -> None:
        """What the people's ambitions do now (choice weights fade with the years):
        the labor bias and deeper stores (GovernmentPeopleSystem), the research
        pace (PeopleDirection.research_multiplier), the ruler's research emphasis
        (preferences + current_plan's culture weights, research_plan) and
        the expansion drive (current_plan)."""
        p = self.temper
        scores = choice_weights(self.culture_events, self.day)
        total = sum(scores.values()) or 1.0
        share = {c: w / total for c, w in scores.items()}
        bias: dict = {}
        for c, s in share.items():
            for role, v in WORK[c].items():
                bias[role] = bias.get(role, 0.0) + v * s
        # The path the ruler leans the work toward (work_paths.gd lean).
        path = work_path(p)
        food_wish = float(bias.get("Food", 0.0))
        for role, v in PATH_WORK.get(path, {}).items():
            bias[role] = max(bias.get(role, 0.0), float(v))
        self.culture_bias = bias
        self.reserve_lean = clamp(max(food_wish / RESERVE_FOOD_WISH, float(PATH_FOOD_LEAN.get(path, 0.0))), 0.0, 1.0)
        relevant = {line: sum(s for c, s in share.items() if line in AMBITIONS[c]["domains"]) for line in gd.LINES}
        mult = np.array([.95 + .30 * relevant[line] for line in gd.LINES])
        self.chance = self.base_chance * mult[self.cat.line]
        weights = research_weights(p)
        for c, s in share.items():
            for d in AMBITIONS[c]["domains"]:
                weights[d] += s * 4.0
        self.s.research = research_plan(weights)
        self.drive = culture_drive(scores)
        self.expand = expansion_plan(p, self.drive)

    # ---- helpers
    def _remove(self, count: float, weights) -> float:
        share = self.coh * weights
        total = share.sum()
        if total <= 0 or count <= 0:
            return 0.0
        taken = np.minimum(self.coh, share / total * count)
        self.coh = self.coh - taken
        self._sync()
        return float(taken.sum())

    def _take_stores(self, amount: float) -> float:
        taken = max(0.0, min(amount, self.fresh + self.stored))
        fresh = min(self.fresh, taken)
        self.fresh -= fresh
        self.stored = max(0.0, self.stored - (taken - fresh))
        return taken

    def _hungry(self) -> bool:
        return self.last.get("intake", 1.0) < .98

    # ---- one month of the leaders' decisions
    def _monthly(self, year: float) -> None:
        pop = self.population
        self.hunger_deaths += float(getattr(self, "mortality", {}).get("Hunger", 0.0)) * pop * MONTH / YEAR
        self.deaths_by_month.append(float(getattr(self, "deaths", 0.0)))
        self.hunger_by_month.append(self.hunger_deaths)
        # A new century: the ruler takes up its ambition again, now knowing
        # whether other peoples are about (civilization_controller order_steps).
        century = int(self.day // CENTURY_DAYS)
        if century > int((self.day - MONTH) // CENTURY_DAYS) and self.day > MONTH:
            self.ambition = choose_ambition(self.temper, self.neighbours(year))
            self.culture_events.append((self.day, self.ambition, 10.0))
            self.ambitions_taken.append(self.ambition)
        if int(self.day // MONTH) % 12 == 0:
            self._culture_refresh()
        self._expansion(year)
        self._works(year)
        self._standing(year)

    def _expansion(self, year: float) -> None:
        """civilization_controller.expansion_order_steps by the shared rule."""
        x = self.expand
        if self.completed < 1.0 or self.day < self.convoy_until:
            return
        if int(self.day // 30) % x["months"] != 0:
            return
        if self._hungry() or self.stored_days < x["food"]:
            return
        if self.daughters >= int(year / SITE_YEARS):
            return
        pop = self.population
        founders = max(40.0, round(pop * .02))
        if pop - founders < 80.0:
            return
        travel = x["distance"] * self.leader_rng.uniform(.5, 1.5) / 16.0
        food = founders * (travel + x["margin"])
        if self.fresh + self.stored < food:
            return
        self._take_stores(food)
        # The new town eats what its settlers carried until its first harvest:
        # thin rations meet a late harvest with hunger.
        short = max(0.0, float(self.leader_rng.uniform(25.0, 70.0)) - x["margin"])
        self.settler_deaths += self._remove(founders * min(.4, short * .004), HUNGER_W)
        self.daughters += 1
        self.convoy_until = self.day + travel + 30.0

    def _works(self, year: float) -> None:
        """Great works: conception, gates, building and outcome."""
        p = self.temper
        food_days = self.stored_days
        if self.work is not None:
            self._build(p, food_days)
            return
        self.construction_diverted = 0.0
        # civilization_controller.great_work_orders: not hungry, 60 days in store,
        # the ruler's interval since the last work, a motive strong enough.
        if self.completed < 1.0 or self._hungry() or food_days < 60 or self.day - self.last_started < wonder_interval_days(p):
            return
        pop = self.population
        found = []
        if year >= 25 and int(year) % 25 == 0 and (self.day % YEAR) < MONTH:
            found.append("anniversary")
        if food_days > 150:
            found.append("plenty")
        if self.day - self.victory_day < YEAR:
            found.append("victory")
        if len(self.deaths_by_month) >= 25:
            # A hard year: well past the deaths of the year before (conception_trigger).
            last, before = self.deaths_by_month[-1] - self.deaths_by_month[-13], self.deaths_by_month[-13] - self.deaths_by_month[0]
            if last >= max(5.0, pop * .03) and last >= before * HARD_YEAR_DEATHS:
                found.append("death")
        if len(self.hunger_by_month) >= 25 and self.hunger_by_month[-1] - self.hunger_by_month[0] >= max(2.0, pop * .005):
            found.append("famine")
        if self.neighbours(year) > 0 and self.leader_rng.random() < .1 / 12.0:
            found.append("envy")
        best, motive = "", MOTIVE_THRESHOLD
        for kind in found:
            m = wonder_motive(kind, p)
            if m >= motive:
                best, motive = kind, m
        if not best:
            return
        # The builders' odds by ambition; more builders and better tools do better.
        capability = (self.capacities.get("infrastructure", .3) + self.capacities.get("production", .3)) * .5 - .4
        chosen, value, feasibility = "", -math.inf, 0.0
        for ambition, base in (("modest", .82), ("grand", .64), ("audacious", .42)):
            f = clamp(base + capability * .25, .05, .95)
            v = wonder_value(ambition, f, p)
            if v > value:
                chosen, value, feasibility = ambition, v, f
        if not chosen or value == -math.inf:
            return
        self.work = {"ambition": chosen, "total": WORK_BASE * AMBITION_WORK[chosen], "scale": 1.0, "speed": 1.0, "progress": 0.0, "quality": 0.0,
                     "shift": 0.0, "feasibility": feasibility, "allure": 1.0, "gates": set()}
        self.last_started = self.day

    def _build(self, p: dict, food_days: float) -> None:
        w = self.work
        press = (p["discipline"] > .6 and food_days > 90) or (p["risk_tolerance"] > .75 and food_days > 60)
        share = .5 if press else .2
        self.construction_diverted = share
        crew = self.workers("Construction") * share * w["speed"]
        if not press and self.last.get("intake", 1.0) < .95:
            crew = 0.0
        quality = clamp(.4 * getattr(self, "labor_eff", .72) + .2 * self.cohesion + .4 * .7, .1, 1)
        w["progress"] += crew * quality * MONTH
        w["quality"] += crew * quality * quality * MONTH
        total = w["total"] * w["scale"]
        for at, key in GATES:
            if key in w["gates"] or w["progress"] < total * at:
                continue
            w["gates"].add(key)
            left = total - w["progress"]
            facts = {"feasibility": clamp(w["feasibility"] + w["shift"], .02, .98), "food_days": food_days, "cohesion": self.cohesion,
                     "enabled": {"pour"} | ({"paid"} if self.fresh + self.stored >= left * .04 else set())}
            answer = works_answer(key, facts, p)
            if answer == "grander":
                w["scale"] *= 1.25; w["allure"] *= 1.35; w["shift"] -= .08
            elif answer == "practical":
                w["scale"] = max(w["progress"] / w["total"] + .01, w["scale"] * .85); w["allure"] *= .8; w["shift"] += .06
            elif answer == "pour":
                rations = self._take_stores(min((self.fresh + self.stored) * .25, total * .10 * 2.0))
                w["progress"] += rations * .5; w["shift"] += .02
            elif answer == "paid":
                self._take_stores(left * .04); w["speed"] *= 1.15; self.cohesion = clamp(self.cohesion + .02, .01, .99); w["shift"] += .04
            elif answer == "levy":
                w["speed"] *= 1.4; self.cohesion = clamp(self.cohesion - .05, .01, .99); self.legitimacy = clamp(self.legitimacy - .03, .01, .99); w["shift"] -= .03
            elif answer == "volunteers":
                w["speed"] *= .85; w["allure"] *= 1.1; self.cohesion = clamp(self.cohesion + .01, .01, .99); w["shift"] += .03
            w["shift"] = clamp(w["shift"], -.4, .4)
        if w["progress"] < w["total"] * w["scale"]:
            return
        score = clamp(w["feasibility"] + w["shift"] + (clamp(w["quality"] / max(1.0, w["progress"]), 0, 1) - .75) * .3, .02, .98)
        o = odds(score, w["ambition"])
        roll = float(self.leader_rng.random())
        if roll < o["collapse"]:
            risk = AMBITION_RISK[w["ambition"]]
            self.follies += 1
            self.folly_deaths += self._remove(int(clamp(round(risk * 2.0), 1, 4)), INSEC_W)
            self.cohesion = clamp(self.cohesion - .04 * risk, .01, .99)
            self.legitimacy = clamp(self.legitimacy - .05 * risk, .01, .99)
        else:
            outcome = "flawed" if roll < o["collapse"] + o["flawed"] else "triumph" if roll < o["collapse"] + o["flawed"] + o["triumph"] else "success"
            self.works_done += 1
            self.triumphs += outcome == "triumph"
            self.splendor += 6.0 * AMBITION_PAY[w["ambition"]] * OUTCOME_PAY[outcome] * w["allure"]
            self.cohesion = clamp(self.cohesion + {"triumph": .03, "success": .015}.get(outcome, 0.0), .01, .99)
            if outcome == "triumph":
                self.legitimacy = clamp(self.legitimacy + .02, .01, .99)
        self.work = None
        self.construction_diverted = 0.0

    def neighbours(self, year: float) -> int:
        contact = float(self.p.get("contact_year", 40.0))
        return 0 if year < contact else min(NEIGHBOURS_MAX, 1 + int((year - contact) / NEIGHBOUR_YEARS))

    def might_ratio(self) -> float:
        """standing.gd our_fighting_strength over a same-size neighbour's (3 % under arms, ready 0.45)."""
        warriors = clamp(self.alloc_pct["Defense"] / 100.0 * self.able / max(1.0, self.population), 0, 1)
        readiness = clamp(self.security, 0, 1)
        ours = (1 - warriors) * .8 + warriors * (1 + WARRIOR_WEIGHT * readiness)
        theirs = .97 * (.55 + .45 * .3) + .03 * (1 + WARRIOR_WEIGHT * .45)
        return ours / theirs

    def _standing(self, year: float) -> None:
        """Envy raids (standing.gd view_of, war_loop.gd envy_raid_chance) and goodwill."""
        n = self.neighbours(year)
        if n <= 0:
            return
        p = self.temper
        # An empathetic ruler sends goodwill with a gift from full stores, one
        # mission at a time; welcomed gifts open a treaty.
        if p["empathy"] > .65 and not self.treaty and self.stored_days >= GOODWILL_FOOD_DAYS and self.day - self.last_gift >= 180.0:
            self.gift_food += self._take_stores(clamp(self.population * 1.25, 10.0, 300.0))
            self.gifts += 1
            self.last_gift = self.day
            self.treaty = self.gifts >= 2
        ratio = self.might_ratio()
        might_term = clamp((ratio - .8) / 1.6, 0, 1)
        heard = clamp(self.splendor / 30.0, 0, 1)
        awe = clamp(might_term * .45 + heard * .35, 0, 1)
        trust = .5 + (.15 if self.treaty else 0.0)
        wealth = clamp(clamp(self.stored_days / WEALTH_FOOD_DAYS, 0, 1) * .65 + clamp(self.material, 0, 1) * .35, 0, 1)
        envy = clamp((wealth * .6 + heard * .4) * (1 - awe) * (1 - trust * .5), 0, 1)
        chance = clamp((envy - ENVY_RAID_FLOOR) * .06, 0, .03)
        for _ in range(n):
            if self.leader_rng.random() >= chance:
                continue
            self.raids += 1
            if ratio >= 1.25:
                self.repelled += 1
                self.victory_day = self.day
                self.raid_deaths += self._remove(self.population * .001, INSEC_W)
                continue
            exposure = clamp(1.45 - ratio, .2, 1.0)
            self.raid_stores += self._take_stores((self.fresh + self.stored) * .2 * exposure)
            self.raid_deaths += self._remove(self.population * .006 * exposure, INSEC_W)
            self.cohesion = clamp(self.cohesion - .01 * exposure, .01, .99)

    def snapshot(self) -> dict:
        row = super().snapshot()
        if hasattr(self, "temper"):
            row.update({"ambition": self.ambition, "ambitions": list(self.ambitions_taken), "towns": 1 + self.daughters, "settler_deaths": self.settler_deaths, "hunger_deaths": self.hunger_deaths,
                        "works": self.works_done, "triumphs": self.triumphs, "follies": self.follies, "folly_deaths": self.folly_deaths,
                        "splendor": self.splendor, "raids": self.raids, "repelled": self.repelled, "raid_deaths": self.raid_deaths,
                        "raid_stores": self.raid_stores, "gifts": self.gifts, "gift_food": self.gift_food, "might_ratio": self.might_ratio()})
        return row


def _shock_class():
    from shock_world import ShockSurrogate

    class LeaderShockSurrogate(LeaderSurrogate, ShockSurrogate):
        """The same people inside the opt-in epochal-shock world (shock_world.py)."""
    return LeaderShockSurrogate


def temper_choosing(ambition: str) -> dict:
    """A temper leaning from even toward one ambition's weights (AMBITION_TEMPER),
    so a ruler of that temper takes it up (tests/test_leader_balance.gd checks every one)."""
    return {a: clamp(.5 + TEMPER[ambition].get(a, 0.0) * TEMPER_LEAN, .12, .92) for a in AXES}


def run_one(args) -> tuple:
    name, temper, seed, years, site, shocks = args
    constants, cat = simlib.data()
    _table, sites = simlib.scenarios()
    scenario = Scenario.from_dict(f"leader:{name}", {"site": site, "research": {}, "labor": {}}, sites)
    cls = _shock_class() if shocks else LeaderSurrogate
    model = cls(scenario, seed, simlib.params(), (constants, cat), temper)
    return name, site, seed, model.run(years)["rows"]


# ------------------------------------------------------------------ the report
OUTCOMES = [  # key, label, higher is better
    ("population", "People", True),
    ("food_days", "Days of food in store", True),
    ("life_expectancy", "Life expectancy", True),
    ("known", "Discoveries", True),
    ("works", "Great works standing", True),
    ("might_ratio", "Might (fighting strength ratio)", True),
    ("towns", "Towns", True),
    ("cap_production", "Production capacity", True),
    ("cap_culture", "Culture capacity", True),
    ("hunger_rate", "Hunger deaths /1000 person-years", False),
    ("raid_rate", "Killed by raiders /1000 person-years", False),
    ("settlers_per_town", "Settlers lost per town founded", False),
    ("follies", "Follies (works fallen)", False),
]


def summarize(rows_by_seed: list, year: int) -> dict:
    """Mean over seeds at `year`. Deaths are rates over the person-years lived so
    far (a larger people is not charged for being larger); settler losses are
    per town founded."""
    vals: dict = {}
    for rows in rows_by_seed:
        upto = [r for r in rows if r["year"] <= year + 1e-6]
        at = upto[-1]
        lived = max(1.0, sum(float(r["population"]) for r in upto))
        derived = {"hunger_rate": at["hunger_deaths"] / lived * 1000.0, "raid_rate": at["raid_deaths"] / lived * 1000.0,
                   "settlers_per_town": at["settler_deaths"] / max(1, at["towns"] - 1),
                   "cap_production": at["capacities"]["production"], "cap_culture": at["capacities"]["culture"]}
        for key, _label, _up in OUTCOMES:
            vals.setdefault(key, []).append(float(derived[key] if key in derived else at[key]))
    return {key: float(np.mean(v)) for key, v in vals.items()}


def dominance(table: dict, outcomes: list, eps: float = .03) -> list:
    """Pairs (a, b) where a is at least as good as b on every outcome and better on one."""
    out = []
    for a in table:
        for b in table:
            if a == b:
                continue
            better = worse = 0
            for key, _label, up in outcomes:
                x, y = table[a][key], table[b][key]
                diff = (x - y) if up else (y - x)
                scale = max(abs(x), abs(y), 1.0 if not up else 1e-6)
                if diff > eps * scale:
                    better += 1
                elif diff < -eps * scale:
                    worse += 1
            if worse == 0 and better > 0:
                out.append([a, b])
    return out


def ranks(table: dict, outcomes: list) -> dict:
    """Each temper's best (first) and worst (last) outcomes."""
    out = {}
    for name in table:
        best, worst = [], []
        for key, label, up in outcomes:
            vals = {n: table[n][key] for n in table}
            order = sorted(vals, key=lambda n: vals[n], reverse=up)
            if abs(vals[order[0]] - vals[order[-1]]) <= 1e-9:
                continue
            if abs(vals[name] - vals[order[0]]) <= 1e-9:
                best.append(label)
            if abs(vals[name] - vals[order[-1]]) <= 1e-9:
                worst.append(label)
        out[name] = {"best": best, "worst": worst}
    return out


def print_table(title: str, table: dict, outcomes: list, width: int = 21) -> None:
    names = list(table)
    print(title)
    print(f"  {'outcome':38s}" + "".join(f"{n[:width - 2]:>{width}s}" for n in names))
    for key, label, up in outcomes:
        vals = [table[n][key] for n in names]
        hi, lo = (max(vals), min(vals)) if up else (min(vals), max(vals))
        cells = [f"{v:>{width - 2},.{2 if max(abs(x) for x in vals) < 10 else 1}f}{' +' if v == hi and hi != lo else ' -' if v == lo and hi != lo else '  '}" for v in vals]
        print(f"  {label:38s}" + "".join(cells))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", type=int, default=2)
    ap.add_argument("--years", type=int, default=600)
    ap.add_argument("--site", default="both", choices=["good", "poor", "both"])
    ap.add_argument("--ambitions", action="store_true",
                    help="one temper per ambition (a temper that takes it up) instead of the five archetypes")
    ap.add_argument("--shocks", action="store_true", help="opt-in: live through the epochal-shock world (shock_world.py)")
    ap.add_argument("--jobs", type=int, default=10)
    ap.add_argument("--json", type=Path, default=None)
    args = ap.parse_args()
    t0 = time.time()
    tempers = {a: temper_choosing(a) for a in TEMPER} if args.ambitions else dict(ARCHETYPES)
    sites = ["good", "poor"] if args.site == "both" else [args.site]
    jobs = [(name, temper, s, args.years, site, args.shocks)
            for site in sites for name, temper in tempers.items() for s in range(1, args.seeds + 1)]
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        results = list(pool.map(run_one, jobs))
    rows: dict = {}
    for name, site, _seed, r in results:
        rows.setdefault((site, name), []).append(r)
    print(f"leader tempers: {len(tempers)} x {args.seeds} seeds x {args.years} years on the {' and '.join(sites)} site"
          f"{'s' if len(sites) > 1 else ''}{' + shocks' if args.shocks else ''}  ({time.time() - t0:.0f}s)\n")
    for name, p in tempers.items():
        first, later = choose_ambition(p, 0), choose_ambition(p, 1)
        x = expansion_plan(p, culture_drive({later: 1.0}))
        print(f"  {name:20s} path {work_path(p)}; ambition {first}{' then ' + later if later != first else ''}: settles at {x['food']:.0f} days in store, "
              f"looks every {x['months']} mo, settlers carry {x['margin']:.0f} d; "
              f"reserve x{1 + clamp(float(WORK[later].get('Food', 0)) / RESERVE_FOOD_WISH, 0, 1):.1f}; "
              f"a work at most every {wonder_interval_days(p) / 365:.1f} y")
    report = {"years": args.years, "seeds": args.seeds, "sites": sites, "shocks": args.shocks, "tempers": tempers, "results": {}}
    for year in sorted({min(300, args.years), args.years}):
        combined: dict = {name: {} for name in tempers}
        combined_outcomes = []
        for site in sites:
            table = {name: summarize(rows[(site, name)], year) for name in tempers}
            dom, rk = dominance(table, OUTCOMES), ranks(table, OUTCOMES)
            report["results"][f"{site}@{year}"] = {"outcomes": table, "dominated_pairs": dom, "ranks": rk}
            print_table(f"\n{site} site, year {year}", table, OUTCOMES, 21 if len(tempers) <= 6 else 13)
            print("  dominated pairs (first at least as good everywhere):", dom if dom else "none")
            for name in tempers:
                print(f"  {name:20s} best: {', '.join(rk[name]['best']) or '-'}")
                print(f"  {'':20s} worst: {', '.join(rk[name]['worst']) or '-'}")
            for key, label, up in OUTCOMES:
                combined_outcomes.append((f"{key}@{site}", f"{label} ({site})", up))
                for name in tempers:
                    combined[name][f"{key}@{site}"] = table[name][key]
        if len(sites) > 1:
            dom = dominance(combined, combined_outcomes)
            report["results"][f"both@{year}"] = {"dominated_pairs": dom}
            print(f"\n  year {year}, both sites together: dominated pairs:", dom if dom else "none")
    if args.json:
        args.json.write_text(json.dumps(report, indent=1, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
