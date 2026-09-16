# Opening cultivation and husbandry integration handoff

## Scope

This wave repairs the bootstrap for Selective Planting and Animal Taming. Both discoveries now emerge from bounded physical programs rather than a prerequisite idea alone. The live catalog remains 883 discoveries.

## Selective planting

- Seasonal Patterns, a settled site, at least two Food workers, recognized fertile ground, and finite Dry Staples are required to begin.
- Workers gradually separate a population-scaled retained-seed reserve. Before Selective Planting can become eligible, seed must pass through two separate 90-day plots with at least 70 tended days each.
- Each plot spends retained seed and returns a small bounded seed quantity after a successful cycle. The trial does not manufacture ordinary edible food.
- Learning Selective Planting without local seed provides no cultivation output, yield effects, or visible field growth. Existing and externally learned knowledge can establish its local reserve by physically separating dry seed on later qualifying days.
- As population rises, seed coverage can fall until additional real seed is retained.

## Animal taming

- Seasonal Patterns, a settled site, at least two Food workers, water access, and a recognized Game population with suitable quality or potential are required.
- The first herd removes up to four animals from that wild population. It then consumes finite Fresh Plants or Dry Staples every qualifying day.
- Sixty supplied handling days expose Animal Taming. Reproduction begins only after continuing care, stays bounded against population, and no longer depends on the original wild population once capture occurred.
- A missed day of staff, water, or feed immediately removes animal-derived effects. After three consecutive missed care days, the living herd declines by two percent per day.
- Animal Taming and its pack, mount, and mounted-scout descendants scale their listed passive effects with the maintained living herd. Knowledge supplies no animals.

## Compatibility and limits

- The bounded seed and herd records live in the existing `opening_opportunities` save dictionary. Older saves without `programs` remain valid and upgrade in place on the next qualifying discovery day.
- An older save that already knows Selective Planting separates real stored dry seed before cultivation resumes. An older animal line must establish and maintain a local herd before animal-derived passive effects resume.
- This wave does not yet make military recruitment debit individual mounts. That inventory contract belongs to the later mounted-unit operating wave.

## Validation

- `test_opening_domestication.gd`: 5/5 passed.
- `test_opening_opportunities.gd`: 6/6 passed.
- `test_technology_requirements.gd`: 15/15 passed.
- `test_crop_nutrition.gd`: 13/13 passed.
- `test_agronomy_knowledge.gd`: 8/8 passed.
- `test_field_botany.gd`: 10/10 passed.
- `test_settlement_model.gd`: 43/43 passed.
- The GdUnit launcher emits its existing invalid remote-debug port warning before successful execution.

## Integration notes

- Shared hotspots touched: `discovery_system.gd`, `food_system.gd`, and `settlement_model.gd`.
- No player game was launched from the worker checkout.
