# Security dependencies, years 2400–3000

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md` and the 600–1200, 1200–1800 and 1800–2400 partials. Cross-line ids are marked with their line. Earlier-block ids are marked "0–600", "600–1200", "1200–1800" or "1800–2400". `Requires (any)` groups are separated by `;`. Every prerequisite and precedent is dated at or before its dependent (adjusted years from `partials/pils_year_adjustments.json`; registry years for other lines; proposed years for earlier blocks). Catalog ids keep the prerequisites written in `scripts/*.gd`, except where a catalog prerequisite is dated after its dependent; those cases are resolved by a year move inside the registry band or listed below. Years marked "was" are moved in `partials/pils_year_adjustments.json`.

Firearms: `flintlock_ignition` + `isolated_airs_chemistry` → **`percussion_cap_ignition`** (2453) → needle rifle, revolvers, **`expanding_base_bullet`** (2531) → **`metallic_cartridges`** (2560) → repeaters, volley guns → **`automatic_actions`** (2624) → machine-gun companies → **`continuous_trench_systems`** (2704). `aromatic_nitration` (production) → **`stable_blasting_explosive`** (2579) → **`smokeless_propellant`** (2627) → with `rifled_breech_artillery`, **`recoil_absorbing_field_gun`** (2659).

Fleets: `steam_propulsion` → paddle and screw warships → **`armored_hulls`** (2557) → turrets → with `steam_turbine_ships` (logistics), **`all_big_gun_battleships`** (2683). `naval_torpedoes` (2577) → **`submersible_hulls`** (2667) → convoys and sound ranging; with Infrastructure's `reactor_engineering`, `nuclear_propulsion` (2810).

Staffs and police: `military_staffs` + `officer_war_games` → **`staff_war_college`** (2427) → naval college, policy doctrine. `magistrates_runners` + `capital_police_lieutenant` → **`uniformed_beat_police`** (2477) → rural police, detectives, fingerprints, political police → `state_intelligence_service` (2691).

Weapons of mass destruction are research items only: `chemical_gas_warfare` (2708), **`fission_weapon`** (2787), **`thermonuclear_weapon`** (2805), **`intercontinental_missiles`** (2818) and `missile_submarine_patrols` (2826). No non-weapon item requires them: treaties (`gas_germ_weapon_ban`, `nuclear_test_ban_treaties`), `nuclear_civil_defence`, `launch_warning_satellites`, `hypersonic_glide_vehicles`, `rival_capital_hotline` and Logistics' `orbital_satellite_launch` list them only as precedents. `deterrence_doctrine` is the one doctrine that requires `thermonuclear_weapon`. The effects pass must forbid generals from using any of these on their own authority; see the report for the list.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 2405 | **`all_arms_army_corps`** | `all_arms_divisions` (1800–2400), `military_staffs` (1800–2400) | - | `military_survey_maps` (1800–2400) | - | Corps of divisions under one commander. |
| 2411 | **`class_year_conscription`** | `nation_in_arms_levy` (1800–2400), `canton_regimental_rolls` (1800–2400) | - | - | - | Young men called up by class-year. |
| 2413 | `rifle_skirmisher_battalions` | `light_troop_screens` (1800–2400), `rifled_barrels` (1800–2400) | - | `columns_behind_skirmishers` (1800–2400) | - | Rifle battalions screen the line. |
| 2416 | `spherical_case_shot` | `standardized_artillery_system` (1800–2400), `corned_powder_mills` (production, 1800–2400) | - | - | - | Shells of balls burst over troops. |
| 2417 | `economic_blockade_decrees` | `sail_battle_fleet` (1800–2400), `own_hull_navigation_law` (logistics, 1800–2400) | - | `customs_frontier_patrols` (1800–2400) | - | Decrees close whole coasts to enemy trade. |
| 2421 | `guerrilla_band_warfare` | `light_troop_screens` (1800–2400) | - | `nation_in_arms_levy` (1800–2400) | - | Irregular bands harass an occupying army. |
| 2427 | **`staff_war_college`** | `military_staffs` (1800–2400), `officer_war_games` (1800–2400) | - | `officer_cadet_schools` (1800–2400) | - | Staff officers trained in planning. |
| 2453 | **`percussion_cap_ignition`** | `flintlock_ignition` (1800–2400), `isolated_airs_chemistry` (knowledge, 1800–2400) | - | - | - | Percussion caps fire in the rain. |
| 2459 | `coast_guard_service` | `customs_frontier_patrols` (1800–2400) | - | `dovetailed_rock_lighthouse` (infrastructure, 1800–2400) | environment=coast | Coast stations watch for wrecks and smugglers. |
| 2464 | `naval_shell_guns` | `naval_gunnery` (1800–2400), `solid_bored_cannon` (1800–2400) | - | `spherical_case_shot` | - | Flat-firing shell guns at sea. |
| 2464 | `volunteer_lifeboat_rescue` | `coast_guard_service` | - | `insured_fire_brigades` (1800–2400) | environment=coast | Volunteer lifeboat crews on dangerous coasts. |
| 2469 | `masonry_casemate_forts` | `coastal_gun_forts` (1800–2400), `naval_shell_guns` | - | - | environment=coast | Casemate forts guard harbour mouths. |
| 2477 | **`uniformed_beat_police`** | `magistrates_runners` (1800–2400), `capital_police_lieutenant` (1800–2400) | - | - | - | Salaried uniformed police on fixed beats. |
| 2480 | `paddle_steam_warships` | `steam_propulsion` (production), `sail_battle_fleet` (1800–2400) | - | - | environment=coast | Paddle warships tow sailing ships into action. |
| 2485 | `war_as_policy_doctrine` | `staff_war_college` | - | - | - | War taught as the continuation of policy. |
| 2496 | `rural_constabulary` | `uniformed_beat_police`, `mounted_highway_constabulary` (1800–2400) | - | - | - | County police in the countryside. |
| 2497 | `revolving_pistols` | `percussion_cap_ignition`, `interchangeable_component_fits` (production) | - | - | - | Revolving pistols for horsemen and officers. |
| 2507 | `detached_fort_rings` | `fortress_frontier_belt` (1800–2400), `masonry_casemate_forts` | - | - | - | Detached forts ring great towns. |
| 2509 | `needle_breech_rifle` | `percussion_cap_ignition`, `rifled_barrels` (1800–2400) | - | `paper_cartridges` (1800–2400) | - | Breech-loading needle rifle. |
| 2512 | `detective_branch` | `uniformed_beat_police` | - | `printed_wanted_notices` (1800–2400) | - | Plain-clothes detectives. |
| 2523 | `screw_steam_warships` | `screw_propeller_ships` (logistics), `paddle_steam_warships` | - | - | environment=coast | Screw-propelled steam warships. |
| 2531 | **`expanding_base_bullet`** | `rifled_barrels` (1800–2400), `percussion_cap_ignition` | - | - | - | Expanding bullets load rifles quickly. |
| 2533 | `engineer_demonstration_ranges` | `siege_engineering` (600–1200), `experimental_controls` (knowledge, 1800–2400) | `professional_corps` (600–1200) / `military_staffs` (1800–2400) | - | - | Engineers demonstrate works on test ranges. |
| 2541 | `range_estimation_drill` | `standard_measures` (knowledge, 0–600) | `crossbow_mechanism` (600–1200) / `rifled_barrels` (1800–2400) | `expanding_base_bullet` | - | Musketry schools drill range judging and aimed fire. |
| 2544 | `field_telegraph_trains` | `electrical_telegraphy` (knowledge), `military_telegraph_lines` (1800–2400) | - | - | - | Telegraph wagons link headquarters to corps. |
| 2557 | **`armored_hulls`** | `steam_propulsion` (production), `naval_gunnery` (1800–2400) | - | `screw_steam_warships`, `naval_shell_guns` | - | Iron-armoured steam warships. |
| 2557 | **`railway_mobilization`** | `intercity_passenger_railway` (logistics), `military_staffs` (1800–2400) | - | `telegraph_train_dispatch` (logistics) | - | Troops sent to the frontier by timetable. |
| 2559 | `rifled_breech_artillery` | `rifled_barrels` (1800–2400), `standardized_artillery_system` (1800–2400), `steel_refining` (production, 1800–2400) | - | `needle_breech_rifle` | - | Rifled breech-loading artillery. |
| 2560 | **`metallic_cartridges`** | `rifled_barrels` (1800–2400) | - | `needle_breech_rifle`, `expanding_base_bullet` | - | Metallic cartridges. |
| 2567 | `magazine_repeating_rifles` | `metallic_cartridges`, `interchangeable_component_fits` (production) | - | - | - | Lever and tube-magazine repeaters. |
| 2568 | `revolving_gun_turrets` | `armored_hulls`, `rifled_breech_artillery` | - | - | - | Revolving turrets on low-sided warships. |
| 2569 | `field_army_war_rules` | `articles_of_war` (1800–2400), `staff_war_college` | - | `war_as_policy_doctrine` | - | Rules of war issued to armies as orders. |
| 2573 | `steam_fire_brigades` | `insured_fire_brigades` (1800–2400), `high_pressure_steam_engines` (production) | - | `leather_fire_hose` (1800–2400) | - | Paid brigades with steam fire engines. |
| 2576 | `crank_volley_guns` | `metallic_cartridges`, `interchangeable_component_fits` (production) | - | - | - | Hand-cranked many-barrel volley guns. |
| 2577 | `naval_torpedoes` | `steam_propulsion` (production), `precision_machinery` (infrastructure, 1800–2400) | - | `compressed_air_systems` (infrastructure) | - | Self-propelled naval torpedoes. |
| 2579 | **`stable_blasting_explosive`** | `aromatic_nitration` (production), `powder_rock_blasting` (production, 1800–2400) | - | - | - | Stable high explosive for demolition. |
| 2587 | **`reserve_mobilization_plans`** | `railway_mobilization`, `class_year_conscription` | - | `field_telegraph_trains` | - | Reservists mobilized by plan and telegraph. |
| 2589 | `examined_officer_commissions` | `officer_cadet_schools` (1800–2400), `competitive_civil_service` (institutions) | - | - | - | Commissions won by examination, not bought. |
| 2613 | `political_police_bureau` | `detective_branch` | - | - | - | Political police watch dissenters. |
| 2624 | **`automatic_actions`** | `metallic_cartridges`, `precision_machinery` (infrastructure, 1800–2400) | - | `crank_volley_guns` | - | Automatic firearms. |
| 2625 | `naval_war_college` | `staff_war_college` | - | `war_as_policy_doctrine` | - | Naval officers study strategy at college. |
| 2627 | **`smokeless_propellant`** | `stable_blasting_explosive`, `aromatic_nitration` (production) | - | `celluloid_moulding` (production) | - | Smokeless propellant. |
| 2640 | `sea_power_doctrine` | `naval_war_college` | - | - | - | Command of the sea decides wars. |
| 2648 | `torpedo_boat_destroyers` | `naval_torpedoes`, `screw_steam_warships` | - | `steam_turbines` (production) | - | Fast destroyers hunt torpedo boats. |
| 2651 | `fingerprint_identification` | `detective_branch` | - | `printed_wanted_notices` (1800–2400) | - | Offenders identified by fingerprints. |
| 2659 | **`recoil_absorbing_field_gun`** | `rifled_breech_artillery`, `smokeless_propellant` | - | `packed_piston_seals` (production) | - | Quick-firing gun absorbs its own recoil. |
| 2664 | **`indirect_fire`** | `powder_artillery` (1800–2400), `military_staffs` (1800–2400) | - | `military_survey_maps` (1800–2400) | - | Hidden batteries fire by map and observer. |
| 2665 | `barbed_wire_entanglements` | `steel_wire_drawing` (production) | - | - | - | Barbed-wire entanglements. |
| 2666 | `land_war_conventions` | `field_army_war_rules`, `neutral_wounded_convention` (health) | - | `interrealm_arbitration` (institutions) | - | Realms agree laws of land war. |
| 2667 | **`submersible_hulls`** | `naval_torpedoes`, `armored_hulls` | - | - | - | Submersible hulls. |
| 2677 | `field_telephone_lines` | `telephone_circuits` (knowledge), `field_telegraph_trains` | - | - | - | Field telephones link observers and guns. |
| 2680 | `naval_fire_control` | `armored_hulls`, `military_staffs` (1800–2400) | - | `indirect_fire` | - | Naval fire control. |
| 2683 | **`all_big_gun_battleships`** | `revolving_gun_turrets`, `steam_turbine_ships` (logistics) | - | `naval_fire_control` | - | All-big-gun turbine battleships. |
| 2685 | `machine_gun_companies` | `automatic_actions` | - | - | - | Machine-gun companies in every regiment. |
| 2691 | `state_intelligence_service` | `political_police_bureau`, `career_diplomatic_service` (institutions) | - | - | - | State foreign intelligence service. |
| 2693 | `naval_aviation` | `powered_flight` (production), `naval_torpedoes` | - | - | - | Naval aviation. |
| 2696 | `aerial_bombardment` | `powered_flight` (production), `powder_artillery` (1800–2400) | - | - | - | Aerial bombardment. |
| 2704 | **`continuous_trench_systems`** | `barbed_wire_entanglements`, `machine_gun_companies` | - | `siege_by_parallels` (1800–2400) | - | Continuous trenches with dugouts and wire. |
| 2707 | `fighter_tactics` | `powered_flight` (production), `formation_drill` (0–600) | - | - | - | Fighter tactics. |
| 2707 | `mountain_field_school` | `route_memory` (knowledge, 0–600) | `military_staffs` (1800–2400) / `professional_corps` (600–1200) | - | - | Mountain field school. |
| 2708 | `chemical_gas_warfare` | `chloralkali_cells` (production), `continuous_trench_systems` | - | - | - | Research only: war gases and the gas mask. |
| 2709 | **`armored_vehicles`** | `internal_combustion` (production), `armored_hulls` | - | - | - | Armoured fighting vehicles. |
| 2710 | `armor_piercing_weapons` | `armored_vehicles`, `indirect_fire` | - | - | - | Armour-piercing weapons. |
| 2711 | `sound_flash_ranging` | `indirect_fire`, `electrical_measurement` (knowledge) | - | `acoustic_diaphragms` (knowledge) | - | Sound and flash locate hidden guns. |
| 2712 | `carrier_aviation` | `naval_aviation`, `naval_fire_control` | - | - | - | Carrier aviation. |
| 2713 | `escorted_convoy_system` | `submersible_hulls`, `torpedo_boat_destroyers` | - | `escorted_ocean_fleets` (logistics, 1800–2400) | - | Escorted merchant convoys against submarines. |
| 2713 | `infiltration_storm_squads` | `continuous_trench_systems`, `machine_gun_companies` | - | - | - | Infiltration squads with light machine guns. |
| 2714 | `engineer_infantry_security` | `indirect_fire`, `military_staffs` (1800–2400) | - | - | - | Engineer-infantry security. |
| 2714 | `infantry_tank_cooperation` | `armored_vehicles`, `military_staffs` (1800–2400) | - | - | - | Infantry-tank cooperation. |
| 2715 | `mechanized_crew_school` | `armored_vehicles`, `workshop_standards` (knowledge, 0–600), `military_staffs` (1800–2400) | - | - | - | Mechanized crew school. |
| 2716 | `underwater_sound_ranging` | `submersible_hulls`, `acoustic_diaphragms` (knowledge) | - | - | - | Submarines ranged by underwater sound. |
| 2717 | `independent_air_arm` | `aerial_bombardment`, `fighter_tactics` | - | - | - | An air arm beside army and navy. |
| 2725 | `naval_arms_limitation` | `all_big_gun_battleships`, `league_of_realms` (institutions) | - | - | - | Treaty caps battle fleets. |
| 2733 | `gas_germ_weapon_ban` | `league_of_realms` (institutions), `land_war_conventions` | - | `chemical_gas_warfare` | - | Treaty bans gas and germ weapons. |
| 2747 | `mobile_radio_command` | `amplitude_modulation` (knowledge), `armored_vehicles` | - | - | - | Radio nets command moving formations. |
| 2749 | `rotor_cipher_machines` | `electromagnetic_relays` (production), `teleprinter_mechanisms` (knowledge) | - | - | - | Rotor cipher machines. |
| 2763 | `rotary_wing` | `advanced_airframes` (production) | - | - | - | Rotary-wing flight. |
| 2764 | **`radio_detection_ranging`** | `feedback_radio_oscillators` (knowledge), `superheterodyne_reception` (knowledge) | - | `underwater_sound_ranging` | - | Radio echoes range aircraft and ships. |
| 2765 | `radio_patrol_emergency_line` | `uniformed_beat_police`, `amplitude_modulation` (knowledge), `motor_carriage` (logistics) | - | - | - | Radio patrol cars and an emergency number. |
| 2767 | `civil_air_defence` | `aerial_bombardment`, `independent_air_arm` | - | - | - | Wardens, shelters and blackout. |
| 2768 | **`armoured_division`** | `armored_vehicles`, `mobile_radio_command`, `infantry_tank_cooperation` | - | - | - | Tanks, motor infantry and guns in one division. |
| 2773 | **`integrated_air_defence`** | `radio_detection_ranging`, `independent_air_arm` | - | `mobile_radio_command` | - | Radar, plotting rooms and fighter control. |
| 2775 | `airborne_operations` | `advanced_airframes` (production), `professional_corps` (600–1200) | - | - | - | Airborne operations. |
| 2776 | `infantry_antitank_coordination` | `armor_piercing_weapons`, `military_staffs` (1800–2400) | - | - | - | Infantry-antitank coordination. |
| 2779 | `machine_cryptanalysis` | `rotor_cipher_machines`, `relay_logic` (production) | - | `computability_theory` (knowledge) | - | Codes broken by electromechanical machines. |
| 2780 | `naval_logistics` | `steam_propulsion` (production), `supply_groups` (logistics, 0–600) | - | - | - | Fleets replenished while under way. |
| 2781 | `amphibious_landing_doctrine` | `sea_soldier_regiments` (1800–2400), `compression_ignition_engines` (production) | - | `carrier_aviation` | environment=coast | Landing craft and beach-assault doctrine. |
| 2784 | `guided_weapons` | `jet_propulsion` (production), `naval_fire_control` | - | - | - | Guided weapons. |
| 2785 | `ballistic_rocket_bombardment` | `iron_cased_war_rockets` (1800–2400), `guided_weapons`, `cryogenic_air_separation` (production) | - | - | - | Long-range rockets bombard distant targets. |
| 2787 | **`fission_weapon`** | `nuclear_fission` (knowledge), `reactor_engineering` (infrastructure) | - | `state_great_laboratories` (knowledge) | resources_known=Uranium Ore | Research only: a fission bomb can destroy a city. |
| 2792 | `unified_defence_ministry` | `independent_air_arm`, `single_minister_departments` (institutions) | - | - | - | One ministry over army, navy and air. |
| 2797 | `standing_alliance_command` | `unified_defence_ministry` | - | `world_assembly_of_realms` (institutions) | - | A standing alliance with a joint command. |
| 2800 | `swept_wing_jet_fighters` | `jet_propulsion` (production), `fighter_tactics` | - | `radio_detection_ranging` | - | Swept-wing jets with radar sights. |
| 2805 | **`thermonuclear_weapon`** | `fission_weapon` | - | `state_great_laboratories` (knowledge) | - | Research only: fusion-stage weapon. |
| 2810 | `nuclear_propulsion` | `reactor_engineering` (infrastructure), `submersible_hulls` | - | - | - | Nuclear propulsion. |
| 2812 | `surface_to_air_missiles` | `guided_weapons`, `radio_detection_ranging` | - | `integrated_air_defence` | - | Missile batteries defend against aircraft. |
| 2814 | `nuclear_civil_defence` | `civil_air_defence`, `nuclear_fission` (knowledge) | - | `fission_weapon` | - | Shelters and evacuation against nuclear attack. |
| 2815 | `interrealm_peacekeepers` | `world_assembly_of_realms` (institutions) | - | - | - | Lightly armed peacekeepers of the world assembly. |
| 2816 | `continuity_of_government` | `nuclear_civil_defence` | - | - | - | Bunkers keep government working through attack. |
| 2818 | **`intercontinental_missiles`** | `ballistic_rocket_bombardment`, `thermonuclear_weapon` | - | `orbital_satellite_launch` (logistics) | - | Research only: intercontinental ballistic missiles. |
| 2825 | **`reconnaissance_satellites`** | `orbital_satellite_launch` (logistics) | - | `war_photography` (culture) | - | Satellites photograph from orbit. |
| 2826 | `deterrence_doctrine` | `thermonuclear_weapon` | - | `intercontinental_missiles` | - | Deterrence doctrine and hardened command. |
| 2826 | `missile_submarine_patrols` | `nuclear_propulsion`, `intercontinental_missiles` | - | - | - | Research only: missile submarines on patrol. |
| 2828 | `naval_missiles` | `guided_weapons`, `naval_torpedoes` | - | - | - | Naval missiles. |
| 2832 | `rival_capital_hotline` | `teleprinter_mechanisms` (knowledge), `career_diplomatic_service` (institutions) | - | `deterrence_doctrine` | - | A direct line between rival capitals. |
| 2838 | **`nuclear_test_ban_treaties`** | `nuclear_fission` (knowledge), `fallout_monitoring` (ecology) | - | `thermonuclear_weapon` | - | Test-ban and non-proliferation treaties. |
| 2839 | `helicopter_air_assault` | `rotary_wing`, `airborne_operations` | - | - | - | Helicopter air assault. |
| 2842 | `night_vision_intensifiers` | `photoconductivity` (knowledge), `electron_physics` (knowledge) | - | `bipolar_junction_transistors` (production) | - | Image intensifiers see by starlight. |
| 2850 | `launch_warning_satellites` | `orbital_satellite_launch` (logistics), `ballistic_rocket_bombardment` | - | `intercontinental_missiles` | - | Satellites warn of missile launches. |
| 2855 | `laser_guided_munitions` | `guided_weapons`, `bipolar_junction_transistors` (production) | - | - | - | Laser-guided bombs. |
| 2856 | `biological_weapons_ban` | `gas_germ_weapon_ban` | - | `nuclear_test_ban_treaties` | - | Convention bans germ weapons. |
| 2858 | `counterterror_units` | `state_intelligence_service` | - | `helicopter_air_assault` | - | Counterterror and hostage-rescue units. |
| 2872 | `disaster_management_agency` | `continuity_of_government` | - | `troops_in_disaster_relief` (1800–2400) | - | A national disaster management agency. |
| 2875 | `remote_aircraft` | `guided_weapons`, `advanced_airframes` (production) | - | - | - | Remote aircraft. |
| 2882 | `stealth_aircraft` | `swept_wing_jet_fighters`, `computer_aided_design` (production), `carbon_fibre_composites` (production) | - | - | - | Low-observable stealth aircraft. |
| 2888 | `tactical_data_links` | `packet_switching` (knowledge), `mobile_radio_command` | - | - | - | Digital links join command posts, ships and aircraft. |
| 2892 | `onsite_arms_inspection` | `nuclear_test_ban_treaties` | - | `rival_capital_hotline` | - | Missile elimination checked on site. |
| 2902 | **`satellite_guided_strike`** | `satellite_ship_navigation` (logistics), `laser_guided_munitions` | - | - | - | Satellite-guided precision strike. |
| 2908 | `chemical_weapons_convention` | `gas_germ_weapon_ban`, `biological_weapons_ban` | - | - | - | Convention bans and destroys chemical weapons. |
| 2912 | `town_camera_surveillance` | `television_broadcasting` (culture), `uniformed_beat_police` | - | - | - | Cameras watch town streets. |
| 2918 | `antipersonnel_mine_ban` | `land_war_conventions` | - | `chemical_weapons_convention` | - | Anti-personnel mines banned; demining begins. |
| 2928 | **`mass_signals_surveillance`** | `internetworking_protocols` (knowledge), `state_intelligence_service` | - | `machine_cryptanalysis` | - | The state intercepts communications en masse. |
| 2930 | `armed_remote_strike` | `remote_aircraft`, `satellite_guided_strike` | - | - | - | Armed remote aircraft strike from afar. |
| 2940 | `biometric_border_documents` | `frontier_passport_control` (institutions), `fingerprint_identification` | - | `digital_identity_register` (institutions) | - | Biometric identity documents at borders. |
| 2945 | **`cyber_defence_command`** | `internetworking_protocols` (knowledge), `unified_defence_ministry` | - | `mass_signals_surveillance` | - | Network sabotage met by a cyber command. |
| 2952 | `public_alert_broadcasts` | `cellular_telephony` (knowledge), `disaster_management_agency` | - | - | - | Alerts pushed to every pocket telephone. |
| 2972 | `hypersonic_glide_vehicles` | `ballistic_rocket_bombardment`, `computer_aided_design` (production) | - | `intercontinental_missiles` | - | Hypersonic glide vehicles. |
| 2980 | **`mass_small_drones`** | `remote_aircraft`, `lithium_ion_cells` (production), `open_satellite_positioning` (logistics) | - | - | - | Cheap drones spot and strike at the front. |
| 2990 | `machine_assisted_targeting` | `deep_learning_networks` (knowledge), `learned_machine_law` (institutions) | - | `armed_remote_strike` | - | Machines suggest targets; humans sign off. |
| 2995 | `directed_energy_point_defence` | `mass_small_drones`, `wide_bandgap_power_chips` (production) | - | - | - | Directed energy shoots down drones. |
