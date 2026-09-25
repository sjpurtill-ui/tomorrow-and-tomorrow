"""Epochal shock model for the surrogate (standalone; integrate after the years 600-1200 research pass).

    from tools.sim.shocks import apply_shocks, apply_deltas, apply_emergence, apply_changes

See docs/research/epochal/EPOCHAL_SHIFTS.md for the design, calibration and interface.
"""
from .engine import STATE_KEYS, LEVEL_KEYS, apply_deltas, apply_shocks, reset_slot, retire_slot
from .emergence import apply_changes, apply_emergence

__all__ = ["apply_shocks", "apply_deltas", "apply_emergence", "apply_changes", "reset_slot", "retire_slot",
           "STATE_KEYS", "LEVEL_KEYS"]
