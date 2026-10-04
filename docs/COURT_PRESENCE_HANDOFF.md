# Court presence: lighting, staging and sound

Status: INTEGRATED at the user's explicit merge request. Source `7516b33f` and its prerequisites are recorded in `docs/INTEGRATION_STATUS.md` and `docs/FEATURE_RECONCILIATION.md`. The worker evidence below is retained; historical references to pending integration describe the handoff state, not the later integration record. No player restart was performed.

Worktree: `C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow`.
Delivery branch: `codex/court-presence`.
Base: `066cac48f43c43312d5d2a2fa8892e8f36e2399a` (`codex/court-atmosphere`), which contains the latest integrated main `ec537b74fa82253806dc3cb5ee2ce9bd718ba81d`.
This is a continuation of the complete atmosphere/evolution delivery. It is not a replacement for those prerequisite commits, and it has not been merged into canonical main.

## What the player sees and hears

- A divine address gives the room a short anticipatory pause, one composed camera move, a still hold and a gentle release. The camera stays on the same side of the room, preserving hands and context.
- Favour holds its subject instead of interrupting its own camera move with a cutaway. Wrath keeps a cowering person's whole body in frame through the existing kneel.
- Cold wrath and warm favour enter chapter rooms through an actual authored window. A small diffuse return keeps the addressed face and hands readable. Light follows the moving subject without hopping between windows. Legacy smoke-hole and outdoor sources remain supported.
- The hearth and braziers sustain their hush or warmth throughout the moment; a per-frame fire update no longer erases it. The light's attack is part of the spoken duration, followed by a short afterglow rather than adding the attack twice.
- Sound has a short hush, a distinct attack, a quieter bed beneath words and a finite tail. Open gatherings, timber rooms, stone halls, records rooms and furnished offices have distinct acoustic returns. Existing synthesized timbres are reused.
- A new speaker cancels old decorative camera callbacks. Named missing, leaving or hidden targets cannot redirect the effect onto somebody else. Executions retain camera priority, including against shakes.
- Reduced motion keeps static reframing and colour changes, suppresses camera travel/shake and divine wind/motes. Hiding the court, changing quality and closing/reopening sound immediately reconcile effects; stale sound jobs cannot revive or extinguish a new audience's cue.

The four enabled executions remain club, fire, dogs and beheading. No outcome, reaction decision, order, death, official, population or resource is invented here. The camera presents the supplied response. The diagnostic replay explicitly supplies fixture responses `blessed` and `cower` and does not adjudicate a real campaign.

## Source checkpoints and owned files

- Root effects: `82f70256d30a1edfd8bfba8bc0fa77014e6e4372`, then `2ce6a855380955a2527f0145da8f8698d8738f97`. Own `court_set_3d.gd`, `court_shaft.gdshader`, `test_court_presence.gd` and the optional atmosphere capture path in `court_chapter_capture.gd`.
- Staging worker: `a69acb97ec21a6b7398b1c22723c452aada58ac7` on `codex/court-dramatic-staging`; cherry-picked as `9414f983dbf29d5e8894bdd1d72b429c90b08b28`. Own `court_camera.gd`, `court_director.gd`, `court_stage.gd`, focused tests and `court_dramatic_capture.gd/.tscn`. Worker handoff: `docs/COURT_DRAMATIC_STAGING_HANDOFF.md`.
- Sound worker: `2daf41d5f31e6ecdf39f3847d2e8b3405cb17aaa` on `codex/court-presence-sound`; cherry-picked as `758df709`. Own `court_sound.gd` and `test_court_presence_sound.gd`. Worker handoff: `docs/COURT_PRESENCE_SOUND_HANDOFF.md`.
- Combined follow-up: shorter, correctly timed visual recovery and one existing chapter acoustics test updated to verify actual enclosure differences rather than the replaced universal hall constants.

These are the shared presentation files the integrator must reconcile deliberately with execution/court builders. Do not overwrite full files from a worker checkout. No shared simulation hotspot, project setting, garment/animation asset, city or save schema was changed in this follow-up.

## Verification and evidence

All paths below are relative to this worker worktree. Generated reports and captures remain local, not source assets.

- Final focused effects/set run: `artifacts/court-presence-return-tests.log`, 46/46 passing before the final line-duration regression was added.
- Initial combined run: `artifacts/court-presence-full-tests.log`, 462 cases across 41 suites; four assertion failures within one existing chapter reverb test, which expected the old uniform room constants. All other cases passed. That test now verifies open air < furnished office < stone hall acoustic return.
- Final combined run: `artifacts/court-presence-full-final-tests.log`, 462/462 across41 suites, zero errors/failures/flaky/skipped/orphans, exit0, report73 (3m37s).
- The suite selection includes all court presentation/acting, wardrobe, motion, director, stage, camera, execution and sound tests. It excludes external/live evaluation and unrelated fact/order suites (`test_court_live_eval`, `eval`, `facts`, `listening`, `office_orders`, `war_orders`); no external AI calls were required.
- All 16 chapters rendered with wrath, favour, recovery and high/low quality: `artifacts/court-presence-all-chapters-gpu.log`, PASS16; private GPU PID55820 exited0. The first effects preview PID50800 and face-return refinement PID2696 also exited0.
- Full actual audience modal, 1280x720, normal-speed 24-second sequence: medieval year1400 `artifacts/court-presence-dramatic-medieval-gpu.log`, PASS706 frames/5 phases, PID12120 exited0. Modern year3000 preliminary PID81076 exited0; final combined `artifacts/court-presence-dramatic-modern-final-gpu.log`, PASS717 frames/5 phases, PID48180 exited0. Timing records show184 moving samples in the medieval replay and185 in the final modern replay; holds are still, with no repeated camera hunting.
- Reduced-motion modern sequence: `artifacts/court-presence-dramatic-reduced-gpu.log`, PASS717 frames/5 phases, PID64280 exited0; the timing trace reports zero moving camera samples.
- Visual boards: `reports/court_presence/wrath-chapters.png`, `favour-chapters.png`, `medieval-sequence.png`, `modern-sequence.png`. Normal-speed, eight-frame-per-second review GIFs: `medieval-replay.gif`, `modern-replay.gif`. Full JPEG frames and timing records are in `reports/court_dramatic/1400`, `3000` and `3000-reduced`.
- An independent reviewer inspected the effects/staging/sound source and all16 chapter boards. Reported issues were addressed: baseline drift during a near-finished light release, wrong-target fallback, stale camera callbacks, execution shake priority and an untracked execution music fade.

Every graphical probe uses `tools/run_isolated_gpu_probe.ps1` on a private desktop with Dummy audio, never a player launch. The first attempt was rejected before process creation because Windows could not verify the input desktop; the later attempt succeeded without changing the guard. The initial new test draft also had two local type-inference errors, corrected before successful effects runs. Retained failure logs are not evidence of a passing run. Compatibility renderer depth-of-field warnings are pre-existing; inspect final logs for any other engine/script errors.

## Limits, compatibility and delivery

No save migration. Existing saves derive the same state and actual response; presentation is transient. The fixed-bounds addition is one unshadowed, diffuse-only light near the addressed person, reusing the existing single shaft and dust emitter. This is a stylized light volume, not fully occluded volumetric scattering.

The captures exercise prepared knowledge snapshots and real presentation routing, not a continuous 3000-year campaign. Sound's actual samples are checked for peaks, discontinuities and energy under speech; subjective audible listening is not claimed because all probes use Dummy audio. The game has not been declared visually perfect, and this pass does not redesign every game system.

Only intentional source/tests/docs are committed. Generated imports, UIDs, caches, captures and unrelated worker changes remain excluded. Final delivery is verified with a fresh `git ls-remote`, fetch and0/0; the exact final documentation commit is reported with the handoff. The integrator must reconcile this branch with current main, rerun the combined court/clothing checks, push main before updating canonical, and verify delivery before telling the player it is included. No canonical player/editor was launched or stopped by this worker. At the final process audit, canonical player PID79300 was running with the correct absolute `C:/Users/sjpur/TomorrowandTomorrow` project path and was left untouched; it does not load this worker branch.
