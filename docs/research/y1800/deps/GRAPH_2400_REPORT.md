# Research dependency graph report, years 1800–2400

Source: `graph_2400.json`, merged from the three dependency partials (`partials/kicl.json`, `partials/pils.json`, `partials/nhde.json`) by `tools/research/merge_graph_2400.py`. Node attributes (line, name, years, band, research time, key threshold) come from `../registry_2400.json`. Edges run prerequisite → dependent. A parent may be a 0–600 id (`docs/research/deps/graph.json`, plus the items the game adopted into its 0–600 block), a 600–1200 id (`docs/research/y600/deps/graph_1200.json`) or a 1200–1800 id (`docs/research/y1200/deps/graph_1800.json`). The node format is the one `tools/research/build_research_block.py` reads, the same as `graph_1800.json`.

Rebuild: `python tools/research/merge_graph_2400.py` (add `--stats` to print the figures in this report). The baked blocks are read from `origin/codex/research-1200`; `--game-dir <game worktree>` reads them from a local game checkout instead.

## Totals

- **Items:** 1,139. Every registry id appears exactly once across the partials, and no partial row has an unknown id.
  - kicl (knowledge, institutions, culture, labor): 411.
  - pils (production, infrastructure, logistics, security): 383.
  - nhde (nutrition, health, demography, ecology): 345.
- **Edges:** 3,820.
  - Hard `requires_all`: 1,846.
  - `requires_any`: none.
  - Precedents: 1,974 (including one demoted hard edge, see *Demoted link*).
- **Cross-line edges:** hard 378, precedent 615.
- **Cross-block edges (the parent is an earlier-block id):** 1,567. By block: 121 to 0–600, 346 to 600–1200 and 1,100 to 1200–1800. By kind: hard 768, precedent 799. 326 items have hard parents only in earlier blocks.
- **Items with no requirement:** 0.
- **Key thresholds:** 238.
- **Conditions normalized.** Every `resources_known` and `environment` value is a list, and `contact_required` is a boolean on every node.
  - `resources_known` (15 items): Coal ×5, Salt ×4, Lead Ore ×2, Silver Ore ×2, Copper Ore, Tin Ore.
  - `environment`, any-of (54 items): coast 39, river 13, woodland 4.
  - `contact_required` true: 58. This includes the whole overseas-crop chain: `maize_garden_trials` (1915, requires `transoceanic_contact_voyages`), `maize_field_crop`, `hill_sweet_potato_maize`, `maize_skin_sickness` and the potato items.
  - No other condition keys and no unmapped resources.

## Validation

The merge tool exits without writing anything when a check fails. Every check below passes.

| check | result |
|---|---|
| every referenced id known (this block, the 0–600 graph with the game's adopted items, the 600–1200 graph, or the 1200–1800 graph) | pass: 0 unknown |
| no id defined in two blocks, except recorded redates | pass: `registry_2400` has no redates; the 1200–1800 redate of `ocean_sailing` is applied to the prior set |
| design graphs agree with the game's baked blocks (`research_600.json`, `blocks/y600_1200.json`, `blocks/y1200_1800.json`): same ids, same block, same proposed years | pass: 0 missing, 0 extra, 0 year differences |
| combined 0–2400 graph acyclic over hard/any edges | pass |
| combined 0–2400 graph acyclic over all edges including precedents | pass |
| no `requires_all` parent dated after its dependent (baked years for earlier blocks) | pass: 0 |
| no `requires_any` group entirely later than its dependent | pass (no groups) |
| no precedent dated after its dependent | pass: 0 |
| every conditions list is a list (partials and merged nodes) | pass |
| every proposed year inside 1800–2400 | pass |
| no earlier-block item references a redated id | pass |

## Same-year hard edges (KICL)

Six `requires_all` edges join two items with the same proposed year. All six are kept as hard edges; none is demoted:

- `build_research_block.py` rejects only a parent with a **later** proposed year, so equal years pass.
- The loader (`scripts/research_600_catalog.gd`) compares no years between parent and dependent. An item opens once every hard parent is known and the year has reached its `min_year` (band_low), so the dependent simply waits for its parent.

| dependent | parent | year |
|---|---|---:|
| `abolition_of_estate_privileges` (institutions) | `single_national_assembly` (institutions) | 2378 |
| `estate_bondage_abolition` (labor) | `abolition_of_estate_privileges` (institutions) | 2378 |
| `freeborn_labor_debates` (labor) | `estates_rule_without_ruler` (institutions) | 2098 |
| `printed_vernacular_romances` (culture) | `town_printing_houses` (knowledge) | 1892 |
| `realm_bill_of_rights` (institutions) | `conditional_crown_settlement` (institutions) | 2178 |
| `rebuild_trade_opening` (labor) | `fire_rebuilding_acts` (infrastructure) | 2114 |

`realm_bill_of_rights` has band_low 2133, ten years below its parent's 2143, so in play it opens only after the settlement is known. The first two form a same-year chain of three (assembly → abolition of privileges → abolition of bondage at 2378).

## Demoted link

One hard edge is demoted to a precedent through `DEMOTE` in the merge tool:

| dependent | former hard parent | reason |
|---|---|---|
| `cylinder_boring` (infrastructure 2342) | `solid_bored_cannon` (security 2224) | Cannon boring came first and stays the precedent. As a hard edge, though, it made `precision_machinery` (and through it the game's modern civilian capabilities) depend on gun research. The game requires a peaceful path to those capabilities (`tests/test_civilian_science.gd`). `cylinder_boring` now requires `atmospheric_beam_engine` only. |

## Year adjustments

None. The kicl, pils and nhde adjustment files are empty. `year_adjustments_2400.json` is written with an empty list so the build tool's auto-detection finds a file.

## Cross-line matrix (hard; row = prerequisite line, column = dependent line; includes earlier-block parents)

| from \ to | KNO | INS | CUL | LAB | PRO | INF | NUT | HEA | DEM | LOG | ECO | SEC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| KNO | 174 | 6 | 26 | 4 | 10 | 3 | 12 | 14 | 1 | 7 | 2 | 6 |
| INS | 1 | 145 | 6 | 14 | 1 | 3 | 3 | 2 | 4 | 2 | 2 | 6 |
| CUL | 4 | 3 | 119 | 1 | · | 1 | · | · | · | · | · | 1 |
| LAB | 1 | 1 | 1 | 122 | · | · | 2 | 1 | 2 | · | · | · |
| PRO | 12 | · | 2 | 7 | 164 | 14 | 13 | 4 | · | 5 | 3 | 13 |
| INF | 1 | 1 | 2 | 2 | 2 | 106 | 5 | · | · | 8 | 2 | 1 |
| NUT | · | 1 | 2 | 3 | 3 | 2 | 99 | 5 | · | 3 | 5 | · |
| HEA | 1 | · | · | 1 | · | 2 | 1 | 109 | 4 | · | 5 | · |
| DEM | · | 1 | · | 2 | · | · | 1 | 1 | 99 | · | 2 | 1 |
| LOG | 2 | 3 | 3 | 3 | 3 | 4 | 17 | 5 | 2 | 100 | 5 | 4 |
| ECO | · | · | · | 4 | 5 | 1 | 2 | · | · | · | 91 | 1 |
| SEC | · | 2 | 1 | 2 | 3 | 3 | · | 5 | 2 | · | · | 140 |

## Pacing

- **Impossible (critical-path earliest year > band_high): 0.** Hard links alone make every item reachable long before 1800: the critical path from year 0 has a median of 11% of band_low, and the deepest item is reachable by year 383. Items stay in the window because the loader applies `min_year = band_low`, together with research throughput and conditions.
- **Queue pressure is far worse than in 1200–1800.** Total `research_years` per line exceeds the 600-year window in **every** line:

  | line | items | research years | over the window |
  |---|---:|---:|---:|
  | knowledge | 110 | 1,040 | +440 |
  | security | 104 | 976 | +376 |
  | institutions | 104 | 941 | +341 |
  | production | 106 | 786 | +186 |
  | logistics | 83 | 754 | +154 |
  | culture | 98 | 716 | +116 |
  | health | 86 | 669 | +69 |
  | infrastructure | 90 | 667 | +67 |
  | labor | 99 | 658 | +58 |
  | ecology | 89 | 645 | +45 |
  | nutrition | 87 | 640 | +40 |
  | demography | 83 | 636 | +36 |

  In the serial model (one project per line from 1800, proposed-year order, waiting on cross-line prerequisites), **1,114 of 1,139 items finish after band_high**. The last serial finishes run from 3240 (culture) to 3339 (production). The worst overruns are about 920 years:

  | item | serial finish | band_high |
  |---|---:|---:|
  | `pressure_vessels` | 3339 | 2419 |
  | `mechanical_clutches` | 3331 | 2416 |
  | `metal_annealing_control` | 3325 | 2414 |
  | `pressure_pipe_jointing` | 3319 | 2416 |
  | `yarn_count_standards` | 3319 | 2411 |
  | `bone_ash_porcelain` | 3314 | 2408 |

  The 1200–1800 block had 753 serial overruns. If the engine researches one project per line at a time, this block needs roughly half its current `research_years`, or two to three parallel projects per line. Each node carries `serial_line_finish_year` and `serial_overrun`.

## Longest dependency chains (hard links, counted from year 0)

The deepest items (35 links) continue the institutions trunk of the earlier blocks: writing → alphabet → natural philosophy → `written_office_examinations` → `professional_service`, then either

1. → `petition_registers` → … → `sealed_royal_writs` → `royal_chancery_office` → `chancery_enrolment_rolls` → `fixed_capital_archives` → `sworn_royal_council` → `specialized_royal_councils` → `mercantile_trade_council` → `privileged_crown_manufactories` → **`artisan_emigration_bans`** / **`crown_works_settlements` → `factory_villages`** (earliest feasible 376.5), or
2. → `nine_rank_official_grading` → … → `mirror_for_rulers` → `reason_of_state_treatise` → `sovereignty_doctrine` → `social_contract_doctrine` → `declaration_of_rights` → `single_national_assembly` → **`realm_republic` → `emergency_safety_committee`** / **`abolition_of_estate_privileges` → `estate_bondage_abolition`** (34 links).

The cameral branch (`fixed_court_of_accounts` → `cameral_domain_chambers` → `cameral_science_chairs`) reaches `police_ordinance_science`, `free_grain_trade_edict` and `division_of_labor_doctrine` at 34 links.

## Spot checks used by the game tests

- **`hand_gun_tubes`.** Security 1822, band 1792–1852. Requires `gun_barrel_founding` (production 1812, which requires `black_powder`) and `pot_bolt_guns` (1806).
- **`powder_artillery`.** Security 1848, band 1818–1878. Requires `hand_gun_tubes` and `gun_barrel_founding`; the catalog's `military_staffs` and `precision_machinery` are gone.
- **`regimental_light_guns`** 2062, **`grenadier_companies`** 2138, **`galloping_horse_artillery`** 2326 (requires `regimental_light_guns` and `mounted_firearms`).
- **`preventive_inoculation`.** Health 2302. Requires `variolation_trials` (2244) and `experimental_controls` (2294); no `contagion_mapping`.
- **`steel_refining`.** Production 2282. Requires `cementation_blister_steel` and `coke_firing` (2220).
- **`four_course_rotation`.** Nutrition 2324, band 2279–2369. Requires `three_field_rotation`, `clover_ley_fodder` and `field_turnips`.
- **Maize.** `maize_garden_trials` 1915 and `maize_field_crop` 1970 are `contact_required` and follow `transoceanic_contact_voyages`.

## Bake-time fixes (from `REGISTRY_2400_NOTES.md`)

1. **`hand_cannon` / `hand_cannoneer`** → gate on `hand_gun_tubes` (supersedes the 1200–1800 suggestion of `powder_artillery`).
2. **`grenadier`** → `grenadier_companies`.
3. **`horse_artillery`** → `galloping_horse_artillery`.
4. **`field_artillery`** → `regimental_light_guns`; `bombard_crew` stays on `powder_artillery`.
5. **`powder_artillery`** drops `military_staffs` and `precision_machinery` (the design graph already does; the block's `requires_all` replaces the catalog's).
6. **`preventive_inoculation`** at 2302 without `contagion_mapping`; **`steel_refining`** at 2282.
7. **`mountain_infantry`** is gated on `military_staffs` (2320); review.

## Open items

- **Serial queue pressure.** See *Pacing*: every line exceeds the window, knowledge by 440 years.
- **Bands outside the window.** 147 bands reach outside 1800–2400 by up to 43 years; every proposed year is inside.
