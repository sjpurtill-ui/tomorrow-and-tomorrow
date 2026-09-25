# Phase 2 (600–1200): nutrition, health and demography effects

Files: `data/research/effects_y600_1200/nutrition.json`, `health.json` and `demography.json`. Every item of the three lines in `data/research/blocks/y600_1200.json` has a row.

- **Nutrition:** 83 rows, 79 NEW and 4 catalog.
- **Health:** 85 rows, 80 NEW and 5 catalog.
- **Demography:** 69 rows, 68 NEW and 1 catalog.

That is 237 rows in total. Every effect name is in `SocietyModel.EFFECT_LIMITS`, and every value is inside its bound. `test_research_1200` passes 3/3 and `test_research_blocks` passes 7/7, with no loader warnings.

## What was filled

- **NEW items.** Each one gets effects (2–7 keys), a short display name and a one-line in-world observation. Key thresholds also get an `ability_reason`. Where the change is social, a row also gets a `social_consequence`: 14 nutrition rows, 3 health and 10 demography.
- **Catalog items.** Their authored effects were sized for the old flat caps. For example, `trained_midwives` had maternal .14 and neonatal .12, and `civic_infirmaries` had health .10. These items are `crop_rotation`, `dough_leavening`, `green_manure_crops`, `grain_milling`, `clinical_observation_rounds`, `clinical_pulse_assessment`, `battlefield_medicine`, `civic_infirmaries`, `surgical_anatomy` and `trained_midwives`. Each row replaces the item's effects with era-sized ones and adds an `ability_reason`. Their authored names and observations are kept. `dough_leavening` and `green_manure_crops` previously had no effects.
- **Sizing.** Effects were drafted at their historical weight, then scaled on each key so that the three lines' 600–1200 additions stay within a budget. Only the beneficial direction is scaled. Routine items are scaled harder than key thresholds, which keep up to 1.6× the routine scale. Costs are never scaled. After scaling, typical routine values are .001–.008 and key thresholds reach .01–.017 on their main channel.
- **Art.** Each row points to an existing painting. The painting is a related 0–600 subject (`subjects/*-v1.png`), a paper painting (`paper/*.png`) or a `discovery-600` painting, such as `ox_drawn_ard` for the iron ard and the coulter plough. Catalog items that have their own subject painting have no `art` row.
- **No production items.** No existing `civilian_industry.gd` recipe is gated on these ids.

## Effect totals (three lines combined, full adoption, before clamping)

The 600 column is the rebalanced 0–600 total of these lines' registry items at year 600. It comes from a fresh `dump_effects_600.gd` run. Each later column adds every 600–1200 item with `proposed_year ≤ Y`. The era ceiling applies to all twelve lines together; the table gives it for reference.

| Sub-dimension | Key | 600 | 700 | 900 | 1200 | Δ 600→1200 | Era ceiling 600 → 1200 |
|---|---|---:|---:|---:|---:|---:|---|
| Daily supply | food_output | .200 | .211 | .245 | .280 | +40% | .35 → .47 |
| Land productivity | cultivation_yield | .327 | .364 | .395 | .423 | +30% | .50 → .61 |
| | soil_productivity | .125 | .150 | .165 | .165 | +32% | .40 → .51 |
| Stored reserve | food_storage | .293 | .319 | .361 | .389 | +33% | .55 → .72 |
| | food_spoilage | −.259 | −.278 | −.295 | −.311 | −20% | |
| Diet quality | nutrition_quality | .212 | .225 | .241 | .258 | +21% | .25 → .30 |
| General health | health_protection | .164 | .176 | .208 | .234 | +43% | .22 → .31 |
| Disease control | disease_exposure | −.074 | −.102 | −.089 | −.099 | net −.025 | .20 → .29 |
| Injury safety | injury_risk | −.109 | −.119 | −.140 | −.165 | −51% | .22 → .31 |
| Treatment harm (cost) | health_risk | .031 | .037 | .069 | .080 | +.049 | |
| Water and waste | sanitation / water_safety | .104 / .139 | .116 / .139 | .132 / .146 | .146 / .164 | +40% / +18% | .22→.34 / .28→.37 |
| Maternal safety | maternal_safety | .216 | .216 | .249 | .279 | +29% | .22 → .34 |
| Child survival | neonatal_survival | .220 | .225 | .250 | .285 | +29% | .22 → .34 |
| Fertility conditions | conception_support | .167 | .178 | .170 | .184 | +10% | .25 → .28 |
| Shelter capacity | housing_output | .165 | .187 | .204 | .221 | +34% | .45 → .57 |

Side channels add small absolute amounts on small bases:

| Channel | 600 → 1200 |
|---|---|
| labor_efficiency | .06 → .12 |
| state_capacity | .09 → .17 |
| knowledge_preservation | .11 → .17 |
| trade_capacity | .03 → .09 |
| cohesion | .05 → .09 |
| labor_demand (cost) | .47 → .66 |
| institutional_rigidity (cost) | .10 → .18 |
| ecological_pressure (cost) | .04 → .08 |

**Life expectancy and infant mortality.** Maternal and neonatal gains from these lines are held to about +.065 each over six centuries, about half of the ceiling's rise. The surrogate already puts balanced-play infant mortality near 165–177/1000 before 600, which is better than the benchmark's high bound. Disease control barely moves, because urban crowding cancels most of the public-health gains. Treatment harm rises. This is deliberate: classical cities were population sinks, e0 should stay around 20–35 and infant mortality around 250–350. The survival gains come mostly from midwifery, infirmaries and child funds, and they arrive after about 850.

## Notable threshold items

- **Nutrition**
  - Iron ard shares (670), crop rotation and leavened bread (700), free-threshing wheat (760) and the rotary quern (800) lead into the town grain dole (818) and husbandry handbooks (864).
  - Then come the overshot mill (1012), the coulter plough (1100) and crystal sugar (1195).
  - Tillage keys carry cultivation_yield ≈ .013–.015 each after scaling.
- **Health**
  - Healing shrines (628) and marsh drainage (660), the largest disease cut at −.02, are followed by town physicians (720), fluid-balance theory (782) and healing schools (805).
  - Dissection, infirmaries and army surgeons arrive at 893. Then come materia medica (named in game as the "Book of Healing Substances"), vessel ligature (955) and military hospitals (990).
  - Late keys are medical encyclopedias (1058), numbing powder (1106), animal experiments (1122), the grand medical system (1160) and charity hospitals (1195).
- **Demography**
  - Overseas colonies (618), forced resettlement (668), two-parent citizenship (700), household tax registers (732), town consolidation (772), property-class census (804) and written wills (828).
  - Trained midwives come at 876, then midwifery manuals (920), the five-yearly census (936), marriage incentives (1033), child grain funds (1050), head-and-land tax units (1160) and federate settlement (1192).

## Costs and trade-offs introduced

On a positive-is-harm key, a cost is a rise, and on the other keys it is a fall. 43 nutrition rows, 40 health rows and 42 demography rows carry at least one.

- **Crowding and cities (disease_exposure +).**
  - Town consolidation .01, tenement blocks .012 (plus disaster_risk and a health_protection penalty) and the drift to the grain city .01 (which also costs cohesion, cultivation and housing).
  - Mixed foundations, harvest migrants carrying fevers and forced resettlement.
  - Infirmaries, charity hospitals, incubation shrines and gymnasium baths, where sickness gathers in crowded wards and pools.
  - Flooded paddies (.01), night-soil market gardens (with water_pollution), yard fowl, dovecotes and fish-sauce vats.
  - Feeding horns: infants survive without a nursing mother, but soured spouts sicken them.
- **Lead and treatment harm (health_risk +).**
  - Boiled must syrup in soft-metal pans. The in-world observation hints at the pallor it causes.
  - Rye ergot in wet years.
  - Bloodletting .006, cupping, purges, enemas, barber-bleeders, poppy draughts, sleep sponges, numbing powder, stone cutting, cataract couching, fluid-balance theory (which drives bleeding and purging), contraceptive herbs and adulterated drug shops.
  - The counterweights are `clay_over_lead_pipes` (−.006, water_safety +), pharmacy weights, fixed-formula decoctions and dosed prescriptions.
  - Lead pipes themselves are in Infrastructure; see the note below.
- **Labour and upkeep (labor_demand, fatigue +).**
  - Terraces, paddies, double cropping, hay mowing, trenched beds, the coulter plough's ox-teams, estates, public ovens and the dole.
  - Physicians, schools, hospitals, street wardens, latrines, burial crews, censuses and registers.
  - Mills pay some of it back: they lower fatigue and labor_demand.
- **Soil and land.** Catch crops, irrigated winter wheat and double cropping lower soil_productivity. The iron ard, the coulter plough, mast-fed swine (with timber_pressure), game parks, summer pastures and veteran allotments raise ecological_pressure.
- **Dependency and rigidity.**
  - The grain dole and public ovens raise legitimacy and cohesion, but also institutional_rigidity and labour.
  - Estates swallow smallholders.
  - Graded flour ranks bread by class.
  - The grand medical system adds rigidity .01, so its errors are copied along with its truths.
- **Social strain (cohesion and legitimacy −).**
  - Forced resettlement (−.012 / −.008), federate settlement, internal passes (which also cost trade and labour), head-and-land tax units, two-parent citizenship (which also costs trade), marriage incentive laws, property-class census, colonies, resident aliens and leper houses.
  - Dissection and vivisection offend.
  - Walled game parks favour the great.
- **Births traded for survival or order (conception_support −).** Contraceptive herbs, family-size counsel, fertile-day counting, celibate communities, the eldest's double share and one lawful wife. Colonies, widow remarriage and marriage incentives push the other way, so fertility conditions rise only about 10%.
- **Other.**
  - Free-threshing wheat keeps worse than spelt (food_storage −).
  - The ox header spills grain (storage_loss +).
  - Tracking pestilence along the roads costs trade.
  - The heiress marriage rule lowers maternal safety.

## Notes for the coordinator and later passes

- **Aqueduct lead.** No lead-pipe item is in these lines. If Infrastructure has lead water pipes or rolled lead sheet for conduits, it should carry a small `health_risk` (about +.003–.005). `clay_over_lead_pipes` (1012) is the remedy for that cost.
- **Stacking.** These totals assume full adoption, and the rebalance pass will add ceilings. The heavy scaling of routine items on health_protection (×0.21) and cultivation_yield (×0.23) is intentional: those keys have many small items. The rebalance can raise the budget if play shows health gains are not felt enough.
- **Not measured in play.** No surrogate or campaign run was made with these effects.
