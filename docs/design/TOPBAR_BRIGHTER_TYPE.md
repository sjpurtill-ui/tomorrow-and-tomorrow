# Brighter transparent top bar — October 5, 2026

HELD for the user to review the rendered example before game integration.
Branch `codex/topbar-brighter-type`, base `1df2277270556b175377fbe6933dbccbc25ec8b5`.
Worktree: `C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow`.

The user likes the transparent bar but finds its small muted type unreadable.
Normal top-bar text is now near-white ivory (`#fffef8`). Readings use 24px
semibold Garamond instead of 20px regular; captions use 12px strong Barlow
instead of 10px. The town name is 22px semibold and the clock 18px strong.
Pause and speed controls gain stronger, brighter lettering. A one-pixel dark
edge and short shadow separate the brighter strokes from pale terrain without
adding a backing panel. Warning and shortage colors are retained.

At compact widths, familiar units shorten only when a full value would not fit:
`225 days` becomes `225 d`, `31 winters` becomes `31 yr`, and PEOPLE/LORE
omit redundant `souls`/`known`. Full readings remain in hover/accessibility
accounts, and return automatically when space is available. Reading gaps
shrink from 10px to 8px; the persistent bar stays 45px high. Data formatting
at its authoritative source, simulation, save format and terrain are unchanged.

The private GPU harness renders actual HUD controls over terrain from the
user's earlier screenshot, with explicitly prepared values. Dark terrain is a
modulated contrast stress check, not a capture of the running player's camera.
Both 1920px and 1280px widths are captured. The harness hides MapTopTint to
exercise fully transparent lettering; production transparency is unchanged.

Owned files: `scripts/hud/topbar_ink.gd`, `folio_readings.gd`, text setup in
shared `command_rail_hud.gd`, existing reading tests and preview harness,
and this delivery record. Review the shared HUD file carefully at integration.
Generated captures, imports, logs and test userdata stay local. No player or
editor is restarted, and canonical main does not include this preview yet.

Evidence: `artifacts/topbar-brighter/{pale,dark}-{1920,1280}.png`,
`artifacts/topbar-brighter-tests.log`, `artifacts/topbar-brighter-preview.log`.
Reproduce through `tools/run_isolated_gpu_probe.ps1` with
`res://tests/topbar_contrast_preview.tscn`, `--topbar-preview --map=<screenshot>`,
and isolated acceptance userdata. Headless suite: `test_folio_readings.gd`.

Validation: 4/4 existing HUD tests pass with zero errors, failures, skips or
orphans (report 24). The narrow-layout case now also measures the rendered
value text against each reading's actual width, including later-era decimals;
when necessary `12.0 d`/`46.4 yr` compact to `12.0d`/`46.4y` without rounding.
Private GPU probe PID 43952 exited 0 with no script/engine errors after capturing
all four prepared examples. Final decimal-only shortening was then verified
headlessly; it does not change those earlier-era captured readings.
