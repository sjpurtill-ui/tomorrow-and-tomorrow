# Nutrition dependencies: years 2400–3000

Generated from `docs/research/y2400/deps/partials/nhde.json`. It uses ids from `registry_3000.json`, the 1800–2400 registry (`docs/research/y1800/registry_2400.json`, with the dependencies in `docs/research/y1800/deps/partials/`, since `graph_2400.json` is not yet merged), the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph and block, the 0–600 graph and block only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 2400–3000 id owned by Logistics, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1800-2400]` is a same-line 1800–2400 id. `requires_all` are hard prerequisites; a `requires_any` group needs one member; precedents are soft influences. Every parent is dated at or before its dependent, after the year moves in `partials/nhde_year_adjustments.json`, and no edge links two 2400–3000 items of the same year. The Year column shows the adjusted year. `environment` lists mean any one listed environment satisfies the gate. `contact_required` marks items that inherit the ocean-contact gate from a contact-gated parent (new-world crops, cinchona).

**124 entries, 227 hard edges, 240 precedent edges, 4 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2411 | carbonated_table_waters | isolated_airs_chemistry [knowledge, 1800-2400], dark_bottle_glass [production, 1800-2400] |  | bottle_sparkling_wine [1800-2400], pressure_vessels [production, 1800-2400] |  |
| 2427 (was 2424) | humidity_measurement | precision_thermometry [knowledge, 1800-2400], measurement_uncertainty [knowledge] |  | grain_bellows_ventilation [1800-2400], estate_ice_houses [1800-2400] |  |
| 2427 | food_retorts | pressure_vessels [production, 1800-2400], precision_thermometry [knowledge, 1800-2400] |  | voyage_keeping_foods [1800-2400], sealed_vessels [0-600] |  |
| 2432 | root_beet_sugar | sugar_beet_selection [1800-2400], sugar_loaf_refining [production, 1800-2400] |  | beet_sugar_discovery [1800-2400], high_pressure_steam_engines [production] |  |
| 2440 | farm_improvement_societies | agricultural_improvement_societies [1800-2400] |  | printed_farm_journals [1800-2400], agriculture_board_surveys [1800-2400] |  |
| 2459 | pedigree_herd_books | pedigree_stock_breeding [1800-2400], printed_farm_journals [1800-2400] |  | farm_improvement_societies, stall_winter_fattening [1800-2400] |  |
| 2467 | pressed_bakers_yeast | brewers_yeast_bread [1800-2400], juniper_grain_spirit [1800-2400] |  | porter_vat_brewing [1800-2400] |  |
| 2475 | cocoa_press_chocolate | court_chocolate_drink [1800-2400], root_beet_sugar |  | sugar_confectionery [1200-1800], seed_oil_pressing [production, 0-600] | contact_required: True |
| 2480 | household_preserving_jars | food_retorts, plunger_pressed_glass [production] |  | rolled_tinplate [production, 1800-2400], honey_fruit_preserves [600-1200] |  |
| 2480 | vacuum_pan_sugar | root_beet_sugar, vacuum_experiments [knowledge, 1800-2400] |  | steam_suction_pump [production, 1800-2400], high_pressure_steam_engines [production] |  |
| 2485 | oilcake_winter_feed | seed_oil_pressing [production, 0-600], stall_winter_fattening [1800-2400] |  | field_turnips [1800-2400], bean_cake_fertilizer [1800-2400] |  |
| 2488 | sheep_scab_dipping | veterinary_schools [ecology, 1800-2400] |  | cattle_health_passes [ecology, 1800-2400], pedigree_herd_books, mineral_acid_distillation [knowledge, 1200-1800] |  |
| 2491 | mechanical_reaper | cast_iron_plough_parts [1800-2400], fodder_cutting_machines [1800-2400] |  | threshing_machine [1800-2400], interchangeable_component_fits [production], draft_horse_breeding [logistics, 1800-2400] |  |
| 2499 | steel_scouring_plough | cast_iron_plough_parts [1800-2400], steel_refining [production, 1800-2400] |  | light_swing_plough [1800-2400], mechanical_reaper |  |
| 2507 | nutrient_response_trials | soil_assays [ecology], experimental_controls [knowledge, 1800-2400] |  | crushed_bone_manure [1800-2400], agriculture_board_surveys [1800-2400], atomic_combining_weights [knowledge] |  |
| 2507 | soil_infiltration_trials | soil_assays [ecology], standard_measures [knowledge, 0-600] |  | covered_field_drains [ecology, 1800-2400] |  |
| 2509 | seabird_guano_trade | nutrient_response_trials, company_merchant_fleets [logistics, 1800-2400] |  | seabird_colony_shares [ecology, 1200-1800], crushed_bone_manure [1800-2400] | environment: coast |
| 2511 (was 2507) | mineral_nitrate_dressing | nitrate_cultivation [ecology, 1200-1800], nutrient_response_trials |  | state_nitre_plantations [ecology, 1800-2400], ocean_steamship_line [logistics] |  |
| 2511 (was 2507) | mulch_water_management | crop_residue_cover [0-600], soil_infiltration_trials |  | horse_hoe_tillage [1800-2400] |  |
| 2512 | phosphate_dressing | crushed_bone_manure [1800-2400] |  | nutrient_response_trials, steam_bone_digester [1800-2400] |  |
| 2515 | experimental_farm_station | agriculture_board_surveys [1800-2400], nutrient_response_trials |  | experimental_controls [knowledge, 1800-2400], farm_improvement_societies, research_university [knowledge] |  |
| 2517 | phosphate_solubilization | phosphate_dressing, nutrient_response_trials, lead_chamber_acid [production, 1800-2400] |  | steam_bone_digester [1800-2400] |  |
| 2520 | machine_tile_drainage | ridge_furrow_strips [1200-1800], covered_field_drains [ecology, 1800-2400] |  | soil_infiltration_trials, drained_lake_polders [infrastructure, 1800-2400] |  |
| 2523 | famine_relief_works | public_soup_kitchens [1800-2400], poor_law_boards [institutions] |  | free_grain_trade_edict [1800-2400], public_work_relief [labor, 1800-2400], grain_magistracy [1800-2400] |  |
| 2528 | heated_glasshouses | heated_orangeries [infrastructure, 1800-2400], hotbed_forcing [1800-2400] |  | iron_roof_trusses [infrastructure], cast_plate_glass [production, 1800-2400], town_luxury_vegetables [1800-2400] |  |
| 2533 | intensive_gardens | periurban_market_gardens [600-1200], heated_glasshouses |  | town_luxury_vegetables [1800-2400], hotbed_forcing [1800-2400] |  |
| 2533 | steam_threshing_sets | threshing_machine [1800-2400], high_pressure_steam_engines [production] |  | mechanical_reaper |  |
| 2541 | food_adulteration_tests | compound_microscopy [knowledge], systematic_chemical_names [knowledge, 1800-2400] |  | spoiled_food_condemnation [health, 1200-1800], bread_weight_assize [1200-1800] |  |
| 2547 | graded_grain_elevators | steam_grain_elevators [logistics] |  | printed_grain_prices [1800-2400], electrical_telegraphy [knowledge], standard_measures [knowledge, 0-600] |  |
| 2549 | chemical_baking_powder | salt_cake_soda [production, 1800-2400], dough_leavening [600-1200] |  | brewers_yeast_bread [1800-2400] |  |
| 2549 | condensed_milk | vacuum_pan_sugar, food_retorts |  | household_preserving_jars, lowland_export_dairying [1800-2400], rolled_tinplate [production, 1800-2400] |  |
| 2552 | fermentation_starter_cultures | fermentation_control [0-600] | one of: experimental_controls [knowledge, 1800-2400] | microbial_observation [knowledge], grain_mould_starters [1200-1800] |  |
| 2560 | plant_pathology_diagnosis | biological_classification [ecology, 1800-2400], experimental_controls [knowledge, 1800-2400] |  | compound_microscopy [knowledge], microbial_observation [knowledge] |  |
| 2564 (was 2560) | can_body_forming | tinplate_coating [production], standard_measures [knowledge, 0-600] |  | food_retorts, household_preserving_jars |  |
| 2565 | farm_colleges_ministry | experimental_farm_station, single_minister_departments [institutions] |  | research_university [knowledge], farm_improvement_societies |  |
| 2571 | gentle_heat_treatment | microbial_observation [knowledge], precision_thermometry [knowledge, 1800-2400] |  | food_retorts, fermentation_starter_cultures |  |
| 2573 | meat_extract_cubes | steam_bone_digester [1800-2400], vacuum_pan_sugar |  | condensed_milk, atomic_combining_weights [knowledge] |  |
| 2584 | beef_fat_margarine | keg_salted_butter [1200-1800], systematic_chemical_names [knowledge, 1800-2400] |  | condensed_milk, lowland_export_dairying [1800-2400] |  |
| 2587 | roller_grain_milling | graded_flour_bolting [600-1200], high_pressure_steam_engines [production] |  | steam_grain_elevators [logistics], open_hearth_steel [production] |  |
| 2592 | twine_binding_harvester | mechanical_reaper |  | steel_wire_drawing [production], steam_threshing_sets |  |
| 2600 | food_adulteration_law | food_adulteration_tests |  | central_board_of_health [health], bread_weight_assize [1200-1800], medical_officer_of_health [health] |  |
| 2605 | frozen_meat_trade | mechanical_refrigeration [infrastructure], iron_hulled_steamers [logistics] |  | compound_marine_engines [logistics], marsh_fattened_cattle [1800-2400] |  |
| 2608 | cream_separator | butter_churning [0-600], gear_tooth_generation [production] |  | lowland_export_dairying [1800-2400] |  |
| 2613 | resistant_vine_rootstocks | vine_rootstock_grafting [600-1200] |  | grafted_tree_nurseries [1200-1800], plant_pathology_diagnosis |  |
| 2619 | cooperative_creameries | consumer_cooperatives [labor], cream_separator |  | cheese_weigh_houses [1800-2400], lowland_export_dairying [1800-2400] |  |
| 2621 | silage_towers | winter_fodder [0-600], fodder_cutting_machines [1800-2400] |  | clover_ley_fodder [1800-2400], maize_field_crop [1800-2400] |  |
| 2627 | copper_lime_spray | plant_pathology_diagnosis |  | resistant_vine_rootstocks, chlorine_bleaching [production, 1800-2400] |  |
| 2635 | double_seaming | can_body_forming, bearing_surfaces [logistics, 0-600] |  | food_retorts |  |
| 2640 | bottled_town_milk | gentle_heat_treatment |  | refrigerated_rail_cars [logistics], plunger_pressed_glass [production] |  |
| 2640 | butterfat_milk_test | lead_chamber_acid [production, 1800-2400], cream_separator |  | cooperative_creameries |  |
| 2651 | dietary_heat_units | calorimetry [knowledge, 1800-2400], energy_conservation_law [knowledge] |  | meat_extract_cubes, food_adulteration_tests |  |
| 2659 | deficiency_disease_discovery | experimental_controls [knowledge, 1800-2400], dietary_heat_units |  | scurvy_controlled_trial [health, 1800-2400], lemon_juice_scurvy [health, 1800-2400], maize_skin_sickness [health, 1800-2400] |  |
| 2667 | chilled_fruit_shipping | frozen_meat_trade |  | refrigerated_rail_cars [logistics], steam_turbine_ships [logistics] |  |
| 2675 | progeny_rows | mass_seed_selection [0-600], tallies [knowledge, 0-600] |  | pedigree_herd_books, experimental_farm_station |  |
| 2680 | controlled_pollination | progeny_rows, experimental_controls [knowledge, 1800-2400] |  | descent_by_selection [knowledge] |  |
| 2680 | field_variety_trials | progeny_rows, statistical_sampling [knowledge] |  | experimental_farm_station |  |
| 2683 (was 2680) | heredity_experiments | progeny_rows, controlled_pollination |  | descent_by_selection [knowledge], cell_division_observation [knowledge] |  |
| 2683 | regional_seed_trials | field_variety_trials, regional_maps [knowledge, 0-600] |  | experimental_farm_station, farm_colleges_ministry |  |
| 2683 | school_meals | compulsory_elementary_schooling [knowledge], public_soup_kitchens [1800-2400] |  | dietary_heat_units, famine_relief_works |  |
| 2685 | plant_resistance_trait_trials | heredity_experiments, plant_pathology_diagnosis |  | field_variety_trials |  |
| 2691 | food_acidity_measurement | standard_measures [knowledge, 0-600], electrochemical_cells [knowledge] |  | food_retorts, household_preserving_jars |  |
| 2693 | clean_milk_ordinances | bottled_town_milk, consumption_germ_identified [health] |  | butterfat_milk_test, germ_theory_of_disease [health], medical_officer_of_health [health] |  |
| 2699 | vitamin_factors | deficiency_disease_discovery |  | dietary_heat_units, atomic_physics [knowledge] |  |
| 2704 | farm_extension_agents | experimental_farm_station, farm_colleges_ministry |  | regional_seed_trials, printed_farm_journals [1800-2400] |  |
| 2711 (was 2701) | ammonium_sulfate_fertilizer | catalytic_ammonia_synthesis [production], sulfuric_acid_production [production], nutrient_response_trials |  | mineral_nitrate_dressing, iron_ammonia_catalysts [production] |  |
| 2712 | farm_tractor | internal_combustion [production], steel_scouring_plough |  | steam_threshing_sets, series_built_motor_car [logistics] |  |
| 2712 | wartime_ration_cards | war_economy_boards [institutions], dietary_heat_units |  | public_soup_kitchens [1800-2400], famine_relief_works |  |
| 2720 | forced_air_grain_drying | electric_motors [production], grain_bellows_ventilation [1800-2400] |  | graded_grain_elevators, humidity_measurement |  |
| 2720 | grain_moisture_testing | humidity_measurement |  | graded_grain_elevators, electrical_measurement [knowledge] |  |
| 2720 | thermal_process_validation | food_retorts, double_seaming, experimental_controls [knowledge, 1800-2400] |  | food_acidity_measurement |  |
| 2725 | rickets_prevention | vitamin_factors |  | school_meals, infant_milk_depots [demography] |  |
| 2731 | iodized_salt | iodine_goitre_treatment [health] |  | vitamin_factors, school_medical_inspection [health] |  |
| 2736 | hybrid_maize_seed | heredity_experiments, maize_field_crop [1800-2400] |  | controlled_pollination, regional_seed_trials | contact_required: True |
| 2744 | quick_frozen_foods | mechanical_refrigeration [infrastructure], frozen_meat_trade |  | thermal_process_validation, regenerated_cellulose_fibre [production] |  |
| 2747 | contour_cultivation | geometric_survey [knowledge, 0-600], crop_calendars [0-600] |  | cross_slope_ploughing [ecology, 600-1200] |  |
| 2747 | cover_crop_mixtures | green_manure_crops [600-1200], field_variety_trials |  | crop_residue_cover [0-600] |  |
| 2750 (was 2747) | strip_cropping | contour_cultivation, crop_rotation [600-1200] |  | cross_slope_ploughing [ecology, 600-1200] |  |
| 2752 | household_refrigerator | mechanical_refrigeration [infrastructure], induction_motors [production] |  | alternating_current_grids [infrastructure], quick_frozen_foods |  |
| 2760 | soil_conservation_service | contour_cultivation, plains_dust_storms [ecology] |  | strip_cropping, cover_crop_mixtures, farm_extension_agents |  |
| 2763 | hitch_tractor | farm_tractor, pneumatic_tyres [logistics] |  | chain_power_transmission [production] |  |
| 2768 | combine_harvester | twine_binding_harvester, farm_tractor |  | hitch_tractor, steam_threshing_sets |  |
| 2776 | recommended_daily_allowances | vitamin_factors |  | wartime_ration_cards, dietary_heat_units, rickets_prevention |  |
| 2781 | food_group_guides | recommended_daily_allowances |  | school_meals, radio_broadcasting [culture] |  |
| 2787 | synthetic_crop_insecticide | chloralkali_cells [production], coal_tar_dyes [production] |  | copper_lime_spray, mosquito_control_brigades [health] |  |
| 2789 | selective_hormone_herbicide | chloralkali_cells [production], experimental_farm_station |  | synthetic_crop_insecticide, enzyme_catalysis [production] |  |
| 2792 | artificial_cattle_insemination | pedigree_herd_books, cryogenic_air_separation [production] |  | heredity_experiments, veterinary_schools [ecology, 1800-2400] |  |
| 2800 | confinement_broiler_houses | vitamin_factors, poultry_breed_selection [600-1200] |  | recommended_daily_allowances, rural_electrification [infrastructure], mould_broth_antibiotic [health] |  |
| 2800 | food_batch_traceability | material_accounting [knowledge, 0-600], cargo_seals [logistics, 0-600] |  | clean_milk_ordinances, punched_card_tabulation [knowledge] |  |
| 2800 | postharvest_loss_measurement | material_accounting [knowledge, 0-600], statistical_sampling [knowledge] |  | grain_moisture_testing |  |
| 2800 | soil_moisture_scheduling | soil_infiltration_trials, irrigation_loss_accounts [0-600] |  | resistive_sensing [production] |  |
| 2808 | self_service_cold_stores | quick_frozen_foods, mechanical_refrigeration [infrastructure] |  | pallet_forklift_handling [logistics], brand_advertising [culture], household_refrigerator |  |
| 2812 | centre_pivot_irrigation | rural_electrification [infrastructure], soil_moisture_scheduling |  | river_basin_works [infrastructure], hitch_tractor |  |
| 2822 | food_process_hazard_analysis | food_batch_traceability | one of: thermal_process_validation, experimental_controls [knowledge, 1800-2400] | clean_milk_ordinances, food_acidity_measurement |  |
| 2826 (was 2822) | food_package_barrier_testing | food_process_hazard_analysis | one of: experimental_controls [knowledge, 1800-2400] | polymer_film_extrusion [production] |  |
| 2826 (was 2822) | food_water_activity_measurement | food_process_hazard_analysis, humidity_measurement |  | grain_moisture_testing |  |
| 2829 (was 2822) | food_package_leak_detection | food_package_barrier_testing | one of: pressure_vessels [production, 1800-2400], electrical_measurement [knowledge] | food_water_activity_measurement, polymer_film_extrusion [production] |  |
| 2832 | inter_realm_food_standards | food_adulteration_law, world_assembly_of_realms [institutions] |  | food_process_hazard_analysis, inter_realm_health_council [health] |  |
| 2838 | drip_irrigation | thermoplastic_processing [production], soil_moisture_scheduling |  | centre_pivot_irrigation |  |
| 2838 | reduced_tillage | contour_cultivation, soil_assays [ecology] |  | selective_hormone_herbicide, soil_conservation_service |  |
| 2838 | semi_dwarf_grain_package | plant_resistance_trait_trials, ammonium_sulfate_fertilizer |  | hybrid_maize_seed, centre_pivot_irrigation, farm_extension_agents, regional_seed_trials |  |
| 2842 | food_banks | public_soup_kitchens [1800-2400] |  | self_service_cold_stores, postharvest_loss_measurement |  |
| 2842 | microwave_oven | radio_detection_ranging [security] |  | household_refrigerator |  |
| 2845 | aseptic_carton_milk | bottled_town_milk, polymer_film_extrusion [production] |  | thermal_process_validation, food_package_barrier_testing |  |
| 2855 | integrated_pest_management | synthetic_crop_insecticide, persistent_pesticide_warning [ecology] |  | population_dynamics_equations [ecology], farm_extension_agents |  |
| 2855 | starch_sugar_syrup | enzyme_catalysis [production], maize_field_crop [1800-2400] |  | hybrid_maize_seed, vacuum_pan_sugar | contact_required: True |
| 2862 | net_pen_aquaculture | fish_hatcheries [ecology], confinement_broiler_houses |  | stocked_fish_ponds [0-600], sustainable_yield_fisheries [ecology] | environment: coast |
| 2868 | national_dietary_goals | recommended_daily_allowances |  | food_group_guides, tobacco_cancer_evidence [health] |  |
| 2875 | hydroponic_glasshouses | heated_glasshouses, nutrient_response_trials |  | drip_irrigation, thermoplastic_processing [production] |  |
| 2888 | famine_early_warning | earth_observation_satellites [ecology], famine_relief_works |  | postharvest_loss_measurement, printed_grain_prices [1800-2400], weather_satellites [ecology] |  |
| 2900 | nutrition_labels | national_dietary_goals, food_adulteration_law |  | scanned_product_barcodes [logistics], recommended_daily_allowances |  |
| 2915 | therapeutic_ready_food | recommended_daily_allowances, groundnut_oil_crop [1800-2400] |  | oral_rehydration_salts [health], famine_early_warning | contact_required: True |
| 2915 | transgenic_crops | recombinant_vaccine [health], plant_resistance_trait_trials |  | hereditary_double_helix [knowledge], hybrid_maize_seed |  |
| 2920 | folic_acid_fortification | recommended_daily_allowances, roller_grain_milling |  | vitamin_factors, randomised_controlled_trial [health] |  |
| 2932 | precision_agriculture | open_satellite_positioning [logistics], hitch_tractor |  | earth_observation_satellites [ecology], desk_computers [knowledge], soil_moisture_scheduling |  |
| 2938 | marker_assisted_breeding | field_variety_trials, hereditary_double_helix [knowledge] |  | transgenic_crops, human_genome_reading [health] |  |
| 2945 | biofortified_staples | marker_assisted_breeding, vitamin_factors |  | folic_acid_fortification |  |
| 2950 | stress_tolerant_varieties | plant_resistance_trait_trials, marker_assisted_breeding |  | climate_assessment_panel [ecology] |  |
| 2965 | sugar_drink_taxes | national_dietary_goals |  | tobacco_control_laws [health], starch_sugar_syrup, nutrition_labels |  |
| 2970 | gene_edited_crops | transgenic_crops, marker_assisted_breeding |  | human_genome_reading [health] |  |
| 2975 | precision_fermented_proteins | recombinant_vaccine [health], fermentation_starter_cultures |  | transgenic_crops |  |
| 2982 | cultivated_cell_meat | cell_culture_methods [knowledge], fermentation_starter_cultures |  | precision_fermented_proteins, monoclonal_antibody_drugs [health] |  |
| 2988 | nitrogen_fixing_seed_microbes | gene_edited_crops, nutrient_response_trials |  | precision_fermented_proteins, green_manure_crops [600-1200] |  |
| 2992 | vertical_indoor_farms | hydroponic_glasshouses, solid_state_lighting [production] |  | digital_twin_plants [production] |  |
| 3000 | climate_shift_crop_planning | climate_circulation_models [ecology], regional_seed_trials |  | stress_tolerant_varieties, climate_adaptation_plans [ecology] |  |

## Notes

- **Catalog gates.** Every catalog item keeps the `requires_all` and `requires_any` its `scripts/*_knowledge.gd` entry declares, with one exception. `phosphate_solubilization` (2517) declares Production `sulfuric_acid_production`, which is placed at 2655, after it. Production `lead_chamber_acid` (1800–2400, 2295) replaces it. Acid phosphate dates from about AD 1843, and the lead-chamber process supplies its acid. `plant_pathology_diagnosis` declares the any-group `germ_theory` or `experimental_controls`. `germ_theory` is not a registry id, and Health's `germ_theory_of_disease` (2608) is later, so `experimental_controls` is required.
- **Year moves (all inside their bands).**
  - `humidity_measurement` 2424 → 2427, after Knowledge `measurement_uncertainty` (2424).
  - `mulch_water_management` and `mineral_nitrate_dressing` 2507 → 2511. `soil_assays` (Ecology) moves to 2500, so the trials at 2507 follow it.
  - `can_body_forming` 2560 → 2564, after Production `tinplate_coating` (2562).
  - `heredity_experiments` 2680 → 2683, after `controlled_pollination`.
  - `ammonium_sulfate_fertilizer` 2701 → 2711, after Production `catalytic_ammonia_synthesis` (2708).
  - `strip_cropping` 2747 → 2750, after `contour_cultivation`.
  - The package tests follow `food_process_hazard_analysis` (2822): barrier testing and water activity 2826, leak detection 2829.
- **Preserving.** `food_retorts` (Production `pressure_vessels`, Knowledge `precision_thermometry`) → household jars (Production `plunger_pressed_glass`) → `can_body_forming` → `double_seaming` → `thermal_process_validation` → hazard analysis → the package tests. Vacuum-pan sugar feeds condensed milk and meat extract. `gentle_heat_treatment` needs Knowledge `microbial_observation`. It leads to bottled milk and then to the clean-milk ordinances, which also need Health `consumption_germ_identified`, and to aseptic cartons (Production `polymer_film_extrusion`).
- **Soil fertility.** Ecology `soil_assays` → `nutrient_response_trials` → nitrate, guano, the experimental station and phosphate solubilization. Synthetic ammonia is Production's. The green-revolution package needs `plant_resistance_trait_trials` and `ammonium_sulfate_fertilizer`.
- **Machines.** The reaper needs `cast_iron_plough_parts` and `fodder_cutting_machines`. The tractor needs Production `internal_combustion` and the steel plough. The hitch tractor adds Logistics `pneumatic_tyres`. The combine needs the twine binder and the tractor. Centre-pivot irrigation needs Infrastructure `rural_electrification`.
- **Breeding.** The catalog chain `progeny_rows` → `controlled_pollination` / `field_variety_trials` → `heredity_experiments` → `plant_resistance_trait_trials`. Transgenic crops need Health `recombinant_vaccine` (2890), the first gene transfer in the registry, because no separate recombinant-DNA row exists. Marker-assisted breeding needs Knowledge `hereditary_double_helix`. Gene-edited crops need transgenic crops and marker breeding. Precision-fermented proteins need `recombinant_vaccine` and `fermentation_starter_cultures`.
- **Diet science.** Knowledge `calorimetry` and `energy_conservation_law` → `dietary_heat_units` → deficiency diseases → vitamins → rickets and daily allowances → food-group guides → dietary goals → labels and sugar-drink taxes. Ration cards need Institutions `war_economy_boards`.
- **Regional items.** `seabird_guano_trade` and `net_pen_aquaculture` need `environment: coast`. `cocoa_press_chocolate`, `hybrid_maize_seed`, `starch_sugar_syrup` and `therapeutic_ready_food` carry `contact_required`, inherited from contact-gated parents (`court_chocolate_drink`, `maize_field_crop`, `groundnut_oil_crop`). `resistant_vine_rootstocks` and `deficiency_disease_discovery` are regional in the list, but they are not gated. No vine or rice environment exists, and gating the deficiency discovery would also gate the vitamins.

## Cross-line parents in 2400–3000

Nutrition, Health, Demography and Ecology are mapped in this partial. The other lines are mapped by other agents.

- **Culture:** `brand_advertising` (2613), `radio_broadcasting` (2720)
- **Demography:** `infant_milk_depots` (2651)
- **Ecology:** `climate_adaptation_plans` (2950), `climate_assessment_panel` (2895), `climate_circulation_models` (2868), `earth_observation_satellites` (2856), `fish_hatcheries` (2539), `persistent_pesticide_warning` (2830), `plains_dust_storms` (2757), `population_dynamics_equations` (2733), `soil_assays` (2500), `sustainable_yield_fisheries` (2810), `weather_satellites` (2825)
- **Health:** `central_board_of_health` (2528), `consumption_germ_identified` (2619), `germ_theory_of_disease` (2608), `human_genome_reading` (2932), `inter_realm_health_council` (2795), `iodine_goitre_treatment` (2453), `medical_officer_of_health` (2547), `monoclonal_antibody_drugs` (2918), `mosquito_control_brigades` (2669), `mould_broth_antibiotic` (2781), `oral_rehydration_salts` (2845), `randomised_controlled_trial` (2795), `recombinant_vaccine` (2890), `school_medical_inspection` (2685), `tobacco_cancer_evidence` (2800), `tobacco_control_laws` (2835)
- **Infrastructure:** `alternating_current_grids` (2645), `iron_roof_trusses` (2430), `mechanical_refrigeration` (2536), `river_basin_works` (2752), `rural_electrification` (2745)
- **Institutions:** `poor_law_boards` (2491), `single_minister_departments` (2427), `war_economy_boards` (2704), `world_assembly_of_realms` (2787)
- **Knowledge:** `atomic_combining_weights` (2408), `atomic_physics` (2696), `cell_culture_methods` (2685), `cell_division_observation` (2587), `compound_microscopy` (2480), `compulsory_elementary_schooling` (2587), `descent_by_selection` (2557), `desk_computers` (2868), `electrical_measurement` (2453), `electrical_telegraphy` (2504), `electrochemical_cells` (2400), `energy_conservation_law` (2525), `hereditary_double_helix` (2808), `measurement_uncertainty` (2424), `microbial_observation` (2480), `punched_card_tabulation` (2640), `research_university` (2427), `statistical_sampling` (2667)
- **Labor:** `consumer_cooperatives` (2512)
- **Logistics:** `compound_marine_engines` (2573), `iron_hulled_steamers` (2515), `ocean_steamship_line` (2501), `open_satellite_positioning` (2912), `pallet_forklift_handling` (2752), `pneumatic_tyres` (2635), `refrigerated_rail_cars` (2613), `scanned_product_barcodes` (2860), `series_built_motor_car` (2688), `steam_grain_elevators` (2512), `steam_turbine_ships` (2659)
- **Production:** `catalytic_ammonia_synthesis` (2708), `chain_power_transmission` (2613), `chloralkali_cells` (2645), `coal_tar_dyes` (2554), `cryogenic_air_separation` (2677), `digital_twin_plants` (2970), `electric_motors` (2492), `enzyme_catalysis` (2660), `gear_tooth_generation` (2486), `high_pressure_steam_engines` (2410), `induction_motors` (2635), `interchangeable_component_fits` (2424), `internal_combustion` (2605), `iron_ammonia_catalysts` (2704), `open_hearth_steel` (2573), `plunger_pressed_glass` (2467), `polymer_film_extrusion` (2762), `regenerated_cellulose_fibre` (2650), `resistive_sensing` (2686), `solid_state_lighting` (2925), `steel_wire_drawing` (2581), `sulfuric_acid_production` (2655), `thermoplastic_processing` (2759), `tinplate_coating` (2562)
- **Security:** `radio_detection_ranging` (2764)
