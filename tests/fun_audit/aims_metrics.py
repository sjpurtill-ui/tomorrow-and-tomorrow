"""Generational-aims metrics from a fun_playtest JSONL log (audit item #4).

  python aims_metrics.py log.jsonl [-v]

Reports, from the founding to the end of the log:
  share active     - share of game days with a live aim (the people are
                     striving for something)
  decisions/hour   - aim decisions the player took in court (taking up an aim,
                     bidding the people wait, answering a lagging aim), per
                     game-hour = 3600 game days at the default 1 day/s
  proposals        - aim proposals filed as court matters, and the longest gap
                     between them (the audit asks for one at least every 10 years)
  aims             - every aim: proposed, taken up (by the god or the people),
                     resolved (fulfilled / failed / released) and how long it ran
  rivals           - rival vows made, learned from envoys, and resolved
With -v, prints the player's transcript: court scenes, choices and every
Chronicle entry about an aim.
"""
import json, sys

AIM_TITLES = ("An Aim for a Generation", "Remembered:", "An Aim Unmet", "An Aim Set Down", "The Court Speaks of an Aim",
              "A Call to Set Our Aim Aside", "Our Aim Falters")


def load(path):
    rows = []
    for line in open(path, encoding="utf-8"):
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
    return rows


def main(path, verbose=False):
    rows = load(path)
    founded = next((r["day"] for r in rows if r["t"] == "settled"), 0)
    end = max((r.get("day", 0) for r in rows), default=0)
    aims = [r for r in rows if r["t"] == "aim"]
    decisions = [r for r in rows if r["t"] == "aim_decision"]
    live, start, active_days = False, 0, 0
    runs = []
    current = None
    for r in aims:
        k, d = r.get("aim_kind"), r["day"]
        if k == "adopted":
            if live:
                active_days += d - start
            live, start = True, d
            current = {"title": r.get("text", ""), "template": r.get("template", ""), "by": r.get("by", ""), "years": r.get("years", 0), "start": d}
            runs.append(current)
        elif k in ("fulfilled", "failed", "released") and live and current is not None:
            active_days += d - start
            live = False
            current["end"], current["outcome"] = d, k
            if k == "fulfilled":
                current["legacy"] = r.get("legacy", "")
    if live:
        active_days += end - start
    span = max(1, end - founded)
    proposals = [r["day"] for r in aims if r.get("aim_kind") == "proposed"]
    gaps = [b - a for a, b in zip([founded] + proposals, proposals + [end])]
    print("log:", path)
    print("founded day %d, end day %d (%.1f game years)" % (founded, end, span / 365.0))
    print("share of game time with a live aim: %.0f%%" % (100.0 * active_days / span))
    stats = next((r.get("aim", {}).get("stats") for r in reversed(rows) if r["t"] == "year" and r.get("aim")), None)
    if stats:
        print("  (engine count: %d of %d tracked days active = %.0f%%)" % (stats.get("active_days", 0), stats.get("tracked", 0), 100.0 * stats.get("active_days", 0) / max(1, stats.get("tracked", 1))))
    hours = span / 3600.0
    print("aim decisions by the player: %d = %.1f per game-hour (3600 game days)" % (len(decisions), len(decisions) / hours))
    print("aim proposals filed as court matters: %d; longest gap between proposals %.1f years" % (len(proposals), max(gaps) / 365.0 if gaps else 0))
    taken = {}
    for run in runs:
        taken[run["by"]] = taken.get(run["by"], 0) + 1
    print("aims taken up: %d (%s)" % (len(runs), ", ".join("%s %d" % kv for kv in sorted(taken.items()))))
    outcomes = {}
    for run in runs:
        outcomes[run.get("outcome", "live")] = outcomes.get(run.get("outcome", "live"), 0) + 1
    print("outcomes:", ", ".join("%s %d" % kv for kv in sorted(outcomes.items())))
    for run in runs:
        dur = (run.get("end", end) - run["start"]) / 365.0
        print("  y%4.1f  %-9s %-8s %-48s %s after %.1f y%s" % ((run["start"] - founded) / 365.0, run["template"], run["by"], run["title"][:48],
                                                        run.get("outcome", "LIVE"), dur, (" -> " + run["legacy"]) if run.get("legacy") else ""))
    rival = [r for r in aims if str(r.get("aim_kind", "")).startswith("rival")]
    kinds = {}
    for r in rival:
        kinds[r["aim_kind"]] = kinds.get(r["aim_kind"], 0) + 1
    print("rival vows:", ", ".join("%s %d" % kv for kv in sorted(kinds.items())) or "none", "| clashes noted:", sum(1 for r in aims if r.get("aim_kind") == "clash" or r.get("clash") is True))
    if verbose:
        print("\nTRANSCRIPT")
        events = []
        for r in decisions:
            events.append((r["day"], "COURT", r))
        for r in rows:
            title = str(r.get("title", ""))
            if r["t"] == "feed" and (r.get("kind") == "milestone" or title.startswith(AIM_TITLES[:7]) or "Sworn" in title or "Boast" in title or "Have Their Way" in title):
                events.append((r.get("entry_day", r["day"]), "CHRONICLE", r))
        for day, kind, r in sorted(events, key=lambda e: e[0]):
            y = (day - founded) / 365.0
            if kind == "COURT":
                print("\n[year %.1f] COURT: %s is summoned." % (y, r.get("holder", "")))
                for line in r.get("lines", []):
                    print("    " + line)
                print("    OPTIONS: " + " | ".join(r.get("options", [])))
                print("    GOD CHOSE: %s -> %s" % (r.get("pick", ""), r.get("outcome", "")))
            else:
                print("[year %.1f] CHRONICLE (%s) %s: %s" % (y, r.get("tier", ""), r.get("title", ""), r.get("text", "")))


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "-v"]
    main(args[0], "-v" in sys.argv)
