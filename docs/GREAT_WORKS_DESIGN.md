# Great Works — shared build contract

Branch `codex/great-works`, worktree `C:/Users/sjpur/tt-great-works`, base `d55b339a`.
Coordinator owns this contract and commits. Workers edit only owned files; no git commit.

## Why (current weakness)

Wonders ("undertakings") are private per-city buildings with small % buffs, no rival competition (no AI code starts them), random per-city availability, passive construction, a log-line completion, no later-era wonders (first 300 years only), and a buried victory path. Keep what works: real labor/materials, upkeep, decay to ruin, recorded hardship.

## Target

1. **World-unique & contested.** Each Great Work exists at most once in the world. The player and AI civilizations pursue them under identical rules (AI parity: strategy/personality choose pursuits via existing validated order paths). Progress is observable (envoys/scouts/rumors, dated, uncertain). First to finish claims it; the loser's site becomes a named "unfinished rival" monument (can later be repurposed as a lesser work or quarried for part of its materials).
2. **Master builder.** Each work has a named architect (a `HistoricalFigures` exceptional contributor, role "architect") with personality, vision and ego, which may be poached. Construction proceeds in **stages** (foundations → raising → crowning → dedication). Each stage gate raises a **decision** (e.g. grander design vs. practical; forced labor vs. paid; pour food stores in vs. protect them; honor the architect's demand vs. refuse) with real engine consequences, and **events** can fire during stages (collapse, strike, ingenious solution, omen, rival sabotage/poaching, accident with named victims), bounded and deterministic from seed.
3. **Dedication.** Completion creates a pending **ceremony** record: attending foreign envoys (contacted civs, relation-weighted; may bring real gifts from real stores), speeches, naming, chronicle entry; allure/reputation spike; map landmark glow.
4. **Transformative effects** (not just %): each work grants a distinctive capability — e.g. Steps of the Watching Sky: forecast of famine/bad seasons N days ahead; Sanctuary of Safe Passage: more envoys/traders/refugees routed to you; Crown of the Ridge: rivals' threat/war propensity toward you reduced; House of the Long Song: knowledge and leader memories survive collapse/succession; Granary of the Covenant: famine shock absorbed; etc. — plus one unique decree/dialogue option each. Bounded, explained in text.
5. **Allure & artifacts.** Great Works are the largest allure source; artifacts may be **enshrined** in suitable works (bounded exhibit bonus, pilgrims). The artifact branch (`codex/artifact-culture`, `scripts/artifact_culture.gd`) is separate: expose hooks here, integration wires them.
6. **All eras, layered sites.** Catalog spans all eras (~36 works over founding → classical → medieval → industrial → modern; gated by discoveries/era, not a 300-year cap). Some works **upgrade in place** (Ancestors' Ring → Temple of the Ring → Cathedral of the Ring), keeping the site's accumulated history, events and name.
7. **War.** Works in captured cities change owner (existing occupation), can be damaged in sieges, looted (enshrined artifacts taken, reputation hit to looter among observers), and restored. Losing one creates a lasting grievance/memory for the former owner.
8. ~~**Victory**~~ — withdrawn: there is no victory in this game (user directive). Wonders are expressed only as history, legacy, reputation and chronicle.

## Hooks for the Experience worker (later, after Audience Hall integrates)

The engine exposes, in `scripts/great_works.gd` (static facade, `extends RefCounted`):
```
static func catalog()->Array[Dictionary]                     # all works incl. era, form, upgrade_from, effects text, claimed_by
static func world_status()->Array[Dictionary]                 # per work: {id,title,era,status:"unclaimed"|"in_progress"|"claimed",claimant civ ids known to player, progress estimate (player-known, dated), your site record}
static func site(city_id:String,id:String)->Dictionary        # full record: stage, architect person id, events, decisions, condition, history layers, enshrined artifact ids
static func pending_decisions()->Array[Dictionary]            # {work_id,city_id,stage,prompt,architect_id,options:[{id,label,sub,enabled,reason,tone}]}
static func decide(city_id:String,work_id:String,option_id:String)->Dictionary
static func pending_ceremonies()->Array[Dictionary]           # {work_id,city_id,day,attendees:[{civ_id,name,gift:{resource,amount}}],name_suggestions:[...]}
static func dedicate(city_id:String,work_id:String,name:String)->Dictionary
static func recent_events(limit:int=20)->Array[Dictionary]    # {day,work_id,city_id,kind,text,figure_ids}
static func rival_news_for(observer:String)->Array[Dictionary]   # observable rival progress items (dated, uncertain) for envoys/Chief Scout
static func allure_contribution(owner:String="player")->Dictionary   # {value,breakdown:[{source,value,text}]}
static func enshrine(city_id:String,work_id:String,artifact_id:String)->Dictionary   # guarded; validates artifact ownership via GameState.society_exchange
static func forecast()->Array[Dictionary]                     # e.g. Watching Sky season/famine warnings if owned
```
If `preload("res://scripts/audience_hall.gd")` exists and `has_method("enqueue")`, decisions/ceremonies/rival news may also be enqueued as audiences (guarded; harmless when absent).

## REVISION 2 — Conceived wonders (supersedes the fixed catalog, world-uniqueness and races)

User direction: "Too much like Civ. No limited wonders. A civilization should be able to come up with a wonder and try it. It should be a reflection of their civilization, with a unique name, and it could fail or succeed based on the conditions of the civilization. Keep much of our work, but no fixed list."

### Motivation — why a people builds
A wonder is conceived from **who this people is and what it is going through**: societal values (hierarchy, collective obligation, experimentation, pluralism, stewardship…), dominant needs and fears (famine, floods, war, a death, a triumph, a founding anniversary), environment (river, ridge, coast, desert), the ruler's and officials' personalities, and known discoveries/materials. Each conceived wonder has a **purpose/aspiration** (e.g. honor the dead, bind the tribes, tame the flood, watch the heavens, awe rivals, remember knowledge, give thanks for a harvest, defy the gods) — purpose drives payoff.

### Conception — no list, a grammar
`scripts/wonder_concept.gd` generates concepts deterministically from seed + civ state + day + trigger: **form** (from a bounded set: ring, mound, stair/terrace, tower, hall, basin/cistern, granary, bridge, causeway, dam, colossus/statue, garden, observatory, gate/arch, canal, library/archive, amphitheatre, lighthouse… gated by materials and discoveries), **purpose**, **ambition** (modest / grand / audacious — chosen by the ruler), **materials & labor** (derived from form × scale × known techniques), **unique name** in the civ's naming tradition ("The Weeping Stair of Varrow", "Hearth-that-Never-Sleeps", "Ossuary of the Ninety Winters") and a short lore line. Concepts arise from (a) officials/architects proposing in the Audience Hall when a trigger fires, (b) the ruler describing one in words (AI interpretation maps free text into form/purpose/ambition within the grammar; offline keyword mapping), (c) AI civilizations conceiving their own under identical rules. Unlimited in number; many civs may raise towers — each is its own.

### Risk — it can fail
Before and during construction a **feasibility** is computed and spoken of in-world (never as a bare %): engineering capability vs ambition (relevant discoveries, material quality, architect skill, skilled crafters), social support (cohesion, legitimacy, food security, war), and duration of stability. Stage-gate decisions and events shift it. Outcomes: **triumph** (exceeds vision), **success**, **flawed** (functions, reduced payoff, maybe later decay), **collapse/folly** (resources lost, legitimacy/cohesion hit, deaths possible, becomes a named ruin with lore), **abandoned** (support withdrawn). Overreach is the drama: audacious works pay far more and fail far more.

### Payoff — reflects purpose and outcome
Purpose maps to existing effect families (forecast, famine reserve, memory persistence, deterrence, traffic/attraction, research, craft, cohesion/legitimacy, water/food capacity) scaled by ambition × outcome quality, bounded. Every success adds **allure** and identity (cohesion, collective memory); failures add lore and a scar (memory in officials, grievances if forced labor). Ceremony on completion as before. Upgrading/expanding an existing work is a new conception layered on the site (history preserved).

### Keep / change / remove
- KEEP: architects (HistoricalFigures), stages + decisions + events, dedication ceremony, effects module (bounded), enshrinement, allure contribution, war capture/damage/loot/restore/grievance, rival **news** (dated, uncertain), AI parity via validated orders, save compatibility. (Victory removed by user directive: no victory conditions; wonders are history, legacy, reputation and chronicle only.)
- REMOVE: fixed 36-work catalog as the source of wonders (keep existing 12 founding definitions only as legacy mapping for old saves), world-uniqueness claims, races, "Unfinished X" rival monuments from losing races (a failed/abandoned work still becomes a ruin/folly), sabotage framed as race tactic (envy-driven sabotage may remain, rare).
- Rival news becomes "news of their works": rivals hear of your wonder (awe, envy, emulation — an AI may conceive a rival work in response).

### Facade changes (`scripts/great_works.gd`)
Replace catalog/world_status/claims/candidates with:
```
static func conceive(owner:String="player", trigger:Dictionary={})->Array[Dictionary]   # 1–3 fresh concepts
static func concept_from_words(text:String, owner:String="player")->Dictionary          # ruler-described
static func assess(concept:Dictionary, owner:String="player")->Dictionary                # feasibility: {score, factors:[{name,effect,text}], spoken:String, costs, duration_estimate}
static func commission(city_id:String, concept:Dictionary, ambition:String, owner:String="player")->Dictionary
static func works(owner:String="player")->Array[Dictionary]      # all of this owner's works incl. ruins/follies
static func known_foreign_works(observer:String="player")->Array[Dictionary]
```
Keep site/pending_decisions/decide/pending_ceremonies/dedicate/recent_events/allure_contribution/enshrine/forecast/decree_options.
