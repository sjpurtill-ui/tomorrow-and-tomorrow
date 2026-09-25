# Phase 2 (1800–2400): nutrition, health and demography effects

Files: `data/research/effects_y1800_2400/nutrition.json`, `health.json` and `demography.json`. Every item of the three lines in `data/research/blocks/y1800_2400.json` has a row.

| Line | Rows | New ids | Catalog ids | Key thresholds (`ability_reason`) | `social_consequence` | Rows with a cost |
|---|---:|---:|---:|---:|---:|---:|
| Nutrition | 87 | 84 | 3 | 16 | 19 | 51 |
| Health | 86 | 84 | 2 | 22 | 18 | 51 |
| Demography | 83 | 83 | 0 | 20 | 24 | 58 |

Every row has:

- effects, with 2–8 keys, all named in `SocietyModel.EFFECT_LIMITS` and all inside their bounds;
- a short name;
- a one-line in-world observation;
- an existing painting as `art`.

The largest single value is .019 (food_storage on the grain magistracy). Routine values are .001–.008.

Validation:

- `test_research_blocks` passes 7/7 and `test_research_2400` passes 6/6.
- `test_agronomy_knowledge` and `test_field_medicine` also pass. They cover the catalog items that were given effects.
- A fresh `dump_effects_600.gd` run shows all 256 rows applied exactly as authored, with no loader warnings.

## Catalog items changed

- **`row_spacing_trials`, `sowing_depth_trials`, `seedbed_firming`.** Their authored effects were empty. Each now has a small `cultivation_yield` (.003–.004). Their agronomy profiles in `agronomy_knowledge.gd` are untouched.
- **`litter_bearer_drill`.** Its effects were empty. It now has `injury_risk` −.005, `warfare_readiness` .003 and `labor_demand` .001. Its field-medicine capacity and its unit and equipment gates are untouched.
- **`preventive_inoculation`.** Its effects were wrongly scaled for this window: `disease_exposure` −.20 and `neonatal_survival` .05, about ten times a key threshold. They are replaced with `disease_exposure` −.007, `neonatal_survival` .009, `health_risk` .004, `state_capacity` .002, `legitimacy` −.002 and `labor_demand` .002.

## Sizing

I drafted the effects at their historical weight. I then scaled each key's beneficial direction so that each sub-dimension grows about 25–45% over its 1800 total. Costs are never scaled.

| Keys | Factor |
|---|---:|
| food_storage | ×1.9 |
| food_spoilage | ×2.5 |
| soil_productivity | ×1.3 |
| injury_risk | ×1.3 |
| sanitation | ×1.8 |
| water_safety | ×1.5 |
| maternal_safety | ×1.65 |
| neonatal_survival | ×1.15 |
| disease_exposure reductions | ×0.5 |
| state_capacity | ×0.6 |
| trade_capacity | ×0.65 |
| knowledge_rate | ×0.5 |
| knowledge_preservation | ×0.85 |
| observation_rate | ×0.8 |
| disaster_resilience, naval_capacity | ×0.7 |

## Effect totals

These are the three lines combined, at full adoption and before clamping. The 1800 column is the total of these lines' registry items from blocks 0–600, 600–1200 and 1200–1800, taken from `dump_effects_600.gd`. The later columns add every 1800–2400 item with `proposed_year ≤ Y`.

| Sub-dimension | Key | 1800 | 2100 | 2400 | Δ 1800→2400 | Previous block Δ |
|---|---|---:|---:|---:|---:|---:|
| Daily supply | food_output | .392 | .481 | .544 | +39% | +44% |
| Land productivity | cultivation_yield | .550 | .631 | .734 | +33% | +30% |
| | soil_productivity | .199 | .232 | .271 | +36% | +21% |
| Stored reserve | food_storage | .520 | .601 | .657 | +26% | +33% |
| | food_spoilage | −.370 | −.417 | −.455 | +23% | +19% |
| Diet quality | nutrition_quality | .331 | .377 | .414 | +25% | +28% |
| General health | health_protection | .329 | .386 | .459 | +39% | +41% |
| Disease control | disease_exposure | −.131 | −.164 | −.192 | net −.061 (+46%) | net −.032 |
| Injury safety | injury_risk | −.211 | −.258 | −.285 | +35% | +29% |
| Treatment harm (cost) | health_risk | .079 | .073 | .067 | net −.012 | net −.001 |
| Water and waste | sanitation / water_safety | .176 / .180 | .188 / .184 | .208 / .193 | +18% / +8% | +21% / +10% |
| Maternal safety | maternal_safety | .320 | .351 | .416 | +30% | +15% |
| Child survival | neonatal_survival | .334 | .362 | .441 | +32% | +17% |
| Fertility conditions | conception_support | .188 | .205 | .201 | +7% | +2% |
| Shelter capacity | housing_output | .284 | .299 | .317 | +12% | +29% |

Side channels, 1800 → 2400:

| Channel | 1800 | 2400 |
|---|---:|---:|
| state_capacity | .263 | .374 (+42%) |
| knowledge_preservation | .245 | .338 |
| knowledge_rate | .086 | .130 |
| trade_capacity | .132 | .188 |
| legitimacy | .088 | .106 |
| cohesion | .105 | .079 (net strain) |
| labor_efficiency | .149 | .184 |
| warfare_readiness | .075 | .102 |
| labor_demand (cost) | .808 | .986 |
| institutional_rigidity (cost) | .276 | .342 |
| ecological_pressure (cost) | .124 | .156 |
| fuel_demand (cost) | .128 | .140 |

### Life expectancy and fertility

The benchmark raises life expectancy (e0) from 28 to 34. Infant mortality falls from 205 to 185 per 1,000 and maternal deaths from 950 to 750 per 100k. TFR stays flat at 5.0.

- **Survival.** Maternal safety rises 30% and neonatal survival 32%, about twice the previous block's rise. The gain is back-loaded: from 1800 to 2100, the two channels rise only 10% and 8%. Most of it comes after 2240:
  - variolation trials, organized inoculation, village inoculation and cowpox vaccination (2244–2394);
  - forceps made public (2266), the lying-in hospital (2294) and the manikin midwife schools (2332);
  - mothers nursing their own infants (2318).

  This matches the benchmark e0 curve (29 → 31 by 2200 → 34 by 2400).
- **Disease control.**
  - From 1800 to 2000, quarantine, health passes, the island station and the standing magistracy give most of the gain.
  - Late in the window, inoculation gives most of it.
  - Crowding costs offset it: the general hospital, subscription hospitals, foundling and lying-in wards, tidal rice fields, colonies, cane islands and wage migration.
- **Fertility conditions stay nearly flat.** Several items raise it:
  - remarriage after the mortality;
  - colonies and colonist brides;
  - dowry funds and caps;
  - field potatoes.

  Several items lower it:
  - witnessed-marriage and secret-marriage rules;
  - strict family settlement;
  - the pauper marriage bar;
  - soldiers' marriage limits;
  - maternal nursing;
  - deliberate birth limitation (2364, −.008).

**Contact.** New-world crops, drinks and drugs all carry `contact_required` from the design. Their effects are ordinary research gains:

- maize, potatoes, cassava, sweet potato, beans and squash, turkeys, chili and tomatoes;
- coffee, cacao and tea;
- fever bark, guaiac wood and flux root.

Contact epidemics are **not** modelled as research. `contact_epidemic_records` only records them (knowledge_preservation, observation_rate, −.002 cohesion, −.0005 disease_exposure). The dying itself belongs to the shock system.

**Clamping.**

- **Diet quality.** Across all lines, nutrition_quality already exceeds its era ceiling (.37 against .35 at 1800), so much of this block's +.083 will be clamped until the ceiling rises (.40 at 2400).
- **Health protection.** The same is true of health_protection (.44 against .39).

## Threshold items

- **Nutrition:**
  - grain magistracy (1862), island cane plantations (1878), maize garden trials (1915), distant-bank salt cod (1925), coffee houses (1962), maize field crop (1970), convertible husbandry (1990);
  - field turnips (2092), grain export bounties (2170), field potatoes (2238), seed drill (2252), agricultural societies (2290), four-course rotation (2324), pedigree breeding (2328), threshing machine (2372), board of agriculture surveys (2386).
- **Health:**
  - forty-day quarantine (1822), quarantine island (1845), standing health magistracy (1906), the new pox recognized (1916), college of physicians (1932), mild gunshot dressing (1948), anatomy atlas (1952), seeds of contagion (1956);
  - folk variolation (2002), blood circulation (2056), fever bark (2080), general hospital (2112), ergot named (2152), state medical college (2166), sanitary cordon (2240), variolation trials (2244), scurvy trial (2296), organized inoculation (2302), seats of disease (2326), medical police (2360), moral treatment (2382), cowpox vaccination (2394).
- **Demography:**
  - ten-yearly household registers (1818), household wealth census (1856), registered foundling hospital (1872), overseas settler colonies (1926), contact epidemic records (1936), shrine registers (1948), witnessed marriage (1968);
  - weekly mortality bills (2008), strict family settlement (2108), political arithmetic (2124), faith refugee edict (2170), life table (2186), realm census (2208), forceps made public (2266), population tables office (2298), frontier colonist recruitment (2326), birth limitation (2364), apportionment census (2380), civil registration (2385), population treatise (2396).

## Costs introduced

- **Crowding and contact exposure (disease_exposure +):**
  - hospitals and wards: the general hospital, subscription hospitals, the incurables hospital, army field hospitals, foundling hospitals (registered and national), foundling wet-nurses, country wet-nursing and the lying-in hospital (childbed fever);
  - land and migration: tidal rice fields, island cane, overseas colonies and wage migration.
- **Treatment harm (health_risk +):**
  - mercury for the pox, chemical medicine, opium tincture and foxglove;
  - variolation, the two forceps items, man-midwives and cassava;
  - spirits (juniper spirit .006, molasses rum .003), sugared tea and fruit pastes.
- **Labour and upkeep (labor_demand +):**
  - every hospital, quarantine, cordon, census and register;
  - paddies and plantations, turnips and rotations.
  - The seed drill, horse hoe, threshing machine and chaff cutters pay some of this back.
- **Rigidity (institutional_rigidity +):**
  - licensing colleges, the state medical college and medical police;
  - registers and censuses, strict family settlement (.006) and lineage books;
  - the pauper marriage bar and export bounties.
- **Social strain (cohesion −, legitimacy −):**
  - plague measures: shut-up plague houses (−.004/−.002), the sanitary cordon and quarantine;
  - institutions of confinement and control: the general hospital, closed bathhouses and the census of wealth;
  - population and marriage policy: the vital-events tax, devotee houses closed, the pauper marriage bar, convict transportation and the faith refugee edict;
  - farming and trade changes: colonies, the threshing machine (machine-breaking), the free grain trade edict and the potato edict;
  - plantations: cane and coffee, worked by bound labour;
  - cheap spirits.
- **Trade given up for safety (trade_capacity −):** forty-day quarantine (−.008), the sanitary cordon (−.005), the island station, health passes, market seals, bills of health, spirit licences and lodging registers.
- **Land and fuel:**
  - Double-cropping, hill clearing and field maize lower soil_productivity.
  - Herring, cod, cane, coffee, hill clearing, dairying, pedigree breeding and colonists raise ecological_pressure.
  - Cane boiling, rum, brewhouses and porter raise fuel_demand.
  - Coke malt adds pollution. The closed range and coke malt reduce fuel and timber demand.

## Missing recipes (proposals for Phase 3)

No `civilian_industry.gd` recipe is gated on any of these ids, so no row sets `production_items` or `resource_requirements`. The recipes worth adding are:

| Item | Proposed recipe |
|---|---|
| `herring_buss_fleets`, `distant_bank_salt_cod`, `sworn_fish_packers` | Sea-cured and stage-dried fish: fish + Salt → barrelled herring / dry cod |
| `town_hopped_brewhouses`, `porter_vat_brewing`, `coke_dried_pale_malt` | Town brewhouse: malt + hops + fuel → keeping beer / porter |
| `molasses_rum`, `juniper_grain_spirit` | Still: molasses or grain + fuel → spirits (needs the distilling apparatus) |
| `island_cane_plantations`, `beet_sugar_discovery` / `sugar_beet_selection` | Roller cane mill and sugar house: cane or beet + fuel → sugar, molasses |
| `sugar_fruit_pastes` | Fruit + sugar + fuel → fruit paste |
| `coffee_houses`, `shipped_tea_trade` | Roasted coffee and packed tea as traded goods |
| `bottled_strong_cider`, `bottle_sparkling_wine`, `fortified_voyage_wines` | Bottling: glass bottles + cider or wine → bottled drink |
| `voyage_keeping_foods` | Sauerkraut and portable soup: cabbage + Salt; bones + fuel → ship stores |
| `seed_drill`, `light_swing_plough`, `horse_hoe_tillage`, `cast_iron_plough_parts`, `threshing_machine`, `fodder_cutting_machines` | Farm implements from timber and iron (shared with Production) |
| `crushed_bone_manure`, `bean_cake_fertilizer` | Bone mill; oil-cake press residue → fertilizer |
| `printed_city_pharmacopoeia`, `chemical_medicine_school`, `opium_tincture`, `cinchona_fever_bark` | Apothecary compounding (`medical_method` profile) |
| `sea_surgeons_chest`, `army_field_hospitals` | Surgeon's chest kit (extends `medical_kit`) |
| `estate_ice_houses` | Ice house: winter ice + straw → summer ice |

## Notes for the coordinator

- **Civic evolution.** Several civic changes are carried in `social_consequence` text only, and each needs Phase 3 code:
  - grain magistrates, gaugers, weigh-masters and packers;
  - the health magistracy, the colleges and the state medical college;
  - searchers, the population tables office and civil registrars.
- **Art.** All art uses existing paintings. `preventive_inoculation-v1.png` is used for the variolation and vaccination family. No painting of a 2400–3000 item is used. For example, `contagion_mapping`, `intensive_gardens`, `compound_microscopy` and `statistical_inference` are all avoided.
- **Not measured in play.** No surrogate or campaign run was made with these effects.
