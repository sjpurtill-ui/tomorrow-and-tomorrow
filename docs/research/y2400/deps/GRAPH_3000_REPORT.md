# Research dependency graph report, years 2400–3000

Source: `graph_3000.json`, merged from the three dependency partials (`partials/kicl.json`, `partials/pils.json`, `partials/nhde.json`) plus the registry's six gap rows by `tools/research/merge_graph_3000.py`. Node attributes (line, name, years, band, research time, key threshold) come from `../registry_3000.json`. Edges run prerequisite → dependent. A parent may be an id of any earlier block: 0–600 (`docs/research/deps/graph.json`, plus the items the game adopted into its 0–600 block), 600–1200 (`y600/deps/graph_1200.json`), 1200–1800 (`y1200/deps/graph_1800.json`) or 1800–2400 (`y1800/deps/graph_2400.json`). The node format is the one `tools/research/build_research_block.py` reads, the same as `graph_2400.json`. This is the last block: game 3000 is AD 2030, the end of the game.

Rebuild: `python tools/research/merge_graph_3000.py` (add `--stats` to print the figures in this report). The baked blocks are read from `origin/codex/research-1200`; `--game-dir <game worktree>` reads them from a local game checkout instead. A baked block that is not on the game ref yet is reported as pending, and its design-graph years are used.

## Totals

- **Items:** 1,575, every registry id exactly once. No partial row has an unknown id.
  - kicl (knowledge, institutions, culture, labor): 448 from the partial, plus 5 gap rows.
  - pils (production, infrastructure, logistics, security): 646 from the partial, plus 1 gap row.
  - nhde (nutrition, health, demography, ecology): 475.
- **Edges:** 4,928.
  - Hard `requires_all`: 2,859.
  - `requires_any`: 57 members in 28 groups.
  - Precedents: 2,012.
- **Cross-line edges:** hard 891, any 26, precedent 630.
- **Cross-block edges (the parent is an earlier-block id):** 1,402. By block: 134 to 0–600, 76 to 600–1200, 107 to 1200–1800 and 1,085 to 1800–2400. By kind: hard 757, any 36, precedent 609. 239 items have hard parents only in earlier blocks.
- **Items with no requirement:** 0.
- **Key thresholds:** 274.
- **Conditions normalized.** Every `resources_known` and `environment` value is a list, and `contact_required` is a boolean on every node.
  - `resources_known` (32 items): Crude Oil ×5, Coal ×4, Uranium Ore ×4, Sulfur ×3, Iron Ore ×3, Lead Ore ×2, Tin Ore ×2, Salt ×2, Limestone ×2, Bauxite ×2, Fine Sand ×2, Graphite, Nickel Ore, Clay, Bitumen.
  - `environment`, any-of (39 items): coast 31, river 7, dry 2.
  - `contact_required` true: 12.
  - No other condition keys and no unmapped resources.

## Validation

The merge tool exits without writing anything when a check fails. Every check below passes. The baked-block check ran with `--game-dir C:/Users/sjpur/tt-research-1200` (the 0–600, 600–1200 and 1200–1800 blocks). `blocks/y1800_2400.json` was not baked yet, so its 1,139 ids were checked against `graph_2400.json` years only; see *Open items*.

| check | result |
|---|---|
| every registry id mapped (1,575, including the 6 gap rows); no row for an unknown id; no id mapped twice | pass |
| every referenced id known (this block, 0–600 with the game's adopted items, 600–1200, 1200–1800 or 1800–2400) | pass: 0 unknown |
| no id defined in two blocks, except recorded redates | pass: `registry_3000` and `registry_2400` have no redates; the 1200–1800 redate of `ocean_sailing` is applied to the prior set |
| design graphs agree with the game's baked blocks (`research_600.json`, `blocks/y600_1200.json`, `blocks/y1200_1800.json`): same ids, same block, same proposed years | pass: 0 missing, 0 extra, 0 year differences (1800–2400 pending its bake) |
| combined 0–3000 graph acyclic over hard/any edges | pass |
| combined 0–3000 graph acyclic over all edges including precedents | pass |
| no `requires_all` parent dated after its dependent (adjusted years; baked years for earlier blocks) | pass: 0 |
| no `requires_any` group entirely later than its dependent | pass: 0 of 28 groups |
| no precedent dated after its dependent | pass: 0 |
| every conditions list is a list (partials and merged nodes) | pass |
| every proposed year inside 2400–3000 | pass |
| every year adjustment names a registry id, matches its current year and stays in its band | pass: 49 |
| every gap row is a registry `rows_added_by_registry` id, and every rewire finds the edge it replaces | pass: 6 rows, 15 rewires |

## Gap rows and rewires

The registry pass placed six discoveries that no line list claimed (`registry_3000.json` `rows_added_by_registry`). The Knowledge and Infrastructure lists carry the rows, so they survive a rebuild. No partial mapped them, so their dependency rows are `GAP_ROWS` in the merge tool. The dependents that had used a stand-in parent are rewired in `REWIRES`. Both are recorded in `graph_3000.json` under `meta.gap_rows` and `meta.rewires`.

| id | line | year (band) | AD | requires_all | precedents |
|---|---|---|---|---|---|
| `rock_oil_well_drilling` | infrastructure (shared: production) | 2555 (2530–2580) | ≈ 1858 | `percussion_drilled_wells` [1200–1800], `high_pressure_steam_engines` | none; needs Crude Oil known |
| `typewriter` | knowledge (shared: labor) | 2600 (2575–2625) | ≈ 1875 | `interchangeable_component_fits` | `sewing_machine_mechanisms`, `metal_type_casting` [1200–1800], `telegraph_keys` |
| `cathode_ray_discharge_tubes` | knowledge (shared: health) | 2603 (2578–2628) | ≈ 1876 | `vacuum_pumps` [1800–2400], `electromagnetic_induction` | `spectroscopy`, `electrochemical_cells` |
| `expanding_universe_cosmology` | knowledge | 2744 (2719–2769) | ≈ 1929 | `spectroscopy`, `relative_spacetime` | `mirror_telescope` [1800–2400], `fixed_light_images` |
| **`stored_program_computer`** | knowledge (shared: production) | 2796 (2761–2831) | ≈ 1948 | `triode_valves`, `binary_adders`, `relay_registers`, `computability_theory` | `punched_card_tabulation` |
| **`recombinant_dna`** | knowledge (shared: health, nutrition) | 2858 (2823–2893) | ≈ 1973 | `hereditary_double_helix`, `enzyme_catalysis`, `microbial_isolation_methods` | `cell_culture_methods` |

The computer is placed in Knowledge rather than Production because Production's 2750–2800 bin is already flagged for load and Knowledge's is not. A progressive income tax was checked and not added: the 1800–2400 row `graduated_income_tax` (institutions 2398, `[gov: law]`) already covers it.

Rewires:

- `numerical_weather_prediction` (ecology 2801): `binary_adders` → **`stored_program_computer`** in `requires_all`. `binary_adders` is kept as a precedent.
- `transgenic_crops` (nutrition 2915) and `precision_fermented_proteins` (nutrition 2975): `recombinant_vaccine` → **`recombinant_dna`** in `requires_all`. The fermented proteins keep the vaccine as a precedent.
- `bone_shadow_imaging` (health 2653): `electromagnetic_induction` → **`cathode_ray_discharge_tubes`** in `requires_all`.
- New hard parents: `recombinant_vaccine` and `engineered_microbe_chemicals` ← `recombinant_dna`; `electron_physics` ← `cathode_ray_discharge_tubes`; `crude_oil_pipelines` ← `rock_oil_well_drilling`.
- New precedents: `fuel_refining` ← `rock_oil_well_drilling`; `women_office_clerks` and `teleprinter_mechanisms` ← `typewriter`; `formula_programming_languages` and `stored_program_control` ← `stored_program_computer`.

## Year adjustments

There are 49 moves, all inside their bands. They are written to `year_adjustments_3000.json`, where the build tool finds them automatically.

- **kicl (1):** `automation_retraining` 2830 → **2835**, after its parent `industrial_robots`.
- **pils (33):**
  - The machine-shop chain of 2540–2600 is reordered so each tool follows the one it needs. Examples: `lead_screw_cutting` 2549 → 2540, `toolbit_heat_treatment` 2600 → 2575, `horizontal_milling_machines` 2570 → 2592.
  - `structural_steel` 2632 → 2625.
  - The lead-acid pair: `porous_battery_separators` 2671 → 2646 and `lead_acid_cells` 2622 → 2647.
  - The drill-jig, polymer and electronics steps.
  - **`industrial_robots` 2834 → 2829**, after `electronic_machine_control` (2824) and in the same year as `hardwired_sequence_control` (2829).
- **nhde (15):** small moves of 3–10 years, so that nutrition, health and demography items follow their catalog gates. Examples: `soil_assays` 2507 → 2500, `ammonium_sulfate_fertilizer` 2701 → 2711, the three food-package tests 2822 → 2826–2829, `residual_house_spraying` 2787 → 2790.

These moves resolve the registry's backward predecessor `automation_retraining` → `industrial_robots` (2829 < 2835). The registry's other backward note, `scheduled_river_steamers` (2419) continuing `steam_propulsion` (2452), is not an edge in the partials.

## Same-year hard edges

26 `requires_all` edges join two items with the same proposed year. All are kept as hard edges, and `DEMOTE` is empty. The build tool rejects only a parent with a **later** year, and the loader opens a dependent once its parents are known and its `min_year` (band_low) has come. Most of these edges are catalog clusters:

- the compound microscope and its four parts at 2480;
- the electron trio at 2659;
- error codes, framing and repeat requests at 2825.

The pils moves add one more: `industrial_robots` ← `hardwired_sequence_control` at 2829.

## Cross-line matrix (hard + any; row = prerequisite line, column = dependent line; includes earlier-block parents)

| from \ to | KNO | INS | CUL | LAB | PRO | INF | NUT | HEA | DEM | LOG | ECO | SEC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| KNO | 218 | 7 | 39 | 15 | 164 | 25 | 37 | 30 | 7 | 18 | 30 | 25 |
| INS | 2 | 146 | 6 | 20 | · | · | 4 | 3 | 10 | · | 4 | 9 |
| CUL | 1 | 5 | 93 | · | · | · | · | · | · | · | · | 1 |
| LAB | · | 6 | 2 | 118 | · | · | 1 | 2 | 2 | 1 | · | · |
| PRO | 29 | 1 | 7 | 5 | 435 | 65 | 27 | 12 | 1 | 51 | 11 | 34 |
| INF | 1 | · | 2 | · | 37 | 133 | 6 | 3 | 1 | 16 | 1 | 4 |
| NUT | 1 | · | 1 | · | 2 | · | 136 | 4 | 2 | · | 2 | · |
| HEA | · | 2 | · | 1 | · | 3 | 2 | 159 | 15 | · | 1 | 1 |
| DEM | · | 4 | · | 1 | · | · | · | 7 | 105 | · | · | · |
| LOG | 1 | · | 4 | 4 | 6 | 1 | 7 | 2 | 2 | 146 | 3 | 10 |
| ECO | 2 | · | 1 | · | 2 | 4 | 12 | · | 1 | · | 148 | 1 |
| SEC | · | 2 | · | 1 | · | · | 1 | · | 3 | 6 | 2 | 162 |

## Weapons of mass destruction

The research items below make a weapon **known**. They do not make it **usable**. A general never uses them on his own authority. Their use is the ruler's explicit, spoken decision in the Court. The game enforces this at use time, not at research time (see *Bake-time fixes*, item 2). The graph records the class on each node as `use_authority`, and lists it under `meta.use_authority`.

| id | class | year (band) | requires_all | dependents in this block |
|---|---|---|---|---|
| `chemical_gas_warfare` | sovereign | 2708 (2668–2748) | `chloralkali_cells`, `continuous_trench_systems` | `gas_germ_weapon_ban` (precedent) |
| `fission_weapon` | sovereign | 2787 (2757–2817) | `nuclear_fission`, `reactor_engineering` | `thermonuclear_weapon`, `fallout_monitoring` (hard); `nuclear_civil_defence` (precedent) |
| `thermonuclear_weapon` | sovereign | 2805 (2775–2835) | `fission_weapon` | `intercontinental_missiles`, `deterrence_doctrine` (hard); `nuclear_test_ban_treaties` (precedent) |
| `intercontinental_missiles` | sovereign | 2818 (2788–2848) | `ballistic_rocket_bombardment`, `thermonuclear_weapon` | `missile_submarine_patrols` (hard); `deterrence_doctrine`, `launch_warning_satellites`, `hypersonic_glide_vehicles` (precedent) |
| `missile_submarine_patrols` | sovereign | 2826 (2786–2866) | `nuclear_propulsion`, `intercontinental_missiles` | none |
| `hypersonic_glide_vehicles` | sovereign | 2972 (2932–3000) | `ballistic_rocket_bombardment`, `computer_aided_design` | none |
| `aerial_bombardment` | restricted (cities) | 2696 (2656–2736) | `powered_flight`, `powder_artillery` | `independent_air_arm`, `civil_air_defence` (hard) |
| `armed_remote_strike` | restricted | 2930 (2890–2970) | `remote_aircraft`, `satellite_guided_strike` | `machine_assisted_targeting` (precedent) |
| `machine_assisted_targeting` | human sign-off | 2990 (2950–3000) | `deep_learning_networks`, `learned_machine_law` | none |

- **Sovereign.** A general may not employ the weapon in any operation, whatever his standing orders, ambition or desperation. Only a ruler's decision spoken in the Court authorises it. The decision names the weapon and the war, and it is recorded, so the people and other realms remember it. Without that decision, a general who has the weapon in his arsenal fights with conventional means.
- **Restricted.** Bombardment from the air and armed remote strikes may be used against armies, fleets and works in the field. Striking a **city** (population centres, not their garrisons) needs the same sovereign decision.
- **Human sign-off.** Machine-assisted targeting may only propose targets. A named commander must approve each strike, and it never widens the general's own authority.
- **Research is unaffected.** No non-weapon item depends on a sovereign weapon except `fallout_monitoring` (hard, on `fission_weapon`) and `deterrence_doctrine` (hard, on `thermonuclear_weapon`). Treaties, civil defence and warning satellites list them only as precedents. Knowing the bomb opens the deterrence doctrine; it does not put the bomb in a general's hands.
- **No victory.** None of these items ends the game or grants any win state.

## Pacing

- **Impossible (critical-path earliest year > band_high): 0.** Hard links alone make every item reachable by year 529 counted from year 0. The median critical path is 13% of band_low. Items stay in the window because the loader applies `min_year = band_low`, together with research throughput and conditions.
- **Load per line.** Load is summed `research_years` divided by the 600-year window. A load of 1.0 is one staffed team working without a break for the whole window.

  | line | items | research years | load | late (local serial) | last local serial finish |
  |---|---:|---:|---:|---:|---:|
  | knowledge | 143 | 1,047 | 1.75 | 135 | 3469 |
  | institutions | 100 | 716 | 1.19 | 89 | 3469 |
  | culture | 100 | 560 | 0.93 | 87 | 3471 |
  | labor | 110 | 453 | 0.76 | 88 | 3467 |
  | production | 278 | 884 | 1.47 | 262 | 3454 |
  | infrastructure | 111 | 513 | 0.85 | 95 | 3610 |
  | nutrition | 124 | 811 | 1.35 | 111 | 3537 |
  | health | 126 | 1,053 | 1.75 | 107 | 3577 |
  | demography | 100 | 603 | 1.00 | 82 | 3602 |
  | logistics | 128 | 1,046 | 1.74 | 110 | 3653 |
  | ecology | 125 | 851 | 1.42 | 106 | 3644 |
  | security | 130 | 1,105 | 1.84 | 113 | 3614 |

  Eight of twelve lines exceed one team's worth of research in the window. Security (1.84), knowledge and health (1.75) and logistics (1.74) are the heaviest; labor (0.76) and infrastructure (0.85) the lightest. The gap rows add 39 research years to knowledge (+0.07) and 5 to infrastructure (+0.01).
- **Serial model.** In the serial model, each line works on one project at a time from 2400, in proposed-year order, and waits for cross-line parents.
  - **Local.** Earlier-block parents count as known at their proposed year. 1,385 of 1,575 items still finish after band_high, and the last items finish around 3450–3650.
  - **Inherited.** Earlier-block parents keep the 1800–2400 graph's own serial finishes, which already run to about 3340. With those, 1,573 items are late, and the last finishes run to 4500. This is the same queue pressure that `GRAPH_2400_REPORT.md` reported.
  - **What it means.** If the engine researches one project per line at a time, this block needs roughly half its `research_years`, or two parallel projects per line. Each node carries `serial_line_finish_year` (inherited) and `serial_overrun`.

## Longest dependency chains (hard links, counted from year 0)

The deepest items are 55 links deep, with an earliest feasible year of about 525. They run along the writing trunk (fibre grading → tablets → alphabets → natural philosophy → scholastic method → experimental science). The chain then follows electricity (`friction_electric_machine` → `charge_storing_jar` → `electrochemical_cells` → … → `electron_physics` → `quantum_mechanics` → `pn_junctions`) and computing (transistors → registers → `stored_program_control` → `single_chip_processors` → `desk_computers` → `world_hypertext_web` → `cloud_data_halls` → `deep_learning_networks` → `large_language_models`). It ends at `learned_machine_law` → **`algorithmic_decision_audits`** and **`machine_assisted_targeting`**. The new `cathode_ray_discharge_tubes` sits on this spine, between `electromagnetic_induction` and `electron_physics`, but it does not lengthen it: induction → discharge tubes → electron is as long as induction → wave theory → electron.

## Spot checks used by the game tests

- **`stored_program_computer`.** Knowledge 2796, band 2761–2831 (min_year 2761). It is locked before its window.
- **`fission_weapon`.** Security 2787. Requires `nuclear_fission` (knowledge 2768) and `reactor_engineering`. Sovereign use.
- **`numerical_weather_prediction`.** Ecology 2801. Requires `state_weather_service` and `stored_program_computer`.
- **`industrial_robots` 2829 → `automation_retraining` 2835.**
- **Cross-block parents.** `rock_oil_well_drilling` ← `percussion_drilled_wells` (1200–1800); `cathode_ray_discharge_tubes` ← `vacuum_pumps` (1800–2400).

## Bake-time fixes

1. **`portland_cement_clinker`.** This catalog id (main `building_material_knowledge.gd`) carries a real place name. Its display name is already generic ("Hydraulic cement: clinker burned hot from lime and clay"). Record it for a later rename (for example `hydraulic_cement_clinker`) with its gates, and do not break code that references it now.
2. **Sovereign-use gate.** Generals must not use `chemical_gas_warfare`, `fission_weapon`, `thermonuclear_weapon`, `intercontinental_missiles`, `missile_submarine_patrols` or `hypersonic_glide_vehicles` without the ruler's spoken decision. They must not bomb cities with `aerial_bombardment` or `armed_remote_strike` without it either. `machine_assisted_targeting` needs human sign-off. Enforce this where generals choose weapons and tactics, not in the research tree.
3. **`orbital_satellite_launch`.** The registry added it for spaceflight. The five satellite items require or follow it here.

## Open items

- **1800–2400 bake pending.** Re-run `merge_graph_3000.py --game-dir <game worktree>` once `blocks/y1800_2400.json` is baked, to confirm that its ids and years agree with `graph_2400.json`.
- **Queue pressure.** See *Pacing*: eight lines have a load above 1.0, and the local serial model leaves 1,385 items late.
- **Bands outside the window.** 55 bands reach outside 2400–3000, by up to 37 years. Every proposed year is inside.
- **`read_write_memory` after the computer.** The catalog's addressable memory (2806) follows the first stored-program computer (2796). The early machines had their own stores, so the computer does not require it.
