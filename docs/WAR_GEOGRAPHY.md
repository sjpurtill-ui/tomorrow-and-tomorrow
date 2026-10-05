# War geography: from one settlement to HOI4 fronts

Status: decided and built (2026-10-05). The user: "make the world smaller",
"6-7 on one continent and 6-7 on another (think Europe and Asia)", and
"everybody has one settlement that expands" (no new towns: they cost too
much run rate). Built: the two-continent placement (`civilization_start.gd`)
and realm reach (`realm_reach.gd`). The presentation was built on
`codex/war-night` (PR #157).
Read with `GENERAL_CAMPAIGN_DESIGN.md` and `ADJUDICATION.md`.

## The goal

The user, 2026-10-04: drive war toward "fighting at the level of Hearts of
Iron IV"; the game "will settle into a groove very much like Hearts of Iron IV,
somewhere around the year 2200". And: "the distinct thing is fronts making
sense at that time in relation to how borders are constructed. And the
evolution and expansion of what started as an initial settlement to the point
where HOI4-type objectives would make sense."

Game year 2200 is about 1700 AD on the game's own calendar
(`technology_eras.gd` CURVE: 2000 = 1600, 2400 = 1800). That is the age of
nation-states dividing whole continents between them. HOI4 itself (1936) is
about game year 2790.

## What the world is today (measured from the user's save, year 114)

- The world is 36,000 km by 18,000 km (`CIVILIZATION_WORLD_RADIUS_*_KM`).
- 12 other peoples, each of about 400 to 600 people. None is met yet.
- Each people founds towns through the same settlement model as ours
  (`world_simulation.gd` gives every new town a region). In this save each
  people has only its capital so far; its four unfounded slots are laid out
  within about 220 km by 180 km of it.
- The nearest people is about 6,000 km away. The general's road to the nearest
  known town in a fresh capture world is about 280 days.
- Land is drawn only as the claims of towns
  (`nation_borders.gd` `estimated_radius` / the settlement network).
  Our 409 people claim a disc a few km across.

**Consequence:** under today's model two peoples' lands meet only if their
towns spread in a chain across thousands of km: hundreds of towns, each
claiming a few km to a few tens of km. Whether that ever happens by 2200 is
unmeasured. It is unlikely on this map. Without meeting land there are no borders between peoples, and so no
fronts in the HOI4 sense. Taking a town is the only objective there is. The
presentation built tonight (below) is correct, but in natural play it would
never show a border front.

### How big peoples get (fast sim, `tools/sim/run.py --scenario sensible`, 3 seeds)

| Game year | 100 | 300 | 600 | 800 | 1000 | 1200 |
|---|---:|---:|---:|---:|---:|---:|
| People | 400 | 1,230 | 4,340 | 13,200 | 19,700 | 25,600 |

A people of 25,000 at year 1200 holds towns a few tens of km across. Even the
generous realm reach below gives it about 100 km. Peoples 6,000 km apart can
never meet at these sizes. **The map's scale and the peoples' sizes do not
fit an HOI4 groove by 2200.** Something has to give:
- **(a) A denser world.** Peoples a few hundred km apart, or many more of
  them, so that peoples of 10,000 to 100,000 meet by 1000 to 2000. Historically
  most early peoples had neighbours within days, not years.
- **(b) Far larger peoples.** Populations in the millions by 2000, which
  changes all balance.
- **(c) Realms far wider than their people.** This reads false at small sizes.

(a) fits history and the HOI4 goal best. It conflicts with the 2026-10-01
choice "neighbours far, first contact years in" (memory: sparse contact). That
was made to keep early envoys and contact rare. It could hold for the first
centuries if peoples start far apart and spread toward each other: new towns
founded outward, and contested middle ground filling in by 1000 to 1500.

## The ladder (what war looks like at each stage)

| Stage | When (game year) | Ground | Fronts | Objectives |
|---|---|---|---|---|
| Camps | 0 to about 800 | each people a speck of claimed land in open country | none; raids and marches cross open land | their stores, their camp, a town |
| Frontiers | lands first meet (about 800 to 1500) | realms touch along a frontier (Boundary Marker Surveys) | a front along the meeting line, worked by the forces near it | border towns, the land between |
| Realms | 1500 to 2200 | states with agreed borders (Peace Congress) and many towns | long fronts split into sectors, one per border town | towns weighted by worth (victory points) |
| The groove | 2200 on | continental realms meet on every side | fronts like HOI4: sectors with the men on each, pockets, breakthroughs | victory points, a capital, a coast |

## Proposal: realm reach (the land a people holds grows with it)

The land a people holds should be more than its towns' fields. It should be
the country it rules: one more claim per people, centred on its capital, its
reach growing with its people and its ability to govern.

    reach_km = 1.2 × people^0.42 × governing

`governing` comes from what the people knows:
- 1.0 to begin with;
- 1.5 with kingship and roads;
- 2.0 with sovereign realms (Peace Congress);
- 3.0 with rail and the telegraph.

| People | reach at 1.0 | at 2.0 | at 3.0 |
|---|---:|---:|---:|
| 400 | 15 km | | |
| 10,000 | 57 km | 115 km | |
| 1 million | 400 km | 800 km | |
| 30 million | 1,650 km | 3,300 km | 5,000 km |

For two peoples 6,000 km apart, their realms meet when the two reaches add
up to about 6,000 km: tens of millions of people each, with sovereign realms.
That lands around game year 2000 to 2400 if populations follow history. **This
depends on the long-run population curve.** It must be checked with the fast
sim (`tools/sim`) before any number is fixed.

The partition (`nation_border_partition.gd`) already cuts touching claims
where their scores are equal. It also leaves water to nobody and stops a
stranger's land at the edge of ground our people have charted. A realm claim
needs no new geometry: borders, washes and meeting lines follow on their own.

**One ledger (ADJUDICATION.md).** If realms are drawn, the engine must hold
the same land. The realm reach must be one pure function, read by:
- the borders (drawing and fronts);
- `resource_system.gd` `_foreign_holds` (finds in foreign land), which today
  keeps its own town-radius holds;
- settling, so a town cannot be founded inside another people's realm;
- the war council's march, which should know when it crosses into their land.

If any of these disagreed with the map, the map would lie.

**Decided 2026-10-05:** (a) a smaller world (two continents of six or
seven peoples each, about 1,100 km between neighbours) together with realm
reach, centred on each people's one settlement. The earlier questions were:
1. Should peoples hold country beyond their towns at all?
2. Which of (a) a denser world, (b) larger peoples or (c) wider realms?
   The sparse world (12 peoples, 6,000 km apart) and tens of thousands of
   people per people cannot give fronts between peoples by 2200.
3. Or should towns spread further and faster instead (founding reach and
   pace), with land staying as the towns' fields?

## What `codex/war-night` built (presentation, correct under either model)

- **War screen: where every soldier stands.**
  - One allocation bar from the personnel ledger, whose parts always add up to
    everyone under arms: guarding home, ready, against each people, holding
    towns, drilling, hurt or away.
  - Readiness gauges: drill, armed, will and fed.
  - Each town's guard against its need.
  - Each band with bars for men, will and fed, and where it is bound.
  - Each enemy: our men against their warriors as our watchers reckon them,
    and the general's own march to their nearest town.
- **Fronts from borders.**
  - At war or in a hot feud with a people whose land meets ours, the front
    is the meeting line.
  - Local strength bends the line, massed forces thicken it, battles on it
    heat it, and it moves when a town changes hands.
  - Where lands do not meet there is no front. The chip says how many days
    of road lie between.
  - The war map draws each people's real claimed land, not a disc.
- **Sectors.** A border front splits by our nearest town. Each stretch shows
  our men against theirs, ringed in red at two to one.
- **Objectives.** Enemy towns are victory points worth 1 to 3. The town the
  ruler bid taken is ringed, with the general's planned thrust drawn to it.
- **Battles** are plates showing the weapons of their age, "12 v 15", and who
  is winning. **Marches** name where they end and when.

Once realms grow (the proposal above), all of this lights up in natural play
without further presentation work.
