# Nutrition dependencies: years 1800–2400

Generated from `docs/research/y1800/deps/partials/nhde.json`. It uses ids from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`), the 0–600 graph and the game's baked blocks only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1800–2400 id owned by Logistics, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two 1800–2400 items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. `contact_required` is reserved in this block for items that need ocean contact through Logistics `transoceanic_contact_voyages` (1912), directly or through a contact-gated parent. (regional) items are gated by `environment` or inherit a regional parent from 1200–1800, which already carries `contact_required`. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

**87 entries, 155 hard edges, 177 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1808 | post_mortality_meat_diet | cattle_droving [1200-1800], deserted_village_pasture [demography, 1200-1800] |  | barreled_salt_meat [1200-1800], bread_weight_assize [1200-1800] |  |
| 1818 | estate_fishpond_chains | stew_pond_fisheries [1200-1800], mill_leats [infrastructure, 1200-1800] |  | pond_carp_rearing [600-1200], river_fish_restocking [ecology, 600-1200] |  |
| 1822 | rice_wheat_double_crop | double_crop_calendar [600-1200], early_ripening_rice [1200-1800] |  | irrigated_winter_wheat [600-1200], terraced_rice_paddies [1200-1800] | environment: river |
| 1828 | town_hopped_brewhouses | hopped_export_beer [1200-1800], malting_floor_brewhouses [1200-1800] |  | ale_taster_licensing [1200-1800], coopered_cargo_casks [logistics, 600-1200] |  |
| 1835 | herring_buss_fleets | barrel_gutted_herring [1200-1800], two_masted_round_ships [logistics] |  | smoked_red_herring [1200-1800], catch_share_crews [labor, 1200-1800] | environment: coast; resources_known: Salt |
| 1840 | famine_food_herbal | illustrated_herbals [health, 1200-1800] |  | famine_reserves [0-600], town_dearth_granaries [1200-1800], edible_resource_recognition [0-600] |  |
| 1855 | sworn_cask_gaugers | coopered_cargo_casks [logistics, 600-1200], cask_tonnage_rating [logistics, 1200-1800] |  | ale_taster_licensing [1200-1800], market_wardens [institutions, 600-1200] |  |
| 1862 | grain_magistracy | town_dearth_granaries [1200-1800], dearth_price_ceilings [1200-1800] |  | bread_mouth_census [demography, 1200-1800], municipal_exchange_bank [institutions] |  |
| 1870 | marsh_fattened_cattle | cattle_droving [1200-1800] |  | embanked_salt_meadows [ecology, 600-1200], protected_drove_routes [1200-1800], post_mortality_meat_diet |  |
| 1878 | island_cane_plantations | irrigated_cane_fields [1200-1800], roller_cotton_gin [production, 1200-1800] |  | refined_loaf_sugar [1200-1800], fortified_trading_posts [logistics] | environment: coast |
| 1882 | cheese_weigh_houses | public_weighhouses [logistics, 1200-1800], long_aged_hard_cheese [1200-1800] |  | keg_salted_butter [1200-1800], market_wardens [institutions, 600-1200] |  |
| 1890 | sworn_fish_packers | barrel_gutted_herring [1200-1800], sworn_cask_gaugers |  | herring_buss_fleets, spoiled_food_condemnation [health, 1200-1800] | environment: coast |
| 1896 | printed_cookery_books | measured_court_recipes [1200-1800], screw_press_printing [knowledge] |  | town_printing_houses [knowledge], recipe_collections [600-1200] |  |
| 1905 | printed_farm_manuals | illustrated_farm_treatise [1200-1800], town_printing_houses [knowledge] |  | farm_encyclopedia [1200-1800], monthly_farm_calendar [1200-1800] |  |
| 1915 | maize_garden_trials | transoceanic_contact_voyages [logistics] |  | new_garden_vegetables [1200-1800], walled_kitchen_gardens [1200-1800] | contact_required: True |
| 1920 | hop_drying_kilns | hop_gardens [1200-1800], grain_drying_kilns [1200-1800] |  | town_hopped_brewhouses |  |
| 1925 | distant_bank_salt_cod | offshore_cod_fishing [1200-1800], ocean_carrack [logistics] |  | latitude_sailing [logistics], barrel_gutted_herring [1200-1800] | environment: coast; resources_known: Salt |
| 1928 | chili_pepper_spread | transoceanic_contact_voyages [logistics] |  | imported_spice_blends [1200-1800], maize_garden_trials | contact_required: True |
| 1932 | sugar_fruit_pastes | sugar_candied_fruit [1200-1800], refined_loaf_sugar [1200-1800] |  | sugar_confectionery [1200-1800], honey_fruit_preserves [600-1200] |  |
| 1936 | farmyard_turkeys | transoceanic_contact_voyages [logistics] |  | poultry_breed_selection [600-1200] | contact_required: True |
| 1948 | new_land_beans_squash | maize_garden_trials |  | new_garden_vegetables [1200-1800], legume_field_interplanting [0-600] | contact_required: True |
| 1962 | coffee_houses | transoceanic_contact_voyages [logistics] |  | teahouse_tea [1200-1800], street_bakeries [600-1200], imported_spice_blends [1200-1800] | contact_required: True |
| 1966 | mulberry_dike_fishponds | sericulture_reeling [production, 1200-1800], stocked_fish_ponds [0-600] |  | paddy_fish_rearing [600-1200], estate_fishpond_chains | environment: river |
| 1970 | maize_field_crop | maize_garden_trials |  | new_land_beans_squash, summer_millet_catch_crop [600-1200] | contact_required: True |
| 1975 | potato_garden_curiosity | transoceanic_contact_voyages [logistics] |  | walled_kitchen_gardens [1200-1800], root_cellars [0-600] | contact_required: True |
| 1980 | hill_sweet_potato_maize | maize_field_crop |  | cross_slope_ploughing [ecology, 600-1200], potato_garden_curiosity | contact_required: True |
| 1985 | cassava_cultivation | transoceanic_contact_voyages [logistics], root_grating_dewatering [0-600] |  | starch_washing_separation [0-600], maize_garden_trials | contact_required: True |
| 1990 | convertible_husbandry | three_field_rotation [1200-1800], pasture_reseeding [ecology, 600-1200] |  | hay_meadow_management [ecology, 600-1200], fodder_crop_fallow [600-1200], estate_yield_accounts [1200-1800] |  |
| 1994 | bean_cake_fertilizer | seed_oil_pressing [production, 0-600], soy_curd_pressing [600-1200] |  | manure_field_spreading [0-600], bean_paste_fermentation [600-1200] |  |
| 1998 | hotbed_forcing | walled_kitchen_gardens [1200-1800], spun_crown_panes [production, 1200-1800] |  | periurban_market_gardens [600-1200], manure_field_spreading [0-600] |  |
| 2010 | groundnut_oil_crop | transoceanic_contact_voyages [logistics], seed_oil_pressing [production, 0-600] |  | new_land_beans_squash | contact_required: True |
| 2012 | court_chocolate_drink | transoceanic_contact_voyages [logistics], refined_loaf_sugar [1200-1800] |  | coffee_houses, measured_court_recipes [1200-1800] | contact_required: True |
| 2018 | lowland_export_dairying | estate_vaccaries [1200-1800], drainage_windmills [infrastructure] |  | cheese_weigh_houses, keg_salted_butter [1200-1800], long_aged_hard_cheese [1200-1800] |  |
| 2028 | shipped_tea_trade | transoceanic_contact_voyages [logistics], company_merchant_fleets [logistics] |  | teahouse_tea [1200-1800], coffee_houses | contact_required: True |
| 2036 | printed_grain_prices | grain_magistracy, printed_weekly_news [knowledge] |  | printed_broadsides [knowledge], share_exchange_bourse [institutions] |  |
| 2042 | town_luxury_vegetables | periurban_market_gardens [600-1200], hotbed_forcing |  | new_garden_vegetables [1200-1800], walled_kitchen_gardens [1200-1800] |  |
| 2050 | cottage_potato_patches | potato_garden_curiosity |  | root_cellars [0-600], hill_sweet_potato_maize | contact_required: True |
| 2064 | bottled_strong_cider | cider_perry_pressing [1200-1800], dark_bottle_glass [production] |  | coal_fired_glass_furnace [production] |  |
| 2072 | clover_ley_fodder | spring_field_legumes [1200-1800], convertible_husbandry |  | fodder_legume_fields [ecology, 600-1200], alfalfa_fodder [600-1200], green_manure_crops [600-1200] |  |
| 2086 | seedsmen_named_varieties | named_fruit_cultivars [600-1200], printed_farm_manuals |  | grafted_tree_nurseries [1200-1800], town_luxury_vegetables |  |
| 2092 | field_turnips | winter_fodder [0-600], convertible_husbandry |  | clover_ley_fodder, new_garden_vegetables [1200-1800], walled_kitchen_gardens [1200-1800] |  |
| 2104 | molasses_rum | distilled_spirits [1200-1800], island_cane_plantations |  | sugar_loaf_refining [production] | contact_required: True |
| 2110 | estate_ice_houses | root_cellars [0-600], pitched_brick_vaults [infrastructure, 0-600] |  | frozen_river_winters [ecology], channelled_garden_courts [infrastructure, 1200-1800] |  |
| 2116 | sainfoin_lucerne_hay | alfalfa_fodder [600-1200], clover_ley_fodder |  | liming_sour_soils [ecology, 600-1200], thin_soil_grassland [ecology, 600-1200] |  |
| 2124 | brewers_yeast_bread | town_hopped_brewhouses, dough_leavening [600-1200] |  | village_bake_ovens [1200-1800], graded_bread_loaves [1200-1800] |  |
| 2136 | juniper_grain_spirit | distilled_spirits [1200-1800], malting_floor_brewhouses [1200-1800] |  | distilled_herb_waters [health, 1200-1800] |  |
| 2146 | stall_winter_fattening | stall_fattened_cattle [0-600], field_turnips |  | marsh_fattened_cattle, clover_ley_fodder |  |
| 2158 | steam_bone_digester | air_spring_law [knowledge], vacuum_experiments [knowledge] |  | food_steaming_vessels [0-600], cast_iron_vessels [production, 600-1200] |  |
| 2170 | grain_export_bounties | dearth_price_ceilings [1200-1800], printed_grain_prices |  | mercantile_trade_council [institutions], salt_and_drink_excise [institutions] |  |
| 2176 | fortified_voyage_wines | distilled_spirits [1200-1800], vintage_wine_aging [600-1200] |  | ocean_victualling [logistics], coopered_cargo_casks [logistics, 600-1200] |  |
| 2182 | tomato_sauce_cookery | transoceanic_contact_voyages [logistics], printed_cookery_books |  | verjuice_sauces [1200-1800], new_land_beans_squash | contact_required: True |
| 2184 | sown_ryegrass_leys | clover_ley_fodder |  | pasture_reseeding [ecology, 600-1200], seedsmen_named_varieties |  |
| 2190 | bottle_sparkling_wine | dark_bottle_glass [production], vintage_wine_aging [600-1200] |  | bottled_strong_cider |  |
| 2214 | coke_dried_pale_malt | malting_floor_brewhouses [1200-1800], coal_grading [production] |  | grain_drying_kilns [1200-1800], sea_coal_substitution [ecology, 1200-1800] | resources_known: Coal |
| 2222 | coffee_plantations | coffee_houses, plantation_gang_labor [labor] |  | island_cane_plantations, overseas_settler_colonies [demography] | contact_required: True |
| 2232 | row_spacing_trials | estate_yield_accounts [1200-1800], standard_measures [knowledge, 0-600] |  | chartered_experimental_society [knowledge], laboratory_notebooks [knowledge], convertible_husbandry |  |
| 2238 | field_potato_crop | cottage_potato_patches |  | convertible_husbandry, ridge_furrow_strips [1200-1800] | contact_required: True |
| 2244 | porter_vat_brewing | town_hopped_brewhouses |  | coke_dried_pale_malt, coopered_cargo_casks [logistics, 600-1200] |  |
| 2252 | seed_drill | seed_drill_funnel [600-1200], row_spacing_trials |  | spiked_harrow [1200-1800], printed_farm_manuals, iron_farm_tools [production, 600-1200] |  |
| 2260 | light_swing_plough | mouldboard_plough [1200-1800], horse_ploughing [1200-1800] |  | iron_plate_hammer_mills [production], heavy_draught_breeding [1200-1800] |  |
| 2266 | horse_hoe_tillage | seed_drill, horse_ploughing [1200-1800] |  | light_swing_plough |  |
| 2276 | household_sugared_tea | shipped_tea_trade, sugar_loaf_refining [production] |  | pale_hard_fired_ware [production, 1200-1800] | contact_required: True |
| 2290 | agricultural_improvement_societies | chartered_experimental_society [knowledge], printed_farm_manuals |  | public_experiment_lectures [knowledge], fraternal_lodges [culture], row_spacing_trials |  |
| 2296 | sowing_depth_trials | experimental_controls [knowledge], row_spacing_trials |  | seed_drill |  |
| 2298 | beet_sugar_discovery | chemical_distillation [knowledge, 1200-1800], two_lens_tube_microscope [knowledge] |  | sugar_loaf_refining [production], laboratory_notebooks [knowledge] |  |
| 2300 | field_carrot_cabbage_fodder | field_turnips |  | stall_winter_fattening, town_luxury_vegetables |  |
| 2302 | tidal_rice_fields | flooded_paddy_fields [600-1200], sluiced_polders [ecology, 1200-1800] |  | plantation_gang_labor [labor], dryland_rice_basins [1200-1800] | environment: coast, river |
| 2306 | grain_bellows_ventilation | ventilated_granaries [infrastructure, 0-600], wooden_tub_bellows [production] |  | air_spring_law [knowledge], granary_fumigation [600-1200] |  |
| 2310 | spirit_licensing_duties | salt_and_drink_excise [institutions], juniper_grain_spirit |  | ale_taster_licensing [1200-1800] |  |
| 2314 | potato_planting_edict | field_potato_crop |  | police_ordinance_science [institutions], cameral_domain_chambers [institutions] | contact_required: True |
| 2320 | seedbed_firming | seed_drill |  | sowing_depth_trials, spiked_harrow [1200-1800] |  |
| 2324 | four_course_rotation | three_field_rotation [1200-1800], clover_ley_fodder, field_turnips |  | convertible_husbandry, enclosure_by_agreement [ecology], horse_hoe_tillage, sainfoin_lucerne_hay |  |
| 2328 | pedigree_stock_breeding | heavy_draught_breeding [1200-1800], stall_winter_fattening |  | pasture_matched_breeds [ecology, 600-1200], poultry_breed_selection [600-1200], enclosure_by_agreement [ecology], draft_horse_breeding [logistics] |  |
| 2340 | voyage_keeping_foods | brine_fermentation [0-600], ocean_victualling [logistics] |  | steam_bone_digester, victualling_yards [logistics], lemon_juice_scurvy [health] |  |
| 2344 | printed_farm_journals | printed_farm_manuals, agricultural_improvement_societies |  | periodical_essay_sheets [culture], daily_printed_newspaper [knowledge] |  |
| 2348 | free_grain_trade_edict | free_grain_trade_doctrine [institutions] |  | grain_export_bounties, printed_grain_prices |  |
| 2352 | fodder_cutting_machines | field_turnips, stall_winter_fattening |  | sand_flask_casting [production], gear_cutting_engine [production] |  |
| 2358 | brewing_thermometer | porter_vat_brewing, precision_thermometry [knowledge] |  | laboratory_notebooks [knowledge] |  |
| 2362 | yellow_turnip_mangold_roots | field_turnips |  | seedsmen_named_varieties, four_course_rotation |  |
| 2364 | crushed_bone_manure | manure_field_spreading [0-600], edge_runner_mills [production, 1200-1800] |  | steam_bone_digester, four_course_rotation |  |
| 2368 | brewers_saccharometer | brewing_thermometer, hydrostatic_pressure [knowledge, 600-1200] |  | experimental_controls [knowledge] |  |
| 2372 | threshing_machine | hand_crank_winnower [600-1200], gear_cutting_engine [production] |  | horse_whim_hoists [production, 1200-1800], tested_waterwheel_efficiency [production], fodder_cutting_machines |  |
| 2376 | cast_iron_plough_parts | light_swing_plough, sand_flask_casting [production] |  | coke_firing [production] |  |
| 2381 | public_soup_kitchens | town_grain_dole [600-1200], parish_poor_law [labor] |  | grain_magistracy, field_potato_crop, subscription_hospitals [health] |  |
| 2386 | agriculture_board_surveys | agricultural_improvement_societies, cadastral_tax_survey [institutions] |  | printed_farm_journals, trade_and_colonies_board [institutions] |  |
| 2390 | closed_cooking_range | iron_flue_stoves [infrastructure] |  | sand_flask_casting [production], coke_firing [production] |  |
| 2395 | sugar_beet_selection | beet_sugar_discovery, mass_seed_selection [0-600] |  | seedsmen_named_varieties, yellow_turnip_mangold_roots |  |

## Notes

- **Contact crops and drinks.** Maize, potato, chili, turkeys, beans and squash, cassava, groundnuts, coffee, cacao, tea and tomatoes all require Logistics `transoceanic_contact_voyages` (1912), directly or through a contact-gated parent, and carry `contact_required`. `maize_garden_trials` → `maize_field_crop` → `hill_sweet_potato_maize`; `potato_garden_curiosity` → `cottage_potato_patches` → `field_potato_crop` → `potato_planting_edict`; `coffee_houses` → `coffee_plantations`; `shipped_tea_trade` (also Logistics `company_merchant_fleets`) → `household_sugared_tea`. `island_cane_plantations` (1878) comes before contact and extends the regional 1200–1800 cane chain; `molasses_rum` is contact-gated.
- **Fodder revolution.** `three_field_rotation` (1200–1800) + ecology `pasture_reseeding` → `convertible_husbandry` (1990) → `clover_ley_fodder` (2072) and `field_turnips` (2092). Clover and turnips are both hard prerequisites of `four_course_rotation` (2324), with Ecology `enclosure_by_agreement` and `horse_hoe_tillage` as precedents. Clover leads on to `sainfoin_lucerne_hay` and `sown_ryegrass_leys`; turnips lead to `stall_winter_fattening`, `field_carrot_cabbage_fodder`, `yellow_turnip_mangold_roots` and `fodder_cutting_machines`.
- **Tillage.** `row_spacing_trials` (2232) + 600–1200 `seed_drill_funnel` → `seed_drill` (2252) → `horse_hoe_tillage` (2266), which also needs `horse_ploughing`. The drill leads to `seedbed_firming`. `sowing_depth_trials` (2296) needs Knowledge `experimental_controls` (2294). `light_swing_plough` → `cast_iron_plough_parts` (Production `sand_flask_casting`). `threshing_machine` needs `hand_crank_winnower` and Production `gear_cutting_engine`.
- **Drink.** `hopped_export_beer` + `malting_floor_brewhouses` → `town_hopped_brewhouses` → `porter_vat_brewing` → `brewing_thermometer` (Knowledge `precision_thermometry`) → `brewers_saccharometer`. Production `dark_bottle_glass` gates bottled cider and sparkling wine. Production `coal_grading` gates `coke_dried_pale_malt` (`resources_known: Coal`). `juniper_grain_spirit` + Institutions `salt_and_drink_excise` → `spirit_licensing_duties`.
- **Public food and farm writing.** `town_dearth_granaries` → `grain_magistracy` → `printed_grain_prices` (Knowledge `printed_weekly_news`) → `grain_export_bounties`; Institutions `free_grain_trade_doctrine` → `free_grain_trade_edict`. `printed_farm_manuals` (Knowledge `town_printing_houses`) + Knowledge `chartered_experimental_society` → `agricultural_improvement_societies` → `printed_farm_journals` and, with Institutions `cadastral_tax_survey`, `agriculture_board_surveys`. `public_soup_kitchens` needs Labor `parish_poor_law`.
- **Sugar beet.** `beet_sugar_discovery` needs Knowledge `chemical_distillation` and `two_lens_tube_microscope`; `sugar_beet_selection` adds `mass_seed_selection`.
- **Regional items.** `rice_wheat_double_crop` (river; parent `early_ripening_rice` is regional), `mulberry_dike_fishponds` (river), `tidal_rice_fields` (coast or river) and `bean_cake_fertilizer` (soy parents). Fish items carry `environment: coast`, and the salt-cured ones `resources_known: Salt`.

## Cross-line parents in 1800–2400 (mapped by other agents)

- **Culture:** `fraternal_lodges` (2234), `periodical_essay_sheets` (2222)
- **Demography:** `overseas_settler_colonies` (1926)
- **Ecology:** `enclosure_by_agreement` (1935), `frozen_river_winters` (1996)
- **Health:** `lemon_juice_scurvy` (2006), `subscription_hospitals` (2250)
- **Infrastructure:** `drainage_windmills` (1848), `iron_flue_stoves` (2284)
- **Institutions:** `cadastral_tax_survey` (2236), `cameral_domain_chambers` (2080), `free_grain_trade_doctrine` (2316), `mercantile_trade_council` (2128), `municipal_exchange_bank` (1834), `police_ordinance_science` (2260), `salt_and_drink_excise` (1852), `share_exchange_bourse` (2004), `trade_and_colonies_board` (2192)
- **Knowledge:** `air_spring_law` (2124), `chartered_experimental_society` (2120), `daily_printed_newspaper` (2204), `experimental_controls` (2294), `laboratory_notebooks` (2126), `precision_thermometry` (2228), `printed_broadsides` (1890), `printed_weekly_news` (2010), `public_experiment_lectures` (2238), `screw_press_printing` (1867), `town_printing_houses` (1892), `two_lens_tube_microscope` (1993), `vacuum_experiments` (2108)
- **Labor:** `parish_poor_law` (2002), `plantation_gang_labor` (1950)
- **Logistics:** `company_merchant_fleets` (2006), `draft_horse_breeding` (2212), `fortified_trading_posts` (1872), `latitude_sailing` (1905), `ocean_carrack` (1883), `ocean_victualling` (1908), `transoceanic_contact_voyages` (1912), `two_masted_round_ships` (1833), `victualling_yards` (2050)
- **Production:** `coal_fired_glass_furnace` (2022), `coal_grading` (2194), `coke_firing` (2220), `dark_bottle_glass` (2062), `gear_cutting_engine` (2138), `iron_plate_hammer_mills` (1906), `sand_flask_casting` (2214), `sugar_loaf_refining` (1971), `tested_waterwheel_efficiency` (2319), `wooden_tub_bellows` (2032)
