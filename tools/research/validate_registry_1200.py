#!/usr/bin/env python3
"""Validate docs/research/y600/registry_1200.json against the 0-600 registry.

Checks: unique ids; schema (top-level keys, count keys, discovery and alias
fields and types) matches docs/research/registry.json; all 12 lines present;
target years in 600-1200; no id collides with a 0-600 id unless listed as a
redate; predecessors resolve; no denylisted real-world name in ids or names.
Prints counts per line, merges, redates, exclusions and ambiguous items.
Exit status 1 on any error.

  python tools/research/validate_registry_1200.py
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REG_600 = os.path.join(ROOT, "docs", "research", "registry.json")
REG_1200 = os.path.join(ROOT, "docs", "research", "y600", "registry_1200.json")
FIRST, LAST = 600, 1200

# Real peoples, polities, places, persons, religions and events (lower-case
# word stems). A word matches when it equals a stem or starts with a stem
# marked with a trailing '*'.
DENYLIST = """
rome roman romans greece greek* hellen* athen* sparta* spartan* corinth* macedon* thebes theban* delph* olymp*
rhod* attic ionia* ionian doric dorian aegean crete cretan minoa* mycen* troy trojan* hittite* assyria* babylon*
sumer* akkad* egypt* pharaoh* nile persia* achaemen* parthia* sasan* scythia* scythian* phoenic* carthag* punic etrusc*
latin* celt* gaul gauls gallic goth* vandal* hun huns hunnic frank* saxon* norse viking* china chinese han qin
zhou shang india indian* maurya* gupta vedic hindu* buddh* jain* confuc* taoist daoist laozi mohist legalist
jew jews jewish juda* israel* hebrew* christ* church* islam* muslim* arab arabs arabian byzant* constantinop*
alexandr* alexander ptolem* seleuc* hadrian* augustus caesar* diocletian* aurelian* theodos* justinian* trajan*
nero pompe* vesuv* herculan* archimed* euclid* aristot* plato* platonic socrat* pythagor* hippocrat* galen*
vitruv* pliny homer* hesiod* herodot* thucydid* solon draco* draconian lycurg* pericle* cleisthen* hammurabi
moses jesus zoroast* mithra* isis osiris zeus apollo* athena jupiter mars venus pharos colosseum mausole*
pantheon parthenon acropolis forum agora nubia* kush* aksum* axum* nabat* petra silk appian qanat* sahara*
mesopotam* anatolia* levant* canaan* iberia* hispan* britann* german* danub* rhine tigris euphrat* indus ganges
yellow_river yangtze olympic olympiad marathon thermopyl* salamis plataea cannae actium
""".split()
# Stems that are ordinary English words in this corpus; checked exactly only.
EXACT_ONLY = {"attic", "forum", "silk", "petra", "mars", "venus", "yellow_river"}


def denylist_hits(text):
    hits = []
    words = re.findall(r"[a-z]+", text.lower().replace("_", " "))
    for w in words:
        for stem in DENYLIST:
            if stem.endswith("*"):
                if w.startswith(stem[:-1]):
                    hits.append(w)
            elif w == stem:
                hits.append(w)
    return sorted(set(hits))


def main():
    r6 = json.load(open(REG_600, encoding="utf-8"))
    r12 = json.load(open(REG_1200, encoding="utf-8"))
    errors, warnings = [], []

    # Schema.
    missing_top = [k for k in r6 if k not in r12]
    if missing_top:
        errors.append("top-level keys missing: %s" % missing_top)
    extra_top = [k for k in r12 if k not in r6]
    if r12.get("lines") != r6["lines"]:
        errors.append("lines differ from 0-600: %s" % r12.get("lines"))
    count_keys = set(next(iter(r6["counts"].values())).keys())
    for line in r6["lines"]:
        if line not in r12["counts"]:
            errors.append("counts missing line %s" % line)
        elif set(r12["counts"][line].keys()) != count_keys:
            errors.append("count keys differ for %s" % line)
    d6 = r6["discoveries"][0]
    field_types = {k: type(v) for k, v in d6.items()}
    alias_example = next(a for d in r6["discoveries"] for a in d["aliases"])
    alias_types = {k: type(v) for k, v in alias_example.items()}
    for d in r12["discoveries"]:
        if list(d.keys()) != list(field_types.keys()):
            errors.append("%s: fields %s" % (d.get("id"), list(d.keys())))
            continue
        for k, t in field_types.items():
            if not isinstance(d[k], t):
                errors.append("%s: %s is %s, want %s" % (d["id"], k, type(d[k]).__name__, t.__name__))
        if d["status"] not in ("catalog", "era", "new"):
            errors.append("%s: status %s" % (d["id"], d["status"]))
        if d["line"] not in r6["lines"]:
            errors.append("%s: unknown line %s" % (d["id"], d["line"]))
        for s in d["shared_with"]:
            if s not in r6["lines"] or s == d["line"]:
                errors.append("%s: bad shared_with %s" % (d["id"], s))
        for a in d["aliases"]:
            if set(a.keys()) != set(alias_types.keys()):
                errors.append("%s: alias fields %s" % (d["id"], sorted(a.keys())))
            for k, t in alias_types.items():
                if k in a and not isinstance(a[k], t):
                    errors.append("%s: alias %s is %s" % (d["id"], k, type(a[k]).__name__))
        if not re.fullmatch(r"[a-z][a-z0-9_]*", d["id"]):
            errors.append("%s: id is not snake_case" % d["id"])
        if not (FIRST <= d["target_year"] <= LAST):
            errors.append("%s: target_year %d outside %d-%d" % (d["id"], d["target_year"], FIRST, LAST))
        if not (d["band_low"] <= d["target_year"] <= d["band_high"]):
            errors.append("%s: year %d outside its band %d-%d" % (d["id"], d["target_year"], d["band_low"], d["band_high"]))
        if d["band_high"] > LAST:
            warnings.append("%s: band reaches %d (target %d)" % (d["id"], d["band_high"], d["target_year"]))
    # Unique ids.
    seen = {}
    for d in r12["discoveries"]:
        if d["id"] in seen:
            errors.append("duplicate id %s (%s, %s)" % (d["id"], seen[d["id"]], d["line"]))
        seen[d["id"]] = d["line"]
    # Lines present.
    present = {d["line"] for d in r12["discoveries"]}
    for line in r6["lines"]:
        if line not in present:
            errors.append("line %s has no discoveries" % line)
    # Totals.
    if r12["total_canonical"] != len(r12["discoveries"]):
        errors.append("total_canonical mismatch")
    listed = sum(c["listed_rows"] for c in r12["counts"].values())
    aliases = sum(len(d["aliases"]) for d in r12["discoveries"])
    excluded = len(r12.get("excluded_rows", []))
    if listed != r12["total_listed_rows"]:
        errors.append("listed_rows sum %d != total_listed_rows %d" % (listed, r12["total_listed_rows"]))
    if listed != len(r12["discoveries"]) + aliases + excluded:
        errors.append("rows %d != canonical %d + aliases %d + excluded %d"
                      % (listed, len(r12["discoveries"]), aliases, excluded))
    # 0-600 collisions.
    ids6 = {d["id"]: d for d in r6["discoveries"]}
    redated = {r["id"] for r in r12.get("redates", [])}
    for d in r12["discoveries"]:
        if d["id"] in ids6 and d["id"] not in redated:
            errors.append("%s collides with 0-600 registry (%s %d) and is not a recorded redate"
                          % (d["id"], ids6[d["id"]]["line"], ids6[d["id"]]["target_year"]))
    for r in r12.get("redates", []):
        if r["id"] not in ids6 or r["id"] not in seen:
            errors.append("redate %s does not match both registries" % r["id"])
    # Predecessors resolve to 0-600 or this block.
    for i, preds in r12.get("predecessors", {}).items():
        if i not in seen:
            errors.append("predecessors key %s not in block" % i)
        for p in preds:
            if p not in ids6 and p not in seen:
                errors.append("%s continues unknown id %s" % (i, p))
    # Belongs-later ids must not be in the block.
    for b in r12.get("belongs_later", []) + r12.get("belongs_before_600", []):
        if b["id"] in seen:
            errors.append("belongs-elsewhere id %s is in the block" % b["id"])
    # Denylist.
    for d in r12["discoveries"]:
        texts = [d["id"], d["name"]] + [a["name"] for a in d["aliases"]]
        for t in texts:
            hits = [h for h in denylist_hits(t) if h not in EXACT_ONLY or h in re.findall(r"[a-z]+", t.lower())]
            if hits:
                errors.append("%s: real-name term(s) %s in %r" % (d["id"], hits, t))

    # Report.
    print("registry_1200: %d canonical from %d listed rows" % (len(r12["discoveries"]), listed))
    print("%-15s %6s %9s %7s %4s %4s %7s" % ("line", "listed", "canonical", "catalog", "era", "new", "merged>"))
    for line in r6["lines"]:
        c = r12["counts"][line]
        print("%-15s %6d %9d %7d %4d %4d %7d" % (line, c["listed_rows"], c["canonical"], c["catalog"], c["era"],
                                                 c["new"], c["rows_merged_elsewhere"]))
    print("merges: %d alias rows into %d entries" % (aliases, sum(1 for d in r12["discoveries"] if d["aliases"])))
    print("redates: %d" % len(r12.get("redates", [])))
    for r in r12.get("redates", []):
        print("  %s: %s %d -> %s %d" % (r["id"], r["old_line"], r["old_year"], r["new_line"], r["new_year"]))
    print("renamed collisions: %s" % ", ".join("%s->%s" % (r["row_id"], r["new_id"]) for r in r12.get("renamed_collisions", [])))
    print("excluded rows: %s" % ", ".join("%s (%s)" % (e["id"], e["line"]) for e in r12.get("excluded_rows", [])))
    print("belongs later: %d; before 600: %d; ambiguous: %d" % (len(r12.get("belongs_later", [])),
          len(r12.get("belongs_before_600", [])), len(r12.get("ambiguous", []))))
    print("extra top-level keys (ignored by 0-600 consumers): %s" % ", ".join(extra_top))
    if warnings:
        print("note: %d bands reach past %d (targets are all in range): %s" % (len(warnings), LAST,
              ", ".join(w.split(":")[0] for w in warnings)))
    for e in errors:
        print("ERROR: " + e)
    print("OK" if not errors else "%d error(s)" % len(errors))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
