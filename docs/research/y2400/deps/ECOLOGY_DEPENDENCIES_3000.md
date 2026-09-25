# Ecology dependencies: years 2400–3000

Generated from `docs/research/y2400/deps/partials/nhde.json`. It uses ids from `registry_3000.json`, the 1800–2400 registry (`docs/research/y1800/registry_2400.json`, with the dependencies in `docs/research/y1800/deps/partials/`, since `graph_2400.json` is not yet merged), the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph and block, the 0–600 graph and block only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 2400–3000 id owned by Logistics, `[ecology, 1800-2400]` is a 1800–2400 Ecology id, `[1800-2400]` is a same-line 1800–2400 id. `requires_all` are hard prerequisites; a `requires_any` group needs one member; precedents are soft influences. Every parent is dated at or before its dependent, after the year moves in `partials/nhde_year_adjustments.json`, and no edge links two 2400–3000 items of the same year. The Year column shows the adjusted year. `environment` lists mean any one listed environment satisfies the gate. `contact_required` marks items that inherit the ocean-contact gate from a contact-gated parent (new-world crops, cinchona).

**125 entries, 202 hard edges, 211 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2405 | mineral_streak_tests | stone_sorting [production, 0-600], pit_firing [production, 0-600], mineral_cleavage [1800-2400] |  | relative_stratigraphy [1800-2400] |  |
| 2419 | vegetation_zone_mapping | far_land_specimen_voyages [1800-2400], instrumental_weather_registers [1800-2400] |  | biological_classification [1800-2400], habitat_observation_records [1800-2400] |  |
| 2427 | sediment_provenance | relative_stratigraphy [1800-2400], mineral_specific_gravity [knowledge, 600-1200], seasonal_patterns [0-600] |  | mineral_streak_tests |  |
| 2429 | forestry_academy | tree_volume_tables [1800-2400] |  | sustained_yield_forestry [1800-2400], state_polytechnic_school [knowledge, 1800-2400] |  |
| 2432 | comparative_mineral_hardness | controlled_flaking [production, 0-600], standard_measures [knowledge, 0-600], mineral_streak_tests |  | mineral_cleavage [1800-2400] |  |
| 2440 | lithologic_correlation | relative_stratigraphy [1800-2400], mineral_cleavage [1800-2400], regional_maps [knowledge, 0-600] |  | sediment_provenance, deep_time_geology [1800-2400] |  |
| 2441 | geologic_cross_sections | geometric_survey [knowledge, 0-600], relative_stratigraphy [1800-2400], similar_triangles [knowledge, 600-1200] |  | mining_engineering_academies [knowledge, 1800-2400] |  |
| 2442 | structural_geologic_mapping | geologic_cross_sections, trigonometry [knowledge, 600-1200], regional_maps [knowledge, 0-600], lithologic_correlation |  | military_survey_maps [security, 1800-2400] |  |
| 2445 | isotherm_maps | vegetation_zone_mapping, instrumental_weather_registers [1800-2400] |  | weather_observer_network [1800-2400] |  |
| 2459 | tall_dispersal_stacks | tall_smelter_flues [600-1200] |  | tall_chimney_orders [1800-2400], high_pressure_steam_engines [production] |  |
| 2464 | atmospheric_heat_retention | precision_thermometry [knowledge, 1800-2400], isolated_airs_chemistry [knowledge, 1800-2400] |  | isotherm_maps, calorimetry [knowledge, 1800-2400] |  |
| 2469 | acid_fume_blight | salt_cake_soda [production, 1800-2400] |  | smelter_fume_blight [1800-2400], dye_works_nuisance [1800-2400] |  |
| 2472 | state_forest_code | forestry_academy |  | realm_forest_ordinance [1800-2400], sustained_yield_forestry [1800-2400] |  |
| 2475 | developmental_stage_series | comparative_anatomy [1800-2400] |  | animalcule_microscope [knowledge, 1800-2400], biological_classification [1800-2400] |  |
| 2491 | gasworks_river_waste | coal_gas_works [production] |  | town_river_fish_kills [1800-2400], dye_works_nuisance [1800-2400] |  |
| 2493 | realm_geological_survey | structural_geologic_mapping |  | single_minister_departments [institutions], mining_engineering_academies [knowledge, 1800-2400] |  |
| 2500 (was 2507) | soil_assays | atomic_combining_weights [knowledge], systematic_chemical_names [knowledge, 1800-2400] |  | plantation_soil_exhaustion [1800-2400], crushed_bone_manure [nutrition, 1800-2400], named_soil_kinds [0-600] |  |
| 2501 | ice_age_theory | glacier_advance_records [1200-1800], lithologic_correlation |  | deep_time_geology [1800-2400], glacier_farm_remission [1800-2400] |  |
| 2520 | colony_hunting_collapse | ocean_whaling_depletion [1800-2400] |  | seabird_colony_shares [1200-1800], island_extinction_record [1800-2400] | environment: coast |
| 2533 | telegraphed_weather_maps | weather_observer_network [1800-2400], electrical_telegraphy [knowledge] |  | isotherm_maps, storm_path_reconstruction [1800-2400] |  |
| 2539 | fish_hatcheries | river_fish_restocking [600-1200] |  | town_river_fish_kills [1800-2400], stocked_fish_ponds [nutrition, 0-600] | environment: river |
| 2541 | smoke_nuisance_ordinances | coal_smoke_limits [1200-1800] |  | tall_dispersal_stacks, coal_smoke_treatise [1800-2400] |  |
| 2547 | acclimatization_societies | colonial_plant_transfers [1800-2400] |  | ocean_steamship_line [logistics], far_land_specimen_voyages [1800-2400] |  |
| 2557 | heat_trapping_gases | atmospheric_heat_retention |  | precision_thermometry [knowledge, 1800-2400], isolated_airs_chemistry [knowledge, 1800-2400] |  |
| 2559 | invasive_species_spread | acclimatization_societies |  | brown_rat_invasion [1800-2400], contact_species_exchange [1800-2400] |  |
| 2563 | harbour_storm_warnings | telegraphed_weather_maps |  | hydrographic_office [logistics, 1800-2400] | environment: coast |
| 2568 | fume_works_inspectorate | acid_fume_blight, smoke_nuisance_ordinances |  | condensing_smelter_flues [1800-2400], smelter_damage_payments [1800-2400] |  |
| 2571 | human_impact_treatise | economy_of_nature [1800-2400], desiccation_forest_reserves [1800-2400] |  | acid_fume_blight, vegetation_zone_mapping |  |
| 2576 | household_of_nature_science | descent_by_selection [knowledge], economy_of_nature [1800-2400] |  | vegetation_zone_mapping, habitat_observation_records [1800-2400] |  |
| 2579 | lichen_air_indicators | biological_classification [1800-2400], acid_fume_blight |  | smoke_nuisance_ordinances |  |
| 2587 | state_weather_service | harbour_storm_warnings |  | telegraphed_weather_maps, single_minister_departments [institutions] |  |
| 2592 | reserved_nature_park | human_impact_treatise |  | landscape_park_gardens [culture, 1800-2400], desiccation_forest_reserves [1800-2400] |  |
| 2593 | tree_planting_days | forestry_academy |  | hedgerow_timber_planting [1800-2400], state_forest_code |  |
| 2603 | river_pollution_act | river_offal_bans [1200-1800], gasworks_river_waste |  | intercepting_sewers [infrastructure] |  |
| 2604 | biogeographic_realms | vegetation_zone_mapping, descent_by_selection [knowledge] |  | far_land_specimen_voyages [1800-2400] |  |
| 2613 | fish_ladder_requirements | weir_fish_gaps [1200-1800] |  | fish_hatcheries, illegal_weir_removal [1800-2400] | environment: river |
| 2619 | smoke_damage_leaf_assays | smelter_fume_blight [1800-2400], soil_assays |  | fume_works_inspectorate, lichen_air_indicators |  |
| 2621 | volcanic_dust_cooling | volcanic_dry_fog_year [1800-2400], telegraphed_weather_maps |  | isotherm_maps, storm_path_reconstruction [1800-2400] |  |
| 2629 | bird_protection_societies | colony_hunting_collapse |  | acclimatization_societies |  |
| 2637 | relict_herd_protection | last_wild_cattle [1800-2400] |  | reserved_nature_park, colony_hunting_collapse |  |
| 2643 | state_forest_reserves | state_forest_code |  | reserved_nature_park |  |
| 2648 | irrigation_salinization | soil_assays |  | saline_drain_channels [600-1200], irrigation_water_tribunals [1200-1800] | environment: dry, river |
| 2653 | game_warden_licences | game_bird_close_seasons [1800-2400] |  | property_game_qualification [1800-2400], relict_herd_protection |  |
| 2656 | fossil_carbon_warming_estimate | heat_trapping_gases, ice_age_theory |  | volcanic_dust_cooling |  |
| 2659 | smoke_density_charts | smoke_nuisance_ordinances |  | fume_works_inspectorate |  |
| 2664 | plant_succession | household_of_nature_science |  | dune_pine_plantations [1800-2400], dune_grass_laws [1800-2400] |  |
| 2667 | systematic_channel_sampling | ore_assaying [production, 0-600], standard_measures [knowledge, 0-600], geometric_survey [knowledge, 0-600] |  | realm_geological_survey |  |
| 2675 | wildlife_refuges | game_warden_licences, reserved_nature_park |  | bird_protection_societies |  |
| 2680 | state_forest_service | state_forest_reserves |  | forestry_academy |  |
| 2688 | resource_conservation_policy | state_forest_service |  | human_impact_treatise, realm_geological_survey |  |
| 2693 | forest_fire_suppression | state_forest_service |  | firebreak_rides [1800-2400] |  |
| 2696 | pelagic_sealing_treaty | colony_hunting_collapse, interrealm_arbitration [institutions] |  | bird_protection_societies, game_warden_licences |  |
| 2699 | continental_drift_hypothesis | structural_geologic_mapping, realm_geological_survey |  | biogeographic_realms |  |
| 2704 | human_caused_extinction | extinction_recognized [1800-2400] |  | relict_herd_protection, colony_hunting_collapse |  |
| 2709 | migratory_bird_treaty | bird_protection_societies, game_warden_licences |  | pelagic_sealing_treaty |  |
| 2711 | park_service_office | reserved_nature_park |  | state_forest_service |  |
| 2720 | range_carrying_capacity | soil_assays, plant_succession |  | herd_size_limits [0-600] |  |
| 2733 | population_dynamics_equations | differential_equations [knowledge, 1800-2400], household_of_nature_science |  | population_pressure_treatise [demography, 1800-2400], plant_succession |  |
| 2736 | oil_discharge_limits | heavy_oil_motor_ships [logistics] |  | river_pollution_act, migratory_bird_treaty | environment: coast |
| 2739 | food_chain_pyramids | household_of_nature_science |  | plant_succession |  |
| 2757 | plains_dust_storms | farm_tractor [nutrition] |  | steel_scouring_plough [nutrition], range_carrying_capacity | environment: dry |
| 2759 | public_grazing_districts | range_carrying_capacity |  | plains_dust_storms |  |
| 2761 | ecosystem_concept | food_chain_pyramids, plant_succession |  | population_dynamics_equations |  |
| 2762 | earthquake_magnitude_scale | realm_geological_survey |  | electrical_measurement [knowledge] |  |
| 2768 | measured_carbon_warming | fossil_carbon_warming_estimate |  | state_weather_service |  |
| 2779 | trophic_energy_flow | ecosystem_concept |  | calorimetry [knowledge, 1800-2400] |  |
| 2789 | whaling_quota_commission | ocean_whaling_depletion [1800-2400], world_assembly_of_realms [institutions] |  | population_dynamics_equations |  |
| 2795 | nature_union_red_lists | human_caused_extinction |  | world_assembly_of_realms [institutions] |  |
| 2800 | grade_tonnage_models | ore_assaying [production, 0-600], statistical_sampling [knowledge], geologic_cross_sections, ratio_proportion [knowledge, 600-1200] |  | systematic_channel_sampling |  |
| 2801 | numerical_weather_prediction | state_weather_service, binary_adders [production] |  | relay_registers [production], computability_theory [knowledge] |  |
| 2805 | killer_smog_episode | smoke_density_charts |  | smoke_nuisance_ordinances |  |
| 2810 | sustainable_yield_fisheries | population_dynamics_equations |  | fish_hatcheries |  |
| 2812 | fallout_monitoring | fission_weapon [security], radiation_measurement [knowledge] |  | radium_tumour_therapy [health], state_weather_service |  |
| 2815 | clean_air_act | killer_smog_episode, smoke_nuisance_ordinances |  | smoke_density_charts, lichen_air_indicators |  |
| 2816 | industrial_mercury_poisoning | river_pollution_act, mercury_amalgam_poisoning [1800-2400] |  | gasworks_river_waste, fish_hatcheries | environment: coast |
| 2820 | atmospheric_co2_record | measured_carbon_warming, gas_composition_analysis [production] |  | heat_trapping_gases, state_weather_service |  |
| 2825 | weather_satellites | orbital_satellite_launch [logistics], state_weather_service |  | numerical_weather_prediction, telegraphed_weather_maps |  |
| 2830 | persistent_pesticide_warning | synthetic_crop_insecticide [nutrition], food_chain_pyramids |  | bird_protection_societies, ecosystem_concept |  |
| 2831 | spatial_variograms | statistical_inference [knowledge], coordinate_geometry [knowledge, 1800-2400], systematic_channel_sampling |  | grade_tonnage_models |  |
| 2832 | resource_kriging | spatial_variograms, matrix_algebra [knowledge], least_squares_estimation [knowledge] |  | grade_tonnage_models |  |
| 2834 | orebody_block_models | geologic_cross_sections, resource_kriging, grade_tonnage_models |  | spatial_variograms |  |
| 2838 | geochemical_baselines | chemical_distillation [knowledge, 1200-1800], statistical_sampling [knowledge], systematic_channel_sampling |  | soil_assays, realm_geological_survey |  |
| 2840 | plate_tectonics | continental_drift_hypothesis, underwater_sound_ranging [security] |  | earthquake_magnitude_scale |  |
| 2841 | endangered_species_list | nature_union_red_lists |  | human_caused_extinction, wildlife_refuges |  |
| 2842 | island_biogeography | biogeographic_realms, population_dynamics_equations |  | ecosystem_concept, vegetation_zone_mapping |  |
| 2844 | oil_spill_response | oil_discharge_limits, very_large_tankers [logistics] |  | river_pollution_act, industrial_mercury_poisoning | environment: coast |
| 2848 | environmental_impact_review | clean_air_act, persistent_pesticide_warning |  | river_pollution_act, industrial_mercury_poisoning |  |
| 2850 | environment_protection_agency | environmental_impact_review, clean_air_act |  | fume_works_inspectorate, industrial_mercury_poisoning |  |
| 2851 | geochemical_anomaly_mapping | geochemical_baselines, regional_maps [knowledge, 0-600], measurement_uncertainty [knowledge] |  | systematic_channel_sampling |  |
| 2852 | wetland_convention | migratory_bird_treaty |  | wildlife_refuges, nature_union_red_lists |  |
| 2855 | interrealm_environment_programme | world_assembly_of_realms [institutions], environment_protection_agency |  | nature_union_red_lists, whaling_quota_commission |  |
| 2856 | earth_observation_satellites | weather_satellites |  | reconnaissance_satellites [security] |  |
| 2858 | endangered_trade_convention | endangered_species_list |  | nature_union_red_lists, wetland_convention |  |
| 2860 | ozone_depletion_theory | gas_composition_analysis [production], chloralkali_cells [production] |  | atmospheric_co2_record |  |
| 2862 | leaded_fuel_phaseout | environment_protection_agency |  | clean_air_act, industrial_mercury_poisoning |  |
| 2865 | transboundary_acid_rain | clean_air_act, fume_works_inspectorate |  | smoke_damage_leaf_assays, lichen_air_indicators |  |
| 2868 | climate_circulation_models | numerical_weather_prediction, measured_carbon_warming |  | atmospheric_co2_record, weather_satellites |  |
| 2872 | transboundary_air_convention | transboundary_acid_rain, interrealm_environment_programme |  | clean_air_act, whaling_quota_commission |  |
| 2875 | polluter_pays_cleanup | environment_protection_agency |  | industrial_mercury_poisoning, oil_spill_response |  |
| 2880 | whaling_moratorium | whaling_quota_commission |  | nature_union_red_lists, endangered_trade_convention |  |
| 2888 | polar_ozone_hole | ozone_depletion_theory |  | earth_observation_satellites |  |
| 2890 | reactor_fallout_crisis | nuclear_power_stations [infrastructure], radiation_measurement [knowledge] |  | fallout_monitoring, environment_protection_agency, nuclear_civil_defence [security], reactor_engineering [infrastructure] |  |
| 2892 | ozone_protection_treaty | polar_ozone_hole, interrealm_environment_programme |  | transboundary_air_convention, leaded_fuel_phaseout |  |
| 2894 | deep_ice_core_records | atmospheric_co2_record |  | ice_age_theory, climate_circulation_models |  |
| 2895 | climate_assessment_panel | climate_circulation_models, interrealm_environment_programme |  | deep_ice_core_records, atmospheric_co2_record |  |
| 2900 | sulfur_allowance_trading | transboundary_acid_rain, environment_protection_agency |  | transboundary_air_convention, polluter_pays_cleanup |  |
| 2905 | climate_framework_convention | climate_assessment_panel |  | ozone_protection_treaty, transboundary_air_convention |  |
| 2906 | biodiversity_convention | endangered_trade_convention, interrealm_environment_programme |  | island_biogeography, whaling_moratorium |  |
| 2912 | predator_reintroduction | park_service_office, ecosystem_concept |  | population_dynamics_equations, endangered_species_list |  |
| 2918 | binding_emission_targets | climate_framework_convention |  | sulfur_allowance_trading, ozone_protection_treaty |  |
| 2919 | ocean_plastic_gyres | thermoplastic_processing [production] |  | oil_spill_response, polymer_film_extrusion [production] |  |
| 2928 | persistent_fluorochemicals | environment_protection_agency |  | geochemical_baselines, industrial_mercury_poisoning |  |
| 2935 | microplastic_monitoring | ocean_plastic_gyres |  | persistent_fluorochemicals, geochemical_baselines |  |
| 2938 | carbon_emission_market | binding_emission_targets, sulfur_allowance_trading |  | climate_assessment_panel |  |
| 2945 | environmental_dna_surveys | human_genome_reading [health] |  | endangered_species_list, island_biogeography |  |
| 2950 | climate_adaptation_plans | climate_framework_convention |  | storm_surge_barriers [infrastructure], deep_ice_core_records |  |
| 2958 | extreme_event_attribution | climate_circulation_models |  | deep_ice_core_records, climate_assessment_panel |  |
| 2962 | universal_climate_pledges | binding_emission_targets |  | carbon_emission_market, extreme_event_attribution |  |
| 2972 | net_zero_statutes | universal_climate_pledges |  | carbon_emission_market, extreme_event_attribution |  |
| 2978 | methane_plume_satellites | earth_observation_satellites |  | climate_assessment_panel, universal_climate_pledges |  |
| 2980 | thirty_percent_protection | biodiversity_convention |  | reserved_nature_park, predator_reintroduction |  |
| 2982 | loss_damage_fund | universal_climate_pledges |  | climate_adaptation_plans, extreme_event_attribution |  |
| 2992 | verified_carbon_removal | carbon_emission_market |  | net_zero_statutes, earth_observation_satellites |  |
| 2995 | natural_capital_accounts | national_income_accounts [institutions], ecosystem_concept |  | thirty_percent_protection, carbon_emission_market |  |
| 3000 | plastics_production_cap | microplastic_monitoring, interrealm_environment_programme |  | ocean_plastic_gyres, universal_climate_pledges |  |

## Notes

- **Catalog gates.** All fifteen catalog ids keep their declared gates. `mineral_streak_tests`, `comparative_mineral_hardness` and `structural_geologic_mapping` also require the item each continues. `soil_assays` has no `*_knowledge.gd` entry. It needs Knowledge `atomic_combining_weights` and `systematic_chemical_names`, and it moves 2507 → 2500 so that Nutrition's catalog trials at 2507 follow it.
- **Earth science.** Streak → hardness; stratigraphy → correlation, cross sections → the realm map → the survey office → continental drift → plate tectonics (with Security `underwater_sound_ranging`). The ore-geology catalog chain follows the catalog.
- **Climate and weather.** Weather registers → vegetation zones and isotherms → heat retention → heat-trapping gases → the coal-warming estimate → measured warming → the CO2 record (Production `gas_composition_analysis`). Telegraphed maps (Knowledge `electrical_telegraphy`) → storm warnings → the weather service → the computed forecast. The forecast needs Production `binary_adders`, because the registry has no electronic-computer row near 2800. Weather satellites need Logistics `orbital_satellite_launch`.
- **Pollution.** Alkali-works blight (Production `salt_cake_soda`) and smoke ordinances → the fume inspectorate. Gas-works waste (Production `coal_gas_works`) → the river pollution act → mercury poisoning. Smoke charts → the killing smog → the clean air act → impact review → the environment agency → leaded-fuel phase-out, polluter pays and sulphur trading. The ozone theory needs `gas_composition_analysis` and Production `chloralkali_cells`.
- **Weapons of mass destruction (research only).** `fallout_monitoring` requires Security `fission_weapon`, as knowledge of test fallout. It gives no authority to use the weapon. `reactor_fallout_crisis` requires Infrastructure `nuclear_power_stations`, and fallout monitoring is only its precedent. No ecology item lets a general use gas, fission or thermonuclear weapons, or missiles.
- **Regional gates.** Coast: colony collapse, storm warnings, oil discharge, oil spills and mercury in a fishing bay. River: fish hatcheries and fish ladders. Dry: dust storms. Dry or river: irrigation salting.
- **Treaties.** These need Institutions `world_assembly_of_realms` or `interrealm_arbitration` and the domestic law they extend. Examples: the migratory-bird treaty needs the bird societies and game wardens, and the climate conventions build on the assessment panel.

## Cross-line parents in 2400–3000

Nutrition, Health, Demography and Ecology are mapped in this partial. The other lines are mapped by other agents.

- **Health:** `human_genome_reading` (2932), `radium_tumour_therapy` (2680)
- **Infrastructure:** `intercepting_sewers` (2550), `nuclear_power_stations` (2812), `reactor_engineering` (2780), `storm_surge_barriers` (2882)
- **Institutions:** `interrealm_arbitration` (2592), `national_income_accounts` (2757), `single_minister_departments` (2427), `world_assembly_of_realms` (2787)
- **Knowledge:** `atomic_combining_weights` (2408), `computability_theory` (2763), `descent_by_selection` (2557), `electrical_measurement` (2453), `electrical_telegraphy` (2504), `least_squares_estimation` (2416), `matrix_algebra` (2555), `measurement_uncertainty` (2424), `radiation_measurement` (2659), `statistical_inference` (2400), `statistical_sampling` (2667)
- **Logistics:** `heavy_oil_motor_ships` (2699), `ocean_steamship_line` (2501), `orbital_satellite_launch` (2817), `very_large_tankers` (2818)
- **Nutrition:** `farm_tractor` (2712), `steel_scouring_plough` (2499), `synthetic_crop_insecticide` (2787)
- **Production:** `binary_adders` (2765), `chloralkali_cells` (2645), `coal_gas_works` (2420), `gas_composition_analysis` (2558), `high_pressure_steam_engines` (2410), `polymer_film_extrusion` (2762), `relay_registers` (2769), `thermoplastic_processing` (2759)
- **Security:** `fission_weapon` (2787), `nuclear_civil_defence` (2814), `reconnaissance_satellites` (2825), `underwater_sound_ranging` (2716)
