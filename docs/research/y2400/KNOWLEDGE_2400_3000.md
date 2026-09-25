# Knowledge: years 2400–3000

**Scope.** This file is the **Knowledge** line for game years 2400–3000 (`knowledge` dynamic; `direction: "Information"`). It has four channels: Observers, Directed attention, Preserved knowledge and Communication, and it continues `y1200/KNOWLEDGE_1200_1800.md` and the 1800–2400 Knowledge list. It covers the research university and industrial laboratory, schooling for every child, the steam press and photography, the sciences of electricity, heat, the atom, the cell and heredity, the microscope, the telegraph, telephone and radio, the mathematics of signals and information, semiconductors, programming, networks and learned machines up to the 2030 frontier. **Catalog ids placed here: 98.** They are every catalog id with `direction: "Information"` whose `HISTORICAL_YEAR` falls in AD 1800–2030 and that no earlier registry has placed, except `metal_type_casting`, which the 1200–1800 registry already placed ≈ 1875. No Information id was left `belongs_later` for this window by `registry_1800.json`. Computing hardware in `digital_logic_knowledge.gd` and `computing_memory_knowledge.gd` has catalog direction `Materials` and is left to Production. Items owned by other lines are left out: germ theory, vaccines, X-ray diagnosis and antibiotics (Health); the post, railways, spaceflight and navigation satellites (Logistics); the census bureau (Demography); weather forecasting and geology (Ecology); newspapers, broadcasting and film as media (Culture). Rows marked [gov: …] change government or civic life; see the tag legend in the Institutions file.

**Historical anchor.** The `CURVE` in `scripts/technology_eras.gd` (`[[2400,1800],[2800,1950],[3000,2030]]`) maps game 2400 to AD 1800, 2500 to ≈ 1838, 2600 to ≈ 1875, 2700 to ≈ 1912, 2800 to 1950, 2900 to ≈ 1990 and 3000 to 2030, the end of the game. Years 2400–2800 run at 0.375 historical years per game year: steam, railways and the telegraph, industrial chemistry, electricity, mass politics and the first world-scale industrial wars. Years 2800–3000 run at 0.4 historical years per game year: computing, nuclear power, spaceflight, networks and the information age, ending in the near future of 2030. Items near 3000 are plausible extensions of what exists by the mid-2020s, not science fiction. Names are generic alternative-history practices. Real places, people, companies, states, wars and religions are used only for calibration.

**Research time.** Time is given in game years while a staffed Knowledge team is working on the item. Real minutes are for **1 day/s** (speed setting 4). In real time, 1 game year is about 6 minutes, and 10 game years are about 1 hour. At 3 days/s, divide by 3. At 8 h/s, multiply by 3.

**Id column.** A plain id is in the main catalog today; its game year comes from `HISTORICAL_YEAR` through `CURVE` unless the last table gives a correction. `NEW` = not authored yet. No `NEW` slug repeats an id in `docs/research/registry.json` (0–600), `docs/research/y600/registry_1200.json` (600–1200), `docs/research/y1200/registry_1800.json` (1200–1800, merge aliases included) or `scripts/*.gd`. "(continues: id)" names an earlier item that a row improves, an earlier row of this file, or a row in another 2400–3000 line.

**"Today" column.** The earliest year seen in recorded headless campaigns (`docs/technology-review/pacing/*.json`). "not seen" means the catalog item never completed in a recorded run. It is `—` when the item is not in main.

## Years 2400–2700 (≈ AD 1800–1912)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| **2400 (2365–2435)** | **Stacked metal-and-brine cells give a steady current** | 10 y | 61 min | electrochemical_cells | 200 |
| 2400 (2375–2425) | Probable causes weighed from scattered observations (continues: probability_theory) | 6 y | 36 min | statistical_inference | not seen |
| 2408 (2383–2433) | Combining weights: each element built of its own kind of atom | 8 y | 49 min | NEW · atomic_combining_weights | — |
| 2413 (2388–2438) | State optical telegraph lines relay signals across the realm (continues: shutter_signal_frames) | 8 y | 49 min | optical_telegraphy | not seen |
| 2416 (2391–2441) | Least squares fit a line through scattered observations | 5 y | 30 min | least_squares_estimation | not seen |
| 2424 (2399–2449) | Precision gauges and standard bars for length | 6 y | 36 min | dimensional_metrology | not seen |
| 2424 (2399–2449) | Every measurement carries its stated error | 5 y | 30 min | measurement_uncertainty | 205 |
| **2427 (2392–2462)** | **Research university: seminars, laboratories and the research doctorate (continues: chartered_university)** | 15 y | 91 min | NEW · research_university | — |
| **2437 (2402–2472)** | **Steam-driven cylinder press prints thousands of sheets an hour (continues: screw_press_printing)** | 10 y | 61 min | cylinder_press_printing | not seen |
| 2453 (2428–2478) | Needle current meters measure current | 6 y | 36 min | electrical_measurement | 202 |
| 2459 (2434–2484) | Quantities checked by their units and dimensions | 5 y | 30 min | dimensional_analysis | 216 |
| 2459 (2434–2484) | Any wave split into a sum of simple waves | 8 y | 49 min | harmonic_analysis | not seen |
| 2459 (2434–2484) | Drag of thick fluids measured and reckoned | 6 y | 36 min | viscous_resistance | not seen |
| 2464 (2439–2489) | Ideal cycle limits the work a heat engine can yield | 8 y | 49 min | heat_engine_cycles | 226 |
| 2469 (2444–2494) | Work and energy given one measure | 6 y | 36 min | mechanical_work_energy | 157 |
| 2480 (2455–2505) | Colour-corrected compound microscope | 10 y | 61 min | compound_microscopy | not seen |
| 2480 (2455–2505) | Fine-focus stages for high magnification | 4 y | 24 min | fine_focus_stages | not seen |
| 2480 (2455–2505) | Condenser and aperture control of the light | 4 y | 24 min | illumination_apertures | not seen |
| 2480 (2455–2505) | Specimens mounted on glass slides under cover glass | 4 y | 24 min | specimen_slide_mounting | not seen |
| 2480 (2455–2505) | Tiny living things watched and drawn | 6 y | 36 min | microbial_observation | not seen |
| 2480 (2455–2505) | Cells seen in plant and animal tissue | 6 y | 36 min | microscopic_cell_observation | not seen |
| **2483 (2448–2518)** | **Moving magnets make current: induction** | 12 y | 73 min | electromagnetic_induction | 207 |
| 2493 (2468–2518) | Electromagnet sounders click out a distant signal | 6 y | 36 min | electromagnet_sounders | not seen |
| 2499 (2474–2524) | Dot-and-dash code: timed signal sequences | 5 y | 30 min | timed_signal_sequences | not seen |
| **2504 (2469–2539)** | **Electric telegraph wires run beside the railways** | 15 y | 91 min | electrical_telegraphy | not seen |
| **2504 (2469–2539)** | **Every living body is built of cells** | 10 y | 61 min | cell_theory | not seen |
| 2504 (2479–2529) | Tissues sorted by their cells: histology | 6 y | 36 min | tissue_histology | not seen |
| **2504 (2469–2539)** | **Light-fixed images on silvered plates** | 10 y | 61 min | NEW · fixed_light_images | — |
| 2517 (2492–2542) | Spring-loaded telegraph keys | 4 y | 24 min | telegraph_keys | not seen |
| 2523 (2498–2548) | Glass and porcelain line insulators | 4 y | 24 min | line_insulators | not seen |
| **2525 (2490–2560)** | **Energy is neither made nor lost, only changed** | 10 y | 61 min | NEW · energy_conservation_law | — |
| 2528 (2503–2553) | Earth return halves the telegraph wire | 4 y | 24 min | telegraph_return_circuits | not seen |
| 2533 (2508–2558) | Polarized relays repeat weak telegraph signals | 5 y | 30 min | polarized_telegraph_relays | not seen |
| 2533 (2508–2558) | Heat runs downhill: the second law and entropy | 8 y | 49 min | NEW · entropy_second_law | — |
| 2555 (2530–2580) | Arrays of numbers multiplied as one: matrix algebra | 6 y | 36 min | matrix_algebra | not seen |
| 2555 (2530–2580) | Dyes stain tissue to show its parts | 5 y | 30 min | biological_staining | not seen |
| 2557 (2532–2582) | Light split into lines names the elements, even in the stars | 8 y | 49 min | spectroscopy | not seen |
| **2557 (2522–2592)** | **Kinds change over ages by descent and selection** | 12 y | 73 min | NEW · descent_by_selection | — |
| 2560 (2535–2585) | Metal breaks under repeated small loads: fatigue | 6 y | 36 min | cyclic_fatigue | not seen |
| **2571 (2536–2606)** | **Light is an electric and magnetic wave** | 12 y | 73 min | electromagnetic_wave_theory | not seen |
| 2576 (2551–2601) | Undersea telegraph cable joins distant shores | 12 y | 73 min | NEW · undersea_telegraph_cable | — |
| **2584 (2549–2619)** | **Elements ordered in a periodic table with gaps foretold** | 10 y | 61 min | NEW · periodic_element_table | — |
| **2587 (2552–2622)** | **Free, compulsory elementary schooling for every child [gov: law]** | 15 y | 91 min | NEW · compulsory_elementary_schooling | — |
| 2587 (2562–2612) | Punched paper tape stores and sends messages | 5 y | 30 min | punched_message_tape | not seen |
| 2587 (2562–2612) | Cell division watched stage by stage | 6 y | 36 min | cell_division_observation | not seen |
| 2595 (2570–2620) | Light changes a metal's resistance | 5 y | 30 min | photoconductivity | not seen |
| 2597 (2572–2622) | Two messages share one wire both ways | 5 y | 30 min | duplex_telegraphy | not seen |
| 2600 (2575–2625) | Typewriter: a keyed machine prints letters on the page (continues: metal_type_casting; shared: labor) | 5 y | 30 min | NEW · typewriter | — |
| 2603 (2578–2628) | Vibrating diaphragms carry the voice | 4 y | 24 min | acoustic_diaphragms | not seen |
| 2603 (2578–2628) | Electromagnetic earpieces | 4 y | 24 min | electromagnetic_earpieces | not seen |
| 2603 (2578–2628) | Instruments sterilized by heat | 5 y | 30 min | instrument_sterilization | not seen |
| 2603 (2578–2628) | Single kinds of germ grown pure on plates | 8 y | 49 min | microbial_isolation_methods | not seen |
| 2603 (2578–2628) | Industrial research laboratory with salaried inventors | 8 y | 49 min | NEW · industrial_research_laboratory | — |
| 2603 (2578–2628) | Evacuated discharge tubes glow; cathode rays stream from the negative plate (continues: vacuum_pumps; shared: health) | 6 y | 36 min | NEW · cathode_ray_discharge_tubes | — |
| **2605 (2570–2640)** | **Telephone lines carry the voice** | 12 y | 73 min | telephone_circuits | not seen |
| 2608 (2583–2633) | Carbon microphones | 5 y | 30 min | carbon_microphones | not seen |
| 2608 (2583–2633) | Manual switchboards join any two subscribers | 6 y | 36 min | manual_switchboards | not seen |
| 2613 (2588–2638) | Aseptic laboratory practice | 6 y | 36 min | aseptic_laboratory_practice | not seen |
| 2613 (2588–2638) | Vector analysis for fields and forces | 6 y | 36 min | vector_analysis | 211 |
| 2616 (2591–2641) | Twisted balanced pairs quiet the line | 5 y | 30 min | balanced_conductor_pairs | not seen |
| 2621 (2596–2646) | Oil films between moving parts reckoned | 5 y | 30 min | lubrication_regimes | not seen |
| 2640 (2615–2665) | Punched-card tabulating machines count the census [gov: offices] | 10 y | 61 min | NEW · punched_card_tabulation | — |
| 2659 (2634–2684) | The electron: a charged particle smaller than any atom | 10 y | 61 min | electron_physics | not seen |
| 2659 (2634–2684) | Rays and radioactivity measured | 6 y | 36 min | radiation_measurement | not seen |
| 2659 (2634–2684) | Hot filaments give off charge in a vacuum | 6 y | 36 min | thermionic_emission | not seen |
| 2664 (2639–2689) | Loading coils carry speech further | 5 y | 30 min | inductive_line_loading | not seen |
| **2664 (2629–2699)** | **Wireless telegraphy across open sea** | 12 y | 73 min | radio_telegraphy | not seen |
| 2667 (2642–2692) | Radiant energy comes in quanta | 8 y | 49 min | NEW · energy_quanta | — |
| 2667 (2642–2692) | Lift and drag of wings reckoned | 8 y | 49 min | aerodynamics | not seen |
| 2667 (2642–2692) | Wind tunnel testing of models | 6 y | 36 min | wind_tunnel_testing | not seen |
| 2667 (2642–2692) | Specialist journals with referee review | 5 y | 30 min | NEW · refereed_journals | — |
| 2667 (2642–2692) | Resonant circuits tuned to one wavelength | 5 y | 30 min | resonant_tuned_circuits | not seen |
| 2667 (2642–2692) | Random samples stand for the whole | 6 y | 36 min | statistical_sampling | 185 |
| 2667 (2642–2692) | Growth of germ cultures counted | 5 y | 30 min | microbial_growth_measurement | not seen |
| 2667 (2642–2692) | Variable air capacitors | 4 y | 24 min | variable_air_capacitors | not seen |
| 2677 (2652–2702) | Crystal detectors hear radio | 5 y | 30 min | crystal_radio_detection | not seen |
| 2677 (2652–2702) | Vacuum diodes rectify signals | 5 y | 30 min | vacuum_diodes | not seen |
| 2680 (2655–2705) | Space and time joined; light speed the same for all | 12 y | 73 min | NEW · relative_spacetime | — |
| 2683 (2658–2708) | Automatic high-speed telegraph senders | 5 y | 30 min | automatic_telegraphy | not seen |
| 2683 (2658–2708) | Teleprinters type the message at both ends | 6 y | 36 min | teleprinter_mechanisms | not seen |
| **2683 (2648–2718)** | **Triode valves amplify weak signals** | 10 y | 61 min | triode_valves | not seen |
| 2685 (2660–2710) | Living cells grown outside the body | 6 y | 36 min | cell_culture_methods | not seen |
| 2688 (2663–2713) | Tuned radio receivers pick one station | 5 y | 30 min | tuned_radio_reception | not seen |
| 2696 (2671–2721) | Atom as a tiny nucleus with electrons around it | 10 y | 61 min | atomic_physics | not seen |
| 2699 (2674–2724) | Speech carried on a modulated radio wave | 6 y | 36 min | amplitude_modulation | not seen |
| 2699 (2674–2724) | Crystal lattices read by penetrating rays | 8 y | 49 min | crystallography | not seen |
| 2699 (2674–2724) | Feedback oscillators generate steady radio waves | 6 y | 36 min | feedback_radio_oscillators | not seen |

## Years 2700–3000 (≈ AD 1912–2030)

| Year (band) | Discovery | Research | Real time | Id | Today |
|---|---|---|---|---|---|
| 2707 (2682–2732) | Telephone repeaters span the continent | 6 y | 36 min | telephone_repeaters | not seen |
| 2715 (2690–2740) | Frequency conversion | 5 y | 30 min | frequency_conversion | not seen |
| 2720 (2695–2745) | Superheterodyne receivers | 6 y | 36 min | superheterodyne_reception | not seen |
| 2720 (2695–2745) | Aerials matched to transmitters | 5 y | 30 min | aerial_matching | not seen |
| 2723 (2698–2748) | Quartz crystals hold the frequency steady | 5 y | 30 min | frequency_stabilization | not seen |
| **2733 (2698–2768)** | **Wave mechanics of the atom** | 12 y | 73 min | NEW · quantum_mechanics | — |
| 2741 (2716–2766) | A signal is fixed by samples at twice its highest pitch | 6 y | 36 min | signal_sampling | not seen |
| 2744 (2719–2769) | Distant star systems recede: the universe is expanding (continues: spectroscopy, relative_spacetime) | 8 y | 49 min | NEW · expanding_universe_cosmology | — |
| 2747 (2722–2772) | Electronic band theory of solids | 8 y | 49 min | band_theory | not seen |
| 2747 (2722–2772) | Solid-state physics | 8 y | 49 min | solid_state_physics | not seen |
| 2755 (2730–2780) | Frequency modulation cuts static | 6 y | 36 min | frequency_modulation | not seen |
| **2763 (2728–2798)** | **Theory of computable procedures and the universal machine** | 10 y | 61 min | NEW · computability_theory | — |
| **2768 (2733–2803)** | **Heavy nuclei split and free more neutrons; reactors and bombs both follow** | 12 y | 73 min | nuclear_fission | not seen |
| 2768 (2743–2793) | Moderators slow neutrons to sustain a chain | 8 y | 49 min | neutron_moderation | not seen |
| 2773 (2748–2798) | Best choices under limits: constrained optimization | 6 y | 36 min | constrained_optimization | not seen |
| 2779 (2754–2804) | State-funded great laboratories for science [gov: offices] | 12 y | 73 min | NEW · state_great_laboratories | — |
| 2784 (2759–2809) | Secondary schooling for every child [gov: law] (continues: compulsory_elementary_schooling) | 10 y | 61 min | NEW · universal_secondary_schooling | — |
| **2795 (2760–2830)** | **Mathematical theory of information and channel capacity** | 10 y | 61 min | NEW · information_theory | — |
| **2796 (2761–2831)** | **Electronic computer holds its own program in memory (continues: computability_theory; shared: production)** | 10 y | 61 min | NEW · stored_program_computer | — |
| 2800 (2775–2825) | Living cells filmed in time lapse | 5 y | 30 min | live_cell_time_lapse | not seen |
| 2802 (2777–2827) | Traces of impurity set a crystal's conduction | 8 y | 49 min | semiconductor_doping | 228 |
| **2802 (2767–2837)** | **Junctions between doped layers switch and amplify** | 10 y | 61 min | pn_junctions | not seen |
| 2808 (2783–2833) | The hereditary molecule is a double helix | 10 y | 61 min | NEW · hereditary_double_helix | — |
| 2810 (2785–2835) | Sunlight turned directly into current | 6 y | 36 min | photovoltaic_conversion | not seen |
| 2812 (2787–2837) | Microinstructions sequence a machine's steps | 6 y | 36 min | microinstruction_sequencing | not seen |
| 2812 (2787–2837) | Speech sent as coded pulses | 6 y | 36 min | pulse_code_modulation | not seen |
| 2818 (2793–2843) | Formula programming languages | 8 y | 49 min | NEW · formula_programming_languages | — |
| 2825 (2800–2850) | Arithmetic-logic units | 6 y | 36 min | arithmetic_logic_units | not seen |
| 2825 (2800–2850) | Diode control stores | 5 y | 30 min | diode_control_stores | not seen |
| 2825 (2800–2850) | Codes that catch transmission errors | 5 y | 30 min | error_detection_codes | not seen |
| 2825 (2800–2850) | Messages framed with headers and checks | 5 y | 30 min | message_framing | not seen |
| 2825 (2800–2850) | Lost blocks asked for again automatically | 5 y | 30 min | automatic_repeat_request | not seen |
| 2825 (2800–2850) | Modems send data over telephone lines | 6 y | 36 min | data_modems | not seen |
| 2830 (2805–2855) | Orbiting satellites relay telephone and pictures | 10 y | 61 min | NEW · relay_satellites | — |
| 2832 (2807–2857) | Mass higher education: many new universities | 8 y | 49 min | NEW · mass_higher_education | — |
| 2838 (2813–2863) | Microprogrammed machine control | 6 y | 36 min | microprogrammed_machine_control | not seen |
| **2848 (2813–2883)** | **Messages cut into addressed packets** | 10 y | 61 min | packet_switching | not seen |
| 2848 (2823–2873) | Packet routers | 6 y | 36 min | packet_routers | not seen |
| 2848 (2823–2873) | Store-and-forward message archives | 5 y | 30 min | store_forward_archives | not seen |
| 2850 (2825–2875) | Relational databases queried by table | 6 y | 36 min | NEW · relational_databases | — |
| **2858 (2823–2893)** | **Genes cut from one living thing and spliced into another (continues: hereditary_double_helix; shared: health, nutrition)** | 10 y | 61 min | NEW · recombinant_dna | — |
| 2865 (2840–2890) | Public-key ciphers (shared: security) | 8 y | 49 min | NEW · public_key_ciphers | — |
| **2868 (2833–2903)** | **Desk computers for homes and offices** | 10 y | 61 min | NEW · desk_computers | — |
| **2882 (2847–2917)** | **Common protocols join many networks into one** | 10 y | 61 min | NEW · internetworking_protocols | — |
| 2882 (2857–2907) | Cellular radio telephones | 8 y | 49 min | NEW · cellular_telephony | — |
| **2902 (2867–2937)** | **Linked hypertext pages span the world** | 12 y | 73 min | NEW · world_hypertext_web | — |
| 2912 (2887–2937) | Planets found around other stars | 5 y | 30 min | NEW · exoplanet_detection | — |
| 2920 (2895–2945) | Search indexes ranked by links | 6 y | 36 min | NEW · ranked_search_indexes | — |
| 2928 (2903–2953) | Open encyclopedia written and corrected by volunteers | 5 y | 30 min | NEW · volunteer_open_encyclopedia | — |
| 2940 (2915–2965) | Computing rented from vast data halls | 6 y | 36 min | NEW · cloud_data_halls | — |
| 2942 (2917–2967) | Pocket touch-screen computers on the phone network | 10 y | 61 min | NEW · pocket_networked_computers | — |
| 2955 (2930–2980) | Deep learned networks recognise images and speech | 10 y | 61 min | NEW · deep_learning_networks | — |
| 2962 (2937–2987) | Gravitational waves detected | 5 y | 30 min | NEW · gravitational_wave_detection | — |
| **2975 (2940–3000)** | **Large language models converse, translate and draft** | 12 y | 73 min | NEW · large_language_models | — |
| 2988 (2963–3000) | Error-corrected quantum processors, small but working | 10 y | 61 min | NEW · error_corrected_quantum_processors | — |
| 2998 (2973–3000) | Learned models plan and run automated laboratory trials | 8 y | 49 min | NEW · automated_discovery_labs | — |

## Pacing

| Years | 2400–2450 | 2450–2500 | 2500–2550 | 2550–2600 | 2600–2650 | 2650–2700 | 2700–2750 | 2750–2800 | 2800–2850 | 2850–2900 | 2900–2950 | 2950–3000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Knowledge advances | 9 | 15 | 10 | 13 | 15 | 25 | 10 | 9 | 20 | 6 | 6 | 5 |

The total is **143** advances: 87 in years 2400–2700 and 56 in years 2700–3000. Five gap rows were added by the registry pass (see *Gap rows*). Across the four channels, one lands about every 4.2 years, so each channel always has work of its age. The list runs longer than the 100–130 target because 99 rows are catalog ids that must be placed; many of them (telegraph and radio parts, microscope parts) are small steps that take 4–6 years. Long thresholds (27 bold rows) take 10–15 years (1–1.5 real hours). The densest stretch is 2650–2700 (≈ AD 1894–1912), when the catalog's radio and electron items cluster.

**Key thresholds:**
1. **Electricity and the field:** electrochemical_cells (2400) → electrical_measurement (2453) → electromagnetic_induction (2483) → energy_conservation_law (2525) → electromagnetic_wave_theory (2571) → cathode_ray_discharge_tubes (2603) → electron_physics (2659) → energy_quanta (2667) → relative_spacetime (2680) → atomic_physics (2696) → quantum_mechanics (2733) → band_theory (2747) → pn_junctions (2802).
2. **Wire and wireless:** optical_telegraphy (2413) → timed_signal_sequences (2499) → electrical_telegraphy (2504) → undersea_telegraph_cable (2576) → telephone_circuits (2605) → radio_telegraphy (2664) → triode_valves (2683) → amplitude_modulation (2699) → superheterodyne_reception (2720) → frequency_modulation (2755) → pulse_code_modulation (2812) → relay_satellites (2830) → cellular_telephony (2882).
3. **Signals to networks:** signal_sampling (2741) → information_theory (2795) → error_detection_codes (2825) → data_modems (2825) → packet_switching (2848) → internetworking_protocols (2882) → world_hypertext_web (2902) → ranked_search_indexes (2920) → pocket_networked_computers (2942).
4. **Computation:** punched_card_tabulation (2640) → computability_theory (2763) → **stored_program_computer (2796)** → formula_programming_languages (2818) → microprogrammed_machine_control (2838) → relational_databases (2850) → desk_computers (2868) → deep_learning_networks (2955) → large_language_models (2975) → error_corrected_quantum_processors (2988) → automated_discovery_labs (2998). Circuits, registers and stored-program control are Production (catalog `Materials`); the machine itself, the first stored-program electronic computer, is placed here and shared with Production.
5. **Life under the lens:** compound_microscopy (2480) → cell_theory (2504) → biological_staining (2555) → descent_by_selection (2557) → microbial_isolation_methods (2603) → cell_culture_methods (2685) → live_cell_time_lapse (2800) → hereditary_double_helix (2808) → **recombinant_dna (2858)**, which Health's recombinant vaccine and Nutrition's transgenic crops and fermented proteins build on.
6. **Matter and the nucleus:** atomic_combining_weights (2408) → spectroscopy (2557) → periodic_element_table (2584) → radiation_measurement (2659) → crystallography (2699) → expanding_universe_cosmology (2744) → nuclear_fission (2768) → neutron_moderation (2768). Fission is framed soberly: it opens both reactors (Production) and bombs (Security).
7. **Schools and science as institutions:** research_university (2427) → compulsory_elementary_schooling (2587) → industrial_research_laboratory (2603) → refereed_journals (2667) → state_great_laboratories (2779) → universal_secondary_schooling (2784) → mass_higher_education (2832).
8. **The page and the image:** cylinder_press_printing (2437) → fixed_light_images (2504) → punched_message_tape (2587) → typewriter (2600) → teleprinter_mechanisms (2683) → volunteer_open_encyclopedia (2928). Photography as portrait and press art is Culture (`portrait_photo_studios`, `photo_news_magazines`).
9. **Ownership of overlaps:** the catalog's microbial and aseptic items stay here by direction; Health builds germ theory, vaccines and antisepsis in surgery on them. `public_key_ciphers` is shared with Security. Railway time and standard time zones are left to Logistics and Labor. `aerodynamics` and `wind_tunnel_testing` feed Logistics' powered flight. `photovoltaic_conversion` feeds Production's solar cells. Undersea cables are laid by Logistics ships but owned here as communication. Newspapers, broadcasting and social media as public culture are Culture; their state control is Institutions (`state_propaganda_ministry`) and Security (`mass_signals_surveillance`).


**Gap rows** (added by the registry pass because no line claimed them; recorded in `rows_added_by_registry`):
- `typewriter` (2600, ≈ AD 1875): the keyed writing machine; feeds Labor's `women_office_clerks` and `teleprinter_mechanisms`.
- `cathode_ray_discharge_tubes` (2603, ≈ AD 1876): evacuated discharge tubes and cathode rays; Health's `bone_shadow_imaging` and `electron_physics` require it.
- `expanding_universe_cosmology` (2744, ≈ AD 1929): receding star systems and the expanding universe.
- `stored_program_computer` (2796, ≈ AD 1948): the first stored-program electronic computer, built from valves, relay registers and binary adders; Ecology's `numerical_weather_prediction` requires it. Production's `read_write_memory` (2806) and `stored_program_control` (2838) remain the catalog's later memory and controller items.
- `recombinant_dna` (2858, ≈ AD 1973): gene splicing; Health's `recombinant_vaccine`, Nutrition's `transgenic_crops` and `precision_fermented_proteins`, and Production's `engineered_microbe_chemicals` require it.
- A progressive income tax was checked and not added: the 1800–2400 Institutions row `graduated_income_tax` (2398) already covers it.

## Government and civic life

Knowledge rows that change government or civic life (for the civic-evolution pass):

   - **Offices (2):** `punched_card_tabulation` 2640, `state_great_laboratories` 2779.
   - **Law (2):** `compulsory_elementary_schooling` 2587, `universal_secondary_schooling` 2784.

`compulsory_elementary_schooling` (2587) makes schooling a state duty and pairs with Institutions' `public_instruction_ministry` (2480). `punched_card_tabulation` (2640) lets the census office count a whole realm in months. `state_great_laboratories` (2779) puts science ministers and scientific advisers into the court. Untagged rows that also matter: `research_university` (2427) trains the examined civil service (Institutions `competitive_civil_service`, 2541); `electrical_telegraphy` (2504) and `radio_telegraphy` (2664) let the capital command provinces and generals in hours; `information_theory`, `packet_switching` and `pocket_networked_computers` are the base for Institutions' `online_government_services`, `digital_identity_register` and Security's `mass_signals_surveillance`; `large_language_models` (2975) is the base for `learned_machine_law` and `algorithmic_decision_audits`.

## Currently too early / too late (knowledge line, main)

These are placement targets only. "Seen" is the earliest year in recorded runs.

| Item | Seen | Belongs |
|---|---|---|
| mechanical_work_energy (catalog AD 1826 ≈ 2469) | 157 | 2469. Seen about 2312 game years early. |
| statistical_sampling (catalog AD 1900 ≈ 2667) | 185 | 2667. Seen about 2482 game years early. |
| electrochemical_cells (catalog AD 1800 ≈ 2400) | 200 | 2400. Seen about 2200 game years early. |
| electrical_measurement (catalog AD 1820 ≈ 2453) | 202 | 2453. Seen about 2251 game years early. |
| measurement_uncertainty (catalog AD 1809 ≈ 2424) | 205 | 2424. Seen about 2219 game years early. |
| electromagnetic_induction (catalog AD 1831 ≈ 2483) | 207 | 2483. Seen about 2276 game years early. |
| vector_analysis (catalog AD 1880 ≈ 2613) | 211 | 2613. Seen about 2402 game years early. |
| dimensional_analysis (catalog AD 1822 ≈ 2459) | 216 | 2459. Seen about 2243 game years early. |
| heat_engine_cycles (catalog AD 1824 ≈ 2464) | 226 | 2464. Seen about 2238 game years early. |
| semiconductor_doping (catalog AD 1951 ≈ 2802) | 228 | 2802. Seen about 2574 game years early. |
| optical_telegraphy (catalog AD 1837 ≈ 2499) | not seen | 2413 (≈ AD 1805). Catalog year is late. |
| least_squares_estimation (catalog AD 1850 ≈ 2533) | not seen | 2416 (≈ AD 1806). Catalog year is late. |
| electromagnet_sounders (catalog AD 1837 ≈ 2499) | not seen | 2493 (≈ AD 1835). Catalog year is late. |
| electrical_telegraphy (catalog AD 1850 ≈ 2533) | not seen | 2504 (≈ AD 1839). Catalog year is late. |
| line_insulators (catalog AD 1850 ≈ 2533) | not seen | 2523 (≈ AD 1846). Catalog year is late. |
| telegraph_return_circuits (catalog AD 1850 ≈ 2533) | not seen | 2528 (≈ AD 1848). Catalog year is late. |
| matrix_algebra (catalog AD 1850 ≈ 2533) | not seen | 2555 (≈ AD 1858). Catalog year is early. |
| telephone_circuits (catalog AD 1897 ≈ 2659) | not seen | 2605 (≈ AD 1877). Catalog year is late. |
| carbon_microphones (catalog AD 1897 ≈ 2659) | not seen | 2608 (≈ AD 1878). Catalog year is late. |
| manual_switchboards (catalog AD 1897 ≈ 2659) | not seen | 2608 (≈ AD 1878). Catalog year is late. |
| radio_telegraphy (catalog AD 1920 ≈ 2720) | not seen | 2664 (≈ AD 1899). Catalog year is late. |
| tuned_radio_reception (catalog AD 1920 ≈ 2720) | not seen | 2688 (≈ AD 1908). Catalog year is late. |
| atomic_physics (catalog AD 1900 ≈ 2667) | not seen | 2696 (≈ AD 1911). Catalog year is early. |
| shutter_signal_frames (catalog AD 1795 ≈ 2387) | not seen | Before this window (1800–2400 lists). `optical_telegraphy` continues it at 2413. |
| metal_type_casting (catalog AD 1809 ≈ 2424) | not seen | Already placed ≈ 1875 by the 1200–1800 registry's belongs-later list (hand-mould casting ≈ AD 1450); not relisted here. |
| public_libraries (catalog AD 1850 ≈ 2533) | not seen | Already placed at 896 (Culture, 600–1200). Culture's `endowed_town_libraries` (2621) continues it. |
| risk_pools (catalog AD 1800 ≈ 2400) | not seen | Already placed at 850 (Institutions, 600–1200). Not relisted. |
| Computing hardware (`binary_adders`, `relay_logic`, `stored_program_control`, `read_write_memory` and the rest of `digital_logic_knowledge.gd` / `computing_memory_knowledge.gd`) | — | Catalog direction `Materials`, so not placed here. Knowledge's `computability_theory` (2763), `formula_programming_languages` (2818) and `desk_computers` (2868) sit beside them. |
