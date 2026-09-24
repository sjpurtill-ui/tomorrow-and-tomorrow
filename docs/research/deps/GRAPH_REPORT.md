# Research dependency graph report

Source: `graph.json` (merged from the 12 line maps). Edges run prerequisite → dependent.

## Totals

- Items: 1101 (all registry ids; none missing, no unknown references).
- Edges: 2818 — hard `requires_all` 1716, `requires_any` members 203 (in 97 groups), precedents 899.
- Cross-line edges: hard 534, any 160, precedent 513.
- Items with no requirement: 51, all at year ≤ 5.
- Conditions normalized: `resources_known` is a list of in-game names (25 items); `environment` is an any-of list (72); `contact_required` is a boolean on every node (17 true).
- Resource mapping: Copper→Copper Ore, Tin→Tin Ore, Lead→Lead Ore, Gold→Gold Ore; Clay, Stone, Salt, Limestone, Sulfur and Bitumen match exactly. There is no raw in-game resource for these, so they are moved to `resources_unmapped` and not enforced: Gypsum on `gypsum_mortar`, Meteoric iron on `meteoric_iron_working`, Alum on `alum_mordant_dyeing`.

## Cross-line matrix (hard + any; row = prerequisite line, column = dependent line)

| from \ to | KNO | INS | CUL | LAB | PRO | INF | NUT | HEA | DEM | LOG | ECO | SEC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| KNO | 101 | 37 | 21 | 14 | 7 | 7 | 8 | 3 | 7 | 13 | 4 | 7 |
| INS | 11 | 127 | 17 | 11 | 2 | 2 | 3 | 2 | 13 | 2 | 7 | 3 |
| CUL | 2 | 8 | 91 | 4 | · | 1 | · | 1 | 3 | 1 | 1 | 2 |
| LAB | 7 | 7 | 3 | 88 | 9 | 8 | 2 | 6 | 2 | 4 | 2 | 4 |
| PRO | 11 | 4 | 18 | 3 | 129 | 26 | 18 | 21 | 1 | 19 | 7 | 22 |
| INF | 4 | 5 | 17 | 3 | 3 | 115 | 9 | 12 | 3 | 15 | 9 | 18 |
| NUT | · | · | 3 | 5 | 9 | 2 | 138 | 10 | 6 | 6 | 21 | 1 |
| HEA | · | · | · | · | · | · | 2 | 94 | 5 | · | 3 | · |
| DEM | · | 3 | 3 | · | · | · | 4 | 6 | 78 | 1 | 1 | 1 |
| LOG | 5 | 3 | 14 | 1 | · | 2 | 4 | 1 | 1 | 112 | 1 | 8 |
| ECO | 1 | · | 2 | 1 | 6 | 2 | 1 | 2 | · | 4 | 77 | 1 |
| SEC | 2 | 7 | · | · | · | 3 | 2 | · | · | · | 2 | 75 |

## Links removed (16, all precedents; no hard prerequisite was cut): 1 mandated, 12 cycle breaks, 3 reversed by promotions

| dependent | dropped precedent | years | reason |
|---|---|---|---|
| `hired_labor_contracts` | `price_wage_schedules` | 540 → 520 | mapper report: precedent to a later item (540) |
| `stone_sorting` | `quarry_reading` | 5 → 2 | precedent points forward in time (+3 y) |
| `hafted_tools` | `hafted_weapons` | 7 → 7 | precedent closes cycle; weakest link |
| `smoking` | `hide_smoke_curing` | 10 → 11 | precedent closes cycle; weakest link |
| `herd_size_limits` | `animal_taming` | 16 → 8 | precedent points forward in time (+8 y) |
| `wedges_and_levers` | `rollers_and_runners` | 65 → 55 | precedent points forward in time (+10 y) |
| `hide_tanning` | `tannery_waste_channeling` | 112 → 100 | precedent points forward in time (+12 y) |
| `courtyard_storerooms` | `sealed_store_doors` | 190 → 170 | precedent points forward in time (+20 y) |
| `reed_mat_brick_layers` | `stepped_temple_towers` | 480 → 470 | precedent points forward in time (+10 y) |
| `fish_weirs_and_traps` | `spawning_calendar` | 24 → 23 | precedent points forward in time (+1 y) |
| `shaft_furnaces` | `refractory_body_trials` | 565 → 520 | precedent points forward in time (+45 y) |
| `goldsmith_filigree` | `hard_soldering` | 450 → 400 | precedent points forward in time (+50 y) |
| `brick_quotas` | `standard_brick_proportions` | 430 → 430 | precedent closes cycle; weakest link |
| `fermentation_control` | `resin_sealed_wine` | 65 → 116 | reversed by promotion: wine now requires fermentation_control |
| `cored_socket_casting` | `socketed_spearheads` | 450 → 540 | reversed by promotion: spearheads now require cored casting |
| `animal_taming` | `herd_size_limits` | 8 → 16 | precedent reversed by a promoted hard link (cycle) |

Precedents that still point forward in time (not cycles, left in place): 49.

## Year adjustments

18 proposed moves and 10 precedent → hard promotions. See `YEAR_ADJUSTMENTS.md`. With the moves, there are 0 hard or any-route time violations. Before the moves there were 2, both any-routes.

## Pacing

- **Impossible (critical-path earliest year > band_high): 0.** Research times never prevent an item from landing in its band.
- **Under-gated: 238 items** have band_low ≥ 100 but a critical-path earliest year below 10% of band_low. The median item is reachable at 11% of its target year. Gates alone do not hold the eras back; pacing depends on research throughput, conditions and population, not on prerequisites.
  By line: NUT 32, HEA 30, INF 30, ECO 29, PRO 19, CUL 18, DEM 17, KNO 17, LOG 17, LAB 16, INS 8, SEC 5.
  The 15 worst cases (earliest-feasible year vs band_low): `protected_temple_woods` 32.5/560; `cautery` 11.5/536; `tapestry_weaving` 32.5/555; `fruit_tree_grafting` 23.5/545; `crew_loans_between_cities` 45.5/560; `three_year_nursing` 18.5/528; `shadow_clock` 33.0/540; `levirate_marriage` 36.0/538; `trade_elders` 41.5/540; `dried_salted_cheese` 21.5/520; `planted_timber_groves` 38.5/535; `cistern_flushed_drains` 46.5/540; `separate_grain_lines` 39.5/532; `foreign_fashion_adoption` 38.5/530; `workshop_quotas` 42.5/530. Each of these items is tagged `pacing: under_gated` in `graph.json`.
- **Queue pressure.** In a serial model (one project at a time per line, taken in year order, waiting on cross-line prerequisites), 225 items finish after band_high (`serial_overrun`). By line: NUT 50, LOG 48, SEC 34, PRO 30, INF 14, CUL 10, ECO 10, HEA 10, INS 8, KNO 6, LAB 4, DEM 1. The worst overruns are `hogging_truss_hulls` 519.0 vs 455; `scaling_ladders_rams` 524.0 vs 460; `war_chariots` 604.0 vs 540; `shield_equipment_fitting` 609.0 vs 545; `copper_helmets` 506.0 vs 445; `deep_phalanx` 516.0 vs 455. Items that start at years 0–5 already overload the nutrition, production and culture queues, and logistics and security run up to about 65 years behind band_high after year 300. If the engine researches one project per line at a time, these lines need shorter `research_years` or parallel projects.

## Longest dependency chains (by hard/any links)

1. **scale_armor_attachment** — 17 links, earliest feasible 133.5: fiber_grading (4) → cordage (6) → hafted_tools (7) → ground_stone_axes (16) → native_copper_working (68) → ore_assaying (85) → copper_smelting (90) → copper_casting (105) → timber_post_beam_connections (180) → solid_wheel_assembly (225) → wooden_axle_shaping (228) → linchpin_retention (232) → cart_bed_framing (240) → haul_harness_weaving (298) → domesticated_mounts (475) → war_chariots (500) → chariot_crews (530) → scale_armor_attachment (590)
2. **remedy_compendia** — 14 links, earliest feasible 137.5: stone_sorting (2) → clay_testing (12) → clay_shaping (13) → owner_marks (55) → stamp_seals (100) → token_envelopes (160) → impressed_number_tablets (225) → pictographic_records (255) → clay_record_tablets (270) → standard_sign_lists (280) → phonetic_notation (360) → written_lore_tablets (390) → remedy_tablets (482) → case_records (495) → remedy_compendia (595)
3. **outflow_water_clock** — 14 links, earliest feasible 128.5: stone_sorting (2) → clay_testing (12) → clay_shaping (13) → owner_marks (55) → stamp_seals (100) → token_envelopes (160) → impressed_number_tablets (225) → pictographic_records (255) → clay_record_tablets (270) → standard_sign_lists (280) → scribal_apprenticeship (290) → public_schools (420) → reciprocal_tables (485) → fractional_quantities (520) → outflow_water_clock (590)
4. **service_land_registers** — 13 links, earliest feasible 108.5: stone_sorting (2) → clay_testing (12) → clay_shaping (13) → owner_marks (55) → stamp_seals (100) → token_envelopes (160) → impressed_number_tablets (225) → pictographic_records (255) → clay_record_tablets (270) → archive_shelving_order (310) → formal_archives (405) → property_registers (525) → service_land_grants (555) → service_land_registers (600)
5. **core_formed_glass** — 12 links, earliest feasible 84.5: fiber_grading (4) → cordage (6) → hafted_tools (7) → ground_stone_axes (16) → native_copper_working (68) → ore_assaying (85) → copper_smelting (90) → pot_bellows (420) → shaft_furnaces (520) → refractory_body_trials (565) → ceramic_crucibles (570) → crucible_glass_melting (580) → core_formed_glass (590)
6. **jurisdiction_boundaries** — 12 links, earliest feasible 66.5: shared_hearth_gatherings (1) → elder_consultation_rites (8) → household_councils (10) → elder_council_assent (12) → blood_price (20) → customary_law (35) → household_mediators (45) → mediated_restitution_custom (145) → standing_arbiter_appointment (157) → public_grievance_hearings (225) → appeal_reopening_custom (285) → specialized_courts (405) → jurisdiction_boundaries (560)
7. **sailing_calendar** — 12 links, earliest feasible 81.5: fiber_grading (4) → cordage (6) → hafted_tools (7) → ground_stone_axes (16) → framed_construction (20) → warp_weighted_looms (40) → plain_weaving (44) → sail_panel_cutting (272) → coastal_watercraft (310) → hull_seam_caulking (330) → island_hopping_sailing (510) → pilots_sea_lanes (540) → sailing_calendar (550)
8. **written_patrol_reports** — 12 links, earliest feasible 104.5: fiber_grading (4) → cordage (6) → hafted_tools (7) → ground_stone_axes (16) → native_copper_working (68) → ore_assaying (85) → copper_smelting (90) → copper_casting (105) → timber_post_beam_connections (180) → gate_watchtowers (230) → flanked_gate_complex (340) → border_fortress_chains (520) → written_patrol_reports (545)
9. **mixed_flock_balance** — 12 links, earliest feasible 90.5: stone_sorting (2) → clay_testing (12) → clay_shaping (13) → owner_marks (55) → stamp_seals (100) → token_envelopes (160) → impressed_number_tablets (225) → pictographic_records (255) → clay_record_tablets (270) → census_rolls (295) → people_herd_counts (345) → seasonal_herd_matching (460) → mixed_flock_balance (490)
10. **field_armorer_teams** — 11 links, earliest feasible 79.5: fiber_grading (4) → cordage (6) → hafted_tools (7) → ground_stone_axes (16) → native_copper_working (68) → ore_assaying (85) → copper_smelting (90) → copper_casting (105) → cast_copper_weapons (145) → common_armory (260) → bronze_weaponry (400) → field_armorer_teams (600)

Named milestones:
- **pictographic_records** — 7 links, earliest feasible 55.5: stone_sorting (2) → clay_testing (12) → clay_shaping (13) → owner_marks (55) → stamp_seals (100) → token_envelopes (160) → impressed_number_tablets (225) → pictographic_records (255)
- **standard_sign_lists** — 9 links, earliest feasible 73.5: stone_sorting (2) → clay_testing (12) → clay_shaping (13) → owner_marks (55) → stamp_seals (100) → token_envelopes (160) → impressed_number_tablets (225) → pictographic_records (255) → clay_record_tablets (270) → standard_sign_lists (280)
- **bronze_alloying** — 8 links, earliest feasible 58.5: fiber_grading (4) → cordage (6) → hafted_tools (7) → ground_stone_axes (16) → native_copper_working (68) → ore_assaying (85) → copper_smelting (90) → tin_smelting (330) → bronze_alloying (360)
- **place_value** — 13 links, earliest feasible 128.5: stone_sorting (2) → clay_testing (12) → clay_shaping (13) → owner_marks (55) → stamp_seals (100) → token_envelopes (160) → impressed_number_tablets (225) → pictographic_records (255) → clay_record_tablets (270) → standard_sign_lists (280) → scribal_apprenticeship (290) → public_schools (420) → reciprocal_tables (485) → place_value (510)
