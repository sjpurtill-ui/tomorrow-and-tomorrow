"""First-hour pacing from a fun_playtest JSONL log.

Real minutes are computed from game days at the default speed of 1 day/s
(60 game days per real minute), starting at the founding. Counts, per 10 real
minutes of the first hour:
  moments    - opening beats, discoveries, first contacts and other
               non-routine events (routine = single births/deaths, "nothing
               found" scout returns, pregnancy losses, drills, officeholder HR
               lines, sightings of foreign scouts).
  decisions  - envoy audiences (unbidden) plus newly filed court matters
               (business waiting for the ruler to summon, each with choices).
Also reports the longest stretch with no moment and no decision, and the
longest stretch with no moment and no matter waiting (matters wait 150 days).

  python first_hour.py log.jsonl [days_per_real_second=1]
"""
import json, re, sys

ROUTINE = [r"^\d+ (birth|death)s? at ", r"^Pregnancy Losses", r" complete$", r"^Officeholder Died",
           r"^Scouts report foreign", r"^Foreign unit sighted", r"^Settlement Site Chosen", r"^Settlement Named"]
MATTER_DAYS = 150

def routine(title, desc):
    if any(re.search(p, title) for p in ROUTINE):
        return True
    if title == "SCOUTS RETURN":
        return not re.search(r"Direct contact|Smoke|smoke|tracks|cold hearth|wanderers|joined", desc)
    return False

def main(path, speed=1.0):
    rows = []
    for l in open(path, encoding="utf-8"):
        try:
            rows.append(json.loads(l))
        except ValueError:
            pass  # a line still being written
    founded = next((r["day"] for r in rows if r["t"] == "settled"), 0)
    per_min = 60.0 * speed
    end = founded + 60 * per_min
    moments, decisions, matters = [], [], []
    beat_keys = set()
    seen_audiences = set()
    for r in rows:
        d = r.get("day", 0)
        if d < founded or d > end:
            continue
        t = r["t"]
        if t == "beat":
            moments.append((d, "beat: " + r["title"]))
            beat_keys.add((d, r["title"]))
        elif t == "discovery":
            moments.append((d, "discovery: " + r.get("name", "")))
        elif t == "event":
            if (d, r["title"]) in beat_keys or routine(r["title"], r.get("desc", "")):
                continue
            moments.append((d, r["title"]))
        elif t == "audience":
            key = (d, r.get("situation", ""), r.get("speaker", ""))
            if key in seen_audiences:
                continue  # older harness logs repeat an audience while its modal closes
            seen_audiences.add(key)
            decisions.append((d, "envoy: %s %s" % (r.get("situation", ""), r.get("speaker", ""))))
        elif t == "matter":
            decisions.append((d, "matter: %s (%s)" % (r.get("holder", ""), r.get("situation", ""))))
            matters.append(d)
    minutes = 60
    buckets = []
    for b in range(0, minutes, 10):
        lo, hi = founded + b * per_min, founded + (b + 10) * per_min
        buckets.append((b, sum(lo <= d < hi for d, _ in moments), sum(lo <= d < hi for d, _ in decisions)))
    marks = sorted([founded] + [d for d, _ in moments] + [d for d, _ in decisions] + [end])
    gap = max(b - a for a, b in zip(marks, marks[1:]))
    # lenient: covered while a matter waits
    covered = sorted(set(marks))
    worst, last = 0, founded
    waiting_until = -1
    events = sorted([(d, "m") for d, _ in moments] + [(d, "x") for d in matters] + [(d, "a") for d, t in decisions if t.startswith("envoy")] + [(end, "e")])
    for d, kind in events:
        start = max(last, waiting_until)
        if d > start:
            worst = max(worst, d - start)
        last = max(last, d)
        if kind == "x":
            waiting_until = max(waiting_until, d + MATTER_DAYS)
    print("log:", path)
    print("founded day %d; first hour = days %d-%d at %.1f day/s" % (founded, founded, end, speed))
    print("10-min bucket  moments  decisions")
    for b, m, x in buckets:
        flag = "" if m >= 3 and x >= 2 else "   <- below target (3 moments, 2 decisions)"
        print("  %2d-%2d min    %3d      %3d%s" % (b, b + 10, m, x, flag))
    print("totals: moments %d, decisions %d (envoys %d, matters %d)" % (len(moments), len(decisions), sum(1 for _, t in decisions if t.startswith("envoy")), len(matters)))
    print("longest stretch without a moment or decision: %d days = %.1f real min" % (gap, gap / per_min))
    print("longest stretch without a moment or a waiting matter: %d days = %.1f real min" % (worst, worst / per_min))
    first = lambda pred: next((d for d, t in moments if pred(t)), None)
    print("first signs day:", first(lambda t: "Smoke" in t or "Tracks" in t), "| first contact day:", first(lambda t: "First contact" in t or "Strangers at the fire" in t))
    if "-v" in sys.argv:
        for d, t in sorted(moments + decisions):
            print("   day %5d (min %5.1f)  %s" % (d, (d - founded) / per_min, t[:110]))

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "-v"]
    main(args[0], float(args[1]) if len(args) > 1 else 1.0)
