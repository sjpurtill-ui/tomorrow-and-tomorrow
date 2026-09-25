# Nutrition: years 2400–3000

**Scope.** The **Nutrition** research line (`nutrition` dynamic; `direction: "Sustenance"`) for game years 2400–3000, the end of the game. Its channels are Daily supply, Diet quality, Land productivity and Stored reserve. It covers farm machinery in the field, fertilizer science, experiment stations and extension, plant and animal breeding, canning, freezing and gentle heat treatment, milling and dairying, food purity law, diet science and vitamins, rationing, soil conservation, the green revolution, food safety systems, and the near-future frontier of engineered crops and cultured proteins. Fertilizer and ammonia plants, sulfuric acid, tinplate and sheet steel are Production's (`catalytic_ammonia_synthesis`, `iron_ammonia_catalysts`, `sulfuric_acid_production`, `tinplate_coating`, `sheet_steel_rolling`). Cold stores (`mechanical_refrigeration`) belong to Infrastructure, and rail and ship transport to Logistics. Botanical science (`biological_reference_collections`, `developmental_stage_series`, `soil_assays`) is Ecology's. Continues `docs/research/y1200/NUTRITION_1200_1800.md` and the 1800–2400 Nutrition list. New-world crops, the four-course rotation, the seed drill and enclosure are in the 1800–2400 window. Catalog ids placed here (36): every Sustenance-direction id and the agronomy, canning, grain-processing and food-batch ids whose year falls in the window, plus the belongs-later `fermentation_starter_cultures` and `roller_grain_milling`. Rows marked [gov: …] should be read together with the Institutions list in the civic-evolution pass.

**Historical anchor.** `scripts/technology_eras.gd` CURVE (read from `origin/codex/research-1200`) `[[2400,1800],[2800,1950],[3000,2030]]`: game 2400 ≈ AD 1800, 2500 ≈ 1838, 2600 ≈ 1875, 2700 ≈ 1912, 2800 = 1950, 2900 = 1990 and 3000 = 2030, the end of the game. Years 2400–2800 run at 0.375 historical years per game year (steam, railways, industrial chemistry, electricity and the world-scale industrial wars). Years 2800–3000 run at 0.4 (the antibiotic age to the near future). A game year is only four or five historical months, so bands are narrow: ±25 game years for ordinary rows and ±35 for key thresholds (about ±9 and ±13 historical years). Rows near the 2030 frontier are near-future practice; where they are not yet routine they are marked (speculative). None is science fiction. Names are generic alternative-history practices. Real people, companies, nations, wars and events are calibration only. (regional) items suit a climate or tradition and should be gated by terrain or culture.

**Research time.** Game years of staffed research on the item. Real time is for **1 day/s** (1 game year ≈ 6 min; 5 y ≈ 30 min; 10 y ≈ 61 min; 20 y ≈ 2 h). At 3 days/s, divide by 3.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd` or `technology_eras.gd` HISTORICAL_YEAR). Its year is its catalog year through CURVE unless the last table gives a correction. `NEW · slug` = not authored yet. No slug repeats an id in `docs/research/registry.json` (0–600), `y600/registry_1200.json` (600–1200), `y1200/registry_1800.json` (1200–1800), `scripts/*.gd` or HISTORICAL_YEAR; a script checks this. "(continues: id)" names the earlier item a row improves: an item from those registries, an earlier row of this file, or a row of a sister 2400–3000 line. `(shared: X)` straddles another line; `(culture)` feeds this line from Culture. `[gov: offices|court|law|seat|towns|culture]` marks rows that change government, civic life or the court.

**"Today" column.** Earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run; `—` for items not in main.

## Years 2400–2700 (≈ AD 1800–1912)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2411 (2386–2436) | Sparkling table waters bottled under pressure | 4 y | 24 min | NEW · carbonated_table_waters | — |
| 2424 (2399–2449) | Store humidity measured to judge when food will spoil (shared: knowledge) | 5 y | 30 min | humidity_measurement | not seen |
| **2427 (2392–2462)** | **Food sealed in jars and boiled: the first canned rations** | 12 y | 73 min | food_retorts | not seen |
| **2432 (2397–2467)** | **Beet sugar factories boil the pale field root in cold lands (continues: sugar_beet_selection)** | 12 y | 73 min | NEW · root_beet_sugar | — |
| 2440 (2415–2465) | Farm societies hold shows and prize ploughing matches (culture) | 5 y | 30 min | NEW · farm_improvement_societies | — |
| **2459 (2424–2494)** | **Printed herd books register pedigrees of cattle, sheep and horses (continues: pedigree_stock_breeding)** | 8 y | 49 min | NEW · pedigree_herd_books | — |
| 2467 (2442–2492) | Pressed bakers' yeast sold fresh from the distillery | 4 y | 24 min | NEW · pressed_bakers_yeast | — |
| 2475 (2450–2500) | Cocoa pressed and moulded into eating chocolate | 5 y | 30 min | NEW · cocoa_press_chocolate | — |
| 2480 (2455–2505) | Cheap glass jars and tin boxes for household preserving (continues: food_retorts) | 5 y | 30 min | NEW · household_preserving_jars | — |
| 2480 (2455–2505) | Vacuum pans boil sugar at low heat for whiter crystals (continues: root_beet_sugar) | 5 y | 30 min | NEW · vacuum_pan_sugar | — |
| 2485 (2460–2510) | Pressed oil-cake bought as winter feed for fattening stock | 4 y | 24 min | NEW · oilcake_winter_feed | — |
| 2488 (2463–2513) | Sheep dipped against scab and ticks | 4 y | 24 min | NEW · sheep_scab_dipping | — |
| **2491 (2456–2526)** | **Horse-drawn mechanical reaper (shared: production, labor)** | 10 y | 61 min | NEW · mechanical_reaper | — |
| 2499 (2474–2524) | Polished steel plough that scours prairie sod (continues: cast_iron_plough_parts) | 6 y | 37 min | NEW · steel_scouring_plough | — |
| **2507 (2472–2542)** | **Crop response to measured nitrogen, phosphorus and potash compared** | 12 y | 73 min | nutrient_response_trials | not seen |
| 2507 (2482–2532) | Mined nitrate spread on grain fields | 6 y | 37 min | mineral_nitrate_dressing | not seen |
| 2507 (2482–2532) | Mulch depth compared for water retention | 4 y | 24 min | mulch_water_management | not seen |
| 2507 (2482–2532) | Soil infiltration measured before choosing drainage or mulch (shared: ecology) | 5 y | 30 min | soil_infiltration_trials | not seen |
| 2509 (2484–2534) | Seabird dung shipped from far islands as fertilizer (regional) | 5 y | 30 min | NEW · seabird_guano_trade | — |
| 2512 (2487–2537) | Ground phosphate rock dressing (continues: crushed_bone_manure) | 5 y | 30 min | phosphate_dressing | 141 |
| **2515 (2480–2550)** | **Experimental farm station with long-term field plots (continues: agriculture_board_surveys) [gov: offices]** | 12 y | 73 min | NEW · experimental_farm_station | — |
| 2517 (2492–2542) | Acid-treated soluble phosphate factories (continues: phosphate_dressing) | 8 y | 49 min | phosphate_solubilization | not seen |
| 2520 (2495–2545) | Clay pipes machine-made for tile drainage of wet fields (continues: ridge_furrow_strips) | 8 y | 49 min | NEW · machine_tile_drainage | — |
| 2523 (2498–2548) | Relief works and state food imports in a blight famine (shared: demography) [gov: seat] | 8 y | 49 min | NEW · famine_relief_works | — |
| 2528 (2503–2553) | Glasshouses heated by hot-water pipes force winter crops | 5 y | 30 min | NEW · heated_glasshouses | — |
| 2533 (2508–2558) | Intensive market gardens on high ground rents | 6 y | 37 min | intensive_gardens | not seen |
| 2533 (2508–2558) | Steam threshing sets travel from farm to farm (continues: threshing_machine) | 6 y | 37 min | NEW · steam_threshing_sets | — |
| 2541 (2516–2566) | Microscope and chemistry expose adulterated bread, milk and tea (shared: health) | 6 y | 37 min | NEW · food_adulteration_tests | — |
| 2547 (2522–2572) | Grain sold by inspected grade from the elevator bins (continues: steam_grain_elevators) (shared: logistics) | 6 y | 37 min | NEW · graded_grain_elevators | — |
| 2549 (2524–2574) | Baking powder raises bread and cakes without yeast | 4 y | 24 min | NEW · chemical_baking_powder | — |
| 2549 (2524–2574) | Sweetened condensed milk in sealed tins | 6 y | 37 min | NEW · condensed_milk | — |
| 2552 (2527–2577) | Pure starter cultures of yeast and souring germs | 8 y | 49 min | fermentation_starter_cultures | ≈ 80 |
| **2560 (2525–2595)** | **Crop diseases traced to fungi and named by their signs** | 8 y | 49 min | plant_pathology_diagnosis | not seen |
| 2560 (2535–2585) | Tin cans cut, rolled and soldered by machine | 6 y | 37 min | can_body_forming | not seen |
| **2565 (2530–2600)** | **Chartered farm colleges and a ministry of agriculture [gov: offices]** | 10 y | 61 min | NEW · farm_colleges_ministry | — |
| **2571 (2536–2606)** | **Gentle heating kills spoiling germs in wine, beer and milk** | 10 y | 61 min | NEW · gentle_heat_treatment | — |
| 2573 (2548–2598) | Meat extract and stock cubes | 4 y | 24 min | NEW · meat_extract_cubes | — |
| 2584 (2559–2609) | Butter substitute churned from beef fat and milk | 5 y | 30 min | NEW · beef_fat_margarine | — |
| **2587 (2552–2622)** | **Steel roller mills grind white flour** | 10 y | 61 min | roller_grain_milling | not seen |
| 2592 (2567–2617) | Twine-binding harvesters (continues: mechanical_reaper) | 6 y | 37 min | NEW · twine_binding_harvester | — |
| **2600 (2565–2635)** | **Food adulteration law with public analysts (continues: food_adulteration_tests) [gov: law]** | 8 y | 49 min | NEW · food_adulteration_law | — |
| **2605 (2570–2640)** | **Frozen and chilled meat carried by ship from grazing lands (continues: mechanical_refrigeration) (shared: logistics)** | 8 y | 49 min | NEW · frozen_meat_trade | — |
| 2608 (2583–2633) | Spinning cream separator | 5 y | 30 min | NEW · cream_separator | — |
| 2613 (2588–2638) | Vines grafted onto pest-resistant roots (regional) (continues: vine_rootstock_grafting) | 6 y | 37 min | NEW · resistant_vine_rootstocks | — |
| 2619 (2594–2644) | Farmer-owned cooperative creameries and dairies [gov: towns] | 8 y | 49 min | NEW · cooperative_creameries | — |
| 2621 (2596–2646) | Chopped green fodder kept in pits and towers as silage | 5 y | 30 min | NEW · silage_towers | — |
| 2627 (2602–2652) | Copper-lime spray against mildew and blight (continues: plant_pathology_diagnosis) | 6 y | 37 min | NEW · copper_lime_spray | — |
| 2635 (2610–2660) | Double-seamed cans without solder | 6 y | 37 min | double_seaming | not seen |
| 2640 (2615–2665) | Bottled heat-treated town milk (continues: gentle_heat_treatment) | 6 y | 37 min | NEW · bottled_town_milk | — |
| 2640 (2615–2665) | Milk paid by butterfat test | 4 y | 24 min | NEW · butterfat_milk_test | — |
| **2651 (2616–2686)** | **Foods and diets measured in heat units; working rations costed** | 10 y | 61 min | NEW · dietary_heat_units | — |
| 2659 (2634–2684) | Polished-rice sickness cured by the husk: deficiency diseases found (regional) | 8 y | 49 min | NEW · deficiency_disease_discovery | — |
| 2667 (2642–2692) | Chilled tropical fruit shipped to cold-land markets (continues: frozen_meat_trade) (shared: logistics) | 5 y | 30 min | NEW · chilled_fruit_shipping | — |
| 2675 (2650–2700) | Pure lines selected from single plants | 6 y | 37 min | progeny_rows | 102 |
| 2680 (2655–2705) | Controlled pollination of chosen parents | 6 y | 37 min | controlled_pollination | 189 |
| 2680 (2655–2705) | Field variety trials under replicated plots | 6 y | 37 min | field_variety_trials | 200 |
| **2680 (2645–2715)** | **Heredity experiments fix traits across generations** | 12 y | 73 min | heredity_experiments | not seen |
| 2683 (2658–2708) | Regional seed trials recommend varieties by district | 6 y | 37 min | regional_seed_trials | 207 |
| 2683 (2658–2708) | School meals for poor children (shared: demography) [gov: towns] | 6 y | 37 min | NEW · school_meals | — |
| 2685 (2660–2710) | Resistance traits bred into crops against rust and wilt | 8 y | 49 min | plant_resistance_trait_trials | not seen |
| 2691 (2666–2716) | Food acidity measured for safe preserving | 5 y | 30 min | food_acidity_measurement | not seen |
| 2693 (2668–2718) | Milk ordinances: tested herds and licensed dairies (continues: bottled_town_milk) [gov: law] | 6 y | 37 min | NEW · clean_milk_ordinances | — |
| **2699 (2664–2734)** | **Accessory food factors named: the vitamins (continues: deficiency_disease_discovery)** | 12 y | 73 min | NEW · vitamin_factors | — |

## Years 2700–3000 (≈ AD 1912–2030)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2701 (2666–2736)** | **Ammonium sulfate fertilizer from synthetic ammonia (continues: mineral_nitrate_dressing)** | 8 y | 49 min | ammonium_sulfate_fertilizer | not seen |
| 2704 (2679–2729) | County farm advisers bring the station's results to every farmer (continues: experimental_farm_station) [gov: offices] | 8 y | 49 min | NEW · farm_extension_agents | — |
| **2712 (2677–2747)** | **Light petrol tractor replaces the plough team (shared: production)** | 12 y | 73 min | NEW · farm_tractor | — |
| **2712 (2677–2747)** | **Ration cards and a food ministry in industrial war (shared: institutions) [gov: offices]** | 8 y | 49 min | NEW · wartime_ration_cards | — |
| 2720 (2695–2745) | Grain dried with forced air | 5 y | 30 min | forced_air_grain_drying | not seen |
| 2720 (2695–2745) | Grain moisture tested before storage | 4 y | 24 min | grain_moisture_testing | not seen |
| 2720 (2695–2745) | Heat-process times validated for each can size | 6 y | 37 min | thermal_process_validation | not seen |
| 2725 (2700–2750) | Rickets cured by fish-liver oil and sunlight (shared: demography) | 5 y | 30 min | NEW · rickets_prevention | — |
| 2731 (2706–2756) | Iodized table salt (continues: iodine_goitre_treatment) (shared: health) | 5 y | 30 min | NEW · iodized_salt | — |
| **2736 (2701–2771)** | **Hybrid maize from crossed inbred lines (regional)** | 10 y | 61 min | NEW · hybrid_maize_seed | — |
| 2744 (2719–2769) | Quick-frozen packaged foods | 6 y | 37 min | NEW · quick_frozen_foods | — |
| 2747 (2722–2772) | Contour cultivation along the slope | 5 y | 30 min | contour_cultivation | 88 |
| 2747 (2722–2772) | Cover crop mixtures hold winter soil | 5 y | 30 min | cover_crop_mixtures | not seen |
| 2747 (2722–2772) | Strip cropping against wind and water erosion (shared: ecology) | 5 y | 30 min | strip_cropping | not seen |
| 2752 (2727–2777) | Electric household refrigerator (shared: production) | 6 y | 37 min | NEW · household_refrigerator | — |
| 2760 (2735–2785) | Soil conservation service with district demonstration farms and price supports (continues: contour_cultivation) (shared: ecology) [gov: offices] | 8 y | 49 min | NEW · soil_conservation_service | — |
| 2763 (2738–2788) | Rubber-tyred tractor with power take-off and hitch (continues: farm_tractor) | 6 y | 37 min | NEW · hitch_tractor | — |
| 2768 (2743–2793) | Self-propelled combine harvester (continues: twine_binding_harvester) | 8 y | 49 min | NEW · combine_harvester | — |
| 2776 (2751–2801) | Daily nutrient allowances and enriched flour (continues: vitamin_factors) [gov: law] | 8 y | 49 min | NEW · recommended_daily_allowances | — |
| 2781 (2756–2806) | Food-group guides for every household | 4 y | 24 min | NEW · food_group_guides | — |
| 2787 (2762–2812) | Synthetic contact insecticide dusted on crops (shared: ecology) | 6 y | 37 min | NEW · synthetic_crop_insecticide | — |
| 2789 (2764–2814) | Hormone weedkiller that spares grain crops | 6 y | 37 min | NEW · selective_hormone_herbicide | — |
| 2792 (2767–2817) | Frozen semen and artificial insemination of cattle | 6 y | 37 min | NEW · artificial_cattle_insemination | — |
| 2800 (2775–2825) | Confinement broiler houses and feed-mill rations | 6 y | 37 min | NEW · confinement_broiler_houses | — |
| 2800 (2775–2825) | Every food batch traceable from field to store | 6 y | 37 min | food_batch_traceability | not seen |
| 2800 (2775–2825) | Irrigation scheduled by soil moisture | 5 y | 30 min | soil_moisture_scheduling | not seen |
| 2800 (2775–2825) | Post-harvest losses measured and cut | 5 y | 30 min | postharvest_loss_measurement | not seen |
| 2808 (2783–2833) | Self-service food stores with cold cabinets (shared: logistics) | 5 y | 30 min | NEW · self_service_cold_stores | — |
| 2812 (2787–2837) | Centre-pivot sprinkler irrigation (shared: ecology) | 6 y | 37 min | NEW · centre_pivot_irrigation | — |
| **2822 (2787–2857)** | **Hazard analysis at each critical point of food processing** | 8 y | 49 min | food_process_hazard_analysis | not seen |
| 2822 (2797–2847) | Package barrier testing | 4 y | 24 min | food_package_barrier_testing | not seen |
| 2822 (2797–2847) | Package leak detection | 4 y | 24 min | food_package_leak_detection | not seen |
| 2822 (2797–2847) | Water activity measured to set shelf life | 4 y | 24 min | food_water_activity_measurement | not seen |
| 2832 (2807–2857) | Food standards agreed between realms [gov: court] | 6 y | 37 min | NEW · inter_realm_food_standards | — |
| 2838 (2813–2863) | Drip irrigation lines feed each plant (shared: ecology) | 6 y | 37 min | NEW · drip_irrigation | — |
| 2838 (2813–2863) | Reduced tillage leaves residue on the field | 5 y | 30 min | reduced_tillage | not seen |
| **2838 (2803–2873)** | **Semi-dwarf wheat and rice with fertilizer and water: the green revolution** | 15 y | 91 min | NEW · semi_dwarf_grain_package | — |
| 2842 (2817–2867) | Charity food banks collect surplus food (culture) | 4 y | 24 min | NEW · food_banks | — |
| 2842 (2817–2867) | Countertop microwave oven | 4 y | 24 min | NEW · microwave_oven | — |
| 2845 (2820–2870) | Sterile cartons keep heat-treated milk without cold (continues: bottled_town_milk) | 5 y | 30 min | NEW · aseptic_carton_milk | — |
| 2855 (2830–2880) | Cheap sweet syrup made from maize starch | 5 y | 30 min | NEW · starch_sugar_syrup | — |
| 2855 (2830–2880) | Integrated pest management with scouting and thresholds (shared: ecology) | 6 y | 37 min | NEW · integrated_pest_management | — |
| 2862 (2837–2887) | Net-pen fish farming with pellet feed (shared: ecology) | 6 y | 37 min | NEW · net_pen_aquaculture | — |
| 2868 (2843–2893) | National dietary goals against fat, salt and sugar [gov: law] | 5 y | 30 min | NEW · national_dietary_goals | — |
| 2875 (2850–2900) | Soil-less crops fed in glasshouse channels | 5 y | 30 min | NEW · hydroponic_glasshouses | — |
| 2888 (2863–2913) | Famine early-warning from rainfall, prices and satellite images [gov: offices] | 6 y | 37 min | NEW · famine_early_warning | — |
| 2900 (2875–2925) | Nutrition labels on packaged foods [gov: law] | 4 y | 24 min | NEW · nutrition_labels | — |
| **2915 (2880–2950)** | **Crops carrying a transferred gene for pest or herbicide resistance** | 12 y | 73 min | NEW · transgenic_crops | — |
| 2915 (2890–2940) | Ready-to-use peanut paste treats starving children at home (shared: demography, health) | 6 y | 37 min | NEW · therapeutic_ready_food | — |
| 2920 (2895–2945) | Folic acid added to flour (shared: demography) | 4 y | 24 min | NEW · folic_acid_fortification | — |
| 2932 (2907–2957) | Satellite-guided precision planting and variable-rate spreading | 8 y | 49 min | NEW · precision_agriculture | — |
| 2938 (2913–2963) | Marker-assisted breeding reads the seed's genes | 6 y | 37 min | NEW · marker_assisted_breeding | — |
| 2945 (2920–2970) | Vitamin-rich staple varieties for poor diets | 6 y | 37 min | NEW · biofortified_staples | — |
| 2950 (2925–2975) | Drought- and flood-tolerant grain varieties (continues: plant_resistance_trait_trials) | 6 y | 37 min | NEW · stress_tolerant_varieties | — |
| 2965 (2940–2990) | Taxes on sugared drinks [gov: law] | 4 y | 24 min | NEW · sugar_drink_taxes | — |
| **2970 (2935–3000)** | **Gene-edited crops without foreign genes (continues: transgenic_crops)** | 10 y | 61 min | NEW · gene_edited_crops | — |
| 2975 (2950–3000) | Milk and egg proteins made by fermenting microbes | 8 y | 49 min | NEW · precision_fermented_proteins | — |
| 2982 (2957–3000) | Meat grown from animal cells in tanks | 10 y | 61 min | NEW · cultivated_cell_meat | — |
| 2988 (2963–3000) | Microbial seed coatings fix nitrogen for grain | 6 y | 37 min | NEW · nitrogen_fixing_seed_microbes | — |
| 2992 (2967–3000) | Stacked indoor farms under electric light (speculative) | 6 y | 37 min | NEW · vertical_indoor_farms | — |
| **3000 (2965–3000)** | **Climate-shift crop maps move varieties and sowing dates by district (speculative) (shared: ecology)** | 8 y | 49 min | NEW · climate_shift_crop_planning | — |

## Pacing

| Years | 2400–2450 | 2450–2500 | 2500–2550 | 2550–2600 | 2600–2650 | 2650–2700 | 2700–2750 | 2750–2800 | 2800–2850 | 2850–2900 | 2900–2950 | 2950–3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Nutrition advances | 5 | 9 | 17 | 9 | 10 | 13 | 14 | 9 | 17 | 6 | 7 | 8 |

The total is **124** advances: 63 in years 2400–2700 and 61 in 2700–3000, one about every 4.8 game years. 36 are catalog ids. With four channels, each channel always has current work. Measurements and single practices take 4–6 years (24–37 min). Machines, laws and breeding programs take 6–10 years. The 24 key thresholds take 8–15 years (49–91 min). The first century is canning, beet sugar factories, herd books and the reaper. Around 2500 comes the chemistry of the soil: nitrate, phosphate, experiment stations and tile drainage. The next century is gentle heat treatment, roller flour, frozen meat, cooperative dairies, food purity law and diet measured in heat units. The 2700s bring vitamins, synthetic nitrogen, tractors, hybrid seed and wartime rationing. After 2800 come food safety systems and the green revolution, then precision and gene-edited crops, with cultured proteins and climate-shift planning at the frontier.

**Key thresholds:**
1. **Preserving:** `food_retorts` (2427) → household jars (2480) → condensed milk (2549) → `can_body_forming` (2560) → gentle heat treatment (2571) → frozen meat trade (2605) → `double_seaming` (2635) → bottled town milk (2640) → `thermal_process_validation` (2720) → quick-frozen foods (2744) → household refrigerator (2752) → `food_process_hazard_analysis` (2822) → aseptic cartons (2845).
2. **Soil fertility:** 1800–2400's `crushed_bone_manure` (2364) → `nutrient_response_trials` and `mineral_nitrate_dressing` (2507) → guano (2509) → `phosphate_dressing` (2512) → experimental farm station (2515) → `phosphate_solubilization` (2517) → `ammonium_sulfate_fertilizer` (2701) → green-revolution package (2838) → precision agriculture (2932) → nitrogen-fixing seed microbes (2988). Synthetic ammonia itself is Production's `catalytic_ammonia_synthesis`.
3. **Machines in the field (shared: production, labor):** 1800–2400's `cast_iron_plough_parts` (2376) and `threshing_machine` (2372) → reaper (2491) → steel plough (2499) → steam threshing (2533) → twine binder (2592) → tractor (2712) → hitch tractor (2763) → combine (2768) → centre pivot (2812).
4. **Breeding:** pedigree herd books (2459) → `progeny_rows` (2675) → `heredity_experiments` and `controlled_pollination` (2680) → `plant_resistance_trait_trials` (2685) → hybrid maize (2736) → artificial insemination (2792) → semi-dwarf grain (2838) → transgenic crops (2915) → marker-assisted breeding (2938) → gene-edited crops (2970).
5. **Diet science and public food:** 1800–2400's `public_soup_kitchens` (2381) → famine relief works (2523) → adulteration tests and law (2541–2600) → heat units (2651) → deficiency diseases (2659) → school meals (2683) → vitamins (2699) → ration cards (2712) → iodized salt (2731) → daily allowances (2776) → dietary goals (2868) → nutrition labels (2900) → therapeutic ready food (2915) → sugar-drink taxes (2965).
6. **Soil and water keeping (shared: ecology):** `soil_infiltration_trials` and `mulch_water_management` (2507) → tile drainage (2520) → `contour_cultivation`, `strip_cropping` and `cover_crop_mixtures` (2747) → soil conservation service (2760) → `soil_moisture_scheduling` (2800) → `reduced_tillage` (2838) → drip irrigation (2838) → climate-shift crop planning (3000, speculative).
7. **Ownership of overlaps:** Production owns the chemical plants, ammonia synthesis, sulfuric acid, tinplate and sheet steel. Infrastructure owns `mechanical_refrigeration` and cold stores. Logistics owns `steam_grain_elevators` (2512) and `refrigerated_rail_cars` (2613); the frozen meat trade by sea, grain grading and chilled fruit are kept here and shared. Ecology owns field botany, `soil_assays` (2507), pesticide side effects and fish stocks; integrated pest management, the synthetic insecticide and net-pen farming are shared. Health keeps iodine for goitre, malaria spraying and drug purity; Nutrition keeps iodized salt, clean milk and food purity. Demography keeps infant food; school meals, rickets, folic acid and therapeutic food are shared with it.

## Government and civic life

These should visibly change government and civic life in the civic-evolution pass:
- **famine_relief_works (2523)**: dearth relief moves from the town soup kitchen to the seat of rule. The court orders food imports and relief works, and its failures cost legitimacy.
- **experimental_farm_station (2515)**, **farm_colleges_ministry (2565)** and **farm_extension_agents (2704)**: a ministry of agriculture joins the court composition, with a station director and an adviser in every district.
- **food_adulteration_law (2600)** and **clean_milk_ordinances (2693)**: public analysts and dairy inspectors become town officers, replacing the ale-taster and bread warden.
- **cooperative_creameries (2619)**: farmer-owned cooperatives with elected boards become a civic body in the villages.
- **school_meals (2683)**, **wartime_ration_cards (2712)** and **recommended_daily_allowances (2776)**: a food ministry issues ration books in war. In peacetime its nutrition standards drive school meals and enriched flour.
- **soil_conservation_service (2760)**, **inter_realm_food_standards (2832)** and **famine_early_warning (2888)**: standing agencies for soil, price support and famine warning appear. Envoys agree food standards between realms.
- **national_dietary_goals (2868)**, **nutrition_labels (2900)** and **sugar_drink_taxes (2965)**: diet becomes a subject of public law and taxation.

## Currently far too early / too late (nutrition line, main)

| Item | Seen | Belongs |
|---|---|---|
| row_spacing_trials (catalog 1800 ≈ 2400) | 57 | Placed by the 1800–2400 Nutrition list at 2232. It is not relisted. |
| phosphate_dressing (catalog 1842 ≈ 2512) | 141 | 2512 |
| phosphate_solubilization (catalog 1900 ≈ 2667) | not seen | 2512. Acid-treated phosphate is ≈ AD 1843, so the catalog year is ≈ 150 game years late. Its gate `sulfuric_acid_production` (catalog 1900) is Production's and is also late for the lead-chamber process. |
| progeny_rows / controlled_pollination / field_variety_trials / regional_seed_trials (catalog 1905 ≈ 2680) | 102 / 189 / 200 / 207 | 2677–2683 |
| contour_cultivation (catalog 1930 ≈ 2747) | 88 | 2747 |
| fermentation_starter_cultures (catalog 1857) | ≈ 80 | 2552. Grain mould starters (1252) are the pre-scientific form. |
| roller_grain_milling (catalog 1870) | not seen | 2587. The earlier registries gave ≈ 2640 from an older curve. |
| humidity_measurement (catalog 1809) | not seen | 2424 (store humidity; shared with Knowledge's instruments) |
| seedbed_firming / sowing_depth_trials (catalog 1747 ≈ 2259) | not placed | 1800–2400 window. They are not placed here. |
| mechanical_refrigeration (catalog 1851 ≈ 2536) | 232 | Infrastructure (catalog direction). The frozen meat trade (2604) continues it. |

