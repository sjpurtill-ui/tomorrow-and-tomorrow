# Logistics dependencies

Machine-readable source: `logistics.json`. Format: `MAPPING_CONTRACT.md`. Cross-line ids are listed by name. `resources_known` values are lists.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | `carried_load_balancing` | - | - | - | - |
| 3 | `landmark_route_naming` | - | - | route_memory | - |
| 4 | `paired_carrier_balancing` | - | - | carried_load_balancing | - |
| 5 | `guest_host_reciprocity` | - | - | shared_hearth_gatherings | - |
| 6 | `vermin_deterrent_placement` | edible_resource_recognition | - | pest_deterrent_storage_herbs | - |
| 7 | `hide_floats` | cordage | - | timber_grading | environment=river |
| 8 | `dry_cache_siting` | food_drying | - | seasonal_patterns | - |
| 10 | `carrying_poles` | paired_carrier_balancing | - | cordage | - |
| 12 | `trail_waymarking` | landmark_route_naming | - | route_memory | - |
| 14 | `river_craft` | hafted_tools, timber_grading | - | hide_floats, ground_stone_axes | environment=river |
| 16 | `trade_partner_tokens` | guest_host_reciprocity | - | kin_body_ornament | - |
| 18 | `sledges_travois` | cordage, carrying_poles | - | timber_grading | - |
| 20 | `down_the_line_exchange` | trade_partner_tokens | - | stone_sorting | - |
| 22 | `load_lashing_knots` | cordage | - | carrying_poles | - |
| 25 | `route_food_caches` | dry_cache_siting, trail_waymarking | - | - | - |
| 28 | `portage_paths` | river_craft, trail_waymarking | - | - | environment=river |
| 32 | `skis_snowshoes` | cordage, timber_grading | - | timber_seasoning, bone_needle_sewing | - |
| 36 | `reed_bundle_boats` | hide_floats, basketry | - | river_craft, bitumen_sealing | environment=river |
| 40 | `brushwood_trackways` | trail_waymarking, hafted_tools | - | basketry | - |
| 45 | `load_backframes` | load_lashing_knots, joinery | - | woven_carriers | - |
| 50 | `boundary_exchange_sites` | down_the_line_exchange | - | common_ground_marking | - |
| 60 | `wayfinding_stars` | named_star_figures | - | route_memory | - |
| 65 | `rollers_and_runners` | sledges_travois | - | wedges_and_levers | - |
| 75 | `seasonal_ford_timing` | seasonal_patterns, route_memory | - | flood_mark_reading | environment=river |
| 78 | `relay_carrying_shifts` | carrying_poles, labor_rotations | - | route_food_caches | - |
| 80 | `oldest_first_marking` | owner_marks | - | dry_cache_siting, tallies | - |
| 85 | `trade_partner_memory` | boundary_exchange_sites | - | counting_words | - |
| 90 | `salt_shell_routes` | down_the_line_exchange, trail_waymarking | - | boundary_exchange_sites | contact_required=True |
| 100 | `river_landings` | river_craft | - | portage_paths, site_clearing_assessment | environment=river |
| 110 | `hide_covered_boats` | hide_tanning, basketry | - | river_craft | environment=river |
| 115 | `stock_layering_method` | oldest_first_marking | - | clay_lined_storage_pits | - |
| 120 | `seasonal_route_assessment` | seasonal_ford_timing, trail_waymarking | - | weather_sign_reading | - |
| 125 | `barter_equivalence_custom` | trade_partner_memory, tallies | - | standard_measures | - |
| 135 | `ox_drawn_sledges` | rollers_and_runners, animal_taming | - | herding_rotas | - |
| 140 | `long_distance_axe_trade` | ground_stone_axes, down_the_line_exchange | - | salt_shell_routes | contact_required=True |
| 150 | `pack_animals` | animal_taming, load_lashing_knots | - | ox_drawn_sledges | environment=dry |
| 152 | `load_bundling_by_weight` | load_backframes, standard_measures | - | - | - |
| 155 | `rest_stop_spacing_custom` | relay_carrying_shifts | - | route_food_caches, paced_distance_counting | - |
| 160 | `pest_barrier_maintenance` | vermin_deterrent_placement | - | communal_upkeep_scheduling | - |
| 165 | `shared_trade_escort` | salt_shell_routes | - | joint_hamlet_defense_pacts | - |
| 170 | `pack_load_balancing` | pack_animals, carried_load_balancing | - | - | - |
| 175 | `pack_saddles` | pack_animals, joinery | - | - | - |
| 180 | `plank_trackways` | brushwood_trackways, wedges_and_levers | - | joinery | - |
| 185 | `paired_ox_yoke` | ox_drawn_sledges, joinery | - | - | - |
| 190 | `sealed_store_doors` | stamp_seals | - | marked_storage_registers, courtyard_storerooms | - |
| 200 | `plank_extended_dugouts` | river_craft, wedges_and_levers | - | cordage, bow_drill_drive | environment=river |
| 225 | `solid_wheel_assembly` | joinery, timber_post_beam_connections | - | rollers_and_runners, tournette | - |
| 228 | `wooden_axle_shaping` | solid_wheel_assembly, timber_seasoning | - | - | - |
| 232 | `linchpin_retention` | wooden_axle_shaping | - | - | - |
| 235 | `trade_colonies` | long_distance_axe_trade, satellite_hamlets | - | river_landings | contact_required=True |
| 240 | `cart_bed_framing` | linchpin_retention, paired_ox_yoke | - | - | - |
| 242 | `cargo_stowage_sequencing` | load_bundling_by_weight | any of cart_bed_framing/plank_extended_dugouts/pack_saddles | - | - |
| 245 | `storage_humidity_judging` | stock_layering_method, grain_moisture_watch | - | - | - |
| 248 | `market_timing_knowledge` | barter_equivalence_custom, seasonal_patterns | - | festival_calendar | - |
| 252 | `crossing_point_survey` | seasonal_route_assessment | - | landmark_triangulation, sightline_staking | - |
| 260 | `four_wheeled_wagons` | cart_bed_framing | - | timber_post_beam_connections | - |
| 272 | `sail_panel_cutting` | plain_weaving, plank_extended_dugouts | - | cordage | environment=river |
| 278 | `waypoint_cargo_transfer` | cargo_stowage_sequencing, river_landings | - | portage_paths | - |
| 282 | `alternate_route_scouting` | crossing_point_survey | - | raid_scouting | - |
| 285 | `cache_capacity_accounting` | route_food_caches, material_accounting | - | capacity_ledgers | - |
| 288 | `seasonal_trade_gathering` | boundary_exchange_sites, market_timing_knowledge | - | festival_calendar | min_settlements=2 |
| 292 | `supply_groups` | cache_capacity_accounting, task_captains | - | pack_animals, shared_trade_escort | - |
| 295 | `cargo_seals` | sealed_store_doors | - | cylinder_seals | - |
| 298 | `haul_harness_weaving` | paired_ox_yoke, cart_bed_framing | - | cordage, plain_weaving | - |
| 300 | `graded_roads` | great_work_parties, rod_and_cord_leveling | - | cart_bed_framing, sightline_staking | institutions_min=0.3 |
| 305 | `cart_running_gear` | four_wheeled_wagons, load_bundling_by_weight | - | - | - |
| 310 | `coastal_watercraft` | plank_extended_dugouts, sail_panel_cutting | - | - | environment=coast |
| 315 | `timber_bridges` | timber_post_beam_connections, crossing_point_survey | - | plank_trackways | - |
| 320 | `rope_laying` | cordage, fiber_retting | - | wool_spinning | - |
| 325 | `caulking_fiber_preparation` | fiber_retting | any of bitumen_sealing/charcoal | plank_extended_dugouts | - |
| 330 | `hull_seam_caulking` | caulking_fiber_preparation, coastal_watercraft | - | - | - |
| 335 | `treenail_fastening` | joinery, coastal_watercraft | - | bow_drill_drive, copper_carpentry_tools | - |
| 340 | `towpaths` | rope_laying, river_landings | - | - | environment=river |
| 345 | `mast_making` | sail_panel_cutting, rope_laying | - | treenail_fastening | - |
| 350 | `ferry_crossings` | crossing_point_survey, plank_extended_dugouts | - | rope_laying | environment=river |
| 355 | `plank_spiling` | treenail_fastening | - | copper_carpentry_tools | - |
| 360 | `central_storehouses` | sealed_store_doors, public_stores | any of marked_storage_registers/clay_record_tablets | courtyard_storerooms, temple_common_storehouse | institutions_min=0.4 |
| 370 | `convoy_load_distribution` | supply_groups | any of cart_running_gear/pack_saddles | - | - |
| 375 | `store_airflow_arrangement` | storage_humidity_judging | - | raised_granaries | - |
| 380 | `trade_route_risk_assessment` | alternate_route_scouting, shared_trade_escort | - | - | - |
| 385 | `waystation_spacing_judgment` | rest_stop_spacing_custom, cache_capacity_accounting | - | paced_distance_counting | - |
| 390 | `onager_hybrid_teams` | four_wheeled_wagons, haul_harness_weaving | - | pack_animals | environment=dry |
| 395 | `paved_haul_roads` | graded_roads, dressed_stone_masonry | - | wedge_and_fire_quarrying | resources_known=Stone |
| 400 | `stone_jetty_harbors` | coastal_watercraft, dry_stone_walls | - | river_landings, great_work_parties | environment=coast |
| 405 | `wetted_track_sledging` | ox_drawn_sledges, plank_trackways | - | megalith_raising, great_work_parties | - |
| 410 | `navigation_canals` | river_supply_channels, rod_and_cord_leveling | - | towpaths, flood_levees | environment=river; institutions_min=0.5 |
| 415 | `hogging_truss_hulls` | plank_spiling, rope_laying | - | mast_making | environment=coast |
| 425 | `grain_barge_fleets` | navigation_canals, central_storehouses | - | convoy_load_distribution | - |
| 435 | `donkey_caravans` | pack_saddles, seasonal_trade_gathering | - | waystation_spacing_judgment, trade_route_risk_assessment | - |
| 445 | `standard_transport_jars` | wheel_thrown_pottery, cross_settlement_measure_agreement | - | reference_vessel_sets | - |
| 455 | `road_stations` | waystation_spacing_judgment, lined_well_shafts | - | graded_roads, guest_host_reciprocity | institutions_min=0.5 |
| 475 | `domesticated_mounts` | animal_taming, haul_harness_weaving | - | onager_hybrid_teams | contact_required=True |
| 485 | `hired_carriers` | sealed_tablet_contracts, relay_carrying_shifts | - | hired_harvest_hands, hired_labor_contracts | - |
| 490 | `spoke_tenon_cutting` | solid_wheel_assembly, copper_carpentry_tools | - | bow_drill_drive, bronze_alloying | - |
| 500 | `spoked_wheel_assembly` | spoke_tenon_cutting | - | domesticated_mounts, hide_tanning | - |
| 510 | `island_hopping_sailing` | hull_seam_caulking, mast_making | - | wayfinding_stars | environment=coast |
| 518 | `mountain_pack_trains` | donkey_caravans | - | tin_smelting | contact_required=True |
| 525 | `merchant_quarters_abroad` | trade_colonies, foreign_treaties | - | sworn_interpreters | contact_required=True |
| 540 | `pilots_sea_lanes` | island_hopping_sailing | - | landmark_triangulation | environment=coast |
| 550 | `sailing_calendar` | pilots_sea_lanes, solar_year_reckoning | - | weather_sign_reading | environment=coast |
| 560 | `harbor_warehouses` | stone_jetty_harbors, central_storehouses | - | merchant_quarters_abroad | environment=coast |
| 590 | `consignment_lists` | cargo_seals, sealed_tablet_letters | - | standard_royal_letters | - |
| 600 | `relay_team_stations` | road_stations, domesticated_mounts | - | messenger_relay_stations | - |
