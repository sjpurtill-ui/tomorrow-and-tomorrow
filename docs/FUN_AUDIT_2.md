# Fun Audit 2 — hours 2 to 5

Worktree `C:/Users/sjpur/tt-fun-audit2`, branch `codex/fun-audit-2`, base `48f74ed5` (origin/main, fun waves 1 and 2 integrated). This was a read-and-play pass. No gameplay code was changed. User data was isolated through an untracked `override.cfg` (`TomorrowFunAudit2Tests`). No saves were written, and the player's game and editor were not touched.

**The verdict in one line.** Waves 1 and 2 fixed the first hour: it is now busy, warm and full of named people. Then it runs out. From about real hour 2 the game settles into one loop, in which an envoy arrives, the player picks accept, decline or rebuff, and a seasonal "what we learned" notice follows. Nothing the player refuses ever comes back to hurt them. The people shrink and nobody says why. For the first two real hours no generational aim is achieved in any run.

## How I played

| Tool | What it does |
|---|---|
| `tests/fun_audit/fun_playtest.tscn` | The real `local_terrain.tscn` through `advance_world_time`, with a plausible-player policy for envoys (`--policy`) and aims (`--aims`). This pass adds three things to its log: the founding biome; yearly wars, treaties, peoples met, great works and soldiers; and UI marks at years 50, 75 and 100. |
| `tests/fun_audit/long_run.py` (new) | Per game decade (about one real hour at the default 1 day/s): moments, notices, whispers, decisions, matters, named deaths, discoveries, the longest gap, the share of lines never told before, and the most repeated line templates. |
| `tests/fun_audit/first_hour.py` | The first-hour pacing from wave 1, unchanged. |
| `tests/universal_order_probe.tscn` | 41 typed divine orders, offline. |
| `wave2_capture` (one GPU run, seed 31337, woodland) | Taken before the coordinator narrowed this pass to the simulation. The captures are kept locally and not committed. |

**Runs.** All ran in parallel and headless. They were stopped at the delivery deadline, so the years reached are shown.

| Run | Seed | Biome | Ambition | Aims / envoy policy | Years reached |
|---|---|---|---|---|---|
| A | 424242 | grassland | makers | player / heuristic | 25 |
| B | 77013 | grassland | military | player / random | 26 |
| C | 31337 | woodland | dominion | silent / heuristic | 19 |
| D | 5150 | grassland | commerce | player / heuristic | 23 |
| E | 12121 | grassland | horizons | player / random | 27 |
| F | 888 | grassland | retribution | player / heuristic | 24 |
| G–I | 31689, 7932, 20260 | woodland, woodland, grassland | wellbeing, purity, gathering | mixed | 9/11/10 |

**Limits.**
- The deadline was about one hour, so runs A–F cover 19–27 game years rather than 100. That is about 2–2.7 real hours at 1 day/s, so hour 2 is measured and hours 3–5 are extrapolated from the trend. Headless cost rose from about 50 s to about 150 s of CPU per game year around year 14 in every run.
- Voice was offline.
- The harness never types orders, never summons officials for non-aim matters (so mourning, great-work and wonder pitches go unanswered), and never opens ledgers. A human player would do more of this.
- Visual findings come from the coordinator's wave-2 notes and one wave-2 capture on the woodland seed. They were not re-verified on the GPU.

## Evidence

### 1. The moment rate collapses after the first hour

Chronicle entries graded "moment", per game year (one game year is about 6 real minutes at 1 day/s):

```
   year  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27
A        9  5  1  6  3  2  2  4  2  3  1  0  0  1  0  0  0  0  0  1  2  4  0  0  1
B        8  5  4  6  3  1  5  1  1  2  0  1  2  0  2  1  1  1  0  0  0  0  0  1  2  0
C        9  7  3  2  2  3  6  3  4  2  1  2  0  2  1  1  0  2  1
D        9  2  2  1  1  4  8  4  3  5  0  2  0  2  1  0  2  0  0  1  2  1  1
E        7  5  2  2  2  3  2  3  2  1  2  1  3  1  0  2  1  1  0  1  0  2  0  0  1  0  1
F        9  4  3  2  3  1  1  1  3  4  1  1  0  1  0  1  0  1  0  1  1  0  0  1
```

Decisions per game year stay at about 4 in every run except E. Nearly all of them are envoy audiences on a fixed cadence of about 100 days:

```
   year  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27
A        5  3  4  3  4  5  3  3  4  3  5  3  4  4  4  4  5  4  3  3  6  3  4  3  5
B        5  4  3  5  4  4  4  4  3  4  3  5  4  3  4  5  6  4  4  5  4  4  3  5  5  3
C        3  4  4  4  4  4  4  4  4  4  3  4  4  4  4  4  4  4  3
D        5  3  4  5  4  3  5  3  4  4  4  5  3  4  4  4  4  4  4  5  4  4  4
E        3  0  0  1  0  2  0  0  0  0  1  0  0  0  0  1  0  0  1  0  1  1  0  0  1  0  1
F        5  3  4  3  4  4  4  4  4  4  5  4  4  3  5  5  4  4  3  4  5  3  4  4
```

- **Run B by decade (`long_run.py`; one decade is about one real hour):**

  ```
  hour | moments notices whispers | decisions (aim) matters | named deaths | discoveries | fresh lines
   1   |   36   47   92          |   40 (3)  42            |  8           |  36         | 83% of 320
   2   |    8   70   91          |   43 (4)  40            |  2           |  51         | 77% of 297
   3*  |    4   52   51          |   28 (2)  32            |  4           |  34         | 76% of 176   (* 6 years)
  ```

  Notices hold steady, but they are seasonal digests and refiled court wishes. Moments fall by a factor of 4–6. By hour 2 about a quarter of all lines the player reads are repeats, even with digits folded.
- **Over the whole run:** moments per game year fall from 5.5–8.0 in years 0–1 to 0.6–1.1 from year 10 on (mean 6.6 → 0.8); at 1 day/s that is one moment every 7 real minutes in hour 2+.
- **Run E (horizons, seed 12121) met only one people, the Drazhen.** It had **0 decisions in most years from year 2 onward**. Its later decades are an obituary, a seasonal "what the spring taught" and "The Land Is Thinning" on a loop.
- **The feed in hours 2–3 is dominated by:**
  - seasonal teaching notices ("What the autumn taught" is the most repeated title in 4 of 6 runs);
  - scout chatter: in the first 16 years of run B, 26 "The scouts come home" and 38 "Scouts report foreign scout/expedition";
  - `The Land Is Thinning`, filed **every 120 days** from year 13 with the identical text "Gatherers report longer journeys and diminishing returns near the settlement." It never escalates and never asks for a choice.

### 2. Refusals cost nothing, and war never comes

- **Wars with the player: 0 in every run.** Soldiers at the latest year were 2–5 in every run, including *military* (B) and *dominion* (C).
- **Run B received 28 tribute, redress or "test of resolve" demands in 26 years and refused 19 of them. Not one refusal was followed by harm.** Whatever the answer, the only consequences were words: "Pelas answered with a warning but did not move", "Kintara is hardening its border", "It was a bluff… Kintara never came". Paying is the worst choice ("Kintara Had No Spears… the 140 Food you paid bought nothing"). The dominant strategy is always to defy, and the player learns it within an hour.
- **The general-led campaign never happens in the player's world.** `GeneralCampaign` is reached only from the Military dock's "PLAY GENERAL CAMPAIGN" button, which saves the world and restarts on the authored Alderford seed (`general_campaign.gd:48–55`, `dock_content_military.gd:545`). An AI can `declare_war` (`civilization_strategy.gd:86`), but none did in any run.

### 3. The people dwindle, and nobody says why

- **Population in every run falls from 120 to 85–98 by years 19–27 (about 1% a year) while the stores hold 120+ days:**

  ```
  A  y0 120/31d  y5 110/87d  y10 104/126d  y15 101/125d  y20 100/125d  y25 94/128d
  B  y0 120/31d  y5 106/97d  y10 99/131d  y15 95/130d  y20 92/134d  y25 90/132d  y26 90/132d
  C  y0 120/31d  y5 110/96d  y10 100/152d  y15 95/168d  y19 90/163d
  D  y0 120/31d  y5 108/51d  y10 98/132d  y15 93/135d  y20 91/129d  y23 89/141d
  E  y0 120/31d  y5 107/60d  y10 102/134d  y15 96/136d  y20 89/138d  y25 85/142d  y27 85/221d
  F  y0 120/31d  y5 108/124d  y10 102/127d  y15 97/127d  y20 96/128d  y24 98/127d
  ```

- **The top bar's LIVES falls from "46 winters" at the founding to "22 winters" at year 1**, and "10 in 100 babes die" becomes "30 in 100" (`ui` rows). No beat, court line or Chronicle entry gives a cause.
- **The aims system notices the decline and turns it into the people's goal.** By year 11 four of the six runs had adopted "Be 120 Souls Again" or "Be 105/107 Souls Again", and the population kept falling after "Press harder" and "Give it two more winters".
- **The research-600 surrogate calibrated 0.3–0.8%/yr growth.** `PHASE3_BALANCE.md` already warns: "The real engine is harsher than the surrogate for tiny populations." This is that gap, and the player feels it as a slow, unexplained decline.

### 4. Generational aims never pay off

- **Across all nine runs (about 190 civ-years):**
  - **The player adopted 29 aims and fulfilled 2:** "No Child Hungry for Five Winters" (F, day 7218) and "Walk Farther Than Any of Us Has Walked" (E, day 7790). Both came after year 19. 13 were released or set aside, and 4 failed. Two of the failures were "Be 120/105 Souls Again", at 0% progress.
  - **Rivals fulfilled 18 aims and failed 18.** Rivals win nine times as often as the player.
  - **For about 20 game years (two real hours) no aim of the player's succeeds in any run.**
- **Every run proposes "Found a Daughter Hearth" first.** It is never achieved (C failed it on day 3144), because the band is shrinking.
- **Aims contradict each other and nobody notices.** "Make the Telmar Fear Our Name" sits on the Known World sheet directly above "Vilka Tall-Grass of the Telmar has sworn to bind us to them in friendship… the marriage of Hobb into your people" (wave-2 capture, seed 31337). Run B adopted "Make the Kintara Fear Our Name" while paying Kintara tribute.
- **Rival victories arrive as a notice with no warning.** In A, "The Nine Fires Have Their Way… make us yield to them, and pay for their peace" was fulfilled on day 1680 **because the player repaid a gift-loan**. The player never knew that repaying counted as yielding.

### 5. Envoys have become one form in rotation

- **Every run opens with the same envoy:** a food gift of 130–220, carrying one of two strings (a loan, or "their hunters take about 2 Food a month for two winters").
- **After that, `proposal` audiences cycle through four shapes:** an artifact gift, an artifact purchase, an accord offer and a protection pact. Each has the same accept / decline / rebuff triad and the same decline cost, "X looks elsewhere for friends".
- **Artifact names are procedural strings with loot rarity attached.** Examples: "The sharp edge guarded by a fold — a little grit added (common)" and "The pebble line counted by moving — the unfinished comparison (unusual)". There were 28 "(common) as a gift" offers across the runs.
- **Anachronism:** 18 purchase offers in the stone age read "For 45 in coin, paid from their treasury with metal backing".

### 6. The court turns over too fast to love anyone, and names break the era

- **Hearth Chiefs die at 36–54.** In E the chiefs were Faro (died day 3782, age 36), Tam (4472) and Anni (4802): three chiefs in three years. B and D saw 8–9 named deaths in the first decade.
- **Mourning and succession are matters that wait to be summoned.** The harness never summoned, so every succession passed by default, silently. A player who does not visit the Court gets the same result.
- **Officials refile the same wish about every 150 days.** In B, "Bekk Oath-Holder wants a public council where the people can…" appeared 15 times and "Ulla Full-Basket wants more hands set to inquiry" 14 times.
- **Children of the court get modern real-world names, often of the other sex:**
  - a son "Hana", a son "Laleh", a son "Nadiya", a son "Soraya", a son "Dimitra", a daughter "Farid", a daughter "Yejun";
  - the first-winter families are "the Qureshi grandmother", "the Yi grandmother" and "the Chandra grandmother".

  This breaks both the era-names rule and alternative-history naming.

### 7. Two notification systems and dashboard remnants (coordinator's list, verified in code)

- **The top bar still shows °F:** `command_rail_hud.gd:1029` (`"%d°F %s"`).
- **The babes line collides with LORE:** `era_words.gd:136` draws "30 in 100 babes die" as a sub-label that runs into LORE in both wave-2 captures.
- **Bottom bar remnants:**
  - "SCOUTING · %.1f%% · %d AWAY" (`local_terrain.gd:11134`, `command_rail_hud.gd:1157`);
  - "SITE 20 M";
  - the distance selector reads "10,000 ft" at the 200 m opening height (`CAMERA_DISTANCE_LEVELS`, `local_terrain.gd:113`).
- **The old toasts stack beside and on top of Chronicle cards.** In the year-5 capture, "EXPEDITION RETURNED · 8 UNREAD" (dated Y4 D300) and "RESEARCH · 13 NEW FINDINGS" sit beside a Chronicle card from two seasons earlier, and they cover the aim sheet.
- **"the The Nine Fires?" on the story map:** `known_world_board.gd:873` formats `"the %s?"` around a name that already begins with "The".
- **Developer voice still reaches the Chronicle:**
  - "Lookouts sight Seven Wells about 9 km away at the marked position. **This is a local observation, not global tracking.**"
  - "Returning scouts report **a expedition** of Pelas", and "an unidentified **polity**"
  - "Foreign policy enacted: A standing trade compact opens **value-conserved exchange**"
- **The Materials ledger in year 1 lists copper and iron** (`ui_measure` lexicon hits `metal:copper`, `metal:iron`).
- **The court roll shows "Hollin the Fair K"** as a name (wave-2 capture).

### 8. The god has little to do after the first hour

- **Replies to typed orders now vary** (`universal_order_probe`, 41 orders). All 41 still quote the order back inside one of five frames: "— it will be done" 14, "and we will see to it" 8, "the people will hear it tonight" 7, "will learn what obedience weighs" 5 and "a small order with a long shadow" 5. 36 of 41 last exactly 180 days.
- **All five miracles have identical effects** (labor −0.011…−0.013, cohesion +0.009, 43 food).
- **"Build a great temple to me on the hill" does not start a Great Work.** It maps to `emergency_building+custom[attempt,monument]`.
- **No Great Work was commissioned in any run.** Wonder pitches did arrive (C: 2 `wonder_proposal`, D: 4 `great_work` matters), but they wait in the court queue among refiled wishes and lapse unanswered. Completed works stayed at the 5 founding structures in every run.
- **The harness never needed the god.** Nothing in years 5–30 invites a divine act: no crisis, no plea, no omen that asks for an answer.

### 9. Discovery is a firehose of paperwork

- **Runs learn 3–5 practices a game year:** A went from 10 to 87 in 15 years. Most arrive as whispers or seasonal digests, with names such as "Batch Task Grouping", "Paired Carrier Balancing", "Raw-Material Pre-Staging" and "Sightline Staking".
- **A discovery never changes the map, the court or the story.** The research toast reads "13 NEW FINDINGS · Review findings →" beside the Chronicle.

### 10. Every start looks the same

- **15 of 18 probed seeds found in open grassland; 3 in dense woodland.** No coast, hills, marsh or dry country appeared.
- **The first ten years run the same script in every seed:** a food-gift envoy, first contact on day 60–74, "Found a Daughter Hearth", a named child at a chief's hearth, the first winter's grandmother.

## What already works (protect it)

- **The first hour.** Each run had 123–161 moments and 43–117 decisions in its first real hour, and the longest silence was 1.3–2.6 real minutes (`first_hour.py`). First contact comes on day 60–74.
- **Rival rulers with memory make good lines:**
  - "Birk has not forgotten how you refused us 55 Food when we were hungry."
  - "Qira rules now in place of Yenna, and was raised on the story of how you refused our gift of 200 Food."
- **Bluff tells ("names no day and no place, and will not meet your eye") are a real skill test.** The next step is to let them sometimes lie.
- **Child milestones are among the most affecting lines in the game:** "Hana is walking… into the fire-stones and out again. Hana has outlived the year that takes one in every 3."
- **The aim proposal scene** puts two officials arguing at the fire. It is the best decision format in the game.

## Top 10, ranked by impact

Size: S ≤ 2 days, M ≤ 1 week, L > 1 week for one worker.

### 1. A mid-game that makes things happen: shocks and crises from the sim (L)
- **Problem:** Moments fall from 8–9 in year 1 to about 1 per game year after year 10. Nothing in hours 2–5 threatens the people or asks the god to act.
- **Fix: bring in the first slice of the epochal-shock model** (`docs/research/epochal/EPOCHAL_SHIFTS.md`, `tools/sim/shocks/`), limited to what the lived clock needs now:
  - hunger (a failed harvest or a long winter against stores);
  - fever (crowding, contact and trade links, including the "strangers' sickness" after first contact);
  - a drought run of several years.
- **Rules:**
  - Hazards are read from real state. No calendar schedule.
  - Each shock opens with an omen or petition in the court, a crisis matter with 2–4 real levers (ration, move camp, send the sick away, beg or raid a neighbour, a rite), a mid-crisis report and an aftermath line.
  - Survivors are named and the dead are counted.
- **The loop that already fires:** `The Land Is Thinning` escalates into a "move the camp or clear new ground" decision after its second notice instead of repeating every 120 days.
- **Files:**
  - new `scripts/shock_system.gd`, fed by `local_terrain._commit_world_day`
  - `food_system.gd:780–806` (the existing drought and winter rolls become the hunger trigger)
  - `chronicle.gd`
  - `audience_hall.gd` (a `crisis` matter)
  - `court_lives.gd` (the named dead)
  - `consequence_engine.gd`
- **Measurable proxy (`long_run.py`):**
  - at least 2 moments per game year in every decade to year 50;
  - no stretch of more than 3 game years without a moment that carries a decision;
  - each shock kind within the per-century hazard bands of `EPOCHAL_SHIFTS.md` §9.
- **Playtest:** after two real hours, the player retells "the hungry winter" or "the fever from the east" without being prompted.

### 2. Make refusals bite: raids and war in the player's own world, run by a general (L)
- **Problem:** There were 0 wars and 20 toothless demands in 16 years. "Defy" is always right, and the General Campaign exists only as a separate authored world.
- **Fix:**
  - A refused demand from a ruler who is **not** bluffing (their tells absent, their strength real) leads, within 60–240 days, to a raid on stores or a hunting ground, told in the Chronicle with named losses.
  - A second refusal, or a grudge above a threshold, lets `civilization_strategy.diplomatic_action` actually choose `declare_war` against the player.
  - When war starts, the player's war leader is summoned to the fire (a new `war` matter). The god gives the objective in conversation. The conversation → validated objective → movement and battle → unsolicited report loop from `general_campaign.gd` then runs **in the current world**, not in the Alderford restart.
  - Bluffs stay common, but the player can no longer assume them.
- **Scope:** keep the general-led rules (`docs/GENERAL_CAMPAIGN_DESIGN.md`): no cohort control, no logistics forms.
- **Files:**
  - `civilization_strategy.gd:83–90`
  - `rival_rulers.gd` (follow-through)
  - `audience_hall.gd` (the tribute outcome and a `war` matter)
  - `general_campaign.gd` (a `start_in_world(enemy)` entry that skips `launch()`/`_restart_world`)
  - `military_campaign.gd`
  - `chronicle.gd`
- **Measurable proxy:**
  - across 6 seeds × 30 years, at least one raid in 5/6 runs and at least one war in 2–4/6;
  - the share of refused demands followed by harm within a year is 25–50% (currently 0%);
  - in the heuristic policy, the "pay" choice is right at least 20% of the time.
- **Playtest:** the player hesitates over a tribute demand, and can say why.

### 3. Explain the dwindling, and give the god a lever (M)
- **Problem:** Every run loses about 1% a year while well fed (120 → 85–98 by years 19–27). LIVES halves in year 1. Aims become "Be 120 Souls Again" and fail anyway.
- **Fix:**
  1. **Diagnose.** Compare the real engine's year-0–30 CBR, CDR and e0 with the research-600 surrogate for the same seed and focus. `PHASE3_BALANCE.md` already flags the gap. Either bring small-band fertility or mortality into the calibrated 0.3–0.8% growth band, or keep the decline and make it a story.
  2. **Tell the cause.** The Hearth Chief's first-winter and yearly lines name the real driver: "more cradles are empty than graves are filled", "the fever took the small ones", "the young women marry late".
  3. **Levers that work.** `aim_press` on a population aim and typed orders like "care for the mothers" must move the relevant rates measurably within bounds.
- **Files:**
  - `population_system`/`early_life_conditions.gd`
  - `hearth_count.gd`
  - `legacy_aims.gd` (a lever for `aim_press`)
  - `custom_directive.gd`
  - `scripts/hud/era_words.gd`
- **Measurable proxy:**
  - the median growth over years 0–30 across 6 seeds lies inside the benchmark band;
  - when the population falls for 3 or more years running, a Chronicle line names the cause within 1 game year;
  - "Be N Souls Again" is fulfilled in at least 1 of 3 attempts when pressed.
- **Playtest:** asked why the people are fewer, the player gives a reason the game told them.

### 4. Aims that can be won, and that know about each other (M)
- **Problem:** 2 of 29 player aims fulfilled, both after year 19, against 18 rival wins. Contradictory aims pass without comment. A rival's win arrives as a notice after the player unknowingly helped it.
- **Fix:**
  - Tune `legacy_aims.gd` so that the first aim a court proposes is fulfilled in 50–70% of plausible play. Drop "Found a Daughter Hearth" when the band is shrinking.
  - Detect clashes between a "fear our name" aim and a live marriage, pact or tribute with the same people. The court voices the tension at proposal time ("You would have the Telmar fear us, and Hobb married among them?"), and the option says so.
  - Foreshadow rival aims when an action counts toward them. For example, repaying the Nine Fires' gift-loan is marked: "Oskel will call this yielding."
  - Deduplicate the "Hear their other matter" option.
- **Files:**
  - `legacy_aims.gd` (`propose`, the clash check, `rival_*` hooks)
  - `legacy_aims_lines.gd`
  - `rival_rulers.gd`
  - `audience_hall.gd`
- **Measurable proxy:**
  - 6 seeds × 30 years: at least 1 player aim fulfilled in every run, and fulfilled:failed:released of about 2:1:1;
  - no adopted aim contradicts a live treaty or marriage without a clash line in the log;
  - each rival aim fulfilment is preceded by at least 1 warning line.
- **Playtest:** the player can name a legacy their people won.

### 5. One Chronicle, no dashboard (S)
- **Problem:** The coordinator's list is verified (item 7 of the evidence). Two notification systems stack, and developer strings leak into the player's feed.
- **Fix:**
  - Retire the old EXPEDITION RETURNED and RESEARCH toasts. Route them through `chronicle.gd` tiers, fold discoveries into the seasonal digest, and give an expedition's return a Chronicle card.
  - Change the top bar to era words for temperature ("a hard frost", "warm"), or °C only after counting.
  - Move the babes line under LIVES without overlapping LORE.
  - The bottom bar shows the scouting party in words ("two walkers out") and hides "SITE 20 M".
  - The distance selector names the real height, or uses words ("close", "the valley", "the region").
  - Fix `known_world_board.gd:873` "the The".
  - Scrub developer strings ("not global tracking", "polity", "a expedition", "value-conserved exchange").
  - Gate the metal lexicon in Materials by era.
- **Files:**
  - `hud/command_rail_hud.gd`
  - `hud/era_words.gd`
  - `local_terrain.gd` (actions bar, `CAMERA_DISTANCE_LEVELS` labels)
  - `hud/research_announcements.gd`
  - `hud/scout_return_notice.gd`
  - `hud/known_world_board.gd`
  - `chronicle.gd`
  - `civilization_system.gd` (scout sighting text)
- **Measurable proxy:**
  - `ui_measure`: 0 modern or lexicon hits at years 1, 5, 10 and 25;
  - one card stack on screen;
  - a regex over 30 years of the feed finds 0 of `polity|global tracking|a expedition|value-conserved`.
- **Playtest:** a first-time player never asks which of two notification piles to read.

### 6. Envoys with more than one shape (M)
- **Problem:** The same opening gift in 6 of 6 seeds. Four proposal shapes rotate with one triad. The artifact names read as loot. There are coins in the stone age. A one-neighbour seed gets 0 decisions a year.
- **Fix:**
  - Draw envoy business from each ruler's live character and history (`rival_character()`): a marriage request, a plea for help in their famine (ties into item 1), a quarrel between two neighbours you are asked to judge, a feast invitation, a defector seeking refuge, a stolen-child accusation.
  - The first envoy varies by the ruler's trait.
  - Give artifacts era-voiced names without rarity tags, such as "the fold-guarded blade Kolv's grandmother carried".
  - Gate coin behind the known practice.
  - When only one people is in reach, the Chief Scout finds the second group's signs (the regional-group rule from wave 1) within 5 years.
- **Files:**
  - `audience_hall.gd`
  - `envoy_*`/`rival_rulers.gd`
  - `artifact_culture.gd` / `artifact_collection.gd` (names)
  - `society_exchange.gd` (the coin gate)
  - `civilization_start.gd` (the reachable second neighbour)
- **Measurable proxy:**
  - over 30 years, no single envoy shape is more than 25% of audiences;
  - the first envoy differs in at least 4 of 6 seeds;
  - every seed reaches at least 2 decisions a game year in decades 2–3;
  - 0 "coin" before coinage is known.
- **Playtest:** the player looks forward to the next envoy and reads its facts.

### 7. Let people live long enough to love, and name them for their world (M)
- **Problem:** Chiefs die at 36–54, with three chiefs in three years. Succession passes silently when the Court is not visited. Wishes are refiled 15 times. Children get modern names of the other sex.
- **Fix:**
  - Protect officeholders' survival within the benchmark bands (adult e0 conditional on reaching 15 is about 50–55, not the birth e0). Hearth Chiefs should average 10+ years in office.
  - A death with no summons within 30 days becomes an unbidden mourning audience the first time for each office. This is a narrow exception to player-initiated court, because the dead chief's kin come to the god.
  - A refiled wish must escalate (the official grows bitter, leaves, or acts on their own) or stop.
  - Name children through `era_names.gd` with the child's sex and the family's tradition. Replace the modern surnames in the first-winter beat ("the Qureshi grandmother") with era names ("the grandmother of Reed hearth").
- **Files:**
  - `government_people_system.gd`
  - `court_lives.gd` and `court_lives_lines.gd`
  - `era_names.gd` (children, hearths)
  - `opening_arc.gd` (first-winter family)
  - `audience_director.gd`
- **Measurable proxy:**
  - median Hearth Chief tenure of at least 8 years over 30 years × 6 seeds;
  - 0 modern given or family names from `historical_name_generator` pools in the court and the feed;
  - 0 sex-mismatched child names;
  - no official wish filed more than 3 times.
- **Playtest:** at year 30 the player names a chief who served long and grieves them.

### 8. Give the god acts that matter mid-game: great works and miracles with consequences (M)
- **Problem:** No Great Work in any run. Typed monuments do not start one. Miracles are identical. Orders quote themselves in five frames.
- **Fix:**
  - A wonder pitch becomes an unbidden moment when the court is idle, not a lapsing matter.
  - Typed orders that name a monument, temple, ring or mound route to `GreatWorks.concept_from_words` and open the commissioning scene.
  - Miracles differ by kind. Rain rites wait for the next real rain (the omen system from wave 1), and a failed miracle leaves a mark: dread up, or a doubter at court.
  - Replace the quote-back frames with personality-keyed paraphrase in at least 60% of replies, and vary the duration by order.
- **Files:**
  - `custom_directive.gd`
  - `divine_reply.gd`
  - `great_works_audience.gd`
  - `wonder_concept.gd`
  - `audience_director.gd`
- **Measurable proxy:**
  - `universal_order_probe`: no frame in more than 15% of replies, and fewer than 50% at exactly 180 days;
  - miracles produce at least 3 distinct effect sets;
  - over 30 years × 6 seeds, at least one Great Work commissioned in at least 3 runs under the plausible-player policy (extend the harness to answer `wonder_proposal`).
- **Playtest:** the player builds something and goes to look at it on the map.

### 9. Discoveries as turning points, not a feed (S–M)
- **Problem:** 3–5 practices a year arrive as whispers and digests. None changes what the player sees or does.
- **Fix:**
  - Mark at most one discovery per 5–10 years as a turning point (pottery, planting, the first metal, writing), each with a scene, a visible change on the map and a new court voice or option.
  - Fold the rest into the seasonal digest with their plain-words effect ("stores keep a month longer").
  - Retire the RESEARCH toast (item 5).
- **Files:**
  - `chronicle.gd`
  - `hud/research_announcements.gd`
  - `discovery_system.gd` (turning-point flags)
  - `opening_arc.gd` (the scene format)
- **Measurable proxy:**
  - 1–2 turning points per decade;
  - the digest line always states an effect;
  - "What the X taught" is at most 20% of Chronicle titles.
- **Playtest:** the player remembers when their people learned to make pots.

### 10. Different lands, different openings (M)
- **Problem:** 15 of 18 seeds start in open grassland, and the first decade follows one script.
- **Fix:**
  - Let the founding site draw from coast, river valley, hill, marsh and dry country, weighted to where early peoples actually lived.
  - Vary the opening beats with biome and neighbours: a fishing people's first storm, a dry country's failing spring, a hill people's first raid from below.
  - "Found a Daughter Hearth" is not always the first aim.
- **Files:**
  - `civilization_start.gd` / `local_terrain` founding site choice
  - `opening_arc.gd`
  - `legacy_aims.gd` (biome-weighted proposals)
- **Measurable proxy:**
  - 20 seeds cover at least 4 biomes, with none above 40%;
  - the first aim differs in at least 4 of 6 seeds.
- **Playtest:** two new games in a row feel like different peoples.

## Signature moments for hours 2–5

Each is built from items 1–4 and from existing systems. Nothing is faked.

1. **The Hungry Winter (year 8–20).** A real failed harvest against thin stores.
   - The Hearth Chief petitions the god with three levers: cut rations, send the young to the Keshan, or raid the Nine Fires' cache.
   - A named child's survival is at stake, and the neighbour's answer depends on the debts and grudges already on file.
   - Spring brings a tally of the dead by name, and an aim: "No Child Hungry for Seven Winters".
2. **The Demand That Was Not a Bluff (year 10–25).** A ruler with no tells asks for tribute.
   - If refused, a raid takes the stores and a named hunter dies.
   - The war leader is summoned to the fire and proposes an objective. The god speaks, and the general marches and reports back, unbidden, from the field. The first war in the player's own world.
3. **The Strangers' Sickness (after first contact, year 5–30).** Fever arrives along the trade path from the people you welcomed.
   - The court divides: send the sick away, close the path, or pray.
   - It ends with a remembered healer, a quarantine custom learned, and a neighbour who blames you.
4. **The Daughter Hearth Departs (year 15–40).** When the band can finally spare them, the young leave under a named founder.
   - A caravan crosses the map. The Chronicle and the Known World gain a new fire, and the first legacy is won.
   - Twenty years later the daughter hearth's chief comes to court with their own demands.
5. **The Stone That Outlives Them (year 20–50).** The god answers a wonder pitch (or types one), and the work is raised through setbacks: an accident, a strike, a rival's envy.
   - The dedication is attended at the site.
   - A generation later a rival's envoy speaks of it: "Even at our fires they talk of your stone ring."

## Harness additions in this branch

- `tests/fun_audit/fun_playtest.gd` now logs the founding biome, yearly wars, treaties, peoples met, great works and soldiers, and UI marks at years 50, 75 and 100.
- `tests/fun_audit/long_run.py` gives decade pacing, repetition and templates.
- **Next harness step:** answer `wonder_proposal`, `mourning` and `great_work` matters with a plausible policy, and type a few orders per decade.
