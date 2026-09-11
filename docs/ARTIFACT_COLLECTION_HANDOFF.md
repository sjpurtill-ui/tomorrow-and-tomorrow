# Artifact collections

READY. Feature worker delivery; not integrated into canonical main.

Worktree: `/Users/seanpurtill/Documents/Codex/tt-artifact-collections`

Branch: `codex/artifact-collections`

Base: `940d5a2ad848d9f45b8d98825cd5219a3eda83e9`

## Behavior

Exploration into physically visited, uncharted land now recovers deterministic material-culture artifacts as well as the existing specimens. The catalogue has 4,096 named combinations of 16 objects, 16 decorative styles and 16 motifs, using materials appropriate to the object. Five rarity tiers have 60%, 28%, 9.5%, 2.2% and 0.3% nominal hash-roll shares. Artifacts feed sixteen existing research subjects. Study can introduce questions before their ordinary date; prerequisites, research workers, materials, completion and adoption remain authoritative.

Each returned artifact accumulates custody days. Its prestige is rarity weight times `1 + log(1 + held_days / 360)`, with rarity weights from 1 to 39.0625. Appraisal is 20 times prestige times study factor (1–2). Holding a larger, older collection adds logarithmic research support: 4.5% times log(1 + total prestige) for ordinary research, 7.5% for cultural research. Cultural capacity also receives 12% of that cultural research bonus, within its existing 0–1 bounds. Losing an object removes its ongoing support; completed discoveries remain learned. No exponential income loop or population creation is introduced.

Peacefully contacted owners can receive gifts, purchase artifacts when both have currency, or exchange an artifact of at least the requested value. Trades move the actual objects. Sales debit the buyer's treasury, transfer currency and the corresponding minimum reserve backing, and credit the seller. Gifts increase recipient respect once per object/owner pair, preventing repeated gift-return farming. Discovery provenance stays intact. Site claims persist after sale, gifting, or failed return and are checked across civilization owners.

Public Libraries and Comparative Chronicles enable museum exhibition. Studied exhibits attract paying domestic visitors once currency exists. Revenue is limited by collection prestige, existing Knowledge staffing and household liquidity; receipts move existing private currency to the treasury. Museums are curated collection status within existing institutions, not new map buildings or international tourist travel simulation.

Brought Home supports name/origin search, pages of 40 items, rarity, prestige, appraisal, age, museum status, gifts, sales and trades. Requested foreign objects have their own name search and a maximum of 40 menu results. The panel pauses the simulation through the existing nested-modal pause helper and restores the prior speed on close.

## Validation

Run headlessly from the explicit worktree, with `override.cfg` assigning isolated user data `TomorrowArtifactCollectionTests`:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-artifact-collections -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/test_artifact_collection.gd -a res://tests/test_society_exchange.gd -a res://tests/test_discovery_projects.gd -a res://tests/test_civilization_owned_simulation.gd
```

Final combined run: **91 cases pass**, zero errors/failures/skips/orphans (`/tmp/tt-artifact-final-tests.log`). Final focused run after the last interface and effect assertions: **37 cases pass**, zero errors/failures/skips/orphans (`/tmp/tt-artifact-final-focused.log`). All owned Godot processes exited.

Coverage includes deterministic catalogue diversity, research benefits and early questions, appreciation, ownership transfer, repeat-gift prevention, currency conservation, museums, legacy records, reflected serialization, daily idempotence, populated 340×640 / 960×720 layout, paging and search, plus existing exchange/research/owned-civilization continuation regressions. The 4,096-item accrual/summary/validation probe took approximately 38–41 ms across the last runs; this includes several scans and is not a frame-rate or full-campaign benchmark. UI checks are headless geometry checks, not native rendered image validation.

## Compatibility, limitations and integration

Existing `GameState.society_exchange` remains the sole owner of records. New metadata and ledger keys are optional and validated. Legacy objects accrue from subsequent simulated days; no retrospective finds or years of custody are invented. Collections and claimed sites are bounded at 16,384 per owner. Knowledge/evidence/origin limits rise with this bound. All owners use the same rules; this does not add autonomous AI collection trading strategy.

The thousands are generated catalogue variants, not thousands of individually authored stories, powers or raster illustrations. Sixteen research families and five rarity tiers differentiate their effects. Existing symbolic icons are retained. Museums have domestic admission revenue; physical museum construction and international visitor routes are not implemented. Full multi-century balance and mature-campaign frame-rate testing remain outstanding.

Owned files: `scripts/artifact_collection.gd`, `scripts/society_exchange.gd`, `scripts/hud/exchange_collection_panel.gd`, targeted research/cultural-capacity hooks in `scripts/discovery_system.gd` and `scripts/society_model.gd`, artifact/exchange tests and this handoff. `discovery_system.gd` is a named shared integration hotspot. Other recent exchange/scouting work could conflict in `society_exchange.gd` and the collection panel; reconcile deliberately. No canonical changes, merge, player launch or player/editor interruption. Remove the owned test override before integration/package. The integrator must merge and verify canonical main before describing this as included in the current game.
