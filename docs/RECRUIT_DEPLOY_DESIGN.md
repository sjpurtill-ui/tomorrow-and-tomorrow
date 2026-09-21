# Recruitment, training and deployment

## Governing rule — September 20, 2026

The user explicitly rejects predetermined manpower percentages, conscription-law ceilings and technology gates on how many people a nation may draft. Recruitment can consume every actual available working-age person. It cannot duplicate troops, draft away scouts/envoys/convoys, create population, or create equipment. Military knowledge still determines which kinds of formations and equipment are understood; unfamiliar practices remain slower and riskier. Prototype headcount and one-cohort limits are removed.

Drafting displaces civilian work. `GameState.effective_workers` reduces actual civilian worker availability by mobilization beyond Defense allocation. Settlement-local scopes carry the same national fraction instead of subtracting the entire national army from each town. Drafting all available adults can leave no farm/workshop workforce. Food bills, instruction crowding, equipment deficits, injury, weak proficiency, upkeep and existing hardship/desertion systems continue. Cancellation/demobilization returns people to the civilian workforce; injuries already suffered remain. These are modeled consequences, not a promise of a new comprehensive political draft-resistance system.

## Implemented land recruitment workflow

- Recruit & Deploy opens a compact formation queue board rather than the old design chooser.
- Select an era-appropriate template; set parallel formations, serial batches, or continuous repetition.
- Each line owns its copied composition and its own recruits. It never counts a shared home soldier twice.
- Manpower, equipment and instruction are separate progress bars. Missing equipment, food or classroom places do not forbid enlistment. Instruction consumes available food, including civilian reserves; no food means no instruction progress. Crowding reduces instruction speed. Equipment/personnel completeness limits new-line training progress.
- Low/normal/high priority allocates incoming equipment and available people. Existing reservations stay with their owners. Pause, cancel, repeat and automatic deployment are supported.
- Fully trained/equipped formations deploy automatically. A manual early-deploy action unlocks at 20% training; they receive reduced skill through the existing combat model. Training injuries may leave a completed cohort understrength.
- Deployment creates a new army at home or joins a selected existing army stationed at home. It transfers real recruits/equipment; it does not teleport them to a distant front. Battlefield commands and commander authority are unchanged.
- Completed line settings remain available for review/reuse. Pending headcounts remain aggregate: a million requested parallel formations with a small population does not create a million empty objects. Queue rendering paginates lines and formations. Recruitment operates on aggregate cohorts, never individual people.
- Old standing-template requests and saves still work, with their arbitrary intake restrictions removed. New lines and reservations use the normal military save payload and its actual binary Variant codec; malformed line identities/links are rejected.

## HOI4 comparison and remaining differences

The reference is HOI4's template → recruitment queue → equipment/training → deployment workflow, described in the [Paradox-authored user manual](https://manualmachine.com/paradoxdevelopmentstudio/heartsofironiv/17905101-user-manual/). This delivery implements the land queue mechanics above; it is **not a claim of exhaustive HOI4 parity**.

Deployment-site selection currently uses the home assembly site and existing armies at home, not an arbitrary owned province and automatic front assignment. Template edits do not retrofit already-queued copied compositions. Reinforcement/upgrades do not yet have HOI4's global equipment-priority controls relative to new formations. Naval commissioning and air-wing creation retain the game's existing service workflows. Existing independent-command representation bounds remain; more soldiers can join an existing home command. These differences need further work to satisfy literal parity; none should be hidden behind an “exactly HOI4” claim.

## Validation and handoff

Worktree `/Users/seanpurtill/.codex/worktrees/military-recruit-deploy`, branch `codex/military-recruit-deploy`, base `e91927a3`. Owned systems: military recruitment/training/deployment, HUD queue/editor integration, civilian workforce accounting, settlement-local workforce context, related tests. Shared hotspots: `military_campaign.gd`, `game_state.gd`.

67 focused tests passed across recruitment/deployment, reconciliation, military accounting and training strategy. Checks include full mobilization and labor recovery, away scouts, million-formation pending requests, equipment priority, actual instruction-to-auto-deployment, early deployment, joining an existing army, pause costs, cancellation, binary save/load, invalid-save rejection, and headless UI construction. Existing graphical probes have assertions updated for the requested new rules but were not launched. No player restart, live graphical approval, performance benchmark or 3,000-year balance claim. The new staffing consequences intentionally change campaign outcomes.
