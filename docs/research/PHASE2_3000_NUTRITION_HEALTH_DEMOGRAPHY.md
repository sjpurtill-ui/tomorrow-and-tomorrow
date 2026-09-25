# Phase 2 (2400–3000): nutrition, health and demography effects

Files: `data/research/effects_y2400_3000/nutrition.json`, `health.json` and `demography.json`. Every item of the three lines in `data/research/blocks/y2400_3000.json` has a row.

| Line | Rows | Catalog ids | Key thresholds (`ability_reason`) | `social_consequence` | Rows with a cost |
|---|---:|---:|---:|---:|---:|
| Nutrition | 124 | 36 | 24 | 29 | 55 |
| Health | 126 | 11 | 20 | 19 | 63 |
| Demography | 100 | 1 | 12 | 27 | 55 |

Each row has effects, a one-line in-world observation and an existing painting as `art`. NEW ids also have a short `name`. Every effect name is in `SocietyModel.EFFECT_LIMITS`, and every value is inside its bound.

Checks:

- `test_research_blocks` passes 7/7 and `test_research_3000` passes 5/5.
- A fresh `dump_effects_600.gd` run applies all 350 rows exactly as authored, with no loader warnings.

## How the effects become life expectancy (read this first)

The mortality transition runs through three places:

- `EarlyLifeConditions.burden_relief()`: health_protection, sanitation, water_safety and disease_exposure, each divided by its modern limit, averaged, then raised to the power 2.5.
- The maternal and neonatal factors: maternal_safety and neonatal_survival.
- The conception multiplier: `1 + clamp(conception_support, −.30, .30)`, together with the infant-loss birth-interval feedback.

I rebuilt those formulas, with `_mortality_condition_factor` and the surrogate's `life_expectancy`, as a static calculator. It confirms that **the engine cannot reach the benchmark's modern end state from effects**:

- With all four relief channels at their modern limits, maternal and neonatal safety at .65 and ideal health, food and housing, the engine gives e0 ≈ 50–54 and IMR ≈ 47–60.
- The limit is the baseline life table itself. `BASELINE_HAZARD_BY_AGE[0]` is .09, and the best condition factor is ≈ .44–.56. The burden relief can only remove the era burden. It never goes below the baseline table.
- The benchmark wants e0 58 at 2800, 70 at 2900 and 77 at 3000, and IMR 70 → 30 → 8. **That needs a Phase 3 change**, for example a modern term that scales the baseline table below 1 once relief is complete. It should not be done by inflating effects.
- Fertility is similar. `conception_support` can cut conception by 30% at most, and the infant-loss feedback about 10% more, so TFR bottoms out near 2.8, not 1.7.

So the rows are sized to **follow the benchmark's typical curve century by century until the engine ceiling, and to reach that ceiling around 2800–2850 (not earlier)**. After that, further rows mostly land in the clamp. The era ceilings (`LATER_RISE`: 75% of the modern gap at 2400, 100% at 2800) already hold a society that researches too fast to the benchmark's high row.

Projection with the calculator:

- It assumes all lines, the actual 0–2400 totals (including the now-filled 1800–2400 rows), and this block's other lines as currently filled (Infrastructure adds sanitation +.09 and water_safety +.07; the other lines net +.004 disease_exposure).
- It assumes full adoption, food security .85–.95 and housing 1.0.

| Year | e0 (bench typical) | IMR (bench) | Relief | Fertility vs 2400 → TFR (bench) |
|---|---|---|---:|---|
| 2400 | 34.6–36.3 (34) | 130–140 (185) | .35 | 5.0 (5.0) |
| 2500 | 35.6–37.4 (36) | 124–134 (180) | .41 | 4.9 (4.9) |
| 2600 | 37.5–39.4 (38) | 112–122 (170) | .50 | 4.4 (4.5) |
| 2700 | 41.7–43.9 (45) | 88–98 (130) | .69 | 4.1 (3.8) |
| 2800 | 44.6–47.0 (58) | 74–83 (70) | .80 | 3.9 (3.0) |
| 2900 | 46.6–49.1 (70) | 65–74 (30) | .88 | 2.8 (2.3) |
| 3000 | 48.3–51.0 (77) | 58–67 (8) | .94 | 2.8 (1.7) |

Adoption lag (ADOPTION_PACE) delays each step by years to decades, so live values sit a little below these.

The engine's IMR at 2400 is already below the benchmark (130–140 against 185). That comes from earlier blocks and the baseline table, not from this block.

The fertility fall lags between 2700 and 2800. That era's decline historically came from schooling, child-labour law, towns and the depression, which belong to Culture, Labor and Institutions, and those files carry almost no conception_support. See the notes for the coordinator.

## Sizing

- **Routine rows** are .001–.008. Key thresholds are about .010–.03 on their main channel.
- **Larger key rows.** The brief allows larger values for the mortality and fertility transition, and these rows carry it:
  - **Mortality.** Germ theory −.032, mould antibiotic −.030, chlorination −.026 and sulfa drugs −.020 on disease_exposure. Sulfa drugs also add .026 maternal_safety.
  - **Fertility.** Family limitation −.070, birth-control clinics −.070, the pill −.090, family-planning fieldwork −.055 and small-family campaigns −.045 on conception_support. Adoption spreads these over decades.
- **Food keys** were drafted at historical weight and then scaled so that each sub-dimension grows 30–33% over its year-2400 total: food_storage ×2.2, food_spoilage ×1.7, food_output ×1.3, soil ×1.4 and cultivation ×1.2. Costs were not scaled.
- **Clamps.** Cultivation_yield and nutrition_quality are already at their era ceilings across all twelve lines. Their growth mostly lands in the clamp, the same as last block.

## Effect totals (the three lines only, registry items, full adoption, before clamping)

Taken from a fresh `dump_effects_600.gd`. "Previous" is the 1800 → 2400 change as now filled.

| Sub-dimension | Key | 2400 | 2700 | 3000 | Δ this block | Δ previous block |
|---|---|---:|---:|---:|---:|---:|
| Daily supply | food_output | .520 | .616 | .688 | +.168 (+32%) | +.152 (+41%) |
| Land productivity | cultivation_yield | .739 | .850 | .965 | +.226 (+31%) | +.189 (+34%) |
| | soil_productivity | .271 | .321 | .352 | +.081 (+30%) | +.072 (+36%) |
| Stored reserve | food_storage | .657 | .772 | .860 | +.202 (+31%) | +.138 (+26%) |
| | food_spoilage | −.455 | −.518 | −.587 | −.133 (+29%) | −.085 |
| Diet quality | nutrition_quality | .414 | .477 | .532 | +.118 (+29%) | +.083 |
| General health | health_protection | .458 | .560 | .670 | +.212 (+46%) | +.130 (+40%) |
| Disease control | disease_exposure | −.200 | −.429 | −.583 | **−.383** (gross −.412, costs +.029) | −.061 |
| Injury safety | injury_risk | −.270 | −.288 | −.303 | −.033 | −.068 |
| Treatment harm (cost) | health_risk | .067 | .041 | .003 | −.064 | −.012 |
| Water and waste | sanitation / water_safety | .208 / .193 | .255 / .244 | .258 / .245 | +.050 / +.052 | +.031 / +.014 |
| Maternal safety | maternal_safety | .416 | .517 | .660 | **+.244** (+59%) | +.095 |
| Child survival | neonatal_survival | .440 | .562 | .697 | **+.256** (+58%) | +.106 |
| Fertility conditions | conception_support | .201 | .095 | −.269 | **−.470** | +.013 |
| Shelter | housing_output | .317 | .335 | .337 | +.020 | +.033 |

The bold rows are the transition. Disease control, maternal safety and child survival grow by more than the 30–60% guide because this block holds the modern mortality transition. They are timed by century:

| Channel | 2500 | 2600 | 2700 | 2800 | 2900 | 3000 |
|---|---:|---:|---:|---:|---:|---:|
| disease_exposure (cumulative Δ) | −.023 | −.081 | −.229 | −.305 | −.350 | −.383 |
| maternal_safety | +.002 | +.029 | +.101 | +.192 | +.241 | +.244 |
| neonatal_survival | +.008 | +.027 | +.122 | +.159 | +.235 | +.256 |
| conception_support | −.008 | −.090 | −.106 | −.176 | −.462 | −.470 |

Before 2600 the net is small on purpose. Vaccination, filtration and boards of health are offset by the crowding and migration costs of the industrial towns. Most of the gain comes between 2608 and 2800: germ theory, antitoxin, chlorination, then sulfa drugs and antibiotics.

Across all lines, maternal and neonatal safety reach their .65 limit at about 2860–2880.

Side channels, 2400 → 3000 (these lines only):

| Channel | 2400 | 3000 |
|---|---:|---:|
| state_capacity | .374 | .458 |
| trade_capacity | .188 | .231 |
| labor_efficiency | .184 | .230 |
| labor_demand (cost) | .969 | 1.056 |
| institutional_rigidity (cost) | .342 | .385 |
| ecological_pressure (cost) | .146 | .169 |
| fuel_demand (cost) | .140 | .186 |
| pollution (cost) | .019 | .033 |
| water_pollution (cost) | .010 | .031 |
| chemical_control | .002 | .021 |
| cohesion (net) | .079 | .068 |

## Threshold items

- **Nutrition.**
  - Food retorts (2427), beet sugar (2432), herd books (2459), mechanical reaper (2491).
  - Nutrient response trials and the experiment station (2507, 2515).
  - Plant pathology (2560), farm colleges and ministry (2565), gentle heat treatment (2571), roller milling (2587).
  - Adulteration law (2600), frozen meat trade (2605), diet heat units (2651), heredity experiments (2683), vitamins (2699).
  - Ammonium sulfate, the farm tractor and ration cards (2711–2712), hybrid maize (2736), hazard analysis (2822).
  - Semi-dwarf grain (2838), transgenic crops (2915), gene-edited crops (2970), climate crop planning (3000).
- **Health.**
  - Slow sand filtration (2411), ether (2523), the central board of health (2528), contagion mapping and nursing organisation (2544).
  - Antiseptic surgery (2579), germ theory (2608), sickness insurance (2621), diphtheria antitoxin (2643), chlorination (2688).
  - Insulin (2725), sulfa drugs (2760), the mould antibiotic (2781).
  - The national health service and the controlled trial (2795), the paralysis vaccine (2812).
  - Oral rehydration (2845), smallpox eradication (2872), antiviral therapy (2915), the message-molecule vaccine (2975).
- **Demography.**
  - Household census (2509), mass emigration (2533), homestead grants (2565), family limitation (2595), child growth records (2667).
  - Birth-control clinics (2709), family allowances (2787), the refugee convention (2802), the pill (2825).
  - Test-tube conception (2870), long-term care insurance (2912), managed resettlement (2990).

## Costs introduced

- **Crowding and contagion (disease_exposure +).**
  - Mass emigration .005, the population exchange .003, displaced-persons camps .003 and bottle feeding .003 (which also costs neonatal_survival −.004).
  - Broiler houses .004, crèches .002, assisted emigration and guest workers .002, colony schemes, market gardens on night soil, net-pen fish farms, child evacuation and refugees.
- **Treatment harm (health_risk +).**
  - Radium .003, the arsenical .003, the pure opiate .003, ether and chloroform .002, transfusion before blood typing .002, sulfa drugs and synthetic insecticide .002.
  - Smaller amounts from carbonated waters, preserving jars, sheep dip, iodine, saline, syringes and chlorination.
  - Later trials, drug approval, stewardship and reviews bring the total below zero.
- **Poorer diet (nutrition_quality −).** Roller-milled white flour −.004, starch syrup −.004, beet sugar, margarine and condensed milk.
- **Industrial farming.**
  - Water pollution: ammonium sulfate .004, semi-dwarf grain .004, insecticide .003, broilers .003, net pens .003, and copper, nitrate and phosphate dressings.
  - Pollution: insecticide .005, soluble phosphate .003 and house spraying .003.
  - Ecological pressure: pivot irrigation .005, insecticide .004, semi-dwarf grain .004, guano .003 and homesteads .003.
  - Fuel demand: tractors, combines, glasshouses, refrigerators and frozen foods.
  - Injury risk: reaper .002, tractor .002 and steam threshing .001.
  - Semi-dwarf grain also costs soil_productivity −.003.
- **Upkeep and rigidity.**
  - Labour demand: hospitals, the national health service .005, sickness insurance, boards, inspectors, nurses, clinics and long-term care .004.
  - Rigidity: birth quotas .006, residence permits .004, the practitioner register .003, clean-milk and adulteration law, and pharmacopoeias.
- **Social strain (cohesion and legitimacy −).**
  - State birth quotas (−.010 / −.008), the population exchange (−.004 / −.002), residence permits −.004, mass emigration −.003 and the anatomy law (−.003 / −.002).
  - Compulsory vaccination −.003, guest workers, termination and managed resettlement −.003.
  - Pandemic closures, test-and-trace, transgenic crops and quotas.
- **Trade given up.** Pandemic closures and test-and-trace (−.003 each), origin quotas −.002, ration cards −.002 and outbreak rules.

## Catalog ids whose effects were replaced

- `intensive_gardens` was at food_output .12 and nutrition_quality .08. It is now .004 / .003, plus labour and a small disease cost.
- `contagion_mapping` was at disease_exposure −.16. It is now −.012.
- `child_growth_records` was at neonatal_survival .075. It is now .010.
- `slow_sand_filtration` was at water_safety .06. It is now .015, plus disease_exposure −.007.
- `water_service_inspections` was at .025. It is now .006.

The old values were 0–600 era scale and would have exceeded a whole century's step by themselves. The other 43 catalog ids had empty effects. Their method profiles, such as `food_system.gd` preservation for `food_retorts`, are untouched.

The seven field-medicine ids (`casualty_collection_posts` … `convalescent_duty_reviews`, shared with Security) give injury_risk −, warfare_readiness + and logistics_endurance +. What generals can sustain in the field changes, and the player never commands units.

No row touches weapons of mass destruction.

## Recipes

`production_items` are set only where an existing `civilian_industry.gd` recipe is gated on the id:

| Id | Recipe |
|---|---|
| `food_retorts` | `food_retort` |
| `can_body_forming` | `food_can_sets` |
| `double_seaming` | `seaming_head` |
| `mineral_nitrate_dressing` | `nitrate_fertilizer` |
| `phosphate_dressing` | `ground_phosphate_fertilizer` |
| `phosphate_solubilization` | `soluble_phosphate_fertilizer` |
| `ammonium_sulfate_fertilizer` | `ammonium_sulfate` |

No row sets `resource_requirements`.

Missing recipes (Phase 3 proposals):

| Item | Proposed recipe |
|---|---|
| `root_beet_sugar`, `vacuum_pan_sugar` | Beet sugar works: sugar beet + fuel + lime → sugar |
| `condensed_milk`, `aseptic_carton_milk`, `bottled_town_milk` | Dairy works: milk + sugar or cartons or bottles + fuel → keeping milk |
| `quick_frozen_foods`, `frozen_meat_trade` | Freezing plant: food + power → frozen stores. Needs Infrastructure's `mechanical_refrigeration`. |
| `beef_fat_margarine`, `meat_extract_cubes` | Rendering and extract works: fat or meat + fuel → margarine or extract |
| `roller_grain_milling` | Roller mill: grain + power → flour (a `grain_method` profile) |
| `iodized_salt`, `folic_acid_fortification`, `recommended_daily_allowances` | Fortification: Salt or flour + a trace chemical → fortified staple |
| `synthetic_crop_insecticide`, `selective_hormone_herbicide`, `copper_lime_spray` | Crop chemicals: chemical feedstocks → sprays (an `agronomy_profile`) |
| `hybrid_maize_seed`, `semi_dwarf_grain_package` | Seed works: bred seed lots, as seed stock |
| `oral_rehydration_salts`, `sulfa_drugs`, `mould_broth_antibiotic`, `diphtheria_antitoxin`, vaccines | Pharmaceutical works (`medical_method` profiles): deep-tank fermentation and serum/vaccine lines |
| `water_chlorination` | Chlorine dosing at the waterworks. Needs Production's chlor-alkali. |
| `oral_contraceptive_pill` | Hormone synthesis (pharmaceutical) |

## Notes for the coordinator

- **Engine ceiling (Phase 3).** As explained above, e0 above about 52, IMR below about 50 and TFR below about 2.8 cannot be reached from effects. The benchmark's 2800–3000 rows need a modern-mortality term in `EarlyLifeConditions`/`GameState` (the baseline life table scaled by relief and era) and a fertility-preference term beyond `conception_support`'s −.30 clamp.
- **Other lines and fertility.** The benchmark's 2700–2800 fertility fall (3.8 → 3.0) needs about −.2 more conception_support than these lines give. That decline historically came from compulsory schooling, child-labour law and town life: rows in Culture, Labor and Institutions. Those rows now carry about zero.
- **Starting totals.** The table uses the 1800–2400 NHD rows as filled at the time of this pass. If those change, the 2400 column moves, and this block's deltas do not.
- **Not measured in play.** No surrogate or campaign run was made. The surrogate reads only the 0–600 block.
