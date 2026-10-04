# One settlement growing through history

Integration workspace: `C:/Users/sjpur/.codex/worktrees/settlement-growth-integration/TomorrowandTomorrow`.
Branch: `codex/settlement-growth-integration`. Starting canonical/main base:
`bdacd023ee3af689039ca07d1f95e649edafece5`.

This is the first implementation slice of one expanding central settlement.
New quarters connect to its existing fabric, and new buildings use architecture
supported by the settlement's current knowledge, adoption, workforce and age.
Existing plots keep their recorded history and sites. The supported progression
is tested from the opening portable-shelter generation through game year 3000;
calendar time alone does not grant construction capabilities.

## Source deliveries

- Model: `2805336c0704f17cfb33b2b1bed7bc899784c614`,
  `codex/settlement-growth`; details in `SETTLEMENT_GROWTH_CONTINUITY_HANDOFF.md`.
- Retained renderer: `3d0a4a8af125d66d9fe36d32145ce44c0045ce2d`,
  `codex/settlement-patches`; founding-core priority follow-up `0b31984b` and incremental placement/performance follow-up `afeb5c96`.
- Camera coverage helper: `64fa954d2a9c8a49451c999ae921fad157ae5c50`,
  `codex/settlement-ground-view`.
- Ground retention/streaming: integrator checkpoints `6db3f75e`, `2750f788`
  `9820b43c` and `8f1a0d8e`.
- Raster and paint-key optimizations: `292c6afa`, `3417f3f8`, `be859720`
  on `codex/settlement-ground-raster`, integrated through `86b07cdf`.
- Live acceptance probe and final evidence: `928bd2cc`, `9e9534fb`
  on `codex/settlement-growth-acceptance`, integrated through `bcc9c9e5`.

Task ownership covers settlement model policy, retained map geometry, ground
painting/streaming and their tests/docs. `local_terrain.gd` is the coordinated
shared integration file. Worker edits were reconciled in this worktree without
source conflicts; no canonical source was edited concurrently.

## What changes on the map

Persistent plot patches and separate route roots replace whole-settlement
replacement. Appearance changes replace the affected geometry while unchanged
neighbors remain installed. Fixed 256-metre cells and persistent ID groups keep
patch identity independent of total settlement size. New quarters can extend
beyond the former 1.05-kilometre candidate boundary, using bounded searches and
connected approaches checked against terrain and inherited parcel polygons.

The founding ground keeps its detailed texture. Four additional texture layers
follow the projected camera footprint at power-of-two scales; their coverage
includes aspect ratio and camera tilt. Raster work is prepared one tile per
service call, keeping the previous complete set installed until replacements
are ready. The completed set then uploads at most four image pairs. Twelve
cached CPU image pairs bound retained raster memory.

Queued ground paint freezes only the lightweight inputs it reads, so labour or
crop updates cannot strand a pending window under an obsolete cache key.
Fallback clearing participates in those keys. The home no longer overlays the
legacy synthetic field halo: recorded land use owns both paint and clearing.

Ground paths are derived from the whole settlement before raster clipping.
Recorded roads retain their original sampling across padded seams. Derived
field/water tracks retain the same endpoints even when their hearth or field
falls outside a tile. Approach changes invalidate current requests. Route
geometry, field season and actual paint inputs participate in cache identities.
Removing a frontier or clearing the world removes its requests and ground.
Settlement-local noise and split world origins keep texture detail anchored.

Line rasterization resolves brush state once per line. The full source revision
still notices changed records, but the home paint key includes only records
that actually contribute to its image. A new fallback building or repair can
therefore update geometry without repainting identical ground. Complete CPU
image bytes remain identical across the optimized 96/128/129/damage/repair
specimens; texture readback under the headless dummy renderer is not the oracle.

## Validation and evidence

Godot 4.7.2, explicit isolated worktree paths and Dummy audio throughout.

- Final combined regression: 231/231 cases across 15 suites, zero errors,
  failures, skips or orphans; report 11 and
  `artifacts/settlement-growth-final-combined-tests.log`. Covers model policy,
  architecture kits, construction history, roads/siting, ground/camera caches,
  retained patches and existing early/organic/year-71/city architecture checks.
  The older roads assertion now expects the deliberately disabled home halo;
  approach changes still invalidate ground exactly once.
- Model worker: 53 focused cases, including all 13 construction generations,
  year 3000, capability gates, growth past one kilometre, blocked terrain,
  complete bounded batches, unchanged inherited records and exact parcel-edge
  intersection (including narrow and off-center inherited parcels).
- Ground/view integration: 28 cases across `test_settlement_grounds.gd`,
  `test_settlement_ground_tiles.gd` and `test_settlement_ground_view.gd`.
  Includes 36 real camera projection combinations, negative coordinates and
  scale thresholds, retained core identity, distant crop/route updates,
  approach invalidation, seam connectivity, a 600-km road with clipped raster
  iteration, cached revisits, complete replacement coverage and cache bounds.
  Additional contributor-key checks cover inherited geometry-only changes,
  repair reuse, genuine paint changes and conservative foreign invalidation.
- Private actual-terrain-shader close/wide frontier capture: a recorded field
  crossing tile boundaries remains continuous and fully visible at wide zoom.
  Private process 22156 exited 0 with clean engine/script logs;
  `artifacts/frontier-ground-final-gpu.log` and its runner log.
  This diagnostic uses a flat plane and prepared field/road, not the player map.
- The live GPU fixture passed 169/169 checks after raster optimization; its
  separate full visual-history capture passed 193/193 on the earlier combined
  runtime. All 13 supported construction generations have actual visible mesh
  evidence, including generation 12 at year 3000. Final paint-key optimization
  passed the targeted 33/33 GPU checks. See `SETTLEMENT_GROWTH_ACCEPTANCE.md`
  for exact source checkpoints, reproduction and full before/after tables.
- Final targeted RTX 4090 / Compatibility / 1600x900 observations: adding plot
  129 submitted in 22.263 ms; repair in 17.348 ms. Neither repainted the home
  ground. All 14 inherited plot roots survived growth from 96 to 128 plots;
  all 18 survived the next addition. Repair replaced only its one affected
  patch. The 129-plot steady refresh p95 was 1.283 ms with zero geometry/ground
  churn. These are measured fixture costs on this host, not a portable FPS claim.

Generated screenshots, timing JSON, engine imports, caches and isolated userdata
are local diagnostic artifacts. Tests use prepared records and paused simulation;
they do not represent a completed continuous campaign or the current player save.
The generated visual triptych and year-3000 study are aspirational concept art,
not game footage or shipped building assets.

## Compatibility and limits

No save schema migration, new population ledger, labor owner or civic authority.
GovernmentPeopleSystem remains authoritative for civic officials and daily
settlement labor. Aggregate housing/material accounting and bounded visual
representatives remain in place. HistoricalFigures ownership is unchanged.

The existing six-quarter target and 2048-plot/1024-route bounds remain. Detailed
kit placement still has a first-128-plot/512-representative budget, with later
plots using supported fallback drawing. This work does not add a complete new
asset library for every era or a distinct year-3000 art kit. Existing late-era
forms are exercised at the endpoint. Individual mesh builders and texture
uploads have measurable costs; a cooperative queue is not a hard FPS guarantee.
Cold direct initialization with 96 prepared plots still measured 820.803 ms:
the first refresh can solve the full layout synchronously before a retained
root exists. Incremental updates are improved; slicing cold initialization
remains unfinished. The final targeted maximum mesh job was 10.470 ms and
incremental layout step 16.600 ms.

No player/editor process is launched, stopped or restarted for these checks.
Delivery must verify origin/main before fast-forwarding the canonical checkout.
The player receives new scripts on the next normal canonical launch.

The canonical checkout has 4696 existing modified/untracked local files in the
pre-delivery SHA256 inventory. Incoming source paths must not overlap them;
verify every inventoried byte after the fast-forward. Generated worktree
imports, captures, reports, concept images and isolated userdata are excluded.
