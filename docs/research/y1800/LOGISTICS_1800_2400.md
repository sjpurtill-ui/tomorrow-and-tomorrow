# Logistics: years 1800–2400

**Scope.** The game's **Logistics** research line (`logistics` dynamic; `Movement`-direction entries, and the shipbuilding, naval-service, cartwright and rail-freight catalogs) continues `y1200/LOGISTICS_1200_1800.md` and `registry_1800.json`. It covers draft and carriage, hulls and rigs, navigation at sea, water routes, posts and roads, and the carrying side of trade: carriers, cargo papers, payment at a distance, ocean fleets and overseas trading posts. Ocean contact (`transoceanic_contact_voyages`, 1912) is placed here. The new-world crops that depend on it belong to Nutrition. Bridges, road construction, harbor works and lighthouses belong to Infrastructure. Canal routes, river navigation and carrying services are placed here. Canal engineering (mitre gates, lock staircases, tunnels, aqueducts) and the turnpike trusts belong to Infrastructure. Banks, exchanges, joint-stock charters and public debt belong to Institutions. Rows that touch those lines are marked shared. Rows marked `[gov: …]` change offices, law, towns or the court. Names are generic practices. Real history is used only to calibrate dates.

**Historical anchor.** The `technology_eras.gd` CURVE on `origin/codex/research-600` runs `[[1500,1000],[2000,1600],[2400,1800]]` through this window. Game 1800 is about AD 1360, 1900 about AD 1480, 2000 about AD 1600, 2100 about AD 1650, 2200 about AD 1700, 2300 about AD 1750 and 2400 about AD 1800. In years 1800–2000, one game year is about 1.2 historical years. In years 2000–2400 it is half a historical year, so a historical decade spreads over 20 game years.
- **Years 1800–2000** cover the late-medieval and oceanic analogs: the three-masted full-rigged ship, carrack and caravel, latitude sailing, the wind circuits, ocean contact, the public letter post, galleons, escorted ocean fleets, straight-course charts and the cheap bulk carrier.
- **Years 2000–2400** cover the early-modern analogs: company fleets, stagecoaches, summit and two-sea canals, packet ships, the octant and sextant, and finally longitude by lunar distance and by marine timekeeper. Steam haulage is only a trial at the very end (2390). Steam boats and rail locomotives belong later.

**Research time.** Time is given in game years while a staffed Logistics team is working on the item. Real time is for **1 day/s**: 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3.

**Id column.** A plain `id` is in the main catalog today. Its year comes from `HISTORICAL_YEAR` through the CURVE, unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `y600/registry_1200.json` (600–1200), `y1200/registry_1800.json` (1200–1800), the game's baked blocks, `scripts/*.gd`, or another 1800–2400 list. "(continues: id)" names an earlier item that the row improves. "(shared: X)" marks an item that straddles into line X. Bands are ±40 years, and ±30 for key thresholds (bold).

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `n/s` when the item is in main but was not reached in any recorded run, and `—` when it is not in main.

## Years 1800–2100 (≈ AD 1360–1650)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1806 (1766–1846) | Carriage body slung on chains or leather straps above the frame | 6 y | 36 min | NEW · slung_carriage_body | — |
| 1815 (1775–1855) | Sounding lead armed with tallow brings up the bottom; depths and grounds written into sailing directions | 6 y | 36 min | NEW · armed_sounding_lead | — |
| 1833 (1793–1873) | Two-masted round ship with a lateen mizzen aft | 8 y | 49 min | NEW · two_masted_round_ships | — |
| 1840 (1800–1880) | Hooped canvas tilt keeps carriers' goods dry on the road (continues: horse_freight_wagons) | 4 y | 24 min | NEW · tilt_covered_wagons | — |
| **1850 (1820–1880)** | **Full-rigged three-master: square fore and main, lateen mizzen (continues: two_masted_round_ships)** | 16 y | 97 min | NEW · full_rigged_three_master | — |
| 1863 (1823–1903) | Traverse table turns a zig-zag course into distance made good (continues: sandglass_dead_reckoning) | 8 y | 49 min | NEW · traverse_course_tables | — |
| 1867 (1827–1907) | Light lateen-rigged exploring ship that beats against contrary winds | 10 y | 61 min | NEW · lateen_caravel | — |
| 1872 (1832–1912) | Fortified overseas trading posts with resident factors (shared: institutions, security) | 10 y | 61 min | NEW · fortified_trading_posts | — |
| **1878 (1848–1908)** | **Light passenger coach with a slung body, built in a coach-making town (continues: slung_carriage_body)** | 12 y | 73 min | NEW · passenger_coach | — |
| **1883 (1853–1913)** | **Ocean carrack: deep hold, high castles, three or four masts (continues: full_rigged_three_master)** | 14 y | 85 min | NEW · ocean_carrack | — |
| 1888 (1848–1928) | Mariner's quadrant and sea astrolabe take the pole star and noon sun on deck (continues: pole_star_latitude_tablet) | 8 y | 49 min | NEW · mariners_quadrant | — |
| 1892 (1852–1932) | Topsails set above the courses on fore and main | 6 y | 36 min | NEW · topsail_rig | — |
| **1898 (1868–1928)** | **Wind-circuit sailing: stand far out to sea to find the prevailing winds home** | 12 y | 73 min | NEW · ocean_wind_circuit | — |
| **1905 (1875–1935)** | **Latitude sailing: noon sun and declination tables, then run down the parallel to landfall (continues: mariners_quadrant)** | 14 y | 85 min | NEW · latitude_sailing | — |
| 1908 (1868–1948) | Ocean victualling: biscuit, salt meat and water casks for months at sea (continues: voyage_victualling_scales) | 6 y | 36 min | NEW · ocean_victualling | — |
| **1912 (1882–1942)** | **Return voyages across the western ocean to newly met lands (contact) [gov: court]** | 20 y | 2 h | NEW · transoceanic_contact_voyages | — |
| 1914 (1874–1954) | Graving dock with gates: a ship is floated in and drained dry for hull work | 12 y | 73 min | dry_dock_services | n/s |
| 1918 (1878–1958) | House of trade registers every ocean voyage, cargo and pilot [gov: offices] (shared: institutions) | 10 y | 61 min | NEW · ocean_house_of_trade | — |
| 1926 (1886–1966) | Master chart corrected from each returning pilot's log (shared: knowledge) | 8 y | 49 min | NEW · master_pattern_chart | — |
| **1930 (1900–1960)** | **Realm post carries private letters for fees under a postmaster-general [gov: offices] (continues: realm_relay_post)** | 12 y | 73 min | NEW · public_letter_post | — |
| 1934 (1894–1974) | Chief pilot examines and licenses ocean pilots [gov: offices] (continues: licensed_pilots) | 6 y | 36 min | NEW · examined_ocean_pilots | — |
| 1938 (1898–1978) | Pilots' corporation buoys and beacons the harbor channels (shared: infrastructure) | 6 y | 36 min | NEW · buoyed_channel_corporation | — |
| 1942 (1902–1982) | Whipstaff lever steers a large ship from below deck | 5 y | 30 min | NEW · whipstaff_steering | — |
| 1946 (1906–1986) | Compass slung in gimbals stays level in a seaway (continues: dry_compass_card) | 5 y | 30 min | NEW · gimballed_compass | — |
| 1948 (1908–1988) | Dished wheels on splayed axles carry heavy loads over ruts | 6 y | 36 min | NEW · dished_wheels | — |
| **1955 (1925–1985)** | **Galleon: long, low-castled ocean ship for cargo and guns (continues: ocean_carrack; shared: security)** | 14 y | 85 min | NEW · ocean_galleon | — |
| 1960 (1920–2000) | Mine wagonways: guided trucks pushed on timber rails | 10 y | 61 min | wagonway_haulage | n/s |
| **1969 (1939–1999)** | **Escorted ocean fleets sail twice a year and bring bullion and goods home (shared: security)** | 12 y | 73 min | NEW · escorted_ocean_fleets | — |
| 1974 (1934–2014) | Yearly galleon run across the widest ocean trades silver for silk (continues: ocean_galleon) | 10 y | 61 min | NEW · cross_ocean_galleon_run | — |
| **1978 (1948–2008)** | **Sea charts on a projection that keeps compass courses straight (continues: compass_bearing_sea_charts; shared: knowledge)** | 14 y | 85 min | NEW · straight_course_projection_charts | — |
| 1982 (1942–2022) | Log and knotted line measure a ship's speed | 6 y | 36 min | NEW · log_and_line | — |
| 1988 (1948–2028) | Printed sea atlas of charts and sailing directions (continues: straight_course_projection_charts; shared: knowledge) | 8 y | 49 min | NEW · printed_sea_atlases | — |
| 1994 (1954–2034) | Backstaff takes the sun's height with the observer's back to it (continues: mariners_quadrant) | 6 y | 36 min | NEW · backstaff | — |
| **1998 (1968–2028)** | **Cheap narrow-decked bulk carrier worked by a small crew (continues: high_sided_bulk_ships)** | 14 y | 85 min | NEW · fluyt_bulk_carrier | — |
| 2006 (1966–2046) | Chartered company fleets with overseas factors and warehouses (continues: joint_stock_company; shared: institutions) | 12 y | 73 min | NEW · company_merchant_fleets | — |
| 2012 (1972–2052) | Entrepot port re-exports far-sea goods to the whole coast (continues: staple_market_towns) | 8 y | 49 min | NEW · entrepot_reexport_port | — |
| 2018 (1978–2058) | Endorsed bills of exchange pass from hand to hand (continues: bills_of_exchange; shared: institutions) | 6 y | 36 min | NEW · endorsed_bills | — |
| 2022 (1982–2062) | Ship's logbook: course, speed and weather written each watch (continues: log_and_line) | 5 y | 30 min | NEW · ship_logbooks | — |
| 2026 (1986–2066) | Sun's bearing at rising taken to find the compass variation at sea (continues: gimballed_compass) | 6 y | 36 min | NEW · azimuth_variation_finding | — |
| 2034 (1994–2074) | Hackney coaches for hire in town streets (continues: passenger_coach) | 5 y | 30 min | NEW · hackney_coaches | — |
| 2042 (2002–2082) | Navigator's logarithmic scale solves courses with dividers | 6 y | 36 min | NEW · navigators_log_scale | — |
| 2050 (2010–2090) | State victualling yards bake biscuit and pack salt meat for the fleets (shared: security) | 10 y | 61 min | NEW · victualling_yards | — |
| 2058 (2018–2098) | Towpath passenger barges leave at fixed hours (continues: horse_towed_barges) | 6 y | 36 min | NEW · scheduled_passenger_barges | — |
| 2066 (2026–2106) | Carriers' guide lists every wagon, inn and departure day (continues: merchant_route_handbooks) | 6 y | 36 min | NEW · carriers_guide | — |
| 2072 (2032–2112) | Postage fixed by distance and published (continues: public_letter_post) | 5 y | 30 min | NEW · distance_postage_rates | — |
| **2080 (2050–2110)** | **Summit canal links two river basins for through barge traffic (continues: reservoir_fed_summit_canals; shared: infrastructure)** | 18 y | 1.8 h | NEW · staircase_summit_canal | — |
| 2090 (2050–2130) | Stage wagons run on fixed days between towns (continues: horse_freight_wagons) | 6 y | 36 min | NEW · scheduled_stage_wagons | — |
| 2098 (2058–2138) | Navigation law: the realm's cargo only in the realm's own ships [gov: law] (shared: institutions) | 8 y | 49 min | NEW · own_hull_navigation_law | — |

## Years 2100–2400 (≈ AD 1650–1800)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2110 (2080–2140)** | **Stagecoaches on long routes, changing teams at an inn each stage (continues: passenger_coach)** | 12 y | 73 min | NEW · long_route_stagecoaches | — |
| 2118 (2078–2158) | River commissioners dredge and straighten rivers for barges [gov: offices] (shared: infrastructure) | 10 y | 61 min | NEW · river_navigation_commissions | — |
| 2132 (2092–2172) | Steel leaf springs under coach bodies (continues: slung_carriage_body) | 8 y | 49 min | NEW · steel_leaf_springs | — |
| 2140 (2100–2180) | Wheel-width laws: broad wheels for heavy wagons [gov: law] | 5 y | 30 min | NEW · broad_wheel_laws | — |
| 2150 (2110–2190) | Printed road book of strip maps and measured miles (continues: carriers_guide) | 8 y | 49 min | NEW · printed_road_books | — |
| **2160 (2130–2190)** | **Canal joins two seas; barges carry the through trade (continues: staircase_summit_canal; shared: infrastructure)** | 24 y | 2.4 h | NEW · two_sea_canal | — |
| 2168 (2128–2208) | Packet ships carry the mail on fixed sailing days (continues: public_letter_post) | 8 y | 49 min | NEW · mail_packet_ships | — |
| 2176 (2136–2216) | Underwriters meet in a coffee house and share ship news (continues: premium_sea_insurance; shared: institutions) | 8 y | 49 min | NEW · underwriters_room | — |
| 2184 (2144–2224) | Jibs and staysails set between the masts | 6 y | 36 min | NEW · jib_staysail_rig | — |
| 2190 (2150–2230) | Tonnage set by a builder's formula for dues (continues: cask_tonnage_rating) | 5 y | 30 min | NEW · builders_measure_tonnage | — |
| 2196 (2156–2236) | Fingerposts at crossroads required by law [gov: law] | 4 y | 24 min | NEW · crossroad_fingerposts | — |
| 2212 (2172–2252) | Heavy draft horses bred for freight wagons (shared: nutrition) | 8 y | 49 min | NEW · draft_horse_breeding | — |
| 2218 (2178–2258) | Ship's wheel worked through ropes to the tiller (continues: whipstaff_steering) | 6 y | 36 min | NEW · ships_steering_wheel | — |
| 2226 (2186–2266) | Fore-and-aft rigged schooner for the coasting trade | 8 y | 49 min | NEW · coasting_schooner | — |
| 2234 (2194–2274) | Bonded warehouses hold transit goods duty-free (shared: institutions) | 6 y | 36 min | NEW · bonded_warehouses | — |
| 2240 (2200–2280) | Printed cargo forms: manifest, bill of lading and charter-party (continues: bills_of_lading) | 5 y | 30 min | NEW · printed_cargo_forms | — |
| 2246 (2206–2286) | Ships built from drawn body plans and half-models | 10 y | 61 min | NEW · drawn_hull_plans | — |
| 2252 (2212–2292) | Light post chaises hired stage by stage (continues: long_route_stagecoaches) | 5 y | 30 min | NEW · post_chaise_hire | — |
| **2262 (2232–2292)** | **Double-reflecting octant holds sun and horizon in one view (continues: backstaff)** | 12 y | 73 min | NEW · reflecting_octant | — |
| 2268 (2228–2308) | Printed shipping list of arrivals, departures and losses (continues: underwriters_room) | 5 y | 30 min | NEW · printed_shipping_lists | — |
| 2274 (2234–2314) | Milestones on every turnpike (continues: turnpike_trust_roads; shared: infrastructure) | 4 y | 24 min | NEW · turnpike_milestones | — |
| 2282 (2242–2322) | Fast freight wagons driven through the night (continues: scheduled_stage_wagons) | 6 y | 36 min | NEW · night_fly_wagons | — |
| 2295 (2255–2335) | Home coasts surveyed by triangulation and soundings (continues: triangulation_survey; shared: knowledge) | 10 y | 61 min | NEW · coastal_hydrographic_survey | — |
| **2306 (2276–2336)** | **Sextant measures wide angles for lunar distances (continues: reflecting_octant)** | 10 y | 61 min | NEW · sextant | — |
| **2318 (2288–2348)** | **Longitude worked at sea by lunar distance from the moon's tables (continues: sextant; shared: knowledge)** | 18 y | 1.8 h | NEW · lunar_distance_longitude | — |
| **2326 (2296–2356)** | **Contour canal carries a mine's coal to the city at half the cart price (continues: two_sea_canal, canal_river_aqueducts)** | 16 y | 97 min | NEW · contour_coal_canal | — |
| 2334 (2294–2374) | Printed nautical almanac of lunar distances [gov: offices] (continues: lunar_distance_longitude; shared: knowledge) | 8 y | 49 min | NEW · nautical_almanac | — |
| 2338 (2298–2378) | Iron-plated rails on colliery wagonways (continues: wagonway_haulage) | 8 y | 49 min | NEW · iron_plated_wagonway_rails | — |
| 2342 (2302–2382) | Iron hoop tyres shrunk hot onto wheels (shared: production) | 5 y | 30 min | NEW · hoop_iron_tyres | — |
| **2348 (2318–2378)** | **Marine timekeeper holds the home port's time at sea for longitude (continues: sandglass_dead_reckoning; shared: knowledge)** | 20 y | 2 h | NEW · marine_timekeeper | — |
| 2354 (2314–2394) | Copper sheathing guards hulls against worm and weed (shared: production) | 10 y | 61 min | NEW · copper_hull_sheathing | — |
| 2358 (2318–2398) | Canal companies raise shares and charge tolls under charter (shared: institutions) | 8 y | 49 min | NEW · canal_share_companies | — |
| 2366 (2326–2406) | Trunk canals join four river systems across the realm (continues: contour_coal_canal; shared: infrastructure) | 14 y | 85 min | NEW · trunk_canal_cross | — |
| **2372 (2342–2402)** | **Mail coaches with armed guards on timed schedules [gov: offices] (continues: public_letter_post)** | 10 y | 61 min | NEW · timed_mail_coaches | — |
| 2384 (2344–2424) | Hydrographic office publishes surveyed charts [gov: offices] (continues: coastal_hydrographic_survey) | 8 y | 49 min | NEW · hydrographic_office | — |
| 2390 (2350–2430) | Trial steam paddle boat runs upriver (experimental; continues: treadle_paddle_boats) | 10 y | 61 min | NEW · trial_steam_paddle_boat | — |

## Pacing

| Years | 1800–1850 | 1850–1900 | 1900–1950 | 1950–2000 | 2000–2050 | 2050–2100 | 2100–2150 | 2150–2200 | 2200–2250 | 2250–2300 | 2300–2350 | 2350–2400 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Logistics advances | 4 | 9 | 12 | 9 | 7 | 7 | 4 | 7 | 6 | 6 | 7 | 6 |

The total is **84** advances: 48 in years 1800–2100 and 36 in years 2100–2400. 20 of them are key thresholds. Across the four channels (draft and carriage, hulls and rigs, navigation, routes and trade), one lands about every 6–7 years. Most items take 5–10 years. Hull, canal and longitude thresholds take 12–24 years. Years 1850–2000 are the densest. Ships, instruments and ocean routes change fastest there, while each game year still covers 1.2 historical years.

**Key thresholds:**
1. **Hulls and rigs:** two-masted round ships (1833) → full-rigged three-master (1850) → caravel (1867) → ocean carrack (1883) → topsails (1892) → galleon (1955) → cheap bulk carrier (1998) → jibs and staysails (2184) → ship's wheel (2218) → schooner (2226) → drawn hull plans (2246) → copper sheathing (2354). The galleon as a warship, gunports and the battle line are Security (`naval_gunnery` 1936, `race_built_warship` 1985, `line_ahead_fleet_tactics` 2116).
2. **Navigation:** sounding lead (1815) → traverse table (1863) → mariner's quadrant (1888) → wind circuits (1898) → latitude sailing (1905) → gimballed compass (1946) → **straight-course charts (1978)** → log and line (1982) → printed sea atlases (1988) → backstaff (1994) → logbooks (2022) → octant (2262) → sextant (2306) → **lunar-distance longitude (2318)** → nautical almanac (2334) → **marine timekeeper (2348)** → hydrographic office (2384). Chronometers on ordinary merchant ships belong to the 2400–3000 list (`merchant_chronometer_issue`, 2493). These belong to Knowledge: the realm longitude observatory (`realm_longitude_observatory`, 2150), triangulation (`triangulation_survey`, 1944), the telescope, the pendulum clock and the mathematics behind the tables. Knowledge removed its own chart-projection and lunar-table rows in favour of the rows here.
3. **Ocean reach and exchange:** fortified trading posts (1872) → **ocean contact (1912)** → house of trade (1918) → escorted ocean fleets (1969) → cross-ocean galleon run (1974) → company fleets (2006) → entrepot port (2012) → navigation law (2098). New-world crops (maize, potatoes, sugar, coffee) are contact-gated in Nutrition. The species exchange and island deforestation are Ecology (1942, 1984).
4. **Water routes:** scheduled passenger barges (2058) → summit canal (2080) → river commissioners (2118) → two-sea canal (2160) → contour coal canal (2326) → canal share companies (2358) → trunk canal cross (2366). The engineering is Infrastructure's: `mitre_lock_gates` (1908), `lock_staircases` (2158), `canal_tunnels` (2162), `puddled_clay_canal_lining` (2321) and `canal_river_aqueducts` (2324).
5. **Roads, coaches and posts:** slung carriage body (1806) → canvas tilt wagons (1840) → passenger coach (1878) → **public letter post (1930)** → dished wheels (1948) → hackney coaches (2034) → distance postage (2072) → stagecoaches (2110) → packet ships (2168) → broad-wheel laws (2140) → post chaises (2252) → milestones (2274) → timed mail coaches (2372). Turnpike trusts and road beds are Infrastructure (`turnpike_trust_roads` 2212, `layered_stone_road_beds` 2350).
6. **Rails and haulage:** `wagonway_haulage` (1960) → iron-plated wagonway rails (2338). Graded rail track and gauges (`rail_track_foundations`, `rail_gauge_standards`) belong later (≈ 2520).
7. **Ownership of overlaps:**
   - **Security:** army magazines (2144), the navy board (1965) and letters of marque (2034).
   - **Infrastructure:** road building (`aggregate_road_foundations` at 890, `layered_stone_road_beds` 2350), turnpike trusts (2212), canal engineering, bridges, wet docks (2230), breakwaters and lighthouses.
   - **Institutions:** joint-stock charters (`joint_stock_company` 2000), exchange banks, bourses, central banks and public debt. `company_merchant_fleets` (2006), `canal_share_companies` (2358), `endorsed_bills` (2018) and `bonded_warehouses` (2234) cover only the carrying side.
   - **Knowledge:** optical signal telegraphs (`shutter_signal_frames`, AD 1795 ≈ 2390).
   - **Health:** quarantine stations and ship quarantine.
   - **Nutrition:** heavy draft-horse breeding is shared (2212).

## Government and civic life

These rows should change offices, law, towns or the court at the seat of rule:
- **Ocean contact** (1912) `[gov: court]` brings envoys, captives' tales and new goods to the court. It opens the far lands to the court's ambitions.
- The **house of trade** (1918) `[gov: offices]` adds a board that registers every ocean voyage, licenses pilots and keeps the master chart. The **chief pilot** (1934) sits in it.
- The **public letter post** (1930) `[gov: offices]` puts a postmaster-general at court. Private letters now reach the capital at a fixed fee. **Distance postage** (2072) and **timed mail coaches** (2372) extend the office.
- The **navigation law** (2098) `[gov: law]` reserves the realm's cargoes for the realm's own ships.
- **River commissioners** (2118) `[gov: offices]`, **wheel-width laws** (2140) `[gov: law]` and **fingerposts** (2196) `[gov: law]` put river and road use into law. The turnpike trusts that give towns their toll-houses are Infrastructure's (2212).
- The **nautical almanac** (2334) and the **hydrographic office** (2384) `[gov: offices]` put astronomers and chart-makers on the state's payroll.

## Currently far too early / too late (logistics line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| dry_dock_services (catalog AD 1747 ≈ 2294) | n/s | 1914 (placed). Gated graving docks are ≈ AD 1495; the catalog date is late. It was belongs-later in 1200–1800. |
| wagonway_haulage (catalog AD 1846 ≈ 2523) | n/s | 1960 (placed). Mine wagonways with guided trucks are ≈ AD 1550; iron-plated rails follow at 2338. |
| rail_track_foundations / rail_gauge_standards (AD 1846 ≈ 2523) | n/s | Still belong later (≈ 2520) |
| rail_vehicle_braking (AD 1869 ≈ 2584) / hull_condition_surveys (AD 1900 ≈ 2667) | n/s | Belong later |
| aggregate_road_foundations (catalog AD 1747 ≈ 2294) | n/s | Already placed at 890 by Infrastructure. Layered broken-stone road surfaces are Infrastructure's; the turnpike trusts (2204) pay for them. |
| carvel_frame_construction (catalog AD 1400 ≈ 1833) | n/s | Already placed at 1540. No row in this window. |
| Steam boats in service, rail locomotives, steam road carriages | — | Belong later (≈ 2410+). Only a trial paddle boat (2390) falls in this window. |
