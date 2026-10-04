"""The built fabric in the fast sim: a mirror of scripts/built_fabric.gd (homes by
grade, roads, fine works, work buildings, the builders' craft), of the defence
ledger's stages as the people's council raises them (military_campaign.gd
SETTLEMENT_DEFENSE_STAGES, civilization_controller.gd defense_decision), and a
standard great-works policy every path runs alike (wonder_concept.gd assess and
odds, undertaking_system.gd advance_record and apply_outcome).

Every constant is read from the game. When scripts/built_fabric.gd is absent
(SIM_GAME_REV=<an older main>) the fabric is off and only the great works run,
with the engine's odds as they were, so a main -> branch table is like for like.

Surrogate stand-ins (not engine numbers):
* one raw-materials pool stands for timber, clay, stone and fibre (the engine
  keeps each); the fabric draws only what lies above FABRIC_RESERVE loads a head;
* the civic works and new homes are not objects: builders are halved for the
  fabric while the homes lag the people (the surrogate's housing target);
* the council's danger is the neighbours' alone (0.2 once other peoples are
  known, contact_year); there are no raids or sieges;
* great works: one grand work at a time, started every WORK_INTERVAL years when
  fed and stores hold 30 days; its crew is a fifth of the builders, its bill the
  engine's 0.07 loads a unit of work, its form a stone ring of the people's tier.
"""
from __future__ import annotations

import math

import gdparse as g

BF = "scripts/built_fabric.gd"
ON = g.game_file_exists(BF)


def _c(name, default):
    return g.const(BF, name, default=default, optional=True) if ON else default


GRADES = _c("GRADES", ["lean_to"])
GRADE_Q = [float(x) for x in _c("GRADE_Q", [0.0])]
GRADE_BUILD = [float(x) for x in _c("GRADE_BUILD", [0.0])]
GRADE_MATERIALS = _c("GRADE_MATERIALS", [{}])
GRADE_UPKEEP = [float(x) for x in _c("GRADE_UPKEEP", [0.0])]
GRADE_WEAR = [float(x) for x in _c("GRADE_WEAR", [0.0])]
GRADE_KNOW = _c("GRADE_KNOW", [[]])
GRADE_CRAFT = [float(x) for x in _c("GRADE_CRAFT", [0.0])]
GRADE_CRAFT_FULL = [float(x) for x in _c("GRADE_CRAFT_FULL", [0.0])]
K = {k: float(_c(k, 0.0)) for k in (
    "TICK_DAYS", "HOME_HEALTH", "HOME_COHESION", "HOME_ILLNESS", "HOME_SICKNESS", "HOME_FIRE",
    "ROAD_FULL", "ROAD_WEAR", "ROAD_STONE", "ROAD_LOGISTICS", "HOME_WEATHER", "HOMES_AHEAD", "HOMES_SHORT", "CIVIC_SHARE", "REPAIR_SHARE", "WALL_UPKEEP", "WALL_WEAR", "GREAT_CREW_SHARE", "BEAUTY_SCALE", "BEAUTY_WEAR", "ARTISTRY_EACH", "BEAUTY_MATERIALS",
    "BEAUTY_COHESION", "BEAUTY_CULTURE", "WORKS_FULL", "WORKS_WEAR", "WORKSHOP_MAKING", "GRANARY_ROT",
    "KILN_BUILDING", "STOREHOUSE_LOGISTICS", "STOREHOUSE_EXTRACTION", "WALL_SHARE", "CRAFT_YEARS", "CRAFT_PER_LEVEL", "CRAFT_MAX", "CRAFT_WORK",
    "CRAFT_RESEARCH", "CRAFT_SIGNAL", "CRAFT_WALLS", "CRAFT_WALL_QUALITY", "STONE_DEFENSE", "BUILDER_WALL_WEIGHT", "STONE_STAGE",
    "STONE_WATCH", "FORT_STRENGTH", "BASTION_BONUS", "WALL_WISH", "WALL_WISH_FROM", "WALL_WISH_MAX", "GREAT_CRAFT", "GREAT_BUILDERS",
    "GREAT_CREW", "GREAT_MATERIALS", "GREAT_PAYOFF", "RESERVE")}
ROAD_KINDS = _c("ROAD_KINDS", [["", 0.0]])
ARTISTRY = _c("ARTISTRY", [])
WORKS_LOADS = float(_c("WORKS_LOADS", 0.25))
WORKS_KNOW = _c("WORKS_KNOW", {})
SPLIT = _c("SPLIT", {})
UPKEEP_ORDER = _c("UPKEEP_ORDER", ["homes", "walls", "works", "roads", "beauty"])
FABRIC_RESERVE = 3.0     # loads a head of the one raw pool held back (four materials at RESERVE each, about)

MC = "scripts/military_campaign.gd"
STAGES = g.const(MC, "SETTLEMENT_DEFENSE_STAGES", default=[], optional=True) or []
DAILY_SHARE = float(g.const(MC, "DEFENSE_DAILY_SHARE", default=0.04, optional=True))
WORK_PER_HAND = float(g.const(MC, "DEFENSE_WORK_PER_HAND", default=0.38, optional=True))
CC = "scripts/civilization_controller.gd"
STAGE_NEED = g.const(CC, "DEFENSE_STAGE_NEED", default=[0.0, .2, .35, .5, .65, .8], optional=True)
SPARE = float(g.const(CC, "DEFENSE_SPARE", default=2.0, optional=True))
DEFENSE_FOOD_DAYS = float(g.const(CC, "DEFENSE_FOOD_DAYS", default=15.0, optional=True))
DEFENSE_MAX_DAYS = float(g.const(CC, "DEFENSE_MAX_DAYS", default=1095.0, optional=True))
DANGER = g.const(CC, "DEFENSE_DANGER", default={"neighbours": .2}, optional=True)

WC = "scripts/wonder_concept.gd"
AMBITION_WORK = g.const(WC, "AMBITION_WORK", default={"grand": 1.0}, optional=True)
AMBITION_DEMAND = g.const(WC, "AMBITION_DEMAND", default={"grand": .65}, optional=True)
AMBITION_RISK = g.const(WC, "AMBITION_RISK", default={"grand": 1.0}, optional=True)
AMBITION_PAY = g.const(WC, "AMBITION_PAY", default={"grand": 1.0}, optional=True)
AMBITION_TRIUMPH = g.const(WC, "AMBITION_TRIUMPH", default={"grand": 1.0}, optional=True)
OUTCOME_PAY = g.const(WC, "OUTCOME_PAY", default={"triumph": 1.35, "success": 1.0, "flawed": .5}, optional=True)
TIER_MARKERS = g.const(WC, "TIER_MARKERS", default=[], optional=True) or []
RING_WORK = 4000.0           # wonder_concept.gd FORMS ring (no knowledge needed), stone
STONE_QUALITY = 0.8
TALENT = 0.72                # an ordinary master builder (assess's default)
WORK_INTERVAL = 15.0         # years between works under the standard policy
WORK_FOOD_DAYS = 30.0
WORK_RISK = 0.12             # the most risk of collapse the standard policy accepts
RENOWN_SCALE = float(g.const("scripts/great_works.gd", "RENOWN_SCALE", default=30.0, optional=True))
WORKS_CAP = float(g.const("scripts/artifact_culture.gd", "ALLURE_WORKS", default=.25, optional=True))
ST = "scripts/standing.gd"
import standing as standing_mirror  # noqa: E402  standing.gd against the age


def clamp(x, lo, hi):
    return lo if x < lo else hi if x > hi else x


class Fabric:
    """One people's fabric (one aggregate town), its craft, walls and great works."""

    def __init__(self, sim):
        self.sim = sim
        self.homes = [1.0] + [0.0] * (len(GRADES) - 1)
        self.roads = 0.0
        self.beauty = 0.0
        self.works = 0.0
        self.xp = 0.0
        self.paid = 1.0
        self.spent = {}
        self.quality = 0.0
        self.road = 0.0
        self.beauty_r = 0.0
        self.cover = 0.0
        self.stone = 0.0
        self.craft = 0.0
        self.next_tick = 0.0
        # Defence ledger.
        self.stage = 0
        self.project = -1
        self.project_work = 0.0
        self.next_council = 0.0
        self.wall_builders = 0.0
        # Great works.
        self.work = None
        self.last_started = -1e9
        self.works_done = self.triumphs = self.follies = 0
        self.works_points = 0.0
        self.payoffs = []
        self.ambitions = {}
        import numpy as np
        self.rng = np.random.default_rng((int(getattr(sim, "seed", 1)) * 2654435761 + 97) & 0xFFFFFFFF)

    # ------------------------------------------------------------------ knowledge
    def knows(self, ids) -> bool:
        if not ids:
            return True
        s = self.sim
        for rid in ids:
            i = s.cat.index.get(rid)
            if i is not None and s.known[i]:
                return True
        return False

    def caps(self) -> list:
        out = [1.0] + [0.0] * (len(GRADES) - 1)
        for gi in range(1, len(GRADES)):
            if not self.knows(GRADE_KNOW[gi]):
                break
            span = max(0.01, GRADE_CRAFT_FULL[gi] - GRADE_CRAFT[gi])
            out[gi] = min(out[gi - 1], clamp((self.craft - GRADE_CRAFT[gi]) / span, 0.0, 1.0))
        return out

    def road_cap(self) -> float:
        cap = float(ROAD_KINDS[0][1])
        kind = 0
        for k in range(1, len(ROAD_KINDS)):
            ids = ROAD_KINDS[k][0]
            if self.knows(ids if isinstance(ids, list) else [ids]):
                cap, kind = float(ROAD_KINDS[k][1]), k
        self.road_kind = kind
        return cap

    def artistry(self) -> float:
        return 1.0 + K["ARTISTRY_EACH"] * sum(1 for rid in ARTISTRY if self.knows([rid]))

    def works_on(self, kind: str) -> float:
        need = str(WORKS_KNOW.get(kind, ""))
        return 0.0 if need and not self.knows([need]) else self.cover

    # --------------------------------------------------------------------- month
    def step(self, days: float) -> None:
        """A month: the walls and the great work every month; the fabric's
        reckoning every TICK_DAYS (here, once a month for its days)."""
        s = self.sim
        if not ON:
            # The engine before the fabric: the watch alone raises the walls.
            self._walls(days, clamp(float(getattr(s, "labor_eff", 0.9)), 0.2, 1.2))
            self._great_works(days)
            return
        labor = clamp(float(getattr(s, "labor_eff", 0.9)), 0.2, 1.2)
        builders_all = s.able * s.alloc_pct["Construction"] / 100.0
        crew_share = float(getattr(s, "construction_diverted", 0.0))
        pop = max(1.0, s.population)
        # Craft: experience fades e-fold over CRAFT_YEARS.
        self.xp = self.xp * math.exp(-days / (K["CRAFT_YEARS"] * 365.0)) + builders_all * labor * days
        self.craft = clamp(self.xp / pop / K["CRAFT_PER_LEVEL"], 0.0, K["CRAFT_MAX"])
        # built_fabric.gd crews: homes, the civic works, repair, the walls, then the fabric.
        crews = self.crews(builders_all * (1.0 - crew_share), pop)
        self.wall_builders = crews["walls"]
        self.wall_ready = crews["walls_ready"]
        builders = crews["fabric"]
        budget = builders * labor * days * (1.0 + K["CRAFT_WORK"] * self.craft) * (1.0 + K["KILN_BUILDING"] * self.works_on("kilns"))
        self._reckon(budget, days, pop)
        self._walls(days, labor)
        self._great_works(days)

    def crews(self, builders: float, pop: float) -> dict:
        """built_fabric.gd crews. The surrogate's homes go up while the places lag
        the people (housing_target_ratio stands in for the engine's 80% trigger);
        its civic works are the founding works; its town is in full repair; it
        has no water channels, waste works or railways (no works crew)."""
        s = self.sim
        if not ON:
            return {"homes": builders, "fabric": 0.0, "walls": 0.0, "walls_ready": 0.0}
        short = s.housing_capacity < pop
        ahead = s.housing_capacity < pop * float(s.p["housing_target_ratio"])
        homes = builders * K["HOMES_SHORT"] if short else builders * K["HOMES_AHEAD"] if ahead else 0.0
        rest = builders - homes
        civic = rest * K["CIVIC_SHARE"] if s.completed < float(s.p["founding_works"]) else 0.0
        rest -= civic
        repair = min(rest, pop * K["REPAIR_SHARE"] * 0.5)
        rest -= repair
        ready = rest * K["WALL_SHARE"]
        walls = ready if self.project >= 0 else 0.0
        rest -= walls
        return {"homes": homes, "civic": civic, "repair": repair, "walls": walls, "walls_ready": ready, "fabric": max(0.0, rest)}

    def _reckon(self, budget: float, days: float, pop: float) -> None:
        s = self.sim
        years = days / 365.0
        places = max(1.0, s.housing_capacity)
        bills = self.work["bill"] * (1.0 - self.work["progress"] / self.work["total"]) if self.work is not None else 0.0
        raw_spare = max(0.0, s.raw - FABRIC_RESERVE * pop - bills)
        avail = [raw_spare]
        homes = self.homes
        home_need = sum(homes[gi] * places * GRADE_UPKEEP[gi] * years for gi in range(len(GRADES)))
        walls_need = float(STAGES[self.stage]["work"]) * K["WALL_UPKEEP"] * years if STAGES and self.stage > 0 else 0.0
        wants = {"homes": home_need, "walls": walls_need, "works": self.works * K["WORKS_WEAR"] * years, "roads": self.roads * K["ROAD_WEAR"] * years,
                 "beauty": self.beauty * K["BEAUTY_WEAR"] * years / max(1.0, self.artistry())}
        need = sum(wants.values())
        kept, upkeep = {}, 0.0
        for key in UPKEEP_ORDER:
            pay = min(budget, wants[key])
            budget -= pay
            upkeep += pay
            kept[key] = clamp(pay / wants[key], 0.0, 1.0) if wants[key] > 0.0 else 1.0
        need += walls_need
        self.paid = clamp(upkeep / need, 0.0, 1.0) if need > 0.0 else 1.0
        self.walls_kept = kept.get("walls", 1.0)
        for gi in range(len(GRADES) - 1, 0, -1):
            fall = homes[gi] * min(1.0, GRADE_WEAR[gi] * years * (1.0 - kept["homes"]))
            homes[gi] -= fall
            homes[gi - 1] += fall
        self.roads *= 1.0 - min(1.0, K["ROAD_WEAR"] * years * (1.0 - kept["roads"]))
        self.works *= 1.0 - min(1.0, K["WORKS_WEAR"] * years * (1.0 - kept["works"]))
        self.beauty *= 1.0 - min(1.0, K["BEAUTY_WEAR"] * years * (1.0 - kept["beauty"]))
        spent = {"upkeep": upkeep, "homes": 0.0, "roads": 0.0, "works": 0.0, "beauty": 0.0}
        shares = dict(SPLIT)
        caps = self.caps()
        road_cap = self.road_cap()
        for _ in range(3):
            if budget <= 0.001:
                break
            total = sum(shares.values())
            if total <= 0.0:
                break
            left = 0.0
            for key in list(shares.keys()):
                offer = budget * shares[key] / total
                if key == "homes":
                    used = self._raise_homes(offer, places, caps, avail)
                elif key == "roads":
                    room = max(0.0, road_cap * K["ROAD_FULL"] * pop - self.roads)
                    used = min(offer, room)
                    if self.road_kind > 0:
                        used = min(used, avail[0] / max(1e-9, K["ROAD_STONE"]))
                        avail[0] -= used * K["ROAD_STONE"]
                    self.roads += used
                elif key == "works":
                    room = max(0.0, K["WORKS_FULL"] * pop - self.works)
                    per = WORKS_LOADS
                    used = min(offer, room, avail[0] / max(1e-9, per))
                    avail[0] -= used * per
                    self.works += used
                else:
                    used = min(offer, avail[0] / max(1e-9, K["BEAUTY_MATERIALS"]))
                    avail[0] -= used * K["BEAUTY_MATERIALS"]
                    self.beauty += used * self.artistry()
                spent[key] += used
                left += offer - used
                if used < offer * 0.999 and key != "beauty":
                    shares.pop(key)
            budget = left
        s.raw = max(0.0, s.raw - (raw_spare - avail[0]))
        self.spent = spent
        self.idle = budget
        self.quality = sum(homes[gi] * GRADE_Q[gi] for gi in range(len(GRADES)))
        self.road = clamp(self.roads / (K["ROAD_FULL"] * pop), 0.0, road_cap)
        self.beauty_r = 1.0 - math.exp(-self.beauty / pop / max(1e-9, K["BEAUTY_SCALE"]))
        self.cover = clamp(self.works / (K["WORKS_FULL"] * pop), 0.0, 1.0)
        self.stone = homes[-1]

    def _raise_homes(self, offer: float, places: float, caps: list, avail: list) -> float:
        homes = self.homes
        used = 0.0
        for gi in range(1, len(GRADES)):
            above = sum(homes[gi:])
            move = min(max(0.0, caps[gi] - above), homes[gi - 1])
            if move <= 0.0:
                continue
            cost = GRADE_BUILD[gi]
            per = sum(float(v) for v in GRADE_MATERIALS[gi].values())
            move = min(move, (offer - used) / max(0.001, cost * places), avail[0] / max(1e-9, per * places) if per > 0 else math.inf)
            if move <= 0.0:
                continue
            homes[gi - 1] -= move
            homes[gi] += move
            avail[0] -= move * places * per
            used += move * places * cost
            if used >= offer * 0.999:
                break
        return used

    def follow_places(self, before: float, now: float) -> None:
        """New places come at the plainest grade the people build; lost ones go from every grade."""
        if ON and now > before > 0.0:
            base = 1 if self.caps()[1] >= 0.5 else 0
            self.homes = [h * before / now for h in self.homes]
            self.homes[base] += (now - before) / now

    # -------------------------------------------------------------------- effects
    def weather(self, cold: float) -> float:
        """built_fabric.gd weather_bonus (the surrogate's sites have cold, no heat)."""
        return K["HOME_WEATHER"] * clamp(cold, 0.0, 2.0) * self.quality

    def making(self) -> float:
        return 1.0 + K["WORKSHOP_MAKING"] * self.works_on("workshops")

    def extraction(self) -> float:
        return 1.0 + K["STOREHOUSE_EXTRACTION"] * self.works_on("storehouses")

    def granary(self) -> float:
        return 1.0 - K["GRANARY_ROT"] * self.works_on("granaries")

    def research(self, line: str) -> float:
        return 1.0 + K["CRAFT_RESEARCH"] * self.craft if line == "infrastructure" else 1.0

    def signal(self) -> float:
        return 1.0 + K["CRAFT_SIGNAL"] * self.craft

    def defense_bonus(self) -> float:
        bonus = float(STAGES[self.stage]["defense_bonus"]) if STAGES else 0.0
        if not ON:
            return bonus
        return bonus * (1.0 + K["CRAFT_WALL_QUALITY"] * self.craft) + K["STONE_DEFENSE"] * self.stone

    # ---------------------------------------------------------------------- walls
    def _walls(self, days: float, labor: float) -> None:
        """settlement_defense: the project's daily work by the watch and the builders
        on the walls; the people's council each month (civilization_controller.gd
        defense_decision)."""
        s = self.sim
        if not STAGES:
            return
        watch = s.watch() if hasattr(s, "drill") else 0.0
        if self.project >= 0:
            stage = STAGES[self.project]
            hands = watch * (K["STONE_WATCH"] if ON and self.project >= K["STONE_STAGE"] else 1.0) + self.wall_builders * K["BUILDER_WALL_WEIGHT"] * (1.0 + K["CRAFT_WALLS"] * self.craft)
            daily = min(float(stage["work"]) * DAILY_SHARE, hands * clamp(labor, 0.15, 1.25) * WORK_PER_HAND)
            self.project_work += daily * days
            if self.project_work >= float(stage["work"]):
                self.stage, self.project, self.project_work = self.project, -1, 0.0
            return
        if s.day < self.next_council:
            return
        self.next_council = s.day + 30.0
        nxt = self.stage + 1
        if nxt >= len(STAGES):
            return
        year = s.day / 365.0
        danger = float(DANGER.get("neighbours", .2)) if year >= float(s.p.get("contact_year", 40.0)) else 0.0
        weighed = danger * (.6 + .8 * 0.5) + (clamp(K["WALL_WISH"] * (self.craft - K["WALL_WISH_FROM"]), 0.0, K["WALL_WISH_MAX"]) if ON else 0.0)
        if weighed < float(STAGE_NEED[nxt]) or s.stored_days < DEFENSE_FOOD_DAYS or s.last.get("intake", 1.0) < 0.995:
            return
        stage = STAGES[nxt]
        bill = sum(float(v) for v in (stage.get("materials") or {}).values())
        if s.raw < bill * SPARE:
            return
        hands = watch * (K["STONE_WATCH"] if ON and nxt >= K["STONE_STAGE"] else 1.0) + (getattr(self, "wall_ready", 0.0) * K["BUILDER_WALL_WEIGHT"] * (1.0 + K["CRAFT_WALLS"] * self.craft) if ON else 0.0)
        daily = min(float(stage["work"]) * DAILY_SHARE, hands * clamp(float(getattr(s, "labor_eff", 0.9)), 0.15, 1.25) * WORK_PER_HAND)
        if daily <= 0.0 or float(stage["work"]) / daily > DEFENSE_MAX_DAYS:
            return
        s.raw -= bill
        self.project, self.project_work = nxt, 0.0

    # ----------------------------------------------------------------- great works
    def tier(self) -> int:
        t = 0
        for level, ids in TIER_MARKERS:
            if self.knows(ids):
                t = max(t, int(level))
        return t

    def _great_works(self, days: float) -> None:
        s = self.sim
        year = s.day / 365.0
        if self.work is None:
            s.construction_diverted = 0.0
            if s.completed < 1.0 or s.last.get("intake", 1.0) < .98 or s.stored_days < WORK_FOOD_DAYS or year - self.last_started < WORK_INTERVAL or year < 10.0:
                return
            t = self.tier()
            # The most ambitious work the builders give good odds (collapse at
            # most WORK_RISK at today's assessment).
            chosen = "modest"
            for ambition in ("audacious", "grand", "modest"):
                total = RING_WORK * float(AMBITION_WORK[ambition]) * (1.0 + t * .5)
                if self._odds(ambition, t, total * .07, 0.75)["collapse"] <= WORK_RISK:
                    chosen = ambition
                    break
            total = RING_WORK * float(AMBITION_WORK[chosen]) * (1.0 + t * .5)
            self.work = {"total": total, "progress": 0.0, "quality": 0.0, "tier": t, "bill": total * .07, "ambition": chosen}
            self.last_started = year
            return
        w = self.work
        s.construction_diverted = .20
        builders = s.able * s.alloc_pct["Construction"] / 100.0
        crew = builders * .20
        crafters = s.able * s.alloc_pct["Crafting"] / 100.0
        quality = clamp(float(getattr(s, "labor_eff", .72)) * .4 + s.cohesion * .2 + min(1.0, crafters / 8.0) * .2 + .5 * .2, .1, 1.0)
        work = crew * quality * days
        if s.last.get("intake", 1.0) < .95:
            work = 0.0
        per = w["bill"] / w["total"]
        work = min(work, max(0.0, s.raw) / max(1e-9, per), w["total"] - w["progress"])
        s.raw -= work * per
        w["progress"] += work
        w["quality"] += work * quality
        if w["progress"] + 1e-6 < w["total"]:
            return
        # Completion: wonder_concept.gd assess (a stone ring) and odds.
        t = w["tier"]
        ambition = w["ambition"]
        o = self._odds(ambition, t, w["bill"], clamp(w["quality"] / w["total"], 0.0, 1.0))
        collapse, flawed, triumph, score = o["collapse"], o["flawed"], o["triumph"], o["score"]
        risk = float(AMBITION_RISK[ambition])
        roll = float(self.rng.random())
        self.last_odds = o
        self.work = None
        s.construction_diverted = 0.0
        if roll < collapse:
            self.follies += 1
            s.cohesion = clamp(s.cohesion - .04 * risk, .01, .99)
            s.legitimacy = clamp(s.legitimacy - .05 * risk, .01, .99)
            return
        outcome = "flawed" if roll < collapse + flawed else "triumph" if roll < collapse + flawed + triumph else "success"
        payoff = 1.0 + K["GREAT_PAYOFF"] * self.craft if ON else 1.0
        self.payoffs.append(payoff)
        self.works_done += 1
        self.triumphs += outcome == "triumph"
        fame = {"triumph": 1.25, "success": 1.0, "flawed": .75}[outcome]
        self.works_points += 6.0 * float(AMBITION_PAY[ambition]) * (1.0 + t * .4) * fame * payoff
        self.ambitions[ambition] = self.ambitions.get(ambition, 0) + 1
        s.cohesion = clamp(s.cohesion + {"triumph": .03, "success": .015}.get(outcome, 0.0), .01, .99)
        if outcome == "triumph":
            s.legitimacy = clamp(s.legitimacy + .02, .01, .99)

    def _odds(self, ambition: str, t: int, bill: float, workmanship: float) -> dict:
        """wonder_concept.gd assess (engineering x 0.6 + the people x 0.4, the
        crews' workmanship on the day) and odds, for a stone ring."""
        s = self.sim
        builders = s.able * s.alloc_pct["Construction"] / 100.0
        crafters = s.able * s.alloc_pct["Crafting"] / 100.0
        capability = .35 + .08 * t + .10 * STONE_QUALITY + .10 * TALENT + .08 * min(1.0, crafters / 10.0) + .05 * min(1.0, builders / 20.0)
        if ON:
            cover = clamp(s.raw / max(1.0, bill), 0.0, 1.0)
            capability += K["GREAT_CRAFT"] * self.craft + K["GREAT_BUILDERS"] * clamp(builders * K["GREAT_CREW_SHARE"] / K["GREAT_CREW"], 0.0, 1.0) + K["GREAT_MATERIALS"] * (cover - 0.5)
        engineering = clamp(.5 + (capability - float(AMBITION_DEMAND[ambition])) * 1.4, 0.0, 1.0)
        social = s.cohesion * .35 + s.legitimacy * .25 + clamp(s.last.get("intake", 1.0), 0.0, 1.0) * .25 + .15
        score = clamp(engineering * .6 + social * .4, .02, .98)
        score = clamp(score + (workmanship - .75) * .3, .02, .98)
        risk = float(AMBITION_RISK[ambition])
        collapse = clamp((1.0 - score) ** 1.6 * .9 * risk, 0.0, .9)
        flawed = clamp((1.0 - score) * .45 * math.sqrt(risk), 0.0, 1.0 - collapse)
        triumph = clamp(score * score * .25 * float(AMBITION_TRIUMPH[ambition]), 0.0, 1.0 - collapse - flawed)
        return {"score": score, "collapse": collapse, "flawed": flawed, "triumph": triumph, "capability": capability}

    # ------------------------------------------------------------------ readings
    def readings(self) -> dict:
        """standing.gd strengths against the age and renown, as far as one people
        alone can be read (standing.py): might (the watch at the ready, the
        walls), splendor (great works, culture, fine works), awe, allure, pride."""
        s = self.sim
        pop = max(1.0, s.population)
        walls = clamp(self.defense_bonus() / max(1e-9, K["BASTION_BONUS"] or 0.62), 0.0, 1.0)
        row = {"year": s.day / 365.0, "population": pop, "watch": s.watch() if hasattr(s, "drill") else 0.0, "drill": getattr(s, "drill", 0.0),
               "defense_bonus": self.defense_bonus() if ON else 0.0, "works_points": self.works_points, "beauty": self.beauty_r if ON else 0.0,
               "artifacts": {"allure": float(getattr(s, "allure", 0.0))}, "known": int(s.known.sum()), "knowledge_workers": s.workers("Knowledge"),
               "food_days": s.stored_days, "raw": getattr(s, "raw", 0.0), "goods_per_head": max(0.0, getattr(s, "goods", 0.0)) / pop,
               "health": s.health, "cohesion": s.cohesion, "legitimacy": s.legitimacy, "logistics": s.logistics, "alloc": dict(s.alloc_pct), "able": s.able}
        r = standing_mirror.readings(row, getattr(s.s, "posture", {}) or {})
        command = standing_mirror.renown(r)
        return {"might_strength": r["might"], "splendor": r["splendor"], "awe": command["awe"], "allure_view": command["allure"], "pride": command["pride"],
                "walls": walls, "defense_bonus": self.defense_bonus(), "stage": self.stage}

    def snapshot(self) -> dict:
        row = {"homes": list(self.homes), "home_quality": self.quality, "roads": self.road, "beauty": self.beauty_r, "works_cover": self.cover,
               "stone_share": self.stone, "craft": self.craft, "fabric_paid": self.paid, "great_works": self.works_done, "triumphs": self.triumphs,
               "follies": self.follies, "works_points": self.works_points, "audacious": self.ambitions.get("audacious", 0), "work_odds": dict(getattr(self, "last_odds", {}))}
        row.update(self.readings())
        return row
