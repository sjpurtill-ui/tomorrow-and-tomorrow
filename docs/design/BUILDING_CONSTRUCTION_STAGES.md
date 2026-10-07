# Visible building construction

Ordinary new buildings now show foundations, an open frame, unroofed walls,
and the recorded finished roof at 0%, 25%, 50%, and 75% of their existing
construction interval. The next monthly pass still makes the building active.
This feature does not charge materials, allocate a new crew, or extend that
existing completion rule. The normal daily settlement update records progress;
renderers only read it. Rebuilding a ruin records a fresh start day. Existing
saves use their recorded last update or creation date, preserving progress.

The shared early/town/later renderer derives stages from the final building
mesh, keeping its placement, dimensions, colours, and material codes. At the
roof milestone it uses the exact finished mesh. Expansion seeds use the same
renderer for genuine unfinished records; completed representative clusters
are not assigned invented construction jobs. Existing paid fabric refits keep
the old building visible with a small access scaffold until the job ends.
No walking people or new ambient actor simulation is added.

Appearance keys contain the discrete stage rather than fractional progress.
A separate per-city, per-day construction signature lets the map see a new
stage without invalidating parcel placement or vegetation. Visible patch
replacement uses the existing bounded queue and retains the old mesh until
its replacement is ready. Stages are shared MultiMesh batches, not one node
per building. Unsupported aggregate fabric follows the same milestones on its
existing footprint and preserves its random placement sequence. Its wall
base was corrected from 1.6 metres to 0.24 metres above the sampled ground,
avoiding inverted walls on the existing 1.1-metre one-storey fallback.

Mesh caches are capped at 128 stage meshes and 24 source analyses. Source
inspection is capped at 16 surfaces and 40,000 triangles; frames use at most
24 wall edges and four levels. No new geometry is generated per animation
frame. Fast-forwarding can legitimately skip observed stages between days.

Source checkpoint: `cbfc5fd0`, branch `codex/building-construction-stages`,
based on `670a4fee`. It is combined with the subsequent culture-screen update
`e08fdba9` in merge `1ef466df`; no construction conflicts or geometry changes.

The 63 distinct focused checks passed across reports 86–87: six mesh cases,
four normal-play/legacy/ownership progress cases, eleven stage/cache/terrain
cases, eighteen existing early-building cases, twelve patch-renderer cases,
eleven material-operation cases, and one initialized probe parser check.
The final affected eleven passed with zero errors, failures, or orphans.
Normal household growth traverses all four stages on days 30/38/45/53 and
completes exactly once on day 60. Intermediate stocks, population, allocation,
history and morphology revision remain unchanged. Exact transforms are
compared independently of batch ordering; the later kit now retains its
already computed transform array for the same headless observability as the
early and town kits.

The private-desktop visual probe uses explicitly labelled prepared plots on
a copy of genuine saved terrain; it is not a claim that those buildings
occurred in the campaign's history. Baseline renderer sources are frozen from
`670a4fee`, with hashes saved alongside the ignored local evidence. Root and
country renderer comparisons share identical camera, plots and terrain.
Capture encoding occurs after frame measurements. Full map-loop timing and
the unmodified saved settlement context are reported separately.

Final GPU review on combined source `1ef466df` passed with no runtime errors;
the isolated probe exited 0. All ten prepared plot IDs were represented in
both rendering paths. All five images were inspected. The foundations are
faint at the chosen aerial scale; the camera yaw makes the specimen rows
diagonal. The four stages are visible in both timber and courtyard buildings.
All map-human batches remain empty. Five fractional updates reused the
installed node (176 microseconds total request time); crossing 50% rebuilt
exactly one patch (maximum observed retained job: 250 microseconds).

The 120-frame frozen-background samples measured the following mean render
CPU times: root 0.960 -> 0.966 ms, country 0.975 -> 1.024 ms. Wall frame time
remained about 20.01 ms at the existing 50 FPS cap. This shows no observed
steady-frame slowdown in this specimen, not zero cost or a universal FPS
guarantee. Drawing previously invisible construction added 45 draw calls.
Cold whole-specimen builds increased from 15.4 to 45.1 ms at the root and
41.0 to 80.4 ms in country rendering; these are uncapped direct probe calls,
separate from normal retained-patch updates. GPU mean times varied downward
between runs; that noise is not evidence of a speed improvement.

The separate live saved-map sample averaged 20.00 ms wall frame time,
1.447 ms render CPU and 4.131 ms GPU, with dynamic draw counts. It is context,
not a controlled before/after comparison. Local ignored evidence is under
`artifacts/building-construction/`: `capture-audit.json`, `preview-final.log`,
its private-runner record, five PNGs, source commit and baseline hashes.
Generated images, renderer snapshots and the copied save are not published.

After the culture-screen merge, its five cases and the four construction
progress cases passed together (report 88): 68 distinct checks across the
feature and integration validation. No save migration or live-player restart
was performed. Save and restart normally through the canonical launcher to
load the delivered scripts.
