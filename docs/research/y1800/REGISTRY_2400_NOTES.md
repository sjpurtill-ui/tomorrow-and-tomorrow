# Research registry notes: years 1800–2400

`registry_2400.json` holds one canonical entry for each discovery in the twelve `*_1800_2400.md` lists. It uses the same schema as the 0–600 `docs/research/registry.json`, the 600–1200 `docs/research/y600/registry_1200.json` and the 1200–1800 `docs/research/y1200/registry_1800.json`: the same top-level keys, the same per-line count keys, and the same discovery and alias fields and types. Tooling that reads `discoveries` can consume it unchanged.

- **Rebuild:** `python tools/research/build_registry_2400.py`. It reads the lists, all three earlier registries and the game's baked blocks. Catalog ids resolve against `main`, era ids against `origin/codex/era-research-pacing`, and `HISTORICAL_YEAR` and `CURVE` against `origin/codex/research-600`. The baked blocks are every `data/research/research_600.json` and `data/research/blocks/*.json` file on `origin/codex/research-1200`, so a `y1200_1800` block is picked up automatically once it lands. The builder refuses to run if an id appears in two rows without a recorded merge, or if an ownership ruling does not resolve to exactly one row in the owning line.
- **Validate:** `python tools/research/validate_registry_2400.py`. It checks for unique snake_case ids and a schema that matches 0–600 exactly. Every line must have entries, and every target year must fall in 1800–2400 and inside its own band. No id may collide with an id placed, merged or excluded before 1800 unless it is a recorded redate. That covers all three registries, their merged alias slugs and excluded rows, and the game's baked blocks. Every predecessor must resolve, and no belongs-later, belongs-earlier or excluded id may be present. No id or name may use a denylisted real name. The script then runs the cross-line near-duplicate scan and a new scan against the three earlier registries. The current result is **OK**.
- **Timeline:** game 1800 ≈ AD 1360, 2000 = AD 1600, 2400 = AD 1800, following `CURVE` in `technology_eras.gd`.
- **Extra top-level keys:** these are the 1200–1800 set, plus four new ones:
  - `ownership_rulings`: the asserted single owners
  - `still_later_from_1800`
  - `catalog_in_window_unplaced`
  - `for_next_window`

  `window.game_blocks_checked` lists the blocks that were read. Consumers of the 0–600 schema ignore all of these.
- **Predecessors:** every "(continues: id)" note is recorded in `predecessors`: 663 entries and 686 links, 341 of which reach into earlier windows. Every link resolves, and no predecessor is placed later than the item that continues it. The builder adds links that the lists left out; see "Links added".
- **Civic tags:** the `[gov: …]` markers are removed from names and kept in `gov_tags`, with 344 entries: law 126, offices 83, towns 73, court 32, seat 23 and culture 20. The government sections in each file remain the fuller source.

## Counts

The lists contain **1,140** rows, which matches the totals the files state. The result is **1,139** canonical entries, 0 merged aliases and 1 excluded row. Of the canonical entries, 95 carry catalog ids, none carry era ids, 1,044 are new, and 238 are key thresholds.

| Line | Rows listed | Canonical | catalog | era | new | Key thresholds |
|---|---|---|---|---|---|---|
| knowledge | 110 | 110 | 45 | 0 | 65 | 27 |
| institutions | 104 | 104 | 0 | 0 | 104 | 20 |
| culture | 98 | 98 | 0 | 0 | 98 | 15 |
| labor | 99 | 99 | 0 | 0 | 99 | 14 |
| production | 106 | 106 | 19 | 0 | 87 | 21 |
| infrastructure | 90 | 90 | 6 | 0 | 84 | 22 |
| nutrition | 87 | 87 | 3 | 0 | 84 | 16 |
| health | 86 | 86 | 2 | 0 | 84 | 22 |
| demography | 83 | 83 | 0 | 0 | 83 | 20 |
| logistics | 84 | 83 | 2 | 0 | 81 | 20 |
| ecology | 89 | 89 | 7 | 0 | 82 | 16 |
| security | 104 | 104 | 11 | 0 | 93 | 25 |
| **Total** | **1,140** | **1,139** | **95** | **0** | **1,044** | **238** |

Logistics lists one more row than it has entries because `hoop_iron_tyres` is excluded. No row was merged into another line.

## Shared ids: verified single owners

The coordinator's list of ids still shared between lines was checked against the lists' latest text. Every one had already been reduced to a single table row by the list authors, so no merge was needed. The builder now asserts each owner, and these checks are recorded in `ownership_rulings`.

| Id | Owner | Year | Evidence |
|---|---|---|---|
| `coal_grading` | production | 2194 | Production places it as the fuel sort that `coke_firing` requires. Ecology's notes and its too-early table defer to Production. |
| `heated_orangeries` | infrastructure | 2192 | Shared with Nutrition. Nutrition removed its row and keeps the fruit. |
| `mitre_lock_gates` (and `lock_staircases`) | infrastructure | 1908 (2158) | Canal engineering belongs to Infrastructure; canal routes, share companies and tolls belong to Logistics. |
| `enclosure_by_agreement` | ecology | 1935 | This is the only enclosure row. Its statute stage is `assembly_enclosure_acts` (ecology 2326). Nutrition removed its rows. |
| `floated_water_meadows` (and `covered_field_drains`) | ecology | 2050 (2152) | Shared with Nutrition, which removed its rows. |
| `indentured_passage` | labor | 2036 | Shared with Demography, which removed its row. `emigrant_recruiting_agents` (demography 2352) continues it. |
| `veterinary_schools` | ecology | 2332 | Nutrition's `veterinary_school` row is gone. Nutrition's and Health's notes name `veterinary_schools`, so the two are one entry. |
| `capital_police_lieutenant` | security | 2134 | Shared with Institutions, whose notes defer to Security. |
| `turnpike_trust_roads` | infrastructure | 2212 | Shared with Logistics and Institutions. `turnpike_milestones` and `layered_stone_road_beds` continue it. |

**One correction to the coordinator's summary.** The lists do **not** give the drainage items to Production. `drainage_windmills` (1848), `drained_lake_polders` (2036) and `fen_drainage_cuts` (2066) are Infrastructure rows, and the Infrastructure and Ecology ownership notes agree on this. Ecology keeps the water meadows, the buried field drains and drained-land subsidence. Production owns only `coal_grading` among these items. The placements were kept as listed.

**Enclosure exists exactly once.** `landless_wage_laborers` (labor 2344) names enclosure in its text but continued only `cottager_day_laborers`. The builder adds `enclosure_by_agreement` and `assembly_enclosure_acts` as its predecessors.

**Source-list note fixes.** `INSTITUTIONS_1800_2400.md` made three stale claims, and each has been corrected:
- It gave turnpike trusts to Logistics. They are now given to Infrastructure, shared with Logistics and Institutions.
- It gave enclosure acts to "Ecology's and Nutrition's". They are now given to Ecology.
- Its scope line said "Ecology or Nutrition". It now says "Ecology".

## `nitre_beds`: an improvement, renamed

Production `nitre_beds` (1846) is described as "Saltpetre works leach nitre earth and convert the lye with wood-ash potash". The 1200–1800 `nitrate_cultivation` (ecology 1775) is "Heaped nitre beds of dung, lime and earth kept moist and turned", and the leaching itself is `nitre_earth_leaching` (1745). The 1846 row adds a new step: the works that convert the leached lye into saltpetre with potash (≈ AD 1400). It is therefore an **improvement**, not a duplicate.

Its slug, however, names the older practice, so the row is renamed **`potash_saltpetre_works`**. Its predecessors are `nitrate_cultivation` and `nitre_earth_leaching`, and `recrystallised_saltpetre` (2084) now continues the new id. The rename is recorded in `renamed_collisions`. Ecology's ownership note still says `nitre_beds`; read that as this entry. No 2400–3000 list refers to `nitre_beds`.

## Renames for real names (`renamed_collisions`)

| Listed id | Registry id | Why |
|---|---|---|
| `nitre_beds` | `potash_saltpetre_works` | See above |
| `japanned_ware` | `stoved_varnish_ware` | "Japanning" is named for a country. The name is now "Tin and iron ware coated in hard black varnish stoved in an oven". |
| `bone_ash_china` | `bone_ash_porcelain` | "China" as a ware is named for a country, the same ruling as 1200–1800 `kaolin_porcelain`. The name now ends "…a white, strong ware". |
| `flemish_bond_brickwork` | `alternating_bond_brickwork` | "Flemish" names a people. The row name already said "alternating bond". |
| `swede_mangold_roots` | `yellow_turnip_mangold_roots` | "Swede" (the root) is named for a people. The name is now "Yellow winter turnips and mangolds grown as hardier roots". |

The rows' names were edited in `PRODUCTION_1800_2400.md` and `NUTRITION_1800_2400.md`, but their ids were left as listed; the registry id is canonical. Ecology's `great_drowning_flood_marks` also had a name edit: "church walls" became "the walls of the god's houses". No row continues any of the renamed slugs, in this window or in the 2400–3000 lists.

## Denylist

The validator inherits the 1200–1800 denylist and adds early-modern terms:
- confessions and religious orders
- continents, oceans and colonies
- dynasties and polities
- cities and manufactories
- scientists, inventors, engineers, philosophers, writers, composers, painters and navigators
- eponymous units
- trade names such as "prussian blue", "plaster of paris", "leyden jar", "west indies" and "jesuit's bark"

Matching is whole-word only:
- **Tokens:** ids and names are split into `[a-z]+` tokens. A starred stem matches any token that starts with it; an unstarred stem must equal the whole token.
- **Phrases:** multi-word phrases are raw-string regexes that use real `\b` word boundaries.
- **Self-test:** a self-test runs first. It fails if any phrase pattern contains a control character, which guards against the old `focus_bench` bug of a literal backspace in place of `\b`. It also checks that `turk` does not match "turkeys", that `plato` does not match "platoon", that an exact-only word does not prefix-match, and that id tokens are checked.

These words would have matched but are ordinary vocabulary, so they are allowed:
- "attic" (the room)
- "canton" (a recruiting district)
- "encyclopedia"
- "bounty"
- "caesarean" (the operation)
- "platoon"
- "a great fire"
- "a bill of rights"

`plato` is now matched exactly, and "orange", "bow" and "java" are dropped.

## Excluded (1 row)

- **Logistics 2342 `hoop_iron_tyres`** ("Iron hoop tyres shrunk hot onto wheels") duplicates the 600–1200 catalog item `iron_tyre_fitting` (production 800), "Iron tyres shrunk onto wheels". No row continues it.

## Collisions with earlier blocks

- **Collisions:** no id in this block matches an id placed, merged or excluded before 1800. The check covers all three registries, their alias slugs and excluded rows, and the game's `research_600.json` and `blocks/y600_1200.json`.
- **Redates and earlier exclusions:** there are 0 redates and 0 previously excluded ids.
- **Game blocks checked:** `origin/codex/research-1200` at `583f8170` is the ref that was checked. The **1200–1800 block has not landed**: after a fresh `git fetch`, no origin branch contains `data/research/blocks/y1200_1800.json`. The collision check against the 1200–1800 **registry** covers the same ids. Once the block lands, rerun both scripts; they will read it without changes.
- **Other checks:** no NEW slug matches a catalog or era id.

## Belongs-later items from 1200–1800, now placed (42)

| Id | Suggested | Placed |
|---|---|---|
| `powder_artillery` | 1900 | security 1848 |
| `articulated_plate_armor` | 1880 | security 1856 |
| `pike_drill` | 1830 | security 1884 |
| `matchlock_drill` / `gun_line_security` | 1900 | security 1920 / 1926 |
| `naval_gunnery` / `gun_detachment_school` / `mounted_firearms` | 1950 | security 1936 / 1958 / 1976 |
| `rifled_barrels` | 2000 | security 2290 |
| `military_staffs` | 2250 | security 2320 |
| printing and engraving (`burin_engraving`, `copperplate_preparation`, `screw_press_printing`, `oil_based_printing_inks`, `hand_relief_printing`, `metal_type_casting`, `drypoint_printmaking`) | 1858–1917 | knowledge 1858–1917 |
| `polynomial_equations` / `complex_numbers` / `symbolic_algebra` / `measured_kinematics` | 1992–2000 | knowledge 1954 / 1977 / 1992 / 2008 |
| `graphite_marking` | 1971 | knowledge 1971 |
| `bolt_blank_forging` / `flyer_spinning` | 1875 / 1940 | production 1875 / 1940 |
| `steel_refining` | 2210 | production 2282 |
| `multi_spindle_spinning` / `textile_calendering` / `belt_power_transmission` | 2350 | production 2328 / 2344 / 2361 |
| `mine_airways` / `concrete_mix_design` / `concrete_formwork_systems` / `precision_machinery` | 1920–2370 | infrastructure 1925 / 2314 / 2366 / 2371 |
| `dry_dock_services` / `wagonway_haulage` | 1910 / 1950 | logistics 1914 / 1960 |
| `comparative_anatomy`, `relative_stratigraphy`, `habitat_observation_records`, `plant_transpiration_measurement`, `biological_classification`, `biological_reference_collections`, `mineral_cleavage` | — | ecology 1960–2366 |
| `preventive_inoculation` | 2545 | health 2302 |

**Still later.** 15 ids are still later, and all are recorded in `belongs_later`. The years below are the draft 2400–3000 placements:
- **Ecology:** `mineral_streak_tests` (2405), `sediment_provenance`, `comparative_mineral_hardness`, `lithologic_correlation`, `geologic_cross_sections` and `structural_geologic_mapping` (2427–2442), and `soil_assays` (2507).
- **Health:** `slow_sand_filtration` (2411), `water_service_inspections` (2533) and `nursing_care_organization` (2544).
- **Nutrition:** `fermentation_starter_cultures` (2552) and `roller_grain_milling` (2587; the 1200–1800 registry said 2640).
- **Logistics:** `rail_track_foundations` (2485) and `rail_gauge_standards` (2523).
- **Demography:** `child_growth_records` (2667).

`belongs_later` also records these ids:
- **Health:** `contagion_mapping` (2544)
- **Nutrition:** `intensive_gardens` (≈ 2530)
- **Security:**
  - `range_estimation_drill` (2541)
  - `metallic_cartridges`, `armored_hulls`, `naval_torpedoes` and `indirect_fire` (≈ 2555–2665)
- **Knowledge:** `cylinder_press_printing`

`belongs_earlier` repeats the three Production catalog ids that should be redated rather than relisted: `resist_dye_patterning`, `textile_dye_fixation` and `investment_casting_process`.

## Bake-time fixes (required)

These fixes are listed in `bake_time_fixes`. The prerequisite changes are also written into `predecessors`, so the dependency pass sees them.

1. **Hand cannon gate.** Re-gate the `hand_cannoneer` unit (`scripts/military_unit_catalog.gd`) and the `hand_cannon` equipment (`scripts/military_equipment_extension.gd`, and the equipment gate map in `military_unit_catalog.gd`) from `black_powder` to **`hand_gun_tubes`** (security 1822). `hand_gun_tubes` requires `black_powder` (1787), `pot_bolt_guns` (1806) and Production's **`gun_barrel_founding`** (1812). This supersedes the 1200–1800 suggestion to use `powder_artillery`.
2. **Grenadier.** The `grenadier` unit is gated on `matchlock_drill` (1920). Move it to **`grenadier_companies`** (security 2138).
3. **Horse artillery.** The `horse_artillery` unit is gated on `mounted_firearms` (1976). Move it to **`galloping_horse_artillery`** (security 2326).
4. **Field artillery.** The `field_artillery` unit shares the `powder_artillery` gate with `bombard_crew`. Move it to **`regimental_light_guns`** (security 2062). `bombard_crew` stays on `powder_artillery` (1848).
5. **`powder_artillery` requirements.** The catalog requires `black_powder`, `precision_machinery` and `military_staffs` (`society_knowledge_catalog.gd`). **Drop `military_staffs` (placed 2320) and `precision_machinery` (placed 2371)**, and require `black_powder`, `pot_bolt_guns` and `gun_barrel_founding`. Otherwise it cannot open at 1848.
6. **`preventive_inoculation`** is **redated to 2302** as organized variolation (≈ AD 1750); it was belongs-later at 2545. The catalog requires `contagion_mapping` (AD 1854, belongs later at ≈ 2544) and `experimental_controls` (knowledge 2294). **Drop `contagion_mapping`**, and require `variolation_trials` (2244) and `experimental_controls`.
7. **`steel_refining`** sits at **2282** as crucible cast steel; the 1200–1800 suggestion was 2210. The catalog (`civilian_industry.gd`) requires `bloomery_smelting`, `coke_firing` (production 2220) and `precision_thermometry` (knowledge 2228). The year 2282 comes after both; 2210 would have opened before its prerequisites.
8. **`mountain_infantry`** is gated on `military_staffs` (2320). That is acceptable in this window, but the unit lineage says "industrial"; review it at bake time.

## For the next window

- **`cylinder_press_printing` against `steam_cylinder_press`.** The catalog id `cylinder_press_printing` (`printing_knowledge.gd`, AD 1814 ≈ game 2428) gates `cylinder_printed_sheets` and `motor_printed_sheets` (`civilian_industry.gd`) and Printed Sheets (`paper_study.gd`). Knowledge's 2400–3000 list places the same practice as NEW `steam_cylinder_press` (2437), and Production's 2400–3000 list does not relist it. The 2400–3000 registry should use the catalog id for that row, or merge `steam_cylinder_press` into it, so that the existing gates resolve. The detail is recorded in `for_next_window`.

## Near-duplicates reviewed

**Within the block.** The validator lists 27 cross-line candidate pairs, and all are kept separate:
- **`health_passes` and `cattle_health_passes`:** people versus driven cattle.
- **`free_grain_trade_doctrine` (institutions 2316) and `free_grain_trade_edict` (nutrition 2348):** the argument and the edict; the edict already continues the doctrine.
- **`abolition_of_estate_privileges` (institutions 2378) and `estate_bondage_abolition` (labor 2378):** rank privileges versus bondage and labor dues. They are two halves of one decree and may fire together; see `ambiguous`.
- **`quarter_session_justices` (1801) and `quarter_session_wage_hearings` (1804):** the court and its wage function. The builder links the second to the first.
- **`steam_suction_pump` and `street_suction_pumps`:** a steam mine pump versus a street-well pump.
- **`mirror_grid_perspective` (knowledge) and `single_point_perspective_painting` (culture):** a proof versus a painting practice, as the lists intend.
- **The `printed_*_manual` and `printed_*_books` family:** drill, midwifery, dissection, farming, cookery, road books and part books. Each is the print form of its own line's practice.
- **Pairs matched only on a shared word:** `town_printing_houses` / `town_fever_houses`, `post_plague_*`, `crown_works_settlements` / `conditional_crown_settlement`, `bridge_road_engineer_corps` / `engineer_officer_corps`, and the copperplate, calico and type-casting pairs.

**Against earlier registries.** This scan is new. At threshold 0.5 it finds four pairs; each is kept, with the earlier item as predecessor:
- **`arm_flap_nose_repair` (health 1998) → `skin_flap_repair` (728).** The list already linked them.
- **`rubble_mound_breakwaters` (infrastructure 2374) → `rubble_breakwaters` (680).** The names are almost identical. It is kept as the detached offshore breakwater for an open roadstead. Exclude it if the effects pass cannot tell the two apart.
- **`epidemic_season_records` (health 2146) → `epidemic_chronicles` (812).** It is kept as the physician's yearly record of fever seasons.
- **`elected_municipal_councils` (institutions 2380) → `municipal_charters` (1076).**

A pass at 0.4 was also read by eye. Most candidates are already linked. Two predecessors were added from it: `travel_passports` → `sealed_travel_passes` and `debt_sinking_fund` → `funded_public_debt_shares`.

## Links added (`PREDECESSOR_ADD`)

- `potash_saltpetre_works` → `nitre_earth_leaching`
- `landless_wage_laborers` → `enclosure_by_agreement`, `assembly_enclosure_acts`
- `hand_gun_tubes` → `black_powder`, `gun_barrel_founding`
- `powder_artillery` → `black_powder`, `pot_bolt_guns`, `gun_barrel_founding`
- `preventive_inoculation` → `experimental_controls`
- `steel_refining` → `coke_firing`, `precision_thermometry`
- `rubble_mound_breakwaters` → `rubble_breakwaters`; `epidemic_season_records` → `epidemic_chronicles`; `elected_municipal_councils` → `municipal_charters`; `quarter_session_wage_hearings` → `quarter_session_justices`; `travel_passports` → `sealed_travel_passes`; `debt_sinking_fund` → `funded_public_debt_shares`

## Catalog years far from the placement

`catalog_year_gaps` lists 25 catalog ids whose `HISTORICAL_YEAR`, mapped through the curve, is 100 or more game years from where they are placed. Most of them are catalog defaults of AD 1747 (≈ 2294) or obvious curve errors:
- **Catalog year far too early:** `graphite_marking` (400 BC), `bolt_blank_forging` (1000 BC) and `habitat_observation_records` (8000 BC).
- **Deliberately placed earlier than the catalog:** `metal_type_casting` (catalog 2424, placed 1875), `steel_refining` (catalog 2549, placed 2282) and `preventive_inoculation` (catalog 2544, placed 2302).
- **Deliberately placed later than the catalog:** `precision_machinery` (catalog 1792, placed 2371), `military_staffs` (catalog 1772, placed 2320) and `rifled_barrels` (catalog 1917, placed 2290).

When the implementation layer applies these years, it should check what each catalog item is meant to cover.

`catalog_in_window_unplaced` lists 14 catalog ids whose catalog year falls in 1800–2400 but which are not in this block. Eleven are already placed in earlier windows; for example, `soap_manufacture` is at 1625 and `textile_printing` at 1320. The other three are the belongs-earlier dyeing and casting ids. None needs a row here.

## Ambiguous and open

- **Bands:** 147 bands reach outside 1800–2400 by up to 43 years. Every target year is inside the window.
- **1200–1800 block not yet baked:** rerun both scripts after it lands on `origin/codex/research-1200`.
- **Ecology's note on `nitre_beds`** refers to what is now `potash_saltpetre_works`.
- **Source-list edits made by this pass:**
  - `INSTITUTIONS_1800_2400.md`: the three ownership-note fixes.
  - `PRODUCTION_1800_2400.md`: two names.
  - `NUTRITION_1800_2400.md`: one name.
  - `ECOLOGY_1800_2400.md`: one name.
  - No row year, id or band was changed in the lists. Id changes live in the builder's `RENAMES`.
