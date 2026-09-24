# Infrastructure dependencies

Machine-readable source: `docs/research/deps/infrastructure.json`. Format per `MAPPING_CONTRACT.md`. Year flags: `infrastructure_FLAGS.md`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | `common_ground_marking` — Common ground marked out for building | — | — | named_landmark_lore | — |
| 3 | `hazard_landmark_memory` — Hazard landmark memory | — | — | route_memory | — |
| 4 | `drainage` — Surface water led away from sleeping places | — | — | common_ground_marking, weather_sign_reading | — |
| 6 | `sightline_staking` — House plots staked by sightline | common_ground_marking | — | — | — |
| 8 | `site_clearing_assessment` — Site-clearing judgment | common_ground_marking, hazard_landmark_memory | — | — | — |
| 10 | `joinery` — Lashed and notched pole joints | cordage | — | hafted_tools | — |
| 12 | `well_siting` — Wells sited by seepage and plants | streambank_vegetation_watch | — | turbidity_judging, drainage | — |
| 14 | `clay_lined_storage_pits` — Clay-lined storage pits | clay_testing | — | drainage | resources_known=Clay |
| 15 | `flood_mark_reading` — High-water marks read from banks | hazard_landmark_memory | — | — | environment=river |
| 18 | `adobe_wall_construction` — Hand-formed mud lumps and adobe walls | clay_shaping | — | joinery, clay_lined_storage_pits | resources_known=Clay |
| 20 | `framed_construction` — Earth-fast post-and-beam longhouse | joinery, ground_stone_axes | — | — | environment=woodland |
| 24 | `wattle_and_daub_walls` — Wattle-and-daub walls | framed_construction, basketry | — | adobe_wall_construction | — |
| 26 | `thatched_roofing` — Reed and straw thatch | framed_construction, cordage | — | — | — |
| 28 | `dry_stone_walls` — Dry-stone walls for pens and terraces | stone_sorting, sightline_staking | — | — | — |
| 32 | `lined_well_shafts` — Timber- and wattle-lined well shafts | well_siting | any of wattle_and_daub_walls, framed_construction | — | — |
| 36 | `flood_house_mounds` — House mounds raised above flood | flood_mark_reading | — | adobe_wall_construction | environment=river |
| 40 | `stone_wall_footings` — Stone footings under earthen walls | dry_stone_walls | any of adobe_wall_construction, wattle_and_daub_walls | — | — |
| 44 | `flat_clay_roofs` — Flat roofs of beams, reeds and packed clay | framed_construction, adobe_wall_construction | — | — | environment=dry |
| 48 | `mould_made_mudbricks` — Mould-made mudbricks | adobe_wall_construction, clay_tempering | — | notched_measuring_rods | resources_known=Clay |
| 52 | `lime_plastered_floors` — Lime-plastered floors and walls | lime_burning | — | — | — |
| 55 | `wedges_and_levers` — Wedges, levers and rollers for heavy stones | dry_stone_walls | — | rollers_and_runners, timber_seasoning | — |
| 58 | `bitumen_sealing` — Bitumen waterproofing for floors and sills | mould_made_mudbricks | — | lime_plastered_floors | resources_known=Bitumen |
| 72 | `footing_soil_judging` — Footing soil judged before building | stone_wall_footings, topsoil_depth_reading | — | — | — |
| 75 | `refuge_point_designation` — Refuge points agreed before floods | refuge_point_marking, flood_mark_reading | — | — | environment=river |
| 80 | `megalith_raising` — Megaliths raised with earth ramps, levers and ropes | wedges_and_levers, work_party_feasts | — | rollers_and_runners, hauling_chants | min_population=100 |
| 88 | `seasonal_path_maintenance` — Paths repaired each season | trail_waymarking, seasonal_work_round | — | — | — |
| 95 | `central_hall_houses` — Tripartite central-hall house | mould_made_mudbricks, flat_clay_roofs | — | — | — |
| 105 | `river_supply_channels` — Supply channels dug from river to settlement | drainage, flood_mark_reading | — | task_captains | environment=river |
| 115 | `bracing_inspection_rounds` — Bracing inspection rounds | framed_construction, task_captains | — | rotating_inspection_duty | — |
| 120 | `communal_upkeep_scheduling` — Communal upkeep scheduling | seasonal_path_maintenance, slack_season_building | — | — | — |
| 122 | `dwelling_site_orientation` — Dwellings oriented to sun and wind | sightline_staking, solstice_horizon_markers | — | — | — |
| 125 | `storm_response_drill` — Storm response drill | dawn_readiness_drill, hazard_landmark_memory | — | weather_sign_reading | — |
| 135 | `flood_levees` — Earthen dykes and levees against floods | flood_house_mounds, great_work_parties | — | — | environment=river |
| 150 | `shrine_terraces` — Shrine terrace of packed earth and brick | mould_made_mudbricks, first_shrine_house | — | central_hall_houses | — |
| 155 | `corner_squaring_method` — Corners squared with a cord triangle | sightline_staking, standard_measures | — | cordage | — |
| 158 | `public_space_allocation` — Public space allocated | common_ground_marking, public_stores | — | — | min_population=150 |
| 160 | `warning_call_relay` — Warning calls relayed | alarm_relay_signals, storm_response_drill | — | — | — |
| 170 | `courtyard_storerooms` — Storerooms with sealed doors around a court | central_hall_houses, stamp_seals | — | sealed_store_doors | — |
| 180 | `timber_post_beam_connections` — Mortised post-and-beam frames cut with copper chisels | framed_construction, copper_casting | — | timber_seasoning | — |
| 190 | `niched_brick_facades` — Buttressed and niched mudbrick façades | mould_made_mudbricks, shrine_terraces | — | — | — |
| 200 | `rainwater_cisterns` — Lime-plastered rainwater cisterns | lime_plastered_floors | — | clay_lined_storage_pits, drainage | environment=dry |
| 210 | `stone_lined_drains` — Stone-lined lane drains | drainage, dry_stone_walls | — | public_space_allocation | — |
| 220 | `wedge_and_fire_quarrying` — Quarrying with wedges, pounders and fire | wedges_and_levers, stone_grain_judging | — | fire_setting_mining | — |
| 235 | `clay_pipe_forming` — Fired clay drain pipes | kiln_control, stone_lined_drains | — | wheel_thrown_pottery, tournette | — |
| 240 | `course_leveling_practice` — Courses levelled as walls rise | rod_and_cord_leveling, mould_made_mudbricks | — | — | — |
| 242 | `ground_bearing_assessment` — Ground bearing assessment | footing_soil_judging | — | course_leveling_practice | — |
| 245 | `post_disaster_damage_survey` — Damage surveyed after a disaster | bracing_inspection_rounds | — | disaster_recovery_roles, storm_response_drill | — |
| 248 | `runoff_grade_reading` — Runoff grade reading | stone_lined_drains, rod_and_cord_leveling | — | — | — |
| 255 | `ceramic_pipe_firing_qualification` — Pipe sections fired to a tested standard | clay_pipe_forming, output_quality_sorting | — | — | — |
| 260 | `courtyard_houses` — Multi-room courtyard houses | courtyard_storerooms | — | corner_squaring_method | — |
| 268 | `load_path_reading` — Load path reading | timber_post_beam_connections, ground_bearing_assessment | — | — | — |
| 270 | `shared_work_crew_rotation` — Shared work crew rotation | labor_rotations, communal_upkeep_scheduling | — | rotating_heavy_tasks | — |
| 275 | `corbelled_vaults` — Corbelled stone vaults and passages | dry_stone_walls, megalith_raising | — | load_path_reading | — |
| 285 | `post_storm_resource_pooling` — Resources pooled after a storm | storm_response_drill, public_stores | — | mutual_aid_customs | — |
| 290 | `diversion_dams` — Rubble diversion dams and reservoirs | river_supply_channels, flood_levees | — | runoff_grade_reading | environment=river |
| 300 | `town_enclosure_walls` — Mudbrick town enclosure wall | mould_made_mudbricks, great_work_parties | — | ditch_palisades | min_population=500 |
| 315 | `herringbone_plano_convex_brick` — Plano-convex brick laid in herringbone courses | mould_made_mudbricks, course_leveling_practice | — | — | — |
| 330 | `kiln_fired_bricks` — Kiln-fired bricks for wet courses | mould_made_mudbricks, kiln_control | — | clay_pipe_forming, charcoal | — |
| 340 | `gypsum_mortar` — Gypsum mortar for stone and brick | lime_burning | — | lime_plastered_floors | resources_known=Gypsum |
| 350 | `dressed_stone_masonry` — Dressed-stone masonry with copper tools | wedge_and_fire_quarrying, copper_carpentry_tools, corner_squaring_method | — | — | — |
| 360 | `rammed_earth_construction` — Pounded-earth walls in board forms | timber_seasoning, course_leveling_practice | — | adobe_wall_construction | — |
| 370 | `stepped_stone_tombs` — Stepped stone tomb: ramps, sledges and wetted tracks | dressed_stone_masonry, great_work_parties | — | wetted_track_sledging, chamber_tombs | institutions_min=0.6 |
| 378 | `public_works_priority_review` — Public works priority review | communal_upkeep_scheduling, problem_council_sessions | — | — | — |
| 380 | `structural_repair_triage` — Structural repair triage | post_disaster_damage_survey, load_path_reading | — | — | — |
| 382 | `seasonal_hazard_calendar` — Seasonal hazard calendar | storm_response_drill, solar_year_reckoning | — | flood_mark_reading | — |
| 385 | `lime_mortar` — Lime mortar for stone and brick courses | lime_burning, course_leveling_practice | — | gypsum_mortar | — |
| 390 | `wedge_brick_well_lining` — Well shafts lined with wedge-shaped bricks | lined_well_shafts, kiln_fired_bricks | — | — | — |
| 395 | `wadi_dams` — Stone-faced dam across a wadi | diversion_dams, dressed_stone_masonry | — | — | environment=dry |
| 400 | `fired_roof_tiles` — Fired roof tiles | kiln_fired_bricks, timber_post_beam_connections | — | — | — |
| 405 | `upper_storeys` — Upper storeys on timber joists | timber_post_beam_connections, load_path_reading | — | courtyard_houses | — |
| 410 | `bitumen_bedded_brick` — Bitumen-bedded brick for baths and drains | bitumen_sealing, kiln_fired_bricks | — | — | — |
| 420 | `covered_sewers` — Brick-covered street drains | stone_lined_drains, kiln_fired_bricks | — | urban_street_plans | — |
| 425 | `rigid_pipe_bedding` — Pipes laid in bedded, graded trenches | ceramic_pipe_firing_qualification, runoff_grade_reading | — | covered_sewers, water_trough_leveling | — |
| 430 | `standard_brick_proportions` — Standard brick proportions (1:2:4) | mould_made_mudbricks, standard_unit_naming | — | brick_quotas | — |
| 435 | `masonry_bond_patterns` — Header-and-stretcher brick bonds | standard_brick_proportions, course_leveling_practice | — | — | — |
| 440 | `urban_street_plans` — Planned street grid with house blocks | public_space_allocation, corner_squaring_method | — | geometric_survey | min_population=1000 |
| 445 | `building_drainage_coordination` — Roof runoff led into drains | covered_sewers | — | runoff_grade_reading, flat_clay_roofs | — |
| 450 | `ventilated_granaries` — Raised granary with air channels | raised_granaries | — | store_airflow_arrangement, kiln_fired_bricks | — |
| 455 | `pitched_brick_vaults` — Pitched-brick barrel vaults without centering | masonry_bond_patterns, load_path_reading | — | corbelled_vaults, gypsum_mortar | — |
| 460 | `shaduf_water_lift` — Shaduf water lift | wedges_and_levers, irrigation_schedules | — | river_supply_channels | — |
| 470 | `reed_mat_brick_layers` — Reed-mat and cable layers in mass brick | mould_made_mudbricks, woven_carriers, rope_laying | — | stepped_temple_towers | environment=river |
| 480 | `stepped_temple_towers` — Stepped temple tower of solid brick | shrine_terraces, reed_mat_brick_layers | — | kiln_fired_bricks, bitumen_bedded_brick | institutions_min=0.6 |
| 490 | `brick_mass_drain_shafts` — Drain shafts through a brick mass | stepped_temple_towers | — | building_drainage_coordination | — |
| 500 | `wooden_log_conduits` — Hollowed-log water channels | river_supply_channels, timber_seasoning | — | — | environment=woodland |
| 510 | `clay_pipe_socket_jointing` — Tapered, socketed terracotta pipes | rigid_pipe_bedding, wheel_thrown_pottery | — | — | — |
| 520 | `timber_splice_connections` — Scarf joints for long timber beams | timber_post_beam_connections, copper_carpentry_tools | — | — | — |
| 530 | `light_wells` — Light wells and ventilated rooms | upper_storeys, courtyard_houses | — | — | — |
| 540 | `building_shading_design` — Eaves and screens shading walls | dwelling_site_orientation, timber_post_beam_connections | — | — | — |
| 550 | `ceramic_pipe_fit_gauges` — Gauges for pipe socket fit | clay_pipe_socket_jointing, template_based_sizing | — | — | — |
| 560 | `ashlar_masonry` — Ashlar courses fitted without mortar | dressed_stone_masonry, bronze_work_hardening | — | plumb_line_sighting | — |
| 570 | `mine_shoring` — Mine galleries propped with timber | fire_setting_mining, timber_post_beam_connections | — | — | — |
| 580 | `cistern_flushed_drains` — Palace drains flushed from roof cisterns | rainwater_cisterns, building_drainage_coordination | — | — | — |
| 590 | `timber_laced_walls` — Rubble walls laced with timber against earthquakes | stone_wall_footings, timber_post_beam_connections | — | timber_splice_connections, post_disaster_damage_survey | — |
| 600 | `colonnaded_porticoes` — Colonnaded porticoes on stone bases | dressed_stone_masonry, timber_post_beam_connections | — | ashlar_masonry, urban_street_plans | — |
