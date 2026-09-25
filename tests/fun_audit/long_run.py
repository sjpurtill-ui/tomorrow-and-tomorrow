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
    print("\nmost repeated line templates (whole run):")
    for text, n in templates.most_common(top):
        print("  %4d  %s" % (n, text[:150]))
    print("\nmost repeated Chronicle titles:")
    for text, n in title_templates.most_common(top):
        print("  %4d  %s" % (n, text[:120]))

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    top = next((int(a.split("=")[1]) for a in sys.argv[1:] if a.startswith("--templates=")), 15)
    main(args[0], float(args[1]) if len(args) > 1 else 1.0, top)
