# Responsive decrees

Worker RD, `codex/responsive-decrees`, worktree `C:/Users/sjpur/tt-responsive-decrees`, base `56880c30`.

## Behavior

**Leaders stay in character.** The civic prompt is character-first: the leader's
lifelong voice model (`CharacterVoice.brief`), their love/dread read toward the god
(`DivineRegard.regard`, read-only) and the era line are sent as `YOU`. Answers
that step outside the world (records, systems, data, statistics, mechanics, the
game) are discarded and replaced by an in-voice offline line
(`CustomDirective.breaks_frame` / `voiced`). Numbers never appear in speech: a
committed order shows the leader's words, then one small `RECEIPT ·` line that the
civic conversation renders at 9 px under the bubble. Follow-up reports are spoken
the same way (in-character lines for each effect that has begun and each
unforeseen consequence that has surfaced, then a compact receipt).

**Villagers asked about by name persist.** "Who is the smartest fertile man?" gets
a named person (`VillageNotables`), deterministic from world seed + settlement +
question, remembered in a bounded registry (12 per settlement) saved inside the
existing `ForeignDiplomacy.audiences` payload (`village_notables`; unknown keys
already pass `AudienceHall.validate_state`). Re-asking returns the same person;
they age, gain children, die on a seeded day, and a successor answers after that.
"Is Ulf still alive?" is answered from the registry. The live model receives
`asked_about_notable` and `village_notables`, and an answer that does not name the
registered person is replaced by the offline one, so the name is stable either way.

**Every explicit order ripples.** Catalog policies are unchanged and still the
precise path. Any explicit order (or part of an order) the catalog does not cover
becomes a `custom_directive` policy that runs through the same assessment,
leader-willingness, execution, follow-up and report pipeline:

1. Reading: the live model returns `custom_directive` in the strict schema
   (natures, feasibility, coercion, effects on the parameters below with strength,
   uncertainty, days, delay, reason; food/material cost shares). Offline, a
   lexicon of 38 natures supplies the same shape. Model effects already moved by a
   matched catalog policy are dropped to avoid double counting.
2. Feasibility: compliance from legitimacy, cohesion, coercion and enforcement;
   administrative reach; food and material stores; leader office execution. Never
   zero and never a refusal. Impossible feats (miracles) get feasibility ≈ 0.05:
   effort and stores are spent, only the attempt's social effects occur, and a
   later loss of legitimacy is likely.
3. Application: effects become `active_modifiers` records (`id:"custom_directive"`)
   feeding ordinary `policy_effect` channels, grouped by start day; delayed
   effects and side effects only act once begun. A small immediate shift is
   applied to cohesion/legitimacy/security/health. Food and materials are paid
   from real stores (deferred to the start day for future-dated orders). Deaths
   are only deliberate (sacrifice: exactly one) or seeded work/hunt/raid accidents.
4. Unforeseen consequences: each nature has a side-effect table (parameter,
   strength, probability, delay, duration) rolled deterministically from world
   seed + order id + wording and scaled by implementation. They are not shown in
   the receipt; the leader reports them when they surface.
5. When every catalog reading is blocked (missing practice, no stone, too little
   enforcement), an `attempt` custom plan runs instead of nothing happening.
6. Future-dated orders ("in ten years") are booked: effects and costs begin on the day.

Plain statements and questions still enact nothing. `Would killing dissidents
help?`, `Why are we rationing?`, `The river is high` stay discussion.

## Alterable parameters (`DecreeStatistics.PARAMETERS`)

Strength is normalized to [-1, 1]; +1 = `max` below, before feasibility and implementation.

| parameter | engine input it drives | max |
|---|---|---|
| fertility | `conception_support` → `GameState._conception_condition_factor` (conceptions; births ~9 months later) | 0.20 |
| infant_mortality | `neonatal_survival` (negated) → newborn death rate in `process_reproduction_day` (clamp widened to -0.5) | 0.30 |
| disease | new `disease_risk` → Illness mortality component (+0.03/yr per unit) and health target (-0.4) | 0.20 |
| health | `health_target` | 0.06 |
| cohesion | `cohesion_target` | 0.07 |
| legitimacy | `legitimacy_target` | 0.07 |
| security | `security_target` | 0.07 |
| violence | new `violence` → Insecurity mortality (+0.02/yr), security target (-0.45), cohesion target (-0.3) | 0.15 |
| knowledge | `knowledge_gain` multiplier (research/discovery pace) | 0.30 |
| labor | `labor_multiplier` (all production) | 0.10 |
| food_use | `food_demand` (FoodSystem demand) | 0.12 |
| food_yield | `food_yield` (FoodSystem practice) | 0.10 |
| materials | `material_target` | 0.07 |
| logistics | `logistics_target` | 0.07 |
| construction | `construction_rate`, now read by `SettlementConstruction` (also activates the catalog stone-housing channel that was previously unread) | 0.25 |
| water | `water_collection` (ResourceSystem) | 0.30 |
| ecology | `ecology_delta` per day | 0.0004 |
| migration | new `migration_pull` → whole-person arrivals/departures via `register_population_arrivals/departures` (annual share) | 0.05 |
| resentment | record `resistance` → governance `directive_resistance_pressure` → lower cohesion and legitimacy targets | 0.45 |

Plus real costs (food, materials), counted deaths where the order is a killing
or dangerous work, and the existing six immediate metric estimates for catalog orders.

## Files

New: `scripts/custom_directive.gd`, `scripts/village_notables.gd`,
`tests/responsive_decree_probe.*`, `tests/universal_order_probe.*`,
`tests/live_responsive_decree_probe.*` (manual, spends three requests).

Changed: `decree_statistics.gd` (parameter table, validation, compact receipts),
`pronouncement_interpreter.gd` (character-first system prompt and prompt,
`custom_directive` in the strict schema and validator, plain-imperative speech
act, "kill the wolf" is not repression, no caching of custom plans),
`advisor_system.gd` (custom/attempt policies, in-character replies with receipts,
notable answers, follow-up reference only for real follow-ups),
`consequence_engine.gd` (custom routing; delayed records; `disease_risk`,
`violence`, `neonatal_survival`, `migration_pull` channels),
`civic_implementation_system.gd` (custom evaluation, spoken reports + receipt),
`game_state.gd` (one clamp), `settlement_construction.gd` (one channel),
`hud/dock_blocks.gd` + `hud/content/dock_content_civilization.gd` (receipt line).
Tests updated where they encoded "proposal recorded, nothing happens".

## Saves

No new save fields. Custom directive records live in `active_modifiers` and
sovereign orders like catalog records; notables ride in the audience payload.
Old saves load unchanged.

## Integration notes

Shared hotspots touched: `game_state.gd` (neonatal clamp only). Not touched:
`divine_regard.gd`, `hud_tokens.gd`, government people decay (read-only use of
`DivineRegard`). `local_terrain.gd` is unchanged; the prompt derives the leader
from the settlement id it already sends.

## Interaction database wiring (added at coordinator request)

- `pronouncement_interpreter.gd`: in Hybrid/Offline mode `interpret()` consults
  `InteractionMatcher.resolve(..,"civic",ctx)` first. The context carries the
  leader's voice model, their address to the god, and a real villager from
  `VillageNotables.matcher_slots` (never a placeholder name). Offline answers still
  pass the speech-act guard. Catalog policies come only from the grounded
  deterministic reading, and every scaled offline effect goes to the custom path.
  `_api_config()` returns `{}` when `AiMode.allows_api()` is false. Successful live
  civic responses are captured with `InteractionCapture.capture_civic`, including
  the custom plan's effects converted back to record deltas. `_prompt()` now trims
  the oldest conversation turns so the prompt stays within `API_MAX_PROMPT_UTF8_BYTES`.
- Custom path: `CustomDirective.plan_from_offline` consumes `offline_effects`,
  `offline_costs` (food person-days and materials become shares of real stores),
  `offline_counted` and `offline_side_effects` (narrative consequences the leader
  reports if they roll). The lexicon adds the parameters a recorded profile cannot
  name, such as fertility, violence and resentment.
- Metrics: `DecreeStatistics.OFFLINE_METRICS` covers the six metrics plus every
  parameter. `InteractionContext.writable_metrics()` reads that list (a one-line
  edit in IS's file), so the matcher keeps type profiles on any of them.
  `METRIC_EQUIVALENT` converts a recorded delta into a parameter strength and back.
- Capture-only lines, each clearly delimited: `audience_voice.gd` `_on_response`
  (speak stage), `foreign_dialogue.gd` `_response` (valid branch), and
  `general_dialogue.gd` `_completed` (player).
- The Menu → AI Connection panel now has a Live/Hybrid/Offline selector and an
  "Export interactions" button.
- Probes run in Offline mode through the real `interpret()` entry point
  (`responsive_decree_probe`, `OFFLINE MODE` section). The live probe records
  nothing to the player's store.
