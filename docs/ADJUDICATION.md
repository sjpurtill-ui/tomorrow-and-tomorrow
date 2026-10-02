# Adjudication: a statistically consequential RPG

The user's pillar: "Like DND but with statistical structure. That's the WHOLE POINT!"

The engine is the referee and the model is the storyteller. Orders have real,
lasting consequences decided by rules and odds from one consistent world state.
The AI never decides an outcome, never invents a number and never contradicts the
state.

## One state

- Every consequential quantity lives in one ledger that every system reads and
  writes. Examples: a held town's people by group and status (free, bound,
  hostage, worker, conscript, fled with destination, killed, captive on the road,
  arrived among us, freed); forces; stores; opinion, dread and grudges.
- Never keep a parallel counter "for the report" or "for the court". Reports,
  map cards, the order reader's world brief and the officials' fact sheets all
  read the same ledger.
- Counts add up: the ledger before, plus or minus the reported changes, equals
  the ledger after. Tests assert this for every order that changes it.
- Who holds a town is one reading too (town_ledger.hold / holds): the region
  says whose it is, and it is held only while a garrison of ours stands in
  it. The order path, the fact sheets, the reader's brief, the map, the
  held-town report, the chase and the garrison's measures all ask it; none
  keeps its own test of a garrison or a controller.
- Only a held town has anyone under our guard. Where no garrison stands, those
  we held go free (or scatter from a ruin we burned), reconciled on load, on
  the first read and each day, and said once through the war leader.
- When the live voice is off or fails, a factual question is answered from the
  same fact sheet (court_answers.gd), never with a stock line claiming not to
  know; the footer says in plain words why the line was offline.

## Every order, the same path

1. **Intent.** The order reader (scripts/order_reader.gd) or the offline reader
   turns the words into a structured order with ids from the provided lists.
2. **Validity against state.** Who can do it, with how many, over how long, and
   what physically prevents it. Bound men cannot flee. The dead stay dead. A
   garrison of 17 cannot guard 400.
3. **Odds from stated stats.** Numbers, skill, loyalty, dread, supply, terrain,
   era and resistance set the chance. Keep the odds within historical outcome
   ranges.
4. **A seeded roll.** The roll is reproducible from the save, and viewing a
   record never rolls again.
5. **Bounded outcome and state update,** through the ledger.
6. **Report with exact numbers and how it was decided,** in plain words, e.g.
   "Seventeen guards against 38 bound men: none could run. All 38 were killed."
   or "Nine went after six men in their own hills: a poor chance, about 1 in 4.
   Two were caught."
7. **Narration.** The voice receives the result and the speaker's fact sheet and
   only tells what happened.

## Consequences persist and compound

Memory, dread, grudges, reputation, legitimacy, cohesion, later incidents, and
costs in food, time and guard load all persist. A harsh act is remembered by the
people it struck, by their neighbours and by the officer who carried it out.

Grave orders against the god's own people ("kill all women in the village",
"burn our own village", "drive out the old") are adjudicated the same way
(scripts/grave_home.gd): the one ordered may obey, plead or refuse; each hand
may refuse or flee; each person named is caught on stated odds, a few days'
work at most; the dead and the fled come off the population model by group
and sex, in that town's own count, and births fall while the women are fewer.
"The village" is asked about when a town we hold, or a war, makes it unclear.

## Officials know their office

Each official answers from an exact fact sheet for their office
(scripts/court_facts.gd):

- **War leader:** bands, garrisons, and every held town's ledger.
- **Headman:** stores, food days, water, housing, sickness and work.
- **Keeper of Tribute:** tribute and trade.

When the facts are listed, an official states them. When a fact really is not
known to them, they say who would know or what would find out. They never
invent ignorance or an excuse.

## Honest words

- Never say an order is or will be carried out unless a mechanic did it or has
  queued it. When nothing is set in motion, say so and say what it would need.
- Every order the god gives, from the court or any screen, gets a card at the
  bottom right (scripts/order_tracker.gd, hud/order_stack.gd) that reads its
  state from the ledger itself (order_probes.gd). An order no mechanic took,
  or that nothing in the ledger moved by the end of the next game day, turns
  red: "Nothing has happened yet", with the engine's reason. A new order
  screen registers its orders there.
- An unclear grave order (kill, maim, burn, march to war, abandon a town) gets
  one specific question with options; a second unclear reply is acted on by the
  speaker's nearest reading, never the same question again.

## Tests for any new order or consequence

- Exact user wording on both the live-reader path (stubbed HTTP) and the offline path.
- Ledger consistency before and after.
- The odds, the roll and the bounds, including the historical range.
- The reported numbers match the state.
- The voice's prompt contains the facts it needs.
