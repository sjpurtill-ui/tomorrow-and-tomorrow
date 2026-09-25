# Logistics dependencies, years 1800–2400

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md` and the 600–1200 and 1200–1800 partials. Cross-line ids are marked with their line. Earlier-block ids are marked "0–600", "600–1200" or "1200–1800". `Requires (any)` groups are separated by `;`. Every prerequisite and precedent is dated strictly before its dependent (registry target years; adjusted years for earlier blocks). No year moves are proposed (`partials/pils_year_adjustments.json` is empty).

Hulls and rigs: `high_sided_bulk_ships` + `lateen_merchant_rig` → `two_masted_round_ships` (1833) → **`full_rigged_three_master`** (1850) → **`ocean_carrack`** (1883). `carvel_frame_construction` + `lateen_merchant_rig` → `lateen_caravel` (1867). `ocean_carrack` + `transoceanic_contact_voyages` → **`ocean_galleon`** (1955) → `escorted_ocean_fleets` (1969) and `cross_ocean_galleon_run` (1974). `high_sided_bulk_ships` → **`fluyt_bulk_carrier`** (1998). `fore_and_aft_sail` → `jib_staysail_rig` (2184) → `coasting_schooner` (2226). `lead_hull_sheathing` + Production's `rolled_metal_strip` → `copper_hull_sheathing` (2354).

Ocean contact, as required: carrack → latitude sailing → contact → galleon. `pole_star_latitude_tablet` + `planispheric_astrolabe` (knowledge) → `mariners_quadrant` (1888); `ocean_carrack` + `mariners_quadrant` → **`latitude_sailing`** (1905); `lateen_caravel` + `seasonal_wind_crossings` → **`ocean_wind_circuit`** (1898); latitude sailing + wind circuit → **`transoceanic_contact_voyages`** (1912), which the contact-gated Production dyes and furs require.

Instruments and longitude: `mariners_quadrant` → `backstaff` (1994) → **`reflecting_octant`** (2262) → **`sextant`** (2306) → with Knowledge's `realm_longitude_observatory`, **`lunar_distance_longitude`** (2318) → `nautical_almanac` (2334). **`marine_timekeeper`** (2348) requires Production's `mainspring_fusee_clocks` and the `sextant` (for local time); lunar distances, the observatory and `precision_thermometry` are precedents. `compass_bearing_sea_charts` + Knowledge's `graticule_world_maps` → **`straight_course_projection_charts`** (1978) → with `printed_engraved_maps`, `printed_sea_atlases` (1988). Knowledge's `triangulation_survey` + `armed_sounding_lead` → `coastal_hydrographic_survey` (2295) → `hydrographic_office` (2384).

Water routes: `reservoir_fed_summit_canals` + Infrastructure's `mitre_lock_gates` → **`staircase_summit_canal`** (2080; `canal_locks` is a precedent) → **`two_sea_canal`** (2160) → with Infrastructure's `canal_river_aqueducts`, **`contour_coal_canal`** (2326) → `trunk_canal_cross` (2366). `joint_stock_company` (institutions) + `contour_coal_canal` → `canal_share_companies` (2358).

Roads and posts: `strap_suspended_carriages` + `pivoting_front_axle` → `slung_carriage_body` (1806) → **`passenger_coach`** (1878) → **`long_route_stagecoaches`** (2110) → `post_chaise_hire` (2252). `realm_relay_post` → **`public_letter_post`** (1930) → with stagecoaches, **`timed_mail_coaches`** (2372). Infrastructure's `turnpike_trust_roads` → `turnpike_milestones` (2274). `deep_silver_mining` + `plank_trackways` → `wagonway_haulage` (1960) → `iron_plated_wagonway_rails` (2338). `treadle_paddle_boats` + Production's `double_acting_engine` → `trial_steam_paddle_boat` (2390).

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 1806 | `slung_carriage_body` | `strap_suspended_carriages` (600–1200), `pivoting_front_axle` (600–1200) | - | `single_horse_shafts` (1200–1800) | - | The body hangs on chains or straps above the frame. |
| 1815 | `armed_sounding_lead` | `sounding_lead` (600–1200), `written_sailing_directions` (600–1200) | - | `compass_bearing_sea_charts` (1200–1800), `licensed_pilots` (1200–1800) | environment=coast | Tallow in the lead brings up the bottom; grounds are logged. |
| 1833 | `two_masted_round_ships` | `high_sided_bulk_ships` (1200–1800), `lateen_merchant_rig` (1200–1800) | - | `sternpost_rudder` (1200–1800), `carvel_frame_construction` (1200–1800) | environment=coast | A lateen mizzen is stepped aft of the square main. |
| 1840 | `tilt_covered_wagons` | `horse_freight_wagons` (1200–1800) | - | `carrier_stage_tariffs` (1200–1800) | - | A hooped canvas tilt keeps carriers' goods dry. |
| 1850 | **`full_rigged_three_master`** | `two_masted_round_ships` | - | `reef_points` (1200–1800), `raked_bow_foresail` (600–1200) | environment=coast | Square fore and main with a lateen mizzen. |
| 1863 | `traverse_course_tables` | `sandglass_dead_reckoning` (1200–1800), `half_chord_sine_tables` (knowledge, 1200–1800) | - | `compass_bearing_sea_charts` (1200–1800) | - | A table turns a zig-zag course into distance made good. |
| 1867 | `lateen_caravel` | `carvel_frame_construction` (1200–1800), `lateen_merchant_rig` (1200–1800) | - | `windward_luff_spar` (1200–1800) | environment=coast | A light lateen ship beats against contrary winds. |
| 1872 | `fortified_trading_posts` | `coastal_trading_colonies` (600–1200), `lateen_caravel` | - | `merchant_quarters_abroad` (0–600), `salaried_trade_factors` (labor, 1200–1800) | environment=coast | Walled posts overseas house resident factors. |
| 1878 | **`passenger_coach`** | `slung_carriage_body` | - | `endowed_day_stage_inns` (1200–1800) | - | Coach-makers build a light passenger coach on a slung body. |
| 1883 | **`ocean_carrack`** | `full_rigged_three_master` | - | `deck_windlass` (1200–1800), `annual_bulk_fleets` (1200–1800) | environment=coast | A deep-holded, high-castled ship for ocean voyages. |
| 1888 | `mariners_quadrant` | `pole_star_latitude_tablet` (1200–1800), `planispheric_astrolabe` (knowledge, 1200–1800) | - | `horary_quadrant` (knowledge, 1200–1800) | - | Quadrant and sea astrolabe take star and sun heights on deck. |
| 1892 | `topsail_rig` | `full_rigged_three_master` | - | `reef_points` (1200–1800) | environment=coast | Topsails set above the courses on fore and main. |
| 1898 | **`ocean_wind_circuit`** | `lateen_caravel`, `seasonal_wind_crossings` (600–1200) | - | `land_finding_signs` (1200–1800) | environment=coast | Ships stand far out to find the prevailing winds home. |
| 1905 | **`latitude_sailing`** | `ocean_carrack`, `mariners_quadrant` | - | `printed_ephemerides` (knowledge), `traverse_course_tables` | environment=coast | Noon sun and declination tables find the parallel to run down. |
| 1908 | `ocean_victualling` | `voyage_victualling_scales` (1200–1800), `barreled_salt_meat` (nutrition, 1200–1800) | - | `coopered_cargo_casks` (600–1200) | - | Biscuit, salt meat and water casks stock months at sea. |
| 1912 | **`transoceanic_contact_voyages`** | `latitude_sailing`, `ocean_wind_circuit` | - | `ocean_victualling`, `fortified_trading_posts` | environment=coast | Return voyages cross the western ocean to newly met lands. |
| 1914 | `dry_dock_services` | `mitre_lock_gates` (infrastructure), `excavated_harbor_basins` (infrastructure, 600–1200) | - | `ship_sheds` (infrastructure, 600–1200), `launching_cradles` (600–1200) | environment=coast | A gated dock is drained for hull work. |
| 1918 | `ocean_house_of_trade` | `transoceanic_contact_voyages`, `harbor_ship_registers` (1200–1800) | - | `royal_chancery_office` (institutions, 1200–1800) | - | A board registers every ocean voyage, cargo and pilot. |
| 1926 | `master_pattern_chart` | `compass_bearing_sea_charts` (1200–1800), `ocean_house_of_trade` | - | `graticule_world_maps` (knowledge) | - | A master chart is corrected from each returning log. |
| 1930 | **`public_letter_post`** | `realm_relay_post` (1200–1800) | - | `merchant_courier_schedules` (1200–1800), `fee_kept_post_stations` (1200–1800) | - | The realm post carries private letters for fees. |
| 1934 | `examined_ocean_pilots` | `licensed_pilots` (1200–1800), `ocean_house_of_trade` | - | `latitude_sailing` | - | A chief pilot examines and licenses ocean pilots. |
| 1938 | `buoyed_channel_corporation` | `licensed_pilots` (1200–1800), `harbor_beacon_towers` (infrastructure, 600–1200) | - | `harbor_masters` (600–1200) | environment=coast | Pilots buoy and beacon the harbour channels. |
| 1942 | `whipstaff_steering` | `sternpost_rudder` (1200–1800) | - | `ocean_carrack` | - | A whipstaff lever steers a large ship from below. |
| 1946 | `gimballed_compass` | `dry_compass_card` (1200–1800) | - | `ocean_carrack` | - | Gimbals keep the compass level in a seaway. |
| 1948 | `dished_wheels` | `spoked_wheel_assembly` (0–600), `horse_freight_wagons` (1200–1800) | - | `felloe_jointing` (0–600), `iron_tyre_fitting` (production, 600–1200) | - | Dished wheels on splayed axles ride over ruts. |
| 1955 | **`ocean_galleon`** | `ocean_carrack`, `transoceanic_contact_voyages` | - | `naval_gunnery` (security), `topsail_rig` | environment=coast | A long, low-castled ship carries cargo and guns across the ocean. |
| 1960 | `wagonway_haulage` | `deep_silver_mining` (production, 1200–1800), `plank_trackways` (0–600) | - | `single_wheel_barrow` (600–1200) | - | Guided trucks run on timber rails in the mines. |
| 1969 | **`escorted_ocean_fleets`** | `ocean_galleon`, `annual_bulk_fleets` (1200–1800) | - | `merchant_ship_convoys` (600–1200), `naval_gunnery` (security) | - | Escorted fleets sail twice a year and bring bullion home. |
| 1974 | `cross_ocean_galleon_run` | `ocean_galleon`, `ocean_wind_circuit` | - | `escorted_ocean_fleets` | - | A yearly galleon trades silver across the widest ocean. |
| 1978 | **`straight_course_projection_charts`** | `compass_bearing_sea_charts` (1200–1800), `graticule_world_maps` (knowledge) | - | `master_pattern_chart` | - | A projection keeps compass courses straight on the chart. |
| 1982 | `log_and_line` | `sandglass_dead_reckoning` (1200–1800) | - | `rope_laying` (0–600) | - | A log and knotted line measure a ship's speed. |
| 1988 | `printed_sea_atlases` | `straight_course_projection_charts`, `printed_engraved_maps` (knowledge) | - | `written_sailing_directions` (600–1200) | - | Charts and sailing directions are printed together. |
| 1994 | `backstaff` | `mariners_quadrant` | - | `latitude_sailing` | - | The sun's height is taken with the observer's back to it. |
| 1998 | **`fluyt_bulk_carrier`** | `high_sided_bulk_ships` (1200–1800) | - | `crank_driven_sawmills` (production, 1200–1800), `deck_windlass` (1200–1800) | environment=coast | A cheap, narrow-decked hull worked by a small crew. |
| 2006 | `company_merchant_fleets` | `joint_stock_company` (institutions), `ocean_galleon` | - | `fortified_trading_posts` | - | Chartered companies keep fleets, factors and warehouses. |
| 2012 | `entrepot_reexport_port` | `staple_market_towns` (1200–1800), `escorted_ocean_fleets` | - | `public_weighhouses` (1200–1800) | - | An entrepot port re-exports far-sea goods along the coast. |
| 2018 | `endorsed_bills` | `bills_of_exchange` (1200–1800) | - | `municipal_exchange_bank` (institutions) | - | Endorsed bills pass from hand to hand. |
| 2022 | `ship_logbooks` | `log_and_line` | - | `traverse_course_tables` | - | Course, speed and weather are written each watch. |
| 2026 | `azimuth_variation_finding` | `gimballed_compass` | - | `magnetic_declination_note` (knowledge, 1200–1800), `earth_magnet_treatise` (knowledge) | - | The sun's rising bearing gives the compass variation. |
| 2034 | `hackney_coaches` | `passenger_coach` | - | `stage_animal_hire` (600–1200) | - | Coaches ply for hire in town streets. |
| 2042 | `navigators_log_scale` | `logarithms` (knowledge) | - | `traverse_course_tables` | - | A logarithmic scale solves courses with dividers. |
| 2050 | `victualling_yards` | `ocean_victualling` | - | `naval_arsenals` (security, 600–1200), `navy_board` (security) | - | State yards bake biscuit and pack salt meat for the fleet. |
| 2058 | `scheduled_passenger_barges` | `horse_towed_barges` (1200–1800) | - | `merchant_courier_schedules` (1200–1800) | - | Towpath barges leave at fixed hours. |
| 2066 | `carriers_guide` | `merchant_route_handbooks` (1200–1800) | - | `tilt_covered_wagons`, `town_printing_houses` (knowledge) | - | A printed guide lists every carrier, inn and departure. |
| 2072 | `distance_postage_rates` | `public_letter_post` | - | `carrier_stage_tariffs` (1200–1800) | - | Postage is fixed by distance and published. |
| 2080 | **`staircase_summit_canal`** | `reservoir_fed_summit_canals` (1200–1800), `mitre_lock_gates` (infrastructure) | - | `canal_locks` (infrastructure, 1200–1800), `horse_towed_barges` (1200–1800) | - | A summit canal links two river basins for through barges. |
| 2090 | `scheduled_stage_wagons` | `horse_freight_wagons` (1200–1800), `tilt_covered_wagons` | - | `carriers_guide` | - | Stage wagons run on fixed days between towns. |
| 2098 | `own_hull_navigation_law` | `company_merchant_fleets` | - | `frontier_customs_posts` (600–1200), `free_seas_doctrine` (institutions) | - | The realm's cargoes go only in the realm's own ships. |
| 2110 | **`long_route_stagecoaches`** | `passenger_coach` | - | `endowed_day_stage_inns` (1200–1800), `post_horse_studs` (600–1200) | - | Coaches change teams at an inn each stage. |
| 2118 | `river_navigation_commissions` | `horse_towed_barges` (1200–1800), `harbor_dredging` (infrastructure, 600–1200) | - | `river_toll_stations` (600–1200) | environment=river | Commissioners dredge and straighten rivers for barges. |
| 2132 | `steel_leaf_springs` | `slung_carriage_body`, `cementation_blister_steel` (production) | - | `passenger_coach`, `spring_shears` (production, 600–1200) | - | Steel leaf springs carry the coach body. |
| 2140 | `broad_wheel_laws` | `scheduled_stage_wagons` | - | `dished_wheels` | - | Heavy wagons must run on broad wheels. |
| 2150 | `printed_road_books` | `carriers_guide`, `strip_route_maps` (600–1200) | - | `printed_engraved_maps` (knowledge) | - | A road book of strip maps and measured miles. |
| 2160 | **`two_sea_canal`** | `staircase_summit_canal` | - | `lock_staircases` (infrastructure) | - | A canal joins two seas for through trade. |
| 2168 | `mail_packet_ships` | `public_letter_post` | - | `fluyt_bulk_carrier` | environment=coast | Packets carry the mail on fixed sailing days. |
| 2176 | `underwriters_room` | `premium_sea_insurance` (1200–1800), `coffee_houses` (nutrition) | - | `merchant_newsletters` (knowledge) | - | Underwriters meet in a coffee house and share ship news. |
| 2184 | `jib_staysail_rig` | `fore_and_aft_sail` (600–1200), `full_rigged_three_master` | - | `raked_bow_foresail` (600–1200), `topsail_rig` | - | Jibs and staysails are set between the masts. |
| 2190 | `builders_measure_tonnage` | `cask_tonnage_rating` (1200–1800) | - | `harbor_dues_by_cargo` (600–1200) | - | A builder's formula sets tonnage for dues. |
| 2196 | `crossroad_fingerposts` | `distance_milestones` (infrastructure, 600–1200) | - | `printed_road_books` | - | The law requires fingerposts at crossroads. |
| 2212 | `draft_horse_breeding` | `heavy_draught_breeding` (nutrition, 1200–1800) | - | `horse_freight_wagons` (1200–1800) | - | Heavy draft horses are bred for freight wagons. |
| 2218 | `ships_steering_wheel` | `whipstaff_steering` | - | `deck_windlass` (1200–1800) | - | A wheel works the tiller through ropes. |
| 2226 | `coasting_schooner` | `fore_and_aft_sail` (600–1200), `jib_staysail_rig` | - | `fluyt_bulk_carrier`, `coastal_cabotage_trade` (1200–1800) | environment=coast | A fore-and-aft rigged schooner works the coasting trade. |
| 2234 | `bonded_warehouses` | `harbor_warehouses` (0–600), `transit_bond_seals` (600–1200) | - | `entrepot_reexport_port` | - | Transit goods lie duty-free in bonded stores. |
| 2240 | `printed_cargo_forms` | `bills_of_lading` (1200–1800) | - | `town_printing_houses` (knowledge) | - | Manifest, bill of lading and charter-party are printed forms. |
| 2246 | `drawn_hull_plans` | `frame_moulding` (600–1200) | - | `scale_plan_drawings` (infrastructure) | - | Ships are built from drawn body plans and half-models. |
| 2252 | `post_chaise_hire` | `long_route_stagecoaches` | - | `steel_leaf_springs` | - | Light chaises are hired stage by stage. |
| 2262 | **`reflecting_octant`** | `backstaff` | - | `experimental_optics` (knowledge) | - | Two mirrors hold sun and horizon in one view. |
| 2268 | `printed_shipping_lists` | `underwriters_room` | - | `printed_weekly_news` (knowledge) | - | A printed list of arrivals, departures and losses. |
| 2274 | `turnpike_milestones` | `turnpike_trust_roads` (infrastructure) | - | `distance_milestones` (infrastructure, 600–1200) | - | A milestone stands at every mile of the turnpike. |
| 2282 | `night_fly_wagons` | `scheduled_stage_wagons` | - | `turnpike_trust_roads` (infrastructure), `draft_horse_breeding` | - | Fast freight wagons drive through the night. |
| 2295 | `coastal_hydrographic_survey` | `triangulation_survey` (knowledge), `armed_sounding_lead` | - | `printed_sea_atlases` | - | Home coasts are triangulated and sounded. |
| 2306 | **`sextant`** | `reflecting_octant` | - | `eyepiece_design` (knowledge) | - | A sextant measures wide angles for lunar distances. |
| 2318 | **`lunar_distance_longitude`** | `sextant`, `realm_longitude_observatory` (knowledge) | - | `comet_return_prediction` (knowledge) | - | Longitude is worked from the moon's distance and tables. |
| 2326 | **`contour_coal_canal`** | `two_sea_canal`, `canal_river_aqueducts` (infrastructure) | - | `coal_grading` (production), `puddled_clay_canal_lining` (infrastructure) | - | A contour canal halves the price of a mine's coal in the city. |
| 2334 | `nautical_almanac` | `lunar_distance_longitude` | - | `printed_ephemerides` (knowledge) | - | A printed almanac tabulates lunar distances. |
| 2338 | `iron_plated_wagonway_rails` | `wagonway_haulage` | - | `coke_firing` (production) | - | Iron plates cap colliery wagonway rails. |
| 2348 | **`marine_timekeeper`** | `mainspring_fusee_clocks` (production), `sextant` | - | `sandglass_dead_reckoning` (1200–1800), `gear_cutting_engine` (production), `lunar_distance_longitude`, `realm_longitude_observatory` (knowledge), `precision_thermometry` (knowledge) | - | A sea clock keeps home-port time for longitude. |
| 2354 | `copper_hull_sheathing` | `lead_hull_sheathing` (600–1200), `rolled_metal_strip` (production) | - | `dry_dock_services`, `sail_battle_fleet` (security) | - | Copper sheets guard hulls against worm and weed. |
| 2358 | `canal_share_companies` | `joint_stock_company` (institutions), `contour_coal_canal` | - | `share_exchange_bourse` (institutions), `river_toll_stations` (600–1200) | - | Canal companies raise shares and charge tolls by charter. |
| 2366 | `trunk_canal_cross` | `contour_coal_canal` | - | `canal_share_companies` | - | Trunk canals join four river systems. |
| 2372 | **`timed_mail_coaches`** | `public_letter_post`, `long_route_stagecoaches` | - | `turnpike_trust_roads` (infrastructure), `steel_leaf_springs` | - | Guarded mail coaches run to a timed schedule. |
| 2384 | `hydrographic_office` | `coastal_hydrographic_survey` | - | `nautical_almanac` | - | A state office publishes surveyed charts. |
| 2390 | `trial_steam_paddle_boat` | `treadle_paddle_boats` (1200–1800), `double_acting_engine` (production) | - | `scheduled_passenger_barges` | environment=river | A steam paddle boat is tried upriver. |
