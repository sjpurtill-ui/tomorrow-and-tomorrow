"""Hours 2-5 and beyond, from a fun_playtest JSONL log.

At the default 1 day/s one game year is about 6 real minutes, so each game
decade is about one real hour ("hour N" = decade N). Per decade this reports:
  moments / notices / whispers  - Chronicle feed entries by tier
  decisions  - audiences the player answered plus aim decisions
  matters    - court matters newly filed
  deaths     - named people mourned (feed kinds death/mourning with a name)
  gap        - longest stretch (real minutes at 1 day/s) with no moment and no decision
  fresh      - share of the decade's feed/audience lines never told before in the run
  pop, known practices, works built, peoples met, wars (from year rows)
Then the most repeated line templates (digits folded) across the whole run.

  python long_run.py log.jsonl [days_per_real_second=1] [--templates=15]
"""
import json, re, sys
from collections import Counter, defaultdict

def norm(text):
    text = re.sub(r"\d[\d,.]*", "#", text)
    return re.sub(r"\s+", " ", text).strip()

def load(path):
    rows = []
    for line in open(path, encoding="utf-8"):
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
    return rows

def main(path, speed=1.0, top=15):
    rows = load(path)
    founded = next((r["day"] for r in rows if r["t"] == "settled"), 0)
    dec = lambda d: max(0, (d - founded)) // 3650
    per = defaultdict(Counter)
    marks = defaultdict(list)  # decade -> days with a moment or decision
    seen_lines = set()
    fresh = defaultdict(lambda: [0, 0])
    templates = Counter()
    title_templates = Counter()
    years = {}
    audience_kinds = defaultdict(Counter)
    seen_aud = set()
    for r in rows:
        d = r.get("day", 0)
        t = r["t"]
        k = dec(d)
        lines = []
        if t == "feed":
            tier = r.get("tier", "")
            per[k][tier] += 1
            per[k]["kind:" + r.get("kind", "")] += 1
            if tier == "moment":
                marks[k].append(d)
            if r.get("kind") in ("death", "mourning", "succession"):
                per[k]["deaths"] += 1
            lines.append(r.get("text", ""))
            title_templates[norm(r.get("title", ""))] += 1
        elif t == "audience":
            key = (d, r.get("speaker", ""), r.get("kind", ""))
            if key in seen_aud:
                continue
            seen_aud.add(key)
            per[k]["decisions"] += 1
            audience_kinds[k][r.get("kind", "") or r.get("situation", "")] += 1
            marks[k].append(d)
            lines += [l.split(": ", 1)[-1] for l in r.get("lines", [])]
        elif t == "crisis_decision":
            per[k]["decisions"] += 1
            per[k]["crisis_decisions"] += 1
            marks[k].append(d)
            lines += [l.split(": ", 1)[-1] for l in r.get("lines", [])]
        elif t == "aim_decision":
            per[k]["decisions"] += 1
            per[k]["aim_decisions"] += 1
            marks[k].append(d)
            lines += [l.split(": ", 1)[-1] for l in r.get("lines", [])]
        elif t == "matter":
            per[k]["matters"] += 1
        elif t == "discovery":
            per[k]["discoveries"] += 1
        elif t == "year":
            years[r["year"]] = r
        for text in lines:
            n = norm(text)
            if not n:
                continue
            templates[n] += 1
            fresh[k][1] += 1
            if n not in seen_lines:
                fresh[k][0] += 1
                seen_lines.add(n)
    last = max(per) if per else 0
    last_day = max((r.get("day", 0) for r in rows), default=0)
    print("decade (~real hour at %.1f day/s) | moments notices whispers | decisions (aim) matters | named deaths | disc | longest gap min | fresh lines | pop known works met wars" % speed)
    for k in range(last + 1):
        c = per[k]
        start, end = founded + k * 3650, min(founded + (k + 1) * 3650, last_day)
        pts = sorted([start] + marks[k] + [end])
        gap = max(b - a for a, b in zip(pts, pts[1:])) / 60.0 / speed
        y = years.get((k + 1) * 10) or years.get(max([yy for yy in years if yy <= (k + 1) * 10] or [0]), {})
        f = fresh[k]
        span = max(1, end - start) / 365.0
        print("%2d%s | %3d %3d %4d | %3d (%2d) %3d | %2d | %3d | %5.1f | %3.0f%% of %d | %s %s %s %s %s" % (
            k + 1, "" if span >= 9.99 else "*", c["moment"], c["notice"], c["whisper"], c["decisions"], c["aim_decisions"], c["matters"],
            c["deaths"], c["discoveries"], gap, 100.0 * f[0] / max(1, f[1]), f[1],
            y.get("pop", "?"), y.get("known", "?"), y.get("built", "?"), len(y.get("met", [])) if "met" in y else y.get("contacts", "?"), y.get("wars", "?")))
    rates = []
    for k in range(last + 1):
        span = max(1, min(founded + (k + 1) * 3650, last_day) - founded - k * 3650) / 365.0
        rates.append("%d: %.1f / %.1f / %.1f" % (k + 1, per[k]["moment"] / span, per[k]["decisions"] / span, (per[k]["moment"] + per[k]["notice"]) / span))
    print("(* partial decade)\nper game year, moments / decisions / moments+notices:  " + "   ".join(rates))
    print("\naudience kinds per decade:")
    for k in range(last + 1):
        print("  %2d %s" % (k + 1, dict(audience_kinds[k].most_common())))
    print("\nfeed kinds per decade:")
    for k in range(last + 1):
        print("  %2d %s" % (k + 1, {x[5:]: v for x, v in per[k].most_common() if x.startswith("kind:")}))
    summary(rows, founded, last_day, speed)
    print("\nmost repeated line templates (whole run):")
    for text, n in templates.most_common(top):
        print("  %4d  %s" % (n, text[:150]))
    print("\nmost repeated Chronicle titles:")
    for text, n in title_templates.most_common(top):
        print("  %4d  %s" % (n, text[:120]))

# Catalog bands per game century (tools/sim/shocks/catalog.py HISTORICAL_BASE_RATES,
# "ancient" group; benchmarks_1200.json shock_widening.hazard_per_game_century).
CATALOG = {"famine>=2%": (0.5, 1.5), "pestilence>=5%": (0.2, 0.7), "climate shock": (1.0, 2.5)}

def summary(rows, founded, last_day, speed=1.0):
    """The fun-fix measures: after year 10 and in real hours 2+."""
    y10 = founded + 3650
    moments, decisions, envoy, marks = [], [], [], []
    seen_aud = set()
    for r in rows:
        d, t = r.get("day", 0), r["t"]
        if t == "feed" and r.get("tier") == "moment":
            moments.append(d); marks.append(d)
        elif t == "audience":
            key = (d, r.get("speaker", ""), r.get("kind", ""))
            if key in seen_aud:
                continue
            seen_aud.add(key)
            marks.append(d)
            (envoy if r.get("origin") == "foreign" else decisions).append(d)
        elif t in ("aim_decision", "crisis_decision"):
            decisions.append(d); marks.append(d)
    span_after = max(0.0, (last_day - y10) / 365.0)
    after = lambda xs: sum(1 for x in xs if x >= y10)
    print("\nSUMMARY (game years after year 10: %.1f)" % span_after)
    if span_after > 0:
        print("  moments per game year after year 10:               %.2f" % (after(moments) / span_after))
        print("  decisions per game year after year 10 (no envoys): %.2f   (envoy audiences %.2f)" % (after(decisions) / span_after, after(envoy) / span_after))
    span_all = max(0.01, (last_day - founded) / 365.0)
    print("  moments per game year, whole run:                 %.2f" % (len(moments) / span_all))
    print("  decisions per game year, whole run (no envoys):    %.2f" % (len(decisions) / span_all))
    if last_day > y10:
        pts = sorted([y10] + [m for m in marks if m >= y10] + [last_day])
        g, at = max((b - a, a) for a, b in zip(pts, pts[1:]))
        print("  longest quiet stretch in hours 2+ (no moment, no audience): %.1f real min (%d game days from year %.1f)" % (g / 60.0 / speed, g, (at - founded) / 365.0))
        own = sorted([y10] + [m for m in moments + decisions if m >= y10] + [last_day])
        g2, at2 = max((b - a, a) for a, b in zip(own, own[1:]))
        print("  longest stretch in hours 2+ with no moment and no decision of our own (envoys aside): %.1f real min (%d game days from year %.1f)" % (g2 / 60.0 / speed, g2, (at2 - founded) / 365.0))
    crises = [r for r in rows if r["t"] == "crisis" and r.get("crisis_kind") == "onset"]
    ends = [r for r in rows if r["t"] == "crisis" and r.get("crisis_kind") == "end"]
    turning = [r for r in rows if r["t"] == "feed" and str(r.get("key", "")).startswith("turning:")]
    cent = span_all / 100.0
    by = defaultdict(int)
    for r in crises:
        by[r.get("type", "?")] += 1
    if crises:
        print("  crises: %d onsets = %.2f per game year; per game century by type: %s" % (len(crises), len(crises) / span_all,
              ", ".join("%s %.0f" % (k, v / cent) for k, v in sorted(by.items()))))
        famine = sum(1 for r in crises if r.get("type") == "hunger" and r.get("severe"))
        pest = sum(1 for r in crises if r.get("type") in ("sickness", "stranger") and r.get("severe"))
        climate = sum(1 for r in crises if r.get("type") in ("drought", "cold", "flood") and r.get("severe"))
        for label, n in (("famine>=2%", famine), ("pestilence>=5%", pest), ("climate shock", climate)):
            lo, hi = CATALOG[label]
            print("    %-15s %d in %.1f years = %.2f per century (catalog ancient band %.1f-%.1f)" % (label, n, span_all, n / cent, lo, hi))
        deaths = sum(int(r.get("deaths", 0)) for r in ends)
        print("  crisis deaths: %d; answered by the god / holders acted alone: %d / %d" % (deaths,
              sum(1 for r in rows if r["t"] == "crisis" and r.get("crisis_kind") == "decided"),
              sum(1 for r in rows if r["t"] == "crisis" and r.get("crisis_kind") == "silent")))
    print("  turning points: %d (%s)" % (len(turning), ", ".join("y%d %s" % ((r["day"] - founded) // 365, r.get("title", "")) for r in turning)))

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    top = next((int(a.split("=")[1]) for a in sys.argv[1:] if a.startswith("--templates=")), 15)
    main(args[0], float(args[1]) if len(args) > 1 else 1.0, top)
