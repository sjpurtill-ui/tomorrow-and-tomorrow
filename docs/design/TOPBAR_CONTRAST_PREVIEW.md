# Transparent top-bar lettering — held for approval

October 5, 2026. The user likes the transparent bar but finds its pale lettering
hard to read over the light map at high altitude. This isolated preview adds a
two-pixel dark outline and a small shadow to the existing readings and date;
town names and speed buttons receive the same outline. Small reading captions
use full cream opacity. Speed hover, focus and pressed text stay light so the
dark outline remains useful. Warning and shortage value colors are retained.
No map tint, panel opacity, geometry, sidebar, ledger or simulation changes.

Branch: `codex/topbar-contrast`.
Base: `222f43ca74d6cc9cbae558cbef32a2f932d8bd10`.
Worktree: `C:/Users/sjpur/.codex/worktrees/topbar-contrast/TomorrowandTomorrow`.
Owned runtime files: `scripts/hud/topbar_ink.gd`, `folio_readings.gd`, and the
text setup in shared `command_rail_hud.gd`. Merge this shared file carefully.
Save format and compatibility are unchanged.

Validation: all four existing `tests/test_folio_readings.gd` cases passed
(report 1, no errors, failures, skips or orphans). These cover reading parity,
live warnings/focus, era and narrow layouts, navigation, and speed actions.
The private GPU preview exited 0 with no script/engine errors. It renders the
actual HUD controls over terrain from the supplied screenshot, with prepared
values. The dark comparison uses that terrain darkened for a contrast stress
check, not a claim to capture the live close-up renderer. The preview hides
MapTopTint to exercise the fully transparent case in the user's screenshot;
production tint code is unchanged. No live player/editor was restarted.

Reproduce with `tools/run_isolated_gpu_probe.ps1`, this explicit worktree,
`res://tests/topbar_contrast_preview.tscn`, and user arguments
`--topbar-preview --map=<absolute screenshot PNG path>`. Use an ignored
override.cfg with custom userdata containing `acceptance`. Captures are
`artifacts/topbar-contrast/pale.png` and `dark.png`; tests and GPU logs are
`artifacts/topbar-tests.log` and `artifacts/topbar-preview.log`. These generated
files and the user's screenshot stay local. First cold editor import reported
missing font loaders before importing assets; subsequent tests and GPU run
compiled and executed successfully.

Status: HELD for the user's requested visual approval. Publishing this task
branch is backup/review delivery, not integration into the player game.
