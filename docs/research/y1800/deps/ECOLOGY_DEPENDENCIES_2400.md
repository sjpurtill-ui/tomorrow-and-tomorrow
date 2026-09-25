# Ecology dependencies: years 1800–2400

Generated from `docs/research/y1800/deps/partials/nhde.json`. It uses ids from `registry_2400.json`, the 1200–1800 graph (`docs/research/y1200/deps/graph_1800.json`), the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`), the 0–600 graph and the game's baked blocks only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1800–2400 id owned by Logistics, `[ecology, 1200-1800]` is a 1200–1800 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two 1800–2400 items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. `contact_required` is reserved in this block for items that need ocean contact through Logistics `transoceanic_contact_voyages` (1912), directly or through a contact-gated parent. (regional) items are gated by `environment` or inherit a regional parent from 1200–1800, which already carries `contact_required`. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

**89 entries, 117 hard edges, 130 precedent edges, 0 requires_any groups.**

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1808 | great_drowning_flood_marks | storm_surge_records [1200-1800] |  | dike_boards [1200-1800], drowned_land_abandonment [1200-1800] | environment: coast |
| 1814 | post_plague_woodland | abandoned_land_regrowth [1200-1800] |  | deserted_village_pasture [demography, 1200-1800], woodbank_enclosures [1200-1800] |  |
| 1820 | pine_seed_row_sowing | conifer_seed_sowing [1200-1800] |  | tree_nurseries [600-1200] | environment: woodland |
| 1826 | salmon_conservators | river_fishery_wardens [1200-1800] |  | weir_fish_gaps [1200-1800], net_mesh_limits [600-1200] | environment: river |
| 1832 | leased_fuel_blocks | kiln_fuel_licences [1200-1800] |  | marked_tree_sales [1200-1800], coppice_with_standards [1200-1800] | environment: woodland |
| 1838 | yearly_felling_blocks | felling_rotation_ordinance [1200-1800] |  | leased_fuel_blocks |  |
| 1852 | herring_shoal_shift | barrel_gutted_herring [nutrition, 1200-1800] |  | herring_buss_fleets [nutrition] | environment: coast |
| 1858 | sheep_enclosure_depopulation | deserted_village_pasture [demography, 1200-1800], quickset_hedges [1200-1800] |  | wool_flock_overgrazing [1200-1800] |  |
| 1864 | cold_margin_abandonment | crop_limit_shift_watch [1200-1800] |  | marginal_land_retreat [1200-1800] |  |
| 1870 | replant_on_cut_licence | leased_fuel_blocks |  | tree_nurseries [600-1200], conifer_seed_sowing [1200-1800] |  |
| 1876 | arsenal_oak_reserves | naval_timber_reserves [600-1200], marked_tree_sales [1200-1800] |  | ordnance_office [security], forest_law_courts [1200-1800] | environment: woodland |
| 1882 | smelter_fume_blight | windy_hill_smelting_hearths [1200-1800] |  | mine_water_complaints [1200-1800] |  |
| 1888 | nitre_earth_exhaustion | nitre_earth_leaching [1200-1800] |  | potash_saltpetre_works [production], nitrate_cultivation [1200-1800] |  |
| 1894 | game_damage_compensation | paled_deer_parks [1200-1800] |  | warren_escape_liability [1200-1800] |  |
| 1900 | illegal_weir_removal | weir_fish_gaps [1200-1800], salmon_conservators |  | mill_dam_height_limits [1200-1800] | environment: river |
| 1910 | tillage_protection_laws | sheep_enclosure_depopulation |  | deserted_village_pasture [demography, 1200-1800], dearth_price_ceilings [nutrition, 1200-1800] |  |
| 1916 | wolf_extirpation | wolf_bounties [1200-1800] |  | hand_gun_tubes [security], post_plague_woodland |  |
| 1918 | mine_tailings_silting | mine_water_complaints [1200-1800] |  | valley_sediment_burial [1200-1800], liquation_silver_parting [production] | resources_known: Silver Ore |
| 1926 | home_fur_exhaustion | fur_beast_depletion [1200-1800] |  | wildlife_return_watch [1200-1800] |  |
| 1935 | enclosure_by_agreement | stinted_commons [1200-1800], quickset_hedges [1200-1800] |  | sheep_enclosure_depopulation, tillage_protection_laws, estate_survey_books [labor, 1200-1800] |  |
| 1942 | contact_species_exchange | introduced_weed_watch [1200-1800], transoceanic_contact_voyages [logistics] |  | maize_garden_trials [nutrition] | contact_required: True |
| 1948 | dune_grass_laws | drifting_sand_burial [1200-1800] |  | great_drowning_flood_marks | environment: coast |
| 1954 | pressed_plant_herbaria | illustrated_herbals [health, 1200-1800] |  | from_life_printed_herbals [health], herbal_classification [health, 0-600] |  |
| 1960 | comparative_anatomy | dissection_anatomy_atlas [health], herbal_classification [health, 0-600] |  | bird_observation_treatise [1200-1800], pressed_plant_herbaria |  |
| 1966 | mercury_amalgam_poisoning | mercury_ore_amalgamation [production] |  | mine_water_complaints [1200-1800], mercury_ointment [health, 1200-1800] |  |
| 1972 | statute_vermin_bounties | wolf_bounties [1200-1800] |  | locust_bounty_campaigns [1200-1800] |  |
| 1978 | goat_woodland_bans | forest_law_courts [1200-1800] |  | coppice_with_standards [1200-1800], yearly_felling_blocks |  |
| 1984 | island_forest_felling | contact_species_exchange, island_cane_plantations [nutrition] |  | sugar_loaf_refining [production] | contact_required: True |
| 1990 | commercial_peat_cutting | peat_fuel_cutting [1200-1800] |  | sea_coal_substitution [1200-1800], drainage_windmills [infrastructure] |  |
| 1996 | frozen_river_winters | crop_limit_shift_watch [1200-1800] |  | cold_margin_abandonment, daily_weather_diaries [1200-1800] | environment: river |
| 2004 | far_land_specimen_voyages | pressed_plant_herbaria, transoceanic_contact_voyages [logistics] |  | foreign_plant_gardens [600-1200], faculty_physic_garden [health] | contact_required: True |
| 2012 | smelter_damage_payments | smelter_fume_blight |  | equity_conscience_court [institutions] |  |
| 2020 | private_nuisance_law | coal_smoke_limits [1200-1800], pleaded_case_reports [institutions] |  | smelter_damage_payments |  |
| 2042 | whale_ground_depletion | ocean_galleon [logistics] |  | seabird_colony_shares [1200-1800], distant_bank_salt_cod [nutrition], company_merchant_fleets [logistics] | environment: coast |
| 2050 | floated_water_meadows | hay_meadow_management [600-1200], mill_leats [infrastructure, 1200-1800] |  | sluiced_polders [1200-1800], convertible_husbandry [nutrition] | environment: river |
| 2056 | last_wild_cattle | relict_wild_cattle_reserves [1200-1800] |  | paled_deer_parks [1200-1800] |  |
| 2064 | fur_frontier_depletion | home_fur_exhaustion, overseas_settler_colonies [demography] |  | fortified_trading_posts [logistics] | contact_required: True |
| 2072 | plantation_soil_exhaustion | island_forest_felling |  | plantation_gang_labor [labor], soil_exhaustion_recognition [nutrition, 0-600] | contact_required: True |
| 2080 | glacier_farm_remission | glacier_advance_records [1200-1800] |  | cold_margin_abandonment |  |
| 2100 | timber_import_dependence | arsenal_oak_reserves |  | fluyt_bulk_carrier [logistics] |  |
| 2106 | instrumental_weather_registers | daily_weather_diaries [1200-1800], mercury_barometer [knowledge] |  | district_rain_gauges [knowledge, 1200-1800] |  |
| 2114 | oak_planting_treatise | arsenal_oak_reserves |  | timber_import_dependence, printed_farm_manuals [nutrition] |  |
| 2122 | coal_smoke_treatise | coal_smoke_limits [1200-1800] |  | private_nuisance_law, weekly_mortality_bills [demography] |  |
| 2128 | fossil_organic_origin | comparative_anatomy |  | quarry_reading [0-600], two_lens_tube_microscope [knowledge] |  |
| 2134 | island_extinction_record | contact_species_exchange |  | island_forest_felling | contact_required: True |
| 2138 | realm_forest_ordinance | forest_law_courts [1200-1800], arsenal_oak_reserves |  | cameral_domain_chambers [institutions], yearly_felling_blocks |  |
| 2140 | oyster_spat_relaying | shellfish_closed_seasons [1200-1800], oyster_bed_culture [nutrition, 600-1200] |  |  | environment: coast |
| 2142 | relative_stratigraphy | fossil_organic_origin, quarry_reading [0-600] |  | route_memory [knowledge, 0-600], powder_rock_blasting [production] |  |
| 2146 | property_game_qualification | reserved_hunting_rights [1200-1800] |  | game_damage_compensation |  |
| 2152 | covered_field_drains | ridge_furrow_strips [nutrition, 1200-1800] |  | convertible_husbandry [nutrition] |  |
| 2158 | habitat_observation_records | pressed_plant_herbaria, seasonal_patterns [0-600] |  | daily_weather_diaries [1200-1800], herbal_classification [health, 0-600] |  |
| 2164 | peat_shrinkage_pumping | drained_land_subsidence [1200-1800], fen_drainage_cuts [infrastructure] |  | drainage_windmills [infrastructure] |  |
| 2172 | trade_wind_map | ocean_wind_circuit [logistics] |  | instrumental_weather_registers, ship_logbooks [logistics] |  |
| 2180 | tall_chimney_orders | coal_smoke_treatise |  | multi_flue_chimney_stacks [infrastructure] |  |
| 2188 | pannage_decline | mast_count_pannage [1200-1800] |  | enclosure_by_agreement |  |
| 2196 | storm_path_reconstruction | instrumental_weather_registers |  | printed_weekly_news [knowledge], public_letter_post [logistics] |  |
| 2210 | game_bird_close_seasons | property_game_qualification |  | shellfish_closed_seasons [1200-1800] |  |
| 2218 | sustained_yield_forestry | realm_forest_ordinance |  | yearly_felling_blocks, oak_planting_treatise |  |
| 2226 | cattle_plague_slaughter_orders | contact_contagion [health, 1200-1800], cattle_droving [nutrition, 1200-1800] |  | standing_health_magistracy [health], walled_out_slaughter [health, 1200-1800] |  |
| 2234 | cattle_health_passes | cattle_plague_slaughter_orders, health_passes [health] |  |  |  |
| 2242 | hedgerow_timber_planting | enclosure_by_agreement |  | oak_planting_treatise |  |
| 2250 | brown_rat_invasion | company_merchant_fleets [logistics] |  | enclosed_wet_docks [infrastructure] |  |
| 2256 | plant_transpiration_measurement | chartered_experimental_society [knowledge], habitat_observation_records |  | laboratory_notebooks [knowledge], science_of_weights [knowledge, 1200-1800] |  |
| 2264 | caterpillar_nest_ordinance | police_ordinance_science [institutions] |  | locust_bounty_campaigns [1200-1800] |  |
| 2270 | biological_classification | comparative_anatomy, habitat_observation_records |  | herbal_classification [health, 0-600], pressed_plant_herbaria |  |
| 2276 | tree_ring_notes | storm_path_reconstruction |  | yearly_felling_blocks |  |
| 2280 | pheasant_preserves | statute_vermin_bounties, property_game_qualification |  |  |  |
| 2282 | dye_works_nuisance | private_nuisance_law |  | indigo_vat_dyeing [production] |  |
| 2288 | tree_volume_tables | sustained_yield_forestry |  | integral_calculus [knowledge], triangulation_survey [knowledge] |  |
| 2294 | economy_of_nature | biological_classification |  | habitat_observation_records |  |
| 2300 | biological_reference_collections | biological_classification, far_land_specimen_voyages |  | public_collection_museum [culture] |  |
| 2306 | phenology_records | habitat_observation_records |  | instrumental_weather_registers |  |
| 2312 | dune_pine_plantations | dune_grass_laws, pine_seed_row_sowing |  |  | environment: coast |
| 2316 | firebreak_rides | pine_seed_row_sowing |  | sustained_yield_forestry |  |
| 2326 | assembly_enclosure_acts | enclosure_by_agreement |  | cadastral_tax_survey [institutions], triangulation_survey [knowledge] |  |
| 2332 | veterinary_schools | cattle_plague_slaughter_orders |  | comparative_anatomy, draft_horse_breeding [logistics] |  |
| 2338 | desiccation_forest_reserves | island_forest_felling |  | instrumental_weather_registers, sustained_yield_forestry | contact_required: True |
| 2348 | state_nitre_plantations | nitrate_cultivation [1200-1800] |  | saltpetre_commissioners [security], recrystallised_saltpetre [production] |  |
| 2350 | colonial_plant_transfers | far_land_specimen_voyages |  | biological_classification, coffee_plantations [nutrition] | contact_required: True |
| 2356 | charcoal_wood_clearance | ironmaster_coppice_contracts [1200-1800], coke_firing [production] |  | coal_grading [production] |  |
| 2362 | weather_observer_network | instrumental_weather_registers |  | precision_thermometry [knowledge], salaried_science_academy [knowledge] |  |
| 2366 | mineral_cleavage | stone_sorting [production, 0-600], quarry_reading [0-600] |  | relative_stratigraphy, mining_engineering_academies [knowledge] |  |
| 2368 | volcanic_dry_fog_year | dim_sun_years [1200-1800] |  | weather_observer_network |  |
| 2374 | deep_time_geology | relative_stratigraphy |  | fossil_organic_origin, mineral_cleavage |  |
| 2380 | ocean_whaling_depletion | whale_ground_depletion |  | copper_hull_sheathing [logistics] | environment: coast |
| 2384 | torrent_check_dams | avalanche_guard_forests [1200-1800] |  | sustained_yield_forestry |  |
| 2388 | town_river_fish_kills | river_offal_bans [1200-1800] |  | dye_works_nuisance | environment: river |
| 2392 | extinction_recognized | fossil_organic_origin, comparative_anatomy |  | island_extinction_record, deep_time_geology |  |
| 2399 | condensing_smelter_flues | tall_smelter_flues [600-1200], smelter_damage_payments |  | reverberatory_furnace [production] |  |

## Notes

- **Enclosure is Ecology's.** `stinted_commons` + `quickset_hedges` → `enclosure_by_agreement` (1935) → `hedgerow_timber_planting`, `pannage_decline` and `assembly_enclosure_acts` (2326). `sheep_enclosure_depopulation` → `tillage_protection_laws` sit before it. Nutrition's `four_course_rotation` and `pedigree_stock_breeding` take `enclosure_by_agreement` as a precedent only.
- **Woodland and fuel.** `naval_timber_reserves` + `marked_tree_sales` → `arsenal_oak_reserves` → `timber_import_dependence`, `oak_planting_treatise` and, with `forest_law_courts`, `realm_forest_ordinance` → `sustained_yield_forestry` → `tree_volume_tables`. `charcoal_wood_clearance` needs Production `coke_firing`.
- **Contact and far lands.** Contact-gated: `contact_species_exchange` (Logistics `transoceanic_contact_voyages`) → `island_forest_felling` (with Nutrition `island_cane_plantations`) → `plantation_soil_exhaustion` and `desiccation_forest_reserves`; `island_extinction_record`; `far_land_specimen_voyages` → `colonial_plant_transfers`; `fur_frontier_depletion` (Demography `overseas_settler_colonies`).
- **Natural history.** `illustrated_herbals` → `pressed_plant_herbaria` → `habitat_observation_records`. Health `dissection_anatomy_atlas` + `herbal_classification` → `comparative_anatomy` (1960) → `fossil_organic_origin` → `relative_stratigraphy` → `deep_time_geology`; `extinction_recognized` needs fossils and comparative anatomy. `comparative_anatomy` + `habitat_observation_records` → `biological_classification` → `economy_of_nature` and `biological_reference_collections`. The catalog prerequisites dated later than these items (`experimental_controls` for `plant_transpiration_measurement`, `habitat_observation_records` for `comparative_anatomy`) are replaced by in-window parents.
- **Climate.** `daily_weather_diaries` + Knowledge `mercury_barometer` → `instrumental_weather_registers` → `storm_path_reconstruction` → `tree_ring_notes`, and → `weather_observer_network` → precedent of `volcanic_dry_fog_year`. `trade_wind_map` needs Logistics `ocean_wind_circuit`.
- **Pollution and nuisance.** `windy_hill_smelting_hearths` → `smelter_fume_blight` → `smelter_damage_payments` → `condensing_smelter_flues` (with 600–1200 `tall_smelter_flues`). `coal_smoke_limits` + Institutions `pleaded_case_reports` → `private_nuisance_law` → `dye_works_nuisance`; `coal_smoke_limits` → `coal_smoke_treatise` → `tall_chimney_orders`.
- **Stock disease.** `contact_contagion` + Nutrition `cattle_droving` → `cattle_plague_slaughter_orders` → `cattle_health_passes` (with Health `health_passes`) and `veterinary_schools`.
- **Gates.** Coastal items (flood marks, dune laws, dune pines, herring shift, oysters, whaling) carry `environment: coast`; salmon, weirs, frozen rivers, water meadows and river fish kills carry `environment: river`; pine sowing, leased fuel blocks and oak reserves `woodland`; mine tailings `resources_known: Silver Ore`.

## Cross-line parents in 1800–2400 (mapped by other agents)

- **Culture:** `public_collection_museum` (2166)
- **Demography:** `overseas_settler_colonies` (1926), `weekly_mortality_bills` (2008)
- **Health:** `dissection_anatomy_atlas` (1952), `faculty_physic_garden` (1954), `from_life_printed_herbals` (1942), `health_passes` (1832), `standing_health_magistracy` (1906)
- **Infrastructure:** `drainage_windmills` (1848), `enclosed_wet_docks` (2230), `fen_drainage_cuts` (2066), `multi_flue_chimney_stacks` (1894)
- **Institutions:** `cadastral_tax_survey` (2236), `cameral_domain_chambers` (2080), `equity_conscience_court` (1850), `pleaded_case_reports` (1833), `police_ordinance_science` (2260)
- **Knowledge:** `chartered_experimental_society` (2120), `integral_calculus` (2150), `laboratory_notebooks` (2126), `mercury_barometer` (2086), `mining_engineering_academies` (2330), `precision_thermometry` (2228), `printed_weekly_news` (2010), `salaried_science_academy` (2132), `triangulation_survey` (1944), `two_lens_tube_microscope` (1993)
- **Labor:** `plantation_gang_labor` (1950)
- **Logistics:** `company_merchant_fleets` (2006), `copper_hull_sheathing` (2354), `draft_horse_breeding` (2212), `fluyt_bulk_carrier` (1998), `fortified_trading_posts` (1872), `ocean_galleon` (1955), `ocean_wind_circuit` (1898), `public_letter_post` (1930), `ship_logbooks` (2022), `transoceanic_contact_voyages` (1912)
- **Nutrition:** `coffee_plantations` (2222), `convertible_husbandry` (1990), `distant_bank_salt_cod` (1925), `herring_buss_fleets` (1835), `island_cane_plantations` (1878), `maize_garden_trials` (1915), `printed_farm_manuals` (1905)
- **Production:** `coal_grading` (2194), `coke_firing` (2220), `indigo_vat_dyeing` (2012), `liquation_silver_parting` (1896), `mercury_ore_amalgamation` (1962), `potash_saltpetre_works` (1846), `powder_rock_blasting` (2054), `recrystallised_saltpetre` (2084), `reverberatory_furnace` (2186), `sugar_loaf_refining` (1971)
- **Security:** `hand_gun_tubes` (1822), `ordnance_office` (1845), `saltpetre_commissioners` (1972)
