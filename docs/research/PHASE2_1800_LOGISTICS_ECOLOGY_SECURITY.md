# Phase 2, years 1200–1800: Logistics, Ecology and Security effects

Files:

- `data/research/effects_y1200_1800/logistics.json`
- `data/research/effects_y1200_1800/ecology.json`
- `data/research/effects_y1200_1800/security.json`

The window runs from about AD 360 to about AD 1360. It covers late-antique retreat, early-medieval recovery and the high-medieval expansion. The benchmarks for this window (`benchmarks_1800.json`) are nearly flat: defense share stays at 5–10% and army share at 1–5%, and trade reach grows only from 3,000–9,000 km to 4,000–12,000 km. Growth is therefore held to the low-to-middle part of the 30–60% range.

## Counts

Every item of the three lines in `data/research/blocks/y1200_1800.json` has a row. That is 220 rows in total.

| Line | Rows | NEW | Catalog | Key thresholds | Social consequences |
|---|---:|---:|---:|---:|---:|
| Logistics | 72 | 70 | 2 | 13 | 10 |
| Ecology | 72 | 71 | 1 | 11 | 12 |
| Security | 76 | 72 | 4 | 19 | 10 |

- **Every row** has `effects`, a one-line era-grounded `observation` and `art`.
- **NEW rows** also have a short `name`.
- **Key thresholds** also have an `ability_reason`.
- **Catalog rows** keep their authored names, recipes and gates. These are `clinker_shell_construction`, `carvel_frame_construction`, `nitrate_cultivation`, `mounted_remount_school`, `counterweight_engines`, `ocean_sailing` and `black_powder`. Their effects and observations were replaced to fit this block's scale.
- **`ocean_sailing` has been rescaled.** Its row was scaled for year 560 (warfare .008, coordination .0049). It is now a key threshold at 1692: naval .016, warfare .012, endurance .006, coordination .0049. It also carries costs: disease .003 (ship fever), timber pressure .003 and labor .002. It gates sailing warships and convoys.
- **`black_powder` is chemistry only.** Its effects are chemical control .008, observation .002, disaster risk .004 and injury .0016. It adds no warfare readiness, and its ability reason says it gives no general a new weapon, in line with `test_research_1800`.
- **Art** uses existing paintings only, from `paper/`, `first300-cards/`, `discovery-600/` and `subjects/`. Examples are `subjects/ocean_sailing-v1.png`, `counterweight_engines-v1.png`, `black_powder-v1.png`, `nitrate_cultivation-v1.png`, `curtain_wall_systems-v1.png`, `naval_arsenals-v1.png`, `caravanserais-v1.png`, `canal_locks-v1.png` and `pike_drill-v1.png`.
- **Names** follow alternative history. There are no real names, places or peoples.

## Validation

- `tests/test_research_blocks.gd`: 7/7 pass.
- `tests/test_research_1800.gd`: 5/5 pass. This includes `ocean_sailing` warfare > 0 and black powder unlocking no gun.
- Every effect key is in `SocietyModel.EFFECT_LIMITS`, every file is valid JSON, and every `art` path exists. No loader warnings were printed.
- Routine values are within ±0.008. Key thresholds are within ±0.02. The largest are the rigid horse collar (haul .020) and the realm relay post (travel .020).

## Calibration

Values were drafted per item and then scaled per key:

- **Logistics:** haul ×1.25, naval ×1.1, endurance ×1.7, travel ×1.6, and storage-loss, food-storage and container ×1.4.
- **Ecology:** recovery ×1.25, timber pressure ×1.35, ecological pressure ×1.5, soil ×1.7, water pollution and pollution ×1.2.
- **Security:** warfare ×0.75, security ×0.9, coordination ×0.7 and injury ×0.8. The draft ran warfare at +59%, which is too hot for a window with flat army-size benchmarks.

A second pass added endurance, travel, storage and ecological-pressure terms to fitting items where those sub-dimensions were thin. Examples are post, wagons, bulk ships, casks and staple stores, and the forest, commons and fishery rules.

## Totals

These are raw sums before adoption weighting, using `proposed_year`. The 1200 column is the cumulative total from `effects/` plus `effects_y600_1200/`. The 1500 and 1800 columns add this block's items up to that year.

The previous block's growth (600→1200) is given for comparison.

### Logistics

| Sub-dimension | Effect | 1200 | 1500 | 1800 | 1800 vs 1200 | Previous block |
|---|---|---:|---:|---:|---:|---:|
| Carrying capacity | `haul_capacity` | .385 | .464 | .525 | +36% | +42% |
|  | `logistics_endurance` | .310 | .365 | .402 | +30% | +21% |
|  | `fatigue` | −.039 | −.043 | −.043 | | |
| Route quality | `route_speed` | .317 | .364 | .421 | +33% | +32% |
|  | `travel_speed` | .262 | .304 | .342 | +30% | +24% |
|  | `injury_risk` | −.031 | −.035 | −.054 | | |
| Storage system | `storage_loss` | −.115 | −.126 | −.144 | +26% | +19% |
|  | `food_storage` | .084 | .090 | .099 | +18% | +36% |
|  | `container_capacity` | .122 | .127 | .136 | +11% | +22% |
| Trade reach | `trade_capacity` | .308 | .344 | .435 | +41% | +56% |
|  | `naval_capacity` | .403 | .476 | .555 | +38% | +39% |
| Costs | `timber_pressure` | .076 | .085 | .095 | | |
|  | `labor_demand` | .090 | .101 | .108 | | |
|  | `disease_exposure` | .029 | .032 | .036 | | |
|  | `food_output` (fodder) | .019 | .017 | .014 | | |
|  | `legitimacy` | .001 | −.002 | −.002 | | |

### Ecology

| Sub-dimension | Effect | 1200 | 1500 | 1800 | 1800 vs 1200 | Previous block |
|---|---|---:|---:|---:|---:|---:|
| Land health | `soil_productivity` | .240 | .282 | .313 | +31% | +52% |
|  | `ecological_pressure` | −.289 | −.331 | −.365 | +26% | +34% |
|  | `disaster_risk` | −.053 | −.066 | −.084 | +59% | |
| Natural recovery | `ecology_recovery` | .387 | .432 | .506 | +31% | +29% |
|  | `cultivation_yield` | .121 | .147 | .157 | +30% | +48% |
|  | `foraging_yield` / `hunting_yield` | .180 / .098 | | .177 / .098 | net loss | |
| Pollution control | `pollution` | −.082 | −.081 | −.091 | +10% | +20% |
|  | `water_pollution` | −.084 | −.084 | −.109 | +30% | +29% |
|  | `water_safety` | .046 | .049 | .060 | +30% | +38% |
|  | `sanitation` | .044 | .044 | .051 | +16% | +36% |
| Resource sustainability | `timber_pressure` | −.310 | −.340 | −.405 | +30% | +38% |
|  | `timber_yield` | .228 | .232 | .247 | +8% | +6% |
| Costs | `labor_demand` | .060 | .082 | .099 | | |
|  | `legitimacy` | −.003 | −.003 | −.003 | | |
|  | `chemical_control` (nitre) | .000 | .000 | .011 | new | |

### Security

| Sub-dimension | Effect | 1200 | 1500 | 1800 | 1800 vs 1200 | Previous block |
|---|---|---:|---:|---:|---:|---:|
| Military readiness | `warfare_readiness` | .481 | .558 | .699 | +45% | +53% |
|  | `task_coordination` | .074 | .089 | .109 | +47% | +61% |
|  | `naval_capacity` | .032 | .050 | .086 | | |
| Organized defense | `security_efficiency` | .407 | .499 | .578 | +42% | +45% |
|  | `labor_demand` (cost) | .217 | .247 | .284 | +31% | +46% |
| Public safety | `injury_risk` | −.036 | −.041 | −.053 | +49% | |
|  | `cohesion` / `legitimacy` | −.003 / .019 | −.008 / .010 | −.006 / .003 | net loss | |
| Crisis resilience | `disaster_resilience` | .073 | .084 | .094 | +29% | +55% |
|  | `disaster_risk` | −.042 | −.038 | −.041 | flat | |
| Costs | `timber_pressure` | .053 | .061 | .077 | | |
|  | `fuel_demand` | .015 | .015 | .019 | | |
|  | `trade_capacity` | .011 | .010 | .007 | | |

## Threshold items

Values are after scaling.

**Logistics**

| Year | Item | Main effects |
|---:|---|---|
| 1300 | Rigid horse collar | haul .020, travel .0048; costs fodder (`food_output` −.002) |
| 1340 | Clinker shell | naval .0154 |
| 1385 | Keeled sailing longships | naval .0176; costs injury |
| 1455 | Nailed horseshoes | travel .016, endurance .0085 |
| 1540 | Carvel frame | naval .0154 |
| 1580 | Guarded trade fairs | trade .016; costs disease |
| 1600 | Floating needle compass | route .008 |
| 1650 | Bills of exchange | trade .014; costs cohesion |
| 1685 | Sternpost rudder | naval .0154 |
| 1692 | High-sided bulk ships | haul .0175 |
| 1703 | Realm relay post | travel .020, state .006; costs legitimacy, labor, fodder |
| 1742 | Compass-bearing sea charts | route .008 |
| 1757 | Dry compass card | route .008 |

**Ecology**

| Year | Item | Main effects |
|---:|---|---|
| 1325 | Endowed reclamation | soil .0136, cultivation .010, but recovery −.005 |
| 1450 | Irrigation water tribunals | water .008, cohesion .003 |
| 1497 | Licensed forest clearing | timber pressure −.0108 |
| 1555 | Sluiced polders | cultivation .010, but recovery −.0063 |
| 1592 | Forest law courts | recovery .010; costs legitimacy −.004 |
| 1652 | Coppice with standards | timber pressure −.0135, timber yield .008 |
| 1692 | Stinted commons | ecological pressure −.012 |
| 1700 | Dike boards | disaster risk −.008 |
| 1750 | River offal bans | water pollution −.0096 |
| 1755 | Coal-smoke limits | pollution −.0096 |
| 1775 | Nitrate cultivation | chemical control .008; costs pollution |

**Security**

| Year | Item | Main effects |
|---:|---|---|
| 1220 | Triple land walls | security .0126 |
| 1245 | Military district settlement | warfare .0075 |
| 1290 | Generals' field manual | coordination .0056 |
| 1300 | Paired stirrups | warfare .009 |
| 1345 | Siphoned liquid fire | naval .008; costs disaster risk |
| 1390 | Summoned mounted retinues | warfare .009 |
| 1440 | Burgh defense network | security .0108 |
| 1478 | Motte and bailey | security .009 |
| 1515 | Couched lance charge | warfare .0105 |
| 1525 | Stone keep towers | security .0108 |
| 1583 | Arsenal-built war galleys | naval .012 |
| 1667 | Counterweight engines | warfare .0105 |
| 1673 | Decimal army | coordination .007 |
| 1692 | Ocean sailing | naval .016, warfare .012 |
| 1727 | Concentric castles | security .0126 |
| 1742 | Coat of plates | injury −.0048 |
| 1752 | Militia pike hedge | warfare .0075, cohesion .003 |
| 1765 | Massed longbow volleys | warfare .009 |
| 1787 | Black powder | chemistry only |

Each security ability reason says what a *general* or *admiral* can now attempt. Examples are giving ground wall by wall, raising district armies without coin, planting quick castles on taken land, breaking a line with a charge, replacing a lost fleet in a season, and carrying and supplying an army across open sea. The ruler gives objectives. No row implies direct unit control.

Liquid fire is a guarded state secret, and nitre incendiaries are small. No row expresses a weapon of mass destruction.

## Costs introduced

| Line | Cost | Rows |
|---|---|---:|
| Logistics | `labor_demand`: levies, road duty, canals, estate carting, the post | 8 |
| Logistics | `disease_exposure`: fairs, cabotage, caravans, inns, canals | 7 |
| Logistics | `timber_pressure`: clinker, carvel and bulk hulls | 5 |
| Logistics | fodder (`food_output`): collar, horse wagons, barges, post | 4 |
| Logistics | `legitimacy`: wagon levy, road duty, relay post | 3 |
| Logistics | `injury_risk`: longships, desert crossings, sledge roads | 3 |
| Logistics | `institutional_rigidity`: staple towns, galley convoys, sea customs | 3 |
| Ecology | `labor_demand`: reclamation, polders, dikes, coppicing, hedges | 19 |
| Ecology | lost `cultivation_yield`, `foraging_yield`, `hunting_yield` and `food_output` from protective rules: forest law, parks, wardens, stinting, marginal-land retreat | 18 in all |
| Ecology | `legitimacy`: hunting reserves, forest courts, licensed clearing | 5 |
| Ecology | new `pollution` and `ecological_pressure`: peat, sea-coal, salt-pan fuel, wandering glassworks, nitre beds | 9 |
| Ecology | `ecology_recovery` lost to reclamation, polders and wolf bounties | 3 |
| Security | `labor_demand`: walls, keeps, castles, arsenals, watches | 29 |
| Security | `legitimacy` | 13 |
| Security | `cohesion`: retinues, captive corps, foreign guards, free companies, service money | 6 |
| Security | `timber_pressure`: galleys, mottes, hoardings, engines | 9 |
| Security | `fuel_demand`: mail, plate | 3 |
| Security | `trade_capacity`: pressed fleets, export bans, booms | 4 |
| Security | `housing_output`: citadels, tile roofs | 2 |
| Security | fodder: remounts, couched lance | 3 |
| Security | `disaster_risk`: liquid fire, nitre fire, powder | 3 |

Some costs run the other way:

- **Military districts, the rotating half-levy, service money and free companies** lower `labor_demand`. They buy readiness with land, coin or loyalty instead.
- **Free companies** also lower `security_efficiency`, because they prey on the country between wars.

## Missing recipes (proposals for Phase 3)

Only `clinker_shell_construction` and `carvel_frame_construction` have `civilian_industry` recipes, and those stay authored. None of this block's rows sets `production_items` or `resource_requirements`.

These recipes are proposed:

- **Transport:**
  - `rigid_horse_collar`: padded collar and hames.
  - `nailed_horseshoes`: horseshoe and nail batches; needs iron.
  - `sternpost_rudder`: pintle and gudgeon ironwork.
  - `high_sided_bulk_ships`: bulk hull sections.
  - `floating_needle_compass` / `dry_compass_card`: compass. Needs lodestone, which is an unmapped resource.
- **War:**
  - `series_built_war_galleys`: arsenal galley hulls.
  - `counterweight_engines`: engine timber kit. Military equipment already gates on it, but there is no civilian recipe.
  - `coat_of_plates` / `plate_limb_defences`: plate armor pieces.
  - `siphoned_liquid_fire`: siphon and fire mixture. Needs Bitumen, and should stay under the ruler's control.
- **Materials:**
  - `nitrate_cultivation` / `nitre_earth_leaching`: nitre (saltpetre) batches.
  - `peat_fuel_cutting` / `sea_coal_substitution`: peat and sea-coal fuel.

`black_powder` should get no weapon recipe before `powder_artillery`.

## Known limitations

- **Storage totals are short.** Container capacity (+11%) and food storage (+18%) sit below 30%. The line has almost no storage-system items in this window, since granaries and stores belong to Nutrition and Infrastructure.
- **Ecology pollution is short.** Air pollution grows only +10%, because sea-coal, peat, salt-pan and glass fuel add smoke that the smoke limits only partly offset. This is deliberate, and so is the fall of foraging and hunting.
- **Security legitimacy falls.** It drops from .019 to .003, because the feudal and mercenary rows each carry a small legitimacy cost. Cohesion also ends slightly negative.
- **Raw sums.** The totals are raw sums per line. Shared keys such as warfare, trade, labor demand and naval are also fed by other lines, so era ceilings belong to the rebalance pass.
- **The generator is not in the repo.** It is a scratch script. The committed JSON is authoritative.
