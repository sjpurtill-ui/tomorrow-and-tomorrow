# Phase 2: Logistics, Ecology and Security effects

Files:

- `data/research/effects/logistics.json`
- `data/research/effects/ecology.json`
- `data/research/effects/security.json`

Each registry item in these three lines has a row: 103 in Logistics, 87 in Ecology and 82 in Security, 272 in total.

| Line | Rows | NEW | Existing (era + catalog) | Names overridden | Social consequences | Art proposals |
|---|---:|---:|---:|---:|---:|---:|
| Logistics | 103 | 46 | 57 | 46 | 9 | 43 |
| Ecology | 87 | 51 | 36 | 51 | 6 | 38 |
| Security | 82 | 44 | 38 | 45 | 9 | 37 |

- Every NEW row has its own effects, a short name, and an in-world observation. Key thresholds also have an `ability_reason`.
- Every row uses only the 67 recognized effect names, and every value is inside its `EFFECT_LIMITS` bound. The loader merges each row exactly. A headless dump confirmed 0 unknown names and 0 value mismatches.
- No production items, recipes, requirements or conditions were touched. The military unit gates are unchanged, because they key on ids:
  - `hafted_weapons`
  - `bow_craft`
  - `shield_wall`
  - `field_fortifications`
  - `bronze_weaponry`
  - `war_chariots`

## Validation

`tests/test_research_600.gd` gives **0 failures from these three lines**.

The suite as a whole is not yet 14/14. `test_new_design_items_use_the_catalog_format_and_a_valid_channel` fails 162 times. All of those failures are NEW items in the culture (70), institutions (54) and knowledge (38) effect files.

- **Cause:** those files point NEW items at specific paintings, but test line 58 still requires every NEW item to use its line painting (`<line>-v1.png`).
- **What I did:** I followed the test. My NEW rows keep `art` on the line painting.
- **Where my picks are:** the best existing painting for each NEW item is recorded under a top-level `art_proposals` map in each file. The loader reads only `items`, so it ignores that map.
- **Next step:** once the coordinator relaxes that assertion, the proposals can move into `art`.
- **Existing items:** these rows do carry specific existing paintings.

## How the effects were set

**Sub-dimensions and their effect keys:**

- **Logistics**
  - Carrying capacity: `haul_capacity`, `logistics_endurance`, `fatigue`
  - Route quality: `route_speed`, `travel_speed`, `injury_risk`
  - Storage system: `storage_loss`, `food_storage`, `food_spoilage`, `container_capacity`
  - Trade reach: `trade_capacity`, `naval_capacity`
- **Ecology**
  - Land health: `soil_productivity`, `ecological_pressure`
  - Natural recovery: `ecology_recovery`, `foraging_yield`, `hunting_yield`
  - Pollution control: `pollution`, `water_pollution`, `water_safety`, `sanitation`
  - Resource sustainability: `timber_pressure`, `timber_yield`
- **Security**
  - Military readiness: `warfare_readiness`
  - Organized defense: `security_efficiency`
  - Public safety: `injury_risk`, `cohesion`
  - Crisis resilience: `disaster_risk`, `disaster_resilience`, `food_storage`

**Costs are part of the design.** These make choices matter:

| Item | Cost |
|---|---|
| Wagons, plank trackways, palisades | `timber_pressure` |
| Canals, harbors | `disease_exposure` |
| Dung fuel | `soil_productivity` |
| Controlled burning | `pollution`, `disaster_risk` |
| Standing company | `labor_demand`, `legitimacy` |
| Night gate challenge | `trade_capacity` |
| Trade outposts, merchant quarters abroad | `cohesion` |
| Musters and forts | `labor_demand` |

**Budget scaling.** Before scaling, the raw sums at year 600 overran the caps. Examples: `warfare_readiness` 2.1 against a cap of 1.0, and `haul_capacity` 1.69 against 1.0. Years 100 and 300 would have saturated them early. To fix this, ten keys were scaled **uniformly across every row in these three files**. That includes kept authored values, so the relative weights and pacing are preserved. The combined three-line total now stays inside each cap, with headroom for the other nine lines.

| Key | Raw 600-year sum | Factor |
|---|---:|---:|
| `haul_capacity` | 1.69 | 0.473 |
| `route_speed` | 1.265 | 0.538 |
| `trade_capacity` | 1.125 | 0.667 |
| `warfare_readiness` | 2.105 | 0.404 |
| `security_efficiency` | 1.415 | 0.481 |
| `ecology_recovery` | 0.815 | 0.675 |
| `ecological_pressure` | -0.665 | 0.602 |
| `labor_demand` | 0.385 | 0.571 |
| `disaster_risk` | -0.354 | 0.508 |
| `pollution` | -0.22 | 0.636 |

For example, `watch_rotation` `security_efficiency` goes from .11 to .053, `formation_drill` `warfare_readiness` from .14 to .057, and `graded_roads` `route_speed` from .12 to .065. No scaled value falls below ±.004.

## Totals by year

Each total is the raw sum of the effects of items whose target year is at or before the given year, before adoption weighting.

### Logistics

| Sub-dimension | Effect | Year 100 | Year 300 | Year 600 |
|---|---|---:|---:|---:|
| Carrying capacity | `haul_capacity` | +0.147 | +0.533 | +0.800 |
|  | `logistics_endurance` | +0.070 | +0.320 | +0.520 |
|  | `fatigue` | -0.075 | -0.135 | -0.145 |
| Route quality | `route_speed` | +0.151 | +0.363 | +0.681 |
|  | `travel_speed` | +0.080 | +0.080 | +0.260 |
|  | `injury_risk` | -0.032 | -0.077 | -0.111 |
| Storage system | `storage_loss` | -0.070 | -0.225 | -0.385 |
|  | `food_storage` | +0.040 | +0.100 | +0.190 |
|  | `food_spoilage` | -0.010 | -0.050 | -0.070 |
|  | `container_capacity` | +0.000 | +0.000 | +0.100 |
| Trade reach | `trade_capacity` | +0.140 | +0.353 | +0.733 |
|  | `naval_capacity` | +0.000 | +0.060 | +0.590 |

### Ecology

| Sub-dimension | Effect | Year 100 | Year 300 | Year 600 |
|---|---|---:|---:|---:|
| Land health | `soil_productivity` | +0.095 | +0.215 | +0.435 |
|  | `ecological_pressure` | -0.138 | -0.252 | -0.405 |
|  | `disaster_risk` | -0.032 | -0.033 | -0.079 |
| Natural recovery | `ecology_recovery` | +0.175 | +0.401 | +0.549 |
|  | `foraging_yield` | +0.215 | +0.270 | +0.290 |
|  | `hunting_yield` | +0.060 | +0.090 | +0.110 |
|  | `food_output` | +0.070 | +0.090 | +0.145 |
| Pollution control | `pollution` | -0.034 | -0.107 | -0.138 |
|  | `water_pollution` | +0.000 | -0.020 | -0.065 |
|  | `water_safety` | +0.030 | +0.110 | +0.130 |
|  | `sanitation` | +0.010 | +0.040 | +0.040 |
| Resource sustainability | `timber_pressure` | -0.025 | -0.220 | -0.410 |
|  | `timber_yield` | +0.050 | +0.125 | +0.215 |

### Security

| Sub-dimension | Effect | Year 100 | Year 300 | Year 600 |
|---|---|---:|---:|---:|
| Military readiness | `warfare_readiness` | +0.160 | +0.378 | +0.802 |
|  | `task_coordination` | +0.010 | +0.061 | +0.131 |
| Organized defense | `security_efficiency` | +0.192 | +0.384 | +0.677 |
|  | `labor_demand` | +0.023 | +0.070 | +0.149 |
| Public safety | `injury_risk` | -0.064 | -0.090 | -0.141 |
|  | `cohesion` | +0.025 | +0.065 | +0.055 |
|  | `legitimacy` | +0.010 | +0.030 | +0.055 |
| Crisis resilience | `disaster_risk` | -0.042 | -0.064 | -0.083 |
|  | `disaster_resilience` | +0.000 | +0.100 | +0.180 |
|  | `food_storage` | +0.020 | +0.020 | +0.090 |

## How these tie into food and survival

`codex/early-consequences` (commit 9642d611) is not merged into this branch, but its effect names are the recognized ones, so these rows plug straight in.

**Wild ground renewal and depletion** (`food_system.gd`):

- Wild renewal is multiplied by `1 + ecology_recovery`, which gives about ×1.18 by year 100, ×1.40 by year 300, and ×1.55 by year 600.
- Overuse damage is multiplied by `1 + ecological_pressure`, which gives about ×0.86 by year 100, ×0.75 by year 300, and ×0.60 by year 600.
- The items that carry these effects are breeding stock spared, spawning calendar, shellfish beds rested, communal catch limits, hunting closures, wetland reserves, sworn fishing closures, weirs opened for the run, transhumance, grazing rotation and herd matching.
- `foraging_yield`, `hunting_yield` and `food_output` raise the harvest itself.

**Early care channels** (`early_life_conditions.gd`):

| Channel | Items | Effect |
|---|---|---|
| Clean water and waste | Midden siting, spring-head fencing, sacred springs, riparian belts, effluent and tannery control | `water_safety`, `sanitation` |
| Lean-season stores | Dry caches, route caches, sealed store doors, central storehouses, barge fleets, harbor warehouses, emergency food caching, standing relief stores | `food_storage` |
| Wound and injury care | Weapon-free gatherings, truce seasons, market peacekeepers, shields and helmets | `injury_risk` down |

## Key thresholds (after scaling)

- **Logistics**
  - Pack animals at 150: haul .047, endurance .06, trade .027.
  - Solid wheel at 225 and ox carts at 240.
  - River sail at 272.
  - Graded roads at 300 (authored, kept).
  - Sewn-plank boats at 310: naval .08.
  - Stone-jetty harbor at 400: naval .08, trade .047.
  - Donkey caravans at 435: trade .053, endurance .05.
  - Horses at 475: travel .08.
  - Spoked wheels at 500.
  - Island-hopping sailing at 510: naval .10, trade .053.
- **Ecology**
  - Communal catch limits at 150: pressure −.024 more, recovery +.02 more.
  - Coppice at 195: timber pressure −.05, recovery .027.
  - Grazing rotation at 228: pressure −.03.
  - Salt crust recognized at 305: soil .05.
  - Resource quotas at 365.
  - Water-table fallow at 430: soil .06.
  - Farmer's almanac at 560.
- **Security**
  - Defensive ditches at 70.
  - Shield wall at 310, with injury −.01 added.
  - Manned wall posts at 330: security .034.
  - Bronze arms at 400 (authored, kept).
  - Standing paid company at 440.
  - Composite bow at 460.
  - Light war chariots at 500. These were a .035 placeholder; they now give readiness .036, travel .02, legitimacy .01 and coordination .015.

## Changes to existing items

- **Placeholder effects replaced.** These had empty or placeholder-sized effects:
  - Logistics: `hide_floats`, `river_craft`, `pack_animals`, `solid_wheel_assembly`, `wooden_axle_shaping`, `linchpin_retention`, `cart_bed_framing`, `sail_panel_cutting`, `haul_harness_weaving`, `cart_running_gear`, `coastal_watercraft`, `rope_laying`, `caulking_fiber_preparation`, `hull_seam_caulking`, `treenail_fastening`, `mast_making`, `plank_spiling`, `domesticated_mounts`, `spoke_tenon_cutting`, `spoked_wheel_assembly`
  - Security: `war_chariots`, `shield_equipment_fitting`, `scale_armor_attachment`, `field_armorer_teams`
- **Raised as bold thresholds:**
  - `communal_catch_limits`
  - `coppice_regrowth_cutting`
  - `grazing_rotation_customs`
  - `resource_use_quotas`
  - `defensive_ditch_siting`
  - `shield_wall` (+injury)
  - `standing_relief_stores` (+`food_storage`)
- **Small additions:**
  - `dry_cache_siting`: `food_storage`
  - Streambank, herd limits, spawning grounds and hunting closures: `ecology_recovery`
  - Midden siting: `sanitation`
  - Tannery, dye and effluent control: `water_pollution`
- **Text overrides:**
  - Observations rewritten for the new placement:
    - `river_craft` described framed hulls at year 14; it now describes dugouts.
    - `pack_animals` now names donkeys.
    - `timber_bridges` described standard trusses; it now describes log footbridges.
    - `rope_laying` mentioned a ropewalk; that is gone.
    - `supply_groups`, `graded_roads`, `domesticated_mounts`, `war_chariots`, `shield_equipment_fitting` and `scale_armor_attachment` were also rewritten.
  - `war_chariots` is renamed "Light War Chariots". Its id and unit gate are unchanged.
- **Other existing items:** all other authored effects are kept as they were, apart from the uniform budget scaling described above.

## Adopt or re-date: undated items in the window (these three lines)

These live entries are dated inside the window by `technology_eras.gd` but are outside the design. The build data is unchanged. These are proposals for the design branch.

| Id | Gate now | Proposal |
|---|---:|---|
| `wheel_blank_jointing`, `wheel_hub_boring` | 202 | **Adopt** into Logistics carrying as sub-steps of the solid wheel, about 215–220, band 185–265. |
| `wooden_axle_boxes` | 205 | **Re-date** to about 232. Today it opens before its own foundation's design year (`wooden_axle_shaping`, 228). |
| `drawbar_fitting` | 288 | **Re-date** to about 325. It requires `rope_laying` (design 320), so it cannot open at 288 anyway. The alternative is to drop that requirement and adopt it at 298 beside `haul_harness_weaving`. |
| `sail_seaming` | 270 | **Adopt** at about 280, right after `sail_panel_cutting` (272). |
| `rope_rigging` | 270 | **Re-date** to about 345, beside `mast_making`. Rigging before the river sail is anachronistic. |
| `bearing_surfaces` (knowledge) | 360 | **Adopt** into Logistics at about 490 with spoked wheels (hub bearings). Alternatively leave it in Knowledge at 360. |
| `felloe_jointing` | 450 | **Re-date** to about 485, just before `spoke_tenon_cutting` (490) and spoked wheels (500). |
| `axle_sleeve_fitting` | 594 | **Re-date beyond 600**. It needs `forge_welding` (iron). |
| `common_path_alignment` (infrastructure) | 2 | **Adopt** into Logistics routes at about 5, or alias it with `landmark_route_naming`. |
| `ocean_sailing` (security) | 486 | **Re-date** to about 560, and require `island_hopping_sailing` (510). It gates sailing-warship and convoy-transport equipment, so it must not precede island-hopping. |
| `elephant_training` | 450 | **Re-date** to 500 at the earliest, as the Security design says. It needs a regional condition, but no elephant-habitat condition exists yet. |
| `professional_corps`, `galley_navigation`, `naval_arsenals` | 594 | **Re-date beyond 600**, to about 660, as the Security design lists them. The 0.9× gate lets them in at 594. |
| `amphibious_operations` | 594 | **Re-date beyond 600**, to about 700. |
| `habitat_observation_records` (nutrition) | 7 | **Adopt** into Ecology natural recovery at about 15, beside `phenology_signs` (18). |

The "(dup)" design items are not in these files: `stocked_fish_ponds`, `hive_beekeeping`, `standard_ingots` and `seasonal_crisis_leader`. The build assigned them to other lines.

## Known limitations

- **Pollution.** Kept era values already push `pollution` toward its −.15 floor by about year 450, so pollution control saturates early. Later industry adds positive pollution, which restores headroom.
- **Adoption weighting.** The totals above are raw sums. In play, effects arrive gradually as adoption rises.
- **Art.** Art proposals for NEW items wait on the test change described under Validation.
