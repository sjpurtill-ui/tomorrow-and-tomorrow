#!/usr/bin/env python3
"""Validate docs/research/y2400/registry_3000.json against everything placed before 2400.

Checks (errors):
  - unique snake_case ids; schema (top-level keys, count keys, discovery and
    alias fields and types) matches docs/research/registry.json; all 12 lines;
  - target years in 2400-3000 and inside their own bands;
  - row accounting: listed rows = canonical + aliases + excluded;
  - no id collides with an id placed, merged, excluded or renamed before 2400
    (all four earlier registries, including registry_2400.json, and every baked
    block on origin/codex/research-1200) unless it is a recorded redate;
  - every predecessor ("(continues: id)" and builder additions) resolves, and
    none is the item itself;
  - the ids replaced by source_list_fixes and the excluded rows are absent;
  - [gov: ...] tags use only the normalised vocabulary;
  - catalog coverage: no catalog id from AD 1800 on is left unplaced;
  - no id or name (canonical or alias) contains a denylisted real-world name
    (tools/research/denylist_modern.py, which extends the 1800-2400 list;
    whole-word matching, with exact-only stems for ordinary words such as
    germanium, franking or japanning; its self-test runs first).
    Catalog ids listed in real_name_id_exceptions are reported, not failed.

It also prints (not errors) the cross-line near-duplicate candidates in this
window, the near-duplicate candidates against registry_2400.json, predecessors
placed after the item that continues them, and the research-pace flags.
Exit status 1 on any error.

  python tools/research/validate_registry_3000.py
"""
import importlib.util
import itertools
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))


def _load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, name + ".py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_v1800 = _load("validate_registry_1800")
denylist = _load("denylist_modern")
builder = _load("build_registry_3000")

REG_600 = os.path.join(ROOT, "docs", "research", "registry.json")
REG_3000 = os.path.join(ROOT, "docs", "research", "y2400", "registry_3000.json")
FIRST, LAST = 2400, 3000


def cross_window_near(discoveries, earlier, threshold=0.4):
    out = []
    for a in discoveries:
        wa = _v1800._words(a)
        for d in earlier:
            wb = _v1800._words(d)
            score = len(wa & wb) / float(len(wa | wb))
            if score >= threshold:
                out.append((round(score, 2), a["id"], a["line"], a["target_year"], d["id"], d["line"], d["target_year"]))
    return sorted(out, reverse=True)


def main():
    denylist.self_test()
    r6 = json.load(open(REG_600, encoding="utf-8"))
    reg = json.load(open(REG_3000, encoding="utf-8"))
    errors, warnings = [], []

    # Schema, against 0-600.
    missing_top = [k for k in r6 if k not in reg]
    if missing_top:
        errors.append("top-level keys missing: %s" % missing_top)
    extra_top = [k for k in reg if k not in r6]
    if reg.get("lines") != r6["lines"]:
        errors.append("lines differ from 0-600: %s" % reg.get("lines"))
    count_keys = set(next(iter(r6["counts"].values())).keys())
    for line in r6["lines"]:
        if line not in reg["counts"]:
            errors.append("counts missing line %s" % line)
        elif set(reg["counts"][line].keys()) != count_keys:
            errors.append("count keys differ for %s" % line)
    field_types = {k: type(v) for k, v in r6["discoveries"][0].items()}
    alias_example = next(a for d in r6["discoveries"] for a in d["aliases"])
    alias_types = {k: type(v) for k, v in alias_example.items()}
    for d in reg["discoveries"]:
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
            errors.append("%s: year %d outside its band %d-%d" % (d["id"], d["target_year"], d["band_low"], d["band_high"]))
        if d["band_high"] > LAST or d["band_low"] < FIRST:
            warnings.append("%s: band %d-%d" % (d["id"], d["band_low"], d["band_high"]))

    seen = {}
    for d in reg["discoveries"]:
        if d["id"] in seen:
            errors.append("duplicate id %s (%s, %s)" % (d["id"], seen[d["id"]], d["line"]))
        seen[d["id"]] = d["line"]
    by_id = {d["id"]: d for d in reg["discoveries"]}
    alias_slugs = {a["id"]: c for c, al in reg.get("merge_alias_ids", {}).items() for a in al}
    for slug, canon in alias_slugs.items():
        if slug in seen:
            errors.append("merged alias slug %s (-> %s) is also a canonical id" % (slug, canon))
    for line in r6["lines"]:
        if line not in {d["line"] for d in reg["discoveries"]}:
            errors.append("line %s has no discoveries" % line)
    if reg["total_canonical"] != len(reg["discoveries"]):
        errors.append("total_canonical mismatch")
    listed = sum(c["listed_rows"] for c in reg["counts"].values())
    aliases = sum(len(d["aliases"]) for d in reg["discoveries"])
    excluded = len(reg.get("excluded_rows", []))
    if listed != reg["total_listed_rows"]:
        errors.append("listed_rows sum %d != total_listed_rows %d" % (listed, reg["total_listed_rows"]))
    if listed != len(reg["discoveries"]) + aliases + excluded:
        errors.append("rows %d != canonical %d + aliases %d + excluded %d"
                      % (listed, len(reg["discoveries"]), aliases, excluded))

    # Everything placed, merged, excluded or renamed before 2400.
    prior = builder.prior_ids()
    redated = {r["id"] for r in reg.get("redates", [])}
    now_placed = {x["id"] for x in reg.get("previously_excluded_now_placed", [])}
    for d in reg["discoveries"]:
        if d["id"] in prior:
            src, line, year, kind = prior[d["id"]]
            if kind == "excluded":
                if d["id"] not in now_placed:
                    errors.append("%s was excluded in %s and is not recorded as placed" % (d["id"], src))
            elif d["id"] not in redated:
                errors.append("%s collides with %s %s %s (%s) and is not a recorded redate"
                              % (d["id"], src, line, year, kind))
    for slug in alias_slugs:
        if slug in prior:
            errors.append("merged alias slug %s collides with %s" % (slug, prior[slug][0]))

    # Predecessors.
    for i, preds in reg.get("predecessors", {}).items():
        if i not in seen:
            errors.append("predecessors key %s not in block" % i)
            continue
        for p in preds:
            if p == i:
                errors.append("%s continues itself" % i)
            elif p not in prior and p not in seen:
                errors.append("%s continues unknown id %s" % (i, p))
            elif p not in seen and prior[p][3] != "placed":
                errors.append("%s continues %s, which is %s in %s; point it at the canonical id"
                              % (i, p, prior[p][3], prior[p][0]))
            elif p in by_id and by_id[p]["target_year"] > by_id[i]["target_year"]:
                warnings.append("%s (%d) continues later item %s (%d)"
                                % (i, by_id[i]["target_year"], p, by_id[p]["target_year"]))

    for fix in reg.get("source_list_fixes", []):
        if fix["old_id"] in seen or fix["old_id"] in alias_slugs:
            errors.append("source fix: old id %s still present" % fix["old_id"])
        if fix["new_id"] not in seen:
            errors.append("source fix: new id %s missing" % fix["new_id"])
        for i, preds in reg.get("predecessors", {}).items():
            if fix["old_id"] in preds:
                errors.append("%s still continues the replaced id %s" % (i, fix["old_id"]))
    for e in reg.get("excluded_rows", []):
        if e["id"] in seen:
            errors.append("excluded row id %s is in the block" % e["id"])
    for b in reg.get("belongs_later", []) + reg.get("belongs_earlier", []):
        if b["id"] in seen:
            errors.append("belongs-elsewhere id %s is in the block" % b["id"])

    vocab = set(reg.get("gov_tag_normalisation", {}).get("vocabulary", []))
    for i, tags in reg.get("gov_tags", {}).items():
        for t in tags:
            if t not in vocab:
                errors.append("%s: [gov:] tag %s not in the normalised vocabulary" % (i, t))

    cover = reg.get("catalog_coverage", {})
    for u in cover.get("unplaced", []):
        errors.append("catalog id %s (AD %s) is not placed in any registry" % (u["id"], u["catalog_historical_year"]))

    exceptions = reg.get("real_name_id_exceptions", {})
    exception_hits, allowed = [], set()
    for d in reg["discoveries"]:
        texts = [("id", d["id"]), ("name", d["name"])] + [("alias", a["name"]) for a in d["aliases"]]
        texts += [("alias_id", a["id"]) for a in reg.get("merge_alias_ids", {}).get(d["id"], [])]
        for kind, t in texts:
            h = denylist.hits(t)
            allowed |= set(denylist.allowed_terms_used(t))
            if not h:
                continue
            if kind == "id" and d["id"] in exceptions:
                exception_hits.append("%s %s" % (d["id"], h))
            else:
                errors.append("%s: real-name term(s) %s in %s %r" % (d["id"], h, kind, t))

    # Report.
    print("registry_3000: %d canonical from %d listed rows" % (len(reg["discoveries"]), listed))
    print("%-15s %6s %9s %7s %4s %4s %7s" % ("line", "listed", "canonical", "catalog", "era", "new", "merged>"))
    for line in r6["lines"]:
        c = reg["counts"][line]
        print("%-15s %6d %9d %7d %4d %4d %7d" % (line, c["listed_rows"], c["canonical"], c["catalog"], c["era"],
                                                 c["new"], c["rows_merged_elsewhere"]))
    print("merges: %d alias rows; resolved duplicates without alias rows: %d"
          % (aliases, len(reg.get("resolved_duplicates", []))))
    for r in reg.get("resolved_duplicates", []):
        print("  kept %s (%s %d), dropped %s (%s %d)" % (r["kept"], r["kept_line"], r["kept_year"], r["dropped"],
                                                         r["dropped_line"], r["dropped_year"]))
    print("excluded rows: %s" % ", ".join("%s (%s %d)" % (e["id"], e["line"], e["target_year"])
                                          for e in reg.get("excluded_rows", [])))
    print("redates: %d; previously excluded now placed: %d" % (len(reg.get("redates", [])), len(now_placed)))
    print("source-list id fixes: %s" % ", ".join("%s -> %s" % (f["old_id"], f["new_id"])
                                                 for f in reg.get("source_list_fixes", [])))
    print("rows added by this pass: %s" % ", ".join("%s (%s %d)" % (a["id"], a["line"], a["year"])
                                                    for a in reg.get("rows_added_by_registry", [])))
    print("predecessor links: %d entries" % len(reg.get("predecessors", {})))
    print("belongs-later items from 1800-2400 placed here: %d; still unplaced: %d"
          % (len({x["id"] for x in reg.get("placed_from_2400_belongs_later", [])}),
             len(reg.get("belongs_later_still_unplaced", []))))
    print("catalog coverage from AD %d: %d ids, %d placed here, %d placed earlier, %d excluded, %d unplaced"
          % (cover.get("from_ad", 0), cover.get("ids", 0), cover.get("placed_here", 0),
             len(cover.get("placed_earlier", [])), len(cover.get("excluded", [])), len(cover.get("unplaced", []))))
    if exception_hits:
        print("real-name catalog id exceptions (reported, not failed): %s" % "; ".join(exception_hits))
    if allowed:
        print("allowed technical terms used: %s" % ", ".join(sorted(allowed)))
    print("extra top-level keys (ignored by 0-600 consumers): %s" % ", ".join(extra_top))
    near = _v1800.near_duplicates(reg["discoveries"])
    print("near-duplicate candidates across lines (reviewed in REGISTRY_3000_NOTES.md): %d" % len(near))
    for n in near:
        print("  %.2f %s (%s %d) ~ %s (%s %d)" % n)
    r24 = json.load(open(builder.PRIOR_REGISTRIES[3][1], encoding="utf-8"))["discoveries"]
    cross = cross_window_near(reg["discoveries"], r24)
    print("near-duplicate candidates against registry_2400 (score >= 0.4): %d" % len(cross))
    for n in cross:
        print("  %.2f %s (%s %d) ~ %s (%s %d)" % n)
    pace = reg.get("pace", {}).get("lines", {})
    print("research pace (load = research years / band width; flag > 2.0 or > 30 items per 50 years):")
    for line in r6["lines"]:
        p = pace.get(line)
        if p:
            print("  %-15s window %.2f; flagged 50y bins: %s; peak 25y %s load %.2f (%d items)"
                  % (line, p["window_load"], ", ".join(p["flagged_bins_50y"]) or "none", p["peak_25y"]["window"],
                     p["peak_25y"]["load"], p["peak_25y"]["items"]))
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
