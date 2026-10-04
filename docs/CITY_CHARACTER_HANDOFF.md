# City character: facade checkpoint

Worker: `codex/city-character` in
`C:/Users/sjpur/.codex/worktrees/court-chapter-policy-tests/TomorrowandTomorrow`,
based on `05c9ecce98486738b60236844dc51dc4dcdc1aba`.

Three deterministic modern facade treatments replace the repeated cream window
grid: pale grouped bays, warm horizontal bands, and cool vertical piers. Their
choice comes from the recorded plot seed. The existing type, floor count,
structural envelope, roof vertices and roof-provenance selection stay unchanged.
Modern glazing has restrained sky colour and a separate roughness/specular
response; its internal edges no longer receive heavy silhouette ink. Early
meshes and their shared material keep the prior treatment.

Validation: four focused city-character tests pass (determinism, record
immutability, common envelopes/exact roof vertices over all eight modern types
at 1/3/8/18 storeys, preindustrial variant neutrality and material isolation).
The existing architecture/evolution suites passed 14 cases during development.
Private same-camera GPU capture PID40864 exited 0 with no script/engine errors:
16 dated city frames plus the paired roof-outline check under
`artifacts/city-character-facades/`. Year-zero PNG is byte-identical to the
previous verified swatch; later snapshots are not a full economic simulation.
The year-3000 view visibly separates the three families while keeping the same
recorded skyline. No GPU process remains from this capture.

This first checkpoint excludes the ongoing LivingMap/path/smoke work. No
simulation, save format, terrain, population ownership, weather, or player
launch changes. Generated imports and captures are local evidence, excluded
from the commit. Only the integrator can deliver this worker branch to main.

## LivingMap checkpoint

Workers now approach the front edge of the renderer's saved building footprint,
use active street waypoints and detour around expanded building footprints.
The pure placement helper owns only disposable presentation geometry. It keeps
at most 512 detailed obstacles and reserves every remaining footprint inside
one conservative blocked envelope. Search uses the nearest 32 detailed obstacle
boundaries, at most 64 street points and at most 322 total graph points, and
caches at most 128 paths. An unresolved/blocked route
holds the representative rather than crossing a wall. Aggregate parcels with
no detailed footprint are conservatively reserved as whole parcels. Geometry
or route changes invalidate the cache; normal refreshes retain identities/counts. Walking
uses distance along the path with terrain samples every three metres. Children's
short play runs reject building/water crossings as well. All usable saved home
frontages participate in placement, avoiding a crowd at the first home of a
multi-building parcel without increasing the representative population.
Same-day roof/storey/material/parcel changes also refresh geometry and smoke.
Existing children retain their identity and valid play legs; new construction
rehomes a covered child or cancels a newly blocked remaining leg. If no home
frontage is usable, a bounded search checks the old camp ring, actual frontage
and lane points, and finite outer rings out to 600 metres. Every candidate must
be outside obstacles and on land. If none passes, ordinary worker/child visuals
are omitted until safe ground returns, without changing the real population,
labour allocation or officials.

Smoke now comes from actual chimney-cap geometry at its rotated position and
roof height, or an actual open-hearth record/camp. Modern vents, unfinished,
structurally destroyed or aggregate buildings do not invent chimneys. A modern block without a hearth
record has no phantom central flame/firelight. Existing worker/plume ceilings
and GovernmentPeopleSystem labour allocation remain authoritative. No new
population, building, research, resource or save records are written.

CPU validation: combined architecture/facade/evolution/life suites passed
34/34; the final placement/life rerun with conservative aggregate handling passed
17/17 (`artifacts/city-character-life-final-tests-2.log`, report34). The boundary
follow-up passed 18/18, including 516 footprints, 100 nearby routes, and all
recorded home frontages. Final lifecycle/safe-fallback validation passes 21/21
(`artifacts/city-character-safe-final-tests.log`, report40), with zero
script/engine errors or orphan nodes. It covers same-day roof height/removal,
aggregate parcel changes, covered/blocked/unaffected child play legs, and
complete overflow enclosure followed by safe restoration. The current prepared
full-city fixture routes 29/29 sampled pairs around 142 detailed/aggregate
obstacles in roughly 126 ms total cold search time. A live-layer regression
also samples worker travel/terrain following and unchanged actor counts.
The short two-era CPU visual probe passed before the final safeguards.

Private capture entry: `res://tools/city_life_character_capture.tscn`, using
`tools/run_isolated_gpu_probe.ps1` with this explicit worker project and
`--out=res://artifacts/city-life-character`. This prepares four real-rendered
three-storey parcels in each era and records 20 frames per era. It is a visual
fixture, not the player game or an economic progression simulation. The initial
40-frame probe, PID38220, exited 0 with zero script/engine errors. Its masonry
view has seven bounded plumes at actual chimney caps; modern has zero plumes or
phantom hearth. Every sampled worker remained outside recorded footprints.
Images are under `artifacts/city-life-character/`. Review identified first-home
crowding, corrected by the tested all-frontages change above. Final recapture
PIDs49584 and69956 both failed before renderer initialization with exit
3221226505 and only the Godot banner in their logs. Both exited; this last
distribution change is CPU-verified but its final pixels remain unverified.

Limits: conservative whole-parcel/overflow obstacles and bounded local graph
search can hold a representative in unusually crowded/disconnected layouts.
The 142-obstacle performance fixture is not a claim of exhaustive large-city
coverage. The private probe uses flat ground rather than the live landscape.
Workers use the existing minimum 0.6-second leg duration. This does not change the
separate scripted scout-return/burial-procession paths. Roof style/provenance,
terrain generation, simulation owners and all save formats remain unchanged.
