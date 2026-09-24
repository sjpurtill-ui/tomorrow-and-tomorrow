# Ecology dependencies

Machine-readable source: `ecology.json`. Format: `MAPPING_CONTRACT.md`. Cross-line ids are listed by name. `resources_known` values are lists.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | `seasonal_patterns` | - | - | - | - |
| 3 | `timber_grading` | - | - | - | - |
| 4 | `fiber_grading` | - | - | edible_resource_recognition | - |
| 5 | `quarry_reading` | - | - | stone_sorting | - |
| 6 | `streambank_vegetation_watch` | seasonal_patterns | - | - | environment=river |
| 8 | `herd_size_limits` | seasonal_patterns | - | animal_taming | - |
| 9 | `fallow_thicket_regrowth` | seasonal_patterns | - | - | - |
| 10 | `midden_siting_away_from_water` | turbidity_judging | - | sickness_pattern_memory | - |
| 11 | `topsoil_depth_reading` | edible_resource_recognition | - | seasonal_patterns | - |
| 12 | `browse_line_monitoring` | herd_size_limits | - | - | - |
| 13 | `burn_scar_regrowth_tracking` | fallow_thicket_regrowth | - | ember_tending | - |
| 14 | `cookfire_smoke_venting_habit` | ember_tending | - | hearth_heat_retention | - |
| 18 | `phenology_signs` | seasonal_patterns | - | weather_sign_reading | - |
| 20 | `controlled_undergrowth_burning` | burn_scar_regrowth_tracking, friction_fire_ignition | - | - | - |
| 24 | `spawning_calendar` | phenology_signs | - | fish_weirs_and_traps | environment=river |
| 28 | `firebreaks` | controlled_undergrowth_burning | - | - | - |
| 30 | `indicator_plants` | topsoil_depth_reading | - | herbal_classification | - |
| 35 | `breeding_stock_sparing` | seasonal_protein_sourcing | - | phenology_signs | - |
| 40 | `swidden_cycle` | fallow_thicket_regrowth, controlled_undergrowth_burning | - | seed_selection, ground_stone_axes | environment=woodland |
| 45 | `leaf_fodder_pollarding` | animal_taming, hafted_tools | - | fallow_thicket_regrowth | environment=woodland |
| 50 | `hive_sparing_honey_harvest` | breeding_stock_sparing | - | wild_honey_smoking | - |
| 55 | `drought_signs` | weather_sign_reading, phenology_signs | - | - | - |
| 60 | `transhumance` | animal_taming, herding_rotas | - | phenology_signs | - |
| 65 | `shellfish_bed_recovery` | breeding_stock_sparing | - | - | environment=coast |
| 75 | `downwind_workshop_placement` | cookfire_smoke_venting_habit | - | hide_smoke_curing, pit_firing | - |
| 78 | `slope_erosion_watch` | streambank_vegetation_watch, swidden_cycle | - | - | - |
| 80 | `spawning_ground_avoidance` | spawning_calendar, breeding_stock_sparing | - | - | environment=river |
| 85 | `frost_pocket_reading` | crop_calendars | - | weather_sign_reading | - |
| 90 | `pest_swarm_watch` | crop_calendars | - | weather_sign_reading | - |
| 100 | `sacred_grove_protection` | sacred_places | - | selective_deadwood_gathering | - |
| 105 | `contour_terrace_reading` | slope_erosion_watch, dry_stone_walls | - | - | - |
| 108 | `seasonal_hunting_closures` | breeding_stock_sparing, customary_law | - | - | - |
| 110 | `selective_deadwood_gathering` | timber_grading | - | fallow_thicket_regrowth | - |
| 112 | `tannery_waste_channeling` | hide_tanning, drainage | - | midden_siting_away_from_water | - |
| 120 | `seed_scatter_after_gathering` | seed_selection | - | breeding_stock_sparing | - |
| 130 | `reed_bed_rotation` | fallow_thicket_regrowth | - | basketry | environment=river |
| 140 | `copper_outcrop_signs` | quarry_reading, mineral_pigment_preparation | - | native_copper_working | resources_known=Copper |
| 150 | `communal_catch_limits` | spawning_ground_avoidance, customary_law | - | elder_council_assent | - |
| 152 | `refuse_pit_rotation` | refuse_removal, midden_siting_away_from_water | - | - | - |
| 155 | `windbreak_hedgerow_siting` | field_boundary_markers | - | thorn_barriers | - |
| 158 | `root_stock_preservation` | seed_scatter_after_gathering | - | cutting_propagation | - |
| 170 | `flood_silt_fields` | flood_mark_reading, indicator_plants | - | - | environment=river |
| 180 | `wood_pasture` | leaf_fodder_pollarding | - | browse_line_monitoring, selective_deadwood_gathering | environment=woodland |
| 195 | `coppice_regrowth_cutting` | leaf_fodder_pollarding | - | fallow_thicket_regrowth | environment=woodland |
| 198 | `dye_vat_runoff_control` | textile_dye_extraction, tannery_waste_channeling | - | - | - |
| 200 | `sapling_protection_customs` | browse_line_monitoring, thorn_barriers | - | - | - |
| 210 | `grazing_ground_recovery_marking` | browse_line_monitoring, common_ground_marking | - | - | - |
| 220 | `dung_cake_fuel` | animal_taming | - | selective_deadwood_gathering | environment=dry |
| 225 | `replanting_after_clearance` | cutting_propagation, sapling_protection_customs | - | - | - |
| 228 | `grazing_rotation_customs` | grazing_ground_recovery_marking, herding_rotas | - | - | - |
| 232 | `timber_stand_reserves` | coppice_regrowth_cutting, customary_law | - | - | environment=woodland |
| 238 | `kiln_smoke_venting_customs` | kiln_control, downwind_workshop_placement | - | - | - |
| 250 | `waterlogging_recognition` | irrigation_schedules | - | indicator_plants | - |
| 265 | `riparian_tree_belts` | streambank_vegetation_watch, replanting_after_clearance | - | river_supply_channels | environment=river |
| 275 | `fuelwood_rotation` | selective_deadwood_gathering, coppice_regrowth_cutting | - | - | - |
| 280 | `spring_head_fencing` | clean_water, thorn_barriers | - | grazing_ground_recovery_marking | - |
| 290 | `named_soil_kinds` | indicator_plants, flood_silt_fields | - | standard_sign_lists | - |
| 305 | `salinity_recognition` | waterlogging_recognition | - | - | environment=dry |
| 312 | `riverbank_shift_watch` | flood_silt_fields, streambank_vegetation_watch | - | - | environment=river |
| 320 | `salt_leaching_fallow` | salinity_recognition, field_rest_scheduling | - | - | environment=dry |
| 330 | `wetland_margin_reserves` | reed_bed_rotation, communal_catch_limits | - | - | environment=river |
| 340 | `stubble_grazing` | grazing_rotation_customs | - | manure_field_spreading | - |
| 350 | `pit_pond_reclamation` | - | any of mould_made_mudbricks/wedge_and_fire_quarrying | rainwater_cisterns, fish_weirs_and_traps | - |
| 360 | `recovery_zone_designation` | grazing_ground_recovery_marking, seasonal_hunting_closures | - | timber_stand_reserves | institutions_min=0.3 |
| 362 | `watershed_boundary_marking` | boundary_marker_surveys, river_supply_channels | - | - | - |
| 365 | `resource_use_quotas` | recovery_zone_designation, material_accounting | - | - | institutions_min=0.4 |
| 368 | `workshop_effluent_separation` | dye_vat_runoff_control, stone_lined_drains | - | - | - |
| 385 | `distant_timber_reserves` | timber_stand_reserves | - | trade_colonies, river_landings | - |
| 415 | `salt_tolerant_barley` | salinity_recognition, seed_selection | - | - | environment=dry |
| 430 | `water_table_fallow` | salt_leaching_fallow, irrigation_schedules | - | - | environment=dry |
| 440 | `timed_silt_clearance` | river_supply_channels, riverbank_shift_watch | - | public_levies | environment=river |
| 450 | `layered_shade_gardens` | offshoot_date_planting, kitchen_gardens | - | - | environment=dry |
| 460 | `seasonal_herd_matching` | grazing_rotation_customs, people_herd_counts | - | - | - |
| 470 | `dune_spread_watch` | windbreak_hedgerow_siting, drought_signs | - | - | environment=dry |
| 480 | `deforestation_flood_link` | slope_erosion_watch, riparian_tree_belts | - | flood_origin_stories | - |
| 490 | `mixed_flock_balance` | seasonal_herd_matching | - | - | - |
| 500 | `sworn_fishing_closures` | communal_catch_limits, formal_oath_taking | - | boundary_treaties | - |
| 510 | `fish_run_weir_opening` | sworn_fishing_closures, fish_weirs_and_traps | - | - | environment=river |
| 515 | `vermin_control_cats` | pest_barrier_maintenance | - | animal_taming | - |
| 520 | `shared_woodland_boundaries` | timber_stand_reserves, boundary_treaties | - | - | - |
| 530 | `mine_spoil_containment` | fire_setting_mining, workshop_effluent_separation | - | - | - |
| 540 | `timed_grass_burning` | controlled_undergrowth_burning, grazing_rotation_customs | - | - | - |
| 550 | `coppiced_charcoal_woods` | fuelwood_rotation, charcoal | - | shaft_furnaces, timber_stand_reserves | environment=woodland |
| 560 | `farmers_almanac` | crop_calendars, written_lore_tablets | - | intercalated_calendar, pest_swarm_watch | - |
| 575 | `planted_timber_groves` | replanting_after_clearance, distant_timber_reserves | - | cutting_propagation | - |
| 590 | `sworn_grazing_rights` | grazing_rotation_customs, sealed_tablet_contracts | - | stubble_grazing | - |
| 600 | `protected_temple_woods` | sacred_grove_protection, timber_stand_reserves | - | temple_estates | - |
