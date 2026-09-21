# Authoritative game checkout

This is the current game: `C:/Users/sjpur/TomorrowandTomorrow`.

The OneDrive copy at `C:/Users/sjpur/OneDrive/Documents/ChatGPT/Tomorrow and Tomorrow` is archived. Never copy its full terrain, project settings, or simulation systems over this checkout. Preserve local changes, including active map work.

Launch the game only through `tools/launch_game.ps1` with this checkout as the explicit working directory. Verify the Godot process command line contains this absolute project path. Never present a test scene, graphical audit, battle demo, or another checkout as the current game. Keep isolated tests headless or close them after captures. Do not stop a user's editor or game with unsaved state merely to launch a new build.

## Coordination

For the authorized Mac clone, see `docs/MAC_SETUP.md`. Designate that clone as the Mac's canonical checkout and use Godot F5; the PowerShell launcher is Windows-only. The same integrator and worktree discipline applies.

One designated integrator owns this canonical checkout and merges completed work. Other workers use Git worktrees created from its latest integrated `main`, on `codex/<task>` branches; they do not edit the canonical checkout concurrently. Worktrees are development areas, not alternative current games. Use explicit worktree paths for headless tests. No folder copying, automatic synchronization, blanket checkout, reset, or overwrite from the archived OneDrive project.

Before starting, report the absolute worktree path, branch, base commit, and files/systems owned by the task. Read `docs/WORKER_HANDOFF.md`. Commit only task changes. Supply the commit hash, concise behavior summary, tests, known limitations, save compatibility, and any shared-file conflicts to the integrator. Do not merge into main, launch the player game, or claim the player build includes your changes until integration is verified.

Shared integration hotspots are `project.godot`, `local_terrain.gd`, `game_state.gd`, `discovery_system.gd`, `military_campaign.gd`, and `save_system.gd`. Preserve the current GovernmentPeopleSystem as the owner of civic officials and daily settlement labor. HistoricalFigures records exceptional contributors and independent field generals. Preserve aggregate population counts and bounded visual representatives.

## GitHub delivery is required

The user authorizes normal pushes of completed task work to this project's existing private GitHub repository. Do not wait for another request to push each completed batch. Respect an explicit request to keep a particular change local.

- Before work, fetch origin and inspect the current branch, upstream, and ahead/behind counts. Resolve existing unpushed task commits before accumulating another backlog. Preserve unrelated changes and coordinate divergent history; never force-push shared branches or reset work to make synchronization easy.
- Commit intentional task files at each coherent, validated checkpoint and push that checkpoint promptly. Workers push their own `codex/<task>` branch before handoff; only the designated integrator integrates and pushes `main`. Pushing a worker branch does not deliver the change to the player branch.
- After every integration, the integrator must push `main` before reporting delivery or moving to the next batch. Local commits alone are not a backup, synchronization, or delivery to another device.
- Verify successful delivery with a fresh remote query: `git ls-remote origin refs/heads/<branch>` must match the intended local commit. Fetch afterward and check ahead/behind counts; a synchronized branch has zero on both sides. A push attempt or stale `origin/main` is not verification.
- Before ending a task, check for uncommitted task files and unpushed task commits. Report the pushed branch and verified commit. Explicitly identify anything still local, unfinished, or excluded; never say “everything is pushed” without checking the requested scope.
- If authentication, networking, remote divergence, or asset size blocks a push, report it immediately with the local commit and affected branch. Preserve the work and resolve the blocker; do not silently continue building a backlog or imply another device has the work. Never publish credentials, saves, generated caches, or unrelated files to satisfy this rule.

## General-led campaign direction

Read docs/GENERAL_CAMPAIGN_DESIGN.md before military or leader work. Generals execute battlefield operations in every era; the player observes consequences and gives objectives through conversation. Do not revive the discarded direct-cohort-control design or make routine logistics a mandatory form-filling flow.

The user considers the current development campaign a disposable test and prioritizes playable implementation and behavioral quality. Do not center progress reports on preserving that test save. This preference is scoped to this development campaign, not permission to delete arbitrary user data or interrupt other sessions.
