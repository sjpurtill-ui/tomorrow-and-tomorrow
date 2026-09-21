# Growing chart and completed research indexes

Base `e1f2f8e2`; worktree `/Users/seanpurtill/.codex/worktrees/campaign-performance`, branch `codex/settlement-map-scaling`. Scope expanded to research candidate selection at the user's request during this pass.

## Map visibility

Every visibility query previously scanned all explored circle/trail records and converted their points back to vectors. The map, resource markers and army visibility repeatedly invoke this query. The existing scout-planning spatial index now serves these calls too. Each CivilizationSystem owns its own derived index, rebuilt on fog revision or record-count changes and cleared on reset/import. Retained circles and trail segments remain the authority; spatial buckets only narrow which exact geometric tests run. Radius-boundary comparisons use the same distance operation as the original authoritative query. Large diagonals use an exact fallback. Bucket references are capped at 262,144; overflow also falls back to exact checks rather than allocating unbounded bucket lists.

The index is a RefCounted object, excluded from reflected saves and absent from curated exports. No save schema changes. Production reveal mutations increment fog_revision; direct development edits to existing records must also do so, as required by the renderer. Replacing saved charts with the same revision and count explicitly discards the index.

Synthetic 1,024-trail, 64-point chart queries average 24.416 ms with a full scan versus 0.0089 ms after indexing. The first query costs 113.9 ms to build the index. The test includes revealed and unrevealed positions; it is not a measured game frame rate. A heavily overlapping chart or many broad diagonal segments can still require substantial exact work. Full raster redraws on changed exploration remain untouched.

## Completed versus obsolete research

Completed knowledge remained in each channel's daily candidate list. Every channel check rebuilt a membership dictionary from all known IDs and revisited already completed entries. The new derived research index shares that membership lookup and lazily builds unfinished candidates per channel, preserving the original sorted order. It invalidates on knowledge content changes (including same-length replacement/forgetting), catalog-array replacement/growth and discovery-system reset/initialization. Catalog definitions remain static during ordinary play.

Only completion is cached. Eligibility, material access, imports, practice, targets, scoring and AND/OR foundation rules remain live. A completed channel returns no candidate immediately; learning more in other channels still invalidates its pending list. Every known ID remains in campaign knowledge, adoption, history and prerequisite checks. The index is an unsaved object.

The component probe uses the current 883-entry technology_catalog, not all 5,491 catalog records: the latter also includes 4,608 retired generated frontier records. All 36 channels take 4.475 ms through the original check when this candidate catalog is completed, versus 0.292 ms with the index. At 441 known entries, 2.215 → 0.281 ms; at zero, 3.434 → 3.278 ms. These are synthetic known subsets, not naturally reached eras or a promise about the complete planned discovery journey.

Retired generated frontier entries are already excluded from candidate channels. Old adopted benefits remain supported for saved campaigns. There is no general authored technology-obsolescence contract that makes age alone sufficient to retire an effect. Society effects are accumulated with adoption/practice and clamped after summation: a currently capped or unused bonus can matter again after adoption, supplies or staffing change, or when combined with negative effects. Do not remove those foundations or benefits as a performance shortcut. Potential future work is an index of contributors by effect/production family, with explicit invalidation, rather than indiscriminate pruning. This pass changes no effect formulas or adoption cadence.

## Validation and limits

33 focused cases pass across test_chart_and_research_indexes.gd, test_scouting_staff.gd and test_scaling_predicates.gd, with no errors/failures/skips/orphans. Coverage includes exact geometry and radius boundaries, long diagonals, trail extension, clearing charts, same-revision import, save exclusion, bounded fallback, candidate order, knowledge replacement/forgetting and full-catalog selection equivalence at multiple completion levels. Existing live pathway tests cover imports and experimental thresholds. The older scout-origin fixture now supplies food in its selected departure city's stores, matching the already integrated local-provisions rule; no production provisioning change was made.

The same 24-day, twelve-opponent, day-11238 replay matches all saved simulation state except timestamp. Daily-tick mean was 247.56 ms baseline versus 259.38 ms changed (about 4.8% slower in this pair), including a larger initial warmup. This does not demonstrate a whole-world daily speedup; component gains must not be presented as one. Host load and cold index builds affect runs, and the daily harness omits normal repeated map visibility queries. No claim that the original year-100 slowdown is resolved. Existing replay shutdown has the same two-object/one-resource warning; focused suites have zero orphans.

The checked growth costs are reduced without deleting territory, research history, or benefits. Remaining work includes changed-chart rasterization, measuring total rendered-frame throughput with a developed world, and civilization/settlement observer scaling. No player or editor restart, release packaging, skipped days, or AI cadence reduction.
