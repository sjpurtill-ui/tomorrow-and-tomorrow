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

The military and warm campaigns have now reached day 109500. An endpoint audit checked all 611 recorded discovery routes: no missing origin records or recorded prerequisite violations. The military history also matches current authored routes throughout; the warm history retains the already-corrected hydrogen-glass shortcut from year 186. This verifies dependency consistency, not environmental evidence or sustained production. See [endpoint foundation audit](technology-review/pacing/first300-endpoint-foundations.json).

Other completed checks:

- Research chronology: 640 recorded discoveries across five actual campaign histories had their recorded foundations available when learned. All also matched an authored route in the audited build. A later correction requires hydrogen-production knowledge before hydrogen-flame glassworking; older retained discoveries do not validate that corrected gate. This covers checkpoints through years 71–187, not the final 300-year endpoint; [evidence and limitations](technology-review/pacing/first300-recorded-foundations.json).

- Default player-plus-twelve-opponent opening: 25 years completed, no state errors or waterless starts, valid saves, exact restoration and exact next-day continuation. The final replay covers years 20–25 after fixing a scouting route cache that omitted changing travel range. All twelve opponents had full current food intake, with 28–46 known practices and recorded production; some paused production to protect low food reserves. No false contact with the distant player was recorded. See [the endpoint evidence](technology-review/pacing/first300-default12-25.json). This is a 25-year default-count check, not a default-count 300-year result.
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

Cold civilian production has a verified short recovery, but sustained output remains a release gate. At year 186, household cooking exhausted delivered Timber for a small optional diet bonus, and affordable civilian orders were missed outside the AI's monthly review. Optional cooking now preserves the existing craft startup reserve; idle civilian workshops also review newly available supplies between monthly strategy reviews. The same checkpoint produced six drainage components in 30 days, with full food intake, unchanged population against the meal-only comparison, and exact save/next-day continuation. The meal-only change restored weapons but no civilian output. See [civilian recovery evidence](technology-review/pacing/first300-civilian-arrival-review.json) and [meal-fuel evidence](technology-review/pacing/first300-meal-fuel-recovery.json). Earlier year-161 recovery did not prove sustained later production; these later checks caught the renewed stall.

The military and warm economic endurance runs completed 300 years. Woodland, cold, Makers, and player-plus-three-opponent campaigns remain in progress from their retained checkpoints. These runs span revisions, and the isolated histories include the older scouting omission described below. No fresh final-build full-system 300-year result is established; do not restart existing campaigns from zero or count retired baselines as completed endpoints.

A subsequent catalog correction closes an ammonia-catalyst shortcut found in the woodland history: catalyst inquiry now needs the modeled nitrogen/hydrogen and pressure-control foundations. Fourteen focused checks and the complete dependency graph pass; retained older discoveries and currently running campaigns do not establish fresh pacing under this correction. See [the catalyst foundation evidence](technology-review/pacing/first300-ammonia-foundations.json).

Finish the ongoing Makers, woodland, cold and full-world campaigns, and verify sustained production recovery in the completed military and warm campaigns. Confirm final target days, actual output and fielded capabilities, government succession, state validity, and exact save/next-day continuation. The normal twelve-opponent run has passed its 25-year contact, production and save checks. Record any remaining limitations explicitly before marking the first 300 years ready.

Historical intermediate observations are retained in the [development archive](FIRST_300_YEARS_PACING_ARCHIVE.md).

### Scope correction for isolated campaign evidence

The isolated history harness omitted the civilization/scouting lifecycle until the September 22 correction. Existing isolated checkpoints validate economy and production across their recorded years, but not a complete 300-year scouting history. Do not describe even a day-zero isolated start as fresh final-build full-system validation. Continue saved campaigns with the corrected lifecycle; do not discard their economic evidence or restart them from zero. Full-world runs already advance the complete lifecycle.

A corrected 90-day replay from the warm year-301 checkpoint returned eight expeditions and resumed 75 drainage components without supplies being granted. Exact save/next-day continuation passed. The [recovery evidence](technology-review/pacing/first300-scout-supply-recovery.json) distinguishes this result from the still-pending full campaign checks.
