# Current integration checkpoint

## Latest: release 2026.09.05.5

Battle/siege HUD delivery through worker 018cedd is integrated as 540d1d4
from c89b895 with test project settings excluded. Includes formation orders,
replay, siege controls and linked battle history. Saved notification restoration
preserves fractional time. See RELEASE_2026_09_05_5.md for validation and audit.
The sections below are historical checkpoints, not the current launch record.

Continuous actual-world city encounters and faction uniforms remain PENDING;
no implementation commit exists yet. Outposts, sliced vegetation and unfinished
Blender authoring remain HELD. All prior worktrees/local changes are preserved.
Copy-ready worker prompt: WORKER_PROMPT.txt. Player: canonical main via the
desktop shortcut. A running test scene is never the current campaign.

Verified canonical launch September5 16:56:05: PID3672, source540d1d4,
release2026.09.05.5, --resume-saved. Title and log confirm SeanTown/day9432/
population405. Exact saved time9432.03296121855 passed the isolated resume check.
The disposable siege preview PID51828 closed normally; no worker was stopped.
Original quicksave hash remains unchanged. Latest validation:174/174 cases plus
private-desktop battle/siege interaction probes and actual copied-save GPU check.

Canonical player checkout: `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`.
The OneDrive project is archived. Use `tools/launch_game.ps1` or the existing **Play Tomorrow and Tomorrow** desktop shortcut. The launcher prints the commit it starts. F5 runs the game; F6 may run a preview scene.

Release **2026.09.05.4** is integrated on canonical main (gameplay `3657301`, worker `1d71971`). It includes all prior releases plus direct city orders, visible battle starts, occupation figures, retained scattered-personnel records and compact death summaries. Canonical combined validation: **118 tests passed**. Real GPU mouse probes pass; both renderer-only figure tests also pass. Player launched source `3963fde`, PID41076, September5 14:14:24; title/log confirm .4 and resumed SeanTown/day9432/population405. See `docs/RELEASE_2026_09_05_4.md` for the final launch record. A worker branch alone never updates the running player.

Current saved campaign: September 5 13:45:30, SeanTown, day9432, population405, seed1792400273. The day9049 battle left four occupation soldiers and two scattered, zero killed; pending aftermath is preserved. Previous .1/.2/.3 launch records below are historical, not the current build.

Military readability `cc5ffc5`, rumors `1672447`, Inquiry/Materials/scouting `aba8c73`, occupation `5c39a0f`/`81c38d2`, recovery `d8bf575`, final guards/version `c337a0f`, and isolated spatial report `a9dddbb` are integrated. See docs/RELEASE_2026_09_05_1.md for behavior-specific validation and limits. Canonical combined suite:125 cases pass. Outposts, unrelated economy, sliced vegetation and unfinished Blender authoring remain HELD.

## Consolidation queue — September 5

| Delivery | State | Location / evidence |
| --- | --- | --- |
| Strategic charts and dynamic dock tabs | INTEGRATED | Worker `4107fd1` → main `12d16a3`; 64 combined tests + GPU |
| Discovered city intelligence | INTEGRATED | Worker `02a6587` → main `efbff12`, follow-up `691eed6` → `d418704`; 113 combined tests + 14 focused follow-up cases + GPU |
| Zoom terrain fill | INTEGRATED | Worker `1142441` → main `42595fb`; five terrain cases and expanded camera runtime probe pass |
| Military usability redesign | INTEGRATED | cc5ffc5 after explicit reauthorization; live progress/focus/selection and canonical GPU checks |
| Outposts, sliced vegetation, unrelated economy and Blender authoring experiment | HELD | Preserved prototypes below; excluded from the player build |

Historical consolidation session: player PID 65696 started before the integrations; the user later saved and closed it. See the current release/session status above. Save and exit normally, then use **Play Tomorrow and Tomorrow** to load the integrated code. The shortcut's target and working directory were verified canonical. Older process references below are historical checkpoints, not current status.

## Integrated

- Existing terrain, cities, animated armies, battle generals/carnage/cameras, scouting, military progression, civics, historical people, ambitions and diplomacy: retained from the prior reconciliation through `af76241`.
- Player century focus and council recommendations: `69bc384`, from worker `4967e43`.
- Encounter terrain, opposing contact choreography, clearer battle losses and persistent injured veteran workforce capacity: `3485f1b`, from worker `64d7c7f`.

- Civic and foreign leader conversation continuity: `2dff85c`, from worker `e11302c`; 24 civic context messages, recent decisions, persistent foreign discussions and recoverable failures.
- Scout returns preserve simulation speed and keep reports available for later reading: `cf3a058`. Recruitment outcomes restored to first report page and unused HUD label removed: `4bc66f4`.

## Preserved pending work

- Frontier outposts: uncommitted isolated prototype in `C:/Users/sjpur/tt-frontier-outposts`; explicitly not ready for the game. No autoload, shared state, UI or save hooks are integrated.
- Blender contact clip authoring experiment: preserved in `C:/Users/sjpur/tt-battle-contact-landscape`; missing source blend dependencies prevented export. Existing runtime animation assets remain in use.
- Sliced vegetation: uncommitted, unvalidated prototype in `C:/Users/sjpur/tt-sliced-vegetation`, held outside the player build.
- Older worktrees are retained for traceability. Many commits were cherry-picked/reconciled, so differing hashes do not imply missing features. Do not bulk-merge their old versions.

## Ownership and delivery

One integrator owns main. Every worker starts from the current integrated main in its own `codex/<task>` worktree, reports file ownership, tests, and returns a task-only commit. A worker's preview is not a player release. Update this file and `FEATURE_RECONCILIATION.md` when integration is verified. Keep unfinished prototypes explicit; never claim all planned features shipped.

Preserve saves, existing uncommitted files and active player sessions. A running process may still contain older scripts/state. Save and restart after structural integration; do not kill a live game to make it look current. No automatic folder synchronization or copying from the archived OneDrive tree.

Copy-ready worker instructions are in `docs/WORKER_HANDOFF.md`.

## Verification at this checkpoint

The broad suite ran 522 cases (two skipped). It exposed four assertions in one recruitment-report test and an orphan HUD label. Both causes were fixed. The final combined focused run passed 66 cases with zero errors, failures or orphans (dialogue continuity, 39 UI cases, scout return speed, injuries/geometry and century focus). The earlier broad suite covered century-scale rivals, billion-population bounded state and military accounting. It was not rerun in full after the isolated fixes.

Actual save/load, opening/century renewal, GPU battle graphics and foreign diplomacy probes passed. The offline pronouncement probe now explicitly disables API access for its offline cases and passes. Worker HTTP failure/retry and four live Terra conversation turns passed before integration. Engine shutdown still reports two ObjectDB instances and one resource in the final save probe; no clean shutdown claim is made.

Revised battle demo was visibly replayed from canonical main and verified via a fresh screenshot. It is explicitly labeled BATTLE DEMONSTRATION. The separate campaign process and editor were preserved. Save and restart the campaign through the canonical launcher to load all integrated structural changes.

## Latest visual refinement

Integrated `1af3fbe` from `codex/battle-planted`: fighters stay planted after approach, use varied guarded weapon strikes and small upper-body hit reactions instead of reciprocal whole-body sliding. A 100-frame/five-second GPU temporal probe measured zero root drift while attack and guard poses changed; the battle graphics regression passed. No casualty, population or save rules changed.

## Sustained sieges and protection diplomacy — September 5

Canonical implementation checkpoint: `7964a29` (sieges `8077fa3`, protection/leagues `60910ec`, combined relief persistence tests `7964a29`). These changes are integrated into main, not yet loaded in a player process started at `883a8f2`. Preserve its session; save and relaunch through the canonical launcher when ready.

- Fortified home settlements can hold through sustained sieges, including the unattended threat deadline. Ordinary raids and occupation defenses keep their existing controls. A stationed field army can choose **BESIEGE SETTLEMENT** in foreign civilization actions, then use **WAR PLANNING** to continue, negotiate, seek allied relief, assault/sortie, or withdraw.
- Blockade reduces actual home harvest and the target region's share of rival food production. Existing reserves bridge shortfalls; rival aggregate demography responds after reserves can no longer bridge lost production. Supply and besieger endurance limit the investment. Army movement is locked during investment, and withdrawal uses its physical return route. Starting a siege does not transfer people or territory.
- Protection treaties and leagues require provisioned envoy negotiation and consent. Existing promises cover verified future defensive attacks, not retroactive aid for player-started wars. Independent members can disagree, leave, or refuse unaffordable relief. See `PROTECTION_FACTIONS_HANDOFF.md` for the diplomacy model and limits.
- Delivered relief is a one-use receipt, a separate allied camp, and a physically timed return. Donor military/food accounts stay separate from player population. Camps consume 0.55 Food per troop per day, matching the donor's reserved thirty-day provisions. Camps affect access and do not participate in tactical casualty rounds; all surviving camp personnel return through the same donor ledger.
- Enemy stores are never displayed as a live exact number: the siege view shows returned, dated observations or unknown. Orders precede detailed assessments in the dock. Reputation abbreviations were replaced by explicit Mercy/Fear/Grievance labels.

Validation on canonical main: **98 cases, zero errors/failures/skips/orphans**, across siege progression, real relief integration plus inherited commitments, dialogue continuity, 39 UI cases, military accounting, injuries, and century focus. Actual full-world `SAVE_LOAD_PROBE PASS`; GPU `SIEGE_UI_PASS`, capture inspected and test window closed. Import clean. The worker also supplied 96-case civilization/century regression, final 19 commitment/dialogue cases, actual persistence, live Terra negotiation and council GPU evidence before integration. No repeated full 522-case claim.

Current limits: one player siege at a time; no rival-only playable siege scenes, automatic foreign-only relief combat, ocean transport/pathfinder, or siege of a third party's occupied territory. Foreign food/demography retains the simulation's monthly resolution. The existing camp/army records remain bounded; history retains 24 sieges.

Strategic charts are newly authorized but still being implemented in `C:/Users/sjpur/tt-strategic-charts`, branch `codex/strategic-charts`, base `883a8f2`. They are not in this checkpoint. Its held vegetation prototype remains held, as do outposts and other unrelated economy prototypes.

## Scouting archive and military audit — September 5

Integrated scout worker `6e6b6d0` as `d0315c9`. World / Scouting shows up to three highlights from the latest eight returns plus **Expedition Archive**. The archive renders five cards per page, supports saved-text search (including exact `party N` / `day N`), All/Findings/Routine/Losses/Unread filters, and significance/newest sorting. Each card opens the retained full report; Back to Archive restores the query, filter, sorting and page. Routine evidence is summarized on the findings page and retained in Journey & Accounts.

Full report retention increased from 24 to 256; existing reports are preserved and no knowledge/deposit/formation simulation was changed. Unread metadata begins with new returns; older records have unknown review status until explicitly opened. Reports already evicted from older saves cannot be restored. Earlier map/contact/resource knowledge remains under its existing authorities. The UI states the retention limit rather than implying an infinite archive.

Large repeated cover art is removed from the findings page. Journey details may show a 112px illustration selected only from saved terrain words. Forest, river, mountain and desert records select matching existing art; absent terrain evidence gets no decorative fallback. The actual saved route chart remains available. No new illustrated landmarks or map evidence were invented.

Canonical validation: 71 cases pass with zero errors/failures/skips/orphans (archive, 39 existing UI, return-speed, siege and real relief tests). GPU archive passes at the real 540px dock width: 256 reports, 5 rendered cards, 29 search matches, empty-result behavior. Worktree GPU navigation also verifies opening a report and returning preserves search/page. Probe windows closed; player/editor preserved. No-autopause behavior remains intact.

Military audit `docs/MILITARY_CONSOLE_AUDIT.md` and `tests/military_console_audit_probe.tscn`: reproduced hover-induced frozen progress labels, fractional work versus calendar-day ambiguity, and condition-based BROKEN semantics. Proposed plain-language status/grouping fixes are documented. No military usability fix is claimed integrated by this audit.

Historical session at this earlier checkpoint: PID 54444 at 883a8f2; see the top of this document for current session status. Save and relaunch through the canonical launcher to load later features; it was not silently restarted. Newly authorized charts, discovered-city intelligence, and measured zoom-fill work continue in separate worktrees with explicit shared-file ownership. Held outpost/economy/vegetation prototypes remain held.

## September 5 — independent city intelligence

Worker `02a6587` integrated as `efbff12`. Foreign cities use the existing five strategic urban regions per polity, independent markers and hit targets, and per-observer dated reports. Discovering one does not expose the others. Estimates age and remain frozen between observations; scouts, envoys and army runners deliver reports through their return paths. AI player-city knowledge uses the same evidence model and gates targeting. Existing secondary-city defense simulation remains absent rather than fabricated; the military campaign still targets the player primary city. Regional food outlook is not a per-city warehouse ledger. Full bounds, save compatibility and limitations: CITY_INTELLIGENCE_HANDOFF.md.

Canonical eight-suite 113-case regression passes. This includes actual city-intelligence and strategic-history save/load coverage. The worker's full 118-case civilization/century run finished with 117 passes and one founding-focus visibility failure, zero runtime errors. Both 36,500-day scale simulations passed, including billion-population bounded state. The one-line visibility guard was restored in `d418704`; the failed case plus all 13 city-intelligence cases then passed canonically (14/14). The entire 118-case suite was not repeated after that isolated fix. Canonical city-report GPU capture and three independent hit targets pass; probe exited and stderr is empty.

## September 5 — zoom terrain streaming

Worker `1142441` integrated as `42595fb`, preserving independent-city marker/hit-test code, chart daily sampling, and the scouting archive. Obsolete camera jobs are canceled, a geographic coverage pass precedes full detail, four completed meshes and their river-height fields are cached, and the world mesh remains visible outside the streamed rectangle. Save format unchanged.

Canonical five terrain cases pass; expanded camera probe passes smooth/anchored zoom, north reset, cancellation, coarse-to-fine scheduling and bounded exact mesh reuse. Camera probe shutdown reports two ObjectDB instances and one resource still in use; no clean-shutdown claim. Worker GPU comparison measured zero uncovered frames versus up to 338, and cached revisits of 40–81ms versus seconds. Cold fine detail still takes roughly six seconds, and some frame spikes remain. Synthetic million-person fixture is not a loaded mature campaign benchmark. See ZOOM_PERFORMANCE_HANDOFF.md for comparable measurements and limits.

All agreed completed deliveries are integrated; no further feature expansion is underway for this consolidation. Military usability and older unfinished prototypes remain HELD.

Final canonical GPU zoom run completed all eight transitions with zero uncovered frames; screenshots inspected. Its test process exited. Like the camera probe, it reports two ObjectDB instances and one resource in shutdown cleanup; no new script/parser errors appeared. This capture run is visual/integration evidence, not the screenshot-free comparative benchmark above. Player PID 65696 remains the only canonical campaign process and was not restarted.


September 5 follow-up integrated: fd7b360, version 2026.09.05.2. Reported-settlement close rendering and complete-batch recruitment/readiness corrections. Canonical 78-case regression and both actual-save GPU probes pass. See docs/RELEASE_2026_09_05_2.md for current campaign blockers, evidence, and limits.


Release2026.09.05.3 integrated187bea5: polished foreign city reports, named city army arrival, explicit scout labels and successful deliberate attack/siege starts war without declaration. Canonical88tests +actual-save GPU verification pass. See docs/RELEASE_2026_09_05_3.md; peacetime trespass response remains unimplemented.
