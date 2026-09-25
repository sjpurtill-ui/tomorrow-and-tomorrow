# Phase 2, years 1800–2400: Knowledge, Institutions, Culture effects

The files are `data/research/effects_y1800_2400/{knowledge,institutions,culture}.json`. They follow the Phase 2 schema in `IMPLEMENTATION_600.md`. The window runs from about AD 1360 to AD 1800: printing with cast type, the new mathematics and astronomy, experiment and learned societies, the fiscal-military and court states, and the constitutional and rights documents that close the window.

## Counts

| Line | Block items | Filled | NEW | Catalog | Key thresholds (with ability_reason) | social_consequence | Short names |
|---|---:|---:|---:|---:|---:|---:|---:|
| knowledge | 110 | 110 | 65 | 45 | 27 | 18 | 109 |
| institutions | 104 | 104 | 104 | 0 | 20 | 26 | 104 |
| culture | 98 | 98 | 98 | 0 | 15 | 9 | 98 |

Every row has these fields:
- `effects`, using only names registered in `SocietyModel.EFFECT_LIMITS`
- `art`, an existing subject, discovery or paper painting. No row falls back to the line default.
- a one-line in-world `observation`, with no real names

**Value ranges.**

| Line | Routine items | Key thresholds |
|---|---|---|
| knowledge | .0005–.008 | up to .0134 (`pendulum_regulated_clock` coordination) |
| institutions | up to .0037 | up to .0078 (`separation_of_powers` rigidity −) |
| culture | up to .004 | up to .0045 |

These match the per-row scale of 1200–1800.

**Catalog overrides.**
- `experimental_controls` had modern-scale effects: knowledge .15, observation .16 and standardization .05. They are replaced with era-scale values: observation .0044, knowledge .0035, standardization .0023, health protection .0013 and rigidity −.002.
- `graphite_marking` had knowledge .10, state .06 and standardization .04. They are replaced with craft, standardization and knowledge at about .001–.002. Its `resource_requirements` (Graphite) are kept.
- The other 43 catalog ids had empty effects, and they are now filled.
- Authored `production_items` were not touched.

## Method

The generator is in the session scratchpad (`kicE2400/rows_*.py`, `build.py`) and is not committed. It is the 1200–1800 generator with one addition, a clamp scale.
1. Relative magnitudes are authored per item in thousandths.
2. The same line units are used: knowledge 1.0, institutions 0.7, culture 0.5. Key thresholds in institutions and culture get ×1.6.
3. For each main beneficial key, this block's addition to the line is set to the previous block's addition × 1.4 × a clamp scale. The clamp scale comes from the **all-line** raw total at 1800, taken over all twelve lines and all three earlier blocks:

   | Share of the key's clamp at 1800 | Clamp scale |
   |---|---:|
   | ≥ 120% | 0.40 |
   | 100–120% | 0.55 |
   | 85–100% | 0.60 |
   | 80–85% | 0.65 |
   | < 80% | 1.0 |

   Negative values on a benefit key are never amplified.
4. Costs keep the line unit. Positive `labor_demand` is ×0.6 and positive `institutional_rigidity` is ×0.5, because both are already far past their clamps.

## Keys scaled down because they are near or past their clamp

All-line raw totals are shown at 1800, then with this block's three lines added. The other nine lines are still unfilled for this block.

| Key | All lines at 1800 | Clamp | Share | Scale | This block (K+I+C) | After |
|---|---:|---:|---:|---:|---:|---:|
| labor_demand (cost) | 2.655 | .35 | 759% | ×0.6 cost | +.059 | 2.714 |
| institutional_rigidity (net) | .988 | .55 | 180% | ×0.5 cost | **−.112** | .876 |
| legitimacy | .840 | .55 | 153% | .40 | +.031 | .871 |
| state_capacity | 1.187 | .90 | 132% | .40 | +.085 | 1.272 |
| knowledge_preservation | 1.071 | .85 | 126% | .40 | +.113 | 1.185 |
| trade_capacity | 1.178 | 1.0 | 118% | .55 | +.080 | 1.258 |
| security_efficiency | .900 | .80 | 113% | .55 | +.040 | .940 |
| standardization | .880 | .80 | 110% | .55 | +.088 | .968 |
| task_coordination | .698 | .65 | 107% | .55 | +.058 | .756 |
| warfare_readiness | 1.066 | 1.0 | 107% | .55 | +.019 | 1.085 |
| cultivation_yield | .913 | .90 | 101% | .55 | +.001 | .913 |
| labor_efficiency | .533 | .55 | 97% | .60 | +.005 | .538 |
| disaster_resilience | .749 | .80 | 94% | .60 | +.005 | .754 |
| cohesion | .511 | .55 | 93% | .60 | +.059 | .570 |
| ecology_recovery | .592 | .65 | 91% | .60 | +.001 | .593 |
| craft_output | .906 | 1.0 | 91% | .60 | +.043 | .949 |
| construction_rate | .874 | 1.0 | 87% | .60 | +.024 | .898 |
| naval_capacity | .778 | .90 | 86% | .60 | +.018 | .796 |
| observation_rate | .641 | .75 | 85% | .60 | +.101 | .742 |
| water_access / logistics_endurance / health_protection | .67 / .59 / .44 | .80 / .70 / .55 | 81–84% | .65 | ≤ +.003 each | — |
| adoption_rate | .668 | .80 | 84% | .65 | +.141 | .810 |
| knowledge_rate | .735 | .90 | 82% | .65 | +.159 | .895 |

What these three lines leave for the other lines:
- **Knowledge rate, observation, adoption and cohesion** are now within about 0–2% of their ceilings. The other nine lines of this block should add almost nothing to them.
- **Legitimacy and rigidity.** Legitimacy grows only +.031, because the reform, satire and revolution rows subtract. Net rigidity *falls* by .112, the first block where it does: estates, charters, rights, separation of powers, press freedom and toleration outweigh codes, venal offices, tribunals and test oaths. Rigidity is still well above its .55 clamp.
- **The rebalance pass.** It should decide whether to raise these ceilings for the early-modern world or to trim the earlier blocks. Several totals are past their clamps even at full adoption.

## Totals per sub-dimension

"Start" is the line's cumulative total from 0–1800. "Prev block" is what 1200–1800 added. "+2100" and "+2400" are this block's cumulative additions from items with `proposed_year` ≤ 2100 (mid-window, about AD 1650) and ≤ 2400. "× prev" is +2400 ÷ prev block.

**Knowledge**

| Effect | Start | Prev block | +2100 | +2400 | × prev |
|---|---:|---:|---:|---:|---:|
| knowledge_rate | .513 | .155 | .070 | .141 | 0.91 |
| adoption_rate | .411 | .125 | .075 | .114 | 0.91 |
| observation_rate | .400 | .120 | .048 | .100 | 0.84 |
| survey_speed | .442 | .081 | .063 | .085 | 1.05 |
| knowledge_preservation | .433 | .130 | .045 | .073 | 0.56 |
| standardization | .274 | .080 | .036 | .061 | 0.77 |
| trade_capacity | .196 | .058 | .035 | .045 | 0.78 |
| task_coordination | .143 | .045 | .016 | .035 | 0.77 |
| craft_output | .120 | .040 | .019 | .034 | 0.85 |
| state_capacity | .168 | .048 | .012 | .026 | 0.54 |
| route_speed / construction_rate | .137 / .142 | .028 / .018 | .009 / .004 | .021 / .018 | 0.73 / 1.00 |
| chemical_control / naval_capacity | .008 / .007 | .008 / .003 | 0 / .008 | .015 / .014 | — |
| labor_demand (cost) | .348 | .073 | .021 | .034 | 0.47 |
| legitimacy (net) | .030 | .011 | −.012 | −.022 | — |
| institutional_rigidity (net) | .028 | .007 | −.012 | −.024 | — |
| timber / fuel / health_risk / pollution / fatigue / injury (costs) | — | — | — | .004 / .002 / .002 / .001 / .001 / .001 | — |

**Institutions**

| Effect | Start | Prev block | +2100 | +2400 | × prev |
|---|---:|---:|---:|---:|---:|
| state_capacity | .383 | .102 | .029 | .059 | 0.58 |
| security_efficiency | .145 | .045 | .028 | .035 | 0.77 |
| legitimacy (net) | .363 | .102 | .005 | .034 | 0.34 |
| trade_capacity | .072 | .043 | .021 | .031 | 0.72 |
| standardization | .056 | .031 | .010 | .024 | 0.77 |
| task_coordination | .099 | .030 | .012 | .023 | 0.76 |
| warfare_readiness | .057 | .021 | .006 | .013 | 0.62 |
| knowledge_preservation | .044 | .020 | .008 | .010 | 0.52 |
| cohesion (net) | .051 | .053 | −.004 | .005 | 0.10 |
| labor_demand (cost) | .354 | .069 | .013 | .019 | 0.27 |
| institutional_rigidity (net) | .362 | .053 | −.012 | −.068 | — |
| food_storage / injury_risk | .123 / 0 | .008 / 0 | .001 / −.002 | −.002 / −.002 | — |

**Culture**

| Effect | Start | Prev block | +2100 | +2400 | × prev |
|---|---:|---:|---:|---:|---:|
| cohesion | .211 | .067 | .029 | .055 | 0.81 |
| knowledge_preservation | .158 | .050 | .019 | .031 | 0.61 |
| adoption_rate | .069 | .022 | .015 | .022 | 1.00 |
| legitimacy (net) | .189 | .061 | .012 | .019 | 0.31 |
| knowledge_rate | .049 | .015 | .009 | .015 | 0.98 |
| craft_output / warfare_readiness / construction_rate | .040 / .047 / .028 | .008 / .018 / .016 | .004 / .002 / .003 | .006 / .006 / .006 | — |
| institutional_rigidity (net) | .004 | −.002 | −.009 | −.021 | — |
| labor_demand / disease_exposure / injury_risk (costs) | .119 / .030 / .008 | .030 / .006 / .003 | .005 / .003 / .001 | .006 / .004 / .002 | — |

**Growth against the brief's 30–60% target.**
- Keys with room to grow do grow in that range. Survey speed and construction in Knowledge, and adoption and knowledge rate in Culture, are at 1.0–1.05× the previous block.
- Keys near or past their clamps are held to 0.3–0.9×, as the scaling table above sets out. These are the ones the coordinator asked to scale down.
- The low net legitimacy, cohesion and rigidity figures are deliberate. The window's disputes and revolutions both give and take legitimacy and cohesion.

**Pacing and the historical arc.** About half of each line's additions arrive by 2100 (AD 1650), and the rest in 2100–2400, when the historical clock runs at 0.5 years per game year. This matches the benchmarks:
- Literacy is 8% at 1800, 13% at 2100 and 22% at 2400. Printing and primers come early, while schooling, subscription libraries and the encyclopedia come late.
- Institutional reach roughly doubles, and state revenue rises from 4% to 7% of output. State capacity in Institutions is carried by the councils, secretaries, intendants, cadastre, cameral chairs and the income tax.

## Key thresholds

- **Knowledge:**
  - Printing: `screw_press_printing` (adoption .0111), `metal_type_casting`, `town_printing_houses` and `reasoned_trades_encyclopedia` (adoption .0079, preservation .0069, rigidity −.003).
  - Learning and number: `ruler_founded_universities` and `printed_arithmetic_summa` (trade .0089).
  - Maps and perspective: `graticule_world_maps` (survey .0098) and `mirror_grid_perspective`.
  - Sky: `sun_centred_system` (legitimacy −.004), `precision_naked_eye_observatory`, `two_lens_telescope`, `elliptical_planet_orbits` and `universal_gravitation` (knowledge .0061).
  - Algebra, logarithms and the calculus: `polynomial_equations`, `symbolic_algebra`, `logarithms`, `coordinate_geometry` and `differential_calculus`.
  - Experiment: `measured_kinematics`, `inductive_method_program`, `mercury_barometer`, `vacuum_pumps`, `chartered_experimental_society` and `experimental_controls`.
  - Clocks and chemistry: `pendulum_regulated_clock` (coordination .0134) and `oxygen_combustion_theory` (chemical control .008).
  - Measures: `decimal_earth_measures` (standardization .0082).
- **Institutions:**
  - Estates and consent: `two_chamber_estates`, `provincial_union_estates`, `written_frame_of_government`, `realm_bill_of_rights`, `cabinet_first_minister`, `separation_of_powers` (rigidity −.0078), `declaration_of_rights`, `federal_written_constitution` and `single_national_assembly`.
  - Central administration: `specialized_royal_councils`, `secretaries_of_state`, `provincial_intendants`, `cameral_science_chairs` and `grand_palace_court` (legitimacy, but labor and food_storage −).
  - War and diplomacy: `permanent_army_tax` (warfare .0075; generals command a paid standing force, the player does not), `resident_ambassadors` and `sovereign_realms_congress` (warfare −).
  - Law and money: `realm_criminal_code`, `joint_stock_company` (trade .0048, naval .0027) and `chartered_central_bank`.
- **Culture:**
  - Letters: `civic_humanism`, `pilgrim_tale_cycle` and `comic_knight_novel`.
  - Painting: `single_point_perspective_painting`, `oil_glaze_painting` and `painted_vault_cycle`.
  - The rite in dispute: `printed_reform_dispute` (legitimacy −.0045, cohesion −.0034, rigidity −.004) and `vernacular_scripture`.
  - Theatre and music: `public_playhouses` (disease +.0024), `sung_drama_opera` and `four_movement_symphony`.
  - Public life and collections: `coffeehouse_public_talk`, `public_collection_museum`, `fraternal_lodges` and `realm_public_museum`.

No row gives a general any weapon of mass destruction or direct battlefield control. The military-facing rows (`permanent_army_tax`, `war_ministry_bureaus`, `regional_peace_circles`, `two_lens_telescope`, `measured_kinematics`) only change what generals have to work with: readiness, logistics endurance, security and observation.

## Costs and tradeoffs introduced

- **Labor diverted.**
  - Knowledge: the island observatory, universities, the longitude observatory, transit expeditions, the shutter telegraph, compulsory schooling, the encyclopedia and the air pump.
  - Institutions: councils, secretaries, intendants, the war ministry, the senate colleges and the palace court.
  - Culture: the vault, the colossus, opera, national festivals and landscape parks.
- **Rigidity.**
  - These raise it: the orthodoxy tribunal, venal offices, the test oath, press licensing, the council court, the criminal code, the table of ranks, the emergency committee, the academy of the tongue, the royal art academy and graded classes.
  - These lower it: the estates chambers, impeachment, equity, charters, rights, separation of powers, the press lapse and the press statute, toleration, satire, coffee-houses, lodges, the forgery critique and the society for experiment.
- **Social strain (cohesion −).**
  - Institutions: the poll tax, excise, tax farming, the army tax, the orthodoxy tribunal, the test oath, the takeover of the god's house lands, intendants, uniform departments, the cadastre, the emergency committee and the income tax.
  - Culture and knowledge: sorcery panics (cohesion −, injury +), the reform dispute, broadsides, the newspaper, the calendar reform and decimal measures.
- **Legitimacy costs.** The sun-centred system, the new star, the spyglass discoveries, comets, the forgery critique, satire, the ideal commonwealth, the reform dispute, venal offices, the deposition of a tyrant, the estates ruling alone, the social contract and the republic.
- **Material and health costs.**
  - Type metal: health_risk.
  - The press and printing houses: timber_pressure.
  - Copper plates and inks: fuel_demand.
  - Chemistry of airs: pollution and health_risk.
  - The charge jar: injury.
  - Playhouses, opera houses, the riverbank theatre, the floating-world quarter and the grand tour: disease_exposure.
  - Bat-and-ball wagers: injury_risk.
  - The palace court, playhouses and national festivals: food_storage −.
  - Free grain trade: food_storage − and cohesion −.
  - Hand printing: fatigue.
- **Capability given up.**
  - Balance-of-power leagues, perpetual peace and the peace congress lower warfare_readiness.
  - Press licensing lowers adoption.
  - The orthodoxy tribunal lowers knowledge_rate.
  - The god's-house land seizure lowers knowledge_preservation.
  - The bubble law lowers trade.

## Missing recipes (Phase 3 proposals)

No `civilian_industry.gd` recipe is gated on any NEW id in these lines, so no `production_items` or `resource_requirements` were added. The 18 catalog ids with gated recipes keep their authored `production_items`. These are proposals for Phase 3:

- **Printing products.** Printed primers, broadsides, weekly and daily news sheets, printed sky tables and engraved maps, using `Paper`, `Printing Ink` and a type or plate forme. Gates: `printed_alphabet_primers`, `printed_broadsides`, `printed_weekly_news`, `daily_printed_newspaper`, `printed_ephemerides` and `printed_engraved_maps`.
- **Instruments.** A brass quadrant or surveying circle (`instrument_maker_workshops`, `triangulation_survey`). A spyglass and a mirror telescope (`two_lens_telescope`, `mirror_telescope`), using lens glass and brass tube. A glass mercury barometer (`mercury_barometer`). A bead-lens microscope (`animalcule_microscope`). A boxwood slide rule (`logarithmic_slide_rule`).
- **Clocks and machines.** A pendulum clock movement (`pendulum_regulated_clock`) and a geared adding machine (`geared_adding_machine`), sharing inputs with Production.
- **Electricity.** A friction machine (`friction_electric_machine`) and a foil-lined charge jar (`charge_storing_jar`).
- **State paper.** Cadastral map sheets (`cadastral_tax_survey`), share certificates and bank notes (`joint_stock_company`, `chartered_central_bank`), and lottery tickets (`state_lottery_loans`).
- **Culture.** Oil paint from linseed and ground pigment (`oil_glaze_painting`), a cast bronze statue (`freestanding_bronze_statuary`), and a hammer-action keyboard (`hammer_keyboard`), shared with Production.

**Review note.** Several catalog recipes in this block are modern industrial processes. They open at these gates' early-modern dates, which is anachronistic, just as the `chemical_distillation` recipes were in 1200–1800:
- `vacuum_melting_chambers` on `vacuum_pumps`, about AD 1650
- `gently_formed_steel_bars` and `cold_bent_steel_bars` on `stress_strain_relations`
- `alloy_phase_trial_sets` on `precision_thermometry`
- `fracture_loading_frames` on `structural_load_testing`, which uses electric motors and sensor assemblies

Phase 3 should re-gate them onto later ids.

## Validation

- `test_research_blocks.gd`: 7/7 pass.
- `test_research_2400.gd`: 6/6 pass.
- No unregistered or unsupported effect names and no script errors appear in the logs.
- All three JSON files parse. Every key used is in `EFFECT_LIMITS`, and every `art` path exists on disk. Every key threshold has an `ability_reason`.
