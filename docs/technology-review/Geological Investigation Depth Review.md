# Geological investigation depth review

Integrator worktree `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`, branch `codex/geological-investigation-coverage`, base `ac6edc6`. Scope:31 new D22 authored proposals, explicit horizon mappings and this review. Independent textile illustrations were reviewed and integrated on this branch as `d13ca4b`; they do not add identities.

## Scope and distinction

The added methods cover catchment/soil reconnaissance, specimen preparation, direct subsurface sampling, downhole measurements, in-situ ground testing, surface geophysics and qualified interpretation. None reveals ore merely because a discovery name is known. A future operating implementation must pay for accessible survey locations, finite crews, rigs or instruments, samples, calibration, analysis and delay. It must retain measured extent, uncertainty and failed or ambiguous results in bounded saved records.

Existing `orebody_block_models` and `spatial_variograms` already cover local resource representations and spatial correlation; neither receives a renamed duplicate. Generic sample custody/reference tracking stays under existing `industrial_material_traceability` and experimental controls. `systematic_channel_sampling`, mineral identification tests, `sediment_provenance`, `structural_geologic_mapping`, `seismic_wave_observation`, `seismic_tomography`, regional aquifer response and broad radar observation remain existing foundations. New entries distinguish physical observations or analysis procedures with different evidence and limits. Regional grade/tonnage distributions describe a deposit population, not another local orebody block model.

Acoustic and optical borehole imaging remain distinct because their transducers, visibility requirements and evidence differ. Mechanical caliper data measure geometry, whereas gamma and resistivity logs measure different physical responses. Cone penetration does not magically provide a sample; the standard penetration method includes a disturbed sample and empirical corrections. Packer tests require actual interval isolation and can fail through leakage. A joint interpretation needs both a seismic branch and an electrical branch, not either one alone.

Two speculative additions—geometallurgical domain modeling and metallurgical sample compositing—were left out of this batch pending specific process-response evidence and semantic review. No forced filler identities were added to meet a quota.

## Reviewed method inventory

| Proposed method | Distinct mechanism | Operating limit |
|---|---|---|
| Stream Sediment Reconnaissance | Use catchment sediment chemistry to narrow upstream mineral search areas. | Directs follow-up visits while transport and mixed sources can displace anomalies. |
| Heavy Mineral Indicator Sampling | Concentrate and identify resistant heavy grains as source indicators. | Retains selected indicators lost in bulk averages; biased grain survival remains explicit. |
| Soil Geochemical Grids | Compare soil chemistry across a recorded spatial sampling grid. | Bounds local anomalies without treating untested ground as an ore body. |
| Geochemical Dispersion Models | Explain how weathering and transport displace chemical evidence from its source. | Separates plausible source zones from downstream or transported signals. |
| Mineral Thin Section Preparation | Cut and mount a rock slice with controlled thickness for transmitted-light inspection. | Creates an inspectable section while preparation loss and damaged grains remain costs. |
| Polarized Light Petrography | Interpret grain textures and optical responses in a prepared rock section. | Distinguishes mineral assemblages and textures without automatically measuring bulk grade. |
| Core Drilling Recovery | Recover a depth-indexed cylindrical sample while accounting for unrecovered intervals. | Adds subsurface specimens; poor recovery leaves gaps rather than invented rock. |
| Oriented Core Logging | Relate recovered structures to core depth and an orientation reference. | Preserves structural evidence while broken or rotated pieces reduce confidence. |
| Borehole Deviation Surveys | Measure the borehole path so downhole observations have spatial coordinates. | Corrects apparent vertical locations while sensor interference leaves uncertainty. |
| Borehole Caliper Logging | Measure borehole diameter along depth. | Identifies enlargement or constriction relevant to interpreting other logs. |
| Natural Gamma Borehole Logging | Record natural gamma response along a borehole. | Helps correlate lithologic intervals without directly proving ore grade. |
| Downhole Resistivity Logging | Measure formation and fluid electrical responses at known depths. | Constrains electrical contrasts while fluids and geometry complicate interpretation. |
| Acoustic Borehole Imaging | Image borehole-wall reflections with a rotating acoustic probe. | Records oriented wall features where acoustic contrast and access permit. |
| Optical Borehole Imaging | Record oriented optical views of the borehole wall. | Makes visible features inspectable; turbid water and casing obscure evidence. |
| Borehole Flow Logging | Measure vertical borehole flow under declared hydraulic conditions. | Locates contributing intervals without treating open-hole flow as isolated aquifer yield. |
| Packer Interval Testing | Isolate a borehole interval to test its hydraulic response. | Separates interval behavior where seals hold; leakage invalidates conclusions. |
| Standard Penetration Testing | Record corrected penetration resistance and recover a disturbed split-barrel sample. | Supplies an empirical ground indicator within its calibration limits. |
| Cone Penetration Soundings | Push an instrumented cone to obtain continuous penetration-response profiles. | Resolves changing ground response without producing a physical soil sample. |
| Pressuremeter Ground Testing | Measure pressure and deformation as a probe expands against ground. | Constrains in-situ stiffness and response where disturbance is controlled. |
| Rock Joint Shear Testing | Test sliding response of a rock discontinuity under controlled normal loading. | Constrains a tested joint class; untested roughness and scale remain uncertain. |
| Seismic Refraction Surveys | Interpret first-arrival travel times from controlled surface sources. | Constrains suitable velocity boundaries while hidden layers may remain unresolved. |
| Seismic Reflection Profiling | Image subsurface reflectors from timed returning seismic energy. | Suggests interface geometry with resolution and interpretation limits. |
| Surface Wave Ground Characterization | Infer near-surface velocity structure from surface-wave dispersion. | Estimates a family of ground profiles rather than a uniquely known subsurface. |
| Electrical Resistivity Tomography | Invert multiple electrode configurations into a constrained resistivity section. | Maps possible electrical structure while nonuniqueness and poor contact limit resolution. |
| Induced Polarization Surveys | Observe delayed or frequency-dependent polarization after electrical excitation. | Adds chargeability evidence without equating every anomaly with valuable mineralization. |
| Ground Penetrating Radar Surveys | Trace shallow electromagnetic reflections along surveyed ground paths. | Resolves some buried contrasts; conductive ground can erase useful penetration. |
| Transient Electromagnetic Soundings | Interpret the decay of induced subsurface currents after transmitter switch-off. | Constrains conductive structure within a bounded footprint and depth sensitivity. |
| Regional Grade Tonnage Models | Use comparable deposit populations to describe regional grade and size distributions. | Supports uncertain regional assessment without creating a discovered mine or reserve. |
| Acid Rock Drainage Characterization | Evaluate rock-water reactions and observed drainage chemistry. | Identifies possible acidic or metal-bearing drainage and follow-up needs. |
| Geophysical Joint Interpretation | Compare independent geophysical observations against a shared geological interpretation. | Rejects some inconsistent models while shared biases and ambiguity remain. |
| Geochemical Background Models | Estimate context-dependent background before flagging chemical anomalies. | Reduces false anomaly claims without labeling all elevated concentrations harmless. |

## Evidence and game-design status

The entry records link direct USGS research/method sources and FHWA ground-investigation references. Source descriptions support the physical distinctions; prerequisite selection, horizon allocation, recovery costs and simulation consequences are original game-design proposals, not historical invention dates, engineering standards or resource/reserve certification. Each entry has five paid recovery routes with local demonstration and no instant mastery.

The USGS stream-sediment and copper-exploration research supports reconnaissance methods. USGS borehole logging tables, instrument pages and actual borehole-image study support modality-specific measurements. FHWA site-characterization references support direct ground tests and sample recovery. USGS surface-geophysics and hydrogeophysics publications support field methods and their interpretation limits. USGS deposit-population and drainage research supports the regional model and environmental-characterization distinctions. No new legal classification or financial reserve claim is introduced.

## Acceptance and remaining work

31 identities are new; all original catalog identities are preserved. All new mandatory parents and alternative groups resolve, with no unreachable drafts or normalized-name duplicates. All15 existing catalog-tool tests pass. The field D22 authored/implemented total increases from76 to107 of its160 target. Total catalog identities become3,213:716 integrated plus2,497 drafts, leaving1,787 to author and4,284 to implement. Historical horizons are explicit editorial mappings and never calendar gates.

These31 are authored scope only. There are no new deposits, extraction systems, instruments, survey UI, population changes or save fields. The verified runtime remains716 discoveries /498 routes /365 recipes /18 facilities. Full historical pacing and operational implementation remain required. Logs: `/tmp/tt-geology-coverage.log`, `/tmp/tt-geology-ledger-tests.log`.
