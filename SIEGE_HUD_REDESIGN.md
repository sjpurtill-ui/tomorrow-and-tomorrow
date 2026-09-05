# Native siege HUD — isolated review delivery

Integration update: selected for canonical release 2026.09.05.5. The text below
records the original isolated delivery; current status is in docs/INTEGRATION_STATUS.md.

Base: fd59e24, building on the reviewed native battle HUD in cba299a. Worktree: C:/Users/sjpur/tt-city-defense-aftermath, branch codex/city-defense-aftermath. Canonical main remains c89b895 / release 2026.09.05.4 until deliberately integrated.

## Interface

The siege screen uses the battle HUD's bundled Barlow fonts and ink/teal/orange/gold controls. Existing SiegeCityScene meshes, terrain, soldier representatives, city defenses and camera mechanics are unchanged.

- Day/status header; your personnel, morale and readiness; reported enemy strength with observation date.
- Assault-pressure bar with its real meaning: reduces the prepared defense bonus, not win probability or a required completion threshold.
- Supply, City, and Reports tabs distinguish delivered ration coverage, land access restrictions, endurance, population reports, fortifications, and uncertain enemy stores/civilian conditions.
- Maintain Siege, negotiation, relief, lifting the siege or yielding the defended city, and explicit assault/sortie controls. Small windows use a compact order grid and a supplies/orders switch rather than scrolling.
- Real campaign Pause/Play/Fast, camera presets/pan/orbit/zoom, bounded local observation/activity log, ended siege record, linked battle review, and recovery access after yielding the home city.
- Assault closes the siege overlay and opens the new battle HUD paused at round zero. It cannot resolve combat from an old siege button row.
- Archived sieges find their matching battle even after newer battles. An unrelated active battle is not mislabeled as that siege's assault. Linked historical battle review uses its seed.

No siege pressure, supply/endurance coefficients, civilian defense formula, hostility prerequisite, population accounting, save schema, or battle balance changed. Maintain Siege leaves campaign time, simulation state, and screen selection unchanged. It confirms existing orders; Play/Fast changes time separately.

## Controlled scenario

Run res://tests/manual_city_siege.tscn in this isolated project. It reuses the verified dry 180 attackers / 119 defenders / 600 residents / world seed74017 fixture. A valid Provision founding choice enables the real time controls; no additional military force is created. Music is muted. It starts paused on the map with no siege or battle underway. Click the army, then BESIEGE TEST RIVER CITY. RESET TEST restarts this siege fixture fullscreen. No normal campaign save is loaded.

## Verification

57 focused tests pass, including new Maintain idempotence/time invariance and historical battle identity regressions, existing siege progression/recovery/relief, and battle-order coverage.

GPU mouse flow covers map→besiege→war initiated→Maintain→Play/Fast/Pause→save/import/reopen→compact tabs→assault→new battle→result→siege outcome→linked historical review. A separate run covers lifting the siege and map return. Repeated Maintain checks include 20 paused clicks with exact exported-state equality and 12 clicks during time advancement, plus negotiation and relief overlays. Geometry/reopen probe covers four defense stages at800×600/1280×900 and bounded visuals at a synthetic billion population.

Tests now run using tools/run_isolated_gpu_probe.ps1. It creates a private Windows desktop, starts Godot there, never switches the input desktop, checks the input desktop throughout, enforces a timeout, closes only its own process/desktop, and writes a .runner.txt audit beside the engine log. It fails on logged script/engine errors. This avoids exposing automated game interactions on the user's desktop; shell Hidden alone is not the isolation boundary.

Logs: artifacts/siege-final-private.log, siege-maintain-regression.log, siege-native-layout.log, siege-hud-tests.log. Screenshots: artifacts/siege-hud-*.png and siege-<stage>-<width>.png.

## Reported Maintain/exit incident

Evidence preserved under artifacts/siege-incident-20260905-1620. Last known interactive PID30904 ran fd59e24; its log ended16:05 with successful attacks and an earlier WASAPI device invalidation warning, but no fatal script/crash entry. The automated new-siege probe ran16:17:24–16:17:39, performed its scripted transitions and exited normally. No recent Godot Windows crash dump/event was found. The original reported exit was not reproduced or conclusively attributed; do not claim the audio warning or test visibility was its confirmed cause.

Current Maintain behavior and overlay/time interactions pass the regressions above. Subsequent graphical automation is isolated from the input desktop. Interactive runs never receive verification flags. SIEGE_UI_OPEN/ORDER/TIME/TRANSITION/CLOSE records make any future report traceable.

## Integration handoff

Shared changes: siege_screen.gd, a read-only battle identity lookup in military_campaign.gd, and optional historical seed selection in military_command_ui.gd/battle_graphics_screen.gd. Keep the manual scenario and test-only project settings separate from canonical configuration. Preserve existing unrelated .import and .uid work. Re-run combined tests and launch only the canonical launcher after integrator review.
