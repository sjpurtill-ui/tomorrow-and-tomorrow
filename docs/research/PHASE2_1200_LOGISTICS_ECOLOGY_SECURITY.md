# Phase 2, years 600–1200: Logistics, Ecology and Security effects

Files:

- `data/research/effects_y600_1200/logistics.json`
- `data/research/effects_y600_1200/ecology.json`
- `data/research/effects_y600_1200/security.json`

## Counts

Every item of the three lines in `data/research/blocks/y600_1200.json` has a row. That is 228 rows in total.

| Line | Rows | NEW | Catalog | Key thresholds | Social consequences |
|---|---:|---:|---:|---:|---:|
| Logistics | 75 | 67 | 8 | 11 | 10 |
| Ecology | 67 | 67 | 0 | 7 | 10 |
| Security | 86 | 70 | 16 | 15 | 13 |

- **NEW rows.** Each has its own effects, a short name, a one-line in-world observation and `art`.
- **Key thresholds.** Each also has an `ability_reason`.
- **Catalog rows.** Existing ids such as `professional_corps`, `siege_engineering`, `galley_navigation`, `crossbow_mechanism`, `mail_armor_fabrication` and the shipbuilding and cartwright steps keep their authored names.
  - Their authored effects were empty, placeholders (`warfare_readiness .035` / `task_coordination .015`), or unscaled (for example `professional_corps` warfare .16 and `siege_engineering` warfare .14). They now carry values on the same scale as the rest.
  - Placeholder observations ("Develop and demonstrate …") were rewritten.
- **Art.** Each row points to the best existing painting:
  - a related 0–600 subject (`paper/`, `first300-cards/`, `discovery-600/`), such as `galley_navigation.png`, `crossbow_mechanism.png`, `mail_armor_fabrication.png`, `charcoal.png` and `messenger_relay_stations.png`;
  - or the nearest subject card.
- **Not touched.** No recipes, requirements, conditions or unit gates were changed.
- **Names.** Alternative history is kept: no real places or peoples. The block's "maniples" row is named "Flexible Company Lines".

## Validation

- `tests/test_research_1200.gd`: 3/3 pass.
- `tests/test_research_blocks.gd`: 7/7 pass.
- No unregistered effect names appear. Every key is in `SocietyModel.EFFECT_LIMITS`, and every file is valid JSON.
- A headless dump after `DiscoverySystem.initialize()` shows all 228 rows merged, with 0 value mismatches against the files.

## Calibration

The per-line scaling follows the coordinator's calibration note:

- Headline totals by year 1200 land about 30–60% above each line's year-600 total.
- Routine items are within ±0.008 (typically 0.001–0.005, median 0.0025).
- Key thresholds are within ±0.02. The largest is 0.016 (`camel_caravans` endurance, `trunk_road_courier_relay` travel).

To get there, the drafted values were scaled uniformly per line:

- Logistics ×0.8, Ecology ×0.85, Security ×0.85.
- Some keys had an extra per-key factor:
  - trade ×0.53 and naval ×0.6 in Logistics;
  - soil ×0.75 and disaster risk ×0.7 in Ecology;
  - warfare ×0.38, security ×0.61, labor demand ×0.51, coordination ×0.55, naval ×0.6, disaster resilience ×0.6 and injury ×0.7 in Security.
- The caps then clipped 11 routine values. Relative weights are otherwise preserved.

## Totals

Totals are raw sums before adoption weighting, using each item's `proposed_year`.

- The 600 column is the sum of the current, post-rebalance `data/research/effects/<line>.json` for the same line.
- The later columns are cumulative (600 total plus this block's items to that year).

### Logistics

| Sub-dimension | Effect | 600 | 700 | 900 | 1200 | 1200 vs 600 |
|---|---|---:|---:|---:|---:|---:|
| Carrying capacity | `haul_capacity` | .271 | .285 | .321 | .385 | +42% |
|  | `logistics_endurance` | .256 | .256 | .296 | .310 | +21% |
|  | `fatigue` | −.028 | −.028 | −.030 | −.038 | |
| Route quality | `route_speed` | .241 | .251 | .281 | .317 | +32% |
|  | `travel_speed` | .212 | .212 | .236 | .262 | +24% |
|  | `injury_risk` | −.018 | −.022 | −.031 | −.031 | |
| Storage system | `storage_loss` | −.097 | −.097 | −.099 | −.115 | +19% |
|  | `food_storage` | .061 | .061 | .064 | .083 | +36% |
|  | `container_capacity` | .100 | .105 | .105 | .122 | +22% |
| Trade reach | `trade_capacity` | .198 | .208 | .259 | .309 | +56% |
|  | `naval_capacity` | .290 | .322 | .351 | .403 | +39% |
| Costs | `timber_pressure` | .059 | .067 | .069 | .077 | |
|  | `labor_demand` | .059 | .061 | .074 | .089 | |
|  | `disease_exposure` | .017 | .019 | .022 | .029 | |
|  | `cohesion` / `legitimacy` | | | | −.006 / −.004 added | |

### Ecology

| Sub-dimension | Effect | 600 | 700 | 900 | 1200 | 1200 vs 600 |
|---|---|---:|---:|---:|---:|---:|
| Land health | `soil_productivity` | .157 | .168 | .204 | .239 | +52% |
|  | `ecological_pressure` | −.216 | −.231 | −.259 | −.289 | +34% |
|  | `disaster_risk` | −.027 | −.030 | −.042 | −.053 | |
| Natural recovery | `ecology_recovery` | .299 | .314 | .354 | .387 | +29% |
|  | `cultivation_yield` | .082 | .086 | .103 | .121 | +48% |
|  | `food_output` | .098 | .098 | .102 | .116 | +18% |
|  | `hunting_yield` / `foraging_yield` | .101 / .181 | | | .097 / .180 | net loss |
| Pollution control | `pollution` | −.069 | −.069 | −.072 | −.083 | +20% |
|  | `water_pollution` | −.065 | −.065 | −.077 | −.084 | +29% |
|  | `water_safety` | .034 | .038 | .042 | .047 | +38% |
|  | `sanitation` | .033 | .035 | .045 | .045 | +36% |
| Resource sustainability | `timber_pressure` | −.225 | −.238 | −.261 | −.310 | +38% |
|  | `timber_yield` | .215 | .215 | .213 | .228 | +6% |
| Costs | `labor_demand` | .015 | .022 | .036 | .059 | |
|  | `legitimacy` | .003 | .003 | −.001 | −.003 | |

### Security

| Sub-dimension | Effect | 600 | 700 | 900 | 1200 | 1200 vs 600 |
|---|---|---:|---:|---:|---:|---:|
| Military readiness | `warfare_readiness` | .320 | .346 | .437 | .490 | +53% |
|  | `task_coordination` | .049 | .056 | .075 | .079 | +61% |
|  | `naval_capacity` | .000 | .013 | .028 | .032 | |
| Organized defense | `security_efficiency` | .280 | .298 | .343 | .407 | +45% |
|  | `labor_demand` (cost) | .149 | .159 | .186 | .217 | +46% |
| Public safety | `injury_risk` | −.015 | −.018 | −.029 | −.035 | |
|  | `cohesion` / `legitimacy` | .003 / .029 | | | −.003 / .019 | net loss |
| Crisis resilience | `disaster_resilience` | .047 | .049 | .063 | .073 | +55% |
|  | `disaster_risk` | −.030 | −.032 | −.037 | −.042 | |
|  | `food_storage` | .017 | .017 | .022 | .028 | |
| Costs | `timber_pressure` | .010 | .020 | .044 | .053 | |
|  | `fuel_demand` | .000 | .003 | .009 | .015 | |

## Notable thresholds

Values are after scaling.

- **Logistics**
  - Seafaring:
    - brailed square sail at 650: naval .012;
    - deep-hold merchantmen at 700: naval .014, trade .006, timber pressure .005;
    - seasonal-wind ocean crossings at 990: naval .012, with injury and disease added;
    - great bulk freighters at 1020: naval .012, haul .0096;
    - fore-and-aft sail at 1170.
  - Coinage-era trade: coins taken by count at 800 (trade .0085), deposit transfer orders at 893, and long relay trade at 960 (trade .0076, disease .004, cohesion −.0016).
  - Camel caravans at 710: endurance .016, haul .0096.
  - Roads and posts: trunk-road courier relay at 805 (travel .016), then state post with passes at 1035 (travel .012, state .008, legitimacy −.0024).
- **Ecology**
  - Smelter woodland watch at 670.
  - Ship-timber crown forests at 850: timber pressure −.010, but timber yield −.0034 and legitimacy −.0026.
  - Steep forests kept standing at 880.
  - Plant-habitat treatise at 895.
  - Tall smelter flues at 1015: pollution −.0085, but ecological pressure +.0017, because the fumes are spread rather than removed.
  - Managed city firewood rings at 1100: timber pressure −.012.
  - Forest supervisors at 1150.
- **Security**
  - Professional corps at 660: warfare .0097, security .0078, legitimacy −.0043.
  - Iron swords at 690 and iron spearheads for the levy at 732. Both add `fuel_demand` and `timber_pressure` for charcoal.
  - Mounted archery at 722 and siege engineering at 724.
  - Citizen heavy infantry at 762: cohesion and legitimacy go up.
  - Three-banked warships at 797: timber pressure .0068.
  - Crossbow at 847, torsion engines at 876 and mail at 893.
  - Frontier long walls at 935: security .0083, labor .0052, legitimacy −.0026.
  - Armored horse at 950 and horned saddle at 992.
  - Long-service enlistment at 1036 and mobile field reserves at 1178.

Security effects change what forces and generals *can* do: readiness, coordination, protection, endurance and fortification. They follow `GENERAL_CAMPAIGN_DESIGN.md`. No row implies direct cohort control. The texts and ability reasons describe what a general can now attempt, for example planning a siege, harrying an army with horse archers, or holding a frontier thinly and striking with a reserve.

## Costs and tradeoffs introduced

**Deforestation, erosion and siltation.** The costs sit on the drivers:

- Shipbuilding (merchantmen, freighters, grown frames, galleys, arsenals, ram galleys, three-banked warships), siege works and towers, timber-laced ramparts, marching camps, coopered casks and liming all add `timber_pressure`.
- Iron arms, mail, banded plate and permanent fortresses add `fuel_demand`, which stands for charcoal.
- Timber rafting and trunk canals add `ecological_pressure`.

The Ecology responses then carry their own costs:

| Response | Cost |
|---|---|
| Crown ship-timber forests, steep forests kept standing | lost `timber_yield` |
| Crown ship-timber forests, forest supervisors | `legitimacy` |
| Smelter woodland watch | `metal_yield` |
| Goats kept off regrowth, net mesh limits | `food_output` |
| Thin soils left in grass, worn fields retired, protected drove roads, flood overflow grounds | `cultivation_yield` |
| Game wardens | `hunting_yield`, `legitimacy` |
| Recognizing locally extinct beasts | `hunting_yield` |
| Timber export limits | `trade_capacity` |
| Terraces, check dams, saline drains, dune fixing, tailing ponds, city firewood rings and others | `labor_demand` (Ecology's labor demand roughly quadruples) |

`harbor_silting_link` adds labor for dredging, and its social consequence records harbor towns stranded inland.

**Intensification has real losses:**

- **Planned wetland drainage:** `cultivation_yield` +.0085, but `ecology_recovery` −.0068, `ecological_pressure` +.0051, and lost foraging and hunting.
- **Embanked salt meadows:** lose recovery and foraging.
- **Saline drains:** push salt downstream (`water_pollution` +).
- **Sewage fields:** raise `disease_exposure`.
- **Press-cake fuel and orchard smokes:** add `pollution`.
- **Volcanic vine soils:** add a little `disaster_risk`.

**Logistics costs:**

| Items | Cost |
|---|---|
| Canals, harbors and far trade | `disease_exposure` |
| Harbor dues, frontier customs | `trade_capacity` |
| Duty-free harbor | `state_capacity` |
| Frontier customs, the state post, river tolls | `legitimacy` |
| Trading colonies, small change coins, long relay trade | `cohesion` |
| Timber rafting, flash locks, ocean crossings | `injury_risk` |
| Roads, canals, the post, stud farms | `labor_demand` |

**Security costs:**

| Items | Cost |
|---|---|
| Walls, standing and long-service armies, warships | `labor_demand` |
| Professional corps, mercenaries, frontier walls, long service, grain levy, chariot-to-cavalry | `legitimacy` |
| Curfew, mercenaries, treaty levies, evacuations, contracted circuit walls | `cohesion` |
| Curfew | `trade_capacity` |
| Wet moats | `disease_exposure` |
| Armored horse | fodder (`food_output`) |
| Contracted walls | `housing_output` |
| Incendiaries | `disaster_risk` |

Treaty border levies are the one cost that runs the other way: they lower `labor_demand`, because foreign levies spare our own men.

## Known limitations

- **Short endurance and travel totals.** Logistics endurance, travel, container and storage-loss totals come out at +19–24%, below the 30% floor. This is deliberate. Most of this era's gains are in ships, coin and trade, and roads and posts already scored high before 600.
- **Raw sums.** The totals above are raw sums. Other lines also add to shared keys such as `trade_capacity`, `warfare_readiness` and `labor_demand`. The era ceilings belong to the rebalance pass.
- **Art is provisional.** It reuses existing paintings until block paintings arrive.
- **The generator is not in the repo.** It is a scratch script. The committed JSON is authoritative.
