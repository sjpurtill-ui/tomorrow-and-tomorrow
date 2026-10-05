# Food folio — held for visual approval

October 5, 2026. Prepared on `codex/food-folio`, based on canonical main
`222f43ca74d6cc9cbae558cbef32a2f932d8bd10`, in
`C:/Users/sjpur/.codex/worktrees/food-folio/TomorrowandTomorrow`.

The user called the Food page inefficient and identified its single-town
"All from Ashfire" breakdown as redundant. The new Food renderer pairs food
and water, presents today's actual production, consumption, spoilage and net
change together, and reduces fresh/stored food to two rows with care details.
It reuses the existing illustrations without repeating them beside each stock.
The gain/loss sentence uses the recorded net rather than calling a small gain
on a large stock "what comes in matches what is eaten". Existing urgency colors
and shortage forecasts remain. Departing-party rations get a line when nonzero.

Gathering & preparation keeps the actual source/processing report accessible.
Water access and history remain available. The deliveries link appears only
when the selected settlement's trade snapshot has shipments or history.
All worker-direction callbacks remain GovernmentPeopleSystem-owned.

Food's common-store renderer is a compact derivative of the existing purse
board: a ration balance, expected seasonal net and an explicit distinction from
town stores. Contributions, spending, levy controls and history are behind a
persistent disclosure. Single-town source bars and "All from Ashfire" disappear;
uncollected amounts remain available, and multiple sources still get a breakdown.
The ordinary Wealth purse board is unchanged. No simulation, save schema,
population or account ownership changes. Shared integration files are
`scripts/hud/dock_blocks.gd` and `scripts/hud/content/dock_content_economy.gd`.

Validation: 14/14 cases passed across `test_food_folio.gd` and
`test_home_docks_plain.gd` (report 2); the final urgency-preserving wording change
passed all three focused cases again (report 3). Coverage includes live values,
shortage readings, direction callbacks, delivery visibility, retained allocation
controls and persistent disclosure state. An initial fixture mutated the same
dictionary already owned by the widget; it now supplies a fresh dictionary like
the live provider. Initial new-file parsing/encoding errors were repaired.

Private GPU captures passed in dark and light at 1536px and dark at 1138px.
The initial reserve heading wrapped to one character per line; its width is now
measured without wrapping, and corrected captures show the full summary.
The final dark capture also aligns its prepared top-bar figures with the page.
These are prepared figures in the actual HUD shell, not a live campaign capture.
The common reserve forecast still comes from the prepared simulation's account.
Existing player/editor sessions were not restarted.

Reproduce through `tools/run_isolated_gpu_probe.ps1` with the explicit worktree,
`res://tests/food_folio_preview.tscn`, custom userdata containing `acceptance`,
and `--food-preview --mode=dark|light --width=1536|1138`. Captures are under
`artifacts/food-folio-<mode>-<width>/food.png`. Logs and reports remain local.
No screenshot, save, import cache or generated UID is part of this delivery.

Status: HELD pending the user's requested visual approval. The separate
top-bar contrast preview is not included; neither preview is integrated by
this branch publication.
