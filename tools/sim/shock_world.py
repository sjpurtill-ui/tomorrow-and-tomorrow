"""Opt-in epochal shocks for the surrogate: the player's society inside a multi-civ world.

    simlib.run("sensible", seed, 600, shocks=True)        # or run.py/matrix.py/sweep_strategies.py --shocks

Off by default. Nothing here changes ``model.Surrogate``: ``ShockSurrogate`` subclasses it
and only adds three hooks that are exact no-ops until a shock lands:

* ``_conditions`` (called at every year boundary) steps the world once per game year;
* ``_weather`` is multiplied by this year's shock food multiplier (1.0 without shocks);
* ``policy("labor_multiplier")`` is scaled by the shock output multiplier x productivity.

The world (``SurrogateWorld``) is the shock package's stand-in host (``shocks.world.World``)
with slot 0 bound to the detailed surrogate. Rivals are lightweight rows (logistic
population toward an era capacity, levels relaxing toward era norms) with the contact /
trade / war / alliance graph; emergence spawns and absorbs peoples within the slot budget.
Every name comes from ``shocks.names`` (in-world sound-stock; no real-history names).

Player row each year (read from the surrogate; strategy choices move these):
    pop, capacity (food security), era_year (ceiling_era), density (era norm x crowding),
    trade (logistics capacity + trade_capacity), health_knowledge (health_protection,
    sanitation, water_safety, disease_exposure), food_reserve (stored days / 365),
    diversification (diet window), legitimacy, cohesion, institutions (institutions
    capacity + education, x era norm), knowledge (knowledge_metric x era norm),
    mobilization (defense share).
Feedback (deltas -> surrogate): cohorts scaled by the pop change (deaths, emigrants,
immigrants, secessions, unions, the god following a people); this year's food and output
multipliers; legitimacy/cohesion added; institutions/knowledge/health-knowledge losses
remove adoption of known practices in the matching lines (they regrow through the
surrogate's own adoption dynamics = recovery); trade losses hit logistics; stores lost;
lasting capacity loss hits housing.
"""
from __future__ import annotations

import collections

import numpy as np

import gamedata as gd
from model import Surrogate
from shocks import apply_deltas, apply_emergence, apply_shocks, apply_changes
from shocks.catalog import TYPES, hist_year, ramp
from shocks.world import (DENS_NORM, GROWTH, INST_NORM, KNOW_NORM, LAND_REACH, PEOPLE_PER_TERRITORY, TRADE_NORM,
                          HK_NORM, World)

DEFAULTS = {
    "slots": 24,            # civ slot budget (player + rivals + room for new peoples)
    "n_start": 10,          # peoples alive at the start (player included)
    "rival_scale": 0.3,     # rival people per territory vs the stand-in world's table (surrogate band scale)
    "harvest_noise_sd": 0.0,  # the surrogate draws its own weather
    "rate_scale": 1.0,
    "min_viable_pop": 40.0,
    "surrogate_famine": True,   # the player's famine deaths come from the surrogate's own hunger model
}
INST_LINES = ("institutions", "infrastructure", "logistics", "security")
ROW_KEYS = ("institutions", "health_knowledge", "knowledge", "food_reserve", "diversification", "trade", "density", "legitimacy",
            "cohesion", "inequality")


def _lines_mask(cat, lines):
    idx = [gd.LINES.index(l) for l in lines]
    return np.isin(cat.line, idx)


class SurrogateWorld(World):
    """``shocks.world.World`` whose slot ``player`` is driven by a ``Surrogate``."""

    def __init__(self, rng, sur, opts):
        self.o = opts
        super().__init__(rng, n_start=int(opts["n_start"]), slots=int(opts["slots"]), mode="campaign")
        s = self.state
        k = float(opts["rival_scale"])
        s["pop"] *= k
        s["capacity"] *= k
        s["founding_pop"] *= k
        s["civ_uid"] = np.zeros(self.n, dtype=int)   # filled by emergence memory on first call
        self.player = 0
        s["aggression"][0] = 0.25
        s["inequality"][0] = 0.45
        s["territory"][0] = max(0.6, float(s["territory"][0]))
        self.sur = sur
        self.write_player()
        s["founding_pop"][0] = s["pop"][0]
        self.params = {"harvest_noise_sd": float(opts["harvest_noise_sd"]), "rate_scale": float(opts["rate_scale"])}
        self.eparams = {"min_viable_pop": float(opts["min_viable_pop"])}

    # ------------------------------------------------------------ player <-> row
    def write_player(self):
        s, sur, p = self.state, self.sur, self.player
        pop = max(1.0, float(sur.population))
        era = float(sur.ceiling_era)
        H = float(hist_year(era))
        cap = sur.capacities
        e = sur.eff
        crowd = pop / max(1.0, float(sur.housing_capacity))
        s["era_year"][p] = era
        s["pop"][p] = pop
        s["capacity"][p] = pop * (0.75 + 0.4 * float(sur.food_security))
        s["density"][p] = float(ramp(DENS_NORM, H) * np.clip(0.7 + 0.5 * crowd, 0.6, 1.4))
        s["trade"][p] = float(np.clip(ramp(TRADE_NORM, H) * (0.6 + 0.8 * cap.get("logistics", 0.3)) + e("trade_capacity"), 0, 1))
        protect = (e("health_protection") + e("sanitation") + e("water_safety")) / 3.0
        s["health_knowledge"][p] = float(np.clip(ramp(HK_NORM, H) + protect - 0.5 * e("disease_exposure"), 0, 1))
        s["food_reserve"][p] = float(sur.stored_days) / 365.0
        s["diversification"][p] = float(np.clip(sur.diet_window, 0, 1))
        s["legitimacy"][p] = float(np.clip(sur.legitimacy, 0, 1))
        s["cohesion"][p] = float(np.clip(sur.cohesion, 0, 1))
        s["institutions"][p] = float(np.clip(ramp(INST_NORM, H) * (0.5 + 0.6 * cap.get("institutions", 0.5) + 0.4 * sur.education), 0, 1))
        s["knowledge"][p] = float(np.clip(ramp(KNOW_NORM, H) * (0.7 + 0.6 * sur.knowledge_metric), 0, 1))
        s["mobilization"][p] = float(np.clip(sur.alloc_pct.get("Defense", 2.0) / 100.0 * 0.5, 0.005, 0.2))
        return pop

    def feed_back(self, D, changes, pre_pop):
        """Apply this year's shock outcome for the player's people to the surrogate."""
        s, sur, p = self.state, self.sur, self.player
        new_p = changes.get("god_follow")
        moved = new_p is not None and new_p != p
        if new_p is not None:
            self.player = p_now = int(new_p)
        else:
            p_now = p
        row_pop = float(s["pop"][p_now]) if s["alive"][p_now] else pre_pop
        factor = float(np.clip(row_pop / max(1.0, pre_pop), 0.05, 20.0))
        for b in changes["births"]:
            if p in b["parents"] and b.get("terr_share", 0) > 0 and not moved:
                sur.housing_capacity *= max(0.3, 1.0 - float(b["terr_share"]))
        if moved:
            sur.housing_capacity *= factor
            sur.adoption[sur.known] = np.maximum(0.015, sur.adoption[sur.known] * 0.9)
            s["aggression"][p_now] = 0.25
        if abs(factor - 1.0) > 1e-9:
            sur.coh = sur.coh * factor
            sur.preg = sur.preg * factor
            sur.postpartum *= factor
            sur.stored *= factor if factor < 1 else 1.0
            sur._sync()
        s["pop"][p_now] = float(sur.population)
        if moved:
            sur.shock_food_mult = sur.shock_output_mult = 1.0
            return {"factor": factor, "moved": True}
        # this year's multipliers (used until the next year boundary)
        sur.shock_food_mult = float(D["food_mult"][p])
        sur.shock_output_mult = float(D["output_mult"][p]) * float(s["productivity"][p])
        sur.housing_capacity *= float(D["capacity_mult"][p])
        sur.legitimacy = float(np.clip(sur.legitimacy + D["legitimacy"][p], 0.02, 1.0))
        sur.cohesion = float(np.clip(sur.cohesion + D["cohesion"][p], 0.02, 1.0))
        sur.logistics = float(np.clip(sur.logistics + D["trade"][p], 0.0, 1.0))
        sur.knowledge_metric = float(np.clip(sur.knowledge_metric + D["knowledge"][p], 0.0, 1.0))
        if D["food_reserve"][p] < 0:
            keep = max(0.0, 1.0 + D["food_reserve"][p] / max(1e-6, self._pre["food_reserve"]))
            sur.stored *= keep
            sur.fresh *= keep
        k = sur.known
        for key, mask in (("institutions", self.inst_mask), ("health_knowledge", self.health_mask), ("knowledge", None)):
            d = float(D[key][p])
            if d < 0:
                rel = max(0.2, 1.0 + d / max(1e-3, self._pre[key]))
                m = k if mask is None else (k & mask)
                sur.adoption[m] = np.maximum(0.015, sur.adoption[m] * rel)
        return {"factor": factor, "moved": False}

    # ------------------------------------------------------------ one game year
    def step(self, year):
        s, g, rng, o = self.state, self.graph, self.rng, self.o
        alive = s["alive"]
        self._set_era(s, year)
        H = hist_year(s["era_year"])
        s["cap_bonus"] += 0.005 * (1.0 - s["cap_bonus"])
        K = s["territory"] * ramp(PEOPLE_PER_TERRITORY, H) * 1000 * float(o["rival_scale"]) * s["cap_bonus"]
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
        # the player's row comes from the detailed surrogate, not the stand-in dynamics
        pre_pop = self.write_player()
        p = self.player
        self._pre = {k: float(s[k][p]) for k in ROW_KEYS}
        self.trade_scar += 0.03 * (1.0 - self.trade_scar)
        self._graph()
        c = g["contact"]
        pair_alive = np.outer(alive, alive)
        aggr = 0.5 * (s["aggression"][:, None] + s["aggression"][None, :])
        start = np.triu(rng.random((self.n, self.n)) < 0.0012 * c * aggr * pair_alive, 1)
        g["war"] |= start | start.T
        stop = np.triu(rng.random((self.n, self.n)) < 0.25, 1)
        g["war"] &= ~(stop | stop.T)
        if np.median(H[alive]) > -2500:
            form = np.triu(rng.random((self.n, self.n)) < 0.004 * c * pair_alive, 1)
            g["alliance"] |= form | form.T
            brk = np.triu(rng.random((self.n, self.n)) < 0.03, 1)
            g["alliance"] &= ~(brk | brk.T)
        g["alliance"] &= ~g["war"]
        g["war"] &= pair_alive
        g["alliance"] &= pair_alive
        events, D = apply_shocks(s, g, rng, year, self.params)
        p = self.player
        if self.o["surrogate_famine"]:
            # The surrogate starves by itself: the engine still declares the famine (legitimacy,
            # flight, cascades) and its harvest loss reaches the surrogate's food system, but the
            # famine's own mortality and store wipe are left to the surrogate's hunger model.
            ff = float(D["deaths_by_type"]["famine"][p]) / max(1.0, float(s["pop"][p]))
            if ff > 0:
                D["pop_loss_frac"][p] = 1.0 - (1.0 - D["pop_loss_frac"][p]) / max(1e-6, 1.0 - ff)
                D["famine_declared_deaths"] = ff
                D["deaths_by_type"]["famine"][p] = 0.0
            D["food_reserve"][p] = max(float(D["food_reserve"][p]), -0.3)
        apply_deltas(s, g, D)
        if D["trade_link_mult"] is not None:
            self.trade_scar *= D["trade_link_mult"]
        s["cap_bonus"] *= D["capacity_mult"]
        pop_mid = float(s["pop"][p])
        eevents, changes = apply_emergence(s, g, rng, year, events, self.eparams)
        colonists = pop_mid - float(s["pop"][p])        # emergence moves colonists out directly
        gained = sum(float(s["pop"][d["slot"]]) * 0.9 / max(1, len(d["into"])) for d in changes["deaths"]
                     if p in d["into"] and d["slot"] != p)
        lost = 0.0
        for b in changes["births"]:
            if p in b["parents"] and b["kind"] != "colony" and not (b.get("from_outside") or b.get("newcomer_pop_from_outside")):
                lost += float(b["share"]) * pop_mid
        apply_changes(s, g, changes, year)
        if changes["births"] or changes["deaths"]:
            born = [b["slot"] for b in changes["births"]]
            self.trade_scar[:, born] = 1.0
            self.trade_scar[born, :] = 1.0
            self._graph()
        fb = self.feed_back(D, changes, pre_pop)
        fb.update(colonists=colonists / max(1.0, pre_pop), absorbed_gain=gained / max(1.0, pre_pop), breakaway=lost / max(1.0, pre_pop))
        return events, eevents, D, changes, fb, p


class ShockSurrogate(Surrogate):
    """A ``Surrogate`` that lives through epochal shocks in a multi-civ world."""

    def __init__(self, scenario, seed, params, data=None, shock_opts=None, **kw):
        super().__init__(scenario, seed, params, data, **kw)
        self.shock_opts = {**DEFAULTS, **(shock_opts or {})}
        self.shock_food_mult = 1.0
        self.shock_output_mult = 1.0
        self._shock_year = 0
        self.world = None
        self.shock_log = {"player": [], "onsets": collections.Counter(), "civ_years": collections.Counter(),
                          "births": collections.Counter(), "deaths": collections.Counter(), "alive": [], "god_moves": 0,
                          "player_episodes": [], "names": {}}

    # hooks -----------------------------------------------------------------------------
    def _weather(self, day):
        return super()._weather(day) * self.shock_food_mult

    def policy(self, channel):
        base = super().policy(channel)
        if channel == "labor_multiplier" and self.shock_output_mult != 1.0:
            return (1.0 + base) * self.shock_output_mult - 1.0
        return base

    def _conditions(self, year):
        super()._conditions(year)
        y = int(round(year))
        if y < 1 or y <= self._shock_year or not hasattr(self, "labor_eff"):
            return
        self._shock_year = y
        if self.world is None:
            rng = np.random.default_rng((self.seed * 104729 + 7) & 0xFFFFFFFF)
            self.world = SurrogateWorld(rng, self, self.shock_opts)
            self.inst_mask_init()
        self._shock_step(y)

    def inst_mask_init(self):
        self.world.inst_mask = _lines_mask(self.cat, INST_LINES)
        self.world.health_mask = _lines_mask(self.cat, ("health",))

    def _shock_step(self, y):
        w, log = self.world, self.shock_log
        pop0 = float(self.population)
        events, eevents, D, changes, fb, p = w.step(y)
        s = w.state
        alive = s["alive"]
        century = (y - 1) // 100 * 100 + 100
        log["civ_years"][century] += int(alive.sum())
        log["alive"].append(int(alive.sum()))
        mem = s["shock_memory"]
        hit = collections.Counter()
        for e in events:
            if e["event"] == "onset":
                log["onsets"][(century, e["type"])] += 1
                ep = mem["episodes"].get(e["episode"], {})
                if p in ep.get("civs", {}) or e["origin"] == p:
                    log["player_episodes"].append({"year": y, "type": e["type"], "kind": e["kind"], "name": e["name"],
                                                   "severity": e["severity"], "episode": e["episode"], "origin": e["origin"] == p})
            elif e["event"] == "spread" and e.get("civ") == p:
                ep = mem["episodes"].get(e["episode"], {})
                log["player_episodes"].append({"year": y, "type": ep.get("type", "pandemic"), "kind": ep.get("kind", ""),
                                               "name": ep.get("name", ""), "severity": e.get("mortality", 0.0), "episode": e["episode"]})
        for t in TYPES:
            d = float(D["deaths_by_type"][t][p])
            if d > 0:
                hit[t] = d / max(1.0, pop0)
        for b in changes["births"]:
            log["births"][(century, b["kind"])] += 1
        for key in ("breakaway", "colonists", "absorbed_gain"):
            if fb.get(key):
                hit[key] = float(fb[key])
        for d in changes["deaths"]:
            log["deaths"][(century, d["kind"])] += 1
        if fb["moved"]:
            log["god_moves"] += 1
        if D.get("famine_declared_deaths"):
            hit["famine_engine_estimate"] = float(D["famine_declared_deaths"])
        log["player"].append({"year": y, "pop_before": pop0, "pop_after": float(self.population), "loss_frac": float(D["pop_loss_frac"][p]),
                              "emig": float(D["emigrants"][p]) / max(1.0, pop0), "immig": float(D["immigrants"][p]) / max(1.0, pop0),
                              "food_mult": float(D["food_mult"][p]), "output_mult": float(D["output_mult"][p]),
                              "by_type": dict(hit), "moved": fb["moved"],
                              "at_war": bool(w.graph["war"][w.player].any()), "strain": float(mem["strain"][w.player]),
                              "row": {k: round(v, 4) for k, v in w._pre.items()}})
        log["names"]["player"] = s["names"][w.player]

    def run(self, years, record_every=1.0):
        out = super().run(years, record_every)
        log = self.shock_log
        out["shocks"] = {"player": log["player"], "player_episodes": log["player_episodes"],
                         "onsets": {f"{c}:{t}": n for (c, t), n in log["onsets"].items()},
                         "civ_years": dict(log["civ_years"]),
                         "births": {f"{c}:{k}": n for (c, k), n in log["births"].items()},
                         "deaths": {f"{c}:{k}": n for (c, k), n in log["deaths"].items()},
                         "alive": log["alive"], "god_moves": log["god_moves"], "names": log["names"]}
        return out
