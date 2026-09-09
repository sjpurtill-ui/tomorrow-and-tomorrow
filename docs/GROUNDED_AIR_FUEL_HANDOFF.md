# Grounded air missions and flight fuel

READY for integration from `codex/grounded-air-fuel`, based on `705e015b8b5d5ad478175ab0e96c4ddd2bbca77d`, in `/Users/seanpurtill/Documents/Codex/tt-command-order-state`. The source commit is recorded in the canonical integration entry after merge.

Owned changes: `scripts/joint_operations.gd`, `scripts/hud/air_command_panel.gd`, `tests/test_joint_campaign_loop.gd`, and this handoff. No shared integration hotspot changes or conflicts.

A wing whose carrier moves beyond its assigned area's range now reports **Grounded · operating area out of range**, contributes no air control or mission experience, and spends no sortie fuel. Its standing order remains intact and resumes automatically when the carrier returns within range, including after an operations save/load round trip. An active air order without a region also waits without spending sortie fuel. Partial coverage still permits reduced-efficiency missions, subject to fuel availability. The Air command summary separates flight fuel actually used today from the mission's daily requirement and reserve.

Naval travel, carrier ferry flights, airbase transfers, repair-return flights and transport retain their fuel charges. Staff training remains a separate paid policy; grounding a mission does not suspend authorized exercises. Daily mission costs and coverage sampling are otherwise unchanged. This fixes an operational accounting error and its report, not a complete air-war model or numerical HOI4 parity.

Validation against this explicit worktree with isolated userdata `TomorrowGroundedAirFuelTests`:

- The new carrier departure regression failed on the previous code: four grounded fighters consumed four extra fuel. `/tmp/tt-grounded-air-fuel-before.log`.
- **71 tests pass**, zero errors/failures/skips/orphans, exit 0, across `test_joint_campaign_loop`, `test_joint_operations`, `test_training_strategy` and `test_main_map_services`. `/tmp/tt-grounded-air-fuel-tests.log`.
- Four new regressions cover actual carrier travel out of range and return, retained orders/save state and visible fuel reporting, partial coverage and resupply, paid ferry/rebase/repair movement, and missing-region grounding. Existing transport, combat eligibility, replacement, training and separate main-map service checks pass.
- `git diff --check` passes. The owned test override is removed before committing.

No save schema or population changes. No native window was opened or live player/editor interrupted; player PID 15785 was running standalone source `705e015b8b5d` when work began. Headless UI assertions verify the report text and existing map-panel behavior; subjective native usability is not claimed. The running app keeps its bundled code until a user-requested updated launch.
