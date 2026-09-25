"""Surrogate of Tomorrow and Tomorrow's civilization engine for fast balancing.

One aggregate society, stepped monthly (research, adoption, effects, capacities,
artifacts) with ``substeps_per_month`` demography/food sub-steps using the
engine's daily rates. Every formula names its GDScript source; numeric
constants are parsed from the game where feasible (gamedata.py / gdparse.py),
and the rest live in params.json.

What it deliberately omits (see docs/research/SURROGATE_SIM.md): individual
people and officials, geography/terrain, rivals and diplomacy, war, trade and
the money economy, construction projects and buildings as objects (buildings are
a count), per-resource stockpiles, water logistics, policies other than the
scenario knobs, the civic court and decrees.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np

import gamedata as gd
import gdparse as g

YEAR = 365.0
MONTH = YEAR / 12.0
ROLES = ["Food", "Survey", "Extraction", "Construction", "Crafting", "Logistics", "Knowledge", "Administration", "Defense"]
R = {r: i for i, r in enumerate(ROLES)}
COH = ["children", "youth", "early_adults", "established_adults", "mature_adults", "elders"]
# Death weights by cause (game_state.gd _mortality_weights_for).
_W = g.literal_after("scripts/game_state.gd", '"Hunger": return', default={"children": 2.2, "youth": 0.8, "early_adults": 0.7, "established_adults": 0.8, "mature_adults": 1.2, "elders": 2.0})
HUNGER_W = np.array([_W[k] for k in COH])
_W = g.literal_after("scripts/game_state.gd", '"Illness","Dehydration","Exposure": return', default={"children": 1.8, "youth": 0.7, "early_adults": 0.7, "established_adults": 0.9, "mature_adults": 1.4, "elders": 2.6})
ILL_W = np.array([_W[k] for k in COH])
_W = g.literal_after("scripts/game_state.gd", '"Insecurity","Killed in battle": return', default={"children": 0.2, "youth": 1.2, "early_adults": 1.8, "established_adults": 1.7, "mature_adults": 1.1, "elders": 0.3})
INSEC_W = np.array([_W[k] for k in COH])
_W = g.literal_after("scripts/game_state.gd", '"Complications of childbirth": return', default={"children": 0.0, "youth": 1.2, "early_adults": 2.0, "established_adults": 1.5, "mature_adults": 0.4, "elders": 0.0})
MATERNAL_W = np.array([_W[k] for k in COH])
BASE_ALLOC = g.const("scripts/government_people_system.gd", "BASE_ALLOCATIONS",
                     default={"Food": 42.0, "Survey": 8.0, "Extraction": 11.0, "Construction": 11.0, "Crafting": 7.0, "Logistics": 7.0, "Knowledge": 6.0, "Administration": 4.0, "Defense": 4.0})
FOCUS_CHANGES = g.literal_after("scripts/government_people_system.gd", "var changes:Dictionary=(", default={})
LABOR_EXTRAS = g.literal_after("scripts/food_system.gd", "var extras:=", default={"Food": 0.17, "Extraction": 0.18, "Construction": 0.18, "Defense": 0.12, "Survey": 0.13, "Logistics": 0.14, "Crafting": 0.08, "Knowledge": 0.04, "Administration": 0.04})
# Optional Phase 3 pre-modern burden (early_life_conditions.gd); absent -> 1.
ERA_BURDEN = g.const("scripts/early_life_conditions.gd", "ERA_BURDEN", default={}, optional=True)
EXCESS_WEIGHT = g.const("scripts/early_life_conditions.gd", "EXCESS_WEIGHT", default={}, optional=True)
RELIEF_CHANNELS = g.const("scripts/early_life_conditions.gd", "RELIEF_CHANNELS", default={}, optional=True)
RELIEF_POWER = float(g.const("scripts/early_life_conditions.gd", "RELIEF_POWER", default=1.5, optional=True))
BURDEN_OVERLAP_FLOOR = float(g.const("scripts/early_life_conditions.gd", "BURDEN_OVERLAP_FLOOR", default=1.0, optional=True))
PREMODERN_FECUNDITY = float(g.const("scripts/early_life_conditions.gd", "PREMODERN_FECUNDITY", default=1.0, optional=True))
# Phase 3 (R3) engine mechanics mirrored here; each reads its constants from the GDScript.
FECUNDITY_KNEE = float(g.const("scripts/early_life_conditions.gd", "PREMODERN_FECUNDITY_KNEE", default=9.0, optional=True))
FECUNDITY_SLOPE = float(g.const("scripts/early_life_conditions.gd", "PREMODERN_FECUNDITY_SLOPE", default=1.0, optional=True))
TERRITORY_CAPACITY = g.const("scripts/early_life_conditions.gd", "TERRITORY_CAPACITY", default=[], optional=True)
CROWDING_ONSET = float(g.const("scripts/early_life_conditions.gd", "CROWDING_ONSET", default=0.8, optional=True))
CROWDING_MORTALITY = float(g.const("scripts/early_life_conditions.gd", "CROWDING_MORTALITY", default=0.0, optional=True))
CROWDING_CONCEPTION = float(g.const("scripts/early_life_conditions.gd", "CROWDING_CONCEPTION", default=0.0, optional=True))
SPARE_LAND_ONSET = float(g.const("scripts/early_life_conditions.gd", "SPARE_LAND_ONSET", default=0.0, optional=True))
SPARE_LAND_CONCEPTION = float(g.const("scripts/early_life_conditions.gd", "SPARE_LAND_CONCEPTION", default=0.0, optional=True))
SPARE_LAND_HEALTH = float(g.const("scripts/early_life_conditions.gd", "SPARE_LAND_HEALTH", default=0.0, optional=True))
SUSTAINABLE_SPECIALISTS = g.const("scripts/society_model.gd", "SUSTAINABLE_SPECIALISTS", default=[], optional=True)
SPECIALIST_UPKEEP = g.const("scripts/society_model.gd", "SPECIALIST_UPKEEP", default={}, optional=True)
DECREE_COVER = g.const("scripts/early_life_conditions.gd", "DECREE_COVER", default={}, optional=True)
FOOD_LABOR_FLOOR = g.const("scripts/government_people_system.gd", "FOOD_LABOR_FLOOR", default=[], optional=True)
SPECIALIZATION_HEADROOM = float(g.const("scripts/society_model.gd", "SPECIALIZATION_HEADROOM", default=0.0, optional=True))
EFFECT_LINE = g.const("scripts/society_model.gd", "EFFECT_LINE", default={}, optional=True)
INFANT_LOSS_REPLACEMENT = float(g.const("scripts/early_life_conditions.gd", "INFANT_LOSS_REPLACEMENT", default=2.6, optional=True))
SPECIALIZATION_NEGLECT = float(g.const("scripts/society_model.gd", "SPECIALIZATION_NEGLECT", default=0.0, optional=True))
# Birth-care burden adds to the missing-care excess (EarlyLifeConditions.neonatal_factor).
ADDITIVE_BIRTH_BURDEN = "float(care.get(\"neonatal\",1.0))+float((care.get(\"burden\"" in g.source("scripts/early_life_conditions.gd")
# Chronic shortfall lowers conception through sqrt(food) (GameState._conception_condition_factor).
SQRT_FOOD_CONCEPTION = "lerpf(0.10,1.05,sqrt(food))" in g.source("scripts/game_state.gd")


def curve(points, x):
    """SocietyModel._rise / piecewise-linear [[x, y], ...]."""
    if not points:
        return 0.0
    if x <= float(points[0][0]):
        return float(points[0][1])
    for i in range(1, len(points)):
        if x <= float(points[i][0]):
            a, b = points[i - 1], points[i]
            return lerp(float(a[1]), float(b[1]), (x - float(a[0])) / max(0.001, float(b[0]) - float(a[0])))
    return float(points[-1][1])
POLICIES = g.const("scripts/government_policy_catalog.gd", "POLICIES", default={})
PROBE_POLICY_MAGNITUDE = 0.18   # truth/early-consequence probes: apply_policy(id, 0.18, 120 days) every 120 days
# research_600 foundation work (DiscoverySystem._research_600_foundation_candidate):
# present in the engine source -> a staffed line with no open question of its
# own researches open prerequisites of its era-open questions from any line.
FOUNDATION_WORK = "_research_600_foundation_candidate" in g.source("scripts/discovery_system.gd")
ART_ERA_BONUS_SHARE = float(g.const("scripts/artifact_collection.gd", "ERA_BONUS_SHARE", default=-1.0, optional=True))


def lerp(a, b, t):
    return a + (b - a) * t


def clamp(x, lo, hi):
    return lo if x < lo else hi if x > hi else x


def lag(x, target, rate, days):
    """x approaches target at a daily lerp rate over ``days`` (day_span.gd SPAN.rate)."""
    return x + (target - x) * (1.0 - (1.0 - rate) ** days)


@dataclass
class Scenario:
    name: str
    site: str = "good"
    research: dict = field(default_factory=dict)
    focus: str = ""
    policies: list = field(default_factory=list)
    targets: list = field(default_factory=list)
    scouting: float = 0.0
    study_weight: int = 0
    ai: bool = False
    start_population: int = 120
    labor: dict = field(default_factory=dict)
    # Timed strategy: [{"from": year, "research": {...}, "knowledge_share": pct}, ...]
    phases: list = field(default_factory=list)
    knowledge_share: float = -1.0   # override Knowledge labor % (others scaled; Food still guarded)
    site_profile: dict = field(default_factory=dict)
    seed_finds_day: int = -1
    study_rule: str = ""      # "ai": ArtifactCollection.advance staffs 1 while anything is unstudied

    @staticmethod
    def from_dict(name: str, d: dict, sites: dict) -> "Scenario":
        s = Scenario(name=name, **{k: v for k, v in d.items() if k in Scenario.__dataclass_fields__ and k not in ("name", "site_profile")})
        s.site_profile = dict(sites.get(s.site, sites.get("good", {})))
        s.site_profile.update(d.get("site_profile", {}))
        return s


class Surrogate:
    def __init__(self, scenario: Scenario, seed: int, params: dict, data=None, record_items: bool = True):
        self.p = params
        self.c, self.cat = data if data is not None else (gd.load_constants(), None)
        if self.cat is None:
            self.cat = gd.Catalog(self.c)
        self.s = scenario
        self.seed = seed
        self.rng = np.random.default_rng(seed)
        self.record_items = record_items
        c, cat = self.c, self.cat
        n = cat.n
        # --- per-item static draws (discovery_system.gd _research_draw) -----------
        self.cost_draw = 0.85 + self.rng.random(n) * 0.30
        # --- tuning knobs (tune.py): game-side changes expressed as multipliers ----
        self.tune_pace = float(params.get("tune_research_pace", 1.0))          # x on daily progress (discovery_system 0.12 / research_years)
        self.tune_doubling = float(params.get("tune_era_doubling", c.era_doubling))
        self.tune_window = float(params.get("tune_era_window", c.era_window))
        self.tune_adoption = float(params.get("tune_adoption_pace", 1.0))       # x on SocietyModel.ADOPTION_PACE
        self.tune_cap = float(params.get("tune_cap_scale", 1.0))                # x on era ceilings (ERA_CEILING_600 anchors)
        self.tune_burden = float(params.get("tune_burden_scale", 1.0))          # x on (ERA_BURDEN - 1), early_life_conditions.gd
        line_scale = params.get("tune_line_scale") or {}
        self.E = cat.E
        if line_scale:
            scale = np.array([float(line_scale.get(line, 1.0)) for line in gd.LINES])[cat.line]
            self.E = cat.E * scale[:, None]
        # research_affinity: seeded draw x100 + resource potential x15 per requirement.
        self.affinity = self.rng.random(n) * 100.0 + np.array([len(r) for r in cat.resource_requirements]) * 15.0 * float(params.get("resource_potential", 0.5))
        ctx = dict(params["context"])
        self.ctx = ctx
        self._activity(ctx, hearth=False)
        # --- life table per cohort (game_state.gd _natural_cohort_hazards) -------
        self.ages = np.arange(110)
        self.cohort_age_slices = [(int(round(c.cohort_ranges[k][0])), int(round(c.cohort_ranges[k][1]))) for k in COH]
        self.cohort_days = np.array([c.cohort_days[k] for k in COH])
        self.cohort_mean = np.zeros((6, 110))
        for ci, (a, b) in enumerate(self.cohort_age_slices):
            self.cohort_mean[ci, a:b] = 1.0 / max(1, b - a)
        # --- population --------------------------------------------------------
        total = float(scenario.start_population)
        self.coh = np.array([0.32, 0.15, 0.14, 0.13, 0.18, 0.08]) * total   # initialize_population_model
        self._sync()
        repro = self._reproductive()
        self.preg = np.array([0.34, 0.33, 0.33]) * repro * 0.045
        self.postpartum = repro * 0.018
        self.health = 0.72
        self.food_security = 0.82
        self.cohesion = 0.58
        self.legitimacy = 0.62
        self.security = 0.38
        self.logistics = 0.16
        self.material = 0.12
        self.ecology = 0.88
        self.knowledge_metric = 0.18
        self.nutrition_reserve = 0.90
        self.malnutrition = 0.0
        self.diet_window = 0.62
        self.infant_loss = 0.0
        self.shortage_days = 0.0
        self.housing_capacity = 150.0
        self.completed = 0.0
        self.capacities = {"demography": 0.5, "nutrition": 0.5, "health": 0.5, "labor": 0.5, "knowledge": 0.18, "production": 0.12,
                           "infrastructure": 0.05, "logistics": 0.16, "ecology": 0.88, "institutions": 0.25, "security": 0.38, "culture": 0.58}
        self.education = 0.18
        self.fresh = 0.0
        self.stored = total * 30.0 * 0.95   # founding manifest: about 30 days of food
        self.source_health = {"gather": 0.92, "hunt": 0.88, "fish": 0.90, "cult": 0.94}
        self.last = {"production": total * 0.95, "need": total * 0.95, "food_share": 0.35, "intake": 1.0, "diet": 0.62, "harvest": {}}
        self.alloc_pct = {r: float(v) for r, v in BASE_ALLOC.items()}
        # --- research ------------------------------------------------------------
        self.known = cat.id_mask(params.get("starting_known", []))
        self.adoption = np.where(self.known, 0.025, 0.0)
        self.discovered_day = np.full(n, -1.0)
        self.progress = np.zeros(n)
        nch = len(cat.channel_keys)
        self.active = np.full(nch, -1, dtype=np.int64)
        self.channel_weight = np.zeros(nch)
        self.unit_alloc = np.zeros(nch, dtype=np.int64)
        self.line_channels = [np.where((cat.channel_line == li) & cat.channel_staffable)[0] for li in range(len(gd.LINES))]
        self.scholarship = 0.0
        self.effects = np.zeros(len(cat.effect_keys))
        self.effect_raw = np.zeros(len(cat.effect_keys))
        self.ceiling_era = 0.0
        self.targets = cat.id_mask(scenario.targets)
        self.chan_items = [np.where(cat.channel == k)[0] for k in range(nch)]
        self.children = [[] for _ in range(n)]
        for i in range(n):
            for j in cat.req_all[i]:
                if j < n:
                    self.children[j].append(i)
            for j in cat.route_req[cat.route_owner == i].ravel() if False else []:
                pass
        # parents through requires_any groups and routes also wake children
        for gi, owner in enumerate(cat.any_owner):
            for j in cat.any_groups[gi]:
                if j < n:
                    self.children[j].append(int(owner))
        for ri, owner in enumerate(cat.route_owner):
            for j in cat.route_req[ri]:
                if j < n:
                    self.children[j].append(int(owner))
        self.children = [np.unique(np.array(ch, dtype=np.int64)) for ch in self.children]
        self.ready = np.zeros(n, dtype=bool)
        self._refresh_ready(np.arange(n))
        self.cond_ok = np.ones(n, dtype=bool)
        self.log: list = []
        self.items: list = []
        # --- artifacts -------------------------------------------------------------
        self.art = {"tier": [], "work": [], "study": [], "held": [], "set": [], "set_size": [], "lean": [], "family": [], "seeded": []}
        self.art_sets: dict = {}
        self.art_explored = 0.0
        self.art_sites_left = 1.0
        self.art_bonus = {"science": 0.0, "culture": 0.0}
        self.art_family = np.zeros(len(gd.LINES))
        self.allure = 0.0
        self.day = 0.0
        self._effects_update()
        self._capacities()

    # ------------------------------------------------------------------ helpers
    def eff(self, key: str) -> float:
        return self._eff.get(key, 0.0)

    def _activity(self, ctx: dict, hearth: bool) -> None:
        """discovery_system.gd process_day: activity = 0.65 + sum(context[signal])*0.22;
        _candidate_score adds clamp(context,0,4)*13 per signal."""
        scale = float(self.p.get("signal_scale", 1.0))
        c = dict(ctx)
        if not hearth:
            for k in ("construction", "storage", "timber"):
                c.pop(k, None)
        vals = [sum(c.get(s, 0.0) for s in sig) * scale for sig in self.cat.signals]
        self.activity_sum = np.array(vals)
        self.item_activity = 0.65 + self.activity_sum * 0.22
        self.signal_score = np.array([sum(min(4.0, max(0.0, c.get(s, 0.0) * scale)) for s in sig) * 13.0 for sig in self.cat.signals])

    def _reproductive(self) -> float:
        w = self.c.reproductive_weights
        return self.coh[1] * w[0] + self.coh[2] * w[1] + self.coh[3] * w[2] + self.coh[4] * w[3]

    @property
    def population(self) -> float:
        return self._pop

    @property
    def able(self) -> float:
        return self._able

    def _sync(self) -> None:
        values = self.coh.tolist()
        self._pop = sum(values)
        self._able = values[1] + values[2] + values[3] + values[4]

    def workers(self, role: str) -> float:
        count = self.able * self.alloc_pct[role] / 100.0
        if role == "Knowledge":
            count *= float(self.p["knowledge_effective_factor"])
        return count

    # ---------------------------------------------------------------- readiness
    def _refresh_ready(self, rows: np.ndarray) -> None:
        cat = self.cat
        n = cat.n
        known_ext = np.concatenate([self.known, [True, False]])
        if len(rows) == 0:
            return
        ok = known_ext[cat.req_all[rows]].all(axis=1)
        if len(cat.any_owner):
            sel = np.isin(cat.any_owner, rows)
            if sel.any():
                known_any = np.concatenate([self.known, [False, False]])
                group_ok = known_any[cat.any_groups[sel]].any(axis=1)
                bad = np.zeros(n, dtype=bool)
                bad[cat.any_owner[sel][~group_ok]] = True
                ok &= ~bad[rows]
        rsel = np.isin(cat.route_owner, rows)
        route_ok = known_ext[cat.route_req[rsel]].all(axis=1)
        has_route = np.zeros(n, dtype=bool)
        has_route[cat.route_owner[rsel][route_ok]] = True
        ok &= has_route[rows]
        self.ready[rows] = ok & ~self.known[rows]

    def _conditions(self, year: float) -> None:
        """Research600.conditions_met + resource requirements, re-evaluated yearly."""
        cat, p = self.cat, self.p
        pop = self.population
        settlements = self.settlements
        inst = self.capacities["institutions"]
        contact = year >= float(p["contact_year"])
        env = self.s.site_profile.get("environment_tags", ["river", "woodland"])
        rk = p["resource_known_year"]
        lagd = p["resource_stage_lag"]
        ok = (cat.min_population <= pop) & (cat.min_settlements <= settlements) & (cat.institutions_min <= inst + 1e-9)
        ok &= ~cat.contact_required | contact
        evidence = np.ones(cat.n)
        for i in range(cat.n):
            rs = cat.resources_known[i]
            if rs and any(year < rk.get(r, 1e9) for r in rs if r not in ("Gypsum", "Meteoric iron", "Alum")):
                ok[i] = False
                continue
            envs = cat.environment[i]
            if envs and not any(e in env for e in envs):
                ok[i] = False
                continue
            reqs = cat.resource_requirements[i]
            if reqs:
                score = 0.0
                for q in reqs:
                    r = q.get("resource", "")
                    stage = q.get("stage", "recognized")
                    ready_year = rk.get(r, 1e9) + lagd.get(stage, 0)
                    override = (p.get("resource_stage_year_override") or {}).get(r, {})
                    if stage in override:
                        ready_year = float(override[stage])
                    if year < ready_year:
                        ok[i] = False
                        break
                    score += p["evidence_by_stage"].get(stage, 1.0)
                evidence[i] = clamp(score / max(1, len(reqs)), 0.55, 1.25)
        gate = cat.opening_gate & (year < float(p["opening_gate_delay_years"]))
        self.cond_ok = ok & ~gate
        self.evidence = evidence

    @property
    def territory_settlements(self) -> int:
        """Settlements that hold land for EarlyLifeConditions.carrying_capacity.
        Truth probes: the player's delegated society stays in one settlement; the
        rival controller founds daughter settlements (about one per 30 years)."""
        if self.s.ai:
            return 1 + int(self.day / YEAR // float(self.p.get("ai_settlement_years", 30.0)))
        return 1

    @property
    def settlements(self) -> int:
        return 1 + int(max(0.0, self.population - 120.0) // float(self.p["settlement_population"]))

    # ------------------------------------------------------------------ effects
    def _effects_update(self) -> None:
        """SocietyModel._rebuild_effect_totals: sum(effects x adoption), held under
        the era ceiling of society_era() (calendar vs 95th percentile of known eras)."""
        cat = self.cat
        weights = np.where(self.known, np.clip(self.adoption, 0.0, 1.0), 0.0)
        raw = weights @ self.E
        # SocietyModel specialization (Phase 3 R3): a focused line's benefits count more.
        focus_by_line = None
        if SPECIALIZATION_HEADROOM > 0.0:
            pol = self.research_policy(self.day / YEAR) or {}
            tot = sum(max(0.0, float(v)) for v in pol.values())
            if tot > 0:
                even = 1.0 / 12.0
                focus_by_line = np.array([clamp((max(0.0, float(pol.get(ln, 0))) / tot - even) / (1.0 - even), 0.0, 1.0) for ln in gd.LINES])
                if focus_by_line.max() > 0:
                    fl = focus_by_line[cat.line]
                    item_mult = np.where(fl > 0, 1.0 + SPECIALIZATION_HEADROOM * fl, 1.0 - SPECIALIZATION_NEGLECT * focus_by_line.max())
                    benefit = np.where(cat.lower_better[None, :], np.minimum(self.E, 0.0), np.maximum(self.E, 0.0))
                    raw = raw + (weights * (item_mult - 1.0)) @ benefit
        self.effect_raw = raw
        eras = cat.ceiling_era[self.known]
        if eras.size:
            eras = np.sort(eras)
            frontier = eras[int((eras.size - 1) * self.c.frontier_percentile)]
            self.ceiling_era = clamp(min(self.day / YEAR, frontier), 0.0, self.c.modern_era)
        else:
            self.ceiling_era = 0.0
        lo, hi = gd.era_bounds(cat, self.c, self.ceiling_era)
        if self.tune_cap != 1.0:
            lo = np.where(cat.lower_better, np.maximum(cat.limit_lo, lo * self.tune_cap), lo)
            hi = np.where(cat.lower_better, hi, np.minimum(cat.limit_hi, hi * self.tune_cap))
        # SocietyModel.era_ceiling specialization headroom (Phase 3 R3).
        if SPECIALIZATION_HEADROOM > 0.0:
            weights = self.research_policy(self.day / YEAR) or {}
            total = sum(max(0.0, float(v)) for v in weights.values())
            if total > 0:
                even = 1.0 / 12.0
                focus = {ln: clamp((max(0.0, float(v)) / total - even) / (1.0 - even), 0.0, 1.0) for ln, v in weights.items()}
                fmax = max(focus.values()) if focus else 0.0
                mult = np.array([(1.0 + SPECIALIZATION_HEADROOM * focus.get(EFFECT_LINE.get(k, ""), 0.0)) if focus.get(EFFECT_LINE.get(k, ""), 0.0) > 0
                                 else (1.0 - SPECIALIZATION_NEGLECT * fmax) for k in cat.effect_keys])
                lo = np.where(cat.lower_better, np.maximum(cat.limit_lo, lo * mult), lo)
                hi = np.where(cat.lower_better, hi, np.minimum(cat.limit_hi, hi * mult))
        self.effects = np.clip(raw, lo, hi)
        self._eff = dict(zip(cat.effect_keys, self.effects.tolist()))
        # SocietyModel._apply_specialist_upkeep (Phase 3 R3): Knowledge workers
        # beyond the era's sustainable share cost labor, stores, cohesion and births.
        self.specialist_excess = 0.0
        if SUSTAINABLE_SPECIALISTS and self.able > 0:
            share = clamp(self.workers("Knowledge") / max(1.0, self.able), 0.0, 1.0)
            self.specialist_excess = max(0.0, share - curve(SUSTAINABLE_SPECIALISTS, self.ceiling_era))
            for key, k in SPECIALIST_UPKEEP.items():
                lim = self.c.effect_limits.get(key, (-0.5, 0.8)) if hasattr(self.c, "effect_limits") else (-0.5, 0.8)
                self._eff[key] = clamp(self._eff.get(key, 0.0) + float(k) * self.specialist_excess, float(lim[0]), float(lim[1]))
        self._knowledge_rate_cap = float(hi[cat.effect_index["knowledge_rate"]]) if "knowledge_rate" in cat.effect_index else 1.0

    def _adoption(self, days: float) -> None:
        """SocietyModel.process_day adoption (every 30 days)."""
        pop = max(1.0, self.population)
        teaching = self.workers("Knowledge") / pop * 0.055 + self.able * self.alloc_pct["Administration"] / 100 / pop * 0.018 \
            + self.able * self.alloc_pct["Crafting"] / 100 / pop * 0.012
        factor = 1.0 + clamp(self.eff("adoption_rate"), -0.35, 0.80)
        preserved = clamp(self.knowledge_metric + self.eff("knowledge_preservation"), 0.05, 1.2)
        k = self.known
        a = self.adoption[k]
        practice = np.minimum(0.012, self.activity_sum[k] * 0.0014)
        line_weight = np.array([float(self.s_research.get(line, 0)) for line in gd.LINES])[self.cat.line[k]]
        directed = np.minimum(0.006, line_weight * 0.0012)
        pace = self.c.adoption_pace * self.tune_adoption
        spread = (0.00035 + teaching + practice + directed) * factor * pace * (1.0 - a)
        loss = np.where(self.activity_sum[k] <= 0.05, max(0.0, 0.00018 - preserved * 0.00015) * pace, 0.0)
        self.adoption[k] = np.clip(a + (spread - loss) * days, 0.015, 1.0)

    # --------------------------------------------------------------- capacities
    def _capacities(self) -> None:
        """SocietyModel.evaluate_capacities + evaluate_subcategories (education index)."""
        e = self.eff
        pop = max(1.0, self.population)
        able_ratio = clamp(self.able / pop, 0, 1)
        housing = clamp(self.housing_capacity / pop, 0, 1)
        observers = self.workers("Knowledge")
        weights = [float(v) for v in self.s_research.values()] if hasattr(self, "s_research") else [1.0] * 12
        inquiry = sum(weights)
        active_dirs = sum(1 for w in weights if w > 0)
        attention_fit = clamp(observers / max(1.0, inquiry), 0.10, 1.0)
        diversity = clamp(active_dirs / 12.0, 0.05, 1.0)
        preserved = clamp(self.knowledge_metric + e("knowledge_preservation") * 0.55, 0.0, 1.0)
        communication = clamp(0.28 + e("route_speed") * 0.30 + e("standardization") * 0.42 + e("state_capacity") * 0.22, 0.10, 1.0)
        admin = self.able * self.alloc_pct["Administration"] / 100.0
        inst_support = clamp(0.20 + admin / max(1.0, pop * 0.06) * 0.38 + self.legitimacy * 0.22, 0.05, 1.0)
        overload = clamp(max(0.0, inquiry - observers) / max(1.0, observers) * 0.22 + e("institutional_rigidity") * 0.25, 0.0, 0.55)
        combined = clamp((0.18 + observers / max(1.0, pop * 0.08) * 0.22 + self.health * 0.14 + preserved * 0.17 + communication * 0.10
                          + inst_support * 0.10 + diversity * 0.09) * attention_fit * (1.0 - overload), 0.03, 1.0)
        labor = clamp(able_ratio * (0.32 + self.health * 0.27 + self.food_security * 0.18 + self.cohesion * 0.13 + housing * 0.10)
                      * (1.0 + e("labor_efficiency") - e("labor_demand") * 0.28 - e("fatigue") * 0.20), 0.08, 1.15)
        diet = self.last["diet"]
        art_culture = self.art_bonus_for("culture")
        cap = {
            "demography": clamp(self.health * 0.34 + self.food_security * 0.30 + housing * 0.18 + self.cohesion * 0.10 + e("maternal_safety") * 0.08, 0.02, 1.0),
            "nutrition": clamp(self.food_security * 0.72 + diet * 0.20 + e("nutrition_quality") * 0.08, 0.02, 1.0),
            "health": clamp(self.health + e("health_protection") * 0.22 - e("disease_exposure") * 0.18 - e("health_risk") * 0.15, 0.02, 1.0),
            "labor": labor, "knowledge": combined,
            "production": clamp(self.material * 0.45 + labor * 0.30 + e("tool_quality") * 0.14 + e("task_coordination") * 0.11, 0.02, 1.0),
            "infrastructure": clamp(housing * 0.38 + self.completed / 10.0 * 0.32 + e("construction_rate") * 0.18 + e("disaster_resilience") * 0.12, 0.01, 1.0),
            "logistics": clamp(self.logistics * 0.55 + e("haul_capacity") * 0.22 + e("route_speed") * 0.16 + e("storage_loss") * -0.07, 0.01, 1.0),
            "ecology": clamp(self.ecology + e("ecology_recovery") * 0.20 - e("ecological_pressure") * 0.18 - e("pollution") * 0.12, 0.01, 1.0),
            "institutions": clamp(inst_support + e("state_capacity") * 0.22 + e("legitimacy") * 0.12 + float(self.p["institution_offset"]), 0.02, 1.0),
            "security": clamp(self.security + e("security_efficiency") * 0.18 + e("warfare_readiness") * 0.12, 0.02, 1.0),
            "culture": clamp(self.cohesion * 0.52 + self.legitimacy * 0.25 + diversity * 0.12 + e("cohesion") * 0.11 + art_culture * 0.12, 0.02, 1.0),
        }
        self.capacities = cap
        self.communication = communication
        self.preserved = preserved
        self.education = clamp(preserved * 0.58 + communication * 0.42 + float(self.p["education_offset"]), 0.01, 1.0)

    # --------------------------------------------------------------------- labor
    def _allocate_labor(self) -> None:
        """GovernmentPeopleSystem._allocations_for_focus + _apply_survival_guard."""
        if self.s.labor:
            # Observed delegated mix (GovernmentPeopleSystem auto focus + cultural
            # labor bias + leader skills), measured from the truth runs.
            w = {r: float(self.s.labor.get(r, BASE_ALLOC[r])) for r in ROLES}
            share = getattr(self, "active_knowledge_share", -1.0)
            if share >= 0:
                # Researchers come out of every other non-food role in proportion
                # (the engine's focus weights do the same through normalization).
                others = [r for r in ROLES if r not in ("Food", "Knowledge")]
                total = sum(w.values())
                free = total - w["Food"] - total * share / 100.0
                scale = free / max(1e-6, sum(w[r] for r in others))
                for r in others:
                    w[r] *= max(0.0, scale)
                w["Knowledge"] = total * share / 100.0
        else:
            w = {r: float(v) for r, v in BASE_ALLOC.items()}
            for role, v in FOCUS_CHANGES.get(self.s.focus, {}).items():
                w[role] = w.get(role, 0.0) + float(v)
        # _survival_guard: shortage now, or stores falling with little left. The
        # forecast part is approximated by a falling month with < 20 days left.
        food_risk = self.last["intake"] < 0.995 or (self.stored_days < 20.0 and self.last["production"] < self.last["need"] * 0.97)
        if food_risk:
            w["Food"] += 18.0
            w["Logistics"] += 5.0
        demand, produced, prev = self.last["need"], self.last["production"], self.last["food_share"]
        if demand > 0 and prev > 0 and (food_risk or self.p.get("guard_always", False)):
            buffer = (1.08 if food_risk else 1.02) * float(self.p["food_buffer"]) / 1.10
            needed = clamp(prev * demand * buffer / max(0.01, produced), 0.0, 0.85)
            other = sum(v for r, v in w.items() if r != "Food")
            w["Food"] = max(w["Food"], other * needed / max(0.01, 1.0 - needed))
        if FOOD_LABOR_FLOOR:
            # GovernmentPeopleSystem._apply_food_labor_floor (Phase 3 R3).
            floor_share = curve(FOOD_LABOR_FLOOR, self.day / YEAR)
            pol = self.research_policy(self.day / YEAR) or {}
            tot = sum(max(0.0, float(v)) for v in pol.values())
            if tot > 0:
                even = 1.0 / 12.0
                fo = lambda ln: clamp((max(0.0, float(pol.get(ln, 0))) / tot - even) / (1.0 - even), 0.0, 1.0)
                floor_share *= 1.0 - 0.25 * clamp(fo("nutrition") + 0.5 * fo("labor"), 0.0, 1.0)
                floor_share *= 1.0 + 0.12 * fo("health") + 0.08 * fo("demography")
            floor_share = clamp(floor_share * (1.0 + max(0.0, -self.policy("labor_multiplier"))), 0.0, 0.85)
            other = sum(v for r, v in w.items() if r != "Food")
            w["Food"] = max(w["Food"], other * floor_share / max(0.01, 1.0 - floor_share))
        if not self.s.labor:
            # Default leader skills of 50 (Administration/Logistics/Knowledge bonuses).
            w["Administration"] += 50 * 0.025
            w["Logistics"] += 50 * 0.018
            w["Knowledge"] += 50 * 0.012
        total = sum(w.values())
        target = {r: w[r] / total * 100.0 for r in ROLES}
        # The engine re-plans labor daily; a month with any shortfall moves at once.
        rate = 1.0 if food_risk else float(self.p["food_adjust_rate"])
        for r in ROLES:
            self.alloc_pct[r] = lerp(self.alloc_pct[r], target[r], rate)

    @property
    def stored_days(self) -> float:
        return (self.fresh + self.stored) / max(0.01, self.last["need"])

    # ---------------------------------------------------------------------- food
    def _weather(self, day: float) -> float:
        """food_system.gd _weather_yield_factor (drought pulses, hard winters)."""
        prof = self.s.site_profile
        var = clamp(prof.get("rainfall_variability", 0.35), 0, 1)
        rolling = math.sin((day + self.phase_a) / 53.0) * 0.62 + math.sin((day + self.phase_b) / 127.0) * 0.38
        factor = 1.0 + rolling * (0.035 + var * 0.105)
        year = int(day // 365)
        yr = self.year_draws(year)
        doy = day % 365.0
        pulse = max(0.0, 1.0 - abs(doy - yr["center"]) / yr["half"])
        if yr["roll"] < 0.08 + var * 0.34:
            factor *= 1.0 - (0.12 + yr["sev"] * (0.06 + var * 0.32)) * pulse
        elif yr["roll"] > 0.88:
            factor *= 1.0 + yr["good"] * pulse
        seasonality = clamp(float(self.p["seasonality_c"]) / 20.0, 0.0, 1.3)
        wy = self.year_draws(int((day + 120) // 365))
        if wy["winter"] < 0.08 + seasonality * 0.12:
            winter = max(0.0, -math.sin((day % 365.0) / 365.0 * 2 * math.pi))
            factor *= 1.0 - wy["winter_sev"] * winter
        return clamp(factor, 0.52, 1.24)

    def year_draws(self, year: int) -> dict:
        cache = self.__dict__.setdefault("_years", {})
        if year not in cache:
            r = np.random.default_rng((self.seed * 1000003 + year * 7919) & 0xFFFFFFFF).random(8)
            cache[year] = {"roll": r[0], "center": 65 + r[1] * 235, "half": 28 + r[2] * 50, "sev": r[3], "good": 0.08 + r[4] * 0.10,
                           "winter": r[5], "winter_sev": 0.16 + r[6] * 0.18}
        return cache[year]

    def _seasons(self, day: float) -> dict:
        """PlanetEnvironment.food_season_factor."""
        prof = self.s.site_profile
        wave = math.sin((day % 365.0) / 365.0 * 2 * math.pi)
        seasonality = clamp(float(self.p["seasonality_c"]) / 20.0, 0.25, 1.35)
        growing = clamp(prof.get("growing_season", 0.5), 0.04, 1.0)
        precip = clamp(prof.get("precipitation", 0.5), 0.0, 1.0)
        return {
            "plants": clamp((0.58 + growing * 0.52) + wave * 0.40 * seasonality, 0.16, 1.52),
            "meat": clamp(0.88 + prof.get("game", 0.4) * 0.20 - wave * 0.10 * seasonality, 0.58, 1.22),
            "fish": clamp(0.86 + prof.get("water_access", 0.0) * 0.22 + math.sin((day % 365.0) / 365.0 * 2 * math.pi + 0.8) * 0.14, 0.52, 1.24),
            "staples": clamp(0.30 + growing * 0.70 + wave * 0.56 * seasonality - (1.0 - precip) * 0.18, 0.02, 1.58),
            "wave": wave,
        }

    def _food(self, days: float, labor_eff: float) -> dict:
        """FoodSystem._process_local_day over ``days`` days of the same conditions."""
        c, p, e = self.c, self.p, self.eff
        prof = self.s.site_profile
        pop = max(1.0, self.population)
        day = self.day + days * 0.5
        W = self.workers("Food")
        # --- demand (_calculate_aggregate_demand)
        children, elders = self.coh[0], self.coh[5]
        adults = max(0.0, pop - children - elders)
        base = children * 0.60 + adults + elders * 0.86
        labor = sum(self.able * self.alloc_pct[r] / 100.0 * float(LABOR_EXTRAS.get(r, 0.02)) for r in ROLES)
        pregnancy = float(self.preg.sum()) * 0.12
        lactation = pop * 0.012 * 0.21
        season = self._seasons(day)
        temp = float(p["mean_temperature_c"]) + season["wave"] * float(p["seasonality_c"])
        climate = base * (clamp((12.0 - temp) / 28.0, 0, 1) * 0.075 + clamp((temp - 31.0) / 17.0, 0, 1) * 0.045)
        policy_demand = 1.0 - (0.0)
        need = (base + labor + pregnancy + lactation + climate) * policy_demand
        # --- production (_produce)
        water = clamp(prof.get("water_access", 0.0), 0, 1)
        fishing_w = max(0.16 * max(float(p["fishing_access"]), water), 0.0)
        cult_w = 0.0
        seed_i = self.cat.index.get("seed_selection")
        if seed_i is not None and self.known[seed_i]:
            cult_w = (0.22 + prof.get("fertility", 0.0) * 0.20 + float(p["access_fertile"]) * 0.08) * float(self.adoption[seed_i])
        remaining = max(0.0, 1.0 - fishing_w - cult_w)
        hunt_w = remaining * (0.31 + float(p["access_game"]) * 0.09)
        gather_w = max(0.0, remaining - hunt_w)
        sh = self.source_health
        # _adaptive_source_weights (blend 0.8)
        wild = {"plants": (gather_w, sh["gather"]), "meat": (hunt_w, sh["hunt"]), "fish": (fishing_w, sh["fish"])}
        tot = gather_w + hunt_w + fishing_w
        scores = {k: w * math.sqrt(clamp(h * season[k], 0.05, 2.0)) for k, (w, h) in wild.items()}
        st = sum(scores.values())
        adapted = {k: lerp(wild[k][0], scores[k] / max(1e-4, st) * tot, 0.8) for k in wild}
        tg = lerp(0.54, 1.34, clamp(prof.get("forage", 0.45), 0, 1))
        th = lerp(0.52, 1.38, clamp(prof.get("game", 0.40), 0, 1))
        eff_f = lerp(0.76, 1.08, clamp(labor_eff, 0, 1))
        ecol = lerp(0.58, 1.04, clamp(self.ecology, 0, 1))
        practice = 1.0 + e("foraging_yield") + e("food_output") + self.policy("food_yield")
        weather = self._weather(day)
        cal = c.yield_calibration
        raw = {
            "plants": W * adapted["plants"] * 4.55 * cal * tg * season["plants"] * eff_f * ecol * sh["gather"] * practice * weather,
            "meat": W * adapted["meat"] * 4.85 * cal * th * season["meat"] * eff_f * ecol * sh["hunt"] * (1.0 + float(p["access_game"]) * 0.18) * (1.0 + e("hunting_yield")) * practice * lerp(1.0, weather, 0.38),
            "fish": W * adapted["fish"] * 5.00 * cal * season["fish"] * eff_f * sh["fish"] * (0.76 + float(p["fishing_access"]) * 0.34) * practice * lerp(1.0, weather, 0.28),
        }
        staples = 0.0
        if cult_w > 0:
            staples = W * cult_w * 5.65 * season["staples"] * eff_f * sh["cult"] * (0.68 + prof.get("fertility", 0.0) * 0.38 + float(p["access_fertile"]) * 0.12) \
                * (1.0 + e("soil_productivity") + e("cultivation_yield")) * clamp(weather ** 1.25, 0.46, 1.30)
        # _apply_wild_ceilings + wild_food_capacity
        reach = math.sqrt(pop / 120.0)
        regrowth = lerp(0.55, 1.15, self.ecology) * (1.0 + max(0.0, e("ecology_recovery")))
        rations = {"plants": (60.0 + clamp(prof.get("forage", 0.45), 0, 1) * 170.0) * reach,
                   "meat": (10.0 + clamp(prof.get("game", 0.40), 0, 1) * 60.0) * reach,
                   "fish": (15.0 + water * 80.0) * reach}
        renewal = {"plants": 0.0040 * regrowth, "meat": 0.0015 * regrowth, "fish": 0.0022 * regrowth}
        overuse = {"plants": 0.0025, "meat": 0.0040, "fish": 0.0030}
        weather_mult = {"plants": weather, "meat": lerp(1.0, weather, 0.38), "fish": lerp(1.0, weather, 0.28)}
        keymap = {"plants": "gather", "meat": "hunt", "fish": "fish"}
        harvest = {}
        freed = 0.0
        for k, amount in raw.items():
            if amount <= 0:
                harvest[k] = 0.0
                continue
            ceiling = max(0.01, rations[k] * c.standing_harvest * season[k] * weather_mult[k] * sh[keymap[k]])
            taken = ceiling * (1.0 - math.exp(-amount / ceiling))
            harvest[k] = taken
            freed += adapted[k] * (1.0 - taken / amount)
        if freed > 0 and cult_w > 0 and staples > 0:
            staples *= 1.0 + freed / cult_w
        harvest["staples"] = staples
        # _update_source_health
        able = max(1.0, self.able)
        pressure = W / able
        for k in ("plants", "meat", "fish"):
            h = sh[keymap[k]]
            take = harvest[k] / max(0.01, rations[k])
            change = renewal[k] * (1.0 - h) - overuse[k] * max(0.0, take - 1.0) * h * (1.0 + e("ecological_pressure"))
            sh[keymap[k]] = clamp(h + change * days, 0.12, 1.0)
        if staples > 0:
            recovery = 0.00035 * (1.0 + e("ecology_recovery"))
            sh["cult"] = clamp(sh["cult"] + (recovery - max(0.0, pressure - 0.55) * 0.0011) * days, 0.12, 1.0)
        # --- stocks: fresh eaten first, preserved into stores, spoilage, capacity
        fresh_in = harvest["plants"] + harvest["meat"] + harvest["fish"]
        spoil_mult = (0.72 if self.completed_names("Storage Pits") else 1.0) * max(0.30, 1.0 + e("food_spoilage"))
        fresh_rate = c.spoilage_fresh * spoil_mult * float(p["fresh_spoil_mult"])
        stored_rate = c.spoilage_stored * spoil_mult
        eat_fresh = min(fresh_in + self.fresh / days, need)
        surplus = max(0.0, fresh_in - eat_fresh)
        preserve_cap = (self.workers("Logistics") * 0.16 + self.workers("Crafting") * 0.18) * (1.0 + e("food_storage"))
        preserved = 0.0
        drying = self.cat.index.get("food_drying")
        if drying is not None and self.known[drying]:
            dry = min(surplus, preserve_cap * 0.55 * float(self.adoption[drying]) * 0.85)
            preserved += dry * 0.88
            surplus -= dry
            preserve_cap = max(0.0, preserve_cap - dry)
        smoking = self.cat.index.get("smoking")
        if smoking is not None and self.known[smoking] and preserve_cap > 0:
            smk = min(surplus, preserve_cap * 0.5 * float(self.adoption[smoking]))
            preserved += smk * 0.82
            surplus -= smk
        self.fresh = max(0.0, self.fresh - max(0.0, eat_fresh - fresh_in) * days)
        # A standing fresh pool at its spoilage equilibrium (4%/day).
        self.fresh = lerp(self.fresh, surplus / max(1e-6, fresh_rate), 1.0 - (1.0 - fresh_rate) ** days)
        self.stored += (staples + preserved) * days
        self.stored *= (1.0 - stored_rate) ** days
        from_stores = max(0.0, need - eat_fresh)
        eaten_stored = min(self.stored, from_stores * days) / days
        self.stored -= eaten_stored * days
        capacity = float(p["storage_base_rations"]) + (pop * 84.0 if self.completed_names("Storage Pits") else 0.0)             + (pop * 120.0 if self.completed_names("Public Stores") else 0.0)
        excess = self.fresh + self.stored - capacity
        if excess > 0:
            cut = min(excess, self.fresh)
            self.fresh -= cut
            self.stored = max(0.0, self.stored - (excess - cut))
        eaten = eat_fresh + eaten_stored
        intake = clamp(eaten / max(0.01, need), 0.0, 1.0)
        production = fresh_in + staples
        # _diet_quality (early rules)
        plants, protein = harvest["plants"], harvest["meat"] + harvest["fish"]
        pf = plants / (plants + protein) if plants + protein > 0.001 else 0.5
        total = max(0.001, eaten)
        plant_share = (eat_fresh * pf + eaten_stored * 0.75) / total
        protein_share = (eat_fresh * (1.0 - pf) + eaten_stored * 0.25 * 0.45) / total
        harvested = max(0.001, production)
        even = 1.0 - sum((x / harvested) ** 2 for x in (harvest["plants"], harvest["meat"], harvest["fish"], staples))
        even = clamp(even / 0.75, 0.0, 1.0)
        fresh_share = clamp(eat_fresh / total / 0.5, 0.0, 1.0)
        staple_heavy = max(0.0, staples / harvested - 0.55)
        diet = clamp(0.06 + min(plant_share, 0.55) * 0.40 + min(protein_share, 0.40) * 0.55 + even * 0.16 + fresh_share * 0.10
                     - staple_heavy * 0.20 + e("nutrition_quality"), 0.05, 1.0)
        # _update_nutrition
        self.nutrition_reserve = clamp(self.nutrition_reserve + ((intake - 0.94) * 0.010 + (diet - 0.55) * 0.0018) * days, 0.0, 1.0)
        burden = clamp((1.0 - intake) * 0.68 + (0.58 - diet) * 0.24 + (0.28 - self.nutrition_reserve) * 0.45, 0.0, 1.0)
        self.malnutrition = lag(self.malnutrition, burden, 0.045 if burden > self.malnutrition else 0.012, days)
        self.diet_window = lag(self.diet_window, diet, 1.0 / 120.0, days)
        food_days = (self.fresh + self.stored) / max(0.01, need)
        self.last.update({"production": production, "need": need, "intake": intake, "diet": diet, "harvest": harvest,
                          "food_share": W / max(1.0, self.able), "food_days": food_days, "weather": weather})
        return self.last

    def completed_names(self, name: str) -> bool:
        """settlement_construction.gd works the surrogate tracks by name."""
        if name == "Storage Pits":
            return self.day / YEAR >= float(self.p["storage_pits_year"])
        if name == "Public Stores":   # requires Storage Pits + the public_stores discovery
            i = self.cat.index.get("public_stores")
            return self.completed_names("Storage Pits") and i is not None and self.known[i]                 and self.day - self.discovered_day[i] >= float(self.p["build_delay_years"]) * YEAR
        return False

    def policy(self, channel: str) -> float:
        """ConsequenceEngine.policy_effect: magnitude x the catalog effect, for the
        scenario's continuously renewed decrees (government_policy_catalog.gd POLICIES)."""
        total = 0.0
        for pol in self.s.policies:
            total += PROBE_POLICY_MAGNITUDE * float(POLICIES.get(pol, {}).get("effects", {}).get(channel, 0.0))
        return clamp(total, -1.0, 1.0)

    # ----------------------------------------------------------------- mortality
    def _practice_scale(self, i: int) -> float:
        """SocietyModel.practiced: neglected lines' practices are carried out less thoroughly."""
        if SPECIALIZATION_NEGLECT <= 0.0:
            return 1.0
        pol = self.research_policy(self.day / YEAR) or {}
        tot = sum(max(0.0, float(v)) for v in pol.values())
        if tot <= 0:
            return 1.0
        even = 1.0 / 12.0
        focus = {ln: clamp((max(0.0, float(v)) / tot - even) / (1.0 - even), 0.0, 1.0) for ln, v in pol.items()}
        fmax = max(focus.values()) if focus else 0.0
        line = gd.LINES[int(self.cat.line[i])]
        return 1.0 if focus.get(line, 0.0) > 0 or fmax <= 0 else 1.0 - SPECIALIZATION_NEGLECT * fmax

    def _care(self, overwork: float) -> dict:
        """EarlyLifeConditions.profile (blend 1: new world)."""
        c, e = self.c, self.eff
        excess = dict.fromkeys(("under5", "child", "adult", "neonatal", "maternal"), 0.0)
        cover = {}
        for cat in c.care_categories:
            practice = 0.0
            for rid, wgt in cat["practices"].items():
                i = self.cat.index.get(rid)
                if i is not None and self.known[i]:
                    practice += float(wgt) * clamp(float(self.adoption[i]) * self._practice_scale(i), 0, 1)
            if cat["id"] == "stores":
                for work, wgt in c.storage_works.items():
                    if self.completed_names(work):
                        practice += float(wgt)
            channel = sum(max(0.0, e(ch) / float(scale)) for ch, scale in cat["channels"].items())
            coverage = clamp(max(practice, channel) + (max(0.0, self.policy(DECREE_COVER[cat["id"]])) if cat["id"] in DECREE_COVER else 0.0), 0.0, 1.0)
            cover[cat["id"]] = coverage
            for k in excess:
                excess[k] += float(cat.get(k, 0.0)) * (1.0 - coverage)
        diet = clamp(self.diet_window, 0, 1)
        mal = clamp(self.malnutrition, 0, 1)
        nutrition = clamp(1.0 + mal * 1.1 + max(0.0, 0.66 - diet) * 2.2 - max(0.0, diet - 0.76) * 0.45, 0.85, 2.2)
        care = {
            "under5": (1.0 + excess["under5"]) * nutrition,
            "child": (1.0 + excess["child"]) * (1.0 + (nutrition - 1.0) * 0.5),
            "adult": 1.0 + excess["adult"] + mal * 0.15,
            "neonatal": (1.0 + excess["neonatal"]) * (1.0 + max(0.0, 0.58 - diet) * 0.9 + mal * 0.5),
            "maternal": (1.0 + excess["maternal"]) * (1.0 + mal * 0.6 + overwork * 0.20),
        }
        il = clamp(self.infant_loss, 0.0, 0.6)
        diet_lift = lerp(0.80, 1.05, clamp((diet - 0.35) / 0.45, 0, 1))
        if diet_lift > FECUNDITY_KNEE:
            diet_lift = FECUNDITY_KNEE + (diet_lift - FECUNDITY_KNEE) * FECUNDITY_SLOPE
        care["conception"] = diet_lift * (1.0 - overwork * 0.16) * (1.0 + max(0.0, il - c.reference_infant_loss) * INFANT_LOSS_REPLACEMENT) * PREMODERN_FECUNDITY
        care["pregnancy_risk"] = 1.0 + overwork * 0.35 + max(0.0, 0.5 - diet) * 0.6
        relief = 0.0
        if RELIEF_CHANNELS:
            relief = sum(clamp(e(ch) / float(v), 0.0, 1.0) for ch, v in RELIEF_CHANNELS.items()) / len(RELIEF_CHANNELS)
            relief = relief ** RELIEF_POWER
        scale = self.tune_burden
        # EarlyLifeConditions.carrying_capacity / crowding (Phase 3 R3).
        crowding = 0.0
        if TERRITORY_CAPACITY:
            base = curve(TERRITORY_CAPACITY, self.day / YEAR)
            territory = 1.0 + math.sqrt(max(0, int(self.territory_settlements) - 1)) * 1.6
            methods = 1.0 + max(0.0, e("cultivation_yield")) + max(0.0, e("soil_productivity")) * 0.6 + max(0.0, e("food_output")) * 0.5 + max(0.0, e("food_storage")) * 0.25
            grounds = clamp(sum(self.source_health.values()) / max(1, len(self.source_health)), 0.4, 1.0)
            self.carrying_capacity = base * territory * methods * lerp(0.6, 1.0, grounds)
            crowding = max(0.0, self.population / max(1.0, self.carrying_capacity) - CROWDING_ONSET)
        self.crowding = crowding
        # engine: spare land is judged against the founding territory only
        spare = max(0.0, SPARE_LAND_ONSET - self.population / float(TERRITORY_CAPACITY[0][1])) if TERRITORY_CAPACITY else 0.0
        age_keys = ("under5", "child", "adult", "elder")
        care["burden"] = {k: (1.0 + (float(v) - 1.0) * scale * (1.0 - relief) * ((1.0 - spare * SPARE_LAND_HEALTH) if k in age_keys else 1.0)) * ((1.0 + crowding * CROWDING_MORTALITY) if k in age_keys else 1.0) for k, v in ERA_BURDEN.items()}
        care["conception"] *= max(0.3, 1.0 - crowding * CROWDING_CONCEPTION) * (1.0 + spare * SPARE_LAND_CONCEPTION)
        care["excess_weight"] = {k: float(v) for k, v in EXCESS_WEIGHT.items()}
        care["coverage"] = cover
        return care

    def _age_mult(self, care: dict, band: str, age_ge45: bool, cf: float) -> float:
        """EarlyLifeConditions.age_multiplier (with optional Phase 3 burden)."""
        raw = care.get(band, 1.0)
        overlap = clamp((self.c.good_conditions / max(0.01, cf)) ** 1.5, 0.4, 1.0)
        excess = raw if raw <= 1.0 else 1.0 + (raw - 1.0) * overlap
        burden = care.get("burden") or {}
        if not burden:
            return excess
        weight = care.get("excess_weight", {}).get(band, 1.0)
        # Hunger and sickness in the condition factor overlap the burden too.
        era_burden = 1.0 + (burden.get("elder" if age_ge45 else band, 1.0) - 1.0) * max(BURDEN_OVERLAP_FLOOR, overlap)
        return era_burden * (1.0 + (excess - 1.0) * weight)

    _BAND_OF_AGE = np.array([0 if a < 5 else 1 if a < 15 else 2 if a < 45 else 3 for a in range(110)])

    def _hazards(self, care: dict, cf: float) -> np.ndarray:
        """Per-age annual hazard (before the condition factor): baseline x age_multiplier."""
        mult = np.array([self._age_mult(care, "under5", False, cf), self._age_mult(care, "child", False, cf),
                         self._age_mult(care, "adult", False, cf), self._age_mult(care, "adult", True, cf)])
        return self.c.hazard_by_age * mult[self._BAND_OF_AGE]

    def _condition_factor(self, housing: float) -> float:
        """GameState._mortality_condition_factor."""
        return lerp(1.90, 0.64, clamp(self.health, 0, 1)) * lerp(2.40, 0.78, clamp(self.food_security, 0, 1)) * lerp(1.65, 0.88, clamp(housing, 0, 1))

    def life_expectancy(self, age_hazard: np.ndarray, cf: float, exceptional: float) -> float:
        h = np.clip(age_hazard * cf + exceptional, 0.0001, 0.98)
        survival = np.concatenate([[1.0], np.cumprod(1.0 - h)[:-1]])
        return clamp(float(survival.sum()), 1.0, 110.0)

    # --------------------------------------------------------------- demography
    def _demography(self, days: float, housing: float, care: dict, mortality: dict) -> None:
        c = self.c
        cf = self._condition_factor(housing)
        age_h = self._hazards(care, cf)
        coh_h = self.cohort_mean @ age_h
        natural = np.clip(coh_h * cf, 0.0001, 0.98)                 # annual, per cohort
        self._age_h, self._cf = age_h, cf
        # Exceptional deaths distributed by cause weights (register_population_deaths).
        pop = self.population
        other = np.zeros(6)
        for rate, weights in ((mortality["Hunger"], HUNGER_W), (mortality["Illness"] + mortality["Exposure"] + mortality.get("Other", 0.0), ILL_W), (mortality["Insecurity"], INSEC_W)):
            if rate > 0:
                share = self.coh * weights
                other += share / max(1e-9, share.sum()) * rate * pop
        deaths = self.coh * (1.0 - np.exp(-natural * days / YEAR)) + other * days / YEAR
        deaths = np.minimum(deaths, self.coh * 0.999)
        self.coh = self.coh - deaths
        self.deaths += float(deaths.sum())
        # Aging (game: 1/duration per day).
        moving = self.coh[:-1] * (1.0 - np.exp(-days / self.cohort_days[:-1]))
        self.coh[:-1] -= moving
        self.coh[1:] += moving
        # Reproduction (GameState.process_reproduction_day, daily rates x days).
        cw = c.conception
        repro = self._reproductive()
        active = float(self.preg.sum())
        eligible = max(0.0, repro - active - self.postpartum * 0.55)
        baseline = self.coh[1] * cw[0] * cw[1] + self.coh[2] * cw[2] * cw[3] + self.coh[3] * cw[4] * cw[5] + self.coh[4] * cw[6] * cw[7]
        availability = clamp(eligible / max(1.0, repro), 0.0, 1.0)
        ctx_food = clamp(self.food_security, 0, 1)
        cond = lerp(0.12, 1.08, clamp(self.health, 0, 1)) * lerp(0.10, 1.05, math.sqrt(ctx_food) if SQRT_FOOD_CONCEPTION else ctx_food) * lerp(0.55, 1.03, clamp(housing, 0, 1)) * lerp(0.82, 1.04, clamp(self.cohesion, 0, 1))
        if self.last["intake"] < 0.82 or self.malnutrition > 0.38:
            cond *= 0.06
        cond *= 1.0 + clamp(self.eff("conception_support"), -0.30, 0.30)
        cond = clamp(cond, 0.0, 1.30)
        annual = baseline * cond * availability * clamp(care["conception"], 0.3, 2.0)
        risk = 1.0 + max(0.0, 0.72 - self.health) * 3.2 + max(0.0, 0.58 - ctx_food) * 2.6 + max(0.0, 0.55 - housing) * 1.8
        risk *= 1.0 - clamp(self.eff("maternal_safety"), 0.0, 0.60)
        risk = clamp(risk, 0.72, 5.0) * clamp(care["pregnancy_risk"], 0.5, 2.5)
        f, s, t = self.preg
        losses = np.array([f * 0.00105, s * 0.00024, t * 0.00007]) * risk * days
        to2 = max(0.0, f - losses[0]) * (1 - math.exp(-days / 91.0))
        to3 = max(0.0, s - losses[1]) * (1 - math.exp(-days / 91.0))
        deliveries = max(0.0, t - losses[2]) * (1 - math.exp(-days / 98.0))
        still = clamp(0.018 + (risk - 1.0) * 0.018, 0.010, 0.14)
        live = deliveries * (1.0 - still)
        if ADDITIVE_BIRTH_BURDEN:
            neonatal_care = care["neonatal"] + (care.get("burden") or {}).get("neonatal", 1.0) - 1.0
            maternal_care = care["maternal"] + (care.get("burden") or {}).get("maternal", 1.0) - 1.0
        else:
            neonatal_care = care["neonatal"] * (care.get("burden") or {}).get("neonatal", 1.0)
            maternal_care = care["maternal"] * (care.get("burden") or {}).get("maternal", 1.0)
        neonatal_rate = clamp((0.018 + (risk - 1.0) * 0.025) * (1.0 - clamp(self.eff("neonatal_survival") + self.policy("neonatal_survival"), -0.50, 0.60)) * clamp(neonatal_care, 0.5, 4.0), 0.004, 0.18)
        maternal_rate = clamp((0.0045 + (risk - 1.0) * 0.0065) * (1.0 - clamp(self.eff("maternal_safety"), 0.0, 0.65)) * clamp(maternal_care, 0.5, 4.0), 0.0008, 0.055)
        self.preg = np.maximum(0.0, np.array([f + annual / YEAR * days - losses[0] - to2, s + to2 - losses[1] - to3, t + to3 - losses[2] - deliveries]))
        self.postpartum = max(0.0, self.postpartum + deliveries - self.postpartum * (1 - math.exp(-days / 365.0)))
        neonatal_deaths = live * neonatal_rate
        maternal_deaths = deliveries * maternal_rate
        self.coh[0] += live - neonatal_deaths
        share = self.coh * MATERNAL_W
        self.coh -= share / max(1e-9, share.sum()) * maternal_deaths
        self.coh = np.maximum(self.coh, 0.0)
        self.births += live
        self.deaths += neonatal_deaths + maternal_deaths
        self.neonatal += neonatal_deaths
        self.maternal += maternal_deaths
        # Infant mortality (CivilizationIndicators.infant_mortality_per_1000).
        later = clamp(age_h[0] * cf, 0.0, 0.9)
        self.imr = (neonatal_rate + (1.0 - neonatal_rate) * later) * 1000.0
        self.infant_loss = self.imr / 1000.0
        self._risk = risk
        self._sync()

    # ------------------------------------------------------------------ society
    def _society(self, days: float, labor_eff: float, food: dict) -> dict:
        """ConsequenceEngine.process_day targets and lags."""
        e, p = self.eff, self.p
        pop = max(1.0, self.population)
        able = max(1.0, self.able)
        housing = clamp(self.housing_capacity / pop, 0.15, 1.12)
        food_days = food["food_days"]
        production_ratio = food["production"] / max(0.01, food["need"])
        intake = food["intake"]
        if intake < 0.95:
            self.shortage_days += days
        else:
            self.shortage_days = max(0.0, self.shortage_days - 2.0 * days)
        fs_target = clamp(0.05 + min(1.0, food_days / 45.0) * 0.30 + min(1.15, production_ratio) * 0.25 + intake * 0.18 + food["diet"] * 0.12
                          + self.nutrition_reserve * 0.10 - self.malnutrition * 0.24, 0.02, 0.98)
        self.food_security = lag(self.food_security, fs_target, 0.055, days)
        disease = float(p["disease_pressure"])
        clean_water = e("health_protection") + e("water_safety") * 0.25 - e("disease_exposure") * 0.18
        env_cost = disease * max(0.18, 1.0 - e("sanitation")) * 0.045 + (float(p["cold_pressure"]) * 0.024) * max(0.0, 0.92 - housing)
        shelter = float(p["shelter_bonus"]) * clamp(self.completed / 2.0, 0.0, 1.0)
        h_target = clamp(0.18 + self.food_security * 0.43 + food["diet"] * 0.06 + housing * 0.16 + clean_water + shelter
                         - self.malnutrition * 0.28 - env_cost + self.policy("health_target") + float(p["health_offset"]), 0.02, 0.97)
        self.health = lag(self.health, h_target, 0.022, days)
        stewards = self.able * self.alloc_pct["Administration"] / 100.0
        admin_cov = clamp(stewards / max(1.0, pop * 0.035), 0.0, 1.25)
        heavy = (self.alloc_pct["Food"] + self.alloc_pct["Extraction"] + self.alloc_pct["Construction"]) / 100.0
        work_strain = clamp(heavy, 0.0, 1.0)
        coh_target = clamp(0.24 + self.food_security * 0.26 + housing * 0.15 + admin_cov * 0.20 + e("state_capacity") * 0.08 + e("cohesion") * 0.10
                           + (1.0 - work_strain) * 0.08 + self.policy("cohesion_target") + float(p["cohesion_offset"]), 0.08, 0.96)
        self.cohesion = lag(self.cohesion, coh_target, 0.014, days)
        observers = self.workers("Knowledge")
        inquiry = sum(float(v) for v in self.s_research.values())
        focus_q = 1.0 if inquiry <= max(1, int(observers)) else clamp(observers / max(1.0, inquiry), 0.15, 1.0)
        gain = observers * labor_eff * focus_q / max(3000.0, pop * 92.0) * (1.0 + e("knowledge_rate")) * lerp(0.55, 1.45, self.capacities["knowledge"]) * float(p["knowledge_gain_mult"])
        self.knowledge_metric = clamp(self.knowledge_metric + gain * days + float(self.known.sum()) / 240000.0 * days, 0.0, 1.0)
        makers = self.able * self.alloc_pct["Crafting"] / 100.0
        craft_cov = clamp(makers / max(1.0, pop * 0.05), 0.0, 1.25)
        accessible = min(1.0, (self.day / YEAR / 10.0 * float(p["accessible_deposits_per_decade"])) / 4.0)
        mat_target = clamp(0.05 + craft_cov * 0.38 + accessible * 0.25 + self.knowledge_metric * 0.18 + e("tool_quality") * 0.30 + e("craft_output") * 0.22
                           + (0.08 if self.completed >= 1 else 0.0), 0.02, 0.96)
        self.material = lag(self.material, mat_target, 0.012, days)
        carriers = self.able * self.alloc_pct["Logistics"] / 100.0
        log_target = clamp(0.05 + carriers / max(1.0, pop * 0.08) * 0.55 + self.material * 0.18 + e("haul_capacity") * 0.18 + e("route_speed") * 0.12, 0.03, 0.95)
        self.logistics = lag(self.logistics, log_target, 0.016, days)
        guards = self.able * self.alloc_pct["Defense"] / 100.0
        sec_target = clamp(0.10 + guards / max(1.0, pop * 0.05) * 0.42 + self.cohesion * 0.24 + self.logistics * 0.12 + e("warfare_readiness") * 0.14, 0.04, 0.96)
        self.security = lag(self.security, sec_target, 0.016, days)
        extraction_pressure = self.alloc_pct["Extraction"] / 100.0
        foraging_pressure = max(0.0, self.alloc_pct["Food"] / 100.0 - 0.48)
        resilience = clamp(self.s.site_profile.get("ecological_resilience", 0.5), 0, 1)
        delta = 0.00010 + (resilience - self.ecology) * 0.00018 + self.policy("ecology_delta") - extraction_pressure * 0.00052 - foraging_pressure * 0.00105
        self.ecology = clamp(self.ecology + delta * days, 0.04, 1.0)
        leg_target = clamp(0.12 + self.food_security * 0.26 + self.health * 0.18 + self.cohesion * 0.20 + self.security * 0.10 + admin_cov * 0.10
                           + e("legitimacy") * 0.12 + self.capacities["institutions"] * 0.05 + self.policy("legitimacy_target"), 0.06, 0.96)
        self.legitimacy = lag(self.legitimacy, leg_target, 0.012, days)
        # Housing: builders add places until capacity leads population.
        builders = self.able * self.alloc_pct["Construction"] / 100.0
        if self.housing_capacity < pop * float(p["housing_target_ratio"]):
            self.housing_capacity += builders * labor_eff * float(p["housing_build_rate"]) * (1.0 + e("construction_rate") + e("housing_output")) * days
        # Founding works (Hearth, Lean-to, Open Work Area, Gathering Yard, Storage Pits)
        # finish in the first years; later works follow their discoveries.
        early = min(float(p["founding_works"]), self.day / YEAR * float(p["completed_per_year"]))
        later = sum(1.0 for w in ("Public Stores",) if self.completed_names(w))
        framed = self.cat.index.get("framed_construction")
        if framed is not None and self.known[framed] and self.day - self.discovered_day[framed] >= float(p["build_delay_years"]) * YEAR:
            later += 1.0
        self.completed = min(float(p["completed_max"]), early + later)
        # Mortality components (annual rates).
        mortality = {"Hunger": 0.0, "Illness": max(0.0, 0.50 - self.health) * 0.055 * max(0.35, 1.0 + e("disease_exposure") - e("sanitation"))
                     + disease * max(0.10, 1.0 - e("sanitation")) * 0.005,
                     "Exposure": max(0.0, 0.68 - housing) * 0.040 + (float(p["cold_pressure"]) * 0.018) * max(0.0, 0.92 - housing),
                     "Insecurity": max(0.0, 0.30 - self.security) * 0.025,
                     # Work accidents, dehydration, cold snaps and the other small daily
                     # components the surrogate does not model one by one (fitted).
                     "Other": float(p["other_mortality"])}
        if intake < 0.98 or self.malnutrition > 0.05:
            ramp = clamp((self.shortage_days - 5.0) / 45.0, 0.0, 1.0)
            mortality["Hunger"] = max(0.0, 1.0 - intake) * (0.08 + ramp * 0.90) + self.malnutrition * 0.42
        return {"housing": housing, "mortality": mortality}

    # ----------------------------------------------------------------- research
    def _research(self, days: float) -> list:
        cat, c, p = self.cat, self.c, self.p
        year = self.day / YEAR
        pop = max(1.0, self.population)
        researchers_total = self.workers("Knowledge")
        # Scholarship (discovery_system.gd scholarship_rate).
        staffing = clamp(min(researchers_total / 6.0, researchers_total / pop / 0.03), 0.0, 1.0)
        rate = (0.45 + 0.55 * staffing) * lerp(0.85, 1.2, self.education) * lerp(0.7, 1.0, self.food_security)
        self.scholarship += rate * days / YEAR
        open_mask = self.ready & self.cond_ok & (cat.earliest <= year) & cat.channel_staffable[cat.channel]
        has_candidate = np.bincount(cat.channel[open_mask], minlength=len(cat.channel_keys)) > 0
        # Emphasis units per line sit on subcategory channels and stay there
        # (_auto_allocate_domain_attention). A channel with no open question
        # hands its units to the line's live channels with the fewest
        # (_redistribute_stranded_attention); a live channel left empty takes
        # one unit back from a channel holding two or more
        # (_research_600_return_waiting_attention).
        alloc_key = (has_candidate.tobytes(), tuple(int(self.s_research.get(l, 0)) for l in gd.LINES))
        if alloc_key == getattr(self, "_alloc_key", None):
            weights = self._alloc_weights
        else:
            units_now = self.unit_alloc
            for li, line in enumerate(gd.LINES):
                units = int(self.s_research.get(line, 0))
                chans = self.line_channels[li]
                if len(chans) == 0:
                    continue
                current = units_now[chans]
                live = has_candidate[chans]
                if units <= 0:
                    units_now[chans] = 0
                    continue
                # stranded units move to live channels (fewest first)
                stranded = int(current[~live].sum()) if live.any() else 0
                if live.any():
                    current[~live] = 0
                # emphasis changed: add or remove units
                diff = units - int(current.sum()) - stranded
                pool = stranded + max(0, diff)
                for _ in range(max(0, -diff)):
                    j = int(np.argmax(current))
                    current[j] -= 1
                order = np.where(live)[0] if live.any() else np.arange(len(chans))
                for _ in range(pool):
                    j = order[int(np.argmin(current[order]))]
                    current[j] += 1
                # a live but empty channel takes one unit from a channel with >= 2
                for j in np.where(live & (current == 0))[0]:
                    donor = int(np.argmax(current))
                    if current[donor] >= 2:
                        current[donor] -= 1
                        current[j] = 1
                units_now[chans] = current
            if FOUNDATION_WORK:
                weights = units_now.astype(float)
            else:
                weights = np.where(has_candidate, units_now, 0).astype(float)
            self._alloc_key, self._alloc_weights = alloc_key, weights
        self.channel_weight = weights
        total_weight = max(1.0, weights.sum() + self.study_weight())
        found = []
        food_support = lerp(0.62, 1.08, clamp(self.food_security, 0, 1))
        material_support = lerp(0.72, 1.12, clamp(self.material, 0.0, 1.2) / 1.2)
        support = food_support * material_support * lerp(0.78, 1.18, clamp(self.capacities["institutions"], 0, 1)) * lerp(0.55, 1.45, self.education)
        throughput = float(p["throughput"]) * math.exp(float(p["throughput_growth"]) * year / 100.0)
        known_ext = None
        kr = 1.0 + self.eff("knowledge_rate")
        for ch in np.where(weights > 0)[0].tolist():
            item = self.active[ch]
            cand = None
            if item < 0 or not open_mask[item]:
                items = self.chan_items[ch]
                cand = items[open_mask[items]]
                if len(cand) == 0 and FOUNDATION_WORK:
                    busy = set(self.active[self.active >= 0].tolist())
                    found_ids = [i for i in self._foundation_ids(int(cat.channel_line[ch]), year, open_mask) if i not in busy]
                    if found_ids:
                        self.active[ch] = found_ids[0]
                        item = found_ids[0]
                        cand = None
                if cand is not None and len(cand) == 0:
                    self.active[ch] = -1
                    continue
            if cand is not None and (item < 0 or not open_mask[item]):
                era_cost = np.maximum(0.0, cat.era[cand] - self.scholarship - self.tune_window) / self.tune_doubling
                score = self.affinity[cand] + self.signal_score[cand] + weights[ch] * 8.0 - era_cost * 20.0 + self.targets[cand] * 1e5
                item = int(cand[np.argmax(score)])
                self.active[ch] = item
            researchers = researchers_total * weights[ch] / total_weight
            team = researchers if researchers < 1.0 else 1.0 + math.log10(researchers) * 0.78
            attention = team * support * (1.0 + (self.art_bonus_for(gd.LINES[cat.channel_line[ch]]) if self.art["tier"] else 0.0))
            precedent = 1.0
            if cat.has_precedents[item]:
                if known_ext is None:
                    known_ext = np.concatenate([self.known, [False, False]])
                precedent = min(c.precedent_cap, 1.0 + c.precedent_bonus * float(known_ext[cat.precedents[item]].sum()))
            difficulty = self.cost_draw[item] * 2.0 ** min(30.0, max(0.0, cat.era[item] - self.scholarship - self.tune_window) / self.tune_doubling) / precedent
            prob = cat.chance[item] / difficulty * attention * self.item_activity[item] * self.evidence[item] * throughput * self.tune_pace \
                * kr * 0.12 * 1.0055
            noise = 1.0 + self.rng.normal(0.0, 0.16 / math.sqrt(max(1.0, days)))
            self.progress[item] += prob * days * noise
            if self.progress[item] >= 1.0:
                found.append(item)
                self.active[ch] = -1
        for item in found:
            self._learn(item)
        return found

    def _foundation_ids(self, line: int, year: float, open_mask: np.ndarray) -> list:
        """Open prerequisites (down to researchable ones, depth <= 8) of the line's
        era-open unknown questions, earliest design day first."""
        key = (line, int(self.known.sum()), int(year))
        cache = self.__dict__.setdefault("_foundation_cache", {})
        if key in cache:
            return cache[key]
        cat = self.cat
        n = cat.n
        frontier = []
        pending = np.where((cat.line == line) & ~self.known & (cat.earliest <= year) & self.cond_ok)[0]
        for i in pending.tolist():
            frontier.extend(self._missing_parents(i))
        found, visited, depth = {}, set(), 0
        while frontier and depth < 8:
            nxt = []
            for j in frontier:
                if j in visited or j >= n or self.known[j]:
                    continue
                visited.add(j)
                if not (cat.earliest[j] <= year and self.cond_ok[j]):
                    continue
                if open_mask[j]:
                    found[j] = cat.era[j]
                else:
                    nxt.extend(self._missing_parents(j))
            frontier = nxt
            depth += 1
        ids = sorted(found, key=lambda j: found[j])
        if len(cache) > 256:
            cache.clear()
        cache[key] = ids
        return ids

    def _missing_parents(self, i: int) -> list:
        cat = self.cat
        n = cat.n
        out = [int(j) for j in cat.req_all[i] if j < n and not self.known[j]]
        for gi in np.where(cat.any_owner == i)[0].tolist():
            group = [int(j) for j in cat.any_groups[gi] if j < n]
            if not any(self.known[j] for j in group):
                out.extend(group)
        return out

    def _learn(self, item: int) -> None:
        self.known[item] = True
        self.ready[item] = False
        self.adoption[item] = max(0.025, self.adoption[item])
        self.discovered_day[item] = self.day
        self.progress[item] = 0.0
        if len(self.children[item]):
            self._refresh_ready(self.children[item])

    # ---------------------------------------------------------------- artifacts
    def study_weight(self) -> int:
        """ArtifactCollection.study_role weight (0..MAX_STUDY_WEIGHT), part of the
        shared research emphasis budget."""
        if self.s.study_rule == "ai":
            return 1 if any(x < 1.0 for x in self.art["study"]) else 0
        return int(min(self.s.study_weight, int(self.c.art["MAX_STUDY_WEIGHT"])))

    def art_bonus_for(self, line: str) -> float:
        raw = (self.art_bonus["culture"] if line == "culture" else self.art_bonus["science"]) + float(self.art_family[gd.LINES.index(line)])
        if ART_ERA_BONUS_SHARE > 0:
            raw = min(raw, self._knowledge_rate_cap * ART_ERA_BONUS_SHARE)
        return raw

    def _add_piece(self, tier: int, set_id: str | None, set_size: int, seeded: bool = False) -> None:
        a = self.art
        k = self.c.art
        work = 160.0 if tier == 4 else 20.0 + tier * 20.0
        lean = np.array([0.5, 0.5, 0.5])
        # AC.channels: one object word (+.6), one motif word (+.3), family lean.
        if self.rng.random() < 0.8:
            lean[self.rng.integers(3)] += 0.6
        if self.rng.random() < 0.6:
            lean[self.rng.integers(3)] += 0.3
        family = int(self.rng.integers(len(gd.LINES)))
        fam = gd.LINES[family]
        if fam == "culture":
            lean[0] += 0.7
        elif fam == "knowledge":
            lean[1] += 0.7
        elif fam in ("production", "labor", "logistics", "infrastructure", "nutrition"):
            lean[2] += 0.35
            lean[1] += 0.35
        else:
            lean[1] += 0.5
        a["tier"].append(tier)
        a["work"].append(work)
        a["study"].append(0.0)
        a["held"].append(0.0)
        a["set"].append(set_id)
        a["set_size"].append(set_size)
        a["lean"].append(lean / lean.sum())
        a["family"].append(family)
        a["seeded"].append(seeded)
        if set_id:
            self.art_sets[set_id] = self.art_sets.get(set_id, 0) + 1

    def seed_finds(self) -> None:
        """Mirror of truth_probe.gd _seed_finds: a legendary set of 3 + two site pieces."""
        for i in range(3):
            self._add_piece(4 if i == 2 else 2, "legend:0", 3, seeded=True)
        for i in range(2):
            self._add_piece(1 if self.rng.random() < 0.85 else 2, f"site:{i}", 3 + int(self.rng.integers(4)), seeded=True)

    def _artifacts(self, days: float) -> None:
        k, p = self.c.art, self.p
        pop = max(1.0, self.population)
        # --- finds by scouting parties (society_exchange.gd sample_ground)
        if self.s.scouting > 0 and self.stored_days > 7.0:
            scouts = pop * self.s.scouting
            parties = scouts / max(2.0, float(p["party_size"]))
            trips = parties * days / float(p["trip_days"])
            carry = max(1.0, float(p["party_size"]) / 2.0)
            cells = trips * float(p["cells_per_trip"])
            new_ground = math.exp(-self.art_explored / float(p["explored_area_cells"]))
            self.art_explored += cells
            site_p = (float(k["SITE_CHANCE"]) / 1000.0) * 9.0 / float(k["REGION"]) ** 2 * self.art_sites_left
            scatter_p = float(p["ground_density"]) * self.art_sites_left
            legend_p = float(k["LEGEND_COUNT"]) / float(p["legend_reach_cells"])
            expected = cells * new_ground * (site_p * 1.0 + (1.0 - site_p) * scatter_p)
            finds = min(int(self.rng.poisson(max(0.0, expected))), int(trips * carry + 0.999))
            st = k["scatter_tiers"]
            for _ in range(finds):
                if self.rng.random() < site_p / max(1e-9, site_p + (1 - site_p) * scatter_p):
                    roll = self.rng.integers(1000)
                    tier = 3 if roll >= k["site_tiers"][1] else 2 if roll >= k["site_tiers"][3] else 1
                    self._add_piece(tier, f"site:{len(self.art_sets)}", 3 + int(self.rng.integers(4)))
                else:
                    roll = self.rng.integers(1000)
                    tier = 3 if roll >= st[3] else 2 if roll >= st[5] else 1 if roll >= st[7] else 0
                    self._add_piece(tier, None, 1)
            if self.rng.random() < 1.0 - math.exp(-cells * new_ground * legend_p / 400.0):
                for i in range(3):
                    self._add_piece(4 if i == 2 else 2, f"legend:{self.rng.integers(1_000_000)}", 3)
            self.art_sites_left = max(0.0, self.art_sites_left * (1.0 - float(p["rival_claim_rate"]) * days / YEAR))
        a = self.art
        if not a["tier"]:
            return
        # --- study (ArtifactCollection.study_capacity / study)
        weight = self.study_weight()
        total = max(1.0, self.channel_weight.sum() + weight)
        researchers = self.workers("Knowledge") * weight / total if weight > 0 else 0.0
        pool = researchers * lerp(0.55, 1.45, self.education) * float(k["STUDY_RATE"]) * clamp(self.last["intake"], 0, 1) * days
        for i in range(len(a["tier"])):
            a["held"][i] += days
            if pool > 0 and a["study"][i] < 1.0:
                used = min(pool, (1.0 - a["study"][i]) * a["work"][i])
                pool -= used
                a["study"][i] = min(1.0, a["study"][i] + used / a["work"][i])
        # --- summary (prestige, values, bonuses)
        prestige_total = research_value = culture_value = 0.0
        family = np.zeros(len(gd.LINES))
        effective = 0.0
        for i in range(len(a["tier"])):
            size = a["set_size"][i]
            sf = 1.0
            if a["set"][i] and size > 1:
                held = min(size, max(1, self.art_sets.get(a["set"][i], 1)))
                sf = 1.0 + float(k["set_step"]) * (held - 1) / (size - 1) + (float(k["set_complete"]) if held >= size else 0.0)
            worth = float(k["prestige_base"]) ** a["tier"][i] * (1.0 + math.log(1.0 + a["held"][i] / 360.0)) * sf
            prestige_total += worth
            if a["study"][i] >= 1.0:
                lean = a["lean"][i]
                culture_value += worth * 3.0 * lean[0]
                research_value += worth * 3.0 * lean[1]
                family[a["family"][i]] += worth * 3.0 * lean[1]
                effective += worth
            else:
                effective += worth * float(k["RAW_SHARE"]) * 0.8
        self.art_bonus = {"science": math.log(1.0 + prestige_total * float(k["RAW_SHARE"]) + research_value) * float(k["science_scale"]),
                          "culture": math.log(1.0 + prestige_total * float(k["RAW_SHARE"]) + culture_value) * float(k["culture_scale"])}
        self.art_family = np.minimum(float(k["FAMILY_CAP"]), np.log1p(family) * float(k["family_rate"]))
        self.art_prestige = prestige_total
        # --- allure (ArtifactCulture.allure_report)
        collection = float(k["ALLURE_COLLECTION"]) * (1.0 - math.exp(-effective / float(k["COLLECTION_SCALE"])))
        works = min(float(k["ALLURE_WORKS"]), float(p["works_allure"]))
        self.allure = clamp(collection + float(k["ALLURE_CULTURE"]) * self.capacities["culture"] + float(k["ALLURE_VALUES"]) * float(p["openness"]) + works, 0.0, 1.0)

    # --------------------------------------------------------------------- run
    def research_policy(self, year: float) -> dict:
        if self.s.phases:
            phase = [ph for ph in self.s.phases if float(ph.get("from", 0)) <= year + 1e-9][-1]
            self.active_knowledge_share = float(phase.get("knowledge_share", self.s.knowledge_share))
            return phase.get("research", self.s.research)
        self.active_knowledge_share = self.s.knowledge_share
        if not self.s.ai:
            return self.s.research
        # AI-like: CivilizationController leans toward what hurts (food, health,
        # security) with a floor on every line.
        # CivilizationController (truth runs): 4 emphasis units, re-chosen every
        # few years: knowledge and production almost always, infrastructure
        # early then logistics, and one rotating unit (nutrition while food is
        # short, otherwise demography/culture/ecology/labor/health/nutrition).
        period = int(year // 5)
        cache = self.__dict__.setdefault("_ai_plan", {})
        if period not in cache:
            r = np.random.default_rng((self.seed * 7349 + period) & 0xFFFFFFFF)
            w = dict.fromkeys(gd.LINES, 0)
            w["knowledge"] = 1
            w["production"] = 1
            w["infrastructure" if year < 25 else "logistics"] = 1
            if self.food_security < 0.9 and year < 25:
                w["nutrition"] += 1
            else:
                pick = r.choice(["demography", "culture", "nutrition", "ecology", "labor", "health", "production", "knowledge", "infrastructure"],
                                p=[0.2, 0.15, 0.12, 0.08, 0.08, 0.05, 0.14, 0.1, 0.08])
                w[str(pick)] += 1
            cache[period] = w
        return cache[period]

    def run(self, years: int, record_every: float = 1.0) -> dict:
        p = self.p
        self.phase_a = float(abs(self.seed * 31) % 997)
        self.phase_b = float(abs(self.seed * 73) % 991)
        self.births = self.deaths = self.neonatal = self.maternal = 0.0
        self.imr = 0.0
        self.evidence = np.ones(self.cat.n)
        self.s_research = self.research_policy(0.0)
        self._conditions(0.0)
        sub = int(p["substeps_per_month"])
        rows = []
        months = int(years * 12)
        next_record = 0.0
        hearth = False
        for m in range(months + 1):
            year = self.day / YEAR
            if year + 1e-9 >= next_record:
                rows.append(self.snapshot())
                next_record += record_every
            if m == months:
                break
            if m % 12 == 0:
                self.s_research = dict(self.research_policy(year))
                self._conditions(year)
            if not hearth and self.completed >= 1.0:
                hearth = True
                self._activity(self.ctx, hearth=True)
            self._allocate_labor()
            heavy = (self.alloc_pct["Food"] + self.alloc_pct["Extraction"] + self.alloc_pct["Construction"]) / 100.0
            overwork = clamp(clamp((heavy - 0.74) / 0.22, 0, 1) * 0.7 + (0.5 if "labor_mobilization" in self.s.policies else 0.0), 0.0, 1.0)
            care = self._care(overwork)
            days = MONTH / sub
            for _ in range(sub):
                pop = max(1.0, self.population)
                housing = clamp(self.housing_capacity / pop, 0.15, 1.12)
                labor_eff = clamp(0.34 + self.health * 0.34 + self.cohesion * 0.18 + housing * 0.12, 0.25, 1.08)
                labor_eff *= lerp(0.82, 1.08, clamp(self.capacities["labor"], 0, 1)) * (1.0 + self.policy("labor_multiplier"))
                labor_eff = clamp(labor_eff, 0.20, 1.12)
                self.labor_eff = labor_eff
                food = self._food(days, labor_eff)
                soc = self._society(days, labor_eff, food)
                self._demography(days, soc["housing"], care, soc["mortality"])
                self.mortality = soc["mortality"]
                self.day += days
            if self.s.seed_finds_day >= 0 and self.day - MONTH < self.s.seed_finds_day <= self.day:
                self.seed_finds()
            self._adoption(MONTH)
            self._effects_update()
            self._capacities()
            self._research(MONTH)
            self._artifacts(MONTH)
        return {"rows": rows, "discoveries": self.discovery_list()}

    def discovery_list(self) -> list:
        order = np.argsort(self.discovered_day)
        return [[float(self.discovered_day[i]), self.cat.ids[i], self.cat.rows[i]["line"]] for i in order if self.discovered_day[i] >= 0]

    def snapshot(self) -> dict:
        pop = self.population
        cf = getattr(self, "_cf", self._condition_factor(1.0))
        age_h = getattr(self, "_age_h", self.c.hazard_by_age)
        mort = getattr(self, "mortality", {"Hunger": 0, "Illness": 0, "Exposure": 0, "Insecurity": 0})
        exceptional = sum(mort.values())
        per_line = np.bincount(self.cat.line[self.known], minlength=len(gd.LINES))
        e = self.eff
        a = self.art
        h14 = np.clip(age_h[1:5] * cf + exceptional, 0.0001, 0.98)
        child_1_4 = (1.0 - float(np.prod(1.0 - h14))) * 1000.0
        women = 0.5 * (self.coh[1] * 10.0 / 11.0 + self.coh[2] + self.coh[3])
        return {
            "year": round(self.day / YEAR, 3), "population": pop, "child_mortality_1_4": child_1_4, "women_15_45": float(women),
            "food_share": self.alloc_pct["Food"], "defense_share": self.alloc_pct["Defense"], "knowledge_share": self.alloc_pct["Knowledge"], "cohorts": dict(zip(COH, self.coh.round(2).tolist())),
            "life_expectancy": self.life_expectancy(age_h, cf, exceptional), "infant_mortality": getattr(self, "imr", 0.0),
            "health": self.health, "food_security": self.food_security, "food_days": self.stored_days, "intake": self.last["intake"],
            "diet": self.last["diet"], "malnutrition": self.malnutrition, "births": self.births if hasattr(self, "births") else 0.0,
            "deaths": getattr(self, "deaths", 0.0), "neonatal": getattr(self, "neonatal", 0.0), "maternal": getattr(self, "maternal", 0.0),
            "alloc": dict(self.alloc_pct), "knowledge_workers": self.workers("Knowledge"), "scholarship": self.scholarship, "education": self.education,
            "knowledge_metric": self.knowledge_metric, "material_capacity": self.material, "cohesion": self.cohesion, "legitimacy": self.legitimacy,
            "security": self.security, "logistics": self.logistics, "ecology": self.ecology, "housing_ratio": clamp(self.housing_capacity / max(1.0, pop), 0.15, 1.12),
            "labor_efficiency": getattr(self, "labor_eff", 0.0), "capacities": dict(self.capacities), "known": int(self.known.sum()),
            "per_line": {gd.LINES[i]: int(v) for i, v in enumerate(per_line)}, "ceiling_era": self.ceiling_era,
            "effects": {k: float(v) for k, v in zip(self.cat.effect_keys, self.effects) if abs(v) > 5e-5},
            "harvest": {k: float(v) for k, v in self.last["harvest"].items()}, "need": self.last["need"],
            "food_per_worker": self.last["production"] / max(1.0, self.workers("Food")),
            "source_health": dict(self.source_health), "settlements": self.settlements, "completed": self.completed,
            "artifacts": {"count": len(a["tier"]), "studied": int(sum(1 for s in a["study"] if s >= 1.0)), "study_sum": float(sum(a["study"])),
                          "prestige": float(getattr(self, "art_prestige", 0.0)), "science": self.art_bonus["science"], "culture": self.art_bonus["culture"],
                          "research_bonus": self.art_bonus_for("knowledge"), "allure": self.allure,
                          "diplomacy": self.allure * float(self.c.art["DIPLOMACY_MAX"]), "migration": max(0.0, self.allure - float(self.p["works_allure"])) * float(self.c.art["MIGRATION_MAX"]),
                          "museum_draw": 1.0 + self.allure * float(self.c.art["MUSEUM_ALLURE"])},
            "state_capacity": e("state_capacity"), "tool_quality": e("tool_quality"), "craft_output": e("craft_output"),
            "construction_rate": e("construction_rate"), "trade_capacity": e("trade_capacity"), "warfare_readiness": e("warfare_readiness"),
        }
