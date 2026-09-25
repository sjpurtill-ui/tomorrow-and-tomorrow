# Fun Audit — 2026-09-25

Worktree `C:/Users/sjpur/tt-fun-audit`, branch `codex/fun-audit`, base `d4ca8cdf` (origin/main). This was a read-and-play pass: no gameplay code changed and nothing committed. User data was isolated through an untracked `override.cfg` pointing at `TomorrowFunAuditTests`. No saves were written, and the user's game and editor were not touched.

**The verdict in one line.** The game's heart is good: the Court, the Known World map, the scout debriefs and the ambition art are well written, well drawn and grounded in their era. That heart is buried under a management sim, and the first decade of play contains almost nothing the player would feel or retell.

## How I played

| Harness (uncommitted, `tests/fun_audit/`) | What it does |
|---|---|
| `fun_playtest.tscn` | Runs the real `local_terrain.tscn` through `advance_world_time`/`_commit_world_day` at speed 5. It picks an ambition, settles on day 0, and answers every envoy at random among the enabled options. It logs every event, council item, ticker change, discovery popup, audience, pause and yearly KPI row to JSONL. Seeds 424242 (Makers) and 77013 (Military). |
| `fun_capture.tscn`, `fun_close.tscn` | Isolated GPU captures of a fresh game: the opening, the first map, docks, the Court and settlement close-ups. Run through `tools/run_isolated_gpu_probe.ps1`. |
| `tools/audit_history_pacing.gd` | An AI seat simulated for 50 years (seed 91420): discovery and growth timeline. |
| `tests/audience_transcript_dump.tscn`, `audience_summon_probe.tscn`, `universal_order_probe.tscn` | Offline transcripts of envoys, summoned officials and typed divine orders. |

Captures are in `docs/fun_audit_captures/`. The raw logs are in the session scratchpad; the numbers below are copied from them.

**Limits of this evidence:**
- Voice was offline (no LLM).
- The harness settles immediately and answers envoys blindly, so a human player might act more.
- Headless CPU time is not rendered frame time.
- The player runs were stopped at year 25 (about 80 s of CPU per year by then). Numbers cover years 0–25 of both seeds, plus the 50-year AI seat.

## Evidence

### Numbers

| Measure (years 0–25) | Seed 424242 (Makers) | Seed 77013 (Military) | 50-year AI seat |
|---|---|---|---|
| First discovery | toast at year 5.0 (day 1834) | toast at year 4.5 (day 1629) | year 5.9 |
| Known practices | 10 → 28 | 10 → 26 | 10 → 33 (year 50) |
| Discovery popups (interrupting cards) | 1 in 25 years | 1 in 25 years | — |
| Population | 120 → 147 | 120 → 154 | 120 → 193 (year 50) |
| Completed works | 5 by day 366, **still 5 at year 25** | 5 → 5 | 5 → 6 in 50 years |
| Foreign peoples met | **0 in 25 years** | **0 in 25 years** | — |
| Envoy audiences (the only unbidden decisions) | **0** | **0** | — |
| Officeholder deaths (one HR sentence each) | 9 | 12 | — |
| Share of all events that are routine (single birth/death, scout "nothing", drill, pregnancy loss) | **96%** of 297 | **95%** of 316 | — |
| Non-routine events after founding | 4 (discovery toast, caravan out, village seeded, "Government Expanded"), all by year 6 | 4, all by year 5 | — |
| **Longest dead stretch** (nothing but routine and officeholder deaths) | **day 2192 → 9160+: ~19 game years** | **day 1831 → 9323+: ~20 game years** | — |
| Status ticker | tutorial hint "RECOGNIZED RESOURCES SHOWN • TWO-FINGER SLIDE TO PAN" for 24 of 25 years | same | — |

**Real-time pacing:**
- The game starts at ½ h/s, which is **48 real seconds per game day** (`local_terrain.gd:20380`).
- Top speed is capped at 3 days/s, so 25 game years take at least 50 real minutes, which is a full first session. In that time the game solicits **zero decisions** (apart from founding and naming) and delivers four non-routine events, all in years 5–6.
- The Year-71 audit measured 0.63 days/s at year 71, about 10 real minutes per game year (`docs/performance/YEAR71_AUDIT.md`).

### Quotes the player actually sees

- **A chief's death, rendered as HR policy:** "Sana Ivers died aged 53 while serving as Hearth Chief. The office and local duties now pass through the same succession rules as every other appointment."
- **Ledger rows:**
  - "No exceptional crisis outweighed ordinary mortality… Affected cohorts: children, youth, early_adults, established_adults, mature_adults, elders."
  - "1 pregnancies ended before delivery under current health, nutrition, shelter, and care conditions."
- **Developer notes shown to the player:** "Government Expanded — Population, distance, and institutional work now require additional named officeholders. Government remains a bounded cast of people, not an abstract cabinet."
- **Drills in a 120-person band:** "The exercise improved aggregate formation preparation and command practice. It consumed 16.5 extra rations and wore 0 issued equipment."
- **Typed divine orders** (`universal_order_probe`, 41 orders):
  - **41/41** replies begin "I have heard you."
  - **32/41** contain the identical sentence "We can make a visible start, but the settlement cannot sustain every part at once."
  - "Sacrifice a child at the new moon" produces `legitimacy +0.009 · cohesion −0.015 · 1 dead` and then nothing further.
- **Envoys** (3-year offline transcript, 20 audiences): 7 are gifts, and 11/20 resolutions are "accept". Stone-age envoys are named "Roger Ward", "Simon Carter" and "Agnes Reed" (court member "Aster Reed" shares the family name); the court seats both "Liora Yi" and "Liora Zoric". Player officials in the runs: "Hana Kim", "Bako Sato", "Edda Ward", "Nkiru Chandra".
- **UI vocabulary in the stone age:** KPI strip "REAL GDP / DAY 66.9", "IMR 173%", "SCIENCE 2.3 · 60% edu". The government is a "Federated Civic Order". The Culture dock reads "Personal Autonomy, Private Control, Extraction". The Military dock shows **Navy** and **Air Force** tabs for 2 soldiers.

### Screenshots

| File | What it shows |
|---|---|
| `01-opening-ambition-screen.png` | 14 purpose cards (scrolling needed), tagged "LOGISTICS · ECOLOGY", with unexplained Council / National character tabs. The art is lovely. |
| `02-first-map-convoy.png` | The first playable frame: flat green void, a label, 7 KPI jargon chips. |
| `03-founding-naming.png` | Naming prompt: "an owned, governed place with its own population share…". |
| `05-year1-map.png`, `06-dock-overview.png` | A 15-tile dashboard covering 70% of the screen; the map behind it is still empty green. |
| `06-dock-production.png`, `06-dock-military.png` | Production line "Simple levy weapons 0.00/day · Paused"; Army / Navy / Air Force. |
| `06-dock-world.png` | The Known World: charcoal-on-hide map, "8 tales carried home". **The best screen in the game.** |
| `07-court-at-rest.png` | The fire circle court: a good era backdrop, love/dread bars, matter badges. The Pathfinder and War leader use the **same portrait**. |
| `12-settlement-day1460-*.png` | Year 5 settlement at 10,000 ft (an empty ring with a label), 200 m and 70 m. Low-poly cabins and sheds; **no people, smoke, fire or motion** anywhere. |

### What already works (protect it)

- **Summoned-official and scout debriefs are vivid:** "you hear Orrun Gate before you see it… hammering from first light, and workshop smoke you can taste".
- **Court asides have wit:** "The last present we had was a goat, and the goat bit me."
- **The Known World map is era-perfect.**
- **Love and dread** have real mechanics: sabotage, flight, candour.
- **Typed orders never refuse** and always move bounded stats.
- **The no-repeat rule and cadence budgets hold:** 0 duplicate lines in 132.

## Top 10 fun problems, ranked by impact

### 1. The first session is dead air (four non-routine events in 25 years, then about 19 silent years)
- **Evidence:** Across 25 game years (at least 50 real minutes at top speed):
  - 0 envoys, 0 peoples met, and 1 interrupting discovery card.
  - 95–96% of events are routine.
  - The only story beats are a discovery toast and an automatic daughter-village caravan at years 4.5–6. After that, about 19 game years pass with nothing but births, deaths, scout "nothing found" returns and officeholder obituaries.
  - The game also starts at 48 s per game day.
  - `WHOLE_GAME_COHERENCE.md` (.16) records natural contact on day 45 in a fresh world. These two default-start seeds made no contact in 9,000+ days despite 43–53 scout returns. Check first whether the reachable-neighbour placement regressed or only succeeds on some seeds.
- **Fix: an Opening Arc director** that guarantees a real, sim-grounded beat every 2–4 real minutes across the first hour. Every beat must come from existing systems, never invented stock:
  - **Day 0–30, first omen.** The nearest community's smoke or tracks are sighted. `WorldSimulation.communities` already places reachable neighbours, so the first scout party returns with a concrete sign instead of "no polity".
  - **First winter.** A named family is at risk, and the player hears it in court.
  - **First discovery.** It is taken from the nearest-ready founding practice and presented as a scene. This fits the research-block branches: it chooses *which* ready practice is shown first and does not accelerate research.
  - **First birth of a named child** to a court member.
  - **First meeting with the neighbours** by about year 2. Use the existing contact rules; do not force contact on distant civs.
- **Speed:** default to 1 day/s after founding.
- **Size:** L.
- **Touches:**
  - new `scripts/opening_arc.gd`, fed by `local_terrain._commit_world_day`
  - `chief_scout.gd` (return content)
  - `civilization_system.gd` / `WorldSimulation.communities` (nearest-neighbour sighting)
  - `local_terrain.gd:20380` (default speed)
- **Verify:**
  - Extend `fun_playtest` with a `FIRST_HOUR` budget: at least one "moment" tier event every ≤ 120 game days at speed 5, the first by day 60, and a neighbour contact or sighting by day 730.
  - Playtest: a fresh player can name three things that happened in their first 10 minutes.

### 2. Named people die as paperwork, so nobody is loved
- **Evidence:** 9 and 12 officeholders died in 25 years in the two seeds, each with one HR sentence. Portraits are reused (Pathfinder = War leader). Names are modern Anglo, Scottish, Persian and Chinese given+family pairs (`historical_name_generator.gd` POOLS), which read anachronistically in a band with no surnames. Officials cannot marry, have children or grow old on screen.
- **Fix: a Lives layer** on top of GovernmentPeopleSystem, with no new population authority:
  - **Death becomes a Court scene:** mourning, a eulogy in the survivors' voices, and the god chooses among 2–3 voiced successor candidates. If the god says nothing, the existing succession rule stands.
  - **Kin links** (child of, apprentice of) and a "Remembered" roll in the Chronicle.
  - **Era-gated naming:**
    - Stone age: single names plus an epithet ("Liora Who Found the Ford").
    - Family names only after institutions or writing.
    - Deduplicate given names within a court.
  - **Unique portrait per living court member** (vary the existing art index).
- **Size:** M.
- **Touches:**
  - `government_people_system.gd` (succession hook)
  - `audience_hall.gd` (new `mourning`/`succession` occasion)
  - `historical_name_generator.gd`
  - `hud/person_portrait.gd`
  - `historical_figures.gd`
- **Verify:**
  - Probe: every officeholder death within 30 days yields a waiting succession matter with at least 2 candidates. No two living court members share a given name or portrait.
  - Playtest: at year 20 the player can name a dead chief and why they mattered.

### 3. Being a god has no spectacle and no memory
- **Evidence:** 41/41 order replies share the same opener and effects of ±0.01. "Make it rain" costs 43 food and does nothing, ever. There are no omens, no visible rite on the map, and no callback months later. Wrath and favour are buttons, including a skull icon beside every official in Government. Foreign `civ_dread` and the people's regard are displayed but no AI reads them (agent audit, `divine_regard.gd`).
- **Fix: make divine acts into events:**
  1. **A staged reply:** 3–6 personality-keyed openers per path, and a line quoting the order back in the speaker's voice.
  2. **A visible rite** on the map for 3–10 days: bonfire, procession, cairn, carved cliff. Use the existing settlement fabric and props; no new image assets (procedural-icon rule).
  3. **A consequence callback** 30–180 days later, told in court: "Since the feast, the Reed families share one fire."
  4. **Coincidence omens.** When real weather or harvest happens to match a "miracle" request (rain within 20 days of "make it rain"), love and dread jump and the court talks about it. No miracles are faked; the world only has to *agree* sometimes.
  5. **Rivals read `civ_dread`** in envoy tone and in tribute and threat choice.
- **Size:** M.
- **Touches:**
  - `custom_directive.gd`
  - `court_commands.gd`
  - `divine_regard.gd`
  - `audience_hall.gd` (callback occasions)
  - `consequence_engine.gd`
  - `local_terrain.gd` (rite props)
  - `civilization_controller.gd` (read dread)
- **Verify:**
  - `universal_order_probe`: at most 15% of replies share an opener, and no sentence repeats in more than 3 of the 41.
  - A 3-year cadence probe: each distinct order produces at least one callback line.
  - Playtest: the user retells a "the rain came after I demanded it" story.

### 4. No hour-to-hour aim: nothing to strive for without victory
- **Evidence:** Over 50 years the AI seat went 120 → 193 people and 5 → 6 works. Both player seeds stayed at 5 works for 25 years, with population 120 → 147/154. There is one ambition per century and 3 visions, then none (`people_direction.gd:122`). There is no self-set goal and no visible progress toward anything.
- **Fix: generational Aims (a "Legacy ledger"):**
  - The people and officials propose 2–3 condition-led aims when conditions change. Examples: "Reach the salt lake", "No child dies of hunger this winter", "Make Orrun fear our name", "Raise a stone ring the whole valley can see". Each lasts 5–25 years.
  - The god picks one, or types their own; any typed aim is accepted.
  - Progress is shown on the Known World or the map. Success or failure goes into the Chronicle as a legacy line, and the people's love or dread shifts.
  - Rivals hold aims too, and some are visible through envoys.
  - Replace exhausted visions with this.
- **No victory:** aims never end the game.
- **Size:** M.
- **Touches:**
  - `people_direction.gd` (retire VISIONS)
  - new `scripts/legacy_aims.gd`
  - `campaign_chronicle.gd`
  - `hud/known_world_board.gd`
  - the Court
- **Verify:**
  - At every point in years 0–100 at least one aim is live, with a proposal at least every 10 years.
  - Aims resolve in 5–25 years and do not repeat within 50.
  - Playtest: asked "what are you trying to do right now?", the player gives a specific answer.

### 5. The UI is a management dashboard, not a god's view
- **Evidence:**
  - 11 rail sections: Food, Materials, Wealth, Buildings and Production are separate ledgers.
  - A 15-tile Overview.
  - KPI jargon (GDP/day, IMR 173%, 60% edu).
  - Production lines at 0.00/day, and Navy / Air Force in the stone age.
  - The Court, the heart of the game, is one small rail tile.
  - Past complaint: "hideous and boring" screens.
- **Fix:**
  - **Reorder the rail** around the fantasy: **Court**, **The People** (overview in plain words), **Known World**, **Chronicle**. Collapse Food, Materials, Wealth, Buildings, Production and Military details into a "Ledgers" drawer. The detail stays one click away, so none is lost.
  - **Era vocabulary for KPIs:** "118 souls", "stores last 48 days", "water: the spring (5 days if it fails)". Hide GDP, IMR and "edu" until the civ has counting and records.
  - **Hide Navy and Air Force** until the capability exists.
  - **Do not auto-open the settlement dock on founding;** it covers 70% of the map (`local_terrain._open_people_panel`).
- **Size:** M.
- **Touches:**
  - `hud/command_rail_hud.gd` (SECTIONS)
  - `hud/civilization_kpi_model.gd`
  - `hud/content/dock_content_overview.gd`
  - `hud/content/dock_content_military.gd`
  - `local_terrain._start_settlement_here`
- **Verify:**
  - A capture diff at year 1 shows no modern acronyms on screen.
  - The rail shows ≤ 6 primary entries in the stone age.
  - Playtest: a first-time player's first click after founding is the Court or the map, not a ledger.

### 6. The map is an empty green field: no life, no juice
- **Evidence:**
  - The first playable frame is flat green at 10,000 ft (`02-first-map-convoy.png`).
  - At year 5, 10,000 ft shows an empty ring and a label. At 70 m there are brown cabins and bushes, with no people, fire, smoke, animals or seasons visibly acting (`12-*`).
  - Births, deaths, discoveries and scouts leave no mark on the map.
- **Fix: a "living map" layer:**
  - The **opening camera starts at the 200 m view** on the convoy.
  - **Bounded visual representatives** (AGENTS rule) doing the current labor mix: gatherers walking to the catchment, smoke from hearths scaled by population, a fire at the Court site.
  - **Event pings** on the map (a birth light, a death smoke, a scout walking home along its route).
  - **Seasonal tint** tied to the calendar.
  - Keep counts bounded.
- **Size:** L.
- **Touches:**
  - `local_terrain.gd` (settlement visuals / `_refresh_settlement_footprint`)
  - `basic_units` crowd assets already in `tools/` (`bake_basic_unit_crowds.py`)
  - `hud/service_world_overlay.gd`
- **Verify:**
  - A GPU capture at 200 m on day 30 shows at least 8 moving figures and at least 1 smoke plume.
  - Frame time p95 at speed 5 stays within the year-71 budget.
  - Playtest: the player zooms in unprompted and watches for more than 10 s.

### 7. Nothing feels good when it happens
- **Evidence:**
  - Discoveries interrupt only for 6 hard-coded milestones (`research_announcements.gd:8`: seed_selection … reactor_engineering). Everything else is a corner toast.
  - `AudienceDirector._offer_ceremony()` is **never called**, so great-work dedications never open by themselves.
  - There are 7 separate notification channels and no single readable log.
  - Routine rows are clinical.
- **Fix:**
  - **Tier every report** as whisper, notice or **moment**. A moment gets a short illustrated card with the art already in `assets/ui/artifacts` and `research_card_art`, a sound sting and a one-line era-voiced caption. It never pauses unless it is a decision.
  - **Make the first discovery in each domain a moment,** instead of the 6-ID list.
  - **Wire `_offer_ceremony`** into `AudienceDirector._process`.
  - **One Chronicle feed** (a rail entry) reading `GameState.simulation_events`, `discovery_log`, the chronicle chapters and audience history, in era voice.
- **Size:** S–M.
- **Touches:**
  - `hud/research_announcements.gd`
  - `audience_director.gd:135`
  - `hud/discovery_popup.gd`
  - new `hud/chronicle_feed.gd`
  - `consequence_engine.gd` (event prose)
- **Verify:**
  - Probe: a dedication opens within 1 day of pending.
  - Over 30 years, moment-tier cards number 1–4 per game year and are never more than 3 per 30 days.
  - Playtest: the player reads the Chronicle voluntarily.

### 8. Repetition and noise drown the signal
- **Evidence** (seed 424242, 25 years):
  - 53 "SCOUTS RETURN… No organized foreign polity was encountered"
  - 123 "1 birth" rows and 74 "1 death" rows
  - 15 "Pregnancy Losses" rows ("1 pregnancies…")
  - 9 drill reports in a band of about 130
  - the ticker stuck on a tutorial hint for 24 of 25 years
- **Fix:**
  - **Fold single births and deaths** into a seasonal "Hearth count" line ("Spring: 4 born, 2 buried, among them old Tamsin").
  - **Scout returns stay silent** unless they find something new. "Nothing found" only updates the Known World.
  - **Drills are silent** below a force threshold.
  - **The ticker shows the latest moment,** never a tutorial hint after day 30.
  - **Fix the pluralization.**
- **Size:** S.
- **Touches:**
  - `consequence_engine.gd`
  - `civilization_system.gd` (scout return event)
  - military training report emitter
  - `local_terrain._commit_world_day` ticker
- **Verify:**
  - In `fun_playtest`, no normalized event text exceeds 10% of all events in any 5-year window.
  - Routine rows are ≤ 25/year.

### 9. Envoy choices are trivial and rivals aren't characters
- **Evidence:**
  - 11 of 20 audiences resolve "accept", and 7 of 20 are free gifts.
  - Accords are "+12% culture research support".
  - Nobody is met in 25 years of natural play in either seed.
  - Rival leaders exist only as a named chief in a messenger's line.
  - Free-text foreign dialogue needs a live model (`foreign_dialogue.gd:113`).
- **Fix:**
  - **Every envoy ask carries a cost or a string:** gifts with obligations (a marriage, a hunting ground, a hostage), requests at a time when giving hurts, and border quarrels over a real catchment.
  - **Options show which court member objects, and why.**
  - **Rival rulers get a persistent portrait, a literary voice, grudges** (the ledger already exists) and one signature trait visible in the tone of every envoy.
  - **An offline fallback for foreign talk** reusing the court voice banks.
- **Size:** M.
- **Touches:**
  - `audience_hall.gd` (`_foreign_candidates`, options)
  - `diplomatic_commitments.gd`
  - `foreign_dialogue.gd`
  - `character_voice.gd`
- **Verify:**
  - Transcript probe: the "accept" share is ≤ 45%, and every option set has at least one cost line.
  - A rival's grudge from year X is referenced at least once by year X+5.
  - Playtest: the player names a rival ruler and their temperament.

### 10. The opening asks the wrong questions in the wrong words
- **Evidence:**
  - The first screen offers 14 purposes (6 below the fold, including all five dark ambitions), tagged in simulation domains ("LOGISTICS · ECOLOGY").
  - Two unexplained tabs.
  - Then a bureaucratic naming dialog, then the Overview dock.
- **Fix:**
  - **Open on the convoy at dusk with the fire circle;** the Court is the first screen.
  - The Hearth Chief asks **one question in voice**: "What should our children say of us?"
  - Offer **4 era-worded answers plus "something else" (typed)**, and map them to ambitions.
  - Show the rest of the list only on request.
  - **Ask for the name in the chief's voice at first fire**, with the option to name it later.
- **Size:** S–M.
- **Touches:**
  - `people_direction_screen.gd`
  - `local_terrain._open_founding_focus_panel`
  - `_open_settlement_naming_panel`
  - the Court (`hud/audience_modal.gd` focus)
- **Verify:**
  - Time from launch to first unpaused day is ≤ 45 s in the GPU journey.
  - Playtest: no one asks "what does LOGISTICS mean?".

**Also noted, below the cut:**
- Real-time pacing collapses to about 10 min per game year by year 71 (performance is owned elsewhere). Consider an "until something happens" speed that runs uncapped quiet days and stops at moment-tier events.
- Love can be farmed through repeated summon-and-bless with no diminishing returns.
- Settlement leaders in `court_civic.gd` can still refuse outright, which contradicts "leaders never refuse" (past complaint).
- The auto-settled daughter village (year 5–6) happens without the god.

## Signature moments for the first hour (≈ years 0–30 at 1–3 days/s)

1. **"Smoke on the horizon" (minutes 2–6).** The first scout returns with a concrete sign of the nearest community. The Pathfinder tells it in court, the Known World draws a "?" at the smoke, and the god chooses: send gifts, send watchers, or hide our fires. It is built from `WorldSimulation.communities` and `chief_scout.gd`. **Check:** it occurs by day 90 in ≥ 90% of seeds.
2. **"The first hard winter" (minutes 8–15).** Seasonal stores dip below 20 days and a named family is at risk. The Hearth Chief is summoned or petitions, and the choice is to share stores, send hunters, or pray. Whatever is chosen gets a callback in spring: who lived and who is grateful. It is driven by real `food_days`, not scripted. **Check:** 1 per first 5 years when food_days < 20. If the site is too rich for that, substitute a fever or injury beat.
3. **"The chief is dead; choose who speaks for the hearth" (minutes 10–25).** Mourning at the fire circle, with 2–3 candidates who speak. The choice sticks for life, and the loser may resent it. This uses the officeholder deaths that already happen about every 3 years.
4. **"The god's word, answered by the sky" (whenever the player types a miracle or rite).** A visible rite on the map, then a coincidence omen when real weather or harvest agrees. The love and dread swing is voiced by the court. **Check:** at least one omen per 3 rites.
5. **"Strangers at the fire" (by year 2–5).** The first envoy arrives with a gift that has a string (a marriage between houses). Accepting creates a named in-law at court. That person later becomes a hostage, a traitor or a bridge, when war or peace comes.

**Measurable proxy for the whole hour:** from `fun_playtest`, count moment-tier events, prompted decisions and player-available matters per 10 real minutes at 1 day/s.
- **Today:** 0 prompted decisions and 4 non-routine events in the first 50 real minutes at top speed, followed by an unbroken dead stretch of about 19 game years.
- **Target:**
  - at least 3 moments and at least 2 decisions per 10 real minutes in the first hour
  - no stretch of more than 4 real minutes without a moment or a waiting matter
  - no normalized line exceeding 10% of the log

## Coordination with in-flight branches

- **Research pacing:** `codex/research-600` and `codex/research-1200` own it. #1 and #7 change only how the first discovery is *presented*, not when it happens.
- **Scout survival:** `codex/scout-survival` owns scout deaths. #1 and #8 change only what a return *says*.
- **Summoning anyone and lies:** `codex/court-summon` owns that. #2 and #9 add occasions and must merge with it.
- **Court evolution:** `codex/civic-evolution` owns the backdrop and stages. #10 uses the Court as the opening scene.

**Shared hotspots touched by the proposals:**
- `local_terrain.gd`: #1, #5, #6, #8, #10
- `audience_hall.gd`: #2, #3, #9
- `game_state.gd`: #7

**Suggested order:** #8 and #7 (S, fast feel wins) → #1 and #10 (the opening) → #2 and #3 (people and god) → #4 and #9 (arc and rivals) → #5 and #6 (UI and map, largest).
