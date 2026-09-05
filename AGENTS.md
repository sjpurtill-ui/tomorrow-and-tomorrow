# Authoritative game checkout

This is the current game: `C:/Users/sjpur/TomorrowandTomorrow`.

The OneDrive copy at `C:/Users/sjpur/OneDrive/Documents/ChatGPT/Tomorrow and Tomorrow` is archived. Never copy its full terrain, project settings, or simulation systems over this checkout. Preserve local changes, including active map work.

Launch the game only through `tools/launch_game.ps1` with this checkout as the explicit working directory. Verify the Godot process command line contains this absolute project path. Never present a test scene, graphical audit, battle demo, or another checkout as the current game. Keep isolated tests headless or close them after captures. Do not stop a user's editor or game with unsaved state merely to launch a new build.

## Coordination

One designated integrator owns this canonical checkout and merges completed work. Other workers use Git worktrees created from its latest integrated `main`, on `codex/<task>` branches; they do not edit the canonical checkout concurrently. Worktrees are development areas, not alternative current games. Use explicit worktree paths for headless tests. No folder copying, automatic synchronization, blanket checkout, reset, or overwrite from the archived OneDrive project.

Before starting, report the absolute worktree path, branch, base commit, and files/systems owned by the task. Read `docs/WORKER_HANDOFF.md`. Commit only task changes. Supply the commit hash, concise behavior summary, tests, known limitations, save compatibility, and any shared-file conflicts to the integrator. Do not merge into main, launch the player game, or claim the player build includes your changes until integration is verified.

Shared integration hotspots are `project.godot`, `local_terrain.gd`, `game_state.gd`, `discovery_system.gd`, `military_campaign.gd`, and `save_system.gd`. Preserve the current GovernmentPeopleSystem as the owner of civic officials and daily settlement labor. HistoricalFigures records exceptional contributors and independent field generals. Preserve aggregate population counts and bounded visual representatives.
