# Military front graphics — worker handoff

Status: READY for integrator review; not integrated or launched as the player game.

Worktree: `/Users/seanpurtill/.codex/worktrees/c2aa/tomorrow-and-tomorrow`
Branch: `codex/military-front-graphics`
Base: `577f8aa5d17310674b9d75454c2f584317c6c7aa` (verified organic-town integration).
The delivery commit is the commit containing this document.

## Behavior and entry paths

- `ArmyFrontVisual` draws broad, thin colored occupied-ground sections from combat-capable counts and recorded equipment. Metre geometry uses `.001` in the kilometre terrain. Deployment changes aspect without changing area; real losses shrink area. Map heading uses the existing reported heading/destination. Separate counter glyphs retain readability at distance without enlarging occupied ground.
- `local_terrain.gd` connects player field armies, dated foreign sightings and eligible occupation garrisons. Camera scale and cosmetic stacking offsets cancel out of the physical transform. Close soldier figures and decorative objective-front wings are removed; selection, labels, objectives and reports remain.
- Home invasion and field/city assault observation still enter `BattleGraphicsScreen` and `BattleDiorama`. They instantiate zero soldier or mounted-general actors. The general-led campaign's map and recorded battle view use the same front geometry.
- `hud/siege_screen.gd` actively instantiates `siege_city_scene.gd`; it is a live siege/assault presentation, not peaceful guards. It now uses two bounded fronts, with no fabricated sector troops/camps for unknown forces. Existing city damage comes from the supplied snapshot. No movement, intensity or deployment creates fire.
- Legacy cohort-order panels and responsive toggle stay hidden in all phases and sizes; their handlers and the old whole-army retreat handler cannot issue orders. Watch Next Exchange uses the existing `advance_engagement("hold")` exactly once. No replacement combat solver or new balancing was added. Strategic objectives and conversation remain in `GeneralCampaignScreen` (send discussion, commit objective, pause to speak/continue mission); general records remain in People & Legacies. Generic legacy battle observation does not itself acquire a new strategic conversation controller.

## Truth boundaries and limitations

Current CombatSimulator/GeneralCampaign records contain formations, strength, equipment, morale, outcomes and cumulative losses, but no cohort coordinates or evolving encirclement topology. Battle/siege bands are explicitly labeled **schematic deployment**. They do not claim actual flanking, curved contact, moving reserves or continuous spatial combat. The optional `deployment_position_m`, `facing`, `front_bend_m` and section status inputs can depict supplied spatial records; production normalization does not currently supply them. Tests of these optional inputs are renderer-contract tests, not claims of implemented maneuvers. Separate sections never gain bridging triangles.

Area is a presentation calibration: 4 m² per active person plus recorded equipment allowance (6 m² for cavalry/mobile equipment, 20 m² for heavy equipment). It is not an authoritative historical density or game balance. Over 24 cohorts collapse to one remainder preserving aggregate personnel/equipment area. Distant foreign footprints use only the midpoint of the published estimate; report labels retain the range and observation date.

Dated own-army reports discard live formation equipment and live remaining counts. Missing away reports produce no footprint; destruction is not disclosed before a report merely by testing live troop counts. Occupation forces lack a dated strength-report ledger, so their ground footprint is withheld before live communications. Foreign shapes never read the live enemy force. Hidden/offscreen fronts stop interpolation; terrain fronts are omitted beyond the 80 km camera band. Triangle vertex/centroid land and reveal tests suppress unsupported terrain; this is sampled clipping, not exact shoreline polygon intersection. Report positions snap to new observations rather than extrapolating unseen movement across water.

Prisoners in a recorded termination are excluded from the defeated combat footprint, without changing the alive/casualty ledger. Wounded, scattered and captured pools never inflate active area. Prisoner sites and independently located remnants cannot be drawn without actual coordinates; their existing reports remain authoritative. No new casualty, control, prisoner, scorch/preserve, urban-damage or fire mechanics are introduced. No contact sparks or blood actors are synthesized.

One mesh per front, at most 24 sections with 48 polygon vertices each, independently of population. Geometry is cached by input and interpolates for 0.35 seconds only on changes; the campaign overview has a bounded 32-entry layout cache. Terrain sampling occurs during these bounded rebuilds. No per-frame model/API requests. No GPU screenshots, visual signoff or hardware FPS claim: only headless execution was authorized/available on this Mac.

## Validation

Godot 4.7.2, explicit isolated worktree paths, Dummy audio, isolated test user directory; no player/editor interrupted or graphical test launched.

- Headless editor import: clean.
- `tests/test_army_front_visual.gd`: 10 cases covering physical area/deployment/facing, optional detached/bent inputs, water rejection, dated foreign intelligence, paused interpolation, billion-person geometry, actual invasion entry, map transform invariance across zoom, alive pools, siege boundedness and capture/equipment-overflow accounting.
- Combined front, general campaign, battle injury, organic town and military development suites: 59 passed, zero errors/failures/skips/orphans.
- `res://tests/battle_graphics_probe.tscn`: PASS. Actual invasion screen, five phases across three viewport sizes, inert legacy controls, exactly one resolution, replay preserves complete exported military state and calendar, pause, zero actors.
- Broader eight-suite run including siege progression/relief/recovery: 92 passed of 93; one pre-existing failure in `test_siege_progression.gd:145`, `test_offensive_requires_presence_locks_army_saves_and_returns_physically` (withdrawal expects moving, receives stationed). Reproduced on untouched base `577f8aa` in `/tmp/tat-front-baseline-577f8aa`: 8 passed/1 identical failure. No siege mechanics changed to conceal it.
- Earlier figure-layout compatibility run: 43 passed/2 existing GPU-only checks skipped; no errors/failures/orphans.

Evidence: `/tmp/front-ready-tests.log`, `/tmp/front-ready-ui.log`, `/tmp/front-ready-import.log`, `/tmp/front-final-tests.log`, `/tmp/front-baseline-siege.log`. Final targeted reruns are recorded in `/tmp/front-final-hook-tests.log` and `/tmp/front-final-ui.log`; the final missing-report guard rerun passed all 10 cases in `/tmp/front-final-map-tests.log`.

## Integration

Save schema and aggregate simulation authorities are unchanged; existing saved forces/rounds have fallback aggregate layouts. Replay reconstructs display copies and does not re-resolve combat. Existing organic-town assets and hooks are preserved.

Shared hotspot: `scripts/local_terrain.gd` only (military presentation, runner sanitization, garrison visibility). No changes to project.godot, game_state.gd, discovery_system.gd, military_campaign.gd or save_system.gd. Other owned files: new army front renderer; battle diorama/screen; general campaign map/screen; siege scene/HUD tooltip; warfare map presentation; front suite and updated battle graphics probe; this document. Unrelated generated UID sidecars and ignored test configuration are not part of the commit.

Integrator should review the schematic limitation and unchanged siege-withdrawal failure, merge only this worker commit after review, run combined checks on canonical main, and arrange an authorized graphical review before claiming visual signoff or player delivery. Do not launch this worktree as the current game.
