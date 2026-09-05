# One current game

The player build is `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`. Start it with `tools/launch_game.ps1` or the desktop **Play Tomorrow and Tomorrow** shortcut. The OneDrive repository is archived reference material. Files being newer by timestamp does not establish that their whole system should replace another version.

## Work cycle

1. The integrator finishes and commits the current main checkpoint.
2. Assign a bounded task and file/system ownership to each worker. Workers create Git worktrees from the latest integrated main on `codex/<task>` branches. Never create a second copied project folder.
3. Workers inspect current behavior, implement their task, run relevant tests against their explicit worktree path, and commit only their changes. Generated captures stay in artifacts or out of source commits.
4. Workers return a commit hash and handoff. The integrator reviews and merges/cherry-picks one task at a time, resolves conflicts deliberately, tests the combined result, and commits main.
5. Launch the canonical game only after integration. A worker's isolated preview is not the player build.

If two tasks touch a shared simulation or UI file, coordinate ownership or let the integrator apply that part. Do not copy complete old files over evolved systems. Do not discard uncommitted work to make a merge clean. Preserve saves and never kill a player's running game as cleanup.

## Editor development

The integrator can open the canonical editor with
`powershell -ExecutionPolicy Bypass -File tools/launch_game.ps1 -Editor`
from the canonical checkout, then use **F5 / Run Project**. F6 runs the selected
scene and may launch a test or preview; it is not the standard player launch.
Keep the editor and game visible. Save the player session before a restart.

Use Godot's **Debug → Synchronize Scene Changes** and **Synchronize Script
Changes**, plus **Editor Settings → Text Editor → Behavior → Files → Auto Reload
Scripts on External Change**. These are enabled on this machine. External edits
are detected when the editor regains focus; unsaved conflicts still need review.
Structural changes, autoloads and initialization changes can require a restart.
Live synchronization does not merge a worker branch or replay world generation.
Workers must still hand off commits; the integrator merges and verifies them.
Godot documents the external reload and unsaved-conflict behavior in
[EditorSettings](https://docs.godotengine.org/en/stable/classes/class_editorsettings.html#class-editorsettings-property-text-editor-behavior-files-auto-reload-scripts-on-external-change).

Integration records belong in `FEATURE_RECONCILIATION.md`; state the canonical
commit and tested behavior before saying a feature is in the player's build.

## Copy-ready worker prompt

```text
Work on Tomorrow and Tomorrow. The authoritative game is:
C:\Users\sjpur\TomorrowandTomorrow

Read its AGENTS.md and docs/WORKER_HANDOFF.md first. The OneDrive copy is archived; do not develop there or copy its systems wholesale.

Your task: [DESCRIBE TASK]
Your owned files/systems: [ASSIGN OWNERSHIP]

You are a feature worker, not the integrator. Create/use a Git worktree from the latest integrated main on a codex/<task> branch. Before editing, report the absolute worktree path, branch, base commit, and scope. Do not change the canonical working directory or another worker's files. If shared-file changes are needed, identify them explicitly in your handoff.

Preserve the latest terrain, civics, saves, military progression, animated battle visuals, ambitions, community network, and diplomacy. Keep population aggregate and visual counts bounded. Do not introduce duplicate authorities for labor, government people, research, or save state.

Implement and test your task in the worktree using explicit paths. Do not launch an isolated preview as the current game. Do not merge into main or overwrite/revert existing work. Commit only your task changes.

Return: commit hash; changed files; player-visible behavior; tests and results; save compatibility; limitations; integration conflicts. Your work reaches the player only after the designated integrator merges it, tests the combined main, and launches the canonical game.
```
