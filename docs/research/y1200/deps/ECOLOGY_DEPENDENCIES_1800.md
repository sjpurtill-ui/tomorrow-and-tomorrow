# Ecology dependencies: years 1200–1800

Generated with `docs/research/y1200/deps/partials/nhde.json`. It uses ids from `registry_1800.json`, the 600–1200 graph (`docs/research/y600/deps/graph_1200.json`) and the 0–600 graph only. Brackets mark a parent from another line or an earlier block: `[logistics]` is a 1200–1800 id owned by Logistics, `[ecology, 600-1200]` is a 600–1200 Ecology id, `[0-600]` is a same-line 0–600 id. An `environment` list means any one of the listed environments satisfies the gate. `requires_all` are hard prerequisites dated at or before the dependent (no edge links two items of the same year); `requires_any` groups need one member; precedents are soft influences, also dated at or before it. No year moves are proposed for this line (`partials/nhde_year_adjustments.json` is empty).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 1210 | terrace_collapse_watch | terrace_wall_upkeep [600-1200], slope_erosion_watch [0-600] |  |  |  |
| 1222 | runoff_catchment_fields | wadi_dams [infrastructure, 0-600] |  | brush_check_dams [600-1200], dune_spread_watch [0-600] | environment: dry |
| 1235 | failed_drain_marsh_return | planned_wetland_drainage [600-1200], marsh_fever_drainage [health, 600-1200] |  | waterlogging_recognition [0-600] |  |
| 1250 | abandoned_land_regrowth | worn_field_retirement [600-1200] |  | deserted_land_grants [demography, 600-1200] |  |
| 1265 | wildlife_return_watch | local_extirpation_watch [600-1200], abandoned_land_regrowth |  |  |  |
| 1275 | valley_sediment_burial | slope_erosion_watch [0-600], deforestation_flood_link [0-600] |  | harbor_silting_link [600-1200] | environment: river |
| 1280 | dim_sun_years | famine_reserves [nutrition, 0-600], astronomical_diaries [knowledge, 600-1200] |  | eclipse_records [knowledge, 600-1200] |  |
| 1290 | well_spacing_rules | well_drawdown_watch [600-1200] |  | oasis_water_shares [600-1200], promulgated_edict_code [institutions] |  |
| 1295 | licensed_estuary_weirs | fish_weirs_and_traps [nutrition, 0-600] |  | fish_run_weir_opening [0-600], sworn_fishing_closures [0-600] | environment: coast, river |
| 1300 | fen_commons | wetland_plot_leases [600-1200], wetland_margin_reserves [0-600] |  | common_pasture_fees [600-1200] |  |
| 1310 | mast_count_pannage | mast_fed_swine [nutrition, 600-1200], wood_pasture [0-600] |  | seasonal_herd_matching [0-600] | environment: woodland |
| 1325 | endowed_reclamation | devotee_communities_under_rule [culture], deserted_land_grants [demography, 600-1200] |  | abandoned_land_regrowth |  |
| 1330 | seabird_colony_shares | nesting_season_netting_ban [600-1200], communal_catch_limits [0-600] |  |  | environment: coast |
| 1340 | village_wood_reeves | shared_woodland_boundaries [0-600], fuelwood_rotation [0-600] |  | charcoal_licensing [600-1200] | environment: woodland |
| 1355 | summer_shielings | transhumance [0-600], summer_pasture_dairies [nutrition, 600-1200] |  |  |  |
| 1360 | fixed_charcoal_hearths | coppiced_charcoal_woods [0-600], covered_charcoal_clamps [production, 600-1200] |  | charcoal_licensing [600-1200] | environment: woodland |
| 1370 | quickset_hedges | windbreak_hedgerow_siting [0-600], sapling_protection_customs [0-600] |  | tree_nurseries [600-1200] |  |
| 1385 | managed_heathland | timed_grass_burning [0-600], grazing_rotation_customs [0-600] |  | thin_soil_grassland [600-1200] |  |
| 1395 | reserved_hunting_rights | game_wardens [600-1200] |  | enclosed_game_parks [nutrition, 600-1200], service_land_grants [institutions, 0-600] |  |
| 1400 | wolf_bounties | crop_raider_culls [600-1200] |  | local_extirpation_watch [600-1200], wildlife_return_watch |  |
| 1412 | locust_bounty_campaigns | locust_egg_digging [600-1200], district_counts [institutions] |  | price_stabilizing_granary [institutions, 600-1200] | environment: dry |
| 1430 | fur_beast_depletion | local_extirpation_watch [600-1200] |  | transcontinental_relay_trade [logistics, 600-1200], wildlife_return_watch |  |
| 1438 | turf_manuring_depletion | managed_heathland, manure_field_spreading [nutrition, 0-600] |  | soil_exhaustion_recognition [nutrition, 0-600] |  |
| 1442 | mill_dam_height_limits | water_mills [production, 600-1200], hay_meadow_management [600-1200] |  | overshot_mill_wheels [nutrition, 600-1200] | environment: river |
| 1450 | irrigation_water_tribunals | river_diversion_weirs [infrastructure] | oasis_water_shares [600-1200] or irrigation_schedules [nutrition, 0-600] |  | environment: dry, river |
| 1462 | introduced_weed_watch | staged_acclimatization [600-1200], foreign_plant_gardens [600-1200] |  | new_garden_vegetables [nutrition], orchard_pest_smokes [600-1200] |  |
| 1475 | storm_surge_records | embanked_salt_meadows [600-1200] |  | flood_height_gauges [600-1200], formal_chronicle_keeping [knowledge, 0-600] | environment: coast |
| 1482 | drifting_sand_burial | turf_manuring_depletion | dune_spread_watch [0-600] or dune_fixing_plantings [600-1200] |  |  |
| 1488 | common_fallow_grazing_rule | stubble_grazing [0-600], three_field_rotation [nutrition] |  | night_folding_on_fallow [600-1200], manor_court_customals [institutions] |  |
| 1497 | licensed_forest_clearing | replanting_after_clearance [0-600], forest_supervisors [600-1200] |  | endowed_reclamation | environment: woodland |
| 1508 | peat_fuel_cutting | peat_drying [production, 0-600], city_firewood_supply [600-1200] |  | fen_commons |  |
| 1518 | protected_hawk_eyries | reserved_hunting_rights, raptor_nesting_encouragement [600-1200] |  |  |  |
| 1530 | windy_hill_smelting_hearths | argentiferous_lead_working [production, 600-1200], tall_smelter_flues [600-1200] |  | mine_spoil_containment [0-600] | resources_known: Lead Ore |
| 1542 | oak_bark_seasons | coppice_regrowth_cutting [0-600], lined_tanning_pits [600-1200] |  | alum_tawed_leather [production] |  |
| 1555 | sluiced_polders | embanked_salt_meadows [600-1200], canal_sluice_gates [infrastructure, 600-1200] |  | estuary_embankments [infrastructure] | environment: coast |
| 1575 | marked_tree_sales | forest_inventory_counts [600-1200], charcoal_licensing [600-1200] |  | licensed_forest_clearing |  |
| 1580 | forest_perambulation | shared_woodland_boundaries [0-600], forest_supervisors [600-1200] |  | watershed_boundary_marking [0-600] |  |
| 1592 | forest_law_courts | forest_supervisors [600-1200], reserved_hunting_rights |  | seigneurial_immunity_courts [institutions], forest_perambulation |  |
| 1603 | woodbank_enclosures | coppice_regrowth_cutting [0-600], sapling_protection_customs [0-600] |  | quickset_hedges | environment: woodland |
| 1615 | river_fishery_wardens | sworn_fishing_closures [0-600], net_mesh_limits [600-1200] |  | licensed_estuary_weirs | environment: river |
| 1622 | paled_deer_parks | enclosed_game_parks [nutrition, 600-1200], reserved_hunting_rights |  | forest_law_courts |  |
| 1632 | salt_pan_fuel_draw | saltworks_shift_crews [labor], smelter_fuel_depletion_watch [600-1200] |  | brine_purification [production] | resources_known: Salt |
| 1642 | woodland_common_allowances | village_wood_reeves, mast_count_pannage |  | manor_court_customals [institutions] | environment: woodland |
| 1652 | coppice_with_standards | coppiced_charcoal_woods [0-600], timber_stand_reserves [0-600] |  | woodbank_enclosures | environment: woodland |
| 1662 | relict_wild_cattle_reserves | forest_law_courts, local_extirpation_watch [600-1200] |  | paled_deer_parks |  |
| 1672 | mine_water_complaints | mine_drainage [production, 600-1200], mine_spoil_containment [0-600] |  | water_ore_stamps [production], ore_washing_sluices [production] |  |
| 1678 | kiln_fuel_licences | charcoal_licensing [600-1200], lime_mortar [infrastructure, 0-600] |  | clamp_fired_brick [production], smelter_fuel_depletion_watch [600-1200] |  |
| 1682 | downstream_trade_quarters | smoky_trades_zoning [600-1200], workshop_effluent_separation [0-600] |  | dye_vat_runoff_control [0-600] | environment: river |
| 1688 | sea_coal_substitution | city_firewood_supply [600-1200], coal_fired_ironworking [production] |  | peat_fuel_cutting |  |
| 1690 | warren_escape_liability | coney_warrens [nutrition], manor_court_customals [institutions] |  |  |  |
| 1692 | stinted_commons | common_pasture_fees [600-1200], seasonal_herd_matching [0-600] |  | common_fallow_grazing_rule |  |
| 1695 | crop_limit_shift_watch | northern_slope_vineyards [nutrition], dim_sun_years |  | estate_yield_accounts [nutrition] |  |
| 1700 | dike_boards | dike_duty_lengths [labor] | sluiced_polders or flood_levees [infrastructure, 0-600] | sworn_town_commune [institutions] | environment: coast, river |
| 1705 | wool_flock_overgrazing | seasonal_herd_matching [0-600], pasture_matched_breeds [600-1200] |  | stinted_commons |  |
| 1708 | bird_observation_treatise | descriptive_natural_history [knowledge, 600-1200], protected_hawk_eyries |  | observation_notebooks [knowledge] |  |
| 1715 | shellfish_closed_seasons | shellfish_bed_recovery [0-600], oyster_bed_culture [nutrition, 600-1200] |  | river_fishery_wardens | environment: coast |
| 1718 | ironmaster_coppice_contracts | charcoal_licensing [600-1200], water_blown_stack_bloomery [production] |  | coppice_with_standards | environment: woodland |
| 1728 | itinerant_forest_glassworks | potash_forest_glass [production] |  | licensed_forest_clearing | environment: woodland |
| 1734 | steward_husbandry_treatises | husbandry_handbooks [nutrition, 600-1200], estate_yield_accounts [nutrition] |  | farm_encyclopedia [nutrition] |  |
| 1740 | drained_land_subsidence | planned_wetland_drainage [600-1200] |  | sluiced_polders, peat_fuel_cutting |  |
| 1745 | nitre_earth_leaching | ash_lye_cleansers [production, 600-1200] |  | brine_purification [production], town_dung_collectors [600-1200] |  |
| 1750 | river_offal_bans | workshop_effluent_separation [0-600], street_filth_ordinances [health] |  | fountain_fouling_law [health, 600-1200] | environment: river |
| 1755 | coal_smoke_limits | sea_coal_substitution, smoky_trades_zoning [600-1200] |  | kiln_smoke_venting_customs [0-600] |  |
| 1760 | weir_fish_gaps | fish_run_weir_opening [0-600], mill_dam_height_limits |  | river_fishery_wardens | environment: river |
| 1762 | felling_rotation_ordinance | forest_inventory_counts [600-1200], coppice_with_standards |  | marked_tree_sales |  |
| 1775 | nitrate_cultivation | nitre_earth_leaching |  | nitre_incendiary_mixtures [security], manure_field_spreading [nutrition, 0-600] |  |
| 1780 | marginal_land_retreat | worn_field_retirement [600-1200], crop_limit_shift_watch |  | dim_sun_years |  |
| 1785 | glacier_advance_records | crop_limit_shift_watch, snowpack_flow_forecast [600-1200] |  |  |  |
| 1790 | avalanche_guard_forests | steep_slope_forest_retention [600-1200] |  | glacier_advance_records, felling_rotation_ordinance |  |
| 1792 | drowned_land_abandonment | storm_surge_records, dike_boards |  | drained_land_subsidence | environment: coast |
| 1795 | daily_weather_diaries | district_rain_gauges [knowledge], commonplace_books [knowledge] |  | star_weather_almanac [knowledge, 600-1200] |  |
| 1798 | conifer_seed_sowing | tree_nurseries [600-1200], felling_rotation_ordinance |  |  |  |

## Notes

- **Woods.** `forest_supervisors` + `forest_inventory_counts` (600–1200) → `marked_tree_sales`, `forest_perambulation`, `forest_law_courts` → `relict_wild_cattle_reserves`. `coppiced_charcoal_woods` + `timber_stand_reserves` → `coppice_with_standards` (1652) → `felling_rotation_ordinance` → `conifer_seed_sowing`. Fuel pressure runs `city_firewood_supply` → `peat_fuel_cutting` → `sea_coal_substitution` → `coal_smoke_limits`. `sea_coal_substitution` also requires production `coal_fired_ironworking`. The industrial wood draws require labor `saltworks_shift_crews`, production `water_blown_stack_bloomery` and production `potash_forest_glass`.
- **Game and commons.** `game_wardens` → `reserved_hunting_rights` (1395) → `protected_hawk_eyries`, `forest_law_courts` and `paled_deer_parks`. `common_pasture_fees` → `stinted_commons`. `stubble_grazing` + nutrition `three_field_rotation` → `common_fallow_grazing_rule`. Institutions `manor_court_customals` gates `warren_escape_liability`, together with nutrition `coney_warrens`.
- **Water and coast.** `embanked_salt_meadows` → `storm_surge_records` and `sluiced_polders`. `dike_boards` requires labor `dike_duty_lengths` and either `sluiced_polders` or 0–600 `flood_levees`, so river settlements can form them too. Dike boards lead to `drowned_land_abandonment`. `irrigation_water_tribunals` requires infrastructure `river_diversion_weirs` and either `oasis_water_shares` or `irrigation_schedules`. `mill_dam_height_limits` → `weir_fish_gaps`.
- **Nitre.** `ash_lye_cleansers` → `nitre_earth_leaching` (1745) → `nitrate_cultivation` (1775). Security `nitre_incendiary_mixtures` (1760) is only a precedent. Security's `black_powder` (1787) may take nitre from here.
- **Climate watching.** Knowledge `astronomical_diaries` (600–1200) + `famine_reserves` → `dim_sun_years` → `crop_limit_shift_watch` → `marginal_land_retreat` and `glacier_advance_records`. `crop_limit_shift_watch` also requires nutrition `northern_slope_vineyards`. `daily_weather_diaries` requires knowledge `district_rain_gauges` and `commonplace_books`.
- **Environment gates.**
  - coast: `seabird_colony_shares`, `storm_surge_records`, `sluiced_polders`, `shellfish_closed_seasons` and `drowned_land_abandonment`.
  - river: `valley_sediment_burial`, `mill_dam_height_limits`, `downstream_trade_quarters`, `river_fishery_wardens`, `river_offal_bans` and `weir_fish_gaps`.
  - woodland: the coppice, pannage and forest-industry items.
  - dry: `runoff_catchment_fields` and `locust_bounty_campaigns`.
  - Resources: `windy_hill_smelting_hearths` needs `Lead Ore`, and `salt_pan_fuel_draw` needs `Salt`.
