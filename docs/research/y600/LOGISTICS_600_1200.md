# Logistics: years 600–1200

**Scope.** The game's **Logistics** research line (`logistics` dynamic; `direction: "logistics"` entries, plus the shipbuilding and cartwright catalogs) continues from the 0–600 list (`LOGISTICS_600_YEARS.md`, `registry.json`). It covers carrying and draft animals, wheels and harness, seafaring hulls, sails and harbors, canals, roads and posting systems, and the trade logistics of the coinage era: weighed silver, coins taken by count, money changers, freight contracts, deposit orders and customs. Minting is in Production, sea loans are in Institutions, and harbor works, road beds, milestones and tunnels are in Infrastructure. Names are generic practices. Real history is used only to calibrate dates.

**Historical anchor.** On the `technology_eras.gd` CURVE (`codex/research-600`), game year 600 is about 1500 BC, 800 is about 500 BC, and 1200 is about AD 360. Between 800 and 1500, 500 BC–AD 1000 is interpolated, so one game year is about 2.14 historical years. Years 600–800 cover the Late Bronze Age and early Iron Age: deep-hold merchant ships, camel caravans, and coins in market use by 800. Years 800–1200 cover classical and late-antique analogs: trunk canals, courier relays, standard axle gauges, deposit banks, monsoon-style ocean crossings, great freighters and the state post.

**Research time.** Time is given in game years while a staffed Logistics team is working on the item. Real minutes are for **1 day/s**: 1 game year is about 6 minutes, and 6 years are about 37 minutes. Items in this window take longer than earlier ones (5–16 years).

**Id column.** A plain `id` is in the main catalog today; a year from `HISTORICAL_YEAR` is converted on the CURVE. `NEW` = not authored yet. "(continues: id)" names a 0–600 registry predecessor. "(shared: X)" marks an item that straddles into line X. No row duplicates a registry id.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `n/s` when the item is in main but was not reached in any recorded run, and `—` when it is not in main.


## Years 600–900 (≈ 1500–290 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 610 (570–650) | Standard ingot shapes cast for carrying metal by ship and pack | 8 y | 49 min | NEW · standard_ingot_shapes | — |
| 620 (580–660) | Composite stone anchors with wooden fluke stakes | 6 y | 37 min | NEW · composite_stone_anchors | — |
| 630 (590–670) | Sailcloth seamed from narrow panels and edge-roped | 6 y | 37 min | sail_seaming | n/s |
| 640 (600–680) | Harbor dues assessed by cargo (shared: institutions) | 6 y | 37 min | NEW · harbor_dues_by_cargo | — |
| **650 (620–680)** | **Brailed square sail shortened from the deck** | 10 y | 61 min | NEW · brailed_square_sail | — |
| 660 (620–700) | Iron sleeves fitted in axle boxes | 6 y | 37 min | axle_sleeve_fitting | n/s |
| 665 (625–705) | Traveling merchant's balance and weight set | 6 y | 37 min | NEW · traveling_balance_kits | — |
| 680 (640–720) | Timber rafted downriver from distant forests (continues: distant_timber_reserves) | 8 y | 49 min | NEW · timber_rafting | — |
| 685 (645–725) | Rock-cut roadbeds with worn wheel ruts through passes | 10 y | 61 min | NEW · rutted_rock_roadbeds | — |
| 695 (655–735) | Launching cradles and building slips for large hulls | 8 y | 49 min | launching_cradles | n/s |
| **700 (670–730)** | **Round-hulled merchant ships with deep holds** | 12 y | 73 min | NEW · deep_hold_merchantmen | — |
| 702 (662–742) | Keel timbers joined by long scarfs | 8 y | 49 min | keel_scarfing | n/s |
| 704 (664–744) | Grown timber chosen for curved frames | 6 y | 37 min | grown_frame_selection | 17 |
| 706 (666–746) | Frame shapes laid out from moulds | 8 y | 49 min | frame_moulding | n/s |
| **710 (680–740)** | **Camels bred and trained for desert caravans (regional)** | 12 y | 73 min | NEW · camel_caravans | — |
| 715 (675–755) | Water stages for dry routes: wells, cisterns and jar depots (continues: road_stations) | 8 y | 49 min | NEW · desert_water_stages | — |
| 720 (680–760) | Mules bred for pack trains | 8 y | 49 min | NEW · mule_breeding | — |
| 725 (685–765) | Mounted messengers on set routes | 6 y | 37 min | NEW · mounted_messengers | — |
| 730 (690–770) | Merchant ships sail in seasonal convoys | 6 y | 37 min | NEW · merchant_ship_convoys | — |
| 735 (695–775) | Weighed silver pieces used as payment on trade routes | 8 y | 49 min | NEW · weighed_silver_payment | — |
| 740 (700–780) | Trading settlements founded on foreign coasts (continues: trade_colonies) | 12 y | 73 min | NEW · coastal_trading_colonies | — |
| 760 (720–800) | Forward supply depots stocked before a campaign (shared: security) | 8 y | 49 min | NEW · forward_supply_depots | — |
| 780 (740–820) | Paved haulway for dragging ships across an isthmus | 10 y | 61 min | NEW · paved_ship_haulway | — |
| 790 (750–830) | Paired quarter rudders linked to a tiller bar | 8 y | 49 min | NEW · paired_quarter_rudders | — |
| 795 (755–835) | Money changers at harbors and markets | 6 y | 37 min | NEW · money_changers | — |
| **800 (770–830)** | **Coins taken by count, not weighed, in market trade (shared: institutions)** | 8 y | 49 min | NEW · coin_count_trade | — |
| 802 (762–842) | Carts assembled with sleeved axles and iron fittings | 6 y | 37 min | sleeved_cart_assembly | n/s |
| **805 (775–835)** | **Mounted courier relay on a trunk road with fixed day-stages (continues: relay_team_stations)** | 12 y | 73 min | NEW · trunk_road_courier_relay | — |
| 808 (768–848) | Framed camel saddle for heavy loads (regional) | 8 y | 49 min | NEW · framed_camel_saddle | — |
| 810 (770–850) | Trunk canals linking separate river systems (continues: navigation_canals) | 16 y | 97 min | NEW · trunk_canals | — |
| 820 (780–860) | Touchstone testing of coin and bullion | 6 y | 37 min | NEW · touchstone_testing | — |
| 825 (785–865) | Sounding lead armed with tallow to sample the seabed | 5 y | 30 min | NEW · sounding_lead | — |
| 845 (805–885) | Small bronze change coins for daily trade | 6 y | 37 min | NEW · small_change_coins | — |
| 855 (815–895) | Written sailing directions from harbor to harbor (continues: pilots_sea_lanes) | 10 y | 61 min | NEW · written_sailing_directions | — |
| 860 (820–900) | Written freight contracts with named penalties (shared: institutions) | 6 y | 37 min | NEW · written_freight_contracts | — |
| 870 (830–910) | Harbor masters assign berths and loading turns | 6 y | 37 min | NEW · harbor_masters | — |
| 880 (840–920) | Voyage partnerships sharing cargo, profit and risk | 8 y | 49 min | NEW · voyage_partnerships | — |
| 885 (845–925) | Tide reckoning for harbor entry on tidal coasts (regional) | 6 y | 37 min | NEW · tide_reckoning | — |
| 890 (850–930) | Stamped jar handles naming maker and official | 6 y | 37 min | NEW · stamped_jar_handles | — |
| **893 (863–923)** | **Deposit banks paying written orders between accounts (shared: institutions)** | 10 y | 61 min | NEW · deposit_transfer_orders | — |

## Years 900–1200 (≈ 290 BC–AD 360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 905 (865–945) | Jettison losses shared by all cargo owners | 5 y | 30 min | NEW · general_average_jettison | — |
| 910 (870–950) | Breast-strap harness for draft horses | 8 y | 49 min | NEW · breast_strap_harness | — |
| 915 (875–955) | Lead sheathing on hulls against shipworm | 8 y | 49 min | NEW · lead_hull_sheathing | — |
| 917 (877–957) | Standing and running rigging separated | 8 y | 49 min | standing_running_rigging | n/s |
| 919 (879–959) | Wooden sheave blocks for hoisting yards and cargo | 6 y | 37 min | wooden_sheave_blocks | n/s |
| 920 (880–960) | Grain receipts from state stores passed as payment (shared: institutions) | 8 y | 49 min | NEW · grain_receipt_banks | — |
| 925 (885–965) | Standard axle gauge fixed for all carts | 8 y | 49 min | NEW · standard_axle_gauge | — |
| 935 (895–975) | Flash-lock gates to pass boats over a weir | 10 y | 61 min | NEW · flash_lock_gates | — |
| 955 (915–995) | Duty-free harbor that draws the carrying trade | 8 y | 49 min | NEW · duty_free_harbor | — |
| **960 (930–990)** | **Relay trade across many peoples along a transcontinental route** | 16 y | 97 min | NEW · transcontinental_relay_trade | — |
| 965 (925–1005) | Foresail on a raked bow mast for steering | 8 y | 49 min | NEW · raked_bow_foresail | — |
| 970 (930–1010) | Frontier customs posts levying duty on goods | 6 y | 37 min | NEW · frontier_customs_posts | — |
| 980 (940–1020) | Road crews assigned to keep each district's stretch | 6 y | 37 min | NEW · district_road_crews | — |
| **990 (960–1020)** | **Seasonal-wind crossings of open ocean to far coasts** | 14 y | 85 min | NEW · seasonal_wind_crossings | — |
| 995 (955–1035) | Pivoting front axle on four-wheeled wagons | 10 y | 61 min | NEW · pivoting_front_axle | — |
| 1000 (960–1040) | Chain or force pumps to clear ship bilges | 8 y | 49 min | NEW · ship_bilge_pumps | — |
| 1005 (965–1045) | Stage hire of pack animals and carts by the day | 6 y | 37 min | NEW · stage_animal_hire | — |
| 1012 (972–1052) | Large public warehouses with raised floors and vented walls (continues: store_airflow_arrangement) | 10 y | 61 min | NEW · raised_floor_warehouses | — |
| **1020 (990–1050)** | **Great bulk freighters of several hundred tons** | 14 y | 85 min | NEW · great_bulk_freighters | — |
| **1035 (1005–1065)** | **State post with travel passes and requisitioned mounts** | 10 y | 61 min | NEW · state_post_passes | — |
| 1040 (1000–1080) | State grain fleets sailing on contract to the capital | 10 y | 61 min | NEW · state_grain_fleets | — |
| 1042 (1002–1082) | Removable iron hoof boots for draft animals | 6 y | 37 min | NEW · iron_hoof_boots | — |
| 1045 (1005–1085) | Treadwheel cranes loading ships at quays | 8 y | 49 min | NEW · treadwheel_quay_cranes | — |
| 1050 (1010–1090) | Lighters unload deep freighters at river mouths | 6 y | 37 min | NEW · lighter_transshipment | — |
| 1058 (1018–1098) | Painted labels on cargo jars: contents, weight, shipper | 5 y | 30 min | NEW · painted_cargo_labels | — |
| 1060 (1020–1100) | Stud farms breed and rest horses for the state post | 8 y | 49 min | NEW · post_horse_studs | — |
| 1070 (1030–1110) | Carriage bodies hung on straps to soften the ride | 8 y | 49 min | NEW · strap_suspended_carriages | — |
| 1080 (1040–1120) | One trade coin accepted across many regions | 10 y | 61 min | NEW · common_trade_coin | — |
| 1085 (1045–1125) | Guarded caravan cities at oases on long routes | 10 y | 61 min | NEW · oasis_caravan_cities | — |
| 1090 (1050–1130) | Coopered casks replace jars for bulk liquid cargo (shared: production) | 10 y | 61 min | NEW · coopered_cargo_casks | — |
| 1100 (1060–1140) | Single-wheeled barrow for one carrier | 6 y | 37 min | NEW · single_wheel_barrow | — |
| 1110 (1070–1150) | Written itineraries listing stages and distances | 8 y | 49 min | NEW · road_itineraries | — |
| 1120 (1080–1160) | Freight wagon classes by load for road use | 6 y | 37 min | NEW · graded_wagon_classes | — |
| 1120 (1080–1160) | Sealed transit goods cross frontiers under bond without duty | 6 y | 37 min | NEW · transit_bond_seals | — |
| 1140 (1100–1180) | Merchant letters ordering payment at a distant market | 8 y | 49 min | NEW · distant_payment_letters | — |
| 1155 (1115–1195) | Canal inclined slipways hauling boats between levels | 10 y | 61 min | NEW · canal_boat_slipways | — |
| **1170 (1140–1200)** | **Fore-and-aft triangular sail for sailing closer to the wind** | 16 y | 97 min | NEW · fore_and_aft_sail | — |
| 1185 (1145–1225) | Strip route maps of roads and stations (continues: regional_maps) | 10 y | 61 min | NEW · strip_route_maps | — |
| 1195 (1155–1235) | River patrol-and-toll stations keep barge traffic moving | 6 y | 37 min | NEW · river_toll_stations | — |

## Pacing

| Years | 600–650 | 650–700 | 700–750 | 750–800 | 800–850 | 850–900 | 900–950 | 950–1000 | 1000–1050 | 1050–1100 | 1100–1150 | 1150–1200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Logistics advances | 4 | 6 | 11 | 4 | 8 | 7 | 8 | 7 | 8 | 7 | 5 | 4 |

The total is **79** advances: 40 in years 600–900 and 39 in years 900–1200. Across four channels (carrying, water, routes, stores and exchange), one lands about every 7 years. Items are longer than before (5–16 years), so each team always has one in progress. Years 700–1050 are the densest stretch, when seafaring, coinage and engineered roads all mature together.

**Key thresholds:**
1. **Seafaring:** brailed sail (650) → deep-hold merchantmen (700) → quarter rudders (790) → sounding lead (825) → sailing directions (855) → rigging and sheave blocks (917) → seasonal-wind ocean crossings (990) → great bulk freighters (1020) → state grain fleets (1040) → fore-and-aft sail (1170). Quays, breakwaters, basins, beacons and underwater concrete are Infrastructure rows (670–1024).
2. **Coinage-era trade:** weighed silver (735) → money changers (795) → coins taken by count (800; minting is Production 790) → touchstone (820) → freight contracts (860) → deposit orders (893; sea loans are Institutions `risk_pools` 850) → grain receipts (920) → common trade coin (1080) → distant payment letters (1140).
3. **Roads and posts:** rutted rock roads (685) → mounted messengers (725) → courier relay on trunk roads (805) → standard axle gauge (925) → district road crews (980) → state post with passes (1035) → post-horse studs (1060) → itineraries and strip maps (1110–1185).
4. **Draft and carrying:** axle sleeves (660) → camels and mules (710–720) → sleeved carts (802) → breast-strap harness (910) → pivoting front axle (995) → hoof boots (1042) → barrow (1100).

## Currently far too early / too late (logistics line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| grown_frame_selection | 17 | 704 (far too early) |
| caravanserais | 40 | Placed in Infrastructure (800, walled road stations); not repeated here |
| counterweight_cranes / iron_tyre_fitting | 134 / n/s | Placed in Infrastructure (895) and Production (800); not repeated here |
| mounted_scouts (Warfare) | 46 | 700 (placed in Security) |
| canal_locks (pound locks) | n/s | Belongs later (≈ 1490); flash locks (935) and slipways (1155) cover the window |
| carvel_frame_construction / clinker_shell_construction | n/s | Belongs later (≈ 1300–1360) |
| ocean_sailing (Warfare) | 141 | Belongs later (≈ 1650+); coastal and seasonal-wind crossings only in this window |
| felloe_jointing / wheel_hub_boring / wheel_blank_jointing / wooden_axle_boxes / drawbar_fitting | n/s | Before 600 (≈ 230–500, alongside the registry wheel steps); not placed here |
| Collar harness, nailed horseshoes, paired stirrups, sternpost rudder | — | Belongs later (≈ 1270–1500) |

