# Household clothing service

Worker checkout: `/Users/seanpurtill/.codex/worktrees/ef8f/tomorrow-and-tomorrow`; branch `codex/household-clothing-service`; base `2bcd799a103328887836c503b576caedaf4651c6`. INTEGRATED as runtime `3dce8a70fbc537cce2b0743d1d1e4d167da7d079`; all 15 canonical clothing cases pass.

Six existing authored identities gain operating consumers: `knitted_loop_fabrics`, `twill_weave_structures`, `pile_fabric_weaving`, `layered_clothing_design`, `textile_laundering_practice`, `textile_moisture_transport`. The first three use existing plant yarn to produce knitted garments or woven wraps. No wool, hide or bone supply is invented. Knitting's supported cordage route is retained; the unavailable bone-needle route remains in its editorial history.

Paid equipment and actual materials constrain every operation. Each installed tool has a shared daily quota across its lots. The ordinary FoodSystem owner/local-population scope passes remaining Logistics work after meal, grain and food-batch processing; clothing can use at most 20% of that remainder. Preservation receives the work left after clothing. Industry, ResourceSystem, and GovernmentPeopleSystem labor authority are unchanged. The same input-aware paid equipment steward runs for player and rival owners.

One finite garment unit covers at most one resident. A layered unit consumes two garments, using only spare inventory above population. Issued garments soil and wear; worn-out units are discarded. Laundering consumes water and removes washed units from service until the following day. Moisture handling consumes lining cloth and water for an explicitly bounded treated portion. Knowledge alone never grants exposure protection. Actual supplied condition and coverage reduce the existing cold health cost and cold/storm mortality component; heat, disease and unsheltered baseline costs remain separate.

The Research Atlas exposes paid equipment installation, garment/issued stock and actual service percentages for each selected clothing discovery. No garment-by-garment mandatory management flow is added.

## Persistence and scope

New owned GameState field `household_clothing` holds installed tool counts, at most 48 aggregate lots, last processed day and bounded report. CITY_RESOURCE_DEFAULTS, player SaveSystem validation, owned-world validation and secondary-city validation retain that state. Missing legacy fields load empty. This adds no person records, graphics geometry or player restart.

Shared integration hunks: Discovery registration/description, TechnologyCatalogContract consumer, GameState field/reset, SettlementModel city default, SaveSystem and WorldSimulation validation, FoodSystem remaining-work hook/report, ConsequenceEngine exposure and service telemetry, Research Atlas selected panel. Preserve water's separate state/consumer hunks during integration.

Limits: insulation, soil and moisture-response values are aggregate game balances, not material laboratory measurements. This batch does not implement tanning, felt, sewing, garment trade, individual fitting, machine textile factories or full historical pacing. It adds six working discoveries rather than registering the remaining textile drafts. All lots are city-local; the system does not claim stock transport between cities.

## Verification

Worktree: 101 cases across six suites pass: household clothing15, food batches23, grain20, civilization ownership19, city resources12 and Research Atlas12. The final clothing rerun fixes day-end service telemetry replacement and verifies the actual cold health consumer, not just helper formulas. Graph audit has657 discoveries/439 explicit routes/303 civilian recipes/17 facilities, no graph or dependency errors. Logs: `/tmp/tt-clothing-final.log`, `/tmp/tt-clothing-results.json` (the initial clothing row is superseded by the final rerun), `/tmp/tt-clothing-graph-final.log`. No terrain suite expansion or live player/editor launch.
