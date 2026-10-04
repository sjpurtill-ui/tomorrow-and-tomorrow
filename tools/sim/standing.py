"""standing.gd's nine strengths against the age (standing_scale.gd), for the
surrogate's one people.

Every anchor table and weight is read from the GDScript (gdparse), so the
yardstick cannot drift from the game's. The surrogate has no other peoples,
no covert ledger and no envoys' business, so the arts' own inputs come from
the scenario's posture (model.py Scenario.posture): who speaks for us and
the chief scout's skill, agents abroad, treaties, familiarity and how well we
know the others; its costs (people away, the shifted work, gifts from the
stores) are simulated by model.py.
"""
from __future__ import annotations

import math

import gdparse as g

SC = "scripts/standing_scale.gd"
ST = "scripts/standing.gd"
ON = g.game_file_exists(SC)


def _c(name, default=None):
    return g.const(SC, name, default=default, optional=True) if ON else default


LOW, TYPICAL, HIGH, MOST = 0.2, 0.5, 0.8, 1.0
ABLE_SHARE = float(_c("ABLE_SHARE", 0.6))
READY = float(_c("READY", 0.9))
DEFENSE_SHARE = _c("DEFENSE_SHARE", [[0, 2, 4, 8, 15]])
ENGINE_PACE = float(_c("ENGINE_PACE", 1.43))
KNOWN_SPREAD = _c("KNOWN_SPREAD", [0.5, 1.0, 1.28, 1.47])
KNOWN_TYPICAL_EARLY = _c("KNOWN_TYPICAL_EARLY", [[0, 10]])
KNOWN_BENCHMARK = _c("KNOWN_BENCHMARK", [[600, 390, 790, 1010, 1180]])
TABLES = {name: _c(name, [[0, 0.1, 0.5, 0.8, 1.0]]) for name in
          ["SCHOLARS", "STORES", "MATERIALS", "GOODS", "WATER", "WALLS", "HEALTH", "COHESION", "LEGITIMACY", "LOGISTICS",
           "CULTURE", "ADMINISTRATION", "MET", "WORKS", "BEAUTY", "SCOUTS", "FAMILIARITY", "TREATIES", "GIFTS", "ENVOY_DAYS", "INTEL"]}
ORDINARY_SKILL = float(_c("ORDINARY_SKILL", 0.47))
READY_FROM_DRILL = 1.5


def _w(name, default):
    return g.const(ST, name, default=default, optional=True) if g.game_file_exists(ST) else default


GENIUS_W = _w("GENIUS_WEIGHTS", {"known": 0.6, "scholars": 0.4})
PERSUASION_W = _w("PERSUASION_WEIGHTS", {"envoy": 0.3, "openness": 0.15, "familiarity": 0.1, "treaties": 0.15, "gifts": 0.15, "abroad": 0.15})
CUNNING_W = _w("CUNNING_WEIGHTS", {"scout": 0.25, "eyes": 0.25, "agents": 0.15, "caught": 0.1, "intel": 0.25})
SPLENDOR_W = _w("SPLENDOR_WEIGHTS", {"works": 0.55, "culture": 0.25, "beauty": 0.2})
WEALTH_W = _w("WEALTH_WEIGHTS", {"food": 0.5, "materials": 0.25, "goods": 0.25})
ENDURANCE_W = _w("ENDURANCE_WEIGHTS", {"food": 0.45, "water": 0.1, "walls": 0.2, "health": 0.125, "cohesion": 0.125})
ORDER_W = _w("ORDER_WEIGHTS", {"legitimacy": 0.35, "cohesion": 0.2, "administration": 0.2, "steward": 0.25})
REACH_W = _w("REACH_WEIGHTS", {"logistics": 0.5, "met": 0.5})
AGENTS_HALF = float(_w("AGENTS_HALF", 2.0))
CAUGHT_HALF = float(_w("CAUGHT_HALF", 3.0))
FORT_STRENGTH = float(g.const("scripts/built_fabric.gd", "FORT_STRENGTH", default=0.8, optional=True))
# The arts at work (standing.gd): the same constants as the engine's.
FOREWARN_ODDS_TYPICAL = float(_w("FOREWARN_ODDS_TYPICAL", 0.5))
FOREWARN_ODDS_SLOPE = float(_w("FOREWARN_ODDS_SLOPE", 0.8))
PERSUASION_DRAW = float(_w("PERSUASION_DRAW", 0.06))
GRUDGE_SOFTEN = float(_w("GRUDGE_SOFTEN", 0.4))


def clamp(x, lo, hi):
    return lo if x < lo else hi if x > hi else x


def anchors(table, year):
    """standing_scale.gd anchors."""
    first = table[0]
    if len(table) == 1 or year <= first[0]:
        return [float(v) for v in first[1:5]]
    for i in range(1, len(table)):
        row = table[i]
        if year <= row[0]:
            before = table[i - 1]
            t = (year - before[0]) / max(0.001, row[0] - before[0])
            return [before[k + 1] + (row[k + 1] - before[k + 1]) * t for k in range(4)]
    return [float(v) for v in table[-1][1:5]]


def might_anchors(year):
    return [v / 100.0 * ABLE_SHARE * READY for v in anchors(DEFENSE_SHARE, year)]


def _line(table, year):
    if year <= table[0][0]:
        return float(table[0][1])
    for i in range(1, len(table)):
        if year <= table[i][0]:
            t = (year - table[i - 1][0]) / max(0.001, table[i][0] - table[i - 1][0])
            return table[i - 1][1] + (table[i][1] - table[i - 1][1]) * t
    return float(table[-1][1])


def known_anchors(year):
    if year >= 600.0:
        return [v * ENGINE_PACE for v in anchors(KNOWN_BENCHMARK, year)]
    typical = _line(KNOWN_TYPICAL_EARLY, year)
    if year > 500.0:
        typical = _line(KNOWN_TYPICAL_EARLY, 500.0) + (KNOWN_BENCHMARK[0][2] * ENGINE_PACE - _line(KNOWN_TYPICAL_EARLY, 500.0)) * (year - 500.0) / 100.0
    return [typical * k for k in KNOWN_SPREAD]


def beauty_anchors(year):
    a = anchors(TABLES["BEAUTY"], year)
    return [0.8 + 10.0 * a[0], 1.0 + 10.0 * a[1], 1.0 + 10.0 * a[2], 1.0 + 10.0 * a[3]]


def _t(x, a, b):
    if b <= a or a <= 0.0:
        return 1.0
    return clamp(math.log(x / a) / math.log(b / a), 0.0, 1.0)


def score(x, a):
    """standing_scale.gd score."""
    low = max(0.0, a[0])
    typical = max(low, a[1])
    high = max(typical * 1.0001 + 1e-6, a[2])
    most = max(high * 1.0001, a[3])
    if x <= typical and typical <= 1e-6:
        return TYPICAL
    if x >= typical:
        if x >= most:
            return MOST
        frm = max(typical, 1e-6)
        if x <= high:
            return TYPICAL + (HIGH - TYPICAL) * _t(x, frm, high)
        return HIGH + (MOST - HIGH) * _t(x, high, most)
    if x <= 0.0:
        return 0.0
    if low <= 1e-6 or x <= low:
        floor_at = low if low > 1e-6 else typical
        floor_score = LOW if low > 1e-6 else TYPICAL
        return floor_score * clamp(x / floor_at, 0.0, 1.0)
    return LOW + (TYPICAL - LOW) * _t(x, low, typical)


def score_share(x, a):
    def t(v):
        return 1.0 / max(0.0005, 1.0 - clamp(v, 0.0, 0.9995))
    if x <= 0.0:
        return 0.0
    low = clamp(a[0], 0.0, 0.999)
    if x <= low:
        return LOW * x / max(0.0001, low)
    return score(t(x), [t(low), t(a[1]), t(a[2]), t(a[3])])


def skill_score(skill):
    if skill >= ORDINARY_SKILL:
        return TYPICAL + (MOST - TYPICAL) * clamp((skill - ORDINARY_SKILL) / (1.0 - ORDINARY_SKILL), 0.0, 1.0)
    return TYPICAL * clamp(skill / ORDINARY_SKILL, 0.0, 1.0)


def bonus_score(count, half):
    return TYPICAL + (MOST - TYPICAL) * (1.0 - math.exp(-max(0.0, count) / max(0.01, half) * 0.6931))


def blend(parts, weights):
    total = sum(weights[k] for k in parts)
    return clamp(sum(parts[k] * weights[k] for k in parts) / max(1e-4, total), 0.0, 1.0)


def readings(row: dict, posture: dict | None = None) -> dict:
    """The nine strengths of a surrogate snapshot row, 0..1 against its year."""
    posture = posture or {}
    year = float(row.get("year", 0.0))
    pop = max(1.0, float(row.get("population", 1.0)))
    T = lambda name: anchors(TABLES[name], year)  # noqa: E731
    # Might: the watch (the surrogate's army) at its drill, walls counted.
    watch = float(row.get("watch", 0.0))
    # Stand-in: the surrogate's watch drill (about 0.6) runs below the engine's
    # home-army readiness (0.91-0.97 at year 75 in a played world); read as
    # readiness x READY_FROM_DRILL.
    drill = clamp(float(row.get("drill", 0.0)) * READY_FROM_DRILL, 0.0, 1.0)
    bonus = float(row.get("defense_bonus", 0.0))
    ready = watch * drill / pop * (1.0 + FORT_STRENGTH * bonus)
    might = score(ready, might_anchors(year))
    # Genius.
    known = float(row.get("known", 0.0))
    scholars = float(row.get("knowledge_workers", 0.0)) / pop
    genius = blend({"known": score(known, known_anchors(year)), "scholars": score(scholars, T("SCHOLARS"))}, GENIUS_W)
    # Wealth: the yards' raw materials and the goods a head.
    food = float(row.get("food_days", 0.0))
    wealth = blend({"food": score(food, T("STORES")), "materials": score(float(row.get("raw", 0.0)) / pop, T("MATERIALS")),
                    "goods": score(float(row.get("goods_per_head", 0.0)), T("GOODS"))}, WEALTH_W)
    # Endurance: no water model in the surrogate (read as typical).
    endurance = blend({"food": score(food, T("STORES")), "water": TYPICAL, "walls": score(bonus, T("WALLS")),
                       "health": score_share(float(row.get("health", 0.9)), T("HEALTH")), "cohesion": score_share(float(row.get("cohesion", 0.9)), T("COHESION"))}, ENDURANCE_W)
    # Splendor: renown points, the culture's allure, the realm's beauty.
    arts = row.get("artifacts", {}) or {}
    culture_score = score_share(clamp(float(arts.get("allure", 0.0)), 0.0, 1.0), T("CULTURE"))
    splendor = blend({"works": score(1.0 + float(row.get("works_points", 0.0)), T("WORKS")), "culture": culture_score,
                      "beauty": score(1.0 + 10.0 * float(row.get("beauty", 0.0)), beauty_anchors(year))}, SPLENDOR_W)
    # Order.
    alloc = row.get("alloc", {}) or {}
    able = float(row.get("able", pop * 0.6)) / pop
    admin = float(alloc.get("Administration", 0.0)) / 100.0 * able
    order = blend({"legitimacy": score_share(float(row.get("legitimacy", 0.9)), T("LEGITIMACY")), "cohesion": score_share(float(row.get("cohesion", 0.9)), T("COHESION")),
                   "administration": score(admin, T("ADMINISTRATION")), "steward": skill_score(float(posture.get("steward_skill", ORDINARY_SKILL)))}, ORDER_W)
    # Reach: carrying, and peoples met (the surrogate's typical, plus a posture's).
    met_a = T("MET")
    met = float(posture.get("met", met_a[1] - 1.0)) + float(posture.get("met_extra", 0.0))
    reach = blend({"logistics": score_share(float(row.get("logistics", 0.5)), T("LOGISTICS")), "met": score(1.0 + met, met_a)}, REACH_W)
    # Persuasion: the posture's envoy, ties and treaties; gifts and envoy-days simulated.
    away = float(posture.get("away_envoys", 0.0))
    days_rate = away * 365.0 * 5.0 * 100.0  # envoy-days in five years a hundred people
    gift_rate = float(posture.get("gifts", 0.0))
    persuasion = blend({"envoy": skill_score(float(posture.get("envoy_skill", ORDINARY_SKILL))), "openness": float(posture.get("openness", 0.5)),
                        "familiarity": score(float(posture.get("familiarity", T("FAMILIARITY")[1])), T("FAMILIARITY")),
                        "treaties": score(1.0 + float(posture.get("treaties", T("TREATIES")[1] - 1.0)), T("TREATIES")),
                        "gifts": score(1.0 + 20.0 * gift_rate, T("GIFTS")), "abroad": score(1.0 + days_rate / 10.0, T("ENVOY_DAYS"))}, PERSUASION_W)
    # Cunning: the posture's scout, agents and knowledge; scouts and watch simulated.
    eyes = (float(alloc.get("Survey", 0.0)) + 0.5 * float(alloc.get("Defense", 0.0))) / 100.0 * able
    cunning = blend({"scout": skill_score(float(posture.get("scout_skill", ORDINARY_SKILL))), "eyes": score(eyes, T("SCOUTS")),
                     "agents": bonus_score(float(posture.get("agents", 0.0)), AGENTS_HALF), "caught": bonus_score(float(posture.get("caught", 0.0)), CAUGHT_HALF),
                     "intel": score(float(posture.get("intel", T("INTEL")[1])), T("INTEL"))}, CUNNING_W)
    return {"might": might, "genius": genius, "persuasion": persuasion, "cunning": cunning, "wealth": wealth,
            "splendor": splendor, "order": order, "endurance": endurance, "reach": reach, "_culture_score": culture_score}


AWE_ORDINARY = float(_w("AWE_ORDINARY", 0.25))
ALLURE_ORDINARY = float(_w("ALLURE_ORDINARY", 0.25))
MENACE_FROM = float(_w("MENACE_FROM", 0.5))
RENOWN_MENACE = float(_w("RENOWN_MENACE", 0.15))
PERSUASION_ALLURE = float(_w("PERSUASION_ALLURE", 0.15))
PRIDE_SPLENDOR = float(_w("PRIDE_SPLENDOR", 0.3))
PRIDE_AWE = float(_w("PRIDE_AWE", 0.25))
PRIDE_ALLURE = float(_w("PRIDE_ALLURE", 0.15))


def renown(r: dict) -> dict:
    """standing.gd renown and pride, centred on the typical people of the age."""
    culture = float(r.get("_culture_score", 0.5))
    awe = clamp(AWE_ORDINARY + (r["might"] - .5) * .45 + (r["splendor"] - .5) * .35 + (r["genius"] - .5) * .3, 0.0, 1.0)
    menace = max(0.0, r["might"] - MENACE_FROM) * RENOWN_MENACE
    allure = clamp(ALLURE_ORDINARY + (r["splendor"] - .5) * .2 + (culture - .5) * .2 + (r["wealth"] - .5) * .2 + (r["genius"] - .5) * .1
                   + (r["order"] - .5) * .1 + (r["persuasion"] - .5) * PERSUASION_ALLURE - menace, 0.0, 1.0)
    pride = clamp(.5 + (r["splendor"] - .5) * PRIDE_SPLENDOR + (awe - AWE_ORDINARY) * PRIDE_AWE + (allure - ALLURE_ORDINARY) * PRIDE_ALLURE, 0.0, 1.0)
    return {"awe": awe, "allure": allure, "pride": pride}


def forewarn_odds(cunning):
    return clamp(FOREWARN_ODDS_TYPICAL + (cunning - 0.5) * FOREWARN_ODDS_SLOPE, 0.05, 0.95)


NINE = ["might", "endurance", "wealth", "reach", "persuasion", "splendor", "genius", "cunning", "order"]
