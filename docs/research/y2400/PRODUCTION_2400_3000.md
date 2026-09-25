# Production: years 2400–3000

**Scope.** The game's **Production** research line covers making things: engines and prime movers, iron and steel, machine tools and fasteners, industrial chemistry, glass, textiles and garments, electrical machines and cells, plastics, semiconductors and the automated factory. This list continues `docs/research/y1800/PRODUCTION_1800_2400.md`, which ends with the separate-condenser and rotative engines, puddling, the spinning mule, salt-cake soda and riveted boilers. Names describe generic practices. Real history is used only to calibrate timing. Most of the game's modern catalog has catalog direction `Materials`, so this list is long by necessity: it places **every** `Materials` catalog id whose `HISTORICAL_YEAR` falls in AD 1800–2030 and that no other line has placed (except `cylinder_press_printing`; see the last table), including the computing hardware in `digital_logic_knowledge.gd` and `computing_memory_knowledge.gd` that Knowledge's 2400–3000 list leaves here. Engines and machines are Production's. Power stations, grids, dams and building services are Infrastructure's. Vehicles, ships and aircraft in service are Logistics' and Security's; the rows that make their engines and airframes are marked (shared: logistics, security).

**Historical anchor.** `CURVE` in `scripts/technology_eras.gd` (`[[2400,1800],[2800,1950],[3000,2030]]`, read from `origin/codex/research-600`) maps game 2400 ≈ AD 1800, 2500 ≈ 1838, 2600 ≈ 1875, 2700 ≈ 1912, 2800 ≈ 1950, 2900 ≈ 1990 and 3000 ≈ 2030. One game year is about 0.375 historical years before 2800 and 0.4 after, so a decade of real invention spreads over about 25 game years. Catalog years are often round placeholders (AD 1870, 1900, 1955, 1960). Their items are spread across the surrounding band in working order instead of landing together. The calibration sources run in order:
- **Power:** high-pressure engines (2410) → generators and motors (2483–2492) → compound engines (2540) → gas engine (2605) → steam turbine (2624) → alternating-current motors (2635) → heavy-oil engine (2652) → jet engine (2771)
- **Iron and steel:** hot blast (2475) → converter steel (2550) → open hearth (2573) → electric arc (2670) → stainless (2705) → continuous casting (2800) → oxygen steelmaking (2805) → minimills (2860) → hydrogen-reduced iron (2990)
- **Machine shop:** interchangeable parts (2424) → scraped and lapped planes (2478–2507) → lathe fittings (2545–2555) → the 1870 machine-shop set (2567–2604) → grinding (2606–2608) → toolroom and gauge blocks (2673–2676) → carbide tools (2730) → numerical control (2826) → flexible cells (2870) → additive manufacturing (2885)
- **Chemistry and materials:** coal gas (2420) → vulcanized rubber (2508) → coal-tar dyes (2554) → rock-oil refining (2557) → celluloid (2587) → aluminium (2630) → contact acid (2655) → phenolic resin (2698) → ammonia (2708) → the polymer families (2740–2836) → plant-based plastics and chemical recycling (2930–2965)
- **Electronics:** relays (2494) → relay logic (2641) → relay registers (2765–2769) → junction transistors (2803) → integrated circuits (2825) → single-chip processors (2853) → extreme-ultraviolet lithography (2972)

**Research time.** Times are game years of work by a staffed Production team. Real minutes are for **1 day/s** (speed setting 4): 1 game year takes about 6 real minutes, and 10 game years take about 1 hour. Because the catalog packs so many small machine-shop, fastener and polymer steps into this window, those steps take only 1–3 years (6–18 real minutes). The long thresholds take 8–12 years.

**Id column.** A plain id is in the main catalog today (`scripts/*.gd`); its catalog year is in `HISTORICAL_YEAR`. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `y600/registry_1200.json` (600–1200), `y1200/registry_1800.json` (1200–1800), a quoted id in `scripts/*.gd`, or any id in the 1800–2400 lists and the other 2400–3000 lists. "(continues: id)" names the earlier registry item, a row in a 1800–2400 list, a row in another 2400–3000 line, or a row in this list that the row improves.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run. It is `—` when the item is not in main.

## Years 2400–2700 (≈ AD 1800–1912)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2408 (2373–2443)** | **Chains of punched cards pick the pattern threads on the loom (continues: drawloom_pattern_control)** | 8 y | 49 min | punched_card_loom_control | not seen |
| **2410 (2375–2445)** | **High-pressure steam engines small enough to drive any mill or pump (continues: double_acting_engine, pressure_vessels)** | 10 y | 61 min | NEW · high_pressure_steam_engines | — |
| 2413 (2388–2438) | Paper formed as an endless web on a moving wire screen (continues: wove_paper_moulds; shared: knowledge) | 6 y | 37 min | NEW · continuous_paper_machine | — |
| 2416 (2391–2441) | Ship pulley blocks made on a line of single-purpose machines (shared: labor) | 5 y | 30 min | NEW · machine_block_line | — |
| 2420 (2395–2445) | Coal gas distilled in iron retorts and stored in gasholders (shared: infrastructure) | 5 y | 30 min | NEW · coal_gas_works | — |
| **2424 (2389–2459)** | **Parts made to gauges so that any one fits any machine (continues: jig_filed_gunlocks, precision_machinery)** | 8 y | 49 min | interchangeable_component_fits | not seen |
| 2440 (2415–2465) | Iron power looms fill steam-driven weaving sheds (continues: belt_power_transmission) | 6 y | 37 min | NEW · iron_power_loom_sheds | — |
| 2452 (2427–2477) | Steam engines drive paddle and screw hulls (continues: high_pressure_steam_engines; shared: logistics, security) | 3 y | 18 min | steam_propulsion | 228 |
| 2464 (2439–2489) | Friction matches struck on any rough surface | 3 y | 18 min | NEW · friction_matches | — |
| 2467 (2442–2492) | Glass tableware pressed in iron moulds by a plunger | 2 y | 12 min | plunger_pressed_glass | 140 |
| 2472 (2447–2497) | Ring spinning winds yarn continuously on a travelling ring | 3 y | 18 min | ring_spinning_systems | not seen |
| 2475 (2450–2500) | Heated blast halves the fuel of the iron furnace (continues: blast_furnace) | 6 y | 37 min | NEW · hot_blast_smelting | — |
| 2478 (2453–2503) | Three surface plates lapped against one another into true planes | 3 y | 18 min | three_plate_lapping | not seen |
| 2479 (2454–2504) | Clay-graphite crucibles stand many steel meltings | 2 y | 12 min | graphite_crucibles | 216 |
| 2480 (2455–2505) | Charcoal burned in closed iron retorts, saving the tars | 2 y | 12 min | charcoal_retorts | not seen |
| 2482 (2457–2507) | Wood spirit and acetic acid recovered from retort vapours | 2 y | 12 min | wood_methanol_recovery | not seen |
| **2483 (2448–2518)** | **Rotating magnets and coils make a steady current** | 8 y | 49 min | electrical_generators | 219 |
| 2484 (2459–2509) | Fractionating columns part mixed liquids by boiling point | 4 y | 24 min | fractional_distillation | 141 |
| 2485 (2460–2510) | Water split into hydrogen and oxygen by current | 3 y | 18 min | water_electrolysis | not seen |
| 2486 (2461–2511) | Gear teeth cut to a true rolling curve | 3 y | 18 min | gear_tooth_generation | not seen |
| 2488 (2463–2513) | Machine slides scraped straight against master straightedges | 2 y | 12 min | straightedge_scraping | not seen |
| 2491 (2466–2516) | Coal-tar benzene nitrated for dye and explosive feedstocks (shared: security) | 3 y | 18 min | aromatic_nitration | not seen |
| **2492 (2457–2527)** | **Electric motors turn current back into motion** | 8 y | 49 min | electric_motors | 229 |
| 2494 (2469–2519) | Relays let a weak current switch a strong one (shared: knowledge) | 3 y | 18 min | electromagnetic_relays | 210 |
| 2500 (2475–2525) | Silver, gold and nickel laid on base metal by current | 4 y | 24 min | NEW · electroplating | — |
| 2507 (2482–2532) | Lathe and planer ways scraped to bearing marks | 2 y | 12 min | machine_way_scraping | not seen |
| **2508 (2473–2543)** | **Rubber cured with sulphur and heat stays firm in heat and cold** | 8 y | 49 min | NEW · rubber_vulcanization | — |
| 2510 (2485–2535) | Steam hammers forge shafts and anchors with a controlled blow | 5 y | 30 min | NEW · steam_hammer_forging | — |
| 2523 (2498–2548) | Lockstitch sewing machine with an eye-pointed needle (shared: labor) | 3 y | 18 min | sewing_machine_mechanisms | not seen |
| 2525 (2500–2550) | Wire sheathed in gutta-percha and rubber for cables (shared: knowledge) | 3 y | 18 min | cable_insulation | 234 |
| 2530 (2505–2555) | Leather split and skived to an even thickness by machine | 2 y | 12 min | leather_thickness_skiving | not seen |
| 2533 (2508–2558) | Light oils and benzene recovered from coal tar (continues: coal_tar_pitch) | 2 y | 12 min | coal_light_oil_recovery | not seen |
| 2535 (2510–2560) | Split cotter pins bent from half-round wire | 1 y | 6 min | cotter_pin_forming | not seen |
| 2537 (2512–2562) | Rivet blanks headed cold in dies | 2 y | 12 min | rivet_blank_heading | not seen |
| 2540 (2515–2565) | Compound mill engines expand steam twice for less coal (continues: high_pressure_steam_engines; shared: logistics) | 4 y | 24 min | NEW · compound_steam_engines | — |
| 2545 (2520–2570) | Cross-slides feed the lathe tool square to the work | 2 y | 12 min | cross_slide_assembly | not seen |
| 2547 (2522–2572) | Tailstocks with screw-fed centres on standard lathes | 1 y | 6 min | tailstock_fitting | not seen |
| 2548 (2523–2573) | Engraving on hardened steel plates for long print runs (shared: knowledge) | 2 y | 12 min | steelplate_engraving | not seen |
| 2549 (2524–2574) | Master lead screws cut and corrected for screw-cutting lathes | 2 y | 12 min | lead_screw_cutting | not seen |
| **2550 (2515–2585)** | **Air blown through molten iron makes cheap steel in minutes (continues: steel_refining)** | 10 y | 61 min | NEW · pneumatic_steel_converter | — |
| 2551 (2526–2576) | Split nuts engage and release the lead screw | 1 y | 6 min | split_feed_nuts | not seen |
| 2552 (2527–2577) | Four-jaw chucks grip irregular work on the lathe | 1 y | 6 min | four_jaw_chucks | not seen |
| **2554 (2519–2589)** | **The first coal-tar dye founds a chemical dye trade (continues: aromatic_nitration)** | 6 y | 37 min | NEW · coal_tar_dyes | — |
| 2555 (2530–2580) | Thread pitch checked with standard gauges | 2 y | 12 min | thread_pitch_gauging | not seen |
| 2556 (2531–2581) | Litharge and red lead made in controlled furnaces | 1 y | 6 min | lead_oxide_preparation | not seen |
| **2557 (2522–2592)** | **Rock oil distilled into lamp oil and fuels** | 8 y | 49 min | fuel_refining | 224 |
| 2558 (2533–2583) | Fuel and furnace gases analysed by absorption | 2 y | 12 min | gas_composition_analysis | not seen |
| 2560 (2535–2585) | Washers punched from sheet in one stroke | 1 y | 6 min | washer_punching | not seen |
| 2561 (2536–2586) | Grinding wheels graded by grit and bond | 2 y | 12 min | abrasive_grinding_control | not seen |
| 2562 (2537–2587) | Tinplate coated evenly by rolling through molten tin | 2 y | 12 min | tinplate_coating | not seen |
| 2563 (2538–2588) | Wood and peat turned into producer gas in closed generators | 2 y | 12 min | biomass_gasification | not seen |
| 2564 (2539–2589) | Screw-fed milling tables advance the work steadily | 2 y | 12 min | milling_table_feeds | not seen |
| 2565 (2540–2590) | Paper pulped from ground and chemically cooked wood (continues: continuous_paper_machine) | 4 y | 24 min | NEW · wood_pulp_paper | — |
| 2566 (2541–2591) | Sheet steel rolled thin and even in powered mills | 3 y | 18 min | sheet_steel_rolling | not seen |
| 2567 (2542–2592) | Twist drills milled with helical flutes | 2 y | 12 min | drill_bit_fluting | not seen |
| 2570 (2545–2595) | Horizontal milling machines with an arbor and table | 2 y | 12 min | horizontal_milling_machines | not seen |
| **2573 (2538–2608)** | **Regenerative open hearth makes steel from pig and scrap (continues: pneumatic_steel_converter)** | 8 y | 49 min | NEW · open_hearth_steel | — |
| 2575 (2550–2600) | Screw bench vices hold work at the fitter's bench | 2 y | 12 min | bench_vise_screws | not seen |
| 2577 (2552–2602) | Soda ash made cleanly by the ammonia process (continues: salt_cake_soda) | 4 y | 24 min | NEW · ammonia_soda_process | — |
| 2580 (2555–2605) | Standard centre lathes assembled from matched parts | 3 y | 18 min | centre_lathe_assembly | not seen |
| 2581 (2556–2606) | Steel wire drawn through hard dies for cable and springs | 2 y | 12 min | steel_wire_drawing | not seen |
| 2582 (2557–2607) | Nut bores drilled true to the thread size | 2 y | 12 min | nut_bore_drilling | not seen |
| 2583 (2558–2608) | Column drilling machines with powered feed | 2 y | 12 min | column_drilling_machines | not seen |
| 2585 (2560–2610) | Screw threads cut with split dies | 1 y | 6 min | thread_die_cutting | not seen |
| 2586 (2561–2611) | Taps made to cut internal threads | 1 y | 6 min | thread_tap_cutting | not seen |
| 2587 (2562–2612) | Celluloid: the first plastic, moulded from treated cotton and camphor | 4 y | 24 min | NEW · celluloid_moulding | — |
| 2588 (2563–2613) | External threads cut to standard forms on the lathe | 1 y | 6 min | external_thread_cutting | not seen |
| 2589 (2564–2614) | Holes tapped to standard threads | 1 y | 6 min | internal_thread_tapping | not seen |
| 2590 (2565–2615) | Milling cutters backed off so they can be resharpened | 2 y | 12 min | milling_cutter_relief | not seen |
| 2591 (2566–2616) | Worm dividing heads index gears and flutes | 2 y | 12 min | worm_dividing_heads | not seen |
| 2592 (2567–2617) | Mated threads inspected with go and no-go gauges | 1 y | 6 min | matched_thread_inspection | not seen |
| 2593 (2568–2618) | Geared spindle heads on milling machines | 2 y | 12 min | milling_spindle_heads | not seen |
| 2594 (2569–2619) | Bores reamed to a fitted size | 1 y | 6 min | reamed_bore_finishing | not seen |
| **2595 (2560–2630)** | **The machine shop: lathes, drills and benches set out as one working plant** | 8 y | 49 min | basic_machine_shops | not seen |
| 2596 (2571–2621) | Slotting machines cut keyways and internal profiles | 2 y | 12 min | reciprocating_profile_slotting | not seen |
| 2597 (2572–2622) | Coil springs hardened and tempered to a set load | 2 y | 12 min | coil_spring_tempering | not seen |
| 2598 (2573–2623) | Broaches cut a profile in one pass of stepped teeth | 2 y | 12 min | progressive_profile_broaching | not seen |
| 2599 (2574–2624) | Spring wire coiled on powered arbors | 1 y | 6 min | spring_wire_coiling | not seen |
| 2600 (2575–2625) | Tool bits hardened and tempered to a standard | 2 y | 12 min | toolbit_heat_treatment | not seen |
| 2601 (2576–2626) | Quill feeds advance the drill spindle | 2 y | 12 min | quill_feed_mechanisms | not seen |
| 2602 (2577–2627) | Sheet metal spun over formers on the lathe | 2 y | 12 min | metal_spinning_forming | not seen |
| 2604 (2579–2629) | Glass batches weighed to a set composition | 2 y | 12 min | glass_batch_composition_control | not seen |
| **2605 (2570–2640)** | **Gas engine: fuel burned inside the cylinder on a four-stroke cycle (shared: logistics, security)** | 10 y | 61 min | internal_combustion | 234 |
| 2606 (2581–2631) | Cylindrical grinding to fitted sizes | 2 y | 12 min | cylindrical_grinding | not seen |
| 2608 (2583–2633) | Surface grinding of hardened flat parts | 2 y | 12 min | surface_grinding | not seen |
| 2610 (2585–2635) | Glass tubing drawn continuously to size | 2 y | 12 min | glass_tube_drawing | 144 |
| 2612 (2587–2637) | Carbon-filament lamps blown, pumped and sealed in lamp works (shared: infrastructure) | 5 y | 30 min | NEW · filament_lamp_works | — |
| 2613 (2588–2638) | Roller chains carry power between sprockets | 2 y | 12 min | chain_power_transmission | not seen |
| 2614 (2589–2639) | Shafts aligned by line, level and dial | 1 y | 6 min | shaft_alignment_methods | not seen |
| 2615 (2590–2640) | Sheet rolled into channels and sections | 2 y | 12 min | roll_formed_sections | not seen |
| 2616 (2591–2641) | Ball and roller bearings ground to size | 4 y | 24 min | rolling_element_bearings | not seen |
| 2620 (2595–2645) | Packed glands seal piston rods (shared: infrastructure) | 1 y | 6 min | packed_piston_seals | not seen |
| 2621 (2596–2646) | Oil-film bearings carry heavy shafts | 2 y | 12 min | fluid_film_bearings | not seen |
| 2622 (2597–2647) | Rechargeable lead-acid cells | 3 y | 18 min | lead_acid_cells | not seen |
| **2624 (2589–2659)** | **Steam turbines spin generators at high speed (continues: electrical_generators)** | 8 y | 49 min | NEW · steam_turbines | — |
| 2627 (2602–2652) | Sheet joined by resistance welding | 2 y | 12 min | resistance_welding | not seen |
| 2628 (2603–2653) | Snap fasteners pressed onto garments | 1 y | 6 min | snap_fastener_closures | not seen |
| **2630 (2595–2665)** | **Aluminium won from molten salts by electric current** | 8 y | 49 min | aluminum_electrolysis | not seen |
| 2632 (2607–2657) | Alumina refined from bauxite in caustic liquor | 3 y | 18 min | alumina_refining | not seen |
| 2635 (2610–2660) | Rotating-field motors run on alternating current (continues: electric_motors) | 5 y | 30 min | NEW · induction_motors | — |
| 2638 (2613–2663) | Cutting fluids cool and wash the tool | 1 y | 6 min | cutting_fluid_management | not seen |
| 2640 (2615–2665) | Arc welding with carbon and metal electrodes | 3 y | 18 min | arc_welding_processes | not seen |
| 2641 (2616–2666) | Relay contacts wired to do logic (shared: knowledge) | 3 y | 18 min | relay_logic | 211 |
| 2645 (2620–2670) | Brine split by current into chlorine and caustic soda | 4 y | 24 min | chloralkali_cells | 220 |
| 2647 (2622–2672) | Hydrochloric acid made by burning hydrogen in chlorine | 2 y | 12 min | hydrogen_chloride_synthesis | 221 |
| 2650 (2625–2675) | Artificial silk spun from dissolved wood cellulose | 5 y | 30 min | NEW · regenerated_cellulose_fibre | — |
| 2652 (2627–2677) | Compression-ignition engines burn heavy oil (continues: internal_combustion) | 5 y | 30 min | NEW · compression_ignition_engines | — |
| **2655 (2620–2690)** | **Sulphuric acid made on a catalyst by the contact process** | 6 y | 37 min | sulfuric_acid_production | not seen |
| 2656 (2631–2681) | Sulphur dioxide recovered from smelter gases | 2 y | 12 min | sulfur_dioxide_recovery | not seen |
| 2658 (2633–2683) | Gears cut continuously by hobbing | 2 y | 12 min | gear_hobbing | not seen |
| 2659 (2634–2684) | Carbon resistors for measured circuits | 2 y | 12 min | carbon_resistors | 203 |
| 2660 (2635–2685) | Enzymes put to work as catalysts in brewing and chemistry (shared: nutrition) | 3 y | 18 min | enzyme_catalysis | not seen |
| 2661 (2636–2686) | Gears generated by a reciprocating shaper cutter | 2 y | 12 min | gear_shaping_generation | not seen |
| 2662 (2637–2687) | Hot rivets set by pneumatic hammer | 1 y | 6 min | hot_rivet_setting | not seen |
| 2663 (2638–2688) | Nickel refined from sulphide ores | 2 y | 12 min | nickel_metal_recovery | not seen |
| 2664 (2639–2689) | Rivet holes drifted and reamed in line | 1 y | 6 min | rivet_hole_alignment | not seen |
| 2665 (2640–2690) | Small rivets set cold by press | 1 y | 6 min | cold_rivet_setting | not seen |
| 2666 (2641–2691) | Glass annealed on timed cooling schedules | 2 y | 12 min | glass_annealing_schedules | not seen |
| 2667 (2642–2692) | High-speed tool steel cuts red-hot without softening (continues: toolbit_heat_treatment) | 4 y | 24 min | NEW · high_speed_tool_steel | — |
| 2668 (2643–2693) | Bolt threads rolled instead of cut | 1 y | 6 min | bolt_thread_rolling | not seen |
| 2669 (2644–2694) | Glass worked in hydrogen and oxygen flames | 2 y | 12 min | hydrogen_flame_glassworking | 146 |
| **2670 (2635–2705)** | **Electric arc furnaces melt steel and alloys** | 8 y | 49 min | electric_arc_furnaces | 225 |
| 2671 (2646–2696) | Porous separators part battery plates | 2 y | 12 min | porous_battery_separators | not seen |
| 2672 (2647–2697) | Abrasive belts finish curved parts | 2 y | 12 min | abrasive_belt_finishing | not seen |
| 2673 (2648–2698) | Gauge blocks lapped flat enough to wring together | 2 y | 12 min | gauge_block_lapping | not seen |
| 2674 (2649–2699) | Drill jigs laid out from datum faces | 1 y | 6 min | drill_jig_layout | not seen |
| 2675 (2650–2700) | Hardened bushings guide the drill in the jig | 1 y | 6 min | drill_jig_bushings | not seen |
| **2676 (2641–2711)** | **Powered, controlled flight in a heavier-than-air craft (shared: logistics, security)** | 10 y | 61 min | powered_flight | not seen |
| **2676 (2641–2711)** | **Toolrooms make the jigs, gauges and fixtures for repeat work** | 6 y | 37 min | precision_toolrooms | not seen |
| 2677 (2652–2702) | Air liquefied and parted into oxygen and nitrogen | 4 y | 24 min | cryogenic_air_separation | not seen |
| 2678 (2653–2703) | Looms driven by their own electric motors | 2 y | 12 min | electric_power_looms | not seen |
| 2679 (2654–2704) | Pulp beaters driven by electric motors | 2 y | 12 min | electric_pulp_beating | 230 |
| 2680 (2655–2705) | Rolled foil capacitors | 2 y | 12 min | foil_capacitors | not seen |
| 2681 (2656–2706) | Castellated nuts slotted for locking pins | 1 y | 6 min | castellated_nut_slotting | not seen |
| 2682 (2657–2707) | Split pins lock nuts against vibration | 1 y | 6 min | split_pin_locking | not seen |
| 2683 (2658–2708) | Spring washers cut from coiled wire | 1 y | 6 min | split_washer_cutting | not seen |
| 2684 (2659–2709) | Metal grain size measured under the microscope | 2 y | 12 min | metal_grain_size_measurement | not seen |
| 2685 (2660–2710) | Furnace charges balanced by assay and weight | 2 y | 12 min | metallurgical_mass_balances | not seen |
| 2686 (2661–2711) | Resistance thermometers and strain sensors | 2 y | 12 min | resistive_sensing | 204 |
| 2687 (2662–2712) | Rods and tubes reduced by rotary swaging | 2 y | 12 min | rotary_swaging | not seen |
| 2688 (2663–2713) | Silicon smelted in the electric furnace | 2 y | 12 min | silicon_smelting | 230 |
| 2689 (2664–2714) | Steel normalised to refine its grain | 2 y | 12 min | steel_normalizing_control | not seen |
| 2690 (2665–2715) | Fasteners issued as counted assembly kits | 1 y | 6 min | standard_fastener_kitting | not seen |
| 2691 (2666–2716) | Hardened thread-rolling dies | 2 y | 12 min | thread_rolling_die_making | not seen |
| 2692 (2667–2717) | Air valves direct compressed air to actuators (shared: infrastructure) | 2 y | 12 min | directional_air_valves | not seen |
| 2693 (2668–2718) | Engine bores honed to a fine crosshatch | 2 y | 12 min | honed_bore_finishing | not seen |
| 2693 (2668–2718) | Pneumatic cylinders move tools and clamps (shared: infrastructure) | 2 y | 12 min | pneumatic_cylinders | not seen |
| 2694 (2669–2719) | Pneumatic presses form and assemble parts (shared: infrastructure) | 2 y | 12 min | pneumatic_pressing | not seen |
| 2695 (2670–2720) | Cloth tested for abrasion, strength and wear | 2 y | 12 min | textile_durability_testing | not seen |
| 2696 (2671–2721) | Powered washing machines for laundries and homes | 2 y | 12 min | mechanical_washing_machines | not seen |
| 2697 (2672–2722) | Formaldehyde made from wood spirit over a catalyst | 3 y | 18 min | formaldehyde_synthesis | not seen |
| **2698 (2663–2733)** | **Hard phenolic resin moulded under heat and pressure (continues: formaldehyde_synthesis)** | 5 y | 30 min | NEW · phenolic_resin_moulding | — |

## Years 2700–3000 (≈ AD 1912–2030)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2701 (2676–2726) | Aromatic amines made by hydrogenation | 3 y | 18 min | aromatic_amine_hydrogenation | not seen |
| 2703 (2678–2728) | Catalysts designed and tested for industrial reactions | 4 y | 24 min | industrial_catalyst_design | not seen |
| 2704 (2679–2729) | Promoted iron catalysts for ammonia | 3 y | 18 min | iron_ammonia_catalysts | not seen |
| 2705 (2680–2730) | Chromium steels that do not rust | 4 y | 24 min | NEW · stainless_steel | — |
| 2706 (2681–2731) | Alloy phase diagrams guide heat treatment | 3 y | 18 min | material_phase_diagrams | not seen |
| 2707 (2682–2732) | Weld metal and heat-affected zones understood | 2 y | 12 min | welding_metallurgy | not seen |
| **2708 (2673–2743)** | **Ammonia fixed from the air at high pressure (shared: nutrition, security)** | 12 y | 73 min | catalytic_ammonia_synthesis | not seen |
| 2710 (2685–2735) | Oil cracked by heat into lighter fuels and gases | 4 y | 24 min | hydrocarbon_steam_cracking | not seen |
| 2711 (2686–2736) | Interlocking slide fasteners | 2 y | 12 min | zipper_chain_closures | not seen |
| 2712 (2687–2737) | Pipes cast in spinning moulds | 2 y | 12 min | centrifugal_tube_casting | not seen |
| 2714 (2689–2739) | Centreless grinding of pins and rollers | 2 y | 12 min | centerless_grinding | not seen |
| 2720 (2695–2745) | Plastics and rubbers understood as long chain molecules | 4 y | 24 min | polymer_chain_models | not seen |
| 2722 (2697–2747) | Metals melted in vacuum for purity | 3 y | 18 min | vacuum_metal_melting | not seen |
| 2724 (2699–2749) | Garment patterns graded into standard sizes | 2 y | 12 min | garment_size_grading | not seen |
| 2728 (2703–2753) | Urea made in bulk from ammonia and carbon dioxide (continues: catalytic_ammonia_synthesis; shared: nutrition) | 3 y | 18 min | urea_synthesis | not seen |
| 2730 (2705–2755) | Cemented carbide tools cut hardened steel | 4 y | 24 min | NEW · cemented_carbide_tools | — |
| 2740 (2715–2765) | Monomers chained by free-radical polymerization | 3 y | 18 min | radical_chain_polymerization | not seen |
| 2742 (2717–2767) | Monomers purified for polymer plants | 2 y | 12 min | polymer_monomer_purification | not seen |
| 2744 (2719–2769) | Polymers built by step addition | 3 y | 18 min | additive_step_polymerization | not seen |
| 2746 (2721–2771) | Brazed joints qualified by test | 2 y | 12 min | brazed_joint_qualification | not seen |
| 2747 (2722–2772) | Polymers built by condensation, shedding water | 4 y | 24 min | condensative_step_polymerization | not seen |
| 2748 (2723–2773) | Polymers cast and spun from solution | 2 y | 12 min | polymer_solution_processing | not seen |
| 2749 (2724–2774) | Ethylene oxide made by direct oxidation | 3 y | 18 min | ethylene_oxide_synthesis | not seen |
| 2750 (2725–2775) | Hard metals shaped by electrochemical dissolution | 2 y | 12 min | electrochemical_machining | not seen |
| 2751 (2726–2776) | Residual stresses measured in parts | 2 y | 12 min | residual_stress_assessment | not seen |
| 2752 (2727–2777) | Glycol made from ethylene oxide and water (continues: ethylene_oxide_synthesis) | 2 y | 12 min | ethylene_glycol_hydrolysis | not seen |
| 2753 (2728–2778) | Bearing surfaces superfinished by short-stroke stones | 2 y | 12 min | short_stroke_superfinishing | not seen |
| 2755 (2730–2780) | Synthetic rubber from butadiene (shared: security) | 5 y | 30 min | NEW · synthetic_rubber | — |
| 2758 (2733–2783) | Surfaces hardened by induction heating | 2 y | 12 min | induction_surface_hardening | not seen |
| **2759 (2724–2794)** | **Thermoplastics melted and reshaped by machine** | 6 y | 37 min | thermoplastic_processing | not seen |
| 2760 (2735–2785) | Stressed-skin metal airframes (shared: logistics, security) | 6 y | 37 min | advanced_airframes | not seen |
| 2761 (2736–2786) | Plastics compounded with fillers and stabilisers | 2 y | 12 min | polymer_additive_formulation | not seen |
| 2762 (2737–2787) | Plastic film extruded and blown | 2 y | 12 min | polymer_film_extrusion | not seen |
| 2763 (2738–2788) | Plastics injection-moulded in steel dies | 3 y | 18 min | polymer_injection_molding | not seen |
| **2764 (2729–2799)** | **Synthetic fibre drawn from a polyamide melt (continues: condensative_step_polymerization)** | 8 y | 49 min | NEW · polyamide_synthetic_fibre | — |
| 2765 (2740–2790) | Binary adders built from relays (shared: knowledge) | 3 y | 18 min | binary_adders | 225 |
| 2766 (2741–2791) | Plastic melt flow measured and predicted | 2 y | 12 min | polymer_melt_rheology | not seen |
| 2767 (2742–2792) | Isocyanates for foams and coatings | 3 y | 18 min | isocyanate_synthesis | not seen |
| 2768 (2743–2793) | Hollow plastic ware blow-moulded | 2 y | 12 min | polymer_blow_molding | not seen |
| 2769 (2744–2794) | Relay registers hold binary numbers (shared: knowledge) | 2 y | 12 min | relay_registers | not seen |
| 2770 (2745–2795) | Catalytic cracking lifts fuel yield (continues: fuel_refining) | 5 y | 30 min | NEW · catalytic_cracking | — |
| **2771 (2736–2806)** | **Gas-turbine jet engines (shared: logistics, security)** | 10 y | 61 min | jet_propulsion | not seen |
| 2772 (2747–2797) | Cloth waterproofed with synthetic coatings | 2 y | 12 min | textile_waterproofing | not seen |
| 2773 (2748–2798) | Structural adhesives designed for joints | 2 y | 12 min | adhesive_bond_design | not seen |
| 2774 (2749–2799) | Ionic chain polymerization | 2 y | 12 min | ionic_chain_polymerization | not seen |
| 2775 (2750–2800) | Garment seams sealed against water | 2 y | 12 min | garment_seam_sealing | not seen |
| 2776 (2751–2801) | Foam cell size controlled in plastics | 2 y | 12 min | polymer_foam_cell_control | not seen |
| 2777 (2752–2802) | Polymer chain length controlled | 2 y | 12 min | polymer_molecular_weight_control | not seen |
| 2778 (2753–2803) | Reaction heat managed in polymer reactors | 2 y | 12 min | polymer_reaction_heat_management | not seen |
| 2779 (2754–2804) | Solvents recovered in polymer plants | 2 y | 12 min | polymer_solvent_recovery | not seen |
| 2781 (2756–2806) | Hard dies sunk by electric spark | 2 y | 12 min | sinker_electrical_discharge_machining | not seen |
| 2786 (2761–2811) | Single crystals pulled from the melt | 4 y | 24 min | single_crystal_growth | not seen |
| 2787 (2762–2812) | Silicon purified through chlorosilanes | 3 y | 18 min | chlorosilane_purification | 231 |
| 2788 (2763–2813) | Tubes bent on rotary draw benders | 2 y | 12 min | tube_rotary_draw_bending | not seen |
| 2790 (2765–2815) | Molecules identified by nuclear magnetic resonance (shared: knowledge) | 3 y | 18 min | nuclear_magnetic_resonance_spectroscopy | not seen |
| 2796 (2771–2821) | Brittle materials cut by ultrasonic abrasive | 2 y | 12 min | ultrasonic_abrasive_machining | not seen |
| 2798 (2773–2823) | Plastic sheet thermoformed | 2 y | 12 min | polymer_thermoforming | not seen |
| 2799 (2774–2824) | Fabrics engineered to move sweat | 2 y | 12 min | textile_moisture_transport | not seen |
| 2800 (2775–2825) | Steel cast continuously into slabs and billets | 4 y | 24 min | continuous_metal_casting | not seen |
| 2801 (2776–2826) | Machine-tool stiffness measured and improved | 2 y | 12 min | machine_tool_stiffness_assessment | not seen |
| 2802 (2777–2827) | Ring-opening polymerization | 2 y | 12 min | ring_opening_polymerization | not seen |
| **2803 (2768–2838)** | **Junction transistors made in quantity (shared: knowledge)** | 8 y | 49 min | bipolar_junction_transistors | not seen |
| 2804 (2779–2829) | Memory address decoding circuits (shared: knowledge) | 2 y | 12 min | memory_address_decoding | not seen |
| **2805 (2770–2840)** | **Pure oxygen blown onto molten iron makes steel in minutes (continues: open_hearth_steel)** | 8 y | 49 min | NEW · oxygen_steelmaking | — |
| 2806 (2781–2831) | Addressable read-write memory (shared: knowledge) | 3 y | 18 min | read_write_memory | not seen |
| 2807 (2782–2832) | Transistor amplifiers | 2 y | 12 min | transistor_amplifiers | not seen |
| 2808 (2783–2833) | Catalysts that order polymer chains | 3 y | 18 min | coordination_polymerization | not seen |
| 2810 (2785–2835) | Transistor inverters | 2 y | 12 min | transistor_inverters | not seen |
| 2811 (2786–2836) | Bistable circuits hold one bit | 2 y | 12 min | bistable_multivibrators | not seen |
| 2812 (2787–2837) | Binary counters | 2 y | 12 min | binary_counters | not seen |
| 2813 (2788–2838) | Parallel register banks | 2 y | 12 min | parallel_register_banks | not seen |
| 2814 (2789–2839) | Instruction registers | 2 y | 12 min | instruction_registers | not seen |
| 2815 (2790–2840) | Conditional branch circuits | 2 y | 12 min | conditional_branch_circuits | not seen |
| 2816 (2791–2841) | Program counters | 2 y | 12 min | program_counters | not seen |
| 2817 (2792–2842) | Shift registers | 2 y | 12 min | shift_registers | not seen |
| 2818 (2793–2843) | Thin metals joined by ultrasonic welding | 2 y | 12 min | ultrasonic_metal_joining | not seen |
| 2819 (2794–2844) | Polymer tacticity characterised | 2 y | 12 min | polymer_tacticity_characterization | not seen |
| 2820 (2795–2845) | Plastics tested against weather | 2 y | 12 min | polymer_weathering_trials | not seen |
| 2821 (2796–2846) | Polymers sorted by size-exclusion chromatography | 2 y | 12 min | size_exclusion_chromatography | not seen |
| 2822 (2797–2847) | Metal cast into lost-foam patterns | 2 y | 12 min | lost_foam_casting | not seen |
| 2823 (2798–2848) | Silicon rectifiers | 2 y | 12 min | silicon_rectifiers | not seen |
| 2824 (2799–2849) | Diode logic gates | 2 y | 12 min | diode_logic | not seen |
| **2825 (2790–2860)** | **Many transistors made together on one silicon chip (continues: bipolar_junction_transistors; shared: knowledge)** | 10 y | 61 min | NEW · integrated_circuits | — |
| **2826 (2791–2861)** | **Machine tools run from punched numerical instructions** | 8 y | 49 min | numerical_machine_control | not seen |
| 2827 (2802–2852) | Plate glass floated flat on molten tin | 3 y | 18 min | NEW · float_glass | — |
| 2828 (2803–2853) | Electronic machine control | 2 y | 12 min | electronic_machine_control | not seen |
| 2829 (2804–2854) | Hardwired sequence controllers | 2 y | 12 min | hardwired_sequence_control | not seen |
| 2830 (2805–2855) | Gear power skiving | 2 y | 12 min | gear_power_skiving | not seen |
| 2831 (2806–2856) | Machines monitored against a condition baseline | 2 y | 12 min | machine_condition_monitoring | not seen |
| 2832 (2807–2857) | Metal fracture toughness tested | 2 y | 12 min | metal_fracture_toughness_testing | not seen |
| 2833 (2808–2858) | Silicon solar cells fabricated (shared: infrastructure) | 3 y | 18 min | solar_cell_fabrication | not seen |
| **2834 (2799–2869)** | **Programmable robot arms weld and lift on the line (shared: labor)** | 6 y | 37 min | NEW · industrial_robots | — |
| 2835 (2810–2860) | Silicon ingots sawn into wafers | 2 y | 12 min | wafer_sawing | not seen |
| 2836 (2811–2861) | Copolymer sequences controlled | 2 y | 12 min | copolymer_sequence_control | not seen |
| 2838 (2813–2863) | Stored-program controllers run machines (shared: knowledge) | 6 y | 37 min | stored_program_control | not seen |
| 2840 (2815–2865) | Carbon fibre laid in resin: light, stiff composite parts | 5 y | 30 min | NEW · carbon_fibre_composites | — |
| 2842 (2817–2867) | Incremental sheet forming | 2 y | 12 min | incremental_sheet_forming | not seen |
| 2843 (2818–2868) | Open-end rotor spinning | 2 y | 12 min | rotor_spinning_systems | not seen |
| 2848 (2823–2873) | Wire spark cutting of hard dies | 2 y | 12 min | wire_electrical_discharge_machining | not seen |
| 2850 (2825–2875) | Abrasive waterjet cutting | 2 y | 12 min | abrasive_waterjet_cutting | not seen |
| **2853 (2818–2888)** | **A whole processor on one chip (continues: integrated_circuits; shared: knowledge)** | 8 y | 49 min | NEW · single_chip_processors | — |
| 2860 (2835–2885) | Scrap-fed minimills make steel near their buyers (continues: electric_arc_furnaces) | 3 y | 18 min | NEW · scrap_steel_minimills | — |
| 2865 (2840–2890) | Parts drawn and tested on screen before metal is cut (shared: knowledge) | 5 y | 30 min | NEW · computer_aided_design | — |
| 2870 (2845–2895) | Machining cells switch parts without retooling (continues: numerical_machine_control) | 4 y | 24 min | NEW · flexible_machining_cells | — |
| 2875 (2850–2900) | Solar cells sealed into weatherproof modules (shared: infrastructure) | 2 y | 12 min | module_encapsulation | not seen |
| 2880 (2855–2905) | Circuit boards assembled by pick-and-place machines | 3 y | 18 min | NEW · surface_mount_assembly | — |
| 2885 (2860–2910) | Parts built layer by layer from a digital model | 5 y | 30 min | NEW · additive_manufacturing | — |
| 2890 (2865–2915) | Statistical quality programs drive defects toward none per million | 3 y | 18 min | NEW · statistical_quality_programs | — |
| **2902 (2867–2937)** | **Rechargeable lithium-ion cells: much stored in little weight** | 6 y | 37 min | NEW · lithium_ion_cells | — |
| 2910 (2885–2935) | Flat liquid-crystal display panels made on glass sheets (shared: knowledge) | 4 y | 24 min | NEW · flat_panel_displays | — |
| 2915 (2890–2940) | Chip features printed smaller than the light's wavelength (continues: integrated_circuits) | 6 y | 37 min | NEW · deep_submicron_lithography | — |
| 2925 (2900–2950) | White light from semiconductor diodes (shared: infrastructure) | 4 y | 24 min | NEW · solid_state_lighting | — |
| 2930 (2905–2955) | Plastics broken back into monomers for reuse (shared: ecology) | 4 y | 24 min | selective_polymer_depolymerization | not seen |
| 2938 (2913–2963) | Cameras and software inspect every part on the line | 3 y | 18 min | NEW · machine_vision_inspection | — |
| 2945 (2920–2970) | Metal parts printed by fusing powder with lasers (continues: additive_manufacturing) | 4 y | 24 min | NEW · metal_powder_printing | — |
| 2950 (2925–2975) | Wide-bandgap power chips switch high voltage with little loss | 4 y | 24 min | NEW · wide_bandgap_power_chips | — |
| 2955 (2930–2980) | Light robots work beside people without cages (continues: industrial_robots; shared: labor) | 4 y | 24 min | NEW · collaborative_robots | — |
| 2965 (2940–2990) | Plastics made from plant sugars instead of oil | 3 y | 18 min | NEW · plant_based_plastics | — |
| 2970 (2945–2995) | Whole plants mirrored by live digital models (shared: knowledge) | 4 y | 24 min | NEW · digital_twin_plants | — |
| **2972 (2937–3000)** | **Chips patterned with extreme ultraviolet light (continues: deep_submicron_lithography)** | 8 y | 49 min | NEW · extreme_ultraviolet_lithography | — |
| 2978 (2953–3000) | Cobalt-free iron-phosphate battery cells (continues: lithium_ion_cells) | 3 y | 18 min | NEW · iron_phosphate_cells | — |
| 2982 (2957–3000) | Hydrogen split from water at scale with surplus clean power (continues: water_electrolysis) | 5 y | 30 min | NEW · green_hydrogen_electrolysis | — |
| 2985 (2960–3000) | Engineered microbes brew chemicals and materials in steel tanks (continues: enzyme_catalysis; shared: nutrition) | 4 y | 24 min | NEW · engineered_microbe_chemicals | — |
| **2990 (2955–3000)** | **Iron ore reduced with hydrogen instead of coke (continues: oxygen_steelmaking)** | 6 y | 37 min | NEW · hydrogen_reduced_iron | — |
| 2993 (2968–3000) | Layered tandem solar cells pass the silicon limit (continues: solar_cell_fabrication) | 5 y | 30 min | NEW · perovskite_tandem_cells | — |
| 2996 (2971–3000) | Solid-electrolyte battery cells leave the pilot line (continues: lithium_ion_cells) | 5 y | 30 min | NEW · solid_state_battery_cells | — |

## Pacing

| Years | 2400–2450 | 2450–2500 | 2500–2550 | 2550–2600 | 2600–2650 | 2650–2700 | 2700–2750 | 2750–2800 | 2800–2850 | 2850–2900 | 2900–2950 | 2950–3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Production advances | 7 | 17 | 15 | 39 | 27 | 47 | 23 | 35 | 41 | 9 | 7 | 11 |

The total is **278** advances: 152 in 2400–2700 and 126 in 2700–3000, with 220 catalog ids and 58 new items. 32 rows are key thresholds. This list is far longer than the 100–130 target because it must hold every `Materials` catalog id in the window. The catalog's lumped years create three crowded half-centuries: 2550–2600 (the 1856–1870 lathe and machine-shop set), 2650–2700 (the AD 1900 fastener, battery and furnace set) and 2800–2850 (the 1950–1960 transistor, register and polymer set). In those bands most rows are 1–3-year steps (6–18 real minutes) built on the same workshop base. After 2850 the catalog ends, and new items carry the line to 2030 at one advance about every 6 years.

**Key thresholds:**
1. **Engines:** **high-pressure engines (2410)** → steam hulls (`steam_propulsion`, 2452) → compound engines (2540) → **gas engine (`internal_combustion`, 2605)** → **steam turbines (2624)** → heavy-oil engines (2652) → **powered flight (2676)** → **jet engines (2771)**. Stationary engines before 2400 are the 1800–2400 list's (`double_acting_engine`, `pressure_vessels`).
2. **Iron and steel:** hot blast (2475) → steam hammer (2510) → **converter steel (2550, continues the crucible `steel_refining` of 2282)** → **open hearth (2573)** → **electric arc furnaces (2670)** → stainless steel (2705) → continuous casting (2800) → **oxygen steelmaking (2805)** → scrap minimills (2860) → **hydrogen-reduced iron (2990)**.
3. **Machine shop and precision:** **interchangeable fits (2424)** → surface plates and scraping (2478–2507) → lathe fittings and lead screws (2545–2555) → **the machine shop (2595)** → grinding (2606–2608) → rolling bearings (2616) → gear hobbing and shaping (2658–2661) → high-speed steel (2667) → **toolrooms (2676)** → carbide tools (2730) → **numerical control (2826)** → robots (2834) → flexible cells (2870) → additive manufacturing (2885) → collaborative robots (2955). `precision_machinery` is placed by the 1800–2400 Infrastructure list (2371).
4. **Chemistry:** coal gas (2420) → fractional distillation (2484) → **vulcanized rubber (2508)** → **coal-tar dyes (2554)** → **rock-oil refining (2557)** → ammonia soda (2577) → celluloid (2587) → **aluminium by electrolysis (2630)** → chlor-alkali (2645) → **contact acid (2655)** → **phenolic resin (2698)** → **ammonia synthesis (2708)** → urea (2728) → catalytic cracking (2770) → green hydrogen (2982) → engineered microbes (2985).
5. **Plastics and fibres:** power-loom sheds (2440) → ring spinning (2472) → sewing machines (2523) → artificial silk (2650) → **thermoplastics (2759)** → **polyamide fibre (2764)** → polymer control and testing (2773–2836) → rotor spinning (2843) → carbon fibre (2840) → plant-based plastics (2965) → chemical recycling (`selective_polymer_depolymerization`, 2930).
6. **Electricity and electronics:** **generators (2483)** → **motors (2492)** → relays (2494) → electroplating (2500) → lamp works (2612) → lead-acid cells (2622) → induction motors (2635) → relay logic (2641) → relay adders and registers (2765–2769) → **junction transistors (2803)** → counters and registers (2810–2817) → **integrated circuits (2825)** → **single-chip processors (2853)** → **lithium-ion cells (2902)** → sub-wavelength lithography (2915) → **extreme-ultraviolet lithography (2972)** → tandem solar cells and solid-state cells (2993–2996).
7. **Ownership of overlaps:** Knowledge owns the steam printing press (`steam_cylinder_press`, 2437), photography, telegraph, radio, `triode_valves`, `arithmetic_logic_units`, `microprogrammed_machine_control` and desk computers. The computing hardware with catalog direction `Materials` is placed here, as Knowledge's list asks. Infrastructure owns power stations, grids, `reactor_engineering`, `wound_transformers`, station batteries (`battery_bank_wiring`, `charge_regulation`), `mechanical_refrigeration` and `compressed_air_systems`. Logistics owns locomotives, ships, motor cars and airliners; it continues `steam_propulsion`, `internal_combustion` and `jet_propulsion` from here. Security owns explosives, armour and weapons of mass destruction. Nutrition owns fertilizer use, canning (`can_body_forming`) and farm machines; Production owns the plants that make ammonia, acid, tinplate and sheet steel. The factory workforce, assembly line and lean production are Labor's.

**Government and civic life.** These discoveries should visibly change the court and the seat of rule:
- `high_pressure_steam_engines` (2410) and `interchangeable_component_fits` (2424): engine and arms-works patents come before the council, and the state armoury buys by gauge.
- `coal_gas_works` (2420): the ruler's hall and the town streets are lit by gas (Infrastructure `gas_lit_streets`, 2422).
- `pneumatic_steel_converter` (2550) and `open_hearth_steel` (2573): steel works, rails and armour plate become matters of state.
- `electrical_generators` (2483) and `filament_lamp_works` (2612): the audience hall is lit electrically.
- `catalytic_ammonia_synthesis` (2708): the council sees that the same plant feeds fields and fills shells.
- `integrated_circuits` (2825) and `single_chip_processors` (2853): chip plants become strategic works that the court protects and subsidises.
- `hydrogen_reduced_iron` (2990) and `green_hydrogen_electrolysis` (2982): the council weighs clean-steel subsidies at the end of the game.

## Currently far too early / too late (production, main)

| Item | Seen | Belongs |
|---|---|---|
| electrical_generators / electric_motors (catalog AD 1831 / 1834) | 219 / 228 | 2483 / 2492. Recorded runs reach them about 2,250 game years early. |
| electric_arc_furnaces / silicon_smelting / chloralkali_cells / hydrogen_chloride_synthesis (catalog AD 1892–1900) | 224 / 230 / 220 / 221 | 2645–2688 |
| fuel_refining (catalog AD 1859) / internal_combustion (AD 1876) / steam_propulsion (AD 1824) | 223 / 233 / 227 | 2557 / 2605 / 2452 |
| binary_adders / relay_logic / electromagnetic_relays (catalog AD 1835–1937) | 225 / 210 / 209 | 2765 / 2641 / 2494 |
| chlorosilane_purification (catalog AD 1945) | 231 | 2787 |
| fractional_distillation / plunger_pressed_glass / glass_tube_drawing / hydrogen_flame_glassworking | 140 / 140 / 143 / 145 | 2484 / 2467 / 2610 / 2669 |
| carbon_resistors / resistive_sensing / graphite_crucibles / cable_insulation / electric_pulp_beating | 203 / 204 / 215 / 233 / 229 | 2659 / 2686 / 2479 / 2525 / 2679 |
| urea_synthesis (catalog AD 1828) | not seen | 2728. The catalog item is bulk urea from ammonia and carbon dioxide (AD 1922), which needs `catalytic_ammonia_synthesis`; the AD 1828 flask synthesis is a Knowledge curiosity. |
| ethylene_glycol_hydrolysis (catalog AD 1859) | not seen | 2752, after `ethylene_oxide_synthesis` (2749). Industrial glycol follows ethylene oxide. |
| aluminum_electrolysis / alumina_refining / lead_acid_cells / sulfuric_acid_production (catalog AD 1900) | not seen | 2630 / 2632 / 2622 / 2655. The practices date from AD 1859–1888, so the round catalog year is 25–40 game years late. |
| drill_bit_fluting / horizontal_milling_machines (catalog AD 1870) | not seen | 2567 / 2570 (AD 1861–1862) |
| cylinder_press_printing (catalog AD 1814) | not seen | Not relisted. Knowledge placed the same practice at 2437 as `steam_cylinder_press`. The registry merge should give that row the catalog id. |
| mechanical_clutches / metal_annealing_control / pressure_vessels / yarn_count_standards / nut_blank_forging (catalog AD 1800) | not seen / 117 | Placed by the 1800–2400 Production list (2386–2399; nut blanks 1886). Not relisted. |
| Power loom, paper machine, high-pressure engine, gas lighting (1800–2400 belongs-later) | — | Placed here at 2440, 2413, 2410 and 2420 (with Infrastructure's `gas_lit_streets`, 2422). |
