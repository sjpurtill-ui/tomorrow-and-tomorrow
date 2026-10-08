# Organic places: towns without a second ledger

October 8, 2026. Branch `codex/organic-places`. Engine: `scripts/settlement_places.gd`.

## What the user asked for

- New towns and cities should spring up organically.
- They must stay part of the central simulation, because the old daughter towns made every daily system run once per town and slowed the game.
- Expansion goes to coasts and lake shores before anywhere else, so the people start to use the sea and lakes.
- The map graphics must show this growth organically. Astra, the outside art agent, owns those graphics. This document is the contract Astra works from.

## The rule

A people keeps **one seat and one ledger** (`one_seat.gd`). A **place** is a named spot where some of its families live. A place record holds only these fields:

- `id`, `name`, `position` (world km);
- `kind`: `coast`, `lake`, `river` or `inland`;
- `shoreline`, `marine`, `open_water` and `facing`, all measured once at founding;
- `founded_day`;
- `share` (of the people) and `target`;
- `status` (`living` or `ruin`), plus `setback_until` and `left_day`.

A place has no people, stores, labour, water or daily step of its own. Its people are the realm's people times its share. Nothing in the daily calendar loops over places, so twelve places cost what one costs.

**Forbidden**, now and later:

- a per-place stockpile, workforce, water supply or daily tick;
- putting places into `player_settlements`, which is the register that about 125 daily loops iterate over.

If something needs local detail, compute it on demand from the share.

## How places come and go

The monthly pass (`monthly()`, run every 30 days from `civilization_day.gd`, step `secondary_plan`) does three things.

1. **Shares drift.** Each place closes 6% of the gap to its target each pass. The target is the place's pull divided by the seat's pull (2.5) plus all places' pulls, capped by the most people who may live away from the seat (15% at 1,000 people, 35% at 100,000, never more than 55%).

   Pull is made of:
   - **water:** coast 1.5, lake 1.3, river 1.15, inland 0.75;
   - **age:** reaches full pull after 25 years;
   - **the sea:** coast places pull more as boats go farther out (`sea_reach`);
   - **crowding:** the seat's crowding pushes families out;
   - **floods:** a flood sets a place back to 0.6 of its pull for three years;
   - **room:** if the people shrink below the room for their places, the smallest places keep only 0.15 of their pull.

2. **Places empty.** After ten years, a place below 0.15% of the people or 6 people becomes a **ruin**. At most four ruins are remembered.

3. **Places are founded.** A new place may be founded when all of these hold:
   - there is room: one place per 400 people under the square root (400: 1; 1,600: 2; 10,000: 5; 57,600: 12, the cap);
   - there are 30 days of food in store;
   - a 30% roll passes, so a place comes some seasons after there is room for it.

   **Site search.** Sixteen rays walk outward from the seat in 1.5 km steps, out to half the realm's reach (at most 160 km). Each ray stops at the first water it meets and finds the water's edge. The order is strict:
   - coast before lake before river;
   - dry ground last, and only within the worked land;
   - places stay 5 km apart.

   The search is bounded and runs only when a place is founded.

Founding and leaving each write one chronicle line. The name comes from the people's own tongue (`people_language.town`, using the land word for shore, reed or river). No other town can take that name (`names_in_use`).

## What places change in the game, all on the one ledger

- **The sea and lakes pay off.** The seat's coastal profile reads its best shore place, scaled by that place's share; a place holding 4% of the people works its shore fully (`coast_context`, used in `settlement_model.coastal_site_profile`). That raises shoreline access, marine opportunity and salt, so fishing, food and maritime movement and trade improve. It also raises storm and erosion exposure, the cost that comes with the sea.
- **Floods.** A people whose seat isn't a river camp is still flood-prone in proportion to its water places (`flood_exposure`). A flood comes in at a named place (`flood_place`), with losses scaled by that place's share, and the place is set back. The chronicle titles are "The Sea Comes In at X", "The Lake Rises at X" and "The River Comes In at X".
- **The settlement page** ("How our people spread") lists each place with its water, its people and whether it is growing, shrinking or rebuilding, and says which place works the shore.

Carrying capacity and growth are unchanged: land claims (`one_seat.claim_land`) still do that job. Saves need no migration, because places live in the seat's own register entry (`seat["places"]`).

## Contract for the map art (Astra)

Read this inside the owner's `WorldSimulation` scope:

```gdscript
var view:=preload("res://scripts/settlement_places.gd").snapshot()
# view = {owner, seat_position: Vector2, seat_people: int, revision: int,
#   places: [{id, name, position: Vector2 (world km), kind, status ("living"|"ruin"),
#     people: int, share: float, trend: -1|0|1, age_days, founded_day, left_day,
#     flooded: bool, shoreline, open_water, facing: Vector2 (toward the water; ZERO inland)}]}
```

- **Read-only.** These are plain copies. Never write place records, and never add saved fields for art.
- **When to redraw.** Rebuild when `revision` changes (a place founded or left). Otherwise refresh on the existing visual refresh day when a place's `people` crosses a population bucket (`settlement_country_plan.population_bucket`). Never refresh per frame.
- **Rivals.** Call it in a known rival's scope and the same rule applies, so the art treats every people the same way.

### What the user wants to see

1. **Each living place is a real expansion seed.** Anchor one of the existing country seeds (`settlement_country_growth.gd`) at the place's `position`, instead of placing seeds only by the root-fringe accretion around the seat.
   - Use the same root parcel solver, architecture and completed construction palette, as the root seeds already do.
   - Scale the parcel count with `people` (bounded by `MAX_PARCELS`).
   - Keep seed centres and existing roofs fixed as the place grows.
2. **The water shapes the place.**
   - **Coast:** houses turn toward `facing`; boat hulls drawn up on the beach; drying racks; salt pans where `open_water` is high.
   - **Lake:** reed edges and a short jetty.
   - **River:** houses strung along the bank, with a ford or crossing track.
   - **Inland:** yards and field plots, like the current clusters.
3. **A track joins each place to the seat.** It starts as a desire path and its tier follows `road_tier`. A shore track should follow the coast where it can.
4. **The state shows.**
   - `trend` 1: fresh building sites at the edge.
   - `trend` -1: a few roofs fallen in.
   - `flooded`: a damage wash at the water side for the setback period.
   - `ruin`: roofless walls and overgrowth that fade over the years after `left_day`.
5. **A name on the chart.** Use the inked chart label, smaller than the seat's, and never a dev-looking UI element.
6. **Limits.**
   - At most 12 living places and 4 ruins per people.
   - No human map figures.
   - No new simulation state.
   - Preparation stays cooperative and sliced, like the existing country layer (old patches stay visible until the new one is ready).
   - Era appearance comes from completed construction, never from the calendar.

### Acceptance

Use private GPU captures of a copied save, never the player's live game, at these four moments:

- the first coastal place, at founding;
- a mature coastal place at the same scale as the root;
- a place under flood setback;
- a ruin.

Send the captures to the user before calling the art done; the user's eye is the only approval. Run headless tests against `tests/test_settlement_places.gd` (11 cases), plus the country plan and visual suites.

## Validation of the engine (this branch)

- `tests/test_settlement_places.gd`: 11 of 11 pass. They cover coast before a nearer river, river without a shore, dry ground within the worked land, no place without room or food, the one ledger adding up, the monthly cadence, shore benefits, floods, ruins, the art snapshot, and six centuries of cadence.
- Six centuries, 150 to 60,000 people: 12 places, the first at year 98 (401 people), each some seasons after room opens. Eleven are coastal, then a river once the coast within reach is full. The pass averages under 0.1 ms a month.
- These suites still pass: `test_one_seat`, `test_crisis_water_and_fire`, `test_crisis_every_people`, `test_coastal_water` and `test_town_names`.
