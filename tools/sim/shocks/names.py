"""In-world naming for shocks and newborn peoples (alternative history: no real names).

Everything the game shows is generated from the affected peoples' own sound-stock. The
sound-stock is read from the game's fictional identity roster
(``scripts/civilization_identity.gd`` PROFILES: a people name plus five city names), so a
successor state sounds like its parent, and a shock is named after the place it struck.

Shock *kinds* (``KINDS``) are generic ids; ``event_name`` turns a kind into a chronicle
name such as "the Grey Sickness of the Merren years" or "the Unmaking of Kassul".
"""
from __future__ import annotations

import os
import re

import numpy as np

_FALLBACK = [["Orathi", "Kassul", "Merren", "Tabor", "Uskel", "Nareth"],
             ["Veyra", "Solenne", "Arbrin", "Delsa", "Ivrel", "Korven"],
             ["Keshan", "Adurat", "Beshir", "Zerak", "Ishmet", "Qasra"],
             ["Talovar", "Dravin", "Oskara", "Belgor", "Nesvik", "Kaldren"]]


def _load_profiles():
    here = os.path.dirname(os.path.abspath(__file__))
    for up in range(1, 6):
        root = os.path.abspath(os.path.join(here, *[".."] * up))
        path = os.path.join(root, "scripts", "civilization_identity.gd")
        if os.path.exists(path):
            try:
                text = open(path, encoding="utf8").read()
                block = text[text.index("PROFILES"):text.index("PALETTES")]
                rows = [re.findall(r'"([^"]*)"', a) for a in re.findall(r'\[\s*((?:"[^"]*",?\s*)+)\]', block)]
                rows = [r for r in rows if len(r) >= 2]
                if rows:
                    return rows
            except (OSError, ValueError):
                pass
    return _FALLBACK


PROFILES = _load_profiles()
_SYL = re.compile(r"[^aeiouy]*[aeiouy]+(?:[^aeiouy](?=[^aeiouy]|$))?", re.I)


def _syllables(word):
    parts = _SYL.findall(word.lower())
    return parts if parts else [word.lower()]


# Descriptive English place names (e.g. "Seven Wells", "Chalkhaven") are kept whole for cities but are
# not mined for syllables, so generated names stay in the invented sound-world.
_ENGLISH = ("haven", "well", "mere", "ford", "wick", "bank", "fold", "watch", "crest", "water", "ridge", "gate",
            "barrow", "pool", "court", "mark", "bridge", "fell", "beacon", "bracken", "cistern", "holster", "saltern",
            "bell", "oak", "ash", "reed", "wood", "stone", "basket", "flint", "flame", "ember", "drift", "sedge",
            "spring", "still", "tide", "wren", "wicker", "moss", "crow", "fen", "marsh", "mill", "glass", "gull", "chalk",
            "cinder", "deep", "salt", "red")
_WORDS = [w for row in PROFILES for w in row if w.isalpha() and not any(e in w.lower() for e in _ENGLISH)]
_STOCK = sorted({s for w in _WORDS for s in _syllables(w)})
_ENDINGS = sorted({_syllables(w)[-1] for w in _WORDS})


def _cap(s):
    return s[:1].upper() + s[1:]


def people_name(rng, parent: str | None = None, used: set | None = None) -> str:
    """A new people's name. With ``parent`` it keeps the parent's first syllable (lineage)."""
    used = used if used is not None else set()
    for _ in range(40):
        if parent:
            head = _syllables(parent)[0]
            name = head + str(rng.choice(_STOCK)) + (str(rng.choice(_ENDINGS)) if rng.random() < 0.4 else "")
        else:
            name = "".join(str(rng.choice(_STOCK)) for _ in range(int(rng.integers(2, 4))))
        name = _cap(re.sub(r"(.)\1\1", r"\1\1", name))
        if 4 <= len(name) <= 11 and name not in used:
            used.add(name)
            return name
    return _cap(parent or "Nameless") + str(int(rng.integers(2, 99)))


def place_names(rng, people: str, count: int = 5) -> list:
    head = _syllables(people)[0]
    return [_cap(head[:2] + str(rng.choice(_STOCK)) + str(rng.choice(_ENDINGS))) if rng.random() < 0.5
            else _cap(str(rng.choice(_STOCK)) + str(rng.choice(_ENDINGS))) for _ in range(count)]


def profile(index: int) -> dict:
    row = PROFILES[index % len(PROFILES)]
    return {"name": row[0], "cities": list(row[1:])}


# --- generic shock kinds ------------------------------------------------------------------
KINDS = {
    "climate": ["long_winter", "cold_year", "great_drought", "drought_years", "cold_age"],
    "famine": ["great_hunger", "hunger"],
    "pandemic": ["great_pestilence", "pestilence", "fever", "stranger_sickness"],
    "war": ["war_of_many_peoples", "grinding_war", "general_war", "war_of_opportunity"],
    "migration": ["horde_conquest", "rider_raids", "folk_wandering", "border_migration"],
    "economic": ["debt_crisis", "coin_ruin", "broken_treasury", "market_crash"],
    "upheaval": ["prophet_schism", "new_faith", "great_schism", "overturning"],
    "tech": ["new_metal", "press_and_powder", "engine_age", "lightning_age", "thinking_machines"],
    "collapse": ["state_collapse", "systemic_collapse"],
}
KIND_TITLES = {  # generic, player-facing category labels
    "long_winter": "long winter", "cold_year": "cold year", "great_drought": "great drought", "drought_years": "drought years",
    "cold_age": "cold age", "great_hunger": "great hunger", "hunger": "hunger", "great_pestilence": "great pestilence",
    "pestilence": "pestilence", "fever": "fever", "stranger_sickness": "strangers' sickness",
    "war_of_many_peoples": "war of many peoples", "grinding_war": "grinding war", "general_war": "general war",
    "war_of_opportunity": "war of opportunity", "horde_conquest": "horde conquest", "rider_raids": "rider raids",
    "folk_wandering": "folk wandering", "border_migration": "border migration", "debt_crisis": "debt crisis",
    "coin_ruin": "coin ruin", "broken_treasury": "broken treasury", "market_crash": "market crash",
    "prophet_schism": "prophet's schism", "new_faith": "new faith", "great_schism": "great schism", "overturning": "overturning",
    "new_metal": "new metal", "press_and_powder": "press and powder", "engine_age": "engine age", "lightning_age": "lightning age",
    "thinking_machines": "thinking machines", "state_collapse": "unmaking", "systemic_collapse": "great unravelling",
}
_COLORS = ["Grey", "Pale", "Ash", "Blue", "Speckled", "Weeping", "Silent", "Bitter"]
_TEMPLATES = {
    "great_pestilence": ["the {color} Sickness of the {place} years", "the Great Emptying of the {people}", "the {color} Death"],
    "pestilence": ["the {place} Fever", "the Wasting of {place}", "the {color} Cough"],
    "fever": ["the Summer Fever of {place}", "the {place} Chills"],
    "stranger_sickness": ["the Strangers' Sickness", "the Sickness from over the Water", "the {color} Spots"],
    "long_winter": ["the Ash Winter of the {people}", "the Dim-Sun Years", "the Long Winter"],
    "cold_year": ["the Frost Harvest of {place}", "the Cold Year of {place}"],
    "great_drought": ["the Great Thirst", "the Dry Centuries of {place}"],
    "drought_years": ["the Dust Years of {place}", "the Thirst of {place}"],
    "cold_age": ["the Grey Age", "the Age of Frost"],
    "great_hunger": ["the Empty Granaries of {place}", "the Lean Years of the {people}"],
    "hunger": ["the {place} Hunger", "the Bitter Bread of {place}"],
    "war_of_many_peoples": ["the War of {n} Peoples", "the Great Burning"],
    "grinding_war": ["the Grinding War of the {people}", "the Long Burning of {place}"],
    "general_war": ["the War of the {people} and the {other}", "the {place} War"],
    "war_of_opportunity": ["the {people} Raid-War", "the Seizing of {place}"],
    "horde_conquest": ["the Coming of the {other}", "the {color} Riders"],
    "rider_raids": ["the Rider Raids on {place}", "the Hoofbeat Years"],
    "folk_wandering": ["the Wandering of the {other}", "the Faring of the {other}"],
    "border_migration": ["the Settling of the {other}", "the {place} Newcomers"],
    "debt_crisis": ["the Debt Years of {place}", "the Broken Tallies"],
    "coin_ruin": ["the Clipped-Coin Years", "the Ruin of the {place} Coin"],
    "broken_treasury": ["the Empty Treasury of the {people}", "the Unpaid Years"],
    "market_crash": ["the Crash of {place}", "the Long Slump of the {people}"],
    "prophet_schism": ["the Schism of the {place} Seer", "the Two Altars"],
    "new_faith": ["the Rising of the {place} Way", "the Turning of the {people}"],
    "great_schism": ["the Sundering of the {people}", "the Quarrel of Altars"],
    "overturning": ["the Overturning at {place}", "the {place} Rising"],
    "new_metal": ["the Dark-Metal Turn", "the New Forges of {place}"],
    "press_and_powder": ["the Press and Powder Age", "the {place} Printers' Age"],
    "engine_age": ["the Age of Engines", "the Smoke Years of {place}"],
    "lightning_age": ["the Bottled-Lightning Age", "the Wire Years"],
    "thinking_machines": ["the Age of Thinking Machines", "the Counting-Engine Turn"],
    "state_collapse": ["the Unmaking of {place}", "the Fall of {place}", "the Darkening of the {people}"],
    "systemic_collapse": ["the Great Unravelling", "the Breaking of the {n} Crowns"],
}


def event_name(kind: str, rng, people: str = "", place: str = "", other: str = "", n: int = 3) -> str:
    template = str(rng.choice(_TEMPLATES.get(kind, ["the {place} Troubles"])))
    return template.format(color=str(rng.choice(_COLORS)), people=people or "People", place=place or people or "the Realm",
                           other=other or people_name(rng), n=_NUMBER.get(n, str(n)))


_NUMBER = {2: "Two", 3: "Three", 4: "Four", 5: "Five", 6: "Six", 7: "Seven", 8: "Eight", 9: "Nine", 10: "Ten"}
