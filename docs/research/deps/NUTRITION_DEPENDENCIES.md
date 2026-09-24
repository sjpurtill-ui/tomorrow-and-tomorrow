# Nutrition dependencies

Generated with `docs/research/deps/nutrition.json`. It uses registry ids only. Cross-line ids show their line in brackets. An `environment` list means any one of the listed environments satisfies the gate. In the table, the ids in one `requires_any` group are separated by ` / `, and separate groups are separated by `;`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | edible_resource_recognition |  |  |  |  |
| 3 | ember_tending |  |  |  |  |
| 4 | hearth_heat_retention | ember_tending |  |  |  |
| 5 | food_pounding_mortars |  |  | stone_sorting [production] |  |
| 5 | nut_kernel_shelling | edible_resource_recognition |  |  |  |
| 6 | food_drying | edible_resource_recognition |  | weather_sign_reading [knowledge] |  |
| 7 | seed_selection | edible_resource_recognition |  | seasonal_patterns [ecology] |  |
| 8 | friction_fire_ignition | ember_tending |  |  |  |
| 8 | hearth_roasting_control | ember_tending, hearth_heat_retention |  |  |  |
| 9 | seasonal_protein_sourcing | edible_resource_recognition |  | seasonal_patterns [ecology] |  |
| 10 | percussion_fire_ignition | ember_tending |  | stone_sorting [production], friction_fire_ignition |  |
| 10 | varied_forage_rotation | seasonal_protein_sourcing |  | route_memory [knowledge] |  |
| 11 | smoking | food_drying, ember_tending |  | hide_smoke_curing [production] |  |
| 12 | root_grating_dewatering | food_pounding_mortars |  | basketry [production] |  |
| 13 | pest_deterrent_storage_herbs | food_drying, herbal_classification [health] |  | dry_cache_siting [logistics] |  |
| 15 | fruit_pulp_screening | edible_resource_recognition, basketry [production] |  |  |  |
| 16 | animal_taming | seasonal_protein_sourcing |  | herd_size_limits [ecology], cordage [production] |  |
| 17 | soil_exhaustion_recognition | seed_selection |  | topsoil_depth_reading [ecology] |  |
| 18 | plot_yield_memory | seed_selection, counting_words [knowledge] |  |  |  |
| 19 | acorn_leaching | nut_kernel_shelling, food_pounding_mortars |  | basketry [production] | environment: woodland |
| 20 | pulse_splitting | seed_selection, food_pounding_mortars |  |  |  |
| 22 | earth_oven_cooking | hearth_roasting_control |  | hearth_heat_retention |  |
| 23 | fish_weirs_and_traps | seasonal_protein_sourcing, basketry [production] |  | cordage [production], spawning_calendar [ecology] | environment: river/coast |
| 24 | grain_moisture_watch | seed_selection, food_drying |  |  |  |
| 25 | milking | animal_taming |  |  |  |
| 26 | indirect_solar_food_drying | food_drying | framed_construction [infrastructure] / basketry [production] |  |  |
| 27 | crop_calendars | seed_selection, moon_counting [knowledge] |  | phenology_signs [ecology] |  |
| 28 | threshing_frames | seed_selection |  | grain_moisture_watch, site_clearing_assessment [infrastructure] |  |
| 30 | winnowing_practice | threshing_frames, basketry [production] |  |  |  |
| 32 | saddle_quern_grinding | winnowing_practice, food_pounding_mortars |  | ground_stone_axes [production] |  |
| 34 | cereal_dehulling | threshing_frames, food_pounding_mortars |  |  |  |
| 35 | hand_dough_forming | saddle_quern_grinding |  |  |  |
| 36 | deliberate_milk_souring | milking |  | pit_firing [production] |  |
| 40 | food_steaming_vessels | pit_firing [production], clay_tempering [production] |  | earth_oven_cooking |  |
| 42 | controlled_baking | hand_dough_forming, hearth_roasting_control |  |  |  |
| 46 | seed_cleaning | winnowing_practice, seed_selection |  | basketry [production] |  |
| 48 | drive_hunts | seasonal_protein_sourcing | throwing_spears [security] / bow_craft [security] | labor_rotations [labor] |  |
| 52 | seed_reserves | seed_selection, grain_moisture_watch |  | public_stores [institutions] |  |
| 55 | hermetic_grain_storage | grain_moisture_watch, clay_lined_storage_pits [infrastructure] | pit_firing [production] / lime_plastered_floors [infrastructure] |  |  |
| 58 | wild_honey_smoking | smoking |  |  |  |
| 60 | grain_malting | grain_moisture_watch, threshing_frames |  | saddle_quern_grinding |  |
| 62 | starch_washing_separation | root_grating_dewatering, pit_firing [production] |  | plain_weaving [production] |  |
| 65 | resin_sealed_wine | pit_firing [production], fruit_pulp_screening |  | deliberate_milk_souring, bitumen_sealing [infrastructure] |  |
| 70 | pressed_cheese | deliberate_milk_souring, pit_firing [production] |  |  |  |
| 72 | managed_fallow | soil_exhaustion_recognition, plot_yield_memory |  | fallow_thicket_regrowth [ecology] |  |
| 75 | batch_labeling_by_harvest | seed_reserves, owner_marks [knowledge] |  |  |  |
| 80 | root_cellars | grain_moisture_watch | clay_lined_storage_pits [infrastructure] / dry_stone_walls [infrastructure] | frost_pocket_reading [ecology] |  |
| 85 | raised_granaries | grain_moisture_watch, framed_construction [infrastructure] |  | vermin_deterrent_placement [logistics] |  |
| 90 | leafy_green_incorporation | edible_resource_recognition, seed_selection |  | food_steaming_vessels |  |
| 95 | cutting_propagation | seed_selection, plot_yield_memory |  |  |  |
| 100 | mixed_grain_legume_meals | pulse_splitting, cereal_dehulling |  |  |  |
| 104 | manure_field_spreading | animal_taming, managed_fallow |  |  |  |
| 106 | reserve_allocation_priority | seed_reserves, mouths_against_store [demography] |  |  |  |
| 110 | flour_sifting | saddle_quern_grinding, seed_cleaning | basketry [production] / plain_weaving [production] |  |  |
| 112 | offshoot_date_planting | cutting_propagation |  |  | environment: dry |
| 116 | fermentation_control | grain_malting, deliberate_milk_souring | pit_firing [production] | resin_sealed_wine |  |
| 120 | staggered_meal_timing | mouths_against_store [demography] |  | seasonal_work_round [labor] |  |
| 122 | ash_field_amendment | managed_fallow |  | controlled_undergrowth_burning [ecology], swidden_cycle [ecology] |  |
| 126 | irrigation_schedules | river_supply_channels [infrastructure], crop_calendars |  |  | environment: river |
| 135 | communal_meal_variety_rules | mixed_grain_legume_meals, leafy_green_incorporation |  | shared_hearth_gatherings [culture] |  |
| 145 | ox_drawn_ard | animal_taming, hafted_tools [production] |  | ox_drawn_sledges [logistics], manure_field_spreading |  |
| 150 | reserve_moisture_barrier_layering | hermetic_grain_storage, root_cellars |  | stock_layering_method [logistics] |  |
| 155 | salting_fish_meat | food_drying |  | salt_shell_routes [logistics], smoking | resources_known: Salt |
| 158 | planting_density_adjustment | plot_yield_memory, seed_cleaning |  | topsoil_depth_reading [ecology] |  |
| 172 | butter_churning | deliberate_milk_souring |  | pit_firing [production] |  |
| 180 | winter_fodder | animal_taming, hafted_tools [production] |  | leaf_fodder_pollarding [ecology], transhumance [ecology] |  |
| 195 | intercrop_pairing_lore | planting_density_adjustment |  | managed_fallow, mixed_grain_legume_meals |  |
| 200 | clay_dome_ovens | controlled_baking, kiln_control [production] |  |  |  |
| 208 | portion_allotment_customs | reserve_allocation_priority |  | leader_gift_redistribution [institutions] |  |
| 212 | shared_reserve_access_rules | reserve_allocation_priority, public_stores [institutions] |  | customary_law [institutions] |  |
| 220 | barley_beer | grain_malting, fermentation_control |  | controlled_baking |  |
| 226 | seasonal_diet_diversification | communal_meal_variety_rules, crop_calendars |  |  |  |
| 228 | layered_pit_storage | reserve_moisture_barrier_layering |  | clay_lined_storage_pits [infrastructure] |  |
| 232 | field_rest_scheduling | managed_fallow, crop_calendars |  | solar_year_reckoning [knowledge] |  |
| 245 | dried_fruit_cakes | food_drying, cutting_propagation |  | offshoot_date_planting |  |
| 260 | kitchen_gardens | leafy_green_incorporation, manure_field_spreading |  | irrigation_schedules |  |
| 290 | grain_parboiling | food_steaming_vessels, grain_moisture_watch |  |  |  |
| 305 | stock_rotation | batch_labeling_by_harvest, oldest_first_marking [logistics] |  | marked_storage_registers [knowledge] |  |
| 315 | brine_fermentation | salting_fish_meat, fermentation_control |  |  |  |
| 325 | spoilage_inspection | stock_rotation, rotating_inspection_duty [knowledge] |  |  |  |
| 335 | regional_granaries | raised_granaries, marked_storage_registers [knowledge], tributary_villages [institutions] |  |  |  |
| 345 | ghee | butter_churning |  |  |  |
| 355 | legume_field_interplanting | intercrop_pairing_lore |  | field_rest_scheduling |  |
| 360 | reserve_rotation_ledgers | stock_rotation, clay_record_tablets [knowledge] |  |  |  |
| 365 | weaning_food_customs | weaning_food_softening [demography], interval_weaning_practice [demography] |  |  |  |
| 375 | named_beers | barley_beer |  | standard_measures [knowledge] |  |
| 385 | marked_wine_jars | resin_sealed_wine | stamp_seals [knowledge] / cylinder_seals [knowledge] |  |  |
| 395 | fattened_geese_ducks | animal_taming, raised_granaries |  |  |  |
| 400 | work_gang_bakeries | clay_dome_ovens, barley_beer, fixed_worker_rations [labor] |  | work_gang_overseers [institutions] |  |
| 405 | stocked_fish_ponds | fish_weirs_and_traps, river_supply_channels [infrastructure] |  |  | environment: river |
| 415 | hive_beekeeping | wild_honey_smoking, hive_sparing_honey_harvest [ecology] |  | pit_firing [production] |  |
| 425 | sesame_oil | seed_oil_pressing [production], irrigation_schedules |  |  | contact_required: True |
| 430 | stall_fattened_cattle | winter_fodder |  | leader_feast_obligations [institutions], fodder_barley |  |
| 438 | jarred_salt_fish | salting_fish_meat | river_landings [logistics] / trade_colonies [logistics] | standard_transport_jars [logistics] | environment: river/coast |
| 445 | fodder_barley | winter_fodder, ox_drawn_ard |  |  |  |
| 465 | graded_rations | fixed_worker_rations [labor], worker_ration_lists [institutions] |  |  |  |
| 475 | beam_olive_press | seed_oil_pressing [production], cutting_propagation, wedges_and_levers [infrastructure] |  |  |  |
| 485 | flavouring_herbs | kitchen_gardens, herbal_classification [health] |  |  |  |
| 495 | named_breads | clay_dome_ovens, flour_sifting |  | hive_beekeeping, dried_fruit_cakes |  |
| 505 | vinegar_pickling | brine_fermentation | resin_sealed_wine / barley_beer |  |  |
| 515 | date_palm_pollination | offshoot_date_planting |  |  | environment: dry |
| 525 | date_syrup_preserves | dried_fruit_cakes, offshoot_date_planting |  | hive_beekeeping | environment: dry |
| 540 | famine_reserves | regional_granaries, reserve_rotation_ledgers |  |  |  |
| 560 | dried_salted_cheese | pressed_cheese, salting_fish_meat |  |  |  |
| 572 | separate_grain_lines | named_beers, named_breads |  |  |  |
| 585 | fruit_tree_grafting | cutting_propagation |  | copper_carpentry_tools [production], date_palm_pollination | contact_required: True |
