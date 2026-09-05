# City intelligence handoff

Worker: `C:/Users/sjpur/tt-city-intelligence`, branch `codex/city-intelligence`, based on `b0af56e771c12329758284084a043cf16e0d4474`.

## Behavior

- Each existing foreign strategic urban region has its own stable city identity and world position, with the capital anchored to the existing polity home. Discovering one does not reveal its siblings.
- Terrain markers and hit targets use city IDs. Markers are culled to the nearest 64 in camera range; labels appear only at close zoom. All retained reports, including unidentified locations, remain accessible from scout dispatch's **All City Reports** button. Foreign polity detail also opens its city directory.
- Reports carry observation day, arrival day, source, reference, confidence, estimated ranges, and freshness. Unknown fields are omitted from evidence and explicitly labeled in the UI. Older observations widen in uncertainty without consulting live hidden values. Learning an owner change requires another observation or a battle report.
- Scouts and envoys carry frozen observations until return. Lost scouts publish nothing. Army runners carry observations at departure; signal-era communications use the existing live-report rule. Fast-forwarded trips without sampled observations establish only undated locations, never retroactively sample historical statistics from the present.
- Player and rival observers use the same field thresholds and error model. Foreign scouts learn player cities only on physical routes and deliver knowledge on return. Secondary player cities are independent records. Rival threat/power estimates and primary-city targeting use their surviving dated reports, not live player population or army strength. Envoys disclose their origin location without a census.
- Public city lists, campaign choices, forecasts, army-front estimates, dialogue context, and siege supply outlook use recorded evidence. Knowing statistical inference does not disclose a live global national ranking. The internal competition/victory simulation still operates normally. Aid quantities depend on the player's own capacity rather than private rival population.

## Save compatibility and bounds

The existing civilization save envelope gains optional `city_intelligence`; mission dictionaries and runner snapshots optionally carry `city_observations`. Older saves load without these fields. Migration retains previously reported home locations only, with no fabricated census or revelation of the other cities. Existing running armies are not teleported. Incoming records and runner observations are validated before mutation. Actual SaveSystem round-trip and rejected malformed-record atomicity are tested.

Books are bounded at 64 observers and 512 cities per observer; current rival city count remains the existing five regions per polity. No individual population entities, duplicate settlement economy, or new autoload is introduced. JSON coordinate precision is checked within 0.001 km; evidence fields and record metadata retain equality through the real save/load path.

## Limits

- The foreign simulation currently models five strategic urban regions per polity. Aggregate `settlement_count` does not represent independently positioned economic entities and therefore does not create additional invented map icons.
- Foreign food is an observed regional reserve outlook drawn from the controlling polity's existing food account, explicitly not an independently simulated warehouse. Individual deposits and warehouse inventories remain unknown. Secondary player-city garrison/defense ledgers do not exist and are not fabricated.
- The campaign engine still targets the player's primary city; discovering secondary cities does not introduce an unsupported secondary-city siege mechanic. Existing foreign campaign approach restrictions remain in force.
- This work changes AI knowledge about player cities. It does not redesign existing AI-versus-AI strategy or replace the older trace/hearsay discovery mechanism.
- Early army observations arrive with runners; battle outcome reports use the game's existing battle-resolution notification timing.

## Integration

Integrator owns canonical checkout and player launch. Do not launch this worktree as the player game. Preserve the running canonical session/editor.

Shared hunks: CivilizationSystem observation/diplomacy/scout return/public knowledge/save paths; local_terrain contact-marker refresh, city hit testing, city detail, scout dispatch footer; MilitaryCampaign army report snapshots/runner delivery/import validation and siege_public_snapshot; ForeignDialogue known context.

Keep canonical scout archive changes (`SCOUT_REPORT_LIMIT=256`, `archive_reviewed=false`). This branch adds only `city_observations` to a successful scout report and does not own archive review UI. Preserve charts' daily sample hook and terrain performance scheduling. Military usability's training/deploy/command-rail changes are separate from these runner and siege hunks.

## Validation

Focused suites: 49/49 passed (13 city intelligence, 12 siege progression, 13 siege relief integration, 11 diplomatic commitments). Includes actual save/load, legacy migration, independent discovery, no live-state leakage, stale ownership, reciprocal scout return, unknown-target denial, army runner delay, lost-report denial, and hidden-rank/capital rejection.

GPU probe `tests/city_intelligence_ui_probe.tscn`: passed on RTX 4090/OpenGL; three independent terrain hit targets and selector records, controls inside a 1000x820 viewport, automatic exit. Screenshot: `artifacts/city-intelligence-ui.png`. The final probe also compiles current terrain and city UI.

Civilization regression fixtures now provide explicit reconnaissance instead of treating a country-wide intelligence percentage as knowledge of all cities. Century, aggregate population, victory, save-size, trade/war and existing campaign checks run in `artifacts/city-complete.log`.

Final full run: 117/118 passed, zero runtime errors, in 4m45s. Both 36,500-day simulations (normal and billion-person populations), bounded save size, and state validation passed. The sole failure exposed a missing founding-focus intelligence gate in the public-profile refactor. The follow-up restores the existing 0.58 gate; the failed case plus all 13 city-intelligence tests then passed (14/14, `artifacts/city-founding-gate-final.log`). The lengthy unchanged scale checks were not repeated after this one-line presentation fix.

Integrator confirmed the initial implementation integrated as `efbff12`, with 113 combined canonical tests and the canonical city UI probe passing. The founding-focus gate follow-up must also be integrated. No worker player-game restart was performed.
