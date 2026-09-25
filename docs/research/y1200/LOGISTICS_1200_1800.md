# Logistics: years 1200–1800

**Scope.** The game's **Logistics** research line (`logistics` dynamic; `Movement`-direction entries, the shipbuilding and cartwright catalogs) continues `LOGISTICS_600_1200.md` and `registry_1200.json`. It covers draft harness and carriage, hulls, rigs and steering, navigation at sea, water routes, posts and roads, and the carrying side of trade: fairs, carriers, cargo papers and payment at a distance. Bridges, causeways and harbor works are Infrastructure; pound locks are placed here. Coinage, banking houses, fair courts and merchant leagues are Institutions. Rows that touch those lines are marked shared. Names are generic practices. Real history is used only to calibrate dates.

**Historical anchor.** On the `technology_eras.gd` CURVE `[[800,-500],[1500,1000],[2000,1600]]`, game 1200 is about AD 360, 1300 about AD 570, 1400 about AD 790, 1500 about AD 1000, 1600 about AD 1120, 1700 about AD 1240 and 1800 about AD 1360. In years 1200–1500 one game year is about 2.14 historical years. In 1500–1800 it is about 1.2 historical years, so discoveries crowd more closely in the second table. Years 1200–1500 cover late-antique and early-medieval analogs: freight moving from failing roads to water, camels replacing carts in dry lands, clinker shells, keeled open-sea ships, the rigid horse collar, nailed horseshoes and the first pound lock. Years 1500–1800 cover the high-medieval expansion: frame-first hulls, fairs, bills of exchange, the magnetic needle, the sternpost rudder, high-sided bulk ships, sea charts and the dry compass card.

**Research time.** Time is given in game years while a staffed Logistics team is working on the item. Real minutes are for **1 day/s**: 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3.

**Id column.** A plain `id` is in the main catalog today; its year comes from `HISTORICAL_YEAR` through the CURVE. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `scripts/*.gd` or another 1200–1800 list. "(continues: id)" names an earlier registry item that the row improves. "(shared: X)" marks an item that straddles into line X. Bands are ±40 years, ±30 for key thresholds.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `n/s` when the item is in main but was not reached in any recorded run, and `—` when it is not in main.

## Years 1200–1500 (≈ AD 360–1000)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1218 (1178–1258) | Wagon levies from towns along an army's line of march (shared: security) | 6 y | 36 min | NEW · wagon_requisition_levy | — |
| 1225 (1185–1265) | Pack camels displace carts on dry-country roads (regional; continues: camel_caravans) | 10 y | 61 min | NEW · camel_displaces_cart | — |
| 1240 (1200–1280) | Post stations kept by local landholders for fees when the state post fails (continues: state_post_passes) | 6 y | 36 min | NEW · fee_kept_post_stations | — |
| 1248 (1208–1288) | Sewn-plank hulls lashed with coir for surf coasts (regional) | 6 y | 36 min | NEW · sewn_plank_hulls | — |
| 1255 (1215–1295) | Freight shifted from failing roads to rivers and coasts | 6 y | 36 min | NEW · road_to_water_freight_shift | — |
| 1263 (1223–1303) | Hired caravan guides who know the wells and the peoples on the route | 5 y | 30 min | NEW · hired_caravan_guides | — |
| 1270 (1230–1310) | Hull planks held by fewer, wider-spaced tenons as frames take the load | 10 y | 61 min | NEW · spaced_tenon_planking | — |
| 1285 (1245–1325) | Lateen-rigged merchant ships with long yards (continues: fore_and_aft_sail) | 10 y | 61 min | NEW · lateen_merchant_rig | — |
| 1293 (1253–1333) | Coastal carrying trade in short hops, cargo sold on at each port | 6 y | 36 min | NEW · coastal_cabotage_trade | — |
| **1300 (1270–1330)** | **Padded rigid horse collar that loads the shoulders, not the throat (continues: breast_strap_harness; shared: nutrition)** | 14 y | 85 min | NEW · rigid_horse_collar | — |
| 1308 (1268–1348) | Estate carrying services between scattered holdings | 6 y | 36 min | NEW · estate_carrying_services | — |
| 1315 (1275–1355) | Travel hostels at mountain passes lodge travelers without charge (shared: infrastructure) | 8 y | 49 min | NEW · pass_hospices | — |
| 1330 (1290–1370) | Remittance certificates: pay in the provinces, collect in the capital (shared: institutions) | 10 y | 61 min | NEW · remittance_certificates | — |
| **1340 (1310–1370)** | **Overlapping riveted planks built up as a shell** | 12 y | 73 min | clinker_shell_construction | n/s |
| 1352 (1312–1392) | Paddle-wheel boats driven by treadles on rivers and lakes (regional; shared: security) | 10 y | 61 min | NEW · treadle_paddle_boats | — |
| 1365 (1325–1405) | Hulls divided by watertight bulkheads (regional) | 12 y | 73 min | NEW · watertight_bulkheads | — |
| 1375 (1335–1415) | Shaft harness for a single horse between two poles | 8 y | 49 min | NEW · single_horse_shafts | — |
| **1385 (1355–1415)** | **True keel and one square sail on open-sea clinker ships** | 12 y | 73 min | NEW · keeled_sailing_longships | — |
| 1390 (1350–1430) | Seasonal beach markets at river mouths where ships winter | 8 y | 49 min | NEW · seasonal_beach_emporia | — |
| 1395 (1355–1435) | Land-finding by birds, swell and cloud on open-sea runs (continues: wayfinding_stars) | 6 y | 36 min | NEW · land_finding_signs | — |
| 1400 (1360–1440) | Great desert crossings by caravans of thousands of camels (regional; continues: camel_caravans) | 12 y | 73 min | NEW · great_desert_caravans | — |
| 1405 (1365–1445) | Paid hauling teams at river portages move boats between river systems (continues: portage_paths) | 8 y | 49 min | NEW · portage_hauling_stations | — |
| 1415 (1375–1455) | Pivoting whippletree evens the pull of each draft animal | 6 y | 36 min | NEW · whippletree_evener | — |
| 1420 (1380–1460) | Road and bridge upkeep owed by every landholder (shared: infrastructure, labor) | 6 y | 36 min | NEW · landholder_bridge_duty | — |
| 1425 (1385–1465) | Beamy open-sea cargo ships with a half-deck and hold | 12 y | 73 min | NEW · open_sea_cargo_ships | — |
| 1435 (1395–1475) | Luff spar holds the sail's edge to windward for beating | 6 y | 36 min | NEW · windward_luff_spar | — |
| 1440 (1400–1480) | Hack-silver cut and weighed again on northern routes (regional; continues: weighed_silver_payment) | 5 y | 30 min | NEW · hacksilver_trade | — |
| 1445 (1405–1485) | Winter sledge roads over frozen rivers and marsh (regional; continues: sledges_travois) | 6 y | 36 min | NEW · winter_sledge_roads | — |
| **1455 (1425–1485)** | **Nailed iron horseshoes (continues: iron_hoof_boots)** | 10 y | 61 min | NEW · nailed_horseshoes | — |
| 1465 (1425–1505) | Pole-star height taken with a knotted cord and tablet to hold a latitude (regional) | 8 y | 49 min | NEW · pole_star_latitude_tablet | — |
| 1475 (1435–1515) | Battened sails that reef panel by panel (regional) | 8 y | 49 min | NEW · battened_panel_sails | — |
| 1485 (1445–1525) | Ship stores reckoned per crew member per day of voyage | 6 y | 36 min | NEW · voyage_victualling_scales | — |
| **1493 (1463–1523)** | **Pound locks: a chamber with two gates lifts boats between levels (continues: flash_lock_gates; shared: infrastructure)** | 16 y | 97 min | canal_locks | n/s |

## Years 1500–1800 (≈ AD 1000–1360)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 1505 (1465–1545) | Pack-horse trains of hired carriers on upland roads (continues: mountain_pack_trains) | 6 y | 36 min | NEW · packhorse_carrier_trains | — |
| 1515 (1475–1555) | Horses harnessed in file for heavy loads | 6 y | 36 min | NEW · tandem_file_harness | — |
| 1525 (1485–1565) | Carrier tariffs fixed per load and per stage | 5 y | 30 min | NEW · carrier_stage_tariffs | — |
| 1535 (1495–1575) | Stay-at-home partner funds a traveling merchant for a share of profit (continues: voyage_partnerships; shared: institutions) | 8 y | 49 min | NEW · funded_traveling_merchant | — |
| **1540 (1510–1570)** | **Frames raised first, then planks fastened flush to them** | 16 y | 97 min | carvel_frame_construction | n/s |
| 1548 (1508–1588) | Horse transports that land mounted troops from the sea (shared: security) | 10 y | 61 min | NEW · horse_transport_ships | — |
| 1558 (1518–1598) | Wheel drag shoes for steep descents | 5 y | 30 min | NEW · wheel_drag_shoes | — |
| 1568 (1528–1608) | Safe-conduct letters for merchants crossing hostile ground (shared: institutions) | 6 y | 36 min | NEW · merchant_safe_conducts | — |
| **1580 (1550–1610)** | **Seasonal trade fairs with a guarded peace and fixed settling days** | 12 y | 73 min | NEW · guarded_trade_fairs | — |
| 1592 (1552–1632) | Merchant marks painted and stamped on bales and casks (continues: painted_cargo_labels) | 5 y | 30 min | NEW · merchant_bale_marks | — |
| **1600 (1570–1630)** | **Magnetized needle floated in water to find north at sea** | 14 y | 85 min | NEW · floating_needle_compass | — |
| 1602 (1562–1642) | Carriers answer for goods lost or spoiled on the road | 5 y | 30 min | NEW · carrier_loss_liability | — |
| 1610 (1570–1650) | Bridge brotherhoods fund and keep river bridges by toll and gift (shared: infrastructure) | 8 y | 49 min | NEW · bridge_brotherhoods | — |
| 1622 (1582–1662) | Towing horses replace crews on river towpaths (continues: towpaths) | 6 y | 36 min | NEW · horse_towed_barges | — |
| 1630 (1590–1670) | Written sea customs binding masters, crews and shippers (shared: institutions) | 10 y | 61 min | NEW · written_sea_customs | — |
| 1640 (1600–1680) | Horse-drawn freight wagons replace ox carts on long hauls | 8 y | 49 min | NEW · horse_freight_wagons | — |
| **1650 (1620–1680)** | **Bills of exchange paid in another coin at a set date (continues: distant_payment_letters; shared: institutions)** | 12 y | 73 min | NEW · bills_of_exchange | — |
| 1660 (1620–1700) | Endowed roadside inns spaced a day's ride apart on trunk routes (continues: road_stations; shared: infrastructure) | 10 y | 61 min | NEW · endowed_day_stage_inns | — |
| 1668 (1628–1708) | Cable ferries hauled along a rope across rivers (continues: ferry_crossings) | 6 y | 36 min | NEW · cable_ferries | — |
| 1678 (1638–1718) | Weekly markets spaced a day's walk apart across a district | 8 y | 49 min | NEW · day_walk_market_spacing | — |
| **1685 (1655–1715)** | **Hinged sternpost rudder hung on pintles** | 14 y | 85 min | NEW · sternpost_rudder | — |
| **1692 (1662–1722)** | **Flat-bottomed, high-sided bulk ships with a straight sternpost** | 12 y | 73 min | NEW · high_sided_bulk_ships | — |
| 1698 (1658–1738) | Deck windlass for anchors and heavy yards | 6 y | 36 min | NEW · deck_windlass | — |
| **1703 (1673–1733)** | **Horse-relay post across a vast realm, stations a day's ride apart, metal passes (continues: state_post_passes)** | 14 y | 85 min | NEW · realm_relay_post | — |
| 1706 (1666–1746) | Annual wine and salt fleets sail together to fixed markets | 8 y | 49 min | NEW · annual_bulk_fleets | — |
| 1716 (1676–1756) | Public weighhouse where bulk goods are weighed for a fee | 6 y | 36 min | NEW · public_weighhouses | — |
| 1722 (1682–1762) | Reef points shorten a square sail aloft | 6 y | 36 min | NEW · reef_points | — |
| 1728 (1688–1768) | Ship capacity rated in standard casks carried | 6 y | 36 min | NEW · cask_tonnage_rating | — |
| 1735 (1695–1775) | Summit canals fed from upland reservoirs (continues: trunk_canals; shared: infrastructure) | 14 y | 85 min | NEW · reservoir_fed_summit_canals | — |
| **1742 (1712–1772)** | **Sea charts drawn from compass bearings between harbors (continues: written_sailing_directions; shared: knowledge)** | 12 y | 73 min | NEW · compass_bearing_sea_charts | — |
| 1748 (1708–1788) | Bills of lading: the master signs for cargo taken aboard | 6 y | 36 min | NEW · bills_of_lading | — |
| 1752 (1712–1792) | State-auctioned merchant galley convoys on fixed routes | 10 y | 61 min | NEW · auctioned_galley_convoys | — |
| **1757 (1727–1787)** | **Dry pivoted compass needle under a wind-rose card** | 10 y | 61 min | NEW · dry_compass_card | — |
| 1762 (1722–1802) | Staple towns where passing goods must be offered for sale (shared: institutions) | 8 y | 49 min | NEW · staple_market_towns | — |
| 1767 (1727–1807) | Sandglass-timed watches and reckoned speed for dead reckoning | 8 y | 49 min | NEW · sandglass_dead_reckoning | — |
| 1772 (1732–1812) | Licensed river and harbor pilots | 6 y | 36 min | NEW · licensed_pilots | — |
| 1777 (1737–1817) | Scheduled merchant courier runs between trading cities | 8 y | 49 min | NEW · merchant_courier_schedules | — |
| 1782 (1742–1822) | Merchant handbooks of routes, tolls, coins and measures (continues: road_itineraries) | 8 y | 49 min | NEW · merchant_route_handbooks | — |
| 1788 (1748–1828) | Sea insurance by premium, separate from any loan (shared: institutions) | 10 y | 61 min | NEW · premium_sea_insurance | — |
| 1795 (1755–1835) | Registers of ships, owners and masters kept at the harbor | 6 y | 36 min | NEW · harbor_ship_registers | — |

## Pacing

| Years | 1200–1250 | 1250–1300 | 1300–1350 | 1350–1400 | 1400–1450 | 1450–1500 | 1500–1550 | 1550–1600 | 1600–1650 | 1650–1700 | 1700–1750 | 1750–1800 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Logistics advances | 4 | 5 | 5 | 6 | 8 | 5 | 6 | 4 | 6 | 7 | 8 | 9 |

The total is **73** advances: 33 in years 1200–1500 and 40 in years 1500–1800. Across the four channels (draft and carriage, hulls and rigs, navigation, routes and trade), one lands about every 8–9 years. Most items take 5–10 years. Hull and navigation thresholds take 12–16 years. The last 150 years are densest, because 1.2 historical years per game year puts the compass, rudder, bulk ships and charts close together.

**Key thresholds:**
1. **Draft and carriage:** rigid horse collar (1300; its use in ploughing is Nutrition's) → single-horse shafts (1375) → whippletree (1415) → nailed horseshoes (1455) → horses in file (1515) → horse freight wagons (1640).
2. **Hulls and rigs:** spaced tenons (1270) → lateen merchant rig (1285) → `clinker_shell_construction` (1340) → watertight bulkheads (1365, regional) → keeled open-sea ships (1385) → open-sea cargo ships (1425) → `carvel_frame_construction` (1540) → sternpost rudder (1685) → high-sided bulk ships (1692) → reef points (1722). Rope-walk cables are Production (1730). The state shipyard payroll is Labor (1598).
3. **Navigation:** land-finding signs (1395) → pole-star latitude tablet (1465) → floating needle (1600) → compass-bearing sea charts (1742) → dry compass card (1757) → sandglass dead reckoning (1767). The needle's declination is Knowledge (`magnetic_declination_note`, 1612), and so is map-making in general. Fleet-scale open-sea crossing is `ocean_sailing` in Security (1692).
4. **Water routes:** road-to-water shift (1255) → treadle paddle boats (1352) → portage hauling stations (1405) → `canal_locks` pound locks (1493) → horse-towed barges (1622) → cable ferries (1668) → reservoir-fed summit canals (1735). Bridges and marsh causeways are Infrastructure.
5. **Routes, posts and trade:** fee-kept post stations (1240) → estate carrying services (1308) → pass hospices (1315) → remittance certificates (1330) → landholders' road and bridge duty (1420) → guarded trade fairs (1580) → carrier liability (1602) → bills of exchange (1650) → realm relay post (1703) → public weighhouse (1716) → bills of lading (1748) → staple towns (1762) → premium sea insurance (1788). These are owned elsewhere: road-hostel infirmaries (Health 1320), foreign merchant quarters (Demography 1500), fair courts (Institutions 1628) and the league of chartered towns (Institutions 1722).

**Government and civic life.** These rows should change offices, law or buildings at the seat of rule:
- The **realm relay post** (1703) adds a postmaster's office and pass-bearing couriers who reach the court in days.
- **Guarded trade fairs** (1580) add fair wardens and the ruler's peace over the fair ground. The fair court itself is Institutions (1628).
- The **public weighhouse** (1716) and **staple towns** (1762) put a sworn weigher and a staple hall in the market square.
- **Harbor ship registers** (1795) and **licensed pilots** (1772) add a harbor office.
- **Remittance certificates** (1330) put a remittance bureau in the treasury. **Bills of exchange** (1650) bring money-dealers to the court as lenders.
- **Written sea customs** (1630) give harbor judges a written rule to apply.

## Currently far too early / too late (logistics line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| clinker_shell_construction (catalog AD 700 ≈ 1360) | n/s | 1340 (placed; it was belongs-later in 600–1200) |
| carvel_frame_construction (catalog AD 1400 ≈ 1833) | n/s | 1540 (placed). Frame-first, flush-planked hulls are established by about AD 1000–1050. The catalog date is the late northern adoption |
| canal_locks (catalog AD 984 ≈ 1493) | n/s | 1493 (placed; it was belongs-later in 600–1200). The catalog direction is `Infrastructure`, which defers it to this line |
| ocean_sailing (Warfare) | 141 | 1692, placed in Security (far too early today) |
| dry_dock_services (catalog AD 1747 ≈ 2294) | n/s | Belongs later (≈ 1910; the first graving docks are about AD 1495) |
| wagonway_haulage / rail_gauge_standards / rail_track_foundations | n/s | Belongs later (≈ 1950 for mine wagonways, ≈ 2520 for rails) |
| Sea astrolabe, traverse tables, three-masted full-rigged ship, dished wheels, mitre lock gates | — | Belongs later (≈ 1850–1950) |
