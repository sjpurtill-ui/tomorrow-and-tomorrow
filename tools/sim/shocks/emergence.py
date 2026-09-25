"""Civilizational emergence and disappearance: peoples rise, split, merge and vanish.

Public entry points::

    events, changes = apply_emergence(state, civ_graph, rng, year, shock_events, params=None)
    apply_changes(state, civ_graph, changes)        # reference application for surrogates

Mechanisms (all hazards from current conditions, never from the calendar):

    successor    fragments rise from a collapsing civ (inherit people, land, knowledge,
                 grievances, disease stock, and a lineage claim to the fallen realm)
    secession    a distant province breaks away (overextension, weak legitimacy, drift)
    uprising     a successful revolt of the poor or unfree founds a polity (most fail)
    newcomers    a large migration settles and becomes a people of its own
    confederacy  nomad bands coalesce into a confederation on a civ's open frontier
    colony       an overseas/frontier colony declares independence
    union        two kindred or allied peoples merge
    absorbed     a beaten or dwindling people is swallowed by a neighbour
    dispersed    a people too few to hold together scatters into its neighbours

Civs live in fixed *slots* (the game has a fixed rival budget). A birth needs a free
slot; with none free the would-be state stays an autonomous province of its parent and
is counted as ``suppressed``. The player's god follows a people, not a state: see
``god_follow`` in ``changes`` and EPOCHAL_SHIFTS.md.
"""
from __future__ import annotations

import math

import numpy as np

from . import names as nm
from .catalog import hist_year, ramp
from .engine import reset_slot, retire_slot

EMERGENCE_BASE = {  # per game century at the reference state (calibration in EPOCHAL_SHIFTS.md)
    "secession": [(-5000, 0.012), (-3000, 0.025), (0, 0.03), (1000, 0.035), (1800, 0.025), (1950, 0.02), (2030, 0.015)],
    "uprising": [(-5000, 0.05), (-3000, 0.15), (1500, 0.20), (1800, 0.30), (1950, 0.20), (2030, 0.15)],
    # a small, weak people beside a much larger one is gradually annexed or assimilated
    "absorb": [(-5000, 1.3), (1000, 1.3), (1500, 1.8), (1850, 1.2), (1945, 0.03), (2030, 0.02)],
    "confederacy": [(-5000, 0.01), (-1800, 0.05), (-900, 0.10), (1300, 0.12), (1600, 0.05), (1850, 0.005), (2030, 0.0)],
    "colonize": [(-5000, 0.0), (-1200, 0.05), (-500, 0.15), (1000, 0.05), (1450, 0.10), (1500, 0.6), (1900, 0.4),
                 (1950, 0.0), (2030, 0.0)],
    "independence": [(-5000, 0.15), (1700, 0.2), (1900, 0.6), (1950, 2.0), (2030, 2.0)],
    "union": [(-5000, 0.03), (1500, 0.05), (1850, 0.08), (2030, 0.05)],
    # chance that a beaten, much weaker loser is annexed (state death is rare after mid-20th-century norms)
    "annex": [(-5000, 0.35), (1500, 0.35), (1900, 0.3), (1945, 0.03), (2030, 0.02)],
}

DEFAULTS = {"min_viable_pop": 60.0, "min_viable_share": 0.04}


def _mem(state, n):
    m = state.get("emergence_memory")
    if m is None or m.get("n") != n:
        alive = np.asarray(state.get("alive", np.ones(n)), dtype=float) > 0.5
        m = {"n": n, "next_uid": 1, "records": {}, "colonies": [], "recent_independence": [],
             "last_split": np.full(n, -10_000), "suppressed": 0}
        uid = np.zeros(n, dtype=int)
        for i in np.where(alive)[0]:
            uid[i] = m["next_uid"]
            m["records"][m["next_uid"]] = {"uid": m["next_uid"], "slot": int(i), "name": _name(state, i), "kind": "founding",
                                           "parents": [], "born": 0, "died": None, "culture": m["next_uid"]}
            m["next_uid"] += 1
        state["civ_uid"] = uid
        state.setdefault("culture", uid.copy())
        state.setdefault("founding_pop", np.asarray(state["pop"], dtype=float).copy())
        state["emergence_memory"] = m
    return m


def _name(state, i):
    names = state.get("names", [])
    return str(names[i]) if i < len(names) else f"civ{i}"


def _terr_median(state, alive):
    t = np.asarray(state.get("territory", np.ones(len(alive))), dtype=float)
    return float(np.median(t[alive])) if alive.any() else 1.0


class _Plan:
    def __init__(self, n):
        self.births, self.deaths, self.wars, self.events = [], [], [], []
        self.taken = set()
        self.dead = set()
        self.god_follow = None


def _free_slot(state, plan):
    alive = np.asarray(state["alive"], dtype=float) > 0.5
    for i in np.where(~alive)[0]:
        if int(i) not in plan.taken:
            plan.taken.add(int(i))
            return int(i)
    return None


def _birth(state, plan, rng, year, kind, parents, share, terr_share, pos, count_suppressed=True, **traits):
    """Plan a new people carved from ``parents[0]`` (or from beyond the map if parents is empty)."""
    slot = _free_slot(state, plan)
    src = parents[0] if parents else -1
    if slot is None:
        if count_suppressed:
            state["emergence_memory"]["suppressed"] += 1
            plan.events.append({"year": year, "event": "suppressed", "kind": kind, "parent": src})
        return None
    used = set(state.get("names", []))
    parent_name = _name(state, src) if src >= 0 else None
    name = traits.pop("name", None) or nm.people_name(rng, parent=parent_name, used=used)
    b = {"slot": slot, "kind": kind, "parents": [int(p) for p in parents], "share": float(share),
         "terr_share": float(terr_share), "pos": pos, "name": name, "cities": nm.place_names(rng, name),
         "lineage_claim": parent_name, **traits}
    plan.births.append(b)
    plan.events.append({"year": year, "event": "birth", "kind": kind, "slot": slot, "name": name,
                        "parents": [_name(state, p) for p in parents], "lineage_claim": parent_name})
    return b


def _near(state, i, rng, spread=60.0):
    x, y = float(state["x"][i]), float(state["y"][i])
    a = rng.uniform(0, 2 * math.pi)
    return (x + spread * math.cos(a), y + spread * math.sin(a))


def apply_emergence(state, civ_graph, rng, year, shock_events, params=None):
    """Plan this year's births and deaths of peoples. Returns ``(events, changes)``."""
    P = {**DEFAULTS, **(params or {})}
    n = len(np.asarray(state["pop"]))
    m = _mem(state, n)
    alive = np.asarray(state["alive"], dtype=float) > 0.5
    pop = np.asarray(state["pop"], dtype=float)
    H = hist_year(np.asarray(state["era_year"], dtype=float))
    legit = np.asarray(state["legitimacy"], dtype=float)
    coh = np.asarray(state["cohesion"], dtype=float)
    ineq = np.asarray(state["inequality"], dtype=float)
    inst = np.asarray(state["institutions"], dtype=float)
    overext = np.asarray(state["overextension"], dtype=float)
    mob = np.asarray(state.get("mobilization", np.full(n, 0.01)), dtype=float)
    trade = np.asarray(state["trade"], dtype=float)
    terr = np.asarray(state["territory"], dtype=float)
    cap = np.maximum(1.0, np.asarray(state["capacity"], dtype=float))
    contact = np.asarray(civ_graph["contact"], dtype=float) * np.outer(alive, alive)
    smem = state.get("shock_memory", {})
    strain = smem.get("strain", np.zeros(n))
    tmed = _terr_median(state, alive)
    plan = _Plan(n)
    is_player = np.asarray(state.get("is_player", np.zeros(n)), dtype=bool)

    def busy(i):
        return int(i) in plan.dead or any(int(i) in b["parents"] for b in plan.births)

    # --- driven by this year's shocks ----------------------------------------------------
    for ev in shock_events:
        if ev.get("event") == "onset" and ev["type"] == "collapse":
            i = ev["origin"]
            if busy(i) or not alive[i]:
                continue
            s = ev["severity"]
            big = min(2.0, terr[i] / tmed) * min(2.0, pop[i] / max(1.0, np.median(pop[alive])))
            k = int(min(5, rng.poisson(0.1 + 0.9 * s * big)))
            if k == 0:
                continue  # the centre holds: a dynastic breakdown without fragments
            total = 0.25 + 0.45 * s
            shares = rng.dirichlet(np.ones(k)) * total
            for sh in shares:
                _birth(state, plan, rng, year, "successor", [i], sh, sh, _near(state, i, rng),
                       grievance=[int(i)], inherit_knowledge=rng.uniform(0.7, 0.95), institutions=rng.uniform(0.2, 0.35))
            if s > 0.7 and 1 - total < 0.3 and rng.random() < 0.5:
                plan.dead.add(int(i))
                plan.deaths.append({"slot": int(i), "kind": "dispersed", "into": [b["slot"] for b in plan.births if i in b["parents"]]})
        elif ev.get("event") == "onset" and ev["type"] == "migration":
            i, s = ev["origin"], ev["severity"]
            if busy(i) or not alive[i] or s < 0.35 or rng.random() > 0.35 * s:
                continue
            ep = smem["episodes"][ev["episode"]]
            src = ep.get("source", -1)
            share = 0.04 + 0.12 * s
            b = _birth(state, plan, rng, year, "newcomers", [i] if src < 0 else [i, src], share, 0.05 + 0.1 * s,
                       _near(state, i, rng, 80), name=ep.get("newcomers") if ep.get("steppe") else None,
                       institutions=0.25, grievance=[int(i)], newcomer_pop_from_outside=bool(ep.get("steppe")))
            if b is not None:
                plan.wars.append((b["slot"], int(i)))
    # annexation after wars
    for ev in shock_events:
        if ev.get("event") == "end" and ev["type"] == "war":
            ep = smem["episodes"][ev["episode"]]
            for loser in ep.get("losers", []):
                winners = [w for w in ep.get("winners", []) if alive[w]]
                if not winners or busy(loser) or not alive[loser]:
                    continue
                w = max(winners, key=lambda k: pop[k])
                if pop[loser] < 0.35 * pop[w] and contact[w, loser] > 0.2 and rng.random() < ramp(EMERGENCE_BASE["annex"], H[w]) * (1.2 - inst[loser]):
                    plan.dead.add(int(loser))
                    plan.deaths.append({"slot": int(loser), "kind": "absorbed", "into": [int(w)]})

    # --- secession and uprisings -----------------------------------------------------------
    size = np.clip(terr / tmed - 0.5, 0, 2.0)
    upheaval = np.zeros(n)
    famine = np.zeros(n)
    for eid in smem.get("active", []):
        ep = smem["episodes"][eid]
        for i, e in ep["civs"].items():
            if not e.get("done"):
                if ep["type"] == "upheaval":
                    upheaval[i] = 1.0
                if ep["type"] == "famine":
                    famine[i] = 1.0
    age = np.clip((year - m["last_split"]) / 300.0, 0, 1)
    h_sec = (ramp(EMERGENCE_BASE["secession"], H) / 100 * size
             * np.exp(2 * (overext - 0.3) + 2.5 * (0.55 - legit) + 2 * (0.55 - coh) + 0.3 * age + 0.5 * strain + 0.8 * upheaval))
    h_up = (ramp(EMERGENCE_BASE["uprising"], H) / 100
            * np.exp(3 * (ineq - 0.5) + 3 * (0.5 - legit) + 1.2 * strain + 1.0 * famine))
    for i in np.where(alive)[0]:
        if busy(i):
            continue
        if rng.random() < h_sec[i]:
            share = rng.uniform(0.1, 0.3)
            b = _birth(state, plan, rng, year, "secession", [i], share, share, _near(state, i, rng, 90),
                       inherit_knowledge=rng.uniform(0.9, 1.0), institutions=float(inst[i]) * rng.uniform(0.6, 0.9),
                       grievance=[int(i)])
            if b is not None:
                m["last_split"][i] = year
                if rng.random() < 0.4:
                    plan.wars.append((b["slot"], int(i)))
        elif rng.random() < h_up[i]:
            success = 0.04 + 0.15 * (1 - inst[i]) * max(0.0, 1 - 10 * mob[i])
            if rng.random() < success:
                share = rng.uniform(0.05, 0.2)
                b = _birth(state, plan, rng, year, "uprising", [i], share, share * 0.8, _near(state, i, rng, 50),
                           inherit_knowledge=rng.uniform(0.8, 0.95), institutions=0.2, inequality=0.25, grievance=[int(i)])
                if b is not None:
                    plan.wars.append((b["slot"], int(i)))
            else:
                plan.events.append({"year": year, "event": "uprising_crushed", "slot": int(i), "name": _name(state, i)})

    # --- nomad confederacies on open frontiers --------------------------------------------
    nomad = np.asarray(state.get("nomad_pressure", np.zeros(n)), dtype=float)
    h_conf = ramp(EMERGENCE_BASE["confederacy"], H) / 100 * nomad * alive
    for i in np.where(rng.random(n) < h_conf)[0]:
        if busy(i):
            continue
        cx, cy = float(np.mean(np.asarray(state["x"])[alive])), float(np.mean(np.asarray(state["y"])[alive]))
        dx, dy = float(state["x"][i]) - cx, float(state["y"][i]) - cy
        d = math.hypot(dx, dy) or 1.0
        pos = (float(state["x"][i]) + 150 * dx / d, float(state["y"][i]) + 150 * dy / d)
        b = _birth(state, plan, rng, year, "confederacy", [], rng.uniform(0.2, 0.5) * pop[i], 0.6 * terr[i], pos,
                   from_outside=True, anchor=int(i), institutions=0.25, density=0.08, aggression=0.85, steppe_exposure=1.0)
        if b is not None:
            plan.wars.append((b["slot"], int(i)))

    # --- colonies: founding, growth, independence -----------------------------------------
    h_col = ramp(EMERGENCE_BASE["colonize"], H) / 100 * trade * np.clip(pop / cap - 0.6, 0, 1) * 4 * alive
    for i in np.where(rng.random(n) < h_col)[0]:
        if len([c for c in m["colonies"] if c["parent_uid"] == state["civ_uid"][i]]) < 4:
            a = rng.uniform(0, 2 * math.pi)
            r = rng.uniform(250, 900) if H[i] < 1450 else rng.uniform(1200, 3200)
            share = rng.uniform(0.01, 0.03)
            m["colonies"].append({"parent": int(i), "parent_uid": int(state["civ_uid"][i]), "pop": share * pop[i],
                                  "founded": year, "pos": (float(state["x"][i]) + r * math.cos(a), float(state["y"][i]) + r * math.sin(a))})
            plan.events.append({"year": year, "event": "colony_founded", "slot": int(i), "name": _name(state, i), "pop": share * pop[i]})
            state["pop"][i] -= share * pop[i]
    recent = sum(1 for y in m["recent_independence"] if year - y <= 30)
    keep = []
    for col in m["colonies"]:
        i = col["parent"]
        if not alive[i] or state["civ_uid"][i] != col["parent_uid"]:
            col["parent"] = -1
        col["pop"] *= 1.015 if col["pop"] < 0.5 * max(pop[i] if i >= 0 else 1e9, 1) else 1.005
        age_c = (year - col["founded"]) / 150.0
        pl = legit[i] if i >= 0 else 0.0
        Hc = H[i] if i >= 0 else float(np.max(H[alive]))
        h = ramp(EMERGENCE_BASE["independence"], Hc) / 100 * math.exp(2 * min(1.0, col["pop"] / max(1.0, pop[i] if i >= 0 else 1.0))
                                                                    + 1.5 * min(2.0, age_c) + 2 * (0.55 - pl) + 0.5 * recent)
        if i < 0:
            h = 1.0
        if col["pop"] > 30 and rng.random() < h:
            b = _birth(state, plan, rng, year, "colony", [i] if i >= 0 else [], col["pop"], 0.0, col["pos"],
                       count_suppressed=not col.get("tried"),
                       absolute_pop=col["pop"], inherit_knowledge=0.95, institutions=float(inst[i]) * 0.8 if i >= 0 else 0.4,
                       grievance=[i] if i >= 0 else [])
            col["tried"] = True
            if b is not None:
                m["recent_independence"].append(year)
                if i >= 0 and rng.random() < 0.4:
                    plan.wars.append((b["slot"], int(i)))
                continue
        keep.append(col)
    m["colonies"] = keep

    # --- unions ------------------------------------------------------------------------------
    alliance = np.asarray(civ_graph.get("alliance", np.zeros((n, n))), dtype=bool)
    culture = np.asarray(state["culture"])
    small = pop < np.median(pop[alive]) if alive.any() else np.zeros(n, dtype=bool)
    ub = ramp(EMERGENCE_BASE["union"], H) / 100
    for i, j in zip(*np.where(np.triu(contact > 0.4, 1))):
        if busy(i) or busy(j) or not (small[i] or small[j]):
            continue
        kin = 1.0 if culture[i] == culture[j] else 0.3
        h = ub[i] * contact[i, j] * kin * (1 + alliance[i, j]) * (1 + strain[i] + strain[j])
        if rng.random() < h:
            big, little = (i, j) if pop[i] >= pop[j] else (j, i)
            if is_player[little] and not is_player[big]:
                big, little = little, big  # the god's people are the uniting crown
            plan.dead.add(int(little))
            plan.deaths.append({"slot": int(little), "kind": "union", "into": [int(big)]})
            plan.events.append({"year": year, "event": "union", "slot": int(big), "name": _name(state, big),
                                "absorbed": _name(state, little)})

    # --- annexation / assimilation of small weak peoples by large neighbours ----------------
    ab = ramp(EMERGENCE_BASE["absorb"], H) / 100
    for i in np.where(alive)[0]:
        if busy(i) or is_player[i]:
            continue  # the god's own people are never quietly assimilated; they can still fall in war
        cand = contact[i] * alive * (pop / max(1.0, pop[i]))
        j = int(np.argmax(cand))
        ratio = pop[j] / max(1.0, pop[i])
        if j == i or contact[i, j] < 0.2 or busy(j):
            continue
        h = ab[j] * contact[i, j] * min(1.5, max(0.0, (ratio - 1.5) / 3.0)) * (1.3 - inst[i]) * (1.0 + strain[i])
        if rng.random() < h:
            plan.dead.add(int(i))
            plan.deaths.append({"slot": int(i), "kind": "absorbed", "into": [j]})

    # --- dispersal of peoples too few to hold together --------------------------------------
    fpop = np.asarray(state["founding_pop"], dtype=float)
    for i in np.where(alive)[0]:
        if busy(i):
            continue
        if pop[i] < max(P["min_viable_pop"], P["min_viable_share"] * fpop[i]):
            into = [int(j) for j in np.argsort(-contact[i])[:2] if contact[i, j] > 0.05 and alive[j]]
            plan.dead.add(int(i))
            plan.deaths.append({"slot": int(i), "kind": "absorbed" if into else "dispersed", "into": into})

    # --- the god follows a people -------------------------------------------------------------
    for d in plan.deaths:
        if is_player[d["slot"]]:
            heirs = [b for b in plan.births if d["slot"] in b["parents"]] or []
            if heirs:
                plan.god_follow = max(heirs, key=lambda b: b["share"])["slot"]
            elif d["into"]:
                plan.god_follow = d["into"][0]
            else:  # the faithful scatter to the nearest people, and the god goes with them
                near = np.argsort(-contact[d["slot"]])
                plan.god_follow = next((int(j) for j in near if alive[j] and int(j) not in plan.dead), None)
            plan.events.append({"year": year, "event": "god_follows", "from": _name(state, d["slot"]),
                                "to_slot": plan.god_follow})
    for b in plan.births:
        if any(is_player[p] for p in b["parents"] if p >= 0):
            dev = float(np.asarray(state.get("devotion", np.full(n, 0.7)))[b["parents"][0]])
            b["devotion"] = dev * float(rng.uniform(0.2, 1.0))
            plan.events.append({"year": year, "event": "god_choice", "slot": b["slot"], "name": b["name"],
                                "devotion": round(b["devotion"], 2), "kind": b["kind"]})

    return plan.events, {"births": plan.births, "deaths": plan.deaths, "wars": plan.wars, "god_follow": plan.god_follow}


_INHERIT = ["density", "trade", "health_knowledge", "diversification", "era_year", "steppe_exposure", "aggression",
            "disease_endowment", "productivity"]


def apply_changes(state, civ_graph, changes, year=0):
    """Reference application of emergence ``changes`` to a slot-based surrogate state."""
    m = state["emergence_memory"]
    n = len(state["pop"])
    for b in changes["births"]:
        s = b["slot"]
        parents = [p for p in b["parents"] if p >= 0]
        src = parents[0] if parents else b.get("anchor", -1)
        if b.get("absolute_pop") is not None:
            newpop = b["absolute_pop"]
        elif b.get("from_outside") or b.get("newcomer_pop_from_outside"):
            newpop = b["share"] if b.get("from_outside") else b["share"] * state["pop"][src]
        else:
            newpop = b["share"] * state["pop"][src]
            state["pop"][src] -= newpop
        tshare = b["terr_share"]
        new_terr = tshare if b.get("from_outside") else (tshare * state["territory"][src] if src >= 0 else 1.0)
        if parents and tshare > 0:
            state["territory"][src] -= new_terr
            state["capacity"][src] *= (1 - tshare)
        if b["kind"] == "colony":
            new_terr = max(0.5, newpop / max(1.0, state["capacity"][src] / max(1e-6, state["territory"][src]))) if src >= 0 else 1.0
        state["alive"][s] = True
        state["pop"][s] = max(10.0, newpop)
        state["founding_pop"][s] = state["pop"][s]
        state["territory"][s] = max(0.2, new_terr)
        if src >= 0:
            state["capacity"][s] = state["capacity"][src] / max(1e-6, state["territory"][src]) * state["territory"][s]
            for k in _INHERIT:
                if k in state:
                    state[k][s] = state[k][src]
            state["knowledge"][s] = state["knowledge"][src] * b.get("inherit_knowledge", 0.9)
        else:
            state["capacity"][s] = state["pop"][s] * 1.3
        state["capacity"][s] = max(state["capacity"][s], state["pop"][s] * 1.05)
        state["institutions"][s] = b.get("institutions", 0.3)
        state["legitimacy"][s] = 0.55 + (0.1 if b.get("lineage_claim") else 0.0)
        state["cohesion"][s] = 0.65
        state["inequality"][s] = b.get("inequality", 0.4)
        state["overextension"][s] = 0.1
        state["mobilization"][s] = 0.04 if b["kind"] in ("confederacy", "uprising", "secession") else 0.01
        for k in ("density", "aggression", "steppe_exposure"):
            if k in b:
                state[k][s] = b[k]
        state["x"][s], state["y"][s] = b["pos"]
        state["region"][s] = state["region"][src] if src >= 0 else int(np.max(state["region"])) + 1
        state["is_player"][s] = False
        state["devotion"][s] = b.get("devotion", 0.0)
        state["names"][s] = b["name"]
        state["cities"][s] = b["cities"]
        uid = m["next_uid"]
        m["next_uid"] += 1
        state["civ_uid"][s] = uid
        state["culture"][s] = state["culture"][src] if src >= 0 else uid
        m["records"][uid] = {"uid": uid, "slot": s, "name": b["name"], "kind": b["kind"], "born": year, "died": None,
                             "parents": [int(state["civ_uid"][p]) for p in parents], "lineage_claim": b.get("lineage_claim"),
                             "culture": int(state["culture"][s])}
        reset_slot(state, s, src if src >= 0 else None)
        for g in ("war", "alliance"):
            if g in civ_graph:
                civ_graph[g][s, :] = civ_graph[g][:, s] = False
    for d in changes["deaths"]:
        i = d["slot"]
        if not state["alive"][i]:
            continue
        into = [j for j in d["into"] if state["alive"][j] or any(b["slot"] == j for b in changes["births"])]
        if into:
            per = state["pop"][i] / len(into)
            for j in into:
                state["pop"][j] += per * 0.9
                state["territory"][j] += state["territory"][i] / len(into)
                state["capacity"][j] += state["capacity"][i] / len(into)
        rec = m["records"].get(int(state["civ_uid"][i]))
        if rec:
            rec["died"], rec["death_kind"] = year, d["kind"]
        state["alive"][i] = False
        state["pop"][i] = 0.0
        retire_slot(state, i)
        for g in ("war", "alliance"):
            if g in civ_graph:
                civ_graph[g][i, :] = civ_graph[g][:, i] = False
    for a, b in changes["wars"]:
        if state["alive"][a] and state["alive"][b] and "war" in civ_graph:
            civ_graph["war"][a, b] = civ_graph["war"][b, a] = True
    if changes.get("god_follow") is not None:
        state["is_player"][:] = False
        state["is_player"][changes["god_follow"]] = True
        state["devotion"][changes["god_follow"]] = max(0.5, state["devotion"][changes["god_follow"]])
