# Canopy transition — work in progress

Worktree: `/Users/seanpurtill/Documents/Codex/tt-canopy-transition`
Branch: `codex/canopy-transition`
Base: `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`
Owner: sole integrator. Scope: close vegetation shaders/LOD, LandscapeCover helpers, focused regressions and real generated-site captures, including the existing seasonal crown diagnostic. Shared file: local_terrain.gd. No simulation or art-worktree edits.

September 11 reconciliation: original held commit `88e8054`, based on `d95fa67964e0e2515875436107709562caa3d819`, rebased conflict-free as `d0fbc9dbe820dada755e290531650bdca2bd7bfd`. The follow-up in this handoff reconciles its behavior with the newer deferred-construction and physical-clearance cache. This branch remains HELD and is not in the canonical player build.

## Reproduced

The native baseline uses the actual 10,000 ft camera at both 1280×720 and 960×720, plus clearly identified 0.72/0.30 km diagnostic views. Seed 873421, actual temperate woodland at (12000, -3800), tropical woodland at (400, -1000), and drylands at (6600, -3280). Live LOD updates execute. `/tmp/tt-canopy-before.log` and ignored `artifacts/canopy-transition/*-before.png`. Captures inspected; the probe exited.

At the exact same 3.048 km altitude the wide viewport shows a square of black crown speckles while the 4:3 viewport hides close vegetation entirely. The 470 m square is especially visible in the 0.72 km diagnostic. Fading the crown alpha before applying a fixed 0.16 alpha-scissor threshold leaves tiny opaque remnants; the minimum 0.18 LOD fade prevents full handoff. Shrubs and forest-floor patches do not share crown LOD fading. Counts/identities and climate are stable, and the known dryland has zero woodland.

## Current live session

At the September 11 03:52 UTC heartbeat there was no player or editor process. Canonical main remains clean at `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`, packaged normal release 2026.09.10.4. Do not infer permission to launch or restart from an old recorded PID. Check processes afresh before native work. No player was stopped, relaunched or replaced during this reconciliation.

The latest direct user request is an evolving, ancient-first UI skin. The delivered interactive proposal is `evolving-scouting-window.html` in the task visualization directory; it is separate from this canopy branch and is not a game implementation.

## Status

HELD: the reconciled rendering correction passes all **27 headless cases**, zero errors/failures/skips/orphans, across canopy transition, landscape cover, seasonal landscape, camera distances and surface precision. The six canopy cases also pass alone. Both updated native probe scripts pass headless parse checks; those checks do not render anything. Final evidence is retained in ignored `artifacts/canopy-transition/reconciled-source-tests.log`, `canopy-probe-parse.log` and `seasonal-probe-parse.log`. Initial fixture runs exposed the incorrectly typed marker and the camera-input cooldown; those fixtures were corrected before the final run.

Do not integrate or package until actual native after-captures pass. The previous `/tmp/tt-background-capture` guard and launcher are no longer present. Recreate and verify a background-only native capture harness in a durable task-owned location before GPU testing. The installed Godot.app has hardened runtime signing; use an appropriately signed private test executable for injection, never modify the installed editor or normal release. Subject-specific discovery/unit artwork in tt-subject-art remains separate and unfinished.

## Implemented, not integrated

Close crowns, scrub and understory now receive one continuous LOD opacity based on the larger physical view dimension. The 10,000 ft footprint reaches full handoff on standard, wide, ultrawide and portrait views; distant woodland remains represented by the existing biome-driven terrain material. Removing the old opacity floor and alpha scissor prevents the fade from selecting opaque pinpricks. A radial 130–235 m feather removes the rectangular sampling edge while keeping all candidate cells, transforms, colors, climate channels and count budgets unchanged. Unchanged zoom no longer resubmits the same material uniforms; rebuilding resets that cache. Broad vegetation materials retain their defaults.

The three new tests exercise actual camera presets at four aspect ratios, gradual common opacity across all three real vegetation kinds, exact crown/mesh identity retention through zoom, unchanged resources/population and refreshed boundaries/opacity after a detail move. Existing cover, seasonal, camera-distance and far-world precision cases also pass (22 total). Shader appearance and blending still require native verification; passing these source tests is not graphical sign-off.

The reconciliation adds three more canopy cases and retains main's additional landscape cases (27 total). Drawing and deferred construction now use the same aspect-aware foliage strength. A wide-screen span below the old 1.8 km ground threshold no longer rebuilds fully invisible plants. Portrait foliage that is still visible above that old ground threshold can be constructed. Ordinary upkeep retains the physical-clearance signature and exact mesh identities; actual clearance changes remain deferred while foliage is hidden and apply when it becomes visible. An active camera gesture still defers first construction until input settles. No resource, population, calendar, AI or save mechanics change.

The native canopy probe now distinguishes no initial foliage at the actual aerial preset from the legitimate first construction on a closer diagnostic. It then checks identity retention on subsequent close views and returns through all four actual distances. The existing seasonal crown diagnostic explicitly constructs deferred plants at its close view and requires nonempty woodland, preventing a false success with no crowns. These updated native assertions have only been parsed, not executed graphically.

## Next verification

After verifying the background-only harness, run `tests/canopy_transition_probe.tscn` with the task-owned `TomorrowCanopyTransitionTests` override and no `--before` flag. The owned override is retained in this worktree for that next check. Inspect all after views against the retained before captures, particularly the real 10,000 ft woodland and the explicitly diagnostic 0.72/0.30 km close views. Confirm no rectangular edge, no opaque speckle remnants, retained close crown detail, exact paused pixels and fog hiding. Then run the seasonal native probe and the live four-distance terrain LOD probe; their overrides are compatible unless a stricter guard is added. Record actual costs, current player state and limits before integrating. Remove the owned override before delivery. No player relaunch or normal package is authorized as part of graphical testing. Normal build-only packaging follows verified integration.

Save compatibility: unchanged. Shared-file review: automatic Git rebase was conflict-free, but semantic reconciliation of `local_terrain.gd` was required as described above; no other worktree changes were imported. Next integration must preserve canonical advances after `940d5a2` and rerun focused combined checks. Source success is not native visual approval or a populated-campaign performance benchmark.
