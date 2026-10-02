# The world answers the god

What a people remembers of the god, and what it finally does about it. The code is in `scripts/deeds.gd` and `scripts/world_answer.gd`. Read `docs/ADJUDICATION.md` and `docs/STANDING_DESIGN.md` first: these rules sit on the same single record (the ledger) and on the same views of us.

## Why

In the year-228 Ashley Springs campaign, 10 envoys were killed and 3 towns were taken. The world answered with the same loop about 30 times: the feud flared, about 20 raiders came, then the feud was settled or went cold. The people "spoke of the god warmly and without fear" in every one of 228 years.

Memory was measured in months. Rival dread halved every 180 game days, and our people's talk of the god's wrath halved every 90. At the fastest speed that is 15–30 real seconds. Nothing added up, so nothing ever reached a threshold.

## Deeds (`deeds.gd`): told for a generation

One record of what the god did to whom, saved in `ForeignDiplomacy.audiences.deeds`.

**How deeds fade.**
- Half-life is a generation: 25 years. It is twice that for a people that writes and three times for one that prints (`standing.memory_span`).
- Weights combine like chances, `1-(1-a)(1-b)…`, so many small deeds build a reputation and no single deed fills it.
- Amends (a blood price, a hostage sent home) carry negative resentment.

**Weights (fear, resentment).**

| Deed | Fear | Resentment |
|---|---|---|
| Envoy killed | 0.10 | 0.15 |
| Town taken | 0.12 | 0.18 |
| Town burned | 0.16 | 0.22 |
| Hostage killed | 0.15 | 0.40 |
| Massacre, per head (cap 0.45 / 0.55) | 0.01 | 0.012 |
| Violation, per head (cap 0.2 / 0.45) | 0.004 | 0.012 |
| Feud and war dead | per head | per head |
| Captives | once per party | once per party |

**At home.** The god's acts in the hall become dread and love. A god with nothing told is neutral, so parity with computer peoples holds.

**Word travels.** Every people we know fears us 0.3 as much for what we did to a neighbour. Only the wronged people resents it.

**Who reads deeds.**
- Fear: `court_lives.rival_dread`.
- Resentment: `standing.view_of`.
- Our people's dread and love: `divine_regard.people_regard`.
- The home month, through `standing.god_effects`: love draws families in, binds them and lends the chiefs' word weight; dread drives families off, frays them past 0.15, and makes them obey.
- The Standing page, court facts and the War screen.

**Who writes deeds.**
- `divine_regard._record_event`. An act on an envoy or hostage is told once, and the court's own record of it is skipped.
- `war_loop._tally` and `_exhaust`.
- `town_fate`.
- A monthly look at towns taken or burned and at captive parties (`occupation_transfers`, by id).

Older saves seed the record from the god's 24 most recent acts. Readings are cached for a day and refreshed when a new deed is recorded.

**Feuds stay settled.** A settled feud (`war_loop._end_feud`) settles every envoy wrong from before it. `rival_rulers._war_preparation` respects `keeps_peace`. Together these end the re-fire loop.

## Answers (`world_answer.gd`): how a feud ends

Once a month (from `war_loop.daily`, after the fear league), every people we know that is free to answer makes one seeded roll against two stated chances. The odds and reasons are shown on the Standing page.

**Bow** (the first chance, capped at 0.08 a month).
- Conditions: fear ≥ 0.4 and our strength ≥ 1.3× theirs.
- The chance is `(fear-0.4)·0.3 · outmatched · (1.3-boldness)`, higher if they have lost towns, lower for a grudge-holding ruler, and adjusted by their ruler's vow.
- An envoy comes through any feud. Options:
  - Accept.
  - Ask twice as much, at stated odds.
  - Refuse, after which they don't offer again for 3 years.
- Accepted, they become **tributaries**:
  - one tribute agreement in the trade ledger (`trade_stances._begin_tribute`, sized by `tribute_size`, collected each season in goods);
  - a tributary bond;
  - `keeps_peace`;
  - a hostage who is a court person (`court_persons.gd`): the god can summon him by name, keep him, send him home or put him to death.
- Each yearly reckoning, they keep paying while fear ≥ 0.25, our strength ≥ theirs, their goods last, and we haven't refused them protection in the last year. Otherwise they withhold and the bond breaks.

**Protection.** When a tributary's neighbour raids it, it calls on us as kin do (`kin_call` → `war_support`).
- Standing with it sends our fighters, as for kin.
- Staying out is remembered, and they withhold at the next reckoning.

**Everything they have** (the second chance, capped at 0.06 a month).
- Conditions: resentment ≥ 0.45, our strength ≤ 1.5× theirs (counting their whole league), worn < 0.4, not bound to peace, and they know a road to us.
- First a season of arming, 60–120 days. Their own planner reads it as war (`civilization_controller`) and raises spears, and the Chronicle and War screen warn of it.
- Then every free fighter marches as one band on our town nearest them (`war_council._launch` with `all`). Every league member that is free to come sends its own band.
- A people organised for war (`conflict_scale`) declares war instead.
- Afterwards they wait 5 years before their next answer. A normal answer waits 2.

**Vows** (`legacy_aims` rival vows).
- A vow to make us yield: bow chance ×0.6, all-in chance ×1.3. If they bow, the vow is told as having come to nothing.
- A vow to bind us in friendship: all-in chance ×0.4.

**The god can demand it.** "Bow to us" is among the envoy's demands (`envoy_messages`), answered at the menace system's own odds. It weighs 0.32, just above asking for a hostage.

## Not yet

- Computer peoples don't conquer each other or kill each other's envoys, so they rarely fear one another enough to bow.
- A frightened people abandoning its nearest town ("flight") is deferred: each people's towns belong to its own local simulation.
- There is no typed court route yet for "make the Kezari bow"; the envoy compose screen has it.
