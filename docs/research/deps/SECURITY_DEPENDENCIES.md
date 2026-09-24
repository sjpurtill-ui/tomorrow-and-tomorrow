# Security dependencies

Machine-readable source: `security.json`. Format: `MAPPING_CONTRACT.md`. Cross-line ids are listed by name. `resources_known` values are lists.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions |
|---|---|---|---|---|---|
| 2 | `watch_rotation` | - | - | - | - |
| 3 | `alarm_relay_signals` | - | - | relay_call_stations | - |
| 4 | `dawn_readiness_drill` | - | - | watch_rotation | - |
| 5 | `emergency_food_caching` | - | - | edible_resource_recognition | - |
| 6 | `refuge_point_marking` | hazard_landmark_memory | - | alarm_relay_signals | - |
| 7 | `hafted_weapons` | hafted_tools | - | controlled_flaking | - |
| 8 | `hazard_memory_recitation` | hazard_landmark_memory | - | oral_epics | - |
| 9 | `bow_craft` | timber_grading, cordage | - | controlled_flaking | - |
| 10 | `sparring_customs` | hafted_weapons | - | - | - |
| 12 | `war_slings` | cordage | - | stone_sorting | - |
| 15 | `hide_wicker_shields` | basketry, hide_smoke_curing | - | - | - |
| 18 | `throwing_spears` | hafted_weapons | - | - | - |
| 20 | `stone_maceheads` | hafted_tools, ground_stone_axes | - | bow_drill_drive | - |
| 22 | `ambush_raids` | sparring_customs | - | dawn_readiness_drill | - |
| 25 | `herd_recovery_pursuit` | animal_taming | - | ambush_raids | - |
| 35 | `clay_sling_bullets` | war_slings, pit_firing | - | - | - |
| 40 | `raid_scouting` | ambush_raids | - | distance_call_signals | - |
| 45 | `thorn_barriers` | hafted_tools | - | watch_rotation, refuge_point_marking | - |
| 50 | `weapon_free_gatherings` | guest_host_reciprocity | - | reciprocal_gift_exchange | - |
| 55 | `hostage_exchange` | weapon_free_gatherings | - | village_marriage_alliances | - |
| 70 | `defensive_ditch_siting` | thorn_barriers, sightline_staking | - | slack_season_building | - |
| 78 | `disaster_recovery_roles` | refuge_point_marking | - | seasonal_crisis_leader, hazard_memory_recitation | - |
| 85 | `truce_sanctuary` | weapon_free_gatherings, sacred_places | - | - | - |
| 90 | `ditch_palisades` | defensive_ditch_siting, framed_construction | - | slack_season_building | environment=woodland |
| 95 | `perimeter_patrol_customs` | watch_rotation | - | ditch_palisades, watch_duty_rotation | - |
| 100 | `barred_palisade_gates` | ditch_palisades, joinery | - | - | - |
| 105 | `post_disaster_headcount_custom` | disaster_recovery_roles, counting_words | - | - | - |
| 110 | `hilltop_refuges` | dry_stone_walls, refuge_point_marking | - | great_work_parties | - |
| 120 | `joint_hamlet_defense_pacts` | hostage_exchange | - | village_marriage_alliances, witnessed_agreement_customs | min_settlements=2 |
| 125 | `signal_command_drill` | ambush_raids, distance_call_signals | - | - | - |
| 135 | `paired_veteran_mentoring` | sparring_customs, mentored_task_learning | - | - | - |
| 145 | `cast_copper_weapons` | copper_casting, hafted_weapons | - | - | resources_known=Copper |
| 150 | `neighbor_shelter_pledges` | joint_hamlet_defense_pacts | - | mutual_aid_customs | - |
| 152 | `rotating_watch_captaincy` | watch_duty_rotation, task_captains | - | - | - |
| 158 | `fallback_route_marking` | refuge_point_designation, trail_waymarking | - | - | - |
| 180 | `market_peacekeepers` | truce_sanctuary, perimeter_patrol_customs | - | boundary_exchange_sites | - |
| 190 | `copper_maceheads` | cast_copper_weapons | - | stone_maceheads | - |
| 195 | `mutual_aid_pacts` | neighbor_shelter_pledges, mutual_aid_customs | - | - | - |
| 200 | `copper_daggers` | cast_copper_weapons | - | sheet_copper_riveting | - |
| 210 | `rotating_command_practice` | rotating_watch_captaincy, signal_command_drill | - | - | - |
| 225 | `coordinated_retreat_drill` | signal_command_drill, fallback_route_marking | - | - | - |
| 230 | `gate_watchtowers` | barred_palisade_gates, timber_post_beam_connections | - | - | - |
| 240 | `alarm_relay_customs` | alarm_relay_signals, warning_call_relay | - | drum_relay_signals | - |
| 250 | `night_gate_challenge` | barred_palisade_gates, perimeter_patrol_customs | - | guest_host_reciprocity | - |
| 260 | `common_armory` | cast_copper_weapons, public_stores | - | marked_storage_registers | - |
| 270 | `multi_post_command_relay` | alarm_relay_customs, rotating_command_practice | - | - | - |
| 272 | `rotating_relief_wardens` | rotating_watch_captaincy, gate_watchtowers | - | - | - |
| 285 | `combined_drill_musters` | paired_veteran_mentoring, joint_hamlet_defense_pacts | - | regional_levy_coordination | - |
| 290 | `household_muster` | hearth_counts, combined_drill_musters | - | census_rolls | institutions_min=0.3 |
| 295 | `formation_drill` | signal_command_drill, combined_drill_musters | - | - | - |
| 300 | `field_fortifications` | defensive_ditch_siting, supply_groups | - | - | - |
| 305 | `fortified_stores` | courtyard_storerooms | any of town_enclosure_walls/ditch_palisades | sealed_store_doors | - |
| 310 | `shield_wall` | formation_drill, hide_wicker_shields | - | - | - |
| 330 | `wall_missile_posts` | town_enclosure_walls | any of bow_craft/clay_sling_bullets | - | - |
| 340 | `flanked_gate_complex` | town_enclosure_walls, gate_watchtowers | - | kiln_fired_bricks | - |
| 350 | `copper_battle_axes` | cast_copper_weapons, bivalve_moulds | - | arsenical_copper | - |
| 360 | `layered_defense_coordination` | multi_post_command_relay, flanked_gate_complex | - | - | - |
| 370 | `palace_guard` | kingship | - | rotating_relief_wardens | institutions_min=0.6 |
| 380 | `massed_formation_training` | formation_drill, household_muster | - | - | - |
| 390 | `battle_wagons` | onager_hybrid_teams | - | throwing_spears | - |
| 395 | `standing_relief_stores` | emergency_food_caching, central_storehouses | - | - | - |
| 400 | `bronze_weaponry` | bronze_alloying, common_armory | - | closed_moulds | resources_known=Copper/Tin |
| 405 | `copper_helmets` | sheet_copper_riveting | - | bronze_weaponry, leather_goods_patterning | - |
| 415 | `deep_phalanx` | massed_formation_training, shield_wall | - | bronze_weaponry | - |
| 420 | `scaling_ladders_rams` | town_enclosure_walls, timber_post_beam_connections | - | massed_formation_training | - |
| 440 | `standing_paid_company` | palace_guard, fixed_worker_rations | - | codified_tribute_schedules | institutions_min=0.6 |
| 450 | `socketed_spearheads` | bronze_weaponry, closed_moulds | - | - | - |
| 460 | `composite_bow` | bow_craft, hide_tanning | - | timber_seasoning | - |
| 470 | `sentry_watchwords` | night_gate_challenge, agreed_signal_codes | - | - | - |
| 480 | `siege_ramps_mining` | scaling_ladders_rams, great_work_parties | - | fire_setting_mining | - |
| 500 | `war_chariots` | spoked_wheel_assembly, domesticated_mounts, bronze_weaponry | - | battle_wagons | - |
| 505 | `shield_equipment_fitting` | war_chariots, hide_wicker_shields | - | leather_goods_patterning | - |
| 520 | `border_fortress_chains` | flanked_gate_complex, alarm_relay_customs | any of fire_smoke_signaling/drum_relay_signals | provincial_governors | - |
| 525 | `sickle_sword` | bronze_work_hardening, closed_moulds | - | copper_daggers | - |
| 530 | `chariot_crews` | war_chariots, composite_bow | - | paired_veteran_mentoring | - |
| 540 | `glacis_ramparts` | town_enclosure_walls, siege_ramps_mining | - | lime_mortar | - |
| 545 | `written_patrol_reports` | border_fortress_chains, sealed_tablet_letters | - | - | - |
| 550 | `allied_contingents` | foreign_treaties, standing_paid_company | - | - | contact_required=True |
| 560 | `casemate_walls` | town_enclosure_walls, dressed_stone_masonry | - | flanked_gate_complex, glacis_ramparts | - |
| 575 | `bronze_rapiers` | bronze_work_hardening, closed_moulds | - | copper_daggers, sickle_sword | - |
| 590 | `scale_armor_attachment` | chariot_crews, bronze_work_hardening, leather_goods_patterning | - | - | - |
| 600 | `field_armorer_teams` | bronze_weaponry, supply_groups | - | pot_bellows, full_time_specialists | - |
