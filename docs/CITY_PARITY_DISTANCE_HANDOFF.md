# City management, distance controls and building continuity — September 7, 2026

Worker: /Users/seanpurtill/Documents/Codex/tt-city-design-selection
Branch: codex/city-design-selection
Base: 06c236c4a69b65fb88aff374e91c30ee4e5d3621

Added cities now initialize independent founding plots and inherited routes and use
_the same_ plot/early-building/ground renderer as the original settlement. Existing
recorded plots survive. The old generic secondary footprint generator is removed.
Housing, construction, stores, health, demographic growth, economy state and labor
run in city context. Research, diplomacy and national policies remain shared;
GovernmentPeopleSystem remains local leader/labor authority. National military
upkeep is charged once, from the primary treasury. This does not decentralize the
existing military campaign/fortification system.

City vital changes update national totals by delta while keeping other cities'
headcounts constant. City cohorts, pregnancy state, fractional remainders and
vital history persist. Daily catch-up now sets the actual day for every iteration,
so primary and added cities receive the same number of updates at higher speeds.
HUD population displays overall and selected-city counts simultaneously. Map
notation is consistently name + population, or the foreign report's estimate (or
unknown); it does not disclose hidden foreign population. The age-based “founding
settlement” classification is removed. Local overview/health/history read local
state; the full population ledger remains an explicitly civilization-wide view.

## Recovered distance specification

Source: “Set Up Godot Project”, user turn 01a0790a-81fc-7820-a509-955a65c999f2,
and subsequent calibrated-altitude correction. Agreed views are 10,000 feet,
50,000 feet, Region and Continent. The corrected study uses a fixed 50-degree
horizontal field of view, looking vertically down. The two altitude views cover
2.842611486 and 14.21305743 km horizontally. Region (150 km) and Continent
(3,000 km) are implementation spans; the original four-level discussion did not
specify numeric spans for those two levels. The 150-km breadth also appears in
“Elegant Resource Displays”.

A visible selector and ordinary scroll/pinch/+/- advance one distance at a time,
with a 650-ms burst guard. Shift-scroll/+/- provides gentle continuous inspection.
Logarithmic transitions are speed-limited and preserve the pointer location.
Keyboard travel and rotation are slower. City selection uses the close preset.
Existing debug aerial inspection and specialized campaign cameras remain available.
This uses existing mesh LOD, plot detail budgets and culling; it does not implement
new baked region textures or establish continent-scale FPS/memory performance.

## Building continuity

Vacant intact kit buildings remain visible. The live renderer records bounded
physical sites in the existing saved plot dictionaries. Subsequent layout reserves
those sites before adding new ones; occupancy, road width changes and unrelated
new plots do not regenerate occupied houses. Pure layout APIs remain read-only.
Explicit built-form changes can still replace a building, and destruction remains
visible through existing damaged/ruin paths. Completed Lean-to Shelters still
converts founding households at the monthly synchronization; that actual
construction transition has not been changed into a new multi-stage project.

## Verification and integration

Worktree: 91/91 cases pass, zero errors/failures/skips/orphans, across city resources,
secondary city integration/save/load, early and organic visuals, settlement model,
and distance controls. /tmp/city-parity-release-tests.log.
Real terrain camera navigation probe passes cumulative fine zoom, no overshoot,
pointer anchoring, north resets and retained terrain streaming:
/tmp/camera-navigation-final.log. Probe exits normally but reports two ObjectDB
instances/one resource still in use at shutdown; no gameplay script errors.
Additional population-demographic suite passed its 18 cases but emits its existing
out-of-tree GameState fixture warnings; not included in the clean 91-case claim.

Tests ran headless with an isolated application name and Dummy audio. New fields
are optional dictionary members serialized by existing saves; old city resources
backfill missing defaults without copying home inventory or replacing built plots.
Round-trip checks use numeric tolerance for the existing JSON save precision.
Legacy local vital totals start when local tracking begins; earlier totals are not
invented. No save-schema bump. No unrelated UID files committed.

Shared conflict areas: scripts/local_terrain.gd; settlement_model.gd population
scope, founding plots/routes and per-city daily loop; early/organic visual layout.
The other task's READY affordable-infill change 69d9db9 is not included here.
Canonical integration and launch must be recorded separately after verification.
