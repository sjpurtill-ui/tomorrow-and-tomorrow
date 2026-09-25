#!/usr/bin/env python3
"""Scan player-facing research text for real-world names and terms.

Sources: a headless catalog dump (tools/research/dump_catalog_text.gd) for
discovery names, observations, consequences, ability reasons and production
contracts, plus recipe names and outputs in scripts/civilian_industry.gd and
the resource catalog names.

Checks, all on whole words:
  - tools/research/denylist_modern.py (which extends the 2400, 1800, 1200 and
    0-600 real-name denylists): places, peoples, persons, eponyms, brands;
  - EXTRA_TERMS below: real-world money denominations, named weekdays and
    holy days, and non-metric temperature scales, which the alternative
    history does not use.

  <godot> --headless --path . -s res://tools/research/dump_catalog_text.gd -- dump.json
  python tools/research/scan_player_text.py dump.json
Exit status 1 when any hit is found.
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import denylist_modern as D  # noqa: E402
import recipe_data as R  # noqa: E402

FIELDS = ["name", "observation", "social_consequence", "ability_reason", "production_contract", "operating_contract"]
# Real-world money, calendar and temperature-scale words. The weight "pound"
# and the verb "to pound" are told apart from money by context below.
EXTRA_TERMS = [
    r"farthings?", r"pence", r"penn(y|ies)", r"twopence", r"shillings?", r"cents?", r"dollars?", r"guineas?",
    r"sabbath", r"sundays?", r"saturdays?", r"mondays?", r"tuesdays?", r"wednesdays?", r"thursdays?", r"fridays?",
    r"fahrenheit", r"°\s*f",
    r"(a|one|per|each|by the|ten|two|three|four|five) pounds?(?! locks?)",
]
EXTRA = re.compile(r"(?<![a-z])(" + "|".join(EXTRA_TERMS) + r")(?![a-z])", re.I)


# Ordinary English words that a denylisted stem also matches: a smith at the
# forge, a river ford, the tang of a blade, swift justice, calving season, a
# prize boxer, the reformation of a council.
GENERIC_WORDS = {"smith", "smiths", "ford", "fords", "tang", "swift", "calving", "boxer", "boxers", "reformation"}
PHRASES = [re.compile(r"(?<![a-z])(%s)(?![a-z])" % p) for p in D.PHRASES]


def hits(text):
    """denylist_modern.hits with phrases matched on word boundaries (so "eastern"
    is not "easter") and ordinary English homographs allowed."""
    found = []
    for w in D.words(text):
        if w in D.ALLOWED_TERMS or w in GENERIC_WORDS:
            continue
        for stem in D.DENYLIST:
            if stem.endswith("*"):
                base = stem[:-1]
                if (w == base) if base in D.EXACT_ONLY else w.startswith(base):
                    found.append(w)
            elif w == stem:
                found.append(w)
    low = text.lower().replace("_", " ")
    for phrase in PHRASES:
        found += [m.group(0) for m in phrase.finditer(low)]
    found += [m.group(0).lower() for m in EXTRA.finditer(text)]
    return sorted(set(found))


def main():
    rows = json.load(open(sys.argv[1], encoding="utf-8"))["rows"] if len(sys.argv) > 1 else []
    report = []
    for row in rows:
        for field in ["id"] + FIELDS:
            text = row.get(field)
            if isinstance(text, str) and text:
                h = hits(text)
                if h:
                    report.append((row["id"], field, h, text))
    for rid, spec in R.products().items():
        for field, text in (("recipe id", rid), ("recipe name", spec.get("name", "")), ("recipe output", spec.get("output", ""))):
            h = hits(text)
            if h:
                report.append((rid, field, h, text))
    for rid, field, h, text in report:
        print("%-44s %-20s %s | %s" % (rid, field, ",".join(h), text[:160]))
    print("%d hits" % len(report))
    return 1 if report else 0


if __name__ == "__main__":
    sys.exit(main())
