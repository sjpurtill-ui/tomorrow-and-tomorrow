# Founding convoy map clarity

Source worktree: `/Users/seanpurtill/Documents/Codex/tt-founding-map-clarity`, branch `codex/founding-map-clarity`, base `418027a1dbcf00148eb2383076bc90d44b6fbadc`. Root is the sole integrator; no concurrent workers. The integration log records the source hash.

The founding convoy now uses the shared map card layer at all four distances, with a small aspect-preserving flag, population and compact water status. The oversized 3D banner and multiline text are suppressed. The card follows the actual moving convoy and opens site review on click; a committed camp keeps its progress action until its city marker replaces it. City cards avoid the open review panel and retain the existing dense-view list fallback.

The review panel has a bounded height, scrollable details and persistent close/founding controls. Long warnings no longer push the action offscreen. First-use guidance points to the convoy card. Nearby known open water is distinguished from confirmed drinking water.

Daily collection distance and founding advice now derive from the same physical water-source projection. A drainage centerline submerged below sea level cannot supply drinking water merely because the mathematical line passes nearby. Fog filtering remains in the advice layer. All civilization starting searches apply the same dry-ground/channel clearance check and water-distance rule; no opponent-specific placement or population rule was added.

Owned files: `scripts/local_terrain.gd` (shared hotspot), `scripts/civilization_start.gd`, `scripts/founding_site_advice.gd`, `scripts/hud/city_labels.gd`, `scripts/hud/founding_site_guide.gd`, three existing test suites, two headless probes and their scenes, `project.godot` (version 2026.09.09.2 only), and this document. No shared-file conflicts.

Validation in this explicit worktree, isolated userdata `TomorrowFoundingClarityTests`:

- 40 focused tests pass with zero errors/failures/skips/orphans: founding water guidance, city-card layout and map onboarding (`/tmp/tt-founding-clarity-tests4.log`). Four new regressions cover submerged drainage, long review/resize, all-distance moving convoy cards and real click routing, and panel avoidance.
- 91 starting positions across seven seeds and 13 seats pass the actual founding assessment (`/tmp/tt-founding-clarity-starts-final.log`). Reproduce with `--headless --path <checkout> res://tests/founding_clarity_probe.tscn`.
- The real normal scene passes startup, all four distances and open-review collision checks, with no script errors or shutdown leaks (`/tmp/tt-founding-clarity-boot-final.log`). At the tested 1280×720 window, the card is 186×65 logical pixels; review is 350×442. Reproduce headlessly with `res://tests/founding_clarity_boot_probe.tscn`. This is a layout/behavior check, not a native screenshot.
- Ownership, distance and dismissal regressions also passed during development. The canonical integration entry records the combined final run.
- `git diff --check` passes. Owned test override removed before delivery.

Save schema unchanged. Existing campaigns load; water access is recomputed from physical sources, so an old coastal site relying on a submerged drainage line may lose that invalid supply. No user game/editor was stopped. A running release retains its bundled code; the updated normal release needs a normal restart. No native visual inspection or broad balance/performance claim is made.
