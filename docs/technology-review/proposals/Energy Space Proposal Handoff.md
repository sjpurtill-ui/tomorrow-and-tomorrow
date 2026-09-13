# Energy and space discovery proposals

**READY for editorial review: 40 proposals, 20 Energy (D05) and 20 Space (D23). No runtime discoveries or artwork added.**

Worktree: `/Users/seanpurtill/Documents/Codex/tt-energy-space-proposals`. Branch: `codex/energy-space-proposals`. Base: `2e04f464928354e0f13ceeea452c78e2e1d0f0f6`. This document and `energy-space-proposals.json` are the only owned files. The containing commit is the frozen delivery. Prior metallurgy and civic/cultural deliveries remain unchanged. The designated integrator owns reconciliation and promotion.

## Scope and distinctness

Comparison baseline: 3,470 catalog identities plus eight metallurgy and forty civic/cultural proposals. D05 has 176 catalog identities against its target of 260; D23 has 135 against 180. The forty proposed additions remain outside those counts. Exact ID/name checks supplement comparison with named semantic neighbors, rather than establishing distinctness alone.

The energy proposals distinguish conversion mechanisms, working fluids, storage reactions and actual operating controls. Steam reheating adds heat between expansion stages; condensate flashing recovers a lower-pressure vapor stream. Osmotic pressure conversion and reverse electrodialysis produce different intermediate outputs. Molten-salt freeze protection preserves circulating equipment, while latent storage deliberately changes phase. Detailed methods may still merit consolidation as recipes under a broader discovery; the integrator must resolve that editorial question before promotion.

The space proposals include pre-spaceflight measurement foundations and particular navigation, attitude, thermal and orbital methods. Passive nutation damping dissipates wobble; magnetic unloading exchanges angular momentum with an external field; control-moment gyros steer stored momentum. Repeated-pass aerobraking starts with a captured orbit; single-pass aerocapture attempts capture from an incoming trajectory and remains a researched concept in its cited source. A drag sail spends orbital energy in atmosphere and is not a solar sail.

Existing hydraulic ram pumps, capillary propellant acquisition, low-gravity gauging, settling maneuvers, cryogenic pressure/chilldown controls, electrodynamic tethers, solar sails, radio occultation and asteroseismology were excluded after catalog comparison. No economics or accounting identities are added.

## Branching and recovery

Every ALL parent and one member of each OR group is required. Branch review removed nonexistent placeholder IDs and avoided forcing a point-absorber invention before a hinged wave converter. Thermoelectric measurement admits electrochemical or induction-based electrical foundations. Meridian transit observation admits either clock route and either telescope route. Aerocapture admits ablative or reusable thermal protection; neither removes entry-control requirements.

All records include paid apparatus and staff work, retained observations, failure and downstream use. Resources describe design inputs, not existing stock IDs. Imported equipment or service does not grant local mastery. Scholar visits incur travel, support and demonstration; partnerships incur shared effort and delayed validation; commissioned research incurs delivery and evaluation, including negative findings. These contracts still need runtime implementation and balancing. No percentage bonus substitutes for an operation.

Historical horizons are representative design placements, not first-invention dates or a validated campaign timeline. Modern prototypes and theoretical proposals do not imply routine historical operation. This batch does not fill every early or future historical gap.

## Validation and limits

Forty unique IDs and normalized names; twenty records per field; zero unresolved prerequisite or semantic-neighbor references; no cycle among proposed prerequisite edges. All forty become structurally reachable in two rounds **assuming all 3,518 comparison foundations available**. This is not global runtime reachability: existing runtime definitions and learning routes require their own audit.

Thirty-seven distinct primary institutional, standards-body, instrument, collection or original-research source URLs have per-record locators. Review used retrieved excerpts, abstracts and relevant sections; it was not a full-text audit of every publication. Sources support mechanisms or explicitly labeled concepts, while operating costs and state transitions are original game design. No universal efficiency or historical-priority claim is inferred from a single experiment. Source availability and chronology remain editorial limitations.

No game tests or launches were performed for these authoring-only files. Save compatibility: no runtime/save changes. Shared-file conflicts: none expected; catalog promotion requires semantic review. The full overhaul remains incomplete: reconciliation, physical operation, acquisition balance, military/civilian integration, imagery and 2,500–3,000-year pacing still require delivery.

Comparison catalog SHA-256: `5c6cc58ec17de60fdce85ddcfcd937c209669a60a088606d3bced65c131918c7`.

## Individual proposals

### 1. Phase-Selective Steam Traps

`phase_selective_steam_traps` · D05 · industrial

ALL: `steam_condensers`. OR groups: none.

Discharge condensate while limiting live-steam escape. Pay a sized trap, valve work and pressure/temperature checks; retain drain and leakage observations.

**Failure:** Stuck-open traps waste supplied steam; blocked traps accumulate condensate. **Downstream use:** A steam user receives a drained line with measured steam loss charged to its supply.

**Semantic neighbors:** `condensate_return_networks`, `steam_condensers`. Automatic phase-responsive drainage differs from condensing steam or returning already separated water.

**Source:** [supporting source 1](https://www.energy.gov/sites/prod/files/2014/04/f15/steam_survey_guide.pdf) — steam traps.

### 2. Condensate Flash Recovery

`condensate_flash_recovery` · D05 · industrial

ALL: `steam_condensers`, `thermal_plant_heat_balances`. OR groups: none.

Recover vapor released when hot condensate depressurizes. Pay a flash vessel, pressure control and compatible low-pressure heat demand; retain vapor/liquid split.

**Failure:** No low-pressure demand means recovered vapor cannot be credited as useful heat; carryover contaminates delivery. **Downstream use:** An actual lower-temperature process consumes the retained flash-steam service.

**Semantic neighbors:** `condensate_return_networks`, `regenerative_feed_heating`. Recovering pressure-drop vapor differs from returning liquid and extraction-steam feed heating.

**Source:** [supporting source 1](https://www.energy.gov/sites/prod/files/2014/04/f15/steam_survey_guide.pdf) — flash steam recovery.

### 3. Interstage Steam Reheating

`interstage_steam_reheating` · D05 · industrial

ALL: `compound_steam_expansion`, `steam_superheating`. OR groups: none.

Add heat between separate steam expansion stages. Pay reheater surfaces, extra supplied heat and pressure-loss monitoring; retain stage inlet/outlet states.

**Failure:** Excess pressure drop or insufficient heat prevents the expected second-stage work; moisture limits remain. **Downstream use:** A qualified turbine train exports measured shaft work after accounting for the extra heat.

**Semantic neighbors:** `steam_superheating`, `regenerative_feed_heating`. Interstage reheating differs from initial superheat and heating liquid feedwater.

**Source:** [supporting source 1](https://www.asme.org/codes-standards/find-codes-standards/moisture-separator-reheaters) — PTC 12.4 scope: reheating components between high- and low-pressure turbines; terminal temperature difference, pressure drop and heating-steam flow measurements.

### 4. Regenerative Stirling Engines

`regenerative_stirling_engines` · D05 · industrial

ALL: `mechanical_oscillation`, `precision_thermometry`. OR groups: none.

Cycle a sealed working gas between hot and cold spaces through a regenerator. Pay a sealed engine, regenerator, heat source, cooling service and dynamometer time.

**Failure:** Seal leakage or regenerator loss reduces observed work; a stalled engine produces no shaft service. **Downstream use:** Measured shaft work drives a pump or generator without consuming working gas as fuel.

**Semantic neighbors:** `compound_steam_expansion`, `gas_turbine_cycles`. An externally heated closed displacement cycle differs from steam expansion and continuous-flow gas turbines.

**Source:** [supporting source 1](https://science.nasa.gov/planetary-science/programs/radioisotope-power-systems/dynamic-power/) — Stirling cycle development.

### 5. Supercritical CO2 Power Cycles

`supercritical_co2_power_cycles` · D05 · modern

ALL: `gas_turbine_cycles`, `thermal_plant_heat_balances`. OR groups: none.

Circulate dense carbon dioxide through a closed compression and expansion cycle. Pay pressure-rated machinery, supplied heat, recuperation and sink cooling; retain compressor and turbine work separately.

**Failure:** Near-critical inlet drift, leakage or excessive compression can erase net output. **Downstream use:** A qualified plant exports only turbine work minus compressor and auxiliary demand.

**Semantic neighbors:** `binary_geothermal_cycles`, `gas_turbine_cycles`. A dense-fluid closed Brayton cycle differs from vaporizing a secondary fluid and open combustion turbines.

**Source:** [supporting source 1](https://www.energy.gov/supercritical-co2-tech-team) — closed Brayton cycles.

### 6. Seebeck Power Conversion

`seebeck_power_conversion` · D05 · industrial/modern

ALL: `precision_thermometry`. OR groups: (`electrochemical_cells` OR `electromagnetic_induction`).

Convert a maintained temperature difference across thermoelectric elements into electrical output. Pay qualified elements, contacts, hot-side heat and cold-side rejection; measure delivered current and voltage under load.

**Failure:** Lost temperature difference yields no useful output; contact damage raises losses. **Downstream use:** Remote instruments consume measured electricity while most supplied heat still reaches the sink.

**Semantic neighbors:** `photovoltaic_conversion`, `thermionic_emission`. Solid thermoelectric transport differs from photon absorption and electron emission into a gap.

**Source:** [supporting source 1](https://science.nasa.gov/planetary-science/programs/radioisotope-power-systems/power-radioisotope-thermoelectric-generators/) — thermocouples and heat-to-electric conversion.

### 7. Thermal-Emitter Photovoltaics

`thermal_emitter_photovoltaics` · D05 · modern/research

ALL: `photovoltaic_conversion`, `thermal_plant_heat_balances`. OR groups: none.

Convert radiation from a hot emitter using matched photovoltaic cells. Pay emitter heating, cells, optical enclosure and cell cooling; measure absorbed radiant energy and load output.

**Failure:** Spectral mismatch or excessive cell heat reduces net useful energy; no solar or storage energy is created. **Downstream use:** A charged thermal store can supply a qualified electrical load through the converter.

**Semantic neighbors:** `photovoltaic_array_matching`, `concentrated_solar_power`. Thermal-source radiation and spectral recovery differ from sunlight array matching and turbine-based solar power.

**Source:** [supporting source 1](https://news.mit.edu/2022/thermal-heat-engine-0413) — reported TPV experiment; scale-up remains separate.

### 8. Vacuum Thermionic Power Conversion

`vacuum_thermionic_power_conversion` · D05 · modern/research

ALL: `thermionic_emission`, `thermal_plant_heat_balances`. OR groups: none.

Collect thermally emitted electrons across a maintained gap to deliver power. Pay emitter heat, collector cooling, gap control and vacuum apparatus; retain current-voltage and heat measurements.

**Failure:** Space charge, contamination or excessive return heat can defeat net output. **Downstream use:** A qualified converter supplies an actual electrical load from paid heat.

**Semantic neighbors:** `thermionic_emission`, `seebeck_power_conversion`. A power-producing emitter/collector heat engine adds load and heat closure beyond observing emission.

**Source:** [supporting source 1](https://arxiv.org/abs/1304.3060) — original collector-optimization study.

### 9. Absorption Heat Pumping

`absorption_heat_pumping` · D05 · industrial/modern

ALL: `heat_pump_cycles`. OR groups: none.

Use heat-driven absorption and desorption to circulate a refrigerant. Pay working solution, generator heat, liquid pumping and cooling surfaces; measure heat moved between actual loads.

**Failure:** Crystallization, leaks or inadequate source heat interrupts circulation. **Downstream use:** A building or process receives measured heating/cooling with thermal input and pump demand charged.

**Semantic neighbors:** `heat_pump_cycles`, `ground_source_heat_pumps`. Solution absorption replaces the principal vapor compressor; the source location alone does not define this cycle.

**Source:** [supporting source 1](https://www.energy.gov/energysaver/heat-pump-systems) — absorption heat pumps.

### 10. Steam-Ejector Refrigeration

`steam_ejector_refrigeration` · D05 · industrial

ALL: `steam_condensers`, `thermal_plant_heat_balances`. OR groups: none.

Use a motive steam jet to entrain vapor from a low-pressure evaporator. Pay steam, an ejector, condenser cooling and working water; measure entrainment and evaporation.

**Failure:** Excess backpressure breaks entrainment and cooling; uncondensed discharge remains an energy cost. **Downstream use:** A qualified cold process consumes measured cooling without a mechanical vapor compressor.

**Semantic neighbors:** `heat_pump_cycles`, `absorption_heat_pumping`. Jet entrainment differs from mechanical compression and solution absorption.

**Source:** [supporting source 1](https://www.sciencedirect.com/science/article/abs/pii/S0894177711000021) — Ruangtrakoon et al., Experimental Thermal and Fluid Science 35 (2011), 676-683, abstract and ejector background.

### 11. Tidal-Basin Impoundment Generation

`tidal_basin_impoundment_generation` · D05 · industrial/modern

ALL: `hydroelectric_generation`, `tidal_port_planning`. OR groups: none.

Retain tidal water behind gates and generate across the resulting head. Pay a basin barrier, gates, turbines, maintenance and scheduled passage obligations; track both water levels.

**Failure:** Insufficient head supplies no power; blocked gates and ecological restrictions limit operation. **Downstream use:** A local grid receives generation only during permitted head/flow intervals.

**Semantic neighbors:** `tidal_stream_generation`, `millpond_storage`. A gated tidal head reservoir differs from extracting kinetic energy from an unimpounded current.

**Source:** [supporting source 1](https://www.eia.gov/energyexplained/hydropower/tidal-power.php) — tidal barrages.

### 12. Hinged Wave-Surge Generation

`hinged_wave_surge_generation` · D05 · modern

ALL: `mechanical_oscillation`. OR groups: (`hydroelectric_generation` OR `wind_generator_conversion`).

Drive a power takeoff from wave-driven angular motion about a fixed reaction point. Pay a hinged flap, seabed support, power takeoff and inspections; measure angle, torque and exported work.

**Failure:** Storm overload or a jammed hinge requires shutdown; no wave input means no work. **Downstream use:** A coastal electrical or pumping load uses qualified fluctuating output.

**Semantic neighbors:** `wave_point_absorbers`, `wave_oscillating_water_columns`. Selected seabed-reacted surge rotation differs from heaving-body response and oscillating air chambers.

**Source:** [supporting source 1](https://www.energy.gov/cmei/water/marine-energy-glossary) — oscillating wave surge converter.

### 13. Wave Overtopping Reservoirs

`wave_overtopping_reservoirs` · D05 · modern

ALL: `hydroelectric_generation`. OR groups: none.

Collect wave overtopping above mean water level and release it through a turbine. Pay a collector ramp, reservoir, turbine and support; measure captured water and changing head.

**Failure:** Spillage, low waves or structural damage reduces recoverable output. **Downstream use:** A local load consumes electricity bounded by captured water's potential energy.

**Semantic neighbors:** `wave_point_absorbers`, `millpond_storage`. Waves lift water into a reservoir instead of directly driving a moving absorber.

**Source:** [supporting source 1](https://www.energy.gov/cmei/water/marine-energy-glossary) — overtopping device.

### 14. Pressure-Retarded Osmotic Power

`pressure_retarded_osmotic_power` · D05 · modern/research

ALL: `salinity_gradient_power`. OR groups: none.

Admit low-salinity water through a membrane into a pressurized concentrated stream. Pay two finite feed streams, pretreatment, membranes and pressure recovery; measure added pressurized flow.

**Failure:** Fouling or pump losses can make net output nonpositive; diluted feed cannot be reused as unchanged brine. **Downstream use:** A turbine supplies only net recovered work after pumping and replaces both discharged feed inventories.

**Semantic neighbors:** `salinity_gradient_power`, `reverse_osmosis_desalination`. Uses osmotic water flux to produce hydraulic work; desalination spends work to oppose that flux.

**Source:** [supporting source 1](https://www.energy.gov/sites/prod/files/2015/10/f27/epwrr_workshop_report.pdf) — pressure-retarded osmosis.

### 15. Reverse-Electrodialytic Power

`reverse_electrodialytic_power` · D05 · modern/research

ALL: `salinity_gradient_power`. OR groups: none.

Pass ions through alternating selective membranes to generate stack voltage. Pay contrasting feed streams, membrane pairs, electrode service and pumping; retain stack current and discharged salinities.

**Failure:** Membrane leakage and internal resistance can exceed useful generation. **Downstream use:** An actual electrical load consumes measured net stack power from depleted salinity gradients.

**Semantic neighbors:** `salinity_gradient_power`, `pressure_retarded_osmotic_power`. Selective ion transport generates voltage rather than pressure-driven turbine work.

**Source:** [supporting source 1](https://pmc.ncbi.nlm.nih.gov/articles/PMC8415203/) — original high-concentration stack experiments.

### 16. Superconducting Magnetic Storage

`superconducting_magnetic_storage` · D05 · modern

ALL: `electromagnetic_induction`, `power_semiconductor_switching`. OR groups: none.

Store supplied electrical energy in a superconducting coil's magnetic field. Pay a qualified coil, cryogenic service, converter and quench protection; retain charge/discharge energy.

**Failure:** Loss of cooling or a quench forces controlled energy dissipation; refrigeration is never free. **Downstream use:** An electrical load receives a bounded pulse or short reserve service with actual auxiliary losses.

**Semantic neighbors:** `flywheel_energy_storage`, `electrochemical_double_layer_storage`. Magnetic field storage differs from rotor momentum and electrostatic interface charge.

**Source:** [supporting source 1](https://www.sandia.gov/app/uploads/sites/163/2021/09/SAND2010-0815.pdf) — SMES coil and power conditioning.

### 17. Nickel-Iron Cell Cycling

`nickel_iron_cell_cycling` · D05 · industrial/modern

ALL: `electrochemical_cells`, `nickel_metal_recovery`. OR groups: none.

Cycle alkaline nickel/iron electrodes as a rechargeable cell. Pay qualified electrodes, electrolyte, case, charging electricity and water maintenance; retain capacity and self-discharge measurements.

**Failure:** Gassing, water loss and charge inefficiency reduce delivered energy. **Downstream use:** A stationary load uses inspected cells with measured usable capacity, not a generic chemistry bonus.

**Semantic neighbors:** `lead_acid_cells`, `lithium_intercalation_cells`. Alkaline nickel/iron conversion has different maintenance and charging behavior from lead-acid and lithium host insertion.

**Source:** [supporting source 1](https://www.sandia.gov/app/uploads/sites/163/2021/09/SAND2014-17462.pdf) — selected battery tests.

### 18. Molten Sodium-Sulfur Cells

`molten_sodium_sulfur_cells` · D05 · modern

ALL: `solid_electrolyte_cells`, `battery_thermal_management`. OR groups: none.

Cycle molten reactants across a sodium-ion-conducting ceramic separator. Pay qualified cells, heat-up energy, insulation and containment inspection; retain temperature and charge history.

**Failure:** A cracked separator or failed thermal control isolates the cell; cooling below operating conditions withholds output. **Downstream use:** A grid storage installation supplies measured energy after continuous thermal overhead.

**Semantic neighbors:** `sodium_intercalation_cells`, `solid_electrolyte_cells`. Molten reactants and a ceramic separator differ from sodium insertion into host electrodes.

**Source:** [supporting source 1](https://www.sandia.gov/app/uploads/sites/163/2021/09/SAND2013-5131.pdf) — sodium-sulfur chemistry and beta alumina.

### 19. Reversible Metal-Hydride Storage

`reversible_metal_hydride_storage` · D05 · modern

ALL: `hydrogen_storage_systems`, `precision_thermometry`. OR groups: none.

Absorb hydrogen into a qualified solid and release it by controlled heating. Pay finite hydrogen, alloy bed, heat exchange, valves and cycling work; retain gas mass and thermal receipts.

**Failure:** Poor heat rejection limits charging; insufficient heat or contamination limits release. **Downstream use:** A fuel-cell user consumes only hydrogen actually released at its required pressure.

**Semantic neighbors:** `hydrogen_storage_systems`, `thermochemical_heat_storage`. Hydrogen-bearing solid storage with coupled heat flows differs from a compressed tank or heat-only storage claim.

**Source:** [supporting source 1](https://www.energy.gov/cmei/fuels/july-h2iq-hour-aries-flatirons-campus-mw-scale-hydrogen-system-research-text-version) — ARIES metal-hydride storage thermal management.

### 20. Molten-Salt Freeze Protection

`molten_salt_freeze_protection` · D05 · modern

ALL: `thermal_storage_tanks`, `insulated_process_heat_piping`. OR groups: none.

Maintain or restore liquid flow through a salt heat loop during cold conditions. Pay tracing heat, circulation, temperature sensing and scheduled drain capacity; retain minimum segment temperatures.

**Failure:** An unheated isolated segment can freeze and block delivery; thawing consumes additional heat and time. **Downstream use:** A solar thermal loop resumes usable heat delivery only after monitored flow recovery.

**Semantic neighbors:** `thermal_storage_tanks`, `phase_change_heat_storage`. Preventing unwanted solid blockage in a transport loop differs from deliberately storing latent heat.

**Source:** [supporting source 1](https://www.nrel.gov/docs/fy03osti/40028.pdf) — freeze-protection methods.

### 21. Meridian Transit Timing

`meridian_transit_timing` · D23 · early-modern/industrial

ALL: `angular_sky_catalogs`. OR groups: (`pendulum_timekeeping` OR `marine_timekeeping`); (`refracting_telescopes` OR `reflecting_telescopes`).

Time a star's passage across an aligned meridian instrument. Pay instrument alignment, clock comparison and observers on actual clear nights; retain crossing times.

**Failure:** Clock drift, axis tilt or a missed transit invalidates the claimed precision. **Downstream use:** An observatory updates qualified time and right-ascension observations.

**Semantic neighbors:** `angular_sky_catalogs`, `celestial_reference_frames`. A fixed transit instrument and timing procedure differ from generic angular catalogs and coordinate conventions.

**Source:** [supporting source 1](https://www.rmg.co.uk/collections/objects/rmgc-object-11148) — portable transit telescope.

### 22. Adjustable Armillary Dials

`adjustable_armillary_dials` · D23 · early/classical-to-early-modern

ALL: `angular_sky_catalogs`, `geometric_survey`. OR groups: none.

Set latitude and celestial rings to represent local solar hour geometry. Pay graduated rings, stand alignment and local shadow comparisons; retain dial settings and observed residuals.

**Failure:** Wrong latitude or warped rings makes the displayed hour disagree with observations. **Downstream use:** Local time demonstrations and astronomy teaching use the qualified physical model.

**Semantic neighbors:** `celestial_reference_frames`, `planetary_motion_tables`. A physically adjusted solar dial tests local projection geometry rather than defining a reference frame or fitting planetary motion.

**Source:** [supporting source 1](https://www.rmg.co.uk/collections/objects/rmgc-object-10392) — latitude adjustment, equinoctial ring and meridian gnomon.

### 23. Stellar Doppler Velocimetry

`stellar_doppler_velocimetry` · D23 · industrial/modern

ALL: `spectroscopy`, `celestial_reference_frames`. OR groups: none.

Infer line-of-sight stellar motion from calibrated spectral shifts. Pay telescope time, stable spectrograph, wavelength references and repeated reductions.

**Failure:** Instrument drift or stellar activity remains an alternate explanation; a shift alone proves no planet. **Downstream use:** Orbit investigators consume a dated velocity series with uncertainty.

**Semantic neighbors:** `exoplanet_transit_inference`, `gas_composition_analysis`. Spectral displacement measures motion rather than transit dimming or identifying gas components.

**Source:** [supporting source 1](https://www.eso.org/sci/facilities/lasilla/instruments/harps/inst/performance.html) — HARPS wavelength calibration and errors.

### 24. Occultation Chord Reconstruction

`occultation_chord_reconstruction` · D23 · industrial/modern

ALL: `eclipse_geometry_models`, `orbit_determination`. OR groups: none.

Combine timed stellar disappearances from separated sites into a projected body profile. Pay observer deployment, clock checks, optics and data return; retain positive and negative stations.

**Failure:** Clouded or mistimed reports remain uncertain; one chord cannot prove an entire shape. **Downstream use:** Navigation and size studies use the bounded projected outline at the event epoch.

**Semantic neighbors:** `eclipse_geometry_models`, `angular_image_calibration`. Measures occulting-body cross sections from multiple timed chords rather than predicting eclipse geometry.

**Source:** [supporting source 1](https://pds.nasa.gov/ds-view/pds/viewProfile.jsp?dsid=EAR-A-3-RDR-OCCULTATIONS-V6.0) — asteroid occultation observations.

### 25. Meteor-Track Triangulation

`meteor_track_triangulation` · D23 · industrial/modern

ALL: `angular_image_calibration`, `celestial_reference_frames`. OR groups: none.

Intersect simultaneous sky tracks from separated observers. Pay surveyed station positions, timed imaging and correspondence review; retain each original view.

**Failure:** Unsynchronized or misidentified tracks fail the intersection check. **Downstream use:** Meteor studies receive trajectory, speed and radiant estimates with uncertainty.

**Semantic neighbors:** `orbit_determination`, `angular_sky_catalogs`. A short atmospheric luminous trajectory needs simultaneous multi-site geometry rather than a long orbital arc.

**Source:** [supporting source 1](https://www.nasa.gov/blogs/watch-the-skies/2013/04/23/lyrid-meteor-over-georgia/) — two-station Lyrid observation.

### 26. Astronomical Adaptive Optics

`astronomical_adaptive_optics` · D23 · modern

ALL: `angular_image_calibration`, `reflecting_telescopes`. OR groups: none.

Measure wavefront distortion and command a deformable mirror. Pay a wavefront sensor, reference source, mirror actuators and real-time computing; retain correction residuals.

**Failure:** Dim references, actuator saturation or lag leaves a degraded image. **Downstream use:** An actual observing session receives a measured corrected field within its angular limits.

**Semantic neighbors:** `coronagraphic_starlight_suppression`, `angular_image_calibration`. Corrects time-varying atmospheric phase distortion rather than masking a bright source or mapping pixels to angles.

**Source:** [supporting source 1](https://www.eso.org/sci/facilities/develop/ao/what_ao.html) — adaptive versus active optics.

### 27. Lucky-Imaging Selection

`lucky_imaging_selection` · D23 · modern

ALL: `angular_image_calibration`, `photographic_image_capture`. OR groups: none.

Select and align the sharpest short exposures from a recorded burst. Pay a fast detector, observing time, storage and comparison work; preserve rejected-frame counts.

**Failure:** Insufficient photons or biased selection withholds a reliable composite. **Downstream use:** A qualified composite supports angular measurements while reporting lost exposure and selection limits.

**Semantic neighbors:** `astronomical_adaptive_optics`, `photographic_reproduction`. Post-selects existing exposures without changing the wavefront during capture.

**Source:** [supporting source 1](https://www.eso.org/sci/publications/messenger/archive/no.137-sep09/messenger-no137.pdf) — AstraLux Sur original instrument report.

### 28. X-Ray Pulsar Navigation

`xray_pulsar_navigation` · D23 · modern/research

ALL: `orbit_determination`, `atomic_timekeeping`. OR groups: none.

Fit measured pulsar pulse arrivals to a spacecraft navigation state. Pay an X-ray detector, pointing time, clock service, catalog updates and computation.

**Failure:** Sparse photons or clock/catalog errors leave a broad or ambiguous position estimate. **Downstream use:** A navigator receives an independent uncertain position solution for later route correction.

**Semantic neighbors:** `deep_space_clock_navigation`, `deep_space_tracking`. Uses astrophysical pulse arrivals rather than a ground radio ranging signal or the onboard clock alone.

**Source:** [supporting source 1](https://www.nasa.gov/universe/nasa-team-first-to-demonstrate-x-ray-navigation-in-space/) — SEXTANT demonstration.

### 29. Magnetic Momentum Unloading

`magnetic_momentum_unloading` · D23 · modern

ALL: `reaction_wheel_control`, `electromagnetic_induction`. OR groups: none.

Exchange stored spacecraft angular momentum with an ambient magnetic field. Pay torquer coils, magnetometers, electrical power and control time; retain field and wheel-speed histories.

**Failure:** Weak or unfavorably oriented fields delay unloading; no field means no promised torque. **Downstream use:** Attitude control regains wheel margin within actual orbital field geometry.

**Semantic neighbors:** `reaction_wheel_control`, `electrodynamic_tether_exchange`. Local magnetic dipoles unload attitude momentum without a long conducting tether or propellant impulse.

**Source:** [supporting source 1](https://ntrs.nasa.gov/citations/20080004328) — controlled magnetic torques.

### 30. Control-Moment Gyro Steering

`control_moment_gyro_steering` · D23 · modern

ALL: `reaction_wheel_control`, `inertial_navigation_platforms`. OR groups: none.

Steer gimballed flywheel momentum while avoiding unsupported torque directions. Pay gimbals, flywheel spin energy, bearings and controller work; retain commanded/achieved torque and margin.

**Failure:** Approaching a singular geometry limits maneuver authority and may require a different path. **Downstream use:** A spacecraft executes only attitude slews the retained actuator state can deliver.

**Semantic neighbors:** `reaction_wheel_control`, `marine_gyroscopic_stabilizers`. Gimbal steering and multi-axis singularities differ from changing wheel speed or resisting ship roll.

**Source:** [supporting source 1](https://ntrs.nasa.gov/citations/19720024010) — Original NASA study: gimbal-angle and gimbal-rate control laws with singularity avoidance.

### 31. Passive Nutation Damping

`passive_nutation_damping` · D23 · modern

ALL: `spacecraft_attitude_sensing`, `mechanical_oscillation`. OR groups: none.

Dissipate wobble energy through a qualified internal damper. Pay a tuned fluid-ring or mechanical damper, installation and spin tests; retain wobble decay measurements.

**Failure:** Wrong tuning or fluid behavior can leave unacceptable wobble; lost energy becomes heat. **Downstream use:** A spinning instrument platform can enter its qualified observation envelope.

**Semantic neighbors:** `reaction_wheel_control`, `spacecraft_thruster_control`. Passive dissipation reduces wobble without commanding reaction-wheel or thruster corrections.

**Source:** [supporting source 1](https://ntrs.nasa.gov/citations/19840006160) — AMPTE-IRM fluid damper test report.

### 32. Rocket Pogo Suppression

`rocket_pogo_suppression` · D23 · modern

ALL: `rocket_propellant_feed`, `ascent_load_envelope_models`. OR groups: none.

Decouple feed-system pressure oscillations from longitudinal vehicle motion. Pay suppression hardware, instrumented firings and coupled pressure/acceleration analysis.

**Failure:** A resonance persisting in the measured operating range prevents flight qualification. **Downstream use:** A qualified ascent configuration retains a tested oscillation envelope.

**Semantic neighbors:** `propellant_slosh_models`, `rocket_engine_turbopumps`. Coupled feed/thrust/structural feedback differs from lateral liquid slosh and pump pressure generation.

**Source:** [supporting source 1](https://www.nasa.gov/history/50-years-ago-solving-the-pogo-effect/) — Saturn V suppression development.

### 33. Repeated-Pass Aerobraking

`repeated_pass_aerobraking` · D23 · modern

ALL: `planetary_entry_aerodynamics`, `orbit_determination`. OR groups: none.

Reduce an already captured orbit through controlled repeated atmospheric passes. Pay navigation, thermal monitoring, attitude work and correction propellant; retain each pass's density and energy loss.

**Failure:** Unexpected density or heating triggers a raised periapsis or abort; no instant target orbit. **Downstream use:** A planetary orbiter trades elapsed mission time for qualified propellant savings.

**Semantic neighbors:** `controlled_reentry`, `orbital_transfer_planning`. Repeated shallow passes retain an orbit rather than ending flight at a surface.

**Source:** [supporting source 1](https://mgs-mager.gsfc.nasa.gov/overview/aerobraking.html) — Mars Global Surveyor aerobraking.

### 34. Single-Pass Aerocapture

`single_pass_aerocapture` · D23 · evaluated future mission concept

ALL: `planetary_entry_aerodynamics`, `orbit_determination`. OR groups: (`ablative_heat_shields` OR `reusable_thermal_protection`).

Use one atmospheric passage to convert an arrival trajectory into a bound orbit. Pay a qualified aeroshell, navigation precision, thermal margin and post-pass correction reserves; test sampled atmosphere errors.

**Failure:** Skip-out leaves an unbound trajectory; excessive penetration can destroy the craft; no success guarantee. **Downstream use:** Only a successful bounded capture creates the intended orbital mission state.

**Semantic neighbors:** `repeated_pass_aerobraking`, `controlled_reentry`. Captures an incoming unbound vehicle in one pass instead of shrinking an existing orbit or landing.

**Source:** [supporting source 1](https://robotics.jpl.nasa.gov/what-we-do/research-tasks/aerocapture-systems-definition/) — JPL aerocapture definition and demonstration limits.

### 35. Differential-Drag Formation Control

`differential_drag_formation_control` · D23 · modern

ALL: `formation_flying_control`, `spacecraft_attitude_sensing`. OR groups: none.

Change relative orbital spacing by selecting different atmospheric drag areas. Pay attitude-control work and monitored drag estimates; retain individual orbit losses and available area.

**Failure:** Low density slows control; excess drag spends altitude and mission lifetime. **Downstream use:** A constellation adjusts along-track spacing within measured drag authority.

**Semantic neighbors:** `formation_flying_control`, `collision_avoidance_maneuvers`. A specific low-thrust atmospheric control mechanism consumes orbital altitude instead of propellant.

**Source:** [supporting source 1](https://www.nasa.gov/cara/step-3-close-approach-risk-mitigation/) — CARA frontal-area reorientation.

### 36. Passive Drag-Sail Disposal

`passive_drag_sail_disposal` · D23 · modern

ALL: `orbit_disposal_design`, `deployable_orbital_structures`. OR groups: none.

Deploy additional area to accelerate atmospheric orbital decay. Pay membrane, booms, release mechanism and deployment verification; update disposal prediction from actual area.

**Failure:** A torn or jammed sail retains the old disposal problem; sparse atmosphere can leave long decay times. **Downstream use:** The disposal owner tracks a slowly decaying craft rather than instantly deleting debris.

**Semantic neighbors:** `solar_sail_navigation`, `differential_drag_formation_control`. A drag-augmentation disposal surface differs from radiation-pressure propulsion and reversible spacing control.

**Source:** [supporting source 1](https://www.esa.int/Space_Safety/Clean_Space/Tacking_sails_to_a_satellite) — deployable drag augmentation.

### 37. Radioisotope Thermoelectric Power

`radioisotope_thermoelectric_power` · D23 · modern

ALL: `seebeck_power_conversion`, `nuclear_waste_characterization`. OR groups: none.

Couple a qualified decay-heat source to thermoelectric conversion for spacecraft power. Pay a finite qualified sealed heat-source module, converter, integration and rejection surfaces; track declining thermal output.

**Failure:** Converter degradation or insufficient heat rejection reduces usable power; source production is not granted. **Downstream use:** A spacecraft receives sunlight-independent but finite and declining electrical service.

**Semantic neighbors:** `fission_electric_space_power`, `seebeck_power_conversion`. A decaying heat source and flight containment differ from sustained reactor fission and a generic converter.

**Source:** [supporting source 1](https://science.nasa.gov/planetary-science/programs/radioisotope-power-systems/power-radioisotope-thermoelectric-generators/) — spacecraft RTG heat source and conversion.

### 38. Lunar Laser Round-Trip Ranging

`lunar_laser_roundtrip_ranging` · D23 · modern

ALL: `laser_light_generation`, `atomic_timekeeping`, `orbit_determination`. OR groups: none.

Time laser returns from a known lunar reflector. Pay a laser station, pointing, detector time and an actually placed reflector; retain photon returns and delays.

**Failure:** Clouds, missed pointing or background events leave no accepted range. **Downstream use:** Orbit models ingest qualified Earth-Moon range observations.

**Semantic neighbors:** `deep_space_tracking`, `stellar_parallax_distance`. Two-way optical time of flight to a physical reflector differs from radio links and angular baseline parallax.

**Source:** [supporting source 1](https://earth.gsfc.nasa.gov/geo/networks/sgp/techniques/slr) — SLR and lunar reflector ranging.

### 39. Autonomous Star-Pattern Identification

`autonomous_star_pattern_identification` · D23 · modern

ALL: `spacecraft_attitude_sensing`, `angular_sky_catalogs`. OR groups: none.

Match observed star patterns against a catalog without an initial attitude guess. Pay a camera, catalog storage, processor cycles and validation against known fields.

**Failure:** False stars or ambiguous matches withhold a confident attitude; no arbitrary best match becomes truth. **Downstream use:** Attitude recovery receives a checked orientation estimate after loss of pointing knowledge.

**Semantic neighbors:** `spacecraft_attitude_sensing`, `angular_image_calibration`. Lost-in-space catalog matching solves identification before attitude estimation rather than only measuring angles.

**Source:** [supporting source 1](https://arxiv.org/abs/1808.08686) — original subgraph-matching study.

### 40. Passive Radiator Louvers

`passive_radiator_louvers` · D23 · modern

ALL: `space_radiators`, `spacecraft_thermal_balance`. OR groups: none.

Change exposed radiating area through temperature-responsive shutters. Pay louver blades, bimetal actuators, vacuum cycling and thermal measurement.

**Failure:** A stuck shutter can overcool or overheat the spacecraft; it supplies no new heat source. **Downstream use:** Thermal control varies measured rejection without continuous actuator electricity.

**Semantic neighbors:** `space_radiators`, `multilayer_space_insulation`. Mechanically variable radiative exposure differs from fixed radiator area and reflective insulation layers.

**Source:** [supporting source 1](https://www.nasa.gov/wp-content/uploads/2021/10/7.soa_thermal_2021_0.pdf) — passive bimetallic louver.

