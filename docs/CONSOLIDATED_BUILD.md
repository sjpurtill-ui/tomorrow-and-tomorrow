# Consolidated playable build

This build starts from the current `C:/Users/sjpur/TomorrowandTomorrow` game,
checkpoint `bac2035`, and merges the OneDrive work checkpoint `d085c74`.
Both source histories are preserved as parents of the integration commit.

The current Command Rail HUD, named civic leaders, save system, planet terrain,
city-local resources, and military progression remain authoritative. Overlapping
older implementations were superseded rather than restoring the old interface.
The new military artwork is included with bounded representative army formations
on the map. Rendered positions continue to respect the current runner-report
visibility rules instead of revealing live positions of unseen armies.

Conversation changes are applied to the actual current civic path as well as
the new council/office conversation panel. Terra receives up to eight recent
messages of 400 characters, a 2,800-token completion budget, and a conversational
role. Clear historical directives proceed to deterministic simulation assessment
without repeated ethical questioning or personality-based execution vetoes.
Ambiguous meaning still asks for clarification. Costs, resistance, casualties,
capacity limits, and implementation follow-ups still come from the simulation.
Older saved pending discussions can be resolved after loading.

The new office conversation service retains its own draft/acceptance flow.
The existing settlement Civics interface continues to execute clear orders
through its existing local implementation and feedback systems.

The statistical decree update exposes current simulation statistics and six
bounded writable metrics (health, cohesion, knowledge, security, ecology,
legitimacy). Terra proposes immediate deltas, uncertainty ranges and causal
reasons. Validated proposals replace immediate catalog metric defaults, then the
engine scales the mean by implementation capacity and clamps the resulting
metric. Uncertainty describes the model assumption; it is not a measured confidence
interval or a sampled outcome. Other statistics respond through existing systems.
New games ask Terra by default; the existing routing switch remains available.

Counted executions preserve the literal count and whole-word demographic scope.
Workers come from the aggregate working-age cohorts. These are one-time actions,
not standing repression policies. The full count must fit the eligible population
and enforcement capacity, otherwise no action or statistical effects are applied.
An execution removes population, updates vital statistics, and creates a death
record linked to its order. The Population Ledger displays those records. Reports
distinguish an actual counted result from uncertain downstream effects and expose
observed numerical changes without claiming exclusive causation. Saved historical
reports are preserved; no deaths are fabricated retroactively.

Validation includes 71 government/directive/conversation/implementation tests, leader-conversation
runtime, city-civic runtime, save/load, warfare-map runtime, and all 27 unit imports
with 108 animated clips. A live Terra conversation request also returned a valid
substantive answer, and a live recruitment order mapped correctly on its first
attempt. Headless scene probes retain the pre-existing renderer resource
cleanup warnings seen on the source build; their assertions pass.

Launch with `tools/launch_game.ps1` from this checkout. The launcher reads the user
credential without saving it and uses the configured model (default Terra).
Starting a new session does not delete existing saved games.

Other tasks continued editing the original folders after these checkpoints.
Their later battle-screen and rock-detail changes are not silently copied into
this tested snapshot; they remain in the original working trees for the next build.
