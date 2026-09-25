#!/usr/bin/env python3
"""Validate docs/research/y1800/registry_2400.json against everything placed before 1800.

Checks: unique ids; schema (top-level keys, count keys, discovery and alias
fields and types) matches docs/research/registry.json; all 12 lines present;
target years in 1800-2400 and inside their bands; no id collides with an id
placed, merged or excluded before 1800 (0-600, 600-1200 and 1200-1800
registries, and every baked block on origin/codex/research-1200, including a
y1200_1800 block once it lands) unless listed as a redate; every predecessor
resolves; belongs-later and belongs-earlier ids are absent; no denylisted
real-world name in ids or names. It also re-runs a cross-line near-duplicate
scan inside the block and a scan against the 1200-1800 registry, and prints
the candidate pairs for review; those are not errors. Exit status 1 on any
error.

The denylist matches whole words only: ids and names are split into
[a-z]+ tokens, and multi-word phrases are compiled with real \\b word
boundaries (the self-test below fails if a phrase pattern ever contains a
control character such as a literal backspace).

  python tools/research/validate_registry_2400.py
"""
import importlib.util
import itertools
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
REG_600 = os.path.join(ROOT, "docs", "research", "registry.json")
REG_1200 = os.path.join(ROOT, "docs", "research", "y600", "registry_1200.json")
REG_1800 = os.path.join(ROOT, "docs", "research", "y1200", "registry_1800.json")
REG_2400 = os.path.join(ROOT, "docs", "research", "y1800", "registry_2400.json")
GAME_REF = "origin/codex/research-1200"
FIRST, LAST = 1800, 2400


def _load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_v1800 = _load("validate_registry_1800")

# The 1200-1800 denylist plus early-modern peoples, polities, places,
# persons, confessions, institutions, texts, eponymous units and trade names.
DENYLIST = _v1800.DENYLIST + """
renaissance reformation counterreformation protestant* catholic* lutheran* calvin* huguenot* puritan* quaker*
anabaptist* methodist* anglican* presbyter* jesuit* ursulin* capuchin* jansen* pietis* inquisition papist*
america* europe* european* africa* asia* asian* atlantic caribbean indies peru peruvian* mexic* brazil* virginia*
carolina* jamaica* barbados bengal* mughal* mogul* safavid* qing manchu* tokugawa edo ming siam* ceylon* java
javanese malacca* moluccas batavia* cathay* muscov* russia* prussia* austria* habsburg* hapsburg* bourbon*
stuart* valois hohenzoll* romanov* orange orangist holland dutch netherland* flemish flanders brabant* burgund*
swiss swede* swedish portug* castil* aragon* catalan* spain versailles venice amsterdam antwerp lisbon seville
madrid vienna berlin moscow delhi istanbul naples genev* lyon* marseill* bordeaux nantes dresden meissen sevres
delft delftware nuremberg* augsburg* leipzig leiden leyden bristol manchester birmingham liverpool edinburgh
glasgow dublin boston philadelphia calcutta madras bombay macao nagasaki manila acapulco potosi cadiz
newton* newtonian galile* kepler* copernic* leibniz* descart* cartesian* boyle hooke huygens harvey jenner
linnae* buffon lavoisier priestley franklin volta* voltaic galvan* fahrenheit celsius reaumur torricell*
pascal* fermat napier* mercator* hadley harrison cassegrain* gregorian julian leeuwenhoek malpighi vesal*
paracels* sydenham boerhaave newcomen darby arkwright hargreaves crompton wedgwood huntsman cort smeaton brindley
telford macadam* watt watts* bessemer argand montgolfier* guillotin* voltaire rousseau locke hobbes montesquieu
diderot kant hume spinoza grotius machiavell* bodin luther erasmus calvinist* zwingli* loyola
shakespear* cervantes quixot* milton moliere racine defoe crusoe swift gulliver richardson pamela fielding
goethe werther bach mozart haydn handel vivaldi monteverdi lully rembrandt vermeer rubens leonardo michelangelo
raphael titian durer bosch columbus magellan vespucci drake raleigh cortes pizarro gama cabot hudson tasman
bligh
gobelin* axminster wilton worcester chelsea bow derby spode doulton sheffield toledo cordovan morocco damascus
prussian hessian* nankeen*
""".split()
# Ordinary English words among the stems above are checked as exact words
# only (never as prefixes), and a few are ordinary vocabulary in this window
# and dropped: "orange" (fruit), "bow" (weapon), "derby", "chelsea",
# "worcester" and "hudson" are exact-only.
DROP = {"orange", "bow", "java", "attic"}
DENYLIST = [s for s in DENYLIST if s not in DROP]
EXACT_ONLY = set(_v1800.EXACT_ONLY) | {"plato", "julian", "harvey", "cort", "swift", "drake", "hume", "bosch",
                                       "watt", "pascal", "volta", "galvan", "morocco", "derby", "chelsea",
                                       "worcester", "hudson", "richardson", "fielding", "franklin",
                                       "harrison", "napier", "hadley", "edo", "turk"}
# Ordinary vocabulary that a stem above would catch: "caesarean" (the
# operation; stem caesar*) and "platoon" (stem plato*, now exact-only).
# "canton" (a recruiting district), "encyclopedia", "bounty", "attic",
# "habeas", "a great fire" and "a bill of rights" are generic and not listed.
ALLOW = {"caesarean", "caesareans"}
# Phrases: raw strings with real \b boundaries (checked by self_test()).
PHRASES = _v1800.PHRASES + [
    r"\bnew world\b", r"\bold world\b", r"\bwest indi", r"\beast indi", r"\bindia (rubber|company)\b",
    r"\bguinea (fowl|pig|coast|trade)\b", r"\bjesuits?'? bark\b", r"\bperuvian bark\b", r"\bprussian blue\b",
    r"\bparis green\b", r"\bplaster of paris\b", r"\bportland (cement|stone)\b", r"\bbath stone\b",
    r"\bleyden jar\b", r"\barchimedean\b", r"\bjacob'?s staff\b", r"\bdutch (oven|door|auction|courage)\b",
    r"\bfrench (drain|horn|polish)\b", r"\bvenetian (blind|glass)\b", r"\bspanish (fly|moss|main)\b",
    r"\bturkey red\b", r"\bmorocco leather\b", r"\bholland cloth\b", r"\bbrussels (lace|carpet)\b",
    r"\bgothic (revival|novel)\b", r"\bsouth sea\b", r"\bglorious revolution\b",
    r"\bthirty years'? war\b", r"\bmagna carta\b",
    r"\bnavigation acts?\b", r"\bcorn laws?\b", r"\bpoor law amendment\b", r"\bbastille\b",
]
_PHRASE_RE = [re.compile(p) for p in PHRASES]


def self_test():
    for p in PHRASES:
        if any(ord(ch) < 32 for ch in p):
            raise SystemExit("denylist phrase %r contains a control character (use \\b, not a literal backspace)" % p)
    assert "west indi" in denylist_hits("Tubs of west india rum"), "phrase check failed"
    assert denylist_hits("Prussian blue pigment"), "phrase boundary check failed"
    assert not denylist_hits("Turkeys fattened in yards"), "turk stem must not match turkeys"
    assert denylist_hits("newtonian_optics"), "id tokens must be checked"
    assert not denylist_hits("Swiftly drawn wire"), "exact-only words must not prefix-match"
    assert not denylist_hits("fire by platoons"), "plato must not prefix-match platoon"
    assert denylist_hits("platonic forms") and denylist_hits("Flemish bond"), "whole-word hits failed"


def denylist_hits(text):
    low = text.lower().replace("_", " ")
    hits = []
    for w in re.findall(r"[a-z]+", low):
        if w in ALLOW:
            continue
        for stem in DENYLIST:
            base = stem[:-1] if stem.endswith("*") else stem
            if stem.endswith("*") and base not in EXACT_ONLY:
                if w.startswith(base):
                    hits.append(w)
            elif w == base:
                hits.append(w)
    for rx in _PHRASE_RE:
        hits += [m.group(0) for m in rx.finditer(low)]
    return sorted(set(hits))


def git(*args):
    return subprocess.check_output(["git", "-C", ROOT] + list(args)).decode("utf-8", "replace")


def game_blocks():
    names = git("ls-tree", "-r", "--name-only", GAME_REF, "--", "data/research").split()
    return [p for p in names if p == "data/research/research_600.json"
            or re.fullmatch(r"data/research/blocks/[^/]+\.json", p)]


near_duplicates = _v1800.near_duplicates
_words = _v1800._words


def cross_window(new, old, threshold=0.5):
    out = []
    old_words = [(d, _words(d)) for d in old]
    for a in new:
        wa = _words(a)
        for b, wb in old_words:
            if not wa or not wb:
                continue
            score = len(wa & wb) / float(len(wa | wb))
            if score >= threshold:
                out.append((round(score, 2), a["id"], a["line"], a["target_year"], b["id"], b["line"],
                            b["target_year"]))
    return sorted(out, reverse=True)


def main():
    self_test()
    r6 = json.load(open(REG_600, encoding="utf-8"))
    r12 = json.load(open(REG_1200, encoding="utf-8"))
    r18 = json.load(open(REG_1800, encoding="utf-8"))
    r24 = json.load(open(REG_2400, encoding="utf-8"))
    errors, warnings = [], []

    missing_top = [k for k in r6 if k not in r24]
    if missing_top:
        errors.append("top-level keys missing: %s" % missing_top)
    extra_top = [k for k in r24 if k not in r6]
    if r24.get("lines") != r6["lines"]:
        errors.append("lines differ from 0-600: %s" % r24.get("lines"))
    count_keys = set(next(iter(r6["counts"].values())).keys())
    for line in r6["lines"]:
        if line not in r24["counts"]:
            errors.append("counts missing line %s" % line)
        elif set(r24["counts"][line].keys()) != count_keys:
            errors.append("count keys differ for %s" % line)
    field_types = {k: type(v) for k, v in r6["discoveries"][0].items()}
    alias_example = next(a for d in r6["discoveries"] for a in d["aliases"])
    alias_types = {k: type(v) for k, v in alias_example.items()}
    for d in r24["discoveries"]:
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
        if not re.fullmatch(r"[a-z][a-z0-9_]*", d["id"]):
            errors.append("%s: id is not snake_case" % d["id"])
        if not (FIRST <= d["target_year"] <= LAST):
            errors.append("%s: target_year %d outside %d-%d" % (d["id"], d["target_year"], FIRST, LAST))
        if not (d["band_low"] <= d["target_year"] <= d["band_high"]):
            errors.append("%s: year %d outside its band %d-%d" % (d["id"], d["target_year"], d["band_low"],
                                                                  d["band_high"]))
        if d["band_high"] > LAST or d["band_low"] < FIRST:
            warnings.append("%s: band %d-%d (target %d)" % (d["id"], d["band_low"], d["band_high"], d["target_year"]))

    seen = {}
    for d in r24["discoveries"]:
        if d["id"] in seen:
            errors.append("duplicate id %s (%s, %s)" % (d["id"], seen[d["id"]], d["line"]))
        seen[d["id"]] = d
    alias_slugs = {a["id"]: c for c, al in r24.get("merge_alias_ids", {}).items() for a in al}
    for slug, canon in alias_slugs.items():
        if slug in seen:
            errors.append("merged alias slug %s (-> %s) is also a canonical id" % (slug, canon))
    for line in r6["lines"]:
        if line not in {d["line"] for d in r24["discoveries"]}:
            errors.append("line %s has no discoveries" % line)
    if r24["total_canonical"] != len(r24["discoveries"]):
        errors.append("total_canonical mismatch")
    listed = sum(c["listed_rows"] for c in r24["counts"].values())
    aliases = sum(len(d["aliases"]) for d in r24["discoveries"])
    excluded = len(r24.get("excluded_rows", []))
    if listed != r24["total_listed_rows"]:
        errors.append("listed_rows sum %d != total_listed_rows %d" % (listed, r24["total_listed_rows"]))
    if listed != len(r24["discoveries"]) + aliases + excluded:
        errors.append("rows %d != canonical %d + aliases %d + excluded %d"
                      % (listed, len(r24["discoveries"]), aliases, excluded))

    # Everything placed, merged or excluded before 1800.
    prior, prior_excluded = {}, {}
    for label, reg in (("0-600 registry", r6), ("600-1200 registry", r12), ("1200-1800 registry", r18)):
        for d in reg["discoveries"]:
            prior.setdefault(d["id"], "%s %s %d" % (label, d["line"], d["target_year"]))
        for canon, al in reg.get("merge_alias_ids", {}).items():
            for a in al:
                prior.setdefault(a["id"], "%s alias of %s" % (label, canon))
        for e in reg.get("excluded_rows", []):
            prior_excluded.setdefault(e["id"], "%s excluded %s %d" % (label, e["line"], e["target_year"]))
    blocks = game_blocks()
    for path in blocks:
        for d in json.loads(git("show", GAME_REF + ":" + path))["items"]:
            prior.setdefault(d["id"], "game %s %s %d" % (path.split("/")[-1], d["line"], d["target_year"]))
    redated = {r["id"] for r in r24.get("redates", [])}
    now_placed = {x["id"] for x in r24.get("previously_excluded_now_placed", [])}
    for i in seen:
        if i in prior and i not in redated:
            errors.append("%s collides with %s and is not a recorded redate" % (i, prior[i]))
        if i in prior_excluded and i not in now_placed:
            errors.append("%s collides with %s and is not recorded as placed" % (i, prior_excluded[i]))
    for r in r24.get("redates", []):
        if r["id"] not in prior or r["id"] not in seen:
            errors.append("redate %s does not match a prior id and a block id" % r["id"])
    for slug in alias_slugs:
        if slug in prior or slug in prior_excluded:
            errors.append("merged alias slug %s collides with an earlier id" % slug)
    for r in r24.get("renamed_collisions", []):
        if r["row_id"] in seen:
            errors.append("renamed slug %s is still a canonical id" % r["row_id"])

    # Predecessors resolve.
    n_links = 0
    for i, preds in r24.get("predecessors", {}).items():
        if i not in seen:
            errors.append("predecessors key %s not in block" % i)
            continue
        for p in preds:
            n_links += 1
            if p not in prior and p not in seen:
                errors.append("%s continues unknown id %s" % (i, p))
            if p == i:
                errors.append("%s continues itself" % i)
            if p in seen and p != i and seen[p]["target_year"] > seen[i]["target_year"]:
                warnings.append("%s (%d) continues later item %s (%d)" % (i, seen[i]["target_year"], p,
                                                                          seen[p]["target_year"]))

    for b in r24.get("belongs_later", []) + r24.get("belongs_earlier", []):
        if b["id"] in seen:
            errors.append("belongs-elsewhere id %s is in the block" % b["id"])
    for e in r24.get("excluded_rows", []):
        if e["id"] in seen:
            errors.append("excluded row id %s is in the block" % e["id"])

    for d in r24["discoveries"]:
        for t in [d["id"], d["name"]] + [a["name"] for a in d["aliases"]]:
            hits = denylist_hits(t)
            if hits:
                errors.append("%s: real-name term(s) %s in %r" % (d["id"], hits, t))

    # Report.
    print("registry_2400: %d canonical from %d listed rows" % (len(r24["discoveries"]), listed))
    print("game blocks checked on %s: %s" % (GAME_REF, ", ".join(p.split("/")[-1] for p in blocks)))
    print("%-15s %6s %9s %7s %4s %4s %7s %4s" % ("line", "listed", "canonical", "catalog", "era", "new", "merged>",
                                                 "key"))
    for line in r6["lines"]:
        c = r24["counts"][line]
        key = sum(1 for d in r24["discoveries"] if d["line"] == line and d["key_threshold"])
        print("%-15s %6d %9d %7d %4d %4d %7d %4d" % (line, c["listed_rows"], c["canonical"], c["catalog"], c["era"],
                                                     c["new"], c["rows_merged_elsewhere"], key))
    print("merges: %d alias rows into %d entries" % (aliases, sum(1 for d in r24["discoveries"] if d["aliases"])))
    print("ownership rulings: %s" % ", ".join("%s->%s" % (o["id"], o["owner_line"])
                                              for o in r24.get("ownership_rulings", [])))
    print("renamed: %s" % ", ".join("%s->%s" % (r["row_id"], r["new_id"]) for r in r24.get("renamed_collisions", [])))
    print("redates: %d; previously excluded now placed: %d" % (len(r24.get("redates", [])), len(now_placed)))
    print("placed from 1200-1800 belongs-later: %d; still later: %s"
          % (len(r24.get("placed_from_1800_belongs_later", [])),
             ", ".join(x["id"] for x in r24.get("still_later_from_1800", []))))
    print("catalog ids whose catalog year is in window but unplaced: %d" % len(r24.get("catalog_in_window_unplaced", [])))
    print("belongs later: %d; belongs earlier: %d; bake-time fixes: %d; ambiguous: %d"
          % (len(r24.get("belongs_later", [])), len(r24.get("belongs_earlier", [])),
             len(r24.get("bake_time_fixes", [])), len(r24.get("ambiguous", []))))
    print("predecessor links: %d entries, %d links" % (len(r24.get("predecessors", {})), n_links))
    print("gov tags: %d" % len(r24.get("gov_tags", {})))
    print("extra top-level keys (ignored by 0-600 consumers): %s" % ", ".join(extra_top))
    near = near_duplicates(r24["discoveries"])
    print("near-duplicate candidates across lines: %d" % len(near))
    for n in near:
        print("  %.2f %s (%s %d) ~ %s (%s %d)" % n)
    cross = cross_window(r24["discoveries"], r18["discoveries"] + r12["discoveries"] + r6["discoveries"])
    print("near-duplicate candidates against earlier registries: %d" % len(cross))
    for n in cross:
        print("  %.2f %s (%s %d) ~ %s (%s %d)" % n)
    bands = [w for w in warnings if ": band " in w]
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
