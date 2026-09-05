# Current integration checkpoint

Canonical player checkout: `C:/Users/sjpur/TomorrowandTomorrow`, branch `main`.
The OneDrive project is archived. Use `tools/launch_game.ps1` or the existing **Play Tomorrow and Tomorrow** desktop shortcut. The launcher prints the commit it starts. F5 runs the game; F6 may run a preview scene.

Latest tested feature: `d0315c9`, the scouting archive, on top of siege/protection checkpoint `b0af56e`. Military console audit `de1d41d` records findings and a reproduction; it does not implement a redesign. Charts, foreign-city intelligence and zoom-fill performance work are still pending.

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

Current running player was last verified as PID 54444 at 883a8f2. Save and relaunch through the canonical launcher to load later features; it was not silently restarted. Newly authorized charts, discovered-city intelligence, and measured zoom-fill work continue in separate worktrees with explicit shared-file ownership. Held outpost/economy/vegetation prototypes remain held.
