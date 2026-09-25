"""A stand-in multi-civ world for the shock Monte Carlo (not the game, not SIM).

The surrogate in ``tools/sim/model.py`` simulates one society in detail. Shocks are a
multi-civ phenomenon, so this module provides a deliberately simple host: logistic
population toward a capacity that grows with era, levels that relax toward era norms
(inequality creeps up in peace), ordinary border wars and alliances, and contact that
depends on distance and on how far each era can reach. The shock engine and the
emergence model are what is being tested; this host only has to be plausible.
"""
from __future__ import annotations

import math

import numpy as np

from . import names as nm
from .catalog import era_year_for, hist_year, ramp
from .engine import apply_deltas, apply_shocks
from .emergence import apply_changes, apply_emergence

PEOPLE_PER_TERRITORY = [(-5000, 1.5), (-3000, 3.5), (-1000, 6.0), (1000, 9.0), (1700, 14.0), (1850, 30.0),
                        (1950, 80.0), (2030, 110.0)]            # thousands of people per territory unit
GROWTH = [(-5000, 0.010), (1700, 0.012), (1850, 0.02), (1950, 0.025), (2030, 0.012)]
INST_NORM = [(-5000, 0.15), (-3000, 0.4), (0, 0.55), (1500, 0.6), (1900, 0.75), (2030, 0.8)]
TRADE_NORM = [(-5000, 0.12), (-2000, 0.25), (0, 0.4), (1500, 0.5), (1850, 0.65), (2030, 0.8)]
DENS_NORM = [(-5000, 0.12), (-3000, 0.3), (0, 0.4), (1500, 0.45), (1900, 0.6), (2030, 0.75)]
HK_NORM = [(-5000, 0.03), (1500, 0.12), (1850, 0.3), (1920, 0.55), (1960, 0.8), (2030, 0.9)]
KNOW_NORM = [(-5000, 0.15), (-1000, 0.3), (1000, 0.4), (1700, 0.55), (1900, 0.75), (2030, 0.95)]
LAND_REACH = [(-5000, 110.0), (-1000, 150.0), (1000, 180.0), (1700, 220.0), (1850, 320.0), (1950, 450.0), (2030, 600.0)]
SEA_REACH = [(-5000, 1.0), (1400, 1.0), (1550, 2600.0), (1900, 4500.0), (2030, 9000.0)]   # ocean crossing


class World:
    def __init__(self, rng, n_start=16, slots=36, mode="campaign", fixed_H=None, isolated=0, pace_sd=0.08):
        self.rng = rng
        self.mode, self.fixed_H = mode, fixed_H
        n = slots
        self.n = n
        s = {}
        alive = np.zeros(n, dtype=bool)
        alive[:n_start + isolated] = True
        # Old-world civs in 3 clusters; optional isolated cluster far across the sea.
        xs, ys, reg = np.zeros(n), np.zeros(n), np.zeros(n, dtype=int)
        centres = [(0, 0), (380, 120), (160, 420)]
        for i in range(n_start):
            r = i % 3
            reg[i] = r
            xs[i] = centres[r][0] + rng.normal(0, 110)
            ys[i] = centres[r][1] + rng.normal(0, 110)
        for k in range(isolated):
            i = n_start + k
            reg[i] = 9
            xs[i] = 3200 + rng.normal(0, 120)
            ys[i] = 300 + rng.normal(0, 120)
        s["alive"] = alive
        s["x"], s["y"], s["region"] = xs, ys, reg
        s["pace"] = np.clip(rng.normal(1.0, pace_sd, n), 0.75, 1.2)
        s["territory"] = np.where(alive, rng.lognormal(0, 0.4, n), 0.0)
        s["era_year"] = np.zeros(n)
        self._set_era(s, 0)
        H = hist_year(s["era_year"])
        K = s["territory"] * ramp(PEOPLE_PER_TERRITORY, H) * 1000
        s["capacity"] = K
        s["pop"] = np.where(alive, K * rng.uniform(0.6, 0.85, n), 0.0)
        s["founding_pop"] = s["pop"].copy()
        s["cap_bonus"] = np.ones(n)
        s["density"] = ramp(DENS_NORM, H) * rng.uniform(0.8, 1.2, n)
        s["trade"] = ramp(TRADE_NORM, H) * rng.uniform(0.7, 1.3, n)
        s["health_knowledge"] = ramp(HK_NORM, H) * np.ones(n)
        s["knowledge"] = ramp(KNOW_NORM, H) * rng.uniform(0.9, 1.1, n)
        s["institutions"] = ramp(INST_NORM, H) * rng.uniform(0.8, 1.1, n)
        s["food_reserve"] = 0.2 * np.ones(n)
        s["diversification"] = rng.uniform(0.2, 0.7, n)
        s["inequality"] = rng.uniform(0.35, 0.55, n)
        s["legitimacy"] = rng.uniform(0.5, 0.7, n)
        s["cohesion"] = rng.uniform(0.5, 0.7, n)
        s["overextension"] = np.zeros(n)
        s["mobilization"] = 0.01 * np.ones(n)
        s["productivity"] = np.ones(n)
        s["aggression"] = rng.uniform(0.2, 0.7, n)
        s["steppe_exposure"] = np.where(reg == 1, rng.uniform(0.3, 0.9, n), rng.uniform(0.0, 0.25, n))
        s["disease_endowment"] = np.where(reg == 9, 0.2, 1.0)
        s["is_player"] = np.zeros(n, dtype=bool)
        s["is_player"][0] = True
        s["devotion"] = np.where(s["is_player"], 0.8, 0.0)
        used = set()
        s["names"] = [""] * n
        s["cities"] = [[] for _ in range(n)]
        for i in np.where(alive)[0]:
            p = nm.profile(int(rng.integers(0, 10_000)))
            name = p["name"] if p["name"] not in used else nm.people_name(rng, used=used)
            used.add(name)
            s["names"][i] = name
            s["cities"][i] = p["cities"] if name == p["name"] else nm.place_names(rng, name)
        self.state = s
        self.graph = {"war": np.zeros((n, n), dtype=bool), "alliance": np.zeros((n, n), dtype=bool),
                      "region": s["region"], "contact": np.zeros((n, n)), "trade": np.zeros((n, n))}
        self.trade_scar = np.ones((n, n))
        self._graph()

    def _set_era(self, s, year):
        if self.mode == "fixed":
            s["era_year"] = np.full(len(s["pace"]), float(era_year_for(self.fixed_H)))
        else:
            s["era_year"] = np.clip(year * s["pace"], 0, 3000)

    def _graph(self):
        s, g = self.state, self.graph
        alive = s["alive"]
        d = np.hypot(s["x"][:, None] - s["x"][None, :], s["y"][:, None] - s["y"][None, :])
        H = hist_year(s["era_year"])
        Hp = np.maximum(H[:, None], H[None, :])
        contact = np.maximum(np.exp(-d / ramp(LAND_REACH, Hp)), 0.25 * np.exp(-d / ramp(SEA_REACH, Hp)))
        contact = contact * np.outer(alive, alive)
        np.fill_diagonal(contact, 0.0)
        g["contact"] = contact
        g["trade"] = contact * np.sqrt(np.outer(s["trade"], s["trade"])) * self.trade_scar
        g["region"] = s["region"]

    def step(self, year):
        s, g, rng = self.state, self.graph, self.rng
        alive = s["alive"]
        self._set_era(s, year)
        H = hist_year(s["era_year"])
        # --- ordinary host dynamics ------------------------------------------------------
        s["cap_bonus"] += 0.005 * (1.0 - s["cap_bonus"])
        K = s["territory"] * ramp(PEOPLE_PER_TERRITORY, H) * 1000 * s["cap_bonus"]
        s["capacity"] = np.maximum(K, 1.0)
        r = ramp(GROWTH, H)
        s["pop"] = np.where(alive, s["pop"] * (1 + r * (1 - s["pop"] / s["capacity"]) + rng.normal(0, 0.003, self.n)), 0.0)
        def relax(key, target, rate, noise=0.0):
            s[key] = s[key] + rate * (target - s[key]) + (rng.normal(0, noise, self.n) if noise else 0.0)
        relax("legitimacy", 0.62, 0.03, 0.01)
        relax("cohesion", 0.6, 0.03, 0.01)
        relax("institutions", ramp(INST_NORM, H), 0.015, 0.005)
        relax("inequality", 0.62, 0.003, 0.004)
        relax("trade", ramp(TRADE_NORM, H), 0.02)
        relax("density", ramp(DENS_NORM, H), 0.01)
        relax("health_knowledge", ramp(HK_NORM, H), 0.02)
        relax("knowledge", ramp(KNOW_NORM, H), 0.02)
        relax("food_reserve", 0.12 + 0.35 * s["institutions"], 0.2)
        relax("productivity", 1.0, 0.02)
        relax("mobilization", np.where(H > 1900, 0.015, 0.01), 0.3)
        tmed = np.median(s["territory"][alive]) if alive.any() else 1.0
        reach = ramp(LAND_REACH, H) / 150.0
        s["overextension"] = np.clip(0.25 * s["territory"] / tmed / np.sqrt(reach) + 0.2 * (1 - s["institutions"])
                                     + rng.normal(0, 0.03, self.n), 0, 1)
        for k in ("legitimacy", "cohesion", "institutions", "inequality", "trade", "density", "health_knowledge", "knowledge"):
            s[k] = np.clip(s[k], 0.0, 1.0)
        self.trade_scar += 0.03 * (1.0 - self.trade_scar)
        self._graph()
        # --- ordinary border wars and alliances ----------------------------------------------
        c = g["contact"]
        pair_alive = np.outer(alive, alive)
        aggr = 0.5 * (s["aggression"][:, None] + s["aggression"][None, :])
        start = np.triu(rng.random((self.n, self.n)) < 0.0012 * c * aggr * pair_alive, 1)
        g["war"] |= start | start.T
        stop = np.triu(rng.random((self.n, self.n)) < 0.25, 1)
        g["war"] &= ~(stop | stop.T)
        if np.median(H) > -2500:
            form = np.triu(rng.random((self.n, self.n)) < 0.004 * c * pair_alive, 1)
            g["alliance"] |= form | form.T
            brk = np.triu(rng.random((self.n, self.n)) < 0.03, 1)
            g["alliance"] &= ~(brk | brk.T)
        g["alliance"] &= ~g["war"]
        g["war"] &= pair_alive
        g["alliance"] &= pair_alive
        # --- shocks, then emergence ---------------------------------------------------------
        events, D = apply_shocks(s, g, rng, year)
        apply_deltas(s, g, D)
        if D["trade_link_mult"] is not None:
            self.trade_scar *= D["trade_link_mult"]
        s["cap_bonus"] *= D["capacity_mult"]
        eevents, changes = apply_emergence(s, g, rng, year, events)
        apply_changes(s, g, changes, year)
        if changes["births"] or changes["deaths"]:
            self.trade_scar[:, [b["slot"] for b in changes["births"]]] = 1.0
            self.trade_scar[[b["slot"] for b in changes["births"]], :] = 1.0
            self._graph()
        return events, eevents, D
