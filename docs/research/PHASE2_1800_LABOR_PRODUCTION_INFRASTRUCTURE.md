# Phase 2, years 1200–1800: Labor, Production and Infrastructure effects

Files: `data/research/effects_y1200_1800/labor.json`, `production.json` and `infrastructure.json`. These are data only. They add no saved state and make no script changes.

## Counts

| Line | Items | NEW | Catalog | Key thresholds | `effects` | `name` | `observation` | `ability_reason` | `social_consequence` | `production_contract` | `resource_requirements` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Labor | 86 | 86 | 0 | 12 | 86 | 86 | 86 | 12 | 20 | 0 | 0 |
| Production | 89 | 76 | 13 | 11 | 89 | 76 | 89 | 11 | 12 | 2 | 10 |
| Infrastructure | 72 | 67 | 5 | 9 | 72 | 67 | 72 | 9 | 10 | 0 | 0 |

- **All 247 items have a row.** Each row has its own `effects`, an in-world observation and an `art` path to an existing file.
- **Every key threshold has an `ability_reason`.** No text uses a real historical name.
- **Short names.** Every NEW id gets a short name. The generated names were the full one-liners, for example "Bakers, Shippers and Millers Bound as Hereditary City-supply Corporations". The 18 catalog ids keep their authored names.
- **Effect sizes.**
  - Routine items use 0.001–0.008 per effect, with a median of 0.002.
  - Key thresholds go up to 0.02. The largest are `blast_furnace` (metal .02) and `finery_forges` (metal .019, tools .010).
  - The generator scales some keys per line and clamps them at those limits. Those keys are labor efficiency, craft, trade, state capacity and legitimacy, which are already near their clamp when all lines are summed (see below).

## Effect totals per sub-dimension

Figures are raw sums, before adoption and era ceilings.

- **START (1200)** is the cumulative total of this line over blocks 0–600 and 600–1200. It uses the live catalog's final effects plus `BASE_EFFECTS`, taken from a headless dump of this worktree.
- **+by 1500** and **+by 1800** are what this block adds up to that year (proposed year ≤ Y).
- **Prev. block** is what 600–1200 added.

### Labor

| Sub-dimension | Key | START 1200 | Prev. block | +by 1500 | +by 1800 | END 1800 | Growth |
|---|---|---:|---:|---:|---:|---:|---:|
| Work efficiency | `labor_efficiency` | +0.199 | +0.063 | +0.023 | +0.063 | +0.262 | +32% |
| Coordination | `task_coordination` | +0.181 | +0.060 | +0.032 | +0.059 | +0.240 | +33% |
|  | `cohesion` | +0.051 | +0.021 | +0.012 | +0.020 | +0.071 | +40% |
| Workload balance | `fatigue` | −0.056 | +0.003 | +0.015 | +0.019 | −0.037 | cost |
|  | `labor_demand` | −0.022 | −0.047 | −0.014 | −0.028 | −0.050 | small base |
| Able workforce | `injury_risk` | −0.034 | −0.001 | +0.005 | +0.006 | −0.028 | cost |
|  | `health_risk` | −0.073 | −0.013 | +0.002 | −0.003 | −0.076 | flat |
| Institutional | `state_capacity` | +0.085 | +0.044 | +0.015 | +0.035 | +0.120 | +41% |
|  | `institutional_rigidity` | +0.155 | +0.070 | +0.024 | +0.062 | +0.218 | +40% (cost) |
|  | `adoption_rate` | +0.025 | +0.004 | −0.003 | +0.004 | +0.029 | net small |
| Output | `craft_output` | +0.119 | +0.047 | +0.014 | +0.029 | +0.148 | +25% |
|  | `standardization` | +0.055 | +0.038 | +0.004 | +0.033 | +0.088 | +60% |
|  | `construction_rate` | +0.050 | +0.040 | +0.006 | +0.022 | +0.072 | +44% |
|  | `trade_capacity` | +0.036 | +0.029 | +0.004 | +0.022 | +0.058 | small base |

### Production

| Sub-dimension | Key | START 1200 | Prev. block | +by 1500 | +by 1800 | END 1800 | Growth |
|---|---|---:|---:|---:|---:|---:|---:|
| Material supply | `metal_yield` | +0.563 | +0.154 | +0.021 | +0.112 | +0.675 | +20% |
|  | `fiber_yield` | +0.253 | +0.033 | +0.034 | +0.050 | +0.303 | +20% |
|  | `extraction_yield` | +0.199 | +0.013 | +0.005 | +0.024 | +0.223 | +12% |
|  | `mining_output` | +0.016 | +0.016 | +0.000 | +0.016 | +0.032 | small base |
| Tool quality | `tool_quality` | +0.410 | +0.132 | +0.022 | +0.064 | +0.474 | +16% |
|  | `repair_capacity` | +0.140 | +0.044 | +0.005 | +0.016 | +0.156 | +11% |
| Craft capacity | `craft_output` | +0.353 | +0.123 | +0.042 | +0.096 | +0.449 | +27% |
|  | `trade_capacity` | +0.151 | +0.068 | +0.021 | +0.047 | +0.198 | +31% |
|  | `container_capacity` | +0.366 | +0.068 | +0.021 | +0.029 | +0.395 | +8% |
| Standardization | `standardization` | +0.248 | +0.065 | +0.003 | +0.042 | +0.290 | +17% |
| Fuel | `fuel_efficiency` | +0.332 | +0.046 | +0.002 | +0.021 | +0.353 | +6% |
| Costs | `fuel_demand` | +0.192 | +0.092 | +0.025 | +0.067 | +0.259 | +35% |
|  | `pollution` | +0.129 | +0.039 | +0.001 | +0.034 | +0.163 | +26% |
|  | `timber_pressure` | +0.137 | +0.047 | +0.009 | +0.028 | +0.165 | +20% |
|  | `water_pollution` | +0.021 | +0.012 | +0.004 | +0.022 | +0.043 | doubles |
|  | `health_risk` | +0.046 | +0.021 | +0.003 | +0.009 | +0.055 | +20% |

### Infrastructure

| Sub-dimension | Key | START 1200 | Prev. block | +by 1500 | +by 1800 | END 1800 | Growth |
|---|---|---:|---:|---:|---:|---:|---:|
| Housing | `housing_output` | +0.400 | +0.118 | +0.041 | +0.112 | +0.512 | +28% |
|  | `health_protection` | +0.052 | +0.018 | +0.006 | +0.021 | +0.073 | +40% |
|  | `dry_storage` | +0.235 | +0.016 | +0.000 | +0.011 | +0.246 | +5% |
| Construction | `construction_rate` | +0.327 | +0.097 | +0.042 | +0.099 | +0.426 | +30% |
| Public works | `water_access` | +0.453 | +0.154 | +0.048 | +0.069 | +0.522 | +15% |
|  | `sanitation` | +0.126 | +0.042 | +0.004 | +0.025 | +0.151 | +20% |
|  | `water_safety` | +0.130 | +0.040 | +0.003 | +0.013 | +0.143 | +10% |
| Resilience | `disaster_resilience` | +0.349 | +0.127 | +0.049 | +0.105 | +0.454 | +30% |
|  | `disaster_risk` | −0.049 | −0.010 | +0.002 | +0.000 | −0.049 | flat |
| Transport | `route_speed` | +0.050 | +0.029 | +0.019 | +0.029 | +0.079 | +58% |
|  | `haul_capacity` | +0.044 | +0.023 | +0.015 | +0.024 | +0.068 | +54% |
| Civic | `legitimacy` | +0.071 | +0.024 | +0.011 | +0.032 | +0.102 | +45% |
| Costs | `labor_demand` | +0.506 | +0.142 | +0.045 | +0.071 | +0.577 | +14% |
|  | `timber_pressure` | +0.056 | +0.029 | +0.006 | +0.014 | +0.070 | +25% |
|  | `fuel_demand` | +0.079 | +0.029 | +0.003 | +0.008 | +0.087 | +10% |

### Reading the growth figures

- **Main keys that grow within the target.** These grow 30–45%: labor efficiency, coordination, state capacity, construction, resilience, route and haul, and civic legitimacy. Housing (+28%) and craft (+25–27%) sit just below.
- **Pacing.** About 20–40% of the block's additions land in 1200–1500, and the rest in 1500–1800. This follows the benchmark arc: few new techniques in the early centuries, then water and wind mills, guilds and vaulted building after game year 1500 (AD 1000).
- **Keys held below 30% on purpose.**
  - *Clamps.* All-line raw totals at 1200 are already close to several clamps:
    - labor efficiency .40 of .55
    - craft .71 of 1.0
    - trade .82 of 1.0
    - state capacity .84 of .90
    - legitimacy .62, past its .55 clamp
    - institutional rigidity .76, past its .55 clamp

    These lines' shares were therefore scaled down, to ×0.45–0.8.
  - *The earlier blocks.* Tools, containers, fuel efficiency, extraction and dry storage were already large at 1200. This window's real change was scale, driven by water power, and not better edges or pots.
  - *History.* Metal (+20%) is carried by the late-window blast furnace, finery and water-blown bloomery. Water access and water safety (+10–15%) stay modest because the post-imperial centuries lost more waterworks than they built. Their growth comes from early conduits, tanks and weirs, then from piped town water and bored-log mains after 1600.
- **Costs grow alongside benefits.** Production `fuel_demand` +35%, `pollution` +26% and `water_pollution` roughly doubles. Labor `institutional_rigidity` rises 40%, and labor `fatigue` gives back a third of its earlier relief.

## Key thresholds

| Year | Item | Main effects |
|---:|---|---|
| 1285 | `pendentive_domes` | housing .006, construction .004, legitimacy .0035; labor demand +.005 |
| 1288 | `sericulture_reeling` | fiber .012, trade .0033; labor demand +.003, fatigue +.002 |
| 1292 | `settled_bondsman_households` | efficiency .0039, cultivation .004, cohesion .004 |
| 1318 | `week_work_service` | food .0042, coordination .005, labor demand −.006; fatigue +.003, rigidity +.0048, cohesion −.003 |
| 1320 | `open_spandrel_arch_bridges` | route .006, resilience .005, haul .003 |
| 1380 | `estate_survey_books` | state .0042, coordination .004; rigidity +.0032 |
| 1405 | `tin_opacified_glaze` | container .005, craft .0033; health risk +.002 (lead glaze) |
| 1410 | `pointed_arches` | construction .006, resilience .005, housing .004 |
| 1492 | `kaolin_porcelain` | container .006, trade .0044; fuel +.004, timber +.003 |
| 1493 | `canal_locks` | haul .008, trade .0039, route .004; labor demand +.004 |
| 1498 | `spinning_wheels` | fiber .012, craft .0033, efficiency .0027 |
| 1535 | `apprentice_indentures` | efficiency .0039, knowledge preservation .004, tools .003, adoption .003 |
| 1555 | `hired_labor_levy` | labor demand −.008, construction .005, legitimacy .0024 |
| 1558 | `fulling_mills` | craft, efficiency, labor demand −.004; water pollution +.004, cohesion −.002 |
| 1582 | `rib_vaults` | construction .006, housing .005, resilience .004 |
| 1598 | `state_shipyard_workforce` | naval .01, coordination .006, warfare .003; timber +.004, injury +.002 |
| 1608 | `leaded_stained_glass` | legitimacy .0035, cohesion .003, housing .003 |
| 1616 | `town_residence_freedom` | adoption .004, efficiency .0026; state −.0014, cohesion −.002 |
| 1642 | `wall_chimneys` | health protection .006, housing .005, smoke health risk −.003, fire risk −.002 |
| 1648 | `flying_buttresses` | construction .006, resilience .005; labor demand +.004 |
| 1654 | `post_windmills` | food .006, labor demand −.004 |
| 1676 | `paper_stamping_mills` | knowledge preservation .008, adoption .003; water pollution +.003 |
| 1692 | `masterpiece_trial` | tools .005, standardization .004; rigidity +.0024 |
| 1692 | `bar_tracery_windows` | housing .005, legitimacy .0028 |
| 1712 | `town_trade_statute_book` | state .0035, standardization .004; rigidity +.0032 |
| 1735 | `belfry_town_halls` | state .004, legitimacy .0035, cohesion .004 |
| 1748 | `silk_throwing_mills` | fiber .008, craft .0039 |
| 1772 | `blast_furnace` | metal .02, fuel efficiency .006, tools .0052; fuel +.01, timber +.008, pollution +.008 |
| 1772 | `closed_mastership` | rigidity +.0096, adoption −.006, cohesion −.004, legitimacy −.0024 (a pure cost) |
| 1775 | `guild_council_seats` | state .0042, legitimacy .004; rigidity +.004 |
| 1790 | `post_plague_labor_statutes` | state .0042, labor demand −.004; rigidity +.0064, legitimacy −.004, cohesion −.004 |
| 1794 | `finery_forges` | metal .019, tools .010; fuel +.006, timber +.005 |

No item here is a weapon or grants a general anything beyond small `warfare_readiness` and `naval_capacity` shares:

- the state shipyard;
- registered state artisans;
- co-fusion steel;
- the water grinding wheels.

Black powder and guns are not in these lines.

## Costs introduced

- **Bound labor.** These items raise `institutional_rigidity`, lower `cohesion`, `legitimacy` and `adoption_rate`, and add `fatigue`:
  - hereditary corporations;
  - runaway returns;
  - convict gangs, which add `injury_risk` and `health_risk`;
  - week-work and boon-work;
  - mill suit;
  - the post-plague statutes.

  Freedoms such as manumission, rent commutation and laborer mobility reverse part of this, at a cost to lords' `state_capacity`.
- **Guild closure.**
  - Monopoly, the single-craft rule, shop limits, fixed journeyman rates and closed mastership reduce `adoption_rate` and raise rigidity.
  - Shop limits and night-work bans also cost a little `craft_output`.
- **Putting-out and piece work.**
  - Debt-bound and rented-loom putting-out, carver piece rates, salt-works shifts and the cloth chain add `fatigue` and lower `cohesion`.
  - Rural putting-out lowers `standardization`.
  - Weaver walkouts cost `cohesion`, `legitimacy` and `craft_output`.
- **Displacement.** Fulling mills, mill fulling crews and silk-throwing mills cut `labor_demand` and lower `cohesion`. Cottager day labor adds `health_risk` and lowers nutrition.
- **Fuel, forests and smoke.** These fall on the blast furnace, finery, water-blown bloomery, monumental casting, forest glass, porcelain, hard-fired ware, clamp bricks and draw kilns. Coal ironworking eases `timber_pressure` (−.004) but adds `pollution` +.008 and `health_risk`.
- **Poison and dirty water.**
  - Lead and acid cost health: tin glaze, stained glass, lead roofing, gutters and flashing, and acid parting (+.003).
  - Alum works, ore sluices, ore stamps, fulling, paper mills, textile printing, field bleaching and latrine towers add `water_pollution`.
- **The dense town.**
  - Jettied houses add `disaster_risk` +.004 and `disease_exposure`.
  - Inhabited bridges and plank halls add fire risk.
  - Steam baths, great tanks and open cisterns add `disease_exposure`.
  - Stone party walls, stone merchant houses and wall chimneys lower fire risk.
- **Upkeep.** `labor_demand` falls on domes, bridges, canal locks, embankments, dike duty, reservoirs, weirs and the belfry hall. Infrastructure's raw `labor_demand` total is already past the .35 clamp in every block, so offsetting labor-saving items matter more than new upkeep. This block adds only +.071 to it.
- **Ecology.** Clearance dues holidays, free miner companies, diversion weirs, mill leats, ore sluices and deep silver mining add `ecological_pressure`.

## Catalog ids replaced

All 18 catalog ids take new `effects`. They keep their authored names, recipes and resource gates.

- **Wrong scale.** `canal_locks` had pre-rebalance values: haul .16, trade .10, state .04, labor demand .04, disease .01. It now has haul .008, trade .0039, route .004, water .002, state .0016, labor demand .004 and disease .001.
- **Empty.** The other 17 had no effects, including `blast_furnace`, `finery_forges` and `spinning_wheels`.
- **Observations rewritten.** Most of these catalog ids had specification-style observations, and these were rewritten.
- **`production_contract` rewritten** on `ratchet_motion_control` and `cam_motion_design`. The authored text described motor workshops and electricity. The recipes themselves are unchanged.

## Recipes and materials

**`production_items`.** No NEW id in these lines has a recipe gated on it in `civilian_industry.gd`, so none is linked. Catalog ids keep their authored recipes:

- `ratchet_indexers`
- the textile printing set
- `purified_brine`
- `pressed_paper`
- `wheel_spun_yarn`
- `cam_follower_sets`
- `laundry_soap`
- `roof_flashing_pieces`
- the buttonhole set
- `treadle_lathes`
- `blast_pig_iron` / `charcoal_pig_iron`
- `finery_iron` / `charcoal_finery_iron`

**`resource_requirements` added.** All use stage `recognized` with `sample_sufficient`:

| Resource | Items |
|---|---|
| Iron Ore | `co_fusion_steel`, `monumental_iron_casting`, `coal_fired_ironworking`, `standard_bar_iron`, `water_blown_stack_bloomery`, `tinned_iron_plate` |
| Gold Ore | `salt_cementation_parting` |
| Clay | `kaolin_porcelain` (stand-in), `clamp_fired_brick` |
| Limestone | `draw_lime_kilns` |

Design conditions already cover Coal, Tin Ore, Silver Ore, Salt, Lead Ore and the river, coast and dry environments.

**Missing recipes (proposals for Phase 3).** Nothing below was added.

| Item | Needs |
|---|---|
| `kaolin_porcelain`, `pale_hard_fired_ware`, `frit_stonepaste`, `celadon_reduction_glaze` | A **Kaolin / porcelain stone** resource and a "Porcelain" recipe. Clay is a stand-in gate. |
| `tin_opacified_glaze`, `lustre_glazed_ware`, `sgraffito_slipware`, `underglaze_cobalt_blue` | Glazed-ware recipes; a **cobalt** mineral for the blue |
| `sericulture_reeling`, `silk_throwing_mills`, `slit_silk_tapestry`, `lampas_figured_silks` | A **silkworm / Raw Silk** resource and a "Silk Thread" / "Silk Cloth" recipe |
| `roller_cotton_gin`, `bow_fibre_fluffing`, `fustian_cloth` | A **Cotton** resource and cotton lint and fustian recipes |
| `co_fusion_steel`, `standard_bar_iron`, `water_blown_stack_bloomery` | A pre-industrial "Edge Steel" recipe; bar iron could reuse `wrought_iron` if it is regated |
| `monumental_iron_casting`, `pit_cast_bells`, `cast_bronze_doors` | Great-casting recipes (bells, doors, statues) |
| `fulling_mills`, `mill_fulling_crews`, `teasel_nap_shearing` | A "Fulled Woollen Cloth" recipe |
| `paper_stamping_mills`, `gelatin_paper_sizing`, `paper_watermarks` | A water-powered paper route. `pressed_paper` / `rag_pulp` exist but are gated elsewhere. |
| `post_windmills`, `tide_mills`, `floating_boat_mills`, `horizontal_wheel_mills`, `vertical_axis_windmills` | Mill facilities (grain grinding without a water source) |
| `water_ore_stamps`, `ore_washing_sluices`, `rag_chain_mine_pumps`, `horse_whim_hoists` | Ore-dressing and mine-drainage facilities |
| `alum_works`, `scale_insect_scarlet` | An **Alum** resource (unmapped since 0–600) and a mordant recipe |
| `acid_gold_parting` | A **Saltpetre** resource and a strong-acid recipe |
| `tinned_iron_plate` | The authored "tinplate" recipes are industrial; it needs a hand-dipped tinplate recipe |
| `clamp_fired_brick`, `draw_lime_kilns`, `moulded_brick_architecture` | Fired-brick and continuous-lime recipes |
| `leaded_stained_glass`, `spun_crown_panes`, `house_glass_windows`, `silver_stain_glass` | The "Window Glass" recipe proposed in the 600–1200 doc, plus lead cames |
| `ropewalk_cables` | A cable recipe (Cordage → ship cable) |
| `warded_locks` | A lock and padlock recipe |
| `ratchet_motion_control`, `cam_motion_design`, `paper_sheet_pressing` | Their authored recipes include motor or electric routes that are anachronistic here; hand and water routes would fit |

## Validation

- `test_research_blocks.gd`: 7/7 pass. `test_research_1800.gd`: 5/5 pass.
- The generator checks every effect name against `SocietyModel.EFFECT_LIMITS` and its bounds. It also checks the .008 / .02 caps and that every key threshold has an `ability_reason`. It found no problems.
- **Headless merge check.** `DiscoverySystem.initialize()` was run, then each of the 247 rows was compared with the live definition:
  - every effect, name, observation, art path and contract merged;
  - the resource gates merged;
  - there were 0 mismatches.
- **The three JSON files are valid.**

The generator and data are in the session scratchpad (`p2lpi1800/`), not in the repository.
