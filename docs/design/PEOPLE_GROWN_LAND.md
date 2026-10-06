# One people, worked country — visual review branch

Status: **Integration authorized by the user; basic rendering fix under final verification.**
Worker checkout: `C:/Users/sjpur/tt-people-grown-land`.
Branch: `codex/people-grown-land`.
Base: `a3579bb51c3960cc43a6357268af73eb4353294a` (`origin/main` at task start).
The user has now authorized merging the basics and continuing visual progression
through year 3000. The original visual-review hold is superseded by that request.
The previous checkpoint's 1,356.197-ms cold site build is replaced by incremental
preparation: terrain clipping and vertex emission run in cooperative frame
slices, with the old complete patch retained until replacement is ready. Work
near the camera has priority. A fine-grid stress check preserves all 150,831
vertices with zero clipping skips; its longest call is 17.268 ms, versus a
3.039-second synchronous build. Total work is spread out, not eliminated.
GPU verification and canonical integration are recorded below when complete.

## What the map draws

`settlement_country_plan.gd` reads the current world's actual `OneSeat`
core/worked reach, `RealmReach` border reach, aggregate population, known
construction, built fabric and real resource-deposit records. It writes none
of them. The existing dense town, districts, parcels and recorded architecture
remain the town's fabric. `settlement_visual_extent.gd` supplies its continuous
physical extent; the engine's larger core **working radius** does not stretch
metre-sized houses into kilometre-sized buildings.

At 400 people and above, a deterministic sample of homesteads occupies the
worked annulus. Acceptance follows people per square kilometre, falls outward,
and varies by bearing. Fixed jittered cells preserve surviving homes' positions
when rings grow. There is no hard circle, settlement label, extra town, or
population-sized collection of meshes. Under 400 there is no homestead band.
The existing founding cluster and fields remain; actual worked deposits still
draw. Very sparse herders beyond the worked band have only short local tracks.

The sample is bounded per visible people: 144 homesteads, 10 herders and 96 real
sites, across at most eight admitted peoples. Sites retain a mixture of active
work, exhausted scars, idle workings and genuinely regrowing renewable sites.
Their positions are the ledger's positions, never visual guesses. Woodland
cutting also uses the existing canopy mask and close harvest detail; admitted
rivals now feed the same canopy mask. Paths branch toward nearby farmsteads.
Their surface follows known transport techniques and softens outward.

Country buildings reuse the existing architecture kit with its metre-to-km
transform. Actual dwelling-grade shares and known construction techniques gate
timber, earthen and stone forms. Rivals use their existing forms and colours.
Ground is softly painted, irregular, terrain-draped and clipped to revealed,
buildable land. There is no new lighting or day/night system.

The nearest 16 eligible household clearing cells may also enter the existing
32-area canopy mask. A farm uses 13 cells: one yard and three along each of its
four plots. Those cells and the actual woodland sites are sorted together by
distance before the combined 32-area cap. This is a presentation-only clearing
list; it does not add harvested sites or alter resource records. The shared
budget can leave more distant sampled fields under canopy. HUD resource
descriptions and harvested-site stumps continue to use actual woodland records.

The user's later instruction is absolute: **no people walking around**.
`map_people_policy.gd` suppresses all human map figures, including workers,
children, returned scouts, mourners, rite processions, great-work builders and
boat paddlers. Scout walker icons are removed. Fire, smoke, wildlife, wagons,
boat hulls and abstract military/chart symbols remain. Population and labour
simulation continue normally. Court scenes are outside this task.

## Follow-up visual repair

The user rejected the nearly blank 0.8-km homestead view and featureless worked
site. The initial homestead clearing was roughly **0.53–1.63 km across** around
one or two metre-sized roofs. The repaired layout has four separate plots and
a **25-m-radius yard inside a 100–180-m-radius envelope**. Seeded angle and
distance variation leaves paths and gaps between the plots; surviving
representatives keep their positions and counts. Herder layouts remain smaller,
with one plot. Household shadows, woodpiles and knowledge-gated querns provide
close detail without adding people or new simulation entities.

Country ground ink is now **0.20 m above the sampled terrain**, reduced from
2.5 m, so it no longer covers the lower parts of the houses. Field strips and
short yard paths replace the large overlapping washes. Real worked sites now
have bounded irregular cutting or quarry marks inside their recorded catchment;
their positions, depletion categories and resource amounts are unchanged.
Ground triangles are clipped along the actual regional mesh's cell edges and
alternating diagonals. Each clipping call visits at most 64 intersecting cells
and scans at most 128 row slabs; large triangles use at most six levels of
longest-edge bisection. A thin diagonal track counts its intersected row spans,
not its much larger bounding rectangle. Off-view paint is omitted until the
next settled camera update. This replaces the recursive height-probe approach
from an intermediate, rejected repair, but the current cold build still stalls.
The 20-cm lift covers the measured 11.8-cm planetary-coordinate rounding error;
house bases remain above the paint. An empty clipped surface is handled safely.

The close-crown shader also had a planetary-coordinate precision bug: its hash
multiplied large world coordinates before taking fractional parts, collapsing
the result to zero at the reviewed farm. It therefore retained every crown,
even where the ground canopy mask showed a clearing. The shader now bounds the
hash input first and treats zero retention as zero crowns. Complete plot
footprints, including rotated ends and corners, are covered by the clearing
cells, with feathered margins outside. Existing crown materials receive mask
updates without rebuilding tree chunks. Close panning refreshes the nearest
mask cells every 160 m; broad views retain the 8-km refresh grid. These changes
do not record fictional felling or change timber availability.

A retained chart layer adds a few field, pasture, woodland or quarry strokes
at the same admitted records for regional views. Its mesh topology stays fixed;
the shader sizes the ink from the camera, while houses retain their physical
metre scale. The implementation uses a nominal 14-pixel diameter with a 4-km
cap. Actual same-frame chart-on/off GPU comparisons show farm marks 8–12
pixels wide at 100 km and 7–10 pixels at 300 km. The marks use the map's muted
brown ink; no town circles, labels or people are added. The shader fades them
out again at continental spans. Coincident resource records can still overlay
their different glyphs near the core; visual approval remains the user's.

## Retention and cost

The manager checks a constant-size frame key and captures relevant state at
integer-day or view/source changes. A deposit-category signature is linear in
real deposit count, once per refresh rather than per frame. Ordinary extraction
amounts and worker-count fluctuations within the same visible state do not
rebuild geometry. Plans are cached independently of fog/surface refreshes.

`settlement_patch_renderer.gd` installs bounded replacements while keeping old
geometry attached. Country layers share a cooperative two-job frame budget.
One job cannot be preempted; a cold or changed terrain view can still cause a
longer individual frame. Fog rebuilds previously clipped patches and newly
revealed endpoints; fully revealed unchanged patches remain retained. Terrain
draping updates after camera motion settles. No geometry is rebuilt merely
because the population advances another day inside its visual bucket.

Measurements and screenshots are in the task's local
`artifacts/people-grown-land/` directory. Generated images, caches and private
saves are intentionally excluded from Git. `REVIEW.md` there is the visual
review index for the original checkpoint; `REPAIR_REVIEW.md` supersedes its
rejected farm/site images. JSON records carry source-save hashes, exact population/day,
camera spans, renderer counts and figure audits.

## Repair verification and prior-checkpoint performance

The focused repair checks comprise **60 passing cases**: 17 plan, seven manager,
13 renderer, four chart, two canopy integration, four close-woods, four
harvest-detail and nine terrain-clipping cases. They cover stable compact layouts, plot separation,
land/fog admission, the canopy budget, live crown-material updates and unchanged
resource records. Canopy coverage checks sample 12,320 points across 40 layouts,
including plot ends and corners. These tests do not establish final GPU
approval or rendered playback speed.

The final private GPU run (`repair-ground-final.json`) exited successfully,
with no runtime or shader errors. All four captures have zero human figures,
zero pending jobs and zero terrain-clipping budget skips. The farm has four
fully painted plots. Its cold patch peak is **1,356.197 ms**, attributed to
`sites:site:player:stone_51`. This exceeds an acceptable interactive frame and
remains unresolved. Regional chart visibility was separately verified at
30, 100 and 300 km. No fresh year-100 speed test was started. Work stopped at
this held checkpoint; the player game remains unchanged.

At the prior checkpoint `42f55e05175302393c946e690925bec980f4899c`, 74 unique
tests passed: 30 country plan/renderer/manager cases, 35 human-figure and existing
map cases, and nine day-cost/height-sampling/frame-budget cases. The latter 35
and nine are unchanged by this repair; their earlier results are not presented
as a new rerun. Reports 12, 13, 14 (manager rerun) and 15 are retained locally.

**All performance figures below belong to that prior checkpoint, before this
visual repair. They do not validate the current repair's performance.**

The real year-100 campaign has 636 people, 104 deposits and 12 rival actors.
The prior checkpoint's last private-desktop GPU sample, at speed 5 with a fixed 100-km camera
and HUD hidden, advances **120 days in 20.003186 seconds: 5.999044 days/s**
(about 6, the configured calendar rate). Two simulation days warm up before
measurement. It draws 41.39 frames/s, with median 20.091 ms, p95 47.165 ms and
maximum 78.115 ms frame intervals. Country patch builds rise only from 130 to
132 over those 120 days; no pending jobs remain, and the human batches stay
at zero. This short sample near year 100 is **not a continuous validation
through the first 100 years** and does not establish a strict lower bound of
6 days/s. Source: `year100-final.json`.

Before that checkpoint's timing/height fixes, the equivalent country-enabled sample
was 5.136 days/s; a country-disabled ablation was 5.038 days/s. These are single
samples, not a statistically controlled comparison. The local terrain fix
counts the final simulation pump and its presentation before estimating the
next day's frame budget, and avoids procedural height work that cached ground
immediately replaces. No speed constants or simulation rules were changed.

| Measurement | Year-100 save | 4,554-person save |
|---|---:|---:|
| Unchanged country frame check | 3.296 microseconds | 3.255 microseconds |
| Integer-day country refresh | 1.687 ms/day | 2.776 ms/day |
| Initial country snapshot/plan request | 5.521 ms | 19.598 ms |
| Patch builds before/after 200 unchanged day checks | 57 / 57 | 100 / 100 |

Those manager measurements use the actual frozen states and real fog with
flat draw geometry; they advance the day gate only, not the simulation. State
hashes remain unchanged. Separately, a 30-day headless simulation sample near
year 100 costs 99.692 ms/day (10.03 days/s), after two warm-up days. It excludes
GPU rendering. Sources: `country-layer-perf.json` and `year100-pace.json`.

Cold terrain-draped patch creation remains a hitch risk: the prior detail
retest peaked at **94.469 ms for one patch** (earlier full captures: 95.486 ms).
The two-job cooperative limit cannot preempt a single build. A 2-ms processing
budget is not a guaranteed frame-time ceiling.

## Evidence and limits

The same Ashleyfire campaign (seed 1811640852) has genuine retained checkpoints
at 874 and 3,665 people, plus the exact before/after moment at 4,554. The
120-person reconstruction starts a new campaign with that same seed. The
25,000-person specimen changes the aggregate population of the saved campaign
for a bounded rendering check; it does not invent centuries of site, knowledge,
town or built-fabric history. **Those two specimens are not the requested
original-campaign checkpoints.** Full four-stage campaign acceptance remains
unfulfilled, and this delivery must not be described as approved or complete.

There is another mismatch between the brief and current engine: `OneSeat`
returns zero homestead rings in a rival scope. This branch retains that factual
core-only worked reach. Known rivals draw their real sites and sparse claimed
country, but cannot honestly display a simulated wider homestead band. No
rival simulation rule or intelligence/save schema was changed. Their existing
close-core renderer also retains its original 128-house early architecture.

For populations large enough that core and worked reach both hit 120 km, the
engine leaves no homestead annulus. This visual layer does not invent one.
The current saves also concentrate actual worked sites near the town even when
the worked ring is much wider; the renderer does not move them outward.

The sparse country sample is deliberately incomplete. It is not a household
census or a parcel ownership record. Terrain/water masking can omit sample
locations; there is no relocation into fictitious sites. Extremely narrow
terrain features between mesh samples and the pre-existing regional ground
resolution remain limits of the map's surface rendering.

## Integration surface

Shared hotspot changed: `scripts/local_terrain.gd` only — create/process the
country layer, include admitted rival woodland ledgers and presentation-only
farm canopy clearings, remove scout walker creation/copy, and correct measured
day-cost accounting plus redundant ground sampling. The follow-up also fixes
the crown-mask hash and close-camera mask refresh cadence. `project.godot`,
`save_system.gd`, `game_state.gd`, all population,
production and site-opening authorities are unchanged. There are **no new saved
fields** and no save migration. Local `override.cfg` isolates capture userdata
and is excluded from the branch. The canonical checkout was not edited or
launched, and no player's editor/game was stopped.

Other changed map presentation files: `foreign_settlement_visual.gd`,
`living_map.gd`, `map_ambience.gd`, `map_life_ink.gd`, `rite_marks.gd`; new country
plan/manager/renderer, ground and chart shaders, chart strokes and map-people
policy; focused tests and
the private capture harness. Reconcile those files deliberately if other map
work is integrated before this branch.
