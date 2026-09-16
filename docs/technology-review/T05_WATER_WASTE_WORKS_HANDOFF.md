# T05 water and waste works handoff

**Status:** READY

**Worker:** `/Users/seanpurtill/Documents/Codex/tt-t05-water-waste-works`  
**Branch:** `codex/t05-water-waste-works`  
**Base:** `056dde52ce3366470fb853a1b020131ff158589d`

## Behavior

Four existing discoveries now expose paid, local construction instead of granting settlement-wide effects from knowledge alone:

- Latrine Siting builds separated latrine ground from timber and stone. Its sanitation effect requires completed, maintained works and enough local Construction or Logistics labor for upkeep.
- Protected Wellheads builds a cover and apron only over a confirmed well or developed aquifer. It improves water safety without creating supply and stops operating when the well is unavailable.
- Rainwater Cisterns consumes stone plus one valid lining route. A completed cistern adds finite storage and captures rainfall according to local precipitation; captured water receives no safety bonus.
- Water Settling Basins consumes clay and stone. Its modest water-safety effect is limited by local Logistics labor and daily treatment volume, and is not represented as sterilization.

The existing Water & Sanitation panel exposes the four construction actions in every local city scope. Projects share the established monthly Construction pool with buildings, water lines, rail work and settlement retrofits. Active works decay, compete for maintenance labor, and consume repair material. Discovery descriptions show current local operating coverage.

## State and save compatibility

`water_waste_works` is additive per-city state with at most one record of each kind. Older saves default to an empty ledger. New records are validated for bounded IDs, work, condition, status and unique work kind. Full-save coverage verifies that paid material and unfinished construction restore without duplication.

## Validation

- `tests/test_water_waste_works.gd`: **7/7**
- `tests/test_water_conveyance_operations.gd`: **14/14**
- `tests/test_settlement_model.gd`: **43/43**
- `tests/test_opening_water_health.gd`: **4/4**

All reported suites completed with zero errors, failures, flaky cases, skips or orphans. The standard headless remote-port warning is unchanged.

## Limits and next work

This packet implements the first T05 repair slice. Cistern service credit follows current rainfall; water retained in the shared Freshwater stock still remains physically usable during dry weather, but is not separately tagged by storage vessel. A wellhead requires an already modeled well or developed Deep Aquifer and does not dig the well. Latrine ground is an aggregate local work rather than a rendered individual pit.

Controlled kiln/binder capacity and bounded road/irrigation networks remain the next two T05 implementation packets. No player game was launched from this worktree.
