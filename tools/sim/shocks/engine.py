"""Epochal shock engine: emergent hazards, multi-civ propagation, magnitude/duration/recovery.

Public entry point::

    events, deltas = apply_shocks(state, civ_graph, rng, year, params=None)

``state`` is a dict of per-civ numpy arrays (length N = civ slots); see ``STATE_KEYS``.
The engine never writes the host's variables. It keeps its own bookkeeping in
``state["shock_memory"]`` (created on first call; save it with the host state) and
returns ``deltas`` that the caller applies (``apply_deltas`` does it for surrogates).
Call once per game year, after the host's own yearly update. Dead/empty slots are
marked ``state["alive"] == False`` and are ignored.

Nothing here is scheduled by calendar: every shock starts from a hazard computed from
the civ's current condition, and spreads through the contact/trade/war/alliance graph.
All names are generic kinds plus in-world names from ``names.py``.
"""
from __future__ import annotations

import math

import numpy as np

from . import names as nm
from .catalog import (BASE, CLIMATE, MEDICINE_CEILING, T_INDEX, TYPES, WAR_DURATION_MEDIAN,
                      WAR_MOBILIZATION_CAP, WAR_MORTALITY_MEDIAN, hist_year, ramp)

# name -> (default if missing, meaning)
STATE_KEYS = {
    "pop": (None, "people"),
    "capacity": (None, "people the land/economy can feed at current technique"),
    "era_year": (None, "game-year equivalent of the civ's knowledge frontier"),
    "alive": (1.0, "slot holds a living civ"),
    "density": (0.4, "0..1 crowding / urban share"),
    "trade": (0.4, "0..1 external trade integration"),
    "health_knowledge": (0.1, "0..1 sanitation, quarantine, medicine"),
    "food_reserve": (0.25, "years of stored food"),
    "diversification": (0.4, "0..1 spread of food sources"),
    "inequality": (0.45, "0..1"),
    "legitimacy": (0.6, "0..1"),
    "cohesion": (0.6, "0..1"),
    "institutions": (0.5, "0..1 state capacity"),
    "overextension": (0.3, "0..1 territory beyond logistic reach"),
    "mobilization": (0.01, "share of population under arms"),
    "knowledge": (0.3, "0..1"),
    "steppe_exposure": (0.2, "0..1 open frontier to pastoral/nomad peoples"),
    "productivity": (1.0, "output multiplier level"),
    "aggression": (0.4, "0..1 ruler/doctrine appetite for war"),
    "disease_endowment": (1.0, "0..1 crowd-disease stock (domesticated animals); isolated continents low"),
}
LEVEL_KEYS = ["legitimacy", "cohesion", "institutions", "inequality", "trade", "knowledge",
              "health_knowledge", "productivity", "food_reserve"]

DEFAULTS = {
    "harvest_noise_sd": 0.06,   # set 0 when the host already draws weather (food_system does)
    "rate_scale": 1.0,          # global multiplier on endogenous hazards (difficulty/tuning)
    "warn_hazard": 0.012,       # annual hazard above which a court warning is raised (war: half)
    "warn_ratio": 2.0,          # ... and at least this many times the era's reference rate
    "warn_gap": 15,             # years between repeated warnings of one type per civ
    "max_echoes": 6,
}

DRIVERS = {
    "climate": [],
    "famine": ["climate", "war", "collapse", "migration", "pandemic"],
    "pandemic": ["famine", "war", "migration"],
    "migration": ["climate", "famine", "collapse", "war"],
    "war": ["migration", "upheaval", "economic", "tech", "famine", "collapse"],
    "economic": ["war", "pandemic", "collapse", "climate"],
    "upheaval": ["pandemic", "famine", "economic", "war"],
    "tech": ["pandemic", "war"],
    "collapse": ["war", "migration", "famine", "economic", "pandemic", "climate", "upheaval"],
}


# ------------------------------------------------------------------------------ helpers
def _get(state, key, n):
    v = state.get(key)
    if v is None:
        d = STATE_KEYS[key][0]
        if d is None:
            raise KeyError(f"shock state needs '{key}'")
        return np.full(n, float(d))
    return np.asarray(v, dtype=float)


def _profile(kind: str, dur: int) -> np.ndarray:
    t = np.arange(dur) + 0.5
    if kind == "front":
        w = np.exp(-t / max(0.6, dur / 2.5))
    elif kind == "hump":
        x = t / dur
        w = x * (1.0 - x) + 0.05
    else:
        w = np.ones(dur)
    return w / w.sum()


def _lognorm(rng, median, sigma, lo, hi):
    return float(np.clip(median * math.exp(sigma * rng.standard_normal()), lo, hi))


class _Ctx:
    pass


def _memory(state, n):
    mem = state.get("shock_memory")
    if mem is not None and mem.get("n") == n:
        return mem
    dens = _get(state, "density", n)
    trade = _get(state, "trade", n)
    pool = state.get("disease_pool")
    endow = _get(state, "disease_endowment", n)
    pool = np.asarray(pool, dtype=float) if pool is not None else np.clip(0.1 + 0.6 * dens + 0.3 * trade, 0, 1) * endow
    mem = {
        "n": n, "next_id": 1, "episodes": {}, "active": [], "archive": [],
        "strain": np.zeros(n), "expo": np.zeros((n, len(TYPES))), "expo_ep": np.full((n, len(TYPES)), -1),
        "immunity": np.zeros(n), "pool": pool.copy(), "exchanged": np.zeros((n, n), dtype=bool),
        "outflow": np.zeros(n), "warned": np.full((n, len(TYPES)), -10_000),
        "last_collapse_end": np.full(n, -10_000), "tech_recent": np.zeros(n), "scars": [],
        "echo_queue": [], "cold": None, "systems": {}, "last_famine": np.full(n, -10_000),
    }
    state["shock_memory"] = mem
    return mem


def reset_slot(state, slot, parent=None):
    """Prepare shock memory for a civ newly placed in ``slot`` (emergence calls this).

    A successor inherits its parent's disease pool, immunity and contact history, and a
    share of its strain (the trauma that birthed it).
    """
    mem = state.get("shock_memory")
    if mem is None:
        return
    retire_slot(state, slot)
    if parent is not None and parent >= 0:
        mem["pool"][slot] = mem["pool"][parent]
        mem["immunity"][slot] = mem["immunity"][parent]
        mem["exchanged"][slot, :] = mem["exchanged"][parent, :]
        mem["exchanged"][:, slot] = mem["exchanged"][:, parent]
        mem["strain"][slot] = 0.5 * mem["strain"][parent]
    else:
        mem["pool"][slot] = 0.3
        mem["immunity"][slot] = 0.0
        mem["exchanged"][slot, :] = mem["exchanged"][:, slot] = False
        mem["strain"][slot] = 0.0
    mem["exchanged"][slot, slot] = True
    mem["expo"][slot] = 0.0
    mem["expo_ep"][slot] = -1
    mem["warned"][slot] = -10_000
    mem["last_collapse_end"][slot] = -10_000
    mem["last_famine"][slot] = -10_000
    mem["tech_recent"][slot] = 0.0
    mem["outflow"][slot] = 0.0


def retire_slot(state, slot):
    """End every running shock entry of a civ that vanished (absorbed, dispersed)."""
    mem = state.get("shock_memory")
    if mem is None:
        return
    for eid in mem["active"]:
        e = mem["episodes"][eid]["civs"].get(slot)
        if e is not None:
            e["done"] = True
    mem["scars"] = [s for s in mem["scars"] if s[0] != slot]
    mem["echo_queue"] = [q for q in mem["echo_queue"] if q["civ"] != slot]


def _new_deltas(n):
    d = {k: np.zeros(n) for k in LEVEL_KEYS}
    d.update(pop_loss_frac=np.zeros(n), emigrants=np.zeros(n), immigrants=np.zeros(n),
             food_mult=np.ones(n), output_mult=np.ones(n), capacity_mult=np.ones(n),
             mobilization_floor=np.zeros(n), trade_link_mult=None, war_start=[], war_end=[],
             war_pressure=None, deaths_by_type={t: np.zeros(n) for t in TYPES})
    return d


# ------------------------------------------------------------------------------ episodes
def _active_mask(c, typ):
    m = np.zeros(c.n, dtype=bool)
    for eid in c.mem["active"]:
        ep = c.mem["episodes"][eid]
        if ep["type"] == typ:
            for i, e in ep["civs"].items():
                if not e.get("done"):
                    m[i] = True
    return m


def _parent(c, typ, i, neighbours=False):
    best, best_v = None, 0.05
    for d in DRIVERS[typ]:
        k = T_INDEX[d]
        if neighbours:
            v = c.mem["expo"][:, k] * np.maximum(c.contact[i], np.eye(c.n)[i])
            j = int(np.argmax(v))
            val, eid = float(v[j]), int(c.mem["expo_ep"][j, k])
        else:
            val, eid = float(c.mem["expo"][i, k]), int(c.mem["expo_ep"][i, k])
        if val > best_v and eid > 0:
            best, best_v = eid, val
    return best


def _civ_name(c, i):
    return str(c.names[i]) if 0 <= i < len(c.names) else ""


def _place(c, i):
    if 0 <= i < len(c.cities) and c.cities[i]:
        return str(c.rng.choice(list(c.cities[i])))
    return _civ_name(c, i)


def _new_episode(c, typ, origin, severity, kind, parent=None, other="", n_peoples=3, **extra):
    eid = c.mem["next_id"]
    c.mem["next_id"] += 1
    name = nm.event_name(kind, c.rng, people=_civ_name(c, origin), place=_place(c, origin), other=other, n=n_peoples)
    ep = {"id": eid, "type": typ, "kind": kind, "name": name, "origin": int(origin), "start": c.year, "end": None,
          "severity": float(severity), "parent": parent, "civs": {}, **extra}
    c.mem["episodes"][eid] = ep
    c.mem["active"].append(eid)
    t = T_INDEX[typ]
    warned = origin >= 0 and c.year - c.mem["warned"][origin, t] <= 20
    ep["warned"] = bool(warned)
    c.events.append({"year": c.year, "event": "onset", "type": typ, "kind": kind, "name": name, "episode": eid,
                     "origin": int(origin), "severity": round(float(severity), 3), "parent": parent, "warned": bool(warned)})
    return ep


def _add_entry(c, ep, i, dur, profile="flat", **fx):
    i = int(i)
    dur = max(1, int(round(dur)))
    e = {"start": c.year, "dur": dur, "t": 0, "w": _profile(profile, dur), "pre_pop": float(c.pop[i]),
         "pre_inst": float(c.inst[i]), "dead": 0.0, "emig_n": 0.0, "inst_loss": 0.0, "food_min": 1.0,
         "mort": 0.0, "emig": 0.0, "food_loss": 0.0, "out_loss": 0.0, "cap": 1.0, "mob": 0.0, "after": []}
    for k in LEVEL_KEYS:
        e[k] = 0.0
    frac = fx.pop("inst_frac", 0.0)
    e.update(fx)
    if frac:  # proportional institutional loss, fixed at onset
        e["institutions"] = e.get("institutions", 0.0) - frac * float(c.inst[i])
    ep["civs"][i] = e
    t = T_INDEX[ep["type"]]
    c.mem["expo"][i, t] = max(c.mem["expo"][i, t], 0.3 + ep["severity"])
    c.mem["expo_ep"][i, t] = ep["id"]
    return e


def _entry_food(c):
    f = np.ones(c.n)
    for eid in c.mem["active"]:
        for i, e in c.mem["episodes"][eid]["civs"].items():
            if not e.get("done") and e["food_loss"] > 0:
                shape = e["w"][e["t"]] / e["w"].max()
                f[i] *= 1.0 - e["food_loss"] * shape
    return f


def _run_episodes(c):
    D = c.D
    survive = np.ones(c.n)
    for eid in list(c.mem["active"]):
        ep = c.mem["episodes"][eid]
        for i, e in ep["civs"].items():
            if e.get("done"):
                continue
            w = e["w"][e["t"]]
            shape = w / e["w"].max()
            if e["mort"] > 0:
                frac = 1.0 - (1.0 - e["mort"]) ** w  # compounding keeps the episode total exact
                survive[i] *= 1.0 - frac
                e["surv"] = e.get("surv", 1.0) * (1.0 - frac)
                D["deaths_by_type"][ep["type"]][i] += frac * c.pop[i]
                e["dead"] += frac * c.pop[i]
            if e["emig"] > 0:
                n_out = e["emig"] * w * c.pop[i]
                e["emig_frac"] = e.get("emig_frac", 0.0) + e["emig"] * w
                D["emigrants"][i] += n_out
                e["emig_n"] += n_out
            if e["food_loss"] > 0:
                D["food_mult"][i] *= 1.0 - e["food_loss"] * shape
                e["food_min"] = min(e["food_min"], 1.0 - e["food_loss"] * shape)
            if e["out_loss"] != 0:
                D["output_mult"][i] *= 1.0 - e["out_loss"] * shape
            if e["cap"] != 1.0:
                D["capacity_mult"][i] *= e["cap"] ** w
            if e["mob"] > 0:
                D["mobilization_floor"][i] = max(D["mobilization_floor"][i], e["mob"] * min(1.0, 2.5 * shape))
            for k in LEVEL_KEYS:
                if e[k]:
                    D[k][i] += e[k] * w
            if e["institutions"] < 0:
                e["inst_loss"] += -e["institutions"] * w
            e["t"] += 1
            if e["t"] >= e["dur"]:
                e["done"] = True
                e["end"] = c.year
                for (key, total, years) in e["after"]:
                    c.mem["scars"].append([i, key, total / years, years, ep["id"]])
        if ep["type"] == "pandemic":
            continue  # pandemic episodes end in _pandemic once no civ is infected
        if all(e.get("done") for e in ep["civs"].values()):
            _end_episode(c, ep)
    D["pop_loss_frac"] = 1.0 - survive


def _end_episode(c, ep):
    ep["end"] = c.year
    c.mem["active"].remove(ep["id"])
    c.mem["archive"].append(ep["id"])
    if ep["type"] == "war":
        _resolve_war(c, ep)
    if ep["type"] == "collapse":
        for i in ep["civs"]:
            c.mem["last_collapse_end"][i] = c.year
    c.events.append({"year": c.year, "event": "end", "type": ep["type"], "kind": ep["kind"], "name": ep["name"],
                     "episode": ep["id"], "civs": sorted(int(i) for i in ep["civs"]),
                     "dead": float(sum(e["dead"] for e in ep["civs"].values()))})


def _scars(c):
    keep = []
    for s in c.mem["scars"]:
        i, key, per_year, left, _ = s
        c.D[key][i] += per_year
        s[3] -= 1
        if s[3] > 0:
            keep.append(s)
    c.mem["scars"] = keep


# ------------------------------------------------------------------------------ climate
def _climate(c):
    rng, P, live = c.rng, c.P, np.where(c.alive)[0]
    # Volcanic forcing is hemispheric: every living civ feels it, scaled by vulnerability.
    if rng.random() < CLIMATE["volcanic_severe"] / 100:
        sev = rng.uniform(0.18, 0.32)
        ep = _new_episode(c, "climate", int(live[0]) if live.size else -1, sev, "long_winter")
        for i in live:
            _add_entry(c, ep, i, rng.integers(6, 14), "front", food_loss=sev * c.clim_vuln[i] * 2.2,
                       legitimacy=-0.06, cohesion=-0.03)
    elif rng.random() < CLIMATE["volcanic_notable"] / 100:
        sev = rng.uniform(0.04, 0.12)
        ep = _new_episode(c, "climate", int(live[0]) if live.size else -1, sev, "cold_year")
        for i in live:
            _add_entry(c, ep, i, rng.integers(1, 3), "front", food_loss=sev * c.clim_vuln[i] * 1.3)
    # Regional multi-decade droughts.
    for r in np.unique(c.region[c.alive]):
        members = np.where((c.region == r) & c.alive)[0]
        busy = any(c.mem["episodes"][e].get("region") == int(r) for e in c.mem["active"])
        if not busy and rng.random() < CLIMATE["megadrought"] / 100:
            sev = rng.uniform(0.08, 0.24)
            dur = int(_lognorm(rng, 40, 0.7, 12, 280))
            ep = _new_episode(c, "climate", int(members[0]), sev, "great_drought" if dur >= 100 else "drought_years",
                              region=int(r))
            for i in members:
                _add_entry(c, ep, i, dur, "hump", food_loss=sev * c.clim_vuln[i] * 1.4, emig=0.02 + sev * 0.25,
                           legitimacy=-0.1 * sev)
    # Multi-century cold ages raise harvest variance everywhere.
    cold = c.mem["cold"]
    if cold is None and rng.random() < CLIMATE["cold_epoch"] / 100:
        dur = int(rng.integers(150, 420))
        sev = rng.uniform(0.03, 0.07)
        ep = _new_episode(c, "climate", int(live[0]) if live.size else -1, sev, "cold_age")
        for i in live:
            _add_entry(c, ep, i, dur, "flat", food_loss=sev * c.clim_vuln[i])
        c.mem["cold"] = {"until": c.year + dur, "id": ep["id"]}
    elif cold is not None and c.year >= cold["until"]:
        c.mem["cold"] = None
    var = 1.6 if c.mem["cold"] is not None else 1.0
    c.noise = np.clip(1.0 + rng.standard_normal(c.n) * P["harvest_noise_sd"] * var * c.clim_vuln, 0.5, 1.3)
    c.D["food_mult"] *= c.noise


# ------------------------------------------------------------------------------ pandemic
def _pandemic(c):
    rng, mem = c.rng, c.mem
    med = c.hk * ramp(MEDICINE_CEILING, c.H)
    famine = _active_mask(c, "famine")
    war = _active_mask(c, "war") | c.war.any(axis=1)
    mem["immunity"] *= 0.962   # half-life ~18 years: new generations are susceptible again
    target = np.clip(0.1 + 0.6 * c.dens + 0.3 * c.trade_lvl, 0, 1) * c.endow
    mem["pool"] += 0.01 * (target - mem["pool"])

    def mortality(j, v, pool):
        virgin = 1.0 + 5.0 * max(0.0, pool - mem["pool"][j] - 0.1)
        m = v * (0.5 + c.dens[j]) * (1.0 - mem["immunity"][j]) * (1.0 - med[j]) ** 2 * (1.0 + 0.6 * famine[j]) * virgin
        return float(np.clip(m * math.exp(0.35 * rng.standard_normal()), 0.0, 0.6))

    def infect(ep, j):
        m = mortality(j, ep["v"], ep["pool"])
        e = _add_entry(c, ep, j, rng.integers(1, 4), "front", mort=m, food_loss=0.3 * m, out_loss=0.5 * m,
                       legitimacy=-0.4 * m, cohesion=-0.3 * m, inst_frac=0.5 * m)
        e["health_knowledge"] = 0.15 * m  # quarantine and burial practice are learned in the crisis
        if m >= 0.05:  # labour scarcity afterwards: wages up, inequality down, labour-saving invention
            e["after"] += [("productivity", 0.6 * m, 30), ("inequality", -0.6 * m, 30), ("knowledge", 0.12 * m, 30)]
        mem["immunity"][j] = max(mem["immunity"][j], min(0.85, 0.35 + 4.0 * m))
        if ep["virgin"]:  # a naive people acquires the foreign disease stock one terrible wave at a time
            mem["pool"][j] += 0.35 * max(0.0, ep["pool"] - mem["pool"][j])
        else:
            mem["pool"][j] = max(mem["pool"][j], 0.9 * ep["pool"])
        ep["hit"].add(j)
        ep["mort"][j] = m
        c.events.append({"year": c.year, "event": "spread", "type": "pandemic", "episode": ep["id"], "civ": j,
                         "mortality": round(m, 3), "name": ep["name"],
                         "warned": bool(c.year - mem["warned"][j, T_INDEX["pandemic"]] <= 6)})

    def kind(v, virgin):
        if virgin:
            return "stranger_sickness"
        return "great_pestilence" if v >= 0.2 else ("pestilence" if v >= 0.08 else "fever")

    # 1. First contact between disease pools that never met: virgin-soil epidemics in waves.
    gap = mem["pool"][:, None] - mem["pool"][None, :]
    fresh = (c.contact > 0.1) & ~mem["exchanged"] & c.alive[:, None] & c.alive[None, :]
    naive_hit = fresh & (gap > 0.3)
    for j in np.where(naive_hit.any(axis=0))[0]:
        sources = np.where(naive_hit[:, j])[0]
        i = int(sources[np.argmax(mem["pool"][sources])])
        mem["exchanged"][sources, j] = mem["exchanged"][j, sources] = True
        ep = _new_episode(c, "pandemic", int(j), 0.2, kind(0.2, True), other=_civ_name(c, i), v=0.2,
                          pool=float(mem["pool"][i]), hit=set(), mort={}, echo=0, virgin=True)
        infect(ep, int(j))
    mem["exchanged"] |= fresh & (np.abs(gap) <= 0.3)

    # 2. Emergence of new pathogens (crowding, trade, hunger, war camps).
    h = (ramp(BASE["pandemic_emerge"], c.H) / 100 * c.P["rate_scale"]
         * np.exp(1.6 * (c.dens - 0.4) + 1.2 * (c.trade_lvl - 0.4) + 0.8 * famine + 0.5 * war + 0.6 * (mem["pool"] - 0.4))
         * (1.0 - 0.5 * med)) * c.alive
    c.hazard["pandemic"] = h
    c.signs["pandemic"] = {"crowding": c.dens > 0.6, "far trade": c.trade_lvl > 0.6, "hunger": famine, "war camps": war}
    queue = [q for q in mem["echo_queue"] if q["year"] <= c.year]
    mem["echo_queue"] = [q for q in mem["echo_queue"] if q["year"] > c.year]
    for i in np.where(rng.random(c.n) < h)[0]:
        v = _lognorm(rng, 0.06, 0.85, 0.005, 0.35)
        ep = _new_episode(c, "pandemic", int(i), v, kind(v, False), parent=_parent(c, "pandemic", int(i)), v=v,
                          pool=float(mem["pool"][i]), hit=set(), mort={}, echo=0, virgin=False)
        infect(ep, int(i))
    for q in queue:  # an endemic killer returns every 10-20 years, weaker each time
        i = int(q["civ"])
        if not c.alive[i]:
            continue
        ep = _new_episode(c, "pandemic", i, q["v"], kind(q["v"], q["virgin"]), parent=q["parent"], v=q["v"],
                          pool=q["pool"], hit=set(), mort={}, echo=q["echo"], virgin=q["virgin"])
        infect(ep, i)

    # 3. Spread along contact/trade/war links; each civ is hit once per wave.
    quarantine = np.clip(c.hk * c.inst, 0, 1)
    for eid in list(mem["active"]):
        ep = mem["episodes"][eid]
        if ep["type"] != "pandemic":
            continue
        infectious = np.array([i for i, e in ep["civs"].items() if not e.get("done") and e["t"] <= 1], dtype=int)
        if infectious.size:
            link = c.contact[infectious] * (0.5 * (c.trade_lvl[infectious, None] + c.trade_lvl[None, :]) + c.war[infectious])
            lam = 2.2 * link.sum(axis=0)
            p = (1.0 - np.exp(-lam)) * (1.0 - 0.7 * quarantine) * c.alive
            if ep["virgin"]:  # the strangers' sickness only kills where the stock is new
                p = p * (mem["pool"] < ep["pool"] - 0.2)
            # Rumour runs ahead of contagion: merchants and envoys report the sickness abroad.
            tp = T_INDEX["pandemic"]
            for j in np.where((lam > 0.15) & c.alive & (c.year - mem["warned"][:, tp] > 6))[0]:
                if j not in ep["hit"]:
                    mem["warned"][j, tp] = c.year
                    c.events.append({"year": c.year, "event": "warning", "type": "pandemic", "civ": int(j),
                                     "hazard": round(float(p[j]), 4), "signs": ["sickness in neighbouring lands"],
                                     "name": ep["name"]})
            for j in np.where(rng.random(c.n) < p)[0]:
                if j not in ep["hit"]:
                    infect(ep, int(j))
        if all(e.get("done") for e in ep["civs"].values()):
            _end_episode(c, ep)
            limit = 6 if ep["virgin"] else c.P["max_echoes"]
            if ep["echo"] < limit and rng.random() < min(0.8, (0.9 if ep["virgin"] else 2.0 * ep["v"])):
                hit = sorted((k for k in ep["hit"] if c.alive[k]), key=lambda k: -c.dens[k])
                if hit:
                    mem["echo_queue"].append({"year": c.year + int(rng.integers(8, 21)), "civ": hit[0],
                                              "v": ep["v"] * (0.75 if ep["virgin"] else rng.uniform(0.35, 0.75)),
                                              "pool": ep["pool"], "echo": ep["echo"] + 1, "virgin": ep["virgin"],
                                              "parent": ep["id"]})


# ------------------------------------------------------------------------------ war
def _allies_of(c, i, exclude):
    """Allies honour the call with a chance that falls with distance and with each link of the chain."""
    seen, frontier, depth = {i}, [i], 0
    while frontier and depth < 3:
        nxt = []
        for k in frontier:
            for j in np.where(c.alliance[k] & c.alive)[0]:
                p = (0.55 ** depth) * (0.35 + 0.65 * c.contact[k, j])
                if j not in seen and j not in exclude and c.rng.random() < p:
                    seen.add(int(j))
                    nxt.append(int(j))
        frontier, depth = nxt, depth + 1
    return seen


def _start_war(c, a, b, kind_hint, parent):
    rng = c.rng
    side_a = _allies_of(c, a, {b})
    side_b = _allies_of(c, b, side_a) - side_a
    side_b.add(b)
    Hm = float(np.mean(c.H[list(side_a | side_b)]))
    cap = ramp(WAR_MOBILIZATION_CAP, Hm)
    mort_med = ramp(WAR_MORTALITY_MEDIAN, Hm)
    dur = int(_lognorm(rng, ramp(WAR_DURATION_MEDIAN, Hm), 0.6, 2, 32))
    intensity = rng.beta(2.0, 2.0)
    total_mob = cap * (0.5 + 0.5 * intensity)
    kind = "war_of_many_peoples" if total_mob >= 0.12 else ("grinding_war" if dur >= 20 else kind_hint)
    ep = _new_episode(c, "war", a, intensity, kind, parent=parent, other=_civ_name(c, b),
                      n_peoples=len(side_a) + len(side_b), sides=(sorted(side_a), sorted(side_b)))
    str_a = sum(c.pop[k] * (0.5 + c.inst[k]) for k in side_a)
    str_b = sum(c.pop[k] * (0.5 + c.inst[k]) for k in side_b)
    for side, other_str, own_str in ((side_a, str_b, str_a), (side_b, str_a, str_b)):
        battleground = 1.0 + 0.8 * other_str / (own_str + other_str)   # the weaker side hosts the fighting
        for k in side:
            m = float(np.clip(mort_med * math.exp(0.7 * rng.standard_normal()) * battleground * (0.6 + 0.8 * intensity), 0.002, 0.45))
            industrial = c.H[k] >= 1800
            _add_entry(c, ep, k, dur, "hump", mort=m, mob=total_mob, emig=0.3 * m,
                       food_loss=min(0.5, 0.6 * total_mob + 0.6 * m), out_loss=(-0.08 if industrial else 0.1) * intensity,
                       legitimacy=-0.8 * m, cohesion=0.05 - 0.5 * m, inst_frac=0.4 * m, trade=-0.1 * intensity,
                       food_reserve=-0.2)
    if c.D["trade_link_mult"] is None:
        c.D["trade_link_mult"] = np.ones((c.n, c.n))
    for x in side_a:
        for y in side_b:
            c.D["war_start"].append((int(x), int(y)))
            c.D["trade_link_mult"][x, y] = c.D["trade_link_mult"][y, x] = 0.2
    return ep


def _resolve_war(c, ep):
    a, b = ep["sides"]
    s = [sum(c.pop[k] * (0.5 + c.inst[k]) * (1.0 - ep["civs"][k]["mort"]) * c.alive[k] for k in side) for side in (a, b)]
    p_a = s[0] ** 2 / (s[0] ** 2 + s[1] ** 2 + 1e-9)
    winners, losers = (a, b) if c.rng.random() < p_a else (b, a)
    mass = max(ep["civs"][k]["mob"] for k in ep["civs"]) >= 0.1
    for k in winners:
        c.mem["scars"].append([k, "institutions", 0.08 / 10, 10, ep["id"]])   # war makes states
        c.mem["scars"].append([k, "legitimacy", 0.05 / 5, 5, ep["id"]])
    for k in losers:
        c.D["legitimacy"][k] -= c.rng.uniform(0.1, 0.3)
        c.mem["strain"][k] += 0.6
    for k in ep["civs"]:
        if mass:  # mass mobilisation levels incomes and speeds industry and medicine
            c.mem["scars"] += [[k, "inequality", -0.12 / 15, 15, ep["id"]], [k, "knowledge", 0.05 / 10, 10, ep["id"]],
                               [k, "health_knowledge", 0.03 / 10, 10, ep["id"]], [k, "productivity", 0.06 / 10, 10, ep["id"]]]
    c.D["war_end"].extend((int(x), int(y)) for x in a for y in b)
    ep["winners"] = sorted(int(k) for k in winners)
    ep["losers"] = sorted(int(k) for k in losers)


def _war(c):
    rng = c.rng
    at_war_total = set()
    for eid in c.mem["active"]:
        if c.mem["episodes"][eid]["type"] == "war":
            at_war_total |= set(c.mem["episodes"][eid]["civs"])
    ally_frac = (c.alliance & c.alive[None, :]).sum(axis=1) / max(1, int(c.alive.sum()) - 1)
    mob = c.mob
    base = ramp(BASE["war_escalate"], c.H) / 100 * c.P["rate_scale"]
    hz = np.zeros(c.n)
    # (a) escalation of the host's ordinary wars through alliance entanglement and arms races
    for i, j in zip(*np.where(np.triu(c.war))):
        if i in at_war_total or j in at_war_total or not (c.alive[i] and c.alive[j]):
            continue
        h = 0.5 * (base[i] + base[j]) * math.exp(3.0 * (ally_frac[i] + ally_frac[j]) + 12.0 * (mob[i] + mob[j]))
        hz[i] = max(hz[i], h)
        hz[j] = max(hz[j], h)
        if rng.random() < h:
            ep = _start_war(c, int(i), int(j), "general_war", _parent(c, "war", int(i), neighbours=True))
            at_war_total |= set(ep["civs"])
    # (b) pressure wars: invaders, schisms, power vacuums and military-technical edges
    upheaval = _active_mask(c, "upheaval").astype(float)
    collapse = _active_mask(c, "collapse").astype(float)
    famine = _active_mask(c, "famine").astype(float)
    tech = c.mem["tech_recent"]
    pressure = (np.maximum(upheaval[:, None], upheaval[None, :]) * 0.6 + collapse[None, :] * 1.5 + famine[None, :] * 0.3
                + 1.0 * np.maximum(0.0, tech[:, None] - tech[None, :]) + 10.0 * c.mem["outflow"][None, :])
    pb = ramp(BASE["war_pressure"], c.H) / 100 * c.P["rate_scale"]
    pw = c.contact * pressure * pb[:, None] * (0.5 + c.aggr[:, None]) * np.outer(c.alive, c.alive)
    np.fill_diagonal(pw, 0.0)
    c.D["war_pressure"] = pw
    hz = np.maximum(hz, pw.sum(axis=1))
    c.hazard["war"] = hz
    c.signs["war"] = {"alliances": ally_frac > 0.2, "arms race": mob > 0.03, "schism": upheaval > 0,
                      "weak neighbour": (c.contact * collapse[None, :]).max(axis=1) > 0.2}
    for i, j in zip(*np.where(rng.random((c.n, c.n)) < pw)):
        if i in at_war_total or j in at_war_total:
            continue
        ep = _start_war(c, int(i), int(j), "war_of_opportunity",
                        _parent(c, "war", int(j), neighbours=True) or _parent(c, "war", int(i)))
        at_war_total |= set(ep["civs"])


# ------------------------------------------------------------------------------ economic
def _economic(c):
    rng = c.rng
    crisis = _active_mask(c, "economic").astype(float)
    partner = (c.trade_g * crisis[None, :]).sum(axis=1) / np.maximum(1e-6, c.trade_g.sum(axis=1))
    war = _active_mask(c, "war").astype(float)
    h = (ramp(BASE["economic"], c.H) / 100 * c.P["rate_scale"]
         * np.exp(6.0 * np.maximum(0, c.mob - 0.03) + 2.0 * (c.overext - 0.3) + 2.0 * (0.5 - c.inst)
                  + 2.5 * partner * c.trade_lvl + 0.8 * war + 0.7 * c.mem["strain"] + 1.0 * (c.ineq - 0.45))) * c.alive
    h[crisis > 0] = 0.0
    c.hazard["economic"] = h
    c.signs["economic"] = {"war spending": c.mob > 0.04, "overreach": c.overext > 0.5, "partners failing": partner > 0.2,
                           "debt": c.ineq > 0.6}
    for i in np.where(rng.random(c.n) < h)[0]:
        s = rng.beta(1.5, 4.0)
        H = c.H[i]
        kind = "debt_crisis" if H < -1200 else "coin_ruin" if H < 1000 else "broken_treasury" if H < 1850 else "market_crash"
        ep = _new_episode(c, "economic", int(i), s, kind, parent=_parent(c, "economic", int(i)))
        # Strong institutions answer with reform: debt remission, recoinage, a new fiscal settlement.
        after = [("institutions", 0.05, 10), ("inequality", -0.1 * s, 5)] if rng.random() < c.inst[i] else []
        _add_entry(c, ep, i, 3 + _lognorm(rng, 6, 0.6, 1, 50) * (0.5 + s), "hump", out_loss=0.06 + 0.3 * s,
                   legitimacy=-0.3 * s, inequality=0.08 * s, trade=-0.15 * s, food_reserve=-0.1 * s, after=after)


# ------------------------------------------------------------------------------ famine
def _famine(c, food_now):
    rng = c.rng
    active = _active_mask(c, "famine")
    other = 1.0 - food_now
    partner_short = (c.trade_g * (other[None, :] > 0.08)).sum(axis=1) / np.maximum(1e-6, c.trade_g.sum(axis=1))
    pressure = np.maximum(0.0, c.pop / c.cap - 0.85)
    buffer = (0.35 * np.minimum(c.reserve, 1.0) + 0.12 * c.trade_lvl * (1 - partner_short) + 0.06 * c.inst
              + 0.08 * c.divers) - 0.12
    modern = np.clip((c.H - 1850) / 100, 0, 1)  # fertiliser, rail and world grain markets
    shortfall = (other + 0.6 * pressure) * (1 - 0.45 * modern) - buffer
    # background dearth risk that grows with the shortfall, plus near-certain famine when the gap is wide
    p = (0.0025 * (1 - 0.8 * modern) * np.exp(8.0 * shortfall) + 1.0 / (1.0 + np.exp(-(shortfall - 0.16) / 0.015))) * c.alive
    # after a famine the survivors are fewer, stores are rebuilt and planting changes: a refractory spell
    p *= np.where(c.year - c.mem["last_famine"] < 6, 0.15, 1.0)
    p = np.minimum(p, 0.95)
    p[active] = 0.0
    c.hazard["famine"] = p
    c.signs["famine"] = {"thin stores": c.reserve < 0.15, "crowding": pressure > 0.1, "bad harvest": other > 0.1,
                         "single staple": c.divers < 0.25}
    for i in np.where(rng.random(c.n) < p)[0]:
        sf = float(shortfall[i])
        m = float(np.clip((0.012 + 0.2 * max(0.0, sf)) * (1 - 0.4 * c.inst[i]) * (1 - 0.5 * modern[i])
                          * math.exp(0.5 * rng.standard_normal()), 0.002, 0.25))
        c.mem["last_famine"][i] = c.year
        ep = _new_episode(c, "famine", int(i), m, "great_hunger" if m >= 0.05 else "hunger",
                          parent=_parent(c, "famine", int(i)))
        _add_entry(c, ep, i, rng.integers(1, 3), "front", mort=m, emig=0.005 + 0.3 * m, legitimacy=-0.02 - 1.5 * m,
                   cohesion=-1.0 * m, inst_frac=0.5 * m, food_reserve=-float(c.reserve[i]))


# ------------------------------------------------------------------------------ migration
def _migration(c):
    rng = c.rng
    drought = np.zeros(c.n)
    for eid in c.mem["active"]:
        ep = c.mem["episodes"][eid]
        if ep["type"] == "climate" and ep.get("region") is not None:
            drought[c.region == ep["region"]] = 1.0
    push_nb = (c.contact * c.mem["outflow"][None, :]).sum(axis=1)
    nomad = c.steppe * ramp(BASE["nomad"], c.H) * (1.0 + 2.5 * drought)
    pressure = nomad + 6.0 * push_nb
    active = _active_mask(c, "migration")
    h = (ramp(BASE["migration"], c.H) / 100 * c.P["rate_scale"] * pressure
         * np.exp(1.5 * (0.5 - c.inst) + 0.8 * c.mem["strain"] - 6.0 * np.maximum(0, c.mob - 0.02))) * c.alive
    h[active] = 0.0
    c.hazard["migration"] = h
    c.signs["migration"] = {"riders seen": nomad > 0.4, "refugees": push_nb > 0.01, "drought beyond the border": drought > 0}
    c.nomad_pressure = nomad
    for i in np.where(rng.random(c.n) < h)[0]:
        s = float(np.clip(rng.beta(1.3, 3.5) * (0.6 + 0.4 * min(2.0, pressure[i])), 0, 1))
        steppe = nomad[i] >= 6.0 * push_nb[i]
        conquest = s > 0.6 and rng.random() < 0.5
        kind = ("horde_conquest" if steppe and conquest else "rider_raids" if steppe
                else "folk_wandering" if s > 0.4 else "border_migration")
        src = int(np.argmax(c.contact[i] * c.mem["outflow"]))
        other = nm.people_name(rng) if steppe else _civ_name(c, src)
        ep = _new_episode(c, "migration", int(i), s, kind, parent=_parent(c, "migration", int(i), neighbours=True),
                          other=other, steppe=bool(steppe), conquest=bool(conquest), newcomers=other,
                          source=-1 if steppe else src)
        after = [("institutions", 0.15 * s, 40), ("cohesion", 0.1 * s, 30)] if conquest else []
        e = _add_entry(c, ep, i, 2 + _lognorm(rng, 6, 0.6, 1, 40) * (0.5 + s), "hump", mort=0.01 + 0.22 * s ** 1.5,
                       legitimacy=-0.25 * s, cohesion=-0.2 * s, inst_frac=0.4 * s, trade=-0.1 * s, food_loss=0.15 * s,
                       inequality=0.1 * s if conquest else 0.0, after=after)
        e["inflow"] = (0.02 + 0.12 * s) * c.pop[i] if steppe else 0.0  # newcomers from beyond the known world
        c.D["immigrants"][i] += e["inflow"]


# ------------------------------------------------------------------------------ upheaval, tech
def _upheaval(c):
    rng = c.rng
    active = _active_mask(c, "upheaval").astype(float)
    contagion = 0.002 * (c.contact * active[None, :]).sum(axis=1) * (0.5 + c.know)
    h = (ramp(BASE["upheaval"], c.H) / 100 * c.P["rate_scale"]
         * np.exp(0.6 * c.mem["strain"] + 2.5 * (c.ineq - 0.45) + 2.5 * (0.55 - c.legit) + 0.5 * (c.know * c.trade_lvl - 0.15))
         + contagion) * c.alive
    h[active > 0] = 0.0
    c.hazard["upheaval"] = h
    c.signs["upheaval"] = {"grief": c.mem["strain"] > 0.5, "inequality": c.ineq > 0.6, "doubt": c.legit < 0.4,
                           "new ideas abroad": contagion > 0.002}
    for i in np.where(rng.random(c.n) < h)[0]:
        s = rng.beta(1.5, 3.5)
        H = c.H[i]
        kind = "prophet_schism" if H < -800 else "new_faith" if H < 1400 else "great_schism" if H < 1750 else "overturning"
        ep = _new_episode(c, "upheaval", int(i), s, kind, parent=_parent(c, "upheaval", int(i)))
        _add_entry(c, ep, i, 8 + _lognorm(rng, 15, 0.6, 2, 80), "hump", cohesion=-0.4 * s, legitimacy=-0.3 * s,
                   inst_frac=0.15 * s, after=[("cohesion", 0.25 * s, 20), ("knowledge", 0.04 * s, 20)])


def _tech(c):
    rng = c.rng
    c.mem["tech_recent"] *= 0.97
    diffusion = 0.0008 * (c.contact * c.mem["tech_recent"][None, :]).sum(axis=1) * (c.mem["tech_recent"] < 0.3)
    active = _active_mask(c, "tech")
    h = (ramp(BASE["tech"], c.H) / 100 * np.exp(1.0 * (c.know - 0.4) + 0.8 * (c.trade_lvl - 0.3)) + diffusion) * c.alive
    h[active] = 0.0
    c.hazard["tech"] = h
    c.signs["tech"] = {"new methods": c.know > 0.6, "foreign engines": diffusion > 0.003}
    for i in np.where(rng.random(c.n) < h)[0]:
        s = rng.beta(2.0, 3.0)
        H = c.H[i]
        kind = ("new_metal" if H < 0 else "press_and_powder" if H < 1700 else "engine_age" if H < 1900
                else "lightning_age" if H < 1950 else "thinking_machines")
        ep = _new_episode(c, "tech", int(i), s, kind, parent=_parent(c, "tech", int(i)))
        _add_entry(c, ep, i, 15 + _lognorm(rng, 20, 0.5, 5, 80), "flat", cap=1.0 + 0.25 * s, productivity=0.08 * s,
                   inequality=0.1 * s, legitimacy=-0.1 * s, knowledge=0.05 * s, after=[("inequality", -0.05 * s, 20)])
        c.mem["tech_recent"][i] = 1.0


# ------------------------------------------------------------------------------ collapse
def _collapse(c):
    rng, mem = c.rng, c.mem
    active = _active_mask(c, "collapse").astype(float)
    recent = (c.year - mem["last_collapse_end"]) < 60
    partner = (c.trade_g * active[None, :]).sum(axis=1) / np.maximum(1e-6, c.trade_g.sum(axis=1))
    gate = np.clip((c.inst - 0.1) / 0.2, 0, 1)
    h = (ramp(BASE["collapse"], c.H) / 100 * c.P["rate_scale"] * gate
         * np.exp(3.0 * (0.55 - c.legit) + 2.0 * (0.55 - c.coh) + 2.5 * (c.ineq - 0.45) + 2.5 * (c.overext - 0.3)
                  + 1.2 * mem["strain"] + 3.0 * partner + 2.0 * np.maximum(0, c.pop / c.cap - 1.0))) * c.alive
    h[(active > 0) | recent] = 0.0
    c.hazard["collapse"] = h
    c.signs["collapse"] = {"doubt": c.legit < 0.4, "factions": c.coh < 0.4, "overreach": c.overext > 0.5,
                           "grandees": c.ineq > 0.6, "partners falling": partner > 0.15, "exhaustion": mem["strain"] > 0.8}
    for i in np.where(rng.random(c.n) < h)[0]:
        s = rng.beta(2.0, 2.6)
        ep = _new_episode(c, "collapse", int(i), s, "state_collapse", parent=_parent(c, "collapse", int(i)))
        dur = 15 + _lognorm(rng, 30, 0.6, 5, 240) * (0.5 + s)
        _add_entry(c, ep, i, dur, "hump", mort=0.03 + 0.25 * s, emig=0.03 + 0.12 * s, inst_frac=0.4 + 0.5 * s,
                   legitimacy=-0.1 - 0.4 * s, cohesion=-0.3 * s, knowledge=-0.12 * s, trade=-0.5 * s,
                   cap=1.0 - 0.25 * s, food_loss=0.2 * s,
                   after=[("legitimacy", 0.3, 20), ("inequality", -0.15 * s, 30), ("institutions", 0.25 * s, 60),
                          ("knowledge", 0.05 * s, 60), ("cohesion", 0.2, 30)])
        if c.D["trade_link_mult"] is None:
            c.D["trade_link_mult"] = np.ones((c.n, c.n))
        c.D["trade_link_mult"][i, :] *= 1.0 - 0.7 * s
        c.D["trade_link_mult"][:, i] *= 1.0 - 0.7 * s
        # Systemic collapse: three or more linked polities falling within fifty years.
        linked = [eid for eid in mem["active"] + mem["archive"][-40:]
                  if mem["episodes"][eid]["type"] == "collapse" and eid != ep["id"]
                  and c.year - mem["episodes"][eid]["start"] <= 50
                  and (c.trade_g[i, mem["episodes"][eid]["origin"]] + c.contact[i, mem["episodes"][eid]["origin"]]) > 0.15]
        system = next((mem["episodes"][e].get("system") for e in linked if mem["episodes"][e].get("system")), None)
        system = system or (ep["id"] if linked else None)
        if system:
            ep["system"] = system
            for e in linked:
                mem["episodes"][e]["system"] = system
            members = mem["systems"].setdefault(system, set())
            members |= {mem["episodes"][e]["origin"] for e in linked} | {int(i)}
            if len(members) >= 3 and ("announced", system) not in mem["systems"]:
                mem["systems"][("announced", system)] = True
                c.events.append({"year": c.year, "event": "systemic", "type": "collapse", "kind": "systemic_collapse",
                                 "name": nm.event_name("systemic_collapse", rng, n=len(members)), "episode": system,
                                 "civs": sorted(members)})


# ------------------------------------------------------------------------------ main
def apply_shocks(state, civ_graph, rng, year, params=None):
    """Advance the shock model one game year.

    Returns ``(events, deltas)``. ``events`` is a list of dicts with ``event`` in
    {onset, spread, end, systemic, warning}. ``deltas`` holds what the host applies:
    ``pop_loss_frac`` (share of people who die this year), ``emigrants``/``immigrants``
    (people), ``food_mult``/``output_mult`` (this year's multipliers), ``capacity_mult``
    (lasting), additive level changes for ``LEVEL_KEYS``, ``mobilization_floor``,
    ``war_start``/``war_end`` pairs, ``trade_link_mult`` and ``war_pressure`` (N x N or
    None) and ``deaths_by_type``.
    """
    P = {**DEFAULTS, **(params or {})}
    n = len(np.asarray(state["pop"]))
    c = _Ctx()
    c.n, c.P, c.rng, c.year = n, P, rng, int(year)
    c.mem = mem = _memory(state, n)
    c.alive = _get(state, "alive", n) > 0.5
    c.pop, c.cap = _get(state, "pop", n), np.maximum(1.0, _get(state, "capacity", n))
    c.H = hist_year(_get(state, "era_year", n))
    c.dens, c.trade_lvl, c.hk = _get(state, "density", n), _get(state, "trade", n), _get(state, "health_knowledge", n)
    c.reserve, c.divers = _get(state, "food_reserve", n), _get(state, "diversification", n)
    c.ineq, c.legit, c.coh = _get(state, "inequality", n), _get(state, "legitimacy", n), _get(state, "cohesion", n)
    c.inst, c.overext, c.mob = _get(state, "institutions", n), _get(state, "overextension", n), _get(state, "mobilization", n)
    c.know, c.steppe, c.aggr = _get(state, "knowledge", n), _get(state, "steppe_exposure", n), _get(state, "aggression", n)
    c.endow = _get(state, "disease_endowment", n)
    c.names = list(state.get("names", []))
    c.cities = list(state.get("cities", []))
    g = civ_graph
    live2 = np.outer(c.alive, c.alive)
    c.contact = np.asarray(g["contact"], dtype=float) * live2
    trade_g = g.get("trade")
    c.trade_g = (np.asarray(trade_g, dtype=float) if trade_g is not None
                 else c.contact * np.sqrt(np.outer(c.trade_lvl, c.trade_lvl))) * live2
    c.war = np.asarray(g.get("war", np.zeros((n, n))), dtype=bool) & live2
    c.alliance = np.asarray(g.get("alliance", np.zeros((n, n))), dtype=bool) & live2
    c.region = np.asarray(g.get("region", np.zeros(n)), dtype=int)
    c.clim_vuln = (1.0 - 0.5 * c.divers) * (1.0 - 0.5 * np.clip((c.H - 1850) / 100, 0, 1))
    c.D = _new_deltas(n)
    c.events, c.hazard, c.signs = [], {}, {}
    c.nomad_pressure = np.zeros(n)
    mem["expo"] *= 0.85

    _climate(c)
    _pandemic(c)
    _war(c)
    _economic(c)
    _famine(c, _entry_food(c) * c.noise)
    _migration(c)
    _upheaval(c)
    _tech(c)
    _collapse(c)
    _run_episodes(c)
    _scars(c)
    _route_emigrants(c)
    _warnings(c)

    D = c.D
    for k in LEVEL_KEYS + ["pop_loss_frac", "emigrants", "immigrants"]:
        D[k] = D[k] * c.alive
    mem["outflow"] = D["emigrants"] / np.maximum(1.0, c.pop)
    shock_food = np.maximum(0.0, 1.0 - D["food_mult"] / c.noise)   # weather noise alone is not trauma
    lost = D["pop_loss_frac"] * 3.0 + shock_food * 1.0 + np.maximum(0, -D["institutions"]) * 0.5 \
        + np.maximum(0, -D["legitimacy"]) * 0.3 + mem["outflow"] * 1.0
    mem["strain"] = np.clip(mem["strain"] * 0.9 + lost, 0.0, 2.0) * c.alive
    state["shock_hazard"] = c.hazard            # this year's hazards per type, for court warnings
    state["shock_signs"] = c.signs              # which warning signs are lit, per type
    state["nomad_pressure"] = c.nomad_pressure  # emergence uses it for nomad confederations
    return c.events, D


def _route_emigrants(c):
    """Send this year's emigrants to neighbours in proportion to contact and room to live."""
    out = c.D["emigrants"]
    if out.sum() <= 0:
        return
    room = np.clip(1.2 - c.pop / c.cap, 0.05, 1.0) * c.alive
    w = c.contact * room[None, :]
    np.fill_diagonal(w, 0.0)
    total = w.sum(axis=1, keepdims=True)
    share = np.divide(w, total, out=np.zeros_like(w), where=total > 0)
    c.D["immigrants"] += (out[:, None] * share).sum(axis=0) * 0.7  # the rest die on the road or scatter


def _warnings(c):
    """Court warnings: raised when a hazard is both high and well above its era's reference rate."""
    P = c.P
    ref = {"war": ramp(BASE["war_escalate"], c.H) / 100,
           "economic": ramp(BASE["economic"], c.H) / 100, "migration": ramp(BASE["migration"], c.H) / 100 * 0.3,
           "upheaval": ramp(BASE["upheaval"], c.H) / 100, "collapse": ramp(BASE["collapse"], c.H) / 100,
           "famine": np.full(c.n, 0.005)}
    for typ, h in c.hazard.items():
        if typ not in ref:
            continue
        t = T_INDEX[typ]
        r = h / np.maximum(1e-6, ref[typ])
        thr = P["warn_hazard"] * (0.25 if typ == "war" else 1.0)
        rr = P["warn_ratio"] * (0.75 if typ == "war" else 1.0)
        for i in np.where((h > thr) & (r > rr) & (c.year - c.mem["warned"][:, t] > P["warn_gap"]))[0]:
            c.mem["warned"][i, t] = c.year
            signs = [k for k, v in c.signs.get(typ, {}).items() if bool(np.asarray(v)[i])]
            c.events.append({"year": c.year, "event": "warning", "type": typ, "civ": int(i),
                             "hazard": round(float(h[i]), 4), "signs": signs})


def apply_deltas(state, civ_graph, deltas):
    """Reference application of ``deltas`` to a surrogate state (the demo uses it; SIM may copy it)."""
    alive = np.asarray(state.get("alive", np.ones(len(state["pop"]))), dtype=float) > 0.5
    pop = np.asarray(state["pop"], dtype=float)
    pop = pop * (1.0 - deltas["pop_loss_frac"]) - deltas["emigrants"] + deltas["immigrants"]
    state["pop"] = np.where(alive, np.maximum(pop, 1.0), 0.0)
    state["capacity"] = np.asarray(state["capacity"], dtype=float) * deltas["capacity_mult"]
    for k in LEVEL_KEYS:
        if k in state:
            hi = 3.0 if k in ("productivity", "food_reserve") else 1.0
            lo = 0.3 if k == "productivity" else 0.0
            state[k] = np.clip(np.asarray(state[k], dtype=float) + deltas[k], lo, hi)
    state["mobilization"] = np.maximum(np.asarray(state.get("mobilization", 0.0), dtype=float), deltas["mobilization_floor"])
    if deltas["trade_link_mult"] is not None and "trade" in civ_graph:
        civ_graph["trade"] = civ_graph["trade"] * deltas["trade_link_mult"]
    if "war" in civ_graph:
        for i, j in deltas["war_start"]:
            civ_graph["war"][i, j] = civ_graph["war"][j, i] = True
        for i, j in deltas["war_end"]:
            civ_graph["war"][i, j] = civ_graph["war"][j, i] = False
