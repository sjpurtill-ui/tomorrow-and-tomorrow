# Leader dialogue continuity

Worker: `codex/leader-dialogue-continuity`, `C:/Users/sjpur/tt-leader-dialogue`, based on `af76241693721265ff56803f54faaae81c393b9d`. Integrator merges this task; the worker has not changed or launched canonical main.

## Behavior

Civic model context includes the bounded 24-message discussion and up to eight recent decisions with outcomes, instead of eight heavily truncated messages. Clear duration corrections continue a single unresolved proposal. Model/service failures preserve discussion and return no policies; “retry” resubmits the original failed wording. Explicit discussion boundaries such as “before I give an order” prevent deterministic grounding from enacting the policy under discussion. Normal validated orders retain their existing execution and reporting pipeline.

Foreign dialogue now requires a returned delegate exchange. A one-time audience uses existing `leader_parley` travel, personnel and Food provisioning, with no accord or Timber escrow. Thereafter the established envoy channel supports continued strategic conversation without another trip per message. Actual proposals still use existing dispatched terms and deterministic return-time acceptance/refusal/counteroffers. War may block agreements but does not erase or terminate discussion.

The foreign screen displays a scrolling transcript, preserves input when submission is blocked, and offers retry after service failures. Drafts persist through discussion and errors; players can revise or withdraw them. Context exposes the known civilization/leader, their communicated interests, existing memories/commitments, public treaty/war status and dated returned reports; it does not serialize private population, resources, locations or strength.

## Saves and live editor

Foreign transcript/draft/status is included in the existing curated ForeignDiplomacy save payload, bounded to 40 messages per leader. Old saves without dialogue load normally; older returned diplomatic reports can establish access. Saved pending replies become recoverable interrupted turns. Existing in-memory transcript format is normalized when accessed after script reload. Civic save fields are unchanged.

No new autoload or project setting is required. The integrator should save the live game before integrating, allow external script reload, and close/reopen the foreign leader panel: its node structure changed from a single Label to a RichTextLabel transcript. A currently running model request should finish or be cancelled before updating its scripts. If Godot cannot safely reload the autoload scripts, save and restart via the canonical launcher; the worker did not stop or restart the user's session. Live sync alone does not integrate this branch.

## Verification and limits

Focused civic and continuity suites pass. Existing foreign diplomacy regression passes (travel, escrow, counteroffers, agreements, war, save roundtrip). The local HTTP regression passes (retry, structured-output downgrade, terminal failure, malformed/oversized responses, redirect rejection, cancellation). A live gpt-5.6-terra probe passed two civic discussion turns and two foreign turns without unsolicited gameplay actions. The actual foreign screen was captured and checked, including the footer staying inside the viewport.

Context remains bounded, not an unlimited verbatim archive. Service outages cannot provide a fresh model answer, but leave the discussion recoverable. Supported foreign actions remain the existing three accord kinds; broader partner-specific trade/economy work belongs to its owner. Engine shutdown resource-leak warnings appear in runtime probes; no dialogue script errors occurred in the passing runs.

## Integration boundaries

Shared changes: `scripts/local_terrain.gd` only `_issue_freeform_order` (history/decision context and retry wording); `scripts/advisor_system.gd` conversation context/resolution; `scripts/pronouncement_interpreter.gd` context, speech-act guard and failed-request result; `scripts/foreign_diplomacy.gd` audience resolution and curated dialogue save hooks. Other production changes are `foreign_dialogue.gd` and `foreign_leader_screen.gd`. No changes to CivilizationSystem, GameState, SaveSystem, project.godot, the century `_process` gate, scouting return behavior, or economy files. No conflicts against the base; integrator should review shared civic/diplomacy hunks against newer main.
