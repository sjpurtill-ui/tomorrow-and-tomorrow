# Tomorrow and Tomorrow

## Population scale contract

Population is stored and simulated only as authoritative numeric cohort counts. The game never creates one runtime object, name, household membership, pregnancy record, soldier ID, building, or UI row per human. The same six age cohorts and four reproductive stages represent 120 people, one billion people, or any scale between them.

Military formations, food demand, fertility, mortality, labor, economy, resources, and settlement occupancy all use counts as their source of truth. Government uses a small capped pool of named public figures; ordinary citizens are never instantiated. Settlement morphology is capped at 2,048 simulated plots, 1,024 routes, and 128 nuclei, with larger populations expressed through density, capacity, districts, and land-use cells. Runtime histories and ledgers have explicit retention limits. Any new population-dependent feature must preserve these rules: work per tick may depend on the fixed number of cohorts, systems, formations, districts, public officials, or visible aggregate cells—never on total population.

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
- A starting population convoy with province-to-province movement
- Eight persistent rival civilizations with aggregate demography, adaptive strategy, trade, diplomacy, interstate war, and player-facing competition

## Competitive world

The `WORLD STRATEGY` panel is constrained by player knowledge. A new game names no foreign power, exposes no global rank, and reveals no foreign population, score, territory, force, intention, or relationship. The map itself is dark beyond ground observed by the founding convoy or described in a returned scout report. The player can dispatch one bounded aggregate scout party for 30, 90, 180, or 365 days. Its personnel are absent from ordinary work and its physical provisions leave storage at departure. Nothing is revealed while the party is away. On return, its bounded route becomes mapped and any polity actually encountered becomes a diplomatic contact. Early population, military, score, threat, and intention values are ranges or unknowns; sustained contact, trade, and conflict improve intelligence.

Known rivals take monthly strategic turns and trade, align, fortify, contain, and fight one another whether or not the player opens the panel. Once direct contact exists, the player can open trade, offer non-aggression, send conserved food aid, contain a rival, define a war objective, declare war, launch an aggregate field campaign, or negotiate peace. Illegal, contradictory, or impossible-with-current-intelligence actions are disabled with an explanation. These choices feed the existing economy, security, cohesion, knowledge, territory, and aggregate military systems.

Rival campaigns are raised from the originating civilization's simulated military population and technological capacity. Attacker, defender, terrain advantage, casualties, prisoners, and territorial transfers follow the real direction of each campaign. Battle losses are returned to the correct numeric cohorts and military totals. The world uses eight fixed polity records, six aging cohorts per polity, bounded pairwise relations, and capped histories, so running rival civilizations at one billion people each does not create additional runtime entities. See [the aggregate competition specification](docs/CIVILIZATION_COMPETITION_SPEC.md).

Every contender uses the same seven equal scoring pillars: controlled population, knowledge, production, logistics, military power, resilience, and territory. Resilience itself combines health, cohesion, institutions, and food reserve. No civilization—including an AI rival—can win by score alone. After Year 20 it must maintain at least 45 food-days, 50% health, 45% cohesion, and 35% institutions; rank first overall by at least 10%; lead four of seven domains; and hold all of those conditions for twelve consecutive monthly turns. The player loses if a rival satisfies that identical rule first. Unknown contenders are still evaluated internally but cannot leak through the player-facing leaderboard.

To take control of a rival's cities, build and train a field formation in `MILITARY`, open `WORLD STRATEGY`, select the rival, choose a visible front and a war objective, declare war, and launch the campaign. Objectives are bounded and explicit: take one selected region, break the rival's power by taking its capital or three regions, liberate a foreign holding, or defend against an aggressor. Before committing, the panel reports the defender estimate, intelligence confidence, supply state, casualty risk, readiness, and why the region matters. A decisive offensive victory captures that exact region and detaches real surviving trained personnel into an occupation force. The next region then becomes exposed. `REINFORCE OCCUPATION` moves more of the existing field formation into the city; `EVACUATE OCCUPATION` returns survivors and equipment but leaves the city vulnerable. War score, objective progress, exhaustion on both sides, occupation leverage, resistance, damage, integration, required garrison, relief food, production, market access, cohesion, legitimacy, territory, controlled population, rival strategy, recapture campaigns, peace terms, rank, and victory score all respond to control. Peace creates a one-year truce and preserves the negotiated control line. Taking all five regions breaks a rival's strategic urban control but does not invent individual inhabitants or erase its remaining rural population. A region held by a third rival appears under that occupier as a liberation target, preventing AI wars from creating an unreachable front.

## Research program

The `INQUIRY` panel contains active research projects, not passive observations. Every project states the question being tested, the current method, the permanent bounded effect it will unlock, its present bottleneck, and a projected completion horizon. The player assigns or removes aggregate observer capacity directly on each card. Progress is determined by that allocation together with civic activity, material evidence, and leadership; reallocating observers therefore changes what completes first. Completed work unlocks fixed systemic effects and later research methods without ever creating one scientist, diary, or observation record per person.

## Government pronouncement interpretation

To use an OpenAI-compatible generative endpoint, provide these environment
variables before launching Godot:

- `LEVIATHAN_AI_ENDPOINT` — full chat-completions endpoint; the official OpenAI endpoint is used when only an API key is supplied
- `LEVIATHAN_AI_MODEL` — provider model identifier; defaults to `gpt-5.6-terra`
- `LEVIATHAN_AI_API_KEY` — API credential (or use `OPENAI_API_KEY`)
- `LEVIATHAN_AI_STRUCTURED_OUTPUT` — `on`, `off`, or `auto` (default); `auto`
  enables strict JSON schema for the official OpenAI endpoint

The credential is read at runtime and is never written into the project. The
model may interpret a typed pronouncement only through the fixed policy catalog.
All output is validated and clamped before the deterministic consequence engine
can apply it; generated text cannot directly change population, resources, or code.

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
pronouncement and a hidden self-assessed confidence. The validator checks that quote
against the original text before execution. Low confidence triggers one focused
in-character question and changes no variables. The score and internal policy weights
are never shown to the player.
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
Council institutions react to enacted or successfully repealed policy by matching the
policy's fixed council-affinity profile against that office's public priorities.
Support, objection, and assigned responsibility make small deterministic changes to
trust, respect, and resentment. These reactions are stored on the sovereign order,
shown in council history, aggregated as council support, and feed back into later
office execution and legitimacy. Stale, rejected, duplicate, cancelled, and no-effect
interpretations produce no political reaction. Routine leader exchanges end with an
explicit UNDERWAY, REFUSED, BLOCKED, or NEEDS YOUR DECISION state. Grave lethal,
sexually coercive, or forced-population directives require an ethical-deliberation
exchange and exact confirmation before any effect can begin; the leader may still
refuse. Accepted orders receive one later qualitative success, partial-success, or
failure report derived from simulation state rather than generated numeric changes.

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
force. World-state consequences—casualty counts, retreat, province control,
population-cohort mortality, and historical records—remain an explicit integration step.

For safe manual experimentation, open `res://tools/battle_lab.tscn` in Godot
and run the current scene (F6). The Battle Lab is isolated from `GameState` and
cannot alter the campaign.

### City stores, civic answers, and military attention

Use the city dropdown above the map toolbar to select an owned settlement and move the camera to it. Food, freshwater, materials, deposits, storage, and communal construction belong to that city. Old secondary settlements start with empty inventories rather than inheriting the first city’s stockpile; new founding convoys bring only their remaining travel provisions, because their construction supplies are spent establishing the settlement. Local leaders use local shortages and allocations. Population cohorts remain aggregate across the civilization.

At 30% logistics and 20% institutional capacity, leaders can arrange bounded shipments along known, usable land routes. Donors retain reserves; cargo is withdrawn at departure, occupies transport capacity, and arrives after travel time. Food can spoil in transit. Transport knowledge increases reach, speed, and load capacity. The selected city’s Economy page lists its shipments and recent deliveries.

Civic interpretation preserves a conversational answer independently of executable policy mappings. Unsupported proposals receive a substantive answer without being treated as a leader refusal. Future anniversary requests are recorded as proposals: no festival calendar or scheduled spending is implied. Incoming military threats and completed battles pause time with an explicit War Planning action. Civics displays full military reports separately from routine reports.

### Concrete technology branches

Inquiry now offers 150 distinct, one-time technologies across twelve domains. The Tech Tree tab shows prerequisites, material constraints, effects (including costs), successor technologies, and an explicit research-target action. Switching projects preserves accumulated progress. Eighteen authored additions strengthen culture, labor, demography, and logistics. Recent discoveries appear ahead of the attention controls.

The 4,608 generated lens/maturity permutations are retired from live research. Their definitions and earned effects remain available to old saves, and the library labels them as archived refinements. Player and rival research priorities vary with seeded affinity, geography, activity, and emphasis. Per-technology difficulty varies reproducibly between 85% and 115%; reloads do not reroll it. Randomness never bypasses prerequisite knowledge, earliest discovery dates, or material-access checks. Rival histories now record actual technology IDs; their resource-access estimates also require suitable regional potential and production/logistics capacity. Civilization-scale evidence requirements use the finite authored catalog rather than demanding hundreds of retired permutations.

Military recruitment and exercises are separate: RECRUIT & DEPLOY fills a numeric army design from a shared reserve, while TRAINING improves existing formations. Deployment previews its exact personnel transfer and keeps total service personnel visible. Eight exercises develop command, tactics, logistics, and resolve; home reserves and assembled armies stationed at home attend, while moving or distant armies do not. Shared command practice benefits every unit type and persists through save/load. Prototype orders report their actual capped intake, and prototype identity survives deployment.

Map navigation: mouse wheel smoothly accumulates zoom (Shift + wheel is faster); Q/E or Shift + middle-drag rotates, with vertical drag adjusting tilt. N or the NORTH compass resets north-up. F7 / 10,000 FT enters the terrain-relative aerial view. Regional terrain generation is spread across short frame slices and keeps the current patch visible until replacement is ready.
