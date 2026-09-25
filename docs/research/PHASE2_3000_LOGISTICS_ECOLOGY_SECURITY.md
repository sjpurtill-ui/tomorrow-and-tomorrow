# Phase 2, years 2400–3000: Logistics, Ecology and Security effects

Files:

- `data/research/effects_y2400_3000/logistics.json`
- `data/research/effects_y2400_3000/ecology.json`
- `data/research/effects_y2400_3000/security.json`

The window runs from about AD 1800 to AD 2030: steam and rail, the electric and chemical age, the two world-scale wars, and the welfare and information era. Its benchmarks (`benchmarks_3000.json`) point in different directions:

- **Rising:** trade reach grows from 10,000 to 18,000 km, message speed from 80 to 40,000 km/day, and energy capture from 27,000 to 85,000 kcal per head.
- **Rising, then falling:** army share of the population peaks at 5% around 2800 and falls to 1% by 3000. The largest army rises to about 80,000 and then falls back.
- **Flat or falling:** defence labour share stays at 2.5–5%.

Growth is therefore held to the low-middle of the 30–60% range. Military readiness gets the smallest growth that still marks the industrial battlefield.

## Counts

Every item of the three lines in `data/research/blocks/y2400_3000.json` has a row. That is 383 rows in total.

| Line | Rows | NEW | Catalog | Key thresholds | Social consequences |
|---|---:|---:|---:|---:|---:|
| Logistics | 128 | 124 | 4 | 29 | 29 |
| Ecology | 125 | 110 | 15 | 23 | 27 |
| Security | 130 | 103 | 27 | 31 | 18 |

- **Every row** has `effects`, a one-line era-grounded `observation` and `art`.
- **NEW rows** also have a short `name`.
- **Key thresholds** also have an `ability_reason`.
- **Values:** routine values are clamped to ±0.008 and key thresholds to ±0.02. The largest values are container shipping, the public steam railway and the great nature park.
- **Names:** the rows use no real names. Canals, parks, disasters and treaties are generic, for example "a fishing bay", "a capital" and "a great park".
- **Art:** only existing paintings are used. Examples:
  - `subjects/`: `steam_propulsion`, `ocean_sailing`, `canal_locks`, `jet_propulsion`, `armored_hulls`, `submersible_hulls`, `carrier_aviation`, `guided_weapons` and `naval_logistics`
  - `paper/`: `rail_*`, `radio_telegraphy`, `binary_adders`, `gas_composition_analysis`, `relative_stratigraphy` and `hull_condition_surveys`
  - `discovery-600/`: `weather_sign_reading` and `messenger_relay_stations`
  - The line paintings, where no subject painting fits.

### Catalog rows replaced

46 catalog rows had their `effects` and `observation` replaced. Names, recipes, gates and method profiles stay as authored.

| Group | Rows | Change |
|---|---|---|
| Military (`joint_force_knowledge`, `combined_arms_doctrine`, `military_education_knowledge`) | 27 | The joint-force rows carried the flat generic warfare .035 and coordination .015, about four times the block scale. The doctrine and school rows had empty effects. All now carry item-specific values (warfare .002–.0105, naval .005–.0096) and real costs such as fuel, labor, and trade lost to submarines. Doctrine levels, training profiles and equipment gates are unchanged. |
| Rail (`rail_track_foundations`, `rail_gauge_standards`, `rail_vehicle_braking`) | 3 | These had empty effects. Their recipes (`timber_rail_panels`, gauge templates and wheelsets) are kept. |
| `hull_condition_surveys` | 1 | This had empty effects. |
| Geoscience (`geoscience_knowledge`) | 13 | These had empty effects. They now have small survey, extraction and observation terms. Their prospecting profiles are unchanged. |
| `developmental_stage_series`, `soil_assays` | 2 | Rescaled to small observation, soil and cultivation terms. |

## Weapons of mass destruction

Six rows are gated by `scripts/sovereign_weapons.gd` (SOVEREIGN): `chemical_gas_warfare`, `fission_weapon`, `thermonuclear_weapon`, `intercontinental_missiles`, `missile_submarine_patrols` and `hypersonic_glide_vehicles`.

- **No battle effects.** None of these rows has warfare readiness, naval capacity, security, coordination or endurance. The generator asserts this.
- **Costs only.** Each carries legitimacy and cohesion losses (dread), disaster risk, and labor demand for the state programme. The bombs and gases also carry pollution (fallout, gas works) and health risk.
- **Ability reason.** Each says that the weapon is known, not usable, and that only the ruler's spoken decision in the Court can loose it.

The restricted means get this treatment:

- **`aerial_bombardment` and `armed_remote_strike`** carry a modest warfare effect, because their use against forces in the field is the general's own call. They also carry legitimacy and cohesion costs. Their ability reasons say that striking a city needs the ruler's spoken decision.
- **`machine_assisted_targeting`** gives coordination and a little warfare. It also carries institutional rigidity for the human sign-off, and its ability reason says it never widens a general's authority.

Deterrence and treaty rows carry legitimacy, security and disaster-risk effects, with no warfare gain:

- Deterrence doctrine, the hotline, test bans and launch warning.
- The gas, germ and chemical conventions, inspection, and the naval arms limit, which lowers naval capacity and labor.
- The mine ban, which carries a small negative warfare effect and the cost of demining.

`test_research_3000` still passes unchanged.

## Totals

These are raw sums before adoption weighting, using `proposed_year`.

- **2400** is the cumulative total of `effects/`, `effects_y600_1200/`, `effects_y1200_1800/` and `effects_y1800_2400/`, as filled when this was written.
- **2700** and **3000** add this block's items up to that year.
- **Previous block** is the 1800→2400 growth.

For cost keys and lower-is-better keys, a negative total is the good direction.

### Logistics

| Effect | 2400 | 2700 | 3000 | 3000 vs 2400 | Previous block |
|---|---:|---:|---:|---:|---:|
| `haul_capacity` | .701 | .821 | .957 | +37% | +34% |
| `logistics_endurance` | .528 | .631 | .673 | +27% | +31% |
| `route_speed` | .653 | .783 | .863 | +32% | +55% |
| `travel_speed` | .454 | .544 | .617 | +36% | +33% |
| `storage_loss` | −.187 | −.206 | −.252 | 35% better | 30% better |
| `container_capacity` | .187 | .202 | .240 | +28% | +37% |
| `food_storage` | .116 | .128 | .136 | +17% | +17% |
| `trade_capacity` | .671 | .789 | .892 | +33% | +54% |
| `naval_capacity` | .756 | .848 | .866 | +15% | +36% |
| Cost: `fuel_demand` | .008 | .054 | .094 | new | |
| Cost: `pollution` | .005 | .032 | .032 | new | |
| Cost: `ecological_pressure` | .017 | .025 | .044 | | |
| Cost: `water_pollution` | .001 | .005 | .012 | | |
| Cost: `disaster_risk` | −.001 | .004 | .012 | | |
| Cost: `disease_exposure` | .062 | .070 | .076 | | |
| Cost: `labor_demand` | .153 | .179 | .178 | | |
| `injury_risk` | −.076 | −.092 | −.110 | safer | |

Pollution rises through the steam and motor decades. It levels off after 2750 as electrification, oil-electric traction and later battery vehicles offset the jets and motorways. Travel speed, endurance and naval capacity are held back because their raw sums near their limits of .65, .70 and .90.

### Ecology

| Effect | 2400 | 2700 | 3000 | 3000 vs 2400 | Previous block |
|---|---:|---:|---:|---:|---:|
| `ecology_recovery` | .658 | .769 | .869 | +32% | +30% |
| `ecological_pressure` | −.380 | −.414 | −.485 | 28% better | 4% better |
| `timber_pressure` | −.520 | −.606 | −.619 | 19% better | 28% better |
| `soil_productivity` | .369 | .369 | .366 | −1% (deliberate) | +18% |
| `cultivation_yield` | .211 | .212 | .195 | −8% (deliberate) | +34% |
| `hunting_yield` / `foraging_yield` | .086 / .167 | .077 / .157 | .068 / .157 | net loss | |
| `pollution` | −.117 | −.124 | −.157 | 34% better, almost all after 2800 | 29% better |
| `water_pollution` | −.109 | −.111 | −.142 | 30% better, almost all after 2800 | 1% better |
| `water_safety` | .064 | .065 | .071 | +11% | +5% |
| `disaster_risk` | −.103 | −.129 | −.142 | 38% better | 23% better |
| Cost: `health_risk` | .003 | .000 | .008 | | |
| Cost: `labor_demand` | .154 | .178 | .208 | | |
| Cost: `craft_output` (compliance) | −.005 | −.010 | −.035 | | |
| Cost: `construction_rate` (review delays) | .010 | .009 | .000 | | |

The modern costs are real rows, not footnotes:

- **Industrial pollution:** acid fume blight, gasworks waste, killing smog, mercury poisoning, acid rain, ocean plastic and forever chemicals.
- **Climate forcing:** measured warming and extreme-event attribution each add disaster risk and cut cultivation. Dust storms add disaster risk and strip soil.
- **Species loss:** colony collapse, invasive species and extinction by hunting cut recovery and hunting yields and raise ecological pressure. The acclimatization societies cause part of this loss themselves.
- **Degradation:** salted irrigation land, reactor fallout and the ozone hole.
- **Remediation has its own cost.** The fume inspectorate, clean air, the EPA, polluter-pays cleanup, the carbon market, pledges, net-zero and the plastics cap carry `labor_demand`, `craft_output` loss, `institutional_rigidity`, fuel costs or `legitimacy`.
- **Protection has its own cost.** Parks, reserves, wolf reintroduction and thirty-percent protection cost hunting, foraging, timber, food or cohesion.

Two results are deliberate:

- **Soil and cultivation end slightly lower.** The recognized harms outweigh the soil science in this line.
- **Pollution control mostly lands after 2800.** Before then, the pollution rising in Logistics and Production goes largely unanswered.

`pollution-` is scaled ×0.5 because the key's beneficial limit is only −.15.

### Security

| Effect | 2400 | 2700 | 3000 | 3000 vs 2400 | Previous block |
|---|---:|---:|---:|---:|---:|
| `warfare_readiness` | 1.087 | 1.285 | 1.452 | +34% | +56% |
| `task_coordination` | .188 | .238 | .280 | +49% | +73% |
| `naval_capacity` | .145 | .222 | .258 | +78% (small base) | +67% |
| `security_efficiency` | .793 | .863 | 1.013 | +28% | +37% |
| `disaster_resilience` | .131 | .142 | .178 | +36% | +39% |
| `disaster_risk` | −.047 | −.048 | −.046 | flat | |
| Cost: `labor_demand` | .392 | .430 | .503 | +28% | +38% |
| Cost: `legitimacy` | −.014 | −.025 | −.047 | falls | |
| Cost: `cohesion` | .010 | .006 | −.035 | falls | |
| Cost: `fuel_demand` | .046 | .057 | .073 | +59% | |

- **Warfare readiness** is scaled ×0.75 and naval ×0.8 to hold growth near the low end.
- **The raw sums pass the limits.** Warfare readiness was already above its limit of 1.0 at 2400, and security efficiency passes its limit of .80. Era ceilings belong to the rebalance pass, so the growth rates are the figures that matter here.
- **Legitimacy and cohesion fall** because of conscription, political police, cameras, mass interception, remote strike and the dread that weapons of mass destruction bring.

## Threshold items

The main effects are listed after scaling.

**Logistics**

| Year | Item | Main effects |
|---:|---|---|
| 2419 | River steamers | route .010, trade .007; costs fuel, pollution |
| 2467 | Public steam railway | haul .019, route .0125, endurance .012; costs fuel, pollution, timber |
| 2480 | Intercity railway | route .010, travel .009 |
| 2501 | Ocean steamship line | naval .015, trade .0115 |
| 2507 | Prepaid stamp post | trade, state, coordination, cohesion |
| 2523 | `rail_gauge_standards` | standardization .008, haul .0075 |
| 2584 | Continental railway | route .0125, haul .010; costs hunting, legitimacy, ecological pressure |
| 2584 | Isthmus ship canal | route .0125, naval .012; costs disease, labor |
| 2597 | Postal union | trade .007 |
| 2621 | Railway standard time | coordination .008 |
| 2629 | Motor carriage | travel .0045; costs fuel, injury, pollution |
| 2688 | Series-built motor car | travel .0075; costs fuel .008, pollution .006, injury .006 |
| 2704 | High-lock canal | route .0125 |
| 2715 | Air mail | travel .006 |
| 2731 | Motorways | route .0125; costs soil, ecological pressure |
| 2752 | Pallets and fork-lifts | haul .010, container .007; costs labor displaced |
| 2757 | Oil-electric locomotives | haul .010, fuel efficiency .006 |
| 2805 | Jet airliners | travel .009; costs disease, pollution |
| 2815 | Shipping containers | haul .015, trade .014, container .011; costs cohesion |
| 2815 | National motorway network | route .0125 |
| 2817 | First satellite | knowledge, route |
| 2835 | High-speed rail | travel .0075, pollution −.002 |
| 2848 | Moon landing | legitimacy, cohesion, knowledge; no cargo |
| 2858 | Overnight air express | trade .007 |
| 2860 | Bar codes | storage loss −.008, coordination .006 |
| 2912 | Open satellite positioning | route .0125, survey .006 |
| 2918 | Online orders | trade .009; costs cohesion, pollution |
| 2958 | Battery-electric cars | pollution −.006, fuel −.004; costs mining pressure |
| 2992 | Driverless freight | haul .010; costs cohesion |

**Ecology**

| Year | Item | Main effects |
|---:|---|---|
| 2429 | Forestry academy | timber pressure −.019 |
| 2442 | `structural_geologic_mapping` | survey, extraction, mining |
| 2493 | Realm geological survey | survey, extraction, state |
| 2501 | Ice age theory | knowledge |
| 2533 | Telegraphed weather maps | disaster risk −.012 |
| 2568 | Fume works inspectorate | pollution −.005; costs labor, craft |
| 2571 | Human impact treatise | ecological pressure −.012, recovery .011 |
| 2587 | State weather service | disaster risk −.012 |
| 2592 | Great nature park | recovery .020 |
| 2656 | Coal warming estimate | knowledge only |
| 2680 | State forest service | timber pressure −.019, recovery .011 |
| 2761 | Ecosystem concept | recovery .011 |
| 2801 | Computed forecasts | disaster risk −.012 |
| 2815 | Clean air act | pollution −.007, health risk −.004; costs fuel |
| 2820 | Carbon dioxide record | knowledge only |
| 2830 | Persistent pesticide warning | recovery .011; costs cultivation, chemical control |
| 2848 | Environmental impact review | ecological pressure −.016; costs construction, rigidity |
| 2850 | Environmental protection agency | water pollution −.016; costs craft, rigidity |
| 2892 | Ozone treaty | health risk −.006 |
| 2895 | Climate assessment panel | knowledge, state |
| 2905 | Climate framework convention | legitimacy; no limits, so warming continues |
| 2938 | Carbon market | pollution and fuel −.004; costs craft |
| 2962 | Universal climate pledges | pollution and fuel −.004; costs craft, labor |

**Security**

The main effects are listed after ×0.75 on warfare and ×0.8 on naval.

| Year | Item | Main effects |
|---:|---|---|
| 2405 | Army corps | warfare .009, coordination .007 |
| 2411 | Class-year conscription | warfare .009; costs labor .008, legitimacy, cohesion |
| 2427 | Staff war college | coordination .0085 |
| 2453 | Percussion caps | warfare .0075 |
| 2477 | Uniformed police | security .012 |
| 2531 | Expanding-base bullet | warfare .009 |
| 2557 | `armored_hulls` | naval .0096 |
| 2557 | Railway mobilization | warfare .009, endurance .006 |
| 2560 | `metallic_cartridges` | warfare .009 |
| 2579 | Stable high explosive | construction, mining, warfare |
| 2587 | Reserve mobilization | warfare .009 |
| 2624 | `automatic_actions` | warfare .009 |
| 2627 | Smokeless powder | warfare .0075 |
| 2659 | Quick-firing field gun | warfare .009 |
| 2664 | `indirect_fire` | warfare .009 |
| 2667 | `submersible_hulls` | naval .0096 |
| 2683 | Battleships | naval .011; costs labor, fuel |
| 2704 | Continuous trenches | security .010; costs disease, injury, cohesion |
| 2709 | `armored_vehicles` | warfare .0105 |
| 2764 | Radar | security .012 |
| 2768 | Armoured division | warfare .012 |
| 2773 | Integrated air defence | security .012 |
| 2787 | Fission bomb | costs only |
| 2805 | Thermonuclear weapon | costs only |
| 2818 | Intercontinental missiles | costs only |
| 2825 | Reconnaissance satellites | security .010; dated observations only |
| 2838 | Test-ban treaties | pollution, disaster risk, health risk down; legitimacy |
| 2902 | Satellite-guided strike | warfare .0105 |
| 2928 | Mass signals surveillance | security .012; costs legitimacy −.008, cohesion |
| 2945 | Cyber defence command | security .012 |
| 2980 | Small drones | warfare .009 |

Each military ability reason says what a general or admiral can now attempt. Examples are commanding a corps, reaching the frontier by timetable, shelling unseen targets, holding a front with trenches, breaking through with an armoured division, and meeting raids with integrated air defence. No row implies direct unit control. Intelligence rows give dated observations only.

## Costs introduced

| Line | Cost | Rows |
|---|---|---:|
| Logistics | `fuel_demand` | 32 |
| Logistics | `labor_demand` | 23 |
| Logistics | `pollution` | 19 |
| Logistics | `injury_risk`: motor traffic, lorries, airships, hump yards | 13 |
| Logistics | `ecological_pressure`: railways across the continent, canals, motor roads, tankers, battery metals | 8 |
| Logistics | `disaster_risk`: pipelines, tankers, just-in-time fragility, very large ships | 7 |
| Logistics | `cohesion`: displaced dockers, drivers and shops | 7 |
| Logistics | `disease_exposure`: canals, ocean lines, jets | 6 |
| Logistics | `water_pollution` | 5 |
| Logistics | `legitimacy` | 5 |
| Logistics | endurance lost to lean supply | 2 |
| Ecology | `labor_demand` | 26 |
| Ecology | `hunting_yield` lost | 16 |
| Ecology | `craft_output` lost to compliance | 16 |
| Ecology | `ecological_pressure` from harm rows | 11 |
| Ecology | lost `ecology_recovery` | 8 |
| Ecology | lost `cultivation_yield` | 8 |
| Ecology | `health_risk` | 7 |
| Ecology | `legitimacy` | 7 |
| Ecology | lost `soil_productivity` | 6 |
| Ecology | lost `food_output` | 6 |
| Ecology | lost `foraging_yield` | 5 |
| Ecology | lost `construction_rate` | 5 |
| Ecology | `institutional_rigidity` | 5 |
| Ecology | `disaster_risk`: warming, dust, fire suppression | 4 |
| Security | `labor_demand` | 32 |
| Security | `legitimacy` | 21 |
| Security | `cohesion` | 17 |
| Security | `injury_risk` | 12 |
| Security | `fuel_demand` | 9 |
| Security | `disaster_risk` | 8 |
| Security | `trade_capacity` lost to blockades, submarines, mobilization and battleships | 4 |
| Security | `pollution` and `health_risk`: gas and fallout | 3 |

Some costs run the other way:

- **Labor falls** with fork-lifts, containers, oil-electric traction, robots, driverless lorries, centralized traffic control and the naval arms limit.
- **Pollution falls** with electrified lines, electric trams and buses, high-speed rail, battery cars and low-carbon ship fuels.

## Missing recipes (proposals for Phase 3)

No row sets `production_items` or `resource_requirements`. Only the three rail catalog items have `civilian_industry` recipes, and those stay authored.

These recipes are proposed:

- **Transport:**
  - `public_steam_railway`: locomotive and iron rail. Needs Coal and Iron.
  - `rolled_steel_rails`
  - `iron_hulled_steamers` / `screw_propeller_ships`: iron hull plates and a propeller.
  - `series_built_motor_car` / `motor_freight_lorries`: motor chassis. Needs Crude Oil.
  - `pneumatic_tyres`: needs rubber, which is unmapped.
  - `intermodal_shipping_containers`: steel container.
  - `pallet_forklift_handling`: pallets.
  - `mass_battery_electric_cars`: battery packs. Needs lithium or nickel.
- **Ecology:**
  - `fish_hatcheries`: fry batches.
  - `tree_planting_days`: nursery seedlings.
  - `fume_works_inspectorate`: condensing towers.
  - `clean_air_act`: smokeless fuel briquettes.
  - `polluter_pays_cleanup`: remediation works.
- **Security:**
  - `stable_blasting_explosive`: dynamite sticks. Needs Nitrates.
  - `smokeless_propellant`
  - `metallic_cartridges` / `automatic_actions` ammunition. Military equipment already gates on these, but there is no civilian recipe.
  - `barbed_wire_entanglements`: wire.
  - `radio_detection_ranging`: radar set.
  - `field_telephone_lines`
- **Weapons of mass destruction:** never give them a recipe or equipment that a general can draw on without the sovereign gate.

## Validation

- `tests/test_research_blocks.gd`: 7/7 pass.
- `tests/test_research_3000.gd`: 5/5 pass.
- All three files are valid JSON. Every effect key is in `SocietyModel.EFFECT_LIMITS`, and every `art` path exists. No loader warnings were printed.

## Known limitations

- **The 2400 baseline could change.** The 2400 column reads the filled `effects_y1800_2400/` files (see `PHASE2_2400_LOGISTICS_ECOLOGY_SECURITY.md`). If those files are rebalanced, rerun the totals.
- **Raw sums.** The totals are raw sums per line. Shared keys such as warfare, naval, trade, pollution and labor are also fed by other lines. Era ceilings and the pollution balance against Production belong to the rebalance pass.
- **Short growth:** naval capacity in Logistics (+15%) and timber pressure (19% better) grow less than the target. Naval is held back by its limit, and coal takes over from wood as the era's fuel.
- **The generator is not in the repo.** It is a scratch script. The committed JSON is authoritative.
