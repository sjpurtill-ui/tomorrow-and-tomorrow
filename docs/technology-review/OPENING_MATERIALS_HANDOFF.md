# Opening Materials Runtime Handoff

## Integration record

- Worktree: `/Users/seanpurtill/Documents/Codex/tt-opening-materials-wave`
- Branch: `codex/opening-materials-wave`
- Base: `5d545c2691d3813a33119238601dc922a07ee276`
- Scope: opening tool, fiber, container, ceramic, timber and clothing practice; chronology prerequisites; save and civilization ownership; atlas visibility.

## Player behavior

Controlled flaking, cordage, hafted tools, basketry, clay shaping, pit firing and joinery now create finite physical stocks from local materials and Crafting labor. Those stocks wear out. The discoveries' aggregate effects scale with current stock coverage, while the knowledge itself remains known. Pit firing also needs a live maintained fire. No stock appears merely because a discovery is learned.

The Knowledge Atlas reports the physical product and current operating coverage for these discoveries. Materials inventory also exposes the resulting stocks through the existing generic material listing.

The opening chronology now requires edible-resource recognition before food drying, fiber grading before cordage and basketry, clay testing before clay shaping, and hafted tools plus timber grading before joinery. Existing alternative research routes still obey the shared foundations. The live graph remains reachable.

Ordinary local hunting now recovers bounded bone independently of whether sewing is understood. Bone-needle sewing can use raw hides and prepared plant fiber before woven cloth and spun yarn are available; the textile route remains preferred when supplied.

## State and compatibility

Opening craft state and products are local to each civilization and settlement, are included in reflected saves, and are validated before restore. Older saves without the additive state field load with an empty valid practice record; known practices resume production from actual local inputs on the next eligible day. Existing discovery identities and the 883-discovery live count are unchanged.

## Verification

Godot 4.7.2 headless import completed with the explicit worktree path. Focused GdUnit coverage passed after the final fixes:

- `test_opening_craft_practice.gd`: 6/6
- `test_opening_fire_knowledge.gd`: 10/10
- `test_technology_requirements.gd`: 15/15
- `test_household_clothing.gd`: 28/28
- `test_food_preparation.gd`: 14/14
- `test_civilization_owned_simulation.gd`: 19/19
- `test_resource_recognition.gd`: 9/9

This is 101 focused cases with zero remaining errors, failures, skips or orphans. The checks cover causal prerequisites, physical input conservation, stock-gated effects, Atlas reporting, live-fire gating, ordinary hunting inputs, actor and city isolation, graph reachability, and complete owned-civilization save continuation.

## Known boundary

This wave converts the first seven shared material practices and the immediate bone-needle clothing route. Later downstream workshops still treat these discoveries as knowledge foundations and retain their own existing physical production contracts. Converting every downstream use to consume these opening stocks belongs to later transformation waves and should be done only where the stock represents a real recurring input rather than general accumulated craft competence.
