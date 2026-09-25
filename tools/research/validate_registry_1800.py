#!/usr/bin/env python3
"""Validate docs/research/y1200/registry_1800.json against everything placed before 1200.

Checks: unique ids; schema (top-level keys, count keys, discovery and alias
fields and types) matches docs/research/registry.json; all 12 lines present;
target years in 1200-1800 and inside their bands; no id collides with an id
placed before 1200 (0-600 and 600-1200 registries, their merged alias slugs
and excluded rows, and the game's baked blocks on origin/codex/research-1200)
unless listed as a redate; every predecessor resolves; belongs-later and
belongs-earlier ids are absent; no denylisted real-world name in ids or
names. It also re-runs a cross-line near-duplicate scan (shared id stems and
name-word overlap) and prints the candidate pairs for review; those are not
errors. Exit status 1 on any error.

  python tools/research/validate_registry_1800.py
"""
import importlib.util
import itertools
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
REG_600 = os.path.join(ROOT, "docs", "research", "registry.json")
REG_1200 = os.path.join(ROOT, "docs", "research", "y600", "registry_1200.json")
REG_1800 = os.path.join(ROOT, "docs", "research", "y1200", "registry_1800.json")
GAME_REF = "origin/codex/research-1200"
GAME_BLOCKS = ["data/research/research_600.json", "data/research/blocks/y600_1200.json"]
FIRST, LAST = 1200, 1800

_spec = importlib.util.spec_from_file_location(
    "validate_registry_1200", os.path.join(os.path.dirname(os.path.abspath(__file__)), "validate_registry_1200.py"))
_v1200 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_v1200)

# The 600-1200 denylist plus late-antique and medieval peoples, polities,
# places, persons, orders, texts and events.
DENYLIST = _v1200.DENYLIST + """
norman* romanesqu* gothic mongol* tatar* turk* seljuk* ottoman* abbasid* umayyad* fatimid* caliph* sultan* mamluk*
janissar* saracen* moorish carolingian* merovingian* capetian* plantagenet* tudor* hanse hanseatic venic* venetian*
genoa genoese florent* pisan lombard* magyar* bulgar* khazar* kiev* novgorod* varang* samurai shogun* daimyo* khmer*
angkor* tang yuan ming sui heian kamakura nara srivijaya* majapahit* champa chola* rajput* aztec* maya mayan* inca*
toltec* frisia* avar avars templar* hospitaller* teuton* benedictin* cistercian* francisc* dominican* crusad* papal
pope pontiff* doge khan khans khanate* sufi* zen bushido jihad hajj mecca medina jerusalem paris london cordoba
baghdad cairo damascus damascen* kyoto changan toledo iceland* scandinav* anglo english french spanish italian arabic
turkish japan* korea* vietnam* tibet* welsh irish scottish danish dane danegeld swahili zimbabwe ghana mali timbuktu
benin gutenberg fibonacci khwarizm* avicenna averro* maimonid* aquinas abelard bacon grosseteste buridan oresme
bradwardine merton* oxford cambridge bologna salerno montpellier sorbonne chartres cluny hildegard dante petrarch*
boccacc* chaucer* beowulf roland arthur* arthurian grail nibelung* edda* genji shahnameh decameron canterbury
reynard mesta fondaco* karum domesday magna carta bayeux borobudur hagia sophia justinian* charlemagne alfred
harun saladin genghis kublai marco polo zheng podesta
""".split()
# "silk" is an ordinary material in this window (sericulture, silk mills);
# only the trade-route phrase is a real name, so it moves to PHRASES.
DENYLIST = [s for s in DENYLIST if s != "silk"]
EXACT_ONLY = _v1200.EXACT_ONLY | {"maya", "zen", "tang", "nara", "sui", "ming", "yuan", "dane", "mali"}
PHRASES = [r"silk (road|route)", r"black death", r"hundred years'? war", r"holy land", r"new world",
           r"china (clay|stone)", r"greek fire", r"arabic (numeral|digit)", r"hindu[- ]arabic"]


def denylist_hits(text):
    hits = []
    for w in re.findall(r"[a-z]+", text.lower().replace("_", " ")):
        for stem in DENYLIST:
            if stem.endswith("*"):
                if stem[:-1] not in EXACT_ONLY and w.startswith(stem[:-1]):
                    hits.append(w)
            elif w == stem:
                hits.append(w)
    for phrase in PHRASES:
        hits += re.findall(phrase, text.lower().replace("_", " "))
    return sorted(set(str(h) for h in hits))


def git_json(ref, path):
    return json.loads(subprocess.check_output(["git", "-C", ROOT, "show", ref + ":" + path]))


STOP = set("a an the of and or in on by to for with from as at its their each one two is are be into who that "
           "god god's his her all every".split())


def _stem(w):
    for suf in ("ing", "es", "s", "ed"):
        if len(w) > 4 and w.endswith(suf):
            return w[:-len(suf)]
    return w


def _words(d):
    return {_stem(w) for w in re.findall(r"[a-z]+", (d["name"] + " " + d["id"].replace("_", " ")).lower())
            if w not in STOP}


def near_duplicates(discoveries, threshold=0.34):
    out = []
    for a, b in itertools.combinations(discoveries, 2):
        if a["line"] == b["line"]:
            continue
        wa, wb = _words(a), _words(b)
        ia = {_stem(w) for w in a["id"].split("_") if w not in STOP}
        ib = {_stem(w) for w in b["id"].split("_") if w not in STOP}
        score = max(len(wa & wb) / float(len(wa | wb)), len(ia & ib) / float(len(ia | ib)))
        if score >= threshold:
            out.append((round(score, 2), a["id"], a["line"], a["target_year"], b["id"], b["line"], b["target_year"]))
    return sorted(out, reverse=True)


def main():
    r6 = json.load(open(REG_600, encoding="utf-8"))
    r12 = json.load(open(REG_1200, encoding="utf-8"))
    r18 = json.load(open(REG_1800, encoding="utf-8"))
    errors, warnings = [], []

    # Schema, against 0-600 (and so against 600-1200, which matches it).
    missing_top = [k for k in r6 if k not in r18]
    if missing_top:
        errors.append("top-level keys missing: %s" % missing_top)
    extra_top = [k for k in r18 if k not in r6]
    if r18.get("lines") != r6["lines"]:
        errors.append("lines differ from 0-600: %s" % r18.get("lines"))
    count_keys = set(next(iter(r6["counts"].values())).keys())
    for line in r6["lines"]:
        if line not in r18["counts"]:
            errors.append("counts missing line %s" % line)
        elif set(r18["counts"][line].keys()) != count_keys:
            errors.append("count keys differ for %s" % line)
    field_types = {k: type(v) for k, v in r6["discoveries"][0].items()}
    alias_example = next(a for d in r6["discoveries"] for a in d["aliases"])
    alias_types = {k: type(v) for k, v in alias_example.items()}
    for d in r18["discoveries"]:
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
        if d["band_high"] > LAST or d["band_low"] < FIRST:
            warnings.append("%s: band %d-%d (target %d)" % (d["id"], d["band_low"], d["band_high"], d["target_year"]))

    seen = {}
    for d in r18["discoveries"]:
        if d["id"] in seen:
            errors.append("duplicate id %s (%s, %s)" % (d["id"], seen[d["id"]], d["line"]))
        seen[d["id"]] = d["line"]
    alias_slugs = {a["id"]: c for c, al in r18.get("merge_alias_ids", {}).items() for a in al}
    for slug, canon in alias_slugs.items():
        if slug in seen:
            errors.append("merged alias slug %s (-> %s) is also a canonical id" % (slug, canon))
    for line in r6["lines"]:
        if line not in {d["line"] for d in r18["discoveries"]}:
            errors.append("line %s has no discoveries" % line)

    if r18["total_canonical"] != len(r18["discoveries"]):
        errors.append("total_canonical mismatch")
    listed = sum(c["listed_rows"] for c in r18["counts"].values())
    aliases = sum(len(d["aliases"]) for d in r18["discoveries"])
    excluded = len(r18.get("excluded_rows", []))
    if listed != r18["total_listed_rows"]:
        errors.append("listed_rows sum %d != total_listed_rows %d" % (listed, r18["total_listed_rows"]))
    if listed != len(r18["discoveries"]) + aliases + excluded:
        errors.append("rows %d != canonical %d + aliases %d + excluded %d"
                      % (listed, len(r18["discoveries"]), aliases, excluded))

    # Everything placed before 1200.
    prior = {}
    for label, reg in (("0-600 registry", r6), ("600-1200 registry", r12)):
        for d in reg["discoveries"]:
            prior.setdefault(d["id"], "%s %s %d" % (label, d["line"], d["target_year"]))
        for canon, al in reg.get("merge_alias_ids", {}).items():
            for a in al:
                prior.setdefault(a["id"], "%s alias of %s" % (label, canon))
    for path in GAME_BLOCKS:
        for d in git_json(GAME_REF, path)["items"]:
            prior.setdefault(d["id"], "game %s %s %d" % (path.split("/")[-1], d["line"], d["target_year"]))
    excluded_1200 = {e["id"] for e in r12.get("excluded_rows", [])}
    redated = {r["id"] for r in r18.get("redates", [])}
    for d in r18["discoveries"]:
        if d["id"] in prior and d["id"] not in redated:
            errors.append("%s collides with %s and is not a recorded redate" % (d["id"], prior[d["id"]]))
        if d["id"] in excluded_1200 and d["id"] not in {x["id"] for x in r18.get("previously_excluded_now_placed", [])}:
            errors.append("%s was an excluded 600-1200 row and is not recorded as placed" % d["id"])
    for r in r18.get("redates", []):
        if r["id"] not in prior or r["id"] not in seen:
            errors.append("redate %s does not match a prior id and a block id" % r["id"])
    for slug in alias_slugs:
        if slug in prior:
            errors.append("merged alias slug %s collides with %s" % (slug, prior[slug]))

    # Predecessors resolve.
    for i, preds in r18.get("predecessors", {}).items():
        if i not in seen:
            errors.append("predecessors key %s not in block" % i)
        for p in preds:
            if p not in prior and p not in seen:
                errors.append("%s continues unknown id %s" % (i, p))
            if p == i:
                errors.append("%s continues itself" % i)
            if p in seen and p != i:
                py = next(d["target_year"] for d in r18["discoveries"] if d["id"] == p)
                iy = next(d["target_year"] for d in r18["discoveries"] if d["id"] == i)
                if py > iy:
                    warnings.append("%s (%d) continues later item %s (%d)" % (i, iy, p, py))

    for b in r18.get("belongs_later", []) + r18.get("belongs_earlier", []):
        if b["id"] in seen:
            errors.append("belongs-elsewhere id %s is in the block" % b["id"])
    for e in r18.get("excluded_rows", []):
        if e["id"] in seen:
            errors.append("excluded row id %s is in the block" % e["id"])

    for d in r18["discoveries"]:
        for t in [d["id"], d["name"]] + [a["name"] for a in d["aliases"]]:
            hits = denylist_hits(t)
            if hits:
                errors.append("%s: real-name term(s) %s in %r" % (d["id"], hits, t))

    # Report.
    print("registry_1800: %d canonical from %d listed rows" % (len(r18["discoveries"]), listed))
    print("%-15s %6s %9s %7s %4s %4s %7s" % ("line", "listed", "canonical", "catalog", "era", "new", "merged>"))
    for line in r6["lines"]:
        c = r18["counts"][line]
        print("%-15s %6d %9d %7d %4d %4d %7d" % (line, c["listed_rows"], c["canonical"], c["catalog"], c["era"],
                                                 c["new"], c["rows_merged_elsewhere"]))
    print("merges: %d alias rows into %d entries" % (aliases, sum(1 for d in r18["discoveries"] if d["aliases"])))
    for m in r18.get("merges", []):
        print("  %s (%s %d) <- %s (%s %d)" % (m["canonical"], m["canonical_line"], m["canonical_year"],
                                             m["merged_id"], m["merged_line"], m["merged_year"]))
    print("line reassignments: %s" % ", ".join("%s %s->%s" % (r["id"], r["listed_line"], r["owner_line"])
                                              for r in r18.get("line_reassignments", [])))
    print("redates: %d" % len(r18.get("redates", [])))
    for r in r18.get("redates", []):
        print("  %s: %s %s %d -> %s %d" % (r["id"], r["old_source"], r["old_line"], r["old_year"], r["new_line"],
                                          r["new_year"]))
    print("excluded rows: %s" % ", ".join("%s (%s)" % (e["id"], e["line"]) for e in r18.get("excluded_rows", [])))
    print("belongs later: %d; belongs earlier: %d; bake-time fixes: %d; ambiguous: %d"
          % (len(r18.get("belongs_later", [])), len(r18.get("belongs_earlier", [])),
             len(r18.get("bake_time_fixes", [])), len(r18.get("ambiguous", []))))
    print("predecessor links: %d entries" % len(r18.get("predecessors", {})))
    print("extra top-level keys (ignored by 0-600 consumers): %s" % ", ".join(extra_top))
    near = near_duplicates(r18["discoveries"])
    print("near-duplicate candidates across lines (reviewed in REGISTRY_1800_NOTES.md): %d" % len(near))
    for n in near:
        print("  %.2f %s (%s %d) ~ %s (%s %d)" % n)
    bands = [w.split(":")[0] for w in warnings if ": band " in w]
    if bands:
        print("note: %d bands reach outside %d-%d (targets are all in range)" % (len(bands), FIRST, LAST))
    for w in warnings:
        if ": band " not in w:
            print("note: " + w)
    for e in errors:
        print("ERROR: " + e)
    print("OK" if not errors else "%d error(s)" % len(errors))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
