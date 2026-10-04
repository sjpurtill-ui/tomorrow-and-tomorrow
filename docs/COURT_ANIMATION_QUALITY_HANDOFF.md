# Court animation quality pass

Date: 2026-10-03. Worker branch: `codex/court-animation-polish`.
Worktree: `C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow`.
Final implementation checkpoint: `90ad2dd1` (the handoff-only commit follows it).

This is the combined court review branch for the designated wiring integrator. It is not a change to the canonical player checkout. The user's earlier instruction to push motion work without merging main still applies. No player/editor process was stopped or launched.

## Scope and sources

The selected executions remain **2 club, 3 fire, 4 dogs, 10 beheading**. Other catalog entries/assets are preserved but disabled at selection, director and stage boundaries. Presentation consumes the existing adjudicated result; these quality fixes do not decide deaths or reroll outcomes.

Started from integrated main `f9c6f398b38254f4370b99ac7be0e430bc045d39`; incorporated later main `3cfdfeccda3ac4a6b1ac01cafb186880672bd333`. Combined the published four-execution branch `d6aa19b0d5db6bb8ea436f21ca0fcf2cd035d399`, motion `2e99218ff496f25a4634a13351db0f41325d9304`, execution acting `1dd5fe5b`, and the clothing work handed over at `58a0912a`. The execution branch through `0a1f5df1` adds documentation after its implementation checkpoint. The later authored faint fix is retained in the seven clip libraries and their builder; unfinished second-batch execution tooling is excluded.

## Behavior improved

- Turns cross the angle seam by the shortest route. Walk playback follows travel speed; speech cannot cancel walking, storm exits or execution performances. Planned execution approaches use the same stride calculation and release the base walk at their destination.
- Standing up blends from the outgoing seated height. Facial expressions crossfade with the outgoing performance instead of snapping. The director's remaining acting words resolve to adult/child performances.
- Floor sitting hides the built-in stool, including speech, redressing and delayed dismissal. Ordinary stool sitting still has support.
- Executions finish before the modal's ordinary departure path runs. Fire has a visible throw/impact, charred walk and ash collapse. Execution camera priority persists through intervening dialogue; natural completion releases the close shot and returns to the court.
- Execution sounds share the stage clock, including arrival delays. Skipping cancels queued/playing execution sounds, callbacks and reactions; clears the hush/caption; and restores surviving actors and the original dog. The director's cooking and execution sound cues now reach the audio player.
- Weapon scenes use a stable camera-relative arrangement instead of the victim's last conversation heading. All participating actors finish arriving before the plan captures their positions. The dogs stay at the dragged victim's ankles, spectators step out of their route, and framing includes the prone body.
- Authored tools follow the clip's closed-fist frame. The club now contacts the actual head mesh on the first impact frame (about 5 mm surface separation, previously about 0.7 m). The axe's asset edge is calibrated around its grip to the authored 0.66 m reach; the block uses the plan's 0.575 m top, scaled by body height. Ordinary prop sockets are unchanged. The cook's lid stays at rest until pickup and releases onto the pot.
- Both cookware variants fit the authored 0.55 m rim, scaled by the cook's height, so the pot no longer obscures the cook. Opening width is preserved for the incoming head. The lid rests on the rim, is held by its knob, then releases onto the actual pot at the 7.6 s cue; cleanup frees all execution props. A gray object visible by the stores is pre-existing scenery, present before the command, not a leaked lid.
- Execution approaches and survivor returns use the existing floor router around hearths, set obstacles and current people, with route-length stride matching and the original arrival time. The cook's former straight approach passed within 20 cm of the hearth centre in the fire ring and 5 cm in the longhouse; final standing marks were already safe.
- Seated performers can leave a deep bench through a bounded opening in the floor map. Geometry above the seat, the feast table, walls, other people and the hearth remain blocked. The real longhouse headsman now walks around the table's end and reaches the block before the authored clip; the shared cached floor grid is restored after route calculation.
- Automatic support casting checks each adult's route to the actual authored destination, using their settled court mark rather than a temporary doorway position. A blocked explicit actor is never replaced: the visual execution declines cleanly and the modal keeps its existing sober exit. A later failed arrival skips the presentation before a distant swing can play. These checks do not change the adjudicated outcome or identity.
- The authored cook remains reserved through the club scene's lid cue. Generic crowd reactions can no longer make the cook faint or replace the performance midway; other execution methods still treat unused cooks as bystanders.
- Gore preparation no longer retains a dictionary/callable reference cycle after its figure is freed.
- All seven clothing meshes have continuous skirt weights, torso-bound mantles, better sleeve weights and skin coverage matched to moving cloth. Geometry, skeletons, face morphs, animation bytes and normals are preserved by the restricted refit.

## Validation

Godot 4.7.2, always with the explicit worktree path. GPU reviews use `tools/run_isolated_gpu_probe.ps1` on a private desktop with Dummy audio; runner logs confirm exit 0 and unchanged input desktop. Captures are diagnostic scenes, not the current player game.

The broad 15-suite rerun passes **275/275**, zero suite errors/failures/skips/orphans, after fixing the missing `stir` sound and direct execution-cue dispatch. The delayed floor-sitter regression fails 16 assertions against the previous code. The later 17-suite run covers **290 cases** with no assertion failures but exposes two contact-fixture errors (the fixture lacked the router's `kind` field). After correcting the fixture, all **25/25** affected stage/contact/path cases pass with zero errors. The cook-reservation follow-up passes **51/51** director/catalog/support cases with zero errors/failures/skips/orphans.

Suites: `test_court_motion`, `test_court_acting`, `test_court_figure_look`, `test_court_figure_gore`, `test_court_set`, `test_court_set_stage`, `test_court_stage`, `test_court_listening`, `test_court_director`, `test_court_sound`, `test_court_sound_stage`, `test_court_exec_set`, `test_court_exec_sound`, `test_court_exec_stage`, `test_court_executions`.

Added suites: `test_court_exec_contact` checks actual deformed mesh/tool contact, axe edge and block height, adult size variants, generic sockets, cook lid pickup/release and facing after arrival. Its six tests fail 24 assertions against the old attachment. `test_court_execution_paths` checks hearth detours in both settings, people avoidance in a transformed court, route speed, the angle seam, return lifetime and cancellation. The stage integration assertion compares foot rate with measured movement speed rather than the obsolete straight shortcut.

The expanded route suite passes **7/7** in the combined worktree against actual imported hall assets. It samples the seated headsman's route for table/hearth clearance, tests the return and cached-grid restoration, and observes arrival before the authored axe clip. The full command-dispatch beheading capture then passes the stronger mark assertions in the longhouse, with the headsman visibly beside the victim.

`test_court_execution_support` adds three cases, including 240 combinations of role, method, display mode, dread and seed, and observes the cook's authored performance until the lid actually becomes a child of the pot.

The cookware follow-up expands the contact suite to **7/7** cases. Both bag and pottery variants are checked against the authored rim, supported rest pose, knob grip/orientation, scale continuity, actual clip cue and full prop cleanup. The same regression fails six assertions against the previous code. New combined club captures in both settings pass, show the cook clearly behind the resized pot through pickup, and verify completion and recovery; both private processes exit.

`test_court_execution_casting` adds three actual-longhouse cases for implicit helper replacement, blocked explicit identity/clean completion, and an arriving actor whose settled mark is blocked. A real mesh enclosure makes the obstacle deterministic: reachability depends on the destination, and a seat blocked from the petitioner mark may still reach a support mark. The worker's seven affected suites pass **82/82**; the combined branch adds the newer cookware case.

**Final combined gate at `90ad2dd1`: 83/83 pass across seven affected suites**, zero errors/failures/skips/orphans, exit 0. These are execution stage, contact, paths, support, casting, director and execution catalog. Final longhouse club and beheading command-dispatch GPU probes also pass completion, impact and authored-position assertions, and visual review confirms the pot/lid and close weapon staging. Both processes exited with the input desktop unchanged. Together with the earlier broad run and corrected fixture rerun, every changed court system has passing regression coverage; this is not a claim that the independent clothing audit is clean.

Private rendered reviews include entrances, spoken interruptions and storm exits in both settings; petition/official/bow/wrath scenes; child reactions, floor sitting and mirrored actions; and the four selected executions through actual command dispatch, completion and recovery. The command probe observes execution creation and `exec_done`, and requires club/beheading to produce the impact result rather than accepting a vanished victim as success. It also verifies that every observed support performance reaches its authored floor mark. This catches the former longhouse executioner swinging 6.99 m away while the impact still fired.

The raw-GLB clothing audit measures **9,020 samples**, all seven bodies and all their clips. With identical coverage lookup and unchanged thresholds, failures decrease from **2,128 to 445**. There are no newly failing samples versus the delivered clothing refit. Worst garment edge stretch decreases from **27.36x to 3.43x**. The independent byte-invariant check passes **7/7**.

Local ignored evidence:

- `artifacts/animation-polish-final-tests.log`, `animation-polish-sound-final.log`, `animation-polish-combined-tests.log`, `animation-polish-delivery-tests.log`, `animation-polish-delivery-stage-tests.log`, `animation-polish-cook-final-tests.log`, `animation-polish-seated-path-tests.log`.
- `artifacts/animation-polish-complete-tests.log`, `animation-polish-complete-club1.log`, `animation-polish-complete-behead1.log` and their `.runner.txt` process records are the final combined gate.
- `artifacts/animation-polish-final-fire{0,1}.log`, `animation-polish-delivery-dogs{0,1}.log`, `animation-polish-delivery-behead0.log`, `animation-polish-seated-behead1.log`, `animation-polish-cook-final{0,1}.log`, `animation-polish-props-club{0,1}.log` and private-runner records.
- `artifacts/animation-polish-final-clothing-audit.log`, `animation-polish-final-clothing-invariants.log`.
- `artifacts/animation-polish-final-motion.log`, `animation-polish-final-court.log`, `animation-polish-final-r4.log` and their `.runner.txt` process records.
- `reports/court_motion`, `reports/court_figures/clip_home`, `reports/court_figures/clip_envoy`, `reports/court_acting/r4_*.png`, `reports/court_execution_review`.

## Limits and integration

The full clothing audit still exits **1**: deep seated/kneeling folds, overhead stretch, running and child skinning retain 445 flagged samples. Deep robe laps remain angular. The child's unchanged body mesh reaches 3.94x stretch. Do not report a clean all-body audit or simulated cloth.

Seat routing remains bounded; it does not guarantee every seat can reach every destination. The imported-set sweep still finds no route from longhouse `crowd_1`/`high_seat` to the petitioner mark. Support casting checks the actual role destination and handles failure explicitly, without inventing a straight crossing through furniture.

Headless gore cleanup tests emit Godot's dummy-renderer `Parameter "material" is null` diagnostic. The same diagnostic reproduces with a minimal ArrayMesh/override/free script and no game code. The prior ObjectDB/resource/allocator leak is fixed; private GPU probes are clean. Existing import tangent warnings for missing UVs remain.

No quality-pass save schema changes. Existing saves remain compatible. Shared conflicts are expected in `court_stage.gd`, `court_acting.gd`, `court_director.gd`, `audience_modal.gd`, `court_sound.gd`, `court_exec_stage.gd`, figure/gore code, the seven figure/clip GLBs and their Blender builders. This branch also contains the already published execution implementation, including its `game_state.gd` and display-preference additions; review the combined branch rather than copying those files over newer work.

Merge in the designated integration worktree, resolve against latest main, rerun combined court tests and the clothing check, push and remotely verify main before fast-forwarding the canonical checkout. Only then can a normal canonical relaunch include these changes. Generated imports, UIDs, caches, captures and audit artifacts are local review evidence and excluded from task commits.
