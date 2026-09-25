# Logistics: years 2400–3000

**Scope.** The game's **Logistics** research line (`logistics` dynamic; `Movement`-direction entries: the rail-freight, naval-service, shipbuilding and cartwright catalogs) continues `y1200/LOGISTICS_1200_1800.md` and `y1200/registry_1800.json`; the 1800–2400 list is written in parallel in `y1800/`. It has six channels: roads and motor transport; railways; ships and services at sea; navigation and safety at sea; posts, parcels and freight handling; and air carriage. Catalog ids placed here: `rail_track_foundations`, `rail_gauge_standards`, `rail_vehicle_braking` and `hull_condition_surveys`. The engines themselves are other lines' catalog ids (`steam_propulsion`, `internal_combustion`, `powered_flight`, `jet_propulsion` and `advanced_airframes` are `Materials`; `mechanical_refrigeration` is Infrastructure). The rows here are the carrying services built on them and say "(continues: …)". These belong to other lines:
- **Infrastructure:** bridges, harbours, docks, tunnels, street paving and town water.
- **Knowledge:** the telegraph, telephone, radio, computing and networks.
- **Security:** escorted convoys, military railways, fleet replenishment and military airlift doctrine.
- **Institutions:** banks, exchanges, company law and customs unions.
- **Production:** engines, rails and vehicles as manufactures; fuels and refining.

Names are generic practices. Real history is used only to calibrate dates.

**Historical anchor.** On the `technology_eras.gd` CURVE `[[2400,1800],[2800,1950],[3000,2030]]` (on `origin/codex/research-600`), game 2400 is about AD 1800, 2500 about 1838, 2600 about 1875, 2700 about 1912, 2800 about 1950, 2900 about 1990 and 3000 is AD 2030, the end of the game. In years 2400–2800 one historical year spans about 2.7 game years; in 2800–3000 it spans 2.5. About 230 historical years of fast change must fit into 600 game years, so the list is dense: several advances land in most decades, and one historical year often carries two or three rows. Years 2400–2700 carry the age of steam: river and ocean steamers, public railways, stamped postage, refrigerated holds, standard time, the bicycle and the first motor carriages. Years 2700–3000 carry motor roads, air mail and airlines, the pallet and the fork-lift, the steel container, jet airliners, bar codes, satellite positioning, online parcels and warehouse robots. The last 30 game years (≈ AD 2018–2030) are near-future items: marked speculative-plausible, never science fiction.

**Research time.** Time is given in game years while a staffed Logistics team is working on the item. Real minutes are for **1 day/s**: 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3.

**Id column.** A plain `id` is in the main catalog today; its year comes from `HISTORICAL_YEAR` through the CURVE unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800), `scripts/*.gd` or another 2400–3000 list. "(continues: id)" names an earlier item that the row improves. "(shared: X)" marks an item that straddles into line X. `[gov: …]` marks a row that changes government, civic life or the court. Bands are ±40 years, ±30 for key thresholds (bold), capped at 3000.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `n/s` when the item is in main but was not reached in any recorded run, and `—` when it is not in main.

## Years 2400–2700 (≈ AD 1800–1912)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2403 (2363–2443) | Canal fly-boats run day and night with relay horses (continues: trunk_canal_cross) | 5 y | 30 min | NEW · canal_fly_boats | — |
| 2408 (2368–2448) | Horse railway on iron plate rails open to any carrier for a toll (continues: iron_plated_wagonway_rails) | 8 y | 49 min | NEW · public_plateway_hire | — |
| **2419 (2389–2449)** | **Paddle steamer keeps a scheduled river service against the current (continues: trial_steam_paddle_boat, steam_propulsion; shared: production)** | 12 y | 73 min | NEW · scheduled_river_steamers | — |
| 2427 (2387–2467) | Passenger packet boats on the canals | 5 y | 30 min | NEW · passenger_canal_packets | — |
| 2440 (2400–2480) | Steam ferries cross the estuaries on the hour | 5 y | 30 min | NEW · steam_estuary_ferries | — |
| 2443 (2403–2483) | Steam tugs tow sailing ships in and out of harbour | 5 y | 30 min | NEW · steam_harbour_tugs | — |
| 2459 (2419–2499) | Horse omnibus routes inside the great towns | 5 y | 30 min | NEW · town_omnibus_routes | — |
| **2467 (2437–2497)** | **Steam locomotive hauls a public line for goods and passengers (shared: production)** | 15 y | 91 min | NEW · public_steam_railway | — |
| 2477 (2437–2517) | Many-tubed locomotive boilers win the speed trials (shared: production) | 10 y | 61 min | NEW · multitube_locomotive_boilers | — |
| **2480 (2450–2510)** | **Double-track trunk railway between two cities, with timetables and passenger carriages** | 15 y | 91 min | NEW · intercity_passenger_railway | — |
| 2485 (2445–2525) | Track laid on sleepers in drained stone ballast | 10 y | 61 min | rail_track_foundations | n/s |
| 2488 (2448–2528) | Railway freight tariffs by class of goods | 5 y | 30 min | NEW · classed_freight_tariffs | — |
| 2493 (2453–2533) | Chronometers carried by ordinary merchant ships for longitude (continues: marine_timekeeper) | 6 y | 36 min | NEW · merchant_chronometer_issue | — |
| **2501 (2471–2531)** | **Steamships cross the ocean on a regular line (continues: mail_packet_ships)** | 12 y | 73 min | NEW · ocean_steamship_line | — |
| 2504 (2464–2544) | Printed railway guides and public timetables | 4 y | 24 min | NEW · printed_railway_timetables | — |
| **2507 (2477–2537)** | **Uniform low-rate letter postage prepaid with adhesive stamps [gov: office] (continues: distance_postage_rates)** | 8 y | 49 min | NEW · prepaid_stamp_postage | — |
| 2509 (2469–2549) | Screw propeller replaces paddle wheels at sea (continues: steam_propulsion) | 10 y | 61 min | NEW · screw_propeller_ships | — |
| 2512 (2472–2552) | Steam grain elevators with bins and chutes at railheads and ports | 8 y | 49 min | NEW · steam_grain_elevators | — |
| 2515 (2475–2555) | Iron-hulled ocean steamers (shared: production) | 10 y | 61 min | NEW · iron_hulled_steamers | — |
| 2520 (2480–2560) | Express parcel carriers ride the railways | 6 y | 36 min | NEW · rail_express_parcels | — |
| **2523 (2493–2553)** | **One track gauge fixed by law for every railway in the realm [gov: law]** | 8 y | 49 min | rail_gauge_standards | n/s |
| 2525 (2485–2565) | Railway clearing house settles through-fares and freight between lines (shared: institutions) | 6 y | 36 min | NEW · railway_clearing_house | — |
| 2528 (2488–2568) | Post cars sort letters on moving trains | 5 y | 30 min | NEW · travelling_post_office_cars | — |
| 2533 (2493–2573) | Sharp-lined clipper hulls for fast long-haul cargo | 8 y | 49 min | NEW · fast_clipper_hulls | — |
| 2536 (2496–2576) | Wind-and-current charts and great-circle routes shorten ocean passages | 8 y | 49 min | NEW · wind_current_passage_charts | — |
| 2541 (2501–2581) | Telegraph train orders run trains safely on single track (continues: electrical_telegraphy) | 6 y | 36 min | NEW · telegraph_train_dispatch | — |
| 2549 (2509–2589) | Interlocked signal levers forbid conflicting routes | 8 y | 49 min | NEW · interlocked_rail_signals | — |
| 2555 (2515–2595) | Sleeping and dining cars on long-distance trains | 5 y | 30 min | NEW · sleeping_dining_cars | — |
| 2565 (2525–2605) | Coaling stations along the ocean routes (shared: security) | 8 y | 49 min | NEW · ocean_coaling_stations | — |
| 2568 (2528–2608) | Uniform lights and steering rules for ships at sea [gov: law] | 5 y | 30 min | NEW · sea_collision_rules | — |
| 2568 (2528–2608) | Underground railway beneath a great town (shared: infrastructure) | 12 y | 73 min | NEW · underground_town_railway | — |
| 2573 (2533–2613) | Compound marine engines cut the coal burned on each voyage (continues: compound_steam_engines) | 10 y | 61 min | NEW · compound_marine_engines | — |
| 2573 (2533–2613) | Crude oil piped from wells to railheads (shared: production) | 8 y | 49 min | NEW · crude_oil_pipelines | — |
| 2573 (2533–2613) | Rolled steel rails outlast iron under heavy traffic (shared: production) | 8 y | 49 min | NEW · rolled_steel_rails | — |
| **2584 (2554–2614)** | **Continental trunk railway joins two coasts** | 15 y | 91 min | NEW · continental_trunk_railway | — |
| **2584 (2554–2614)** | **Sea-level ship canal cuts through an isthmus (continues: canal_locks; shared: infrastructure)** | 15 y | 91 min | NEW · isthmus_ship_canal | — |
| 2584 (2544–2624) | Continuous air brakes on whole trains | 8 y | 49 min | rail_vehicle_braking | n/s |
| 2592 (2552–2632) | Mail-order catalogues ship goods to farms by rail and post | 6 y | 36 min | NEW · mail_order_parcel_trade | — |
| 2595 (2555–2635) | Automatic couplers join cars with no worker between them (shared: labor) | 6 y | 36 min | NEW · automatic_rail_couplers | — |
| **2597 (2567–2627)** | **Postal union of realms fixes one rate across borders [gov: law]** | 8 y | 49 min | NEW · interrealm_postal_union | — |
| 2603 (2563–2643) | Load lines painted on hulls against overloading [gov: law] | 5 y | 30 min | NEW · hull_load_lines | — |
| 2613 (2573–2653) | Refrigerated rail cars with ice bunkers (continues: mechanical_refrigeration) | 6 y | 36 min | NEW · refrigerated_rail_cars | — |
| 2616 (2576–2656) | Triple-expansion engines make steam freighters cheap on long routes | 8 y | 49 min | NEW · triple_expansion_freighters | — |
| **2621 (2591–2651)** | **Standard time zones set by the railways [gov: law]** | 6 y | 36 min | NEW · railway_standard_time | — |
| 2627 (2587–2667) | Chain-driven safety bicycle (continues: chain_power_transmission) | 6 y | 36 min | NEW · chain_drive_bicycle | — |
| **2629 (2599–2659)** | **Petrol-engined motor carriage (continues: internal_combustion)** | 12 y | 73 min | NEW · motor_carriage | — |
| 2635 (2595–2675) | Electric street tramways (shared: infrastructure) | 8 y | 49 min | NEW · electric_street_tramways | — |
| 2635 (2595–2675) | Air-filled rubber tyres | 5 y | 30 min | NEW · pneumatic_tyres | — |
| 2640 (2600–2680) | Tramp steamers carry bulk on charter wherever cargo waits | 6 y | 36 min | NEW · tramp_bulk_charters | — |
| 2659 (2619–2699) | Steam-turbine fast ships (continues: steam_turbines) | 10 y | 61 min | NEW · steam_turbine_ships | — |
| 2661 (2621–2701) | Hump yards sort freight cars by gravity | 6 y | 36 min | NEW · hump_marshalling_yards | — |
| 2667 (2627–2707) | Hulls surveyed and classed at set intervals by independent surveyors | 6 y | 36 min | hull_condition_surveys | n/s |
| 2672 (2632–2712) | Tar-bound road surfaces lay the dust for motor traffic (shared: infrastructure) | 8 y | 49 min | NEW · tar_bound_road_surfaces | — |
| 2675 (2635–2715) | Driving licences and registered number plates [gov: law] | 5 y | 30 min | NEW · driver_licensing | — |
| 2677 (2637–2717) | Motor lorries carry freight on roads | 8 y | 49 min | NEW · motor_freight_lorries | — |
| 2683 (2643–2723) | Motor buses replace the horse omnibus | 5 y | 30 min | NEW · motor_bus_routes | — |
| **2688 (2658–2718)** | **Cheap motor car built in long series (shared: production)** | 12 y | 73 min | NEW · series_built_motor_car | — |
| 2691 (2651–2731) | Road board builds motor roads from fuel and licence taxes [gov: office] | 8 y | 49 min | NEW · motor_road_fund | — |
| 2693 (2653–2733) | Passenger airships on scheduled routes | 8 y | 49 min | NEW · passenger_airships | — |
| 2696 (2656–2736) | Radio direction-finding fixes a ship's position (continues: radio_telegraphy) | 6 y | 36 min | NEW · radio_direction_finding | — |
| 2699 (2659–2739) | Diesel motor ships | 10 y | 61 min | NEW · diesel_motor_ships | — |

## Years 2700–3000 (≈ AD 1912–2030)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2700 (2660–2740) | Wireless distress watch required on passenger ships [gov: law] (shared: security) | 5 y | 30 min | NEW · wireless_distress_watch | — |
| 2701 (2661–2741) | Parcel post carried by the state post | 5 y | 30 min | NEW · state_parcel_post | — |
| **2704 (2674–2734)** | **High-lock ship canal lifts ocean ships over a divide (continues: isthmus_ship_canal)** | 15 y | 91 min | NEW · lock_ship_canal_divide | — |
| 2707 (2667–2747) | Electric traffic signals at street crossings | 5 y | 30 min | NEW · electric_traffic_signals | — |
| 2709 (2669–2749) | Roadside fuel filling stations | 5 y | 30 min | NEW · roadside_fuel_stations | — |
| **2715 (2685–2745)** | **Scheduled air mail** | 8 y | 49 min | NEW · scheduled_air_mail | — |
| 2717 (2677–2757) | Passenger airline service between capitals | 10 y | 61 min | NEW · passenger_air_service | — |
| 2720 (2680–2760) | State railway administration takes over the lines [gov: office] (shared: institutions) | 8 y | 49 min | NEW · state_railway_administration | — |
| **2731 (2701–2761)** | **Limited-access motor roads with no level crossings** | 15 y | 91 min | NEW · limited_access_motorways | — |
| 2733 (2693–2773) | Articulated tractor-trailer lorries | 6 y | 36 min | NEW · tractor_trailer_rigs | — |
| 2739 (2699–2779) | Rail signals across a whole district worked from one control room | 6 y | 36 min | NEW · centralized_traffic_control | — |
| 2744 (2704–2784) | Radio beacons mark night air routes | 6 y | 36 min | NEW · airway_radio_beacons | — |
| 2747 (2707–2787) | Airport control towers clear flights by radio | 8 y | 49 min | NEW · airport_control_towers | — |
| 2747 (2707–2787) | Electrified main-line railways | 10 y | 61 min | NEW · electrified_main_lines | — |
| **2752 (2722–2782)** | **Fork-lift trucks and standard wooden pallets in warehouses** | 6 y | 36 min | NEW · pallet_forklift_handling | — |
| 2755 (2715–2795) | Road haulage licensed and taxed [gov: law] | 5 y | 30 min | NEW · road_haulage_licensing | — |
| **2757 (2727–2787)** | **Diesel-electric locomotives replace steam** | 10 y | 61 min | NEW · diesel_electric_locomotives | — |
| 2763 (2723–2803) | All-metal monoplane airliners make flying pay (continues: advanced_airframes) | 10 y | 61 min | NEW · metal_monoplane_airliners | — |
| 2773 (2733–2813) | Pressurized airliner cabins fly above the weather | 6 y | 36 min | NEW · pressurized_airliner_cabins | — |
| 2781 (2741–2821) | Hyperbolic radio navigation for ships and aircraft | 8 y | 49 min | NEW · hyperbolic_radio_navigation | — |
| 2784 (2744–2824) | Convention of realms on civil aviation and air rights [gov: law] | 6 y | 36 min | NEW · civil_aviation_convention | — |
| 2789 (2749–2829) | Radar approach control guides airliners to the runway | 6 y | 36 min | NEW · radar_approach_control | — |
| 2795 (2755–2835) | A besieged city fed by air alone (shared: security) | 10 y | 61 min | NEW · sustained_airlift | — |
| **2805 (2775–2835)** | **Jet airliners (continues: jet_propulsion)** | 12 y | 73 min | NEW · jet_airliners | — |
| 2808 (2768–2848) | Roll-on/roll-off ferries for lorries and cars | 6 y | 36 min | NEW · roll_on_roll_off_ferries | — |
| **2815 (2785–2845)** | **Standard steel shipping containers move ship to lorry to train unopened** | 15 y | 91 min | NEW · intermodal_shipping_containers | — |
| **2815 (2785–2845)** | **National motorway network paid from a fuel tax [gov: office]** | 15 y | 91 min | NEW · national_highway_network | — |
| 2818 (2778–2858) | Very large oil tankers | 8 y | 49 min | NEW · very_large_tankers | — |
| 2822 (2782–2862) | Ship-to-shore gantry cranes and container terminals | 8 y | 49 min | NEW · container_gantry_terminals | — |
| 2825 (2785–2865) | Unit trains carry one bulk cargo from mine to port | 5 y | 30 min | NEW · bulk_unit_trains | — |
| 2825 (2785–2865) | Dedicated bulk carriers for ore and grain | 6 y | 36 min | NEW · dedicated_bulk_carriers | — |
| 2828 (2788–2868) | Computer seat reservations for airlines | 8 y | 49 min | NEW · computer_seat_reservations | — |
| **2835 (2805–2865)** | **High-speed passenger rail on dedicated lines** | 15 y | 91 min | NEW · high_speed_rail_lines | — |
| 2835 (2795–2875) | Satellite navigation for ships (continues: hyperbolic_radio_navigation) | 10 y | 61 min | NEW · satellite_ship_navigation | — |
| 2845 (2805–2885) | Container sizes standardized across realms [gov: law] | 6 y | 36 min | NEW · standard_container_sizes | — |
| 2850 (2810–2890) | Wide-body airliners and hub airports | 10 y | 61 min | NEW · wide_body_hub_flights | — |
| 2852 (2812–2892) | Automated high-bay warehouses with stacker cranes | 8 y | 49 min | NEW · automated_high_bay_warehouses | — |
| **2858 (2828–2888)** | **Overnight air express parcel network** | 8 y | 49 min | NEW · overnight_air_express | — |
| **2860 (2830–2890)** | **Scanned bar codes on goods (shared: production)** | 8 y | 49 min | NEW · scanned_product_barcodes | — |
| 2868 (2828–2908) | Just-in-time deliveries to factories (shared: production, labor) | 10 y | 61 min | NEW · just_in_time_supply | — |
| 2872 (2832–2912) | Freight and fares deregulated [gov: law] | 6 y | 36 min | NEW · transport_deregulation | — |
| 2885 (2845–2925) | Double-stack container trains | 6 y | 36 min | NEW · double_stack_container_trains | — |
| 2890 (2850–2930) | Electronic exchange of shipping documents (continues: bills_of_lading) | 6 y | 36 min | NEW · electronic_shipping_documents | — |
| 2895 (2855–2935) | Supply chains managed across firms as one flow | 10 y | 61 min | NEW · supply_chain_management | — |
| 2910 (2870–2950) | Low-cost point-to-point airlines | 6 y | 36 min | NEW · low_cost_point_airlines | — |
| **2912 (2882–2942)** | **Open satellite positioning for every user (continues: satellite_ship_navigation)** | 12 y | 73 min | NEW · open_satellite_positioning | — |
| **2918 (2888–2948)** | **Online orders with tracked parcel delivery** | 10 y | 61 min | NEW · online_order_parcel_tracking | — |
| 2930 (2890–2970) | Automatic ship identification transponders [gov: law] | 5 y | 30 min | NEW · automatic_ship_identification | — |
| 2932 (2892–2972) | Congestion charges for driving into town centres [gov: civic] | 5 y | 30 min | NEW · urban_congestion_charging | — |
| 2935 (2895–2975) | Radio tags on pallets and cases | 6 y | 36 min | NEW · rfid_pallet_tags | — |
| 2938 (2898–2978) | Turn-by-turn satellite routing in cars | 6 y | 36 min | NEW · in_car_satellite_routing | — |
| 2940 (2900–2980) | Ultra-large container ships | 8 y | 49 min | NEW · ultra_large_container_ships | — |
| 2945 (2905–2985) | Pocket maps with live traffic | 5 y | 30 min | NEW · live_traffic_mapping | — |
| 2950 (2910–2990) | Ride-hailing by pocket telephone | 6 y | 36 min | NEW · app_ride_hailing | — |
| 2955 (2915–2995) | Mobile robot fleets in fulfilment warehouses | 10 y | 61 min | NEW · warehouse_robot_fleets | — |
| **2958 (2928–2988)** | **Battery-electric cars in mass production (shared: production)** | 12 y | 73 min | NEW · mass_battery_electric_cars | — |
| 2965 (2925–3000) | Reusable orbital boosters cut launch costs (shared: knowledge) | 15 y | 91 min | NEW · reusable_orbital_boosters | — |
| 2970 (2930–3000) | Battery-electric city buses | 6 y | 36 min | NEW · battery_electric_buses | — |
| 2978 (2938–3000) | Supply-chain resilience reviews and critical-goods stocks [gov: law] | 8 y | 49 min | NEW · supply_chain_resilience_reviews | — |
| 2980 (2940–3000) | Drone parcel delivery in licensed zones | 8 y | 49 min | NEW · drone_parcel_delivery | — |
| 2988 (2948–3000) | Cargo ships burning methanol or ammonia (speculative-plausible) | 10 y | 61 min | NEW · low_carbon_ship_fuels | — |
| **2992 (2962–3000)** | **Driverless freight lorries on fixed motorway corridors (speculative-plausible)** | 12 y | 73 min | NEW · driverless_highway_freight | — |
| 2998 (2958–3000) | Electric air taxis on short town hops (speculative-plausible) | 8 y | 49 min | NEW · electric_air_taxis | — |

## Pacing

| Years | 2400–2450 | 2450–2500 | 2500–2550 | 2550–2600 | 2600–2650 | 2650–2700 | 2700–2750 | 2750–2800 | 2800–2850 | 2850–2900 | 2900–2950 | 2950–3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Logistics advances | 6 | 7 | 14 | 13 | 9 | 12 | 14 | 9 | 12 | 9 | 9 | 10 |

The total is **124** advances: 61 in years 2400–2700 and 63 in years 2700–3000. 4 are catalog ids. Across the six channels, one lands about every 5 game years, so each channel gets work about every 30 years. Most items take 5–10 years (30–61 min). Key thresholds (bold) mostly take 12–15 years (73–91 min): the first public railway, the ocean steamship line, the ship canals, the container and the national motorway network. A few law and handling thresholds (standard time, stamped postage, pallets, bar codes) take 6–8 years. The list is fairly even. Years 2500–2600 and 2700–2750 are densest, because railways and posts spread in AD 1838–1875, and motor roads and airlines in AD 1912–1931.

**Key thresholds:**
1. **Railways:** plate-rail horse railway (2408) → public steam railway (2467) → many-tubed boilers (2477) → intercity passenger railway (2480) → `rail_track_foundations` (2485) → `rail_gauge_standards` (2523) → clearing house (2525) → interlocked signals (2549) → `rail_vehicle_braking` (2584) → continental trunk line (2584) → standard time (2621) → state railway administration (2720) → electrified main lines (2747) → diesel-electric locomotives (2757) → high-speed lines (2835) → double-stack container trains (2885). Troop movement by railway timetable is Security (`railway_mobilization`).
2. **Roads and motor transport:** layered stone road beds (1800–2400 Infrastructure `layered_stone_road_beds`, 2350) → timed mail coaches (1800–2400 `timed_mail_coaches`, 2372) → horse omnibus (2459) → chain-drive bicycle (2627) → motor carriage (2629) → air-filled tyres (2635) → motor lorries (2677) → series-built motor car (2688) → road fund (2691) → limited-access motorways (2731) → national motorway network (2815) → battery-electric cars (2958) → driverless freight corridors (2992).
3. **Ships and services at sea:** trial paddle boat (1800–2400 `trial_steam_paddle_boat`, 2390) → scheduled river steamers (2419) → steam tugs (2443) → ocean steamship line (2501) → screw propeller (2509) → iron hulls (2515) → compound engines (2573) → isthmus ship canal (2584) → frozen meat by sea (Nutrition `frozen_meat_trade`, 2605) → triple expansion (2616) → steam turbines (2659) → diesel motor ships (2699) → high-lock ship canal (2704) → steel containers (2815) → ultra-large container ships (2940) → methanol and ammonia fuels (2988).
4. **Navigation and safety at sea:** chronometers for merchant ships (2493) → wind-and-current charts (2536) → sea collision rules (2568) → load lines (2603) → `hull_condition_surveys` (2667) → radio direction-finding (2696) → wireless distress watch (2700) → hyperbolic radio navigation (2781) → satellite ship navigation (2835) → open satellite positioning (2912) → ship identification transponders (2930).
5. **Posts, parcels and freight handling:** distance postage (1800–2400 `distance_postage_rates`) → stamped postage (2507) → post cars on trains (2528) → mail-order trade (2592) → postal union (2597) → parcel post (2701) → pallets and fork-lifts (2752) → air express (2858) → bar codes (2860) → just-in-time (2868) → supply-chain management (2895) → tracked online parcels (2918) → warehouse robots (2955) → drone parcels (2980).
6. **Air carriage:** passenger airships (2693) → air mail (2715) → passenger airlines (2717) → radio beacons (2744) → all-metal airliners (2763) → aviation convention (2784) → jet airliners (2805) → wide-body hubs (2850) → low-cost airlines (2910) → reusable boosters (2965) → electric air taxis (2998).
7. **Ownership of overlaps:** these are kept by other lists and were removed here: the mail packets and timed mail coaches (1800–2400 `mail_packet_ships`, `timed_mail_coaches`), broken-stone road beds (1800–2400 Infrastructure `layered_stone_road_beds`), the emigrant passage law (Demography `emigrant_passenger_law`, 2525), frozen and chilled meat by sea (Nutrition `frozen_meat_trade`, 2605) and the rail-rate commission (Institutions `rate_regulation_commissions`, 2685). Engines are Production's: screw ships, compound marine engines and turbine ships here continue `steam_propulsion`, `compound_steam_engines` and `steam_turbines`. Escorted convoys are Security (`escorted_convoy_system`), and so are fleet replenishment (`naval_logistics`) and the uses of airlift in war. The telegraph and radio are Knowledge; train dispatch, direction-finding and ship navigation here continue them. Bridges, tunnels, ports, paved streets and broken-stone road beds (1800–2400 `layered_stone_road_beds`) are Infrastructure; the ship canals, the underground railway and electric tramways here are marked (shared: infrastructure). `wagonway_haulage` and `dry_dock_services` belong to the 1800–2400 window.

## Government and civic life

These rows should change offices, law or buildings at the seat of rule:
- **Stamped postage** (2507) makes the postmaster a great officer with one low rate for the whole realm. The **postal union** (2597) adds a treaty bureau for posts between realms.
- **One track gauge** (2523) and **standard time** (2621) are laws. The town clock now follows the railway's time, set from the capital.
- Rail rates are regulated by Institutions' `rate_regulation_commissions` (2685). The **state railway administration** (2720) adds a ministry of railways. **Deregulation** (2872) removes the commissions again. It is a real option, not an upgrade.
- **Sea collision rules** (2568), **load lines** (2603), the **wireless distress watch** (2700) and **ship identification transponders** (2930) give the harbour office new inspectors and new law.
- **Driving licences** (2675), the **road fund** (2691) and **road haulage licensing** (2755) add a road board and a licensing office. The **national motorway network** (2815) adds a ministry of transport with a fuel-tax fund.
- The **civil aviation convention** (2784) adds an aviation authority. **Standard container sizes** (2845) add a standards body.
- **Congestion charging** (2932) is a town-council power. **Supply-chain resilience reviews** (2978) add a critical-goods office at court.

## Currently far too early / too late (logistics line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| rail_gauge_standards / rail_track_foundations (catalog AD 1846 ≈ 2523) | n/s | 2523 / 2485 (placed; `belongs_later` in 1200–1800). Sleepers in ballast are ≈ AD 1830, so the track bed comes before the gauge law |
| rail_vehicle_braking (catalog AD 1869 ≈ 2584) | n/s | 2584 (placed) |
| hull_condition_surveys (catalog AD 1900 ≈ 2667) | n/s | 2667 (placed). Periodic class surveys began earlier, so moving it up to ≈ 2600 is acceptable |
| wagonway_haulage (catalog AD 1846 ≈ 2523) | n/s | 1800–2400 window (≈ 1950, mine wagonways). The catalog year is about 570 game years late. `public_plateway_hire` (2408) continues it |
| dry_dock_services (catalog AD 1747 ≈ 2294) | n/s | 1800–2400 window (≈ 1910) |
| steam_propulsion / internal_combustion / powered_flight / jet_propulsion (`Materials`) | n/s | Other lines place these at their catalog years (≈ 2464 / 2603 / 2675 / 2771). Transport services here follow them |
