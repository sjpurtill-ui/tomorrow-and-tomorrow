# Infrastructure: years 2400–3000

**Scope.** The game's **Infrastructure** research line covers building and civil works: frames and floors, cement and concrete, bridges and tunnels, water supply, sewers and treatment, town services and housing, and from the late nineteenth century the power system: stations, grids, dams and storage. This list continues `docs/research/y1800/INFRASTRUCTURE_1800_2400.md`, which ends with the cast-iron arch bridge, the fireproof iron-framed mill, graded stone road beds, S-trap water closets and iron pressure mains. Names describe generic practices. Real history is used only to calibrate timing. It places every catalog id with direction `Infrastructure` in AD 1800–2030 that the 1800–2400 list did not take, the `?`-direction building ids (`safety_lifts`, `reinforced_concrete`, `structural_steel`, `curtain_wall_systems`), and the power-system ids with direction `Materials` that are works rather than machines (`compressed_air_systems`, `wound_transformers`, `battery_bank_wiring`, `charge_regulation`, `engineered_wood_lamination`, `reactor_engineering`). The pneumatic actuators with direction `Infrastructure` (`directional_air_valves`, `pneumatic_cylinders`, `pneumatic_pressing`, `packed_piston_seals`) are machine parts and are placed by Production. Railways, roads, canals, ports and airports are Logistics' (bridges and tunnels they use are marked here as shared: logistics). Filtration and chlorination of water are Health's.

**Historical anchor.** `CURVE` in `scripts/technology_eras.gd` (`[[2400,1800],[2800,1950],[3000,2030]]`, read from `origin/codex/research-600`) maps game 2400 ≈ AD 1800, 2500 ≈ 1838, 2600 ≈ 1875, 2700 ≈ 1912, 2800 ≈ 1950, 2900 ≈ 1990 and 3000 ≈ 2030. One game year is about 0.375 historical years before 2800 and 0.4 after. The calibration sources run in order:
- gas lighting, iron roofs, chain suspension bridges, clinker cement and the tunnelling shield (2410–2470)
- egg-shaped and intercepting sewers, iron-and-glass halls, passenger lifts, radiators and boulevard rebuilding (2505–2560)
- caissons, rock-drill tunnels, steel bridges, building codes and water towers (2570–2600)
- central power stations, wire-cable bridges, reinforced concrete, steel skeletons, alternating-current grids and hydroelectric stations (2615–2655)
- sludge treatment, zoning, dams, public housing, rural electrification and prestressed concrete (2700–2765)
- reactors, curtain walls, nuclear stations, desalination, tunnel-boring machines and seismic codes (2780–2860)
- solar and wind power, storm-surge barriers, low-energy codes, smart grids, grid batteries and small reactors at the 2030 frontier (2875–2995)

**Research time.** Times are game years of work by a staffed Infrastructure team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd`); its catalog year is in `HISTORICAL_YEAR`. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `y600/registry_1200.json` (600–1200), `y1200/registry_1800.json` (1200–1800), a quoted id in `scripts/*.gd`, or any id in the 1800–2400 lists and the other 2400–3000 lists. "(continues: id)" names the earlier registry item, a row in a 1800–2400 list, a row in another 2400–3000 line, or a row in this list that the row improves.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run. It is `—` when the item is not in main.

## Years 2400–2700 (≈ AD 1800–1912)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2410 (2385–2435) | Rows of back-to-back terraces house mill workers at speed | 3 y | 18 min | NEW · back_to_back_terraces | — |
| 2418 (2393–2443) | Steam pumping stations lift town water into reservoirs and mains (continues: pressure_pipe_jointing) | 4 y | 24 min | NEW · steam_pumped_waterworks | — |
| **2422 (2387–2457)** | **Gas lamps line the streets, fed by mains from the town gasworks (continues: coal_gas_works) [gov: towns]** | 6 y | 37 min | NEW · gas_lit_streets | — |
| 2430 (2405–2455) | Iron roof trusses span wide sheds and markets | 3 y | 18 min | NEW · iron_roof_trusses | — |
| 2450 (2425–2475) | Covered market halls roofed in iron and glass [gov: towns] | 3 y | 18 min | NEW · iron_roofed_market_halls | — |
| **2455 (2420–2490)** | **Wrought-iron chain suspension bridges cross wide rivers (continues: cast_iron_arch_bridge; shared: logistics)** | 8 y | 49 min | NEW · chain_suspension_bridges | — |
| **2464 (2429–2499)** | **Hydraulic cement: clinker burned hot from lime and clay (continues: concrete_mix_design)** | 8 y | 49 min | portland_cement_clinker | not seen |
| 2465 (2440–2490) | Cast-iron street fronts for shops and warehouses (continues: iron_roof_trusses) | 3 y | 18 min | NEW · cast_iron_street_fronts | — |
| **2467 (2432–2502)** | **Tunnelling shield drives through soft ground under rivers (shared: logistics)** | 8 y | 49 min | NEW · tunnelling_shield | — |
| 2485 (2460–2510) | Light frame houses nailed together from sawn studs | 3 y | 18 min | NEW · light_stud_frame_houses | — |
| 2495 (2470–2520) | Brick viaducts of many arches carry level lines across valleys (shared: logistics) | 4 y | 24 min | NEW · brick_arch_viaducts | — |
| 2498 (2473–2523) | Model dwellings for working families, with water and privies on each stair (continues: back_to_back_terraces) [gov: towns] | 4 y | 24 min | NEW · model_worker_dwellings | — |
| 2505 (2480–2530) | Egg-shaped brick sewers scoured by their own flow (continues: vaulted_brick_sewers; shared: health) | 4 y | 24 min | NEW · egg_shaped_sewers | — |
| 2530 (2505–2555) | Riveted wrought-iron box-girder bridges carry heavy loads | 5 y | 30 min | NEW · riveted_box_girder_bridges | — |
| **2533 (2498–2568)** | **Iron-and-glass halls built from standard prefabricated parts [gov: culture]** | 6 y | 37 min | NEW · prefabricated_iron_glass_halls | — |
| 2534 (2509–2559) | Timber frames braced against wind and sway | 3 y | 18 min | timber_lateral_bracing | not seen |
| 2535 (2510–2560) | Compressors and receivers feed air mains to works and tunnels (shared: production) | 3 y | 18 min | compressed_air_systems | not seen |
| 2536 (2511–2561) | Cold stores chilled by compression machines (shared: nutrition) | 5 y | 30 min | mechanical_refrigeration | 232 |
| **2539 (2504–2574)** | **Passenger lifts with safety catches** | 6 y | 37 min | safety_lifts | 230 |
| 2545 (2520–2570) | Rolled iron I-beams carry fireproof floors (continues: iron_framed_fireproof_mill) | 4 y | 24 min | NEW · rolled_iron_floor_beams | — |
| 2548 (2523–2573) | Steam and hot-water radiators heat whole buildings (continues: narrow_throat_fireplace) | 3 y | 18 min | NEW · radiator_central_heating | — |
| **2550 (2515–2585)** | **Intercepting sewers carry town waste far downstream (continues: egg_shaped_sewers; shared: health) [gov: towns]** | 10 y | 61 min | NEW · intercepting_sewers | — |
| **2558 (2523–2593)** | **Great boulevards cut through old quarters, with sewers, water and gas beneath [gov: towns, seat]** | 8 y | 49 min | NEW · boulevard_reconstruction | — |
| 2560 (2535–2585) | Sewer rodding crews clear blocked conduits | 2 y | 12 min | sewer_rodding_service | not seen |
| 2570 (2545–2595) | Compressed-air caissons sink bridge piers deep in riverbeds (continues: bridge_pier_caissons, compressed_air_systems) | 5 y | 30 min | NEW · pneumatic_caissons | — |
| 2578 (2553–2603) | Mountain tunnels driven with compressed-air rock drills (continues: compressed_air_systems; shared: logistics) | 6 y | 37 min | NEW · rock_drill_tunnelling | — |
| **2586 (2551–2621)** | **Steel arch, truss and cantilever bridges of long span (continues: riveted_box_girder_bridges)** | 8 y | 49 min | NEW · steel_long_span_bridges | — |
| 2588 (2563–2613) | Asphalt street paving laid hot over concrete (continues: toll_paved_streets) [gov: towns] | 3 y | 18 min | NEW · asphalt_street_paving | — |
| 2590 (2565–2615) | Building codes set wall thickness, stairs, light and air for housing [gov: towns] | 4 y | 24 min | NEW · building_codes | — |
| 2595 (2570–2620) | High-pressure water mains drive cranes, lifts and dock gates | 3 y | 18 min | NEW · hydraulic_power_mains | — |
| 2598 (2573–2623) | Water towers hold pressure for upper storeys and hydrants | 3 y | 18 min | NEW · water_towers | — |
| 2600 (2575–2625) | Hot-water boilers and piped bathrooms in ordinary houses (continues: s_trap_water_closets) | 3 y | 18 min | NEW · piped_hot_water_bathrooms | — |
| 2610 (2585–2635) | Hollow fired-clay tile floors resist fire (continues: rolled_iron_floor_beams) | 3 y | 18 min | NEW · hollow_tile_fireproof_floors | — |
| 2615 (2590–2640) | Electric arc and filament lamps light streets and halls (continues: gas_lit_streets) [gov: towns] | 4 y | 24 min | NEW · electric_street_lighting | — |
| **2619 (2584–2654)** | **Central generating stations supply a district by wire (continues: electrical_generators) [gov: towns]** | 10 y | 61 min | NEW · central_power_stations | — |
| 2620 (2595–2645) | Town refuse collected on a schedule and burned in destructor furnaces (shared: health) [gov: towns] | 3 y | 18 min | NEW · refuse_destructors | — |
| **2622 (2587–2657)** | **Spun steel-wire cables hang very long spans (continues: chain_suspension_bridges)** | 8 y | 49 min | NEW · wire_cable_suspension_bridges | — |
| **2627 (2592–2662)** | **Reinforced concrete: steel rods cast in concrete** | 8 y | 49 min | reinforced_concrete | 222 |
| 2628 (2603–2653) | Transformers step voltage up for distance and down for use (shared: production) | 5 y | 30 min | wound_transformers | not seen |
| **2632 (2597–2667)** | **Steel skeleton frames carry walls and floors storey by storey** | 8 y | 49 min | structural_steel | 220 |
| 2635 (2610–2660) | Plate-glass shopfronts in steel frames line the streets | 2 y | 12 min | NEW · plate_glass_shopfronts | — |
| **2640 (2605–2675)** | **Tall office towers on steel skeletons with electric lifts (continues: structural_steel) [gov: seat]** | 6 y | 37 min | NEW · skeleton_frame_towers | — |
| 2642 (2617–2667) | Power and telephone wires moved into ducts under the streets [gov: towns] | 3 y | 18 min | NEW · street_utility_ducts | — |
| **2645 (2610–2680)** | **High-voltage alternating current carried between towns (continues: wound_transformers)** | 10 y | 61 min | NEW · alternating_current_grids | — |
| 2650 (2625–2675) | Long gravity aqueducts bring mountain water to cities (continues: long_distance_conduits) [gov: towns] | 6 y | 37 min | NEW · mountain_gravity_aqueducts | — |
| **2655 (2620–2690)** | **Hydroelectric stations at falls and weirs** | 8 y | 49 min | NEW · hydroelectric_stations | — |
| 2667 (2642–2692) | Stationary battery rooms steady station supply (shared: production) | 3 y | 18 min | battery_bank_wiring | not seen |
| 2668 (2643–2693) | Concrete compacted by rodding and vibration | 3 y | 18 min | concrete_compaction_practice | not seen |
| 2672 (2647–2697) | Concrete cured wet for a set time | 3 y | 18 min | concrete_curing_control | not seen |
| 2675 (2650–2700) | Rooms cooled and dried by refrigerating plant (continues: mechanical_refrigeration) | 4 y | 24 min | NEW · refrigerated_air_conditioning | — |
| 2682 (2657–2707) | Steel sheet piles drive quick cofferdams | 3 y | 18 min | NEW · steel_sheet_pile_cofferdams | — |
| 2690 (2665–2715) | Reinforced concrete arch and beam bridges (continues: reinforced_concrete; shared: logistics) | 4 y | 24 min | NEW · reinforced_concrete_bridges | — |

## Years 2700–3000 (≈ AD 1912–2030)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2704 (2679–2729) | Sewage cleaned by aerated sludge before release (continues: intercepting_sewers; shared: health, ecology) | 5 y | 30 min | NEW · activated_sludge_treatment | — |
| 2709 (2684–2734) | Zoning ordinances separate homes, works and shops [gov: towns] | 4 y | 24 min | NEW · zoning_ordinances | — |
| **2715 (2680–2750)** | **Concrete gravity and arch dams store whole valleys (continues: hydroelectric_stations; shared: ecology)** | 10 y | 61 min | NEW · concrete_arch_dams | — |
| 2720 (2695–2745) | Footings sized from tested soil bearing | 3 y | 18 min | shallow_foundation_assessment | not seen |
| 2721 (2696–2746) | Automatic regulators charge station batteries (continues: battery_bank_wiring) | 3 y | 18 min | charge_regulation | not seen |
| **2725 (2690–2760)** | **Towns build rented housing estates for working families [gov: towns, offices]** | 6 y | 37 min | NEW · public_housing_estates | — |
| 2728 (2703–2753) | Concrete proportioned by its water-cement ratio and tested in cubes (continues: concrete_mix_design) | 5 y | 30 min | NEW · water_cement_ratio_design | — |
| 2740 (2715–2765) | Thin concrete shells roof great halls and hangars | 4 y | 24 min | NEW · thin_concrete_shell_roofs | — |
| **2745 (2710–2780)** | **Power lines carried to every village and farm [gov: offices]** | 8 y | 49 min | NEW · rural_electrification | — |
| 2746 (2721–2771) | Buried pipes designed for soil and traffic loads | 3 y | 18 min | buried_pipe_load_assessment | not seen |
| 2748 (2723–2773) | Foundation settlement measured over years | 3 y | 18 min | foundation_settlement_monitoring | not seen |
| **2752 (2717–2787)** | **A river-basin authority builds a chain of dams, locks and power stations (continues: concrete_arch_dams) [gov: offices]** | 6 y | 37 min | NEW · river_basin_works | — |
| **2765 (2730–2800)** | **Prestressed concrete: tendons tensioned before loading (continues: reinforced_concrete)** | 6 y | 37 min | NEW · prestressed_concrete | — |
| 2770 (2745–2795) | Pumped-storage stations lift water at night and generate at the peak | 3 y | 18 min | NEW · pumped_storage_hydro | — |
| 2773 (2748–2798) | Tall buildings designed for measured wind loads | 3 y | 18 min | building_wind_load_assessment | not seen |
| 2774 (2749–2799) | Glued laminated timber beams and arches (shared: production) | 4 y | 24 min | engineered_wood_lamination | not seen |
| **2780 (2745–2815)** | **Controlled nuclear reactors with cooling and containment (shared: security, production)** | 12 y | 73 min | reactor_engineering | not seen |
| 2785 (2760–2810) | Fluorescent tubes light offices and works | 2 y | 12 min | NEW · fluorescent_lighting | — |
| 2790 (2765–2815) | Welded steel frames replace riveting on site | 3 y | 18 min | NEW · welded_steel_frames | — |
| 2798 (2773–2823) | Climbing tower cranes lift frames floor by floor | 3 y | 18 min | NEW · climbing_tower_cranes | — |
| 2800 (2775–2825) | Damp-proof courses and capillary breaks in walls and slabs | 3 y | 18 min | building_capillary_breaks | not seen |
| 2801 (2776–2826) | Sewers and conduits tested for infiltration | 3 y | 18 min | conduit_infiltration_testing | not seen |
| 2802 (2777–2827) | Timber structures designed for moisture movement | 3 y | 18 min | timber_moisture_movement_design | not seen |
| 2803 (2778–2828) | Concrete cores and silos slip-formed without stopping | 3 y | 18 min | NEW · slipformed_concrete_cores | — |
| 2805 (2780–2830) | Glass curtain walls hung on the frame | 4 y | 24 min | curtain_wall_systems | 225 |
| **2812 (2777–2847)** | **Nuclear power stations feed the grid (continues: reactor_engineering) [gov: offices]** | 10 y | 61 min | NEW · nuclear_power_stations | — |
| 2815 (2790–2840) | Cable-stayed bridges hang decks straight from towers (shared: logistics) | 4 y | 24 min | NEW · cable_stayed_bridges | — |
| 2826 (2801–2851) | Rainscreen walls vented behind the cladding | 3 y | 18 min | rainscreen_wall_assemblies | not seen |
| 2830 (2805–2855) | Housing blocks assembled from factory-cast concrete panels [gov: towns] | 4 y | 24 min | NEW · precast_panel_housing | — |
| 2832 (2807–2857) | Desalination plants make fresh water from the sea (shared: health, ecology) | 5 y | 30 min | NEW · seawater_desalination | — |
| 2836 (2811–2861) | Rotary tunnel-boring machines cut whole bores (continues: tunnelling_shield) | 5 y | 30 min | NEW · tunnel_boring_machines | — |
| 2845 (2820–2870) | Direct-current links carry power under seas and between grids | 5 y | 30 min | NEW · direct_current_links | — |
| 2848 (2823–2873) | Framed-tube towers climb past a hundred storeys (continues: skeleton_frame_towers) | 5 y | 30 min | NEW · framed_tube_supertall | — |
| 2850 (2825–2875) | Cable-net and membrane roofs span stadiums | 3 y | 18 min | NEW · cable_net_membrane_roofs | — |
| 2855 (2830–2880) | Earthquake codes require ductile frames and tied walls [gov: towns] | 4 y | 24 min | NEW · ductile_seismic_codes | — |
| 2860 (2835–2885) | Buildings set on isolating bearings ride out earthquakes (continues: ductile_seismic_codes) | 4 y | 24 min | NEW · seismic_base_isolation | — |
| 2862 (2837–2887) | Sewage works strip nitrogen and phosphorus (continues: activated_sludge_treatment; shared: ecology) | 3 y | 18 min | NEW · nutrient_removal_treatment | — |
| 2870 (2845–2895) | Old sewers relined from inside without digging (continues: conduit_infiltration_testing) | 3 y | 18 min | NEW · trenchless_pipe_relining | — |
| **2875 (2840–2910)** | **Solar power plants of installed modules feed the grid (continues: module_encapsulation)** | 6 y | 37 min | photovoltaic_power | not seen |
| 2878 (2853–2903) | Wind farms of large turbines feed the grid | 5 y | 30 min | NEW · wind_turbine_farms | — |
| 2882 (2857–2907) | Movable storm-surge barriers close estuaries in floods (shared: ecology) | 5 y | 30 min | NEW · storm_surge_barriers | — |
| 2890 (2865–2915) | Computers run a building's heat, light and air | 3 y | 18 min | NEW · building_management_systems | — |
| 2895 (2870–2920) | Ramps, lifts and wide doors required in public buildings [gov: towns] | 3 y | 18 min | NEW · accessible_building_rules | — |
| 2900 (2875–2925) | Building energy codes and very low-energy houses [gov: towns] | 4 y | 24 min | NEW · low_energy_building_codes | — |
| 2905 (2880–2930) | Combined-cycle stations burn gas twice over | 4 y | 24 min | NEW · combined_cycle_stations | — |
| 2930 (2905–2955) | Water mains watched for leaks by acoustic sensors | 3 y | 18 min | NEW · acoustic_leak_detection | — |
| 2935 (2910–2960) | Planted and reflective roofs cool dense districts | 2 y | 12 min | NEW · green_cool_roofs | — |
| 2945 (2920–2970) | Smart meters and controls balance the grid minute by minute (shared: knowledge) | 4 y | 24 min | NEW · smart_grid_metering | — |
| 2955 (2930–2980) | Rooftop solar and home batteries on ordinary houses (continues: photovoltaic_power) | 3 y | 18 min | NEW · rooftop_solar_home_batteries | — |
| 2960 (2935–2985) | Offshore wind farms on fixed and floating foundations (continues: wind_turbine_farms) | 5 y | 30 min | NEW · offshore_wind_farms | — |
| 2962 (2937–2987) | Towers built of cross-laminated timber (continues: engineered_wood_lamination) | 4 y | 24 min | NEW · mass_timber_towers | — |
| **2968 (2933–3000)** | **Grid-scale battery plants store surplus power (continues: battery_bank_wiring)** | 6 y | 37 min | NEW · grid_scale_batteries | — |
| 2975 (2950–3000) | Sponge districts soak up cloudbursts in parks and permeable paving (shared: ecology) [gov: towns] | 4 y | 24 min | NEW · sponge_districts | — |
| 2980 (2955–3000) | Heat pumps and district heat networks replace fuel burning in homes (continues: radiator_central_heating) | 4 y | 24 min | NEW · heat_pump_district_networks | — |
| 2985 (2960–3000) | Houses printed in concrete by gantry machines | 3 y | 18 min | NEW · printed_concrete_houses | — |
| 2988 (2963–3000) | Old buildings retrofitted to near-zero energy [gov: towns] | 4 y | 24 min | NEW · near_zero_energy_retrofits | — |
| 2990 (2965–3000) | Cement burned with less carbon and the rest captured (continues: portland_cement_clinker) | 5 y | 30 min | NEW · low_carbon_cement | — |
| 2995 (2970–3000) | Small factory-built reactors sited near towns (continues: nuclear_power_stations) | 6 y | 37 min | NEW · small_modular_reactors | — |

## Pacing

| Years | 2400–2450 | 2450–2500 | 2500–2550 | 2550–2600 | 2600–2650 | 2650–2700 | 2700–2750 | 2750–2800 | 2800–2850 | 2850–2900 | 2900–2950 | 2950–3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Infrastructure advances | 4 | 8 | 9 | 10 | 13 | 8 | 11 | 9 | 13 | 10 | 5 | 10 |

The total is **110** advances: 52 in 2400–2700 and 58 in 2700–3000, with 25 catalog ids and 85 new items. 25 rows are key thresholds. One advance lands about every 5–6 years. The 2400–2450 band is thin because the 1800–2400 list already holds the fireproof mill, iron mains and S-trap closets at its end. The 2600–2650 band is the densest: electricity, steel frames and reinforced concrete arrive within one historical generation. Short items take 2–4 years; the long thresholds take 8–12 years (49–73 real minutes).

**Key thresholds:**
1. **Frames and materials:** iron roof trusses (2430) → **clinker cement (2464)** → **iron-and-glass halls (2533)** → rolled iron beams (2545) → **reinforced concrete (2627)** → **steel skeletons (2632)** → **skeleton-frame towers (2640)** → concrete practice and mix design (2668–2728) → thin shells (2740) → **prestressed concrete (2765)** → glulam (2774) → welded frames (2790) → curtain walls (2805) → framed tubes (2848) → mass timber (2962) → printed houses and low-carbon cement (2985–2990).
2. **Bridges and tunnels:** **chain suspension bridges (2455)** → **tunnelling shield (2467)** → brick viaducts (2495) → box girders (2530) → air caissons (2570) → rock-drill tunnels (2578) → **steel long-span bridges (2586)** → **wire-cable suspension bridges (2622)** → concrete bridges (2690) → cable-stayed bridges (2815) → tunnel-boring machines (2836).
3. **Water and sanitation:** steam waterworks (2418) → egg-shaped sewers (2505) → **intercepting sewers (2550)** → sewer rodding (2560) → water towers (2598) → mountain aqueducts (2650) → activated sludge (2704) → desalination (2832) → nutrient removal (2862) → trenchless relining (2870) → leak detection (2930) → sponge districts (2975). Filtration (`slow_sand_filtration`) and chlorination are Health's.
4. **Power system:** **gas-lit streets (2422)** → electric street lighting (2615) → **central power stations (2619)** → transformers (2628) → **alternating-current grids (2645)** → **hydroelectric stations (2655)** → **concrete dams (2715)** → **rural electrification (2745)** → **river-basin works (2752)** → pumped storage (2770) → **reactors (2780)** → **nuclear power stations (2812)** → direct-current links (2845) → **solar power plants (2875)** → wind farms (2878) → combined-cycle stations (2905) → smart grids (2945) → **grid batteries (2968)** → small modular reactors (2995).
5. **Houses and towns:** back-to-back terraces (2410) → market halls (2450) → model dwellings (2498) → radiators (2548) → **boulevard rebuilding (2558)** → building codes (2590) → piped bathrooms (2600) → utility ducts (2642) → air conditioning (2675) → zoning (2709) → **public housing estates (2725)** → precast panel blocks (2830) → seismic codes (2855) → accessible buildings (2895) → low-energy codes (2900) → heat-pump districts (2980) → near-zero retrofits (2988).
6. **Ownership of overlaps:** the machines that make power (generators, turbines, engines, solar cells and modules) are Production's; the stations, grids and storage built from them are here. `reactor_engineering` is shared with Security, whose bombs are its own. Railways, the underground railway, tramways, motorways and ports are Logistics'. Filtration, chlorination and health boards are Health's; `central_board_of_health` (2528) sets the drains policy that `intercepting_sewers` builds. Towns owning their water, gas and trams (`municipal_utilities`, 2600) and utility-rate commissions are Institutions'. Pollution from gasworks and sewage (`gasworks_river_waste` here, and the 1800–2400 list's `town_river_fish_kills`, 2388) is Ecology's. Household refrigerators and cold chains are Nutrition's and Logistics'; `mechanical_refrigeration` is placed here. Fire brigades are Security's.

**Government and civic life.** These discoveries should visibly change the court and the seat of rule:
- `gas_lit_streets` (2422) and `electric_street_lighting` (2615): the palace square and main streets are lit at night, and a lighting committee joins the town council.
- `intercepting_sewers` (2550) and `boulevard_reconstruction` (2558): the capital is rebuilt around the seat of rule. Broad avenues, public works bonds and a prefect of works replace the old quarters.
- `prefabricated_iron_glass_halls` (2533): the realm holds its exhibitions in a glass hall (Culture `great_realms_exhibition`, 2536).
- `building_codes` (2590), `zoning_ordinances` (2709) and `ductile_seismic_codes` (2855): town building inspectors and planning boards hold standing offices.
- `central_power_stations` (2619), `rural_electrification` (2745) and `nuclear_power_stations` (2812): power becomes a public utility with a ministry or board, and the grid reaches every village.
- `skeleton_frame_towers` (2640): ministries and companies move into tall office towers beside the old palace.
- `public_housing_estates` (2725) and `precast_panel_housing` (2830): towns become landlords to working families.
- `river_basin_works` (2752): a standing authority governs a whole river valley.
- `low_energy_building_codes` (2900) and `near_zero_energy_retrofits` (2988): energy rules reach every house.

## Currently far too early / too late (infrastructure, main)

| Item | Seen | Belongs |
|---|---|---|
| structural_steel / reinforced_concrete (catalog AD 1885) | 219 / 221 | 2632 / 2627 |
| curtain_wall_systems (catalog AD 1950) | 224 | 2805 |
| safety_lifts (catalog AD 1852) / mechanical_refrigeration (AD 1851) | 229 / 231 | 2539 / 2536 |
| portland_cement_clinker (catalog AD 1824) | not seen | 2464 |
| reactor_engineering (catalog AD 1942; `joint_force_knowledge.gd`) | not seen | 2780. Placed here as the power reactor; its weapons use is Security's. |
| concrete_mix_design / concrete_formwork_systems (catalog AD 1747) | not seen | Placed by the 1800–2400 list as hydraulic lime concrete (2314) and shuttering (2366). The modern water–cement ratio is placed here as `water_cement_ratio_design` (2728). |
| pressure_pipe_jointing (catalog AD 1800) | not seen | Placed by the 1800–2400 list at 2396. Not relisted. |
| directional_air_valves / pneumatic_cylinders / pneumatic_pressing / packed_piston_seals (catalog direction Infrastructure) | not seen | Placed by Production (2620–2694) as machine parts. |
| Gas street lighting, clinker-burned cement, suspension bridges (1800–2400 belongs-later) | — | Placed here at 2422, 2464 and 2455. The iron-railed road is Logistics'. |
