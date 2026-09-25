# Research dependency graph report, years 1200–1800

Source: `graph_1800.json`, merged from the three dependency partials (`partials/kicl.json`, `partials/pils.json`, `partials/nhde.json`) by `tools/research/merge_graph_1800.py`. Node attributes (line, name, years, band, research time, key threshold) come from `../registry_1800.json`. Edges run prerequisite → dependent. A parent may be a 0–600 id (`docs/research/deps/graph.json`, plus the items the game adopted into its 0–600 block) or a 600–1200 id (`docs/research/y600/deps/graph_1200.json`). The node format is the one `tools/research/build_research_block.py` reads, the same as `graph_1200.json`.

Rebuild: `python tools/research/merge_graph_1800.py` (add `--stats` to print the figures in this report).

## Totals

- **Items:** 937. Every registry id appears exactly once across the partials, and no partial row has an unknown id.
  - kicl (knowledge, institutions, culture, labor): 342.
  - pils (production, infrastructure, logistics, security): 309.
  - nhde (nutrition, health, demography, ecology): 286.
- **Edges:** 3,555.
  - Hard `requires_all`: 1,671.
  - `requires_any` members: 18, in 9 groups.
  - Precedents: 1,866.
- **Cross-line edges:** hard 372, any 6, precedent 652.
- **Cross-block edges (the parent is an earlier-block id):** 1,999. By block: 606 to 0–600 and 1,393 to 600–1200. By kind: hard 999, any 8, precedent 992. 418 items have hard or any parents only in earlier blocks.
- **Items with no requirement:** 0.
- **Key thresholds:** 159.
- **Conditions normalized.** Every `resources_known` and `environment` value is a list (the partials already used lists; the merge coerces a bare string if one appears). `contact_required` is a boolean on every node.
  - `resources_known` (14 items): Salt ×7, Tin Ore ×2, Lead Ore ×2, Coal, Silver Ore, Bitumen.
  - `environment`, any-of (55 items): river 20, coast 19, woodland 10, dry 10.
  - `contact_required` true: 36.
  - No other condition keys and no unmapped resources.

## Validation

The merge tool exits without writing anything when a check fails. Every check below passes.

| check | result |
|---|---|
| every referenced id known (this block, the 0–600 graph and the game's adopted 0–600 items, or the 600–1200 graph) | pass: 0 unknown |
| no id defined in two blocks, except recorded redates | pass (one redate: `ocean_sailing`, see below) |
| design graphs agree with the game's baked blocks on `origin/codex/research-1200` (`research_600.json`, `blocks/y600_1200.json`): same ids, same block, same proposed years | pass; the only baked id outside the design is the redated `ocean_sailing` |
| combined 0–1800 graph acyclic over hard/any edges | pass |
| combined 0–1800 graph acyclic over all edges including precedents | pass |
| no `requires_all` parent dated after its dependent (adjusted years; baked years for earlier blocks) | pass: 0 |
| no `requires_any` group entirely later than its dependent | pass: 0 |
| no precedent dated after its dependent | pass: 0 |
| every conditions list is a list (partials and merged nodes) | pass |
| every proposed year inside 1200–1800 | pass |
| no earlier-block item references a redated id | pass |

**Same-year hard pairs:** none. Nothing needed demoting, so `DEMOTE` is empty.

## Year adjustments

One move, recorded in `year_adjustments_1800.json` next to the graph, where `build_research_block.py` finds it. The graph already carries it as `proposed_year`, so the build re-applies it idempotently.

| id | line | year | reason |
|---|---|---|---|
| `great_domed_temple` | culture | 1283 → 1287 | The great domed house stands on pendentives; `pendentive_domes` (infrastructure 1285) must precede it. Inside the band 1238–1328. |

The build shifts the band by the same +4, to 1242–1332. The pils and nhde partials had no adjustments.

## Redate: `ocean_sailing`

`registry_1800.json` places `ocean_sailing` at security 1692 (band 1662–1722). The game's 0–600 block adopts it at 560 through `tools/research/design_amendments_600.json` on `codex/research-1200`, where it gates sailing-warship and convoy equipment. The merge drops the adoption from the prior set, confirms that no 0–600 or 600–1200 item references it, and reports it as a baked placement to remove. The game bake must remove the adoption and rebuild the 0–600 block before building 1200–1800, or the build rejects the id as already defined.

Here it requires `open_sea_cargo_ships` and `floating_needle_compass`, with precedents `land_finding_signs`, `pole_star_latitude_tablet`, `seasonal_wind_crossings` and `sternpost_rudder`.

## Cross-line matrix (hard + any; row = prerequisite line, column = dependent line; includes earlier-block parents)

| from \ to | KNO | INS | CUL | LAB | PRO | INF | NUT | HEA | DEM | LOG | ECO | SEC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| KNO | 141 | 8 | 15 | 2 | 2 | 1 | 2 | 9 | 1 | 2 | 4 | 2 |
| INS | 1 | 154 | 13 | 19 | · | · | 5 | 6 | 20 | 6 | 2 | 4 |
| CUL | 3 | 3 | 106 | 4 | · | · | · | 2 | 6 | · | 1 | · |
| LAB | · | 1 | 1 | 111 | · | · | 1 | · | 7 | · | 2 | 1 |
| PRO | 14 | · | 8 | 11 | 130 | 8 | 4 | 4 | · | 9 | 9 | 9 |
| INF | · | · | 7 | 1 | 4 | 98 | 3 | 1 | 1 | 3 | 5 | 10 |
| NUT | · | · | · | 2 | 4 | · | 101 | 5 | 2 | 1 | 13 | · |
| HEA | · | · | 2 | 1 | · | 1 | · | 101 | 4 | · | 2 | · |
| DEM | · | 5 | 1 | 5 | · | · | · | 1 | 84 | · | 1 | 2 |
| LOG | 3 | 3 | · | 4 | 3 | 3 | 7 | 1 | 1 | 96 | · | 9 |
| ECO | 1 | · | · | 1 | · | · | 9 | 1 | · | · | 95 | 3 |
| SEC | 1 | 2 | 2 | 1 | · | · | · | 1 | 2 | 1 | · | 94 |

## Pacing

- **Impossible (critical-path earliest year > band_high): 0.**
- **Gates do not hold the era back.** Hard and any links alone make every item reachable long before 1200: the critical path from year 0 has a median of 9% of band_low, and the deepest item is reachable by year 329. Items stay in the 1200–1800 window because the loader applies `min_year = band_low`, together with research throughput and conditions.
- **Queue pressure is worse than in 600–1200.** Total `research_years` per line exceeds the 600-year window in 7 lines:

  | line | research years |
  |---|---:|
  | institutions | 871 |
  | knowledge | 806 |
  | security | 702 |
  | production | 665 |
  | culture | 615 |
  | logistics | 608 |
  | labor | 584 |
  | infrastructure | 560 |
  | health | 554 |
  | ecology | 519 |
  | demography | 516 |
  | nutrition | 499 |

  In the serial model (one project per line from 1200, proposed-year order, waiting on cross-line prerequisites), 753 of 937 items finish after band_high. Late items per line: institutions 91, labor 86, knowledge 84, culture 80, security 76, health 72, demography 68, infrastructure 66, ecology 61, logistics 50, production 18, nutrition 1. The last serial finishes are institutions 2291, labor 2272 and demography 2247. The worst overruns are about 460 years:

  | item | serial finish | band_high |
  |---|---:|---:|
  | `keepers_of_the_peace` | 2276 | 1811 |
  | `scrutiny_lot_elections` | 2268 | 1809 |
  | `double_entry_ledgers` | 2260 | 1805 |
  | `rank_sumptuary_laws` | 2250 | 1800 |
  | `elector_college_charter` | 2291 | 1842 |
  | `fixed_court_of_accounts` | 2244 | 1797 |

  The 600–1200 block had 597 overruns. If the engine researches one project per line at a time, this block needs shorter `research_years` or parallel projects. Each node carries `serial_line_finish_year` and `serial_overrun`.

## Longest dependency chains (hard/any links, counted from year 0)

All of the deepest items (30 links) sit on the institutions trunk that 600–1200 ended with: writing → alphabet → natural philosophy → `written_office_examinations` → `professional_service` → `petition_registers` → `compiled_rescript_code` → `promulgated_edict_code` → `numbered_article_decrees` → `sealed_royal_writs`, then either

1. → `royal_justice_circuits` → `presenting_jury_of_neighbours` → `ordeal_abolition` → **`petty_trial_jury`** / **`inquisitorial_written_procedure`**, or
2. → `royal_chancery_office` → `chancery_enrolment_rolls` → `fixed_capital_archives` → **`fixed_court_of_accounts`** / **`sworn_royal_council`** / **`permanent_high_court`** (earliest feasible 328.5).

A civilization that stalls on the written-law trunk loses most of the late institutions line.

## Spot checks used by the game tests

- **`printing_process`.** Proposed 1360, band 1315–1405. Requires `relief_block_cutting` and `paper_making`.
- **`blast_furnace`.** Proposed 1772, band 1732–1812. Requires `water_driven_bellows`, `water_blown_stack_bloomery` and `liquid_iron_furnaces`.
- **`black_powder`.** Proposed 1787, band 1757–1817, chemistry only. Requires `nitre_incendiary_mixtures`, `sulfur_purification`, `charcoal`, and one of `nitre_earth_leaching` / `nitrate_cultivation`.
- **`ocean_sailing`.** Proposed 1692 (redate from the game's 560).

## Bake-time fixes (from `REGISTRY_1800_NOTES.md`)

1. **`ocean_sailing`.** Remove the 0–600 adoption at the source (`design_amendments_600.json`), rebuild 0–600, and let its equipment gates move with it to 1692.
2. **Gunpowder gate.** `hand_cannon` equipment and the `hand_cannoneer` unit are gated on `black_powder`. Re-gate both on `powder_artillery` so generals get no guns in this window.
3. **`powder_artillery` requirements** (open for the 1800–2400 block). The catalog requires `black_powder`, `precision_machinery` (≈ 2370) and `military_staffs` (≈ 2200–2300), so it cannot open near its ≈ 1880–1920 target. The 1800–2400 dependency pass must drop or replace those two requirements.

## Bake outcome on `codex/research-1200`

- **`ocean_sailing`.** The adoption row is gone from `design_amendments_600.json`, so the rebuilt 0–600 block has 1,122 items (21 adopted). Its effect row moved from `data/research/effects/security.json` to `data/research/effects_y1200_1800/security.json` unchanged; the effects pass should re-scale it for 1692. Sailing-warship and convoy equipment still key on `ocean_sailing`, so they now open at 1662 (its band_low).
- **Hand cannons.** `hand_cannoneer`, `EQUIPMENT_GATES.hand_cannon` and `military_equipment_extension.gd` `hand_cannon` are gated on `powder_artillery`.
- **`powder_artillery` floor.** The re-gate alone was not enough. The game's catalog dates `powder_artillery` to historical 1350, which the curve puts at game ≈ 1792, inside this window, so its era gate was 1612. Its catalog foundations do not hold it either: `precision_machinery` (catalog 1350) and `military_staffs` (catalog 1326) are also dated inside the window in the game, and `blast_furnace` (1732) plus `black_powder` (1757) would let it open by about 1760–1790. The bake adds a `redate` floor of 1880 for `powder_artillery` in `design_amendments_600.json` (the low end of the registry's ≈ 1880–1920). With it, every gunpowder-era unit and equipment gate opens at 1800 or later. The 1800–2400 design replaces the floor when it places the item.
- The build from `origin/codex/research-plausibility` (`648bd421`) passed on the first run after the `ocean_sailing` removal: 937 items, 1,999 cross-block references, one year adjustment.

## For the 1800–2400 block

- **`powder_artillery` requirements.** Drop or replace `military_staffs` and `precision_machinery` (see bake-time fix 3). Remove the 1880 redate floor once the block designs the item, or keep them consistent.
- **`military_staffs` opens in the game at 1594.5.** It is dated inside this window by the catalog, and it gates the industrial-era `mountain_infantry` unit and `mountain_kit` equipment, plus the `staff_exercise` operation. The registry places it at ≈ 2200–2300. It needs a design placement or a redate floor.
- **`precision_machinery` opens in the game at 1612.5** (it waits on `blast_furnace`, 1732). The registry places it at ≈ 2370.
- **Gun gates at exactly 1800.** `matchlock_drill`, `mounted_firearms`, `naval_gunnery` and `rifled_barrels` open at the 1800 window floor. The registry suggests 1900–2000 for them (within ≈ 1830–2000). `naval_gunnery` also waits on `powder_artillery`, so it is held to 1880.

## Open items

- **Serial queue pressure.** See *Pacing*. `research_years` totals exceed the window in 7 lines, and institutions exceeds it by 271 years.
- **Bands outside the window.** 117 registry bands reach outside 1200–1800 by up to 43 years (see the registry notes); every proposed year is inside.
