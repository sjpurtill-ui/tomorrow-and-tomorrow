# Nutrition dependencies: years 600–1200

Generated with `docs/research/y600/deps/partials/nhde.json`. It uses ids from `registry_1200.json` and the 0–600 graph only. Cross-line ids show their line in brackets; `0-600` marks a cross-block id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent; precedents are soft influences, also dated at or before it. No year moves are proposed for this line.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 605 | dovecote_husbandry | fattened_geese_ducks |  | manure_field_spreading |  |
| 610 | pitched_oil_jars | standard_transport_jars [logistics, 0-600] |  | resin_sealed_wine, bitumen_sealing [infrastructure, 0-600] |  |
| 614 | cured_pork_sides | salting_fish_meat |  | smoking | resources_known: Salt |
| 620 | barley_type_choice | seed_selection, fodder_barley |  | named_soil_kinds [ecology, 0-600] |  |
| 626 | terraced_orchards | contour_terrace_reading [ecology, 0-600], cutting_propagation |  | terrace_wall_upkeep [ecology], resin_sealed_wine |  |
| 632 | yard_fowl_eggs | fattened_geese_ducks |  | dovecote_husbandry |  |
| 638 | spelt_cultivation | seed_selection, named_soil_kinds [ecology, 0-600] |  | barley_type_choice |  |
| 644 | must_syrup | resin_sealed_wine |  | date_syrup_preserves |  |
| 650 | summer_millet_catch_crop | crop_calendars, field_rest_scheduling |  | intercrop_pairing_lore |  |
| 656 | rennet_curdling | pressed_cheese |  | dried_salted_cheese |  |
| 670 | iron_ard_shares | ox_drawn_ard, bloomery_smelting [production] |  | bloom_consolidation [production] |  |
| 676 | vintage_wine_aging | marked_wine_jars |  | must_syrup |  |
| 682 | fermented_fish_sauce | brine_fermentation, jarred_salt_fish |  |  | environment: coast |
| 690 | wall_hive_apiaries | hive_beekeeping |  | mould_made_mudbricks [infrastructure, 0-600] |  |
| 700 | crop_rotation | legume_field_interplanting, field_rest_scheduling |  | soil_exhaustion_recognition, managed_fallow |  |
| 700 | dough_leavening | controlled_baking, fermentation_control |  | barley_beer, clay_dome_ovens |  |
| 704 | green_manure_crops | crop_rotation |  | manure_field_spreading |  |
| 710 | milk_flock_breeding | milking, breeding_stock_sparing [ecology, 0-600] |  | mixed_flock_balance [ecology, 0-600] |  |
| 716 | summer_pasture_dairies | transhumance [ecology, 0-600], rennet_curdling |  | seasonal_herd_matching [ecology, 0-600] |  |
| 722 | staked_vine_training | cutting_propagation, iron_farm_tools [production] |  | terraced_orchards |  |
| 728 | nut_orchards | fruit_tree_grafting |  | nut_kernel_shelling, terraced_orchards |  |
| 734 | hay_meadow_mowing | winter_fodder, iron_farm_tools [production] |  | grazing_rotation_customs [ecology, 0-600] |  |
| 740 | cured_table_olives | brine_fermentation, ash_lye_cleansers [production] |  | vinegar_pickling |  |
| 746 | capon_fattening | yard_fowl_eggs, stall_fattened_cattle |  | fattened_geese_ducks |  |
| 752 | rock_cut_silos | hermetic_grain_storage, iron_tool_rock_cutting [infrastructure] |  | layered_pit_storage |  |
| 760 | free_threshing_wheat | seed_selection, crop_rotation |  | spelt_cultivation, threshing_frames |  |
| 766 | field_ration_measures | graded_rations |  | rower_levies [labor], professional_corps [security] |  |
| 772 | mead_brewing | wall_hive_apiaries, fermentation_control |  |  |  |
| 778 | trenched_garden_beds | iron_farm_tools [production], kitchen_gardens |  | manure_field_spreading |  |
| 784 | sowing_almanac_verses | farmers_almanac [ecology, 0-600], star_rising_civil_year [knowledge, 0-600] |  | fixed_meter_epic_bards [culture] |  |
| 790 | mast_fed_swine | wood_pasture [ecology, 0-600] |  | cured_pork_sides | environment: woodland |
| 800 | grain_milling | saddle_quern_grinding, iron_stone_chisels [production] |  | dough_leavening |  |
| 806 | lever_hopper_mill | grain_milling |  | saddle_quern_grinding |  |
| 812 | olive_crushing_mill | beam_olive_press, grain_milling |  |  |  |
| 818 | town_grain_dole | famine_reserves, regional_granaries |  | town_mayors [institutions, 0-600], price_wage_schedules [institutions, 0-600] |  |
| 824 | pomace_small_wine | vintage_wine_aging |  | graded_rations |  |
| 830 | alfalfa_fodder | crop_rotation, fodder_barley |  | domesticated_mounts [logistics, 0-600] | contact_required: True |
| 838 | street_bakeries | grain_milling, dough_leavening |  | work_gang_bakeries, kiln_fired_bricks [infrastructure, 0-600] |  |
| 845 | flooded_paddy_fields | irrigation_schedules, canal_sluice_gates [infrastructure] |  |  | environment: river; contact_required: True |
| 852 | small_game_pens | animal_taming |  | stall_fattened_cattle, capon_fattening |  |
| 858 | seed_drill_funnel | iron_ard_shares, seed_cleaning |  | planting_density_adjustment |  |
| 864 | husbandry_handbooks | farmers_almanac [ecology, 0-600], authored_prose_treatises [knowledge] |  | crop_rotation, sowing_almanac_verses |  |
| 870 | shore_salting_vats | jarred_salt_fish, fermented_fish_sauce |  | crushed_pottery_plaster [infrastructure] | environment: coast; resources_known: Salt |
| 876 | dried_noodle_strips | hand_dough_forming, grain_milling |  | indirect_solar_food_drying | contact_required: True |
| 882 | named_fruit_cultivars | fruit_tree_grafting |  | nut_orchards, descriptive_natural_history [knowledge] |  |
| 888 | bean_paste_fermentation | brine_fermentation, pulse_splitting |  | fermented_fish_sauce | contact_required: True |
| 905 | hourglass_animal_mill | grain_milling, animal_mill_tending [labor] |  | lever_hopper_mill |  |
| 912 | villa_press_rooms | olive_crushing_mill, vintage_wine_aging |  | estate_bailiffs [labor], husbandry_handbooks |  |
| 918 | olive_pruning_rules | husbandry_handbooks, terraced_orchards |  |  |  |
| 924 | vine_rootstock_grafting | fruit_tree_grafting, staked_vine_training |  |  |  |
| 930 | stone_fruit_orchards | fruit_tree_grafting |  | named_fruit_cultivars | contact_required: True |
| 936 | brackish_fish_farming | stocked_fish_ponds, canal_sluice_gates [infrastructure] |  |  | environment: coast |
| 942 | oyster_bed_culture | shellfish_bed_recovery [ecology, 0-600] |  | brackish_fish_farming | environment: coast |
| 948 | enclosed_game_parks | small_game_pens, game_wardens [ecology] |  |  | environment: woodland |
| 954 | poultry_breed_selection | yard_fowl_eggs, capon_fattening |  | milk_flock_breeding |  |
| 960 | fodder_crop_fallow | crop_rotation, fodder_legume_fields [ecology] |  | alfalfa_fodder |  |
| 966 | periurban_market_gardens | trenched_garden_beds, town_dung_collectors [ecology] |  | sewage_field_irrigation [ecology] |  |
| 972 | smoke_loft_wine | vintage_wine_aging |  | smoking |  |
| 978 | granary_fumigation | pest_deterrent_storage_herbs, sulfur_fumigation [health] |  | ventilated_granaries [infrastructure, 0-600], lime_burning [production, 0-600] |  |
| 984 | stamped_loaves | street_bakeries, stamp_seals [knowledge, 0-600] |  | market_wardens [institutions] |  |
| 990 | graded_flour_bolting | grain_milling, flour_sifting |  | fine_linen_counts [production] |  |
| 996 | cased_sausages | cured_pork_sides |  | salting_fish_meat |  |
| 1012 | overshot_mill_wheels | water_mills [production], gravity_conduit_grade_control [infrastructure] |  | water_lifting_wheels [infrastructure] |  |
| 1020 | campaign_rations | field_ration_measures, cured_pork_sides |  | forward_supply_depots [logistics], nightly_marching_camps [security] |  |
| 1028 | food_qualities_lore | fluid_balance_theory [health], seasonal_regimen [health] |  |  |  |
| 1036 | paddy_fish_rearing | flooded_paddy_fields, stocked_fish_ponds |  |  | environment: river; contact_required: True |
| 1044 | honey_fruit_preserves | must_syrup, hive_beekeeping |  | dried_fruit_cakes |  |
| 1052 | ox_header_reaper | iron_farm_tools [production], spoked_wheel_assembly [logistics, 0-600] |  | villa_press_rooms |  |
| 1060 | herb_bittered_beer | named_beers, flavouring_herbs |  |  |  |
| 1068 | oat_field_crop | crop_rotation, seed_selection |  | spelt_cultivation |  |
| 1076 | rye_cultivation | crop_rotation |  | spelt_cultivation, named_soil_kinds [ecology, 0-600] |  |
| 1084 | cave_aged_cheese | rennet_curdling |  | summer_pasture_dairies |  |
| 1092 | pond_carp_rearing | stocked_fish_ponds, canal_sluice_gates [infrastructure] |  | paddy_fish_rearing | environment: river; contact_required: True |
| 1100 | coulter_plough | iron_ard_shares, iron_tyre_fitting [production] |  | breast_strap_harness [logistics], iron_farm_tools [production] |  |
| 1110 | chestnut_flour_groves | nut_orchards, grain_milling |  | vine_stake_coppice [ecology] | environment: woodland |
| 1120 | irrigated_winter_wheat | free_threshing_wheat, irrigation_schedules |  | water_lifting_wheels [infrastructure] | environment: river, dry |
| 1130 | recipe_collections | authored_prose_treatises [knowledge], named_breads |  | food_qualities_lore |  |
| 1140 | preserved_herb_salts | flavouring_herbs, salting_fish_meat |  | transcontinental_relay_trade [logistics] |  |
| 1150 | hand_crank_winnower | winnowing_practice, grain_milling |  | wooden_sheave_blocks [logistics] | contact_required: True |
| 1160 | soy_curd_pressing | bean_paste_fermentation, grain_milling |  | rennet_curdling | contact_required: True |
| 1170 | state_bread_ovens | town_grain_dole, street_bakeries | hourglass_animal_mill / water_mills [production] | bakery_mill_workforces [labor] |  |
| 1180 | double_crop_calendar | crop_calendars, irrigated_winter_wheat |  | summer_millet_catch_crop, flooded_paddy_fields | environment: river |
| 1195 | cane_sugar_crystals | must_syrup |  | transcontinental_relay_trade [logistics] | contact_required: True |

## Notes

- **Iron tools.** `iron_ard_shares` (670) requires `bloomery_smelting` (production 660) directly, because the merged `iron_farm_tools` sits at 695 (production). The nutrition alias `iron_harvest_tools` was listed at 662. Iron sickles and share tips arrived together historically. Later iron-tool items (`staked_vine_training`, `hay_meadow_mowing`, `trenched_garden_beds`, `ox_header_reaper`) require `iron_farm_tools`. Flag only: moving `iron_farm_tools` to about 665 would let `iron_ard_shares` require it. No move is proposed.
- **Milling.** `grain_milling` is the rotary quern (800). It requires `saddle_quern_grinding` and `iron_stone_chisels` (production 735) to dress the stones. Bakeries, the hopper mill, the animal mill, olive crushing, flour bolting, noodles, the crank winnower and soy curd all require it. `state_bread_ovens` needs milling at scale, through `hourglass_animal_mill` or `water_mills` (requires_any). `overshot_mill_wheels` requires `water_mills` and `gravity_conduit_grade_control` (infrastructure).
- **Rotation.** `crop_rotation` (700) is the hub for green manure, fodder crops, free-threshing wheat, oats, rye and fallow fodder. Ecology `fodder_legume_fields` (810) requires it, and `fodder_crop_fallow` (960) requires both.
- **Regional items.** Paddy rice, paddy fish, carp ponds, noodles, bean paste, soy curd, stone fruit, alfalfa, the crank winnower and cane sugar carry `contact_required`. Paddy items also carry `environment: river`.
- **Written farming.** `husbandry_handbooks` (864) requires `farmers_almanac` and `authored_prose_treatises` (knowledge 820).
