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
8. **Victory** — rework "Enduring Civilization" to count Great Works claimed/held, and surface it proudly.

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
