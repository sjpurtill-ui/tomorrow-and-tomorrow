# World overview redesign — READY

- Worktree: C:/Users/sjpur/tt-world-screen
- Branch: codex/world-screen
- Base: 95836e061c74ca304fba5665ac1aece7dd5240c3
- Scope: scripts/hud/world_board.gd, scripts/hud/content/dock_content_world.gd, tests/test_world_board.gd.

Recent discoveries lead the overview in a wider column; expeditions, encountered societies and actual rumors occupy the secondary column. One compact toolbar replaces the metric tiles and boxed banner. Empty rumor cards and unavailable diplomacy are omitted; the no-contact state explains how to meet neighbors. Unread returned reports have a NEW marker. The report archive, report detail, scouting dispatch, known-contact records and eligible diplomacy retain their callbacks. Below 850 logical pixels the columns stack.

Validation: Godot 4.7.2 headless, explicit worktree path, GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/test_world_board.gd: 4/4 pass, zero errors, failures, skips or orphans. Covers archive navigation, two dock widths, returned report navigation/live revision and a long title at 500 logical pixels with its action inside the board. Private-desktop GPU capture of the actual dock provider with three fixture reports exited 0 with no engine/script errors. Capture: artifacts/world-overview.png (local, excluded from source delivery).

No save schema or simulation changes. No shared simulation hotspots touched. Potential integration conflicts are limited to the three scoped UI/test files. Generated imports, caches, test reports and probe files are excluded. No player launch, restart or main integration performed. The player branch requires designated-integrator review, integration, combined validation, push and remote verification before this is delivered to the current game.
