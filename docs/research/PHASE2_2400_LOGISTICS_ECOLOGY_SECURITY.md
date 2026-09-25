# Phase 2, years 1800–2400: Logistics, Ecology and Security effects

Files:

- `data/research/effects_y1800_2400/logistics.json`
- `data/research/effects_y1800_2400/ecology.json`
- `data/research/effects_y1800_2400/security.json`

The window runs from about AD 1360 to about AD 1800. It covers the gunpowder transition, ocean sailing and contact across the ocean, canals and stage roads, the fiscal-military state, and the first naturalists and forest law. The benchmarks (`benchmarks_2400.json`) move more than in the previous window:

- **Trade reach** grows from a typical 4,000 km to 10,000 km.
- **Army size** grows from a typical 8,000 to 30,000.
- **Army share** grows from 1.2% to 2%.
- **Message speed** grows from 40 to 80 km/day.
- **Defense labour share** stays flat at 5–10%.

So warfare, trade and route speed grow at the upper end of the 30–60% range. Security efficiency and endurance grow at the lower end.

## Counts

Every item of the three lines in `data/research/blocks/y1800_2400.json` has a row. That is 276 rows in total.

| Line | Rows | NEW | Catalog | Key thresholds | Social consequences |
|---|---:|---:|---:|---:|---:|
| Logistics | 83 | 81 | 2 | 20 | 13 |
| Ecology | 89 | 82 | 7 | 16 | 21 |
| Security | 104 | 93 | 11 | 25 | 12 |

- **Every row** has `effects` (recognized names only), a one-line era-grounded `observation` and an existing `art` path.
- **NEW rows** have a short `name`, because the design names are full sentences.
- **Key thresholds** have an `ability_reason`.
- **Catalog rows** keep their authored names, recipes, contracts, training and prospecting profiles, and doctrine.

### Catalog rows whose effects were replaced

**Overscaled rows.** These were scaled for a single discovery in the old catalog:

| Item | Old effects | New effects |
|---|---|---|
| `powder_artillery` | warfare .24, state .05 | warfare .0107 |
| `military_staffs` | warfare .15, endurance .09, coordination .08 | warfare .008, endurance .008, coordination .0063 |
| `pike_drill`, `matchlock_drill`, `mounted_firearms`, `naval_gunnery` | warfare .035, coordination .015 | warfare .008–.0107; naval gunnery is now naval .0048 and warfare .004 |
| `rifled_barrels` | warfare .035 | warfare .004 |
| `aerostat_observation` | warfare .035, coordination .015 | warfare .0027, survey .003 |

**Previously empty rows** now have effects:

- `dry_dock_services`
- `wagonway_haulage`
- the 7 science catalog rows in Ecology
- `gun_detachment_school`
- `gun_line_security`
- `articulated_plate_armor`

**Rows with no force bonus.** The authored contracts for `articulated_plate_armor` and `gun_line_security` say that knowledge alone grants no force bonus. They therefore carry no `warfare_readiness`:

- **Plate armour** has injury −.003, and costs of fuel and labour.
- **Gun-line security** has coordination and security only.

## Gunpowder and the unit gates

No effect unlocks a unit or equipment. Effects are society totals. Unit and equipment gates remain what `military_unit_catalog.gd` and `military_equipment_extension.gd` set. Each ability reason names only what that item's own gate already opens:

| Item | What its ability reason covers |
|---|---|
| `hand_gun_tubes` | hand gunners |
| `powder_artillery` | bombards |
| `pike_drill` | pikes |
| `matchlock_drill` | arquebusiers |
| `mounted_firearms` | pistol horse |
| `regimental_light_guns` | field guns |
| `grenadier_companies` | grenadiers (no ability reason, not a key threshold) |
| `galloping_horse_artillery` | horse artillery (no ability reason) |
| `rifled_barrels` | marksmen (no ability reason) |
| `military_staffs` | staff planning |

The pre-gun rows (`fire_lance_tubes`, `pot_bolt_guns`, `war_wagon_laager`) and the later drill and lock rows add readiness only. `flintlock_ignition`, `socket_bayonet` and `platoon_fire_battalions` describe what the general can do with musketeers he already has. The unit and equipment gates stay unchanged, and `test_research_2400` passes.

Every security ability reason describes what a general or admiral can attempt, such as:

- breaching old walls in days
- holding a bastioned town
- a rolling platoon fire
- fortress belts
- staff-planned marches
- divisions on separate roads

The ruler gives objectives. No row implies direct unit control.

**Recruitment.** `nation_in_arms_levy` changes consent, speed and cost, not a draft ceiling. This follows the recruitment rule in `GENERAL_CAMPAIGN_DESIGN.md`.

**Weapons of mass destruction.** No row expresses one. Rockets, grenades and fireships are small, local and inaccurate.

## Validation

- `tests/test_research_blocks.gd`: 7/7 pass.
- `tests/test_research_2400.gd`: 6/6 pass.
- Every effect key is in `SocietyModel.EFFECT_LIMITS`.
- Every file is valid JSON.
- Every `art` path exists.
- Routine values are ≤ .008. Key thresholds are ≤ .02 after scaling and clipping.

## Calibration

Values were drafted per item, then scaled per key. Some factors apply to one sign only:

| Line | Scaling |
|---|---|
| Logistics | travel ×1.15, storage loss ×1.4, container ×1.3, endurance ×1.25, haul ×1.12, survey and preservation ×0.6 |
| Ecology | positive recovery ×1.5, negative ecological pressure ×2.2, positive soil ×2.0, negative air pollution ×1.2, negative water pollution ×1.6, observation and preservation ×0.6 |
| Security | warfare ×0.67, coordination ×0.45, naval ×0.6, state ×0.5, security ×1.45, standardization ×0.6 |

The security draft ran warfare at +82% and coordination at +160%, which is above the army benchmarks.

A second pass added endurance and storage terms to ships, canals, wagons and the victualling rows. It also capped eight routine rows at .008.

## Totals

These are raw sums before adoption weighting, using `proposed_year`. They are cumulative over all four blocks:

- **1800** means items before year 1800.
- **2100** and **2400** add this block's items up to that year.

The "Previous block" column is the 1200→1800 growth from `PHASE2_1800_LOGISTICS_ECOLOGY_SECURITY.md`.

### Logistics

| Sub-dimension | Effect | 1800 | 2100 | 2400 | 2400 vs 1800 | Previous block |
|---|---|---:|---:|---:|---:|---:|
| Carrying capacity | `haul_capacity` | .525 | .621 | .701 | +34% | +36% |
|  | `logistics_endurance` | .402 | .486 | .528 | +31% | +30% |
| Route quality | `route_speed` | .421 | .538 | .653 | +55% | +33% |
|  | `travel_speed` | .342 | .388 | .454 | +33% | +30% |
|  | `injury_risk` | −.054 | −.063 | −.076 | +41% | |
| Storage system | `storage_loss` | −.144 | −.177 | −.187 | +30% | +26% |
|  | `container_capacity` | .136 | .179 | .187 | +37% | +11% |
|  | `food_storage` | .099 | .114 | .116 | +17% | +18% |
| Trade reach | `trade_capacity` | .436 | .589 | .671 | +54% | +41% |
|  | `naval_capacity` | .555 | .702 | .756 | +36% | +38% |
| Costs | `labor_demand` | .108 | .130 | .153 | | |
|  | `disease_exposure` | .036 | .055 | .062 | | |
|  | `timber_pressure` | .095 | .116 | .110 | | |
|  | `institutional_rigidity` | .004 | .016 | .018 | | |
|  | `food_output` (fodder) | .014 | .011 | .003 | | |

### Ecology

| Sub-dimension | Effect | 1800 | 2100 | 2400 | 2400 vs 1800 | Previous block |
|---|---|---:|---:|---:|---:|---:|
| Land health | `soil_productivity` | .313 | .336 | .369 | +18% | +31% |
|  | `ecological_pressure` | −.365 | −.345 | −.380 | +4% net | +26% |
|  | `disaster_risk` | −.084 | −.088 | −.103 | +23% | +59% |
| Natural recovery | `ecology_recovery` | .506 | .548 | .658 | +30% | +31% |
|  | `cultivation_yield` | .157 | .179 | .211 | +34% | +30% |
|  | `hunting_yield` / `foraging_yield` | .098 / .177 | | .086 / .167 | net loss | |
| Pollution control | `pollution` | −.091 | −.097 | −.117 | +29% | +10% |
|  | `water_pollution` | −.109 | −.107 | −.109 | flat | +30% |
| Resource sustainability | `timber_pressure` | −.404 | −.452 | −.520 | +28% | +30% |
|  | `timber_yield` | .247 | .279 | .310 | +26% | +8% |
| Science (new here) | `observation_rate` | .120 | .138 | .210 | +76% | |
| Costs | `labor_demand` | .099 | .117 | .154 | | |
|  | `legitimacy` | −.003 | −.001 | −.016 | | |
|  | `cohesion` | .024 | .016 | .005 | | |

**Gross flows this block:**

| Effect | Rows that improve it | Rows that worsen it |
|---|---:|---:|
| `ecological_pressure` | −.090 | +.075 |
| `water_pollution` | −.018 | +.017 |
| `soil_productivity` | +.076 | −.020 |
| `ecology_recovery` | +.206 | −.054 |

### Security

| Sub-dimension | Effect | 1800 | 2100 | 2400 | 2400 vs 1800 | Previous block |
|---|---|---:|---:|---:|---:|---:|
| Military readiness | `warfare_readiness` | .698 | .919 | 1.087 | +56% | +45% |
|  | `task_coordination` | .109 | .142 | .188 | +73% | +47% |
|  | `naval_capacity` | .087 | .117 | .145 | +67% | |
| Organized defense | `security_efficiency` | .578 | .695 | .793 | +37% | +42% |
|  | `state_capacity` | .072 | .089 | .105 | +46% | |
| Public safety | `injury_risk` | −.053 | −.057 | −.057 | +7% | +49% |
|  | `legitimacy` | .003 | −.008 | −.014 | net loss | |
| Crisis resilience | `disaster_resilience` | .094 | .106 | .131 | +39% | +29% |
|  | `disaster_risk` | −.041 | −.038 | −.047 | +15% | flat |
| Costs | `labor_demand` | .284 | .348 | .392 | | |
|  | `fuel_demand` | .020 | .040 | .046 | | |
|  | `institutional_rigidity` | .023 | .036 | .041 | | |

The totals reach 1.087 for warfare and 1.2 for SocietyModel's clamp. Shared keys also get contributions from other lines, so era ceilings belong to the rebalance pass.

## Threshold items

Only the main effects are shown, after scaling.

**Logistics**

| Year | Item | Main effects |
|---:|---|---|
| 1850 | Full-rigged three-master | naval .016, haul .009 |
| 1878 | Passenger coach | travel .016 |
| 1883 | Ocean carrack | naval .018, haul .013; costs timber, disease |
| 1898 | Ocean wind circuit | route .016, naval .010 |
| 1905 | Latitude sailing | route .016 |
| 1912 | Transoceanic voyages | trade .018, naval .010; costs disease .006 |
| 1930 | Public letter post | travel .0115, trade .008, state .006 |
| 1955 | Ocean galleon | naval .018, warfare .004 |
| 1969 | Escorted ocean fleets | trade .014; costs rigidity |
| 1978 | Straight-course charts | route .016 |
| 1998 | Bulk carrier | haul .018, trade .010; labour −.003 |
| 2080 | Summit canal | haul .018; costs labour .006 |
| 2110 | Long-route stagecoaches | travel .018 |
| 2160 | Two-sea canal | trade .016, haul .011 |
| 2262 | Reflecting octant | route .014 |
| 2306 | Sextant | route .012 |
| 2318 | Lunar longitude | route .016 |
| 2326 | Contour coal canal | haul .020, timber −.004; costs pollution |
| 2348 | Marine timekeeper | route .016 |
| 2372 | Timed mail coaches | travel .018, security .003 |

**Ecology**

| Year | Item | Main effects |
|---:|---|---|
| 1876 | Arsenal oak reserves | timber pressure −.012; costs legitimacy |
| 1910 | Tillage protection | cultivation .008, soil .008 |
| 1935 | Enclosure by agreement | soil .016; costs cohesion, foraging |
| 1942 | Species exchange | cultivation .012; costs pressure, disease |
| 2020 | Nuisance law | pollution −.0096, water pollution −.0096 |
| 2050 | Water meadows | soil .016, food .008 |
| 2122 | Coal smoke treatise | pollution −.012 |
| 2138 | Realm forest ordinance | timber −.016, recovery .015; costs legitimacy |
| 2142 | Relative stratigraphy | survey .006 |
| 2218 | Sustained yield | timber −.018, recovery .015 |
| 2270 | Biological classification | observation .006 |
| 2294 | Economy of nature | pressure −.018, recovery .015 |
| 2326 | Enclosure acts | soil .020; costs cohesion, legitimacy, foraging |
| 2338 | Rain forest reserves | recovery .018 |
| 2362 | Weather observer network | resilience .006 |
| 2374 | Deep time | observation, knowledge .006 |

**Security**

| Year | Item | Main effects |
|---:|---|---|
| 1822 | Hand-gun tubes | warfare .0067; costs injury, disaster |
| 1848 | Bombards | warfare .0107, security −.003 (old walls lose value) |
| 1856 | Plate harness | injury −.003 only |
| 1872 | Standing horse | warfare .0094, security .0058 |
| 1884 | Pike drill | warfare .0094 |
| 1902 | Siege train | warfare .0107; costs fodder |
| 1920 | Matchlock | warfare .0107 |
| 1942 | Bastion trace | security .020; costs labour .006, housing |
| 1946 | Pike and shot | warfare .0107 |
| 1976 | Pistol horse | warfare .008 |
| 2002 | Countermarch | warfare .0107 |
| 2014 | Printed drill | warfare .0067, coordination .0045 |
| 2026 | Flintlock | warfare .0107 |
| 2062 | Regimental guns | warfare .0107 |
| 2100 | Crown standing army | warfare .0134, security .0087; costs labour .006 |
| 2116 | Line of battle | naval .0096 |
| 2134 | Police lieutenant | security .020; costs legitimacy, cohesion |
| 2148 | Parallels | warfare .0094, injury −.004 |
| 2160 | Fortress belt | security .020; costs labour .008 |
| 2182 | Socket bayonet | warfare .0107 |
| 2204 | Platoon fire | warfare .0121 |
| 2320 | Military staffs | endurance .008, warfare .008 |
| 2332 | Artillery system | warfare .0107 |
| 2360 | All-arms divisions | warfare .0121 |
| 2386 | Nation in arms | warfare .0134; costs labour .010, fodder |

## Costs introduced

Counts are rows carrying each cost.

**Logistics**

| Cost | Rows | Sources |
|---|---:|---|
| `labor_demand` | 18 | canals, yards, the post, coaches |
| `disease_exposure` | 10 | ocean voyages, contact, canals, coaches |
| `institutional_rigidity` | 6 | house of trade, navigation law, companies |
| fodder (`food_output`) | 6 | |
| `timber_pressure` | 6 | big hulls |
| `injury_risk` | 5 | |
| `fuel_demand` | 3 | |
| `pollution` | 2 | coal canal, trial steamboat |
| `trade_capacity` | 1 | navigation law |

**Ecology**

| Cost | Rows | Sources |
|---|---:|---|
| `labor_demand` | 23 | |
| `ecological_pressure` | 21 | mining, amalgamation, contact, island felling, whaling, plantations |
| `food_output` | 15 | protective rules and cold years |
| `ecology_recovery` | 14 | |
| `legitimacy` | 10 | reserves, game law, enclosure |
| `cultivation_yield` | 9 | |
| `hunting_yield` | 9 | |
| `soil_productivity` | 7 | |
| `cohesion` | 7 | |

Ecology also adds new pollution rows: smelter fume, tailings, mercury, peat, nitre and town fouling.

**Security**

| Cost | Rows | Sources |
|---|---:|---|
| `labor_demand` | 48 | |
| `fuel_demand` | 14 | guns and powder |
| `legitimacy` | 13 | saltpetre men, press gangs, police informers, passports, mercenaries |
| `injury_risk` | 9 | early guns, grenades, rockets |
| `institutional_rigidity` | 8 | |
| fodder | 7 | siege train, horse, nation in arms |
| `disaster_risk` | 7 | powder |
| `cohesion` | 5 | |
| `timber_pressure` | 5 | |
| `trade_capacity` | 5 | passports, customs, marque, press |
| `security_efficiency` | 3 | bombards, wheel-lock pistols, privateers |
| `housing_output` | 2 | bastion clearance, barracks |

Some rows lower `labor_demand` instead of adding to it. They buy readiness with land, loyalty or honest accounts:

- captains' contracts
- patented regiments
- muster commissaries
- soldier crofts
- socket bayonet
- the bulk carrier

## Missing recipes (proposals for Phase 3)

Only two catalog rows in these lines have `civilian_industry` recipes gated on them:

- `articulated_plate_armor`: `forged_plate_armor` and `sheet_plate_armor`
- `wagonway_haulage`: `rail_wagons_900` and `rail_wagons_1435`

Both stay authored. No row sets `production_items` or `resource_requirements`. These recipes are proposed:

- **Ships:**
  - `ocean_carrack`, `ocean_galleon`, `fluyt_bulk_carrier`: ocean hull sections
  - `copper_hull_sheathing`: copper sheathing plate, which needs Copper
  - `full_rigged_three_master`, `topsail_rig`: mast and rigging sets
- **Navigation:**
  - `mariners_quadrant`, `backstaff`, `reflecting_octant`, `sextant`: navigation instruments
  - `marine_timekeeper`: marine clock, which needs precision work
  - `printed_sea_atlases`, `nautical_almanac`: printed charts and almanacs
- **Road:** `passenger_coach`, `steel_leaf_springs`, `dished_wheels`: coach bodies and leaf springs
- **Supply:** `victualling_yards` / `ocean_victualling`: ship biscuit and salt-meat casks
- **Guns:**
  - `hand_gun_tubes`: hand-gun tube
  - `wheel_lock_firearms`, `snaphance_lock`, `flintlock_ignition`: gun locks
  - `paper_cartridges`: cartridges
  - `socket_bayonet`, `plug_bayonet`: bayonets
  - `solid_bored_cannon`, `regimental_light_guns`, `standardized_artillery_system`: bored guns and carriages with limbers
  - `iron_cased_war_rockets`: rockets, under the ruler's control
- **Kit:** `regimental_uniforms`: regimental coats
- **Materials:**
  - `state_nitre_plantations`: nitre (with the Production line's saltpetre works)
  - `commercial_peat_cutting`: peat fuel
  - `condensing_smelter_flues`: lead recovered from fume

## Known limitations

- **Ecological pressure and water pollution are net flat.** This is deliberate. The window adds as much damage as it repairs through tailings, mercury amalgamation, island felling, whaling, fur depletion, plantations and town river fouling. Protective law reaches water only at the end of the window. Gross flows are shown above.
- **Soil productivity (+18%) and food storage (+17%) are short.** Most soil and storage gains in this window belong to Nutrition (rotation, granaries) and Infrastructure (drainage).
- **Hand-gun tubes carry little readiness.** Their weapon power comes from the gated unit and equipment, not from society totals. The same is true of plate armour.
- **Legitimacy declines in Security and Ecology.** Security legitimacy falls to −.014 and Ecology legitimacy to −.016. This comes from saltpetre men, press gangs, informers, forest and game law, and enclosure.
- **Raw sums.** Shared keys (warfare, trade, labour, naval) are also fed by other lines. Era ceilings belong to the rebalance pass.
- **The generator is not in the repo.** It is a scratch script. The committed JSON is authoritative.
