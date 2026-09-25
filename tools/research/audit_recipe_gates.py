#!/usr/bin/env python3
"""Recipe gate audit: list every civilian_industry.gd recipe whose gate opens
long before the era of the process it describes.

A recipe's *process era* (game years) is the latest of
  - its own gate's proposed game year;
  - the earliest year every material and tooling input can itself be made
    (the cheapest producing recipe, recursively; raw landscape resources are
    available from the start);
  - electricity: a recipe that draws daily power belongs to the era of
    electric service (about AD 1880);
  - PROCESS_ERA below: authored historical years for processes whose era is
    not implied by their inputs (e.g. laboratory chemistry made from wood ash).

A recipe is flagged when its gate opens more than THRESHOLD game years before
its process era. Exit status 1 when any recipe is flagged.

  python tools/research/audit_recipe_gates.py [--all] [--threshold 150]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import recipe_data as R  # noqa: E402

THRESHOLD = 150.0
ELECTRIC_SERVICE_AD = 1880
# Inputs made by other systems, not by PRODUCTS; historical AD year of the material.
EXTERNAL_INPUT_AD = {
    "Broad-Range Recovered PEG Batches": 1950, "Distribution-Qualified PEG Batches": 1950,
    "Narrow PEG DP10 Standards": 1960, "Narrow PEG DP160 Standards": 1960, "Narrow PEG DP40 Standards": 1960,
    "Qualified Aqueous SEC Packing": 1964, "Sequence-Characterized Copolymer Specimens": 1960,
    "Size-Characterized PEG Batches": 1964, "Tacticity-Characterized PP Batches": 1957,
    "Rejected Ground Steel Parts": 1900, "Bauxite": 1880, "Rutile Ore": 1900, "Nickel Ore": 1850,
}
# Authored historical AD years for processes whose inputs do not reveal their era.
PROCESS_ERA = {
    "metallographic_nitric_acid": 1863,   # metallographic etching of polished steel sections
    "metallographic_nital": 1900,
    "styrene_promoter_salts": 1935,       # potassium-promoted dehydrogenation catalysts
    "purified_potassium_chloride": 1860,
    "separated_carbon_monoxide": 1900,
    "captured_calcination_carbon_dioxide": 1760,  # fixed air driven from limestone
    "vacuum_melting_chambers": 1920,
    "gently_formed_steel_bars": 1870,
    "cold_bent_steel_bars": 1870,
    "alloy_phase_trial_sets": 1900,
    "fracture_loading_frames": 1920,
    "case_hardened_gears": 1780,
    "lead_electrode_sheets": 1860,
    "track_ballast": 1800,
}


def audit(threshold=THRESHOLD):
    curve, _ = R.curve_and_history()
    products = R.products()
    years = R.discovery_game_years()
    gy = lambda ad: R.game_year_for(ad, curve)
    producers = {}
    for rid, spec in products.items():
        producers.setdefault(spec["output"], []).append(rid)
        for co in spec.get("co_products", {}):
            producers.setdefault(co, []).append(rid)
    inf = float("inf")
    resource_year = {}
    best_producer = {}
    for name, ad in EXTERNAL_INPUT_AD.items():
        resource_year[name] = gy(ad)

    def res_year(name):
        if name in resource_year:
            return resource_year[name]
        if name not in producers:
            return 0.0
        return inf

    recipe_year = {rid: inf for rid in products}
    floor = {}
    for rid, spec in products.items():
        f = years[spec["gate"]][0]
        if float(spec.get("power", 0)) > 0:
            f = max(f, gy(ELECTRIC_SERVICE_AD))
        if rid in PROCESS_ERA:
            f = max(f, gy(PROCESS_ERA[rid]))
        floor[rid] = f
    changed = True
    while changed:
        changed = False
        for rid, spec in products.items():
            need = floor[rid]
            for name in list(spec.get("materials", {})) + list(spec.get("tooling", {})):
                need = max(need, res_year(name))
            if need < recipe_year[rid]:
                recipe_year[rid] = need
                changed = True
        for name, rids in producers.items():
            if name in EXTERNAL_INPUT_AD:
                continue
            best_rid = min(rids, key=lambda r: recipe_year[r])
            best = recipe_year[best_rid]
            if best < resource_year.get(name, inf):
                resource_year[name] = best
                best_producer[name] = best_rid
                changed = True
    rows = []
    for rid, spec in products.items():
        gate_year = years[spec["gate"]][0]
        era = recipe_year[rid]
        # the input that sets the era, for the report
        why = "gate"
        limit_input = ""
        if rid in PROCESS_ERA and gy(PROCESS_ERA[rid]) >= era - 1e-6:
            why = "authored AD %d" % PROCESS_ERA[rid]
        elif float(spec.get("power", 0)) > 0 and gy(ELECTRIC_SERVICE_AD) >= era - 1e-6:
            why = "electric power"
        else:
            for name in list(spec.get("materials", {})) + list(spec.get("tooling", {})):
                if res_year(name) >= era - 1e-6 and era > gate_year:
                    why = "input " + name
                    limit_input = name
                    break
        rows.append({"id": rid, "gate": spec["gate"], "gate_year": gate_year, "era": era,
                     "era_ad": R.historical_for(era, curve), "lead": era - gate_year, "why": why,
                     "limit_input": limit_input, "limit_producer": best_producer.get(limit_input, "")})
    rows.sort(key=lambda r: -r["lead"])
    return rows, threshold


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--threshold", type=float, default=THRESHOLD)
    a = ap.parse_args()
    rows, th = audit(a.threshold)
    flagged = [r for r in rows if r["lead"] > th]
    for r in (rows if a.all else flagged):
        print("%-44s gate %-38s %6.0f  era %6.0f (AD %5.0f)  lead %6.0f  %s" % (
            r["id"], r["gate"], r["gate_year"], r["era"], r["era_ad"], r["lead"], r["why"]))
    print("%d recipes audited, %d open more than %.0f game years before their process era" % (len(rows), len(flagged), th))
    return 1 if flagged else 0


if __name__ == "__main__":
    sys.exit(main())
