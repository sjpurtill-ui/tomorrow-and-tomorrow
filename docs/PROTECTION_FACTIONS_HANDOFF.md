# Protection, leagues, and foreign negotiation

Worker: `C:/Users/sjpur/tt-protection-factions`, `codex/protection-factions`, base `883a8f24dece8da6155c4cba1e2270d2bea3a0ee`. This work is not integrated or loaded in the running player game until the integrator explicitly verifies it.

## Player behavior

Foreign audiences now offer **Treaties & Leagues**, with a council view of independent leaders, membership, goals, disagreements, defensive calls, and recent dealings. The conversation can draft protection, founding/admission, policy, war consultation, departure, relief requests, and siege withdrawal terms. Reviewing a commitment draft opens its corresponding controls. Discussion, revision, refusal and provider failure never execute commitments.

All commitment proposals use the existing `leader_parley` mission: actual envoy provisions and travel, with additional provisioned round trips to existing league members for consultation. The council displays those costs and elapsed days. Conditions and votes are checked again on return. Serial checks prevent replay. Research accords keep their original timber and research rules.

Mutual protection is a separate, indefinite bilateral promise, covering future defensive sieges until war breaks the agreement. A league is a persistent group of up to nine independent civilizations, with up to four groups tracked. Founding, admission and goal changes require consent; any member's disagreement is recorded. A player can leave, and later request admission to the remaining league. War between members breaks their shared membership. Membership dates prevent retroactive coverage. A war debate records positions but does not silently declare war or deploy anyone.

Foreign league members shift at most four percentage points of their existing strategic allocation toward military, knowledge or production for defense, learning or routes respectively. Total allocation remains conserved. Player allocations remain under player control.

## Siege integration contract

The integrator owns `military_campaign.gd`, siege progression/UI and the reserved civilization harvest/health hunk. This branch does not modify them.

- `ForeignDiplomacy.notify_defensive_siege(attacker_id, defender_id, siege_id, day)` verifies the current public siege and an active war with a recognized initiator. Player declarations, ambiguous legacy war causes, and occupation uprisings do not create defensive protection obligations.
- `ForeignDiplomacy.open_relief(siege_id)` shows eligible prior promises and sends a physical relief request.
- `MilitaryCampaign.siege_public_snapshot(siege_id="")` supplies `id`, `active`, `attacker_id`, `defender_id`, `start_day`, and known `target_position:{x,z}`; player ID is `player`.
- On return of an accepted request, the donor reserves at most 20% of its actual military population and deducts actual `food_days * population` supplies. It retains twenty food days at home and provisions both travel legs plus thirty days of camp rations. Poor relations, inadequate readiness/stores, a changed siege, or ended commitment can prevent dispatch. No player population is added.
- After actual army travel, the module calls `MilitaryCampaign.receive_siege_relief(siege_id, receipt_id)`. That method must validate the active beneficiary before calling `CivilizationSystem.consume_siege_relief_receipt(receipt_id, siege_id)`. A delivered receipt is consumed once and supplies a separate camp, never merged into player soldiers or casualty counts.
- Siege end/exhaustion calls `ForeignDiplomacy.complete_siege_relief(receipt_id, survivors, unused_food)`. This schedules the return journey and later restores actual donor troops and unused cargo. The current camp contract requires all issued troops to survive: a future combat-loss integration needs an explicit death/cohort transaction, not silent subtraction. Travel rations remain consumed.
- Negotiation checks `MilitaryCampaign.siege_negotiation_available(siege_id,civ_id)->{ok,reason}` before dispatch and again on return. `negotiated_siege_withdrawal` applies accepted, currently credible terms; no free capture, instant troop relocation, or unearned ceasefire.

## Reciprocal aid and limits

Known allied invasions create requests only from actual foreign war records after message travel. The existing simulation has one player engagement, not rival-only playable siege scenes. Reciprocal requests therefore direct the player to existing army controls or physically carried Food aid; they do not invent a besieged city or create an army. Food aid is marked delivered only on the real envoy return. Foreign-only automatic relief combat is not implemented. Leagues are founded through player diplomacy; this does not introduce autonomous off-screen league founding.

Relief travel uses the simulation's existing distance/logistics travel model. It does not add ocean transports or a new pathfinder. Attacker stores remain unavailable; discussion gets the siege system's public assessment and dated reports only.

## Persistence and bounded state

Commitments are nested inside the existing curated `ForeignDiplomacy` save payload; no new autoload or save-system authority. Older saves without commitments load empty state. Validation checks terms, finite amounts, membership uniqueness and dates, bounded records, receipts and food consistency before mutation. Existing dialogue saves remain accepted. Foreign leader/dialogue capacity is raised from eight to 64 because the current world can contain more than eight contacted civilizations; per-leader message limits remain unchanged.

Limits: eight separate protection treaties, four leagues, nine members per league, 32 obligations, 16 concurrent relief expeditions, 24 commitment history entries. Expired historical obligations are pruned. No household/citizen entities are added.

Shared CivilizationSystem additions are the daily commitment advance; a strategic allocation adjustment before `_advance_civilization`; a physical-food-aid return note; receipt forwarding; and carried commitment validation. None overlap the reserved siege food/health hunk.

## Verification

- `tests/test_diplomatic_commitments.gd` and `tests/test_dialogue_continuity.gd`: 19 focused cases pass, including actual SaveSystem save/load, envoy timing, replay, disagreement/admission/leave/rejoin, conservative allocation, initiator and membership-date triggers, reciprocal message delay, real relief conservation/return, malformed saves, and conversation isolation.
- `tests/live_commitment_probe.tscn`: two live Terra turns pass: protection draft then league revision; no world action.
- `tests/commitment_ui_probe.tscn`: GPU council capture passes viewport/control bounds and closes itself. Capture is under `artifacts/commitment-council.png`.
- Wider commitment/dialogue/civilization/century regression: 96 cases passed with zero errors, failures or orphans, including century warfare and billion-population bounded-state tests. The final focused run after membership-date and receipt validation changes passed 19 cases; the added actual Food-aid return check also passed. Headless final import reported no script errors. Combined siege callback verification remains the integrator's release gate.

The player/editor processes were preserved. This branch's scripts and new state require integration, then a saved campaign restart to load consistently. Do not present the isolated capture or worktree as the current game.
