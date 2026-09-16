# Opening opportunity wave handoff

## Delivery

- **Status:** READY
- **Base:** `daa1a4dc5638f4f0c7554136a4e41e8f947f4319`
- **Branch:** `codex/opening-opportunities-wave`
- **Worktree:** `/Users/seanpurtill/Documents/Codex/tt-opening-opportunities-wave`

## Player-visible behavior

The opening tree no longer exposes eight unrelated root questions from generic day-one context. Each question now needs a bounded body of lived evidence before local research can begin:

| Question | Evidence that exposes it |
|---|---|
| Seasonal Patterns | repeated days of staffed gathering in forage conditions |
| Ground Drainage | builders working occupied ground in a climate with rain |
| Wound Cleaning | actual civilian or military injuries where freshwater is available |
| Medicinal Classification | recognized medicinal plants handled by gatherers, surveyors, or carers |
| Material Tallies | real food/material stores repeatedly handled by logistics or administration |
| Encoded Routes | actual journey days or strong returned travel observations |
| Labor Rotations | a settled community sustaining several simultaneous staffed roles |
| Organized Watch | sustained staffed guard duty, accelerated by real danger |

These are activity gates, not calendar gates. A civilization can accelerate exposure by creating the relevant conditions. Waiting without the activity contributes nothing. A returned and fully studied foreign knowledge record or specimen remains a slower alternate route and can supply the missing opening evidence.

The evidence ledger is civilization-owned, bounded, validated, saved, and isolated between actors. Old saves that lack it start with an empty ledger and accumulate evidence from their next simulated day. Locked entries remain hidden by the existing atlas rules; when exposed, the normal atlas explanation and research assignment UI take over.

The live authored discovery count remains unchanged at 883. This wave changes exposure and eligibility only; it adds no discoveries and no graph edges.

## Files

- `scripts/opening_opportunities.gd`
- `scripts/discovery_system.gd`
- `scripts/game_state.gd`
- `scripts/save_system.gd`
- `scripts/world_simulation.gd`
- `tests/test_opening_opportunities.gd`
- `tests/test_technology_tree.gd`
- `tests/test_research_controller_viability.gd`

## Validation

- `test_opening_opportunities.gd`: **6/6 passed**. Covers distinct evidence, travel, settlement work, injuries/freshwater, medicinal access, studied foreign evidence, bounds, malformed state rejection, actor isolation, and actor payload validation.
- `test_research_controller_viability.gd`: **3/3 passed**.
- `test_technology_requirements.gd`: **15/15 passed**.
- `test_technology_tree.gd`: the opportunity-sensitive target case and the other seven unaffected cases pass. The suite retains two assertions in its first case that already fail on integrated main because existing branches have depths 30 and 31 against a stale `< 30` threshold. Opportunity evidence adds no graph edges and cannot change those depths.
- Headless Godot project import completed with no script parse errors.

The GdUnit launcher emits its existing invalid remote-debug-port warning before running; the test processes still return their correct suite exit codes.

## Save compatibility and limits

- Additive reflected `GameState.opening_opportunities` data; older saves default to the empty state.
- No population entities, free resources, automatic discoveries, or duplicated labor authority are introduced.
- Evidence is intentionally aggregate by qualifying day. It does not retain individual patients, guards, stores, or travelers.
- This wave addresses opening root density. Food preservation operations and the next settlement/subsistence causal wave remain separate chronological work.
