# First 300 years: prehistoric civilization pacing

**Status: endurance validation in progress. The 300-year endpoint has not yet been signed off.**

Begin with a capable prehistoric community and inherited survival skills. The campaign calendar is not a literal 800–500 BC chronology. Progress comes from people, local evidence, adopted knowledge, supplies and decisions; reaching a date does not grant equipment or a new era.

## Intended progression

| Years | Civilian capability | Military capability |
| --- | --- | --- |
| 0–25 | Viable settlement, maintained tools and bindings, food preservation and storage | Local defense and paid spear manufacture; early ranged investigation |
| 25–75 | Settled food economy, pottery or local alternatives, specialist work | Equipped militia, patrols, trained leadership and distinct roles |
| 75–150 | Connected settlements, exchange and durable public works | Formations, missile support, fortifications and dependable supply |
| 150–300 | Agrarian institutions and regional specialization; early metallurgy where its prerequisites are met | Regional campaigning, specialists, siege labor and replacements |

These are acceptance targets, not automatic unlocks. Isolation, scarce materials, conflict and chosen priorities can delay individual capabilities. A known recipe, a stocked weapon and an equipped soldier are different achievements.

## Geography and player decisions

| Starting conditions | Decisions and consequences |
| --- | --- |
| Fertile river country | Cultivation and storage can support specialists, but water access, flood exposure and seasonal reserves still matter. |
| Woodland and useful stone | Toolmaking and construction have local inputs. Cutting consumes finite standing reserves; regrowth stays at the source until harvested and hauled. |
| Sparse timber or dry ground | Preserve water and food, use feasible clay/fiber construction, obtain supplies through real routes, or relocate. Knowledge cannot create missing wood or freshwater. |
| Coast and waterways | Boats and exchange need usable access, developed methods and physical supplies. Coastal water is not automatically drinking water. |
| Cold or short seasons | Shelter, clothing and reserves compete with expansion and military commitments for labor and materials. |
| Ore scarcity or isolation | Seek samples, trade, settle another site or develop alternatives. An isolated society cannot operate an absent material chain merely by learning its name. |

Generated founding sites use the same viability rules for every seat. Forty-eight real terrain sites across three seeds passed checks for food, season, temperature, water, wood, stone and fiber. Later deliberate settlement can depend on exchange. Starts are not relocated around the player to force an encounter: the default-seed test has a nearest foreign homeland roughly 2,300 km away. Nearby societies, terrain barriers, scouting and settlement placement therefore matter to contact pacing.

Civic direction changes attention, labor and remembered priorities through the existing century-choice system. It does not assign arbitrary research completions. Government officials execute ordinary work, and succession now replaces deceased officials without discarding their historical identities or creating population.

## Completed evidence

A controlled 75-year comparison used fresh starts with the same seed and terrain site and changed only the ordinary Makers/Military ambition. Both maintained full current food intake and knew 61 practices, with different practice identities.

| Year-75 observation | Makers | Military |
| --- | ---: | ---: |
| Population | 624 | 642 |
| Settlements | 8 | 9 |
| Fitted post/beam sets produced | 77 | 64 |
| Fitted splice sets produced | 38 | 28 |
| Spears produced | 476 | 308 |
| Bows / arrows / pikes produced | 0 / 0 / 0 | 137 / 107 / 80 |
| Equipped spears / bows / pikes | 56 / 0 / 0 | 25 / 17 / 8 |

Both endpoints passed exact restoration and next-day continuation after the explicit-empty-observer restore fix. See [the controlled comparison](technology-review/pacing/first300-matched-decisions-75.json). These results establish meaningful choice effects; they do not establish the 300-year endpoint.

Other completed checks:

- Research chronology: 640 recorded discoveries across five actual campaign histories had their recorded foundations available when learned. All also have a satisfied current authored route. This covers checkpoints through years 71–187, not the final 300-year endpoint; [evidence and limitations](technology-review/pacing/first300-recorded-foundations.json).

- Default player-plus-twelve-opponent opening: one year, no reported state errors, viable water access, valid saves and exact whole-game continuation. A longer default-count run is underway.
- Actual player-plus-three-opponent campaign: year-87 checkpoint restored and advanced with exact whole-game equality. The long run continues.
- Managed production recovery: an actual stalled woodland workshop resumed paid fibers, yarn, spears and construction supplies without losing or refunding unfinished batches.
- Gathering: a cold year-131 comparison produced 38 additional spears over the next ordinary year by reducing unused overflowing materials. Samples, active inputs, explicit priorities and startup supplies for known crafts remain protected. Timber stayed scarce.
- Succession: a real older campaign with no living officials recovered ordinary appointments; historical people remain recorded. No population was added.
- Civic and exploration behavior: 69 checks passed for directive follow-through, administration, alerts, culture effects, scouting staff and route planning.
- Military operations: 65 training, recruitment, campaign and chronicle checks passed. Construction and city/material checks also pass.
- Player panels: 20 headless checks passed for live progress, settlement histories, civilian production, culture and research navigation. Visual inspection remains with the user.

## Performance and interpretation

The headless harness now uses the game's existing stable terrain lookup. Its military year-175 replay of 30 ordinary days dropped from 41.080 to 16.338 seconds with exactly equal world state. Reusing unchanged eligibility within one retrofit decision reduced the same replay to 12.599 seconds, again with exact equality. These are individual simulation timing pairs under concurrent load, not rendered frame-rate claims.

The [evidence guide](technology-review/PACING_PRODUCTION_EVIDENCE.md) explains inventories versus output, annual timing bounds, real terrain versus reference environments and checkpoint provenance. Long runs that span fixes are recovery evidence. They must not be presented as fresh uninterrupted runs on the final build.

## Remaining release checks

Cold civilian production remains an open issue: a controlled year-161-to-162 High timber priority decision produced 175 additional spears and 11 lances, but no additional civilian workshop goods. Population and current food intake were unchanged, and the trial passed exact save/next-day continuation. Investigate civilian setup starvation and competing material use before sign-off; [comparison](technology-review/pacing/first300-cold-timber-decision.json).

Finish the fresh current-build 300-year campaign and the ongoing warm, woodland, cold, military and full-world campaigns. Confirm final target days, actual output and fielded capabilities, government succession, state validity, and exact save/next-day continuation. Review the normal twelve-opponent run for contact and exchange opportunities. Record any remaining limitations explicitly before marking the first 300 years ready.

Historical intermediate observations are retained in the [development archive](FIRST_300_YEARS_PACING_ARCHIVE.md).
