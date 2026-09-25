"""Read-only bridges from the surrogate (``tools/sim/model.py``) to a shock-state row.

SIM owns ``tools/sim``; nothing here edits it. When SIM integrates shocks (after the
years 600-1200 research pass), it can build one row per society with
``row_from_surrogate(sur)`` and stack rows with ``stack_rows``; or map its own
multi-civ state directly using the table in EPOCHAL_SHIFTS.md.
"""
from __future__ import annotations

import numpy as np

from .engine import STATE_KEYS


def _eff(sur, key, default=0.0):
    try:
        return float(sur.eff(key))
    except Exception:
        return default


def row_from_surrogate(sur, capacity=None, territory=1.0) -> dict:
    """One civ's shock-state values from a ``Surrogate`` instance (attributes read with fallbacks)."""
    pop = float(sur.population) if not callable(getattr(sur, "population", None)) else float(sur.population())
    stored_days = float(sur.stored_days) if not callable(getattr(sur, "stored_days", None)) else float(sur.stored_days())
    health_protect = (_eff(sur, "health_protection") + _eff(sur, "sanitation") + _eff(sur, "water_safety")) / 3.0
    settlements = float(getattr(sur, "settlements", 1))
    return {
        "pop": pop,
        "capacity": float(capacity if capacity is not None else max(pop, getattr(sur, "housing_capacity", pop))),
        "era_year": float(getattr(sur, "ceiling_era", 0.0)) or float(getattr(sur, "day", 0.0)) / 365.0,
        "density": float(np.clip(pop / max(1.0, settlements) / 5000.0, 0.02, 1.0)),
        "trade": float(np.clip(0.15 + _eff(sur, "trade_capacity") + 0.5 * getattr(sur, "logistics", 0.16), 0, 1)),
        "health_knowledge": float(np.clip(0.05 + health_protect - 0.5 * _eff(sur, "disease_exposure"), 0, 1)),
        "food_reserve": stored_days / 365.0,
        "diversification": float(np.clip(getattr(sur, "diet_window", 0.5), 0, 1)),
        "inequality": 0.45,   # the surrogate has no inequality variable yet: see EPOCHAL_SHIFTS.md
        "legitimacy": float(getattr(sur, "legitimacy", 0.6)),
        "cohesion": float(getattr(sur, "cohesion", 0.6)),
        "institutions": float(np.clip(getattr(sur, "capacities", {}).get("labor", 0.5) * 0.5
                                      + getattr(sur, "education", 0.2) * 0.5, 0, 1)),
        "overextension": float(np.clip(0.3 - getattr(sur, "logistics", 0.16) + 0.1 * (settlements - 1), 0, 1)),
        "mobilization": float(np.clip(getattr(sur, "security", 0.38) * 0.03, 0, 0.3)),
        "knowledge": float(getattr(sur, "knowledge_metric", 0.2)),
        "productivity": 1.0,
        "territory": float(territory),
    }


def stack_rows(rows: list) -> dict:
    """Combine per-civ rows into the array state ``apply_shocks`` expects."""
    keys = set().union(*rows)
    out = {k: np.array([r.get(k, STATE_KEYS.get(k, (0.0,))[0] or 0.0) for r in rows], dtype=float) for k in keys}
    out["alive"] = np.ones(len(rows), dtype=bool)
    return out
