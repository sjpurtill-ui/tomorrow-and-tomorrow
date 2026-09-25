# Research dependency graph report, years 600–1200

Source: `graph_1200.json`, merged from the three dependency partials (`partials/kicl.json`, `partials/pils.json`, `partials/nhde.json`) by `tools/research/merge_graph_1200.py`. Node attributes (line, name, years, band, research time, key threshold) come from `../registry_1200.json`. Edges run prerequisite → dependent, and a parent may be a 0–600 id from `docs/research/deps/graph.json`. The node format is the one `docs/research/deps/graph.json` uses and `tools/research/build_research_block.py` reads.

## Totals

- **Items:** 964. Every registry id appears exactly once across the partials. No partial row has an unknown id, and no id repeats a 0–600 id. That includes the 22 items the game adopted into its 0–600 block (see *Rejected by the build* below).
  - kicl (knowledge, institutions, culture, labor): 328.
  - pils (production, infrastructure, logistics, security): 332, after dropping `sail_seaming`.
  - nhde (nutrition, health, demography, ecology): 304.
- **Edges:** 2,818.
  - Hard `requires_all`: 1,655.
  - `requires_any` members: 22, in 11 groups.
  - Precedents: 1,141.
- **Cross-line edges:** hard 445, any 15, precedent 442.
- **Cross-block edges (the parent is a 0–600 id):** 1,157 (hard 743, any 2, precedent 412). 295 items have hard or any parents only in 0–600.
- **Items with no requirement:** 0. Every 600–1200 item needs at least one earlier discovery.
- **Key thresholds:** 146.
- **Conditions normalized.** The build's `clean_conditions` runs `list()` on the lists, so they must never be bare strings.
  - `resources_known` is always a list of in-game names. 9 items carry one: Salt ×3, Iron Ore, Lead Ore, Tin Ore, Sulfur, Clay, Limestone.
  - `environment` is always an any-of list (37 items): coast, river, dry, woodland.
  - `contact_required` is a boolean on every node (17 true).
  - `min_settlements` appears on 4 items.
  - No partial used a bare string, but the merge coerces one to a list if it appears.
  - There are no unmapped resources.

## Validation

The merge tool exits without writing anything when a check fails. Every check below passes.

| check | result |
|---|---|
| every referenced id known (this block, the 0–600 graph, or the game's 22 adopted 0–600 items) | pass: 0 unknown |
| no id defined in both blocks | pass |
| combined 0–1200 graph acyclic over hard/any edges | pass |
| combined 0–1200 graph acyclic over all edges including precedents | pass |
| no `requires_all` parent dated after its dependent (adjusted years) | pass: 0 |
| no `requires_any` group entirely later than its dependent | pass: 0 |
| no precedent dated after its dependent | pass: 0 (the 0–600 graph left 49 in place; this block has none) |
| every proposed year inside 600–1200 | pass |

**Watched same-year pairs:**

- **`civic_coin_emblems` / `die_struck_coinage` (both 790).** One-way. Culture's `civic_coin_emblems` hard-requires production's `die_struck_coinage`, and there is no reverse edge. No cycle, so nothing was demoted.
- **`underground_shift_rotation` / `mine_drainage` (both 700).** One-way precedent: labor's shift rotation lists `mine_drainage` as a precedent. No cycle.
- **`axle_sleeve_fitting` / `bloomery_smelting` (both 660).** The only other same-year hard pair. It is also one-way.

Because nothing needed demoting, `DEMOTE` in the merge tool is empty. If a later edit introduces a cycle, add the weaker edge there. It then moves from `requires_all` to `precedents` and is recorded in `meta.demoted_links`.

## Cross-line matrix (hard + any; row = prerequisite line, column = dependent line; includes 0–600 parents)

| from \ to | KNO | INS | CUL | LAB | PRO | INF | NUT | HEA | DEM | LOG | ECO | SEC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| KNO | 146 | 8 | 25 | 9 | 1 | 8 | 4 | 6 | 5 | 6 | 3 | 4 |
| INS | 4 | 127 | 3 | 19 | · | · | · | 5 | 20 | 7 | 2 | 4 |
| CUL | 6 | 2 | 106 | 1 | 1 | 1 | · | 1 | 2 | · | · | · |
| LAB | · | 2 | 4 | 72 | · | · | 1 | 1 | 1 | · | · | 1 |
| PRO | 4 | 2 | 10 | 6 | 124 | 14 | 10 | 10 | · | 15 | 5 | 23 |
| INF | · | · | 7 | 4 | 5 | 100 | 5 | 5 | 1 | 15 | 15 | 14 |
| NUT | 2 | 1 | 2 | 4 | 1 | · | 109 | 2 | 2 | · | 23 | 1 |
| HEA | · | · | · | · | 1 | 2 | 3 | 116 | 5 | · | 4 | · |
| DEM | 1 | 4 | · | 4 | · | · | · | · | 67 | · | · | 1 |
| LOG | 2 | 2 | 1 | 2 | 3 | 8 | 2 | 1 | 1 | 91 | 1 | 12 |
| ECO | · | · | 1 | · | · | · | 11 | 1 | · | 1 | 61 | · |
| SEC | · | · | 3 | 3 | · | · | · | 2 | 2 | · | 1 | 98 |

## Year adjustments

There is one move. `year_adjustments_1200.json` records it, and `build_research_block.py` finds that file next to `graph_1200.json`. The graph already carries the move as `proposed_year`, so the build re-applies it idempotently.

| id | line | year | reason |
|---|---|---|---|
| `textile_rag_pulping` | production | 1095 → 1080 | Rag pulp must come before `paper_making` (1090). The new year is inside the band and near the knowledge alias at 1075. |

The build shifts the band by the same −15, from 1055–1135 to 1040–1120. This resolves the ordering issue that `REGISTRY_1200_NOTES.md` flagged. The nhde partial had no adjustments, and kicl has no adjustment file.

## Registry fixes made with this merge

- `urnfield_cremation` was renamed `cremation_urn_cemeteries` in `CULTURE_600_1200.md`, the kicl partial and `CULTURE_DEPENDENCIES_1200.md`. The regenerated `registry_1200.json` carries the new id. The builder's ambiguity note for the old id is gone, so the rename survives a rebuild.
- `BRIEF.md` now gives game 1200 ≈ AD 360. That is the brief's own interpolation, 800→1500 as 500 BC→AD 1000; it previously said AD 570.

## Rejected by the build, fixed at the source

The first `build_research_block.py` run failed with `ERROR: id already defined in an earlier block: sail_seaming`.

- **The duplicate.** The game's 0–600 block adopts `sail_seaming` at logistics 280, from `tools/research/design_amendments_600.json` on `codex/research-1200`. That adoption is not in `docs/research/deps/graph.json`, so the 600–1200 registry listed the same catalog id again at 630.
- **The fix.** The 630 row is now excluded as a duplicate in `build_registry_1200.py` `EXCLUDE`, and its partial row is dropped. `brailed_square_sail` (650) keeps its requirement, which now resolves to the 0–600 item.
- **The guard.** `merge_graph_1200.py` now reads the adopted items from `origin/codex/research-1200` too. A later collision of this kind fails the merge instead of the game build.

## Aligned with the game's authored mathematics and mechanics overlays

The game's `mathematics_knowledge.gd` and `mechanics_knowledge.gd` author some of this block's catalog ids. They declare foundations and model routes that the design replaced, and the game's contract tests flagged three conflicts. The design partials now keep those links:

| item | change | why |
|---|---|---|
| `ratio_proportion` (893) | adds hard `fractional_quantities` (0–600, 520) | Ratios build on named fractions, the authored foundation. |
| `similar_triangles` (895) | adds hard `straightedge_compass` (780) | Similarity is proved by construction, the authored foundation. |
| `compound_pulleys` (917) | hard `lever_moments` (916); `counterweight_cranes` (895) moves from hard to precedent | The mechanics model speeds `counterweight_cranes` with compound pulleys, so compound pulleys requiring the crane made that model circular. |

## Pacing

- **Impossible (critical-path earliest year > band_high): 0.**
- **Gates do not hold the era back.** Hard and any links alone make every item reachable long before 600. The critical path from year 0 has a median of 12% of band_low, and the deepest item is reachable by year 265. Items stay inside the 600–1200 window only because the loader applies `min_year = band_low`, together with research throughput and conditions.
- **Queue pressure is the real constraint.** Total `research_years` per line is over the 600-year window in 7 lines:

  | line | research years |
  |---|---:|
  | knowledge | 811 |
  | security | 790 |
  | health | 685 |
  | production | 679 |
  | infrastructure | 667 |
  | logistics | 625 |
  | nutrition | 627 |
  | institutions | 586 |
  | demography | 564 |
  | culture | 537 |
  | labor | 516 |
  | ecology | 501 |

  In the serial model, one project runs per line from year 600, items are taken in proposed-year order (same-year prerequisites first), and an item waits for its cross-line prerequisites. Under that model 597 of 964 items finish after band_high.

  | line | items late |
  |---|---:|
  | security | 86 |
  | production | 69 |
  | knowledge | 64 |
  | logistics | 60 |
  | labor | 58 |
  | culture | 57 |
  | nutrition | 39 |
  | health | 39 |
  | infrastructure | 39 |
  | institutions | 37 |
  | ecology | 33 |
  | demography | 16 |

  The last serial finishes are health 1471, security 1462, culture 1446 and knowledge 1438. The worst overruns are about 265 years:

  | item | serial finish | band_high |
  |---|---:|---:|
  | `permanent_frontier_fortresses` | 1370 | 1102 |
  | `long_service_enlistment` | 1332 | 1066 |
  | `horned_riding_saddle` | 1286 | 1022 |
  | `force_pump_fire_engines` | 1356 | 1092 |

  If the engine researches one project per line at a time, this block needs shorter `research_years` or parallel projects. The 0–600 block had the same problem at a smaller scale (225 overruns). Each node carries `serial_line_finish_year` and `serial_overrun`.

## Longest dependency chains (hard/any links, counted from year 0)

1. **sky_tables_compendium**: 23 links, earliest feasible 264.5. The path runs through the alphabet and geometry: fiber_grading (4) → … → standard_sign_lists (280) → phonetic_notation (360) → consonantal_alphabet (560) → abecedary_letter_order (628) → adapted_alphabet_borrowing (700) → full_vowel_alphabet (740) → natural_philosophy_schools (800) → demonstrated_geometry (815) → incommensurable_lengths (840) → ratio_proportion (893) → similar_triangles (895) → axiomatic_geometry_compendium (899) → armillary_sphere (952) → star_position_catalogue (976) → sky_tables_compendium (1108).
2. **compiled_rescript_code**: 23 links, 249.5. The same trunk to natural_philosophy_schools (800), then → authored_prose_treatises (820) → public_libraries (896) → endowed_scholar_house (900) → state_official_academy (975) → written_office_examinations (980) → professional_service (1115) → petition_registers (1122) → compiled_rescript_code (1172).
3. **mechanical_treatises**: 23 links, 245.5. It follows the geometry trunk → displacement_buoyancy (918) → hydrostatic_pressure (924) → mechanical_treatises (1060).
4. **scaled_grid_mapping**: 23 links, 244.5. It follows the geometry trunk → earth_circumference_measure (920) → latitude_zones (972) → coordinate_gazetteer_maps (1105) → scaled_grid_mapping (1150).
5. **wooden_sheave_blocks** has 23 links. It now reaches the geometry trunk through `lever_moments` → `compound_pulleys`.
6. **star_position_catalogue**, **geared_sky_calculator**, **syncopated_algebra**, **ground_tremor_detector**, **notarized_work_contracts** and **nine_rank_official_grading** each have 22 links. All of them sit on the same writing → alphabet → natural philosophy trunk.

The written-alphabet trunk (`consonantal_alphabet` → `full_vowel_alphabet` → `natural_philosophy_schools`) gates most of the late knowledge and institutions content. A civilization that stalls there loses most of those lines after about 800.

## Spot checks used by the game tests

- **`glass_blowing`.** Proposed year 1010, band 975–1045. It requires `mandrel_wound_beads` and `decolorized_clear_glass`.
- **`bloomery_smelting`.** Proposed year 660, band 660–690. It requires 0–600 `shaft_furnaces` and `clay_tuyere_draft`, and needs Iron Ore known.

## Open items

- **Iron floor (fixed at the source).** The game's 0–600 block redated the iron items to no earlier than 660, and `BRIEF.md` says iron smelting begins around game 660. A designed item's `min_year` is its `band_low`, which overrides a redate, so the list bands would have let iron open at 640–655. `PRODUCTION_600_1200.md` now floors band_low at 660 for `bloomery_smelting`, `iron_assaying`, `bloomery_charge_control` and `forge_welding`. Their target years are unchanged.
- **Other redated ids that open earlier than before.** The 0–600 block also redates 7 other ids that this block now designs. Their band_low is below the old redate:

  | id | band_low | old redate |
  |---|---:|---:|
  | `masonry_arch_centering` | 595 | 620 |
  | `professional_corps` | 630 | 660 |
  | `galley_navigation` | 622 | 660 |
  | `naval_arsenals` | 624 | 660 |
  | `axle_sleeve_fitting` | 620 | 670 |
  | `amphibious_operations` | 628 | 700 |
  | `grain_milling` | 765 | 800 |

  They are left as designed. `axle_sleeve_fitting` still waits for iron through its prerequisite `bloomery_smelting`.
- **Serial queue pressure.** See *Pacing*. `research_years` totals exceed the window in 7 lines.
