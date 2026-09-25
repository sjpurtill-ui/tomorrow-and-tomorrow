"""Conflict pacing from fun_playtest JSONL logs (audit round 2, item 2).

For each log, and pooled over all of them:
  years           game years played after the founding
  player wars     wars the player's people fought (world war ledger), per century
  rival wars      wars between other peoples, per century (whole world)
  real refusals   demands refused that were not bluffs (the war ledger knows;
                  for a build without it, every refusal not exposed as a bluff)
  harmed <= 2y    share of real refusals followed within 730 days by harm from
                  the same people: a raid, skirmish, war or attack
  raids / skirmishes / operations / enemy attacks
  conflict decisions per game year: threat audiences (tribute, redress, tests
                  of resolve), war_support audiences and war-leader decisions
  conflict dead   our dead and theirs; the largest band as a share of our people

  python war_metrics.py log1.jsonl [log2.jsonl ...]
"""
import json, sys

HARM = ("raid", "skirmish", "war", "enemy_attack")

def load(path):
    rows = []
    for line in open(path, encoding="utf-8"):
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
    return rows

def measure(path):
    rows = load(path)
    founded = next((r["day"] for r in rows if r["t"] == "settled"), 0)
    last = max((r.get("day", 0) for r in rows), default=0)
    years = max(0.01, (last - founded) / 365.0)
    year_rows = [r for r in rows if r["t"] == "year"]
    final = year_rows[-1] if year_rows else {}
    player_wars = final.get("player_wars_total", final.get("wars", 0))
    rival_wars = final.get("civ_wars_total", 0)
    war_rows = [r for r in rows if r["t"] == "war"]
    refusal_rows = [r for r in rows if r["t"] == "war_refusal"]
    audiences = [r for r in rows if r["t"] == "audience"]
    results = [r for r in rows if r["t"] == "audience_result"]
    # Real refusals and whether harm followed.
    harmed = 0
    real = 0
    if refusal_rows:
        harm_days = {}
        for w in war_rows:
            if w.get("war_kind") in HARM:
                harm_days.setdefault(w.get("civ", ""), []).append(w["day"])
        for r in refusal_rows:
            real += 1
            days = harm_days.get(r["civ"], [])
            if any(0 <= d - r["refused_day"] <= 730 for d in days):
                harmed += 1
    else:
        # A build without the war ledger: refusals the outcome does not expose
        # as a bluff, and any later raid/attack/war line naming that people.
        names = {}
        for a in audiences:
            names[a.get("civ", "")] = a.get("title", "")
        texts = [(r["day"], (r.get("title", "") + " " + r.get("desc", r.get("text", ""))).lower()) for r in rows if r["t"] in ("event", "feed")]
        pending = None
        for r in rows:
            if r["t"] == "audience":
                pending = r
            elif r["t"] == "audience_result" and pending is not None:
                if pending.get("kind") == "threat" and r.get("pick") in ("defy", "counter") and "it was a bluff" not in r.get("outcome", "").lower():
                    real += 1
                    civ_words = [w for w in pending.get("facts", "").split(" ")[:2] if w and w[0].isupper()]
                    name = civ_words[0].lower() if civ_words else "@@"
                    if any(0 <= d - r["day"] <= 730 and name in text and any(k in text for k in ("raid", "attack", "war ", "battle", "killed")) for d, text in texts):
                        harmed += 1
                pending = None
    stats = (final.get("war_loop") or {}).get("stats", {})
    kinds = {}
    for w in war_rows:
        kinds[w.get("war_kind", "")] = kinds.get(w.get("war_kind", ""), 0) + 1
    conflict_decisions = sum(1 for a in audiences if a.get("kind") == "threat" or a.get("situation") == "war_support")
    conflict_decisions += sum(1 for r in rows if r["t"] == "war_decision")
    our_dead = sum(int(w.get("our_dead", 0)) for w in war_rows if w.get("war_kind") != "war_end")
    their_dead = sum(int(w.get("their_dead", 0)) for w in war_rows if w.get("war_kind") != "war_end")
    pops = [r.get("pop", 0) for r in year_rows]
    band_share = 0.0
    for w in war_rows:
        if w.get("band"):
            band_share = max(band_share, float(w["band"]) / max(1, min(p for p in pops if p) if pops else 100))
    decisions = len(audiences) + sum(1 for r in rows if r["t"] in ("aim_decision", "war_decision"))
    return {"path": path.split("/")[-1].split("\\")[-1], "years": years, "player_wars": player_wars, "rival_wars": rival_wars,
            "real": real, "harmed": harmed, "raids": kinds.get("raid", 0), "skirmishes": kinds.get("skirmish", 0),
            "war_starts": kinds.get("war", 0), "ops": sum(v for k, v in kinds.items() if k.startswith("op_")), "enemy": kinds.get("enemy_attack", 0),
            "war_ends": kinds.get("war_end", 0), "conflict_decisions": conflict_decisions, "decisions": decisions,
            "our_dead": our_dead, "their_dead": their_dead, "band_share": band_share,
            "pop0": pops[0] if pops else 0, "pop_end": pops[-1] if pops else 0, "orders": stats.get("orders", 0), "orders_auto": stats.get("orders_auto", 0)}

def main(paths):
    rows = [measure(p) for p in paths]
    head = "%-22s %5s | %5s %6s | %4s %4s %5s | %5s %5s %5s %5s %5s %5s | %6s %6s | %4s %4s %5s | %s"
    print(head % ("log", "years", "p.war", "r.war", "real", "harm", "harm%", "raids", "skirm", "wars", "ops", "enemy", "ends", "c.dec/y", "dec/y", "ours", "thrs", "band", "pop"))
    for r in rows:
        print(head % (r["path"][:22], "%.1f" % r["years"], r["player_wars"], r["rival_wars"], r["real"], r["harmed"],
                      "%.0f%%" % (100.0 * r["harmed"] / r["real"]) if r["real"] else "-", r["raids"], r["skirmishes"], r["war_starts"], r["ops"], r["enemy"], r["war_ends"],
                      "%.2f" % (r["conflict_decisions"] / r["years"]), "%.2f" % (r["decisions"] / r["years"]), r["our_dead"], r["their_dead"], "%.3f" % r["band_share"], "%s->%s" % (r["pop0"], r["pop_end"])))
    years = sum(r["years"] for r in rows)
    real = sum(r["real"] for r in rows)
    harmed = sum(r["harmed"] for r in rows)
    print("\npooled over %d runs, %.1f game years:" % (len(rows), years))
    print("  player wars per century        %.2f  (%d wars)" % (100.0 * sum(r["player_wars"] for r in rows) / years, sum(r["player_wars"] for r in rows)))
    print("  rival-rival wars per century   %.2f  (world total %d)" % (100.0 * sum(r["rival_wars"] for r in rows) / years, sum(r["rival_wars"] for r in rows)))
    print("  real refusals followed by harm within 2 years: %d of %d (%s)" % (harmed, real, "%.0f%%" % (100.0 * harmed / real) if real else "-"))
    print("  raids %d, skirmishes %d, general's operations %d, enemy attacks %d" % (sum(r["raids"] for r in rows), sum(r["skirmishes"] for r in rows), sum(r["ops"] for r in rows), sum(r["enemy"] for r in rows)))
    print("  conflict decisions per game year %.2f (all decisions %.2f)" % (sum(r["conflict_decisions"] for r in rows) / years, sum(r["decisions"] for r in rows) / years))
    print("  conflict dead: ours %d, theirs %d; largest band %.1f%% of our people" % (sum(r["our_dead"] for r in rows), sum(r["their_dead"] for r in rows), 100.0 * max([r["band_share"] for r in rows] or [0])))

if __name__ == "__main__":
    main(sys.argv[1:])
