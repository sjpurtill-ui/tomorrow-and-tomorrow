# Settlement views without decorative people

October 5, 2026. HELD for the user's requested visual review before integration.
Branch `codex/settlement-without-figures`, based on
`1df2277270556b175377fbe6933dbccbc25ec8b5`, worktree
`C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow`.

The user asked to cut the oversized, modern-looking people from town/city views.
Settled map scenes now hide the decorative worker, child and event-walker
batches from LivingMap, great-work builders from MapAmbience, and walkers
around map rites. The live Overview shares that same world, so it also shows
the settlement without those stand-ins. Visibility is gated on committed
settlement state, including the first frame after founding and paused scenes.
The pre-settlement travelling group retains its existing presentation.

This changes visual visibility only. Aggregate population, civic labor,
construction, court characters, adjudicated events and all saved ledgers remain
unchanged. Smoke, hearth flames, wildlife and buildings still render. Existing
History photos remain historical records; new captures reflect the clean view.
There is no save-format change and no migration.

Owned runtime files: `scripts/living_map.gd`, `scripts/map_ambience.gd`, and
`scripts/rite_marks.gd` (map-only figure visibility). Existing tests and the
living-village preview harness cover the change. No local_terrain, project
settings, simulation authorities or terrain assets are edited.

Validation: 22/22 living-map and map-ambience tests pass with no errors,
failures, skips or orphans (report 25). The existing worker case now verifies
that settled figures hide while smoke/hearth remain, population stays 120,
and the founding group can still render before settlement. The construction
case retains its count/bounds checks and verifies that its people are hidden.

Private GPU evidence uses the same isolated saved-campaign fixture as the
approved living Overview through `tests/living_village_preview.tscn`. It checks
all four decorative figure batches, constructs a temporary map-rite group to
verify its visibility gate, and checks actual building rendering, album
capture, camera restore, Visit and save serialization. Capture outputs are
`artifacts/settlement-without-figures/{overview,overview-narrow,history,visit}.png`.
Logs are `artifacts/settlement-figures-tests.log` and
`artifacts/settlement-figures-preview.log`. Generated evidence, import caches,
and isolated saves remain local. No player/editor is restarted.

The separate brighter-top-bar preview remains on `codex/topbar-brighter-type`
(`f23e0b0c`), awaiting its own visual approval; it is not included here.

GPU result: probe PID 21124 exited 0 with no script/engine errors. All visibility
checks passed; the actual fixture still renders 83 building representatives,
records its view, and passes the Overview/History/Visit/save checks.
