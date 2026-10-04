# Standing: what we are, how others see us, how our own feel

The player, 2026-09-28: "Allure, Awe, Fear, Respect (not love, love is from YOUR
OWN PEOPLE), Resentment, Trust. ... Genius, Might, deception, persuasiveness:
these are things you earn that are YOUR OWN skills. ... One can go all in on
any, but there will be terrible consequences if the balance is too far.
Ultimately, the game needs to be harder, and in the hands of computer
management, it needs to be smarter. ... Think through to the year 3500."

Three layers, one ledger:

1. **Strengths**: what a people *is and can do*. Earned, never granted: each
   is read from the real state (soldiers, scholars, stores, works, envoys...).
2. **Views**: what *another* people feels about us. Held by the observer,
   built from our strengths *as they know them* (contact, news, dated) and from
   memories of our *deeds* toward them.
3. **Feelings at home**: Love and Dread of the god (divine_regard.gd), Pride,
   Trust in the leaders and Resentment.

Everything follows docs/ADJUDICATION.md: numbers come from the engine, a view
never contradicts the state, and every effect has a named cause the player can
read ("they hold back because they have seen our warbands and the Ring").

## 1. Strengths (derived each month; nothing new is stored)

Each strength is a score 0..1 against the peoples of the same age (section
10): 0.5 is the typical people of the age, 0.8 what its best-documented
peoples did, 1.0 the most the age has plausibly seen, on a log scale between
(so a village is not "weak" for lacking an army of an empire, and no hoard
of one thing fills a strength). An absolute size (fighting strength) is used
when two peoples are compared. All are computed in `scripts/standing.gd`
from state that already exists.

| Strength | Read from (existing state) | Costs the people |
|---|---|---|
| **Might** | fielded soldiers, trainees and recruits × readiness × command × era arms (`CivilizationSystem._player_military_power`), walls and garrisons | people out of the fields; food and arms |
| **Genius** | known discoveries against the age and against neighbours; scholars (Knowledge workers) and learning pace; educated share | people on research; food for them |
| **Persuasion** | envoys and their skill, shared tongue and rites with others, gifts given, treaties made, openness of values | goods given; envoys' time |
| **Cunning** | spies and scouts abroad, secrets kept and taken (intelligence reports, city observations), deceptions carried off | spies' lives; Trust if caught |
| **Wealth** | food and goods per head in store, trade flows, output per worker | nothing by itself; it draws Envy |
| **Splendor** | standing great works (outcome × condition × ambition), treasures held, festivals and rites, fine towns (construction era) | builders, materials, years |
| **Order** | legitimacy, working offices, fair judgments, kept word (promises and ultimatums kept), low crime and resistance | administrators; restraint |
| **Endurance** | days of food and water in store, health, walls, cohesion: how long the people can be starved or besieged before breaking | stores and builders |
| **Reach** | roads, carriers, boats, messengers, maps; how many peoples know of us and how fast word travels | carriers and boats |

Faith is not separate: rites and the god's signs feed Splendor (outward) and
Love (inward). The player is the god.

## 2. Views: held by each other people toward us

Stored where the game already keeps them, never twice:

| View | Stored in (existing) | Derived part (from our strengths, as they know them) | Memory part (our deeds toward them) |
|---|---|---|---|
| **Allure** | derived (artifact_culture.gd `allure_report` stays the culture half) | Wealth, Splendor, Genius (learning), Order (fair rule), openness; *minus menace*: our Might × our aggression toward others | gifts, refuge given, marriages, trade kept |
| **Awe** | new per-people memory beside `civ_dread` | Might relative to theirs, Splendor they have heard of (`heard_by`), Genius lead they can see, sheer size | victories they saw, dedications attended, answered omens, feats |
| **Fear** | `civ_dread` (divine_regard.gd, 180-day half-life) | our Might near them × our hostility | harm to them or their kin: raids, razing, massacres, harmed envoys |
| **Respect** | SocietyExchange connection `respect` | Order, competence (works that stand, defense held, disputes judged) | kept ultimatums, fair trades, mediation; *minus* defeats, follies, bluffs called |
| **Trust** | foreign leader trust / treaties (ForeignDiplomacy) | Order (kept word at home) | treaties honoured, debts repaid, captives returned; broken word collapses it |
| **Resentment** | SocietyExchange `resentment` + rival_rulers grudges | occupation of their kin, stolen treasures | raids, humiliations, broken promises; inherited by their heirs |

Two **dangers** are not stored; the game reads them from the views:

- **Envy** = what they see of our Wealth and Splendor × (1 − Awe) × (1 − Trust/2).
  Rich and weak is what gets raided.
- **Contempt** = the low end of Respect when our Might and Endurance look small
  beside theirs: tests of resolve, insults, tribute demands.

Views move toward their derived part over months (news is slow) and memories
fade with the age (see section 6). A people that has never met us holds no view.

## 3. What views make others do (the consequences)

| Decision (where) | Reads | Effect |
|---|---|---|
| declare war on us (civilization_strategy `diplomatic_action`) | Resentment, Envy, Contempt raise the urge; Awe, Fear, Trust and our Might lower it | replaces the fixed "opinion below war_opinion" test and the great-works deterrence term |
| raid, feud follow-through (war_loop `ratio`, `on_refusal`) | their Might over **our Might** (not our head-count); Envy; Fear | a well-guarded people is raided less; a rich, unguarded one more |
| tribute and tests (court_lives, audience hall) | Fear and Awe → tribute, avoid; Contempt → tests and demands | as today, fed by the views |
| leagues against us (DiplomaticCommitments factions) | Fear held by two or more peoples at once | the mighty and cruel are ganged up on |
| migration, recruits, wandering bands (SocietyExchange `attraction`) | Allure (ours against theirs) | people come to the alluring; flee the feared |
| trade and loans (trade pacts, envoy requests) | Trust × Allure | terms and willingness |
| envoy business mix | all views | trade offers from Trust, pleas from Allure, redress from Resentment |

## 4. Feelings at home

- **Pride** (new, derived): Splendor, Awe and Allure the world holds of us,
  victories and fulfilled aims. Pride keeps people through hard years (lower
  flight and emigration), lifts cohesion and legitimacy targets a little, and
  softens the loss of legitimacy from failures and harsh orders (forgiveness).
- **Trust in leaders** = legitimacy (existing). **Resentment** = directive
  resistance, grievances and officials' resentment (existing).
- **Love and Dread** of the god: divine_regard.gd (existing), untouched.

## 5. Balance: every posture pays and costs

Strengths cost people, so a posture is a choice of who does what:

| All in on | Wins | Terrible if too far |
|---|---|---|
| Research (Genius) | discoveries early (research is never walled: every 5 years ahead of its age adds its work again); Awe and Respect from what others cannot do; knowledge to trade | fields short and scholars hungry; no Might → Envy and Contempt: raids, captured scholars, tribute demanded |
| Might | Awe and Fear: tribute, no raids, wars won | Allure collapses (no migrants, no traders); conscripts resent; neighbours league; fields short; learning stalls |
| Great works (Splendor) | Awe, Allure, Pride; works' rewards | hunger in building years; forced-labour Resentment; follies; a golden town without walls draws Envy |
| Food (Wealth, Endurance) | many people, plenty draws refugees | little Might or Genius: Contempt; worn land; sickness in crowds |
| Balanced | steady | nothing dominant |

Diminishing returns on each strength (its score against the age saturates),
accelerating costs of neglect (Envy and Contempt grow as the gap grows).

Targets for the fast sim (tools/sim) across strategies: each lopsided posture
must meet real trouble within decades (raids, famine, flight, leagues), and
the balanced posture must be the steadiest; no strategy dominates every facet.

## 6. Through the ages to year 3500

Game year 0 = 5000 BC, 300 = 3000 BC, 800 = 500 BC, 1500 = AD 1000,
2000 = 1600, 2400 = 1800, 2800 = 1950, 3000 = 2030. The six views keep their
meaning; what changes is where they come from, how far word travels (Reach)
and how long it is remembered.

| Age | Reach and memory | Awe from | Allure from | Fear from | Trust from |
|---|---|---|---|---|---|
| Bands and villages (0-300) | only those who met us; oral: grudges a generation, legends of works longer | rings and mounds, great hunts, numbers | food and safety, marriages | raids, feuds | gifts, marriages |
| Early states (300-800) | writing: treaties and grudges recorded | ziggurats, walls, chariots | cities, temples (pilgrims), scribes | conquest, tribute | sealed treaties |
| Kingdoms and faiths (800-2000) | continental; chronicles keep feuds for centuries | cathedrals, fleets, roads | faith (converts), universities, free towns | conquest, sieges | marriages of houses, alliances |
| Industry (2000-2800) | print and telegraph cross oceans; archives near-permanent | factories, navies, rail | wages and liberty: mass migration | colonial conquest (long Resentment) | credit, treaty systems |
| Modern (2800-3000) | instant, global public opinion | deterrence, space programmes, scale | culture, openness, living standards | weapons that make Fear dominate | alliances, institutions |
| Beyond (3000-3500) | other worlds: news lags again | orbital works, terraforming, starships, mastery of machines and life | long free lives, culture | existential weapons, runaway machines | verification, shared rule; colonies grow Dependent and Resentful |

## 7. Smarter computer management

The Headman's daily work (GovernmentPeopleSystem) and rival rulers use the same
readings: food first; guards and warriors in proportion to the Envy, Contempt
and Resentment neighbours actually hold; then the people's ambition; never
piling everyone into one trade (diminishing returns make it pointless).

Food (2026-09-29): a food worker spends `FoodSystem.FOOD_WORK_SHARE` (0.7) of
the day getting food; the rest carries, grinds, cooks and stores it, as the
historical share of labour on food counts both. Before this, 60% of the people
on food brought in about twice what was eaten, so food never pinched and a
ruler could move a third of the people to research for free. Now:

- planners work out the share of hands food needs from what each hand brings in,
  and plan up to `RESERVE_MARGIN` (15%) more while the stores are short of
  `RESERVE_TARGET_DAYS` (60 days, or what the stores can hold);
- their floor is `FOOD_FLOOR_OF_TYPICAL` (90%) of the era's typical share, so a
  people ahead in farming frees hands and one behind must find more;
- the ruler's own split still has no floor: a lopsided split shows its cost.

Fast-sim reference (tools/sim, 2 seeds, good site): the Headman keeps about 55%
on food with a 40-60% margin, population and discoveries as before; a poor dry
site goes all in on food and holds 25-60 people; research-heavy grows to about
1,500 by year 600 against 3,500 for a balanced people.

## 8. Build order

1. Research without walls (done: a3b70597).
2. `scripts/standing.gd`: strengths and views, with a "why" for each (the
   court's fact sheets and a Standing page read it). Done: 005c716b.
   The Standing page is its own rail tab (the player, 2026-09-28: "THIS IS THE
   HEART OF THE GAME! Should be its own tab!"): `hud/standing_board.gd` draws
   the rose of nine strengths (last year's shape dashed behind it, a known
   people's laid over it), each strength with its reason, its change in a year
   and the place that raises it; the dangers with the engine's own odds
   (`war_loop.envy_raid_chance`, `grudge_raid_chance`, `court_lives.standing_weight`);
   one card per people (six feelings, what they make them do, what they
   remember, a word in the court); and our own pride, love and dread of the
   god, and trust in the chiefs. The monthly reading of all nine strengths is
   kept in `strategic_history` for the years chart.
3. Consequences: war and raid decisions, migration, tribute, leagues, pride.
   Leagues done (fear_league.gd): two or more met peoples holding Fear 0.45+
   (or Awe 0.6+ with Resentment 0.3+) bind together against us; each weighs
   our strength against all of theirs, backs the others' raids and demands
   (x1.5, gifts x0.7) and shares every fresh grudge; they let go below Fear 0.3.
   Pride forgives (Standing.forgiveness); memory grows with writing and print
   (Standing.memory_span).
   Also done: war declarations weigh the target's might (Standing.war_deterrence:
   a stronger target deters, a weak one emboldens); trade terms read allure,
   respect and contempt (trade_pacts._threshold); allure draws newcomers and
   pride keeps them (Standing.attraction_shift, the same for every people);
   pride comes from a people's own renown (Standing.renown), so it is reckoned
   alike for computer and player peoples; a levy past a twentieth of the
   people is resented (Standing.levy_burden); the court's keepers of ties and
   war leader carry the whole reckoning on their fact sheets (court_facts
   _standing) and answer "why do the X raid us?" from it; the rail's Standing
   button counts the peoples moved against us.
4. Headman and rival allocation, then the sim calibration across postures.
   Done for food (section 7) and guards: the Headman adds guards as the
   neighbours press (GovernmentPeopleSystem.neighbour_threat); rivals share
   the planner (section 9).
5. Era scaling of reach and memory to year 3500. Memory done
   (Standing.memory_span: told, written, printed); reach still to come.

## 9. Every people on the same rules

The player, 2026-09-29: "Make sure all players (computer and player) are
perfectly balanced and that all automated leaders are equally balanced though
with varying tendencies." Every people runs the same simulation in its own
WorldSimulation scope; what differs must be tendency, not rules.

- Food and the Headman: one planner for every people (section 7).
- Crises: the god's people meet them at court (crisis_system.gd); every other
  people meets the same ones in its own scope (crisis_unattended.gd): the same
  hazards read from its own state, the same death draws and floors, and the
  court official's own answers when the god is silent, paid from its own
  stores, roofs and labour.
- Feuds: two small simulated neighbours who fall out (war_loop._rival_wars, at
  the benchmark rate) now fight their feud for real (rival_feuds.gd): the same
  bands and combat simulator as raids on the god's people, the dead and the
  stolen food out of both real ledgers, each side remembering it; grudges fade
  between feuds. Big peoples declare their own wars through their leaders.
- Research: capacity from the people at research, emphasis only directs it,
  one budget rule for every ruler (codex/research-parity).
- Leaders: one rule for every decision a computer ruler and the player's own
  leaders both make; only the temper differs (codex/leader-balance). A ruler's
  temper is its personality; the player's leaders take the people's tendency,
  the values they live by (`leader_personality.from_values`, the reading their
  delegated research uses too).
  - Ambitions: every ambition is open to a ruler, by fit to its temper
    (`AMBITION_TEMPER`); arms, dominion, vengeance and trade wait until another
    people is met.
  - Great works: one answer at a work's gates (`civilization_strategy.works_answer`),
    and the crews build on while a question waits (90 days for the god's word,
    2 for a ruler's); grief moves a ruler to build only after a hard year.
  - Land: `expansion_months` (every month for the boldest or an expansionist
    tradition, every third for an even temper, every fifth for the most
    cautious), settling at 45-100 days of stores, 16-40 km out; bold rulers
    send thinner rations (32 days for the new town's first weeks against 57).
  - Food: a people's wish for food work (sustenance fully, wellbeing half) is
    planned as a deeper reserve, up to 120 days with twice the margin.
  - Goodwill carries a real gift from the stores or does not go; a people's
    aggression, diplomacy and adaptability come from its leader's character.

  `python tools/sim/leaders.py` (five archetypes, or `--ambitions`; good and
  poor land; `--shocks`) checks it: over good and poor land together no
  temper is as good as another everywhere by year 600. On good land the
  cautious and caring grow most (about 28,600 people, 1,070 discoveries) but
  raise no great work; the bold raise most works (59) but lose 31 to folly
  and 6.6 settlers for each town; the warlike are mightiest; the scholarly
  live longest but are fewest (15,300). On poor land the sustenance people
  lose 1.9 in 1,000 to hunger each year against 2.3-4.7 (3.3 against 12-20
  through the shocks). The surrogate has no war, conquest, trade or
  exploration, so the warlike and far-ranging tempers show their costs there
  more than their gains.

## 10. Against the age; others as we know them; the arts at work (2026-10-03)

The player, 2026-10-03: "It seems like no matter what you do, I end up always
at 100%... What is the 100% relative to?" and "are cunning and persuasion
truly represented enough in the game?"

Before this, five strengths were absolute and filled easily: Wealth was full
at 45 days of food, Endurance at 60, Order at full trust; Genius compared with
an old, empty list of the others' technologies and read 100% for every
people (a played world at year 75: "463 practices known against 0"); Cunning
affected nothing and Persuasion only moved trust by ten points.

### The yardstick (`scripts/standing_scale.gd`)

Every strength, for every people, reads against the peoples of its age:
20% the low end, **50% the typical people of the age, 80% what its
best-documented peoples did, 100% the most the age has plausibly seen**,
on a log scale between the anchors (each doubling gains about as much as the
one before; shares that cannot pass 1, like trust in the chiefs, are read on
their shortfall). A strength is a weighted blend of its parts, so no hoard of
one thing fills it: 5,000 days of food and nothing else reads Wealth under
55% and Endurance under 80%. Every reason line says what it is compared with
("food for 248 days, about 9 times a typical people of our age (26)").

| Strength | Parts (weight) | Anchors and where they come from |
|---|---|---|
| Might | the share of the whole people ready to fight: warriors x readiness, walls counting each defender for more | benchmarks `defense_labor_share` (% of the able on watch or under arms) x 0.6 able x 0.9 readiness: typical 2.2 in 100 at year 75, the most 8.1 |
| Genius | practices known (0.6), the share at research (0.4) | known: the fast sim's balanced people before 600 (388 at year 75), then benchmarks `discoveries_known` x 1.43 (the engine's pace against the provisional benchmark at 600 and 1,200), spread 0.5 / 1 / 1.28 / 1.47; research: 1 / 3 / 8 / 15 in 100 |
| Wealth | food in store (0.5), materials a head (0.25), made goods a head (0.25) | stores 10 / 30 / 120 / 365 days (the planners' 30-day reserve is typical; 120 the deepest a ruler plans; a year the granary states); materials 0.3 / 1.5 / 6 / 15 and goods 0.5 / 2 / 6 / 12 a head from year 10 (a played world's computer peoples at year 75; a people founds with about 0.2 and 0.1, typical then) |
| Endurance | stores (0.45), water (0.1), walls (0.2), health and holding together (0.125 each) | stores as Wealth; water 0.5 / 3 / 8 / 20 days from year 10 (none at the founding); walls' bonus 0.04 / 0.12 / 0.35 / 0.62 by year 100 |
| Splendor | great works' renown (0.55), the culture's allure (0.25), the realm's fine works (0.2) | renown: nothing is typical to year 100 (most computer peoples had none at 75), 10 by 300, 30 by 600; culture 62% typical from year 50; beauty 0.22 typical at 100 (the fast sim's balanced people) |
| Order | trust in the chiefs (0.35), holding together (0.2), administrators (0.2), the steward (0.25) | trust and cohesion 93% typical from year 25 (played worlds and the sim settle there); administrators 3.5 in 100; an ordinary official (skill 47) typical |
| Reach | carrying and hauling (0.5), peoples met (0.5) | carrying 60% typical from year 25; peoples met 0.5 at 50, 1 at 100, 2 at 300, 3 at 600 |
| Persuasion | who speaks for us (0.3: the envoy once the office is open, the hearth chief before), openness (0.15), familiarity with those we know (0.1), treaties in force and exchanges kept (0.15), gifts given a head a year (0.15), envoy-days abroad (0.15) | in-game: an ordinary speaker, half openness, one or two treaties, few gifts and few missions are typical (computer peoples at year 75: three of twelve gave gifts, one had a mission out) |
| Cunning | the chief scout (0.25), scouts and half the watch a share of the people (0.25), agents abroad (0.15), their spies caught and turned in three years (0.1), how well we know those we know (0.25) | scouts and watch 6 in 100 typical at the founding, 8 from year 25 (computer peoples 6.4-11.8 at year 75); agents and catches: none is typical, each more lifts it; knowledge (contact_intelligence) 0.22 typical |

Every people's month records its nine readings (`standing_<id>`) and the day
(`standing_day`); the history rows carry `standing_scale` 2, so a year's
change is never read across the old absolute scale.

Played world at year 75 (the player's save, before and after): Might 27 -> 33,
Endurance 98 -> 78, Wealth 84 -> 76, Reach 54 -> 63, Persuasion 25 -> 44,
Splendor 41 -> 44, Genius 100 -> 68, Cunning 73 -> 58, Order 91 -> 70. The
twelve computer peoples read 40-75 on most strengths, but 89-100 on Might:
they keep 6-10% of all their people under arms at readiness 0.91-0.97, at
the historical maximum (11-16% of the able).

### Other peoples, as we know them

Another people's strengths are its own month's reading (its own
`simulation_metrics`, recorded in its own scope; reckoned again in its scope,
read only, when older than 45 days). We see them through an estimate:
certainty = our relation's `contact_intelligence` (0.2 at a first meeting, up
to 0.95), at least 0.75 with an agent of ours among them, and our cunning
(30 points either way). The band is 40 points x (1 - certainty) either way;
our watchers get a reading right at all on certainty x 0.6 + (cunning - 0.5)
x 0.4, else it is off by up to the band (seeded; one estimate a season).
Below certainty 0.1 we say "unknown", never 0. The Standing rose draws every
known people beside ours (a fine line, dashed where it is an estimate); the
one chosen is drawn stronger with its band shaded. The people cards, the court's
fact sheets and the War Ledger give their fighting strength the same way.
Genius names the most learned people we know with their real
`known_discoveries` through this estimate.

### The arts at work (one rule for every people, stated on the Standing page)

| Cunning | Typical (0.5) | Best (1.0) |
|---|---|---|
| Raids seen coming (war_loop `_foresee`; the watch keeps the approaches and meets them at x1.35 ground) | 50 in 100, 18 days ahead | 90 in 100, 30 days |
| Raids between other peoples seen by the defenders (rival_feuds) | the same | the same |
| An arming people heard of at once (world_answer); else only in its last month | 50 in 100 | 90 in 100 |
| An envoy's bluff shows its tells / a real threat its signs / a misleading tell (rival_rulers `_bluff`) | 85 / 70 / 15 in 100 (as before) | 98 / 95 / 2 |
| Our covert operations' odds, and of being caught (covert_ops odds) | +0 | +10 / -10 points |
| Their spies caught (covert_ops `_catch_chance`) | +0 | +15 points |
| A scout's or spy's look at a town (city_intelligence capture): quality, error band | +0, x1 | +0.1, x0.85 |

| Persuasion | Typical (0.5) | Best (1.0) |
|---|---|---|
| Envoys' deals: how freely their ruler pays (envoy_deals temper), and takes our counter (odds) | +0 | +0.1 temper, +10 points |
| A message sent home with a captured agent heeded (captured_agents message_odds) | +0 | +10 points |
| Failed portions an exchange bears before it is ended (trade_pacts misses_borne) | 3 | 5 (1 at none) |
| A treaty between two peoples breaks when regard falls below (civilization_system) | 0.04 | -0.02 for two of the best |
| Families drawn to settle with us (society_exchange attraction) | +0 | +3 points a month |
| A new grudge against us weighs (rival_rulers grudge) | x1 | x0.8 (x1.2 at none) |
| Their rulers' trust in our word (view_of) | +0 | +10 points |

Fed by real ledgers: covert ops in place, spies caught and prisoners turned
(the god's own, or for another people its spies among us and ours it holds),
the trade ledger's gifts, CivilizationSystem diplomatic missions and lent
hands, treaties in force and kept exchanges, the offices' skills. The costs
are theirs: scouts and the watch are hands off other work, agents and envoys
are people abroad, gifts leave the stores.

### Views read the new scale

Renown and pride are centred on the typical people of the age (awe 0.25,
allure 0.25, pride 0.5 for a people at 50% everywhere): a typical people is
neither proud nor ashamed, where before every people drifted proud as
splendour filled. Envy weighs our plenty and how far it passes theirs (their
own month's Wealth). Might past 50% menaces newcomers (5.6 points a month at
85%) and, at a tense border, the neighbours' allure. The computer peoples'
"tempting" danger (wealth past might by 0.35) reads the new scale.

### Fast sim (`python tools/sim/standing_check.py`)

Every people-first path and a lean of each strength the paths leave alone,
read through `tools/sim/standing.py` (docs/research/SURROGATE_SIM.md has the
table). By year 300 the balanced path reads 41-66 everywhere; war lifts Might
to 93, learning Genius to 91 at year 25 and 65 by 300, building Splendor to
71, the arts' postures Cunning to 73 and Persuasion to 83, administration
Order to 70, carriers Reach to 79; nothing reaches 97 off its own lean.
Endurance past 70 needs 100 days and more in store. In the raid world the
same raids met with cunning lose 39% fewer stores (at 5% fewer people by
600, the hands on scouting), and persuasion draws 16% fewer raids (at the
gifts' cost).
