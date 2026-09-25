"""Quick pacing model for first contact and envoys (codex/envoy-pace).

Mirrors the rules in scripts/civilization_system.gd (scout_known_reach_km,
_foreign_scout_operational_range), scripts/neighbor_signs.gd (range_km,
ENCOUNTER_KM) and scripts/audience_hall.gd (ERA_GLOBAL_GAP, ERA_CIV_GAP,
civ_gap, _business_mix, sequels, one envoy waiting at a time). Neighbour
distances come from tests/fun_audit/contact_distance_probe.gd on 12 seeds.
Run: python tests/fun_audit/envoy_pace_model.py
"""
import math, random, statistics

# (nearest, second, third, fourth) km from the placement probe
WORLDS = {424242:[506,550,11413,24060],77013:[490,500,2682,2778],112358:[297,322,22419,22547],
    91420:[312,447,1470,1754],5:[288,546,5136,5137],8080:[316,546,2881,2915],31337:[214,333,430,451],
    2024:[511,540,9729,9764],6:[301,565,5548,5676],99:[361,424,5203,5221],1234:[288,546,3308,3736],555:[717,745,13086,13107]}
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
    reach = 0.00174 * t  # world_reach per year at stone-age rival stats
    return 110.0 + reach * 18000.0 * 0.70

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

def contact_run(dists, rng):
    """Returns per-neighbour (sign_day, contact_day) over YEARS for the given homes."""
    homes = [(d, rng.uniform(-math.pi, math.pi)) for d in dists]
    sign = [None] * len(homes); contact = [None] * len(homes); how = [None] * len(homes)
    day = 30
    foreign_next = [rng.randint(0, 60) for _ in homes]
    foreign_seq = [rng.randint(0, 50) for _ in homes]
    while day < YEARS * 365:
        t = day / 365.0
        # player parties: about one departure a month across two parties
        reach = known_reach(t)
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

if __name__ == "__main__":
    main()
