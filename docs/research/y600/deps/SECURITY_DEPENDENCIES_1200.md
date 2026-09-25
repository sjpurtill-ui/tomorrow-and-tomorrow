# Security dependencies, years 600–1200

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md`. Cross-line ids are marked with their line, and 0–600 ids are marked "0–600". `Requires (any)` groups are separated by `;`. A year marked `*` is a proposed move listed in `partials/pils_year_adjustments.json`.

Every iron weapon requires `bloomery_smelting`, directly or through `forge_welding` or `smithing_tool_sets`. Those are `iron_sword_issue`, `iron_arrowheads`, `iron_spear_levy`, `curved_chopping_sword` and `steel_cavalry_swords`. `steel_cavalry_swords` needs crucible steel or piled blades.

The engine chain is `crossbow_mechanism` (847) → `bolt_throwing_frames` (855) → `torsion_spring_engines` (876). Torsion also needs one of these: precise measure (`graduated_measuring_rods`, knowledge 645) or sinew-spring knowledge (`composite_bow`, 0–600 460).

`mail_armor_fabrication` requires `wire_drawing` and riveting (`forged_iron_nails`).

Cavalry path: `mounted_scouts` → `armored_riding` / `mounted_archery` → `chariot_to_cavalry_shift` → `wedge_shock_cavalry` → `armored_horse_cataphracts` → `two_handed_lancers`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 615 | `bronze_plate_corselet` | `scale_armor_attachment` (0–600), `raised_bronze_vessels` (production, 0–600) | - | `chariot_crews` (0–600) | - | Raised bronze plates for chariot nobles. |
| 625 | `chariot_runners` | `chariot_crews` (0–600) | - | `throwing_spears` (0–600) | - | Foot troops paired with chariots. |
| 645 | `cut_and_thrust_sword` | `bronze_rapiers` (0–600), `bronze_work_hardening` (production, 0–600) | - | - | - | Rapier lengthened and hardened to cut. |
| 650 | `sally_ports_cistern_stairs` | `casemate_walls` (0–600), `rainwater_cisterns` (infrastructure, 0–600) | - | `flanked_gate_complex` (0–600) | - | Hidden exits and water inside walls. |
| 655 | `coastal_raider_watch` | `prearranged_beacon_chains` (knowledge, 0–600), `perimeter_patrol_customs` (0–600) | - | - | environment=coast | Beacon chain faces the sea. |
| 660 | **`professional_corps`** | `standing_paid_company` (0–600) | - | `palace_guard` (0–600) | - | Paid company kept permanently. |
| 662 | `galley_navigation` | `coastal_watercraft` (logistics, 0–600), `pilots_sea_lanes` (logistics, 0–600) | - | `signal_command_drill` (0–600) | - | Oared craft sail as a fleet. |
| 664 | `naval_arsenals` | `galley_navigation`, `harbor_warehouses` (logistics, 0–600) | - | - | - | Fleet stores and yards. |
| 668 | `amphibious_operations` | `galley_navigation` | - | `ambush_raids` (0–600) | - | Galleys land raiding parties. |
| 690 | **`iron_sword_issue`** | `bloomery_smelting` (production), `forge_welding` (production) | - | `cut_and_thrust_sword`, `common_armory` (0–600) | - | Welded bloomery iron forged into swords. |
| 695 | `town_night_curfew` | `night_gate_challenge` (0–600), `ward_residence_lists` (demography, 0–600) | - | `sentry_watchwords` (0–600) | - | Quarters barred by ward at night. |
| 700 | `textile_armor_layering` | `fine_linen_counts` (production) | - | `shield_equipment_fitting` (0–600) | - | Glued linen layers as armor. |
| 702 | `lamellar_armor_assembly` | `scale_armor_attachment` (0–600) | - | `textile_armor_layering` | - | Scales laced to each other. |
| 704 | `mounted_scouts` | `domesticated_mounts` (logistics, 0–600), `raid_scouting` (0–600) | - | - | - | Scouts ride ahead. |
| 706 | `skirmisher_infantry_screens` | `war_slings` (0–600), `throwing_spears` (0–600) | - | `formation_drill` (0–600) | - | Missile troops screen the line. |
| 708 | `skirmish_pair_drill` | `skirmisher_infantry_screens` | - | `paired_veteran_mentoring` (0–600) | - | Skirmishers cover each other in pairs. |
| 715 | `iron_arrowheads` | `bloomery_smelting` (production), `smithing_tool_sets` (production) | - | `socketed_spearheads` (0–600) | - | Bloomery iron punched into heads. |
| 720 | `armored_riding` | `mounted_scouts`, `lamellar_armor_assembly` | - | - | - | Riders wear lamellar. |
| 722 | **`mounted_archery`** | `composite_bow` (0–600), `mounted_scouts` | - | `armored_riding` | - | Composite bows shot from horseback. |
| 724 | **`siege_engineering`** | `siege_ramps_mining` (0–600), `scaling_ladders_rams` (0–600) | - | `professional_corps` | - | Siege methods joined as one trade. |
| 728 | `paired_rider_teams` | `mounted_archery` | - | `chariot_crews` (0–600) | - | Chariot pairing kept on horseback. |
| 732 | **`iron_spear_levy`** | `bloomery_smelting` (production), `smithing_tool_sets` (production), `socketed_spearheads` (0–600) | - | `household_muster` (0–600) | - | Cheap bloomery iron arms the levy. |
| 740 | `wheeled_siege_towers` | `siege_engineering`, `cart_running_gear` (logistics, 0–600) | - | - | - | Towers on wheels with rams. |
| 742 | `camel_riders` | `camel_caravans` (logistics) | - | `mounted_scouts` | environment=dry | Caravan camels ridden to patrol. |
| 745 | `bronze_ram_galleys` | `galley_navigation`, `bronze_alloying` (production, 0–600) | - | `naval_arsenals` | - | Cast bronze ram on a war galley. |
| 748 | `town_fire_watch` | `town_night_curfew` | - | `fire_tending_safeguards` (health, 0–600) | - | Night watch also watches for fire. |
| 760 | `siege_crew_rehearsals` | `siege_engineering` | - | `combined_drill_musters` (0–600) | - | Engineers drill before campaigns. |
| 762 | **`citizen_heavy_infantry`** | `deep_phalanx` (0–600), `bronze_weaponry` (0–600) | - | `household_muster` (0–600), `shield_wall` (0–600), `bronze_plate_corselet` | - | Citizens armed in panoply in the phalanx. |
| 770 | `closed_helmet_greaves` | `copper_helmets` (0–600), `raised_bronze_vessels` (production, 0–600) | - | `citizen_heavy_infantry` | - | Raised bronze encloses head and shins. |
| 778 | `chariot_to_cavalry_shift` | `armored_riding`, `mounted_archery` | - | `war_chariots` (0–600) | - | Riders outperform chariots. |
| 780 | `unit_rally_standards` | `formation_drill` (0–600), `signal_command_drill` (0–600) | - | `emblem_processions` (culture, 0–600) | - | Emblems mark each unit. |
| 784 | `siege_ration_reckoning` | `fortified_stores` (0–600), `graded_rations` (nutrition, 0–600) | - | `weight_conversion_tables` (knowledge) | - | Stores divided by mouths and days. |
| 788 | `road_bandit_patrols` | `mounted_scouts`, `perimeter_patrol_customs` (0–600) | - | `drained_intertown_roads` (infrastructure) | - | Riders patrol trade roads. |
| 792 | `contracted_mercenary_captains` | `allied_contingents` (0–600), `silver_wage_payment` (labor) | - | `professional_corps` | - | Captains hired for silver by season. |
| 797 | **`three_banked_warships`** | `bronze_ram_galleys`, `frame_moulding` (logistics) | - | `rower_levies` (labor) | - | Moulded hulls carry three banks. |
| 805 | `wet_moats` | `town_enclosure_walls` (infrastructure, 0–600), `diversion_dams` (infrastructure, 0–600) | - | `glacis_ramparts` (0–600) | - | Diverted water fills the ditch. |
| 828 | `city_port_long_walls` | `town_enclosure_walls` (infrastructure, 0–600), `stone_quays` (infrastructure) | - | `rubble_core_walling` (infrastructure) | - | Walls link town and harbor. |
| 832 | `siege_evacuation_orders` | `siege_ration_reckoning` | - | `forced_resettlement` (demography) | - | Ration count sends mouths away. |
| 847 | **`crossbow_mechanism`** | `composite_bow` (0–600), `lost_wax_casting` (production, 0–600) | - | `iron_files_rasps` (production) | - | Cast trigger holds a drawn bow. |
| 849 | `cavalry_infantry_liaison` | `chariot_to_cavalry_shift`, `unit_rally_standards` | - | - | - | Cavalry and foot coordinated. |
| 852 | `multivallate_hillforts` | `glacis_ramparts` (0–600), `hilltop_refuges` (0–600) | - | `defensive_ditch_siting` (0–600) | - | Ramparts multiplied on hilltops. |
| 855 | `bolt_throwing_frames` | `crossbow_mechanism` | - | `siege_engineering` | - | Crossbow enlarged on a stand. |
| 858 | `scythed_chariots` | `war_chariots` (0–600), `iron_farm_tools` (production) | - | `chariot_runners` | - | Iron scythes fixed to chariots. |
| 862 | `curved_chopping_sword` | `forge_welding` (production), `hardened_edges` (production) | - | `sickle_sword` (0–600) | - | Hardened iron in a curved blade. |
| 866 | `bowshot_tower_spacing` | `wall_missile_posts` (0–600), `flanked_gate_complex` (0–600) | - | `composite_bow` (0–600) | - | Towers spaced by bow range. |
| 870 | `traction_stone_throwers` | `siege_engineering`, `rope_laying` (logistics, 0–600) | - | `wedges_and_levers` (infrastructure, 0–600) | - | Crew-pulled beam sling. |
| 874 | `siege_defense_manual` | `siege_engineering`, `authored_prose_treatises` (knowledge) | - | `sally_ports_cistern_stairs` | - | Defense practice written as a treatise. |
| 876 | **`torsion_spring_engines`** | `bolt_throwing_frames` | `graduated_measuring_rods` (knowledge), `composite_bow` (0–600) | `rope_laying` (logistics, 0–600) | - | Sinew skeins sized by precise measure. |
| 878 | `long_pike_phalanx` | `citizen_heavy_infantry`, `iron_spear_levy` | - | `massed_formation_training` (0–600) | - | Longer iron pikes in close ranks. |
| 880 | `wedge_shock_cavalry` | `armored_riding`, `cavalry_infantry_liaison` | - | - | - | Armored riders charge in wedge. |
| 883 | `countermine_listening` | `siege_ramps_mining` (0–600) | - | `siege_defense_manual` | - | Defenders listen for and meet mines. |
| 886 | `incendiary_missiles` | `bow_craft` (0–600), `bitumen_sealing` (infrastructure, 0–600) | - | `siege_defense_manual`, `sulfur_purification` (production, 0–600) | - | Bitumen and pitch set alight on missiles. |
| 893 | **`mail_armor_fabrication`** | `wire_drawing` (production), `forged_iron_nails` (production) | - | `lamellar_armor_assembly` | - | Drawn wire rings riveted into mail. |
| 897 | `manipular_lines` | `citizen_heavy_infantry`, `unit_rally_standards` | - | `skirmish_pair_drill` | - | Phalanx broken into maniples under standards. |
| 903 | `standard_trigger_locks` | `crossbow_mechanism`, `closed_moulds` (production, 0–600) | - | `workshop_task_division` (labor) | - | Trigger cast to one pattern. |
| 910 | `engine_proof_walls` | `rubble_core_walling` (infrastructure), `bowshot_tower_spacing` | - | `torsion_spring_engines` | - | Thick walls and towers for artillery. |
| 915 | `boarding_bridges` | `three_banked_warships` | - | `timber_splice_connections` (infrastructure, 0–600) | - | Hinged bridge for boarding. |
| 925 | `wall_repair_levy` | `town_enclosure_walls` (infrastructure, 0–600), `public_levies` (institutions, 0–600) | - | `structural_repair_triage` (infrastructure, 0–600) | - | Walls repaired by levy after disaster. |
| 935 | **`frontier_long_walls`** | `border_fortress_chains` (0–600), `rubble_core_walling` (infrastructure) | - | `prearranged_beacon_chains` (knowledge, 0–600) | - | Fortress chain joined by a wall. |
| 940 | `nightly_marching_camps` | `field_fortifications` (0–600), `professional_corps` | - | `standard_lot_grid_towns` (infrastructure) | - | Drilled troops entrench nightly. |
| 943 | `heavy_javelin_volley` | `manipular_lines`, `throwing_spears` (0–600) | - | `iron_spear_levy` | - | Maniples throw before closing. |
| 950 | **`armored_horse_cataphracts`** | `armored_riding`, `mail_armor_fabrication` | - | `lamellar_armor_assembly`, `wedge_shock_cavalry` | - | Mail and lamellar on horse and rider. |
| 955 | `portcullis_gates` | `flanked_gate_complex` (0–600) | `counterweight_cranes` (infrastructure), `windlass_wells` (infrastructure) | - | - | Gate grille raised by windlass. |
| 962 | `rotating_crossbow_ranks` | `standard_trigger_locks`, `massed_formation_training` (0–600) | - | - | - | Ranks reload and shoot in turn. |
| 968 | `steel_cavalry_swords` | `edge_tempering` (production) | `crucible_steel_cakes` (production), `piled_blade_welding` (production) | `armored_riding` | - | Tempered steel in a long riding sword. |
| 985 | `standard_kit_issue` | `professional_corps`, `workshop_quotas` (institutions, 0–600) | - | `contracted_mercenary_captains` | - | Kit issued from quota workshops. |
| 988 | `timber_laced_ramparts` | `timber_laced_walls` (infrastructure, 0–600), `multivallate_hillforts` | - | - | environment=woodland | Timber lacing in hillfort ramparts. |
| 992 | **`horned_riding_saddle`** | `pack_saddles` (logistics, 0–600), `armored_riding` | - | `framed_camel_saddle` (logistics) | - | Framed saddle with horns holds a rider. |
| 1000 | `anti_piracy_squadrons` | `three_banked_warships`, `coastal_raider_watch` | - | - | - | Warships sweep the sea lanes. |
| 1004 | `recruit_drill_schools` | `massed_formation_training` (0–600), `professional_corps` | - | `skirmish_pair_drill` | - | Standing corps trains recruits. |
| 1012 | `army_bridging_engineers` | `pontoon_bridges` (infrastructure), `siege_engineering` | - | `timber_pile_foundations` (infrastructure) | - | Engineers bridge rivers on campaign. |
| 1036 | **`long_service_enlistment`** | `standing_paid_company` (0–600), `standard_kit_issue` | - | `military_pension_treasury` (institutions), `veteran_land_allotments` (demography) | - | Fixed terms with discharge pay. |
| 1040 | `banded_plate_cuirass` | `forge_welding` (production), `forged_iron_nails` (production) | - | `lamellar_armor_assembly`, `mail_armor_fabrication` | - | Iron bands riveted on leather. |
| 1046 | `crossbow_sight_graduation` | `standard_trigger_locks`, `graduated_measuring_rods` (knowledge) | - | - | - | Graduated sight on the stock. |
| 1052 | `force_pump_fire_engines` | `piston_force_pumps` (infrastructure), `town_fire_watch` | - | `paid_fire_brigades` (labor) | - | Force pump carried to fires. |
| 1062 | `permanent_frontier_fortresses` | `frontier_long_walls`, `nightly_marching_camps` | - | `mass_rubble_concrete` (infrastructure) | - | Camps rebuilt in stone on the wall. |
| 1082 | `lath_stiffened_bow` | `composite_bow` (0–600) | - | `mounted_archery` | - | Bone laths stiffen bow tips. |
| 1088 | `frontier_spy_service` | `trunk_road_courier_relay` (logistics), `written_patrol_reports` (0–600) | - | `letter_substitution_cipher` (knowledge) | - | Courier relay carries frontier intelligence. |
| 1100 | `guarded_road_posts` | `road_bandit_patrols`, `road_stations` (logistics, 0–600) | - | `state_post_passes` (logistics) | - | Patrols garrisoned at stations. |
| 1115 | `treaty_border_levies` | `allied_contingents` (0–600), `foreign_treaties` (institutions, 0–600) | - | `frontier_long_walls` | - | Treaty peoples furnish frontier troops. |
| 1145 | `army_grain_levy` | `forward_supply_depots` (logistics), `codified_tribute_schedules` (institutions, 0–600) | - | `graded_land_tax` (institutions) | - | Grain levied in kind for forts. |
| 1150 | `two_handed_lancers` | `armored_horse_cataphracts` | - | `wedge_shock_cavalry` | - | Mailed riders with long lances. |
| 1165 | `contracted_circuit_walls` | `engine_proof_walls`, `bowshot_tower_spacing` | - | `brick_faced_concrete` (infrastructure) | - | Shorter walls with projecting towers. |
| 1175 | `single_mounting_stirrup` | `horned_riding_saddle` | - | - | - | Loop hung from the saddle to mount. |
| 1178 | **`mobile_field_reserves`** | `long_service_enlistment`, `permanent_frontier_fortresses` | - | `army_grain_levy` | - | Field army held behind fortresses. |
| 1196 | `river_watch_posts` | `guarded_road_posts` | - | `river_toll_stations` (logistics), `permanent_frontier_fortresses` | - | Road posts applied to river frontiers. |
