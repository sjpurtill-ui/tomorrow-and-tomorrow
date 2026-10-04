"""Quick pacing model for first contact and envoys (codex/envoy-pace).

Mirrors the rules in scripts/civilization_system.gd (scout_known_reach_km: the
same known-country rule for every people's parties), scripts/neighbor_signs.gd
(range_km, ENCOUNTER_KM) and scripts/audience_hall.gd (ERA_GLOBAL_GAP,
ERA_CIV_GAP, civ_gap, _business_mix, sequels, one envoy waiting at a time).
Neighbour distances come from the placement probe (civilization_start.gd
candidate, then the real founding-site choice) on 20 seeds.
Run: python tests/fun_audit/envoy_pace_model.py
     python tests/fun_audit/envoy_pace_model.py --contact-table [--years 120] [--before]
"""
import math, random, statistics, sys

# (nearest, second, third, fourth) km from the player's home, after the
# planet-wide placement (codex/far-peoples: every seat at least 2,000 km from
# every other); the nearest is measured at the real founding sites.
WORLDS = {7932:[3909,5069,5480,6388],15851:[3223,7777,8034,9803],23770:[4174,5106,5172,8294],
    31689:[3428,3665,4486,4924],39608:[6558,6788,9110,9146],47527:[2672,5752,8239,9878],
    55446:[7675,14857,16402,16878],63365:[3246,4716,6308,6552],71284:[4128,5776,6508,6603],
    79203:[3011,4965,5584,6308],87122:[5611,6196,8573,9271],95041:[5023,5607,5695,6462],
    102960:[3406,3499,5336,5715],110879:[5318,8113,8147,8547],118798:[2038,5564,5952,7249],
    126717:[2597,3538,5961,6132],134636:[2269,3294,4376,4962],142555:[2248,3289,4992,9164],
    150474:[2325,2445,5892,6080],158393:[3491,5808,6801,7176]}
# The same 20 seeds under the old regional groups of three (two peoples placed
# 250-600 km from the player's seat): the "before" of codex/far-peoples.
REGIONAL_WORLDS = {7932:[460,4733,5050,5069],15851:[291,424,9437,10603],23770:[301,422,9446,9838],
    31689:[341,412,1780,2361],39608:[316,577,10490,10585],47527:[361,402,7942,8242],
    55446:[428,581,16390,16774],63365:[331,388,1774,1981],71284:[418,538,5124,6969],
    79203:[360,588,4433,4621],87122:[404,439,5716,6196],95041:[497,573,6203,6275],
    102960:[368,556,5492,5715],110879:[388,584,8113,8408],118798:[428,447,5564,5803],
    126717:[428,502,612,971],134636:[474,520,4304,4423],142555:[394,566,2229,2516],
    150474:[369,581,5300,5482],158393:[260,278,2978,3105]}
YEARS = 30
ENCOUNTER_KM = 58.0
FREQ = {"rare":1.6,"normal":1.0,"lively":0.6}
ERA_GLOBAL_GAP = [700,560,280,140]
ERA_CIV_GAP = [1400,1150,650,350]
CIV_GAP = 180
CIV_CRISIS_GAP = 120

def travel_knowledge(t):  # route_speed discoveries accumulate slowly
    return min(0.6, 0.008 * t)

def known_reach(t):
    return 110.0 + t * 18.0 * (1.0 + travel_knowledge(t) * 1.5)

def foreign_range(t):
    # Every people's parties walk its own known country (scout_known_reach_km
    # in that people's scope): the same rule as ours.
    return known_reach(t)

def sign_range(t):
    pop = 160 + 12 * t
    return max(150.0, min(240.0, 120.0 + math.sqrt(pop) * 4.0))

def radial_pass(dist, bearing_err, reach):
    """Closest approach of a radial route of length `reach` to a point at
    `dist` whose bearing differs by bearing_err."""
    along = dist * math.cos(bearing_err)
    if along <= 0: return dist
    if along >= reach:
        return math.hypot(dist * math.cos(bearing_err) - reach, dist * math.sin(bearing_err))
    return abs(dist * math.sin(bearing_err))

def contact_run(dists, rng, years=None, player_scouting=True):
    """Returns per-neighbour (sign_day, contact_day) over `years` (default YEARS)
    for the given homes. Without player scouting only their parties travel."""
    years = YEARS if years is None else years
    homes = [(d, rng.uniform(-math.pi, math.pi)) for d in dists]
    sign = [None] * len(homes); contact = [None] * len(homes); how = [None] * len(homes)
    day = 30
    foreign_next = [rng.randint(0, 60) for _ in homes]
    foreign_seq = [rng.randint(0, 50) for _ in homes]
    while day < years * 365:
        t = day / 365.0
        # player parties: about one departure a month across two parties
        reach = known_reach(t) if player_scouting else 0.0
        target = None
        for i, (d, b) in enumerate(homes):
            if sign[i] is not None and contact[i] is None and d - ENCOUNTER_KM <= reach:
                target = i; break
        if target is not None:
            d, b = homes[target]
            est_b = b + rng.gauss(0, 0.12)
            bearing = est_b
        else:
            bearing = rng.uniform(-math.pi, math.pi)
        length = reach * rng.uniform(0.75, 1.0)
        for i, (d, b) in enumerate(homes):
            if contact[i] is not None: continue
            err = abs((bearing - b + math.pi) % (2 * math.pi) - math.pi)
            closest = radial_pass(d, err, length)
            if closest <= ENCOUNTER_KM: contact[i] = day; how[i] = "our scouts"
            elif closest <= sign_range(t) and sign[i] is None: sign[i] = day
        # foreign scouts (each neighbour's one field party)
        for i, (d, b) in enumerate(homes):
            if contact[i] is not None or day < foreign_next[i]: continue
            fr = foreign_range(t)
            foreign_seq[i] += 1
            depth = 0.62 + 0.38 * ((foreign_seq[i] + 1) * 0.61803398875 % 1.0)
            flen = fr * depth
            err = abs(((foreign_seq[i] * 2.399963) % (2 * math.pi)) - math.pi)
            if radial_pass(d, err, flen) <= 12.0: contact[i] = day; how[i] = "their scouts"
            foreign_next[i] = day + int(2 * flen / 22.0) + 5
        day += rng.randint(25, 40)
    return sign, contact, how

# ---- envoy scheduler -------------------------------------------------------
SITUATIONS_GIFT = {"gift_goods", "artifact_gift"}
FIRST_CONTACT_MIX = {"gift_goods":0.25,"news_report":0.9,"accord_offer":0.7,"rumor_share":0.8,"intelligence_share":0.6,"trade_offer":0.6,"artifact_gift":0.15}
WARM_MIX = {"gift_goods":0.3,"accord_offer":1.0,"protection_pact":0.8,"league_invitation":0.6,"scholar_offer":0.8,"research_sale":0.6,"license_offer":0.5,"trade_offer":0.8,"nonaggression_offer":0.4,"artifact_gift":0.3,"artifact_purchase":0.5}
COOL_MIX = {"tribute_demand":1.0,"nonaggression_offer":0.6,"accord_offer":0.5,"news_report":0.3}
TENSION_MIX = {"tribute_demand":1.2,"nonaggression_offer":0.8,"accord_offer":0.7}
# Stone-age peoples cannot sell studies or licenses they do not have yet.
UNAVAILABLE_EARLY = {"research_sale", "license_offer", "scholar_offer", "league_invitation"}

def pick(mix, rng, t, gift_ok):
    items = [(k, w) for k, w in mix.items() if w > 0 and (gift_ok or k not in SITUATIONS_GIFT) and not (t < 15 and k in UNAVAILABLE_EARLY)]
    if not items: return None
    total = sum(w for _, w in items); r = rng.random() * total
    for k, w in items:
        r -= w
        if r <= 0: return k
    return items[-1][0]

def business_mix(civ, rng, t, gift_ok):
    mix = {}
    if civ["opinion"] >= 0.3: mix.update({"accord_offer":0.7,"protection_pact":0.5,"league_invitation":0.3})
    if civ["opinion"] <= -0.2 or civ["tension"] >= 0.45: mix.update({"tribute_demand":1.0,"nonaggression_offer":0.5})
    if civ["commerce"] or rng.random() < 0.3: mix.update({"trade_offer":0.6,"artifact_purchase":0.3,"research_sale":0.3,"license_offer":0.25,"scholar_offer":0.3})
    if rng.random() < 0.15: mix.update({"news_report":0.5,"intelligence_share":0.3})
    if gift_ok and rng.random() < 0.15: mix["gift_goods"] = 0.4
    return mix

def envoy_run(contacts, rng, level="normal", era_at=lambda t: 0 if t < 15 else 1, years=YEARS):
    scale = FREQ[level]
    civs = []
    for i, cday in enumerate(contacts):
        if cday is None: continue
        civs.append({"id": i, "met": cday, "opinion": rng.uniform(-0.34, 0.28), "tension": rng.uniform(0.05, 0.4),
            "commerce": rng.random() < 0.2, "last": -99999, "word": -99999, "last_gift": -99999})
    occasions = []  # dicts: civ, type, not_before, expires, crisis, mix
    last_arrival = -9999; next_any = 0; last_speaker = None
    arrivals = []; words = 0; stale = 0
    for day in range(1, years * 365 + 1):
        t = day / 365.0
        tier = era_at(t)
        gap = ERA_GLOBAL_GAP[tier] * scale / (1 + 0.2 * 0.3)
        live = [c for c in civs if c["met"] <= day]
        for c in live:
            if c["met"] == day:
                occasions.append({"civ": c, "type": "first_contact", "nb": day + 5, "exp": day + 150, "crisis": False, "mix": FIRST_CONTACT_MIX})
            # the living world: opinion drift, frontier worry, hunger, grudges
            if day % 30 == 0:
                c["opinion"] = max(-0.9, min(0.9, c["opinion"] + rng.gauss(0, 0.05)))
                if rng.random() < 0.25 / 12: occasions.append({"civ": c, "type": "swing", "nb": day, "exp": day + 120, "crisis": False, "mix": WARM_MIX if c["opinion"] > 0 else COOL_MIX})
                if rng.random() < 0.08 / 12: occasions.append({"civ": c, "type": "tension", "nb": day, "exp": day + 90, "crisis": rng.random() < 0.3, "mix": TENSION_MIX})
                if rng.random() < 0.10 / 12: occasions.append({"civ": c, "type": "famine", "nb": day, "exp": day + 60, "crisis": True, "mix": {"aid_request": 1.0}})
                if rng.random() < 0.05 / 12: occasions.append({"civ": c, "type": "grudge", "nb": day, "exp": day + 300, "crisis": False, "mix": {"redress_demand": 1.0}})
        # expire
        for o in list(occasions):
            if o["exp"] <= day:
                occasions.remove(o)
                if o["type"] not in ("ambient", "sequel"): stale += 1
        def civ_gap(c):
            return max(CIV_GAP, ERA_CIV_GAP[tier] * scale / (1 + 0.2 * 0.4))
        def speaker_ok(o):
            c = o["civ"]
            if last_speaker is c and o["type"] != "sequel": return False
            floor = CIV_CRISIS_GAP if o["crisis"] else (CIV_GAP if o["type"] == "sequel" else max(CIV_GAP, civ_gap(c) * 0.6))
            return day - c["last"] >= floor
        # ambient
        if day - last_arrival >= gap and day >= next_any and not any(o["nb"] <= day and speaker_ok(o) for o in occasions):
            pool = []
            for c in live:
                if last_speaker is c: continue
                heard = max(c["last"], c["word"], c["met"])
                if day - heard < civ_gap(c): continue
                mix = business_mix(c, rng, t, day - c["last_gift"] >= 3650)
                if not mix or pick(mix, rng, t, True) is None:
                    c["word"] = day; words += 1; continue
                pool.append((c, mix))
            if pool:
                c, mix = rng.choice(pool); c["word"] = day
                occasions.append({"civ": c, "type": "ambient", "nb": day, "exp": day + 45, "crisis": False, "mix": mix})
        # arrivals (one envoy waiting at a time; answered within days)
        if day - last_arrival < 20: continue
        ready = sorted([o for o in occasions if o["nb"] <= day], key=lambda o: (not o["crisis"], o["type"] != "sequel"))
        for o in ready:
            since = day - last_arrival
            budget = since >= max(20, min(60, gap * 0.5)) if o["crisis"] else day >= next_any
            if not budget or not speaker_ok(o): continue
            occasions.remove(o)
            c = o["civ"]
            s = pick(o["mix"], rng, t, day - c["last_gift"] >= 3650)
            if s is None: continue
            arrivals.append((day, c["id"], s, tier))
            last_arrival = day; next_any = day + gap * rng.uniform(0.75, 1.3); last_speaker = c; c["last"] = day
            if s in SITUATIONS_GIFT: c["last_gift"] = day
            # unfinished business brings a sequel (refusals, threats, aid)
            unfinished = s in ("tribute_demand", "redress_demand", "aid_request") or rng.random() < 0.25
            if unfinished:
                nb = day + max(CIV_GAP, civ_gap(c) * 0.6) + rng.randint(0, 90)
                occasions.append({"civ": c, "type": "sequel", "nb": nb, "exp": nb + 240, "crisis": False,
                    "mix": {"news_report": 0.8, "tribute_demand": 0.6, "gratitude_gift": 0.6, "accord_offer": 0.4}})
            break
    return arrivals, words, stale

def main():
    firsts = []; nearest = []; met10 = []; met30 = []; signs = []; second_gap = []
    per_year_stone = []; per_year_stone_by_level = {"rare": [], "normal": [], "lively": []}
    later = []; gift_share = []; all_arrivals = 0; all_gifts = 0; words_total = 0; ages = []
    rows = []
    for seed, dists in WORLDS.items():
        for rep in range(4):
            rng = random.Random(seed * 10 + rep)
            sign, contact, how = contact_run(dists, rng)
            met = sorted(c for c in contact if c is not None)
            first = met[0] / 365.0 if met else None
            firsts.append(first if first is not None else 99)
            nearest.append(dists[0])
            fs = [s for s in sign if s is not None]
            signs.append(min(fs) / 365.0 if fs else (first if first else 99))
            met10.append(sum(1 for c in met if c <= 3650)); met30.append(len(met))
            if len(met) >= 2: second_gap.append((met[1] - met[0]) / 365.0)
            arr, words, _ = envoy_run(contact, random.Random(seed + rep * 7))
            words_total += words
            if met:
                span_days = YEARS * 365 - met[0]
                stone = [a for a in arr if a[3] <= 1]
                per_year_stone.append(len(stone) / max(1.0, span_days / 365.0))
            all_arrivals += len(arr); all_gifts += sum(1 for a in arr if a[2] in SITUATIONS_GIFT)
            for level in ("rare", "normal", "lively"):
                a2, _, _ = envoy_run(contact, random.Random(seed + rep * 7), level)
                if met: per_year_stone_by_level[level].append(len(a2) / max(1.0, (YEARS * 365 - met[0]) / 365.0))
            if rep == 0: rows.append((seed, dists[0], dists[1], signs[-1], first, met10[-1], met30[-1], [how[i] for i in range(len(how)) if contact[i] is not None]))
    # later eras: two peoples met at day 0, metal age, 10 years
    for rep in range(40):
        arr, _, _ = envoy_run([0, 400, 3000], random.Random(900 + rep), "normal", era_at=lambda t: 2, years=10)
        later.append(len(arr) / 10.0)
    q = lambda xs, p: sorted(xs)[min(len(xs) - 1, int(p * len(xs)))]
    print("seed   nearest second  first-sign-yr first-contact-yr met@10 met@30 how")
    for r in rows:
        print("%-7d %5d %6d   %6.1f        %6s          %d      %d   %s" % (r[0], r[1], r[2], r[3], "%.1f" % r[4] if r[4] else "none", r[5], r[6], ",".join(r[7])))
    print()
    print("runs: %d (12 seeds x 4)" % len(firsts))
    print("nearest neighbour km: median %d, range %d-%d" % (statistics.median(nearest), min(nearest), max(nearest)))
    print("first sign year: median %.1f (p10 %.1f, p90 %.1f)" % (statistics.median(signs), q(signs, .1), q(signs, .9)))
    print("first contact year: median %.1f (p10 %.1f, p90 %.1f); share in years 5-20: %.0f%%; none by 30: %.0f%%" % (
        statistics.median(firsts), q(firsts, .1), q(firsts, .9), 100 * sum(1 for f in firsts if 5 <= f <= 20) / len(firsts), 100 * sum(1 for f in firsts if f >= 99) / len(firsts)))
    print("years between first and second people: median %.1f (p10 %.1f)" % (statistics.median(second_gap), q(second_gap, .1)))
    print("peoples met by year 10: mean %.2f; by year 30: mean %.2f" % (statistics.mean(met10), statistics.mean(met30)))
    print("stone-age envoys per year after first contact (normal): mean %.2f, median %.2f" % (statistics.mean(per_year_stone), statistics.median(per_year_stone)))
    for level, xs in per_year_stone_by_level.items(): print("   visitors %-6s: %.2f per year" % (level, statistics.mean(xs)))
    print("metal-age envoys per year, two peoples met: %.2f" % statistics.mean(later))
    print("pure goodwill gifts: %d of %d envoys (%.0f%%); routine-word Chronicle lines: %d" % (all_gifts, all_arrivals, 100 * all_gifts / max(1, all_arrivals), words_total))

def contact_table(worlds, years, reps=8):
    """Per seed: first sign and first contact year, with our parties scouting
    and with only theirs travelling (median of `reps` runs; '-' = none)."""
    def first(days):
        met = [c for c in days if c is not None]
        return min(met) / 365.0 if met else None
    def median_or_none(xs):
        got = sorted(x for x in xs if x is not None)
        if len(got) * 2 <= len(xs): return None
        return got[len(xs) // 2] if len(got) == len(xs) else statistics.median(got + [1e9] * (len(xs) - len(got)))
    fmt = lambda v: "-" if v is None else "%.0f" % v
    print("seed     nearest_km  sign_yr  contact_yr(scouting)  contact_yr(no player scouting)  met@30  met@60")
    all_scout, all_quiet = [], []
    for seed, dists in worlds.items():
        sg, sc, qc, m30, m60 = [], [], [], [], []
        for rep in range(reps):
            sign, contact, _ = contact_run(dists, random.Random(seed * 10 + rep), years, True)
            sg.append(first(sign)); sc.append(first(contact))
            m30.append(sum(1 for c in contact if c is not None and c <= 30 * 365))
            m60.append(sum(1 for c in contact if c is not None and c <= 60 * 365))
            _, quiet, _ = contact_run(dists, random.Random(seed * 10 + rep), years, False)
            qc.append(first(quiet))
        all_scout += sc; all_quiet += qc
        print("%-8d %10d  %7s  %20s  %30s  %6.1f  %6.1f" % (seed, dists[0], fmt(median_or_none(sg)), fmt(median_or_none(sc)), fmt(median_or_none(qc)), statistics.mean(m30), statistics.mean(m60)))
    within = lambda xs, y: 100.0 * sum(1 for x in xs if x is not None and x < y) / len(xs)
    print("runs with first contact before year 30 / 60, our parties scouting: %.0f%% / %.0f%%" % (within(all_scout, 30), within(all_scout, 60)))
    print("runs with first contact before year 30 / 60, only their parties: %.0f%% / %.0f%%" % (within(all_quiet, 30), within(all_quiet, 60)))
    met = sorted(x for x in all_scout if x is not None)
    if met: print("first contact year with our parties scouting: median %.0f, earliest %.0f (%d of %d runs within %d years)" % (statistics.median(met), met[0], len(met), len(all_scout), years))

if __name__ == "__main__":
    if "--contact-table" in sys.argv:
        years = int(sys.argv[sys.argv.index("--years") + 1]) if "--years" in sys.argv else 120
        contact_table(REGIONAL_WORLDS if "--before" in sys.argv else WORLDS, years)
    else:
        main()
