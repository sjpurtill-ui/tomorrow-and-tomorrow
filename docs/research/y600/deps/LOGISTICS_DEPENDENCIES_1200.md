# Logistics dependencies, years 600–1200

Machine-readable source: `partials/pils.json`. The format follows `docs/research/deps/MAPPING_CONTRACT.md`. Cross-line ids are marked with their line, and 0–600 ids are marked "0–600". `Requires (any)` groups are separated by `;`. A year marked `*` is a proposed move listed in `partials/pils_year_adjustments.json`.

Hull chain: `hogging_truss_hulls` (0–600) → `deep_hold_merchantmen` (700) → keel scarfing and grown frames → `frame_moulding` (706) → `great_bulk_freighters` (1020) → `state_grain_fleets` (1040).

Rig chain: `sail_seaming` (0–600, adopted by the game block at 280; the 630 row is excluded as a duplicate) → `brailed_square_sail` (650) → `standing_running_rigging` (917) → `raked_bow_foresail` (965) → `fore_and_aft_sail` (1170).

Money chain: `silver_cupellation` + `traveling_balance_kits` → `weighed_silver_payment` (735) → `die_struck_coinage` (production 790) → `money_changers` / `coin_count_trade` → `deposit_transfer_orders` (893) → `distant_payment_letters` (1140).

Wheeled transport depends on production iron: `axle_sleeve_fitting` needs `bloomery_smelting`, and `sleeved_cart_assembly` needs `iron_tyre_fitting`.

| Year | Discovery | Requires (all) | Requires (any) | Precedents | Conditions | Note |
|---|---|---|---|---|---|---|
| 620 | `composite_stone_anchors` | `coastal_watercraft` (0–600) | - | `rope_laying` (0–600) | - | Stone weight with wooden flukes. |
| 640 | `harbor_dues_by_cargo` | `stone_jetty_harbors` (0–600), `consignment_lists` (0–600) | - | `caravan_tolls` (institutions, 0–600) | - | Cargo lists become the tax base. |
| 650 | **`brailed_square_sail`** | `sail_seaming` (0–600), `mast_making` (0–600) | - | - | - | Brails furl the sail from deck. |
| 660 | `axle_sleeve_fitting` | `wooden_axle_shaping` (0–600), `bloomery_smelting` (production) | - | `cart_running_gear` (0–600) | - | Iron sleeves line wooden axle boxes. |
| 665 | `traveling_balance_kits` | `standard_weight_sets` (production, 0–600), `balance_beam_weights` (knowledge, 0–600) | - | - | - | Portable balance and weights. |
| 680 | `timber_rafting` | `distant_timber_reserves` (ecology, 0–600) | - | `river_craft` (0–600), `rope_laying` (0–600) | environment=river | Distant logs floated downriver. |
| 685 | `rutted_rock_roadbeds` | `graded_roads` (0–600), `wedge_and_fire_quarrying` (infrastructure, 0–600) | - | `four_wheeled_wagons` (0–600) | - | Pass roads cut in rock. |
| 695 | `launching_cradles` | `hogging_truss_hulls` (0–600) | - | `wetted_track_sledging` (0–600), `rollers_and_runners` (0–600) | - | Long hulls built and launched on slips. |
| 700 | **`deep_hold_merchantmen`** | `brailed_square_sail`, `hogging_truss_hulls` (0–600) | - | `launching_cradles`, `hull_seam_caulking` (0–600) | - | Round hulls under brailed sail. |
| 702 | `keel_scarfing` | `deep_hold_merchantmen`, `timber_splice_connections` (infrastructure, 0–600) | - | - | - | Long keels spliced by scarf. |
| 704 | `grown_frame_selection` | `deep_hold_merchantmen`, `timber_seasoning` (production, 0–600) | - | - | - | Curved timber chosen for frames. |
| 706 | `frame_moulding` | `grown_frame_selection` | - | `template_based_sizing` (production, 0–600) | - | Frame curves set out from moulds. |
| 710 | **`camel_caravans`** | `donkey_caravans` (0–600) | - | `mountain_pack_trains` (0–600), `pack_saddles` (0–600) | environment=dry | Caravan practice moved to camels. |
| 715 | `desert_water_stages` | `road_stations` (0–600), `rainwater_cisterns` (infrastructure, 0–600) | - | `camel_caravans` | environment=dry | Stations and cisterns on dry routes. |
| 720 | `mule_breeding` | `domesticated_mounts` (0–600), `donkey_caravans` (0–600) | - | `onager_hybrid_teams` (0–600) | - | Horse and donkey crossed for mules. |
| 725 | `mounted_messengers` | `domesticated_mounts` (0–600), `relay_team_stations` (0–600) | - | - | - | Riders replace runners on relays. |
| 730 | `merchant_ship_convoys` | `deep_hold_merchantmen`, `sailing_calendar` (0–600) | - | `convoy_load_distribution` (0–600) | - | Seasonal sailings grouped. |
| 735 | `weighed_silver_payment` | `silver_cupellation` (production, 0–600), `traveling_balance_kits` | - | `barter_equivalence_custom` (0–600) | - | Refined silver weighed on travel balances. |
| 740 | `coastal_trading_colonies` | `trade_colonies` (0–600), `deep_hold_merchantmen` | - | `merchant_quarters_abroad` (0–600) | - | Merchantmen reach and settle far coasts. |
| 760 | `forward_supply_depots` | `central_storehouses` (0–600), `supply_groups` (0–600) | - | `fortified_stores` (security, 0–600) | - | Stores stocked ahead of a campaign. |
| 780 | `paved_ship_haulway` | `paved_haul_roads` (0–600), `launching_cradles` | - | `wetted_track_sledging` (0–600) | - | Ships dragged on a paved track. |
| 790 | `paired_quarter_rudders` | `deep_hold_merchantmen` | - | `frame_moulding` | - | Twin rudders tied to one tiller. |
| 795 | `money_changers` | `die_struck_coinage` (production), `weighed_silver_payment` | - | - | - | Coins and bullion exchanged at markets. |
| 800 | **`coin_count_trade`** | `die_struck_coinage` (production) | - | `money_changers` | - | Trusted stamps let coins pass by count. |
| 802 | `sleeved_cart_assembly` | `axle_sleeve_fitting`, `iron_tyre_fitting` (production) | - | - | - | Iron-fitted carts assembled. |
| 805 | **`trunk_road_courier_relay`** | `mounted_messengers`, `relay_team_stations` (0–600) | - | `drained_intertown_roads` (infrastructure) | - | Mounted relays at fixed day-stages. |
| 808 | `framed_camel_saddle` | `camel_caravans`, `pack_saddles` (0–600) | - | - | environment=dry | Framed saddle for camel loads. |
| 810 | `trunk_canals` | `navigation_canals` (0–600), `canal_sluice_gates` (infrastructure) | - | `towpaths` (0–600), `gravity_conduit_grade_control` (infrastructure) | - | Gated canals join river systems. |
| 820 | `touchstone_testing` | `weighed_silver_payment` | - | `coin_count_trade`, `iron_assaying` (production) | - | Streak test checks bullion and coin. |
| 825 | `sounding_lead` | `lead_smelting` (production, 0–600), `pilots_sea_lanes` (0–600) | - | - | - | Pilots sound depth and bottom. |
| 845 | `small_change_coins` | `coin_count_trade`, `bronze_alloying` (production, 0–600) | - | - | - | Bronze fractions for daily trade. |
| 855 | `written_sailing_directions` | `pilots_sea_lanes` (0–600), `consonantal_alphabet` (knowledge, 0–600) | - | `sounding_lead` | - | Pilots' lore written down. |
| 860 | `written_freight_contracts` | `consignment_lists` (0–600), `written_court_procedure` (institutions) | - | `sealed_tablet_contracts` (knowledge, 0–600) | - | Freight terms written and enforceable. |
| 870 | `harbor_masters` | `harbor_dues_by_cargo`, `stone_quays` (infrastructure) | - | `excavated_harbor_basins` (infrastructure) | - | Quay berths assigned by an officer. |
| 880 | `voyage_partnerships` | `written_freight_contracts` | - | `licensed_merchant_houses` (institutions, 0–600) | - | Partners share cargo risk by contract. |
| 885 | `tide_reckoning` | `pilots_sea_lanes` (0–600) | - | `astronomical_diaries` (knowledge) | environment=coast | Pilots time tides by the moon. |
| 893 | **`deposit_transfer_orders`** | `money_changers`, `merchant_letter_accounts` (knowledge) | - | `fixed_interest_loans` (institutions, 0–600) | - | Changers pay written orders between accounts. |
| 905 | `general_average_jettison` | `voyage_partnerships` | - | - | - | Jettison shared under partnership law. |
| 910 | `breast_strap_harness` | `haul_harness_weaving` (0–600), `domesticated_mounts` (0–600) | - | - | - | Strap across the chest for horses. |
| 915 | `lead_hull_sheathing` | `lead_sheet_rolling` (production), `deep_hold_merchantmen` | - | `forged_iron_nails` (production) | - | Lead sheet nailed over the hull. |
| 917 | `standing_running_rigging` | `brailed_square_sail`, `rope_laying` (0–600) | - | `compound_pulleys` (infrastructure) | - | Fixed stays separated from working lines. |
| 919 | `wooden_sheave_blocks` | `pole_lathe_turning` (production), `compound_pulleys` (infrastructure) | - | `standing_running_rigging` | - | Turned sheaves in ship blocks. |
| 920 | `grain_receipt_banks` | `central_storehouses` (0–600), `merchant_letter_accounts` (knowledge) | - | `deposit_transfer_orders` | - | Store receipts circulate as payment. |
| 935 | `flash_lock_gates` | `canal_sluice_gates` (infrastructure), `navigation_canals` (0–600) | - | - | - | Weir gate opened to pass boats. |
| 955 | `duty_free_harbor` | `harbor_dues_by_cargo`, `harbor_masters` | - | `foreign_consul_hosts` (institutions) | - | Dues waived to draw shipping. |
| 960 | **`transcontinental_relay_trade`** | `camel_caravans`, `money_changers` | - | `merchant_quarters_abroad` (0–600), `foreign_consul_hosts` (institutions) | - | Coin-backed relays across many peoples. |
| 965 | `raked_bow_foresail` | `standing_running_rigging`, `paired_quarter_rudders` | - | - | - | Bow sail aids steering. |
| 970 | `frontier_customs_posts` | `caravan_tolls` (institutions, 0–600), `jurisdiction_boundaries` (institutions, 0–600) | - | `harbor_dues_by_cargo` | - | Tolls fixed at the frontier line. |
| 980 | `district_road_crews` | `drained_intertown_roads` (infrastructure), `public_levies` (institutions, 0–600) | - | `village_labor_quotas` (labor) | - | Each district levied to keep its road. |
| 990 | **`seasonal_wind_crossings`** | `sailing_calendar` (0–600), `written_sailing_directions` | - | `star_weather_almanac` (knowledge), `raked_bow_foresail` | - | Monsoon timing written into directions. |
| 995 | `pivoting_front_axle` | `four_wheeled_wagons` (0–600), `sleeved_cart_assembly` | - | `iron_tyre_fitting` (production) | - | Front axle swivels on an iron pin. |
| 1000 | `ship_bilge_pumps` | `deep_hold_merchantmen` | `piston_force_pumps` (infrastructure), `screw_water_lifts` (infrastructure) | - | - | Water-lifting machines fitted in hulls. |
| 1005 | `stage_animal_hire` | `mule_breeding`, `road_stations` (0–600) | - | `hired_carriers` (0–600), `coin_count_trade` | - | Station animals hired by the day. |
| 1012 | `raised_floor_warehouses` | `harbor_warehouses` (0–600), `store_airflow_arrangement` (0–600) | - | `pillared_storehouses` (infrastructure) | - | Vented public stores on raised floors. |
| 1020 | **`great_bulk_freighters`** | `frame_moulding`, `keel_scarfing`, `standing_running_rigging` | - | `lead_hull_sheathing`, `merchant_ship_convoys` | - | Moulded frames and rigging scale hulls. |
| 1035 | **`state_post_passes`** | `trunk_road_courier_relay`, `sealed_travel_passes` (institutions, 0–600) | - | `distance_milestones` (infrastructure) | - | Courier relay opened to pass-holders. |
| 1040 | `state_grain_fleets` | `great_bulk_freighters`, `auctioned_public_contracts` (institutions) | - | `town_grain_dole` (nutrition) | - | Freighters contracted for capital grain. |
| 1042 | `iron_hoof_boots` | `smithing_tool_sets` (production), `domesticated_mounts` (0–600) | - | `breast_strap_harness` | - | Strap-on iron shoes for draft animals. |
| 1045 | `treadwheel_quay_cranes` | `counterweight_cranes` (infrastructure), `stone_quays` (infrastructure) | - | `compound_pulleys` (infrastructure) | - | Building cranes moved to the quay. |
| 1050 | `lighter_transshipment` | `great_bulk_freighters`, `grain_barge_fleets` (0–600) | - | - | - | Barges unload deep freighters. |
| 1058 | `painted_cargo_labels` | `stamped_capacity_amphorae` (production) | - | `consignment_lists` (0–600) | - | Stamped jars gain painted details. |
| 1060 | `post_horse_studs` | `state_post_passes` | - | `domesticated_mounts` (0–600) | - | Post supplied by its own studs. |
| 1070 | `strap_suspended_carriages` | `pivoting_front_axle` | - | - | - | Body slung on straps over the axles. |
| 1080 | `common_trade_coin` | `small_change_coins`, `realm_wide_standardization` (institutions) | - | `transcontinental_relay_trade` | - | Standardized coin trusted across regions. |
| 1085 | `oasis_caravan_cities` | `desert_water_stages`, `caravanserais` (infrastructure) | - | `transcontinental_relay_trade` | environment=dry | Stages grow into guarded cities. |
| 1090 | `coopered_cargo_casks` | `iron_bladed_planes` (production), `timber_seasoning` (production, 0–600) | - | `forged_iron_nails` (production) | - | Planed staves hooped into casks. |
| 1100 | `single_wheel_barrow` | `spoked_wheel_assembly` (0–600) | - | `axle_sleeve_fitting` | - | One wheel under a carrier's frame. |
| 1110 | `road_itineraries` | `distance_milestones` (infrastructure) | - | `regional_maps` (knowledge, 0–600), `coordinate_gazetteer_maps` (knowledge) | - | Milestone distances listed by stage. |
| 1120 | `graded_wagon_classes` | `pivoting_front_axle`, `aggregate_road_foundations` (infrastructure) | - | `realm_wide_standardization` (institutions) | - | Wagons classed by road load. |
| 1120 | `transit_bond_seals` | `frontier_customs_posts`, `cargo_seals` (0–600) | - | - | - | Sealed goods pass customs under bond. |
| 1140 | `distant_payment_letters` | `deposit_transfer_orders`, `merchant_letter_accounts` (knowledge) | - | - | - | Transfer orders payable in far markets. |
| 1155 | `canal_boat_slipways` | `trunk_canals`, `paved_ship_haulway` | - | `treadwheel_quay_cranes` | - | Haulways built between canal levels. |
| 1170 | **`fore_and_aft_sail`** | `raked_bow_foresail`, `standing_running_rigging` | - | - | - | Steering foresail grows into a main sail. |
| 1185 | `strip_route_maps` | `road_itineraries`, `regional_maps` (knowledge, 0–600) | - | - | - | Itineraries drawn as strip maps. |
| 1195 | `river_toll_stations` | `frontier_customs_posts` | - | `timber_rafting`, `grain_barge_fleets` (0–600) | - | Customs posts applied to rivers. |
