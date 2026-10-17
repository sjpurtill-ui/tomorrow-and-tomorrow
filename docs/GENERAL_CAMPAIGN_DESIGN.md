# General-led campaign: accepted design and bounded first slice

The player watches the society and speaks to its leaders. Generals execute all
battlefield decisions in every era: routes, camps, deployment, tactics and retreat.
Direct early-era cohort controls were considered and explicitly discarded.
Do not restore mandatory tactical orders or settings-heavy management screens.

The first slice was the Alderford War, an authored early campaign with its own
screen, map and save slot. It was removed on 2026-10-13 (scripts
general_campaign*.gd and general_dialogue.gd, and its button on the military
page): it was a separate scenario, not the player's world, and some forty
places in the engine had to ask whether it was running. The principle above stands and is carried by the living war (war
council, command hierarchy, generals summoned to court). Saves that hold the
old sections still load; the sections are passed over. The notes below
describe that slice and are kept as design record only.

The ruler decides purpose. Routine execution belongs to the general. Discussions
pause; commitments advance all ordinary world systems through the same calendar
entry point. Combat exchanges consume thirty minutes each; marches use distance
and effective speed; siege preparation consumes days. Viewing a recorded battle
does not resolve it again. Simultaneous commitments finish before a changed
objective replaces them. Saving preserves the unspent time of a commitment.

The model proposes structured intent and speaks in character. The engine validates
targets, physical access, available troops and authority. Questions are discussion;
an explicit override is an order, not a guarantee of obedience. Objection,
deliberate refusal, unsupported mechanics and impossible actions are distinct.
Character traits remain hidden; the player hears behavior and explanations.
The prototype's discipline action is replacement with captains' cooperation.
It does not promise a complete institutional punishment or political subsystem.

MilitaryCampaign retains the player's soldiers, equipment and casualty pools.
The existing combat simulator resolves losses and morale. Food carried by this
army is issued once and excluded from the home provision bill; replenishment
withdraws actual stores. Existing occupation capacity and garrison detachment
apply to captured approaches. No free troops, replenishment, or tiny-force city
capture. The hidden land grid is derived from actual terrain and validates edges;
observation counters are dated and do not reveal unobserved enemy positions.

Rivals retain goals, memory, provisions and conditional plans. Routine movement
runs in the engine. Consequential observation/supply changes can request Terra
reconsideration; it may select only supported strategies, not executable code.
Easy adapts more slowly. Medium considers available coalition strength. Hard can
coordinate through shared observations and considers more event-triggered plans.
No unit/tick/real-time periodic API loop. No default throttle or cached substitute
for the player's leader conversations. Actual token and latency receipts are
recorded separately from any price estimate. Model calls do not train weights.

Validation must cover both believable counterparts and strategic challenge.
Separate live model intent/conversation evidence, deterministic held-out combat
replays, and actual UI/save journeys. Never present authored placement as natural
progression, inferred prices as measured spend, or a passing fixture as a novice
usability study. Preserve the player's running session and saves during testing.

The multi-millennial full campaign is the long-term vision. This slice establishes
the command loop, not all eras, diplomacy, naval warfare or political institutions.

## Recruitment rule — September 20

Recruitment may exhaust actual available adults; no technology, law percentage,
prototype headcount or classroom ceiling may forbid drafting. Costs and outcomes
must carry the constraint. See `RECRUIT_DEPLOY_DESIGN.md` for the integrated queue
workflow, workforce consequences and remaining HOI4 parity gaps. This changes
recruitment authority, not the general-led battlefield direction above.

## October 17 — Small raids and shared foraging

Routine raids use 8–20 fighters from the existing Defense allocation. They
attack the existing known fields/stores targets and use the existing march,
interception, combat, loot, feud and retaliation paths. The general considers
returning every council sitting (normally three days while active), after a
quarter of the starting strength is unavailable, two hungry days with at most
one carried ration-day left, a reported overwhelming defense, or fourteen days
out. An ongoing battle resolves before the return order. Punish allows another
raid after thirty days of rest; a fresh explicit order can override that rest.
Explicitly requested larger forces remain possible through the existing orders.
No new troop pool or civilian emergency defenders are introduced.

Foraging has an absolute geographic capacity: twenty full soldier rations per
day in ordinary productive land, up to thirty in richer land, about six in a
full winter or the poorest ordinary land (both penalties can combine). The
remainder needs carried food. Marching fast collects one quarter of that local
capacity; slowing to forage collects the full amount at 80% marching speed,
or 50% in a district with less than half its forage remaining.

All field armies, including rivals, share each 12 km square district's capacity
in proportion to their numbers. A shared daily withdrawal ceiling prevents
splitting, merging or repeated ration calls from multiplying the available
food. Actual food taken depletes the district, including while marching.
Moving out and back, changing army identity, and saving/reloading do not reset
it. District reserves recover gradually, fully within sixty unused days;
recovered entries are pruned. Actual rations and supply previews add foraged
food to carried food, up to the full ration, rather than multiplying only the
shortage by a forage percentage. Map workers use an immutable snapshot of the
same ledger. The map explanation includes the shared local capacity.

This is the first slice of the early-conflict proposal. Separate livestock,
caravan and forage-party target entities, new disputes over access, and new
compensation/tribute objectives are not added here. Existing raids and feuds
continue to provide interception, consequences and settlement of grievances.
The district boundary is an intentional spatial approximation, and the initial
capacities, return deadline and cadence need play balancing.
