# 600-year research layer: implementation (Phase 1)

Branch `codex/research-600`. It is based on main `4d5c5e36`, with `codex/era-research-pacing` merged in (commit `8086e0e1`).

The design sources are on `codex/research-plausibility`:

- `docs/research/*_600_YEARS.md`
- `docs/research/registry.json`
- `docs/research/deps/graph.json`
- `docs/research/deps/YEAR_ADJUSTMENTS.md`

This document covers how the game uses that design, how to check it, and what Phases 2 and 3 still need to do.

## Architecture

```
design branch                      this branch (committed)                    runtime
graph.json + registry.json  --->  tools/research/build_research_600.py  --->  data/research/research_600.json
                                                                                   |
data/research/effects/<line>.json (Phase 2) ------------------------------------+  |
                                                                                v  v
                                                        scripts/research_600_catalog.gd (Research600, static)
                                                                                |
                                                        scripts/discovery_system.gd (delimited "research_600" hooks)
                                                                                |
                                   player research, technology tree, rival_research_candidates, progression_system
```

- **Build step.** Run `python tools/research/build_research_600.py`. By default it reads the two design files with `git show origin/codex/research-plausibility:<path>`. You can pass `--graph`/`--registry` to use local copies instead. It checks that there are no unknown ids and no cycles, and then writes `data/research/research_600.json`, which is committed. The output records the source commit. It also creates the empty effect stubs if they are missing, and never overwrites them. For NEW items it assigns a research channel by keyword (from the one-liner), a short name, observation text, and default activity signals.
- **Year adjustments.** The 18 moves in `YEAR_ADJUSTMENTS.md` are already applied in `graph.json` as `proposed_year`. The tool shifts each adjusted item's band by the same amount. For example, `copper_outcrop_signs` moves from 140 to 80, so its band moves to 40–120.
- **Loader.** `scripts/research_600_catalog.gd` is a static `RefCounted`. It loads the JSON once and merges the Phase 2 effect files. It also provides:
  - `new_entries`: catalog entries for NEW ids
  - `apply`: design overrides for registry ids
  - `earliest_year`: the era gate
  - `unmet_conditions` / `conditions_met`
  - `environment_tags`
  - `precedent_factor`
  - `art_key`
- **DiscoverySystem hooks.** These are the only edits to that shared hotspot, and each is marked `research_600`:
  1. `initialize()` appends `Research600.new_entries()` before the frontier catalog. It applies `Research600.apply()` as the last per-entry step, after the branch, mathematics and mechanics overlays. It then calls `_assign_research_600_years()`.
  2. `_discovery_is_eligible()` returns false unless `research_600_open(discovery,{},current_day)` holds.
  3. In `technology_tree()`, the design reasons (the age has not come yet, or conditions are unmet) appear in `missing` and keep the row LOCKED.
  4. `rival_research_candidates()` filters with `research_600_open(entry, research_600_rival_society(civ))`.
  5. `research_difficulty(..., known)` divides by the precedent factor. `progression_system.gd` passes the rival's own known list.
  6. There is a delimited function block at the end of the file:
     - `_assign_research_600_years`
     - `_research_600_reconciled_era`
     - `research_600_earliest_year`
     - `research_600_open`
     - `research_600_missing`
     - `research_600_player_society`
     - `research_600_rival_society`
- **HUD.** `research_visuals.subject_art_key` falls back to `Research600.art_key(item)` when an item has no subject painting of its own. That is either the Phase 2 `art` path or the line painting `res://assets/ui/research/<line>-v1.png`. Unknown and hidden ids still get no fallback.
- **Save format.** No new saved state. DiscoverySystem gained no member variables. Gate years and overrides live on the transient catalog dictionaries, and the loader cache is static.

## Override precedence

For a registry id that is already in the catalog (200 main + 358 era ids), these fields come from the design:

| Field | Source |
|---|---|
| `requires_all`, `requires`, `requires_any` | Design. They replace the authored and overlay requirements. |
| `learning_routes` | The authored primary route (`local`) is replaced by an open design `local` route. Other authored approaches (`experimental`, `charcoal`, `manuscript`, `metallurgical`, ...) stay as **optional** alternatives. Model overlays (`mathematical:local`, `mechanical:local`) are rebased to require only the model's own foundations. Alternatives can speed research or change which approach gets credit. They can never add requirements. |
| `discovery_era` (TechnologyEras pacing) | `proposed_year` |
| `earliest_year` (era gate) | `band_low`, shifted by any year adjustment |
| `day` (ordering hint only) | `proposed_year * 365` |
| `chance` | `1 / (0.12 * 365 * research_years)`: one fully staffed year per design research year |
| `precedents`, `conditions`, `design_year`, `research_600` | Design |

These stay authored: name, observation, effects, production_contract, production_items, resource_requirements (including `SocietyModel.RESOURCE_GATES`), OpeningOpportunities gates, method profiles, and art.

A Phase 2 effect row can then override any non-protected key. The protected keys are `id`, `dynamic`, `direction`, `requires*`, `learning_routes`, `day`, `chance`, `research_600`, `earliest_year`, `design_year`, `precedents` and `conditions`.

For **NEW** ids (543), the loader builds a full catalog entry with these fields: `id`, `name`, `direction`/`dynamic` (the line), `subcategory` (a valid channel), `signals`, `observation`, `effects` (the per-line default below), plus all the design fields.

Per-line default effects, used until Phase 2 fills them in:

| Line | Default effect |
|---|---|
| knowledge | knowledge_preservation .004 |
| institutions | state_capacity .003 |
| culture | cohesion .003 |
| labor | labor_efficiency .003 |
| production | craft_output .004 |
| infrastructure | construction_rate .004 |
| nutrition | food_output .003 |
| health | health_protection .003 |
| demography | maternal_safety .003 |
| logistics | haul_capacity .004 |
| ecology | ecology_recovery .003 |
| security | security_efficiency .004 |

**Entries outside the registry** (686 live entries) keep all their authored data. Only their era gate changes:

- If `TechnologyEras.HISTORICAL_YEAR` dates the entry, the gate is `0.9 ×` its reconciled era. The reconciled era is the entry's own date, raised to the latest era among its `requires_all` foundations, because those may now carry later design years.
- If the entry is undated, the gate is `max(600, 0.9 × inherited era)`.

## Era gate

`research_600_open` is false while `year < earliest_year`. The year is `current_day/365` when a caller evaluates a specific day, and otherwise the world calendar (`elapsed_days/365`). The player, owned AI seats and projected rivals all use the same world calendar.

The gate only controls availability:

- It never grants, adds or removes knowledge.
- An investigation that opened under the old rules pauses on load, and its `discovery_progress` is kept.
- The era branch's scholarship pricing still applies on top of the gate.

Examples of the worst previously-too-early items:

| Item | Earliest year before (recorded campaigns or reports) | Earliest year now |
|---|---:|---:|
| `fractional_quantities` | 36 | 480 |
| `place_value` | 56 | 470 |
| `case_records` | 48 | 455 |
| `domesticated_mounts` | 40 | 435 |
| `rigid_pipe_bedding` | 18 | 385 |
| `vinegar_pickling` | 79 | 465 |
| `war_chariots` | 99 | 460 |
| `mine_shoring` | 131 | 530 |
| `core_formed_glass` | 152 | 550 |
| `regional_maps` | 136 | 500 |
| `apprentice_contracts` | 108 | 500 |
| `sulfur_purification` | 111 | 470 |
| `geometric_survey` | 82 | 410 |
| `glassmaking` | 104 | 400 |
| `bookbinding_assemblies` | 16 | 1098 (outside the registry, dated 1220) |
| `bloomery_smelting` / `iron_assaying` | ~75 | 594 |
| `differential_calculus` / `integral_calculus` | ~180 | 1926 |
| `public_libraries` | — | 2280 |

## Condition semantics

All listed conditions must hold, except `environment`, which is any-of.

| Condition | Player-side society | Rival society |
|---|---|---|
| `min_population` | `population_total` | `civ.population` |
| `min_settlements` | `max(1, player_settlements.size())` | `max(1, civ.settlement_count)` |
| `resources_known` | A deposit at stage ≥ recognized, or a stockpile > 0 | Landscape potential ≥ 0.16 (the same floor rival research already uses) |
| `environment` (river / coast / woodland / dry) | Tags from every settlement's `environment_profile`. If there is none, the current environment profile is used. Authored hydrology `water_metrics.source_accessible` also counts as river. | Tags from `civ.environment_profile` |
| `institutions_min` | `society_capacities.institutions` | `civ.institutions` |
| `contact_required` | Some civilization with `player_relation.contact_level ≥ 2` (the two have met) | `player_relation.rival_contact_level ≥ 2`, or a relation with trade, war or a treaty |
| `resources_unmapped` | Ignored (Gypsum, Meteoric iron, Alum) | Ignored |

How profiles become environment tags:

- **river**: `river_distance_km < 12`, or biome floodplain/wetland. Planetary profiles that were never observed have no river distance. For those, a wet (precipitation ≥ 0.55), low-relief (< 0.4), non-steppe landscape counts as river country. This fallback matters mainly for rivals.
- **coast**: `coastal`.
- **woodland**: `woodland ≥ 0.42` or biome woodland.
- **dry**: steppe, precipitation < 0.36, or drought ≥ 0.6.

Conditions gate availability only. Known discoveries are never revoked. The technology tree lists unmet conditions as missing requirements.

Precedents are never required. Each known precedent makes research 10% cheaper, up to a limit of 30%. This applies equally to the player's daily progress and to rivals' momentum cost.

## Phase 2 effect schema

There is one file per line, `data/research/effects/<line>.json`. The files are committed as empty stubs:

```json
{
 "line": "nutrition",
 "schema": "research_600_effects/1",
 "items": {
  "<registry id>": {
   "effects": {"food_storage": 0.02, "food_spoilage": -0.02},
   "art": "res://assets/ui/research/paper/<file>.png",
   "name": "Optional display-name override",
   "observation": "Optional in-world one-sentence observation override.",
   "ability_reason": "Optional: why this matters now (shown in announcements).",
   "social_consequence": "Optional override of the line's social consequence text.",
   "production_contract": "Optional: text describing a physical operating contract.",
   "production_items": ["<existing civilian_industry recipe id>"],
   "resource_requirements": [{"resource": "Clay", "stage": "accessible", "minimum_stock": 0.0, "sample_sufficient": true}]
  }
 }
}
```

Rules:

- Only ids in the registry are read. Any other ids are ignored.
- A row for an existing catalog/era id merges over the authored entry. Include only the keys you mean to replace. For example, `effects` replaces the whole authored effects dictionary.
- **effects** values are per-discovery contributions, weighted by adoption. SocietyModel sums them over known discoveries and clamps each total to these limits:

  | Key | Limits |
  |---|---|
  | conception_support | [-.35,.35] |
  | maternal_safety | [-.10,.65] |
  | neonatal_survival | [-.10,.65] |
  | food_output | [-.35,.80] |
  | foraging_yield | [-.35,.65] |
  | hunting_yield | [-.35,.65] |
  | cultivation_yield | [-.35,.90] |
  | food_storage | [-.40,1.2] |
  | food_spoilage | [-.75,.40] |
  | nutrition_quality | [-.30,.45] |
  | soil_productivity | [-.40,.80] |
  | health_protection | [-.30,.55] |
  | water_safety | [-.30,.60] |
  | disease_exposure | [-.55,.55] |
  | injury_risk | [-.45,.55] |
  | health_risk | [-.20,.40] |
  | labor_efficiency | [-.35,.55] |
  | labor_demand | [-.25,.35] |
  | fatigue | [-.35,.45] |
  | task_coordination | [-.30,.65] |
  | knowledge_rate | [-.40,.90] |
  | observation_rate | [-.35,.75] |
  | knowledge_preservation | [-.35,.85] |
  | adoption_rate | [-.40,.80] |
  | survey_speed | [-.40,.85] |
  | water_access | [-.35,.80] |
  | tool_quality | [-.35,.90] |
  | craft_output | [-.40,1.0] |
  | extraction_yield | [-.40,1.1] |
  | metal_yield | [-.40,1.2] |
  | timber_yield, stone_yield, clay_yield, fiber_yield | [-.40,.90] |
  | fuel_efficiency | [-.40,.85] |
  | repair_capacity | [-.30,.75] |
  | standardization | [-.25,.80] |
  | construction_rate | [-.40,1.0] |
  | housing_output | [-.35,.90] |
  | disaster_resilience | [-.40,.80] |
  | mine_safety | [-.40,.80] |
  | mining_output | [-.35,.80] |
  | mobile_shelter | [-.35,.70] |
  | haul_capacity | [-.40,1.0] |
  | route_speed | [-.40,.85] |
  | travel_speed | [-.40,.65] |
  | storage_loss | [-.70,.40] |
  | dry_storage | [-.35,1.0] |
  | container_capacity | [-.35,1.2] |
  | logistics_endurance | [-.35,.70] |
  | trade_capacity | [-.40,1.0] |
  | state_capacity | [-.45,.90] |
  | legitimacy | [-.45,.55] |
  | cohesion | [-.45,.55] |
  | institutional_rigidity | [-.20,.55] |
  | warfare_readiness | [-.40,1.0] |
  | security_efficiency | [-.40,.80] |
  | naval_capacity | [-.30,.90] |
  | ecology_recovery | [-.50,.65] |
  | ecological_pressure | [-.45,.80] |
  | timber_pressure | [-.45,.80] |
  | pollution | [-.15,.80] |
  | water_pollution | [-.15,.70] |
  | fuel_demand | [-.35,.70] |
  | disaster_risk | [-.20,.65] |
  | chemical_control | [-.20,.80] |
  | sanitation | [-.45,.65] |

  Other keys are clamped to [-.5,.8] and only matter if some system reads `DiscoverySystem.effect(key)`. Keep early practices small: the era branch's early practices use roughly .003–.03 per effect.
- **production_items** must name recipes that already exist in `civilian_industry.gd` whose `gate` is this id. New recipes, facilities, method profiles (`clothing_method`, `food_batch_method`, `grain_method`, `medical_method`, `training_profile`, `preservation_profile`, `agronomy_profile`, `prospecting_profile`, `operating_plants`) and `foundation_for` need code, and are checked by `technology_catalog_contract.gd`. They belong to Phase 3.
- **art**: a `res://` image path. With no `art`, the line painting is used.
- The loader rejects protected keys. It never lets Phase 2 change foundations, era, pace or conditions. Those come only from the design through the build tool.

## How to verify

```
python tools/research/build_research_600.py            # regenerates data; git diff should be empty
<godot> --headless --path <worktree> --import           # once
<godot> --headless --path <worktree> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://tests/test_research_600.gd
<godot> --headless --path <worktree> -s res://tools/research/run_research_600_probe.gd -- 100 0.25
```

The probe is a best case: every condition is met, every signal is present, and research is instant. It prints a JSON summary and exits 1 if anything opens before its band or gate.

The Phase 1 result: by year 100, 469 live entries can open. That is all 456 registry items with `band_low ≤ 100`, plus 13 dated entries outside the registry. None opens before its band.

## Phase 2 and 3 plan

- **Phase 2 (content, one worker per line or line pair).** Fill in `data/research/effects/<line>.json`: effects for the 543 NEW ids, better observation text where the one-liner is terse, and `art` paths as paintings arrive. Add a per-line test that every NEW id has authored effects inside the limits above. Do not edit `research_600.json` by hand. Design changes go through the design branch and the build tool.
- **Phase 3 (systems and art).**
  - Recipes, facilities and method profiles for the key thresholds (bold rows), such as token envelopes, cored casting and war chariots.
  - Subject paintings for the 358 era and 543 NEW ids.
  - Research-throughput tuning for the design's serial overruns (225 items in NUT, LOG, SEC and PRO).
  - A real river-distance source for rivals.
  - A campaign-length playtest of the cadence.

## Design data problems found

- **Undated gaps.** 28 live entries outside the registry are dated inside the 600-year window by `technology_eras.gd`. Examples: `grain_milling`, `salt_working`, `sealed_vessels`, `germination_trials`, `layered_clothing_design`, `textile_repair_methods`, `wheel_hub_boring`, `wooden_axle_boxes`, `rope_rigging`, `sail_seaming`, `ocean_sailing`, `elephant_training`, `felloe_jointing`, `bearing_surfaces`. The design neither lists them nor maps them to aliases. They are gated by their reconciled era. The design should adopt or re-date them.
- **Changed foundations.** 508 of the 558 existing registry items had authored foundations that differ from the design. The design wins. The existing suites that asserted the old graph were updated, with comments:
  - `percussion_fire_ignition` no longer needs `stone_sorting`.
  - `charcoal` now comes through `earth_oven_cooking`.
  - `smoking` needs `ember_tending`, and charcoal is no longer an alternative to food drying.
  - `tin_smelting` needs `copper_smelting`.
  - `bronze_alloying` needs `tin_smelting`.
  - `copper_smelting` adds `kiln_control`.
  - `ore_assaying` needs `native_copper_working`.
  - `rainwater_cisterns` needs `lime_plastered_floors` plus dry country.
  - `apprentice_contracts` needs `apprentice_for_keep` plus `sealed_tablet_contracts`.
  - `coastal_watercraft` needs `plank_extended_dugouts` plus `sail_panel_cutting`, on a coast.
- **Unmapped resources.** Gypsum, Meteoric iron and Alum have no in-game resource, so they are not enforced.
- **Graph depth.** Chain depth rises past the old tree-test bound of 30, which main already failed at 30–32. The design's long early chains, such as 17 links to scale armor, push the deepest later entries to 39 (`store_forward_archives`), so the bound is now 48.
- **Behavior at game start.** At year 0 only the 51 starting-knowledge items are open. A research channel with no open question gives its observers to open channels in the same domain. The existing redistribution does this, and the observers do not return on their own when the channel opens later. Three existing tests assumed day-0 availability and now set the calendar or staff the channel: `test_discovery_projects` (two tests) and `test_artifact_collection`. Phase 3 could return waiting observers when a channel's first question opens.
- **Flags left for review.** `YEAR_ADJUSTMENTS.md` leaves some flagged items for review: `dream_interpretation` at 470, the aliasing of `burial_ground_separation` / cemeteries, and `seasonal_crisis_leader`.

## Multiple blocks

The research layer loads one or more **design blocks**. Each block is one approved design window, such as years 0–600 or 600–1200. The blocks are listed in order in `data/research/blocks.json`:

```json
{"schema": "research_blocks/1", "blocks": [
 {"id": "y0_600", "data": "res://data/research/research_600.json", "effects_dir": "res://data/research/effects",
  "art": "res://data/research/art_600.json", "window_start": 0.0, "window_end": 600.0}
]}
```

| Per block | y0_600 (unchanged paths) | y600_1200 |
|---|---|---|
| Design data | `data/research/research_600.json` | `data/research/blocks/y600_1200.json` |
| Effect files (Phase 2 schema above) | `data/research/effects/<line>.json` | `data/research/effects_y600_1200/<line>.json` |
| Art manifest (`art_600.json` schema) | `data/research/art_600.json` | `data/research/art_y600_1200.json` (optional until paintings exist) |

The loader (`scripts/research_600_catalog.gd`) works as follows:

- It merges blocks in manifest order.
- A later block may use earlier-block ids as `requires_all`, `requires_any` and `precedents`.
- If an id appears in more than one block, the first block wins. The build tool rejects duplicates.
- A block's effect files only author that block's own ids.
- Art manifests merge in order. An earlier block's painting wins.
- `redates` merge, and a later block's value wins. A designed item always beats a redate. This means that when the 600–1200 block designs `bloomery_smelting`, its band replaces the Phase 3 redate of 660.
- `Research600.meta()` is still the first block's meta. Use `blocks()`, `block_ids(block)`, `block_meta(block)`, `block_of(id)`, `art_manifests()` and `window_end_year()` for the others.

Era gating for catalog entries outside every block:

- **Dated:** `max(0.9 × era, the end of every loaded window that ends before the era)`. With only y0_600 loaded, this is the same as the old rule. With y600_1200 loaded, an entry dated 700 that the new block does not list still waits until year 630 (`0.9 × 700`), and never opens before 600.
- **Undated:** `max(window_end_year(), 0.9 × era)`. That is 600 today, and 1200 once the second block is present.
- A game without `blocks.json` falls back to the single 0–600 block.

### Build tool

`tools/research/build_research_block.py` builds one block. It takes a registry and a graph as local paths or as `<git ref>:<path>`. It reuses `build_research_600.py` for names, channels, signals, band shifts and amendments. It exits 1 without writing anything if it finds any of these problems:

- an unknown id, checked across this block and every earlier block
- an id already defined by an earlier block
- a cycle in the combined graph
- a prerequisite with a later proposed year than its dependent (`requires_all`, and the earliest member of each `requires_any` group)

Year adjustments come from `--adjustments`, or else from a sibling of the graph named `YEAR_ADJUSTMENTS<suffix>.md` or `year_adjustments<suffix>.json`. The suffix comes from `graph<suffix>.json`. Each move sets `proposed_year`, and the band shifts with it. The tool also creates the empty effect stubs for the block. When run with `--register`, it adds or updates the block's row in `blocks.json`.

`python tools/research/build_research_block.py --block y0_600` regenerates `data/research/research_600.json` byte for byte. It reads `origin/codex/research-plausibility` and re-applies `YEAR_ADJUSTMENTS.md`, which is idempotent.

### Adding the 600–1200 block (one command)

Once `docs/research/y600/registry_1200.json` and `docs/research/y600/deps/graph_1200.json` exist in `C:/Users/sjpur/tt-research-plausibility`, run this from the worktree root:

```
python tools/research/build_research_block.py --block y600_1200 --registry ../tt-research-plausibility/docs/research/y600/registry_1200.json --graph ../tt-research-plausibility/docs/research/y600/deps/graph_1200.json --register
```

If the files have been pushed to the design branch instead, use `--registry origin/codex/research-plausibility:docs/research/y600/registry_1200.json --graph origin/codex/research-plausibility:docs/research/y600/deps/graph_1200.json`. Git-read sources record the design commit.

The command does the following:

- It takes the window 600–1200 from the block id.
- It writes `data/research/blocks/y600_1200.json`.
- It creates the stubs in `data/research/effects_y600_1200/`.
- It registers `art_y600_1200.json`.
- If `deps/YEAR_ADJUSTMENTS_1200.md` or `year_adjustments_1200.json` exists, it applies it.

It prints a warning for each item proposed outside the window. Commit the manifest, the block JSON and the stubs.

Then verify:

```
<godot> --headless --path <worktree> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://tests/test_research_600.gd -a res://tests/test_research_blocks.gd
```

What to expect from the tests:

- `test_research_600.gd` counts only `block_ids("y0_600")`, so it keeps passing.
- `test_research_blocks.gd > test_the_game_manifest_lists_only_the_first_block` asserts the manifest as it is today. Update it to expect `["y0_600","y600_1200"]` and a window end of 1200.
- The rest of `test_research_blocks.gd` uses its own fixture, which is `tests/fixtures/research_blocks`: a synthetic block with 4 items, rebuilt with the same tool.

Expect to adjust these as follow-ups:

- The tools in `tools/sim/` and `tools/research/benchmark_report.py` still read only `research_600.json`.
- The probe `run_research_600_probe.gd` measures the 0–600 window.
