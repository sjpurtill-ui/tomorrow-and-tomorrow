# Phase 2: nutrition, health and demography effects

Files: `data/research/effects/nutrition.json`, `health.json` and `demography.json`. Every registry item in the three lines has a row: 106 nutrition, 89 health and 76 demography, 271 in total. The loader accepts all of them. Every effect name is one of the 67 in `SocietyModel.EFFECT_LIMITS`, and every value is inside its bound. `test_research_600` passes 14/14 and `test_opening_fire_knowledge` passes 10/10.

## What was filled

| | Nutrition | Health | Demography |
|---|---:|---:|---:|
| NEW items (effects, name, observation) | 39 | 45 | 41 |
| Era/catalog items with effects changed or extended | 32 | 0 | 4 |
| `social_consequence` | 25 | 9 | 22 |
| `ability_reason` (catalog items) | 41 | 12 | 3 |
| `art` (era and catalog items without their own painting) | 50 | 36 | 32 |

- **NEW items.** Each one has 2–6 effects. Typical sizes are 0.004–0.03. Key thresholds get more, up to 0.08 (the ox-drawn ard, drive hunts, famine reserves, stocked fish ponds, the injury manual, daughter hamlets and frontier grants). Each also has a shorter display name and a one-sentence in-world observation. Most NEW items carry a cost or trade-off alongside the gain:
  - Milking and penned herds raise `disease_exposure`.
  - The saddle quern raises `fatigue`.
  - Towns draw villagers in: disease goes up and cohesion goes down.
  - Patrilocal residence lowers `maternal_safety`.
  - Pessaries and three-year nursing lower `conception_support`.
  - Poppy, purges, trepanation and lead eye salves raise `health_risk`.
- **Catalog items with no effects.** These are practices whose only consequence was the physical `food_system` lever. They now also get small channel effects: edible plants, the mortar, nuts, roasting, root grating, fruit screening, acorns, pulses, the earth oven, solar drying, threshing, winnowing, dehulling, dough, steaming, baking, seed cleaning, malting, starch, sifting and parboiling. The four fire practices stay effect-free because `test_opening_fire_knowledge` requires it.
- **Catalog effects changed** (values are merged over the authored ones; nothing authored is removed):
  - `animal_taming`: food_output 0.004 → 0.026, plus disease and labor costs. A penned herd is a food source.
  - `hermetic_grain_storage`: only had container_capacity 0.02. Adds food_storage 0.04, less spoilage and less storage loss.
  - `root_cellars`, `raised_granaries`, `stock_rotation`, `brine_fermentation`, `vinegar_pickling`: each adds a storage or spoilage term that fits what it is.
  - Era: `midwife_apprenticeship_lines` adds neonatal survival 0.01 (it is a key threshold). Small additions to `seasonal_protein_sourcing`, `varied_forage_rotation`, `deliberate_milk_souring`, `reserve_allocation_priority`, `seasonal_conception_timing`, `kin_fostering_networks` and `communal_child_supervision_rotas`.
- **Art.** NEW items keep their line painting, because `test_research_600` asserts that fallback. The related paintings proposed for the 123 NEW items are listed under "Art proposals" below. Era and catalog items without their own painting point to a related existing painting, or to their own paper painting where one exists (ember tending, the fire practices).

## Early-life protections (`codex/early-consequences`: `early_life_conditions.gd`)

That file is not on this branch. Each of its named practice ids that is in these lines now carries the matching channel effect, so both routes feed the protection: the practice list and the general-channel fallback.

| Protection | Channel (scale) | Items that feed it |
|---|---|---|
| Clean water and waste | water_safety .22, sanitation .20 | clean_water (authored .16), latrine_siting, refuse_removal (sanitation .03, year 50), river_bathing, fly_protection, ash_fat_soap |
| Wound and injury care | injury_risk −.14 | wound_cleaning, splints, plus the NEW wound packing, honey dressing, suturing, traction and board splints |
| Remedies | health_protection .22 | herbal_classification, dietary_healing_regimens, isolation_practice, case_records, plus small early NEW remedies |
| Birth care | maternal_safety .20 | birth_attendants, maternal_recovery, labor_position_customs, cord_afterbirth_handling, plus the NEW birth stool and women's-ailment texts |
| Child care and weaning food | neonatal_survival .18 | shared_childcare, swaddling, weaning_food_softening, food_pounding_mortars (+.008), food_steaming_vessels (+.006), plus slings, kin care for orphans and wet nurses |
| Cooked and sorted food | nutrition_quality .20 | edible_resource_recognition (+.01), hearth_roasting_control (+.015), earth_oven_cooking (+.01), food_steaming_vessels (+.01), pulse_splitting (+.008). `ember_tending` counts only through the practice list (fire test). |
| Lean-season stores | food_storage .30 | food_drying and smoking (authored), plus acorns, solar drying, sealed pits (.04), cheese, salting and famine reserves |

**Early food matters.** Wild-food channels were nearly empty: food_output .03, foraging .02 and hunting 0 by year 100. They now reach food_output .17, foraging .17 and hunting .11 by year 100. That comes from fish weirs, drive hunts, milking, cheese, penned herds, edible-plant knowledge, acorns and honey. `FoodSystem` multiplies gathered plants, game and fish by `1 + foraging + food_output`, and game additionally by `1 + hunting_yield`.

## Effect totals (my three lines, full adoption, before clamping)

Each figure is the sum over items with `target_year ≤ Y`. The arrow reads "authored before Phase 2 → after".

| Sub-dimension | Key | Y100 | Y300 | Y600 | Cap |
|---|---|---|---|---|---|
| Daily supply | food_output | .03 → .17 | .03 → .23 | .03 → .37 | .80 |
| | foraging_yield | .02 → .17 | .02 → .17 | .02 → .17 | .65 |
| | hunting_yield | 0 → .11 | 0 → .11 | 0 → .11 | .65 |
| Land productivity | cultivation_yield | .35 → .39 | .57 → .71 | .59 → .84 | .90 |
| Stored reserve | food_storage | .38 → .56 | .48 → .81 | .68 → 1.28 | 1.20 |
| Diet quality | nutrition_quality | .21 → .33 | .39 → .51 | .45 → .56 | .45 |
| Water & sanitation | sanitation / water_safety | .00→.03 / .24 | .04→.10 / .41 | .29→.40 / .53 | .65 / .60 |
| Injury safety | injury_risk | −.17 → −.24 | −.28 → −.38 | −.34 → −.50 | −.45 |
| Disease control | disease_exposure | −.30 → −.34 | −.50 → −.53 | −.81 → −.87 | −.55 |
| General health | health_protection | .32 → .40 | .51 → .61 | .72 → .83 | .55 |
| Child survival | neonatal_survival | .31 → .37 | .49 → .58 | .53 → .70 | .65 |
| Maternal safety | maternal_safety | .40 → .40 | .57 → .59 | .63 → .70 | .65 |
| Fertility conditions | conception_support | .04 → .15 | .04 → .16 | .04 → .17 | .35 |
| Shelter capacity | housing_output | .12 → .16 | .20 → .36 | .23 → .46 | .90 |

Side channels added: labor_efficiency (.03 → .26 by 600), cohesion (.08 → .29), state_capacity (.11 → .28), knowledge_preservation (.16 → .33) and trade_capacity (0 → .13).

**Saturation (for Phase 3).** The authored era and catalog effects alone already reach the caps of health_protection, disease_exposure and nutrition_quality by year 300–400 at full adoption. The same applies to maternal and neonatal survival near year 600, and their clamp in `GameState` is .60. So after year ~300, Phase 2 sends new health and diet items mostly to channels that still have room: sanitation, injury, labor, knowledge, housing and fertility. In practice adoption is below 1, so the caps bind later. For life expectancy to keep rising through the centuries, Phase 3 should either scale down the early authored values (the era practices use about .02–.04 each, and there are many of them) or raise these caps.

Conception support is held in balance on purpose. Kinship, marriage and house-plot items add up to +.15 by year 100. Later spacing, nursing and pessary items take some of it back, trading births for survival.

## Items dated inside the window but not in the design (nutrition only)

None of the 28 undated items are health or demography.

| Item | Game era now | Proposal |
|---|---|---|
| `sealed_vessels` | gate 20 | **Adopt** at ≈50 as a precedent or alias of `hermetic_grain_storage`. `early_life_conditions.gd` counts it toward lean-season stores. |
| `salt_working` | gate 20 | **Adopt** at ≈150 as a foundation of `salting_fish_meat` (155). |
| `curing_regimens` | gate 20 | **Redate** to ≈170, after salting and smoking. |
| `grain_milling` (Rotary) | gate 41 | **Redate** beyond 600 (≈800), per the design. The saddle quern (32) covers the early step. |
| `mass_seed_selection` | gate 47 | **Redate** to ≈120, after seed reserves and crop calendars, or merge into `seed_selection`. |
| `germination_trials` | gate 41 | **Redate** beyond 600 (measured trials). |
| `habitat_observation_records` | gate 7 | **Redate** beyond 600 (written natural history). |
| `crop_residue_cover` | gate 270 | **Adopt** at ≈280, next to `field_rest_scheduling` (ecology shared). |
| `irrigation_loss_accounts` | gate 270 | **Adopt** at ≈420, after `irrigation_schedules` and written accounts. |

## Art proposals for NEW items (applied once the line-painting test allows it)

- **animal_taming:** milking, butter_churning, fattened_geese_ducks, stall_fattened_cattle, winter_herder_return, bride_wealth_gifts
- **wound_cleaning:** delousing, joint_reduction, wound_packing, trepanation, honey_wound_dressing, head_shaving_lice, traction_fracture_setting, linen_board_splints
- **herbal_classification:** snakebite, poultices, purges, poppy, bracket fungus, healer_titles, remedy_vehicles, willow_myrtle, pessaries
- **intensive_gardens:** cuttings, date offshoots, kitchen gardens, hives, flavouring herbs, date pollination, grafting
- **sealed_vessels:** resin wine, cheese, ghee, marked wine jars, date syrup, dried salted cheese, fly_protection
- **shared_childcare:** disability care, crutches, slings, orphan care, captive adoption, wet nurses, three-year nursing
- **household_councils:** exogamy, village marriages, newcomer host season, newcomer intermarriage, patron protection, levirate
- **property_registers:** dowry, inheritance, joint estates, divorce, frontier grants
- **customary_law:** mad dog liability, healer fees, belonging oaths, widow's portion
- **paper/seed_oil_pressing:** sesame, olive press, skin oiling, castor oil
- **paper/earth_oven_cooking:** dome ovens, work-gang bakeries, named breads
- **census_rolls / tallies:**
  - census_rolls: people and herd counts, vital lists, ward lists
  - tallies: mouths against the store, harvest headcount, hearth counts
- **Other matches:**
  - fish weirs → basketry
  - drive hunts → hafted_weapons
  - saddle quern → grain_milling
  - wild honey → smoking
  - salting and jarred fish → salt_working
  - fish ponds → river_craft
  - fodder barley → pack_animals
  - ard, winter fodder, carrying capacity → managed_fallow
  - famine reserves → regional_granaries
  - spoilage inspection, graded rations, refugees → public_stores
  - hamlets and kin wards, towns → urban_street_plans
  - daughter hamlets, house plots → paper/wattle_and_daub_walls
  - remedy tablets, injury manual, compendia → pictographic_records
  - named descent lines, healing chants → oral_epics

## Known limitations

- **Not measured in play.** No campaign playtest was run. The totals above assume full adoption.
- **Undated items unchanged.** The adopt/redate proposals are recommendations only; the build data is unchanged.
- **Woven dressings.** `woven_dressings` keeps empty effects. Its consequence is the physical dressing recipe.
