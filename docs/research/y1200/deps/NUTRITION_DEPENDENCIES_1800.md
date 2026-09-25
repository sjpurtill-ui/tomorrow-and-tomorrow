# Nutrition dependencies: years 1200–1800

Generated with `docs/research/y1200/deps/partials/nhde.json`. It uses ids from `registry_1800.json`, the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`) and the 0–600 graph only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1200–1800 id owned by Logistics, `[ecology, 600-1200]` is a 600–1200 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1205 | pork_oil_dole | state_bread_ovens [600-1200], cured_pork_sides [600-1200] |  | town_grain_dole [600-1200], pitched_oil_jars [600-1200] |  |
| 1212 | maslin_mixed_sowing | rye_cultivation [600-1200] |  | intercrop_pairing_lore [0-600], famine_reserves [0-600] |  |
| 1220 | monthly_farm_calendar | husbandry_handbooks [600-1200] |  | sowing_almanac_verses [600-1200], crop_calendars [0-600] |  |
| 1228 | grain_drying_kilns | grain_moisture_watch [0-600], clay_dome_ovens [0-600] |  | grain_malting [0-600], raised_granaries [0-600] |  |
| 1236 | walled_kitchen_gardens | kitchen_gardens [0-600], trenched_garden_beds [600-1200] |  | periurban_market_gardens [600-1200] |  |
| 1244 | straw_skep_hives | wall_hive_apiaries [600-1200] |  | hive_beekeeping [0-600] |  |
| 1252 | grain_mould_starters | fermentation_control [0-600], bean_paste_fermentation [600-1200] |  | grain_parboiling [0-600] | contact_required: True |
| 1260 | farm_encyclopedia | husbandry_handbooks [600-1200], encyclopedic_compendia [knowledge, 600-1200] |  | monthly_farm_calendar, recipe_collections [600-1200] |  |
| 1276 | cow_dairying | milk_flock_breeding [600-1200], butter_churning [0-600] |  | rennet_curdling [600-1200], hay_meadow_mowing [600-1200] |  |
| 1284 | autumn_stock_slaughter | salting_fish_meat [0-600], winter_fodder [0-600] |  | cured_pork_sides [600-1200], hay_meadow_mowing [600-1200] | resources_known: Salt |
| 1325 | pressed_tea_cakes | food_steaming_vessels [0-600], food_drying [0-600] |  | mechanical_screw_presses [production, 600-1200] | contact_required: True |
| 1345 | irrigated_cane_fields | cane_sugar_crystals [600-1200], irrigation_schedules [0-600] |  | water_lifting_wheels [infrastructure, 600-1200] | environment: dry, river; contact_required: True |
| 1360 | seaweed_manuring | seaweed_harvest_rotation [ecology, 600-1200], manure_field_spreading [0-600] |  |  | environment: coast |
| 1370 | terraced_rice_paddies | flooded_paddy_fields [600-1200], terrace_wall_upkeep [ecology, 600-1200] |  | contour_terrace_reading [ecology, 0-600] | contact_required: True |
| 1385 | teahouse_tea | pressed_tea_cakes |  | street_bakeries [600-1200], pale_hard_fired_ware [production] | contact_required: True |
| 1392 | northern_slope_vineyards | staked_vine_training [600-1200], vine_rootstock_grafting [600-1200] |  | volcanic_soil_choice [ecology, 600-1200], named_fruit_cultivars [600-1200] |  |
| 1400 | mouldboard_plough | coulter_plough [600-1200], iron_farm_tools [production, 600-1200] |  | iron_ard_shares [600-1200], forge_welding [production, 600-1200] |  |
| 1405 | hop_gardens | herb_bittered_beer [600-1200], staked_vine_training [600-1200] |  | kitchen_gardens [0-600] |  |
| 1410 | malting_floor_brewhouses | grain_malting [0-600], grain_drying_kilns |  | named_beers [0-600], villa_press_rooms [600-1200], hop_gardens |  |
| 1412 | mould_brewed_rice_wine | grain_mould_starters, flooded_paddy_fields [600-1200] |  | fermentation_control [0-600] | contact_required: True |
| 1415 | dearth_price_ceilings | price_stabilizing_granary [institutions, 600-1200], price_wage_schedules [institutions, 0-600] |  | town_grain_dole [600-1200], numbered_article_decrees [institutions] |  |
| 1430 | three_field_rotation | crop_rotation [600-1200], oat_field_crop [600-1200] |  | mouldboard_plough, fodder_crop_fallow [600-1200] |  |
| 1438 | ridge_furrow_strips | mouldboard_plough |  | named_soil_kinds [ecology, 0-600], waterlogging_recognition [ecology, 0-600] |  |
| 1445 | spring_field_legumes | three_field_rotation, legume_field_interplanting [0-600] |  | green_manure_crops [600-1200] |  |
| 1450 | citrus_orchards | fruit_tree_grafting [0-600], irrigation_schedules [0-600] |  | staged_acclimatization [ecology, 600-1200], foreign_plant_gardens [ecology, 600-1200] | contact_required: True |
| 1455 | new_garden_vegetables | walled_kitchen_gardens, staged_acclimatization [ecology, 600-1200] |  | foreign_plant_gardens [ecology, 600-1200] | contact_required: True |
| 1460 | saffron_fields | flavouring_herbs [0-600] |  | alum_mordant_dyeing [production, 0-600], kitchen_gardens [0-600] | contact_required: True |
| 1465 | dryland_rice_basins | flooded_paddy_fields [600-1200], irrigation_schedules [0-600] |  | groundwater_tunnels [infrastructure, 600-1200] | environment: dry; contact_required: True |
| 1470 | stockfish_drying | food_drying [0-600] |  | jarred_salt_fish [0-600], keeled_sailing_longships [logistics] | environment: coast |
| 1478 | spiked_harrow | ox_drawn_ard [0-600], iron_farm_tools [production, 600-1200] |  | three_field_rotation |  |
| 1482 | village_bake_ovens | clay_dome_ovens [0-600], dough_leavening [600-1200] |  | street_bakeries [600-1200], mill_suit_obligation [labor] |  |
| 1488 | paddy_chain_pumps | terraced_rice_paddies, water_lifting_wheels [infrastructure, 600-1200] |  | cog_and_lantern_gearing [production] | contact_required: True |
| 1490 | dried_fruit_trade | dried_fruit_cakes [0-600] |  | coastal_cabotage_trade [logistics], great_desert_caravans [logistics] |  |
| 1510 | early_ripening_rice | mass_seed_selection [0-600] | terraced_rice_paddies or dryland_rice_basins | double_crop_calendar [600-1200] | contact_required: True |
| 1520 | offshore_cod_fishing | stockfish_drying, keeled_sailing_longships [logistics] |  | land_finding_signs [logistics] | environment: coast |
| 1530 | soy_sauce_drawing | bean_paste_fermentation [600-1200], grain_mould_starters |  |  | contact_required: True |
| 1535 | terraced_tea_gardens | teahouse_tea, terrace_wall_upkeep [ecology, 600-1200] |  | terraced_rice_paddies | contact_required: True |
| 1545 | refined_loaf_sugar | irrigated_cane_fields, closed_moulds [production, 0-600] |  | brine_purification [production] | contact_required: True |
| 1560 | horse_ploughing | rigid_horse_collar [logistics], mouldboard_plough |  | nailed_horseshoes [logistics], whippletree_evener [logistics], oat_field_crop [600-1200] |  |
| 1580 | sugar_candied_fruit | honey_fruit_preserves [600-1200] | refined_loaf_sugar or cane_sugar_crystals [600-1200] | citrus_orchards | contact_required: True |
| 1590 | stew_pond_fisheries | stocked_fish_ponds [0-600], mill_leats [infrastructure] |  | pond_carp_rearing [600-1200], river_fish_restocking [ecology, 600-1200], devotee_communities_under_rule [culture] |  |
| 1600 | graded_bread_loaves | graded_flour_bolting [600-1200], stamped_loaves [600-1200] |  | village_bake_ovens |  |
| 1615 | coney_warrens | small_game_pens [600-1200] |  | enclosed_game_parks [600-1200], managed_heathland [ecology] |  |
| 1622 | heavy_draught_breeding | horse_ploughing, pasture_matched_breeds [ecology, 600-1200] |  | post_horse_studs [logistics, 600-1200], mounted_remount_school [security] |  |
| 1628 | dried_durum_pasta | dried_noodle_strips [600-1200], free_threshing_wheat [600-1200] |  | graded_flour_bolting [600-1200] | contact_required: True |
| 1640 | great_aisled_barns | timber_roof_trusses [infrastructure, 600-1200], three_field_rotation |  | long_span_timber_halls [infrastructure, 600-1200], plank_walled_timber_halls [infrastructure], compulsory_tithe [institutions] |  |
| 1650 | irrigated_husbandry_treatise | husbandry_handbooks [600-1200], fruit_tree_grafting [0-600] |  | irrigation_schedules [0-600], rival_tongue_translation_school [knowledge] | contact_required: True |
| 1656 | cider_perry_pressing | named_fruit_cultivars [600-1200], mechanical_screw_presses [production, 600-1200] |  | beam_olive_press [0-600] |  |
| 1662 | verjuice_sauces | vinegar_pickling [0-600], staked_vine_training [600-1200] |  | recipe_collections [600-1200] |  |
| 1665 | estate_vaccaries | cow_dairying, cave_aged_cheese [600-1200] |  | estate_steward_audits [labor] |  |
| 1675 | estate_yield_accounts | estate_survey_books [labor], plot_yield_memory [0-600] |  | annual_receipt_rolls [institutions], digit_reckoning_handbook [knowledge] |  |
| 1682 | keg_salted_butter | butter_churning [0-600], coopered_cargo_casks [logistics, 600-1200] |  | estate_vaccaries | resources_known: Salt |
| 1690 | bread_weight_assize | graded_bread_loaves, proclaimed_standard_weights [institutions, 0-600] |  | dearth_price_ceilings, market_wardens [institutions, 600-1200] |  |
| 1700 | long_aged_hard_cheese | cave_aged_cheese [600-1200], estate_vaccaries |  | rennet_curdling [600-1200] |  |
| 1703 | grafted_tree_nurseries | named_fruit_cultivars [600-1200], tree_nurseries [ecology, 600-1200] |  | fruit_tree_grafting [0-600], cider_perry_pressing |  |
| 1710 | imported_spice_blends | preserved_herb_salts [600-1200], transcontinental_relay_trade [logistics, 600-1200] |  | great_desert_caravans [logistics] | contact_required: True |
| 1715 | hopped_export_beer | hop_gardens, malting_floor_brewhouses, coopered_cargo_casks [logistics, 600-1200] |  | annual_bulk_fleets [logistics] |  |
| 1722 | distilled_spirits | chemical_distillation [knowledge] |  | alembic_distillation [production, 600-1200], vintage_wine_aging [600-1200], named_beers [0-600] |  |
| 1725 | ale_taster_licensing | named_beers [0-600], market_wardens [institutions, 600-1200] |  | bread_weight_assize |  |
| 1728 | protected_drove_routes | protected_drove_roads [ecology, 600-1200] |  | seasonal_herd_matching [ecology, 0-600], summer_shielings [ecology] |  |
| 1742 | barreled_salt_meat | cured_pork_sides [600-1200], coopered_cargo_casks [logistics, 600-1200] |  | campaign_rations [600-1200], voyage_victualling_scales [logistics] | resources_known: Salt |
| 1748 | almond_milk_fast_food | nut_orchards [600-1200], recipe_collections [600-1200] |  | devotee_communities_under_rule [culture] |  |
| 1752 | measured_court_recipes | recipe_collections [600-1200] |  | household_great_offices [institutions], sickroom_diet_books [health], imported_spice_blends |  |
| 1756 | sugar_confectionery | refined_loaf_sugar, nut_orchards [600-1200] |  | sugar_candied_fruit | contact_required: True |
| 1760 | illustrated_farm_treatise | farm_encyclopedia |  | irrigated_husbandry_treatise, automata_machine_book [knowledge], steward_husbandry_treatises [ecology] |  |
| 1762 | raised_pie_crusts | street_bakeries [600-1200] |  | cased_sausages [600-1200] |  |
| 1765 | buckwheat_cultivation | staged_acclimatization [ecology, 600-1200], named_soil_kinds [ecology, 0-600] |  | rye_cultivation [600-1200], licensed_forest_clearing [ecology] |  |
| 1770 | barrel_gutted_herring | coopered_cargo_casks [logistics, 600-1200], salting_fish_meat [0-600] |  | shore_salting_vats [600-1200], offshore_cod_fishing | environment: coast; resources_known: Salt |
| 1776 | cattle_droving | protected_drove_routes |  | day_walk_market_spacing [logistics], estate_vaccaries |  |
| 1780 | dredge_mixed_grain | oat_field_crop [600-1200], three_field_rotation |  | maslin_mixed_sowing |  |
| 1785 | town_dearth_granaries | price_stabilizing_granary [institutions, 600-1200], dearth_price_ceilings |  | great_aisled_barns, sworn_town_commune [institutions] |  |
| 1792 | smoked_red_herring | barrel_gutted_herring, smoking [0-600] |  |  | environment: coast |

## Notes

- **Plough and field system.** `coulter_plough` (1100) + production `iron_farm_tools` → `mouldboard_plough` (1400) → `ridge_furrow_strips` (1438). `crop_rotation` (700) + `oat_field_crop` → `three_field_rotation` (1430), with the mouldboard plough as a precedent. It leads to `spring_field_legumes`, `dredge_mixed_grain` and `great_aisled_barns`, and to Demography `village_nucleation` and Ecology `common_fallow_grazing_rule`.
- **Horses.** Logistics `rigid_horse_collar` (1300) + `mouldboard_plough` → `horse_ploughing` (1560) → `heavy_draught_breeding` (1622). Logistics `nailed_horseshoes` and `whippletree_evener` are precedents.
- **Brewing and distilling.** `herb_bittered_beer` → `hop_gardens` (1405). `grain_drying_kilns` (1228) → `malting_floor_brewhouses` (1410). With logistics `coopered_cargo_casks` (600–1200) they give `hopped_export_beer` (1715). `distilled_spirits` (1722) requires knowledge `chemical_distillation` (1407).
- **Sugar.** `cane_sugar_crystals` (1195) → `irrigated_cane_fields` → `refined_loaf_sugar`. All three are regional (`contact_required`). `sugar_candied_fruit` and `sugar_confectionery` also carry `contact_required`, because sugar reaches a non-cane civilization only by trade.
- **Fish and meat for keeping.** `food_drying` → `stockfish_drying` (1470), then with logistics `keeled_sailing_longships` → `offshore_cod_fishing`. `coopered_cargo_casks` gates `keg_salted_butter`, `barreled_salt_meat` and `barrel_gutted_herring`, which leads to `smoked_red_herring`. Salt items carry `resources_known: Salt`.
- **Regulated bread and dearth.** `price_stabilizing_granary` + `price_wage_schedules` → `dearth_price_ceilings` (1415) → `town_dearth_granaries` (1785). `graded_flour_bolting` + `stamped_loaves` → `graded_bread_loaves` → `bread_weight_assize`, which is a precedent of `ale_taster_licensing`.
- **Regional crops** carry `contact_required`, following the 600–1200 practice. These are rice terraces, tea, mould ferments, citrus, saffron, durum pasta and the irrigated-husbandry treatise. `dryland_rice_basins` also needs `environment: dry`.
