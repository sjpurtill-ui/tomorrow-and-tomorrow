# Research registry notes: years 2400–3000

`registry_3000.json` holds one canonical entry for each discovery in the twelve `*_2400_3000.md` lists. This is the last window: game 2400–3000, about AD 1800–2030, the end of the game. It uses the same schema as the four earlier registries: `docs/research/registry.json` (0–600), `y600/registry_1200.json`, `y1200/registry_1800.json` and `y1800/registry_2400.json`. The top-level keys, per-line count keys, and discovery and alias fields and types are the same. Tooling that reads `discoveries` can consume it unchanged.

- **Rebuild:** `python tools/research/build_registry_3000.py`. It reuses the parsing and reference helpers of `build_registry_2400.py`. It reads the lists, all four earlier registries (canonical ids, merged alias slugs, excluded rows and renamed slugs) and every baked block on `origin/codex/research-1200` (`data/research/research_600.json` and `data/research/blocks/*.json`). Refs:
  - catalog ids resolve against `main` (`scripts/*.gd`, and `scripts/*_knowledge.gd` for coverage);
  - era ids resolve against `origin/codex/era-research-pacing`;
  - `HISTORICAL_YEAR` and `CURVE` resolve against `origin/codex/research-600`.
- **Validate:** `python tools/research/validate_registry_3000.py`. The current result is **OK**, with 0 errors. It checks:
  - unique snake_case ids and a schema identical to 0–600;
  - every target year in 2400–3000 and inside its own band;
  - the row accounting (listed = canonical + aliases + excluded);
  - no collision with any id placed, merged, excluded or renamed before 2400, **including `registry_2400.json`** and the game's baked blocks;
  - every predecessor resolves to a live canonical id, not a renamed, excluded or alias slug;
  - the ids replaced by this pass are gone;
  - `[gov:]` tags use the normalised vocabulary;
  - no catalog id from AD 1800 on is unplaced;
  - the real-name denylist.

  It also prints the near-duplicate candidates, in-window and against 1800–2400, and the research-pace flags.
- **Denylist:** `tools/research/denylist_modern.py`. It extends the committed 1800–2400 denylist (`validate_registry_2400.py`) with modern entries:
  - countries, peoples, cities and rivers;
  - persons and eponyms, such as diesel\*, pasteur\*, galvan\*, vulcan\*, morse, bessemer, the SI-unit surnames, tsar\* and victorian\*;
  - firms, brands and trade names;
  - agencies and treaties;
  - events, plus phrases such as "second world war", "red cross", "geneva convention", "silicon valley" and "portland cement".

  Matching uses whole words. An id is split on `_` and checked the same way as a name. A starred stem is a prefix match unless it is listed in `EXACT_ONLY`. That list names the ordinary word each exact-only entry protects: germanium, franking, galena, rhodium, delphinium, japanning, celt and vandalism. "industry" is safe because `indus` is exact-only in the 0–600 list. "marshalling" is safe because `marshall` is exact, and "voltage" is in `ALLOWED_TERMS`. A self-test runs first. It asserts these false positives stay clean and the real names are caught. **This denylist is stricter than the 1800–2400 one in two places:** "galvan" is a prefix again, and "caesarean" is not allowed.
- **Timeline:** game 2400 ≈ AD 1800, 2600 ≈ 1875, 2800 ≈ 1950 and 3000 = AD 2030, from `CURVE`.
- **Extra top-level keys:**
  - `window` and `predecessors`;
  - `merge_alias_ids`, `merges` and `line_reassignments`, which are all empty;
  - `resolved_duplicates`, `renamed_collisions` (empty), `source_list_fixes`, `name_fixes`, `note_fixes`, `rows_added_by_registry` and `real_name_id_exceptions`;
  - `redates` and `previously_excluded_now_placed`, which are both empty;
  - `placed_from_2400_belongs_later`, `belongs_later_still_unplaced`, `for_next_window_from_2400` and `deferred_to_earlier_windows`;
  - `excluded_rows`, `belongs_later` (empty, since this is the end of the game) and `belongs_earlier`;
  - `catalog_coverage`, `catalog_year_gaps` and `pace`;
  - `bake_time_fixes`, `gov_tag_normalisation`, `gov_tags`, `new_slugs_matching_catalog` (empty) and `ambiguous`.
- **Predecessors:** 364 entries carry 377 links. Every "(continues: id)" in the lists resolves. The builder adds these links:
  - `steam_pumped_waterworks` → `steam_waterworks`;
  - `game_warden_licences` → `game_bird_close_seasons`, replacing the excluded row;
  - `orbital_satellite_launch` becomes a predecessor of the reconnaissance, weather, relay, ship-navigation and launch-warning satellites.

## Counts

The lists hold **1576** rows: 1565 as written, plus 5 added by this pass and 6 gap rows added by the follow-up pass. They give 1575 canonical entries and 1 excluded row, with no merged aliases. Of the canonical entries, 440 carry catalog ids, 1135 are new, none are era ids, and 274 are key thresholds.

| Line | Rows listed | Canonical | catalog | era | new | Merged into another line |
|---|---|---|---|---|---|---|
| knowledge | 143 | 143 | 99 | 0 | 44 | 0 |
| institutions | 100 | 100 | 0 | 0 | 100 | 0 |
| culture | 100 | 100 | 0 | 0 | 100 | 0 |
| labor | 110 | 110 | 2 | 0 | 108 | 0 |
| production | 278 | 278 | 220 | 0 | 58 | 0 |
| infrastructure | 111 | 111 | 25 | 0 | 86 | 0 |
| nutrition | 124 | 124 | 36 | 0 | 88 | 0 |
| health | 126 | 126 | 11 | 0 | 115 | 0 |
| demography | 100 | 100 | 1 | 0 | 99 | 0 |
| logistics | 128 | 128 | 4 | 0 | 124 | 0 |
| ecology | 126 | 125 | 15 | 0 | 110 | 0 |
| security | 130 | 130 | 27 | 0 | 103 | 0 |
| **Total** | **1576** | **1575** | **440** | **0** | **1135** | **0** |

- Ecology lists 126 rows but has 125 entries, because one row is excluded.
- Logistics was 124 rows and is now 128, with its 4 spaceflight rows.
- Ecology was 125 rows and is now 126, with `developmental_stage_series`.
- Knowledge's catalog count went from 98 to 99, because its press row now carries the catalog id.
- 13 end-of-game rows are marked speculative or speculative-plausible. None is science fiction.

## Known issues, resolved

1. **The treaty protecting the wounded.** Health's `neutral_wounded_convention` (2571, shared with Security) is kept. Security's list had already dropped its own `wounded_protection_convention` and defers to Health. Institutions' overlap note still named both; it now names Health's only. Because the Security row was gone before the build, no alias row is left. The ruling is recorded in `resolved_duplicates`.
2. **`river_fish_kills`.** Infrastructure's overlap note named it as an Ecology item of this window. It is the 1800–2400 Ecology row `town_river_fish_kills` (2388), and the note now says so. No row continued the wrong id.
3. **`cylinder_press_printing`.** Knowledge's row at 2437, NEW `steam_cylinder_press`, now carries the catalog id `cylinder_press_printing` (`printing_knowledge.gd`, AD 1814). Its status is catalog, and the catalog gates `cylinder_printed_sheets` and `motor_printed_sheets` resolve. The references in Knowledge's and Production's notes were updated. The 1800–2400 registry's `for_next_window` item is marked resolved.
4. **`[gov:]` tag names.** These now use the 1800–2400 plural forms:
   - `office` becomes **`offices`** (60 tags);
   - `civic` becomes **`towns`** (11 tags).

   The tags were rewritten in all twelve lists, and the builder rejects any tag outside the vocabulary: `law`, `offices`, `towns`, `court`, `seat` and `culture`. There are 371 tagged entries: law 170, offices 96, towns 40, court 26, culture 23 and seat 20. `registry_1800.json` still says office/civic; read it through the same mapping (`gov_tag_normalisation`).
5. **Production density.** See *Research pace* below.
6. **The deduplication race.** Every pair of rows in different lines was compared by id stems and name-word overlap. The same scan ran within each line and against every 1800–2400 entry. All 1565 rows were also read in year order to find duplicates in meaning and items that had been dropped. The results:
   - **Doubled, across windows:** Ecology `statutory_game_seasons` (2565, "Statute closed seasons for game birds") is the 1800–2400 `game_bird_close_seasons` (2210, "Close seasons for game birds by statute"). It is **excluded**. No row continued it, and `game_warden_licences` (2653) now continues the 1800–2400 item.
   - **Doubled, kept with a link:** `steam_pumped_waterworks` (infrastructure 2418, AD 1807) against 1800–2400 `steam_waterworks` (2256). The 2418 row is kept as the pumping-station-and-reservoir stage, and `steam_waterworks` is added as its predecessor. See `ambiguous`.
   - **Dropped:** `developmental_stage_series` and the spaceflight rows; see *Rows added* below.
   - **Within the window:** no id or meaning is listed twice.

## Rows added by this pass

A list gave each of these items to another line, and that line never placed it. All of them are in `rows_added_by_registry`.

| Id | Line, year | Why |
|---|---|---|
| `developmental_stage_series` | ecology 2475 | A catalog id (`field_botany_knowledge.gd`, AD 1828, direction Sustenance). Nutrition's scope gives it to Ecology, but no registry held it. It continues `comparative_anatomy`. |
| `orbital_satellite_launch` (key) | logistics 2817 | Knowledge's scope gives spaceflight to Logistics, but Logistics listed only `reusable_orbital_boosters` (2965). Meanwhile Security, Knowledge and Ecology place satellites from 2825. AD 1957. |
| `crewed_orbital_flight` | logistics 2828 | AD 1961 |
| `crewed_lunar_landing` (key) | logistics 2848 | AD 1969 |
| `shared_orbital_station` | logistics 2920 | Continuously crewed and shared by several realms, AD 1998–2000 |

`reusable_orbital_boosters` now continues `orbital_satellite_launch`. The Logistics pacing table, total and key-threshold chains were updated to match, and so were Ecology's.

## Real names fixed

The denylist found six ids and two names:

| Old | New | Term |
|---|---|---|
| `gentle_heat_pasteurising` (nutrition 2571) | `gentle_heat_treatment` | eponym |
| `sutured_caesarean` (demography 2619), "…after caesarean birth" | `sutured_surgical_birth`, "…after a surgical birth" | caesar\* |
| `diesel_motor_ships` (logistics 2699), "Diesel motor ships" | `heavy_oil_motor_ships`, "Heavy-oil motor ships" | eponym |
| `diesel_electric_locomotives` (logistics 2757) | `oil_electric_locomotives`, "Oil-engined electric locomotives…" | eponym |
| `rubber_vulcanization` (production 2508) | `sulphur_cured_rubber` | a god's name |
| `electrical_measurement` name "Needle galvanometers…" | "Needle current meters…" | eponym |
| `portland_cement_clinker` name "Portland cement: …" | "Hydraulic cement: …" | place |

The matching wording in each list's notes was changed too. All six id changes were made in the source lists; they are recorded in `source_list_fixes`, and the builder asserts them.

- **Exception.** `portland_cement_clinker` is a `main` catalog id (`building_material_knowledge.gd`), so the id is kept. It is listed in `real_name_id_exceptions`, which the validator reports but does not fail, and in `bake_time_fixes` for renaming at bake time.
- **Accepted standard terms.** "bauxite", a mineral name from a place, and "voltage".
- **Prior-window slug.** `postmortem_cesarean`, which `sutured_surgical_birth` continues, uses the "cesarean" spelling. Rename it in its own window.

## Collisions with earlier blocks

- **No collisions** with any earlier registry (0–600, 600–1200, 1200–1800 or 1800–2400) or with the game's baked blocks, counting canonical ids, alias slugs, excluded rows and renamed slugs.
- **No redates.**
- **No NEW slug matches** a catalog or era id.
- **Belongs-later items from 1800–2400:** all **23** distinct ids are placed here. None is still unplaced.
  - **Health:** `slow_sand_filtration` 2411, `water_service_inspections` 2533, `contagion_mapping` and `nursing_care_organization` 2544.
  - **Nutrition:** `intensive_gardens` 2533, `fermentation_starter_cultures` 2552 and `roller_grain_milling` 2587.
  - **Demography:** `child_growth_records` 2667.
  - **Logistics:** `rail_track_foundations` 2485 and `rail_gauge_standards` 2523.
  - **Ecology:** the seven geoscience and soil ids, 2405–2507.
  - **Security:** `range_estimation_drill` 2541, `armored_hulls` 2557, `metallic_cartridges` 2560, `naval_torpedoes` 2577 and `indirect_fire` 2664.
  - **Knowledge:** `cylinder_press_printing` 2437.
- **Deferred to earlier windows:** the lists name 31 items as belonging to 1800–2400 or earlier. Examples include `shutter_signal_frames`, `seedbed_firming`, `litter_bearer_drill`, `aerostat_observation`, `precision_machinery`, `military_staffs` and `wagonway_haulage`. Every one is placed in an earlier registry (`deferred_to_earlier_windows`).
- **Belongs earlier:** the three Production catalog ids are carried forward unchanged.

## Catalog coverage

The candidates are every catalog id in `HISTORICAL_YEAR` with a historical year of AD 1800 or later, plus every top-level entry in `main` `scripts/*_knowledge.gd`. That is **456 ids**. Of the 611 top-level knowledge-file ids, all have a `HISTORICAL_YEAR`. 74 of the 456 exist only in `HISTORICAL_YEAR`, in other catalog files such as the society, industry, doctrine and field-medicine catalogs.

| Placement | Ids |
|---|---|
| Placed in this registry | **440** |
| Placed in an earlier registry | 16 |
| Recorded as intentionally excluded | 0 |
| **Unplaced** | **0** |

The 16 placed earlier are already-adopted practices whose round catalog year falls in or after AD 1800:
- **0–600 and 600–1200 registries:** `risk_pools` 850, `public_libraries` 896 and `drawloom_pattern_control` 940.
- **1200–1800 registry:** `mounted_remount_school` 1250.
- **1800–2400 registry:** `metal_type_casting` 1875, `nut_blank_forging` 1886, `wagonway_haulage` 1960, `row_spacing_trials` 2232, `steel_refining` 2282, `biological_reference_collections` 2300, `preventive_inoculation` 2302, `yarn_count_standards` 2391, `metal_annealing_control` 2394, `mechanical_clutches` 2396, `pressure_pipe_jointing` 2396 and `pressure_vessels` 2399.

Eighteen `"id"` values in the knowledge files have no historical year: `local`, `empirical`, `junction`, `solid_wheels`, `cut_threads` and the like. They are `learning_routes` entries inside catalog items, not discoveries, and are listed in `catalog_coverage.learning_route_ids_ignored`.

**Catalog years far from the placement** (`catalog_year_gaps`, 100 or more game years):

| Id | Placed | Catalog year on the curve | Why |
|---|---|---|---|
| `least_squares_estimation` | 2416 | 2533 (AD 1850) | The method dates from about AD 1806; the catalog year is late |
| `range_estimation_drill` | 2541 | 2400 (AD 1800) | Belongs with the musketry school of about AD 1853 |
| `urea_synthesis` | 2728 | 2475 (AD 1828) | The catalog item is bulk urea from ammonia, which needs `catalytic_ammonia_synthesis` |
| `ethylene_glycol_hydrolysis` | 2752 | 2557 (AD 1859) | Industrial glycol follows `ethylene_oxide_synthesis` (2749) |
| `phosphate_solubilization` | 2517 | 2667 (AD 1900) | Acid phosphate dates from about AD 1843 |
| `naval_logistics` | 2780 | 2667 (AD 1900) | Replenishment under way at fleet scale dates from the 1940s |

## Research pace (for the rebalance)

The model assumes one staffed team per line, so a band's load is its summed `research_years` divided by its width. A load above 1.0 is more than one team can finish in the band. The earlier windows already run whole lines at up to 1.7: Knowledge 1800–2400 is 1.73, and 1200–1800 reaches 1.45. So the builder flags a band as **more than the pace can deliver** when its load is over **2.0**, or when it holds more than 30 items in 50 years. It checks 50-year bins, matching the lists' pacing tables, and 25-year sliding windows. The full table is in `pace`.

**Production** (window load 1.47, 278 rows):

| Band | Items | Research years | Load | What crowds it |
|---|---|---|---|---|
| 2550–2600 | 39 | 105 | **2.10** | The AD 1856–1870 lathe and machine-shop set: slides, chucks, lead screws, taps, dies and gauges |
| 2650–2700 | 47 | 121 | **2.42** | The AD 1900 fastener, battery, furnace and pneumatic set |
| 2750–2800 | 35 | 105 | **2.10** | The polymer set: melt, foam, molecular weight, reaction heat and solvent recovery |
| 2800–2850 | 41 | 125 | **2.50** | The transistor, counter, register and polymer-characterisation set |

The worst 25-year window is 2747–2772, with 22 items and a load of 3.12. Production's crowding comes from the catalog's lumped round years (AD 1870, 1900, 1937, 1950), and most rows in these bands are 1–3-year steps.

- **Options for the rebalance:**
  - spread each set over its real invention dates;
  - fold the small shop-floor steps into their parent items as effects;
  - let a bundle research as one item.
- **The other flagged lines**, as 50-year bins with load over 2.0:
  - **Security:** 2550–2600, 2650–2850. Its peak is 5.8 at 2763–2788, from the radar-to-fission-weapon run.
  - **Knowledge:** 2550–2600, 2650–2700 and 2800–2850. Its peak is 5.16 at 2659–2684, from the catalog's radio and electron cluster.
  - **Health:** 2500–2550, 2600–2700 and 2750–2850. Its peak is 4.52.
  - **Logistics:** 2500–2600, 2700–2750 and 2800–2850. Its peak is 4.4 at 2811–2836, including the new spaceflight rows.
  - **Ecology:** 2800–2900. Its peak is 3.96, from the treaties and pollution law of AD 1950–1990.
  - **Nutrition:** 2500–2550.
- **Lines with no flagged 50-year bin:** Institutions, Culture, Labor, Infrastructure and Demography.
- **Whole-window loads:**
  - Security 1.84, Health 1.75, Logistics 1.74 and Knowledge 1.68 run above every earlier window.
  - Production 1.47, Ecology 1.42 and Nutrition 1.35 are also high.
  - Labor 0.76 and Infrastructure 0.85 have spare capacity.

## Near-duplicates reviewed and kept separate

- **Within the window.** The validator lists 32 cross-line pairs, and none is a duplicate. They fall into these groups:
  - **Shared words only:**
    - `state_weather_service` / `state_forest_service` / `state_intelligence_service`;
    - `monument_protection_law` / `child_protection_law`;
    - `equal_marriage_law` / `equal_pay_law`;
    - `intensive_care_units` / `neonatal_intensive_care` / `dementia_care_units`;
    - `low_carbon_cement` / `low_carbon_ship_fuels`;
    - `gene_edited_crops` / `gene_edited_blood_cure`;
    - `acoustic_leak_detection` / `food_package_leak_detection`;
    - `toolbit_heat_treatment` / `gentle_heat_treatment`;
    - `great_realm_conference` / `great_realms_exhibition`;
    - `public_broadcasting_charter` / `public_alert_broadcasts`.
  - **An engine and its service**, where the service should require the engine:
    - `compound_steam_engines` → `compound_marine_engines`;
    - `sheet_steel_rolling` / `rolled_steel_rails`;
    - `steam_grain_elevators` (handling) / `graded_grain_elevators` (grading);
    - `telegraph_train_dispatch` (rail) / `field_telegraph_trains` (army);
    - `nuclear_magnetic_resonance_spectroscopy` → `magnetic_resonance_imaging`;
    - `punched_card_loom_control` / `punched_card_tabulation`.
  - **Computing and control pairs** that split along the catalog directions Information and Materials. They are theory and control store on one side, and machine-tool and controller hardware on the other:
    - `microprogrammed_machine_control` / `numerical_machine_control` / `electronic_machine_control`;
    - `diode_control_stores` / `stored_program_control`.
  - **Distinct stages:**
    - `cause_of_death_tables` (demography 2504) / `shared_death_cause_list` (health 2648, the shared list between realms);
    - `old_age_pensions` / `indexed_pension_age`;
    - `famine_relief_works` / `public_relief_works`;
    - `solid_state_physics` / `solid_state_lighting` / `solid_state_battery_cells`;
    - `crystal_radio_detection` / `radio_detection_ranging` / `hyperbolic_radio_navigation`;
    - `great_realm_conference` / `inter_realm_population_conference`.
- **Within a line.** The only pair is `sinker_electrical_discharge_machining` / `wire_electrical_discharge_machining` (production). These are two catalog processes.
- **Against 1800–2400.** The scan finds `steam_pumped_waterworks` ~ `steam_waterworks`, which is kept with a link, and `childrens_hospitals` ~ `smallpox_hospital`, which are different hospitals. The excluded `statutory_game_seasons` no longer appears.
- **Read by eye:** these are near but kept separate.
  - `lean_production` (labor 2845) and `just_in_time_supply` (logistics 2868);
  - `networked_telework` (labor 2915) and `remote_video_gatherings` (culture 2975);
  - `wartime_ration_cards` (nutrition) and `war_economy_boards` (institutions);
  - `welfare_state`, `national_health_service` and `universal_family_allowances`, which are three offices of one settlement.

## Open issues

- **Predecessors out of order.** These two links run backwards, and the list owners should pick a fix:
  - `scheduled_river_steamers` (2419, AD 1807) continues the catalog's `steam_propulsion`, placed at 2452 (AD 1824). Either place `steam_propulsion` at or before 2419, or drop the link.
  - `automation_retraining` (2830) continues `industrial_robots` (2834). The fix is to move it to 2834 or later.
- **Gaps filled (follow-up pass).** Rows no list claimed are now placed and recorded in `rows_added_by_registry`:
  - `stored_program_computer` (knowledge 2796, ≈ AD 1948; shared with Production). Production's `read_write_memory` (2806) and `stored_program_control` (2838) stay as the later catalog parts. `numerical_weather_prediction` now requires it instead of `binary_adders`;
  - `typewriter` (knowledge 2600, ≈ AD 1875; shared with Labor, whose `women_office_clerks` are typists);
  - `rock_oil_well_drilling` (infrastructure 2555, ≈ AD 1858; shared with Production). It feeds `fuel_refining` and `crude_oil_pipelines`;
  - `expanding_universe_cosmology` (knowledge 2744, ≈ AD 1929);
  - `recombinant_dna` (knowledge 2858, ≈ AD 1973). `transgenic_crops` and `precision_fermented_proteins` now require it instead of `recombinant_vaccine`;
  - `cathode_ray_discharge_tubes` (knowledge 2603, ≈ AD 1876). `bone_shadow_imaging` and `electron_physics` require it.
  - A progressive income tax is **not** added: the 1800–2400 row `graduated_income_tax` (institutions 2398) covers it (`gaps_checked_not_added`).
  - The dependency rows for these ids and the rewired dependents are applied in `tools/research/merge_graph_3000.py` (`GAP_ROWS`, `REWIRES`). See `deps/GRAPH_3000_REPORT.md`.
- **Weapons of mass destruction.** The Security list requires that a general can never use gas, fission or thermonuclear weapons, or intercontinental missiles, on his own authority. Their use is the ruler's spoken decision. The effects pass must gate use, not only research (`bake_time_fixes`).
- **Denylist divergence.** The 1800–2400 validator allows "caesarean" and treats "galvan" as exact-only. This window's list is stricter. Decide whether the 1800–2400 list should adopt the stricter form.
- **Source notes with small year slips.** These were left as written:
  - Health says compulsory infant vaccination is 2531, but the row is 2541.
  - Nutrition says the frozen meat trade is 2604, but the row is 2605.
  - Health's too-early table lists `litter_bearer_drill` twice.
- **Bands.** 55 bands reach outside 2400–3000, by up to 37 years. Every target year is inside the window.
- **Source-list edits made by this pass** (all in `docs/research/y2400/`):
  - the six id changes and two name changes;
  - `[gov:]` normalisation in every file;
  - the five added rows, with the Ecology and Logistics count and pacing updates;
  - note fixes in Institutions, Infrastructure, Knowledge, Production, Nutrition, Health, Demography and Logistics.

  No other row's year or band was changed.
