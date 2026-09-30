# Military system, version 2: HOI4 depth with fewer clicks

Status: design for the night of 2026-09-29/30 (branch `codex/military-night`).
Read with `GENERAL_CAMPAIGN_DESIGN.md`, `RECRUIT_DEPLOY_DESIGN.md` and `ADJUDICATION.md`.
The general still fights the battles. The player decides purpose, makes the
army and keeps it fed. Nothing here adds a form to fill in.

## Where we are (audit, 2026-09-29)

Five read-only audits of the current code found the following. Line numbers are
in the audit notes kept with this branch's handoff.

- **Production** has HOI4's shape: lines, hands, a skill ramp, a stock strip and
  staff automation. But about 20 of its 34 newer kits are placeholders: identical
  stats (1.05/1.0/0.1/0.65) and identical recipes (Timber 0.8, Stone 0.2). Muskets
  need no iron. Light and heavy tank kits are the same kit. A tank company is
  weaker than the old "armored formation". The skill ramp ignores multi-day
  steps. Retooling keeps 65% of skill whether you go from spears to spears or
  from spears to tanks.
- **Supply** means food only. One global carrier number feeds every army.
  Nothing reaches a field army except bread: no men, no gear, no ammunition
  unless it walks home. Nobody dies or deserts from hunger in the field. A cart
  moves no faster than a porter.
- **Recruitment** works (queue, three bars, auto-deploy). It has two parallel
  paths, three template editors, a destination list that silently stalls on an
  army that is away, and a fresh general for every deployed band.
- **Combat** is rich (frontage, blocks, reserves, tactics, overrun). Armour only
  ever helps the side that wears it; piercing never matters to the attacker.
  There is no late-era or crewless unit at all: a lost machine is a lost man.
- **Looks**: there are no figures in the world, by design. Armies are ink marks
  on the war chart and plates in the battle view. But a tank army is drawn as
  foot soldiers under a Bronze Age standard. Every modern infantry is "rifle",
  every gun is one cannon, every tank one box. Nothing is drawn after about
  AD 1945 (game year 2800).

## The shape of version 2

Four loops, each with one screen and one number the player can read at a
glance. They share one set of ledgers.

| Loop | Screen | The one number | HOI4 equivalent |
|---|---|---|---|
| Make | Production | Days to cover the shortfall | Production + logistics tab |
| Raise | Recruit & deploy | Days until the band is ready | Deployment |
| Keep | Readiness & supply | Supply per army (0–100%) | Supply map + reinforce |
| Fight | Army bar, war chart, battle view | Will to fight | Battle plans + combat |

HOI4 depth stays where it makes a decision: which lines, how many hands, what
to field, how far to push past the depots, who gets reinforced first. It goes
where it only makes clerical work: no supply hubs to place province by
province, no truck allocation, no division-width arithmetic, no variant
designer.

## 1. One equipment ledger

New data authority: `scripts/equipment_ledger.gd`. Every land kit has one row:

```
id: family, gen, year (game year it usually appears), gate (discovery),
    attack, defense, armor, pierce, crew, ammo_per, supply (loads a day per set),
    fuel (bool), crewless (0..1: share of losses that fall on machines),
    materials {resource: amount}, days (work per set), delivery (load),
    glyph (battle/production icon), look (one line for art)
```

`combat_simulator.WEAPONS`, `CREW_PER_EQUIPMENT`, `AMMUNITION_PER_ELEMENT` and
`military_equipment_extension.ITEMS` read their numbers from the ledger. There
is one place to change a musket.

**Families.** Every kit belongs to one family, and its generation orders it
within the family:

| Family | Generations (game year) |
|---|---|
| Hand arms | improvised (0) → spear (150) → axe (420) → sword & shield (650) → pike (1100) |
| Missile | sling (120) → bow (250) → javelin (300) → mounted bow (700) → crossbow (1000) |
| Firearm | hand cannon (1750) → musket (1980) → grenadier kit (2250) → service rifle (2560) → marksman rifle (2620) → assault kit (2760) → networked rifle (2880) → exosuit (2996) |
| Protection | shield spear → padded → lamellar → scale → mail → plate (armor kits) |
| Mount | lance/horse (600) → chariot (450) → armored lance (1400) → elephant (900) → dragoon (2150) |
| Crew weapon | machine gun (2640) → mortar (2690) → anti-tank (2740) → anti-air (2740) → counter-drone laser (2995) |
| Guns | ram (500) → catapult (900) → trebuchet (1480) → bombard (1760) → field gun (2150) → horse gun (2300) → modern gun (2740) → rocket launcher (2770) → precision fires (2905) |
| Vehicle | motorized (2735) → armored car (2720) → light tank (2745) → armored vehicle (2760) → heavy tank (2775) → tank destroyer (2775) → mechanized (2780) → main battle tank (2850) → robotic combat vehicle (2990) |
| Autonomous | drone team (2980) → combat frame (3000) |
| Support | repair kit, medical kit, engineering kit, siege kit |

**Stats, rule of thumb** (per man; crew-served kits concentrate a crew's
firepower in one set, so a field gun's attack is per gunner):

- Pre-gunpowder hand kits sit between 0.9 and 1.3 attack. Their differences are
  small and real: pikes defend, axes attack, crossbows pierce.
- Each firearm generation adds about a quarter to attack. A rifle is about 1.7,
  an assault kit about 2.3, a networked rifle about 2.8.
- Armor runs 0 (cloth) → 0.4 (mail) → 0.7 (plate) → 1.5 (armored car) → 2.2
  (medium tank) → 3.0 (heavy) → 3.6 (main battle tank). Pierce runs from 0.4
  (spear) to 4.0 (modern anti-tank and precision fires).
- Recipes follow the materials the kit really needs: bronze arms need copper
  and tin, iron arms need iron, firearms need iron and saltpetre-bearing
  stores, vehicles need steel-grade iron, rubber, fuel and more work days.

**Retooling keeps skill by family.** A line keeps all its skill when it keeps
the same kit, 80% when it moves to another kit of the same family, 40% within
land kits, and 20% otherwise. The ramp counts multi-day steps (the span bug).
The line's card says "keeps 80% of its skill" before you switch.

**Upgrades are one click.** When a newer generation of the line's family is
unlocked, the line shows it: "Rifles can be made now. Switch? Keeps 80% of
skill." Staff lines switch by themselves.

## 2. Production (small corrections)

The screen stays as rebuilt on 2026-09-28. Corrections:

- Hands show only on lines that can use them. A line that has met its target,
  or is missing a material, shows "idle" and gives its hands to the lines
  below it.
- The two priorities are HOI4's two priorities, and the screen says so. Hands
  are split by each line's hands (factories). Scarce materials go down the list
  in order.
- The picker shows each kit's family, generation, and attack/defense/armor/
  pierce against the kit it replaces ("+24% attack over muskets").

## 3. Supply lines that carry everything

Supply stops meaning "bread". A field army's line carries food, ammunition,
fuel, replacement gear and replacement men. The engine keeps the existing
distance model (terrain, rivers, relays through held towns) and replaces the
single global carrier number with carriers that exist.

**Demand.** Each army needs, per day, in *loads* (one load = one man's food
for one day):

```
demand = men × ration + Σ sets × ledger.supply
```

A bow army needs about 1.1 loads a man. A rifle army about 1.6. A tank army
about 4. A drone and robot army about 3 (fuel and charge instead of bread).
The template card shows it ("Supply 1.6 a man a day").

**Carriers.** Porters are Logistics workers. Carts and wagons are the Transport
Carts stock. Trucks are a new kit (`supply_truck`, gate `internal_combustion`).
Rail is a multiplier on home-network legs once railways are adopted. Driverless
freight (gate `driverless_highway_freight`) multiplies trucks. Each carrier has
a load and a pace:

| Carrier | Load | Pace km/day | Eats its load per day |
|---|---|---|---|
| Porter | 1 | 20 | 8% |
| Cart | 8 | 25 | 5% |
| Wagon (with `draft_harness` or later) | 20 | 25 | 4% |
| Truck | 80 | 150 | 1% (fuel counted in demand) |
| Rail leg | ×6 on the first home-network leg | 400 | 0.5% |
| Driverless freight | trucks ×1.4 | 150 | 1% |

**Throughput.** Moving `demand` loads a day over a route of `d` haul-days needs
`demand × 2d / load` carriers (there and back). The engine sums what every army
needs, compares it with the carriers we have, and gives each army its share by
**priority** (First / Normal / Last; default Normal). Distance therefore eats
carriers, not just the load: push twice as far and you need twice the carts.
This is van Creveld's arithmetic and HOI4's truck consumption in one line.

**Supply per army.** One writer, one number:

```
supply = min(1, (delivered + foraged + local) / demand)
```

It is stored as `supply_level`; every other system reads it, and the eight
writers found by the audit become inputs to this one function (battle, blockade
and strike effects feed "delivered", encirclement cuts the route).

**Reinforcement in the field.** What the line can carry beyond food goes, in
this order, to ammunition, replacement gear and replacement men for the army's
missing places (First-priority armies first). Replacement men are drawn from
the recruitable adults at home (the same ledger recruitment uses) and arrive
green, lowering the formation's drill in proportion. Gear comes from the stock
the Production screen shows. An army at 100% supply that has lost a fifth of
its men is back to strength in weeks, not never.

**Attrition out of supply.** When supply stays below 0.75 for three days
(hungry), each day costs `men × 1.1% × (0.75 − supply)/0.75`: at no supply at
all, about one man in ninety a day, about a quarter of the army in a month (the
pace of the worst historical retreats; typical shortfalls cost a few percent a
month). Of those, 45% fall sick (they come back when fed), 35% desert home (they
rejoin the workforce), 20% die. Gear wears three times faster. The war leader
states it with numbers: "No bread for nine days: 212 sick, 160 gone home, 94
dead."

**Readiness & supply screen.** Each army row: supply bar, its priority
(First/Normal/Last), carriers used against carriers available, days of haul,
and its reinforcement flow ("+34 men, +20 rifles a day"). The supply map keeps
its wash and draws each army's line with a width that shows its load.

## 4. Raise: templates that say what they do

The template card shows the engine's own numbers: men, attack, defense, armor,
pierce, march km a day, supply a man a day, training days, and the gear it
needs by family, each with a tooltip saying where the number comes from. No
width, no slots.

Fixes: the destination list offers only armies at home (and says why others
are not offered); a band deployed to join an army keeps that army's general;
bands raised together from one line share one general until the player splits
them.

## 5. Fight: armour by hardness (as built)

A formation is as hard as its kit's armour: `hardness = clamp((armor − 0.3)
/ 1.2, 0, 1)`: cloth 0, mail about half, plate and every tank all of it.
Our blows against the enemy's hard share are scaled by how well our kit
pierces the armour of that share:

```
pierce factor = clamp((pierce / armor) ^ 2.5, 0.10, 1.0)   (1 when pierce ≥ armor)
attack vs enemy = attack × ((1 − enemy hard share) + enemy hard share × pierce factor)
```

The enemy's fire falls on our formations by how much of it gets through
their armour (weighted by the enemy's fire at each pierce), so a tank company
in a rifle army takes few of the rifle losses. The old defence-side bonus is
gone (it counted armour twice). Rifles hardly scratch a medium tank (0.25), an
antitank gun pierces it; spears keep about four fifths of their blows against
mailed men, arrows about three fifths.

Machines (kits whose crew is below one man: robotic vehicles, combat frames)
are run by operators. The formation's count is its operators; each fights
with all of his machines (stats are per machine in the ledger, scaled per
operator), cannot fight without them, and a blow on the formation destroys
machines: only the crewless remainder kills operators. A combat frame is
worth somewhat more than a networked soldier, not a legion. Known limit:
frontage still counts operators, not machines.

## 6. Units after 1945 (game years 2800–3000), as built

Gated on discoveries already in the research blocks (unit gate / kit gate):

| Unit | Kit | Gates (game year) | Men per set |
|---|---|---|---|
| Networked infantry | networked rifle kit | `night_vision_intensifiers` 2842 / `tactical_data_links` 2888 | 1 |
| Main battle tanks | main battle tank | `night_vision_intensifiers` 2842 | 4 |
| Precision fires | precision launcher | `satellite_guided_strike` 2902 | 4 |
| Drone teams | drone team | `mass_small_drones` 2980 | 2 |
| Counter-drone batteries | laser point defence | `directed_energy_point_defence` 2995 | 6 |
| Robotic combat vehicles | robotic vehicle | `machine_assisted_targeting` 2990 | one operator runs 3 |
| Exosuit infantry | exosuit | `solid_state_battery_cells` 2996 | 1 |
| Combat frames | combat frame | `collaborative_robots` 2955 / `solid_state_battery_cells` 2996 | one supervisor runs 8 |

A society ahead of history (research allows up to about a century's lead)
meets combat frames around 2900. They cost what they should: rare ores,
Civilian Goods for their parts, long work days, charge and parts on the
supply line, and specialist crews. Drones strike armour from above (they
pierce a main battle tank); counter-drone batteries hunt drones and robots;
precision fires hunt guns and launchers.

## 7. How units look, from the first war band to the combat frame

The game draws armies in ink on one paper throughout (a deliberate choice of
2026-09-26/27): battle plates and production icons (`resource_icons.gd`
`arm_glyph`, one glyph per ledger kit, chosen by `battle_blocks.glyph_of`),
war-chart marks (branch and age read from the ledger family and year) and
battle marks (crossed weapons by the armies' kit year). Owner colour is only
a thin wash or streamer, or a robot's sensor glow.

| Game years (≈ history) | Silhouette on the plate | Map mark | Battle mark |
|---|---|---|---|
| 0–300 (5000–3000 BC) | Knobbed club, flint spear, sling cords and stones, self bow | Tally of bound spears | Crossed spears |
| 300–650 (3000–1200 BC) | Bronze axe, sword and big shield, chariot with driver | Leader's standard | Crossed spears / swords |
| 650–1150 (1200 BC–AD 300) | Crossed pikes, horse archer drawing a recurved bow, elephant with a tower, catapult | Framed standard with arm sign | Crossed swords |
| 1150–1800 (AD 300–1500) | Mailed rider with couched lance, crossbow seen from above, trebuchet, bombard on its bed | Framed standard | Crossed swords |
| 1800–2400 (AD 1500–1800) | Hand cannon on a pole, matchlock, dragoon firing a carbine, field gun on spoked wheels | Square flag on a pike over coloured battalion blocks | Crossed muskets |
| 2400–2700 (AD 1800–1915) | Rifle with bayonet, mountain rifle over peaks, machine gun on its tripod, howitzer with split trail | Staff-map box | Crossed rifles |
| 2700–2975 (AD 1915–2020) | Assault rifle, parachute, helicopter, lorry, armoured car, light, medium and heavy tanks, tank destroyer, carrier, main battle tank, networked soldier with night optic | Box with branch sign (armour oval, motor wheels) | Armour sign |
| 2975–3000+ (AD 2020–2030+) | Four-rotor drone, driverless tracked robot with a sensor mast, exosuit with a battery spine, combat frame: a tall machine, shoulder yoke, bird-jointed legs, one glowing slit for a face | Box with a lattice sign (autonomous) | Lattice sign |

History, not fashion, sets the order: shakos after about 1790; blue, red and
white coats until about 1880, drab after; steel helmets from about 1916.

## What stays out

- No new screens. Every change lands on Production, Recruit & deploy,
  Readiness & supply, the army bar, the war chart and the battle view.
- No player-placed supply hubs, no truck-assignment forms, no width.
- No victory conditions ([no-victory-conditions]).
- Rival civilizations keep their aggregate model for now; the new supply rules
  apply to every force the combat simulator and military campaign run.

## Critic round 1 (2026-09-30, before building) and what changed

An independent review (HOI4 veteran, systems designer, historian) found eight
problems. The plan above is amended as follows; where this section and the
text above disagree, this section wins.

1. **Upgrades go by role, not by generation.** A family groups kits for
   production skill only. Nothing switches a line automatically. A kit
   replaces another only where the same unit type can carry both
   (`military_unit_catalog.equipment_for`).
2. **Loads were 16× too small.** One load stays one man's bread for a day
   (about 1.5 kg). Carriers: porter 16, ox cart 250, horse wagon 700, lorry
   2,000 loads. Supply burdens now span history: a spearman ~1 load a day, a
   Napoleonic musketeer with his share of horses ~3, a First World War rifle
   division ~6, a tank crewman ~30, a main battle tank 600 per tank.
3. **Two shares, two effects.** Food share drives hunger and attrition
   (existing `hungry_days`). Stores share (fodder, fuel, rounds, spares)
   drives vehicle and mount power and march speed. One bar is shown; the
   tooltip splits it. Fodder can be grazed; fuel cannot.
4. **Machines are counted as machines.** For kits with crew below one, the
   formation's count is machines; men = machines × crew. Frontage and losses
   are machines; losses are equipment, not deaths. Machines do not rout.
5. **Armour by hardness, once.** The defence-side armour bonus is replaced
   by a hardness split: each side's hard share (by kit) takes attack scaled
   by pierce against armour, with a floor near 0.1; its soft share takes full
   attack.
6. **Years come from gates.** The ledger's year is the gate's research year
   (a test holds it within 40 years). Corrected gates: lorries
   `motor_freight_lorries` (2677), assault and engineer kits
   `infiltration_storm_squads` (2713), rocket launchers
   `ballistic_rocket_bombardment` (2785), heavy tanks, carriers and tank
   destroyers `armoured_division` (2768), pikes `long_pike_phalanx` (878),
   lances `chariot_to_cavalry_shift` (778), combat frames
   `solid_state_battery_cells` (2996).
7. **Rivals share the daily military loop.** Any carrier or attrition rule
   hits them too; their staff must build carriers for their own shortfall.
8. **Reinforcement reuses the Reinforce path** (training × 0.58) and one
   priority per army, not a third recruitment route.

Also: recipes use raw ores plus a modest Civilian Goods charge. Named
intermediates (engines, motors, batteries) flatten into bills of hundreds to
thousands of goods and would make late armies unbuildable. The unit's own
multipliers (`UNIT_TYPES`) still scale the kit, so "one place to change a
musket" means one place for the kit.

Revised order: (1) the ledger as the only source of kit numbers, family
retention and the skill-ramp fix; (2) looks from the ledger; (3) hardness and
era-equipped enemies; (4) field sustainment; (5) carriers; (6) late units
with machine accounting; (7) recruitment fixes and template numbers.

## Iteration log

- **Iteration 1, the ledger.** `scripts/equipment_ledger.gd`: 56 land kits
  with family, generation, year, per-man stats, crew (fractional for
  machines), crewless share, rounds, supply burden, recipe, delivery load,
  glyph and a one-line look. The combat simulator, the production view
  (`military_equipment_extension.gd`, now 24 lines instead of 600) and the
  crew and rounds rules read it. Placeholder kits have real numbers. Early
  firearms are weaker per man than bows but pierce armour. Spoils no longer
  file rounds under an empty name. Retooling keeps skill by family (100 /
  80 / 40 / 20%) and the skill ramp counts multi-day steps.
- **Iteration 3, armour by hardness.** The defence-side armour bonus is gone.
  Each kit's hardness comes from its armour (cloth 0, mail about half, plate
  and tanks nearly all). Our blows against the enemy's hard share are scaled
  by `(pierce/armor)^2.5`, never below 0.10; the enemy's fire falls on our
  formations by how much of it gets through their armour, so a tank company
  in an infantry army takes few of the rifle losses. Vehicle armour and
  pierce were recalibrated so rifles hardly scratch a medium tank and an
  antitank gun does. Kits the old age table did not name take their battle
  age from their ledger year, so late kits fight at the last age's pace
  instead of the stone age's.
- **Iteration 4, keeping armies in the field** (`scripts/field_sustainment.gd`).
  - *Hunger costs men.* A band or garrison hungry three days or more (below
    three quarters of a ration) loses `men × 1.1% × (0.75 − food)/0.75` a
    day: at no food about a quarter of the band in a month. Of those, 45%
    fall sick (the band's wounded pool; 4% a day rejoin their places once
    fed), 35% go home (they stop being soldiers and are working hands again),
    20% die (population deaths, "Died of hunger in the field"). Totals are
    kept on the band and the war leader states them.
  - *Stores are a second share.* Each kit's supply burden (fodder, fuel,
    rounds, spares) comes on the same line; horses can graze, fuel cannot.
    Kits asking a load or more a man a day fight weaker as stores run short
    (down to 35%). The supply bar's tooltip gives the share.
  - *Losses are replaced by drafts.* Open places in a band (not the sick)
    are drafted from free adults, trained at the Reinforce pace (0.58 of a
    full course), then walk the band's haul days out and join, their drill
    averaging in. On the road they are field personnel in the ledger; a
    draft whose band is gone comes home to the recruits with its gear.
    Drafts survive a save (`field_drafts`).
  - *Gear and rounds reach bands away* along their line: the day's delivery
    load is shared out by priority, a distant band receiving only the share
    its carriers bring over the haul. A distant band's news still comes by
    runner.
  - *One priority per band*: Supplied first / in turn / last, on the
    Readiness & supply rows, for gear, rounds and replacements alike. Rows
    also show "+N coming" (drafts on the road and in training).
- **Iteration 5, carriers that exist** (`scripts/carriers.gd`). The single
  global carrier formula is replaced by the fleet we have: each Logistics
  worker drives a lorry (2,000 loads), else a cart (250; 700 once horse
  freight wagons are adopted), else carries 16 loads on his back. Each band
  away and each garrison asks its loads a day (men's bread plus its kits'
  stores; a garrison only what its town does not give) times its round trip
  (twice its haul days, at least one; railway mobilization cuts the trip up
  to 60%). The day's transport share is what the fleet moves, times the war
  leader's logistics and the people's supply practice, against that demand.
  A band at the home settlement needs no carrier. Lorries are made on a line
  (gate `motor_freight_lorries`) and, once held, set the network's pace.
  The staff build lorries once they can, else carts, for the shortfall,
  never more than there are drivers; the Production stock strip shows what
  the supply lines lack. The Readiness strip's tooltips give the fleet, the
  loads per trip and the load-days asked against those moved.
- **Critic round 2 (code review of iterations 1–4) and the fixes.**
  - Saves taken while replacement drafts train now load (the mode is
    validated); formations saved before the ledger are refitted on load
    (crew sizes and rounds changed), surplus sets and rounds going back to
    the stores.
  - A draft brings gear only for its formation's real gap; arrivals never
    raise a formation's size; men or sets beyond the gap go home. No set is
    lost.
  - No hunger losses while a band is in battle (the battle's copy holds its
    men) or at the home settlement. Hunger-sick are kept apart from battle
    wounded; only they rejoin at 4% a fed day.
  - Drafts go only to bands their line reaches and that are not starving,
    and only from people already called up or within the Defense share of
    work. A draft that cannot reach its band waits at home. The Readiness
    row says why a band gets none.
  - Draft orders merge per formation and start only at three men or 2% of
    the formation; the personnel ledger has a "replacements" category so its
    parts add up; home designs no longer count replacement trainees; a draft
    whose band is gone joins the army at home as trained men.
  - Stores weaken only kits living on them (three loads a man a day or
    more); horse archers graze; stated odds keep the stores share; a far
    band's deliveries cost the budget in proportion to the distance; bands at
    sea wait; drafts on the road keep walking while home is held.
- **Iteration 6, the last age's units.** Networked infantry (night optics,
  data links), main battle tanks, precision fires, drone teams, counter-drone
  batteries, robotic combat vehicles, exosuit infantry and combat frames,
  each on real late research. Machines (crew below one) are run by
  operators: a formation's count is its operators, each fighting with his
  machines (a frame supervisor runs eight, a robot vehicle operator three);
  without machines they cannot fight; a blow mostly destroys machines and
  only the crewless remainder kills operators. Drones strike armour from
  above; counter-drone batteries hunt drones and robots; precision fires
  hunt guns. A frame is worth somewhat more than a networked soldier, not a
  legion. Known limit: frontage still counts operators, not machines.
- **Looks by age** (worker branch `codex/military-looks`, merged). Every
  ledger kit draws its own ink glyph (51 in all, two new primitives), chosen
  by `battle_blocks.glyph_of` so combat's coarse arms are untouched. The war
  chart reads each force's branch and age from its kits (a new "autonomous"
  branch with a lattice sign; a square flag on a pike for gunpowder armies);
  battle marks cross spears, swords, muskets or rifles, or show the armour or
  lattice sign, by the armies' kit year. Units with no painting show their
  kit glyph large on the roster.
- **Iteration 7, recruitment.** Template cards state the engine's numbers:
  strength (men × √(attack × defense) fully armed and drilled), march km a
  day, loads a man a day (bread and stores), training days, with a tooltip
  for attack, defense, armour, pierce, machines and replacement training.
  The destination list greys bands that are away and says a line is waiting
  when its chosen band has marched. A line's later bands join the band it
  raised before while that band is at home, so recruiting no longer makes a
  new general for every band.
