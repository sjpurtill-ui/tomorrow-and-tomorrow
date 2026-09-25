# Phase 2 (1200–1800): nutrition, health and demography effects

Files: `data/research/effects_y1200_1800/nutrition.json`, `health.json` and `demography.json`. Every item of the three lines in `data/research/blocks/y1200_1800.json` has a row. All 214 are NEW ids, so no catalog item's effects were replaced.

| Line | Rows | Key thresholds (`ability_reason`) | `social_consequence` | Rows with a cost |
|---|---:|---:|---:|---:|
| Nutrition | 72 | 8 | 18 | 52 |
| Health | 72 | 14 | 17 | 40 |
| Demography | 70 | 11 | 23 | 49 |

Each row has effects (2–8 keys), a short name, a one-line in-world observation and an existing painting as `art`. Every effect name is in `SocietyModel.EFFECT_LIMITS` and every value is inside its bound. The largest single value is .016. `test_research_blocks` passes 7/7 and `test_research_1800` passes 5/5. A fresh `dump_effects_600.gd` run shows all 214 rows applied exactly as authored, with no loader warnings.

Design merges: the registry folded `enclosed_community_farms` into Labor and `mutual_surety_households` into Institutions (`mutual_surety_tithings`). It also left out `fallow_sheepfolding` and `marl_lime_dressing` as duplicates of Ecology items. None of these four has a row here.

## Sizing

Effects were drafted at their historical weight. Each key's beneficial direction was then scaled so that the three lines' 1200–1800 additions grow each sub-dimension by about 30–45% over its year-1200 total. Where the benchmarks are flat, growth is held lower. Costs are never scaled. The scale factors are:

| Keys | Factor |
|---|---:|
| health_protection | ×0.58 |
| health_risk reductions | ×0.5 |
| disease_exposure reductions | ×0.9 |
| food_storage | ×1.35 |
| cultivation_yield | ×1.15 |
| soil_productivity | ×1.6 |
| food_spoilage | ×1.5 |
| sanitation | ×1.2 |
| maternal_safety | ×1.25 |
| state_capacity, trade_capacity, legitimacy | ×0.7 |
| knowledge_preservation | ×0.75 |

After scaling:

- Routine values are .001–.008.
- Key thresholds reach .010–.016 on their main channel: plough, rotation and rice about .016 cultivation_yield, the realm survey .007 state_capacity, and arrival isolation −.011 disease_exposure.

## Effect totals (three lines combined, full adoption, before clamping)

- The 1200 column is the current total of these lines' registry items from blocks 0–600 and 600–1200, taken from `dump_effects_600.gd`.
- The later columns add every 1200–1800 item with `proposed_year ≤ Y`.
- The previous-block column is the 600→1200 change.
- The era ceiling is for all twelve lines together.

| Sub-dimension | Key | 1200 | 1500 | 1800 | Δ 1200→1800 | Previous block Δ | Era ceiling 1200 → 1800 |
|---|---|---:|---:|---:|---:|---:|---|
| Daily supply | food_output | .256 | .314 | .368 | +44% | +46% | .47 → .58 |
| Land productivity | cultivation_yield | .423 | .502 | .550 | +30% | +30% | .61 → .71 |
| | soil_productivity | .165 | .202 | .199 | +21% | +32% | .51 → .61 |
| Stored reserve | food_storage | .389 | .429 | .520 | +33% | +33% | .72 → .89 |
| | food_spoilage | −.311 | −.332 | −.370 | +19% | +20% | |
| Diet quality | nutrition_quality | .258 | .302 | .331 | +28% | +21% | .30 → .35 |
| General health | health_protection | .232 | .284 | .328 | +41% | +42% | .31 → .39 |
| Disease control | disease_exposure | −.107 | −.103 | −.139 | net −.032 | net −.025 | .29 → .38 |
| Injury safety | injury_risk | −.156 | −.181 | −.202 | +29% | +43% | .28 → .34 |
| Treatment harm (cost) | health_risk | .080 | .073 | .079 | net −.001 | +.049 | |
| Water and waste | sanitation / water_safety | .146 / .164 | .157 / .172 | .176 / .180 | +21% / +10% | +40% / +18% | .34→.44 / .37→.45 |
| Maternal safety | maternal_safety | .279 | .284 | .320 | +15% | +29% | .34 → .44 |
| Child survival | neonatal_survival | .285 | .314 | .334 | +17% | +29% | .34 → .44 |
| Fertility conditions | conception_support | .184 | .188 | .188 | +2% | +10% | .28 → .30 |
| Shelter capacity | housing_output | .221 | .260 | .284 | +29% | +34% | .57 → .68 |

Side channels, 1200 → 1800:

| Channel | 1200 | 1800 |
|---|---:|---:|
| state_capacity | .164 | .263 |
| knowledge_preservation | .169 | .245 |
| trade_capacity | .091 | .132 |
| legitimacy | .064 | .088 |
| cohesion | .091 | .105 |
| labor_efficiency | .115 | .149 |
| labor_demand (cost) | .646 | .792 |
| institutional_rigidity (cost) | .184 | .276 |
| ecological_pressure (cost) | .073 | .114 |
| fuel_demand (cost) | .106 | .128 |
| timber_pressure (cost) | .003 | .015 |

**Life expectancy.** The benchmarks hold e0 near 28 (high 37) and infant mortality near 205–210 per 1,000 through the whole window, and they have TFR falling from 5.3 to 5.0. The survival channels were sized to match:

- **Survival.** Maternal safety rises 15% and neonatal survival rises 17%, about half the previous block's rise. Most of the gain comes late, from the women's medicine treatise (1590), service before marriage (1750) and sworn town midwives (1785).
- **Disease.** Disease control improves by only −.032 net. Crowding and trade exposure add +.050, which almost cancels the gross −.083 until the pestilence measures of 1790–1797. Until about 1650 the net is flat or slightly worse, because planted towns, merchant quarters, migrant-fed towns, paddies, droving and road hostels add exposure as fast as medicine removes it.
- **Treatment harm** stays flat. Licensing, pharmacopoeias, adulteration tests and apothecary law cancel bloodletting calendars, quicksilver ointment, cautery, spirits and the canon's copied errors.
- **Fertility conditions** are flat. Single-heir farms, younger-son careers, the wide kin marriage ban, unfree birth, the marriage-out fee, single women's houses and late marriage offset colonists, dowries and remarriage.
- **Plague waves** are not modelled here. They are shocks. These rows only change how exposed a town is and how well it responds.

**Diet quality ceiling.** All twelve lines together already total about .298 of nutrition_quality at 1200, against a ceiling of .303. This block's +.073 will mostly be clamped until the ceiling rises (.353 at 1800). The rebalance can trim it if that matters.

## Threshold items

- **Nutrition.** Mouldboard plough (1400), dearth price ceilings (1415), three-field rotation (1430), early-ripening rice (1510, regional), horse ploughing (1560), bread assize (1690), distilled spirits (1722) and town dearth granaries (1785).
- **Health.**
  - Palace physician (1210) and court medical office (1328) come first.
  - Ward hospitals (1420), pox and measles told apart (1458) and the physicians' examination (1466) follow.
  - Then illustrated surgery (1500), the ordered canon (1521), nursing brotherhoods (1588) and the faculty licence (1645).
  - Later come apothecary separation (1700), the inquest handbook (1706) and public dissection (1765).
  - The line ends with pestilence health boards (1790) and thirty-day arrival isolation (1797).
- **Demography.**
  - Conqueror settlement (1270), ranked clan genealogies (1320), the foundling house (1405) and village nucleation (1490).
  - Eldest-son succession (1540), the great realm survey (1572), consent marriage (1585) and colonist recruiters (1622).
  - Hereditary surnames (1700), service before marriage (1750) and poll-tax rolls (1798).

## Costs introduced

- **Crowding and trade exposure (disease_exposure +).** These are the costs the brief asks for in place of plague research.
  - Terraced paddies and dry-land rice basins add .004 and .003.
  - Refuge towns, captive craftsmen, the foundling house and the foundling wheel all add exposure.
  - Herder settlement and village nucleation (.003) crowd people together.
  - Merchant quarters (.004), planted burgage towns (.004) and towns fed by migrants (.006, which also costs neonatal and maternal survival) are the largest urban costs.
  - Colonist recruiters, frontier repopulation and endowed hospital beds add smaller amounts.
  - Trade and travel carry disease too: road hostel infirmaries, spice imports, cattle droving and stew ponds.
- **Treatment harm (health_risk +).**
  - Quicksilver ointment .005, bleeding calendars .004 and distilled spirits .006 (also injury_risk and cohesion −).
  - Cautery irons, the household formulary and the canon textbook's copied errors.
  - Smaller amounts from uroscopy, ergot in maslin, rice wine, cider and confectionery.
- **Labour and upkeep (labor_demand +).** Hospitals, dispensaries, nursing orders, pestilence boards and gate watches, ordinances, censuses and surveys, paddies, cane, dairies and granaries. Horse ploughing pays some of it back (labor_demand −, fatigue −), though it eats oats (food_storage −).
- **Rigidity (institutional_rigidity +).**
  - The ordered canon (.006), ranked genealogies (.006), the faculty licence, entail, eldest-son succession, noble lineage rolls and the physicians' examination.
  - The dearth ceilings, bread assize and granaries also add rigidity.
- **Social strain (cohesion and legitimacy −).**
  - Conqueror settlement (−.006 / −.004), frontier repopulation, captive craftsmen, unfree birth, the poll tax (−.004 / −.005) and the realm survey.
  - Vagrant expulsion, leper panels, public dissection, contact-contagion shunning and pestilence cordons and boards.
  - Graded loaves, spice display and the drove-route quarrels.
- **Trade given up for safety (trade_capacity −).**
  - Arrival isolation (−.008, plus travel_speed −.004), the gate watch and health boards (−.005 each) and dearth ceilings (−.004).
  - Smaller amounts from the bread assize, licensing, entail and ransom silver.
- **Land and fuel.**
  - Early rice and divided holdings lower soil_productivity.
  - Warrens, drove routes, the mouldboard plough, colonists, dairies and fisheries raise ecological_pressure.
  - Kilns, sugar boiling, spirits, malting and smokehouses raise fuel_demand, and barrels, barns and hop poles raise timber_pressure.
  - Deserted villages turned to pasture cost cultivation and housing, but give ecology_recovery.

## Missing recipes (proposals for Phase 3)

No existing `civilian_industry.gd` recipe is gated on any of these ids, so no row sets `production_items` or `resource_requirements`. The items with `resources_known: Salt` are gated by design conditions only. Recipes worth adding:

| Item | Proposed recipe |
|---|---|
| `grain_drying_kilns`, `malting_floor_brewhouses` | Kiln-dried grain and malt: grain + fuel → dry grain or malt |
| `hopped_export_beer` | Keeping beer: malt + hops + water + fuel → barrelled beer |
| `distilled_spirits` | Still: wine or ale + fuel → spirits. Needs the `chemical_distillation` apparatus. |
| `barrel_gutted_herring`, `barreled_salt_meat`, `keg_salted_butter` | Brine-barrel packing: fish, meat or butter + Salt + barrels → keeping food |
| `stockfish_drying`, `dried_durum_pasta` | Rack drying: fish or durum dough → dry stores |
| `smoked_red_herring` | Smokehouse: salted fish + fuel → red herring |
| `long_aged_hard_cheese`, `estate_vaccaries` | Cheese room: milk + Salt → hard cheese |
| `refined_loaf_sugar`, `sugar_candied_fruit` | Sugar house: cane juice + fuel + clay cones → loaf sugar. Then sugar + fruit → candied fruit. |
| `hospital_formulary`, `town_antidotary`, `printed_state_pharmacopoeia` | Apothecary compounding: herbs + honey or sugar → standard drugs (`medical_method` profile) |
| `distilled_herb_waters` | Herb waters from the still |
| `reading_spectacles` | Ground lenses + frame. Depends on Knowledge's `optical_lenses`. |

## Notes for the coordinator

- **Civic evolution.** The design's government and civic-life hooks are carried in `social_consequence` text only: market and bread wardens, ale-taster, grain master, medical office, licensing board, coroner, health magistracy, census commissioners and foundling wardens. They need Phase 3 code.
- **Art.** All art uses existing 0–600 paintings: `subjects/*-v1.png`, `paper/*.png` and `discovery-600/*.png`. No painting belonging to a later catalog item was used, such as `child_growth_records` or `nursing_care_organization`.
- **Not measured in play.** No surrogate or campaign run was made with these effects.
