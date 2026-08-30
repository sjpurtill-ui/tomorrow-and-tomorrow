# Tomorrow and Tomorrow

A Godot 4 grand-strategy prototype built around an organic province map.

## Run

Open this folder in Godot 4 and run the project.

## Current prototype

- 72 procedurally shaped provinces
- A newly seeded world on every launch, with continents and oceans
- Province and national borders
- Province hover and selection
- Pan and zoom controls
- Province adjacency with highlighted neighbors
- Terrain, population, and resource generation
- Resource-first economy that can develop weighed-metal exchange, recorded credit, and conserved currency
- A single starting settler with province-to-province movement

## Generative campaign director

Each new seeded campaign receives a founding mandate with conflicting success
conditions and starting pressures. If no API is configured, a deterministic
seeded director supplies a fully playable mandate.

To use an OpenAI-compatible generative endpoint, provide these environment
variables before launching Godot:

- `LEVIATHAN_AI_ENDPOINT` — full chat-completions endpoint
- `LEVIATHAN_AI_MODEL` — provider model identifier
- `LEVIATHAN_AI_API_KEY` — API credential (or use `OPENAI_API_KEY`)
- `LEVIATHAN_AI_STRUCTURED_OUTPUT` — `on`, `off`, or `auto` (default); `auto`
  enables strict JSON schema for the official OpenAI endpoint

The credential is read at runtime and is never written into the project. The
model may propose prose, goals, and a small vocabulary of pressures. All output
is validated and clamped before the deterministic consequence engine can apply
it; generated text cannot directly change population, resources, or code.

The council's free-form pronouncement field uses the same endpoint and model.
Pronouncements are translated into zero to three policies from a fixed allowlist.
The generative service may choose only a policy ID, literal grounding quote, and
confidence; any action, magnitude, or duration it sends is ignored. Deterministic
clause parsing decides enact versus repeal from the player's words. It uses catalog
terms unless the player's same grounded clause explicitly states days, weeks,
months, years, or a bounded intensity keyword. Numeric and common word-number
durations are supported, including “a fortnight”; “until further notice” and similar
open-ended wording is explicitly bounded to 730 days. If the same policy is both enacted
and repealed in one pronouncement, that disputed mapping is withheld while other
unambiguous clauses may proceed. Otherwise-valid clauses beyond the three-policy
execution cap are counted and shown as withheld rather than silently disappearing.
When candidates arrive in a different provider/catalog order, the player's earliest
unambiguous grounded clauses deterministically receive the three execution slots.
Terms, action provenance, and withheld ambiguity are displayed in the council. With no API
configured, a deterministic interpreter keeps the feature
playable. Every issued pronouncement stores its source interpretation and applied
policy IDs in `GameState.sovereign_orders` for inspection and future save support.
Orders may enact or repeal policy. Reissuing a standing policy replaces it rather
than stacking it, and the responsible office's competence scales execution within
the validated bound. Restarting a world cancels any in-flight interpretation. The
council shows current strength, executor, and remaining duration for every active
standing policy, including the exact bounded variable channels it affects. One
authoritative policy catalog supplies AI validation, office execution, UI labels,
and deterministic simulation coefficients. Transient transport, rate-limit, server,
or malformed-response failures receive one bounded retry under the original order;
the ledger records attempt count and provider request ID without storing credentials.
Direct JSON contracts, chat content blocks, and Responses-style output envelopes are
accepted before the same allowlist validation boundary. A local OpenAI-compatible
HTTP probe verifies the full request,
validation, execution, and provenance path without requiring a real API key.
Every API-proposed policy must also include a literal quote from the player's typed
pronouncement and confidence of at least 0.55. The validator checks that quote against
the original text before execution. Ungrounded or uncertain mappings are withheld,
counted in the unresolved record, and change no variables; the accepted quote and
confidence remain visible in active and historical government records.
Only a typed, bounded public context allowlist—day, population, food days, health,
known office names, and active policy IDs/durations—may enter the provider prompt.
Unknown caller fields and nested internal state are discarded before any request.
Provider summaries, notes, and request IDs are length-bounded and stripped of line
control characters before storage or display. Withheld provider prose is explicitly
labelled as interpretation with no direct simulation effect, while deterministic
validation reasons take precedence in the bounded ledger text.
Compatibility-mode JSON must still match the typed root and policy-field contract;
stringified/non-finite confidence, missing fields, or wrong container types fail the
attempt and enter the same bounded retry/fallback path.
When structured output is enabled, the request carries a strict JSON schema whose
policy enum is generated directly from the authoritative catalog. If a compatible
custom endpoint explicitly rejects `response_format` with HTTP 400, 415, or 422,
the same logical request ID receives one plain-JSON compatibility retry. The order
records whether the schema was requested, used, or downgraded.
The council displays a credential-free interpreter status: mode, model, and endpoint
host only. During submission it reports requesting, bounded retry, structured-output
downgrade, accepted, deterministic offline, safe fallback, or cancelled stages. The
status survives closing and reopening the council because progress is retained on the
pending request. API keys and full endpoint paths never enter this diagnostic record.
Remote API endpoints must use HTTPS; plaintext HTTP is accepted only for localhost or
loopback development servers. HTTP redirects are disabled so authorization headers
cannot be forwarded to a different destination, and provider response bodies are
limited to 128 KiB before JSON parsing. Redirected, oversized, or invalid transports
fail through the same bounded retry/fallback ledger and cannot directly apply policy.
Endpoint diagnostics strip user-info, paths, queries, and fragments. URLs containing
embedded user-info credentials or control characters are rejected; credentials belong
only in the API-key environment setting.
Pronouncement records reconcile against their standing effects as active,
partially active, superseded, repealed, expired, unresolved, or no-effect; old
inactive modifier history is bounded while referenced sovereign records remain.
Submission itself creates an auditable `interpreting` order before any network
response arrives. Completion resolves that same order idempotently, including if
the player closes and reopens the council while the request is pending.
Standing policy consumes administrative capacity, with weaker institutions and
vacant offices reducing execution. Replacing or rescinding policy early creates
temporary churn that reduces labor efficiency, cohesion, and legitimacy; the
council exposes both governance load and churn rather than hiding these costs.
Sovereign orders carry monotonic sequence numbers. If concurrent API responses
arrive out of order, an interpretation overtaken by a newer standing decision is
recorded as stale and cannot replace policy, change variables, or create churn.
Pending interpretations can be withdrawn from the council. Cancellation removes
the deferred or HTTP request before it can emit, records a terminal `cancelled`
order, restores the input, and guarantees that no fallback or late response applies.
Each enacted policy also snapshots the linked public simulation metrics and updates
an `OBSERVED SINCE ORDER` report while it remains active. The final observation is
retained when policy is repealed, superseded, or expires. These before/after values
are explicitly observational—not a claim that the order alone caused the change—
because staffing, resources, environment, discoveries, conflict, and other policies
continue to affect the same metrics.
Named advisors now react to enacted or successfully repealed policy by matching the
policy's fixed council-affinity profile against goals already present on that advisor.
Support, objection, and assigned responsibility make small deterministic changes to
trust, respect, and resentment. These reactions are stored on the sovereign order,
shown in council history, aggregated as council support, and feed back into later
office execution and legitimacy. Stale, rejected, duplicate, cancelled, and no-effect
interpretations produce no political reaction.

## Core consequence simulation

Population allocations now propagate through provision, health, effective
labor, construction, discovery, resource access, material capacity, logistics,
security, ecology, cohesion, legitimacy, and population growth. Council choices
and free-form orders map to bounded policies with explicit secondary effects.

Select a province containing an army, then right-click a neighboring friendly province to move. Number keys 0–4 control simulation speed.

## Combat simulation

`CombatSimulator` is a deterministic, presentation-free battle resolver. Its
first-pass model uses troop count, attack, defense, morale, readiness, and a
terrain defense modifier. A seed makes outcomes reproducible for tests, saves,
replays, and later multiplayer synchronization. It also accepts the existing
army `population` field as troop count, allowing the map layer to adopt it
without changing army data immediately.

The simulator returns a round-by-round battle record and does not mutate either
force. World-state consequences—casualties, retreat, province control, citizen
deaths, and historical records—remain an explicit integration step.

For safe manual experimentation, open `res://tools/battle_lab.tscn` in Godot
and run the current scene (F6). The Battle Lab is isolated from `GameState` and
cannot alter the campaign.
