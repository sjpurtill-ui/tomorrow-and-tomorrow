# Leader conversations

Open **Talk to Council** from Council, **Talk to Marshal** from Military Command,
or **Talk to…** on a leadership card. The office selector switches between the
Council, Steward, Marshal, Quartermaster, Scholar, and Envoy. Each has a separate
session history, capped at 24 messages. Starting a new world cancels pending
requests and clears all conversations and drafts.

The complete prompt lives in `scripts/leader_conversation.gd`, in `SYSTEM_PROMPT`.
It asks the configured model to answer naturally, retain the discussion, ask a
focused question when material intent is missing, and work toward a faithful
decree. Each request includes recent conversation, the office's perspective,
current domestic state, active policies, and engine assessments for supported
policies. It uses the existing `LEVIATHAN_AI_*` configuration; no model is hardcoded.

Historical coercion is treated as fictional aggregate simulation. The prompt
does not permit moral objections to become mechanical vetoes or a different,
gentler policy to silently replace the player's intent. It distinguishes physical
impossibility from temporary capacity/resource constraints and missing mechanics.
Resistance, costs, casualties, and political consequences remain part of the sim.

The model returns spoken text and, when appropriate, a draft decree with catalog
mappings. Discussion never directly executes. Drafts must pass the existing
grounding, policy-ID, action, duration, and magnitude validator in full; partially
valid drafts are rejected rather than partially issued. The player sees the exact
decree and deterministic estimates before choosing **Issue this decree** or
explicitly accepting the current draft with `issue it`, `do it`, `yes`, or
`proceed`. Any other message invalidates that offer, preventing edits or questions
from issuing stale terms. An issued draft is consumed once.

Execution calls `AdvisorSystem.execute_pronouncement`, which recalculates current
capacity, resources, implementation, compliance, resistance, and direct effects
through `ConsequenceEngine`. The result shown after issuing comes from that engine,
not a model claim. Multi-policy estimates are individual snapshots; actual policies
execute in order and can have different outcomes as earlier policies consume resources.

This adds dialogue around the existing civilization-wide policy mechanics. It does
not add arbitrary effects, individual/subgroup targeting, exact casualty outcomes,
or natural-language execution of army movement and production queues. The prompt
requires those limitations to be explained as limitations of the current build,
not as historical impossibilities. Existing military controls remain available.

If configuration, transport, or response validation fails, the conversation reports
that nothing was issued. It never silently falls back to executing keyword matches.
The underlying explicit pronouncement interpreter remains available to existing
internal callers and tests.

Validation: `tests/leader_conversation_probe.tscn` covers discussion, draft revisions,
stale/double acceptance, unsupported mappings, historical coercive execution,
repeal, bounded per-office history, offline behavior, panel state, and world reset.
With `tests/mock_leader_conversation.py` running on loopback port 18769 and
`LEADER_CONVERSATION_MOCK=1`, it also tests HTTP round trips, retained draft terms,
follow-ups, malformed replies, and cancellation. These deterministic fixtures verify
the integration; a live provider evaluation is still needed to measure dialogue quality.
