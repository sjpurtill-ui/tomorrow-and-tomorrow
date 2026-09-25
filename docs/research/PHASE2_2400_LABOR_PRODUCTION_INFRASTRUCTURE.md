# Phase 2, years 1800–2400: Labor, Production and Infrastructure effects

Files: `data/research/effects_y1800_2400/labor.json`, `production.json` and `infrastructure.json`. They hold data only: no saved state and no script changes.

## Counts

| Line | Items | NEW | Catalog | Key thresholds | `effects` | `name` | `observation` | `ability_reason` | `social_consequence` | `resource_requirements` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Labor | 99 | 99 | 0 | 14 | 99 | 99 | 99 | 14 | 37 | 0 |
| Production | 106 | 87 | 19 | 21 | 106 | 87 | 106 | 21 | 7 | 19 |
| Infrastructure | 90 | 84 | 6 | 22 | 90 | 84 | 90 | 22 | 5 | 0 |

- **Coverage.** All 295 items have a row. Every row has its own `effects`, an in-world observation and an `art` path to an existing painting.
- **Key thresholds.** Every key threshold has an `ability_reason`.
- **Names.** Every NEW id gets a short name, such as "Mill Hands" or "Turnpike Trusts". The 25 catalog ids keep their authored names.
- **Real names.** No text uses a real historical name or place. `saint_monday_custom` is shown as "Idle Monday". The arsenal, palace, canals and engines are unnamed, and no saint's or church feast name is used.
- **Effect sizes.**
  - Routine items use 0.001–0.008 per effect, with a median of 0.002.
  - Key thresholds go up to 0.02. The largest are:
    - `puddling_furnace` (metal .02)
    - `roller_water_frame` (fibre .02)
    - `steel_refining` (tools .0196)
    - `coke_firing` (metal .018)
    - `mule_spinning` (fibre .018)
    - `cementation_blister_steel` (tools .017)

## Clamp keys (scaled down)

The raw all-lines totals at 1800 were measured with a headless dump of every item in blocks 0–1800. Many keys were already at or past their clamps:

| Key | All lines at 1800 | Clamp | This block's LPI share | Scale used (L / P / I) |
|---|---:|---:|---:|---|
| `institutional_rigidity` | .99 | .55 | +.018 | .7 / – / .7 |
| `legitimacy` | .84 | .55 | −.004 | .6 / .5 / .35 |
| `state_capacity` | 1.19 | .90 | +.030 | .5 / – / .5 |
| `knowledge_preservation` | 1.07 | .85 | +.014 | .5 / .5 / .5 |
| `trade_capacity` | 1.18 | 1.0 | +.081 | .5 / .5 / .5 |
| `security_efficiency` | .90 | .80 | +.000 | – / – / .5 |
| `standardization` | .88 | .80 | +.075 | .6 / .5 / .45 |
| `task_coordination` | .70 | .65 | +.055 | .6 / .6 / .6 |
| `warfare_readiness` | 1.07 | 1.0 | +.014 | .5 / .5 / .5 |
| `cultivation_yield` | .91 | .90 | +.022 | .5 / – / .5 |
| `labor_efficiency` | .53 | .55 | +.049 | .4 / .35 / .5 |
| `cohesion` | .51 | .55 | −.013 | .7 / .7 / .7 |
| `housing_output` | .83 | .90 | +.083 | – / .8 / .8 |
| `disaster_resilience` | .75 | .80 | +.053 | – / – / .7 |
| `craft_output` | .91 | 1.0 | +.106 | .4 / .4 / .7 |

- **`labor_demand`.** Its all-lines raw total is 2.66 against a .35 clamp. New upkeep there changes nothing, so labor-saving items matter more.
- **Mechanised crafts.** Because the craft, efficiency and standardization shares are scaled down, the key thresholds show little of those keys: the stocking frame, flying shuttle, manufactory and rotative engine. Their weight falls on the unclamped keys instead: fibre, metal, tools, extraction, mining and chemistry.
- **Keys scaled up.** Some keys have headroom (metal .72 of 1.2, tools .52 of .9, fibre .40 of .9). Production scales them up so that coke smelting, puddling, cast steel and machine spinning show at the historical scale: metal ×1.3, fibre ×1.3, tools ×1.4.
- **Route and haul.** Infrastructure route and haul are halved (×.5). Without that, turnpikes and canals would have nearly tripled the previous block's additions.
- **Costs.** Labor `fatigue` (×.75) and `health_risk` (×.7) are trimmed so that the costs of the labor focus stay near the benchmark e0 penalty (about 1–1.5 years).

## Effect totals per sub-dimension

Figures are raw sums before adoption and era ceilings.

- **START (1800)** is this line's cumulative total over blocks 0–600, 600–1200 and 1200–1800, taken from the live catalog in a headless dump.
- **+by 2100** and **+by 2400** are what this block adds by that year (proposed year ≤ Y).
- **Prev. block** is what 1200–1800 added.

### Labor

| Sub-dimension | Key | START 1800 | Prev. block | +by 2100 | +by 2400 | END 2400 | Growth |
|---|---|---:|---:|---:|---:|---:|---:|
| Work efficiency | `labor_efficiency` | +.262 | +.063 | +.012 | +.029 | +.291 | +11% (clamp) |
| Coordination | `task_coordination` | +.240 | +.059 | +.030 | +.050 | +.290 | +21% (clamp) |
|  | `cohesion` | +.071 | +.020 | −.011 | −.007 | +.064 | −10% (cost) |
| Workload balance | `fatigue` | −.037 | +.019 | +.016 | +.029 | −.008 | cost |
|  | `labor_demand` | −.050 | −.028 | −.043 | −.058 | −.108 | labor saved |
| Able workforce | `health_risk` | −.076 | −.003 | +.018 | +.030 | −.046 | cost |
|  | `injury_risk` | −.028 | +.006 | +.013 | +.021 | −.007 | cost |
| Institutional | `state_capacity` | +.120 | +.035 | +.011 | +.018 | +.138 | +15% (clamp) |
|  | `institutional_rigidity` | +.218 | +.062 | +.027 | +.015 | +.233 | +7% |
|  | `adoption_rate` | +.029 | +.004 | −.002 | +.020 | +.049 | +69% |
|  | `legitimacy` | +.013 | +.006 | −.014 | −.015 | −.002 | cost |
| Output | `craft_output` | +.148 | +.029 | +.010 | +.023 | +.172 | +16% (clamp) |
|  | `standardization` | +.088 | +.033 | +.014 | +.023 | +.111 | +26% |
|  | `construction_rate` | +.072 | +.022 | +.013 | +.025 | +.097 | +35% |
|  | `food_output` | +.063 | +.022 | +.025 | +.029 | +.092 | +46% |
|  | `mining_output` | +.021 | +.008 | +.026 | +.031 | +.052 | small base |
|  | `fiber_yield` | +.004 | +.004 | +.005 | +.026 | +.030 | small base |
|  | `naval_capacity` | +.026 | +.013 | +.018 | +.021 | +.047 | small base |

### Production

| Sub-dimension | Key | START 1800 | Prev. block | +by 2100 | +by 2400 | END 2400 | Growth |
|---|---|---:|---:|---:|---:|---:|---:|
| Material supply | `metal_yield` | +.675 | +.112 | +.055 | +.146 | +.821 | +22% |
|  | `fiber_yield` | +.303 | +.050 | +.016 | +.091 | +.395 | +30% |
|  | `extraction_yield` | +.223 | +.024 | +.021 | +.045 | +.268 | +20% |
|  | `mining_output` | +.032 | +.016 | +.014 | +.040 | +.072 | small base |
|  | `chemical_control` | +.116 | +.008 | +.020 | +.055 | +.171 | +47% |
| Tool quality | `tool_quality` | +.474 | +.064 | +.046 | +.078 | +.552 | +17% |
|  | `repair_capacity` | +.156 | +.016 | +.004 | +.018 | +.174 | +12% |
| Craft capacity | `craft_output` | +.449 | +.096 | +.031 | +.075 | +.524 | +17% (clamp) |
|  | `trade_capacity` | +.198 | +.047 | +.030 | +.053 | +.251 | +27% (clamp) |
|  | `container_capacity` | +.395 | +.029 | +.025 | +.052 | +.447 | +13% |
| Standardization | `standardization` | +.290 | +.042 | +.016 | +.043 | +.333 | +15% (clamp) |
| Fuel | `fuel_efficiency` | +.353 | +.021 | +.007 | +.060 | +.413 | +17% |
| Costs | `fuel_demand` | +.259 | +.067 | +.031 | +.085 | +.344 | +33% |
|  | `pollution` | +.163 | +.034 | +.014 | +.068 | +.231 | +42% |
|  | `water_pollution` | +.043 | +.022 | +.010 | +.021 | +.064 | +49% |
|  | `health_risk` | +.055 | +.009 | +.014 | +.029 | +.084 | +53% |
|  | `timber_pressure` | +.165 | +.028 | +.006 | −.014 | +.151 | −9% (coal relieves the woods) |

### Infrastructure

| Sub-dimension | Key | START 1800 | Prev. block | +by 2100 | +by 2400 | END 2400 | Growth |
|---|---|---:|---:|---:|---:|---:|---:|
| Housing | `housing_output` | +.512 | +.112 | +.048 | +.069 | +.581 | +13% (clamp) |
|  | `health_protection` | +.073 | +.021 | +.007 | +.019 | +.092 | +26% |
| Construction | `construction_rate` | +.426 | +.099 | +.044 | +.094 | +.520 | +22% |
| Public works | `water_access` | +.522 | +.069 | +.036 | +.065 | +.587 | +12% |
|  | `sanitation` | +.151 | +.025 | +.016 | +.039 | +.190 | +26% |
|  | `water_safety` | +.143 | +.013 | +.011 | +.020 | +.163 | +14% |
| Resilience | `disaster_resilience` | +.455 | +.105 | +.027 | +.053 | +.508 | +12% (clamp) |
|  | `disaster_risk` | −.049 | .000 | −.001 | −.023 | −.072 | risk falls 47% |
| Transport | `route_speed` | +.079 | +.029 | +.010 | +.040 | +.119 | +51% |
|  | `haul_capacity` | +.068 | +.024 | +.009 | +.034 | +.102 | +50% |
|  | `naval_capacity` | +.098 | +.004 | .000 | +.016 | +.114 | +16% |
| Civic | `legitimacy` | +.102 | +.032 | +.005 | +.010 | +.112 | +10% (clamp) |
|  | `state_capacity` | +.036 | +.006 | +.001 | +.012 | +.048 | +34% |
| Costs | `labor_demand` | +.577 | +.071 | +.019 | +.050 | +.627 | +9% (saturated) |
|  | `fuel_demand` | +.087 | +.008 | .000 | +.011 | +.098 | +13% |
|  | `timber_pressure` | +.070 | +.014 | +.010 | +.010 | +.080 | +14% |

### Reading the growth figures

- **Unclamped keys grow within 30–60%.** These are:
  - fibre +30%
  - chemistry +47%
  - route +51% and haul +50%
  - construction in the labor line +35%
  - food from labor +46%
  - sanitation +26%
  - civic state capacity +34%
- **Clamp keys grow 7–26%.** None doubles the previous block's additions. The one exception is route and haul, which reach ×1.4. That is the turnpike, canal-lock, aqueduct and stone-road era.
- **Pacing follows the stretched calendar.** Only 20–40% of each line's additions land by 2100 (≈ AD 1650). The rest lands in 2100–2400, where one game year is half a historical year: manufactories, coke, engines, machine spinning, puddling, turnpikes, canals and wet docks. Production's metal, fibre and fuel efficiency land mostly after 2200. This follows the benchmark arc, which keeps steam factories and railways for the next window.
- **Metal +22% is modest.** It is carried by the late window: flat-rod pumps, cementation, coke, blowing cylinders and puddling. The earlier centuries grew mostly in scale, not method.
- **Water and resilience grow +12%.** They are already high, and near their clamps across all lines. Their growth comes from pressure mains, bridge waterworks, drainage mills, fireproof building and lightning rods.
- **Benchmarks.** No key implies superhuman output. The block's additions are 5–30% of the START totals. The largest single steps are coke, puddling, the water frame and cast steel, and each is at most .02 before adoption.

## Key thresholds

Effects are shown after scaling.

| Year | Item | Line | Main effects |
|---:|---|---|---|
| 1818 | `tenant_leagues_against_bondage` | L | cohesion +.004, rigidity −.004, adoption +.004, state −.002, legitimacy −.002 |
| 1828 | `hammer_beam_roofs` | I | construction +.008, housing +.005, timber +.003 |
| 1848 | `drainage_windmills` | I | resilience +.006, cultivation +.004, disease −.002 |
| 1858 | `mainspring_fusee_clocks` | P | tools +.008, standardization +.002, coordination +.002 |
| 1860 | `arsenal_sequence_fitting` | L | naval +.012, coordination +.005, construction +.004, warfare +.002; timber +.003 |
| 1860 | `centerless_great_dome` | I | construction +.008, legitimacy +.002; labor demand +.004 |
| 1878 | `clear_crystal_glass` | P | craft, trade, containers and observation +.003 each; fuel +.003, timber +.002 |
| 1896 | `export_estate_labor_dues` | L | food +.006, labor demand −.006; fatigue +.0045, cohesion −.004, rigidity +.004, adoption −.003 |
| 1908 | `mitre_lock_gates` | I | haul +.004, route +.002, water +.002 |
| 1937 | `overseas_bound_estate_labor` (contact) | L | food +.005, trade +.003; health risk +.004, cohesion −.0035, legitimacy −.003 |
| 1940 | `flyer_spinning` | P | fibre +.016 |
| 1958 | `flat_rod_mine_pumps` | P | extraction +.008, mining +.008, metal +.008, mine safety +.003 |
| 1969 | `realm_artisan_statute` | L | standardization +.005, tools +.004, state +.003; rigidity +.0056, adoption −.004 |
| 1974 | `elliptical_arch_bridges` | I | route +.003, construction +.003, resilience +.003 |
| 1985 | `bridge_wheel_waterworks` | I | water +.012, sanitation +.004, water safety +.003 |
| 1990 | `stocking_knitting_frame` | P | craft +.003, labor demand −.003; cohesion −.0014 |
| 1995 | `central_manufactory` | L | craft +.004, standardization +.004, coordination +.004; fatigue +.003, cohesion −.002 |
| 2002 | `parish_poor_law` | L | state +.004, cohesion +.003, health risk −.002; rigidity +.004 |
| 2016 | `cementation_blister_steel` | P | tools +.017, metal +.008; fuel +.006 |
| 2036 | `drained_lake_polders` | I | cultivation +.005, food +.004; labor demand +.004, ecological pressure +.003 |
| 2066 | `fen_drainage_cuts` | I | cultivation +.005, food +.003; ecological pressure +.004, cohesion −.002 |
| 2124 | `axial_palace_gardens` | I | construction +.004, state +.002, legitimacy +.002; labor demand +.006, cohesion −.0014 |
| 2128 | `cast_iron_water_mains` | I | water +.010, water safety +.004, sanitation +.003 |
| 2132 | `privileged_crown_manufactories` | L | tools +.005, craft +.003, standardization +.003, trade +.0025 |
| 2148 | `lead_crystal_glass` | P | observation +.004, craft +.003; health risk +.002 |
| 2166 | `water_lifting_machine` | I | water +.008; labor demand +.004 |
| 2176 | `cast_plate_glass` | P | craft +.003, housing +.003, health protection +.002; fuel +.004 |
| 2198 | `steam_suction_pump` | P | extraction +.008, mining +.008; fuel +.006, pollution +.003 |
| 2212 | `turnpike_trust_roads` | I | route +.005, haul +.003, repair +.002 |
| 2220 | `coke_firing` | P | metal +.018, fuel efficiency +.010, timber −.010; pollution +.008, health risk +.002 |
| 2226 | `atmospheric_beam_engine` | P | extraction +.010, mining +.010; fuel +.008, pollution +.004 |
| 2230 | `enclosed_wet_docks` | I | naval +.006, haul +.003, storage loss −.003 |
| 2234 | `bridge_road_engineer_corps` | I | construction +.005, route +.003, state +.002 |
| 2238 | `mill_hand_workforce` | L | fibre +.008, labor demand −.006; fatigue +.0045, health risk +.003, cohesion −.003 |
| 2266 | `flying_shuttles` | P | craft +.004, labor demand −.003; cohesion −.0014 |
| 2276 | `bridge_pier_caissons` | I | construction +.004, resilience +.0035, route +.003; injury +.002 |
| 2282 | `steel_refining` | P | tools +.0196, metal +.008; fuel +.006 |
| 2295 | `lead_chamber_acid` | P | chemistry +.012; pollution +.006, health risk +.003 |
| 2318 | `dovetailed_rock_lighthouse` | I | naval +.006, disaster risk −.003 |
| 2324 | `canal_river_aqueducts` | I | haul +.004, construction +.003, route +.002 |
| 2328 | `multi_spindle_spinning` | P | fibre +.016 |
| 2338 | `roller_water_frame` | P | fibre +.02, labor demand −.004 |
| 2340 | `factory_shift_system` | L | fibre +.008; fatigue +.006, injury +.003, health risk +.003, cohesion −.003 |
| 2341 | `separate_condenser_engine` | P | fuel efficiency +.010, extraction +.006, mining +.006 |
| 2344 | `landless_wage_laborers` | L | food +.004, cultivation +.0025; cohesion −.004, nutrition −.004, health risk +.003 |
| 2350 | `layered_stone_road_beds` | I | route +.005, haul +.003, repair +.003 |
| 2353 | `trade_freedom_edict` | L | adoption +.010, rigidity −.008; cohesion −.003 |
| 2353 | `ministry_office_block` | I | state +.004, coordination +.002; rigidity +.002 |
| 2358 | `mule_spinning` | P | fibre +.018, labor demand −.004 |
| 2359 | `cast_iron_arch_bridge` | I | construction +.004, route +.003, resilience +.002 |
| 2364 | `rotative_steam_engine` | P | craft +.003, labor demand −.003; fuel +.006, pollution +.004 |
| 2368 | `puddling_furnace` | P | metal +.02, timber −.006, fuel efficiency +.004; pollution +.006, fatigue +.003, health risk +.003 |
| 2371 | `precision_machinery` | I | tools +.012, craft +.006, repair +.004 |
| 2374 | `bound_labor_abolition_movement` (contact) | L | cohesion +.004, adoption +.004, legitimacy +.0036; trade −.002 |
| 2378 | `estate_bondage_abolition` | L | rigidity −.007, adoption +.006, cohesion +.004, efficiency +.003 |
| 2385 | `iron_framed_fireproof_mill` | I | resilience +.006, disaster risk −.005, construction +.005 |
| 2385 | `salt_cake_soda` | P | chemistry +.010; pollution +.008, ecological pressure +.003, health risk +.003 |

**Weapons and generals.** Items that touch warfare carry only small `warfare_readiness` shares, each .0015–.002 after scaling:

- `gun_barrel_founding`
- `corned_powder_mills`
- `potash_saltpetre_works`
- `recrystallised_saltpetre`
- `cast_iron_shot_firebacks`
- `iron_plate_hammer_mills`
- `jig_filed_gunlocks`
- `cylinder_boring`
- `arsenal_sequence_fitting`

No item is a weapon of mass destruction, and none grants a general any new capability.

## Costs introduced

- **Bondage and bound labor.** Export-estate labor dues, the rotating mine drafts, bound colliers, the yearly pitmen's bond, convict oarsmen, and the contact-gated overseas bound labor, plantation gangs and indentured passage. These lower `cohesion` and `legitimacy`, raise `institutional_rigidity` and `fatigue`, and add `health_risk` and `injury_risk`. Tenant leagues, abolition societies, the bondage abolition and the collier release reverse part of this, at a cost to lords' `state_capacity` or to `trade_capacity`.
- **Poor law and discipline.** Beggars' badges, vagrancy returns, houses of correction, settlement removals, the workhouse test, pass-books, mill fines and the combination ban. These raise state capacity at the cost of `cohesion`, `legitimacy` and `adoption_rate`.
- **Factory and cottage work.**
  - The manufactory, pin-shop division, mill hands, factory shifts, lace and spinning schools and pauper mill apprentices add `fatigue` and `health_risk`. Mills and shifts also add `injury_risk`.
  - Fewer holy days add fatigue and cost cohesion.
  - Landless laborers lower `nutrition_quality`.
  - Idle Monday gives back fatigue at a cost to efficiency.
- **Displacement.** Gig mills, the ribbon engine, the stocking frame, the flying shuttle, the jenny, the water frame and the mule cut `labor_demand` and cost `cohesion`. Machine breaking costs craft, adoption and legitimacy.
- **Coal, smoke and acid.**
  - Coke, puddling, reverberatory furnaces, coal glasshouses and the engines add `pollution` and `fuel_demand`, while coal eases `timber_pressure`.
  - Copperas, the vitriol globes, lead chambers, chlorine, salt-cake soda and zinc retorts add pollution and `health_risk`. Salt-cake soda also adds `ecological_pressure`.
- **Poisons.** Mercury mirrors, mercury amalgamation yards, carroted fur felt, lead crystal and polychrome glaze add `health_risk`. Amalgamation, indigo, madder, calico printing, vitriol sours and brick sewers draining to the river add `water_pollution`.
- **Explosives and blasting.** Corned powder mills add `disaster_risk`. Powder blasting adds `injury_risk` and lowers `mine_safety`.
- **Town building.**
  - Timber tenements add fire risk and `disease_exposure`.
  - The cut-through avenues and the planned new town cost cohesion.
  - The axial palace, great dome, water machine, drainage cuts and canal works add `labor_demand`.
  - Fen drains and lake polders add `ecological_pressure`, and fen drainage costs the fenmen's cohesion.

## Catalog ids replaced

All 25 catalog ids take new `effects` and in-world observations. They keep their authored names, recipes, contracts and resource gates.

- **Wrong scale.** These had pre-rebalance values:
  - `precision_machinery`: craft .18, tools .16, repair .10, standardization .09. Now tools .012, craft .0056, standardization .0027, repair .004, labor demand +.002.
  - `refractory_furnaces`: fuel efficiency .10, metal .12, craft .08. Now fuel efficiency .005, metal .005, repair .002.
  - `coal_grading`: fuel efficiency .08, survey .03. Now fuel efficiency .004, survey .002, standardization .001.
  - `mine_airways`: mine safety .06. Now mine safety .006, mining .002, health risk −.001.
- **Empty.** The other 21 had no effects:
  - `coke_firing`, `steel_refining`, `flyer_spinning`, `flying_shuttles`, `multi_spindle_spinning`, `mule_spinning`
  - `bolt_blank_forging`, `nut_blank_forging`, `metal_casting_feed_design`, `metal_annealing_control`, `belt_power_transmission`, `mechanical_clutches`, `pressure_vessels`
  - `textile_calendering`, `textile_braiding`, `yarn_tension_control`, `yarn_count_standards`
  - `concrete_mix_design`, `concrete_formwork_systems`, `cylinder_boring`, `pressure_pipe_jointing`
- **Contracts left unchanged.** Some authored `production_contract` texts mention powered or electric routes: `mule_spinning` (`electric_mule_yarn`), `belt_power_transmission`, `mechanical_clutches`, the flyer, shuttle and jenny, and `pressure_pipe_jointing`. They describe recipe behavior ("powered routes consume actual electricity; hand manufacture remains available"), so they were left alone. The electric recipes themselves are gated later.

## Recipes and materials

**`production_items`.** No NEW id in these lines has a recipe gated on it in `civilian_industry.gd`, so none is linked. The catalog ids keep their authored recipes:

- `bolt_blanks`, `nut_blanks`, `flyer_spun_yarn`, `metallurgical_coke`, `shuttle_woven_cloth`, `fed_copper_castings`
- `steel_stock`, `frame_spun_yarn`, `hand_mule_yarn` / `electric_mule_yarn`, `woven_drive_belts` / `belt_drive_sets`
- `textile_finishing_rolls` / `calendered_plant_cloth`, `tensioned_woven_cloth`, `braided_garment_cords`, `measured_yarn`
- `annealed_copper`, `friction_clutches`, the three concretes, `building_formwork`, `bored_cylinders`, `pressure_pipe_fittings`

**`resource_requirements` added.** All use stage `recognized` with `sample_sufficient`:

| Resource | Items |
|---|---|
| Iron Ore | `cast_iron_shot_firebacks`, `cementation_blister_steel`, `rolled_tinplate`, `puddling_furnace` |
| Coal | `reverberatory_furnace`, `puddling_furnace` |
| Clay | `salt_glazed_stoneware`, `soft_paste_porcelain`, `creamware` |
| Fine Sand | `clear_crystal_glass`, `cast_plate_glass` |
| Copper Ore | `brass_battery_works`, `liquation_silver_parting` |
| Lead Ore | `lead_crystal_glass`, `lead_chamber_acid` |
| Silver Ore | `mercury_ore_amalgamation` |
| Sulfur | `globe_oil_of_vitriol`, `lead_chamber_acid`, `salt_cake_soda` |
| Nitrates | `potash_saltpetre_works` |
| Graphite, Refractory Clay | `graphite_clay_crucibles` |

The design conditions already cover these gates: salt, lead, silver, copper, tin and coal knowledge; the river, woodland and coast environments; and contact.

**Missing recipes (proposals for Phase 3).** Nothing below was added.

| Item | Needs |
|---|---|
| `coke_firing` → `puddling_furnace`, `grooved_bar_rolls`, `reverberatory_furnace` | A coal-route "Puddled Bar Iron" recipe that uses `metallurgical_coke`. `wrought_iron` could be re-gated. |
| `cementation_blister_steel`, `steel_refining` | A "Blister Steel" intermediate that feeds `steel_stock` |
| `flat_rod_mine_pumps`, `steam_suction_pump`, `atmospheric_beam_engine`, `separate_condenser_engine`, `rotative_steam_engine`, `double_acting_engine` | Mine-drainage and engine facilities: a pumping engine that consumes coal and clears a flooded-mine blocker, and a rotative mill drive |
| `roller_water_frame`, `cylinder_carding`, `mill_hand_workforce` | A water-powered "Mill-Spun Warp" recipe and a carding facility |
| `stocking_knitting_frame`, `ribbon_engine_loom` | Knitted hosiery and narrow-ware recipes |
| `clear_crystal_glass`, `lead_crystal_glass`, `cast_plate_glass`, `mercury_tin_mirrors` | The "Window Glass" / "Plate Glass" and mirror recipes proposed since 600–1200 |
| `salt_glazed_stoneware`, `soft_paste_porcelain`, `creamware`, `bone_ash_porcelain`, `plaster_mould_slip_casting`, `transfer_printed_ware` | Refined tableware recipes. A **Kaolin** resource is still missing. |
| `lead_chamber_acid`, `globe_oil_of_vitriol`, `chlorine_bleaching`, `salt_cake_soda`, `copperas_works`, `kelp_alkali` | "Oil of Vitriol", "Soda Ash" and "Bleaching Liquor" chemical recipes |
| `potash_saltpetre_works`, `recrystallised_saltpetre`, `corned_powder_mills` | Saltpetre and grained-powder recipes, if the powder supply is ever modelled as stock |
| `zinc_retort_distillation`, `brass_battery_works` | A **Zinc / Calamine** resource and a "Brass Sheet" recipe |
| `rolled_tinplate`, `stoved_varnish_ware` | A rolled, hand-dipped tinplate recipe. The authored tinplate recipes are industrial. |
| `mordant_printed_calico`, `copperplate_calico`, `roller_calico_printing`, `fast_madder_red`, `indigo_vat_dyeing`, `cochineal_scarlet` | A **Cotton** resource (still unmapped) and printed-calico recipes; dye resources for madder, indigo and cochineal |
| `hollander_beater`, `wove_paper_moulds` | A beater route for `pressed_paper` / `rag_pulp` |
| `sugar_loaf_refining`, `carroted_fur_felting`, `turpentine_rosin_distilling`, `coal_tar_pitch` | Refined sugar, felt hats and naval stores (tar, pitch, turpentine) |
| `screw_cutting_lathe`, `gear_cutting_engine`, `screw_tap_and_die`, `jig_filed_gunlocks` | Hand and treadle routes for threaded and indexed parts. The authored machine-tool recipes are later and powered. |
| Infrastructure: `turnpike_trust_roads`, `layered_stone_road_beds`, `canal_river_aqueducts`, `enclosed_wet_docks`, `cast_iron_water_mains`, `vaulted_brick_sewers`, `iron_framed_fireproof_mill` | Undertaking or facility templates. These are road, canal, dock, main, sewer and mill works with real labor and stone or iron costs. |

## Validation

- `test_research_blocks.gd`: 7/7 pass. `test_research_2400.gd`: 6/6 pass.
- **Generator checks.** The generator checks:
  - every effect name against `SocietyModel.EFFECT_LIMITS` and its bounds;
  - the .008 / .02 caps;
  - that every key threshold has an `ability_reason` and every NEW id has a name;
  - that every art path exists;
  - that every resource name exists.

  It found no problems.
- **Headless merge check.** `DiscoverySystem.initialize()` was run, then all 295 rows were compared with the live definitions:
  - every effect, name and observation merged;
  - every `art_key` merged;
  - the added resource gates merged;
  - there were 0 mismatches.
- **The three JSON files are valid.**

The generator and data are in the session scratchpad (`p2lpi2400/`), not in the repository.
