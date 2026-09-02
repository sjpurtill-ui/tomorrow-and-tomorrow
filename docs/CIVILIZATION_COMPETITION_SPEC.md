# Aggregate Civilization Competition

## Requirements and constraints

The world contains other civilizations that keep playing when the player is not looking. Their populations, economies, militaries, territories, diplomacy, and strategies must affect one another and the player. No civilization may materialize people, households, soldiers, leaders, or other population-sized records. A population of one billion must cost the same number of simulation records as a population of one hundred.

## Bounded architecture

The simulation uses eight fixed rival-polity records and one player profile. Each rival stores six numeric age cohorts plus bounded scalar capacities for food, health, production, knowledge, logistics, institutions, ecology, territory, and military readiness. Cohorts age numerically and their composition changes fertility, labor capacity, mobilization limits, hardship, and strategy; no individual person is ever instantiated. A fixed 8×7 relation graph holds opinion, trade, treaties, tension, and war state. Strategic turns run every 30 game days; histories and incident queues have hard caps.

Foreign simulation state is not player knowledge. Every player relation begins at contact level zero. Until a direct meeting, the player-facing contender set contains only the player: no foreign name, exact count, score, rank, position, intent, or diplomatic network is returned to the UI. Contact starts with low intelligence, so quantities remain ranges and strategic fronts remain unavailable until information improves.

Map knowledge follows the same rule. The authoritative planet always exists, but a fixed-resolution discovery mask obscures every area outside the founding convoy's observation radius and the routes contained in returned scout reports. The player chooses a 30, 90, 180, or 365-day mission for one aggregate scout formation. Personnel and provisions are numeric conserved quantities; the formation creates no scout roster. Its outbound route is a capped array. While the party is away, neither the discovery mask nor foreign contact changes. At the return day, the route adds bounded revealed swaths and only polities physically encountered along that route become known. Returned reports and reveal records have hard caps independent of population.

An encounter site is not a diplomatic destination. A returned investigation must first confirm a foreign settlement before an envoy can depart. Envoys then consume personnel, travel rations, and any physical gift. A unilateral declaration begins when its message reaches the destination; a bilateral treaty or trade proposal becomes actionable for the player only when the returning delegation carries acceptance home. Population, traffic, defenses, reserves, exchange, or institutions observed during the visit become player knowledge only when the delegation returns, at which point its capped route corridor is also added to the discovery map. Observation precision is bounded by access, purpose, and accumulated intelligence rather than by access to authoritative rival state.

Each rival also owns exactly five strategic urban-region records: frontier, granary, market, works, and capital. That is 40 records for the entire world at 100 people, one billion people, or any population in between. A record carries numeric population, original owner, current controller, approach order, territory value, fortification, damage, resistance, integration, and occupation age. It is a strategic aggregate—not one rendered city per settlement and never one record per inhabitant.

```text
Player aggregate state ──┐
                         ├── competitive ranking and domain leaders
8 rival aggregate states ┘
       │
       ├── monthly demographic/economic/strategy update
       ├── bounded rival↔rival trade, diplomacy, and war
       ├── player treaties, aid, containment, peace, and war
       └── 40 fixed urban regions → campaign front → aggregate combat
                                      │
                                      └── bounded occupation formations
```

Trade treaties expand the existing value-conserved external market rather than creating free goods. Aid, tribute, and plunder use the same authoritative inventories, so goods cannot disappear from one ledger and reappear from another. Foreign hostility changes security and cohesion pressure. Action availability is centralized: treaties cannot contradict war, repeated actions cannot farm opinion, and peace cannot erase a battle already in the field.

Every player war has one explicit fixed-size objective record: limited conquest, break power, liberation, or defense. The record stores only an objective ID, one target-region ID, war score, two exhaustion scalars, conflict age, start day, and truce deadline. It does not accumulate battle objects or person-sized state. The objective locks when hostilities begin. Captures, losses, incidents, occupation leverage, and elapsed time update score and exhaustion; exhaustion then feeds cohesion, legitimacy, and foreign-pressure consequences. Peace terms are forecast from score, objective progress, occupation leverage, and the rival's exhaustion. Peace preserves the resulting control line and creates a one-year truce that both player and AI must respect.

Rival campaigns are built from the source civilization's numeric armed capacity and technology. The side that initiated the campaign is always the attacker, while terrain and fortifications benefit the actual defender. Battle losses return to the correct civilization's numeric cohorts and military total. Territory changes only when the side controlling that ground loses it: an offensive victory takes bounded rival territory, a defensive loss cedes bounded player territory, and victories do not manufacture land.

## Urban control and occupation

Home regions form an ordered campaign front. The player can target the first rival-controlled region exposed by that front; a decisive win changes that exact record's controller and transfers its pre-existing territory value. Surviving trained personnel detach from the field host to form the occupation force. Reinforcement is another transfer between those same aggregate pools. Evacuation returns survivors, wounded, captives, equipment, and ammunition to their authoritative ledgers. None of these operations creates manpower or equipment.

An occupation has both leverage and cost. Region population contributes to controlled-population ranking, but resistance and damage create a bounded central relief obligation. Integrated granaries can send food surplus, markets improve exchange access, and works improve production. Resistance burdens cohesion and legitimacy. Garrison coverage, logistics, institutions, peace, and time can reduce resistance and raise integration; insufficient coverage can reopen a truce as a regional uprising. Recapture incidents target the actual occupied region, use its occupation formation as defender, and cannot be dismissed with tribute. Losing the battle or yielding the region returns its exact territorial value to the original owner.

Region roles also matter to the rival. Losing the granary constrains food growth, the market and frontier constrain logistics, the works constrains production, and the capital constrains institutions and knowledge. Multiple losses or capital occupation force the rival toward fortification. Occupied regions and the capital add explicit peace leverage; a truce preserves the current control line rather than silently resetting it.

Rival-versus-rival conquest uses these same 40 records. A power may advance only through its own contiguous holdings; it cannot skip a region controlled by the player or a third polity. Foreign holdings are shown under their current controller and can be attacked as liberation campaigns. Liberation restores the original owner instead of silently starting an undeclared second player occupation.

Rival strategy is legible rather than omniscient. The UI derives one bounded intent and threat classification from current relations, comparative military power, treaties, wars, and posture. The diplomatic network names current partners, rivals, and war opponents. AI powers may hold at most two simultaneous wars, respect non-aggression pacts and truces, and prefer fortification when a stronger hostile neighbor threatens them. These rules allow opportunism and containment without an unbounded planner or hidden per-unit simulation.

Before an offensive, the strategic assessment reports a range for real defending aggregate capacity, intelligence confidence, player field strength and readiness, supply condition, casualty risk, expected outlook, and the selected region's systemic value. The estimate never resizes the enemy to match the player's army. During war, the same panel replaces speculation with objective progress, war score, both sides' exhaustion, and a peace forecast so the player can decide whether another campaign is worth its cost.

The complete state transition is:

```text
declare war → select exposed region → aggregate battle
                                      ├── loss/retreat: no capture
                                      └── decisive win: control changes
                                                           ├── home region: player occupation force
                                                           └── foreign holding: liberation

player occupation → garrison coverage + supply + institutions
                  → resistance / integration / damage
                  → food + economy + cohesion + legitimacy + score
                  → peace leverage or targeted uprising/recapture
```

Competition state is JSON-safe and validated before import. Invalid, incomplete, non-finite, asymmetric, or contradictory relation state is rejected without partially mutating the live simulation.

## Competitive outcome

Every contender is scored by the same seven equally weighted 0–100 pillars: controlled population, knowledge, production, logistics, military power (numeric manpower adjusted by readiness and capacity), resilience (health, cohesion, institutions, and food reserve), and territory. The UI exposes this breakdown rather than an unexplained weighted total.

After Year 20, any contender—not only the player—must simultaneously maintain at least 45 food-days, 50% health, 45% cohesion, and 35% institutions; rank first overall by at least 10%; lead at least four of the seven strategic domains; and hold those conditions for twelve consecutive strategic turns. Each contender has one bounded streak counter. The player wins by satisfying the rule first and loses if a rival satisfies the identical rule first. Systemic player collapse under sustained hostile pressure for twelve turns remains an additional defeat path. These counters advance only on monthly strategic turns; opening the UI, negotiating, or resolving a battle cannot accelerate them. A terminal outcome cannot later revert. Unknown rivals continue to compete internally without leaking their standing through the known-world UI.

## Trade-offs and growth path

Eight rivals and five home regions per rival provide meaningful pairwise competition and concrete conquest while keeping work constant and easily auditable. The model deliberately resolves strategic population, AI, resistance, and integration monthly rather than daily; only existing bounded military operations and provision ledgers require daily work. The trade-off is that a strategic region represents a whole urban system and its hinterland, not a literal street map. If the world later needs hundreds of named polities, the fixed active set should become regional aggregates with only nearby or top-ranked polities promoted into these detailed slots. The five-role region schema can remain unchanged, and population must never become the unit of iteration.
