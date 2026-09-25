# Phase 2: Labor, Production and Infrastructure effects

Files: `data/research/effects/labor.json`, `production.json` and `infrastructure.json`.

## Counts

| Line | Items | NEW | Rows with `effects` | New observations | Social consequences | `art` (non-NEW) | `production_items` |
|---|---:|---:|---:|---:|---:|---:|---:|
| Labor | 72 | 37 | 38 | 37 | 11 | 35 | 0 |
| Production | 108 | 35 | 62 | 35 | 15 | 73 | 5 |
| Infrastructure | 94 | 42 | 62 | 42 | 13 | 52 | 1 |

- **Every one of the 274 items has a row.** Every NEW id has its own effects and an in-world observation.
- **All 43 existing items that had no effects now have effects.** These items previously relied on their physical recipes alone. See "Changes to authored data".
- **Existing items with sound authored effects keep them.** Their rows add only art, social text or recipe links.
- **The loader accepts all rows.** The merged catalog has:
  - no unknown effect names;
  - no empty effects;
  - no values outside `SocietyModel.EFFECT_LIMITS`;
  - no `validate_catalog` errors for these ids;
  - no bad `production_items`.

## Budgeting against the caps

Adoption reaches about 1.0 within roughly a year of discovery (`SocietyModel.process_day`), so the raw sums below are close to the live values. **Before Phase 2, the existing items' authored effects in these lines already used most of the headroom on the headline keys.** The table counts existing items only (authored effects plus `BASE_EFFECTS`).

| Key | Existing, year 300 | Existing, year 600 | Cap |
|---|---:|---:|---:|
| construction_rate | .705 | 1.015 | 1.00 |
| craft_output | .625 | .775 | 1.00 |
| tool_quality | .630 | .790 | .90 |
| labor_efficiency | .376 | .455 | .55 |
| fatigue | -.215 | -.255 | -.35 |
| disaster_risk | -.195 | -.230 | -.20 floor |
| housing_output | .220 | .340 | .90 |
| disaster_resilience | .070 | .130 | .80 |

**Where the new effects go.** The new effects go mainly to keys that still have room, so that later discoveries are still felt:

- housing and storage: `housing_output`, `dry_storage`, `food_storage`, `container_capacity`, `storage_loss`;
- water: `water_access`, `sanitation`, `water_safety`;
- `disaster_resilience`;
- material yields, `fuel_efficiency` and `trade_capacity`;
- labor organization: `task_coordination`, `labor_demand`, `injury_risk` and `health_risk`;
- institutional side effects: `state_capacity`, `legitimacy` and `institutional_rigidity`.

**Saturated keys get only small amounts.** Per-key scale factors in the generator do this: construction_rate ×0.15, craft_output ×0.2, tool_quality ×0.2, labor_efficiency ×0.22 and fatigue ×0.35. Negative `disaster_risk` is dropped because authored practices already pass its floor. Key thresholds still carry about 2–3 times a routine practice.

**Costs are real and bounded:**

- Great works, owed shrine labor, levees, walls and towers raise `labor_demand`.
- Smelting, shaft furnaces, kilns and fired brick raise `fuel_demand`, `pollution` and `timber_pressure`.
- Arsenical copper and lead raise `health_risk`.
- Levy substitutes and exemptions cost `legitimacy`.
- Brick quotas and task norms add a little `fatigue`.

**Phase 3 flag.** From these three lines alone, `construction_rate` and `craft_output` hit their caps at roughly year 480–600. Other lines and later eras push them further. After that point, new discoveries on those keys have no effect the player can feel. Phase 3 should rescale the authored era-branch practices or the caps. The Phase 2 files cannot change either.

## Effect totals per sub-dimension

The raw sum of each line's items with target year ≤ Y. It includes authored effects, `BASE_EFFECTS` and the Phase 2 rows, before adoption and caps.

### labor

| Sub-dimension | Year 100 | Year 300 | Year 600 |
|---|---|---|---|
| Able workforce | injury_risk -0.062, health_risk -0.020 | injury_risk -0.079, health_risk -0.030 | injury_risk -0.120, health_risk -0.060, health_protection +0.007 |
| Work efficiency | labor_efficiency +0.209 | labor_efficiency +0.369 | labor_efficiency +0.481 |
| Coordination | task_coordination +0.118, cohesion +0.067 | task_coordination +0.266, cohesion +0.066 | task_coordination +0.462, cohesion +0.088 |
| Workload balance | fatigue -0.210, labor_demand -0.012 | fatigue -0.251, labor_demand +0.048 | fatigue -0.326, labor_demand -0.052 |

### production

| Sub-dimension | Year 100 | Year 300 | Year 600 |
|---|---|---|---|
| Material supply | extraction_yield +0.100, metal_yield +0.090, stone_yield +0.020, clay_yield +0.050, fiber_yield +0.110, timber_yield +0.080 | extraction_yield +0.160, metal_yield +0.200, stone_yield +0.040, clay_yield +0.090, fiber_yield +0.160, timber_yield +0.080 | extraction_yield +0.200, metal_yield +0.450, stone_yield +0.060, clay_yield +0.090, fiber_yield +0.220, timber_yield +0.110 |
| Tool quality | tool_quality +0.431, repair_capacity +0.040 | tool_quality +0.630, repair_capacity +0.050 | tool_quality +0.820, repair_capacity +0.120 |
| Craft capacity | craft_output +0.449 | craft_output +0.715 | craft_output +0.829 |
| Standardization | standardization +0.074 | standardization +0.309 | standardization +0.435 |

### infrastructure

| Sub-dimension | Year 100 | Year 300 | Year 600 |
|---|---|---|---|
| Housing | housing_output +0.424, dry_storage +0.110, food_storage +0.060, storage_loss -0.040 | housing_output +0.490, dry_storage +0.190, food_storage +0.120, container_capacity +0.020, storage_loss -0.080 | housing_output +0.799, dry_storage +0.260, food_storage +0.180, container_capacity +0.020, storage_loss -0.140 |
| Construction | construction_rate +0.338 | construction_rate +0.541 | construction_rate +0.867 |
| Public works | water_access +0.049, sanitation +0.024, water_safety +0.108 | water_access +0.202, sanitation +0.081, water_safety +0.126 | water_access +0.363, sanitation +0.415, water_safety +0.246 |
| Resilience | disaster_resilience +0.164, disaster_risk -0.069 | disaster_resilience +0.299, disaster_risk -0.190 | disaster_resilience +0.636, disaster_risk -0.220 |

Combined totals for the three lines at year 600:

| Key | Total | Note |
|---|---:|---|
| construction_rate | 1.18 | capped at 1.0 |
| craft_output | 1.02 | capped at 1.0 |
| tool_quality | .87 | |
| housing_output | .82 | |
| disaster_resilience | .65 | |
| container_capacity | .59 | |
| labor_efficiency | .54 | |
| task_coordination | .54 | |
| metal_yield | .53 | |
| standardization | .52 | |
| sanitation | .42 | |
| dry_storage | .40 | |
| water_access | .36 | |
| food_storage | .30 | |

## Key thresholds (new effects)

### Labor

| Year | Item | Effects |
|---:|---|---|
| 28 | `work_party_feasts` | task_coordination .019, cohesion .01 |
| 100 | `great_work_parties` | task_coordination .0225, disaster_resilience .015, labor_demand +.025 |
| 155 | `full_time_specialists` | craft and tools, labor_demand +.01, institutional_rigidity +.01 |
| 180 | `shrine_work_obligations` | state_capacity .018, labor_demand +.02, cohesion −.0025 |
| 215 | `fixed_worker_rations` | health_risk −.01, fatigue −.0105, nutrition_quality .01 |
| 380 | `rotating_named_gangs` | task_coordination .03 |
| 390 | `workers_villages` | housing_output .012, health_risk −.01 |
| 450 | `daily_task_norms` | task_coordination .0225, standardization .012, fatigue +.0035 |
| 480 | `man_day_accounts` | task_coordination .026, state_capacity .018 |
| 520 | `hired_labor_contracts` | labor_demand −.03, trade .012 |

### Production

| Year | Item | Effects |
|---:|---|---|
| 175 | `arsenical_copper` | metal_yield .04, warfare .02, health_risk +.01, pollution +.01 |
| 230 | `wheel_thrown_pottery` | container_capacity .04, standardization .018 |
| 420 | `pot_bellows` | metal_yield .06, fuel_efficiency .04 |
| 520 | `shaft_furnaces` | metal_yield .08, extraction_yield .03, fuel_demand, pollution and timber_pressure |
| 555 | `ceramic_glaze_formulation` | container_capacity .03, food_spoilage −.02 |

Lost wax, faience, filigree and core-formed glass mainly add trade and legitimacy.

### Infrastructure

| Year | Item | Effects |
|---:|---|---|
| 48 | `mould_made_mudbricks` | housing_output .036 |
| 95 | `central_hall_houses` | housing_output .036, dry_storage .02, food_storage .02 |
| 135 | `flood_levees` | disaster_resilience .045 |
| 170 | `courtyard_storerooms` | food_storage .05, dry_storage .05, storage_loss −.04 |
| 300 | `town_enclosure_walls` | security_efficiency .04, disaster_resilience .0225 |
| 330 | `kiln_fired_bricks` | disaster_resilience .0375, housing_output .024, fuel_demand and timber_pressure |
| 370 | `stepped_stone_tombs` | haul, state and legitimacy, labor_demand +.03 |
| 450 | `ventilated_granaries` | food_storage .06, storage_loss −.05 |
| 510 | `clay_pipe_socket_jointing` | water_access, water_safety and sanitation |

### Shelter and storage are felt

- `housing_output` scales the capacity of built shelters (`settlement_construction.gd`).
- `dry_storage` and `container_capacity` scale the storage classes (`resource_system.gd`).
- `storage_loss` slows decay.
- **Shelter chain.** Adobe, wattle, thatch, longhouse, mudbrick, footings, flat roofs, central hall, courtyard house, upper storeys and light wells take `housing_output` from .42 at year 100 to .80 at year 600.
- **Storage items:**
  - storage pits (14);
  - longhouse lofts, flat roofs and the central hall;
  - courtyard storerooms (170);
  - corbelled and pitched-brick vaults;
  - ventilated granaries (450).

### Early care

`scripts/early_life_conditions.gd` is on `codex/early-consequences` and is not in this worktree. It watches three ids from these lines: `drainage`, `well_siting` and `labor_rotations`. All three keep their authored channel effects.

- `drainage` gains sanitation .012.
- `well_siting` gains water_access .021.

Both feed the "Clean water and waste" channels. `clay_lined_storage_pits`, `courtyard_storerooms` and `ventilated_granaries` add `food_storage`, which is the channel of lean-season stores.

## Changes to authored data

### Effects added or replaced

| Item | Change |
|---|---|
| `drainage` | + sanitation |
| `well_siting` | + water_access |
| `framed_construction` | + dry_storage .02 |
| `apprentice_contracts` | + labor_efficiency, + knowledge_preservation |
| `rainwater_cisterns` | Adds water_safety .012 and disaster_resilience .0075 to water_access .035 (its placement is now year 200). |

### Existing items that had no effects

43 physical-contract items had an empty `effects` dictionary, so their only consequence was the recipe. They include adobe, wattle, thatch, spindles, looms, weaving, tanning, pipes, tiles, glass, crucibles and refractories. They now get small flat effects: housing, storage, fiber, craft, trade and water.

This follows the user goal that every discovery is felt. The raw module `entries()` are unchanged, so the module tests that assert "no flat effects" still pass. If the flat-effect policy should win instead, drop `effects` from those rows.

### Recipes linked (`production_items`)

Only existing recipes that are gated on the same id were linked.

| Item | Recipes |
|---|---|
| `lime_burning` | `quicklime` |
| `lime_mortar` | `slaked_lime`, `building_mortar` |
| `copper_smelting` | `refined_copper` |
| `glassmaking` | `glass_batch` |
| `lead_smelting` | adds `silver_bearing_bullion` |
| `hide_tanning` | adds `bated_vegetable_leather` |

Deliberately not linked:

| Recipe | Gate | Reason |
|---|---|---|
| `cast_terminal_pin_blanks` | `copper_casting` | electrical |
| `bronze_armor_plates` | `bronze_alloying` | armor too early at year 360 |
| abrasive-wheel recipes | `ceramic_glaze_formulation` | industrial |
| `cullet_glass` | `glassmaking` | needs refractory bricks and crucibles, which come at 570–600 |

### Other changes

- **`production_contract` rewritten** for `lead_smelting`, `tin_smelting`, `seed_oil_pressing` and `lampblack_capture`. The old text described batteries, a cannery and printing forms, which do not fit the new placement.
- **Names are unchanged.** Existing ids keep their authored names, and NEW ids keep the design names.

## Art

`test_research_600.test_new_design_items_use_the_catalog_format_and_a_valid_channel` asserts that every NEW id shows its line painting. So `art` is set only on the 160 existing (catalog and era) ids. Each points to the item's own painting or to the closest related one, and every file was checked on disk.

The table below lists the related paintings chosen for NEW ids. They are not applied. The test must change before they can be. The other Phase 2 lines already set `art` on NEW ids and fail that assertion: culture, knowledge, institutions, demography, health and nutrition. Labor, production and infrastructure pass it.

| Painting (`assets/ui/research/`) | NEW ids |
|---|---|
| `paper/adobe_wall_construction.png` | `brick_quotas`, `mould_made_mudbricks`, `niched_brick_facades`, `herringbone_plano_convex_brick`, `standard_brick_proportions`, `pitched_brick_vaults`, `reed_mat_brick_layers`, `stepped_temple_towers` |
| `paper/bow_drill_drive.png` | `tube_drilled_stone_vessels` |
| `paper/building_capillary_breaks.png` | `stone_wall_footings` |
| `paper/building_drainage_coordination.png` | `brick_mass_drain_shafts` |
| `paper/building_shading_design.png` | `light_wells` |
| `paper/ceramic_glaze_formulation.png` | `faience` |
| `paper/drop_spindles.png` | `wool_spinning` |
| `paper/hide_tanning.png` | `hide_smoke_curing` |
| `paper/layered_clothing_design.png` | `wool_felting_fulling` |
| `paper/mineral_pigment_preparation.png` | `painted_pottery` |
| `paper/nursing_care_organization.png` | `light_duty_for_infirm` |
| `paper/plain_weaving.png` | `horizontal_ground_loom`, `palace_weaving_houses`, `tapestry_weaving` |
| `paper/rammed_earth_construction.png` | `shrine_terraces` |
| `paper/silver_cupellation.png` | `goldsmith_filigree`, `hard_soldering` |
| `paper/textile_dye_fixation.png` | `alum_mordant_dyeing` |
| `paper/thatched_roofing.png` | `flat_clay_roofs` |
| `paper/timber_lateral_bracing.png` | `timber_laced_walls` |
| `paper/wattle_and_daub_walls.png` | `slack_season_building` |
| `subjects/animal_taming-v1.png` | `herding_rotas` |
| `subjects/apprentice_contracts-v1.png` | `household_craft_learning`, `apprentice_for_keep`, `apprentice_quotas` |
| `subjects/bitumen_sealing-v1.png` | `bitumen_bedded_brick` |
| `subjects/bronze_alloying-v1.png` | `bronze_work_hardening`, `weighed_alloy_recipes`, `raised_bronze_vessels`, `standard_ingots` |
| `subjects/census_rolls-v1.png` | `crew_count_scribes`, `attendance_lists` |
| `subjects/clay_shaping-v1.png` | `burnished_slipped_wares`, `tournette`, `wheel_thrown_pottery`, `mould_made_bowls` |
| `subjects/copper_casting-v1.png` | `native_copper_working`, `lost_wax_casting`, `sheet_copper_riveting`, `bivalve_moulds`, `closed_moulds`, `cored_socket_casting` |
| `subjects/copper_smelting-v2.png` | `arsenical_copper`, `pot_bellows`, `shaft_furnaces` |
| `subjects/covered_sewers-v1.png` | `cistern_flushed_drains` |
| `subjects/craft_guilds-v1.png` | `part_time_specialists`, `craft_quarters`, `trade_elders`, `temple_workshops` |
| `subjects/crop_calendars-v1.png` | `seasonal_work_round`, `hired_harvest_hands` |
| `subjects/drainage-v1.png` | `flood_house_mounds`, `flood_levees`, `stone_lined_drains` |
| `subjects/festival_calendar-v1.png` | `work_party_feasts`, `festival_rest_days`, `monthly_rest_days` |
| `subjects/field_fortifications-v1.png` | `town_enclosure_walls` |
| `subjects/framed_construction-v1.png` | `upper_storeys` |
| `subjects/geometric_survey-v1.png` | `measured_plot_allotment` |
| `subjects/hafted_tools-v1.png` | `ground_stone_axes` |
| `subjects/household_space_planning-v1.png` | `household_task_division`, `workers_villages`, `central_hall_houses`, `courtyard_houses` |
| `subjects/irrigation_schedules-v1.png` | `flood_season_great_works`, `river_supply_channels`, `diversion_dams`, `wadi_dams`, `shaduf_water_lift` |
| `subjects/joinery-v2.png` | `copper_carpentry_tools` |
| `subjects/kiln_control-v1.png` | `reduction_firing`, `kiln_fired_bricks` |
| `subjects/lime_burning-v1.png` | `lime_plastered_floors` |
| `subjects/lime_mortar-v1.png` | `corbelled_vaults`, `gypsum_mortar` |
| `subjects/material_accounting-v1.png` | `man_day_accounts` |
| `subjects/ore_assaying-v1.png` | `fire_setting_mining`, `meteoric_iron_working` |
| `subjects/professional_service-v1.png` | `crew_loans_between_cities` |
| `subjects/property_registers-v1.png` | `hired_labor_contracts` |
| `subjects/public_levies-v1.png` | `great_work_parties`, `shrine_work_obligations`, `gangs_of_ten`, `rotating_named_gangs`, `levy_substitutes`, `levy_exemptions` |
| `subjects/public_stores-v1.png` | `full_time_specialists`, `fixed_worker_rations`, `clay_lined_storage_pits`, `courtyard_storerooms` |
| `subjects/quarry_reading-v1.png` | `dry_stone_walls`, `wedge_and_fire_quarrying`, `dressed_stone_masonry`, `ashlar_masonry` |
| `subjects/regional_granaries-v1.png` | `ventilated_granaries` |
| `subjects/shared_childcare-v1.png` | `children_light_tasks` |
| `subjects/tallies-v1.png` | `load_tallies` |
| `subjects/urban_street_plans-v1.png` | `colonnaded_porticoes` |
| `subjects/wedges_and_levers-v1.png` | `hauling_chants`, `megalith_raising`, `stepped_stone_tombs` |
| `subjects/well_siting-v1.png` | `lined_well_shafts`, `wedge_brick_well_lining` |
| `subjects/work_motion_studies-v1.png` | `daily_task_norms` |
| `subjects/work_rest_limits-v2.png` | `midday_heat_rest` |

## Adopt or re-date: undated window items in these lines

These are proposals for the design branch. The build data is unchanged.

| Id (dynamic) | Gate now | Proposal |
|---|---:|---|
| `layered_clothing_design` (production) | 3.6 | **Adopt** at about year 16, band 8–25, beside `bone_needle_sewing` (15), and require it. Its recipe consumes cloth or yarn, so in practice it operates only after `plain_weaving` (44). |
| `textile_repair_methods` (production) | 13.5 | **Adopt** at about year 18, band 10–30, after `bone_needle_sewing`. |
| `textile_laundering_practice` (production) | 16.2 | **Re-date** to about year 50, band 40–70, and require `plain_weaving`. There is no cloth to wash before the loom. |
| `fuel_air_drying` (production) | 135 | **Adopt** at about year 6, band 2–15, beside `ember_tending`. Drying firewood is one of the first fire practices, and the item already has its own painting. Its date of −4000 (year 150) is far too late. |
| `fiber_pulp_beating` (production) | 27 | **Re-date beyond 600.** It is the paper-pulp step (`beaten_pulp` produces Paper Pulp). The −6000 date fits bark-cloth beating, not pulp. |
| `ceramic_slip_casting` (production) | 270 | **Re-date beyond 600**, as the Production design says. It is an 18th-century CE method. |
| `quilted_layer_assembly` (production) | 270 | **Re-date** to about year 590, band 550–630. Require `plain_weaving` and `wool_felting_fulling` (390). |
| `masonry_arch_centering` (infrastructure) | 558 | **Re-date beyond 600**, to about 620 per the design. Its only foundation is `standard_measures`; add `dressed_stone_masonry` and `lime_mortar`. |
| `bloomery_smelting`, `iron_assaying`, `forge_welding`, `bloomery_charge_control` (production) | 594 | **Keep beyond 600**, at about 660. Two fixes are possible: make `shaft_furnaces` (520) and `pot_bellows` (420) foundations of `bloomery_smelting`, or floor the gate at 600 for entries dated after the window. |
| `wheel_blank_jointing`, `wheel_hub_boring`, `wooden_axle_boxes`, `drawbar_fitting`, `rope_rigging`, `felloe_jointing`, `axle_sleeve_fitting` (tagged infrastructure) | 202–594 | These are Logistics items. Defer to `PHASE2_LOGISTICS_ECOLOGY_SECURITY.md`. |

## Validation

`test_research_600.gd` runs 14 test cases.

- One test currently fails. Its failing assertions come only from other lines' `art` on NEW ids (see "Art" above).
- Every labor, production and infrastructure row passes.

A headless loader check covered all 274 rows:

- every row merges;
- there are no unknown names, empty effects or out-of-range values;
- `validate_catalog` and the `production_items` contract are clean.

Other suites:

| Suite | Result | Cause |
|---|---|---|
| `test_opening_framed_construction` | Pass | |
| `test_building_material_operations` | Pass | |
| `test_glass_ceramic_processes` | Pass | |
| `test_refractory_ceramics` | Pass | |
| `test_civilian_goods` | Pass | |
| `test_subject_art` | Fails | Baseline problem: missing image files. It fails 4 times without these files and 3 times with them. |
| `test_discovery_subject_art` | Fails | Baseline problem: missing images for later-era ids. |
| `test_early_practice_knowledge` | Fails | Duplicate names among culture, knowledge and institutions ids. |

Save compatibility: data only, with no new saved state.
