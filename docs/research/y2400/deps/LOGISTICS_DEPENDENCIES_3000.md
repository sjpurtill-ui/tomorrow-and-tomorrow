# Logistics dependencies, years 2400–3000

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md` and the 600–1200, 1200–1800 and 1800–2400 partials. Cross-line ids are marked with their line. Earlier-block ids are marked "0–600", "600–1200", "1200–1800" or "1800–2400". `Requires (any)` groups are separated by `;`. Every prerequisite and precedent is dated at or before its dependent (adjusted years from `partials/pils_year_adjustments.json`; registry years for other lines; proposed years for earlier blocks). Catalog ids keep the prerequisites written in `scripts/*.gd`, except where a catalog prerequisite is dated after its dependent; those cases are resolved by a year move inside the registry band or listed below. Years marked "was" are moved in `partials/pils_year_adjustments.json`.

Rail: `high_pressure_steam_engines` (production) + `iron_plated_wagonway_rails` → **`public_steam_railway`** (2467) → `multitube_locomotive_boilers` → **`intercity_passenger_railway`** (2480) → timetables, clearing house, telegraph dispatch, interlocked signals, **`continental_trunk_railway`** (2584). The catalog prerequisite `rail_gauge_standards` (2523) of `rail_track_foundations` (2485) is dated after it and is dropped; the gauge law now requires the intercity railway and lists track foundations as a precedent. `compression_ignition_engines` + `electric_motors` → **`oil_electric_locomotives`** (2757); `alternating_current_grids` → `electrified_main_lines` → **`high_speed_rail_lines`** (2835).

Sea: `trial_steam_paddle_boat` + `double_acting_engine` → **`scheduled_river_steamers`** (2419; see the Production note on `steam_propulsion`) → ferries and tugs. `mail_packet_ships` + `steam_propulsion` → **`ocean_steamship_line`** (2501) → `screw_propeller_ships` (2509) → iron hulls, compound and triple-expansion engines, `heavy_oil_motor_ships` (2699). `tractor_trailer_rigs` + `pallet_forklift_handling` → **`intermodal_shipping_containers`** (2815) → gantry terminals, standard sizes, double-stack trains.

Road and air: `internal_combustion` + `fuel_refining` → **`motor_carriage`** (2629) → lorries, buses, **`series_built_motor_car`** (2688), licensing and **`limited_access_motorways`** (2731). `powered_flight` → **`scheduled_air_mail`** (2715) → passenger service → `metal_monoplane_airliners` → pressurized cabins → with `jet_propulsion`, **`jet_airliners`** (2805). Space: Security's `ballistic_rocket_bombardment` + `guided_weapons` → **`orbital_satellite_launch`** (2817) → crewed orbit → **`crewed_lunar_landing`** (2848); the launch does not require any weapon of mass destruction. Post and parcels: `distance_postage_rates` → **`prepaid_stamp_postage`** (2507) → **`interrealm_postal_union`** (2597), parcel post, air mail, **`online_order_parcel_tracking`** (2918).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 2403 | `canal_fly_boats` | `trunk_canal_cross` (1800–2400), `night_fly_wagons` (1800–2400) | - | `draft_horse_breeding` (1800–2400) | - | Fly-boats run day and night with relay horses. |
| 2408 | `public_plateway_hire` | `iron_plated_wagonway_rails` (1800–2400) | - | `canal_share_companies` (1800–2400), `wagonway_haulage` (1800–2400) | - | Plate rails open to any carrier for a toll. |
| 2419 | **`scheduled_river_steamers`** | `trial_steam_paddle_boat` (1800–2400), `double_acting_engine` (production, 1800–2400) | - | `high_pressure_steam_engines` (production), `river_navigation_commissions` (1800–2400) | environment=river | Paddle steamers keep a timetable against the current. |
| 2427 | `passenger_canal_packets` | `scheduled_passenger_barges` (1800–2400), `canal_fly_boats` | - | - | - | Passenger packet boats on the canals. |
| 2440 | `steam_estuary_ferries` | `scheduled_river_steamers` | - | `mail_packet_ships` (1800–2400) | environment=coast | Steam ferries cross the estuaries hourly. |
| 2443 | `steam_harbour_tugs` | `scheduled_river_steamers`, `enclosed_wet_docks` (infrastructure, 1800–2400) | - | - | environment=coast | Steam tugs tow sailing ships through harbours. |
| 2459 | `town_omnibus_routes` | `hackney_coaches` (1800–2400), `steel_leaf_springs` (1800–2400) | - | `long_route_stagecoaches` (1800–2400) | - | Horse omnibuses run fixed town routes. |
| 2467 | **`public_steam_railway`** | `high_pressure_steam_engines` (production), `iron_plated_wagonway_rails` (1800–2400) | - | `public_plateway_hire` | resources_known=Coal | Locomotives haul a public line. |
| 2477 | `multitube_locomotive_boilers` | `public_steam_railway`, `pressure_vessels` (production, 1800–2400) | - | - | - | Many-tubed boilers win the speed trials. |
| 2480 | **`intercity_passenger_railway`** | `public_steam_railway`, `multitube_locomotive_boilers` | - | `timed_mail_coaches` (1800–2400) | - | Double-track railway between two cities. |
| 2485 | `rail_track_foundations` | `aggregate_road_foundations` (infrastructure, 600–1200), `public_steam_railway` | - | `layered_stone_road_beds` (infrastructure, 1800–2400) | - | Track laid on sleepers in drained ballast. |
| 2488 | `classed_freight_tariffs` | `intercity_passenger_railway`, `carrier_stage_tariffs` (1200–1800) | - | - | - | Freight charged by class of goods. |
| 2493 | `merchant_chronometer_issue` | `marine_timekeeper` (1800–2400) | - | `nautical_almanac` (1800–2400), `lunar_distance_longitude` (1800–2400) | - | Merchant ships carry chronometers for longitude. |
| 2501 | **`ocean_steamship_line`** | `mail_packet_ships` (1800–2400), `steam_propulsion` (production) | - | `steam_estuary_ferries` | environment=coast | Steamships cross the ocean on a regular line. |
| 2504 | `printed_railway_timetables` | `intercity_passenger_railway` | - | `carriers_guide` (1800–2400), `printed_road_books` (1800–2400) | - | Printed railway guides and timetables. |
| 2507 | **`prepaid_stamp_postage`** | `distance_postage_rates` (1800–2400), `public_letter_post` (1800–2400) | - | `intercity_passenger_railway` | - | Uniform cheap postage prepaid with stamps. |
| 2509 | `screw_propeller_ships` | `steam_propulsion` (production) | - | `ocean_steamship_line` | environment=coast | Screw propellers replace paddle wheels at sea. |
| 2512 | `steam_grain_elevators` | `high_pressure_steam_engines` (production), `public_steam_railway` | - | `belt_power_transmission` (production, 1800–2400) | - | Steam elevators fill bins at railheads and ports. |
| 2515 | `iron_hulled_steamers` | `screw_propeller_ships`, `puddling_furnace` (production, 1800–2400) | - | `ocean_steamship_line` | environment=coast | Iron-hulled ocean steamers. |
| 2520 | `rail_express_parcels` | `intercity_passenger_railway` | - | `carriers_guide` (1800–2400) | - | Express parcel carriers ride the railways. |
| 2523 | **`rail_gauge_standards`** | `standard_measures` (knowledge, 0–600), `workshop_standards` (knowledge, 0–600), `intercity_passenger_railway` | - | `rail_track_foundations` | - | One track gauge fixed by law. |
| 2525 | `railway_clearing_house` | `intercity_passenger_railway`, `classed_freight_tariffs` | - | - | - | A clearing house settles through-fares between lines. |
| 2528 | `travelling_post_office_cars` | `intercity_passenger_railway`, `prepaid_stamp_postage` | - | - | - | Post cars sort letters on moving trains. |
| 2533 | `fast_clipper_hulls` | `drawn_hull_plans` (1800–2400), `copper_hull_sheathing` (1800–2400) | - | `jib_staysail_rig` (1800–2400) | environment=coast | Sharp clipper hulls for fast long hauls. |
| 2536 | `wind_current_passage_charts` | `hydrographic_office` (1800–2400), `ship_logbooks` (1800–2400) | - | `isotherm_maps` (ecology), `statistical_inference` (knowledge) | - | Wind and current charts shorten ocean passages. |
| 2541 | `telegraph_train_dispatch` | `electrical_telegraphy` (knowledge), `intercity_passenger_railway` | - | - | - | Telegraph orders run trains on single track. |
| 2549 | `interlocked_rail_signals` | `intercity_passenger_railway`, `telegraph_train_dispatch` | - | - | - | Interlocked levers forbid conflicting routes. |
| 2555 | `sleeping_dining_cars` | `intercity_passenger_railway` | - | `steel_leaf_springs` (1800–2400) | - | Sleeping and dining cars on long trains. |
| 2565 | `ocean_coaling_stations` | `ocean_steamship_line` | - | `coal_grading` (production, 1800–2400) | environment=coast | Coaling stations along the ocean routes. |
| 2568 | `sea_collision_rules` | `ocean_steamship_line` | - | `numbered_signal_flags` (security, 1800–2400) | - | Uniform lights and steering rules at sea. |
| 2568 | `underground_town_railway` | `public_steam_railway`, `tunnelling_shield` (infrastructure) | - | `town_omnibus_routes` | - | A railway runs beneath a great town. |
| 2573 | `compound_marine_engines` | `compound_steam_engines` (production), `screw_propeller_ships` | - | - | - | Compound engines cut coal on each voyage. |
| 2573 | `crude_oil_pipelines` | `fuel_refining` (production), `pressure_pipe_jointing` (infrastructure, 1800–2400) | - | - | resources_known=Crude Oil | Crude piped from wells to railheads. |
| 2573 | `rolled_steel_rails` | `pneumatic_steel_converter` (production), `grooved_bar_rolls` (production, 1800–2400) | - | `rail_track_foundations` | - | Steel rails outlast iron under traffic. |
| 2584 | **`continental_trunk_railway`** | `intercity_passenger_railway`, `telegraph_train_dispatch` | - | `rock_drill_tunnelling` (infrastructure), `rolled_steel_rails` | - | A trunk railway joins two coasts. |
| 2584 | **`isthmus_ship_canal`** | `canal_locks` (infrastructure, 1200–1800), `steam_propulsion` (production) | - | `two_sea_canal` (1800–2400), `powder_rock_blasting` (production, 1800–2400) | environment=coast | A sea-level ship canal cuts an isthmus. |
| 2584 | `rail_vehicle_braking` | `friction_measurement` (knowledge, 1800–2400), `rail_track_foundations`, `compressed_air_systems` (infrastructure) | - | - | - | Continuous air brakes on whole trains. |
| 2592 | `mail_order_parcel_trade` | `rail_express_parcels`, `prepaid_stamp_postage` | - | - | - | Catalogues ship goods to farms by rail and post. |
| 2595 | `automatic_rail_couplers` | `rail_vehicle_braking` | - | `rail_gauge_standards` | - | Automatic couplers join cars safely. |
| 2597 | **`interrealm_postal_union`** | `prepaid_stamp_postage` | - | `career_diplomatic_service` (institutions), `inter_realm_statistical_congress` (demography) | - | Realms fix one postal rate across borders. |
| 2603 | `hull_load_lines` | `iron_hulled_steamers` | - | `builders_measure_tonnage` (1800–2400) | - | Load lines painted against overloading. |
| 2613 | `refrigerated_rail_cars` | `mechanical_refrigeration` (infrastructure), `intercity_passenger_railway` | - | - | - | Refrigerated cars with ice bunkers. |
| 2616 | `triple_expansion_freighters` | `compound_marine_engines`, `pneumatic_steel_converter` (production) | - | `open_hearth_steel` (production) | - | Triple-expansion engines make freighters cheap. |
| 2621 | **`railway_standard_time`** | `printed_railway_timetables`, `telegraph_train_dispatch` | - | - | - | Railways set standard time zones. |
| 2627 | `chain_drive_bicycle` | `chain_power_transmission` (production), `rolling_element_bearings` (production) | - | `steel_leaf_springs` (1800–2400) | - | Chain-driven safety bicycle. |
| 2629 | **`motor_carriage`** | `internal_combustion` (production), `fuel_refining` (production) | - | `chain_drive_bicycle` | - | Petrol-engined motor carriage. |
| 2635 | `electric_street_tramways` | `electric_motors` (production), `central_power_stations` (infrastructure) | - | `town_omnibus_routes` | - | Electric tramways on town streets. |
| 2635 | `pneumatic_tyres` | `sulphur_cured_rubber` (production), `chain_drive_bicycle` | - | - | - | Air-filled rubber tyres. |
| 2640 | `tramp_bulk_charters` | `triple_expansion_freighters` | - | `underwriters_room` (1800–2400), `undersea_telegraph_cable` (knowledge) | - | Tramp steamers carry bulk wherever cargo waits. |
| 2659 | `steam_turbine_ships` | `steam_turbines` (production), `screw_propeller_ships` | - | - | - | Fast steam-turbine ships. |
| 2661 | `hump_marshalling_yards` | `rail_vehicle_braking`, `interlocked_rail_signals` | - | - | - | Hump yards sort cars by gravity. |
| 2667 | `hull_condition_surveys` | `hull_seam_caulking` (0–600), `measurement_uncertainty` (knowledge) | - | `hull_load_lines` | - | Independent surveyors class hulls at intervals. |
| 2672 | `tar_bound_road_surfaces` | `layered_stone_road_beds` (infrastructure, 1800–2400), `coal_tar_pitch` (production, 1800–2400) | - | `motor_carriage`, `asphalt_street_paving` (infrastructure) | - | Tar-bound surfaces lay the dust. |
| 2675 | `driver_licensing` | `motor_carriage` | - | `hackney_coaches` (1800–2400) | - | Driving licences and number plates. |
| 2677 | `motor_freight_lorries` | `motor_carriage`, `pneumatic_tyres` | - | `compression_ignition_engines` (production) | - | Motor lorries carry road freight. |
| 2683 | `motor_bus_routes` | `motor_carriage`, `pneumatic_tyres` | - | `town_omnibus_routes` | - | Motor buses replace the horse omnibus. |
| 2688 | **`series_built_motor_car`** | `motor_carriage`, `interchangeable_component_fits` (production) | - | `basic_machine_shops` (production), `precision_toolrooms` (production) | - | Cheap cars built in long series. |
| 2691 | `motor_road_fund` | `driver_licensing`, `tar_bound_road_surfaces` | - | - | - | Fuel and licence taxes fund motor roads. |
| 2693 | `passenger_airships` | `aerostat_observation` (security, 1800–2400), `internal_combustion` (production), `aluminum_electrolysis` (production) | - | - | - | Passenger airships on scheduled routes. |
| 2696 | `radio_direction_finding` | `radio_telegraphy` (knowledge) | - | `tuned_radio_reception` (knowledge) | - | Radio bearings fix a ship's position. |
| 2699 | `heavy_oil_motor_ships` | `compression_ignition_engines` (production), `screw_propeller_ships` | - | - | - | Heavy-oil motor ships. |
| 2700 | `wireless_distress_watch` | `radio_telegraphy` (knowledge), `ocean_steamship_line` | - | - | - | Passenger ships keep a wireless distress watch. |
| 2701 | `state_parcel_post` | `prepaid_stamp_postage`, `rail_express_parcels` | - | `mail_order_parcel_trade` | - | The state post carries parcels. |
| 2704 | **`lock_ship_canal_divide`** | `isthmus_ship_canal`, `electric_motors` (production), `portland_cement_clinker` (infrastructure) | - | `mosquito_control_brigades` (health) | - | High locks lift ocean ships over a divide. |
| 2707 | `electric_traffic_signals` | `motor_carriage`, `electromagnetic_relays` (production) | - | `interlocked_rail_signals` | - | Electric signals at street crossings. |
| 2709 | `roadside_fuel_stations` | `motor_carriage`, `fuel_refining` (production) | - | - | - | Roadside fuel filling stations. |
| 2715 | **`scheduled_air_mail`** | `powered_flight` (production) | - | `state_parcel_post` | - | Scheduled air mail. |
| 2717 | `passenger_air_service` | `powered_flight` (production), `scheduled_air_mail` | - | - | - | Airline service between capitals. |
| 2720 | `state_railway_administration` | `railway_clearing_house` | - | `war_economy_boards` (institutions) | - | The state takes over the railways. |
| 2731 | **`limited_access_motorways`** | `motor_road_fund`, `reinforced_concrete_bridges` (infrastructure) | - | - | - | Motor roads with no level crossings. |
| 2733 | `tractor_trailer_rigs` | `motor_freight_lorries`, `compression_ignition_engines` (production) | - | - | - | Articulated tractor-trailer lorries. |
| 2739 | `centralized_traffic_control` | `interlocked_rail_signals`, `electromagnetic_relays` (production) | - | `relay_logic` (production) | - | District rail signals worked from one room. |
| 2744 | `airway_radio_beacons` | `scheduled_air_mail`, `radio_direction_finding` | - | - | - | Radio beacons mark night air routes. |
| 2747 | `airport_control_towers` | `passenger_air_service`, `amplitude_modulation` (knowledge) | - | - | - | Towers clear flights by radio. |
| 2747 | `electrified_main_lines` | `alternating_current_grids` (infrastructure), `electric_street_tramways` | - | - | - | Main-line railways electrified. |
| 2752 | **`pallet_forklift_handling`** | `internal_combustion` (production), `rolling_element_bearings` (production) | - | `steam_grain_elevators` | - | Fork-lift trucks and standard pallets. |
| 2755 | `road_haulage_licensing` | `motor_freight_lorries`, `driver_licensing` | - | - | - | Road haulage licensed and taxed. |
| 2757 | **`oil_electric_locomotives`** | `compression_ignition_engines` (production), `electric_motors` (production) | - | `electrified_main_lines` | - | Oil-engined electric locomotives replace steam. |
| 2763 | `metal_monoplane_airliners` | `advanced_airframes` (production), `passenger_air_service` | - | - | - | All-metal monoplanes make flying pay. |
| 2773 | `pressurized_airliner_cabins` | `metal_monoplane_airliners`, `compressed_air_systems` (infrastructure) | - | - | - | Pressurized cabins fly above the weather. |
| 2781 | `hyperbolic_radio_navigation` | `radio_direction_finding`, `frequency_stabilization` (knowledge) | - | - | - | Timed radio chains fix ships and aircraft. |
| 2784 | `civil_aviation_convention` | `passenger_air_service` | - | `interrealm_postal_union`, `league_of_realms` (institutions) | - | Realms agree civil aviation and air rights. |
| 2789 | `radar_approach_control` | `airport_control_towers`, `radio_detection_ranging` (security) | - | - | - | Radar guides airliners to the runway. |
| 2795 | `sustained_airlift` | `metal_monoplane_airliners`, `airport_control_towers` | - | `airborne_operations` (security) | - | A besieged city fed by air alone. |
| 2805 | **`jet_airliners`** | `jet_propulsion` (production), `pressurized_airliner_cabins` | - | - | - | Jet airliners. |
| 2808 | `roll_on_roll_off_ferries` | `amphibious_landing_doctrine` (security), `series_built_motor_car` | - | - | environment=coast | Lorries and cars drive on and off ferries. |
| 2815 | **`intermodal_shipping_containers`** | `tractor_trailer_rigs`, `pallet_forklift_handling` | - | `welded_steel_frames` (infrastructure) | - | Steel containers move ship to lorry unopened. |
| 2815 | **`national_highway_network`** | `limited_access_motorways`, `motor_road_fund` | - | `prestressed_concrete` (infrastructure) | - | A national motorway net paid by fuel tax. |
| 2817 | **`orbital_satellite_launch`** | `ballistic_rocket_bombardment` (security), `guided_weapons` (security) | - | `jet_propulsion` (production) | - | A many-stage rocket puts a satellite in orbit. |
| 2818 | `very_large_tankers` | `heavy_oil_motor_ships`, `welded_steel_frames` (infrastructure) | - | `crude_oil_pipelines` | environment=coast | Very large oil tankers. |
| 2822 | `container_gantry_terminals` | `intermodal_shipping_containers`, `electric_motors` (production) | - | - | environment=coast | Gantry cranes work container terminals. |
| 2825 | `bulk_unit_trains` | `oil_electric_locomotives`, `centralized_traffic_control` | - | - | - | Unit trains carry one bulk cargo. |
| 2825 | `dedicated_bulk_carriers` | `heavy_oil_motor_ships`, `welded_steel_frames` (infrastructure) | - | - | environment=coast | Dedicated carriers for ore and grain. |
| 2828 | `computer_seat_reservations` | `passenger_air_service`, `data_modems` (knowledge), `read_write_memory` (production) | - | - | - | Computers book airline seats. |
| 2828 | `crewed_orbital_flight` | `orbital_satellite_launch` | - | `pressurized_airliner_cabins` | - | A crewed capsule orbits and returns. |
| 2835 | **`high_speed_rail_lines`** | `electrified_main_lines`, `centralized_traffic_control` | - | `prestressed_concrete` (infrastructure) | - | High-speed trains on dedicated lines. |
| 2835 | `satellite_ship_navigation` | `hyperbolic_radio_navigation`, `orbital_satellite_launch` | - | - | - | Ships navigate by satellite. |
| 2845 | `standard_container_sizes` | `intermodal_shipping_containers` | - | - | - | Container sizes standardized across realms. |
| 2848 | **`crewed_lunar_landing`** | `crewed_orbital_flight` | - | `formula_programming_languages` (knowledge) | - | A crew lands on the moon and returns. |
| 2850 | `wide_body_hub_flights` | `jet_airliners`, `computer_seat_reservations` | - | - | - | Wide-body airliners and hub airports. |
| 2852 | `automated_high_bay_warehouses` | `pallet_forklift_handling`, `hardwired_sequence_control` (production) | - | - | - | Stacker cranes run high-bay warehouses. |
| 2858 | **`overnight_air_express`** | `jet_airliners`, `wide_body_hub_flights` | - | - | - | Overnight air express parcel network. |
| 2860 | **`scanned_product_barcodes`** | `single_chip_processors` (production), `relational_databases` (knowledge) | - | `punched_card_tabulation` (knowledge) | - | Bar codes scanned on goods. |
| 2868 | `just_in_time_supply` | `lean_production` (labor), `tractor_trailer_rigs` | - | - | - | Just-in-time deliveries to factories. |
| 2872 | `transport_deregulation` | `road_haulage_licensing` | - | `state_enterprise_privatization` (institutions) | - | Freight and fares deregulated. |
| 2885 | `double_stack_container_trains` | `intermodal_shipping_containers`, `bulk_unit_trains` | - | - | - | Containers stacked two high on trains. |
| 2890 | `electronic_shipping_documents` | `bills_of_lading` (1200–1800), `data_modems` (knowledge) | - | `standard_container_sizes` | - | Shipping documents exchanged electronically. |
| 2895 | `supply_chain_management` | `just_in_time_supply`, `relational_databases` (knowledge) | - | `scanned_product_barcodes` | - | Supply chains managed as one flow. |
| 2910 | `low_cost_point_airlines` | `jet_airliners`, `transport_deregulation` | - | - | - | Low-cost point-to-point airlines. |
| 2912 | **`open_satellite_positioning`** | `satellite_ship_navigation`, `single_chip_processors` (production) | - | - | - | Open satellite positioning for every user. |
| 2918 | **`online_order_parcel_tracking`** | `world_hypertext_web` (knowledge), `scanned_product_barcodes` | - | `overnight_air_express` | - | Online orders with tracked parcels. |
| 2920 | `shared_orbital_station` | `crewed_orbital_flight` | - | `crewed_lunar_landing` | - | A shared station kept crewed year-round. |
| 2930 | `automatic_ship_identification` | `open_satellite_positioning`, `packet_switching` (knowledge) | - | - | environment=coast | Ships broadcast identity by transponder. |
| 2932 | `urban_congestion_charging` | `town_camera_surveillance` (security) | - | `driver_licensing` | - | Charges for driving into town centres. |
| 2935 | `rfid_pallet_tags` | `scanned_product_barcodes`, `single_chip_processors` (production) | - | - | - | Radio tags on pallets and cases. |
| 2938 | `in_car_satellite_routing` | `open_satellite_positioning`, `flat_panel_displays` (production) | - | - | - | Turn-by-turn satellite routing in cars. |
| 2940 | `ultra_large_container_ships` | `standard_container_sizes`, `heavy_oil_motor_ships` | - | - | environment=coast | Ultra-large container ships. |
| 2945 | `live_traffic_mapping` | `in_car_satellite_routing`, `pocket_networked_computers` (knowledge) | - | - | - | Pocket maps with live traffic. |
| 2950 | `app_ride_hailing` | `live_traffic_mapping`, `pocket_networked_computers` (knowledge) | - | - | - | Ride-hailing by pocket telephone. |
| 2955 | `warehouse_robot_fleets` | `automated_high_bay_warehouses`, `rfid_pallet_tags` | - | `collaborative_robots` (production) | - | Robot fleets move goods in warehouses. |
| 2958 | **`mass_battery_electric_cars`** | `lithium_ion_cells` (production), `series_built_motor_car` | - | - | - | Battery-electric cars in mass production. |
| 2965 | `reusable_orbital_boosters` | `orbital_satellite_launch`, `stored_program_control` (production) | - | `shared_orbital_station` | - | Reusable boosters cut launch costs. |
| 2970 | `battery_electric_buses` | `lithium_ion_cells` (production), `motor_bus_routes` | - | `mass_battery_electric_cars` | - | Battery-electric city buses. |
| 2978 | `supply_chain_resilience_reviews` | `supply_chain_management` | - | `pandemic_test_trace_orders` (health) | - | Reviews and stocks for critical goods. |
| 2980 | `drone_parcel_delivery` | `open_satellite_positioning`, `lithium_ion_cells` (production) | - | `mass_small_drones` (security) | - | Drones deliver parcels in licensed zones. |
| 2988 | `low_carbon_ship_fuels` | `green_hydrogen_electrolysis` (production), `heavy_oil_motor_ships` | - | - | - | Ships burn methanol or ammonia fuels. |
| 2992 | **`driverless_highway_freight`** | `deep_learning_networks` (knowledge), `open_satellite_positioning`, `tractor_trailer_rigs` | - | - | - | Driverless lorries on fixed motorway corridors. |
| 2998 | `electric_air_taxis` | `lithium_ion_cells` (production), `drone_parcel_delivery` | - | - | - | Electric air taxis on short hops. |
