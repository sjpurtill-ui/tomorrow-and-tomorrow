"""Surrogate of Tomorrow and Tomorrow's civilization engine for fast balancing.

One aggregate society, stepped monthly (research, adoption, effects, capacities,
artifacts) with ``substeps_per_month`` demography/food sub-steps using the
engine's daily rates. Every formula names its GDScript source; numeric
constants are parsed from the game where feasible (gamedata.py / gdparse.py),
and the rest live in params.json.

People first (docs/PEOPLE_FIRST.md): the leaders' daily work by focus, the
people's ambition and the path (work_paths.gd, learning cap included), the
ruler's own split with the leader's food guard, searched land and cutting,
one raw-materials stock, making as the engine does it (homes, barter, arms
first), the watch as the army (drill, arms, standing might) and new towns.

What it deliberately omits (see docs/research/SURROGATE_SIM.md): individual
people and officials, geography/terrain, rivals and diplomacy, war, trade and
the money economy, construction projects and buildings as objects (buildings are
a count), per-resource stockpiles (one raw-materials stock stands in), water
logistics, policies other than the scenario knobs, the civic court and decrees.
"""
from __future__ import annotations

import hashlib
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
# The most of the people at work a path puts on learning (work_paths.gd
# LEARNING_CAP; the inquiry ambition raises it by INQUIRY_CAP x its share).
# The leaders' own split (no focus set by hand) is capped.
LEARNING_CAP = g.const("scripts/work_paths.gd", "LEARNING_CAP", default={}, optional=True)
INQUIRY_CAP = float(g.const("scripts/work_paths.gd", "INQUIRY_CAP", default=0.0, optional=True))
LABOR_EXTRAS = g.literal_after("scripts/food_system.gd", "var extras:=", default={"Food": 0.17, "Extraction": 0.18, "Construction": 0.18, "Defense": 0.12, "Survey": 0.13, "Logistics": 0.14, "Crafting": 0.08, "Knowledge": 0.04, "Administration": 0.04})
# Optional Phase 3 pre-modern burden (early_life_conditions.gd); absent -> 1.
# fun-pop: pregnancies under way at founding (game_state.gd initialize_population_model).
# Named officials' deaths are charged to the natural-death accumulator in the engine
# (government_people_system.gd _register_named_death), so the surrogate needs no separate
# term for them; the fitted other_mortality/disease_pressure absorbed the old double
# count and should fall when the truth runs are regenerated.
FOUNDING_PREGNANCY_SHARE = float(g.const("scripts/game_state.gd", "FOUNDING_PREGNANCY_SHARE", default=0.0, optional=True))
ERA_BURDEN = g.const("scripts/early_life_conditions.gd", "ERA_BURDEN", default={}, optional=True)
EXCESS_WEIGHT = g.const("scripts/early_life_conditions.gd", "EXCESS_WEIGHT", default={}, optional=True)
RELIEF_CHANNELS = g.const("scripts/early_life_conditions.gd", "RELIEF_CHANNELS", default={}, optional=True)
RELIEF_POWER = float(g.const("scripts/early_life_conditions.gd", "RELIEF_POWER", default=1.5, optional=True))
MODERN = {k: float(g.const("scripts/early_life_conditions.gd", k, default=0.0, optional=True))
          for k in ("MODERN_BURDEN_LIFT", "MODERN_TABLE_ONSET", "MODERN_TABLE_FULL", "MODERN_TABLE_DEPTH", "MODERN_SURVIVAL_LIMIT")}
SURPLUS_RELEASE = {k: float(g.const("scripts/government_people_system.gd", k, default=0.0, optional=True))
                   for k in ("SURPLUS_RELEASE_DAYS", "SURPLUS_RELEASE_MARGIN", "RESERVE_TARGET_DAYS", "RESERVE_MARGIN")}
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
FOOD_FLOOR_OF_TYPICAL = float(g.const("scripts/government_people_system.gd", "FOOD_FLOOR_OF_TYPICAL", default=1.0, optional=True))
SPECIALIZATION_HEADROOM = float(g.const("scripts/society_model.gd", "SPECIALIZATION_HEADROOM", default=0.0, optional=True))
EFFECT_LINE = g.const("scripts/society_model.gd", "EFFECT_LINE", default={}, optional=True)
INFANT_LOSS_REPLACEMENT = float(g.const("scripts/early_life_conditions.gd", "INFANT_LOSS_REPLACEMENT", default=2.6, optional=True))
SPECIALIZATION_NEGLECT = float(g.const("scripts/society_model.gd", "SPECIALIZATION_NEGLECT", default=0.0, optional=True))
# Birth-care burden adds to the missing-care excess (EarlyLifeConditions.neonatal_factor).
ADDITIVE_BIRTH_BURDEN = "float(care.get(\"neonatal\",1.0))+float((care.get(\"burden\"" in g.source("scripts/early_life_conditions.gd")
# Chronic shortfall lowers conception through sqrt(food) (GameState._conception_condition_factor).
SQRT_FOOD_CONCEPTION = "lerpf(0.10,1.05,sqrt(food))" in g.source("scripts/game_state.gd")
# research_3000 modern transition (early_life_conditions.gd, game_state.gd, civilization_indicators.gd).
MODERN_SURVIVAL_WEIGHT = g.const("scripts/early_life_conditions.gd", "MODERN_SURVIVAL_WEIGHT", default={}, optional=True)
TRANSITION = {k: float(g.const("scripts/early_life_conditions.gd", k, default=0.0, optional=True))
              for k in ("TRANSITION_URBAN", "URBAN_ONSET", "TRANSITION_SCHOOLING", "LITERACY_ONSET", "TRANSITION_MAX")}
URBAN = {k: float(g.const("scripts/civilization_indicators.gd", k, default=0.0, optional=True))
         for k in ("URBAN_SCALE", "URBAN_POWER", "URBAN_MIN_POPULATION", "URBAN_FULL_POPULATION_SPAN")}
# GameState.process_reproduction_day newborn/maternal clamps: (care low, rate floor).
MODERN_BIRTH_CLAMPS = "\"neonatal_care\",1.0)),0.1,4.0),0.0008,0.18)" in g.source("scripts/game_state.gd")
NEONATAL_CLAMP = (0.1, 0.0008) if MODERN_BIRTH_CLAMPS else (0.5, 0.004)
# Fresh food, small stores, keepers and carers (food_care.gd; docs/PEOPLE_FIRST.md B).
# The defaults are the rules before it: food security counted 45 days of store.
FOOD_CARE = {k: float(g.const("scripts/food_care.gd", k, default=d, optional=True)) for k, d in {
    "LEAN_DAYS": 45.0, "LEAN_WEIGHT": 0.30, "FRESH_HEALTH": 0.0, "FRESH_PENALTY": 0.0, "FRESH_EVEN": 0.5, "CARRY_SHARE": 0.03, "CARRY_FRESH_CUT": 0.0,
    "CARRY_REACH": 0.0, "KEEP_SHARE": 0.02, "KEEP_STORED_CUT": 0.0, "CARE_SHARE": 0.04, "CARE_HEALTH": 0.0, "CARE_SETTLE_DAYS": 60.0}.items()}
CARER_COVER = g.const("scripts/early_life_conditions.gd", "CARER_COVER", default={}, optional=True)
CARER_BURDEN = g.const("scripts/early_life_conditions.gd", "CARER_BURDEN", default={}, optional=True)
# Deaths and sickness read what is eaten (the store counted full): GameState.fed_security.
FED_SECURITY = "func fed_security()" in g.source("scripts/game_state.gd")
# Planners draw stores past the reserve back down and release at it (GovernmentPeopleSystem).
LEAN_DRAW = "if bool(guard.food):reserve_gap=maxf(0.0,reserve_gap)" in g.source("scripts/government_people_system.gd")
MATERNAL_CLAMP = (0.02, 0.00002) if MODERN_BIRTH_CLAMPS else (0.5, 0.0008)
FERTILITY_TRANSITION = "context.get(\"fertility_transition\"" in g.source("scripts/game_state.gd")
# Research parity (one rule for every ruler): emphasis is shares. Research600
# ATTENTION_STEPS / RESEARCH_TEAMS present -> the community's whole work comes
# from its researchers alone (team_capacity) and each staffed channel does its
# team strength's part of it (team_strength over all channels' strength); the
# rules that counted emphasis steps read shares on the common scale; the keepers
# a plan asks for follow the lines it covers; specialization neglect is zero-sum;
# and computer rulers plan in the player's 0-12 steps. Absent -> the older rules.
ATTENTION_STEPS = float(g.const("scripts/research_600_catalog.gd", "ATTENTION_STEPS", default=0.0, optional=True))
RESEARCH_TEAMS = float(g.const("scripts/research_600_catalog.gd", "RESEARCH_TEAMS", default=0.0, optional=True))
# Learning without a cap (docs/PEOPLE_FIRST.md A): Research600.QUESTION_EXPONENT
# present -> every learner counts (team_capacity = teams_at x team_strength of
# each team's people, scaled so the normal share keeps normal_work), the teams
# grow without TEAMS_MAX, and a people keeping more learners than its age can
# spare earns a lead over the calendar (LEAD_YEARS_PER_DOUBLING): its questions
# are dated, its scholarship counted and its payoffs capped from calendar + lead.
QUESTION_EXPONENT = float(g.const("scripts/research_600_catalog.gd", "QUESTION_EXPONENT", default=0.0, optional=True))
UNCAPPED = QUESTION_EXPONENT > 0.0
NORMAL = {k: float(g.const("scripts/research_600_catalog.gd", k, default=0.0, optional=True))
          for k in ("LEARNER_PACE", "LEAD_YEARS_PER_DOUBLING", "LEAD_FALL_DOUBLINGS")}
PARITY = ATTENTION_STEPS > 0.0 and (RESEARCH_TEAMS > 0.0 or UNCAPPED)
# Learners use goods (Research600.LEARNER_DAYS_PER_GOOD present): a goods-unit
# per LEARNER_DAYS_PER_GOOD learner-days, taken before the makers' day; makers
# (civilian_goods.gd) keep households' target x 1.2 plus the learners' need for
# the next step; short of goods, learning goes at GOODS_FLOOR + the rest x cover,
# and households' techniques work as far as the stock covers their target.
# Raw materials are taken as on hand (the surrogate keeps no raw stocks).
LEARNER_GOODS = {k: float(g.const("scripts/research_600_catalog.gd", k, default=0.0, optional=True))
                 for k in ("LEARNER_DAYS_PER_GOOD", "GOODS_FLOOR", "LEAD_GOODS_YEARS", "LEAD_UPKEEP_YEARS")}
GOODS_MODEL = LEARNER_GOODS["LEARNER_DAYS_PER_GOOD"] > 0.0
# Research600.AGE_WORK_BY_YEAR: each age's questions ask the work of the
# learners a people of that age usually keeps (absent -> 1).
AGE_WORK = g.const("scripts/research_600_catalog.gd", "AGE_WORK_BY_YEAR", default=[], optional=True) or []
GOODS_K = {k: float(g.const("scripts/civilian_goods.gd", k, default=0.0, optional=True))
           for k in ("BASE_TARGET_PER_PERSON", "DAILY_WEAR", "CRAFT_SHARE", "BASE_RATE", "TECHNIQUE_OUTPUT")}
GOODS_TARGETS = g.const("scripts/civilian_goods.gd", "TARGET_PER_PERSON", default={}, optional=True) or {}
REPLAN_STEPS = float(g.const("scripts/civilization_controller.gd", "REPLAN_STEPS", default=0.0, optional=True))

# --- People first: the leaders' work, paths, land, making, arms and the watch ----
# GovernmentPeopleSystem._allocations_for_focus: the people's ambitions' labor
# bias (cultural_inheritance.gd WORK; Food becomes a deeper reserve), the path's
# lean (work_paths.gd WORK, each role the larger of the two asks), its food
# reserve (FOOD_LEAN) and its learning cap (cap_learning).
AMBITION_WORK = g.const("scripts/cultural_inheritance.gd", "WORK", default={}, optional=True) or {}
PATH_WORK = g.const("scripts/work_paths.gd", "WORK", default={}, optional=True) or {}
PATH_FOOD_LEAN = g.const("scripts/work_paths.gd", "FOOD_LEAN", default={}, optional=True) or {}
RESERVE_FOOD_WISH = float(g.const("scripts/government_people_system.gd", "RESERVE_FOOD_WISH", default=12.0, optional=True))
# GovernmentPeopleSystem._ruler_split_fed: under the ruler's own split the town's
# leader puts more on food while the food alarm is up, until RULER_RELEASE_DAYS.
RULER_FED = "func _ruler_split_fed" in g.source("scripts/government_people_system.gd")
RULER = {k: float(g.const("scripts/government_people_system.gd", k, default=d, optional=True)) for k, d in {
    "RULER_RELEASE_DAYS": 45.0, "FOOD_CEILING_SHARE": 85.0, "RESERVE_TARGET_DAYS": 30.0, "RESERVE_MARGIN": 0.15}.items()}
# resource_system.gd searched land (land_step, land_yield) and the cutters' day.
LAND = {k: float(g.const("scripts/resource_system.gd", "LAND_" + k, default=d, optional=True)) for k, d in {
    "PEOPLE_PER_SEARCHER": 60.0, "RISE_YEAR": 0.45, "RISE_MAX": 0.9, "SAG_YEAR": 0.05, "YIELD_BASE": 0.75, "YIELD_SPAN": 0.5,
    "FIND_RATE": 0.016}.items()}
LAND["HALF"] = 2.0 / 3.0 if "const LAND_HALF:=2.0/3.0" in g.source("scripts/resource_system.gd") else float(g.const("scripts/resource_system.gd", "LAND_HALF", default=2.0 / 3.0, optional=True))
SURVEY_COVER = "func land_yield_factor" in g.source("scripts/resource_system.gd")
_PROFILES = g.const("scripts/resource_system.gd", "MATERIAL_PROFILES", default={}, optional=True) or {}
_MINERAL = g.const("scripts/resource_system.gd", "MINERAL_PROFILE", default={"base_yield": 0.24, "loss": 0.00015}, optional=True)
# civilian_goods.gd: making for the homes, then for barter up to ceiling(), from a basket of materials.
GOODS_X = {k: float(g.const("scripts/civilian_goods.gd", k, default=d, optional=True)) for k, d in {
    "SPECIALIZATION": 0.0, "MAKERS_START": 0.05, "MAKERS_FULL": 0.20, "HOLD_MORE": 0.0, "SURPLUS_PER_HEAD": 0.0,
    "RAW_PER_UNIT": 0.16, "REFERENCE_EFFICIENCY": 0.8}.items()}
GOODS_BASKET = g.const("scripts/civilian_goods.gd", "BASKET", default={"Fiber Plants": .32, "Timber": .30, "Clay": .18, "Stone": .12, "Flint": .08}, optional=True)
# What one cutter brings in at base, over the makers' basket (MATERIAL_PROFILES base_yield).
BASKET_YIELD = sum(float(w) * float(_PROFILES.get(r, _MINERAL).get("base_yield", 0.24)) for r, w in GOODS_BASKET.items()) / max(1e-9, sum(float(w) for w in GOODS_BASKET.values()))
PRICES = g.const("scripts/economy_system.gd", "BASE_VALUES", default={"Food": 1.0, "Civilian Goods": 6.0, "Arms": 48.0}, optional=True)
# weapons_stock.gd: arms for one fighter a set, made first while the watch lacks them.
ARMS_AGES = g.const("scripts/weapons_stock.gd", "AGES", default=[], optional=True) or []
ARMS_SHARE = float(g.const("scripts/weapons_stock.gd", "ARMS_SHARE", default=0.2, optional=True))
ARMS_WEAR_DAY = float(_MINERAL.get("loss", 0.00015))   # the store's mineral rate (weapons_stock.gd header)
# watch_military.gd / MilitaryCampaign: the watch is the army; drill closes on
# _training_quality (levy 0.48, line foot 0.58, + command 0.5 x 0.12 + drill
# practices) x (0.72 + 0.28 armed), a little more for a people given to war.
WATCH = {k: float(g.const("scripts/watch_military.gd", k, default=d, optional=True)) for k, d in {
    "MARTIAL_FROM": 0.05, "MARTIAL_FULL": 0.20, "MARTIAL_DRILL": 0.0, "MARTIAL_PACE": 0.0, "START_DRILL": 0.25}.items()}
WARRIOR_WEIGHT = float(g.const("scripts/standing.gd", "WARRIOR_WEIGHT", default=3.0, optional=True))
LEVY_TRAINING_DAYS = 45.0   # military_unit_catalog.gd training_days: max(45, 7 x 3)
# civilization_strategy.gd expansion (leaders.py _expansion): one more good site
# known every SITE_YEARS; a founding party of max(40, 2 %) leaves 80 at least.
ESTABLISHMENT_DAYS = float(g.const("scripts/civilization_strategy.gd", "ESTABLISHMENT_DAYS", default=30.0, optional=True))
SITE_YEARS = 30.0
# Surrogate stand-ins (not engine numbers; docs/research/SURROGATE_SIM.md):
RAW_START = 60.0          # founding manifest of timber and fibre
RAW_PER_HEAD_HELD = 6.0   # the yards hold about this much a head; the rest stays at the source
BUILD_DRAW = 0.02         # loads a builder uses a day (homes and works)


def team_strength(researchers: float) -> float:
    """Research600.team_strength: in full up to one person, then people^
    QUESTION_EXPONENT (uncapped) or 1 + 0.78 log10(people) (the older rule)."""
    if researchers < 1.0:
        return max(0.0, researchers)
    if UNCAPPED:
        return researchers ** QUESTION_EXPONENT
    return 1.0 + math.log10(researchers) * 0.78


def teams_at(researchers: float) -> float:
    """Research600.teams_at: team_count before rounding (at least one)."""
    if researchers <= 0.0:
        return 1.0
    return max(1.0, TEAMS["TEAMS_BASE"] + TEAMS["TEAMS_PER_TENFOLD"] * math.log10(researchers / TEAMS["TEAMS_REF"]))


def learners_work(researchers: float) -> float:
    """Research600.learners_work: teams_at teams, each at team_strength."""
    if researchers <= 0.0:
        return 0.0
    teams = teams_at(researchers)
    return teams * team_strength(researchers / teams)


def team_capacity(researchers: float) -> float:
    """Research600.team_capacity: the whole community's work from the number of
    its learners alone (uncapped: no knee, never the people's size; the older
    rule's knee otherwise)."""
    if UNCAPPED:
        return learners_work(researchers) * (NORMAL["LEARNER_PACE"] or 1.0)
    if researchers <= RESEARCH_TEAMS:
        return max(0.0, researchers)
    return RESEARCH_TEAMS * team_strength(researchers / RESEARCH_TEAMS)


def lead_rate(share: float, sustainable: float) -> float:
    """Research600.lead_rate: years a year the lead moves with the learning share."""
    if sustainable <= 0.0 or NORMAL["LEAD_YEARS_PER_DOUBLING"] <= 0.0:
        return 0.0
    fall = NORMAL["LEAD_FALL_DOUBLINGS"]
    doublings = -fall if share <= 0.0 else max(-fall, math.log2(share / sustainable))
    return NORMAL["LEAD_YEARS_PER_DOUBLING"] * doublings


def attention_steps(allocations: dict) -> dict:
    """Research600.attention_steps: each line's share of the plan in common steps."""
    total = sum(max(0.0, float(v)) for v in allocations.values())
    if total <= 0.0:
        return {}
    return {line: max(0.0, float(v)) / total * ATTENTION_STEPS for line, v in allocations.items()}


def keepers_asked(allocations: dict) -> float:
    """Research600.keepers_asked: two keepers for each line the plan follows."""
    return ATTENTION_STEPS / 12.0 * sum(1 for v in allocations.values() if int(v) > 0)


def neglect_for(focus_by_line: dict) -> float:
    """SocietyModel.neglect_for (parity): the unfocused lines give up, between
    them, SPECIALIZATION_NEGLECT times what the focused lines gain."""
    gained = sum(max(0.0, float(v)) for v in focus_by_line.values() if v > 0)
    unfocused = 12 - sum(1 for v in focus_by_line.values() if v > 0)
    if gained <= 0.0 or unfocused <= 0:
        return 0.0
    return min(1.0, SPECIALIZATION_HEADROOM * SPECIALIZATION_NEGLECT * gained / unfocused)


# Research600.parallel_capacity (research_3000).
DIFFUSION_TEAM = float(g.const("scripts/research_600_catalog.gd", "DIFFUSION_TEAM", default=0.0, optional=True))
PARALLEL = {k: float(g.const("scripts/research_600_catalog.gd", k, default=0.0, optional=True))
            for k in ("PARALLEL_POPULATION_REF", "PARALLEL_PER_DECADE", "PARALLEL_LITERACY")}
# Research600.stale_factor (research_3000): superseded registry items.
STALE = {k: float(g.const("scripts/research_600_catalog.gd", k, default=0.0, optional=True)) for k in ("STALE_GRACE", "STALE_DOUBLING", "STALE_ABANDON", "DEAD_END_PENALTY", "DEAD_END_VIABLE")}
# Research600 soft era gate: per-world opening years; early work costs in
# proportion to the years ahead (never a wall).
EARLY = {k: float(g.const("scripts/research_600_catalog.gd", k, default=0.0, optional=True)) for k in ("OPEN_JITTER", "OPEN_JITTER_MAX", "AHEAD_STEP_YEARS")}
# DiscoverySystem.FOUNDATION_HORIZON_YEARS: foundations serve questions near their age.
FOUNDATION_HORIZON = float(g.const("scripts/discovery_system.gd", "FOUNDATION_HORIZON_YEARS", default=50.0, optional=True))
# DiscoverySystem._switch_to_quicker_questions: a line ahead of its age takes up a quicker question.
SWITCH_CHECK_DAYS = float(g.const("scripts/discovery_system.gd", "SWITCH_CHECK_DAYS", default=0.0, optional=True))
SWITCH_MARGIN = float(g.const("scripts/discovery_system.gd", "SWITCH_MARGIN", default=1.5, optional=True))
EARLY_SCORE_PER_WORK = float(g.const("scripts/discovery_system.gd", "EARLY_SCORE_PER_WORK", default=0.0, optional=True))
NEAR_AGE_YEARS = float(g.const("scripts/discovery_system.gd", "NEAR_AGE_YEARS", default=1e9, optional=True))
# Research pacing (DiscoverySystem teams): Research600.TEAMS_* present -> the
# researchers work in team_count(researchers) equal teams, each on one question
# until proof (the community's whole work shared equally, so parity holds); a
# followed line's share sets how often it gets a team (its turns: proofs over
# TEAM_TURN_YEARS plus teams held), a line with work of its age never waits past
# TEAM_MAX_WAIT_YEARS, questions of their age come before any ahead of it (lines
# help each other first), foundation work keeps within NEAR_AGE_YEARS, and the
# steps to proof (STAGES) start trial use (TRIAL_SHARE) before proof.
TEAMS = {k: float(g.const("scripts/research_600_catalog.gd", k, default=0.0, optional=True))
         for k in ("TEAMS_BASE", "TEAMS_PER_TENFOLD", "TEAMS_REF", "TEAMS_MAX", "TEAM_MAX_WAIT_YEARS", "TEAM_TURN_YEARS", "PROOF_ADOPTION")}
TEAM_MODE = TEAMS["TEAMS_BASE"] > 0
STAGES = [float(x) for x in g.const("scripts/research_600_catalog.gd", "STAGES", default=[], optional=True)]
TRIAL_SHARE = [float(x) for x in g.const("scripts/research_600_catalog.gd", "TRIAL_SHARE", default=[], optional=True)]
AGE_BUCKET_SCORE = float(g.const("scripts/discovery_system.gd", "AGE_BUCKET_SCORE", default=0.0, optional=True))
# DiscoverySystem.FAR_BANDS: work further ahead than NEAR_AGE_YEARS is taken band
# by band (years ahead), the nearest band any line offers first; a line that has
# waited TEAM_MAX_WAIT_YEARS counts its far work two bands nearer, never nearer
# than the first far band (_team_rank); monthly, a team more than FAR_BANDS[1]
# years ahead moves to the work a free team would take when that stands two
# bands nearer and is SWITCH_MARGIN less work.
FAR_BANDS = [float(x) for x in g.const("scripts/discovery_system.gd", "FAR_BANDS", default=[], optional=True)]
TIER_LAST = 2 + len(FAR_BANDS)


def team_count(researchers: float) -> int:
    """Research600.team_count: questions a community works at once."""
    if researchers <= 0.0:
        return 1
    x = TEAMS["TEAMS_BASE"] + TEAMS["TEAMS_PER_TENFOLD"] * math.log10(researchers / TEAMS["TEAMS_REF"])
    return int(clamp(math.floor(x + 0.5) if x >= 0 else -math.floor(-x + 0.5), 1, TEAMS["TEAMS_MAX"] if TEAMS["TEAMS_MAX"] > 0 else 1e18))


def trial_share(progress):
    """Research600.trial_share (vectorized): households trying a question before proof."""
    out = np.zeros_like(progress, dtype=float)
    for k, threshold in enumerate(STAGES):
        out = np.where(progress >= threshold - 1e-6, TRIAL_SHARE[min(k, len(TRIAL_SHARE) - 1)], out)
    return out
# FoodSystem technique levers and AgronomyKnowledge.factors (engine features the
# 0-600 surrogate left out; they matter once fertilizer and breeding arrive).
FOOD_TECHNIQUES = g.const("scripts/food_system.gd", "TECHNIQUES", default={}, optional=True)
LEVER_LIMITS = g.const("scripts/food_system.gd", "LEVER_LIMITS", default={}, optional=True)


def _agronomy_profiles() -> dict:
    """AgronomyKnowledge entries: id -> (group, rank, gain, protection, weather, labor, land)."""
    import re
    try:
        src = g.source("scripts/agronomy_knowledge.gd")
    except (FileNotFoundError, OSError):
        return {}
    rx = re.compile(r'_e\("(\w+)","[^"]*",\[[^\]]*\],"[^"]*","(\w+)",(\d+),([\d.]+),([\d.]+),([\d.]+),([\d.]+),([\d.]+)\)')
    return {m[0]: (m[1], float(m[2]), float(m[3]), float(m[4]), float(m[5]), float(m[6]), float(m[7])) for m in rx.findall(src)}


AGRONOMY = _agronomy_profiles()


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


_ID_DRAWS: dict = {}


def id_draws(ids: list, seed: int, purpose: str) -> np.ndarray:
    """This world's fixed 0..1 draw for every question, keyed by its id, seed and
    purpose as DiscoverySystem._research_draw is (a hash, not a position in a
    stream): adding questions to the catalog never reshuffles another
    question's cost, affinity, opening year or dead-end draw."""
    key = (id(ids), len(ids), ids[0] if ids else "", ids[-1] if ids else "", seed, purpose)
    got = _ID_DRAWS.get(key)
    if got is None:
        got = np.array([int.from_bytes(hashlib.blake2b(f"{seed}:{rid}:{purpose}".encode("utf-8"), digest_size=8).digest(), "little")
                        for rid in ids], dtype=np.float64) / 2.0 ** 64
        if len(_ID_DRAWS) > 64:
            _ID_DRAWS.clear()
        _ID_DRAWS[key] = got
    return got


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
    # The ruler's own daily split (manual_work.gd, GovernmentPeopleSystem._lay_ruler_split):
    # applied as given, no food floor; the town's leader still feeds the town
    # past it while the food alarm is up (_ruler_split_fed, when the engine has it).
    manual: dict = field(default_factory=dict)
    # People first: the path the leaders lean the work toward (work_paths.gd),
    # the people's ambition (cultural_inheritance.gd WORK), "auto" focus (the
    # leaders' own: GovernmentPeopleSystem._focus_decision_for_settlement) and
    # new towns ("leaders": one per SITE_YEARS when stores allow).
    path: str = ""
    ambition: str = ""
    expand: str = ""

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
        # Keyed by question id, as the engine's are (id_draws).
        self.cost_draw = 0.85 + id_draws(cat.ids, seed, "cost") * 0.30
        # --- tuning knobs (tune.py): game-side changes expressed as multipliers ----
        self.tune_pace = float(params.get("tune_research_pace", 1.0))          # x on daily progress (discovery_system 0.12 / research_years)
        self.tune_doubling = float(params.get("tune_era_doubling", c.era_doubling))
        self.tune_window = float(params.get("tune_era_window", c.era_window))
        self.tune_adoption = float(params.get("tune_adoption_pace", 1.0))       # x on SocietyModel.ADOPTION_PACE
        self.tune_cap = float(params.get("tune_cap_scale", 1.0))                # x on era ceilings (ERA_CEILING_600 anchors)
        self.tune_burden = float(params.get("tune_burden_scale", 1.0))          # x on (ERA_BURDEN - 1), early_life_conditions.gd
        line_scale = params.get("tune_line_scale") or {}
        self.E = cat.E
        # research_3000 tuning knobs (tune.py-style what-ifs for the later windows):
        # tune_pace_by_year replaces Research600.PACE_BY_YEAR, tune_parallel /
        # tune_stale replace PARALLEL_* / STALE_* (dicts of the same keys).
        self.chance = cat.chance
        if params.get("tune_pace_by_year"):
            new = np.array([gd.rise(params["tune_pace_by_year"], float(y)) if r else 1.0 for y, r in zip(cat.design_year, cat.registry)])
            old = np.array([gd.research_pace(float(y)) if r else 1.0 for y, r in zip(cat.design_year, cat.registry)])
            self.chance = cat.chance * new / old
        self.parallel_k = {**PARALLEL, **(params.get("tune_parallel") or {})}
        self.stale_k = {**STALE, **(params.get("tune_stale") or {})}
        self.relevance = np.where(cat.design_year >= 0, cat.design_year, -1.0) if params.get("tune_relevance") == "own" else cat.relevance_year
        # Research600.dead_end_offered (research_3000): this world's seeded subset of
        # dead ends (key thresholds and foundations always open).
        self.offered = np.ones(n, dtype=bool)
        if self.stale_k.get("DEAD_END_VIABLE"):
            dead = cat.registry & (cat.relevance_year >= 0) & (cat.relevance_year <= cat.design_year + 0.5) & ~cat.key_threshold
            draw = id_draws(cat.ids, seed, "dead_end")
            self.offered = ~dead | (draw < self.stale_k["DEAD_END_VIABLE"])
        # Research600.open_year: this world's opening years (a seeded draw per
        # question, as dead ends use). Early work is only slower (_early_doublings).
        earliest = cat.earliest
        open_draw = id_draws(cat.ids, seed, "open_year")
        self.open_year = np.where(earliest > 0, np.maximum(0.0, earliest + (open_draw * 2.0 - 1.0) * np.minimum(EARLY["OPEN_JITTER_MAX"], earliest * EARLY["OPEN_JITTER"])), 0.0)
        if line_scale:
            scale = np.array([float(line_scale.get(line, 1.0)) for line in gd.LINES])[cat.line]
            self.E = cat.E * scale[:, None]
        # research_affinity: seeded draw x100 + resource potential x15 per requirement.
        self.affinity = id_draws(cat.ids, seed, "affinity") * 100.0 + np.array([len(r) for r in cat.resource_requirements]) * 15.0 * float(params.get("resource_potential", 0.5))
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
        # fun-pop: founding pregnancies = FOUNDING_PREGNANCY_SHARE x baseline annual conceptions
        # (game_state.gd initialize_population_model; was repro * 0.045).
        founding_baseline = (self.coh[1] * 0.45 * 0.23 + self.coh[2] * 0.50 * 0.285 + self.coh[3] * 0.45 * 0.18 + self.coh[4] * 0.16 * 0.040)
        self.preg = np.array([0.34, 0.33, 0.33]) * (founding_baseline * FOUNDING_PREGNANCY_SHARE if FOUNDING_PREGNANCY_SHARE > 0.0 else repro * 0.045)
        self.postpartum = repro * 0.018
        self.health = 0.72
        self.food_security = 0.82
        self.fed_security = 0.82
        self.carer_cover = -1.0
        self.fresh_share = 0.5
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
        # DiscoverySystem.learning_lead: years the people's learning runs ahead.
        self.lead = 0.0
        # Civilian Goods held (GOODS_MODEL), the learners' cover and what they took.
        self.goods = -1.0
        self.goods_cover = 1.0
        self.goods_reserved = 0.0
        self.goods_taken = 0.0
        self.goods_made = 0.0
        # People first: searched land, the raw-materials stock, arms and the watch's drill.
        self.cover = 0.0
        self.raw = RAW_START
        self.arms = 0.0
        self.arms_made = 0.0
        self.extracted = 0.0
        self.per_cutter = 0.0
        self.goods_barter = 0.0
        self.maker_capacity = 0.0
        self.drill = WATCH["START_DRILL"]
        self.armed = 0.0
        self.edge = 0.0
        self._watch_prev = 0.0
        self.daughters = 0
        self.settler_deaths = 0.0
        self.hunger_toll = 0.0
        self.person_years = 0.0
        self.fed_guard = False
        self.focus_now = scenario.focus
        self.learning_cap = None
        self.spare_ratio = 0.0
        self.found_rng = np.random.default_rng((seed * 9176 + 3) & 0xFFFFFFFF)
        self.effects = np.zeros(len(cat.effect_keys))
        self.effect_raw = np.zeros(len(cat.effect_keys))
        self.ceiling_era = 0.0
        self.economy_era = 0.0
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
        self._modern_adult = 1.0
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

    def _cover(self, role: str, share: float) -> float:
        """food_care.gd carry/keep/care cover: hands on the role over `share` of the people, at most 1."""
        return clamp(self.workers(role) / max(1.0, max(1.0, self.population) * share), 0.0, 1.0)

    def _fed(self) -> float:
        """GameState.fed_security: what is eaten, which deaths and sickness read."""
        return self.fed_security if FED_SECURITY else self.food_security

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
        env = list(self.s.site_profile.get("environment_tags", ["river", "woodland"]))
        if not p.get("headless_world"):
            # A growing realm's daughter settlements reach other country: the coast,
            # dry steppe (Research600 environment tags of any settlement count).
            for tag, count in (p.get("expansion_environment") or {}).items():
                if self.territory_settlements >= int(count) and tag not in env:
                    env.append(tag)
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
                    override = (p.get("resource_stage_year_override") or {}).get(r, {}) if p.get("headless_world") else {}
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
        founded = int(getattr(self, "daughters", 0))
        if self.s.ai and self.s.expand != "leaders":
            return 1 + founded + int(min(self.day / YEAR, float(self.p.get("ai_settlement_until", 360.0))) // float(self.p.get("ai_settlement_years", 30.0)))
        # The player's realm founds a daughter settlement when its land runs short
        # (_found_daughters); the truth probes' delegated player never crowds in 100 years.
        return 1 + founded

    def _found_daughters(self, year: float) -> None:
        """Surrogate player model (research_3000): a crowded realm founds a daughter
        settlement, at most one per found_interval_years (not in headless calibration runs)."""
        if self.p.get("headless_world") or year < float(self.p.get("found_from_year", 600.0)) or self.s.expand == "leaders":
            return
        last = getattr(self, "_last_found", -1e9)
        if getattr(self, "crowding", 0.0) >= float(self.p.get("found_crowding", 0.15)) and year - last >= float(self.p.get("found_interval_years", 25.0)):
            self.daughters = getattr(self, "daughters", 0) + 1
            self._last_found = year

    @property
    def territory_factor(self) -> float:
        """EarlyLifeConditions.carrying_capacity territory 1 + 1.6 sqrt(n - 1)."""
        return 1.0 + math.sqrt(max(0, int(self.territory_settlements) - 1)) * 1.6

    @property
    def settlements(self) -> int:
        return 1 + int(max(0.0, self.population - 120.0) // float(self.p["settlement_population"]))

    # ------------------------------------------------------------------ effects
    def _effects_update(self) -> None:
        """SocietyModel._rebuild_effect_totals: sum(effects x adoption), held under
        the era ceiling of society_era() (calendar vs 95th percentile of known eras)."""
        cat = self.cat
        weights = np.where(self.known, np.clip(self.adoption, 0.0, 1.0), 0.0)
        if STAGES and TRIAL_SHARE:
            # SocietyModel._rebuild_effect_totals: questions past their first cases
            # are tried in a share of households before proof.
            weights = np.where(self.known, weights, trial_share(self.progress))
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
                    neglect = neglect_for(dict(zip(gd.LINES, focus_by_line.tolist()))) if PARITY else SPECIALIZATION_NEGLECT * focus_by_line.max()
                    item_mult = np.where(fl > 0, 1.0 + SPECIALIZATION_HEADROOM * fl, 1.0 - neglect)
                    benefit = self.__dict__.get("_benefit")
                    if benefit is None:
                        benefit = self._benefit = np.where(cat.lower_better[None, :], np.minimum(self.E, 0.0), np.maximum(self.E, 0.0))
                    raw = raw + (weights * (item_mult - 1.0)) @ benefit
        self.effect_raw = raw
        eras = cat.ceiling_era[self.known]
        if eras.size:
            eras = np.sort(eras)
            frontier = eras[int((eras.size - 1) * self.c.frontier_percentile)]
            self.ceiling_era = clamp(min(self.day / YEAR + self.lead, frontier), 0.0, self.c.modern_era)
            # SocietyModel.economy_era: the calendar or the frontier, never the lead.
            self.economy_era = clamp(min(self.day / YEAR, frontier), 0.0, self.c.modern_era)
        else:
            self.ceiling_era = 0.0
            self.economy_era = 0.0
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
                neglect = neglect_for(focus) if PARITY else SPECIALIZATION_NEGLECT * fmax
                mult = np.array([(1.0 + SPECIALIZATION_HEADROOM * focus.get(EFFECT_LINE.get(k, ""), 0.0)) if focus.get(EFFECT_LINE.get(k, ""), 0.0) > 0
                                 else (1.0 - neglect) for k in cat.effect_keys])
                lo = np.where(cat.lower_better, np.maximum(cat.limit_lo, lo * mult), lo)
                hi = np.where(cat.lower_better, hi, np.minimum(cat.limit_hi, hi * mult))
        self.effects = np.clip(raw, lo, hi)
        self._eff = dict(zip(cat.effect_keys, self.effects.tolist()))
        # SocietyModel._apply_specialist_upkeep (Phase 3 R3): Knowledge workers
        # beyond the era's sustainable share cost labor, stores, cohesion and births.
        self.specialist_excess = 0.0
        if SUSTAINABLE_SPECIALISTS and self.able > 0:
            share = clamp(self.workers("Knowledge") / max(1.0, self.able), 0.0, 1.0)
            self.specialist_excess = max(0.0, share - curve(SUSTAINABLE_SPECIALISTS, getattr(self, "economy_era", self.ceiling_era)))
            for key, k in SPECIALIST_UPKEEP.items():
                lim = self.c.effect_limits.get(key, (-0.5, 0.8)) if hasattr(self.c, "effect_limits") else (-0.5, 0.8)
                burden = 1.0 + (self.lead / LEARNER_GOODS["LEAD_UPKEEP_YEARS"] if LEARNER_GOODS.get("LEAD_UPKEEP_YEARS", 0.0) > 0.0 else 0.0)
                self._eff[key] = clamp(self._eff.get(key, 0.0) + float(k) * self.specialist_excess * burden, float(lim[0]), float(lim[1]))
        self._knowledge_rate_cap = float(hi[cat.effect_index["knowledge_rate"]]) if "knowledge_rate" in cat.effect_index else 1.0
        if UNCAPPED and "knowledge_rate" in cat.effect_index:
            # ArtifactCollection.era_bonus_cap reads the economy's age (what artifacts exist).
            self._knowledge_rate_cap = float(gd.era_bounds(cat, self.c, getattr(self, "economy_era", self.ceiling_era))[1][cat.effect_index["knowledge_rate"]])

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
        # Parity: a line's attention is its share of the plan in common steps.
        steps = attention_steps(self.s_research) if PARITY else self.s_research
        line_weight = np.array([float(steps.get(line, 0)) for line in gd.LINES])[self.cat.line[k]]
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
        if PARITY:
            # Research600.keepers_asked: the lines the plan follows, not its numbers.
            inquiry = ATTENTION_STEPS / 12.0 * sum(1 for w in weights if int(w) > 0)
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
        if self.s.manual:
            total = sum(max(0.0, float(v)) for v in self.s.manual.values()) or 1.0
            shares = {r: max(0.0, float(self.s.manual.get(r, 0.0))) / total * 100.0 for r in ROLES}
            if RULER_FED:
                shares = self._ruler_split_fed(shares)
            for r in ROLES:
                self.alloc_pct[r] = shares[r]
            return
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
            self.focus_now = self._auto_focus() if self.s.focus == "auto" else self.s.focus
            for role, v in FOCUS_CHANGES.get(self.focus_now, {}).items():
                w[role] = w.get(role, 0.0) + float(v)
            if self.s.ambition or self.s.path:
                self._lay_path()
            # The people's cultural labor bias (cultural_inheritance.gd labor_bias):
            # every role but Food; the wish for food work deepens the reserve
            # instead (GovernmentPeopleSystem.reserve_lean_of). Leader scenarios
            # set these (leaders.py); others have none.
            for role, v in getattr(self, "culture_bias", {}).items():
                if role != "Food":
                    w[role] = w.get(role, 0.0) + float(v)
        # _survival_guard: shortage now, or stores falling with little left. The
        # forecast part is approximated by a falling month with < 20 days left.
        food_risk = self.last["intake"] < 0.995 or (self.stored_days < 20.0 and self.last["production"] < self.last["need"] * 0.97)
        if food_risk:
            w["Food"] += 18.0
            w["Logistics"] += 5.0
        demand, produced, prev = self.last["need"], self.last["production"], self.last["food_share"]
        # GovernmentPeopleSystem reserve planning: below the reserve target the
        # planners plan past today's need in proportion to the gap.
        # A people set on lasting abundance keeps up to twice the store, with up
        # to twice the margin (GovernmentPeopleSystem reserve_lean).
        lean = clamp(float(getattr(self, "reserve_lean", 0.0)), 0.0, 1.0)
        target_days = (SURPLUS_RELEASE.get("RESERVE_TARGET_DAYS") or 0.0) * (1.0 + lean)
        if target_days > 0 and demand > 0:
            target_days = min(target_days, self._storage_capacity() / demand * 0.8)
        # Signed since the lean stores (food_care.gd): past the reserve the
        # planners plan a little under the need until the stores come back down.
        lean_draw = LEAN_DRAW
        reserve_gap = clamp((target_days - self.stored_days) / max(1.0, target_days), -1.0 if lean_draw else 0.0, 1.0) if target_days > 0 else 0.0
        if food_risk:
            reserve_gap = max(0.0, reserve_gap)
        margin = float(SURPLUS_RELEASE.get("RESERVE_MARGIN") or 0.0) * ((1.0 + lean) * reserve_gap if reserve_gap > 0.0 else reserve_gap)
        if demand > 0 and prev > 0 and (food_risk or reserve_gap != 0.0 or self.p.get("guard_always", False)):
            if food_risk or self.p.get("guard_always", False):
                buffer = ((1.08 if food_risk else 1.02) + margin) * float(self.p["food_buffer"]) / 1.10
            else:
                # The engine's own plain reserve margin (no shortage calibration).
                buffer = 1.02 + margin
            needed = clamp(prev * demand * buffer / max(0.01, produced), 0.0, 0.85)
            other = sum(v for r, v in w.items() if r != "Food")
            w["Food"] = max(w["Food"], other * needed / max(0.01, 1.0 - needed))
        release_at = SURPLUS_RELEASE.get("SURPLUS_RELEASE_DAYS") or 0.0
        if lean_draw:
            release_at = target_days   # GovernmentPeopleSystem: released once the stores hold the reserve
        if SURPLUS_RELEASE.get("SURPLUS_RELEASE_MARGIN") and demand > 0 and prev > 0 and not food_risk and self.stored_days >= release_at:
            # GovernmentPeopleSystem surplus release (research_3000): planned food
            # labor comes down to the needed share (the plan's own margin).
            # Since the lean stores the release is the engine's own plan, with no
            # shortage calibration (food_buffer is the alarm's response).
            needed = clamp(prev * demand * (1.02 + margin) / max(0.01, produced), 0.0, 0.85) if lean_draw                 else clamp(prev * demand * 1.02 * float(self.p["food_buffer"]) / 1.10 / max(0.01, produced), 0.0, 0.85)
            released = clamp(needed * SURPLUS_RELEASE["SURPLUS_RELEASE_MARGIN"], 0.0, 0.85)
            other = sum(v for r, v in w.items() if r != "Food")
            w["Food"] = min(w["Food"], other * released / max(0.01, 1.0 - released))
        if FOOD_LABOR_FLOOR:
            # GovernmentPeopleSystem._apply_food_labor_floor (Phase 3 R3).
            floor_share = curve(FOOD_LABOR_FLOOR, self.day / YEAR) * FOOD_FLOOR_OF_TYPICAL
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
        # work_paths.gd cap_learning: the leaders' own split (no focus set by
        # hand) puts at most the path's cap of the people on learning; what is
        # cut goes to the other work besides food in proportion, so food is as
        # planned. The measured mixes (s.labor, from truth runs before the cap)
        # are the leaders' own split too and are capped alike; a focus set by
        # hand or a scenario's own knowledge_share is the ruler's word, as a
        # manual split is in the engine, and is not.
        cap = getattr(self, "learning_cap", None)
        if cap is None and LEARNING_CAP:
            cap = float(LEARNING_CAP.get("balanced", 1.0))
        # The leaders' own focus ("auto", GovernmentPeopleSystem picks it) is
        # theirs too, so it is capped as no focus is.
        if cap is not None and self.s.focus in ("", "auto") and float(getattr(self, "active_knowledge_share", -1.0)) < 0:
            most = cap * sum(w.values())
            if w["Knowledge"] > most:
                others = sum(v for r, v in w.items() if r not in ("Food", "Knowledge"))
                cut = w["Knowledge"] - most
                w["Knowledge"] = most
                if others > 0:
                    for r in list(w):
                        if r not in ("Food", "Knowledge"):
                            w[r] += cut * w[r] / others
        total = sum(w.values())
        target = {r: w[r] / total * 100.0 for r in ROLES}
        # The engine re-plans labor daily; a month with any shortfall moves at once.
        rate = 1.0 if food_risk else float(self.p["food_adjust_rate"])
        for r in ROLES:
            self.alloc_pct[r] = lerp(self.alloc_pct[r], target[r], rate)

    def _auto_focus(self) -> str:
        """GovernmentPeopleSystem._focus_decision_for_settlement (water always
        reached here; no forecast): provisions while short or while the stores,
        falling, would last under 45 days, shelter under 0.96 housing, defense when weak with towns,
        establishment in the first year, else balanced (development needs a
        leader skilled past 135 in building and carrying; the default is 100)."""
        deficit = self.last["need"] - self.last["production"]
        projected = (self.fresh + self.stored) / deficit if deficit > 0.0 else 9999.0   # FoodSystem food_projected_days
        if self.last["intake"] < 0.995 or projected < 45.0:
            return "provisions"
        if self.housing_capacity / max(1.0, self.population) < 0.96:
            return "shelter"
        if self.capacities.get("security", 0.4) < 0.30 and self.territory_settlements > 1:
            return "defense"
        if self.day < 365.0:
            return "establishment"
        return "balanced"

    def _lay_path(self) -> None:
        """The people's ambition and the path: culture_bias, reserve_lean and
        learning_cap as GovernmentPeopleSystem._allocations_for_focus lays them
        (work_paths.gd lean: each role the larger of the two asks)."""
        bias = {r: float(v) for r, v in AMBITION_WORK.get(self.s.ambition, {}).items()}
        food_wish = float(bias.get("Food", 0.0))
        path = self.s.path or "balanced"
        for role, v in PATH_WORK.get(path, {}).items():
            bias[role] = max(bias.get(role, 0.0), float(v))
        self.culture_bias = bias
        self.reserve_lean = clamp(max(food_wish / max(1e-9, RESERVE_FOOD_WISH), float(PATH_FOOD_LEAN.get(path, 0.0))), 0.0, 1.0)
        if LEARNING_CAP:
            self.learning_cap = float(LEARNING_CAP.get(path, LEARNING_CAP.get("balanced", 1.0))) \
                + (INQUIRY_CAP if self.s.ambition == "inquiry" and path != "learning" else 0.0)

    def _ruler_split_fed(self, shares: dict) -> dict:
        """GovernmentPeopleSystem._ruler_split_fed: the ruler's shares, unless the
        food alarm is up (or the leader is already feeding the town and its stores
        hold under RULER_RELEASE_DAYS): then enough on food for what is eaten and
        spoils, more under the reserve, from today's food per hand, the rest of
        the split scaled down."""
        need = self.last["need"]
        if need <= 0.0:
            return shares
        days = self.stored_days
        alarm = self.last["intake"] < 0.995 or (days < 20.0 and self.last["production"] < need * 0.97)
        if not alarm and not (self.fed_guard and days < RULER["RULER_RELEASE_DAYS"]):
            self.fed_guard = False
            return shares
        self.fed_guard = True
        ruler_food = shares["Food"]
        working = clamp(self.last.get("food_share", 0.0), 0.0, 1.0) * 100.0 or ruler_food
        gap = clamp((RULER["RESERVE_TARGET_DAYS"] - days) / RULER["RESERVE_TARGET_DAYS"], 0.0, 1.0)
        wanted = need * (1.05 + RULER["RESERVE_MARGIN"] * gap)
        produced = self.last["production"]
        food = working * wanted / produced if produced > 0.01 else RULER["FOOD_CEILING_SHARE"]
        food = clamp(food, ruler_food, max(ruler_food, RULER["FOOD_CEILING_SHARE"]))
        if food <= ruler_food + 0.01:
            return shares
        others = 100.0 - ruler_food
        scale = (100.0 - food) / others if others > 0.01 else 0.0
        return {r: (food if r == "Food" else shares[r] * scale) for r in ROLES}

    # ------------------------------------------------------------ people first
    def _people_first(self, days: float) -> None:
        """A month of the systems the people-first overhaul added: searched land
        and the cutters' day (resource_system.gd), the watch's drill
        (watch_military.gd drill_day) and new towns (expand == "leaders")."""
        pop = max(1.0, self.population)
        self.hunger_toll += float(getattr(self, "mortality", {}).get("Hunger", 0.0)) * pop * days / YEAR
        self.person_years += pop * days / YEAR
        # resource_system.gd land_step: searchers for every 60 people.
        searchers = self.able * self.alloc_pct["Survey"] / 100.0
        r = max(0.0, searchers) * LAND["PEOPLE_PER_SEARCHER"] / pop
        target = r / (r + LAND["HALF"])
        years = days / YEAR
        if target > self.cover:
            rate = clamp(LAND["RISE_YEAR"] * r, 0.0, LAND["RISE_MAX"])
            self.cover = clamp(self.cover + (target - self.cover) * (1.0 - (1.0 - rate) ** years), 0.0, 1.0)
        else:
            self.cover = clamp(max(target, self.cover * (1.0 - LAND["SAG_YEAR"]) ** years), 0.0, 1.0)
        # resource_system.gd extraction: base yield x quality (1) x tools x work x knowledge x land.
        cutters = self.able * self.alloc_pct["Extraction"] / 100.0
        tools = clamp(0.18 + self.material * 0.92, 0.18, 1.10)      # ConsequenceEngine.tools_factor
        labor_eff = float(getattr(self, "labor_eff", GOODS_X["REFERENCE_EFFICIENCY"]))
        self.per_cutter = BASKET_YIELD * (0.55 + tools * 0.75) * labor_eff * (1.0 + self.eff("extraction_yield")) * self.land_yield()
        got = cutters * self.per_cutter * days
        builders = self.able * self.alloc_pct["Construction"] / 100.0
        self.raw = min(max(0.0, self.raw + got - builders * BUILD_DRAW * days), pop * RAW_PER_HEAD_HELD)
        self.extracted = got / days
        # watch_military.gd drill_day.
        watch = self.watch()
        self.edge = clamp((watch / pop - WATCH["MARTIAL_FROM"]) / max(1e-9, WATCH["MARTIAL_FULL"] - WATCH["MARTIAL_FROM"]), 0.0, 1.0)
        self.armed = clamp(self.arms / watch, 0.0, 1.0) if watch > 0.5 else 1.0
        quality = clamp(lerp(0.48, 0.58, self.armed) + 0.5 * 0.12 + self._adopted("formation_drill") * 0.14 + self._adopted("professional_corps") * 0.12
                        + self._adopted("military_staffs") * 0.06, 0.30, 1.15)
        ceiling = (quality + WATCH["MARTIAL_DRILL"] * self.edge) * (0.72 + 0.28 * self.armed)
        train = (0.42 + self.capacities.get("security", 0.38) * 0.55) * (1.0 + self._adopted("formation_drill") * 0.35 + self._adopted("professional_corps") * 0.55)
        step = clamp(train * clamp(self.food_security, 0.3, 1.0) * (1.0 + WATCH["MARTIAL_PACE"] * self.edge) / LEVY_TRAINING_DAYS, 0.0, 1.0)
        if watch > self._watch_prev + 1e-6:   # newcomers join raw (START_DRILL)
            self.drill = (self.drill * self._watch_prev + WATCH["START_DRILL"] * (watch - self._watch_prev)) / watch
        self._watch_prev = watch
        self.drill = self.drill + (ceiling - self.drill) * (1.0 - (1.0 - step) ** days) if self.drill < ceiling else ceiling
        if self.s.expand == "leaders":
            self._found_town(self.day / YEAR, 30.0, ESTABLISHMENT_DAYS, 28.0, self.found_rng)

    def _found_town(self, year: float, gate_days: float, margin: float, distance: float, rng) -> bool:
        """civilization_controller.expansion_order_steps by the shared rule
        (leaders.py _expansion): one more good site every SITE_YEARS, not hungry,
        stores at the gate, a founding party of max(40, 2 %) leaving 80 at home;
        the party carries food for the road and the margin, and thin rations meet
        a late first harvest (25-70 days) with hunger."""
        if self.completed < 1.0 or self.day < getattr(self, "convoy_until", -1.0):
            return False
        if self.daughters >= int(year / SITE_YEARS) or self.last.get("intake", 1.0) < 0.98 or self.stored_days < gate_days:
            return False
        pop = self.population
        founders = max(40.0, round(pop * .02))
        if pop - founders < 80.0:
            return False
        travel = distance * float(rng.uniform(.5, 1.5)) / 16.0
        food = founders * (travel + margin)
        if self.fresh + self.stored < food:
            return False
        taken = min(food, self.fresh + self.stored)
        fresh = min(self.fresh, taken)
        self.fresh -= fresh
        self.stored = max(0.0, self.stored - (taken - fresh))
        short = max(0.0, float(rng.uniform(25.0, 70.0)) - margin)
        lost = founders * min(.4, short * .004)
        share = self.coh * HUNGER_W
        taken_people = np.minimum(self.coh, share / max(1e-9, share.sum()) * lost)
        self.coh = self.coh - taken_people
        self._sync()
        self.settler_deaths += float(taken_people.sum())
        self.daughters += 1
        self.convoy_until = self.day + travel + 30.0
        return True

    def _adopted(self, rid: str) -> float:
        i = self.cat.index.get(rid)
        return clamp(float(self.adoption[i]), 0.0, 1.0) if i is not None and self.known[i] else 0.0

    def land_yield(self) -> float:
        """resource_system.gd land_yield: what the searched land gives the cutters."""
        return LAND["YIELD_BASE"] + LAND["YIELD_SPAN"] * clamp(self.cover, 0.0, 1.0) if SURVEY_COVER else 1.0

    def watch(self) -> float:
        """watch_military.gd manpower: those keeping watch are the army."""
        return self.able * self.alloc_pct["Defense"] / 100.0

    def _arms_age(self) -> tuple:
        """weapons_stock.gd making_age: the best set whose knowledge is held (a quarter adopted)."""
        best = (10.0, 2.1, 1.0)
        for age in ARMS_AGES:
            needs = str(age.get("needs", ""))
            if needs and self._adopted(needs) < 0.25:
                continue
            best = (float(age.get("maker_days", 10.0)), sum(float(v) for v in (age.get("materials") or {}).values()), float(age.get("quality", 1.0)))
        return best

    def field_strength(self) -> float:
        """A proxy of the watch's fighting weight: each fighter 1 + WARRIOR_WEIGHT x
        drill, armed sets at their quality and the unarmed at improvised arms (0.55)."""
        quality = self._arms_age()[2]
        return self.watch() * (1.0 + WARRIOR_WEIGHT * self.drill) * (self.armed * quality + (1.0 - self.armed) * 0.55)

    def might(self) -> float:
        """standing.gd our_fighting_strength: the watch counts 1 + WARRIOR_WEIGHT x readiness."""
        pop = max(1.0, self.population)
        w = clamp(self.watch(), 0.0, pop)
        return max(1.0, (pop - w) * 0.8 + w * (1.0 + WARRIOR_WEIGHT * self.drill))

    def _storage_capacity(self) -> float:
        """FoodSystem._food_storage_capacity (founding stores, pits, public stores)."""
        pop = max(1.0, self.population)
        return float(self.p["storage_base_rations"]) + (pop * 84.0 if self.completed_names("Storage Pits") else 0.0)             + (pop * 120.0 if self.completed_names("Public Stores") else 0.0)

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
        # FoodSystem.FOOD_WORK_SHARE: the rest of a food worker's day carries,
        # grinds, cooks and stores what was got.
        W_all = self.workers("Food")
        W = W_all * c.food_work_share
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
                * self._agronomy_yield() * (1.0 + self._lever("cultivation")) * (1.0 + max(0.0, e("farm_mechanization"))) \
                * (1.0 + e("soil_productivity") + e("cultivation_yield")) * clamp(weather ** 1.25, 0.46, 1.30)
        # _apply_wild_ceilings + wild_food_capacity
        reach = math.sqrt(pop / 120.0) * (1.0 + FOOD_CARE["CARRY_REACH"] * self._cover("Logistics", FOOD_CARE["CARRY_SHARE"]))
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
        pressure = W_all / able
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
        fresh_rate = c.spoilage_fresh * spoil_mult * float(p["fresh_spoil_mult"]) * (1.0 - FOOD_CARE["CARRY_FRESH_CUT"] * self._cover("Logistics", FOOD_CARE["CARRY_SHARE"]))
        stored_rate = c.spoilage_stored * spoil_mult * (1.0 - FOOD_CARE["KEEP_STORED_CUT"] * self._cover("Administration", FOOD_CARE["KEEP_SHARE"]))
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
        capacity = self._storage_capacity()
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
        self.fresh_share = clamp(eat_fresh / total, 0.0, 1.0) if eaten > 0.001 else 0.0
        self.last.update({"production": production, "need": need, "intake": intake, "diet": diet, "harvest": harvest,
                          "food_share": W_all / max(1.0, self.able), "food_days": food_days, "weather": weather})
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
        neglect = neglect_for(focus) if PARITY else SPECIALIZATION_NEGLECT * fmax
        return 1.0 if focus.get(line, 0.0) > 0 or fmax <= 0 else 1.0 - neglect

    def urban_share(self) -> float:
        """CivilizationIndicators.urban_share (research_3000)."""
        u = URBAN
        if not u.get("URBAN_SCALE"):
            return 0.0
        food = clamp(self.alloc_pct["Food"] / 100.0, 0.0, 1.0)
        size = clamp(math.log10(max(1.0, self.population) / u["URBAN_MIN_POPULATION"]) / u["URBAN_FULL_POPULATION_SPAN"], 0.0, 1.0)
        return clamp(u["URBAN_SCALE"] * (1.0 - food) ** u["URBAN_POWER"] * size, 0.0, 0.95)

    def parallel_capacity(self) -> float:
        """Research600.parallel_capacity (research_3000)."""
        q = self.parallel_k
        if not q.get("PARALLEL_PER_DECADE"):
            return 1.0
        decades = max(0.0, math.log10(max(1.0, self.population) / q["PARALLEL_POPULATION_REF"]))
        return 1.0 + q["PARALLEL_PER_DECADE"] * decades * lerp(0.6, 1.2, clamp(self.capacities["institutions"], 0.0, 1.0)) \
            * (1.0 + q["PARALLEL_LITERACY"] * clamp(self.eff("literacy"), 0.0, 1.0))

    def _lever(self, lever: str) -> float:
        """FoodSystem._technique_levers: adopted techniques x goods coverage (lumped), capped."""
        if not FOOD_TECHNIQUES:
            return 0.0
        key = ("lever", lever, int(self.known.sum()), int(self.day // 30))
        cache = self.__dict__.setdefault("_lever_cache", {})
        if key not in cache:
            total = 0.0
            for rid, levers in FOOD_TECHNIQUES.items():
                i = self.cat.index.get(rid)
                if i is not None and self.known[i] and lever in levers:
                    total += float(levers[lever]) * clamp(float(self.adoption[i]), 0.0, 1.0)
            if len(cache) > 64:
                cache.clear()
            cover = float(self.p.get("goods_coverage", 0.8))
            if GOODS_MODEL and self.goods >= 0.0:
                # What households hold once the learners have taken their next
                # step's goods (learners take first), against their target.
                cover = min(cover, max(0.0, self.goods - self.goods_reserved) / max(0.25, self._goods_target()))
            cache[key] = min(float(LEVER_LIMITS.get(lever, 1.0)), total * cover)
        return cache[key]

    def _agronomy_yield(self) -> float:
        """AgronomyKnowledge.factors()["yield"]: the best adopted practice per family."""
        if not AGRONOMY or "seed_selection" not in self.cat.index or not self.known[self.cat.index["seed_selection"]]:
            return 1.0
        key = ("agro", int(self.known.sum()), int(self.day // 30))
        cache = self.__dict__.setdefault("_agro_cache", {})
        if key not in cache:
            best = {}
            for rid, (group, rank, gain, prot, weather, labor, land) in AGRONOMY.items():
                i = self.cat.index.get(rid)
                if i is None or not self.known[i]:
                    continue
                a = float(self.adoption[i])
                if rank * a > best.get(group, (0.0,))[0]:
                    best[group] = (rank * a, a, gain, labor, land)
            g_ = sum(b[1] * b[2] for b in best.values())
            lab = min(0.2, sum(b[1] * b[3] for b in best.values()))
            lnd = min(0.15, sum(b[1] * b[4] for b in best.values()))
            if len(cache) > 64:
                cache.clear()
            cache[key] = (1.0 + min(0.3, g_)) * (1.0 - lab) * (1.0 - lnd)
        return cache[key]

    def _care(self, overwork: float) -> dict:
        """EarlyLifeConditions.profile (blend 1: new world)."""
        c, e = self.c, self.eff
        excess = dict.fromkeys(("under5", "child", "adult", "neonatal", "maternal"), 0.0)
        cover = {}
        # Carers settle toward the hands on keeping and caring (food_care.gd settle_care, a month at a time).
        target = self._cover("Administration", FOOD_CARE["CARE_SHARE"])
        self.carer_cover = target if self.carer_cover < 0.0 else lerp(self.carer_cover, target, 1.0 - (1.0 - 1.0 / FOOD_CARE["CARE_SETTLE_DAYS"]) ** MONTH)
        carers = self.carer_cover if CARER_COVER else 0.0
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
            coverage = clamp(coverage + carers * float(CARER_COVER.get(cat["id"], 0.0)), 0.0, 1.0)
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
        if MODERN.get("MODERN_BURDEN_LIFT"):
            # EarlyLifeConditions.modern_burden_lift (research_3000).
            relief = 1.0 - (1.0 - relief) * (1.0 - clamp(e("modern_survival") / MODERN["MODERN_BURDEN_LIFT"], 0.0, 1.0))
        scale = self.tune_burden
        # EarlyLifeConditions.carrying_capacity / crowding (Phase 3 R3).
        crowding = 0.0
        if TERRITORY_CAPACITY:
            base = curve(TERRITORY_CAPACITY, self.day / YEAR)
            territory = self.territory_factor
            methods = 1.0 + max(0.0, e("cultivation_yield")) + max(0.0, e("soil_productivity")) * 0.6 + max(0.0, e("food_output")) * 0.5 + max(0.0, e("food_storage")) * 0.25
            grounds = clamp(sum(self.source_health.values()) / max(1, len(self.source_health)), 0.4, 1.0)
            self.carrying_capacity = base * territory * methods * lerp(0.6, 1.0, grounds)
            crowding = max(0.0, self.population / max(1.0, self.carrying_capacity) - CROWDING_ONSET)
        self.crowding = crowding
        # engine: spare land is judged against the founding territory only
        spare = max(0.0, SPARE_LAND_ONSET - self.population / float(TERRITORY_CAPACITY[0][1])) if TERRITORY_CAPACITY else 0.0
        age_keys = ("under5", "child", "adult", "elder")
        care["burden"] = {k: (1.0 + (float(v) - 1.0) * scale * (1.0 - relief) * ((1.0 - spare * SPARE_LAND_HEALTH) if k in age_keys else 1.0) * (1.0 - carers * float(CARER_BURDEN.get(k, 0.0))))
                          * ((1.0 + crowding * CROWDING_MORTALITY) if k in age_keys else 1.0) for k, v in ERA_BURDEN.items()}
        care["conception"] *= max(0.3, 1.0 - crowding * CROWDING_CONCEPTION) * (1.0 + spare * SPARE_LAND_CONCEPTION)
        care["excess_weight"] = {k: float(v) for k, v in EXCESS_WEIGHT.items()}
        if MODERN_SURVIVAL_WEIGHT:
            # EarlyLifeConditions.modern_factors / fertility_transition (research_3000).
            lim = MODERN.get("MODERN_SURVIVAL_LIMIT") or 0.85
            ms = clamp(e("modern_survival"), 0.0, lim)
            full = MODERN.get("MODERN_TABLE_FULL") or lim
            depth = (clamp((ms - MODERN.get("MODERN_TABLE_ONSET", 0.0)) / max(1e-6, full - MODERN.get("MODERN_TABLE_ONSET", 0.0)), 0.0, 1.0)
                     * MODERN["MODERN_TABLE_DEPTH"]) if MODERN.get("MODERN_TABLE_DEPTH") else ms
            care["modern"] = {k: 1.0 - depth * float(w) for k, w in MODERN_SURVIVAL_WEIGHT.items()}
            self._modern_adult = care["modern"].get("adult", 1.0)
            t = TRANSITION
            care["fertility_transition"] = clamp(e("fertility_transition") + t["TRANSITION_URBAN"] * max(0.0, self.urban_share() - t["URBAN_ONSET"])
                                                 + t["TRANSITION_SCHOOLING"] * max(0.0, clamp(e("literacy"), 0.0, 1.0) - t["LITERACY_ONSET"]), 0.0, t["TRANSITION_MAX"])
            self._transition = care["fertility_transition"]
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
        modern = (care.get("modern") or {}).get("elder" if age_ge45 else band, 1.0)
        return era_burden * (1.0 + (excess - 1.0) * weight) * modern

    _BAND_OF_AGE = np.array([0 if a < 5 else 1 if a < 15 else 2 if a < 45 else 3 for a in range(110)])

    def _hazards(self, care: dict, cf: float) -> np.ndarray:
        """Per-age annual hazard (before the condition factor): baseline x age_multiplier."""
        mult = np.array([self._age_mult(care, "under5", False, cf), self._age_mult(care, "child", False, cf),
                         self._age_mult(care, "adult", False, cf), self._age_mult(care, "adult", True, cf)])
        return self.c.hazard_by_age * mult[self._BAND_OF_AGE]

    def _condition_factor(self, housing: float) -> float:
        """GameState._mortality_condition_factor."""
        return lerp(1.90, 0.64, clamp(self.health, 0, 1)) * lerp(2.40, 0.78, clamp(self._fed(), 0, 1)) * lerp(1.65, 0.88, clamp(housing, 0, 1))

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
        ctx_food = clamp(self._fed(), 0, 1)
        cond = lerp(0.12, 1.08, clamp(self.health, 0, 1)) * lerp(0.10, 1.05, math.sqrt(ctx_food) if SQRT_FOOD_CONCEPTION else ctx_food) * lerp(0.55, 1.03, clamp(housing, 0, 1)) * lerp(0.82, 1.04, clamp(self.cohesion, 0, 1))
        if self.last["intake"] < 0.82 or self.malnutrition > 0.38:
            cond *= 0.06
        cond *= 1.0 + clamp(self.eff("conception_support"), -0.30, 0.30)
        cond = clamp(cond, 0.0, 1.30)
        annual = baseline * cond * availability * clamp(care["conception"], 0.3, 2.0)
        if FERTILITY_TRANSITION:
            annual *= 1.0 - clamp(care.get("fertility_transition", 0.0), 0.0, 0.85)
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
        modern = care.get("modern") or {}
        neonatal_care *= modern.get("neonatal", 1.0)
        maternal_care *= modern.get("maternal", 1.0)
        neonatal_rate = clamp((0.018 + (risk - 1.0) * 0.025) * (1.0 - clamp(self.eff("neonatal_survival") + self.policy("neonatal_survival"), -0.50, 0.60)) * clamp(neonatal_care, NEONATAL_CLAMP[0], 4.0), NEONATAL_CLAMP[1], 0.18)
        maternal_rate = clamp((0.0045 + (risk - 1.0) * 0.0065) * (1.0 - clamp(self.eff("maternal_safety"), 0.0, 0.65)) * clamp(maternal_care, MATERNAL_CLAMP[0], 4.0), MATERNAL_CLAMP[1], 0.055)
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
        fed = 0.05 + min(1.15, production_ratio) * 0.25 + intake * 0.18 + food["diet"] * 0.12 + self.nutrition_reserve * 0.10 - self.malnutrition * 0.24
        fs_target = clamp(fed + min(1.0, food_days / FOOD_CARE["LEAN_DAYS"]) * FOOD_CARE["LEAN_WEIGHT"], 0.02, 0.98)
        self.food_security = lag(self.food_security, fs_target, 0.055, days)
        self.fed_security = lag(self.fed_security, clamp(fed + FOOD_CARE["LEAN_WEIGHT"], 0.02, 0.98), 0.055, days)
        disease = float(p["disease_pressure"])
        clean_water = e("health_protection") + e("water_safety") * 0.25 - e("disease_exposure") * 0.18
        env_cost = disease * max(0.18, 1.0 - e("sanitation")) * 0.045 + (float(p["cold_pressure"]) * 0.024) * max(0.0, 0.92 - housing)
        shelter = float(p["shelter_bonus"]) * clamp(self.completed / 2.0, 0.0, 1.0)
        past = self.fresh_share - FOOD_CARE["FRESH_EVEN"]
        fresh_care = (FOOD_CARE["FRESH_HEALTH"] if past >= 0.0 else FOOD_CARE["FRESH_PENALTY"]) * past + FOOD_CARE["CARE_HEALTH"] * max(0.0, self.carer_cover)
        # ConsequenceEngine process_health_cost: the harm of working materials,
        # by how much is cut and dug for every 8 in 100 of the people (chemical
        # control's cut is left out).
        industry = clamp(self.extracted / max(1.0, pop * 0.08), 0.0, 2.0)
        process_cost = (e("health_risk") + e("pollution") * 0.22 + e("water_pollution") * 0.18) * industry
        h_target = clamp(0.18 + self._fed() * 0.43 + fresh_care + food["diet"] * 0.06 + housing * 0.16 + clean_water + shelter
                         - self.malnutrition * 0.28 - env_cost - process_cost + self.policy("health_target") + float(p["health_offset"]), 0.02, 0.97)
        self.health = lag(self.health, h_target, 0.022, days)
        stewards = self.able * self.alloc_pct["Administration"] / 100.0
        admin_cov = clamp(stewards / max(1.0, pop * 0.035), 0.0, 1.25)
        heavy = (self.alloc_pct["Food"] + self.alloc_pct["Extraction"] + self.alloc_pct["Construction"]) / 100.0
        work_strain = clamp(heavy, 0.0, 1.0)
        coh_target = clamp(0.24 + self.food_security * 0.26 + housing * 0.15 + admin_cov * 0.20 + e("state_capacity") * 0.08 + e("cohesion") * 0.10
                           + (1.0 - work_strain) * 0.08 + self.policy("cohesion_target") + float(p["cohesion_offset"]), 0.08, 0.96)
        self.cohesion = lag(self.cohesion, coh_target, 0.014, days)
        observers = self.workers("Knowledge")
        inquiry = keepers_asked(self.s_research) if PARITY else sum(float(v) for v in self.s_research.values())
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
        # Housing: builders add places until capacity leads population. A great
        # work in hand takes its share of the crew first (undertaking_system.gd
        # advance_record; leaders.py sets construction_diverted).
        builders = self.able * self.alloc_pct["Construction"] / 100.0 * (1.0 - getattr(self, "construction_diverted", 0.0))
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
                     # ConsequenceEngine "Work accidents" scales with max(0.15, 1 +
                     # disaster_risk - mine_safety); about 1 in the calibration runs.
                     # research_3000: x the adult modern factor (occupational safety, trauma care).
                     "Other": float(p["other_mortality"]) * max(0.15, 1.0 + e("disaster_risk") - e("mine_safety")) * self._modern_adult}
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
        goods_factor = self._goods_step(days, researchers_total) if GOODS_MODEL else 1.0
        self._goods_factor = goods_factor
        if UNCAPPED and SUSTAINABLE_SPECIALISTS:
            # DiscoverySystem._advance_learning: the learning done (learners on
            # the lines, goods counted) against what the economy's real age can spare.
            on_lines = researchers_total if sum(max(0, int(v)) for v in self.s_research.values()) > 0 else 0.0
            share = on_lines * goods_factor / max(1.0, self.able)
            self.lead = max(0.0, self.lead + lead_rate(share, curve(SUSTAINABLE_SPECIALISTS, self.economy_era)) * days / YEAR)
        open_mask = self.ready & self.cond_ok & cat.channel_staffable[cat.channel] & self.offered
        if self.stale_k.get("STALE_ABANDON"):
            # Research600.pursued (research_3000): superseded practices are abandoned.
            k = self.stale_k
            doublings = np.where(self.relevance >= 0, np.maximum(0.0, self.ceiling_era - self.relevance - k["STALE_GRACE"]) / k["STALE_DOUBLING"], 0.0)
            open_mask &= doublings <= math.log2(k["STALE_ABANDON"])
        if TEAM_MODE:
            self._line_open = np.bincount(cat.line[open_mask], minlength=len(gd.LINES)) > 0
            return self._research_teams(days, year, open_mask, researchers_total, year + self.lead)
        # DiscoverySystem._channel_has_candidate: a line is live only with an open
        # question within NEAR_AGE_YEARS of its age; otherwise its units help the
        # line's live channels, and work ahead only when none is live.
        near_age = open_mask & (self.open_year - year < NEAR_AGE_YEARS)
        has_candidate = np.bincount(cat.channel[near_age], minlength=len(cat.channel_keys)) > 0
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
        # DiscoverySystem.research_teams (parity): the whole work of the researchers
        # not on artifact study, and every staffed channel's team strength.
        staffed = weights[weights > 0]
        strength = float(sum(team_strength(researchers_total * w / total_weight) for w in staffed)) if PARITY else 0.0
        community = team_capacity(researchers_total * float(staffed.sum()) / total_weight) if PARITY else 0.0
        # Lines with any open question (CivilizationController.research_orders
        # viability), for the computer ruler's plan.
        self._line_open = np.bincount(cat.line[open_mask], minlength=len(gd.LINES)) > 0
        found = []
        food_support = lerp(0.62, 1.08, clamp(self.food_security, 0, 1))
        material_support = lerp(0.72, 1.12, clamp(self.material, 0.0, 1.2) / 1.2)
        support = food_support * material_support * lerp(0.78, 1.18, clamp(self.capacities["institutions"], 0, 1)) * lerp(0.55, 1.45, self.education)
        # The fitted drift stands in for officials' skill and communities maturing
        # over the calibrated horizon (truth runs cover 0-100 years); it is held
        # there rather than extrapolated exponentially across millennia.
        parallel = self.parallel_capacity()
        throughput = float(p["throughput"]) * math.exp(float(p["throughput_growth"]) * min(year, float(p.get("throughput_growth_until", 100.0))) / 100.0)
        known_ext = None
        kr = 1.0 + self.eff("knowledge_rate")
        # DiscoverySystem diffusion (research_3000): a line with no emphasis works
        # its first subcategory channel at DIFFUSION_TEAM.
        diffusion = set()
        if DIFFUSION_TEAM > 0:
            for li, line in enumerate(gd.LINES):
                if int(self.s_research.get(line, 0)) <= 0:
                    first = (cat.subcategories.get(line) or [None])[0]
                    ch = cat.channel_index.get((line, first))
                    if ch is not None:
                        diffusion.add(ch)
        for ch in sorted(set(np.where(weights > 0)[0].tolist()) | diffusion):
            item = self.active[ch]
            cand = None
            recheck = False
            if item >= 0 and open_mask[item] and SWITCH_CHECK_DAYS > 0 and self.targets[item] <= 0 and self.open_year[item] > year                     and int(cat.channel[item]) == ch:
                switch_day = self.__dict__.setdefault("_switch_day", {})
                if self.day - switch_day.get(ch, -1e9) >= SWITCH_CHECK_DAYS:
                    switch_day[ch] = self.day
                    recheck = True
            if item < 0 or not open_mask[item] or recheck:
                items = self.chan_items[ch]
                cand = items[open_mask[items]]
                if len(cand) == 0 and FOUNDATION_WORK and not recheck:
                    busy = set(self.active[self.active >= 0].tolist())
                    found_ids = [i for i in self._foundation_ids(int(cat.channel_line[ch]), year, open_mask) if i not in busy]
                    if found_ids:
                        self.active[ch] = found_ids[0]
                        item = found_ids[0]
                        cand = None
                if cand is not None and len(cand) == 0:
                    self.active[ch] = -1
                    continue
            if cand is not None and (item < 0 or not open_mask[item] or recheck):
                current_item = item
                era_cost = np.maximum(0.0, cat.era[cand] - (self.scholarship + self.lead) - self.tune_window) / self.tune_doubling
                early_work = np.exp2(self._early_doublings(cand, year)) - 1.0
                score = self.affinity[cand] + self.signal_score[cand] + weights[ch] * 8.0 - era_cost * 20.0 - early_work * EARLY_SCORE_PER_WORK + self.targets[cand] * 1e5
                if self.stale_k.get("STALE_DOUBLING"):
                    # DiscoverySystem._candidate_score: superseded practices last (research_3000).
                    rel = self.relevance[cand]
                    score -= np.where(rel >= 0, np.maximum(0.0, self.ceiling_era - rel) / self.stale_k["STALE_DOUBLING"], 0.0) * 20.0
                    # Research600.dead_end: questions nothing later builds on come last.
                    score -= np.where((rel >= 0) & (rel <= cat.design_year[cand] + 0.5), self.stale_k.get("DEAD_END_PENALTY", 0.0), 0.0)
                item = int(cand[np.argmax(score)])
                if self.stale_k.get("STALE_DOUBLING") and FOUNDATION_WORK:
                    # DiscoverySystem: a deferred best question (dead end or leftover past
                    # STALE_GRACE) yields to foundations of current questions (research_3000).
                    rel_i = self.relevance[item]
                    if rel_i >= 0 and (rel_i <= cat.design_year[item] + 0.5 or self.ceiling_era - rel_i > self.stale_k["STALE_GRACE"]):
                        busy = set(self.active[self.active >= 0].tolist())
                        found_ids = [i for i in self._foundation_ids(int(cat.channel_line[ch]), year, open_mask) if i not in busy]
                        if found_ids:
                            item = found_ids[0]
                if recheck and item != current_item and self._expected_work(item, year) * SWITCH_MARGIN >= self._expected_work(current_item, year):
                    item = current_item
                self.active[ch] = item
            researchers = researchers_total * weights[ch] / total_weight
            team = team_strength(researchers)
            if PARITY:
                # DiscoverySystem.research_capacity_for (parity): the channel's team
                # does its strength's part of the community's whole work.
                team = community * team / strength if strength > 0 else 0.0
            if weights[ch] <= 0 and ch in diffusion:
                team = DIFFUSION_TEAM
            attention = team * support * parallel * (1.0 + (self.art_bonus_for(gd.LINES[cat.channel_line[ch]]) if self.art["tier"] else 0.0))
            precedent = 1.0
            if cat.has_precedents[item]:
                if known_ext is None:
                    known_ext = np.concatenate([self.known, [False, False]])
                precedent = min(c.precedent_cap, 1.0 + c.precedent_bonus * float(known_ext[cat.precedents[item]].sum()))
            difficulty = self.cost_draw[item] * self._age_work(item) * 2.0 ** (min(30.0, max(0.0, cat.era[item] - (self.scholarship + self.lead) - self.tune_window) / self.tune_doubling) + float(self._early_doublings(item, year))) / precedent
            if self.stale_k.get("STALE_DOUBLING") and self.relevance[item] >= 0:
                # Research600.stale_factor (research_3000)
                difficulty *= 2.0 ** min(20.0, max(0.0, self.ceiling_era - self.relevance[item] - self.stale_k["STALE_GRACE"]) / self.stale_k["STALE_DOUBLING"])
            prob = self.chance[item] / difficulty * attention * self.item_activity[item] * self.evidence[item] * throughput * self.tune_pace \
                * kr * 0.12 * 1.0055
            noise = 1.0 + self.rng.normal(0.0, 0.16 / math.sqrt(max(1.0, days)))
            self.progress[item] += prob * days * noise
            if self.progress[item] >= 1.0:
                found.append(item)
                self.active[ch] = -1
        for item in found:
            self._learn(item)
        return found

    # ---------------------------------------------------------- research: teams
    def _team_bucket(self, items, year: float):
        """DiscoverySystem.age_bucket: 0 of its age, 1 within NEAR_AGE_YEARS, 2 further ahead."""
        ahead = self.open_year[items] - year
        return np.where(ahead <= 0.0, 0, np.where(ahead < NEAR_AGE_YEARS, 1, 2))

    def _team_scores(self, cand, units: float, year: float):
        """DiscoverySystem._candidate_score over one channel's open questions,
        with the age bucket (a question of its age before any ahead of it)."""
        cat = self.cat
        era_cost = np.maximum(0.0, cat.era[cand] - (self.scholarship + self.lead) - self.tune_window) / self.tune_doubling
        early_work = np.exp2(self._early_doublings(cand, year)) - 1.0
        score = self.affinity[cand] + self.signal_score[cand] + units * 8.0 - era_cost * 20.0 - early_work * EARLY_SCORE_PER_WORK + self.targets[cand] * 1e5
        if self.stale_k.get("STALE_DOUBLING"):
            rel = self.relevance[cand]
            score = score - np.where(rel >= 0, np.maximum(0.0, self.ceiling_era - rel) / self.stale_k["STALE_DOUBLING"], 0.0) * 20.0
            score = score - np.where((rel >= 0) & (rel <= cat.design_year[cand] + 0.5), self.stale_k.get("DEAD_END_PENALTY", 0.0), 0.0)
        return score - AGE_BUCKET_SCORE * self._team_bucket(cand, year)

    def _team_foundations(self, li: int, year: float, open_mask, busy: set) -> list:
        """DiscoverySystem._research_600_foundation_ids, within NEAR_AGE_YEARS of their age."""
        return [i for i in self._foundation_ids(li, year, open_mask) if i not in busy and self.open_year[i] - year < NEAR_AGE_YEARS]

    def _team_bucket_of(self, item: int, year: float) -> int:
        """_team_bucket for one question."""
        ahead = float(self.open_year[item]) - year
        return 0 if ahead <= 0.0 else (1 if ahead < NEAR_AGE_YEARS else 2)

    def _team_tier(self, items, year: float):
        """DiscoverySystem.team_tier: 0 of its age, 1 within NEAR_AGE_YEARS, then
        2.. by FAR_BANDS (the age bucket when there are no bands)."""
        bucket = self._team_bucket(items, year)
        if not FAR_BANDS:
            return bucket
        band = np.searchsorted(np.array(FAR_BANDS), self.open_year[items] - year, side="left")
        return np.where(bucket < 2, bucket, 2 + band)

    def _team_tier_of(self, item: int, year: float) -> int:
        """_team_tier for one question."""
        return int(self._team_tier(np.array([item]), year)[0])

    def _team_due(self, month: dict, ch: int, busy: set):
        """The channel's best open question of its age no team holds (the month's
        look reads only these): (item, score, 0) or None."""
        got = month["due"].get(ch)
        if got is None:
            items = self.chan_items[ch]
            cand = items[month["open_mask"][items] & (self.open_year[items] <= month["year"])]
            if len(cand):
                score = self._team_scores(cand, float(month["units_ch"][ch]), month["year"])
                order = np.argsort(-score, kind="stable")
                got = (cand[order], score[order])
            else:
                got = (cand, np.zeros(0))
            month["due"][ch] = got
        cand, score = got
        for k in range(len(cand)):
            if int(cand[k]) not in busy:
                return int(cand[k]), float(score[k]), 0
        return None

    def _team_channel(self, month: dict, ch: int):
        """A channel's open questions this month, best first: the nearest band first
        (DiscoverySystem._score_best_candidate; a question the player chose before
        any), then _candidate_score; with their bands (team_tier)."""
        got = month["chan"].get(ch)
        if got is None:
            items = self.chan_items[ch]
            cand = items[month["open_mask"][items]]
            if len(cand):
                score = self._team_scores(cand, float(month["units_ch"][ch]), month["year"])
                tier = self._team_tier(cand, month["year"])
                if FAR_BANDS:
                    order = np.lexsort((-score, np.where(self.targets[cand] > 0, -1, tier)))
                else:
                    order = np.argsort(-score, kind="stable")
                got = (cand[order], score[order], tier[order])
            else:
                got = (cand, np.zeros(0), np.zeros(0, dtype=np.int64))
            month["chan"][ch] = got
        return got

    def _team_best(self, month: dict, ch: int, busy: set):
        """The channel's best open question no team holds: (item, score, bucket) or None."""
        cand, score, bucket = self._team_channel(month, ch)
        for k in range(len(cand)):
            if int(cand[k]) not in busy:
                return int(cand[k]), float(score[k]), int(bucket[k])
        return None

    def _team_placements(self, month: dict, followed, busy: set, also: tuple = (), max_bucket: int | None = None) -> list:
        """DiscoverySystem._line_placements over every followed line and band (no
        further than ``max_bucket``, a band: team_tier):
        each line's best question on each of its channels without a team (and the
        channels in ``also``); a deferred best (dead end or leftover) yields to the
        line's foundation work when that is at least as near its age; and the
        line's foundation work alone when none of its channels holds a question
        at least that near its age. A line lends one team to foundations at a
        time. Rows: (bucket, score, line, channel, item)."""
        cat = self.cat
        if max_bucket is None:
            max_bucket = TIER_LAST
        year, open_mask, units_ch = month["year"], month["open_mask"], month["units_ch"]
        out = []
        lending = set()
        for ch in np.where(self.active >= 0)[0].tolist():
            if int(ch) not in also and int(cat.channel[int(self.active[ch])]) != int(ch):
                lending.add(int(cat.channel_line[ch]))
        for li in np.where(followed)[0].tolist():
            free = [int(ch) for ch in self.line_channels[li] if self.active[ch] < 0 or int(ch) in also]
            if not free:
                continue
            lends = li in lending
            own_min = TIER_LAST + 1
            for ch in free:
                best = self._team_due(month, ch, busy) if max_bucket == 0 else self._team_best(month, ch, busy)
                if best is None:
                    continue
                item, score, b = best
                own_min = min(own_min, b)
                if b > max_bucket:
                    continue
                if not lends and self.stale_k.get("STALE_DOUBLING") and FOUNDATION_WORK:
                    rel_i = self.relevance[item]
                    if rel_i >= 0 and (rel_i <= cat.design_year[item] + 0.5 or self.ceiling_era - rel_i > self.stale_k["STALE_GRACE"]):
                        found_ids = self._team_foundations(li, year, open_mask, busy)
                        if found_ids and self._team_tier_of(found_ids[0], year) <= b:
                            f = found_ids[0]
                            out.append((b, float(self._team_scores(np.array([f]), float(units_ch[int(cat.channel[f])]), year)[0]), li, ch, f))
                            lends = True
                            continue
                out.append((b, score, li, ch, item))
            if not lends and FOUNDATION_WORK:
                found_ids = self._team_foundations(li, year, open_mask, busy)
                if found_ids:
                    f = found_ids[0]
                    bf = self._team_tier_of(f, year)
                    if bf < own_min and bf <= max_bucket:
                        out.append((bf, float(self._team_scores(np.array([f]), float(units_ch[int(cat.channel[f])]), year)[0]), li, free[0], f))
        return out

    def _team_turns(self, year: float, held, followed):
        """DiscoverySystem._team_turns: each followed line's recent turns (its proofs
        over TEAM_TURN_YEARS plus the teams it holds) and the year of its last proof."""
        log = self.__dict__.setdefault("team_proofs", [])
        turns = held.astype(float).copy()
        last = np.zeros(len(gd.LINES))
        since = year - TEAMS["TEAM_TURN_YEARS"]
        seen = set()
        # The log runs oldest first: read it back from the newest proof.
        for y, li in reversed(log):
            if li not in seen:
                seen.add(li)
                last[li] = y
            if y >= since:
                turns[li] += 1.0
            elif len(seen) >= len(gd.LINES):
                break
        return turns, last

    def _team_pick(self, placements: list, shares, turns, last, held, followed, year: float):
        """DiscoverySystem._pick_team_placement: the nearest band first (a line that
        has waited TEAM_MAX_WAIT_YEARS counts its far work two bands nearer); then a
        waiting line (longest first); then the line furthest below its share of
        recent turns; then the question's score."""
        total = float(turns[followed].sum())
        wait = TEAMS["TEAM_MAX_WAIT_YEARS"]

        def key(pl):
            b, score, li, ch, item = pl
            waited = held[li] == 0 and year - last[li] >= wait
            rank = max(2, b - 2) if (FAR_BANDS and waited and b > 2) else b
            return (rank, 0 if waited else 1, -(year - last[li]) if waited else 0.0, -(shares[li] * total - turns[li]), -score, ch)
        return min(placements, key=key)

    def _research_teams(self, days: float, year: float, open_mask, researchers_total: float, age: float | None = None) -> list:
        """DiscoverySystem research with teams (see TEAMS above). ``year`` is the
        calendar (turns, waits); ``age`` the people's own age (questions' age)."""
        if age is None:
            age = year
        cat, c, p = self.cat, self.c, self.p
        units = np.array([max(0, int(self.s_research.get(line, 0))) for line in gd.LINES], dtype=float)
        lines_total = float(units.sum())
        study = float(self.study_weight())
        on_lines = researchers_total * lines_total / max(1.0, lines_total + study) if lines_total > 0 else 0.0
        q = team_count(on_lines) if lines_total > 0 else 0
        self.team_count_now = q
        followed = units > 0
        shares = units / lines_total if lines_total > 0 else units
        ch_line = cat.channel_line
        # Sub-line units only prefer a channel (_candidate_score); spread evenly.
        units_ch = np.zeros(len(cat.channel_keys))
        for li in range(len(gd.LINES)):
            chans = self.line_channels[li]
            for k in range(int(units[li])):
                if len(chans):
                    units_ch[chans[k % len(chans)]] += 1
        # 1. A team keeps its question while it is open and its line followed.
        for ch in np.where(self.active >= 0)[0].tolist():
            if not followed[ch_line[ch]] or not open_mask[int(self.active[ch])]:
                self.active[ch] = -1
        held = np.bincount(ch_line[np.where(self.active >= 0)[0]], minlength=len(gd.LINES))
        turns, last = self._team_turns(year, held, followed)
        # 2. Fewer teams (fewer researchers): the teams with the most work still
        # ahead of them stop first.
        teams = np.where(self.active >= 0)[0].tolist()
        if len(teams) > q:
            teams.sort(key=lambda ch: (-self._expected_work(int(self.active[ch]), age), shares[ch_line[ch]] * turns[followed].sum() - turns[ch_line[ch]]))
            for ch in teams[:len(teams) - q]:
                self.active[ch] = -1
                held[ch_line[ch]] -= 1
                turns[ch_line[ch]] -= 1
        busy = set(int(i) for i in self.active[self.active >= 0])
        month = {"year": age, "open_mask": open_mask, "units_ch": units_ch, "chan": {}, "due": {}}
        # 3. Free teams take questions: their age first, then lines below their share.
        free = q - int((self.active >= 0).sum())
        while free > 0:
            # DiscoverySystem._next_team_placement: read afresh after every pick.
            placements = self._team_placements(month, followed, busy)
            if not placements:
                break
            b, score, li, ch, item = self._team_pick(placements, shares, turns, last, held, followed, year)
            self.active[ch] = item
            held[li] += 1
            turns[li] += 1
            busy.add(item)
            free -= 1
        # 4. Monthly, a team working ahead of its age moves to a question of its age
        # (any followed line); one more than FAR_BANDS[1] years ahead, to the work a
        # free team would take when that stands two bands nearer and is
        # SWITCH_MARGIN less work; or, in its own channel, to a much quicker one.
        if SWITCH_CHECK_DAYS > 0:
            due_free = None
            for ch in np.where(self.active >= 0)[0].tolist():
                item = int(self.active[ch])
                if self.open_year[item] <= age or self.targets[item] > 0:
                    continue
                if due_free is None:
                    due_free = self._team_placements(month, followed, busy, max_bucket=0)
                busy.discard(item)
                best = None
                due = list(due_free)
                own_due = self._team_due(month, ch, busy)
                if own_due is not None:
                    due.append((0, own_due[1], int(ch_line[ch]), ch, own_due[0]))
                if due:
                    li = ch_line[ch]
                    held[li] -= 1
                    turns[li] -= 1
                    best = self._team_pick(due, shares, turns, last, held, followed, year)
                    held[li] += 1
                    turns[li] += 1
                tier = self._team_tier_of(item, age) if FAR_BANDS else 0
                if best is None and tier >= 4:
                    li = ch_line[ch]
                    held[li] -= 1
                    turns[li] -= 1
                    # Rows of rank tier - 2 or nearer: a waiting line's up to `tier` itself.
                    # Only the team's own line may count as waiting here.
                    rows = self._team_placements(month, followed, busy, (ch,), tier)
                    others = np.maximum(held, 1)
                    others[li] = held[li]
                    near = self._team_pick(rows, shares, turns, last, others, followed, year) if rows else None
                    held[li] += 1
                    turns[li] += 1
                    if near is not None and near[0] <= tier - 2 and near[4] != item and self._expected_work(near[4], age) * SWITCH_MARGIN < self._expected_work(item, age):
                        best = near
                if best is None and int(cat.channel[item]) == ch:
                    # In its own channel, a much quicker question (SWITCH_MARGIN less work).
                    own = self._team_best(month, ch, busy)
                    if own is not None and own[0] != item and self._expected_work(own[0], age) * SWITCH_MARGIN < self._expected_work(item, age):
                        best = (own[2], own[1], int(ch_line[ch]), ch, own[0])
                if best is None:
                    busy.add(item)
                    continue
                self.active[ch] = -1
                held[ch_line[ch]] -= 1
                turns[ch_line[ch]] -= 1
                b, score, li, nch, nitem = best
                self.active[nch] = nitem
                held[li] += 1
                turns[li] += 1
                busy.add(nitem)
                due_free = None
        teams = np.where(self.active >= 0)[0]
        # The plan's steps by channel (ArtifactCollection's study share reads their
        # total); the desks holding a team are team_desks.
        self.channel_weight = units_ch
        self.team_desks = teams
        found = []
        if len(teams) == 0:
            return found
        # 5. Every team does an equal part of the community's whole work.
        community = team_capacity(on_lines)
        community *= getattr(self, "_goods_factor", 1.0)
        share = community / float(len(teams))
        food_support = lerp(0.62, 1.08, clamp(self.food_security, 0, 1))
        material_support = lerp(0.72, 1.12, clamp(self.material, 0.0, 1.2) / 1.2)
        support = food_support * material_support * lerp(0.78, 1.18, clamp(self.capacities["institutions"], 0, 1)) * lerp(0.55, 1.45, self.education)
        parallel = self.parallel_capacity()
        throughput = float(p["throughput"]) * math.exp(float(p["throughput_growth"]) * min(year, float(p.get("throughput_growth_until", 100.0))) / 100.0)
        known_ext = None
        kr = 1.0 + self.eff("knowledge_rate")
        log = self.__dict__.setdefault("team_proofs", [])
        for ch in teams.tolist():
            item = int(self.active[ch])
            line = gd.LINES[ch_line[ch]]
            attention = share * support * parallel * (1.0 + (self.art_bonus_for(line) if self.art["tier"] else 0.0))
            precedent = 1.0
            if cat.has_precedents[item]:
                if known_ext is None:
                    known_ext = np.concatenate([self.known, [False, False]])
                precedent = min(c.precedent_cap, 1.0 + c.precedent_bonus * float(known_ext[cat.precedents[item]].sum()))
            difficulty = self.cost_draw[item] * self._age_work(item) * 2.0 ** (min(30.0, max(0.0, cat.era[item] - (self.scholarship + self.lead) - self.tune_window) / self.tune_doubling) + float(self._early_doublings(item, age))) / precedent
            if self.stale_k.get("STALE_DOUBLING") and self.relevance[item] >= 0:
                difficulty *= 2.0 ** min(20.0, max(0.0, self.ceiling_era - self.relevance[item] - self.stale_k["STALE_GRACE"]) / self.stale_k["STALE_DOUBLING"])
            prob = self.chance[item] / difficulty * attention * self.item_activity[item] * self.evidence[item] * throughput * self.tune_pace \
                * kr * 0.12 * 1.0055
            noise = 1.0 + self.rng.normal(0.0, 0.16 / math.sqrt(max(1.0, days)))
            self.progress[item] += prob * days * noise
            if self.progress[item] >= 1.0:
                found.append(item)
                self.active[ch] = -1
                log.append((self.day / YEAR, int(ch_line[ch])))
        if len(log) > 2048:
            del log[:1024]
        for item in found:
            self._learn(item)
        return found

    def _age_work(self, i: int) -> float:
        """Research600.age_work of question ``i`` (its design year, else its era)."""
        if not AGE_WORK:
            return 1.0
        table = self.__dict__.get("_age_work_table")
        if table is None:
            years = np.where(self.cat.design_year >= 0, self.cat.design_year, self.cat.era)
            table = self._age_work_table = np.interp(years, [float(p[0]) for p in AGE_WORK], [float(p[1]) for p in AGE_WORK])
        return float(table[i])

    def _goods_target(self) -> float:
        """CivilianGoods.target: what households expect to hold."""
        per = GOODS_K["BASE_TARGET_PER_PERSON"]
        for rid, extra in GOODS_TARGETS.items():
            i = self.cat.index.get(rid)
            if i is not None and self.known[i]:
                per += float(extra) * clamp(float(self.adoption[i]), 0.0, 1.0)
        return max(0.25, self.population * per)

    def _goods_step(self, days: float, learners: float) -> float:
        """DiscoverySystem._advance_learning + CivilianGoods.advance over ``days``:
        wear, the learners' draw first (cover), then the makers make what the
        households' target x 1.2 and the learners' next draw ask, as far as their
        labor goes. Returns the learning factor GOODS_FLOOR + the rest x cover."""
        target = self._goods_target()
        if self.goods < 0.0:
            self.goods = target
        self.goods *= (1.0 - GOODS_K["DAILY_WEAR"]) ** days
        per_learner = 1.0 / LEARNER_GOODS["LEARNER_DAYS_PER_GOOD"]
        if LEARNER_GOODS["LEAD_GOODS_YEARS"] > 0.0:
            per_learner *= 1.0 + self.lead / LEARNER_GOODS["LEAD_GOODS_YEARS"]
        need = max(0.0, learners) * per_learner * days
        taken = min(self.goods, need)
        self.goods -= taken
        self.goods_cover = taken / need if need > 0.0 else 1.0
        self.goods_taken = taken / max(1.0, days)
        output = 1.0
        for rid in GOODS_TARGETS:
            i = self.cat.index.get(rid)
            if i is not None and self.known[i]:
                output += GOODS_K["TECHNIQUE_OUTPUT"] * clamp(float(self.adoption[i]), 0.0, 1.0)
        makers = self.able * self.alloc_pct["Crafting"] / 100.0
        # CivilianGoods.specialization and efficiency: a people of many makers
        # makes more each; output follows how well people work.
        many = clamp((makers / max(1.0, self.population) - GOODS_X["MAKERS_START"]) / max(1e-9, GOODS_X["MAKERS_FULL"] - GOODS_X["MAKERS_START"]), 0.0, 1.0)
        pace = clamp(float(getattr(self, "labor_eff", GOODS_X["REFERENCE_EFFICIENCY"])), 0.2, 1.6) if GOODS_X["SURPLUS_PER_HEAD"] > 0 else 1.0
        rate = GOODS_K["BASE_RATE"] * output * pace * (1.0 + GOODS_X["SPECIALIZATION"] * many)
        # weapons_stock.gd make: arms first while the watch lacks them (ARMS_SHARE of
        # the makers, the whole day); a set wears at the store's mineral rate.
        self.arms *= (1.0 - ARMS_WEAR_DAY) ** days
        arms_hands = 0.0
        self.arms_made = 0.0
        if ARMS_AGES and makers > 0.0:
            maker_days, materials, _quality = self._arms_age()
            lacking = max(0.0, self.watch() - self.arms)
            if lacking > 0.01:
                arms_hands = makers * ARMS_SHARE
                can = arms_hands * pace / maker_days * days
                sets = min(can, lacking, self.raw / max(1e-9, materials))
                arms_hands *= sets / max(1e-9, can)
                self.raw -= sets * materials
                self.arms += sets
                self.arms_made = sets / days
        capacity = max(0.0, makers - arms_hands) * GOODS_K["CRAFT_SHARE"] * rate * days
        self.maker_capacity = capacity / days
        wanted = max(0.0, target * 1.2 + need - self.goods)
        if GOODS_X["SURPLUS_PER_HEAD"] > 0:
            # For the homes first, from any material on hand; then for barter up
            # to ceiling(), only from what the builders' stores can spare (half
            # the stock stands in for BARTER_MATERIAL_FLOOR).
            room = max(0.0, target * 1.2 + max(1.0, self.population) * GOODS_X["SURPLUS_PER_HEAD"] * (1.0 + GOODS_X["HOLD_MORE"] * many) - self.goods)
            by_raw = self.raw / GOODS_X["RAW_PER_UNIT"]
            homes = min(capacity, wanted, room, by_raw)
            barter = max(0.0, min(capacity - homes, room - homes, (by_raw - homes) * 0.5))
            made = homes + barter
            self.raw = max(0.0, self.raw - made * GOODS_X["RAW_PER_UNIT"])
            self.goods_barter = barter / max(1.0, days)
        else:
            made = min(capacity, wanted)
        self.goods += made
        self.goods_reserved = need
        self.goods_made = made / max(1.0, days)
        self.spare_ratio = clamp(max(0.0, self.goods - target * 1.2) / max(1.0, self.population * max(1e-9, GOODS_X["SURPLUS_PER_HEAD"]) * (1.0 + GOODS_X["HOLD_MORE"])), 0.0, 1.0)
        return LEARNER_GOODS["GOODS_FLOOR"] + (1.0 - LEARNER_GOODS["GOODS_FLOOR"]) * self.goods_cover

    def _expected_work(self, i: int, year: float) -> float:
        """DiscoverySystem._expected_work: remaining work over the question's chance."""
        era_cost = max(0.0, float(self.cat.era[i]) - (self.scholarship + self.lead) - self.tune_window) / self.tune_doubling
        difficulty = float(self.cost_draw[i]) * self._age_work(i) * 2.0 ** (min(30.0, era_cost) + float(self._early_doublings(i, year)))
        return (1.0 - float(self.progress[i])) * difficulty / max(1e-9, float(self.chance[i]))

    def _early_doublings(self, idx, year: float):
        """Research600.early_factor as doublings (log2): 0 once a question's age has
        come, then 1 + years_ahead / AHEAD_STEP_YEARS times the work."""
        return np.log2(1.0 + np.maximum(0.0, self.open_year[idx] - year) / max(EARLY["AHEAD_STEP_YEARS"], 1e-9))

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
        pending = (cat.line == line) & ~self.known & (self.open_year - year <= FOUNDATION_HORIZON) & self.cond_ok
        if self.stale_k.get("STALE_ABANDON"):
            # Research600.pursued: only questions still pursued ask for foundations (research_3000).
            k = self.stale_k
            pending &= np.where(self.relevance >= 0, np.maximum(0.0, self.ceiling_era - self.relevance - k["STALE_GRACE"]) / k["STALE_DOUBLING"], 0.0) <= math.log2(k["STALE_ABANDON"])
        pending = np.where(pending)[0]
        for i in pending.tolist():
            frontier.extend(self._missing_parents(i))
        found, visited, depth = {}, set(), 0
        while frontier and depth < 8:
            nxt = []
            for j in frontier:
                if j in visited or j >= n or self.known[j]:
                    continue
                visited.add(j)
                if not self.cond_ok[j]:
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
        # SocietyModel.register_discovery: a proven practice starts in PROOF_ADOPTION
        # of households when it was tried before proof (else 2.5%).
        self.adoption[item] = max(TEAMS["PROOF_ADOPTION"] or 0.025, self.adoption[item])
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
    def _apply_phase(self, year: float) -> None:
        """A timed strategy's phase may also change the work: the leaders'
        weights ("labor"), the ruler's own split ("manual"), the path, the
        ambition or the focus. Read at the turn of each year."""
        if not self.s.phases:
            return
        phase = [ph for ph in self.s.phases if float(ph.get("from", 0)) <= year + 1e-9]
        if not phase:
            return
        phase = phase[-1]
        for key in ("labor", "manual"):
            if key in phase:
                setattr(self.s, key, dict(phase[key]))
        for key in ("path", "ambition", "focus"):
            if key in phase:
                setattr(self.s, key, str(phase[key]))
        if "manual" in phase and phase["manual"]:
            self.s.labor = {}
        elif "labor" in phase or "path" in phase:
            self.s.manual = {}

    def research_policy(self, year: float) -> dict:
        if self.s.phases:
            phase = [ph for ph in self.s.phases if float(ph.get("from", 0)) <= year + 1e-9][-1]
            self.active_knowledge_share = float(phase.get("knowledge_share", self.s.knowledge_share))
            return phase.get("research", self.s.research)
        self.active_knowledge_share = self.s.knowledge_share
        if not self.s.ai:
            return self.s.research
        if PARITY:
            return self._ruler_plan(year)
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

    # Computer ruler's research plan (parity): CivilizationStrategy.preferences
    # weights for a temperament drawn as LeaderPersonality.generate draws one
    # (not the engine's own seeded draw), the goal and crisis boosts, the people's
    # ambitions (the truth probe's "makers", then the ruler's own each century)
    # at CivilizationController.current_plan's 4 x share, fields with no open
    # question dropped, CivilizationStrategy.research_plan in ATTENTION_STEPS
    # steps, and REPLAN_STEPS steadiness. The research supply and foundation
    # planners' one-step nudges are left out.
    AMBITION_DOMAINS = {"horizons": ("logistics", "ecology"), "makers": ("production", "infrastructure"), "gathering": ("culture", "institutions"),
                        "inquiry": ("knowledge", "health"), "military": ("security", "logistics"), "sustenance": ("nutrition", "ecology"),
                        "wellbeing": ("health", "demography"), "commerce": ("production", "logistics")}

    def _ruler_temperament(self) -> dict:
        t = self.__dict__.get("_temperament")
        if t is None:
            r = np.random.default_rng((self.seed * 2654435761 + 7919) & 0xFFFFFFFF)
            t = self._temperament = {axis: float(r.uniform(0.12, 0.92)) for axis in ("openness", "discipline", "empathy", "assertiveness", "risk_tolerance")}
        return t

    def _ruler_weights(self, year: float) -> dict:
        p = self._ruler_temperament()
        open_, disc, emp, assertive, risk = p["openness"], p["discipline"], p["empathy"], p["assertiveness"], p["risk_tolerance"]
        hungry = self.stored_days < 16.0 or self.last["intake"] < 0.98
        w = {"demography": .25 + emp * .9, "nutrition": .3 + emp * .6 + (1 - risk) * .3, "health": .25 + emp * .8, "labor": .2 + disc * .6,
             "knowledge": .15 + open_ * 1.2, "production": .25 + disc * .5 + open_ * .4, "infrastructure": .25 + disc * .65,
             "logistics": .25 + open_ * .5 + assertive * .3, "ecology": .2 + emp * .45 + (1 - risk) * .35, "institutions": .2 + disc * .65,
             "security": .15 + assertive * .8 + disc * .5, "culture": .2 + emp * .6 + open_ * .4}
        goals = {"care": 3.0 if hungry else emp, "learning": open_, "security": disc * .6 + (1 - risk) * .4,
                 "exchange": emp * .55 + open_ * .45, "growth": disc * .45 + assertive * .55}
        boosts = {"care": {"health": 1.5, "demography": .7}, "learning": {"knowledge": 1.8, "culture": .4}, "security": {"security": 1.8, "infrastructure": .6, "logistics": .4},
                  "exchange": {"logistics": 1.5, "production": .75, "culture": .5}, "growth": {"infrastructure": 1.5, "demography": 1.0, "production": .5}}
        for domain, amount in boosts[max(goals, key=goals.get)].items():
            w[domain] += amount
        if hungry:
            w["nutrition"] += 3.0
            w["health"] += 1.0
            w["ecology"] += .8
        # The people's ambitions: makers first (the truth probe), then the ruler's own.
        scores = {"horizons": open_ * .65 + risk * .35, "makers": disc * .55 + open_ * .45, "gathering": emp * .6 + (1 - assertive) * .4,
                  "inquiry": open_ * .85 + (1 - risk) * .15, "military": assertive * .65 + disc * .35, "sustenance": emp * .4 + (1 - risk) * .6,
                  "wellbeing": emp * .85 + (1 - assertive) * .15, "commerce": open_ * .45 + emp * .35 + risk * .2}
        own = max(scores, key=scores.get)
        choices: dict = {}
        for century in range(int(year // 100) + 1):
            pick = "makers" if century == 0 else own
            choices[pick] = choices.get(pick, 0.0) + 10.0 * 0.5 ** (max(0.0, year - century * 100.0) / 60.0)
        total = sum(choices.values())
        for pick, amount in choices.items():
            for domain in self.AMBITION_DOMAINS[pick]:
                w[domain] += amount / total * 4.0
        return w

    def _ruler_plan(self, year: float) -> dict:
        key = int(year)
        cache = self.__dict__.setdefault("_ai_plan", {})
        if key in cache:
            return cache[key]
        w = self._ruler_weights(year)
        line_open = self.__dict__.get("_line_open")
        if line_open is not None and line_open.any():
            for li, line in enumerate(gd.LINES):
                if not line_open[li]:
                    w[line] = 0.0
        # CivilizationStrategy.research_plan: one step on every field weighed at all,
        # the rest of ATTENTION_STEPS by D'Hondt, twelve at most on any field.
        plan = dict.fromkeys(gd.LINES, 0)
        weighed = [line for line in gd.LINES if w[line] > 0]
        left = int(ATTENTION_STEPS)
        if weighed and left >= len(weighed):
            for line in weighed:
                plan[line] = 1
            left -= len(weighed)
        for _ in range(left if weighed else 0):
            best = max((line for line in weighed if plan[line] < 12), key=lambda line: w[line] / (plan[line] + 1), default=None)
            if best is None:
                break
            plan[best] += 1
        previous = self.__dict__.get("_ruler_last")
        if previous is not None and REPLAN_STEPS > 0:
            # CivilizationController._research_plan_moved: steady unless a field starts
            # or stops, or REPLAN_STEPS steps of attention would move.
            before, after = attention_steps(previous), attention_steps(plan)
            crossing = any((int(previous.get(line, 0)) > 0) != (plan[line] > 0) for line in gd.LINES)
            moved = sum(abs(before.get(line, 0.0) - after.get(line, 0.0)) for line in gd.LINES) / 2.0
            if not crossing and moved < REPLAN_STEPS:
                plan = previous
        self._ruler_last = plan
        cache[key] = plan
        return plan

    def _monthly(self, year: float) -> None:
        """Monthly decisions a subclass models (leaders.py: expansion, great
        works, raids); the plain surrogate has none."""

    def seed_state(self, start_year: float, known_ids: list, adoption: dict, population: float, scholarship: float) -> None:
        """Mirror of truth_probe.gd _seed_era (research_3000 later-era spot check): the
        society at game year start_year with these discoveries, adoption and
        scholarship and ``population`` people (founding age structure), housed, with
        the founding works and public stores built and two months of stores."""
        cat = self.cat
        self.day = float(round(start_year * 365.0))
        self.known = cat.id_mask(known_ids)
        self.adoption = np.where(self.known, np.array([float(adoption.get(i, 0.8)) for i in cat.ids]), 0.0)
        self.discovered_day = np.full(cat.n, -1.0)
        self.scholarship = float(scholarship)
        self.coh = np.array([0.32, 0.15, 0.14, 0.13, 0.18, 0.08]) * float(population)
        self._sync()
        repro = self._reproductive()
        self.preg = np.array([0.34, 0.33, 0.33]) * repro * 0.045
        self.postpartum = repro * 0.018
        self.housing_capacity = float(population) * 1.1
        self.stored = float(population) * 60.0
        self.fresh = 0.0
        self.last.update({"production": float(population) * 0.95, "need": float(population) * 0.95})
        self.ready[:] = False
        self._refresh_ready(np.arange(cat.n))
        self._effects_update()
        self._capacities()

    def run(self, years: int, record_every: float = 1.0) -> dict:
        p = self.p
        self.phase_a = float(abs(self.seed * 31) % 997)
        self.phase_b = float(abs(self.seed * 73) % 991)
        self.births = self.deaths = self.neonatal = self.maternal = 0.0
        self.imr = 0.0
        self.evidence = np.ones(self.cat.n)
        start = self.day / YEAR   # 0, or the seeded start year (seed_state)
        self.s_research = self.research_policy(start)
        self._conditions(start)
        sub = int(p["substeps_per_month"])
        rows = []
        months = int(years * 12)
        next_record = start
        hearth = False
        for m in range(months + 1):
            year = self.day / YEAR
            if year + 1e-9 >= next_record:
                rows.append(self.snapshot())
                next_record += record_every
            if m == months:
                break
            if m % 12 == 0:
                self._apply_phase(year)
                self.s_research = dict(self.research_policy(year))
                self._found_daughters(year)
                self._conditions(year)
            if not hearth and self.completed >= 1.0:
                hearth = True
                self._activity(self.ctx, hearth=True)
            self._allocate_labor()
            self._monthly(year)
            self._people_first(MONTH)
            heavy = (self.alloc_pct["Food"] + self.alloc_pct["Extraction"] + self.alloc_pct["Construction"]) / 100.0
            overwork = clamp(clamp((heavy - 0.74) / 0.22, 0, 1) * 0.7 + (0.5 if "labor_mobilization" in self.s.policies else 0.0), 0.0, 1.0)
            care = self._care(overwork)
            days = MONTH / sub
            for k in range(sub):
                if k > 0 and p.get("replan_each_substep", True):
                    # GovernmentPeopleSystem re-plans the work daily: a monthly plan
                    # lags the seasons and overshoots the food work.
                    self._allocate_labor()
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
            "literacy": 100.0 * clamp(e("literacy"), 0.0, 1.0), "urban_share": 100.0 * self.urban_share(),
            "parallel": self.parallel_capacity(), "modern_survival": e("modern_survival"), "fertility_transition": getattr(self, "_transition", 0.0),
            "lead": getattr(self, "lead", 0.0), "goods": max(0.0, getattr(self, "goods", 0.0)), "goods_cover": getattr(self, "goods_cover", 1.0),
            "goods_per_head": max(0.0, getattr(self, "goods", 0.0) - getattr(self, "goods_reserved", 0.0)) / max(1.0, pop), "learners_goods": getattr(self, "goods_taken", 0.0),
            "household_goods": max(0.0, getattr(self, "goods", 0.0) - getattr(self, "goods_reserved", 0.0)) / max(0.25, self._goods_target()) if GOODS_MODEL and getattr(self, "goods", -1.0) >= 0.0 else 1.0,
            # People first (docs/PEOPLE_FIRST.md). Output is economy_system.gd's
            # daily output value in rations: food got + materials x 2 + goods x their price.
            "focus": getattr(self, "focus_now", ""), "fed_guard": bool(getattr(self, "fed_guard", False)),
            "survey_cover": getattr(self, "cover", 0.0), "land_yield": self.land_yield() if hasattr(self, "cover") else 1.0,
            "extracted": getattr(self, "extracted", 0.0), "raw": getattr(self, "raw", 0.0),
            "goods_made": getattr(self, "goods_made", 0.0), "goods_barter": getattr(self, "goods_barter", 0.0), "maker_capacity": getattr(self, "maker_capacity", 0.0),
            "output": self.last.get("production", 0.0) + 2.0 * getattr(self, "extracted", 0.0) + float(PRICES.get("Civilian Goods", 6.0)) / float(PRICES.get("Food", 1.0)) * getattr(self, "goods_made", 0.0),
            "watch": self.watch() if hasattr(self, "drill") else 0.0, "arms": getattr(self, "arms", 0.0), "armed": getattr(self, "armed", 0.0),
            "drill": getattr(self, "drill", 0.0), "field_strength": self.field_strength() if hasattr(self, "drill") else 0.0,
            "might": self.might() if hasattr(self, "drill") else 0.0, "towns": self.territory_settlements, "carrying_capacity": getattr(self, "carrying_capacity", 0.0),
            "crowding": getattr(self, "crowding", 0.0), "carer_cover": getattr(self, "carer_cover", 0.0), "specialist_excess": getattr(self, "specialist_excess", 0.0),
            "hunger_toll": getattr(self, "hunger_toll", 0.0), "settler_deaths": getattr(self, "settler_deaths", 0.0), "person_years": getattr(self, "person_years", 0.0),
            "conception_support": e("conception_support"), "able": self.able,
        }
