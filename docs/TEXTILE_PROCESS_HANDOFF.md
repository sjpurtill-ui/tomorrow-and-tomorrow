# Textile measurement, spinning and figured weaving

Worktree `/Users/seanpurtill/Documents/Codex/tt-textile-process-runtime`, branch
`codex/textile-process-runtime`, base `851a0cad29aa55e6a7fd689d58b5775af3cf7bba`.
Scope approved by the integrator: six existing authored identities, ten physical
recipes, clothing consumers and supply targets. Canonical promotion follows review.

## Operating discoveries

| Discovery | Paid operating consequence |
| --- | --- |
| Yarn-Count Standards | Sampling consumes 1.05 yarn plus clay records and 0.4 work per measured-yarn batch; balance/reel tooling is installed. Measured feed is useful in lower-loss weaving recipes. |
| Yarn-Tension Control | A separate governed loom consumes 1.8 measured yarn per plain cloth batch, with governors, cranks and loom tooling. Other looms receive no automatic efficiency bonus. |
| Ring Spinning Systems | Ring/traveler tooling converts combed fibers to yarn. Hand drive takes 1.2 work; motor drive takes 0.45 work and 1.5 electricity per batch. |
| Rotor Spinning Systems | Powered rotor tooling consumes 1.1 prepared fibers, 0.4 work and 2 electricity per yarn batch. It has a distinct feed preparation and material/work tradeoff. |
| Drawloom Pattern Control | Manual warp selection consumes 2.5 yarn and 5 work to produce figured cloth. Measured-feed alternative consumes 2.2 measured yarn and 4.5 work. |
| Punched-Card Loom Control | Paper and fiber become punched/laced physical pattern cards. Card-selected weaving consumes a replacement allowance of 0.05 cards and 2.4 yarn per cloth; measured feed uses 2.1. Work falls to 2.5 or 2.3 respectively. |

All quantities are game batches and explicit balance coefficients, not historical
productivity or universal textile performance measurements. Sampled yarn represents
one compatible declared count class; the game does not yet store arbitrary numeric
tex/denier classes, individual fibers, or motif instructions. Card consumption models
wear/replacement of a repeating physical control set, not disposal on every pick.
No new identity is claimed for recipe variants or garment decoration.

Original mandatory and alternative prerequisites are retained from
`machinery-fibers-earth.json`; local learning routes are explicit. Existing recovery
services remain the means of receiving foreign knowledge. Importing measured yarn
or figured cloth enables its local use but never grants manufacturing mastery.

## Material consumers and daily behavior

Measured yarn feeds both governed plain weaving and matched-feed figured routes.
Ordinary yarn still feeds plain weaving, sewing and the slower figured routes.
Figured cloth substitutes in existing sewing, cutting and graded-cutting methods,
including paid pattern-template installation. These are the existing skills and
Logistics work budgets; no additional sewing discovery or free labor pool is added.

Garment lots retain an optional `fabric` enum (`plain` or `figured`) through creation,
wear, laundering, layering and other lot transformations. Missing legacy fields mean
plain fabric. Different fabrics cannot merge into one lot. Existing garment kind,
condition and soil still determine protection; decorative pattern alone changes
neither health nor insulation. The clothing panel shows figured-garment quantity and
the actual material currently selected for consumption.

The existing production planner follows a bounded figured-cloth target while usable
sewing and garment deficit exist: at most six cloth in reserve, with patterned stock
targeted at a quarter of population. This is an autonomous preference, not a mandatory
order. Ordinary clothing remains available if the complete patterned supply chain
cannot be provisioned. Shared per-city targets also request real delayed shipments,
retain donor reserves and consume existing finite transport capacity. Arrival precedes
local sewing; neither city can consume the other's warehouse directly.

No new top-level state, save owner, military command, population owner, renderer,
terrain or project configuration is added. Existing clothing validators accept the
explicit fabric enum and legacy default. Full owned-world save continuation preserves
both patterned garments and partially completed powered spinning, without duplicate
output or mutation of the human warehouse.

## Source basis

The modeled mechanisms are informed by primary educational and museum sources:

- [CottonWorks: Yarn Spinning](https://cottonworks.com/learning-hub/yarn-manufacturing/yarn-spinning/) distinguishes ring and rotor formation and their feed/processing tradeoffs.
- [CottonWorks: Preparation for Weaving](https://cottonworks.com/learning-hub/weaving/preparation-for-weaving/) describes uniform yarn count and tension as preparation requirements.
- [Computer History Museum: Punched cards control Jacquard loom](https://www.computerhistory.org/storageengine/punched-cards-control-jacquard-loom/) describes cards selecting warp cords for successive shuttle passes.
- [Science Museum Group: Jacquard card hole punch](https://collection.sciencemuseumgroup.org.uk/objects/co537200/hole-punch-for-making-jacquard-cards) documents physical card preparation tooling.

These sources support mechanism distinctions. Numerical costs, losses, duty budgets,
stock targets and garment coefficients above are authored game rules.

## Integration ownership

Additive recipe insertions in `CivilianIndustry` and registration in `DiscoverySystem`
will overlap the integrator's complementary glass/ceramic and earthen material work.
Preserve those additions. Consumer changes are scoped to HouseholdClothing,
CivilianProductionPlanner, clothing panel and the existing per-city supply-target
merge in SettlementModel. The new optional lot field was explicitly coordinated.

This worktree's structural audit is 709 discoveries / 491 explicit routes / 351
recipes / 18 facilities on its 703-discovery base. Do not replace later canonical
snapshots with this older-base result. Six promotions add no authored identities.
Full historical pacing, remaining technology families and six matching illustrations
remain outstanding; none is claimed complete by this delivery.

## Validation evidence

Godot 4.7.2, explicit worktree paths and headless GdUnit:

```
Godot --headless --path /Users/seanpurtill/Documents/Codex/tt-textile-process-runtime -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/test_textile_process.gd -a tests/test_textile_mechanization.gd -a tests/test_textile_knowledge.gd -a tests/test_household_clothing.gd -a tests/test_civilian_production_planner.gd
```

62/62 passed in 19.229 seconds (`/tmp/tt-textile-process-acceptance.log`).
After connecting actual city transfer, the focused combination of
`test_textile_process.gd`, `test_city_resources.gd`, and
`test_civilian_production_planner.gd` passed 40/40 in 8.615 seconds
(`/tmp/tt-textile-process-city2.log`). That is 76 distinct passing cases, including
12 new textile cases. No errors, skipped cases or orphan nodes in successful runs.

The added city test verifies donor debit, no immediate destination stock, delayed
arrival and actual secondary sewing without touching the capital's clothing or
warehouse. Earlier fixture corrections respected existing single-line workshop
capacity and stock targets, used proper serialized electricity keys, and supplied
an explicit Dictionary type in the city test. They changed no production capacity,
power or save behavior merely to pass a test.

`tools/audit_technology_graph.gd` exits 0 with no graph/production errors and full
structural reachability of 351 recipes and 18 facilities on this worktree's base
(`/tmp/tt-textile-process-graph.log`). It does not prove campaign pacing. Fresh
editor import exited 0 without script errors (`/tmp/tt-textile-process-import.log`).

Normal headless project boot with `--quit-after 2` exited 0, reaching
`DIRECTION_SCREEN_READY` without script errors (`/tmp/tt-textile-process-boot.log`).
No player/editor process was launched, stopped or restarted.
