# Research registry notes: years 1200–1800

`registry_1800.json` holds one canonical entry for each discovery in the twelve `*_1200_1800.md` lists. It uses the same schema as the 0–600 `docs/research/registry.json` and the 600–1200 `docs/research/y600/registry_1200.json`: the same top-level keys, the same per-line count keys, and the same discovery and alias fields and types. Tooling that reads `discoveries` can consume it unchanged.

- **Rebuild:** `python tools/research/build_registry_1800.py`. It reads the lists, both earlier registries and the game's baked blocks. Catalog ids resolve against `main`, era ids against `origin/codex/era-research-pacing`, and `HISTORICAL_YEAR` and `CURVE` against `origin/codex/research-600`. The baked blocks are `data/research/research_600.json` and `data/research/blocks/y600_1200.json` on `origin/codex/research-1200`.
- **Validate:** `python tools/research/validate_registry_1800.py`. It checks for unique snake_case ids and a schema that matches 0–600 exactly. Every line must have entries, and every target year must fall in 1200–1800 and inside its own band. No id may collide with an id placed before 1200 unless it is a recorded redate. That covers both registries, their merged alias slugs and excluded rows, and the 22 items adopted into the game's 0–600 block that the 0–600 registry never listed. Every predecessor must resolve, and no belongs-later or belongs-earlier id may be present. No id or name may use a denylisted real name. The denylist extends the 600–1200 list with late-antique and medieval peoples, polities, places, persons, religious orders and texts, plus phrases such as "china clay" and "silk road". The script then re-runs the cross-line near-duplicate scan. The current result is **OK**.
- **Timeline:** game 1200 ≈ AD 360, 1500 ≈ AD 1000, 1800 ≈ AD 1360, following `CURVE` in `technology_eras.gd`.
- **Extra top-level keys:** `window`, `predecessors`, `merge_alias_ids`, `merges`, `line_reassignments`, `renamed_collisions` (empty), `redates`, `previously_excluded_now_placed`, `placed_from_1200_belongs_later`, `excluded_rows`, `belongs_later`, `belongs_earlier`, `catalog_year_gaps`, `bake_time_fixes`, `gov_tags`, `new_slugs_matching_catalog` (empty) and `ambiguous`. Consumers of the 0–600 schema ignore them.
- **Predecessors:** every "(continues: id)" note is recorded in `predecessors`, 300 entries in all, and every one resolves. The builder also adds two links the lists left out: `hearth_tax_counts` → `hearth_counts`, and `foreign_merchant_quarters` → `merchant_quarters_abroad`. No predecessor is placed later than the item that continues it.
- **Civic tags:** the `[gov: …]` markers in the Culture and Institutions tables are removed from names and kept in `gov_tags` (89 entries) for the civic-evolution pass. The government lists in each file's notes remain the fuller source.

## Counts

The lists contain **945** rows, which matches the total each file states. The result is 937 canonical entries, 6 merged aliases and 2 excluded rows. Of the canonical entries, 32 carry catalog ids, none carry era ids, 905 are new, and 159 are key thresholds.

| Line | Rows listed | Canonical | catalog | era | new | Merged into another line |
|---|---|---|---|---|---|---|
| knowledge | 84 | 84 | 6 | 0 | 78 | 0 |
| institutions | 92 | 92 | 1 | 0 | 91 | 0 |
| culture | 80 | 80 | 0 | 0 | 80 | 0 |
| labor | 86 | 86 | 0 | 0 | 86 | 0 |
| production | 89 | 89 | 13 | 0 | 76 | 0 |
| infrastructure | 71 | 72 | 5 | 0 | 67 | 0 |
| nutrition | 75 | 72 | 0 | 0 | 72 | 1 |
| health | 72 | 72 | 0 | 0 | 72 | 0 |
| demography | 71 | 70 | 0 | 0 | 70 | 1 |
| logistics | 73 | 72 | 2 | 0 | 70 | 0 |
| ecology | 75 | 72 | 1 | 0 | 71 | 3 |
| security | 77 | 76 | 4 | 0 | 72 | 1 |
| **Total** | **945** | **937** | **32** | **0** | **905** | **6** |

Three lines do not balance on their own row counts:
- Infrastructure has one entry more than it listed, and Logistics one fewer, because `canal_locks` moved from Logistics to Infrastructure.
- Nutrition's 75 rows became 72 entries: 1 row merged into Labor and 2 rows excluded.

## Coordinator conflicts, resolved

- **`craft_guilds`:** only Institutions lists it now, at 1583, following the catalog direction (Society). The Labor table no longer has a row for it; Labor's notes defer to Institutions, and `guild_trade_monopoly` (1600) continues it. Institutions' own overlap note still told the integrator to "drop the Labor row". That sentence has been corrected in `INSTITUTIONS_1200_1800.md`. The 600–1200 registry had excluded Labor's 935 row as belongs later with a suggested year of 1540. It is recorded under `previously_excluded_now_placed`.
- **`canal_locks`:** owned by **Infrastructure**, kept at Logistics' year of 1493, and shared with Logistics. The catalog direction is Infrastructure (`society_knowledge_catalog.gd`), Logistics deferred the choice of line to the registry, and this matches the `craft_guilds` rule. Its predecessor is `flash_lock_gates`. The move is recorded in `line_reassignments`.
- **`plague_cordons`:** merged into Health `pestilence_gate_watch` (1792), which now has a single entry. The Security row (1799) is kept as its alias, and the entry is shared with Security. Security's public-safety chain in its key thresholds still names "plague cordons (1799)"; read that as this entry.
- **Owner of `manumission_charters` and `town_residence_freedom`:** these are Labor rows, at 1495 and 1616. Three sentences in `INSTITUTIONS_1200_1800.md` said Demography, at 1395 and 1610. They now say Labor, with the correct years.
- **`military_staffs`:** Institutions' "too early / too late" table calls it "Security line; within this window". Security places it later (≈ 2200–2300). No table row places it, so it is recorded as belongs later. See the bake-time fixes below.

## Bake-time fixes (required)

These are listed in `bake_time_fixes`.

1. **Gunpowder gate.** `black_powder` is placed at 1787 as chemistry only. On `main`, two things are gated on it: the `hand_cannoneer` unit (`scripts/military_unit_catalog.gd`) and the `hand_cannon` equipment (`scripts/military_equipment_extension.gd`). With those gates, generals would get a gun in this window. At bake time, re-gate both on a later gunpowder-weapon discovery such as `powder_artillery`, which belongs at ≈ 1880–1920.
2. **`powder_artillery` requirements.** The catalog requires `black_powder`, `precision_machinery` and `military_staffs`. `military_staffs` belongs at ≈ 2200–2300 and `precision_machinery` at ≈ 2370, so `powder_artillery` could not open near its ≈ 1880–1920 target. The dependency pass should drop or replace the `military_staffs` requirement, and `precision_machinery` as well.
3. **`ocean_sailing` redate.** This item was adopted into the game's 0–600 block at security 560, where it gates sailing-warship equipment. It is redated here to 1692. When this block is baked, the earlier placement and its equipment gates must move with it.

## Duplicates merged (6 rows into 6 entries)

Merges follow the earlier rules. The canonical row keeps its own line, year and band. The alias row is kept in `aliases` and its slug in `merge_alias_ids`. The alias's line joins `shared_with`, and its predecessors are carried over.

| Canonical id | Kept in | Merged row | Why |
|---|---|---|---|
| `pestilence_gate_watch` | health 1792 | security `plague_cordons` 1799 | Coordinator ruling: the cordon is the armed side of the gate watch |
| `ridge_furrow_strips` | nutrition 1438 | ecology `ridge_furrow_drainage` 1425 | Same practice; Nutrition's notes claim it ("stays here") |
| `mutual_surety_tithings` | institutions 1540 | demography `mutual_surety_households` 1558 | Groups of ten households that answer for each other |
| `coney_warrens` | nutrition 1615 | ecology `rabbit_warrens` 1612 | Nutrition keeps warrens; Ecology keeps only `warren_escape_liability` |
| `protected_drove_routes` | nutrition 1728 | ecology `chartered_sheepwalks` 1722 | Same long-distance flock routes; Nutrition's notes claim them |
| `communal_house_workshops` | labor 1268 | nutrition `enclosed_community_farms` 1268 | Same year, same walled farm-and-workshop precinct of a communal house |

The agents deduplicated while racing each other, so a full check was run again: every pair of rows in different lines was compared by exact id, shared id stems and overlap of name words. All 945 rows were also read by eye for duplicates in meaning. Ecology's key thresholds still name ridge-and-furrow drainage (1425), rabbit warrens (1612) and chartered sheepwalks (1722). Read those as the merged entries.

**Near-duplicate candidates reviewed and kept separate.** The validator lists 13 pairs:
- **`mill_fulling_crews` (labor 1592) and `fulling_mills` (production 1558).** The crews are the labor consequence of the machine, and they should require `fulling_mills`.
- **`craft_guilds` and `womens_craft_guilds`**, and **`merchant_guild_monopoly` and `guild_trade_monopoly`:** a craft guild versus a women's guild, and a merchant guild versus a craft guild.
- **`revised_town_statute_books` (institutions 1702) and `town_trade_statute_book` (labor 1712):** town law versus guild statutes.
- **`pointed_arch_glass_temples` (culture) and `pointed_arches` (infrastructure):** a building type versus a technique, as the lists intend.
- **`leaded_stained_glass` (production) and `house_glass_windows` (infrastructure):** figured glass in great halls versus plain glazing in houses.
- **`street_filth_ordinances` (health) and `river_offal_bans` (ecology):** the street versus the river, split on purpose.
- **Pairs matched only on a shared word:** `sworn_town_commune` / `sworn_town_midwives`, `illustrated_farm_treatise` / `illustrated_surgery_treatise`, `free_miner_companies` / `free_mercenary_companies`, `bound_estate_tenants` / `estate_bound_craftsmen`, `rag_chain_mine_pumps` / `paddy_chain_pumps` and `letter_writing_art` / `brush_writing_fine_art`.

## Collisions with earlier blocks

- **Redate: `ocean_sailing`.** The game's 0–600 block has it at security 560, as an item adopted through `design_amendments_600.json`; the 0–600 registry never listed it. Here it is placed at security 1692. It is the only redate. The 600–1200 registry had marked it belongs later (suggested 1650).
- **Previously excluded, now placed:** `craft_guilds` (labor 935 in 600–1200, excluded as belongs later). It is placed here at institutions 1583.
- **Excluded as duplicates of 600–1200 items:**
  - Nutrition 1494 `fallow_sheepfolding`, "Sheep folded on the fallow to dung it", duplicates `night_folding_on_fallow` (ecology 750).
  - Nutrition 1696 `marl_lime_dressing`, "Fields marled and limed against sour soil", duplicates `liming_sour_soils` (ecology 1055).
  - No row continued either item.
- **Kept, with the earlier item as predecessor:**
  - `hearth_tax_counts` (1430) builds on 0–600 `hearth_counts` (170) as a tax assessment.
  - `foreign_merchant_quarters` (1500) builds on 600–1200 `merchant_quarters_abroad` (525) as the walled, privileged quarter under its own headman.
- **Other checks:** no alias slug or NEW slug matches an earlier id or a catalog id. `sail_seaming` and the other 21 adopted game items do not recur.

## Belongs-later items from 600–1200, now placed

| Id | Suggested | Placed |
|---|---|---|
| `mounted_remount_school` | 1250 | security 1250 |
| `clinker_shell_construction` | 1300 | logistics 1340 |
| `relief_block_cutting` / `printing_process` | 1360 | knowledge 1355 / 1360 |
| `chemical_distillation` | 1400 | knowledge 1407 |
| `canal_locks` | 1490 | infrastructure 1493 |
| `spinning_wheels` | 1500 | production 1498 |
| `movable_type_composition` | 1520 | knowledge 1533 |
| `carvel_frame_construction` | 1300 | logistics 1540 |
| `craft_guilds` | 1540 | institutions 1583 |
| `counterweight_engines` | 1670 | security 1667 |
| `ocean_sailing` | 1650 | security 1692 (redate) |
| `optical_lenses` | 1630 | knowledge 1733 |
| `wooden_movable_type` | 1520 | knowledge 1746 |

Still later: `pike_drill`, `steel_refining`, `habitat_observation_records`, `comparative_anatomy` and `biological_classification`.

The two largest departures from the suggestions:
- **`carvel_frame_construction`** is placed at 1540 rather than 1300. Frame-first hulls are established by about AD 1000.
- **`wooden_movable_type`** is placed at 1746 rather than 1520. The AD 1040 type was clay, which `movable_type_composition` (1533) covers, and carved wooden type dates from about AD 1297.

## Outside the block

- **Belongs later.** There are 57 ids, all in the catalog; see `belongs_later` for suggested years.
  - **Security:** `pike_drill`, `powder_artillery`, `military_staffs`, `articulated_plate_armor`, and the gun items `gun_line_security`, `matchlock_drill`, `naval_gunnery`, `rifled_barrels`, `gun_detachment_school` and `mounted_firearms`.
  - **Production:** `steel_refining`, `flyer_spinning`, `bolt_blank_forging`, `textile_calendering`, `multi_spindle_spinning` and `belt_power_transmission`.
  - **Knowledge:**
    - printing: `hand_relief_printing`, `screw_press_printing`, `oil_based_printing_inks` and `metal_type_casting`
    - engraving: `burin_engraving`, `copperplate_preparation` and `drypoint_printmaking`
    - mathematics: `symbolic_algebra`, `polynomial_equations`, `complex_numbers` and `measured_kinematics`
    - `graphite_marking`, at ≈ 1971. The 600–1200 list's ≈ 1760 was a curve error.
  - **Infrastructure:** `precision_machinery`, `mine_airways`, `concrete_formwork_systems` and `concrete_mix_design`.
  - **Logistics:** `dry_dock_services`, `wagonway_haulage`, `rail_gauge_standards` and `rail_track_foundations`.
  - **Ecology:**
    - natural-history forms: `habitat_observation_records`, `comparative_anatomy`, `biological_classification`, `plant_transpiration_measurement` and `biological_reference_collections`
    - geology: `relative_stratigraphy`, `geologic_cross_sections`, `lithologic_correlation`, `structural_geologic_mapping` and `sediment_provenance`
    - mineral and soil tests: `mineral_cleavage`, `mineral_streak_tests`, `comparative_mineral_hardness` and `soil_assays`
  - **Health:** `preventive_inoculation`, `nursing_care_organization`, `slow_sand_filtration` and `water_service_inspections`.
  - **Nutrition:** `fermentation_starter_cultures` and `roller_grain_milling`.
  - **Demography:** `child_growth_records`.
  - **Later practices without catalog ids.** The lists also name practices that have no catalog id, so they are not recorded:
    - forty-day quarantine, variolation and obstetric forceps
    - the sea astrolabe, full-rigged ships, wind-pumped polders, hammer-beam roofs, bombards and the fire lance
- **Belongs earlier.** These catalog entries should be redated in the catalog, not relisted:
  - `resist_dye_patterning`, practised as `resist_dyeing` (600–1200: 905)
  - `textile_dye_fixation`, practised as `alum_mordant_dyeing` (0–600: 530)
  - `investment_casting_process`, practised as `lost_wax_casting` (0–600: 195)

## Catalog years far from the placement

`catalog_year_gaps` lists 13 catalog ids whose `HISTORICAL_YEAR`, mapped through the curve, is 100 or more game years from where they are placed:

| Id | Placed | Catalog year on the curve |
|---|---|---|
| `relief_block_cutting` / `printing_process` | 1355 / 1360 | 1082 |
| `ratchet_motion_control` | 1210 | 893; never placed before 1200 |
| `textile_printing` | 1320 | 2294 |
| `cam_motion_design` | 1545 | 2360 |
| `soap_manufacture` | 1625 | 2294 |
| `masonry_buttressing` | 1550 | 2294 |
| `carvel_frame_construction` | 1540 | 1833 |
| `wooden_movable_type` | 1746 | 1533 |
| `nitrate_cultivation` | 1775 | 1500 |
| `black_powder` | 1787 | 1500 |
| `mounted_remount_school` | 1250 | 2400 |
| `ocean_sailing` | 1692 | 520 |

When the implementation layer applies these years, it should check what each catalog item is meant to cover.

## Ambiguous and open

- **Soldier-settled frontier districts.** Security `military_district_settlement` (1245), Institutions `military_frontier_provinces` (1322) and Demography `soldier_farmer_holdings` (1340) are three stages of the same frontier system. They are kept separate as settlement, governorship and hereditary holdings. Merge them if their effects turn out to be the same.
- **`communal_house_workshops`** absorbed Nutrition's `enclosed_community_farms`. Split it again only if the effects pass needs a separate item for food output.
- **`protected_drove_routes`** absorbed Ecology's `chartered_sheepwalks`. Ecology's government list gives the sheepwalks a civic change: a flock-owners' council with its own judges on the drove routes. That change now belongs to the merged entry.
- **Names changed in the source lists:**
  - Production `kaolin_porcelain` was "True porcelain from white china clay and china stone". It is now "…white porcelain clay and porcelain stone", because "china" in "china clay" is a country name. The id is unchanged; "kaolin" is kept as a standard mineral term.
  - "silk" is ordinary vocabulary in this window, so the denylist now checks only the trade-route phrase.
- **Bands:** 117 bands reach outside 1200–1800 by up to 43 years. Every target year is inside the window.
- **Source-list edits made by this pass:**
  - `INSTITUTIONS_1200_1800.md`: the owner fixes for manumission and town-residence freedom, and the `craft_guilds` sentence.
  - `PRODUCTION_1200_1800.md`: the porcelain name.
  - No row year, id or band was changed.

## Related but kept separate (likely prerequisite links)

- **Mills and their labor:** `fulling_mills` → `mill_fulling_crews`; `mill_suit_obligation` with the Production mills; `mill_leats` with `mill_dam_height_limits`.
- **Hospitality and care on the road:** `pass_hospices` (logistics) and `road_hostel_infirmaries` (health).
- **Glass:** `leaded_stained_glass` → `house_glass_windows`; `potash_forest_glass` → `itinerant_forest_glassworks`.
- **Guilds:** `prefect_guild_rulebook` → `craft_guilds` → `guild_trade_monopoly` → `town_trade_statute_book` → `guild_council_seats`; `revised_town_statute_books` runs alongside.
- **Counting:** `decimal_unit_census` (demography) and `decimal_army_organization` (security); `hearth_tax_counts` → `adult_poll_rolls`.
- **Dikes:** `dike_duty_lengths` (labor) → `dike_boards` (ecology); `estuary_embankments` and `self_closing_tide_gates` (infrastructure) → `sluiced_polders` (ecology).
- **Nitre and powder:** `nitre_earth_leaching` → `nitrate_cultivation` → `black_powder`; `nitre_incendiary_mixtures` runs alongside.
- **Distillation:** `chemical_distillation` → `distilled_herb_waters` (health), `distilled_spirits` (nutrition) and `mineral_acid_distillation` → `acid_gold_parting`.
- **Lenses:** `optical_lenses` → `reading_spectacles` (health).
- **Death and the land after mass mortality:** `deserted_village_pasture` (demography) and `marginal_land_retreat` (ecology), which have different causes; `post_plague_labor_statutes` and `laborer_mobility` (labor).
