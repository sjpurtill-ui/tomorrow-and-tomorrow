# Phase 2, years 2400–3000: Labor, Production and Infrastructure effects

Files: `data/research/effects_y2400_3000/labor.json`, `production.json` and `infrastructure.json`. These are data only. They add no saved state and make no script changes. The window is about AD 1800–2030.

## Counts

| Line | Items | NEW | Catalog | Key thresholds | `effects` | `name` | `observation` | `ability_reason` | `social_consequence` | `resource_requirements` | Old-scale catalog effects replaced |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Labor | 110 | 108 | 2 | 21 | 110 | 109 | 110 | 21 | 25 | 0 | 2 |
| Production | 278 | 58 | 220 | 32 | 278 | 115 | 278 | 32 | 33 | 2 | 7 |
| Infrastructure | 111 | 86 | 25 | 25 | 111 | 105 | 111 | 25 | 10 | 0 | 5 |

- **All 499 items have a row.** Each row has its own `effects`, an in-world observation and an `art` path to an existing painting.
- **Every key threshold has an `ability_reason`.** No text uses a real person, firm, place or trade name. For example, "clinker cement" is used instead of the place name, "polyamide" instead of the trade name, and there are no named engines or processes.
- **Names.** Every NEW id has a short name. Catalog ids keep their authored names unless the name was a specification phrase, for example "Graded Grinding Wheels", "Go and No-Go Gauges", "Spark Die Sinking" and "Microprocessors".
- **Observations.** All 247 catalog ids get new observations. The authored ones were specification text, such as "Specify and verify compatible dimensional ranges across separately made components".
- **Effect sizes.** Routine items use 0.001–0.008, with a median of 0.002–0.003. Key thresholds go up to 0.02:
  - converter, open-hearth, arc-furnace and oxygen steel, and aluminium (metal .02);
  - polyamide fibre (fibre .02);
  - intercepting sewers (sanitation and water safety .02);
  - lifts, structural steel, skeleton towers and public housing (housing .02);
  - arch dams and river-basin works (water .02).
- **Per-line key scales.** The generator scales some keys per line and then clamps them to the .008 and .02 caps. Down-scaled:
  - production: craft, standardization, chemistry, labor efficiency, electronics `knowledge_rate` and health risk;
  - labor: coordination, cohesion and legitimacy;
  - infrastructure: fuel efficiency, route, haul and legitimacy.

  Up-scaled: metal, tools, fibre, extraction and containers in production; construction, housing, resilience, water, sanitation and health protection in infrastructure.

## Recipes kept

- **No `production_items` or `production_contract` is written.** The 206 catalog ids with recipes keep their authored recipes and contracts unchanged. A headless dump checked this: all 206 recipe lists are identical before and after.
- **No NEW id in these lines has a recipe gated on it** in `civilian_industry.gd`.
- **Two resource gates added** (stage `recognized`, sample sufficient): `stainless_steel` (Nickel Ore) and `catalytic_cracking` (Crude Oil). Design conditions already cover Coal, Sulfur, Uranium Ore, Crude Oil for the wells, and Bitumen.

## Effect totals per sub-dimension

Figures are raw sums of each line's own items, before adoption and era ceilings.

- **Total at 1800** is the cumulative total of the line over blocks 0–1800. It comes from a headless dump of this worktree: the live effects plus `BASE_EFFECTS`.
- **The 1800–2400 block is not filled yet.** Its effect files are still empty stubs, so its NEW ids carry only the loader's per-line defaults. **START 2400 (projected)** therefore assumes that block adds about 38% on each key, as the 600–1200 and 1200–1800 blocks did. Recompute once that block is filled.
- **+by 2700** is the mid-window figure. **+by 3000** is what this block adds in total.
- **Growth** is +by 3000 divided by projected START.

### Labor

| Sub-dimension | Key | Total at 1800 | 1200–1800 added | START 2400 (projected) | +by 2700 | +by 3000 | END 3000 (projected) | Growth |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Work efficiency | `labor_efficiency` | +0.342 | +0.063 | +0.472 | +0.037 | +0.130 | +0.601 | +27% |
| Coordination | `task_coordination` | +0.240 | +0.059 | +0.331 | +0.066 | +0.119 | +0.450 | +36% |
|  | `standardization` | +0.088 | +0.033 | +0.122 | +0.024 | +0.052 | +0.174 | +43% |
| Output | `craft_output` | +0.148 | +0.029 | +0.205 | +0.008 | +0.040 | +0.245 | +20% |
| Institutional | `state_capacity` | +0.140 | +0.035 | +0.193 | +0.034 | +0.053 | +0.246 | +27% |
|  | `institutional_rigidity` | +0.218 | +0.062 | +0.301 | +0.046 | +0.084 | +0.385 | +28% |
|  | `adoption_rate` | +0.029 | +0.004 | +0.041 | -0.019 | -0.025 | +0.016 | -62% |
| Social | `cohesion` | +0.101 | +0.020 | +0.139 | +0.035 | +0.069 | +0.207 | +50% |
|  | `legitimacy` | +0.013 | +0.006 | +0.018 | +0.017 | +0.026 | +0.044 | small base |
| Training | `knowledge_preservation` | +0.071 | +0.022 | +0.099 | +0.026 | +0.039 | +0.138 | +40% |
| Able workforce | `injury_risk` | -0.057 | +0.006 | -0.079 | -0.035 | -0.043 | -0.122 | +54% |
|  | `fatigue` | -0.097 | +0.019 | -0.134 | -0.022 | -0.042 | -0.176 | +31% |
|  | `health_protection` | +0.004 | +0.000 | +0.006 | +0.014 | +0.031 | +0.036 | small base |
| Workload | `labor_demand` | -0.050 | -0.028 | -0.069 | +0.026 | +0.043 | -0.026 | -62% |

### Production

| Sub-dimension | Key | Total at 1800 | 1200–1800 added | START 2400 (projected) | +by 2700 | +by 3000 | END 3000 (projected) | Growth |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Material supply | `metal_yield` | +0.705 | +0.112 | +0.973 | +0.162 | +0.254 | +1.227 | +26% |
|  | `fiber_yield` | +0.303 | +0.050 | +0.418 | +0.053 | +0.098 | +0.516 | +23% |
|  | `extraction_yield` | +0.223 | +0.024 | +0.308 | +0.012 | +0.062 | +0.370 | +20% |
| Tools | `tool_quality` | +0.494 | +0.064 | +0.681 | +0.166 | +0.235 | +0.916 | +35% |
|  | `repair_capacity` | +0.156 | +0.016 | +0.215 | +0.044 | +0.060 | +0.275 | +28% |
| Craft capacity | `craft_output` | +0.539 | +0.096 | +0.744 | +0.134 | +0.210 | +0.954 | +28% |
|  | `container_capacity` | +0.615 | +0.029 | +0.849 | +0.040 | +0.086 | +0.935 | +10% |
| Standardization | `standardization` | +0.290 | +0.042 | +0.400 | +0.084 | +0.134 | +0.534 | +34% |
| Chemistry | `chemical_control` | +0.116 | +0.008 | +0.160 | +0.038 | +0.085 | +0.245 | +53% |
| Electronics | `knowledge_rate` | +0.043 | +0.000 | +0.059 | +0.007 | +0.047 | +0.107 | +80% |
| Fuel | `fuel_efficiency` | +0.493 | +0.021 | +0.680 | +0.111 | +0.200 | +0.880 | +29% |
| Costs | `fuel_demand` | +0.299 | +0.067 | +0.413 | +0.084 | +0.171 | +0.583 | +41% |
|  | `pollution` | +0.193 | +0.034 | +0.266 | +0.096 | +0.110 | +0.376 | +41% |
|  | `water_pollution` | +0.043 | +0.022 | +0.059 | +0.026 | +0.038 | +0.097 | +64% |
|  | `health_risk` | +0.055 | +0.009 | +0.076 | +0.035 | +0.055 | +0.130 | +72% |
|  | `injury_risk` | -0.002 | +0.001 | -0.002 | +0.036 | +0.037 | +0.035 | small base |
|  | `ecological_pressure` | +0.008 | +0.004 | +0.011 | +0.006 | +0.026 | +0.037 | small base |
|  | `labor_demand` | +0.032 | -0.010 | +0.044 | -0.014 | -0.063 | -0.019 | -143% |
|  | `cohesion` | +0.004 | +0.002 | +0.005 | -0.012 | -0.030 | -0.025 | small base |

### Infrastructure

| Sub-dimension | Key | Total at 1800 | 1200–1800 added | START 2400 (projected) | +by 2700 | +by 3000 | END 3000 (projected) | Growth |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| Construction | `construction_rate` | +0.536 | +0.099 | +0.739 | +0.142 | +0.220 | +0.959 | +30% |
| Housing | `housing_output` | +0.582 | +0.112 | +0.803 | +0.077 | +0.128 | +0.931 | +16% |
| Resilience | `disaster_resilience` | +0.495 | +0.105 | +0.682 | +0.078 | +0.177 | +0.859 | +26% |
|  | `disaster_risk` | -0.049 | +0.000 | -0.067 | -0.005 | -0.012 | -0.079 | +18% |
| Public works | `water_access` | +0.522 | +0.069 | +0.720 | +0.024 | +0.085 | +0.806 | +12% |
|  | `water_safety` | +0.233 | +0.013 | +0.322 | +0.035 | +0.062 | +0.383 | +19% |
|  | `sanitation` | +0.151 | +0.025 | +0.208 | +0.064 | +0.084 | +0.291 | +40% |
|  | `health_protection` | +0.163 | +0.021 | +0.225 | +0.038 | +0.070 | +0.295 | +31% |
|  | `disease_exposure` | -0.095 | -0.002 | -0.131 | -0.018 | -0.022 | -0.153 | +17% |
| Transport | `route_speed` | +0.079 | +0.029 | +0.109 | +0.043 | +0.049 | +0.157 | +45% |
|  | `haul_capacity` | +0.068 | +0.024 | +0.094 | +0.035 | +0.040 | +0.134 | +43% |
| Power | `fuel_efficiency` | +0.009 | +0.009 | +0.012 | +0.015 | +0.058 | +0.071 | small base |
| Civic | `legitimacy` | +0.102 | +0.032 | +0.141 | +0.013 | +0.022 | +0.163 | +15% |
| Costs | `labor_demand` | +0.597 | +0.071 | +0.824 | +0.045 | +0.055 | +0.879 | +7% |
|  | `fuel_demand` | +0.087 | +0.008 | +0.120 | +0.070 | +0.058 | +0.178 | +48% |
|  | `pollution` | +0.000 | +0.000 | +0.000 | +0.029 | +0.007 | +0.007 | small base |
|  | `ecological_pressure` | +0.016 | +0.004 | +0.022 | +0.014 | +0.051 | +0.073 | small base |
|  | `injury_risk` | -0.001 | -0.003 | -0.001 | +0.027 | +0.028 | +0.027 | small base |

### Reading the growth figures

- **Main keys grow 25–45%.** This covers labor efficiency, coordination, state capacity, tools, metal, craft, standardization, fuel efficiency, construction, resilience, sanitation, health protection, route and haul. None of them doubles.
- **Keys held lower on purpose.**
  - *Near clamps.* Projected END totals are close to or past their clamps for water access (.81 of .80), housing (.93 of .90), disaster resilience (.86 of .80), containers (.94 of 1.2) and craft (.95 of 1.0). These keys grow only 10–28%. All-line raw totals at 1800 are already past the clamp for labor efficiency, craft, trade, state capacity, legitimacy and institutional rigidity, so labor craft (+20%) and civic legitimacy (+15%) stay small.
  - *Shared with other lines.* Water safety (+19%) is shared with Health, which carries filtration and chlorination. Electronics `knowledge_rate` belongs mostly to Knowledge; production adds only +.047.
- **Faster-growing keys.** Chemistry (+53%) and production `knowledge_rate` (+80% on a small base) grow faster because this window invents industrial chemistry and the transistor.
- **Pacing.** About 55–70% of each main key lands by 2700 (AD 1912), with steam, steel, sewers and the factory acts. The rest comes from the assembly line, polymers, electronics and the welfare-era labor settlement.
- **Costs grow alongside benefits.**
  - Production `pollution` +41%, `fuel_demand` +41%, `water_pollution` +64% and `health_risk` +72%. Industrial chemistry and heavy industry are the benchmark reason why a production focus raises infant mortality and lowers life expectancy in `BENCHMARKS_FOCUS_3000.md`.
  - Production `injury_risk` goes from −.002 to +.035.
  - Infrastructure `fuel_demand` +48%, and `injury_risk` rises by .028 from caissons, tunnels and steelwork.
  - Labor `institutional_rigidity` +28%. Labor `labor_demand` turns from saving (−.05) toward cost (+.043), because shorter hours and child-labor bans need more hands.
- **Cleanup comes late.** Pollution cuts after 2800 (AD 1950) come from oxygen and hydrogen-reduced iron, sulphur recovery, wind, solar, nuclear, heat pumps and low-carbon cement. They take infrastructure's net pollution from +.029 at 2700 back to +.007, but never below zero. Production still ends at +.110.

## Key thresholds

| Year | Item | Main effects |
|---:|---|---|
| 2408 | `first_factory_act` | fatigue −.012, injury −.006, health risk −.004; labor demand +.004, rigidity +.003 |
| 2408 | `punched_card_loom_control` | fibre .0096, craft .006; labor demand −.004, cohesion −.003 |
| 2410 | `high_pressure_steam_engines` | craft .007, fuel efficiency .004; pollution +.009, fuel +.0068, injury +.003 |
| 2422 | `gas_lit_streets` | security .008, legitimacy .003; fuel +.006, pollution +.005, fire risk +.002 |
| 2424 | `interchangeable_component_fits` | standardization .0094, repair .0064, tools .0052; rigidity +.003 |
| 2464 | `combination_ban_repeal` | cohesion .0036, coordination .003; adoption −.004 |
| 2464 | `portland_cement_clinker` ("Clinker Cement") | construction .0156, resilience .0084; fuel +.006, pollution +.006, dust health risk +.002 |
| 2488 | `factory_inspectorate` | injury −.008, fatigue −.008, state .006; labor demand +.004 |
| 2490 | `chattel_bondage_abolition` | legitimacy .0048, efficiency .0046, rigidity −.003; trade −.004 |
| 2483 / 2492 | `electrical_generators` / `electric_motors` | fuel efficiency .01 / craft .006, efficiency .0042, tools .0039 |
| 2508 | `sulphur_cured_rubber` | containers .01, craft .005; ecological pressure +.003 |
| 2525 | `ten_hour_day` | fatigue −.014; labor demand +.006, efficiency −.0023 |
| 2539 | `safety_lifts` | housing .02, construction .0039 |
| 2550 | `pneumatic_steel_converter` | metal .02; pollution +.0105, injury +.004 |
| 2550 | `intercepting_sewers` | sanitation .02, water safety .02, health .01, disease −.008; labor demand +.005 |
| 2554 | `coal_tar_dyes` | fibre .0048, chemistry .0042; water pollution +.0035, health risk +.002 |
| 2557 | `fuel_refining` | fuel efficiency .01; pollution +.006, fire risk +.003 |
| 2573 | `open_hearth_steel` | metal .02; pollution +.0075, fuel +.0051 |
| 2619 | `central_power_stations` | efficiency .004, fuel efficiency .0035; fuel +.008, pollution +.007 |
| 2625 / 2627 | `structural_steel` / `reinforced_concrete` | housing .02, construction .018 / construction .018, resilience .014 |
| 2630 | `aluminum_electrolysis` | metal .02; fuel +.0059, pollution +.006 |
| 2644 | `child_labor_prohibition` | knowledge preservation .008; labor demand +.006, craft −.002 |
| 2655 | `hydroelectric_stations` | fuel −.006; ecological pressure +.006 |
| 2670 | `electric_arc_furnaces` | metal .02; fuel +.0051 |
| 2696 / 2701 | `work_motion_studies` / `moving_assembly_line` | efficiency .0138 / .0161, standardization .006 / .01; fatigue +.004 / +.008, cohesion − |
| 2700 | `labor_ministry` | state .01; rigidity +.004 |
| 2708 | `catalytic_ammonia_synthesis` | extraction .018, chemistry .0056; fuel +.0068, pollution +.006 |
| 2715 / 2752 | `concrete_arch_dams` / `river_basin_works` | water .02, resilience; ecological pressure +.008, cohesion − (drowned valleys) |
| 2717 | `eight_hour_day_law` | fatigue −.014; labor demand +.008 |
| 2725 | `public_housing_estates` | housing .02, sanitation .009; rigidity +.003 |
| 2759 / 2764 | `thermoplastic_processing` / `polyamide_synthetic_fibre` | containers .012 / fibre .02; ecological pressure +.004 |
| 2760 / 2768 | `collective_bargaining_law` / `national_minimum_wage` | cohesion, legitimacy; rigidity +.003–.004, adoption −.004, trade −.002 |
| 2771 | `jet_propulsion` | route .012; fuel +.0068, pollution +.006; warfare readiness .004 |
| 2805 | `oxygen_steelmaking` | metal .02, fuel efficiency .006; pollution +.0075, labor demand −.004 |
| 2812 | `nuclear_power_stations` | fuel −.008, pollution −.002; disaster risk +.005, health risk +.003, legitimacy −.0012 |
| 2825 / 2853 | `integrated_circuits` / `single_chip_processors` | knowledge rate .005, coordination .006; labor demand −.003 |
| 2826 / 2829 | `numerical_machine_control` / `industrial_robots` | tools .0078 / labor demand −.006, cohesion −.004 |
| 2845 | `lean_production` | craft .01, standardization .008; fatigue +.004 |
| 2850 | `occupational_safety_agency` | injury −.012, health risk −.008; rigidity +.004 |
| 2902 | `lithium_ion_cells` | fuel efficiency .014; ecological pressure +.004 |
| 2948 | `platform_gig_work` | efficiency .0069; fatigue +.003, injury +.003, cohesion −.0027 |
| 2990 | `hydrogen_reduced_iron` | pollution −.018, metal .012 |
| 2990 | `machine_assistant_desk_work` | efficiency .0138; labor demand −.008, cohesion −.0027 |

Other key thresholds that are not listed are tunnelling shields, chain, steel and wire suspension bridges, iron-and-glass halls, boulevard rebuilding, skeleton towers, AC grids, rural electrification, prestressed concrete, reactor engineering, photovoltaics, grid batteries, precision toolrooms, basic machine shops, internal combustion, steam turbines, contact acid, phenolic moulding, powered flight, junction transistors, EUV lithography, equal pay, accident insurance and union legal standing.

## Weapons and generals

- **No item here is usable as a weapon.** Production and infrastructure items that are military-adjacent carry only small `warfare_readiness` shares. Jet propulsion has .004. Steam propulsion, internal combustion, powered flight, ammonia synthesis, synthetic rubber and airframes each have .002.
- **Nuclear and explosive-feedstock items carry no `warfare_readiness` at all.** This covers `reactor_engineering`, `nuclear_power_stations`, `small_modular_reactors` and `aromatic_nitration`. Their effects are civilian: power, fuel and chemistry, with disaster and health costs.
- **Labor.** Only `total_labor_mobilization` has a readiness share (.002).
- **Generals.** Nothing in these lines gives a general new means.

## Costs introduced

- **Pollution and fuel.**
  - Production has 29 polluting items (+.141 before cleanups) and 69 fuel-demanding items (+.177). The main ones are engines, converter and open-hearth steel, coal gas, refining, aluminium, ammonia and jets.
  - Infrastructure adds smoke from gas lighting, cement, power stations and refuse destructors (+.031), and fuel demand across 42 items (+.112).
- **Dirty water.** Water pollution comes from dyes, coal gas, refining, wood pulp, nitration, electroplating, wafer and solar-cell fabrication, and early sewers that discharge downstream.
- **Workplace injury.**
  - Production (+.055 over 26 items): converters, engines, power looms, steam hammers and machine shops.
  - Infrastructure (+.034): tunnelling shields, pneumatic caissons, rock drills and bridge steelwork.
  - Labor: butty gangs, penal camps, the assembly line, total mobilization and gig work.
  - Toxic trades add `health_risk` (+.055 over 43 production items): dyes, lead oxide, phenolics, isocyanates, matches, nitration, grinding dust and rayon solvent.
  - Against these, the factory acts, inspectorate, accident insurance and the safety agency cut labor `injury_risk` by .043 in total.
- **Urban crowding.**
  - Back-to-back terraces, sweated home work, indentured migration and harvest gangs add `disease_exposure` and fire risk.
  - Boulevard rebuilding costs housing (−.0072) and cohesion as slums are cleared.
  - Model dwellings, sewers and public housing reduce disease.
- **Items with no separate cost.** 110 production items carry no cost of their own: fasteners, gauges, lathe fittings, laboratory methods and logic-circuit steps. Their costs sit upstream, in the steel, engines, fuel and chemistry that they depend on. Labor has 19 items with no cost, and infrastructure 13.
- **Displacement and strain.** Power looms, punched-card looms, block machines, sewing machines, robots, CAD and machine assistants lower `labor_demand` and `cohesion`. Handloom distress, lockouts, deregulation and platform work cost cohesion and legitimacy.
- **Fatigue.** The assembly line, time study, lean production, overlookers and algorithmic management add fatigue.
- **Rigidity.** Arbitration courts, the labor ministry, bargaining law, codes and zoning raise `institutional_rigidity` (+.093 over 34 labor items) and lower `adoption_rate`.
- **Ecology.** Dams, river-basin works, hydroelectric stations, plastics, battery metals and oil wells add `ecological_pressure` (infrastructure +.052, production +.036).
- **Nuclear risk.** Reactors add `disaster_risk` and `health_risk`, and nuclear stations cost a little legitimacy.

## Catalog ids replaced

- **14 catalog ids had old-scale authored effects of .035–.12, and all were replaced.** For example:
  - `graphite_crucibles` had metal .10, craft .08 and chemistry .05;
  - `steam_propulsion` had warfare .035;
  - `safety_lifts` and `structural_steel` had housing and construction .12.

  `work_motion_studies` (fatigue .08) and `work_rest_limits` are the two labor catalog ids.
- **The other 233 catalog ids had empty effects.** All now have effects at the new scale.

## Missing recipes (proposals for Phase 3)

No recipes were added. These NEW items have none:

| Item | Needs |
|---|---|
| `high_pressure_steam_engines`, `compound_steam_engines`, `steam_turbines`, `compression_ignition_engines` | Engine and turbine recipes (Iron, Coal) feeding the existing electric-motor and generator routes |
| `hot_blast_smelting`, `pneumatic_steel_converter`, `open_hearth_steel`, `oxygen_steelmaking`, `scrap_steel_minimills`, `hydrogen_reduced_iron` | Bulk-steel recipes. `blast_pig_iron` exists, but there is no converter or hearth steel. The hydrogen route also needs a hydrogen feed from `green_hydrogen_electrolysis`. |
| `coal_gas_works`, `gas_lit_streets` | A "Town Gas" recipe from Coal, plus a gasholder facility |
| `sulphur_cured_rubber`, `synthetic_rubber` | A **natural rubber / latex** resource and a "Cured Rubber" recipe |
| `coal_tar_dyes`, `ammonia_soda_process`, `electroplating`, `friction_matches` | Dyestuff, soda-ash, plating-bath and match recipes |
| `celluloid_moulding`, `phenolic_resin_moulding`, `regenerated_cellulose_fibre`, `polyamide_synthetic_fibre`, `plant_based_plastics` | Plastic and synthetic-fibre recipes. Polymer catalog recipes such as `radical_ldpe_resin` exist, but none for these. |
| `continuous_paper_machine`, `wood_pulp_paper` | A machine-paper route. `pressed_paper` exists but is gated elsewhere. |
| `iron_power_loom_sheds`, `steam_hammer_forging`, `machine_block_line` | Power-loom cloth, heavy forging and block-making facilities |
| `integrated_circuits`, `single_chip_processors`, `surface_mount_assembly`, `flat_panel_displays`, `deep_submicron_lithography`, `extreme_ultraviolet_lithography`, `wide_bandgap_power_chips` | Chip-fabrication recipes above the existing catalog transistor and logic recipes |
| `lithium_ion_cells`, `iron_phosphate_cells`, `solid_state_battery_cells`, `grid_scale_batteries` | A **Lithium** resource and cell recipes |
| `perovskite_tandem_cells`, `solid_state_lighting`, `filament_lamp_works`, `fluorescent_lighting` | Lamp and cell recipes |
| `central_power_stations`, `hydroelectric_stations`, `nuclear_power_stations`, `combined_cycle_stations`, `pumped_storage_hydro`, `wind_turbine_farms`, `offshore_wind_farms`, `small_modular_reactors` | Power-plant facilities. This is facility work for Infrastructure and needs code. |
| `intercepting_sewers`, `egg_shaped_sewers`, `activated_sludge_treatment`, `nutrient_removal_treatment`, `seawater_desalination`, `steam_pumped_waterworks` | Sewer and waterworks facilities |
| `float_glass`, `plate_glass_shopfronts` | A flat-glass recipe (the "Window Glass" recipe proposed in earlier blocks) |
| `industrial_robots`, `collaborative_robots`, `flexible_machining_cells`, `additive_manufacturing`, `metal_powder_printing`, `carbon_fibre_composites` | Automation and composite recipes |
| `low_carbon_cement`, `printed_concrete_houses` | Variants of the clinker-cement recipe |

Labor items are work regimes, not goods, and need no recipes.

## Validation

- `test_research_blocks.gd` passes 7/7 and `test_research_3000.gd` passes 5/5.
- The generator checks every effect name against `SocietyModel.EFFECT_LIMITS` and its bounds. It also checks the .008 and .02 caps, an `ability_reason` on every key threshold, a name on every NEW id, and that every art path exists. It found no problems.
- **Headless merge check.** `DiscoverySystem.initialize()` was run and each of the 499 rows was compared with the live definition. Every effect, name, observation and art path merged, with 0 mismatches. The 206 catalog recipe lists are unchanged.
- The three JSON files are valid.

The per-item source data (four data files authored in parallel), the generator, the scale table and the patch are in the session scratchpad (`p2lpi3000/`), not in the repository.
