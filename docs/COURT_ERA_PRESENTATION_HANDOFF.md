# Court dress and etiquette progression

Worker branch: `codex/court-era-presentation`.
Worktree: `C:/Users/sjpur/.codex/worktrees/court-motion/TomorrowandTomorrow`.
Base: `09b3a5f5de858b0c11ac181b78a84e2d73299c67`, the pushed court animation pass, itself based on integrated main `3cfdfeccda3ac4a6b1ac01cafb186880672bd333`.

This branch is for the designated court integrator. It has not been merged into main or launched as the player game. It includes the earlier animation work documented in `COURT_ANIMATION_QUALITY_HANDOFF.md`; avoid duplicating that work if it has already been integrated.

Final coordination check: main advanced during this task to `3c8ddbe35e122bf7ec4b39a657ad65325329a9c9` (PR #138, earlier court animation pass). Canonical main and origin/main are synchronized, and `09b3a5f5` is now an ancestor of main. The era-presentation work is still on its worker branch. There are no additional main-side changes to this task's shared court files beyond that incorporated base at this check.

## Behaviour

- `court_presentation.gd` derives six periods from each society's actual known practices and institutions. The calendar cannot grant clothing, administration, democracy or secularism.
- Clothing progresses from hides/woven garments and ancient robes through medieval dress, court coats, formal coats and business clothes. Hair, faces, ages and people's colour identity remain stable; later shirts stay light when the registry varies colours.
- Later civic stages supply appropriate office titles, forms of address, audience protocol and administrative descriptions. GovernmentPeopleSystem remains the owner of officials; no parallel officials or population are created.
- Routine greetings and departures follow the person's society and political tradition. Foreign envoy identity survives normalization. Greetings wait for arrival at the mark; delayed entrances cannot consume them at the door.
- Explicit reverence, fear, refusals and all four selected executions retain their engine-decided meaning. Walking cadence, turn interpolation and execution plans are unchanged by this pass.
- Later courts use visitors and clerks instead of camp extras, omit ambient livestock and rustic stores/spear racks, and avoid archaic musician/fireside gestures. Briefing review uses a thoughtful gesture; there is no unsupported writing into thin air.

## Integration ownership

Shared files changed: `scripts/hud/court_stage.gd`, `court_director.gd`, `court_acting.gd`, `audience_modal.gd`, `court_set_3d.gd`, `scripts/civic_stages.gd`, and the figure wardrobe runtime. Preserve the execution and movement fixes in the base rather than replacing these files wholesale.

Worker sources incorporated: rules `9095db1a`, etiquette `8438a5a1`, foreign/explicit reactions `c34f7744`, routine-marker propagation `9998a038`, and wardrobe `e26ad130` (incorporated as `99df7bf9`). All worker source branches were pushed and freshly verified. Root wiring checkpoint `9244bc69` is pushed and remotely verified.

## Scope and limits

- No save-schema changes. Existing knowledge derives the presentation on opening a court. No adjudication or authoritative ledger changes.
- The four late civic records deliberately use the existing hall as a visual fallback. **Modern offices, conference-room architecture, modern furniture and new city rendering are not implemented by this branch.** Administrative descriptions and titles are not proof that those models exist.
- Wardrobe silhouettes are a shared stylized set, not a complete catalogue of every culture's ceremonial dress. Cultural dye identity is retained.
- The earlier raw clothing audit's residual flags remain documented in the animation handoff; do not call all legacy clothing collision-free.
- New wardrobe stress sampling also remains diagnostic: **439/1,344 sampled poses flag relative edge stretching**, across 72 body/outfit/clip cases, with **0.000 m measured coverage gap** after correcting opposite-leg correspondence. Worst edge: **5.95 mm to 31.25 mm** at the old male's business-jacket armpit while kneeling. These are not 439 distinct tears, but they are also not a passing numerical stretch audit. See `COURT_ERA_WARDROBE_HANDOFF.md` for thresholds, tradeoffs and exact evidence.
- Original seven body GLBs are unchanged. Additive bundles preserve faces, bind rigs and animation libraries; the old painted fallback art is unchanged.
- No physical folios or stationery were added. Generated diagnostics and caches are excluded from source commits.

## Validation

Final combined code checkpoint: `99df7bf9`. After importing the additive wardrobe assets, **256/256 tests in 17 suites passed**, with zero errors, failures, skips, flaky tests or orphan nodes (`artifacts/court-era-final-tests.log`, GdUnit `reports/report_27`). Coverage includes progression, civic stages, stage integration, etiquette, all wardrobe/body combinations, acting, figure looks, walking, the four selected executions, execution routes/support/casting, gore, room sets and the director. Test process exited 0.

The private six-period GPU diagnostic passed and wrote 18 captures (standing, arriving and departure for each period) to `reports/court_eras/`; reviewed medieval, industrial and modern garments in the real court lighting. Process 43608 exited 0 and was verified absent afterward. No script/render errors; the existing compatibility-renderer depth-of-field warning remains. These captures show the existing hall/central hearth still used in later periods, confirming the architecture limitation above. No player session was launched or interrupted.

Wardrobe worker evidence: seven raw rig/face/buffer invariant checks passed and 20 private sheets covered 140 body/outfit/pose views. The separate raw stretch diagnostic remains **439 flagged samples**, as documented above; the functional suite's green result does not supersede that limit.

`tests/court_era_capture.tscn` is an isolated six-period diagnostic using real stage and figure code. Run it only with `tools/run_isolated_gpu_probe.ps1`, Dummy audio and the explicit worktree; it is not the current game. The integrator must re-run combined court tests and clothing checks after resolving shared-file conflicts, push and verify main, then launch only through the canonical launcher.
