# Artifact culture & allure — shared build contract

Branch `codex/artifact-culture`, worktree `C:/Users/sjpur/tt-artifact-culture`, base `d55b339a`.
Coordinator owns this contract and all commits. Workers edit only their owned files and never run git commit.

## Goal (user's words)

"Artifacts should be folded into culture and contribute to a nation's allure. Build a beautiful artifact UI in the culture section. After artifacts are researched, they have value (culture, research, economic). Researching artifacts should be a role on the research team, part of the research allocation."

## Existing system (build on it, do not duplicate)

`GameState.society_exchange` owns artifact records (`scripts/artifact_collection.gd`, `scripts/society_exchange.gd`, `scripts/early_civ_artifacts.gd`, `scripts/prehistoric_artifacts.gd`, `scripts/reverse_engineering.gd`). Prestige, appraisal, study factor, museum exhibition, research support and gifting/sale already exist (see `docs/ARTIFACT_COLLECTION_HANDOFF.md`). Art: `scripts/hud/artifact_visuals.gd`, `assets/ui/artifacts/*/artifact-*.png`. Current panel: `scripts/hud/exchange_collection_panel.gd` ("Brought Home").

## Mechanics (Worker M)

1. **Artifact study is a research-team role.** It is allocated like other research emphasis (the same budget, same allocation UI in the Inquiry dock), and it staffs actual research workers. Unstudied artifacts progress toward "studied" only through that staffing (rate scales with assigned workers × Knowledge skill; rarer pieces take longer). Priority piece can be chosen. No free study.
2. **Studied artifacts yield value in three channels**, depending on object/material/motif/research family:
   - culture: raises cultural capacity/cohesion contribution (bounded, existing 0–1 metrics),
   - research: bonus to their linked research subject/family (extend existing support),
   - economic: museum admissions (existing) and/or appraisal-backed trade value.
   Unstudied pieces give only small raw prestige.
3. **Allure** (0–1, new, derived — no saved authority duplication): the nation's cultural attractiveness from studied/exhibited artifact prestige, cultural capacity, societal values openness/pluralism, completed undertakings/wonders (`scripts/undertaking_rewards.gd`). Wire it with small, bounded effects into existing systems: foreign diplomatic reception (`ForeignDiplomacy.forecast` score, like the wonder reputation bonus), migration/integration attraction if such a hook exists (`scripts/society_exchange.gd`), museum visitors. Explain each effect in text.
4. Save compatibility: new fields optional; old saves load.

## Facade API — `scripts/artifact_culture.gd` (Worker M implements, Worker U consumes)

`extends RefCounted`, static, use via `preload`. All numbers are real engine values.
```
static func summary()->Dictionary
  {allure:float, allure_label:String, allure_breakdown:[{source:String,value:float,text:String}],
   allure_effects:[{target:String,text:String,value:float}],
   collection_count:int, studied_count:int, in_study_count:int, unstudied_count:int, exhibited_count:int,
   prestige_total:float, value_totals:{culture:float,research:float,economic:float},
   study_role:{allocation_key:String, weight:float, workers:int, rate_text:String, focus_id:String}}
static func artifacts(query:Dictionary={})->Dictionary
  query: {status:"all"|"studied"|"in_study"|"unstudied"|"exhibited", sort:"rarity"|"prestige"|"recent"|"value", search:String, page:int, page_size:int}
  -> {items:[Artifact], total:int, page:int, pages:int}
static func artifact(id:String)->Dictionary     # Artifact
static func set_study_focus(id:String)->Dictionary    # {ok} or {error}
static func set_exhibited(id:String,on:bool)->Dictionary
Artifact = {id,name,object,style,motif,material,rarity:String,rarity_index:int(0-4),origin:String,found_day:int,
            held_days:int,prestige:float,appraisal:float,study_progress:float(0-1),state:"unstudied"|"in_study"|"studied",
            value:{culture:float,research:float,economic:float}, research_subject:String, exhibited:bool, can_exhibit:bool,
            story:String (1–3 evocative sentences, deterministic, from object/style/motif/origin),
            texture:Texture2D or null (via artifact_visuals.gd)}
```

## Addendum 1 — Treasure-hunt distribution (Worker M)

Replace the uniform one-artifact-per-24-unit-cell distribution with a **clustered, place-driven** one, still deterministic from world seed and still exclusive (claimed at pickup across all owners):

- **Density from place:** most cells are empty; finds concentrate near rivers/lakeshores, fertile valleys, coasts, caves/rock shelters, passes and old campsites (use the existing ground survey authority / environment profile / biome data). Barren interiors are sparse.
- **Ancient sites:** a seeded set of named **ruins/hoards/burial grounds/shrines** per world (scaled to map size, e.g. 1 per ~N km²), each holding a small cluster of pieces with elevated rarity and a shared culture of origin (coherent styles/motifs = a "lost people"). Finding one piece of a set should make completing it desirable (set bonus to prestige/value is welcome, bounded).
- **Legendaries are placed, not rolled:** a handful per world at specific sites, each with a proper name and story.
- **Rumors:** legendary/ancient sites generate rumors that can be learned (from envoys, trade, scouts, existing `scripts/rumor_network.gd` rumor leads if suitable) — vague direction/landmark hints with uncertainty, never exact coordinates. Expose `static func rumored_sites(observer:String="player")->Array[Dictionary]` in `artifact_culture.gd` ({id,name,hint,confidence,known_since_day,found:bool}) so the Chief Scout / audience hall can speak of them later.
- Keep save compatibility (existing claimed site ids/collections still valid; old worlds may keep old cell ids for already-claimed items). Keep total expected artifacts per world in the same ballpark so research/culture balance holds. Also fix: a civ's already-revealed home ground should not permanently hide nearby finds — allow deliberate local survey/digs to find them (e.g. via scouts/expeditions targeting known rumored sites), without making home ground an infinite farm.

## Deviations (Worker M)

Signatures above are implemented unchanged. Additions and clarifications:

- `artifacts(query)`: `page` is **0-based**; default `page_size` 24 (max 200). Default sort `rarity` (then prestige).
- Artifact dict extra keys: `site_name`, `set_name`, `set_size:int`, `set_held:int`, `set_progress:String` ("3 of 5", empty when not part of a set), `set_factor:float` (1.0–1.5), `origin_kind` ("prehistoric"|"civilization"|"site"|"legendary"), `lean:{culture,research,economic}` (shares summing to 1), `research_subject_id`, `focused:bool`.
- `summary().study_role` extra keys: `researchers:float`, `rate:float` (study-work/day); `summary()` also has `museum_ready:bool`, `museum_revenue:float`.
- Extra facade functions: `study_weight()->int`, `set_study_weight(w)->{ok,weight}`, `change_study_weight(delta)->{ok,weight}` (0–12, same budget as the 12 domains), `allure()->float`, `allure_report()->{allure,label,breakdown,effects}`, `story(item)->String`, `rumored_sites(observer="player")->Array[Dictionary]` (`{id,name,hint,confidence,known_since_day,found,exhausted,legendary,kind,source}`).
- `set_exhibited(id,true)` requires the piece to be studied (and the museum discoveries), returning `{error}` otherwise.
- Storage: the role is `society_exchange.artifact_study = {weight:int, focus:String}` and rumors `society_exchange.artifact_rumors` (both optional, validated). `GameState.research_allocations` is NOT given a 13th key; `DiscoverySystem.research_emphasis_total()` adds the role weight so it shares the observer budget.
- Treasure-hunt distribution lives in new `scripts/artifact_sites.gd` (sites, legends, rumors, digs).
- Recovered finds (prehistoric scatter, site and legendary pieces; `source_id` empty) are studied **only** by the artifact-study role. Craft samples handed over by a living society during a visit (`source_id` set) are practice evidence and stay in the ordinary Knowledge study queue as before; once studied they still count for culture values and allure. Their `state` reads "in_study" until done, and `set_study_focus` on them returns an explanatory `{error}`.
- Display names: Artifact `name` is now a presentation title (e.g. "An Ember Under Ash", "Clay Storage Jar of the Etched River", "The Earth-Darkened Rough Stone Bowl"); the technical variation ("a broad contact") moves to `object` and a new `variant` key; the saved catalogue name is `catalogue_name`. Saved records and ids are unchanged. `artifact_culture.display_name(item)->{name,variant,object}` is public.
- `sets()->Array[Dictionary]`: one entry per held set `{set_id,set_name,site_name,held,total,items:[ids],missing,complete:bool,progress:"3 of 5",legendary:bool}`, sorted by completion.
