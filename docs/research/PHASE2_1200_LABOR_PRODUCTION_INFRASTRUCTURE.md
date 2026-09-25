# Phase 2, years 600–1200: Labor, Production and Infrastructure effects

Files: `data/research/effects_y600_1200/labor.json`, `production.json` and `infrastructure.json`. These are data only. They add no saved state and make no script changes.

## Counts

| Line | Items | NEW | Catalog | Rows with `effects` | New observations | `ability_reason` | `social_consequence` | `production_items` | `production_contract` | `resource_requirements` |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Labor | 72 | 71 | 1 | 72 | 72 | 8 | 9 | 0 | 0 | 0 |
| Production | 90 | 71 | 19 | 90 | 75 | 12 | 7 | 2 | 4 | 6 |
| Infrastructure | 81 | 68 | 13 | 81 | 78 | 13 | 7 | 0 | 1 | 1 |

- **Every one of the 243 items has a row**, with its own `effects` and an `art` key.
- **Every NEW id has an in-world one-line observation.** None of them uses a real historical name.
- **Catalog ids.** The 33 catalog ids take new `effects` in place of their authored effects. Several of those authored effects were at pre-rebalance scale, for example `hardened_edges` tool_quality .16 and `counterweight_cranes` haul .14. Eighteen catalog ids had no effects at all. Catalog ids keep their names. They keep their authored observations unless the text read like a specification rather than something a person would see, as with `domed_masonry_roofs`, `hydraulic_lime_binders`, `voussoir_arch_assembly` and `drawloom_pattern_control`.
- **Effect sizes.** Routine items use 0.001–0.008 per effect, with a median of 0.003–0.004. Key thresholds use up to 0.02. The generator scales and clamps at those limits, and it uses per-line key scales for keys whose lines were growing too fast: labor craft and construction, trade, route and haul, naval capacity, and legitimacy.

## Effect totals per sub-dimension

Each figure is the raw sum over the line's items with a proposed year of Y or earlier, before adoption and era ceilings. The 0–600 column is the current, rebalanced 0–600 files plus authored and `BASE_EFFECTS` values, taken from a headless catalog dump. The target was +30–60% growth by 1200 on each line's main keys.

### Labor

| Sub-dimension | Key | 0–600 total at 600 | Added by 700 | by 900 | by 1200 | Total at 1200 | Change |
|---|---|---:|---:|---:|---:|---:|---:|
| Able workforce | `injury_risk` | -0.033 | -0.007 | -0.003 | -0.001 | -0.034 | -3% |
|  | `health_risk` | -0.060 | -0.005 | -0.009 | -0.013 | -0.073 | -22% |
| Work efficiency | `labor_efficiency` | +0.136 | +0.020 | +0.054 | +0.063 | +0.199 | +46% |
| Coordination | `task_coordination` | +0.121 | +0.019 | +0.051 | +0.060 | +0.181 | +50% |
|  | `cohesion` | +0.030 | -0.003 | +0.014 | +0.021 | +0.051 | small base |
| Workload balance | `fatigue` | -0.059 | -0.014 | +0.000 | +0.003 | -0.056 | +5% |
|  | `labor_demand` | +0.025 | -0.014 | -0.026 | -0.047 | -0.022 | small base |
| Institutional side effects | `state_capacity` | +0.041 | +0.007 | +0.019 | +0.044 | +0.085 | +105% |
|  | `institutional_rigidity` | +0.085 | +0.013 | +0.017 | +0.070 | +0.155 | +83% |
|  | `legitimacy` | -0.003 | -0.001 | +0.011 | +0.010 | +0.007 | small base |
| Output | `craft_output` | +0.072 | +0.013 | +0.031 | +0.047 | +0.119 | +65% |
|  | `construction_rate` | +0.010 | +0.000 | +0.029 | +0.040 | +0.050 | small base |
|  | `trade_capacity` | +0.006 | +0.006 | +0.018 | +0.029 | +0.036 | small base |

### Production

| Sub-dimension | Key | 0–600 total at 600 | Added by 700 | by 900 | by 1200 | Total at 1200 | Change |
|---|---|---:|---:|---:|---:|---:|---:|
| Material supply | `metal_yield` | +0.409 | +0.077 | +0.117 | +0.154 | +0.563 | +38% |
|  | `extraction_yield` | +0.186 | +0.007 | +0.013 | +0.013 | +0.199 | +7% |
|  | `stone_yield` | +0.060 | +0.003 | +0.011 | +0.019 | +0.079 | +32% |
|  | `fiber_yield` | +0.220 | +0.003 | +0.013 | +0.033 | +0.253 | +15% |
| Tool quality | `tool_quality` | +0.277 | +0.044 | +0.116 | +0.132 | +0.410 | +48% |
|  | `repair_capacity` | +0.096 | +0.021 | +0.040 | +0.044 | +0.140 | +46% |
| Craft capacity | `craft_output` | +0.230 | +0.016 | +0.065 | +0.123 | +0.353 | +54% |
|  | `container_capacity` | +0.298 | +0.000 | +0.016 | +0.068 | +0.366 | +23% |
|  | `trade_capacity` | +0.083 | +0.009 | +0.036 | +0.068 | +0.151 | +83% |
| Standardization | `standardization` | +0.183 | +0.009 | +0.037 | +0.065 | +0.248 | +36% |
| Fuel | `fuel_efficiency` | +0.286 | +0.024 | +0.036 | +0.046 | +0.332 | +16% |
|  | `fuel_demand` | +0.100 | +0.021 | +0.052 | +0.092 | +0.192 | +92% |
| Costs | `pollution` | +0.090 | +0.014 | +0.031 | +0.039 | +0.129 | +43% |
|  | `timber_pressure` | +0.090 | +0.015 | +0.033 | +0.047 | +0.137 | +52% |
|  | `health_risk` | +0.025 | +0.002 | +0.012 | +0.021 | +0.046 | small base |

### Infrastructure

| Sub-dimension | Key | 0–600 total at 600 | Added by 700 | by 900 | by 1200 | Total at 1200 | Change |
|---|---|---:|---:|---:|---:|---:|---:|
| Housing | `housing_output` | +0.282 | +0.009 | +0.027 | +0.118 | +0.400 | +42% |
|  | `dry_storage` | +0.219 | +0.000 | +0.008 | +0.016 | +0.235 | +7% |
| Construction | `construction_rate` | +0.229 | +0.007 | +0.041 | +0.097 | +0.327 | +42% |
| Public works | `water_access` | +0.299 | +0.016 | +0.089 | +0.154 | +0.453 | +52% |
|  | `sanitation` | +0.084 | +0.003 | +0.019 | +0.042 | +0.126 | +50% |
|  | `water_safety` | +0.090 | +0.008 | +0.024 | +0.040 | +0.130 | +44% |
| Resilience | `disaster_resilience` | +0.223 | +0.026 | +0.052 | +0.127 | +0.349 | +57% |
|  | `disaster_risk` | -0.039 | -0.003 | -0.003 | -0.010 | -0.049 | -26% |
| Transport and harbors | `route_speed` | +0.021 | +0.004 | +0.018 | +0.029 | +0.050 | small base |
|  | `naval_capacity` | +0.060 | +0.006 | +0.018 | +0.034 | +0.093 | +56% |
| Costs | `labor_demand` | +0.364 | +0.029 | +0.073 | +0.142 | +0.506 | +39% |
|  | `fuel_demand` | +0.050 | +0.002 | +0.002 | +0.029 | +0.079 | +58% |
|  | `timber_pressure` | +0.027 | +0.002 | +0.006 | +0.029 | +0.056 | small base |

**Reading the growth figures.**

- **Main keys.** The main improvement keys grow 36–57% by 1200: labor efficiency, coordination, tools, metal, craft, housing, construction, water, sanitation and resilience.
- **Small bases.** The large percentages on labor `construction_rate` and `trade_capacity`, on infrastructure `route_speed`, and on labor `state_capacity` sit on very small 0–600 bases. Those keys belong mainly to other lines. In absolute terms the additions are 0.03–0.045.
- **Costs grow faster than benefits:**
  - production `fuel_demand` +92% and `health_risk` +84%;
  - infrastructure `timber_pressure` +109%;
  - labor `institutional_rigidity` +83%.

  This is deliberate. The iron age, the bath-and-aqueduct city and the late hereditary trades were expensive.
- **Keys that barely move.** `fatigue`, `injury_risk`, `extraction_yield` and `dry_storage` move little by design. Wage labor, piece rates and night shifts add fatigue and injury back as fast as rest days and shift rotations remove them.

## Notable threshold items

| Year | Item | Main effects |
|---:|---|---|
| 660 | `bloomery_smelting` | metal .02, tools .010; fuel demand .012, timber .01, pollution .006. Links `wrought_iron`. |
| 662 | `forge_crew_roles` | coordination .0072, efficiency .0051 |
| 675 / 705 / 710 | `forge_welding`, `surface_carburization`, `hardened_edges` | tools .013–.017 each, repair .012, warfare .006–.008 |
| 688 | `silver_wage_payment` | labor demand −.008, efficiency .0043, trade .005, cohesion −.002 |
| 740 | `groundwater_tunnels` | water .016, cultivation .006; labor demand +.008 |
| 772 | `public_work_tenders` | construction .006, state .003; labor demand −.006, legitimacy −.002 |
| 790 | `die_struck_coinage` | trade .007, standardization .01 |
| 790 | `two_ended_tunnels` | water .0096, survey .006 |
| 806 | `excavated_harbor_basins` | naval .0075, trade .006; labor demand +.01 |
| 808 | `master_builder_office` | construction .0072, coordination .009, resilience .006 |
| 832 | `liquid_iron_furnaces` | metal .02, craft .0056; fuel .012, timber .01, pollution .008 |
| 838 | `workshop_task_division` | efficiency .011, craft .0066, standardization .008; fatigue +.004 |
| 893 | `water_mills` | food .015, efficiency .01; labor demand −.008 |
| 897 | `crucible_steel_cakes` | tools .017, warfare .012 |
| 928 / 935 | `stone_arch_bridges`, `vaulted_masonry_roofs` | bridges: route .005, haul .003, resilience .0042; vaults: housing .01, resilience .0056 |
| 952 / 968 | `inverted_pressure_siphons`, `arcaded_aqueduct_bridges` | water .012–.016; lead `health_risk` +.003 on the siphons; labor demand +.01 on the arcades |
| 992 / 1002 | `pozzolanic_binder_blends`, `mass_rubble_concrete` | construction .006–.009, resilience .0084 / .0056, housing .008 |
| 1010 | `glass_blowing` | container .012, craft .0056, spoilage −.004 |
| 1024 | `underwater_concrete_moles` | naval .0075, trade .005; labor demand +.01 |
| 1035 | `putting_out_spinning` | craft, trade and efficiency; fatigue +.004, cohesion −.002 |
| 1080 | `domed_masonry_roofs` | housing .012, legitimacy .006; labor demand +.01 |
| 1090 | `paper_making` | knowledge preservation .02, adoption .012. Links `handmade_paper`. |
| 1150 | `occupation_census` | state .006, coordination .0054; rigidity +.0048 |
| 1168 | `hereditary_trade_obligation` | state .004, labor demand −.006; rigidity +.016, adoption −.006, cohesion −.004, legitimacy −.004 |
| 1192 | `blown_cylinder_panes` | housing .01, health protection .004 |

## Costs and tradeoffs

- **Fuel, forests and smoke.** These costs sit on bloomery smelting, liquid iron, charcoal clamps, ore roasting, argentiferous lead, climbing kilns, the big kiln yards, heated baths and raised-floor heating. They use `fuel_demand`, `timber_pressure` and `pollution`.
- **Poison trades** carry `health_risk`:
  - argentiferous lead working;
  - mercury fire gilding (+.006);
  - lead-glazed ware;
  - pewter;
  - lead-backed mirrors;
  - lead sheet;
  - **lead water pipes**: `stamped_lead_pipes` +.004 and `inverted_pressure_siphons` +.003. The health line's `clay_over_lead_pipes` (1012) is the remedy.
- **Water pollution.** Purple-dye works, vat dyeing, resist dyeing and fulling add `water_pollution`.
- **Hard work.** Piece rates, late-completion penalties, volume-paid quarrying, clock-timed shifts, bakery workforces, workshop task division and putting-out add `fatigue`. Piece rates, porter gangs, clock-timed shifts and road tunnels add `injury_risk`. Mine lease labor lowers `mine_safety`.
- **Labor diversion.** Upkeep and levies carry a `labor_demand` cost: cyclopean walls, domed tombs, harbors, tunnels, aqueducts, arch bridges, domes, dams, beacon towers, conduit crews and salaried works staff. Standing engineers and rower levies take men from other work. `soldier_work_details` costs a little `warfare_readiness`.
- **Social strain** shows up as lower `cohesion` and `legitimacy` and higher `institutional_rigidity`. The items are:
  - ration stoppages;
  - graded rations;
  - wage labor;
  - large bought-labor workshops;
  - estate bailiffs;
  - sharecropping and the home-farm split;
  - maximum-wage edicts, which also cost trade .003 and efficiency .0026;
  - hereditary trades;
  - licensed guilds;
  - land-bound tenancy.

  The public tenders and contractor companies cost a little `legitimacy`, because of shoddy low bids and profiteering.
- **Dependency.** The arcaded aqueduct and mill cascades have `social_consequence` text that warns of dependence on a single channel. The mill cascades take −.0024 of water access from the fields and fountains below them. The dense city carries costs too: `tenement_blocks` raises `disaster_risk` and `disease_exposure` by +.004 each, and `heated_public_baths` raises `disease_exposure` by +.003.
- **Freedom of trades.** `adoption_rate` falls under hereditary trades, licensed guilds and land-bound tenancy.

## Recipes, materials and contracts

**Linked (`production_items`).** These are existing recipes gated on the same id:

- `bloomery_smelting` → `wrought_iron`
- `paper_making` → `handmade_paper`

Catalog ids that already had authored recipes keep them: `charged_bloomery_iron`, `case_hardened_gears`, `copper_wire`, `iron_tired_wheels`, `lead_electrode_sheets`, `blown_glass_vessels`, `mold_glass_vessels`, stoneware, `rag_pulp`, `water_hammer_drives`, `mechanical_screw_presses`, figured cloth, `track_ballast`, the binders, `timber_trusses`, `arch_centering`, `voussoir_stones` and `masonry_drainage_beds`.

**Deliberately not linked:**

- `iron_armor_plates` and `water_hammered_armor_plates` (gate `hardened_edges`): plate armor at 710 is anachronistic.
- `vacuum_copper_motor_leads` (gate `wire_drawing`): electrical.

**`resource_requirements` added.** All use stage `recognized` with `sample_sufficient`, so a traded sample is enough:

| Item | Resource |
|---|---|
| `liquid_iron_furnaces` | Iron Ore |
| `crucible_steel_cakes` | Iron Ore |
| `cementation_brass` | Copper Ore |
| `vessel_tinning` | Tin Ore |
| `mercury_fire_gilding` | Gold Ore |
| `decolorized_clear_glass` | Fine Sand |
| `mass_rubble_concrete` | Limestone |

Design conditions already cover argentiferous lead (Lead Ore), pewter (Tin Ore) and hard soap (Salt).

**`production_contract` rewritten** where the authored text was industrial:

| Item | Old text described |
|---|---|
| `lead_sheet_rolling` | battery electrodes |
| `aggregate_road_foundations` | wagonways and track ballast |
| `surface_carburization` | electric welding, motors and continuous casting |
| `mechanical_screw_presses` | printing |
| `textile_rag_pulping` | electric beating |

The authored recipes remain.

**Proposals for Phase 3.** These recipes and resources are missing. Nothing below was added.

| Item | Needs |
|---|---|
| `liquid_iron_furnaces`, `cast_iron_vessels`, `cast_iron_annealing` | A "Cast Iron" output, from Iron Ore + Charcoal, and cast cauldrons and ploughshares |
| `crucible_steel_cakes`, `steel_edge_inlaying`, `pattern_welded_blades` | A pre-industrial "Crucible Steel" recipe, from Wrought Iron + Charcoal in Ceramic Crucibles. The existing Steel recipes are gated on modern ids. |
| `cementation_brass` | A **Zinc Ore / calamine** resource and a "Brass" recipe |
| `pewter_casting` | A "Pewter" recipe, from Tin + a little Refined Lead |
| `vessel_tinning` | A tinned-copper vessel recipe |
| `mercury_fire_gilding` | A **Cinnabar / mercury** resource and a gilding recipe |
| `die_struck_coinage` | A coin-striking recipe, from Refined Silver, and dies |
| `argentiferous_lead_working` | Can reuse `silver_bearing_bullion` if it is regated or duplicated for this id |
| `cast_window_glass`, `blown_cylinder_panes`, `glazed_windows` | A "Window Glass" recipe, from Glass + fuel |
| `lead_backed_glass_mirrors` | A mirror recipe |
| `mass_rubble_concrete`, `underwater_concrete_moles`, `brick_faced_concrete` | A "Concrete" recipe, from Hydraulic or Pozzolanic Binder + Stone rubble |
| `pozzolanic_binder_blends` | A **volcanic ash / pozzolana** resource. Its recipe uses Ceramic Grog as a stand-in. |
| `salted_hard_soap` and `ash_lye_cleansers` | Lye and hard-soap recipes |
| `stamped_lead_pipes`, `inverted_pressure_siphons` | A lead-pipe recipe, from Lead Sheets |
| `aggregate_road_foundations` | Its only recipe makes "Track Ballast", a rail output. It needs a road-bed material instead. |
| `lead_sheet_rolling` | Its recipe is named `lead_electrode_sheets`. Its output, "Lead Sheets", is fine, but the recipe id and its battery use belong to a later era. |
| `surface_carburization` | Its recipe `case_hardened_gears` is anachronistic at year 705. Case-hardened tool edges would fit. |

## Art

Every row points to an existing file on disk:

- the item's own subject painting where one exists: `bloomery_smelting`, `forge_welding`, `iron_assaying`, `hardened_edges`, `mine_drainage`, `water_mills`, `caravanserais`, `counterweight_cranes` and `paper_making`;
- or the paper studies for `glass_blowing`, `high_fire_stoneware`, `drawloom_pattern_control`, `aggregate_road_foundations`, `compound_pulleys`, `water_powered_hammers`, `mechanical_screw_presses` and `surface_carburization`;
- or else the closest 0–600 subject, paper study or `discovery-600` painting.

## Validation

- **Loader suites.**
  - `test_research_1200.gd`: 3/3 pass.
  - `test_research_blocks.gd`: 7/7 pass.
- **Nearby suites also pass:** `test_building_material_operations` (11), `test_glass_ceramic_processes` (1), `test_civilian_goods` (9) and `test_textile_knowledge` (4).
- **Headless merge check** (`DiscoverySystem.initialize()`, then each row compared with the live catalog) over all 243 rows:
  - every effect merged, with no leftover authored effects;
  - no unknown effect names;
  - every observation and linked recipe merged;
  - every art path exists;
  - no `validate_catalog` errors on these ids.
- **The JSON files are valid.**
- **Note.** Eight catalog ids keep an authored `dynamic` that differs from their design line, and their effects apply regardless. `dynamic` is protected, so the Phase 2 files cannot change it.

  | Id | Authored `dynamic` |
  |---|---|
  | `mine_drainage` | infrastructure |
  | `iron_tyre_fitting` | infrastructure |
  | `water_mills` | infrastructure |
  | `paper_making` | knowledge |
  | `compound_pulleys` | knowledge |
  | `caravanserais` | logistics |
  | `aggregate_road_foundations` | logistics |
  | `counterweight_cranes` | logistics |
