# Worked country and clustered expansion

The user authorized integration of the basics, then continued visual improvement
through year 3000. Basics were pushed and integrated at `2cb20e63`. The later
correction follows the user's explicit direction: expansion should look like
inhabited clusters that grow together, not oversized lines across the land.

Development checkout: `C:/Users/sjpur/tt-people-grown-land`.
Branch: `codex/people-grown-land`. Canonical: `C:/Users/sjpur/TomorrowandTomorrow`.

## What is drawn

The renderer reads actual engine core/worked/realm reaches, aggregate population,
completed construction, built fabric and resource ledgers. It writes none of
those authorities. There is still one settlement per people; a drawn cluster
is a bounded representative, not a new town, population record or supply node.

At 400 people and above, compact clusters appear around the dense built footprint.
Fixed 180-metre cells retain their positions, and four to twelve small houses
fill stable slots around shared yards and short lanes. Two nearby field plots
and feathered ground connect neighboring compounds as the fringe fills in.
Up to 96 clusters and 48 sparse outer holdings share the original 144-record
limit. Herders remain sparse and single-house. Candidate evaluation stays bounded
rather than scanning an area proportional to the population or realm.

Houses reuse the existing settlement architecture kits at metre scale. Roof
footprints are checked against admitted land; rejected placements are skipped,
never stacked at the centre. Growth retains existing positions, bases and styles.
Each cluster uses at most three house batches and three shared inanimate props.
Cluster chart field-line glyphs are suppressed. One canopy mask per compound
clears the actual yard and field envelope, letting neighboring compounds meet.
This remains presentation; no timber harvesting is recorded by a visual clearing.

OneSeat's core is a working reach, not the extent of dense buildings. Worked
holdings remain between the actual dense visual footprint and worked reach,
including inside the engine's core. At core=worked=120 km, holdings therefore
remain outside the built town. Engine rings are unchanged. Known rivals use
this same rule with their real scoped state; no invented rival homestead ring.
Dense fabric absorbs reached ground. The sample is not a household census.

Real sites retain depletion/regrowth categories and positions. The rejected
quarry ribbons were 166–306 m long and 11–20 m wide. They are removed. Local
irregular scar washes are now at most 60 m nominal radius; rubble patches have
2–6 m nominal radii, at most 6.96 m after irregularity. A 3-km catchment is never
interpreted as a solid excavation or a giant quarry bench.

## Construction progression

`settlement_country_era.gd` samples up to 2,048 recorded plots and retains up to
32 quantized appearance variants. Completed residential fabric supplies masonry,
industrial and modern rural forms from existing kits, capped at two storeys.
Recorded roofs and installed components are retained; chimney knowledge alone
cannot retrofit a house. Older forms remain in the mix. Calendar and population
do not grant materials, machines, construction or knowledge.

The year-1000/2000/3000 graphical specimens use the existing live fabric conversion
fixture and are explicitly labelled prepared construction, not campaign history.
The fixture produces masonry at the first two horizons and modern at 3000. The
existing modern kit stylizes its facade/flat roof; it does not reproduce every
source-material color literally. Same-day morphology revisions refresh player
and admitted rival appearance even while the clock is paused.

## No human map figures

The user's instruction is absolute: no people walking around. Map workers,
children, returned scouts, mourners, processions, builders and boat paddlers are
suppressed. Population/labor simulation is unchanged. Inanimate props, smoke,
fire, wildlife, boat hulls and abstract military symbols remain. Court scenes
are outside this map task.

## Rendering and validation

Terrain paint follows actual regional facets. Its clipping and vertex emission
are prepared incrementally; the old complete patch remains until replacement
is ready. Nearby camera work has priority. Obsolete or newly revealed partial
work restarts safely. Two jobs/frame and a cooperative time budget limit work;
this is not a hard real-time guarantee. View changes can leave remote patches
preparing in the background. Capping physical scars also avoids tessellating
square kilometres of almost transparent paint at a close-house zoom.

The original basic repair removed a 1,356-ms synchronous stall. Basic private GPU
checks measured 5.297–5.935-ms preparation slices. The first clustered capture
peaked at 11.095 ms and showed visible seven-home compounds with zero people,
zero terrain skips and no runtime/shader errors. All five views completed; remote
patch queues were still preparing in some views. Final evidence uses the
`clusters-final` prefix after the smaller physical-scar bound. Those three final views peaked at 6.943 ms, with zero people, terrain skips or runtime/shader errors. The worked-site queue drained to zero; the two close views retained 111 and 93 background replacements while the selected cluster was already visible.

The six-suite clustered regression run passes 78/78 cases: 26 plan, 21 renderer,
nine manager, nine era, nine clipping and four chart. A following 22-case renderer
run adds the scar-size regression. Earlier no-people/living-map/ambience/day-cost
integration checks also passed. Reports and GPU logs remain in task-local
`artifacts/people-grown-land/` and `reports/`.

The prior basic year-100 sample advanced 101 days in 20.061361 s (5.035 days/s,
19.69 fps). A subsequent country-disabled sample advanced 110 days in 20.000297 s
(5.500 days/s, 24.55 fps). These are short single samples, not a controlled
comparison. The requested six-day target remains unverified for the final
clustered build; this work must not be described as a continuous 3,000-year
playthrough. The upstream survey suite independently reproduces one existing
new-ground failure (25/26 pass); its relevant code matches main.

## Delivery limits and compatibility

Actual retained Ashleyfire checkpoints cover 874, 3,665 and 4,554 people. The
original 120-person same-seed reconstruction and population-only 25,000 specimen
are not original campaign checkpoints. No complete four-stage campaign or
continuous year-3000 run has been manufactured or claimed.

No new saved fields or migrations. Aggregate simulation authorities are unchanged.
The shared terrain hotspot changes are scoped to country-layer hooks, masks,
human-figure removal and the previously validated timing/height sampling fixes.
No project settings or save authority is replaced. Canonical local imports and
untracked files are preserved. Integration is remote-first, verified, then a
canonical fast-forward. Running player/editor sessions are never stopped by tests.