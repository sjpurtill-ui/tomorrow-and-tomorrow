# Logistics: the first 600 years

**Scope.** The game's **Logistics** research line (`logistics` dynamic; `direction: "Movement"` or `"logistics"` entries, mapped in `discovery_system.gd`) has four channels: Carrying capacity, Route quality, Storage system and Trade reach. It covers carrying, trails and fords, pack and draft animals, sledges, rafts, dugouts and plank boats, rollers, wheeled carts, roads and trackways, handling stores, and the logistics of exchange. The main catalog has 33 Movement/logistics entries (discovery list, `technology_branch_catalog.gd`, `shipbuilding_knowledge.gd`, `rail_freight_knowledge.gd`, `naval_service_knowledge.gd`). About 14 of them belong before year 600. This list also claims the pre-600 wheel and cart steps from `cartwright_knowledge.gd` (catalogued as Infrastructure), `graded_roads` and `timber_bridges` (shared: infrastructure) and `supply_groups` (catalogued under Warfare). Granaries, pit and sealed-vessel storage stay with Nutrition. Public stores, ration issue, caravan tolls and licensed merchant houses stay with Institutions. Messengers and signals stay with Knowledge.

**Historical anchor.** Game years 0–300 correspond to roughly 5000–3000 BC (late Neolithic: dugouts, sledges, first pack donkeys, then the solid wheel). Years 300–600 correspond to roughly 3000–1500 BC (early Bronze Age: sail, plank hulls, harbors, canals, donkey caravans, spoked wheels). This is the pacing curve from `codex/era-research-pacing` (`technology_eras.gd`).

**Research time.** Time is given in game years while a staffed Logistics team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** `id` = in the main catalog today. `(era)` = written on the unmerged branch `codex/era-research-pacing` (`early_practice_knowledge.gd`) and not yet in main. `NEW` = not authored yet. "(shared: X)" marks an item that straddles into vertical X but is listed here because its main effect is logistics.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). It is `—` when the item is not in main, and `n/s` when it is in main but was not reached in any recorded run.

## Years 0–300 (≈ 5000–3000 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2 (0–6) | Carried loads balanced on tumpline and back | 1.5 y | 9 min | carried_load_balancing (era) | — |
| 3 (0–7) | Landmark route names | 1.5 y | 9 min | landmark_route_naming (era) | — |
| 4 (0–8) | Two carriers share one heavy load | 1.5 y | 9 min | paired_carrier_balancing (era) | — |
| 5 (1–9) | Guest-host welcome for travelers | 1.5 y | 9 min | guest_host_reciprocity (era) | — |
| 6 (1–11) | Vermin-deterrent placement in stores | 2 y | 12 min | vermin_deterrent_placement (era) | — |
| 7 (2–12) | Hide floats and lashed log rafts | 2 y | 12 min | hide_floats | 6 |
| 8 (3–13) | Dry cache siting | 2 y | 12 min | dry_cache_siting (era) | — |
| 10 (4–16) | Carrying pole for two-ended loads | 2 y | 12 min | NEW | — |
| 12 (5–19) | Trail waymarking: blazes and stacked stones | 2 y | 12 min | trail_waymarking (era) | — |
| 14 (7–21) | Dugout canoes and paddles | 3 y | 18 min | river_craft | 13 |
| 16 (8–24) | Gift tokens between trade partners | 2 y | 12 min | trade_partner_tokens (era) | — |
| 18 (10–26) | Hand-drawn sledges and travois | 3 y | 18 min | NEW | — |
| 20 (11–29) | Down-the-line exchange of flint, obsidian and shell | 3 y | 18 min | NEW | — |
| 22 (12–32) | Load-lashing knots and hitches | 2 y | 12 min | NEW | — |
| 25 (15–35) | Food caches along regular travel routes | 3 y | 18 min | NEW | — |
| 28 (17–39) | Portage paths between waterways | 3 y | 18 min | NEW | — |
| 32 (19–45) | Skis and snowshoes for winter travel (regional) | 3 y | 18 min | NEW | — |
| 36 (22–50) | Reed-bundle boats sealed with bitumen (regional) | 4 y | 24 min | NEW | — |
| 40 (25–55) | Brushwood mats laid over soft ground | 3 y | 18 min | NEW | — |
| 45 (29–61) | Backframes for bulky loads | 3 y | 18 min | NEW | — |
| 50 (30–70) | Exchange partners meet at fixed boundary places | 4 y | 24 min | NEW | — |
| 60 (40–80) | Night travel steered by the stars | 4 y | 24 min | wayfinding_stars | 22 |
| 65 (45–85) | Rollers and runners for heavy logs and stones | 5 y | 30 min | NEW | — |
| 75 (50–100) | Seasonal ford timing | 3 y | 18 min | seasonal_ford_timing (era) | — |
| 78 (50–105) | Relay carrying shifts on long hauls | 4 y | 24 min | relay_carrying_shifts (era) | — |
| 80 (55–105) | Oldest-first stock marking | 3 y | 18 min | oldest_first_marking (era) | — |
| 85 (55–115) | Remembered trade partners and their wants | 3 y | 18 min | trade_partner_memory (era) | — |
| 90 (60–120) | Salt and shell exchange routes | 5 y | 30 min | NEW | — |
| 100 (65–135) | Boat landings cleared and marked on rivers | 4 y | 24 min | NEW | — |
| 110 (75–145) | Hide-covered boats on wicker frames | 5 y | 30 min | NEW | — |
| 115 (75–155) | Stock layering in stores | 3 y | 18 min | stock_layering_method (era) | — |
| 120 (80–160) | Seasonal route assessment | 4 y | 24 min | seasonal_route_assessment (era) | — |
| 125 (85–165) | Customary barter equivalences | 5 y | 30 min | barter_equivalence_custom (era) | — |
| 135 (95–175) | Oxen trained to draw sledges | 8 y | 49 min | NEW | — |
| 140 (100–180) | Polished stone axes carried over long distances | 5 y | 30 min | NEW | — |
| **150 (110–190)** | **Donkeys as pack animals** | 12 y | 73 min | pack_animals | 35 |
| 152 (110–190) | Loads bundled by weight | 3 y | 18 min | load_bundling_by_weight (era) | — |
| 155 (115–195) | Customary rest-stop spacing | 3 y | 18 min | rest_stop_spacing_custom (era) | — |
| 160 (120–200) | Pest barriers kept in repair | 3 y | 18 min | pest_barrier_maintenance (era) | — |
| 165 (125–205) | Shared escort for trade parties | 4 y | 24 min | shared_trade_escort (era) | — |
| 170 (130–210) | Pack loads balanced side to side | 3 y | 18 min | pack_load_balancing (era) | — |
| 175 (135–215) | Wooden pack saddles | 5 y | 30 min | NEW | — |
| 180 (140–220) | Plank trackways across wetland (shared: infrastructure) | 8 y | 49 min | NEW | — |
| 185 (145–225) | Paired-ox yoke | 6 y | 37 min | NEW | — |
| 190 (150–230) | Store doors sealed with clay and seal (shared: knowledge) | 5 y | 30 min | NEW | — |
| 200 (160–240) | Dugouts raised with sewn side planks | 8 y | 49 min | NEW | — |
| **225 (185–265)** | **Solid wheels of joined planks (shared: infrastructure)** | 15 y | 91 min | solid_wheel_assembly | n/s |
| 228 (190–270) | Axles shaped and fitted | 5 y | 30 min | wooden_axle_shaping | n/s |
| 232 (190–270) | Linchpins keep wheels on the axle | 4 y | 24 min | linchpin_retention | n/s |
| 235 (195–275) | Trade outposts in distant river towns | 10 y | 61 min | NEW | — |
| **240 (200–280)** | **Ox-drawn solid-wheel carts** | 10 y | 61 min | cart_bed_framing | n/s |
| 242 (200–280) | Cargo stowage order | 4 y | 24 min | cargo_stowage_sequencing (era) | — |
| 245 (205–285) | Storage humidity judged by hand and smell | 4 y | 24 min | storage_humidity_judging (era) | — |
| 248 (210–290) | Market timing knowledge | 4 y | 24 min | market_timing_knowledge (era) | — |
| 252 (210–290) | Crossing points surveyed | 5 y | 30 min | crossing_point_survey (era) | — |
| 260 (220–300) | Four-wheeled wagons | 10 y | 61 min | NEW | — |
| **272 (230–310)** | **Square sail on river boats** | 12 y | 73 min | sail_panel_cutting | n/s |
| 278 (240–320) | Cargo transferred at waypoints | 4 y | 24 min | waypoint_cargo_transfer (era) | — |
| 282 (240–320) | Alternate routes scouted | 4 y | 24 min | alternate_route_scouting (era) | — |
| 285 (245–325) | Cache capacity accounted | 5 y | 30 min | cache_capacity_accounting (era) | — |
| 288 (250–330) | Seasonal trade gatherings | 5 y | 30 min | seasonal_trade_gathering (era) | — |
| 292 (250–330) | Organized supply parties (shared: security) | 6 y | 37 min | supply_groups | 28 |
| 295 (255–335) | Cargo seals checked at dispatch and arrival | 6 y | 37 min | cargo_seals | 73 |
| 298 (260–340) | Woven haul harness and drawbar | 5 y | 30 min | haul_harness_weaving | n/s |
| **300 (260–340)** | **Graded roads (shared: infrastructure)** | 15 y | 91 min | graded_roads | 26 |

## Years 300–600 (≈ 3000–1500 BC)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 305 (265–345) | Cart running gear matched to loads | 6 y | 37 min | cart_running_gear | n/s |
| **310 (270–350)** | **Sewn-plank river and coastal boats** | 15 y | 91 min | coastal_watercraft | 41 |
| 315 (275–355) | Timber footbridges (shared: infrastructure) | 8 y | 49 min | timber_bridges | 143 |
| 320 (280–360) | Laid rope for towing and rigging | 5 y | 30 min | rope_laying | n/s |
| 325 (285–365) | Caulking fiber prepared with pitch | 4 y | 24 min | caulking_fiber_preparation | 21 |
| 330 (290–370) | Hull seams caulked and pitched | 5 y | 30 min | hull_seam_caulking | n/s |
| 335 (295–375) | Tenon and treenail plank joints | 6 y | 37 min | treenail_fastening | n/s |
| 340 (300–380) | Towpaths: boats hauled upstream by rope | 5 y | 30 min | NEW | — |
| 345 (305–385) | Stepped mast and yard | 6 y | 37 min | mast_making | n/s |
| 350 (310–390) | Fixed ferry crossings | 5 y | 30 min | NEW | — |
| 355 (315–395) | Planks shaped to the hull curve | 6 y | 37 min | plank_spiling | n/s |
| 360 (320–400) | Central storehouses with sealed rooms and issue days (shared: institutions) | 10 y | 61 min | NEW | — |
| 370 (330–410) | Loads spread across a convoy | 5 y | 30 min | convoy_load_distribution (era) | — |
| 375 (335–415) | Store airflow arrangement | 5 y | 30 min | store_airflow_arrangement (era) | — |
| 380 (340–420) | Trade route risk assessment | 5 y | 30 min | trade_route_risk_assessment (era) | — |
| 385 (345–425) | Waystation spacing | 5 y | 30 min | waystation_spacing_judgment (era) | — |
| 390 (350–430) | Onager-hybrid teams for four-wheeled wagons | 10 y | 61 min | NEW | — |
| 395 (355–435) | Stone-paved haul roads from quarries (shared: infrastructure) | 10 y | 61 min | NEW | — |
| **400 (360–440)** | **Sheltered harbor with a stone jetty** | 12 y | 73 min | NEW | — |
| 405 (365–445) | Heavy sledges on wetted timber tracks | 6 y | 37 min | NEW | — |
| 410 (370–450) | Canal cuts for boat traffic (shared: infrastructure) | 12 y | 73 min | NEW | — |
| 415 (375–455) | Seagoing hulls stiffened with a hogging truss | 10 y | 61 min | NEW | — |
| 425 (385–465) | Grain barges moved in fleets on canals | 6 y | 37 min | NEW | — |
| **435 (395–475)** | **Donkey caravans on fixed seasonal routes** | 10 y | 61 min | NEW | — |
| 445 (405–485) | Standard-size transport jars | 6 y | 37 min | NEW | — |
| 455 (415–495) | Road stations with wells and lodging | 8 y | 49 min | NEW | — |
| **475 (435–515)** | **Horses broken to draft and riding** | 15 y | 91 min | domesticated_mounts | 40 |
| 485 (445–525) | Hired carriers and boatmen by contract (shared: institutions) | 5 y | 30 min | NEW | — |
| 490 (450–530) | Spokes tenoned into hub and felloe rim | 8 y | 49 min | spoke_tenon_cutting | n/s |
| **500 (460–540)** | **Light spoked wheels** | 12 y | 73 min | spoked_wheel_assembly | n/s |
| **510 (470–550)** | **Island-hopping sea crossings under sail** | 15 y | 91 min | NEW | — |
| 518 (480–560) | Pack trains of tin and cloth over mountain passes | 8 y | 49 min | NEW | — |
| 525 (485–565) | Resident merchant quarters in foreign towns | 8 y | 49 min | NEW | — |
| 540 (500–580) | Pilots and known sea lanes between harbors | 6 y | 37 min | NEW | — |
| 550 (510–590) | Seasonal sailing calendar for sea trade | 6 y | 37 min | NEW | — |
| 560 (520–600) | Harbor warehouse districts | 10 y | 61 min | NEW | — |
| 570 (530–610) | Oxhide-shaped copper ingots as standard cargo | 6 y | 37 min | NEW | — |
| 590 (550–630) | Sealed consignment lists travel with cargo (shared: knowledge) | 5 y | 30 min | NEW | — |
| 600 (560–640) | Fresh-team stations on main roads | 8 y | 49 min | NEW | — |

## Pacing

| Years | 0–50 | 50–100 | 100–150 | 150–200 | 200–250 | 250–300 | 300–350 | 350–400 | 400–450 | 450–500 | 500–550 | 550–600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Logistics advances | 20 | 8 | 7 | 10 | 9 | 10 | 10 | 9 | 7 | 4 | 5 | 5 |

The total is **104** advances: 65 in the first 300 years and 39 in the next 300. Across the four channels, one lands about every 5–6 years. The first 50 years are dense with 1.5–3-year carrying, trail and cache practices. The big transport steps (donkey, wheel, sail, plank hull, graded road, spoked wheel) take 10–15 years each, so the count per window falls in the second 300 years while each step matters more.

**Key thresholds:**
1. **Carrying:** tumpline and pole (2–10) → sledges and travois (18) → rollers (65) → donkey pack animals (150) → ox yoke (185) → solid-wheel ox carts (225–240) → four-wheeled wagons (260) → horses for draft (475) → spoked wheels (500).
2. **Water:** hide floats and rafts (7) → dugouts (14) → reed and hide boats (36–110) → plank-raised dugouts (200) → river sail (272) → sewn-plank hulls (310) → harbor (400) → canal cuts (410) → seagoing hulls (415) → open-sea crossings under sail (510).
3. **Routes:** waymarks (12) → fords (75) → plank trackways (180) → graded roads (300) → footbridges (315) → paved quarry roads (395) → road stations (455) → fresh-team stations (600).
4. **Stores and exchange:** caches (8–25) → down-the-line exchange (20) → barter equivalences (125) → sealed store doors (190) → trade outposts (235) → cargo seals (295) → central storehouses (360) → donkey caravans (435) → merchant quarters abroad (525) → harbor warehouses (560).

## Currently too early (logistics line, main)

These are placement targets only. The "Seen" column is the earliest year observed in recorded runs. "Belongs" converts the `technology_eras.gd` date to a game year, or uses the placement above.

| Item | Seen | Belongs |
|---|---|---|
| grown_frame_selection | 17 | Beyond 600 (≈ 700) |
| caulking_fiber_preparation | 21 | 325 |
| wayfinding_stars | 22 | 60 |
| graded_roads | 26 | 300 |
| supply_groups (Warfare catalog) | 28 | 292 |
| pack_animals | 35 | 150 |
| domesticated_mounts | 40 | 475 |
| caravanserais | 40 | Beyond 600 (≈ 1450) |
| coastal_watercraft | 41 | 310 |
| mounted_scouts | 46 | Beyond 600 (≈ 700) |
| cargo_seals | 73 | 295 |
| counterweight_cranes | 134 | Beyond 600 (≈ 890) |
| timber_bridges | 143 | 315 |

The wheel and cart steps (`solid_wheel_assembly`, `cart_bed_framing`, `spoked_wheel_assembly`) were not reached in any recorded run, so their timing is still unmeasured.
