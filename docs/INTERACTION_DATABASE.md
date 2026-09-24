# Interaction database and offline engine

The game records every live language-model exchange on this device. The
offline engine answers from those records, and from a catalogue of
interaction types, when the player chooses Hybrid or Offline mode. Live play
fills the database; there is no batch pre-seeding step.

## Files

| File | Role |
|---|---|
| `scripts/interaction_store.gd` (`InteractionStore`) | Append-only JSONL store. Handles recording, rotation, lazy loading, export and import. |
| `scripts/interaction_matcher.gd` (`InteractionMatcher`) | Offline engine: matching, scaling, reply templating and the civic-contract adapter. |
| `scripts/interaction_types.gd` (`InteractionTypes`) | Type catalogue loader, speech-act detection and the lexicon classifier. |
| `scripts/interaction_text.gd` (`InteractionText`) | Normalisation, stop words, a light stemmer, a synonym table, trigrams and credential redaction. |
| `scripts/interaction_context.gd` (`InteractionContext`) | Builds an identity-free context signature from live state (`from_live_state`). |
| `scripts/interaction_capture.gd` (`InteractionCapture`) | One-line capture adapters for each conversation surface. |
| `scripts/interaction_curation.gd` (`InteractionCuration`) | Report-only clustering (proposes new types) and profile-drift detection. |
| `scripts/ai_mode.gd` (`AiMode`) | The Live, Hybrid and Offline setting, stored in `user://ai_mode.cfg` or overridden by `LEVIATHAN_AI_MODE`. |
| `data/interactions/types.json` | 78 types with lexicon, cues, canonical effects, side effects, costs, policy ids and reply archetypes, plus frames for 7 voice-model families. |
| `tools/interaction_db_tool.tscn` | Headless tool for `--stats`, `--export`, `--import` and `--propose`. It never contacts the API. |
| `tests/interaction_store_probe.tscn` | Headless probe. |

## Stores

- **Player store:** `user://interactions/interactions_NNNNNN.jsonl`.
  - Each record is appended and flushed straight away. A torn last line is skipped on load.
  - Files rotate at 1 MB, and the store keeps 24 files (about 24 MB). The oldest file is deleted first.
  - The player store stays on this device. It is never uploaded or committed.
- **Shipped packs:** `res://data/interactions/**/*.jsonl`, read-only at runtime. These are curated from exported bundles.
  - The export preset's `include_filter` currently packs `*.json`, `*.csv` and `*.txt`.
  - **Add `*.jsonl` before shipping a pack.** `types.json` is already included.
- **Loading:** lazy. The first `resolve()` or `records()` call reads both stores. The index is built once and then extended as records are appended.

## Record schema (v1)

```json
{"v":1,"id":"i1790...-0001","day":412,"ts":1790275564,"surface":"civic|audience|summon|envoy|general",
 "speaker":{"role":"Steward","model":"grant","family":"plain"},
 "player_text_raw":"Have the smartest men father children...","player_text":"have the smartest men father children ...",
 "intent":{"speech_act":"order","type_id":"breeding_selection","type_confidence":0.83,"topic":"Selective breeding","policy_ids":["coercive_pronatalism"],"directive_type":""},
 "context":{"era_tier":1,"pop_band":"hamlet","metric_bands":{"cohesion":"mid"},"food_band":"lean"},
 "output":{"reply":"...","summary":"...","effects":[{"metric":"cohesion","delta":-0.03,"uncertainty":0.02,"duration_days":180,"reason":"..."}],
           "side_effects":[{"id":"kin_feud","odds":0.3,"description":"..."}],"policy_ids":["coercive_pronatalism"],"counted":{"kind":"population_deaths","count":1}},
 "source":"live|seed|curated|imported|offline","model":"gpt-5.6-terra","usage":{"prompt_tokens":0,"completion_tokens":0,"total_tokens":0},
 "accepted":true,"latency_ms":2300}
```

`sanitize()` enforces these rules on every record:

- Only the fields above are kept.
- Text length is capped.
- Anything that looks like a key or bearer token is redacted.
- Deltas and uncertainty are clamped to ±0.08.
- The context is reduced to bands (era tier, population band, metric bands and food band). No names, ids or secrets are stored.

Player text and replies can still contain in-world names. Exported bundles should be reviewed before they are shipped.

## AI mode

| Mode | `allows_api()` | `consult_offline_first()` | `should_use_offline(res)` |
|---|---|---|---|
| live (default) | true | false | false |
| hybrid | true | true | true only when `res.source=="match"` and `res.confidence >= hybrid_threshold()` (default 0.72) |
| offline | false | true | true |

Other `AiMode` calls:

- `AiMode.set_mode(m)` and `AiMode.set_hybrid_threshold(x)`.
- `AiMode.records_interactions()` and `set_records_interactions(b)`.
- `AiMode.status()` and `AiMode.LABELS`, for the settings UI.

A type-level answer is capped at confidence 0.68. Hybrid mode therefore only skips the API when a stored interaction genuinely matches.

## API

```gdscript
# Record (capture adapters call this; force=true bypasses the recording toggle)
InteractionStore.record(record:Dictionary, force:=false) -> String   # id or ""
# Offline resolution (never touches the network)
InteractionMatcher.resolve(text:String, surface:String, context:Dictionary) -> Dictionary
InteractionMatcher.to_civic_interpretation(result:Dictionary, text:String) -> Dictionary
InteractionTypes.classify(text) -> {type_id, confidence, speech_act, category, topic, policy_ids, scores}
InteractionContext.from_live_state(extra:={}) -> Dictionary          # live context helper
InteractionContext.signature(context) -> Dictionary                    # what is stored
# Portability
InteractionStore.export_bundle(path:="", with_shipped:=false) -> {ok, path, count}
InteractionStore.import_bundle(path, target:="user"|"<out.jsonl>", relabel_source:="") -> {ok, added, skipped}
InteractionStore.stats() -> Dictionary
InteractionCuration.propose() -> report ; InteractionCuration.to_markdown(report) -> String
```

### `resolve()` context keys

All keys are optional. An empty dictionary means live state.

- `population`, `working_age`, `era_tier` (0 to 3), `era_tags` (`CharacterVoice.era_tags("player")`).
- `metrics` (`{metric: 0..1}`) and `food_days`.
- `feasibility` (0 to 1): implementation capacity.
- `compliance` (0 to 1): the people's willingness.
- `speaker_model` (voice model id) or `voice_family`.
- `address`, `notable`, `trade`, `trait`, `neighbours` and `count`: reply slot values.

### `resolve()` result

```
{confidence, source:"match"|"type"|"default", type_id,
 intent:{speech_act, type_id, topic, category, policy_ids, type_confidence, classified_type},
 discussion:bool,            # questions/greetings: reply only, no effects
 effects:[{metric, delta, uncertainty, duration_days, reason}],   # bounded to DecreeStatistics limits
 side_effects:[{id, odds, description}], costs:{workers, labor_days, food_person_days, materials},
 counted:{kind:"population_deaths"|"population_departures", count}, duration_days,
 reply_text, reply_template, reply_slots, voice_family, matched_ids, surface, context_signature, timing_usec}
```

### Matching

1. **Retrieval.** Canonical tokens and bigrams go through an inverted index with TF-IDF cosine. Rare terms are scored first, and a posting budget keeps the query fast. Unknown words map to their nearest indexed word by trigram overlap.
2. **Re-ranking.** The top 32 candidates are re-scored:

   score = 0.5 × cosine + 0.25 × character-trigram Jaccard + 0.12 × type agreement + 0.05 × speech-act agreement + 0.08 × context-band proximity

   The score is multiplied by 0.93 when the surface differs, and by 0.8 when the record was not accepted.
3. **Thresholds.** A match needs a score of at least 0.60. Below that, the engine uses the type profile if classifier confidence is at least 0.22. Otherwise it uses the `custom_directive` default, so it always answers.

### Scaling

Canonical profiles are written for about 150 people at era tier 1.

- **Population factor:** from 0.55 to 1.35, per the type's `pop_sens`. Small groups feel an order more.
- **Era factor:** from the type's `era_scale`.
- **Positive deltas:** multiplied by feasibility and a compliance factor.
- **Social costs:** cohesion and legitimacy costs grow as compliance falls.
- **Headroom:** gains shrink as a metric nears 1, and losses shrink as it nears 0.
- **Uncertainty:** widens when feasibility is low or the match is weak.
- **Durations:** big works scale with population (`dur_pop_sens`).
- **Costs:** labour share × working-age population, food in person-days, and materials scaled by population^0.7.
- **Blended effects:** effects from matched records are first un-scaled from the record's population band.
- **Unknown metrics:** metrics not in `DecreeStatistics.METRICS` are dropped.

### Replies

- **Order of preference:**
  1. Stored replies from the same voice family, turned into templates. Numbers become `{count}`, honorifics become `{address}`, and proper names become `{notable}` and `{other}`.
  2. The type's `core` lines (or `ask` lines for questions), framed with the family's open, comply, caution or answer lines.
- **Era safety:** every candidate is filled with era slots (`{staple}`, `{store}`, `{structure}`, `{record}`, `{tool}`, `{fields}`, `{shrine}`) and checked with `CharacterVoice.permits` against `era_tags`. Gated words are swapped out or the candidate is dropped.
- **No repeats:** no line is spoken twice in a session. A stored reply is reused at most once per session, and a different voice family never gets another speaker's line.
- **Placeholder names:** `reply_slots.notable_is_placeholder` is true when no real notable was supplied. Pass `notable`, `trade` and `trait` from GovernmentPeopleSystem to name a real person.

## Wiring (for RD and the coordinator)

None of the files below were edited by this task.

### 1. Civic: `scripts/pronouncement_interpreter.gd`

**`interpret()`**, after `fallback` is computed and before the local fast path:

```gdscript
if AiMode.consult_offline_first():
    var offline:=InteractionMatcher.resolve(clean,"civic",InteractionContext.from_live_state({"speaker_model":<leader voice model id>}))
    if AiMode.should_use_offline(offline):
        var r:=InteractionMatcher.to_civic_interpretation(offline,clean)
        _emit_result.call_deferred(request_id,r); return request_id
```

**`_api_config()`**: return `{}` when `not AiMode.allows_api()`. Offline mode then never builds an HTTP request.

**`_on_response()`**, success branch where the validated result is emitted:

```gdscript
InteractionCapture.capture_civic(request.text,result,{"model":String(config.model),"usage":envelope.usage,"speaker":{"role":<office>,"model":<voice model id>},"latency_ms":...})
```

Capture needs the raw envelope usage, so it belongs here rather than in `_emit_result`. Deterministic and cached results are skipped automatically.

**Custom-directive path**: when `to_civic_interpretation` returns no policy, consume `offline_effects`, `offline_counted`, `offline_costs` and `offline_side_effects`.

### 2. Audiences and summons: `scripts/audience_voice.gd`

**`_on_response()`**, after `validate_lines()` succeeds and before `_deliver`:

```gdscript
InteractionCapture.capture_chat_body("summon" if <summoned> else "audience",String(request.extra.get("player_text","")),body,parsed,{"speaker":{"role":<member role>,"model":<member persona model>}})
```

Only record the `speak` stage, which carries a `player_text`.

**`_begin()` and `_send()`**: in Offline mode, or in Hybrid mode with a confident match, answer with `InteractionMatcher.resolve(player_text,"audience",ctx).reply_text` as the speaking member's line. Set `ctx.speaker_model` to that member's persona model.

### 3. Envoys: `scripts/foreign_dialogue.gd`

**`_response()`**, in the `response_valid` branch:

```gdscript
InteractionCapture.capture_chat_body("envoy",<last user message>,body,value)
```

**`_request()`** calls `PronouncementInterpreter._api_config()`. If that returns `{}` in Offline mode, envoys currently fail with a connection message. Add an offline branch that uses `resolve(...,"envoy",ctx)` instead.

### 4. Generals: `scripts/general_dialogue.gd`

**`_completed()`**, for the `id=="player"` branch:

```gdscript
InteractionCapture.capture_chat_envelope("general",<player message from ask()>,envelope,value,{"accepted":row.accepted})
```

Keep the player's message from `ask()` so it is available here.

### 5. Build sketches: `scripts/hud/audience_modal.gd`

**`_request_mapping()`**: optionally call `capture_chat_body("summon", text, body, mapping)`.

### 6. Settings UI

Add a Live/Hybrid/Offline selector (`AiMode.LABELS`, `AiMode.set_mode`) next to Menu → AI Connection. Add "Export interactions" (`InteractionStore.export_bundle()`), which returns the path.

### 7. Export preset

Add `*.jsonl` to `include_filter` in `export_presets.cfg` before any curated pack is shipped.

### Class names

The global class cache was refreshed with `--import` in this worktree. Scripts that load before the cache is refreshed can use `preload("res://scripts/interaction_matcher.gd")` under a different constant name.

## Curation workflow

1. On the player's machine, run the tool with `-- --export <file.jsonl>`, or call `InteractionStore.export_bundle()`. The bundle is a header line followed by one record per line.
2. On a development checkout, run `-- --import <bundle> --into res://data/interactions/curated/<name>.jsonl --relabel curated`. This re-sanitises, de-duplicates and relabels the records. Review them before committing.
3. Run `-- --propose --out <report.md>`. It clusters poorly explained records into proposed new types and lists profile drift, where the recorded mean effect differs from the canonical profile by at least 0.008 over 5 or more samples.
4. Edit `types.json` by hand. The tool never writes to `types.json`.
