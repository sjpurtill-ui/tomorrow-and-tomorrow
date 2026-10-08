# Lived-in yards

Static woodpiles, pottery, drying racks, stored grain and fishing nets now use
the installed root, secondary-town and organic expansion house plans. Houses,
roads and settlement layouts remain unchanged. No map people are introduced.

## Rendering and placement

- One map-wide budget: 32 nearest occupied homes, up to three groups each and
  96 groups total. Five cached meshes/five MultiMesh nodes; the existing ink
  outline may draw each batch twice. There are no per-house scene nodes.
- Hidden above a 0.30 km camera span. No source collection or placement work
  occurs at wider views. A 32 m camera cell controls selection; revisits retain
  placements. Source, completed-surface, fog and occupancy revisions invalidate
  stale data. The cache holds at most 128 homes.
- Reuses the existing woodpile (82 triangles), pottery (192) and drying rack
  (100). New grain baskets use 308 triangles and the net uses 226. Nets use real
  open cells and opaque cord geometry, not transparent cards.
- Placement stays inside the recorded parcel and outside actual building
  footprints and route-width envelopes. Nine samples require revealed dry land;
  steep ground is rejected. Local collision coordinates retain sub-metre gaps
  at planetary coordinates. A house with no valid space receives fewer props.
- Active occupied homes qualify. Construction, vacancy and ruins do not.
  Country parcels explicitly identify representative occupancy without changing
  population records. Live source plots supersede cached occupancy.
- Pottery/drying/storage follow known crafts. Grain also requires an active
  field. Fishing nets require the recorded net craft and revealed physical
  water within the bounded 64 m search. These props represent household use,
  not a new inventory ledger. Knowledge is scoped to each admitted people.
- Legacy EarlyGround/country calls suppress these five kinds so they cannot
  bypass the global cap. Existing public-service furniture remains separate.

## Verification

Source `7e3acaf2`, branch `codex/lived-in-yards`; combined with current Eyes rail
work `135edcb6` at `8c38c677`. Headless results: 82 distinct code tests passed
across reports 93–96, plus initialized GPU-probe parsing. The initial report
found test typed-array mistakes, translated-coordinate expectations and old
legacy-prop expectations; report 94 passed every affected rerun after correction.

`tests/lived_in_yards_capture.tscn` exercises normal terrain wiring using a
read-only saved campaign copy (3,670 people, day 93,035). Run through
`tools/run_isolated_gpu_probe.ps1`, never as the current player game. Final
private GPU run exited 0 on an RTX 4090/Compatibility renderer. Evidence is in
ignored `artifacts/lived-in-yards/` (images, log and `capture-audit.json`).

The near view contained 21 groups: 12 pottery, three woodpiles, three drying
racks and three grain stores. It had zero detected building/route/prop overlaps
or wet footprint samples. Nets were absent because this captured neighborhood
did not meet their location requirements; all five assets were separately
inspected in a labelled specimen. Pan increased the selected props to 27;
returning reused the original world placements. Far view performed no placement
work. All audited map human batches remained empty.

After 120 warm frames, 120 measurement frames per state used identical camera,
terrain and buildings; only yard visibility changed. Mean wall time was
20.010 ms off / 20.006 ms on at the existing cap. Mean render CPU was 1.320 /
1.185 ms; mean GPU was 9.163 / 8.964 ms. These noisy capped samples do not imply
a speedup or zero cost: median draw calls rose from 127 to 135 for four visible
batches. Source preparation reached 6.373 ms, and the observed maximum
cooperative processing slice was 8.502 ms. The 1 ms target yields between homes,
not within source preparation or one placement. Stable views do no placement
or batch rebuild work; other hardware and larger source sets are not benchmarked.

No save format or simulation changes. Existing saves work without migration.
A running player process keeps its loaded scripts; save and restart through the
canonical launcher to load this delivery. No player or editor was restarted.
