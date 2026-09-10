# Canopy transition — work in progress

Worktree: `/Users/seanpurtill/Documents/Codex/tt-canopy-transition`
Branch: `codex/canopy-transition`
Base: `d95fa67964e0e2515875436107709562caa3d819`
Owner: sole integrator. Scope: close vegetation shaders/LOD, LandscapeCover helpers, focused regressions and real generated-site captures. Shared file: local_terrain.gd. No simulation or art-worktree edits.

## Reproduced

The native baseline uses the actual 10,000 ft camera at both 1280×720 and 960×720, plus clearly identified 0.72/0.30 km diagnostic views. Seed 873421, actual temperate woodland at (12000, -3800), tropical woodland at (400, -1000), and drylands at (6600, -3280). Live LOD updates execute. `/tmp/tt-canopy-before.log` and ignored `artifacts/canopy-transition/*-before.png`. Captures inspected; the probe exited.

At the exact same 3.048 km altitude the wide viewport shows a square of black crown speckles while the 4:3 viewport hides close vegetation entirely. The 470 m square is especially visible in the 0.72 km diagnostic. Fading the crown alpha before applying a fixed 0.16 alpha-scissor threshold leaves tiny opaque remnants; the minimum 0.18 LOD fade prevents full handoff. Shrubs and forest-floor patches do not share crown LOD fading. Counts/identities and climate are stable, and the known dryland has zero woodland.

## Current live session

Canonical player PID 3844 runs normal packaged release 2026.09.10.1 at d95fa67964e0, launched on user request September 10. Its real window was verified. Do not interrupt or relaunch it. An AX inspection timed out and buffered player logs remained empty despite the game already running; do not infer startup failure from empty release logs. The separate headless normal-entry resume check passed all initialization stages.

## Status

HELD: rendering correction is implemented and 22 focused headless cases pass, with zero errors/failures/skips/orphans (`/tmp/tt-canopy-tests.log`). Do not integrate or package until actual native after-captures pass. Avoid foreground native probes while the user is playing; baseline is available for development. Subject-specific discovery/unit artwork in tt-subject-art remains separate and unfinished.

## Implemented, not integrated

Close crowns, scrub and understory now receive one continuous LOD opacity based on the larger physical view dimension. The 10,000 ft footprint reaches full handoff on standard, wide, ultrawide and portrait views; distant woodland remains represented by the existing biome-driven terrain material. Removing the old opacity floor and alpha scissor prevents the fade from selecting opaque pinpricks. A radial 130–235 m feather removes the rectangular sampling edge while keeping all candidate cells, transforms, colors, climate channels and count budgets unchanged. Unchanged zoom no longer resubmits the same material uniforms; rebuilding resets that cache. Broad vegetation materials retain their defaults.

The three new tests exercise actual camera presets at four aspect ratios, gradual common opacity across all three real vegetation kinds, exact crown/mesh identity retention through zoom, unchanged resources/population and refreshed boundaries/opacity after a detail move. Existing cover, seasonal, camera-distance and far-world precision cases also pass (22 total). Shader appearance and blending still require native verification; passing these source tests is not graphical sign-off.

## Next verification

When a native capture can run without interrupting the player, run `tests/canopy_transition_probe.tscn` with the existing task-owned `TomorrowCanopyTransitionTests` override and no `--before` flag. Inspect all after views against the retained before captures, particularly the real 10,000 ft woodland and the explicitly diagnostic 0.72/0.30 km close views. Confirm no rectangular edge, no opaque speckle remnants, retained close crown detail, exact paused pixels and fog hiding. Then run the seasonal native probe and the live four-distance terrain LOD probe; their overrides are compatible unless a stricter guard is added. Record actual costs, current player state and limits before integrating. No player relaunch or normal package is authorized as part of graphical testing. Normal build-only packaging follows verified integration.
