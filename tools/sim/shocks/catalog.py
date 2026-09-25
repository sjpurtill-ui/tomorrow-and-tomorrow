"""Epochal shock catalog: era clock, per-type calibration tables, historical base rates.

Every number here is a *calibration anchor*, not a script. Shocks fire only through the
hazard functions in ``engine.py``; the anchors set the per-century rate a typical polity
of that era would see, and the state variables push the hazard up or down from there.

Two clocks
----------
* Lived clock (game years). People are born, age and die on the game calendar, so rates
  that describe what a population lives through (plagues, famines, wars, collapses) are
  expressed per *game* century. A villager's lifetime sees the same number of plagues it
  would have historically.
* Era clock (historical year). The game compresses 7,000 years of technology into 3,000
  game years (``TechnologyEras.CURVE``). The era a civ has reached decides which shocks
  exist at all (no monetary crisis before credit, no industrial total war before
  industry) and how large they get. Each civ's era is its own knowledge frontier, so a
  lagging AI civ keeps pre-modern hazards while its neighbour industrialises.
"""
from __future__ import annotations

import numpy as np

# Mirror of scripts/technology_eras.gd CURVE: [game_year, historical_year].
ERA_CURVE = np.array([[0, -5000], [300, -3000], [800, -500], [1500, 1000], [2000, 1600],
                      [2400, 1800], [2800, 1950], [3000, 2030]], dtype=float)


def hist_year(era_year):
    """Game-year-equivalent knowledge frontier -> historical year (vectorised)."""
    return np.interp(np.asarray(era_year, dtype=float), ERA_CURVE[:, 0], ERA_CURVE[:, 1])


def era_year_for(historical_year):
    """Historical year -> game-year equivalent (inverse of hist_year)."""
    return np.interp(np.asarray(historical_year, dtype=float), ERA_CURVE[:, 1], ERA_CURVE[:, 0])


def ramp(points, H):
    """Piecewise-linear lookup of an era table [(historical_year, value), ...]."""
    pts = np.asarray(points, dtype=float)
    return np.interp(H, pts[:, 0], pts[:, 1])


TYPES = ["climate", "famine", "pandemic", "migration", "war", "economic", "upheaval", "tech", "collapse"]
T_INDEX = {t: k for k, t in enumerate(TYPES)}

ERA_BANDS = [  # (label, historical year from, to) used for reporting only
    ("village", -9999, -3500), ("bronze", -3500, -1200), ("classical", -1200, 500),
    ("medieval", 500, 1450), ("early_modern", 1450, 1800), ("industrial", 1800, 1945), ("modern", 1945, 9999)]


def era_band(H: float) -> str:
    for name, lo, hi in ERA_BANDS:
        if lo <= H < hi:
            return name
    return "modern"


# ---------------------------------------------------------------------------------------
# Base rates at the reference state, per game century, as (historical_year, rate) ramps.
# The reference state is an "ordinary" polity of its era: legitimacy/cohesion 0.6,
# inequality 0.45, trade 0.4, density 0.4, institutions at era norm, no active stress.
# Exogenous rates (climate) are per region/world; endogenous ones per civ.
# ---------------------------------------------------------------------------------------
BASE = {
    # New pathogen emergence per civ (spreads through the contact graph afterwards).
    "pandemic_emerge": [(-5000, 0.01), (-3000, 0.08), (-1200, 0.075), (0, 0.055), (1300, 0.08),
                        (1700, 0.07), (1900, 0.035), (2030, 0.03)],
    # Escalation of an existing war into a general / total war, per war-dyad-year x100.
    "war_escalate": [(-5000, 0.3), (-2000, 0.5), (0, 0.6), (1000, 0.9), (1600, 1.3), (1800, 1.3),
                     (1914, 2.2), (1950, 0.5), (2030, 0.35)],
    # Opportunity/pressure war started directly by shock pressure (migration, schism, vacuum).
    "war_pressure": [(-5000, 0.05), (-2000, 0.08), (1000, 0.10), (1600, 0.12), (1950, 0.035), (2030, 0.025)],
    # Nomad/frontier pressure multiplier (rises with chariots, then mounted archery; falls with gunpowder).
    "nomad": [(-5000, 0.25), (-2000, 0.45), (-1800, 0.8), (-900, 1.0), (1200, 1.25), (1500, 0.8),
              (1700, 0.45), (1850, 0.08), (1950, 0.02), (2030, 0.02)],
    "migration": [(-5000, 0.60), (2030, 0.60)],
    # Money/credit crises: from the first silver-credit economies onward; sovereign defaults later.
    "economic": [(-5000, 0.0), (-3000, 0.04), (-2200, 0.25), (-500, 0.30), (1000, 0.30),
                 (1500, 0.55), (1800, 0.85), (1950, 1.50), (2030, 1.50)],
    "upheaval": [(-5000, 0.06), (-2000, 0.08), (-800, 0.14), (0, 0.14), (600, 0.16), (1500, 0.22),
                 (1800, 0.20), (1950, 0.15), (2030, 0.15)],
    "tech": [(-5000, 0.05), (-3000, 0.12), (-1200, 0.15), (1000, 0.12), (1450, 0.15), (1700, 0.18), (1760, 0.45),
             (1900, 0.60), (1970, 0.70), (2030, 0.7)],
    "collapse": [(-5000, 0.10), (-3000, 0.20), (0, 0.18), (1500, 0.12), (1800, 0.04), (1950, 0.03),
                 (2030, 0.05)],
}

# Climate is exogenous: rates per game century for the world or a region.
CLIMATE = {
    "volcanic_notable": 1.3,   # VEI-6-class eruption: 1-2 bad harvest years
    "volcanic_severe": 0.10,   # double-eruption volcanic winter with a decade-long tail
    "megadrought": 0.14,       # per region: multi-decade to multi-century aridity
    "cold_epoch": 0.04,        # world: multi-century cooling
}

# War magnitude by era.
WAR_MOBILIZATION_CAP = [(-5000, 0.03), (-1200, 0.05), (0, 0.07), (1000, 0.03), (1600, 0.04),
                        (1790, 0.07), (1860, 0.09), (1914, 0.18), (1945, 0.20), (1960, 0.08), (2030, 0.05)]
WAR_MORTALITY_MEDIAN = [(-5000, 0.03), (0, 0.04), (1000, 0.03), (1600, 0.07), (1700, 0.03),
                        (1800, 0.03), (1914, 0.035), (1939, 0.06), (1960, 0.02), (2030, 0.015)]
WAR_DURATION_MEDIAN = [(-5000, 5.0), (1000, 6.0), (1600, 10.0), (1700, 7.0), (1800, 6.0),
                       (1914, 4.5), (2030, 4.0)]

# Health knowledge efficacy against pandemics: modern medicine is decisive, pre-modern weak.
# (Effective protection = health_knowledge * this ceiling.)
MEDICINE_CEILING = [(-5000, 0.35), (1400, 0.45), (1850, 0.8), (1900, 0.9), (1945, 0.95), (2030, 0.95)]

# Share of reported per-century rates that are expected for a *typical* civ in the band.
# Values: (low, high) per game century per polity. Sources in EPOCHAL_SHIFTS.md.
HISTORICAL_BASE_RATES = {
    #                        ancient(bronze-classical)  medieval-early modern   industrial-modern
    "pandemic>=5%":          {"ancient": (0.2, 0.7), "medieval": (0.5, 1.6), "modern": (0.0, 0.3)},
    "pandemic>=25%":         {"ancient": (0.0, 0.1), "medieval": (0.03, 0.2), "modern": (0.0, 0.03)},
    "famine>=2%":            {"ancient": (0.5, 1.5), "medieval": (0.5, 2.0), "modern": (0.05, 0.4)},
    "climate shock":         {"ancient": (1.0, 2.5), "medieval": (1.0, 2.5), "modern": (1.0, 2.5)},
    "collapse":              {"ancient": (0.15, 0.5), "medieval": (0.1, 0.4), "modern": (0.03, 0.2)},
    "general war":           {"ancient": (0.15, 0.6), "medieval": (0.3, 1.0), "modern": (0.2, 0.8)},
    "invasion/migration":    {"ancient": (0.15, 0.6), "medieval": (0.15, 0.6), "modern": (0.0, 0.15)},
    "economic crisis":       {"ancient": (0.1, 0.8), "medieval": (0.4, 1.5), "modern": (0.8, 2.5)},
    "upheaval":              {"ancient": (0.1, 0.4), "medieval": (0.2, 0.6), "modern": (0.2, 0.7)},
    "tech disruption":       {"ancient": (0.03, 0.2), "medieval": (0.1, 0.4), "modern": (0.5, 1.5)},
}

BAND_GROUP = {"village": "ancient", "bronze": "ancient", "classical": "ancient", "medieval": "medieval",
              "early_modern": "medieval", "industrial": "modern", "modern": "modern"}

# Magnitude and frequency calibration references (real history, used only as calibration) are in
# docs/research/epochal/EPOCHAL_SHIFTS.md, "Calibration sources". Nothing in code names real events.
