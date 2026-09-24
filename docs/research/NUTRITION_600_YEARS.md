# Nutrition: the first 600 years

**Scope.** The game's **Nutrition** research line is the `nutrition` dynamic; in main it is every `direction: "Sustenance"` entry (DiscoverySystem maps Sustenance to nutrition). On `codex/era-research-pacing` it has four channels: Daily supply, Diet quality, Land productivity and Stored reserve. The line covers foraging, hunting and fishing, fire and cooking, food processing, drying, smoking, salting and fermentation, storage, the domestication of plants and herd animals, and diet. It draws on `discovery_system.gd`, `fire_knowledge.gd`, `selected_food_knowledge.gd`, `food_preparation.gd`, `food_batch_knowledge.gd`, `grain_processing.gd`, `food_water_knowledge.gd` and the Sustenance rows of `society_knowledge_catalog.gd`. Main has about 92 Sustenance entries, and about 40 of them belong before year 600. The rest (canning, roller mills, fertilizer chemistry, heredity trials, most of `agronomy_knowledge.gd` and `field_botany_knowledge.gd`) belong centuries later. Tools and crafts belong to Production, water works to Infrastructure, and land and soil management to Ecology. Where the catalog tags a land practice as nutrition, it stays here and is marked shared.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic to the first towns). Years 300–600 correspond to roughly 3000–1500 BC (early Bronze Age: temple and palace stores, written law, the first medical texts). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`). Practices that the historical record places before 5000 BC are listed in the first few decades with short research times, because a young society still has to work them out.

**Research time.** Time is given in game years while a staffed Nutrition team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet. `(shared: X)` marks an item that straddles another vertical; it is listed here because its main effect is food supply or diet. `(culture)` marks a culture-line entry that feeds this line.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`), or `≈` for an estimate from the prerequisite graph. It is `—` when the item is not in main.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–7) | Edible plants, roots and seeds known by season | 1.5 y | 9 min | edible_resource_recognition | ≈3 |
| 3 (0–8) | Ember tending: carrying and banking fire | 1.5 y | 9 min | ember_tending | ≈3 |
| 4 (1–9) | Hearth heat held with stones and banked ash | 1.5 y | 9 min | hearth_heat_retention | ≈4 |
| 5 (2–10) | Pounding food in stone mortars | 1.5 y | 9 min | food_pounding_mortars | ≈5 |
| 5 (2–10) | Cracking and shelling nuts | 1.5 y | 9 min | nut_kernel_shelling | ≈5 |
| 6 (3–11) | Sun and wind drying of fish, meat and fruit | 2 y | 12 min | food_drying | 7 |
| 7 (4–12) | Sowing kept seed from the best plants | 2 y | 12 min | seed_selection | 6 |
| 8 (5–13) | Fire by drilling wood | 2 y | 12 min | friction_fire_ignition | ≈8 |
| 8 (5–13) | Hearth roasting on coals, spits and hot stones | 2 y | 12 min | hearth_roasting_control | ≈8 |
| 9 (6–14) | Seasonal protein: fish runs, fowl moults, calving | 2 y | 12 min | seasonal_protein_sourcing (era) | — |
| 10 (5–20) | Fire by striking stone | 2 y | 12 min | percussion_fire_ignition | ≈10 |
| 10 (5–20) | Varied forage rounds through the year | 2 y | 12 min | varied_forage_rotation (era) | — |
| 11 (6–21) | Smoke-curing fish and meat | 2.5 y | 15 min | smoking | 11 |
| 12 (7–22) | Grating and squeezing starchy roots | 2 y | 12 min | root_grating_dewatering | ≈6 |
| 13 (8–23) | Pest-repelling herbs laid in stores | 2 y | 12 min | pest_deterrent_storage_herbs (era) | — |
| 15 (10–25) | Screening fruit pulp from skins and stones | 2 y | 12 min | fruit_pulp_screening | ≈6 |
| 16 (11–26) | Penned herds: sheep, goats, cattle, pigs (shared: ecology) | 3 y | 18 min | animal_taming | 22 |
| 17 (12–27) | Tired ground noticed: yields fall on one plot (shared: ecology) | 2 y | 12 min | soil_exhaustion_recognition (era) | — |
| 18 (8–28) | Remembered yields for each plot | 2 y | 12 min | plot_yield_memory (era) | — |
| 19 (9–29) | Leaching bitterness from acorns | 3 y | 18 min | acorn_leaching | ≈8 |
| 20 (10–30) | Splitting pulses: lentil, pea, chickpea | 2 y | 12 min | pulse_splitting | ≈8 |
| 22 (12–32) | Earth-oven cooking in pits | 3 y | 18 min | earth_oven_cooking | ≈15 |
| 23 (13–33) | Fish weirs, basket traps and sinker nets for fish and fowl | 3 y | 18 min | NEW · fish_weirs_and_traps | — |
| 24 (14–34) | Grain dried and turned against damp | 2 y | 12 min | grain_moisture_watch (era) | — |
| **25 (15–35)** | **Milking goats, sheep and cows** | 3 y | 18 min | NEW · milking | — |
| 26 (16–41) | Shaded drying racks | 2 y | 12 min | indirect_solar_food_drying | ≈10 |
| 27 (17–42) | Crop calendar for sowing and harvest (shared: ecology) | 3 y | 18 min | crop_calendars | 17 |
| 28 (18–43) | Threshing on beaten floors | 3 y | 18 min | threshing_frames | ≈25 |
| 30 (20–45) | Winnowing chaff in the wind | 2 y | 12 min | winnowing_practice | ≈30 |
| 32 (22–47) | Grinding grain on saddle querns | 3 y | 18 min | NEW · saddle_quern_grinding | — |
| 34 (24–49) | Hulling emmer and barley in mortars | 2 y | 12 min | cereal_dehulling | ≈75 |
| 35 (25–50) | Kneading dough by hand | 2 y | 12 min | hand_dough_forming | ≈72 |
| 36 (26–51) | Soured milk kept as a thick curd | 2 y | 12 min | deliberate_milk_souring (era) | — |
| 40 (25–55) | Steaming food over boiling pots | 3 y | 18 min | food_steaming_vessels | ≈15 |
| 42 (27–62) | Flatbread baked on hot stones and griddles | 3 y | 18 min | controlled_baking | ≈80 |
| 46 (31–66) | Seed cleaning with sieves and hand sorting | 3 y | 18 min | seed_cleaning | 77 |
| 48 (33–68) | Drive hunts with fences, funnels and pits | 4 y | 24 min | NEW · drive_hunts | — |
| 52 (37–72) | Seed stock kept apart from eating grain | 4 y | 24 min | seed_reserves | 79 |
| 55 (40–75) | Grain sealed in pots and plastered pits | 5 y | 30 min | hermetic_grain_storage | 91 |
| 58 (38–78) | Honey taken from wild hives with smoke | 2 y | 12 min | NEW · wild_honey_smoking | — |
| 60 (40–85) | Sprouted, dried grain (malt) | 4 y | 24 min | grain_malting | ≈50 |
| 62 (42–87) | Washing starch from pounded roots and grain | 3 y | 18 min | starch_washing_separation | ≈20 |
| 65 (45–90) | Wine from grapes kept in resin-sealed jars | 5 y | 30 min | NEW · resin_sealed_wine | — |
| **70 (50–95)** | **Cheese from curd pressed in pierced strainers** | 5 y | 30 min | NEW · pressed_cheese | — |
| 72 (52–97) | Resting a field for a season (shared: ecology) | 4 y | 24 min | managed_fallow | 26 |
| 75 (55–105) | Harvest batches marked by season | 3 y | 18 min | batch_labeling_by_harvest (era) | — |
| 80 (55–110) | Root cellars | 4 y | 24 min | root_cellars | 40 |
| 85 (60–115) | Raised granaries on posts (shared: infrastructure) | 5 y | 30 min | raised_granaries | 60 |
| 90 (65–120) | Leafy greens gathered and grown for the pot | 2 y | 12 min | leafy_green_incorporation (era) | — |
| 95 (70–130) | Planting from cuttings: fig, olive and vine | 6 y | 37 min | NEW · cutting_propagation | — |
| 100 (70–135) | Grain eaten with pulses | 3 y | 18 min | mixed_grain_legume_meals (era) | — |
| 104 (74–139) | Manure from penned stock spread on fields (shared: ecology) | 4 y | 24 min | manure_field_spreading (era) | — |
| 106 (76–141) | Reserve order: seed first, then children | 3 y | 18 min | reserve_allocation_priority (era) | — |
| 110 (80–150) | Sifting flour through reed and cloth sieves | 3 y | 18 min | flour_sifting | ≈75 |
| 112 (82–152) | Date palms planted from offshoots | 5 y | 30 min | NEW · offshoot_date_planting | — |
| **116 (86–156)** | **Fermenting grain and fruit in vessels** | 8 y | 49 min | fermentation_control | 74 |
| 120 (85–160) | Staggered meal times | 2 y | 12 min | staggered_meal_timing (era) | — |
| 122 (87–162) | Ash spread on fields (shared: ecology) | 3 y | 18 min | ash_field_amendment (era) | — |
| 126 (91–166) | Irrigation turns between households (shared: infrastructure) | 6 y | 37 min | irrigation_schedules | 40 |
| 135 (100–175) | Varied meals from the common pot | 3 y | 18 min | communal_meal_variety_rules (era) | — |
| **145 (105–185)** | **Ox teams yoked to the ard (shared: production)** | 8 y | 49 min | NEW · ox_drawn_ard | — |
| 150 (110–190) | Stores layered against damp | 3 y | 18 min | reserve_moisture_barrier_layering (era) | — |
| 155 (115–195) | Salting fish and meat | 4 y | 24 min | NEW · salting_fish_meat | — |
| 158 (118–198) | Planting density matched to ground | 3 y | 18 min | planting_density_adjustment (era) | — |
| 172 (132–212) | Butter churned from milk | 4 y | 24 min | NEW · butter_churning | — |
| 180 (140–220) | Winter fodder cut and stored for stock | 5 y | 30 min | NEW · winter_fodder | — |
| 195 (155–235) | Paired crops in one field | 4 y | 24 min | intercrop_pairing_lore (era) | — |
| 200 (160–240) | Clay dome ovens for bread | 6 y | 37 min | NEW · clay_dome_ovens | — |
| 208 (168–248) | Portions allotted by household | 3 y | 18 min | portion_allotment_customs (era) | — |
| 212 (172–252) | Rules for drawing on the shared reserve | 3 y | 18 min | shared_reserve_access_rules (era) | — |
| **220 (180–260)** | **Barley beer brewed from malt and bread** | 8 y | 49 min | NEW · barley_beer | — |
| 224 (184–264) | Standard ration bowls for workers (shared: institutions) | 6 y | 37 min | NEW · fixed_worker_rations (dup) | — |
| 226 (186–266) | Seasonal diet planned against lean months | 4 y | 24 min | seasonal_diet_diversification (era) | — |
| 228 (188–268) | Layered storage pits | 4 y | 24 min | layered_pit_storage (era) | — |
| 232 (192–272) | Field-rest schedule (shared: ecology) | 5 y | 30 min | field_rest_scheduling (era) | — |
| 245 (205–285) | Dried-fruit cakes: figs, dates and raisins | 3 y | 18 min | NEW · dried_fruit_cakes | — |
| 260 (220–300) | Kitchen gardens: onion, garlic, leek, lettuce | 5 y | 30 min | NEW · kitchen_gardens | — |
| 290 (250–330) | Parboiling grain before drying | 4 y | 24 min | grain_parboiling | ≈75 |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 305 (265–345) | Stores rotated by date, oldest used first | 4 y | 24 min | stock_rotation | 34 |
| 315 (275–355) | Vegetables and fish fermented in brine | 6 y | 37 min | brine_fermentation | 76 |
| 325 (285–365) | Store keepers inspect jars and cull spoilage | 4 y | 24 min | NEW · spoilage_inspection | — |
| **335 (295–375)** | **Inspected regional granaries (shared: institutions)** | 12 y | 73 min | regional_granaries | 113 |
| 345 (305–385) | Ghee: butter clarified for keeping | 4 y | 24 min | NEW · ghee | — |
| 355 (315–395) | Legumes interplanted in grain fields (shared: ecology) | 6 y | 37 min | legume_field_interplanting (era) | — |
| 360 (320–400) | Reserve rotation ledgers | 5 y | 30 min | reserve_rotation_ledgers (era) | — |
| 365 (325–405) | Soft weaning foods customary | 3 y | 18 min | weaning_food_customs (era) | — |
| 375 (335–415) | Named beers by grain and strength | 6 y | 37 min | NEW · named_beers | — |
| 385 (345–425) | Wine jars sealed and marked by estate and year | 5 y | 30 min | NEW · marked_wine_jars | — |
| 395 (355–435) | Geese and ducks penned and fattened on grain | 6 y | 37 min | NEW · fattened_geese_ducks | — |
| 400 (360–440) | Bakeries and breweries feeding work gangs (shared: labor) | 8 y | 49 min | NEW · work_gang_bakeries | — |
| **405 (365–445)** | **Fish ponds stocked from the river** | 8 y | 49 min | NEW · stocked_fish_ponds | — |
| **415 (375–455)** | **Bees kept in clay and reed hives** | 10 y | 61 min | NEW · hive_beekeeping | — |
| 425 (385–465) | Sesame grown for oil | 6 y | 37 min | NEW · sesame_oil | — |
| 430 (390–470) | Stall-fattened cattle for feasts | 5 y | 30 min | NEW · stall_fattened_cattle | — |
| 438 (398–478) | Salted fish packed in jars for exchange | 5 y | 30 min | NEW · jarred_salt_fish | — |
| 445 (405–485) | Fodder barley grown for draught oxen and asses | 6 y | 37 min | NEW · fodder_barley | — |
| **465 (425–505)** | **Rations scaled by age, sex and work (shared: institutions)** | 8 y | 49 min | NEW · graded_rations | — |
| 475 (435–515) | Beam-and-weight olive press (shared: production) | 10 y | 61 min | NEW · beam_olive_press | — |
| 485 (445–525) | Flavouring herbs grown: coriander, cumin, mustard | 5 y | 30 min | NEW · flavouring_herbs | — |
| 495 (455–535) | Many named breads, sweetened with dates and honey | 6 y | 37 min | NEW · named_breads | — |
| 505 (465–545) | Vinegar from soured wine and beer; pickling | 8 y | 49 min | vinegar_pickling | 79 |
| 515 (475–555) | Hand-pollinating date palms | 8 y | 49 min | NEW · date_palm_pollination | — |
| 525 (485–565) | Date syrup and honey preserves | 5 y | 30 min | NEW · date_syrup_preserves | — |
| **540 (500–580)** | **Famine reserve held across two harvests (shared: institutions)** | 12 y | 73 min | NEW · famine_reserves | — |
| 560 (520–600) | Salted, dried cheeses kept for months | 5 y | 30 min | NEW · dried_salted_cheese | — |
| 572 (532–612) | Separate grain lines kept for bread and for beer | 6 y | 37 min | NEW · separate_grain_lines | — |
| **585 (545–625)** | **Grafting fruit trees (regional)** | 12 y | 73 min | NEW · fruit_tree_grafting | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Nutrition advances | 37 | 13 | 11 | 6 | 9 | 2 | 5 | 6 | 7 | 4 | 4 | 3 |

The total is **107** advances: 78 in the first 300 years and 29 in the next 300. The first 50 years are dense because fire, foraging, drying, smoking, first sowing and penned herds are older than 5000 BC. Each one is a short 1.5–3-year step, so the line is never idle. After year 100, steps lengthen to 4–12 years (fermentation, the ard, beer, granaries, hives, famine reserves), so the count per window falls while each step matters more. With four channels in parallel, some Nutrition research is always under way.

**Key thresholds:**
1. **Herds and milk:** penned herds (16) → milking (25) → soured milk (36) → cheese (70) → butter (172) → ghee (345) → stall-fattened cattle (430).
2. **Grain to bread and beer:** kept seed (7) → threshing and winnowing (28–30) → saddle querns (32) → flatbread (42) → malt (60) → fermentation (116) → dome ovens (200) → barley beer (220) → named breads (495).
3. **Keeping food:** drying and smoking (6–11) → sealed pits (55) → root cellars and raised granaries (80–85) → salting (155) → brine (315) → regional granaries (335) → vinegar (505) → famine reserve (540).
4. **Orchards and gardens:** cuttings (95) → date offshoots (112) → kitchen gardens (260) → sesame (425) → olive press (475) → date hand-pollination (515) → grafting (585).
5. **Sharing food:** portions (208) → ration bowls (224) → work-gang bakeries (400) → rations by age and work (465).

## Currently too early (nutrition line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs, or estimated from the graph where marked ≈.

| Item | Seen | Belongs |
|---|---|---|
| grain_milling (named *Rotary* Grain Milling) | 70 | Rotary quern beyond 600 (≈ 800). Saddle-quern grinding (NEW) belongs at 32 |
| fermentation_starter_cultures (needs only fermentation_control) | ≈80 | Beyond 600 (≈ 2550) |
| row_spacing_trials (agronomy) | 57 | Beyond 600 (≈ 2400) |
| contour_cultivation (agronomy) | 88 | Beyond 600 (≈ 2750) |
| progeny_rows / controlled_pollination / field_variety_trials (agronomy) | 102 / 189 / 200 | Beyond 600 (≈ 2680) |
| sowing_depth_trials / seedbed_firming (agronomy) | 173 / 214 | Beyond 600 (≈ 2290) |
| stock_rotation | 34 | 305 |
| brine_fermentation | 76 | 315 |
| vinegar_pickling | 79 | 505 |
| regional_granaries | 113 | 335 |

Outside Nutrition, the same pattern appears: `child_growth_records` (demography) is seen at 102 but belongs at ≈ 2670, and `work_rest_limits` (labor) is seen at 28 but belongs at ≈ 2670.
