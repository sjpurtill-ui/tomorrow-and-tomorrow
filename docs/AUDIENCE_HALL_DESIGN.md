# Audience Hall — shared build contract

Branch `codex/audience-hall`, worktree `C:/Users/sjpur/tt-audience-hall`, base `d55b339a`.
Coordinator owns this contract and all commits. Workers edit only their owned files and do not run git commit.

## Player experience

The world comes to the ruler. Foreign envoys arrive frequently bearing **gifts, requests, threats (tribute demands) and news**. Officials also **request audiences** (petitions: alarms, grievances, ambitions). An arrival pauses the game and opens a theatrical modal, the **Audience Hall**:

- The envoy (or petitioner) speaks first, in a vivid, distinctive voice with dialect.
- The **whole court chimes in**: every present official (central officeholders + settlement leaders, max 4) may interject, agree, bicker, whisper asides, flatter or warn, each in their own voice. It must feel like a scene, not a form.
- The ruler can **speak freely** (typed text) to the envoy any number of times; the envoy answers in character and officials react.
- The ruler ends the audience with a **choice card** (engine-validated option). The envoy delivers a parting line reacting to the actual outcome; an official gets the last aside.
- "Make them wait" defers to the antechamber. Envoys left waiting past expiry leave insulted (real relation cost).

Tone: forthright, funny, surprising, occasionally sharp. Never tutorial-speak, never "game/system/mechanic/button". Characters have wants, fears, quirks and secrets that leak through speech.

## Truth rules (non-negotiable)

- Only `audience_hall.gd` changes world state. Voice text never transfers goods, starts wars or changes relations beyond the bounded `mood` hook below.
- Gifts come out of the foreign civ's actual stores (`civilization_exchange.gd` `take`), received via `receive("player",…)`. Requests/tribute debit the player's real stores. If a store can't cover it, the audience isn't generated or the option is disabled with a reason.
- Threat defiance goes through `ForeignDiplomacy.apply_conversation_reaction(civ_id, reaction, player_words, leader_words)`; the engine decides actual posture.
- AI receives exact terms and plain facts; prompts forbid inventing amounts, agreements, battles or facts.

## Data (stored in `ForeignDiplomacy.audiences`, saved in its `export_state()` under key `"audiences"`; optional on import)

```
state = {"version":1,"queue":[Audience],"history":[Audience ≤30],"next_foreign":{civ_id:int_day},
         "next_court":{"<person_id>":int_day},"last_arrival_day":int,"serial":int,"summon_immediately":bool}
Audience = {
 "id":"aud_<serial>", "origin":"foreign"|"court", "kind":"gift"|"request"|"threat"|"news"|"petition",
 "civ_id":String, "civ_name":String,
 "speaker":{"name":String,"title":String,"person_id":int (court only, else 0),"role":"envoy"|"official"},
 "arrived_day":int, "expires_day":int, "status":"waiting"|"resolved"|"expired",
 "terms":{"resource":String,"amount":float},            # gift / request / threat tribute; {} otherwise
 "news":{"subject_civ_id":String,"subject_civ_name":String,"fact_kind":String,"fact":String},   # news only
 "petition":{"topic":"food"|"health"|"housing"|"security"|"grievance"|"ambition","summary":String,"suggested_decree":String},
 "lines":[Line ≤60], "outcome":String, "option_id":String, "mood":float (-1..1, running temperature of the room)
}
Line = {"speaker":String,"role":"envoy"|"official"|"ruler"|"narrator","person_id":int,"civ_id":String,"text":String,"day":int,"aside":bool}
```

## APIs

### `scripts/audience_hall.gd` — ENGINE (Worker A). `extends RefCounted`, static functions over `ForeignDiplomacy.audiences`.
```
static func state()->Dictionary                       # ensures defaults
static func daily(day:int)->Array[Dictionary]          # generate arrivals + expire overdue; returns new arrivals
static func waiting()->Array[Dictionary]               # queue, oldest first
static func find(id:String)->Dictionary
static func court(id:String)->Array[Dictionary]        # person snapshots with "office_title", max 4, speaker excluded
static func options(id:String)->Array[Dictionary]      # {id,label,sub,enabled,reason,tone:"warm"|"neutral"|"hostile"}
static func resolve(id:String,option_id:String)->Dictionary   # {ok,outcome (plain factual receipt),reaction:"delighted"|"pleased"|"neutral"|"offended"|"furious"}
static func defer(id:String)->void                     # stays waiting
static func append_line(id:String,line:Dictionary)->void
static func apply_mood(id:String,shift:float)->void    # clamp shift ±0.25; room mood only; at resolve, mood adds ≤ ±0.03 opinion
static func voice_context(id:String)->Dictionary       # facts voice may use: terms, civ relation summary, leader name/temperament/goals, known war status, food situation words, court list
static func debug_force(kind:String,civ_id:String="")->Dictionary   # test/capture helper: create one audience now
```
Pacing: contacted civs (`ForeignDiplomacy.civilization(id)` non-empty) first envoy 6–15 days after first seen, then every 18–40 days per civ (hostile/assertive sooner). Officials petition every 30–60 days each. Global gap ≥3 days between arrivals, queue ≤4. Expiry 20 days; expired foreign audience = opinion −0.04, trust −0.03 + leader memory; expired petition = resentment +0.04.

Option rules (tune numbers, keep spirit):
- gift: accept (+opinion/trust), accept + courtesy gift back (costs player, bigger boost), refuse (offence; proud temperaments more).
- request: grant full, grant half, refuse (hungry + assertive raises border tension).
- threat: pay tribute (tension down; proud officials lose respect), defy (`apply_conversation_reaction` warn/call_bluff by personality), counter-threat (`harden_border`).
- news: thank (+tiny opinion, +contact_intelligence on subject civ if contacted), reward messenger (small real gift).
- petition: issue their decree (UI routes `suggested_decree` to the civic pipeline; hall records relationship gain), promise action, dismiss/rebuke (resentment). Grievance petitions: apologise vs rebuke.
Record memories: foreign via `ForeignDiplomacy.remember`, officials via `GovernmentPeopleSystem.record_person_memory` + `adjust_person_relationship`.

### `scripts/character_voice.gd` + `scripts/audience_voice.gd` — VOICE (Worker B)
`character_voice.gd` (`extends RefCounted`, static, deterministic from world seed — no save needed):
```
static func for_civilization(civ_id:String)->Dictionary   # shared cultural dialect for a people
static func for_foreign_leader(civ_id:String)->Dictionary
static func for_envoy(civ_id:String,audience_id:String)->Dictionary
static func for_person(person:Dictionary)->Dictionary     # officials: from traits, disposition, personality, background
Persona = {"key","name","voice","dialect","tics":[String],"want","fear","quirk","secret","temper","sample":String}
```
`audience_voice.gd` (`extends Node`):
```
signal lines_ready(audience_id:String)      # new lines were appended via AudienceHall.append_line
signal failed(audience_id:String,reason:String)
func open_scene(audience_id:String)->void    # envoy opening + 2–4 court interjections (can bicker/aside)
func player_speaks(audience_id:String,text:String)->void   # envoy reply + 0–2 official reactions; may call apply_mood
func closing(audience_id:String,result:Dictionary)->void   # parting line reacting to actual outcome + one aside
func busy(audience_id:String)->bool
```
Uses `PronouncementInterpreter._api_config()`/`connection_problem()`/`_content_text()`; Chat Completions with strict JSON schema when `structured_output`. Offline (no key) must still be vivid via persona-driven template banks. AI failure falls back to offline lines, never a blank scene.

### `scripts/hud/audience_modal.gd`, `scripts/audience_director.gd` — UI (Worker C)
Director (`extends Node`, added under the terrain HUD layer by a small hook in `local_terrain.gd`): watches `GameState.elapsed_days`; calls `AudienceHall.daily`; opens the modal when arrivals exist and it is appropriate (founding focus chosen, no other pausing modal via `simulation_pause.gd` `blocks`, not `GeneralCampaign.active`, no `ForeignDiplomacy.panel`). Draws an antechamber badge ("2 await an audience") to reopen. Modal pauses with `simulation_pause.gd`, reveals lines theatrically, shows court bench portraits, free-speech input, option cards, "Make them wait", and a toggle for summon-immediately.

## Addendum 1 — Chief Scout (Worker D)

A new central office, **Chief Scout** (key `"ChiefScout"`), available from the founding council onward, with evolving titles per government form (e.g. "Pathfinder", "Chief of Scouts", "Master of Outriders", "Intelligence Director"). The officeholder is a normal GovernmentPeople person (appointable, persona via `character_voice.gd`).

When a scouting party, envoy observation or expedition returns with findings, the Chief Scout requests an audience: kind `"report"`, origin `"court"`, speaker = the Chief Scout (or the returning party's leader if the office is vacant). The debrief is **plain-spoken, concrete, sensory and opinionated** — what they saw, heard, smelled, who they met, what surprised them, what worries them, what they covet — translated from real observation data only (population estimates, crafts/workshops, buildings, farms, defenses, resources, terrain, rumors, dated). Uncertainty is spoken naturally ("I'd not swear to it, but…"). The court then chimes in (Marshal eyes the walls, Quartermaster eyes the granaries…).

- `scripts/chief_scout.gd` (Worker D, `extends RefCounted`, static): `findings(event:Dictionary)->Dictionary` normalizes returned scout/envoy data into facts; `debrief_lines(audience:Dictionary)->Array[Dictionary]` offline vivid lines; `voice_brief(audience)->Dictionary` extra prompt context for AI.
- `AudienceHall.enqueue(record:Dictionary)->Dictionary` (Worker A adds): accept a prebuilt audience (validated, id assigned, status waiting) — used for `"report"`. `"report"` options: "Well done — reward the scouts" (small real Food/relationship), "Send them back for a closer look" (only if an existing scout dispatch path supports it; else omit), "Dismiss". `"report"` is the `"report"` kind in contract enums; `report:{facts:[...],subject_civ_id,subject_name,source:"scouts"|"envoys"|"expedition",observed_day}`.
- Worker B: `open_scene` for kind `"report"` uses `chief_scout.gd` `voice_brief`/`debrief_lines` for the scout's debrief, then court interjections as usual.
- Worker C: herald text "YOUR CHIEF SCOUT RETURNS WITH A REPORT", findings chips (e.g. "≈340 people", "stone walls", "seen 4 days ago").
